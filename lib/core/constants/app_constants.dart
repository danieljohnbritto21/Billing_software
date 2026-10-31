class AppConstants {
  static const String appName = 'FoodBill Pro';
  static const String defaultCurrencySymbol = '₹';
  static const String defaultInvoicePrefix = 'INV-';

  // Units
  static const List<String> standardUnits = [
    'plate',
    'piece',
    'portion',
    'cup',
    'glass',
    'bowl',
    'kg',
    'half-kg',
    'gm',
    'litre',
    'ml',
    'pack',
    'combo',
  ];

  // GST Rates in percent
  static const List<double> standardGstRates = [0.0, 5.0, 12.0, 18.0, 28.0];

  // Payment Methods
  static const String paymentCash = 'Cash';
  static const String paymentUpi = 'UPI';
  static const String paymentCard = 'Card';
  static const String paymentSplit = 'Split';
  static const String paymentDue = 'Credit/Due';

  static const List<String> paymentMethods = [
    paymentCash,
    paymentUpi,
    paymentCard,
    paymentSplit,
    paymentDue,
  ];

  // Roles
  static const String roleAdmin = 'admin';
  static const String roleCashier = 'cashier';

  // Order Statuses
  static const String orderPending = 'Pending';
  static const String orderInProgress = 'In Progress';
  static const String orderCompleted = 'Completed';
  static const String orderCancelled = 'Cancelled';

  static const List<String> orderStatuses = [
    orderPending,
    orderInProgress,
    orderCompleted,
    orderCancelled,
  ];

  // Payment Statuses
  static const String statusPaid = 'Paid';
  static const String statusPartial = 'Partially Paid';
  static const String statusPending = 'Pending';
  static const String statusCancelled = 'Cancelled';
  static const String statusRefunded = 'Refunded';

  static const List<String> paymentStatuses = [
    statusPaid,
    statusPartial,
    statusPending,
    statusCancelled,
    statusRefunded,
  ];

  // Order Types (Restaurant POS)
  static const String orderTypeDineIn = 'Dine In';
  static const String orderTypeTakeaway = 'Takeaway';
  static const String orderTypeDelivery = 'Delivery';

  static const List<String> orderTypes = [
    orderTypeDineIn,
    orderTypeTakeaway,
    orderTypeDelivery,
  ];

  // Standard Restaurant Tables
  static const List<String> defaultTables = [
    'Table 1',
    'Table 2',
    'Table 3',
    'Table 4',
    'Table 5',
    'Table 6',
    'Table 7',
    'Table 8',
    'Table 9',
    'Table 10',
    'Table 11',
    'Table 12',
    'Table 14',
    'Table 15',
    'Table 16',
    'Table 18',
    'Table 20',
  ];
}
