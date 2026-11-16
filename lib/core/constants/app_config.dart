/// Cấu hình các cờ tính năng (Feature Flags) đảm bảo tương thích với Backend Staging
/// BE stg (Baseline 16.11.2026.v3) chỉ triển khai các API chính:
/// - Auth & Profile (Customer)
/// - Catalog & Recommendations & Reviews
/// - B2B Direct Bulk Orders, VNPay Payments & Split Payments
/// - B2B RFQs & Contracts (OTP Ký số điện tử & Milestones)
/// - Deliveries & PoD qua Public Token Link
/// - Real-time SignalR (Notifications & Chat)
/// - Custom Packaging Collaboration
///
/// Các tính năng BE stg KHÔNG triển khai API:
/// - Tài khoản tài xế riêng (/driver/trips) và tra cứu mã chuyến 8 ký tự (/deliveries/public/code/{code})
/// - Trang hồ sơ xưởng công khai (/shops/{slug})
/// - Phản biện khiếu nại xưởng (Rebuttal window)
/// - Job tự động xác nhận đơn sau 72h (Auto-confirm SLA)
class AppConfig {
  /// Cờ bật/tắt luồng tài xế và nhập mã chuyến (mặc định tắt trên Staging vì BE stg không có API này)
  static const bool enableDriverMode = bool.fromEnvironment(
    'ENABLE_DRIVER_MODE',
    defaultValue: false,
  );

  /// Cờ bật/tắt trang hồ sơ xưởng công khai (mặc định tắt vì BE stg không có endpoint GET /api/v1/shops/{slug})
  static const bool enablePublicShopProfile = bool.fromEnvironment(
    'ENABLE_PUBLIC_SHOP_PROFILE',
    defaultValue: false,
  );
}
