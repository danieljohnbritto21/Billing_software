import 'package:flutter_test/flutter_test.dart';
import 'package:foodbillpro/core/database/app_database.dart';
import 'package:foodbillpro/core/utils/currency_formatter.dart';
import 'package:foodbillpro/features/billing/cart_provider.dart';

void main() {
  group('Currency & Paise Calculations Tests', () {
    test('Converts rupees to paise and paise to rupees accurately', () {
      expect(CurrencyFormatter.rupeesToPaise(149.00), equals(14900));
      expect(CurrencyFormatter.rupeesToPaise(99.50), equals(9950));
      expect(CurrencyFormatter.paiseToRupees(14900), equals(149.00));
      expect(CurrencyFormatter.paiseToRupees(9950), equals(99.50));
    });

    test('Tax inclusive GST calculation correctly separates taxable amount and tax', () {
      // ₹105 tax-inclusive at 5% GST:
      // Taxable = 105 * 100 / 105 = 100
      // Tax = 5 (CGST: 2.50 -> 250 paise, SGST: 2.50 -> 250 paise)
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 10500,
        quantity: 1.0,
        gstRatePercent: 5.0,
        isTaxInclusive: true,
      );

      expect(calc.taxableAmountPaise, equals(10000));
      expect(calc.totalTaxPaise, equals(500));
      expect(calc.cgstPaise + calc.sgstPaise, equals(500));
      expect(calc.totalAmountPaise, equals(10500));
    });

    test('Tax exclusive GST calculation correctly adds tax on top', () {
      // ₹100 tax-exclusive at 5% GST:
      // Taxable = 100, Tax = 5, Total = 105
      final calc = CurrencyFormatter.calculateItemTax(
        unitPricePaise: 10000,
        quantity: 1.0,
        gstRatePercent: 5.0,
        isTaxInclusive: false,
      );

      expect(calc.taxableAmountPaise, equals(10000));
      expect(calc.totalTaxPaise, equals(500));
      expect(calc.totalAmountPaise, equals(10500));
    });
  });

  group('Cart & POS Calculations Tests', () {
    final now = DateTime.now();
    final burger = ProductEntry(
      id: 'p1',
      name: 'Crispy Burger',
      sellingPricePaise: 15000, // ₹150.00
      costPricePaise: 7000,
      gstRatePercent: 5.0,
      isTaxInclusive: true,
      unit: 'piece',
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    );

    final fries = ProductEntry(
      id: 'p2',
      name: 'French Fries',
      sellingPricePaise: 8000, // ₹80.00
      costPricePaise: 3000,
      gstRatePercent: 5.0,
      isTaxInclusive: true,
      unit: 'plate',
      isAvailable: true,
      createdAt: now,
      updatedAt: now,
    );

    test('Adding and modifying quantities in cart updates subtotal correctly', () {
      final notifier = CartNotifier();
      notifier.addProduct(burger, quantity: 2.0); // 2 * 150 = 300
      notifier.addProduct(fries, quantity: 1.0);  // 1 * 80 = 80

      expect(notifier.state.itemCount, equals(2));
      expect(notifier.state.subtotalPaise, equals(38000)); // ₹380.00
      expect(notifier.state.grandTotalPaise, equals(38000));

      // Update quantity of burger to 3
      notifier.updateQuantity('p1', 3.0); // 3 * 150 = 450 + 80 = 530
      expect(notifier.state.subtotalPaise, equals(53000)); // ₹530.00
    });

    test('Discounts and round-off calculation', () {
      final notifier = CartNotifier();
      notifier.addProduct(burger, quantity: 1.0); // 15000 paise
      notifier.setBillDiscount(2000); // ₹20 discount

      expect(notifier.state.grandTotalPaise, equals(13000)); // ₹130.00
    });

    test('Individual Bill Note is stored and updated in CartState without affecting financial totals', () {
      final notifier = CartNotifier();
      notifier.addProduct(burger);

      expect(notifier.state.billNote, isEmpty);
      const testNote = 'Customer requested extra mayo and less spicy';

      notifier.setBillNote(testNote);
      expect(notifier.state.billNote, equals(testNote));
      // Verify financial calculation was not modified by adding note
      expect(notifier.state.grandTotalPaise, equals(15000));

      // Edit note
      const editedNote = 'Customer requested takeaway pack with cutlery';
      notifier.setBillNote(editedNote);
      expect(notifier.state.billNote, equals(editedNote));
      expect(notifier.state.grandTotalPaise, equals(15000));
    });
  });
}
