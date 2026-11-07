import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/database/app_database.dart';

class ProcurementPdfGenerator {
  /// Loads Roboto fonts for Unicode Indian Rupee (₹) symbol support
  static Future<pw.ThemeData?> _loadTheme() async {
    try {
      final regular = await PdfGoogleFonts.robotoRegular();
      final bold = await PdfGoogleFonts.robotoBold();
      if (regular.fontName.toLowerCase().contains('helvetica')) {
        return null;
      }
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      return null;
    }
  }

  /// Formats currency with ₹ if Unicode font is active, otherwise Rs.
  static String formatAmount(int paise, {required bool hasUnicodeFont, bool showSymbol = true}) {
    if (!showSymbol) {
      return CurrencyFormatter.formatPaise(paise, showSymbol: false);
    }
    if (hasUnicodeFont) {
      return CurrencyFormatter.formatPaise(paise, showSymbol: true);
    } else {
      return 'Rs. ${CurrencyFormatter.formatPaise(paise, showSymbol: false)}';
    }
  }

  // ===========================================================================
  // 1. PURCHASE ORDER PDF (Admin to Supplier)
  // ===========================================================================
  static Future<Uint8List> generatePurchaseOrderPdf({
    required PurchaseOrderEntry order,
    required List<PurchaseOrderItemEntry> items,
    required SupplierEntry supplier,
    required Map<String, String> settings,
  }) async {
    final theme = await _loadTheme();
    final hasUnicodeFont = theme != null;
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final address = settings['business_address']?.trim() ?? '';
    final phone = settings['business_phone']?.trim() ?? '';
    final gstin = settings['business_gstin']?.trim() ?? '';

    final dateFormat = DateFormat('dd-MM-yyyy');
    final orderedDateStr = dateFormat.format(order.orderedAt);
    final deliveryDateStr = order.expectedDeliveryDate != null
        ? dateFormat.format(order.expectedDeliveryDate!)
        : 'Immediate';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    if (phone.isNotEmpty) pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue800,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text('PURCHASE ORDER', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('PO Number: ${order.poNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Order Date: $orderedDateStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Expected Delivery: $deliveryDateStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Status: ${order.orderStatus}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            // Vendor / Supplier Details Box
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('VENDOR / SUPPLIER DETAILS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        pw.Text(supplier.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                          pw.Text('Attn: ${supplier.contactPerson}', style: const pw.TextStyle(fontSize: 10)),
                        if (supplier.phone != null && supplier.phone!.isNotEmpty)
                          pw.Text('Phone: ${supplier.phone}', style: const pw.TextStyle(fontSize: 10)),
                        if (supplier.email != null && supplier.email!.isNotEmpty)
                          pw.Text('Email: ${supplier.email}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TAX & ADDRESS', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 4),
                        if (supplier.gstin != null && supplier.gstin!.isNotEmpty)
                          pw.Text('GSTIN: ${supplier.gstin}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        if (supplier.address != null && supplier.address!.isNotEmpty)
                          pw.Text('Address: ${supplier.address}', style: const pw.TextStyle(fontSize: 10)),
                        if (supplier.paymentTerms != null && supplier.paymentTerms!.isNotEmpty)
                          pw.Text('Terms: ${supplier.paymentTerms}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6), // S.No
                1: const pw.FlexColumnWidth(3.0), // Item Description
                2: const pw.FlexColumnWidth(1.0), // Qty
                3: const pw.FlexColumnWidth(1.2), // Rate
                4: const pw.FlexColumnWidth(1.0), // GST %
                5: const pw.FlexColumnWidth(1.4), // Taxable
                6: const pw.FlexColumnWidth(1.4), // Total
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                  children: [
                    _tableCell('#', isHeader: true, align: pw.TextAlign.center),
                    _tableCell('Item Description', isHeader: true),
                    _tableCell('Qty', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Rate', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('GST %', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Taxable', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final qtyStr = item.quantity.truncateToDouble() == item.quantity
                      ? '${item.quantity.toInt()} ${item.unit}'
                      : '${item.quantity.toStringAsFixed(1)} ${item.unit}';

                  return pw.TableRow(
                    children: [
                      _tableCell('$idx', align: pw.TextAlign.center),
                      _tableCell('${item.productName}${item.productCode != null ? " (${item.productCode})" : ""}'),
                      _tableCell(qtyStr, align: pw.TextAlign.right),
                      _tableCell(formatAmount(item.unitPricePaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                      _tableCell('${item.gstRatePercent.toStringAsFixed(0)}%', align: pw.TextAlign.right),
                      _tableCell(formatAmount(item.taxableAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                      _tableCell(formatAmount(item.totalAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Totals Section
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal Taxable:', formatAmount(order.subtotalPaise, hasUnicodeFont: hasUnicodeFont)),
                      if (order.taxPaise > 0)
                        _summaryRow('Total GST Tax:', formatAmount(order.taxPaise, hasUnicodeFont: hasUnicodeFont)),
                      pw.Divider(color: PdfColors.grey400),
                      _summaryRow('GRAND TOTAL:', formatAmount(order.grandTotalPaise, hasUnicodeFont: hasUnicodeFont), isBold: true, fontSize: 13),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
              pw.Text('Special Instructions / Notes:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(order.notes!.trim(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
              pw.SizedBox(height: 20),
            ],

            // Signature Blocks
            pw.Spacer(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Authorized Store Signatory', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(width: 140, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Vendor Acceptance & Seal', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ===========================================================================
  // 2. SUPPLIER PURCHASE INVOICE RECORD PDF
  // ===========================================================================
  static Future<Uint8List> generatePurchaseInvoicePdf({
    required PurchaseInvoiceEntry invoice,
    required List<PurchaseInvoiceItemEntry> items,
    required SupplierEntry supplier,
    required Map<String, String> settings,
  }) async {
    final theme = await _loadTheme();
    final hasUnicodeFont = theme != null;
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final dateFormat = DateFormat('dd-MM-yyyy');
    final invoiceDateStr = dateFormat.format(invoice.invoiceDate);
    final dueDateStr = invoice.dueDate != null ? dateFormat.format(invoice.dueDate!) : 'N/A';

    final isApproved = invoice.verificationStatus == 'APPROVED';
    final isRejected = invoice.verificationStatus == 'REJECTED';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.Text('PURCHASE INVOICE RECORD', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: isApproved ? PdfColors.green700 : (isRejected ? PdfColors.red700 : PdfColors.orange700),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        invoice.verificationStatus,
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: $invoiceDateStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Due Date: $dueDateStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Payment: ${invoice.paymentStatus}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey300),

            // Vendor Info
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SUPPLIER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                      pw.Text(supplier.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      if (supplier.phone != null) pw.Text('Phone: ${supplier.phone}', style: const pw.TextStyle(fontSize: 9)),
                      if (supplier.gstin != null) pw.Text('GSTIN: ${supplier.gstin}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  if (invoice.rejectionReason != null && isRejected)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(color: PdfColors.red50, borderRadius: pw.BorderRadius.circular(4)),
                      child: pw.Text('Rejection: ${invoice.rejectionReason}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red800)),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Items Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(0.6),
                1: const pw.FlexColumnWidth(3.0),
                2: const pw.FlexColumnWidth(1.0),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FlexColumnWidth(1.0),
                5: const pw.FlexColumnWidth(1.4),
                6: const pw.FlexColumnWidth(1.4),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _tableCell('#', isHeader: true, align: pw.TextAlign.center),
                    _tableCell('Item', isHeader: true),
                    _tableCell('Qty', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Rate', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('GST %', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Taxable', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...items.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final item = entry.value;
                  final qtyStr = item.quantity.truncateToDouble() == item.quantity
                      ? '${item.quantity.toInt()} ${item.unit}'
                      : '${item.quantity.toStringAsFixed(1)} ${item.unit}';

                  return pw.TableRow(
                    children: [
                      _tableCell('$idx', align: pw.TextAlign.center),
                      _tableCell(item.productName),
                      _tableCell(qtyStr, align: pw.TextAlign.right),
                      _tableCell(formatAmount(item.unitPricePaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                      _tableCell('${item.gstRatePercent.toStringAsFixed(0)}%', align: pw.TextAlign.right),
                      _tableCell(formatAmount(item.taxableAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                      _tableCell(formatAmount(item.totalAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 12),

            // Financial Summary
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Container(
                  width: 230,
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal:', formatAmount(invoice.subtotalPaise, hasUnicodeFont: hasUnicodeFont)),
                      if (invoice.taxPaise > 0)
                        _summaryRow('Tax Amount:', formatAmount(invoice.taxPaise, hasUnicodeFont: hasUnicodeFont)),
                      if (invoice.discountPaise > 0)
                        _summaryRow('Discount:', '-${formatAmount(invoice.discountPaise, hasUnicodeFont: hasUnicodeFont)}'),
                      pw.Divider(color: PdfColors.grey400),
                      _summaryRow('GRAND TOTAL:', formatAmount(invoice.grandTotalPaise, hasUnicodeFont: hasUnicodeFont), isBold: true),
                      _summaryRow('Amount Paid:', formatAmount(invoice.amountPaidPaise, hasUnicodeFont: hasUnicodeFont)),
                      _summaryRow('BALANCE DUE:', formatAmount(invoice.balanceDuePaise, hasUnicodeFont: hasUnicodeFont), isBold: true, fontSize: 12),
                    ],
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ===========================================================================
  // 3. SUPPLIER PAYMENT VOUCHER PDF
  // ===========================================================================
  static Future<Uint8List> generateSupplierPaymentVoucherPdf({
    required SupplierPaymentEntry payment,
    required SupplierEntry supplier,
    required PurchaseInvoiceEntry invoice,
    required Map<String, String> settings,
  }) async {
    final theme = await _loadTheme();
    final hasUnicodeFont = theme != null;
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');
    final paymentDateStr = dateFormat.format(payment.paymentDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(businessName, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
                      pw.Text('ACCOUNTS PAYABLE DISBURSEMENT', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: pw.BoxDecoration(color: PdfColors.teal800, borderRadius: pw.BorderRadius.circular(6)),
                    child: pw.Text('PAYMENT VOUCHER', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1.5, color: PdfColors.grey400),
              pw.SizedBox(height: 12),

              // Voucher Meta
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Voucher No: ${payment.paymentVoucherNumber}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date & Time: $paymentDateStr', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Payment Mode: ${payment.paymentMethod}', style: const pw.TextStyle(fontSize: 10)),
                        if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty)
                          pw.Text('Ref / UTR #: ${payment.referenceNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Beneficiary: ${supplier.name}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (supplier.phone != null) pw.Text('Phone: ${supplier.phone}', style: const pw.TextStyle(fontSize: 10)),
                        if (supplier.gstin != null) pw.Text('GSTIN: ${supplier.gstin}', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Against Invoice: ${invoice.invoiceNumber}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Amount Card
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.teal300, width: 1.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('AMOUNT PAID', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      formatAmount(payment.amountPaise, hasUnicodeFont: hasUnicodeFont),
                      style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Invoice Impact Table
              pw.Text('SETTLEMENT DETAILS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableCell('Total Invoice Liability', isHeader: true),
                      _tableCell('Disbursed Amount', isHeader: true),
                      _tableCell('Remaining Balance', isHeader: true),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      _tableCell(formatAmount(invoice.grandTotalPaise, hasUnicodeFont: hasUnicodeFont), align: pw.TextAlign.center),
                      _tableCell(formatAmount(payment.amountPaise, hasUnicodeFont: hasUnicodeFont), align: pw.TextAlign.center),
                      _tableCell(formatAmount(invoice.balanceDuePaise, hasUnicodeFont: hasUnicodeFont), align: pw.TextAlign.center),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              if (payment.notes != null && payment.notes!.trim().isNotEmpty) ...[
                pw.Text('Notes / Remarks:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.Text(payment.notes!.trim(), style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                pw.SizedBox(height: 16),
              ],

              pw.Spacer(),

              // Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Disbursed / Authorized By', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Beneficiary Receiver Signature', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  // ===========================================================================
  // 4. SUPPLIER ACCOUNT STATEMENT PDF (Ledger Statement)
  // ===========================================================================
  static Future<Uint8List> generateSupplierAccountStatementPdf({
    required SupplierEntry supplier,
    required List<Map<String, dynamic>> ledgerEntries,
    required int totalInvoicedPaise,
    required int totalPaidPaise,
    required int balanceDuePaise,
    required Map<String, String> settings,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final theme = await _loadTheme();
    final hasUnicodeFont = theme != null;
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final dateFormat = DateFormat('dd-MM-yyyy');
    final periodStr = (fromDate != null && toDate != null)
        ? '${dateFormat.format(fromDate)} to ${dateFormat.format(toDate)}'
        : 'All Time';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(businessName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey800)),
                    pw.Text('SUPPLIER ACCOUNT STATEMENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                    pw.Text('Period: $periodStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(supplier.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    if (supplier.contactPerson != null) pw.Text('Contact: ${supplier.contactPerson}', style: const pw.TextStyle(fontSize: 10)),
                    if (supplier.phone != null) pw.Text('Phone: ${supplier.phone}', style: const pw.TextStyle(fontSize: 10)),
                    if (supplier.gstin != null) pw.Text('GSTIN: ${supplier.gstin}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 8),

            // Summary cards
            pw.Row(
              children: [
                _statCard('Total Billed', formatAmount(totalInvoicedPaise, hasUnicodeFont: hasUnicodeFont), PdfColors.blueGrey50),
                pw.SizedBox(width: 8),
                _statCard('Total Paid', formatAmount(totalPaidPaise, hasUnicodeFont: hasUnicodeFont), PdfColors.teal50),
                pw.SizedBox(width: 8),
                _statCard('Net Outstanding', formatAmount(balanceDuePaise, hasUnicodeFont: hasUnicodeFont), PdfColors.amber50, isAlert: balanceDuePaise > 0),
              ],
            ),
            pw.SizedBox(height: 16),

            // Ledger Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2), // Date
                1: const pw.FlexColumnWidth(1.0), // Type
                2: const pw.FlexColumnWidth(1.5), // Ref #
                3: const pw.FlexColumnWidth(1.2), // Invoiced (Credit)
                4: const pw.FlexColumnWidth(1.2), // Paid (Debit)
                5: const pw.FlexColumnWidth(1.2), // Balance
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
                  children: [
                    _tableCell('Date', isHeader: true),
                    _tableCell('Type', isHeader: true),
                    _tableCell('Doc / Ref #', isHeader: true),
                    _tableCell('Billed (+)', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Paid (-)', isHeader: true, align: pw.TextAlign.right),
                    _tableCell('Balance', isHeader: true, align: pw.TextAlign.right),
                  ],
                ),
                ...ledgerEntries.map((e) {
                  final dt = e['date'] is DateTime ? e['date'] as DateTime : DateTime.tryParse(e['date'].toString()) ?? DateTime.now();
                  final type = e['type']?.toString() ?? 'Invoice';
                  final docNum = e['documentNumber']?.toString() ?? e['refNumber']?.toString() ?? '-';
                  final billed = e['billedPaise'] as int? ?? 0;
                  final paid = e['paidPaise'] as int? ?? 0;
                  final balance = e['balancePaise'] as int? ?? 0;

                  return pw.TableRow(
                    children: [
                      _tableCell(dateFormat.format(dt)),
                      _tableCell(type),
                      _tableCell(docNum),
                      _tableCell(billed > 0 ? formatAmount(billed, hasUnicodeFont: hasUnicodeFont, showSymbol: false) : '-', align: pw.TextAlign.right),
                      _tableCell(paid > 0 ? formatAmount(paid, hasUnicodeFont: hasUnicodeFont, showSymbol: false) : '-', align: pw.TextAlign.right),
                      _tableCell(formatAmount(balance, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  // ===========================================================================
  // 5. SALES PAYMENT RECEIPT PDF
  // ===========================================================================
  static Future<Uint8List> generateCustomerPaymentReceiptPdf({
    required InvoiceEntry invoice,
    required PaymentEntry payment,
    required Map<String, String> settings,
  }) async {
    final theme = await _loadTheme();
    final hasUnicodeFont = theme != null;
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final address = settings['business_address']?.trim() ?? '';
    final phone = settings['business_phone']?.trim() ?? '';
    final gstin = settings['business_gstin']?.trim() ?? '';

    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');
    final paymentDateStr = dateFormat.format(payment.createdAt);

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(businessName, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center),
              if (phone.isNotEmpty) pw.Text('Ph: $phone', style: const pw.TextStyle(fontSize: 9)),
              if (gstin.isNotEmpty) pw.Text('GSTIN: $gstin', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1),
              pw.Text('PAYMENT RECEIPT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice #: ${invoice.invoiceNumber}', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(paymentDateStr, style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (invoice.customerName != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text('Customer: ${invoice.customerName}', style: const pw.TextStyle(fontSize: 9)),
                ),
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Text('AMOUNT RECEIVED', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text(
                formatAmount(payment.amountPaise, hasUnicodeFont: hasUnicodeFont),
                style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Method: ${payment.paymentMethod}', style: const pw.TextStyle(fontSize: 9)),
              if (payment.referenceNumber != null && payment.referenceNumber!.isNotEmpty)
                pw.Text('Ref: ${payment.referenceNumber}', style: const pw.TextStyle(fontSize: 8)),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Bill:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(formatAmount(invoice.grandTotalPaise, hasUnicodeFont: hasUnicodeFont), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Paid:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(formatAmount(invoice.paidAmountPaise, hasUnicodeFont: hasUnicodeFont), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              if (invoice.grandTotalPaise > invoice.paidAmountPaise)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Balance Due:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      formatAmount(invoice.grandTotalPaise - invoice.paidAmountPaise, hasUnicodeFont: hasUnicodeFont),
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              pw.Divider(),
              pw.Text('Thank you for your payment!', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            ],
          );
        },
      ),
    );

    return await pdf.save();
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static pw.Widget _tableCell(String text, {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, {bool isBold = false, double fontSize = 10}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _statCard(String label, String value, PdfColor bg, {bool isAlert = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: isAlert ? PdfColors.amber600 : PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: isAlert ? PdfColors.amber900 : PdfColors.blueGrey900)),
          ],
        ),
      ),
    );
  }
}
