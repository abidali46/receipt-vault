// lib/shared/enums/warranty_status.dart

/// Represents the status of a product's warranty.
enum WarrantyStatus {
  /// Warranty is active and has plenty of time remaining (> 30 days).
  active,

  /// Warranty is expiring soon (<= 30 days).
  expiringSoon,

  /// Warranty has expired.
  expired,

  /// Product has no warranty attached.
  none,
}
