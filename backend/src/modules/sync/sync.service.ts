import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { SyncPullQuery, SyncPushBody } from './sync.schema';
import { invoicesService } from '../invoices/invoices.service';
import { paymentsService } from '../payments/payments.service';
import { kotService } from '../kot/kot.service';
import { ordersService } from '../orders/orders.service';
import { purchasesService } from '../purchases/purchases.service';
import { logger } from '../../utils/logger';
import { AuthUser, normalizeRole } from '../../middleware/auth.middleware';

export class SyncService {
  async pullChanges(
    businessId: string,
    deviceId: string | undefined,
    query: SyncPullQuery,
    authUser?: AuthUser
  ) {
    const clientCursor = BigInt(query.cursor);
    const limit = query.limit;
    const isSupplier = authUser && normalizeRole(authUser.role) === 'SUPPLIER';
    const supplierId = authUser?.supplierId;

    // 1. Fetch from commit-safe sync_change_log ordered by cursor ASC
    const changeLogs = await prisma.sync_change_log.findMany({
      where: {
        business_id: businessId,
        cursor: { gt: clientCursor },
      },
      orderBy: { cursor: 'asc' },
      take: limit,
    });

    // 2. Fetch authoritative business cursor
    const cursorRecord = await prisma.business_sync_cursors.findUnique({
      where: { business_id: businessId },
    });
    const latestServerCursor = cursorRecord ? cursorRecord.last_cursor : 0n;

    // Baseline hydration: if a new device starts at cursor 0 and change log is empty,
    // directly deliver all active categories, suppliers, and products
    if (clientCursor === 0n && changeLogs.length === 0) {
      const [initialCategories, initialSuppliers, initialProducts] = await Promise.all([
        prisma.categories.findMany({
          where: { business_id: businessId, deleted_at: null },
          orderBy: { display_order: 'asc' },
        }),
        prisma.suppliers.findMany({
          where: {
            business_id: businessId,
            deleted_at: null,
            ...(isSupplier && supplierId ? { id: supplierId } : {}),
          },
        }),
        prisma.products.findMany({
          where: { business_id: businessId, deleted_at: null },
          include: {
            categories: { select: { name: true } },
            suppliers: { select: { supplier_name: true } },
          },
          orderBy: { name: 'asc' },
        }),
      ]);

      const baselineChanges: any[] = [];
      let cur = 1n;
      for (const cat of initialCategories) {
        if (cat.color_value !== null && cat.color_value !== undefined) {
          (cat as any).color_value = (cat as any).color_value >>> 0;
        }
        baselineChanges.push({
          cursor: cur,
          entityName: 'categories',
          recordId: cat.id,
          operation: 'INSERT',
          data: cat,
          version: cat.server_version || cur,
        });
        cur++;
      }
      for (const sup of initialSuppliers) {
        baselineChanges.push({
          cursor: cur,
          entityName: 'suppliers',
          recordId: sup.id,
          operation: 'INSERT',
          data: sup,
          version: sup.server_version || cur,
        });
        cur++;
      }
      for (const prod of initialProducts) {
        if ((prod as any).categories) {
          (prod as any).category_name = (prod as any).categories.name;
        }
        if ((prod as any).suppliers) {
          (prod as any).supplier_name = (prod as any).suppliers.supplier_name;
        }
        baselineChanges.push({
          cursor: cur,
          entityName: 'products',
          recordId: prod.id,
          operation: 'INSERT',
          data: prod,
          version: prod.server_version || cur,
        });
        cur++;
      }

      const effectiveNextCursor = latestServerCursor > 0n ? latestServerCursor : cur;
      return {
        changes: baselineChanges,
        nextCursor: effectiveNextCursor.toString(),
        hasMore: false,
        latestServerCursor: latestServerCursor.toString(),
      };
    }

    // 3. Hydrate records
    const changes: any[] = [];
    let nextCursor = clientCursor;

    for (const entry of changeLogs) {
      nextCursor = entry.cursor; // Advance only to what is processed

      // If caller is a supplier, filter out sales and other suppliers' records
      if (isSupplier) {
        const supplierAllowedEntities = [
          'categories',
          'suppliers',
          'products',
          'purchase_orders',
          'purchase_invoices',
          'supplier_payments',
        ];
        if (!supplierAllowedEntities.includes(entry.entity_name)) {
          // Do not send sales records to suppliers
          continue;
        }
      }

      if (entry.operation === 'DELETE') {
        changes.push({
          cursor: entry.cursor,
          entityName: entry.entity_name,
          recordId: entry.record_id,
          operation: 'DELETE',
          data: null,
          version: entry.record_version,
        });
        continue;
      }

      // Hydrate from table
      let data: any = null;
      switch (entry.entity_name) {
        case 'categories':
          data = await prisma.categories.findFirst({
            where: { id: entry.record_id, business_id: businessId },
          });
          if (data && data.color_value !== null && data.color_value !== undefined) {
            (data as any).color_value = data.color_value >>> 0;
          }
          break;
        case 'suppliers':
          data = await prisma.suppliers.findFirst({
            where: {
              id: entry.record_id,
              business_id: businessId,
              ...(isSupplier && supplierId ? { id: supplierId } : {}),
            },
          });
          break;
        case 'products':
          data = await prisma.products.findFirst({
            where: {
              id: entry.record_id,
              business_id: businessId,
            },
            include: {
              categories: {
                select: { name: true },
              },
              suppliers: {
                select: { supplier_name: true },
              },
            },
          });
          if (data && (data as any).categories) {
            (data as any).category_name = (data as any).categories.name;
          }
          if (data && (data as any).suppliers) {
            (data as any).supplier_name = (data as any).suppliers.supplier_name;
          }
          break;
        case 'customers':
          data = await prisma.customers.findFirst({
            where: { id: entry.record_id, business_id: businessId },
          });
          break;
        case 'dining_tables':
          data = await prisma.dining_tables.findFirst({
            where: { id: entry.record_id, business_id: businessId },
          });
          break;
        case 'orders':
          data = await prisma.orders.findFirst({
            where: { id: entry.record_id, business_id: businessId },
            include: {
              order_items: true,
            },
          });
          break;
        case 'invoices':
          data = await prisma.invoices.findFirst({
            where: { id: entry.record_id, business_id: businessId },
            include: {
              invoice_items: true,
              bill_notes: true,
              payments: true,
            },
          });
          break;
        case 'payments':
          data = await prisma.payments.findFirst({
            where: { id: entry.record_id },
          });
          break;
        case 'product_images':
          data = await prisma.product_images.findFirst({
            where: { id: entry.record_id, deleted_at: null },
          });
          break;
        case 'kot_records':
          data = await prisma.kot_records.findFirst({
            where: { id: entry.record_id },
          });
          break;
        case 'kot_items':
          data = await prisma.kot_items.findFirst({
            where: { id: entry.record_id },
          });
          break;
        case 'purchase_orders':
          data = await prisma.purchase_orders.findFirst({
            where: {
              id: entry.record_id,
              business_id: businessId,
              ...(isSupplier && supplierId ? { supplier_id: supplierId } : {}),
            },
            include: {
              purchase_order_items: true,
            },
          });
          break;
        case 'purchase_invoices':
          data = await prisma.purchase_invoices.findFirst({
            where: {
              id: entry.record_id,
              business_id: businessId,
              ...(isSupplier && supplierId ? { supplier_id: supplierId } : {}),
            },
            include: {
              purchase_invoice_items: true,
              supplier_payments: true,
            },
          });
          break;
        case 'supplier_payments':
          data = await prisma.supplier_payments.findFirst({
            where: {
              id: entry.record_id,
              business_id: businessId,
              ...(isSupplier && supplierId ? { supplier_id: supplierId } : {}),
            },
          });
          break;
        case 'business_settings':
          data = await prisma.business_settings.findFirst({
            where: { id: entry.record_id, business_id: businessId },
          });
          break;
        default:
          break;
      }

      // If record was permanently removed or not found (or filtered due to supplier ownership), mark or skip
      if (!data) {
        if (!isSupplier) {
          changes.push({
            cursor: entry.cursor,
            entityName: entry.entity_name,
            recordId: entry.record_id,
            operation: 'DELETE',
            data: null,
            version: entry.record_version,
          });
        }
      } else {
        const isSoftDeleted = (data as any).deleted_at != null;
        changes.push({
          cursor: entry.cursor,
          entityName: entry.entity_name,
          recordId: entry.record_id,
          operation: isSoftDeleted ? 'DELETE' : entry.operation,
          data,
          version: entry.record_version,
        });
      }
    }

    // 4. Update device sync state if deviceId is provided
    if (deviceId) {
      await prisma.device_sync_state.upsert({
        where: {
          device_id_entity_name: {
            device_id: deviceId,
            entity_name: 'global',
          },
        },
        update: {
          last_pulled_version: nextCursor,
          last_pushed_at: new Date(),
        },
        create: {
          device_id: deviceId,
          entity_name: 'global',
          last_pulled_version: nextCursor,
          last_pushed_at: new Date(),
        },
      }).catch(() => {});
    }

    const hasMore = nextCursor < latestServerCursor;

    return {
      changes,
      nextCursor: nextCursor.toString(),
      hasMore,
      latestServerCursor: latestServerCursor.toString(),
      count: changes.length,
    };
  }

  async pushChanges(
    businessId: string,
    verifiedDeviceId: string | undefined,
    data: SyncPushBody,
    authUser?: AuthUser
  ) {
    const results: any[] = [];
    const effectiveDeviceId = verifiedDeviceId || data.deviceId;
    const isSupplier = authUser && normalizeRole(authUser.role) === 'SUPPLIER';
    const supplierId = authUser?.supplierId;

    // Sort incoming items by dependency rank defensively so referenced parent records are created first
    const ENTITY_DEPENDENCY_RANK: Record<string, number> = {
      categories: 10,
      suppliers: 20,
      products: 30,
      customers: 40,
      dining_tables: 40,
      orders: 50,
      purchase_orders: 50,
      invoices: 60,
      purchase_invoices: 60,
      payments: 70,
      supplier_payments: 70,
      kot_records: 70,
    };

    const sortedItems = [...data.items].sort(
      (a, b) => (ENTITY_DEPENDENCY_RANK[a.entityName] ?? 99) - (ENTITY_DEPENDENCY_RANK[b.entityName] ?? 99)
    );

    for (const item of sortedItems) {
      try {
        logger.info(
          `[SyncPush] Business=${businessId} Device=${effectiveDeviceId || 'unknown'} Entity=${item.entityName} Op=${item.operation} ID=${item.recordId}`
        );

        switch (item.entityName) {
          case 'customers': {
            const p = item.payload;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              await prisma.customers.upsert({
                where: {
                  business_id_id: {
                    business_id: businessId,
                    id: item.recordId,
                  },
                },
                update: {
                  name: p.name,
                  phone: p.phone,
                  address: p.address,
                  notes: p.notes,
                },
                create: {
                  id: item.recordId,
                  business_id: businessId,
                  name: p.name,
                  phone: p.phone,
                  address: p.address,
                  notes: p.notes,
                },
              });
              results.push({ recordId: item.recordId, status: 'synced', entity: 'customers' });
            }
            break;
          }
          case 'suppliers': {
            // Suppliers can only be created/updated by Admin
            if (isSupplier) {
              results.push({
                recordId: item.recordId,
                status: 'error',
                error: 'Forbidden: Suppliers cannot push supplier master records.',
              });
              continue;
            }
            const p = item.payload;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              const saved = await prisma.suppliers.upsert({
                where: {
                  business_id_id: {
                    business_id: businessId,
                    id: item.recordId,
                  },
                },
                update: {
                  supplier_name: p.supplierName || p.supplier_name,
                  contact_person: p.contactPerson || p.contact_person,
                  phone_number: p.phoneNumber || p.phone_number,
                  email: p.email,
                  address: p.address,
                  notes: p.notes,
                  is_active: p.isActive ?? true,
                },
                create: {
                  id: item.recordId,
                  business_id: businessId,
                  supplier_code: p.supplierCode || p.supplier_code || `SUP-${Date.now()}`,
                  supplier_name: p.supplierName || p.supplier_name,
                  contact_person: p.contactPerson || p.contact_person,
                  phone_number: p.phoneNumber || p.phone_number,
                  email: p.email,
                  address: p.address,
                  notes: p.notes,
                  is_active: p.isActive ?? true,
                },
              });
              results.push({ recordId: item.recordId, status: 'synced', entity: 'suppliers', serverVersion: saved.server_version?.toString() });
            }
            break;
          }
          case 'products': {
            const p = item.payload;
            const existing = await prisma.products.findFirst({
              where: { id: item.recordId, business_id: businessId },
            });

            // Supplier ownership check: If supplier, they cannot edit another supplier's product
            if (isSupplier && supplierId) {
              if (existing && existing.supplier_id !== supplierId) {
                results.push({
                  recordId: item.recordId,
                  status: 'error',
                  error: 'Forbidden: Cannot update product belonging to another supplier.',
                });
                continue;
              }
            }

            const clientVer = item.clientVersion !== undefined && item.clientVersion !== null ? BigInt(item.clientVersion) : null;
            if (
              existing &&
              item.operation === 'UPDATE' &&
              clientVer !== null &&
              clientVer > 0n &&
              existing.server_version &&
              existing.server_version > clientVer
            ) {
              if (effectiveDeviceId) {
                await prisma.sync_conflicts.create({
                  data: {
                    id: randomUUID(),
                    device_id: effectiveDeviceId,
                    entity_name: 'products',
                    record_id: item.recordId,
                    client_payload: item.payload,
                    server_payload: JSON.parse(JSON.stringify(existing)),
                    resolution: 'SERVER_WINS',
                  },
                }).catch(() => {});
              }
              results.push({
                recordId: item.recordId,
                status: 'conflict',
                resolution: 'SERVER_WINS',
                serverVersion: existing.server_version.toString(),
              });
              continue;
            }

            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              let resolvedCategoryId: string | null = null;
              if (p.categoryId) {
                const catById = await prisma.categories.findFirst({
                  where: { id: p.categoryId, business_id: businessId, deleted_at: null },
                });
                if (catById) {
                  resolvedCategoryId = catById.id;
                }
              }

              // Resolve product supplier_id
              let resolvedSupplierId: string | null = null;
              if (isSupplier && supplierId) {
                resolvedSupplierId = supplierId;
              } else if (p.supplierId) {
                const supExists = await prisma.suppliers.findFirst({
                  where: { id: p.supplierId, business_id: businessId },
                });
                resolvedSupplierId = supExists ? supExists.id : null;
              } else if (existing?.supplier_id) {
                resolvedSupplierId = existing.supplier_id;
              } else {
                const defSup = await prisma.suppliers.findFirst({
                  where: { business_id: businessId, supplier_code: 'SUP-DEFAULT' },
                });
                resolvedSupplierId = defSup ? defSup.id : null;
              }

              const savedProduct = await prisma.products.upsert({
                where: {
                  business_id_id: {
                    business_id: businessId,
                    id: item.recordId,
                  },
                },
                update: {
                  category_id: resolvedCategoryId,
                  supplier_id: resolvedSupplierId,
                  name: p.name,
                  code: p.code,
                  description: p.description,
                  cost_price_paise: BigInt(p.costPricePaise ?? 0),
                  selling_price_paise: BigInt(p.sellingPricePaise),
                  gst_rate_percent: p.gstRatePercent ?? 0,
                  is_tax_inclusive: p.isTaxInclusive ?? true,
                  unit: p.unit ?? 'plate',
                  is_available: p.isAvailable ?? true,
                  deleted_at: null,
                },
                create: {
                  id: item.recordId,
                  business_id: businessId,
                  category_id: resolvedCategoryId,
                  supplier_id: resolvedSupplierId,
                  name: p.name,
                  code: p.code,
                  description: p.description,
                  cost_price_paise: BigInt(p.costPricePaise ?? 0),
                  selling_price_paise: BigInt(p.sellingPricePaise),
                  gst_rate_percent: p.gstRatePercent ?? 0,
                  is_tax_inclusive: p.isTaxInclusive ?? true,
                  unit: p.unit ?? 'plate',
                  is_available: p.isAvailable ?? true,
                },
              });
              results.push({
                recordId: item.recordId,
                status: 'synced',
                entity: 'products',
                serverVersion: savedProduct.server_version?.toString(),
              });
            } else if (item.operation === 'DELETE') {
              await prisma.products.updateMany({
                where: {
                  id: item.recordId,
                  business_id: businessId,
                  ...(isSupplier && supplierId ? { supplier_id: supplierId } : {}),
                },
                data: { deleted_at: new Date(), is_available: false },
              });
              results.push({ recordId: item.recordId, status: 'synced', entity: 'products' });
            }
            break;
          }
          case 'categories': {
            if (isSupplier) {
              results.push({
                recordId: item.recordId,
                status: 'error',
                error: 'Forbidden: Suppliers cannot manage categories.',
              });
              continue;
            }
            const p = item.payload;
            const safeColor = p.colorValue !== undefined && p.colorValue !== null ? (Number(p.colorValue) | 0) : null;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              const savedCat = await prisma.categories.upsert({
                where: {
                  business_id_id: {
                    business_id: businessId,
                    id: item.recordId,
                  },
                },
                update: {
                  name: p.name,
                  icon: p.icon,
                  color_value: safeColor,
                  is_active: p.isActive ?? true,
                  display_order: p.displayOrder ?? 0,
                  deleted_at: null,
                },
                create: {
                  id: item.recordId,
                  business_id: businessId,
                  name: p.name,
                  icon: p.icon,
                  color_value: safeColor,
                  is_active: p.isActive ?? true,
                  display_order: p.displayOrder ?? 0,
                },
              });
              results.push({
                recordId: item.recordId,
                status: 'synced',
                entity: 'categories',
                serverVersion: savedCat.server_version?.toString(),
              });
            } else if (item.operation === 'DELETE') {
              await prisma.categories.updateMany({
                where: { id: item.recordId, business_id: businessId },
                data: { deleted_at: new Date(), is_active: false },
              });
              results.push({ recordId: item.recordId, status: 'synced', entity: 'categories' });
            }
            break;
          }
          case 'dining_tables': {
            const p = item.payload;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              await prisma.dining_tables.upsert({
                where: { id: item.recordId },
                update: {
                  table_name: p.tableName,
                  seating_capacity: p.seatingCapacity ?? 4,
                  is_occupied: p.isOccupied ?? false,
                  current_invoice_id: p.currentInvoiceId,
                },
                create: {
                  id: item.recordId,
                  business_id: businessId,
                  table_name: p.tableName,
                  seating_capacity: p.seatingCapacity ?? 4,
                  is_occupied: p.isOccupied ?? false,
                  current_invoice_id: p.currentInvoiceId,
                },
              });
              results.push({ recordId: item.recordId, status: 'synced', entity: 'dining_tables' });
            }
            break;
          }
          case 'orders': {
            const p = item.payload;
            if (item.operation === 'INSERT') {
              const ord = await ordersService.createOrder(
                businessId,
                authUser?.userId || randomUUID(),
                effectiveDeviceId,
                p as any
              );
              results.push({ recordId: item.recordId, status: 'synced', entity: 'orders', orderId: ord.order.id });
            }
            break;
          }
          case 'invoices': {
            const p = item.payload;
            if (item.operation === 'INSERT') {
              const inv = await invoicesService.createInvoice(
                businessId,
                p.cashierId,
                p.cashierName,
                p as any
              );
              results.push({ recordId: item.recordId, status: 'synced', entity: 'invoices', invoiceId: inv?.id || item.recordId });
            } else if (item.operation === 'UPDATE') {
              const existing = await prisma.invoices.findFirst({
                where: { id: item.recordId, business_id: businessId },
              });
              if (existing) {
                const paidBig = p.paidAmountPaise != null ? BigInt(p.paidAmountPaise) : existing.paid_amount_paise;
                const updatedInv = await prisma.invoices.update({
                  where: { id: item.recordId },
                  data: {
                    order_status: p.orderStatus || existing.order_status,
                    payment_status: p.paymentStatus || existing.payment_status,
                    paid_amount_paise: paidBig,
                  },
                });
                if (existing.order_id) {
                  const grandTotalBig = existing.grand_total_paise;
                  const balanceDueBig = grandTotalBig > paidBig ? grandTotalBig - paidBig : 0n;
                  await prisma.orders.update({
                    where: { id: existing.order_id },
                    data: {
                      order_status: p.orderStatus || undefined,
                      payment_status: p.paymentStatus || undefined,
                      amount_paid_paise: paidBig,
                      balance_due_paise: balanceDueBig,
                    },
                  }).catch(() => {});
                }
                results.push({ recordId: item.recordId, status: 'synced', entity: 'invoices', invoiceId: updatedInv.id });
              } else if (p.items && p.subtotalPaise != null) {
                const inv = await invoicesService.createInvoice(
                  businessId,
                  p.cashierId,
                  p.cashierName,
                  p as any
                );
                results.push({ recordId: item.recordId, status: 'synced', entity: 'invoices', invoiceId: inv?.id || item.recordId });
              } else {
                results.push({ recordId: item.recordId, status: 'synced', entity: 'invoices', invoiceId: item.recordId });
              }
            }
            break;
          }
          case 'payments': {
            const p = item.payload;
            if (item.operation === 'INSERT') {
              const pay = await paymentsService.recordPayment(businessId, p as any);
              results.push({ recordId: item.recordId, status: 'synced', entity: 'payments', paymentId: pay?.id || item.recordId });
            }
            break;
          }
          case 'purchase_orders': {
            const p = item.payload;
            if (item.operation === 'INSERT') {
              const po = await purchasesService.createPurchaseOrder(businessId, authUser?.userId || randomUUID(), p as any);
              results.push({ recordId: item.recordId, status: 'synced', entity: 'purchase_orders', poId: po.order.id });
            }
            break;
          }
          case 'purchase_invoices': {
            const p = item.payload;
            if (item.operation === 'INSERT') {
              try {
                const pi = await purchasesService.createPurchaseInvoice(businessId, p as any, isSupplier ? supplierId : undefined);
                results.push({ recordId: item.recordId, status: 'synced', entity: 'purchase_invoices', piId: pi.invoice.id });
              } catch (e: any) {
                if (e.statusCode === 409 || e.message?.includes('already submitted')) {
                  const existingPi = await prisma.purchase_invoices.findFirst({
                    where: { business_id: businessId, supplier_invoice_number: p.supplierInvoiceNumber },
                  });
                  results.push({ recordId: item.recordId, status: 'synced', entity: 'purchase_invoices', piId: existingPi?.id || item.recordId });
                } else {
                  throw e;
                }
              }
            }
            break;
          }
          case 'supplier_payments': {
            if (isSupplier) {
              results.push({
                recordId: item.recordId,
                status: 'error',
                error: 'Forbidden: Suppliers cannot record supplier payments.',
              });
              continue;
            }
            const p = item.payload;
            if (item.operation === 'INSERT') {
              const sp = await purchasesService.recordSupplierPayment(businessId, authUser?.userId || randomUUID(), p as any);
              results.push({ recordId: item.recordId, status: 'synced', entity: 'supplier_payments', paymentId: sp.id });
            }
            break;
          }
          case 'kot_records': {
            const p = item.payload;
            if (item.operation === 'INSERT') {
              const kot = await kotService.createKot(businessId, p as any);
              results.push({ recordId: item.recordId, status: 'synced', entity: 'kot_records', kotId: kot?.id || item.recordId });
            }
            break;
          }
          default:
            results.push({ recordId: item.recordId, status: 'ignored_unsupported' });
            break;
        }
      } catch (err: any) {
        logger.error(`[SyncPushError] Business=${businessId} Entity=${item.entityName} ID=${item.recordId} Error=${err.message}`, {
          stack: err.stack,
          payload: item.payload,
        });
        results.push({ recordId: item.recordId, status: 'error', error: err.message });
      }
    }

    return { processed: results.length, results };
  }

  async getSyncStatus(businessId: string) {
    const cursor = await prisma.business_sync_cursors.findUnique({
      where: { business_id: businessId },
    });
    const totalChanges = await prisma.sync_change_log.count({
      where: { business_id: businessId },
    });

    return {
      businessId,
      latestCursor: cursor ? cursor.last_cursor.toString() : '0',
      totalChangesLogged: totalChanges,
      updatedAt: cursor?.updated_at,
    };
  }
}

export const syncService = new SyncService();
