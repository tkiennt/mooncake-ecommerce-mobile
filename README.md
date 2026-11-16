# 🥮 Nguyệt Phố B2B - Mobile Application (Flutter Edition)

> **Cổng Mua Sắm & Đấu Thầu Quà Tặng Trung Thu Doanh Nghiệp (Mobile Client).**  
> Ứng dụng đã hoàn tất chuyển đổi (Migration) sang **Flutter 3.24+ (Dart 3.5+)**, kế thừa và bảo tồn nguyên vẹn 100% ngôn ngữ thiết kế **Hoàng Gia (Crimson Luxury `#8C1524` & Imperial Gold `#D48806`)**, hệ thống micro-interactions **Lucian UX/UI** và cấu trúc **Ant Design**.

---

## 📑 Mục Lục
1. [Tổng Quan Nền Tảng (Overview)](#-tổng-quan-nền-tảng)
2. [Công Nghệ Sử Dụng (Tech Stack)](#-công-nghệ-sử-dụng)
3. [Kiến Trúc Mã Nguồn (Architecture & Directory Structure)](#-kiến-trúc-mã-nguồn)
4. [Các Phân Hệ Chức Năng Chính (Modules & Features)](#-các-phân-hệ-chức-năng-chính)
5. [Hệ Thống Nhận Diện & Design Tokens (Theme System)](#-hệ-thống-nhận-diện--design-tokens)
6. [Cấu Hình Môi Trường & Kết Nối Backend (API Configuration)](#-cấu-hình-môi-trường--kết-nối-backend)
7. [Hướng Dẫn Cài Đặt & Khởi Chạy (Quick Start)](#-hướng-dẫn-cài-đặt--khởi-chạy)

---

## 🌟 Tổng Quan Nền Tảng

Ứng dụng di động **Nguyệt Phố B2B** phục vụ đối tượng đại diện thu mua doanh nghiệp, cơ quan đoàn thể và người mua sỉ quà tặng Trung Thu cao cấp:
- **Đấu thầu B2B tinh gọn**: Tạo yêu cầu báo giá (RFQ) và nhận các gói chào thầu cạnh tranh trực tiếp từ 50+ xưởng bánh nghệ nhân.
- **Hợp đồng điện tử e-Contract**: Đọc điều khoản, ký tay điện tử và xác thực ký số di động qua mã OTP SMS.
- **Ký quỹ an toàn SafeTrade Escrow**: Giải ngân minh bạch theo từng mốc tiến độ (Milestones).
- **Giám sát giao nhận xe lạnh PoD**: Theo dõi nhiệt độ thùng xe và xem hình ảnh biên bản bàn giao thực tế kèm chữ ký và tọa độ GPS.
- **Trợ lý ảo AI Chatbot**: Tư vấn set quà tặng theo ngân sách doanh nghiệp và văn hóa đối tác.

---

## 🛠️ Công Nghệ Sử Dụng (Flutter)

| Thành Phần | Công Nghệ / Thư Viện | Mục Đích |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.24+ / Dart 3.5+** | Xây dựng ứng dụng native đa nền tảng iOS & Android hiệu năng 60/120fps |
| **Điều Hướng** | `go_router` | Quản lý StatefulShellRoute cho 5 Bottom Tabs và Deep Link `nguyetpho://` |
| **State Management** | `flutter_riverpod` (v2.5+) | Quản lý trạng thái type-safe cho Auth, Giỏ hàng, Thông báo và Sản phẩm |
| **Networking** | `dio` + `pretty_dio_logger` | Tầng gọi API tập trung, tự động gắn JWT Bearer và cơ chế xoay vòng Refresh Token |
| **Realtime Hub** | `signalr_netcore` | Kết nối WebSocket thời gian thực tới ASP.NET Core 8 Hub (`/hubs/notifications`) |
| **Quản Lý Phiên** | `flutter_secure_storage` + `shared_preferences` | Lưu trữ an toàn Token JWT và hồ sơ doanh nghiệp |
| **UI Kit & Grid** | `flutter_staggered_grid_view`, `cached_network_image`, `pinput`, `signature` | Tái tạo feed so le Masonry, ô nhập OTP 6 số và bảng chữ ký số |

---

## 🏛️ Kiến Trúc Mã Nguồn

```text
mooncake-mobile/
├── assets/                         # Tài nguyên hình ảnh, biểu tượng vector, logo
│   └── products/                   # Hình ảnh sản phẩm mẫu, promo-banner.jpg
├── lib/
│   ├── main.dart                   # Điểm khởi chạy ứng dụng Flutter (ProviderScope)
│   ├── app_router.dart             # Cấu hình GoRouter, StatefulShellRoute 5 tabs
│   ├── core/
│   │   ├── constants/              # ApiEndpoints, AppConstants
│   │   ├── network/                # ApiClient (Dio, Interceptors, Auto Refresh Token)
│   │   ├── realtime/               # SignalRService (Hub notifications & bids)
│   │   ├── storage/                # StorageService (Secure storage)
│   │   └── theme/
│   │       ├── app_colors.dart     # Mã màu chuẩn Hoàng Gia (#8C1524, #D48806, #FDFBF7)
│   │       ├── app_tokens.dart     # Ant Design tokens & Lucian UX/UI micro-tokens
│   │       └── app_theme.dart      # ThemeData Material 3
│   ├── data/
│   │   └── models/                 # Product, User, CartItem, Order, Rfq, NotificationItem
│   ├── providers/                  # Riverpod Notifiers (Auth, Cart, Catalog, Notification)
│   ├── shared_widgets/
│   │   ├── common/                 # AppHeader, CustomButton, ProductGridCard, BottomTabBar
│   │   ├── antd/                   # AntdSteps, AntdOtpInput
│   │   └── lucian/                 # AnnouncementPill, B2BPriceCalculator, TearOffCoupon,
│   │                               # TrustSecurityBadges, ReviewFilterStars, RecentOrderToast
│   └── features/
│       ├── home/                   # HomeScreen (Staggered feed, promo banner, RFQ CTA)
│       ├── catalog/                # SearchScreen, ProductDetailScreen
│       ├── cart/                   # CartScreen, CheckoutScreen, PaymentResultScreen
│       ├── auth/                   # Login, Register, VerifyEmail, Forgot & ResetPassword
│       ├── b2b/                    # CreateRfq, RfqList, RfqDetailBidding, Contracts, Sign, DeliveryPoD
│       ├── ai/                     # AiAssistantScreen
│       ├── notification/           # NotificationScreen, NotificationSettingsScreen
│       ├── profile/                # ProfileScreen, EditProfileScreen, OrderHistory, OrderDetail
│       └── dev/                    # UiCatalogScreen (Showcase đối soát thành phần)
├── android/                        # Android build scripts & AndroidManifest (Deep Link)
├── ios/                            # iOS Runner & Info.plist
└── pubspec.yaml                    # Flutter dependencies & assets declarations
```

---

## 🎨 Hệ Thống Nhận Diện & Design Tokens (Theme System)

Bảo toàn 100% định dạng nhận diện thương hiệu:
- **Đỏ Crimson Hoàng Gia**: `#8C1524` (Primary), `#5E0E18` (Dark), `#B82338` (Light), `#FFF1F0` (Tint)
- **Vàng Gold Hoàng Gia**: `#D48806` (Accent), `#FAAD14` (Light), `#FFFBE6` (Background Tint)
- **Nền Giấy Lụa Ngà**: `#FDFBF7`
- **Ánh Sáng & Đổ Bóng**: `glowGold` (`rgba(212, 136, 6, 0.28)`), `glowCrimson` (`rgba(140, 21, 36, 0.22)`)

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy (Quick Start)

### 1. Cài đặt Dependencies
```bash
flutter pub get
```

### 2. Khởi chạy ứng dụng
```bash
# Khởi chạy trên thiết bị / máy ảo kết nối
flutter run

# Chỉ định cấu hình API Server tuỳ chỉnh (nếu dùng thiết bị thật)
flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8089/api/v1
```
