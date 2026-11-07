import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_theme.dart';
import '../invoices/invoice_repository.dart';
import '../settings/settings_repository.dart';
import 'invoice_pdf_generator.dart';
import 'thermal_esc_pos_generator.dart';

class PrinterManagementScreen extends ConsumerStatefulWidget {
  const PrinterManagementScreen({super.key});

  @override
  ConsumerState<PrinterManagementScreen> createState() => _PrinterManagementScreenState();
}

class _PrinterManagementScreenState extends ConsumerState<PrinterManagementScreen> {
  bool _isLoading = true;
  List<Printer> _availablePrinters = [];
  String? _selectedPrinterName;
  String? _selectedPrinterUrl;
  String _paperWidth = '80mm';
  String _characterEncoding = 'CP437';
  bool _autoCut = true;
  bool _openCashDrawer = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndPrinters();
  }

  Future<void> _loadSettingsAndPrinters() async {
    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final settings = await (db.select(db.appSettings)).get();
      final map = {for (final s in settings) s.key: s.value};

      _selectedPrinterName = map['default_printer_name'];
      _selectedPrinterUrl = map['default_printer_url'];
      _paperWidth = map[SettingsRepository.keyPrinterWidth] ?? '80mm';
      _characterEncoding = map['printer_encoding'] ?? 'CP437';
      _autoCut = map['printer_auto_cut'] != 'false';
      _openCashDrawer = map['printer_open_drawer'] == 'true';

      // Scan available printers
      final printers = await Printing.listPrinters();
      setState(() {
        _availablePrinters = printers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Printer discovery note: $e';
      });
    }
  }

  Future<void> _savePreference(String key, String value) async {
    final db = ref.read(databaseProvider);
    await db.into(db.appSettings).insertOnConflictUpdate(
      AppSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<void> _setDefaultPrinter(Printer? printer) async {
    setState(() {
      _selectedPrinterName = printer?.name;
      _selectedPrinterUrl = printer?.url;
    });

    await _savePreference('default_printer_name', printer?.name ?? '');
    await _savePreference('default_printer_url', printer?.url ?? '');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(printer == null ? 'Default printer cleared' : 'Default printer set to ${printer.name}')),
      );
    }
  }

  Future<void> _runTestPrintReceipt() async {
    try {
      // Create mock invoice details for test receipt
      final now = DateTime.now();
      final mockInvoice = InvoiceEntry(
        id: 'test-inv-id',
        invoiceNumber: 'TEST-0001',
        createdAt: now,
        subtotalPaise: 35000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 35000,
        cgstPaise: 875,
        sgstPaise: 875,
        igstPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 36750,
        paidAmountPaise: 36750,
        paymentMethod: 'Cash',
        paymentStatus: 'Paid',
        orderStatus: 'Completed',
        orderType: 'Dine In',
        tableNumber: 'Table 1',
        customerName: 'Test Customer',
        customerPhone: '9876543210',
        isCancelled: false,
      );

      final mockItems = [
        InvoiceItemEntry(
          id: 'test-it-1',
          invoiceId: 'test-inv-id',
          productName: 'Paneer Butter Masala',
          unit: 'plate',
          unitPricePaise: 25000,
          quantity: 1,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 23810,
          taxAmountPaise: 1190,
          totalAmountPaise: 25000,
        ),
        InvoiceItemEntry(
          id: 'test-it-2',
          invoiceId: 'test-inv-id',
          productName: 'Butter Naan',
          unit: 'piece',
          unitPricePaise: 5000,
          quantity: 2,
          discountPaise: 0,
          gstRatePercent: 5.0,
          isTaxInclusive: true,
          taxableAmountPaise: 9524,
          taxAmountPaise: 476,
          totalAmountPaise: 10000,
        ),
      ];

      final details = InvoiceDetails(
        invoice: mockInvoice,
        items: mockItems,
        billNote: null,
        payments: [
          PaymentEntry(
            id: 'test-pay-1',
            invoiceId: 'test-inv-id',
            amountPaise: 36750,
            paymentMethod: 'Cash',
            createdAt: now,
          ),
        ],
      );

      final settings = {
        'business_name': 'FoodBill Pro Test Restaurant',
        'business_address': '123 Market Road, City Center',
        'business_phone': '011-23456789',
        'business_gstin': '29ABCDE1234F1Z5',
        SettingsRepository.keyPrinterWidth: _paperWidth,
      };

      // Test ESC/POS byte generator
      final bytes = await ThermalEscPosGenerator.generateBytes(
        details: details,
        settings: settings,
      );

      // Trigger standard print layout
      await Printing.layoutPdf(
        name: 'Test_Receipt_FoodBillPro',
        onLayout: (format) async {
          return await InvoicePdfGenerator.generate(
            details: details,
            settings: settings,
            format: _paperWidth == '58mm' ? ReceiptFormat.thermal58mm : ReceiptFormat.thermal80mm,
          );
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test Receipt sent to printer (${bytes.length} ESC/POS command bytes)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _runTestPrintKot() async {
    try {
      final now = DateTime.now();
      final mockInvoice = InvoiceEntry(
        id: 'test-kot-inv',
        invoiceNumber: 'ORD-9901',
        createdAt: now,
        subtotalPaise: 25000,
        itemDiscountTotalPaise: 0,
        billDiscountPaise: 0,
        taxableAmountPaise: 25000,
        cgstPaise: 0,
        sgstPaise: 0,
        igstPaise: 0,
        roundOffPaise: 0,
        grandTotalPaise: 25000,
        paidAmountPaise: 0,
        paymentMethod: 'Pending',
        paymentStatus: 'Pending',
        orderStatus: 'In Progress',
        orderType: 'Dine In',
        tableNumber: 'Table 4',
        kotNumber: 'KOT-042',
        isCancelled: false,
      );

      final mockItems = [
        InvoiceItemEntry(
          id: 'test-kot-it-1',
          invoiceId: 'test-kot-inv',
          productName: 'Veg Hakka Noodles',
          unit: 'plate',
          unitPricePaise: 15000,
          quantity: 2,
          discountPaise: 0,
          gstRatePercent: 0,
          isTaxInclusive: true,
          taxableAmountPaise: 15000,
          taxAmountPaise: 0,
          totalAmountPaise: 15000,
        ),
      ];

      final details = InvoiceDetails(
        invoice: mockInvoice,
        items: mockItems,
        billNote: BillNoteEntry(
          id: 'bn-1',
          invoiceId: 'test-kot-inv',
          note: 'Less spicy, no garlic please',
          isCustomerFacing: true,
          createdAt: now,
          updatedAt: now,
        ),
        payments: [],
      );

      final settings = {
        'business_name': 'FoodBill Pro Kitchen',
        SettingsRepository.keyPrinterWidth: _paperWidth,
      };

      final bytes = await ThermalEscPosGenerator.generateKotBytes(
        details: details,
        settings: settings,
      );

      await Printing.layoutPdf(
        name: 'Test_KOT_FoodBillPro',
        onLayout: (format) async {
          return await InvoicePdfGenerator.generateKot(
            details: details,
            settings: settings,
            format: _paperWidth == '58mm' ? ReceiptFormat.thermal58mm : ReceiptFormat.thermal80mm,
          );
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Test KOT sent (${bytes.length} ESC/POS bytes, zero financial totals)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('KOT Print Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermal Printer Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Re-scan Printers',
            onPressed: _loadSettingsAndPrinters,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active Hardware Printer Card
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.print, color: AppTheme.primaryGreen, size: 24),
                            const SizedBox(width: 8),
                            const Text(
                              'Default Hardware Printer',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedPrinterName != null && _selectedPrinterName!.isNotEmpty
                              ? 'Connected: $_selectedPrinterName'
                              : 'No default printer selected (System dialog will appear on print)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedPrinterName != null ? Colors.black87 : Colors.grey.shade700,
                          ),
                        ),
                        if (_selectedPrinterUrl != null && _selectedPrinterUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'URL/Endpoint: $_selectedPrinterUrl',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Re-scan'),
                              onPressed: _loadSettingsAndPrinters,
                            ),
                            if (_selectedPrinterName != null) ...[
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon: const Icon(Icons.link_off, size: 16),
                                label: const Text('Disconnect'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                onPressed: () => _setDefaultPrinter(null),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Available Discovered Printers List
                const Text(
                  'Available System & Network Printers',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (_availablePrinters.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _statusMessage ?? 'No hardware printers discovered. Ensure Bluetooth, USB, or Network printer is connected and powered on.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                      ),
                    ),
                  )
                else
                  ..._availablePrinters.map((p) {
                    final isSelected = p.name == _selectedPrinterName;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade300,
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: ListTile(
                        leading: Icon(
                          p.isAvailable ? Icons.print : Icons.print_disabled,
                          color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                        ),
                        title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${p.model ?? 'Thermal Printer'} • ${p.url}'),
                        trailing: isSelected
                            ? const Chip(
                                label: Text('Active Default', style: TextStyle(fontSize: 11, color: Colors.white)),
                                backgroundColor: AppTheme.primaryGreen,
                              )
                            : OutlinedButton(
                                child: const Text('Set Default'),
                                onPressed: () => _setDefaultPrinter(p),
                              ),
                      ),
                    );
                  }),

                const SizedBox(height: 20),

                // Paper & Hardware Configuration
                const Text(
                  'Printer Configuration',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Paper Width (Roll Size)', style: TextStyle(fontWeight: FontWeight.w600)),
                            DropdownButton<String>(
                              value: _paperWidth,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: '80mm', child: Text('80 mm (Standard POS)')),
                                DropdownMenuItem(value: '58mm', child: Text('58 mm (Compact Roll)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _paperWidth = val);
                                  _savePreference(SettingsRepository.keyPrinterWidth, val);
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Character Encoding', style: TextStyle(fontWeight: FontWeight.w600)),
                            DropdownButton<String>(
                              value: _characterEncoding,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'CP437', child: Text('CP437 (Standard USA/Latin)')),
                                DropdownMenuItem(value: 'UTF-8', child: Text('UTF-8 (Multilingual)')),
                                DropdownMenuItem(value: 'WPC1252', child: Text('WPC1252 (Western European)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _characterEncoding = val);
                                  _savePreference('printer_encoding', val);
                                }
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Auto Paper Cut after Print'),
                          subtitle: const Text('Sends GS V cut command at receipt end'),
                          value: _autoCut,
                          activeColor: AppTheme.primaryGreen,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() => _autoCut = val);
                            _savePreference('printer_auto_cut', val.toString());
                          },
                        ),
                        SwitchListTile(
                          title: const Text('Open Cash Drawer on Settlement'),
                          subtitle: const Text('Sends pulse signal to RJ11 cash drawer port'),
                          value: _openCashDrawer,
                          activeColor: AppTheme.primaryGreen,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (val) {
                            setState(() => _openCashDrawer = val);
                            _savePreference('printer_open_drawer', val.toString());
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Diagnostic Test Printing
                const Text(
                  'Diagnostic Test Prints',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.receipt),
                        label: const Text('Test Print Receipt'),
                        onPressed: _runTestPrintReceipt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.restaurant),
                        label: const Text('Test Print KOT'),
                        onPressed: _runTestPrintKot,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
