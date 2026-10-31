import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _noSymbolFormatter = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '',
    decimalDigits: 2,
  );

  /// Converts paise (integer) to rupees (double)
  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }

  /// Converts rupees (double/num) to integer paise
  static int rupeesToPaise(num rupees) {
    return (rupees * 100).round();
  }

  /// Formats paise integer into Indian Rupee currency string, e.g. "₹450.00"
  static String formatPaise(int paise, {bool showSymbol = true}) {
    final rupees = paiseToRupees(paise);
    if (showSymbol) {
      return _formatter.format(rupees).trim();
    }
    return _noSymbolFormatter.format(rupees).trim();
  }

  /// Formats double rupees into currency string
  static String formatRupees(double rupees, {bool showSymbol = true}) {
    if (showSymbol) {
      return _formatter.format(rupees).trim();
    }
    return _noSymbolFormatter.format(rupees).trim();
  }

  /// Calculates tax breakdown for an item
  /// All amounts in integer paise
  static TaxCalculation calculateItemTax({
    required int unitPricePaise,
    required double quantity,
    required double gstRatePercent,
    required bool isTaxInclusive,
    int discountPaise = 0,
  }) {
    final rawTotal = (unitPricePaise * quantity).round();
    final netTotal = rawTotal - discountPaise;
    final discountedTotal = netTotal > 0 ? netTotal : 0;

    if (gstRatePercent <= 0) {
      return TaxCalculation(
        taxableAmountPaise: discountedTotal,
        cgstPaise: 0,
        sgstPaise: 0,
        igstPaise: 0,
        totalTaxPaise: 0,
        totalAmountPaise: discountedTotal,
      );
    }

    if (isTaxInclusive) {
      // Selling price includes GST
      // Taxable = (SellingPrice * 100) / (100 + GstRate)
      final taxable = (discountedTotal * 100.0 / (100.0 + gstRatePercent)).round();
      final totalTax = discountedTotal - taxable;
      final halfTax = (totalTax / 2.0).round();
      final sgst = totalTax - halfTax; // Prevent 1 paise rounding mismatch

      return TaxCalculation(
        taxableAmountPaise: taxable,
        cgstPaise: halfTax,
        sgstPaise: sgst,
        igstPaise: 0,
        totalTaxPaise: totalTax,
        totalAmountPaise: discountedTotal,
      );
    } else {
      // Tax is added on top
      final taxable = discountedTotal;
      final totalTax = (taxable * (gstRatePercent / 100.0)).round();
      final halfTax = (totalTax / 2.0).round();
      final sgst = totalTax - halfTax;

      return TaxCalculation(
        taxableAmountPaise: taxable,
        cgstPaise: halfTax,
        sgstPaise: sgst,
        igstPaise: 0,
        totalTaxPaise: totalTax,
        totalAmountPaise: taxable + totalTax,
      );
    }
  }
}

class TaxCalculation {
  final int taxableAmountPaise;
  final int cgstPaise;
  final int sgstPaise;
  final int igstPaise;
  final int totalTaxPaise;
  final int totalAmountPaise;

  const TaxCalculation({
    required this.taxableAmountPaise,
    required this.cgstPaise,
    required this.sgstPaise,
    required this.igstPaise,
    required this.totalTaxPaise,
    required this.totalAmountPaise,
  });
}
