import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../invoices/invoice_repository.dart';

class ThermalEscPosGenerator {
  /// Generates ESC/POS command bytes for 58mm or 80mm thermal receipt printers
  static Future<List<int>> generateBytes({
    required InvoiceDetails details,
    required Map<String, String> settings,
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

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

    final isDineIn = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDineIn.toLowerCase();
    final hasTable = details.invoice.tableNumber != null && details.invoice.tableNumber!.trim().isNotEmpty;
    final hasCustomerName = details.invoice.customerName != null && details.invoice.customerName!.trim().isNotEmpty;
    final hasCustomerPhone = details.invoice.customerPhone != null && details.invoice.customerPhone!.trim().isNotEmpty;

    // Header
    bytes += generator.text(
      businessName,
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    if (tagline.isNotEmpty) {
      bytes += generator.text(tagline, styles: const PosStyles(align: PosAlign.center));
    }
    if (address.isNotEmpty) {
      bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
    }
    if (phone.isNotEmpty) {
      bytes += generator.text('Ph: $phone', styles: const PosStyles(align: PosAlign.center));
    }
    if (gstin.isNotEmpty) {
      bytes += generator.text('GSTIN: $gstin', styles: const PosStyles(align: PosAlign.center, bold: true));
    }

    bytes += generator.hr();

    // Invoice Meta
    bytes += generator.row([
      PosColumn(text: 'Inv: ${details.invoice.invoiceNumber}', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: details.invoice.orderType.toUpperCase(), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.row([
      PosColumn(text: formattedDate, width: 7),
      if (isDineIn && hasTable)
        PosColumn(text: 'Table: ${details.invoice.tableNumber!.trim()}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true))
      else
        PosColumn(text: details.invoice.paymentStatus.toUpperCase(), width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (hasCustomerName) {
      bytes += generator.text('Customer: ${details.invoice.customerName!.trim()}');
    }
    if (hasCustomerPhone) {
      bytes += generator.text('Phone: ${details.invoice.customerPhone!.trim()}');
    }

    bytes += generator.hr();

    // Items Table Header: Item (6), Qty (2), Rate (2), Amount (2)
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'Rate', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      PosColumn(text: 'Amount', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    // Items
    for (final item in details.items) {
      final qtyStr = item.quantity.truncateToDouble() == item.quantity
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(1);
      final rateStr = CurrencyFormatter.formatPaise(item.unitPricePaise, showSymbol: false);
      final amtStr = CurrencyFormatter.formatPaise(item.totalAmountPaise, showSymbol: false);

      bytes += generator.row([
        PosColumn(text: item.productName, width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: qtyStr, width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: rateStr, width: 2, styles: const PosStyles(align: PosAlign.right)),
        PosColumn(text: amtStr, width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    bytes += generator.hr();

    // Financial Totals
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 6),
      PosColumn(text: CurrencyFormatter.formatPaise(details.invoice.subtotalPaise, showSymbol: false), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);

    if (details.invoice.itemDiscountTotalPaise > 0 || details.invoice.billDiscountPaise > 0) {
      final totalDisc = details.invoice.itemDiscountTotalPaise + details.invoice.billDiscountPaise;
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 6),
        PosColumn(text: '-${CurrencyFormatter.formatPaise(totalDisc, showSymbol: false)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (details.invoice.cgstPaise > 0) {
      bytes += generator.row([
        PosColumn(text: 'CGST:', width: 6),
        PosColumn(text: CurrencyFormatter.formatPaise(details.invoice.cgstPaise, showSymbol: false), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (details.invoice.sgstPaise > 0) {
      bytes += generator.row([
        PosColumn(text: 'SGST:', width: 6),
        PosColumn(text: CurrencyFormatter.formatPaise(details.invoice.sgstPaise, showSymbol: false), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (details.invoice.roundOffPaise != 0) {
      bytes += generator.row([
        PosColumn(text: 'Round Off:', width: 6),
        PosColumn(text: CurrencyFormatter.formatPaise(details.invoice.roundOffPaise, showSymbol: false), width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.hr(ch: '=');

    // Grand Total
    bytes += generator.row([
      PosColumn(
        text: 'GRAND TOTAL',
        width: 6,
        styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      ),
      PosColumn(
        text: CurrencyFormatter.formatPaise(details.invoice.grandTotalPaise, showSymbol: false),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      ),
    ]);

    bytes += generator.hr(ch: '=');

    // Payment Info
    bytes += generator.row([
      PosColumn(text: 'Payment Method: ${details.invoice.paymentMethod}', width: 7),
      PosColumn(text: details.invoice.paymentStatus.toUpperCase(), width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Paid Amount:', width: 6),
      PosColumn(text: CurrencyFormatter.formatPaise(details.invoice.paidAmountPaise, showSymbol: false), width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    if (details.invoice.grandTotalPaise > details.invoice.paidAmountPaise) {
      bytes += generator.row([
        PosColumn(text: 'BALANCE DUE:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(
          text: CurrencyFormatter.formatPaise(details.invoice.grandTotalPaise - details.invoice.paidAmountPaise, showSymbol: false),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]);
    }

    // Bill Note / Instructions
    if (showNote && details.billNote != null && details.billNote!.note.trim().isNotEmpty) {
      bytes += generator.hr();
      bytes += generator.text('Note: ${details.billNote!.note.trim()}', styles: const PosStyles(bold: true));
    }

    bytes += generator.hr();
    bytes += generator.text(footerMsg, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }

  /// Generates Kitchen Order Ticket (KOT) command bytes without financial totals
  static Future<List<int>> generateKotBytes({
    required InvoiceDetails details,
    required Map<String, String> settings,
    PaperSize paperSize = PaperSize.mm80,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    final businessName = settings['business_name']?.trim().isNotEmpty == true
        ? settings['business_name']!.trim()
        : 'FoodBill Pro';
    final dateFormat = DateFormat('dd-MM-yyyy hh:mm a');
    final formattedDate = dateFormat.format(details.invoice.createdAt);

    final kotNumber = details.invoice.kotNumber != null && details.invoice.kotNumber!.trim().isNotEmpty
        ? details.invoice.kotNumber!.trim()
        : 'KOT-${details.invoice.invoiceNumber.replaceAll(RegExp(r'[^0-9]'), '').padLeft(6, '0')}';

    final isDineIn = details.invoice.orderType.toLowerCase() == AppConstants.orderTypeDineIn.toLowerCase();
    final hasTable = details.invoice.tableNumber != null && details.invoice.tableNumber!.trim().isNotEmpty;
    final hasCustomerName = details.invoice.customerName != null && details.invoice.customerName!.trim().isNotEmpty;
    final hasInstructions = details.billNote != null && details.billNote!.note.trim().isNotEmpty;

    // Header
    bytes += generator.text(
      businessName.toUpperCase(),
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );
    bytes += generator.text(
      'KITCHEN ORDER TICKET',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();

    // KOT Meta
    bytes += generator.row([
      PosColumn(text: 'KOT No: $kotNumber', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Order No: ${details.invoice.invoiceNumber}', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.text('Date: $formattedDate');
    bytes += generator.row([
      PosColumn(text: 'Order Type: ${details.invoice.orderType.toUpperCase()}', width: 6, styles: const PosStyles(bold: true)),
      if (isDineIn && hasTable)
        PosColumn(text: 'Table: ${details.invoice.tableNumber!.trim()}', width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    if (hasCustomerName) {
      bytes += generator.text('Customer: ${details.invoice.customerName!.trim()}');
    }

    bytes += generator.hr();

    // Table Header
    bytes += generator.row([
      PosColumn(text: 'ITEM', width: 9, styles: const PosStyles(bold: true)),
      PosColumn(text: 'QTY', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr();

    // Items
    for (final item in details.items) {
      final qtyStr = item.quantity.truncateToDouble() == item.quantity
          ? item.quantity.toInt().toString()
          : item.quantity.toStringAsFixed(1);
      final unitLabel = (item.unit.isNotEmpty && item.unit.toLowerCase() != 'plate') ? ' (${item.unit})' : '';

      bytes += generator.row([
        PosColumn(text: '${item.productName}$unitLabel', width: 9, styles: const PosStyles(bold: true)),
        PosColumn(text: qtyStr, width: 3, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2)),
      ]);
    }

    bytes += generator.hr();

    // Special Instructions
    if (hasInstructions) {
      bytes += generator.text('Special Instructions:', styles: const PosStyles(bold: true));
      bytes += generator.text(details.billNote!.note.trim(), styles: const PosStyles(bold: true));
      bytes += generator.hr();
    }

    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
