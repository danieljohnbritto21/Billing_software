import { randomUUID } from 'crypto';
import { prisma } from '../../config/prisma';
import { SyncPullQuery, SyncPushBody } from './sync.schema';
import { invoicesService } from '../invoices/invoices.service';
import { paymentsService } from '../payments/payments.service';
import { kotService } from '../kot/kot.service';

export class SyncService {
  async pullChanges(businessId: string, deviceId: string | undefined, query: SyncPullQuery) {
    const clientCursor = BigInt(query.cursor);
    const limit = query.limit;

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

    // 3. Hydrate records
    const changes: any[] = [];
    let nextCursor = clientCursor;

    for (const entry of changeLogs) {
      nextCursor = entry.cursor; // Advance only to what is included

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
          break;
        case 'products':
          data = await prisma.products.findFirst({
            where: { id: entry.record_id, business_id: businessId },
          });
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
        case 'business_settings':
          data = await prisma.business_settings.findFirst({
            where: { id: entry.record_id, business_id: businessId },
          });
          break;
        default:
          break;
      }

      // If record was permanently removed or not found, mark as DELETE
      if (!data) {
        changes.push({
          cursor: entry.cursor,
          entityName: entry.entity_name,
          recordId: entry.record_id,
          operation: 'DELETE',
          data: null,
          version: entry.record_version,
        });
      } else {
        changes.push({
          cursor: entry.cursor,
          entityName: entry.entity_name,
          recordId: entry.record_id,
          operation: entry.operation,
          data,
          version: entry.record_version,
        });
      }
    }

    // 4. Update device sync state if deviceId is provided
    if (deviceId && changeLogs.length > 0) {
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
      }).catch(() => {}); // non-blocking
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

  async pushChanges(businessId: string, data: SyncPushBody) {
    const results: any[] = [];

    for (const item of data.items) {
      try {
        switch (item.entityName) {
          case 'customers': {
            const p = item.payload;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              const customer = await prisma.customers.upsert({
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
          case 'products': {
            const p = item.payload;
            // Check conflict if updating
            const existing = await prisma.products.findFirst({
              where: { id: item.recordId, business_id: businessId },
            });
            if (existing && item.clientVersion !== undefined && existing.server_version && existing.server_version > BigInt(item.clientVersion)) {
              // Conflict detected!
              if (data.deviceId) {
                await prisma.sync_conflicts.create({
                  data: {
                    id: randomUUID(),
                    device_id: data.deviceId,
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
              await prisma.products.upsert({
                where: {
                  business_id_id: {
                    business_id: businessId,
                    id: item.recordId,
                  },
                },
                update: {
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
                create: {
                  id: item.recordId,
                  business_id: businessId,
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
              results.push({ recordId: item.recordId, status: 'synced', entity: 'products' });
            }
            break;
          }
          case 'categories': {
            const p = item.payload;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              await prisma.categories.upsert({
                where: {
                  business_id_id: {
                    business_id: businessId,
                    id: item.recordId,
                  },
                },
                update: {
                  name: p.name,
                  icon: p.icon,
                  color_value: p.colorValue,
                  is_active: p.isActive ?? true,
                  display_order: p.displayOrder ?? 0,
                },
                create: {
                  id: item.recordId,
                  business_id: businessId,
                  name: p.name,
                  icon: p.icon,
                  color_value: p.colorValue,
                  is_active: p.isActive ?? true,
                  display_order: p.displayOrder ?? 0,
                },
              });
              results.push({ recordId: item.recordId, status: 'synced', entity: 'categories' });
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
                where: {
                  id: item.recordId,
                },
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
          case 'invoices': {
            const p = item.payload;
            if (item.operation === 'INSERT' || item.operation === 'UPDATE') {
              const inv = await invoicesService.createInvoice(
                businessId,
                p.cashierId,
                p.cashierName,
                p as any
              );
              results.push({ recordId: item.recordId, status: 'synced', entity: 'invoices', invoiceId: inv?.id || item.recordId });
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
