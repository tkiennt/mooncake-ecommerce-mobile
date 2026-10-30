# 🥮 Nguyệt Phố B2B - Mobile Application (Customer App)

> **Cổng Mua Sắm & Đấu Thầu Quà Tặng Trung Thu Doanh Nghiệp (Mobile Client).**  
> Kết nối trực tiếp với backend ASP.NET Core 8 Clean Architecture (`mooncake-ecommerce-platform`) và đồng bộ hệ thống nhận diện thương hiệu với web portal (`mooncake-fe`).

---

## 📑 Mục Lục
1. [Tổng Quan Nền Tảng (Overview)](#-tổng-quan-nền-tảng)
2. [Công Nghệ Sử Dụng (Tech Stack)](#-công-nghệ-sử-dụng)
3. [Kiến Trúc Mã Nguồn (Architecture & Directory Structure)](#-kiến-trúc-mã-nguồn)
4. [Các Phân Hệ Chức Năng Chính (Modules & Features)](#-các-phân-hệ-chức-năng-chính)
5. [Hệ Thống Nhận Diện & Design Tokens (Theme System)](#-hệ-thống-nhận-diện--design-tokens)
6. [Cấu Hình Môi Trường & Kết Nối Backend (API Configuration)](#-cấu-hình-môi-trường--kết-nối-backend)
7. [Hướng Dẫn Cài Đặt & Khởi Chạy (Quick Start)](#-hướng-dẫn-cài-đặt--khởi-chạy)
8. [Quy Chuẩn Nhánh Git & Đóng Góp (Git Workflow)](#-quy-chuẩn-nhánh-git--đóng-góp)

---

## 🌟 Tổng Quan Nền Tảng

Ứng dụng di động **Nguyệt Phố B2B** phục vụ đối tượng đại diện thu mua doanh nghiệp, cơ quan đoàn thể và người mua sỉ quà tặng Trung Thu cao cấp:
- **Đấu thầu B2B tinh gọn**: Tạo yêu cầu báo giá (RFQ) và nhận các gói chào thầu cạnh tranh trực tiếp từ 50+ xưởng bánh nghệ nhân.
- **Hợp đồng điện tử e-Contract**: Đọc điều khoản và xác thực ký số di động tức thì qua mã OTP SMS.
- **Ký quỹ an toàn SafeTrade Escrow**: Giải ngân minh bạch theo từng mốc tiến độ (Milestones).
- **Giám sát giao nhận xe lạnh PoD**: Theo dõi nhiệt độ thùng xe và xem hình ảnh biên bản bàn giao thực tế kèm chữ ký và tọa độ GPS.
- **Trợ lý ảo AI Chatbot**: Tư vấn set quà tặng theo ngân sách doanh nghiệp và văn hóa đối tác.

---

## 🛠️ Công Nghệ Sử Dụng

| Thành Phần | Công Nghệ / Thư Viện | Mục Đích |
| :--- | :--- | :--- |
| **Framework** | **React Native (Expo SDK 58)** | Xây dựng ứng dụng native đa nền tảng iOS & Android |
| **Điều Hướng** | `@react-navigation/native-stack`, `@react-navigation/bottom-tabs` | Điều hướng Bottom Tabs và Stack màn hình |
| **Networking** | `axios` | Tầng gọi API tập trung, tự động gắn JWT Bearer và xử lý lỗi |
| **Realtime Hub** | `@microsoft/signalr` | Nhận thông báo đẩy sự kiện WebSocket tức thì từ ASP.NET Core 8 |
| **Quản Lý Phiên** | `@react-native-async-storage/async-storage` | Lưu trữ an toàn Token JWT và hồ sơ doanh nghiệp |
| **Icon & UI** | `@expo/vector-icons` (Ionicons) | Hệ thống biểu tượng giao diện chuẩn iOS & Material |

---

## 🏛️ Kiến Trúc Mã Nguồn

Dự án được tổ chức theo kiến trúc phân tầng rõ ràng (Layered Architecture):

```text
mooncake-mobile/
├── assets/                         # Tài nguyên tĩnh, biểu tượng vector, logo
├── src/
│   ├── api/
│   │   ├── apiClient.js            # Axios client tập trung, token interceptors, mock fallback
│   │   └── endpoints.js            # Mapping endpoint RESTful v1 từ Backend ASP.NET Core
│   ├── theme/
│   │   └── colors.js               # Design tokens hoàng gia: Crimson (#8C1524) & Gold (#D48806)
│   ├── context/
│   │   ├── AuthContext.js          # Quản lý phiên xác thực, token và thông tin người dùng
│   │   ├── CartContext.js          # Quản lý giỏ hàng và công thức chiết khấu bậc thang theo MOQ
│   │   └── NotificationContext.js  # Quản lý sự kiện thông báo và đếm số lượng chưa đọc
│   ├── services/
│   │   └── signalrService.js       # Client kết nối Hub SignalR thời gian thực (/hubs/notifications)
│   ├── components/
│   │   └── common/
│   │       ├── AppHeader.js        # Header dùng chung có navigation, title, sub-title & actions
│   │       ├── CustomButton.js     # Nút bấm tương tác hỗ trợ Primary, Secondary, Outline
│   │       └── ProductCard.js      # Card sản phẩm hiển thị đơn giá, badge in logo, chiết khấu sỉ
│   ├── navigation/
│   │   └── AppNavigator.js         # Hệ thống điều hướng Tab Bar (5 Tabs) & Stack Navigator
│   └── screens/
│       ├── Auth/                   # LoginScreen.js
│       ├── Home/                   # HomeScreen.js
│       ├── Catalog/                # SearchScreen.js, ProductDetailScreen.js
│       ├── Cart/                   # CartScreen.js, CheckoutScreen.js
│       ├── B2B/                    # CreateRfqScreen.js, RfqListScreen.js, RfqDetailBiddingScreen.js,
│       │                           # ContractsScreen.js, ContractSignScreen.js, DeliveryPoDScreen.js
│       ├── AI/                     # AiAssistantScreen.js
│       ├── Reviews/                # ReviewFormScreen.js
│       ├── Notification/           # NotificationScreen.js
│       └── Profile/                # ProfileScreen.js, OrderHistoryScreen.js
├── app.json
├── package.json
└── README.md
```

---

## 📦 Các Phân Hệ Chức Năng Chính

### 1. Xác Thực & Hồ Sơ Doanh Nghiệp (Auth & Profile)
- Hỗ trợ đăng nhập qua Số điện thoại / Email và mật khẩu.
- Tích hợp đăng nhập Google Doanh Nghiệp.
- Quản lý phiên làm việc tự động với JWT Access Token & Refresh Token.
- Quản lý thông tin doanh nghiệp, Mã số thuế (MST) và hotline hỗ trợ thu mua 24/7.

### 2. Khám Phá & Chi Tiết Biến Thể Bánh (Catalog & Variant Selection)
- Banner truyền thông mùa lễ hội phong cách hoàng gia Crimson Luxury & Warm Gold.
- Thanh tìm kiếm FTS thời gian thực và bộ lọc đa chiều (bánh nướng, bánh dẻo, in logo, chiết khấu cao).
- **Ràng buộc nghiệp vụ**: Bắt buộc chọn Biến thể (Variant) cụ thể trước khi thêm vào đơn hàng.
- Bảng giá bậc thang (Tiered Pricing) hiển thị phần trăm giảm giá theo số lượng đặt mua.

### 3. Đặt Hàng B2B & Giỏ Hàng Chiết Khấu Sỉ (Bulk Ordering & Cart)
- Tự động áp dụng mức chiết khấu bậc thang (5%, 10%, 15%, 18%) tương ứng với số lượng hộp trong giỏ hàng.
- Biểu mẫu giao nhận doanh nghiệp: Xuất hóa đơn VAT, địa chỉ kho nhận, yêu cầu bảo quản.
- Hỗ trợ đa dạng phương thức thanh toán: Cổng VNPay / Mobile Banking QR, Ký quỹ SafeTrade Escrow, COD.
- Quản lý lịch sử đơn hàng theo trạng thái: Chờ duyệt, Đang sản xuất, Đã giao PoD.

### 4. Đấu Thầu B2B & So Sánh Báo Giá (RFQ & Bidding Center)
- Tạo yêu cầu báo giá RFQ: Thiết lập số lượng dự kiến, khoảng ngân sách min–max, ngày nhận hàng, yêu cầu ép kim logo nhận diện.
- So sánh các gói báo giá (Bids) từ các xưởng bánh cạnh tranh trên bảng đối chiếu trực quan.
- Thao tác chấp thuận báo giá (**Accept Bid**): Chốt xưởng trúng thầu và tự động khởi tạo dự thảo hợp đồng điện tử.

### 5. Hợp Đồng Điện Tử & Ký Số OTP (e-Contract & Milestones)
- Preview nội dung dự thảo hợp đồng điện tử và cam kết chế tài vi phạm.
- Xác thực ký số di động bằng mã OTP SMS 6 chữ số có đếm ngược gửi lại.
- Quản lý tiến độ thanh toán theo mốc (**Milestones**):
  - **M1 (Đặt cọc 30%)**: Kích hoạt hợp đồng sang trạng thái Active để xưởng bắt đầu sản xuất.
  - **M2 (Giao hàng đợt 1 - 50%)**: Nghiệm thu đợt đầu kiện hàng.
  - **M3 (Quyết toán 20%)**: Nghiệm thu toàn bộ và tất toán hợp đồng.

### 6. Giám Sát Vận Chuyển Xe Lạnh & Ảnh Bàn Giao PoD (Logistics & PoD)
- Timeline cập nhật hành trình vận chuyển thời gian thực.
- Kiểm tra thông số nhiệt độ thùng xe lạnh bảo quản bánh (20.5 °C).
- Xem ảnh chụp bàn giao thực tế (**Proof of Delivery - PoD**) gồm ảnh kiện hàng nguyên niêm phong và ảnh chữ ký xác nhận của đại diện nhận hàng.
- Xác thực dấu thời gian (Timestamp) và tọa độ vị trí GPS giao hàng.

### 7. Trợ Lý Ảo AI & Đánh Giá 4 Tiêu Chí (AI Assistant & Reviews)
- Cửa sổ chat AI tích hợp RAG: Tư vấn lập ngân sách theo số lượng nhân sự, phân tích khẩu vị nhân bánh phù hợp từng nhóm đối tác.
- Đánh giá chất lượng sau giao hàng theo 4 tiêu chí chuẩn:
  1. Hương vị & chất lượng bánh
  2. Đúng hẹn giao hàng (xe lạnh)
  3. Dịch vụ hỗ trợ & chăm sóc
  4. Quy cách đóng gói & ép kim logo
- Tải ảnh chụp thực tế kiện hàng sau khi mở hộp để cộng điểm uy tín cho xưởng bánh.

### 8. Trung Tâm Thông Báo Thời Gian Thực (SignalR Notifications)
- Kết nối WebSocket hai chiều tới Backend `NotificationHub`.
- Bắn thông báo tức thì khi có xưởng nộp Bid mới, trạng thái hợp đồng thay đổi hoặc nhắc hạn thanh toán đặt cọc M1.

---

## 🎨 Hệ Thống Nhận Diện & Design Tokens

Bộ màu nhận diện được đồng bộ chặt chẽ với cổng thông tin Web:

| Tên Token | Mã Hex | Ý Nghĩa Sử Dụng |
| :--- | :--- | :--- |
| **Primary** | `#8C1524` | Đỏ Crimson hoàng gia – màu chủ đạo các nút bấm, thương hiệu |
| **Primary Dark** | `#5E0E18` | Đỏ sẫm vương giả – nền thẻ Profile, Header chính |
| **Accent Gold** | `#D48806` | Vàng Gold – điểm nhấn huy hiệu, icon sao đánh giá, viền hộp quà |
| **Background** | `#FDFBF7` | Nền giấy lụa ngà – nền ứng dụng tạo cảm giác trang trọng |
| **Surface** | `#FFFFFF` | Nền thẻ nổi – card sản phẩm, form nhập liệu |
| **Text Primary**| `#1F1F1F` | Màu chữ chính – độ tương phản cao, dễ đọc trên di động |

---

## 🌐 Cấu Hình Môi Trường & Kết Nối Backend

Các endpoint API được cấu hình tập trung tại file [src/api/endpoints.js](file:///d:/FPT-STUDY/10_FALL-2026/PRN232/Github/mooncake-mobile/src/api/endpoints.js):

- **Android Emulator**: `http://10.0.2.2:8089/api/v1`
- **iOS Simulator**: `http://localhost:8089/api/v1`
- **Thiết bị thật (Physical Device)**: Sử dụng IP mạng nội bộ của máy tính chạy backend (ví dụ: `http://192.168.1.15:8089/api/v1`).

---

## 🚀 Hướng Dẫn Cài Đặt & Khởi Chạy

### Yêu cầu tiên quyết:
- **Node.js** >= 20.x
- **Expo Go** app cài đặt trên điện thoại Android/iOS hoặc Trình giả lập (Android Emulator / iOS Simulator)

### Khởi chạy dự án:
```bash
# 1. Di chuyển vào thư mục ứng dụng mobile
cd mooncake-mobile

# 2. Cài đặt các gói thư viện
npm install --legacy-peer-deps

# 3. Khởi chạy máy chủ phát triển Expo
npx expo start
```

### Thao tác trên thiết bị:
- Quét mã QR bằng ứng dụng **Expo Go** (Android) hoặc Camera (iOS).
- Bấm phím `a` trên terminal để mở Android Emulator.
- Bấm phím `w` để mở xem trước trên trình duyệt Web.

# 4. Đẩy lên nhánh tính năng tương ứng trên GitHub
git push origin feature/<tên-tính-năng>
```
