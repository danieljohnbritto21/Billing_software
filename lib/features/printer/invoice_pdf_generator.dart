import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../invoices/invoice_repository.dart';
import '../settings/settings_repository.dart';

enum ReceiptFormat {
  thermal58mm,
  thermal80mm,
  a4Invoice,
}

class InvoicePdfGenerator {
  /// Loads Roboto fonts for Unicode Indian Rupee (₹) symbol support
  static Future<pw.ThemeData?> _loadTheme() async {
    try {
      final regular = await PdfGoogleFonts.robotoRegular();
      final bold = await PdfGoogleFonts.robotoBold();
      // If font failed to load over network, PdfGoogleFonts falls back to Helvetica (which lacks Unicode ₹)
      if (regular.fontName.toLowerCase().contains('helvetica')) {
        return null;
      }
      return pw.ThemeData.withFont(base: regular, bold: bold);
    } catch (_) {
      // Offline or headless test environment fallback
      return null;
    }
  }

  /// Formats currency with ₹ if Unicode font is active, otherwise Rs. for standard ASCII safety
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

  /// Automatically resolves printer paper format based on store settings
  static ReceiptFormat resolveFormat(Map<String, String> settings, [ReceiptFormat? requestedFormat]) {
    if (requestedFormat != null && requestedFormat != ReceiptFormat.thermal80mm) {
      return requestedFormat;
    }
    final width = settings[SettingsRepository.keyPrinterWidth] ?? settings['printer_width'];
    if (width == '58mm') {
      return ReceiptFormat.thermal58mm;
    }
    return requestedFormat ?? ReceiptFormat.thermal80mm;
  }

  /// Generates a PDF byte document for the final customer invoice receipt
  static Future<Uint8List> generate({
    required InvoiceDetails details,
    required Map<String, String> settings,
    ReceiptFormat? format,
  }) async {
    final effectiveFormat = resolveFormat(settings, format);
    final theme = await _loadTheme();
    final hasUnicodeFont = theme != null;
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final tagline = settings['business_tagline']?.trim() ?? '';
    final address = settings['business_address']?.trim() ?? '';
    final phone = settings['business_phone']?.trim() ?? '';
    final gstin = settings['business_gstin']?.trim() ?? '';
    final footerMsg = settings['receipt_footer']?.trim().isNotEmpty == true
        ? settings['receipt_footer']!.trim()
        : 'Thank you for visiting!';
    final showNote = settings['show_note_on_receipt'] != 'false';

    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');
    final formattedDate = dateFormat.format(details.invoice.createdAt);

    if (effectiveFormat == ReceiptFormat.a4Invoice) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) {
            return _buildA4Layout(
              details: details,
              businessName: businessName,
              tagline: tagline,
              address: address,
              phone: phone,
              gstin: gstin,
              footerMsg: footerMsg,
              showNote: showNote,
              formattedDate: formattedDate,
              hasUnicodeFont: hasUnicodeFont,
            );
          },
        ),
      );
    } else {
      final is58mm = effectiveFormat == ReceiptFormat.thermal58mm;
      final pageFormat = is58mm
          ? const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm)
          : const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return _buildThermalLayout(
              details: details,
              businessName: businessName,
              tagline: tagline,
              address: address,
              phone: phone,
              gstin: gstin,
              footerMsg: footerMsg,
              showNote: showNote,
              formattedDate: formattedDate,
              is58mm: is58mm,
              hasUnicodeFont: hasUnicodeFont,
            );
          },
        ),
      );
    }

    return await pdf.save();
  }

  /// Generates a Kitchen Order Ticket (KOT) PDF byte document without financial totals
  static Future<Uint8List> generateKot({
    required InvoiceDetails details,
    required Map<String, String> settings,
    ReceiptFormat? format,
  }) async {
    final effectiveFormat = resolveFormat(settings, format);
    final theme = await _loadTheme();
    final pdf = pw.Document(theme: theme);

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');
    final formattedDate = dateFormat.format(details.invoice.createdAt);

    final kotNumber = details.invoice.kotNumber != null && details.invoice.kotNumber!.trim().isNotEmpty
        ? details.invoice.kotNumber!.trim()
        : 'KOT-${details.invoice.invoiceNumber.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0')}';

    final is58mm = effectiveFormat == ReceiptFormat.thermal58mm;
    final pageFormat = is58mm
        ? const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity, marginAll: 3 * PdfPageFormat.mm)
        : const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return _buildThermalKot(
            details: details,
            businessName: businessName,
            kotNumber: kotNumber,
            formattedDate: formattedDate,
            is58mm: is58mm,
          );
        },
      ),
    );

    return await pdf.save();
  }

  /// Builds the dedicated Kitchen Order Ticket (KOT) strictly adhering to kitchen preparation needs
  static pw.Widget _buildThermalKot({
    required InvoiceDetails details,
    required String businessName,
    required String kotNumber,
    required String formattedDate,
    required bool is58mm,
  }) {
    final titleSize = is58mm ? 12.0 : 15.0;
    final headerSize = is58mm ? 9.5 : 11.5;
    final textSize = is58mm ? 8.5 : 10.0;
    final itemSize = is58mm ? 9.0 : 11.0;
    final qtySize = is58mm ? 10.0 : 12.0;
    final smallSize = is58mm ? 7.5 : 8.5;

    final isDineIn = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDineIn.toLowerCase();
    final hasTable = details.invoice.tableNumber != null && details.invoice.tableNumber!.trim().isNotEmpty;
    final hasCustomerName = details.invoice.customerName != null && details.invoice.customerName!.trim().isNotEmpty;
    final hasInstructions = details.billNote != null && details.billNote!.note.trim().isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // 1. KOT Title & Restaurant Header
        pw.Text(
          businessName.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'KITCHEN ORDER TICKET',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),

        // 2. KOT Order Meta Block
        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
        pw.SizedBox(height: 2),

        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('KOT No: $kotNumber', style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Order No: ${details.invoice.invoiceNumber}', style: pw.TextStyle(fontSize: textSize)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text('Date: $formattedDate', style: pw.TextStyle(fontSize: smallSize)),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Order Type: ${details.invoice.orderType.toUpperCase()}',
                    style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold),
                  ),
                  if (isDineIn && hasTable)
                    pw.Text(
                      'Table: ${details.invoice.tableNumber!.replaceAll(RegExp(r'table\s*', caseSensitive: false), '').trim()}',
                      style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold),
                    ),
                ],
              ),
              if (hasCustomerName) ...[
                pw.SizedBox(height: 2),
                pw.Text('Customer: ${details.invoice.customerName!.trim()}', style: pw.TextStyle(fontSize: smallSize)),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 3),
        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 3. Items Header & Line Items Table
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(7.0),
            1: const pw.FlexColumnWidth(3.0),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('ITEM', style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('QTY', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            ...details.items.map((item) {
              final qtyStr = item.quantity % 1 == 0
                  ? item.quantity.toInt().toString()
                  : item.quantity.toString();
              final unitLabel = (item.unit.isNotEmpty && item.unit.toLowerCase() != 'plate')
                  ? ' (${item.unit})'
                  : '';

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Text(
                      '${item.productName}$unitLabel',
                      style: pw.TextStyle(fontSize: itemSize, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2.5),
                    child: pw.Text(
                      qtyStr,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(fontSize: qtySize, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 4. Special Instructions (Only if provided)
        if (hasInstructions) ...[
          pw.SizedBox(height: 3),
          pw.Align(
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Special Instructions:',
                  style: pw.TextStyle(fontSize: smallSize, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  details.billNote!.note.trim(),
                  style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
        ],

        pw.SizedBox(height: 8),
      ],
    );
  }

  /// Builds professional thermal customer receipt with exact GST, items, and payments
  static pw.Widget _buildThermalLayout({
    required InvoiceDetails details,
    required String businessName,
    required String tagline,
    required String address,
    required String phone,
    required String gstin,
    required String footerMsg,
    required bool showNote,
    required String formattedDate,
    required bool is58mm,
    required bool hasUnicodeFont,
  }) {
    final titleSize = is58mm ? 12.0 : 15.0;
    final headerSize = is58mm ? 8.5 : 10.0;
    final textSize = is58mm ? 8.0 : 9.0;
    final smallSize = is58mm ? 7.0 : 8.0;

    final isDineIn = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDineIn.toLowerCase();
    final hasTable = details.invoice.tableNumber != null && details.invoice.tableNumber!.trim().isNotEmpty;
    final hasCustomerName = details.invoice.customerName != null && details.invoice.customerName!.trim().isNotEmpty;
    final hasCustomerPhone = details.invoice.customerPhone != null && details.invoice.customerPhone!.trim().isNotEmpty;
    final isDelivery = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDelivery.toLowerCase();
    final hasDeliveryAddress = details.invoice.deliveryAddress != null && details.invoice.deliveryAddress!.trim().isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // 1. Restaurant Header
        pw.Text(
          businessName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
        ),
        if (tagline.isNotEmpty)
          pw.Text(tagline, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: smallSize)),
        if (address.isNotEmpty)
          pw.Text(address, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: smallSize)),
        if (phone.isNotEmpty)
          pw.Text('Ph: $phone', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: smallSize)),
        if (gstin.isNotEmpty)
          pw.Text('GSTIN: $gstin',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: smallSize, fontWeight: pw.FontWeight.bold)),

        pw.SizedBox(height: 3),
        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 2. Bill Details
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Invoice No: ${details.invoice.invoiceNumber}',
                      style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold)),
                  pw.Text(details.invoice.orderType.toUpperCase(),
                      style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 1.5),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: $formattedDate', style: pw.TextStyle(fontSize: smallSize)),
                  if (isDineIn && hasTable)
                    pw.Text('Table: ${details.invoice.tableNumber!.trim()}',
                        style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (hasCustomerName) ...[
                pw.SizedBox(height: 1.5),
                pw.Text('Customer: ${details.invoice.customerName!.trim()}', style: pw.TextStyle(fontSize: smallSize)),
              ],
              if (hasCustomerPhone) ...[
                pw.SizedBox(height: 1),
                pw.Text('Phone: ${details.invoice.customerPhone!.trim()}', style: pw.TextStyle(fontSize: smallSize)),
              ],
              if (isDelivery && hasDeliveryAddress) ...[
                pw.SizedBox(height: 1),
                pw.Text('Delivery: ${details.invoice.deliveryAddress!.trim()}', style: pw.TextStyle(fontSize: smallSize)),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 3),
        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 3. Items Table
        pw.Table(
          columnWidths: {
            0: const pw.FlexColumnWidth(4.5), // Item
            1: const pw.FlexColumnWidth(1.2), // Qty
            2: const pw.FlexColumnWidth(2.1), // Rate
            3: const pw.FlexColumnWidth(2.2), // Amount
          },
          children: [
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('Item', style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('Qty', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('Rate', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: headerSize, fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            ...details.items.map((item) {
              final qtyStr = item.quantity % 1 == 0
                  ? item.quantity.toInt().toString()
                  : item.quantity.toString();
              final rateStr = formatAmount(item.unitPricePaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false);
              final amtStr = formatAmount(item.totalAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false);

              return pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Text(item.productName, style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Text(qtyStr, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: textSize)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Text(rateStr, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: textSize)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
                    child: pw.Text(amtStr, textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: textSize, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              );
            }),
          ],
        ),

        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 4. Tax & Totals Breakdown
        _thermalSummaryRow('Subtotal', details.invoice.subtotalPaise, textSize, hasUnicodeFont),
        if (details.invoice.itemDiscountTotalPaise > 0)
          _thermalSummaryRow('Item Discount', -details.invoice.itemDiscountTotalPaise, smallSize, hasUnicodeFont),
        if (details.invoice.billDiscountPaise > 0)
          _thermalSummaryRow('Bill Discount', -details.invoice.billDiscountPaise, smallSize, hasUnicodeFont),
        if (details.invoice.cgstPaise > 0 || details.invoice.sgstPaise > 0)
          _thermalSummaryRow('Taxable Value', details.invoice.taxableAmountPaise, smallSize, hasUnicodeFont),
        if (details.invoice.cgstPaise > 0)
          _thermalSummaryRow('CGST', details.invoice.cgstPaise, smallSize, hasUnicodeFont),
        if (details.invoice.sgstPaise > 0)
          _thermalSummaryRow('SGST', details.invoice.sgstPaise, smallSize, hasUnicodeFont),
        if (details.invoice.roundOffPaise != 0)
          _thermalSummaryRow('Round Off', details.invoice.roundOffPaise, smallSize, hasUnicodeFont),

        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 5. Grand Total
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('GRAND TOTAL', style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold)),
              pw.Text(
                formatAmount(details.invoice.grandTotalPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: true),
                style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),

        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

        // 6. Payment Summary
        _thermalSummaryRow('Payment Method', null, textSize, hasUnicodeFont, customValue: details.invoice.paymentMethod),
        _thermalSummaryRow('Amount Paid', details.invoice.paidAmountPaise, textSize, hasUnicodeFont),
        if (details.invoice.grandTotalPaise > details.invoice.paidAmountPaise)
          _thermalSummaryRow(
            'BALANCE DUE',
            details.invoice.grandTotalPaise - details.invoice.paidAmountPaise,
            textSize,
            hasUnicodeFont,
            isBold: true,
          ),
        _thermalSummaryRow('Payment Status', null, textSize, hasUnicodeFont, customValue: details.invoice.paymentStatus.toUpperCase(), isBold: true),

        // 7. Bill Note (If present)
        if (showNote && details.billNote != null && details.billNote!.note.trim().isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(3.5),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Note:', style: pw.TextStyle(fontSize: smallSize, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 1),
                pw.Text(details.billNote!.note.trim(), style: pw.TextStyle(fontSize: textSize)),
              ],
            ),
          ),
        ],

        pw.SizedBox(height: 3),
        pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
        pw.SizedBox(height: 2),

        // 8. Footer
        pw.Text(footerMsg, textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: smallSize)),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _thermalSummaryRow(
    String label,
    int? amountPaise,
    double fontSize,
    bool hasUnicodeFont, {
    String? customValue,
    bool isBold = false,
  }) {
    final valueText = customValue ?? (amountPaise != null ? formatAmount(amountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false) : '');

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
          pw.Text(
            valueText,
            style: pw.TextStyle(fontSize: fontSize, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  /// Builds professional A4 invoice layout
  static pw.Widget _buildA4Layout({
    required InvoiceDetails details,
    required String businessName,
    required String tagline,
    required String address,
    required String phone,
    required String gstin,
    required String footerMsg,
    required bool showNote,
    required String formattedDate,
    required bool hasUnicodeFont,
  }) {
    final isDineIn = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDineIn.toLowerCase();
    final hasTable = details.invoice.tableNumber != null && details.invoice.tableNumber!.trim().isNotEmpty;
    final hasCustomerName = details.invoice.customerName != null && details.invoice.customerName!.trim().isNotEmpty;
    final hasCustomerPhone = details.invoice.customerPhone != null && details.invoice.customerPhone!.trim().isNotEmpty;
    final isDelivery = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDelivery.toLowerCase();
    final hasDeliveryAddress = details.invoice.deliveryAddress != null && details.invoice.deliveryAddress!.trim().isNotEmpty;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  businessName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green900,
                  ),
                ),
                if (tagline.isNotEmpty)
                  pw.Text(tagline, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                if (address.isNotEmpty)
                  pw.Text(address, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (phone.isNotEmpty)
                  pw.Text('Phone: $phone', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (gstin.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 2),
                    child: pw.Text(
                      'GSTIN: $gstin',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
                    ),
                  ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green800,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    'TAX INVOICE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'Invoice #: ${details.invoice.invoiceNumber}',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Date: $formattedDate',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Order: ${details.invoice.orderType.toUpperCase()}${isDineIn && hasTable ? ' (Table: ${details.invoice.tableNumber})' : ''}',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 16),
        pw.Divider(thickness: 1, color: PdfColors.grey400),
        pw.SizedBox(height: 8),

        // Customer & Payment Status row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL TO:',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
                ),
                pw.Text(
                  hasCustomerName ? details.invoice.customerName!.trim() : 'Walk-in Customer',
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
                ),
                if (hasCustomerPhone)
                  pw.Text('Phone: ${details.invoice.customerPhone!.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                if (isDelivery && hasDeliveryAddress)
                  pw.Text('Address: ${details.invoice.deliveryAddress!.trim()}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Row(
                  children: [
                    pw.Text('Payment Method: ', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(details.invoice.paymentMethod, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('Payment Status: ', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      details.invoice.paymentStatus.toUpperCase(),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: details.invoice.paymentStatus.toLowerCase() == 'paid'
                            ? PdfColors.green800
                            : PdfColors.orange800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        // Items Table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _th('#', width: 24),
                _th('Item Description'),
                _th('Qty', width: 40),
                _th('Rate'),
                _th('Taxable'),
                _th('GST %', width: 44),
                _th('GST Amt'),
                _th('Total Amount'),
              ],
            ),
            ...details.items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final qtyStr = item.quantity % 1 == 0 ? item.quantity.toInt().toString() : item.quantity.toString();

              return pw.TableRow(
                children: [
                  _td('$idx', align: pw.TextAlign.center),
                  _td(item.productName),
                  _td('$qtyStr ${item.unit}', align: pw.TextAlign.center),
                  _td(formatAmount(item.unitPricePaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                  _td(formatAmount(item.taxableAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                  _td('${item.gstRatePercent}%', align: pw.TextAlign.center),
                  _td(formatAmount(item.taxAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right),
                  _td(formatAmount(item.totalAmountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: false), align: pw.TextAlign.right, bold: true),
                ],
              );
            }),
          ],
        ),

        pw.SizedBox(height: 12),

        // Bottom section: Bill Note & Totals Breakdown
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 5,
              child: showNote && details.billNote != null && details.billNote!.note.trim().isNotEmpty
                  ? pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        border: pw.Border.all(color: PdfColors.amber300, width: 1),
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'SPECIAL INSTRUCTIONS / NOTE:',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(details.billNote!.note.trim(), style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900)),
                        ],
                      ),
                    )
                  : pw.SizedBox(),
            ),
            pw.SizedBox(width: 24),
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                children: [
                  _a4SummaryRow('Subtotal', details.invoice.subtotalPaise, hasUnicodeFont),
                  if (details.invoice.itemDiscountTotalPaise > 0)
                    _a4SummaryRow('Item Discount', -details.invoice.itemDiscountTotalPaise, hasUnicodeFont),
                  if (details.invoice.billDiscountPaise > 0)
                    _a4SummaryRow('Bill Discount', -details.invoice.billDiscountPaise, hasUnicodeFont),
                  if (details.invoice.cgstPaise > 0 || details.invoice.sgstPaise > 0)
                    _a4SummaryRow('Taxable Value', details.invoice.taxableAmountPaise, hasUnicodeFont),
                  if (details.invoice.cgstPaise > 0)
                    _a4SummaryRow('CGST', details.invoice.cgstPaise, hasUnicodeFont),
                  if (details.invoice.sgstPaise > 0)
                    _a4SummaryRow('SGST', details.invoice.sgstPaise, hasUnicodeFont),
                  if (details.invoice.roundOffPaise != 0)
                    _a4SummaryRow('Round Off', details.invoice.roundOffPaise, hasUnicodeFont),
                  pw.Divider(thickness: 1, color: PdfColors.green800),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('GRAND TOTAL:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                        formatAmount(details.invoice.grandTotalPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: true),
                        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                      ),
                    ],
                  ),
                  pw.Divider(thickness: 1, color: PdfColors.green800),
                  _a4SummaryRow('Amount Paid', details.invoice.paidAmountPaise, hasUnicodeFont),
                  if (details.invoice.grandTotalPaise > details.invoice.paidAmountPaise)
                    _a4SummaryRow(
                      'Balance Due',
                      details.invoice.grandTotalPaise - details.invoice.paidAmountPaise,
                      hasUnicodeFont,
                      highlight: true,
                    ),
                ],
              ),
            ),
          ],
        ),

        pw.Spacer(),

        // Footer
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(footerMsg, style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text('Generated by FoodBill Pro - POS', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _th(String text, {double? width}) {
    return pw.Container(
      width: width,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _td(String text, {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _a4SummaryRow(String label, int amountPaise, bool hasUnicodeFont, {bool highlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? PdfColors.red800 : PdfColors.black,
            ),
          ),
          pw.Text(
            formatAmount(amountPaise, hasUnicodeFont: hasUnicodeFont, showSymbol: true),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: highlight ? PdfColors.red800 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Print invoice using system print dialog
  static Future<void> printInvoice({
    required InvoiceDetails details,
    required Map<String, String> settings,
    ReceiptFormat? format,
  }) async {
    final effectiveFormat = resolveFormat(settings, format);
    final pdfBytes = await generate(
      details: details,
      settings: settings,
      format: effectiveFormat,
    );
    await Printing.layoutPdf(
      onLayout: (pageFormat) async => pdfBytes,
      name: '${details.invoice.invoiceNumber}.pdf',
    );
  }

  /// Print KOT to thermal roll printer
  static Future<void> printKot({
    required InvoiceDetails details,
    required Map<String, String> settings,
    ReceiptFormat? format,
  }) async {
    final effectiveFormat = resolveFormat(settings, format);
    final pdfBytes = await generateKot(
      details: details,
      settings: settings,
      format: effectiveFormat,
    );
    await Printing.layoutPdf(
      onLayout: (pageFormat) async => pdfBytes,
      name: 'KOT_${details.invoice.invoiceNumber}.pdf',
    );
  }

  /// Share PDF invoice via WhatsApp / Email
  static Future<void> shareInvoice({
    required InvoiceDetails details,
    required Map<String, String> settings,
    ReceiptFormat format = ReceiptFormat.a4Invoice,
  }) async {
    final pdfBytes = await generate(
      details: details,
      settings: settings,
      format: format,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${details.invoice.invoiceNumber}.pdf',
    );
  }

  /// Share KOT via WhatsApp / Email
  static Future<void> shareKot({
    required InvoiceDetails details,
    required Map<String, String> settings,
    ReceiptFormat? format,
  }) async {
    final effectiveFormat = resolveFormat(settings, format);
    final pdfBytes = await generateKot(
      details: details,
      settings: settings,
      format: effectiveFormat,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'KOT_${details.invoice.invoiceNumber}.pdf',
    );
  }
}
