# 🥮 Nguyệt Phố B2B - Mobile Application (Customer App)

> **Ứng dụng di động mua sắm & đấu thầu B2B Bánh Trung Thu Hoàng Gia dành cho Khách hàng doanh nghiệp và người mua sỉ.**  
> Kết nối trực tiếp với backend ASP.NET Core 8 Clean Architecture (`mooncake-ecommerce-platform`) và đồng bộ trải nghiệm với web frontend (`mooncake-fe`).

---

## 📱 Tính Năng Đã Triển Khai

### Giai Đoạn 1 (MVP Core)
1. **Xác thực & Quản lý Phiên (Authentication & Session)**: Đăng nhập SĐT/Email, Google OAuth, JWT Token Interceptor.
2. **Trang Chủ & Khám Phá (Home & Discovery)**: Banner Mùa Trăng 2026, Trust Badges, Danh mục, Sản phẩm nổi bật.
3. **Tìm Kiếm & Bộ Lọc (Search & Multi-filter)**: FTS, lọc vỏ nướng/dẻo, in logo, chiết khấu sỉ.
4. **Chi Tiết Sản Phẩm & Biến Thể (Product Detail & Variant)**: Bắt buộc chọn Variant, Bảng giá bậc thang (Tiered Pricing).
5. **Giỏ Hàng & Tính Chiết Khấu Sỉ (Cart & Tiered Discount)**: Tự động tính chiết khấu theo số lượng.
6. **Đặt Hàng & Thanh Toán (Checkout & Orders)**: Form giao nhận công ty, hóa đơn VAT, thanh toán VNPay / SafeTrade Escrow / COD.
7. **Lịch Sử Đơn Hàng & Hồ Sơ (Orders & Profile)**: Theo dõi trạng thái đơn hàng và hồ sơ MST.

### Giai Đoạn 2 (Phân Hệ B2B Đặc Thù)
8. **Đấu Thầu RFQ (Request for Quote)**:
   - Tạo gói thầu B2B (`CreateRfqScreen`): số lượng, ngân sách, ngày nhận hàng, yêu cầu in ấn logo.
   - Quản lý danh sách gói thầu cá nhân (`RfqListScreen`).
9. **So Sánh Báo Giá Side-by-Side (Bidding Comparison)**:
   - Hiển thị danh sách các Bid do các xưởng nộp lên (`RfqDetailBiddingScreen`).
   - So sánh đơn giá, tổng tiền, thời gian giao hàng, điểm uy tín của xưởng.
   - Thao tác **Chấp nhận Báo giá (Accept Bid)**: Chốt xưởng trúng thầu và tự động sinh Dự thảo hợp đồng điện tử.
10. **Hợp Đồng Điện Tử & Ký Số OTP (e-Contract & Milestones)**:
    - Quản lý danh sách hợp đồng điện tử (`ContractsScreen`).
    - Ký số di động bằng mã OTP SMS (`ContractSignScreen`).
    - Quản lý và kích hoạt mốc **Đặt cọc M1 (30%)** để xưởng chuyển sang trạng thái sản xuất.
11. **Trung Tâm Thông Báo Thời Gian Thực (SignalR Real-time Notifications)**:
    - Tích hợp `@microsoft/signalr` kết nối tới `/api/v1/hubs/notifications`.
    - Nhận thông báo tức thì khi có xưởng nộp Bid mới hoặc trạng thái hợp đồng thay đổi (`NotificationScreen`).

---

## 🎨 Design System & Theme Tokens

- **Primary Color:** `#8C1524` (Đỏ Crimson hoàng gia)
- **Accent Color:** `#D48806` (Vàng Gold vương giả)
- **Background:** `#FDFBF7` (Giấy lụa ngà)
- **Surface:** `#FFFFFF` (Bề mặt thẻ nổi)
- **Text:** `#1F1F1F` (Charcoal đậm)

---

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu cầu tiên quyết:
- **Node.js** >= 20.x
- **Expo CLI** / **Expo Go** app trên điện thoại Android hoặc iOS

### Các bước khởi chạy:
```bash
# 1. Di chuyển vào thư mục mobile
cd mooncake-mobile

# 2. Cài đặt dependencies (nếu chưa cài)
npm install --legacy-peer-deps

# 3. Khởi chạy Expo Dev Server
npx expo start
```

### Mở ứng dụng:
- Quét mã QR bằng app **Expo Go** trên điện thoại Android / iOS.
- Hoặc bấm phím `a` để mở trên Android Emulator.
- Hoặc bấm phím `w` để mở trên trình duyệt Web.

---

## 🌐 Cấu Hình Kết Nối Backend ASP.NET Core 8

Trong file `src/api/endpoints.js`:
- Android Emulator: Dùng `http://10.0.2.2:8089/api/v1`
- iOS Simulator: Dùng `http://localhost:8089/api/v1`
- Thiết bị thật: Đổi sang IP mạng nội bộ của máy tính chạy backend (ví dụ `http://192.168.1.15:8089/api/v1`).

---

## 🗺️ Lộ Trình Giai Đoạn Tiếp Theo

- **Giai đoạn 2**:
  - Tích hợp SignalR Real-time Notification Hub (`/api/v1/hubs/notifications`).
  - Phân hệ Đấu thầu RFQ: Tạo RFQ và so sánh Bids trực quan từ nhiều xưởng.
  - Phân hệ e-Contract: Trình đọc PDF hợp đồng & Ký số bằng OTP SMS.
- **Giai đoạn 3**:
  - Giám sát hành trình xe lạnh và kiểm tra ảnh bàn giao PoD kèm GPS.
  - Trợ lý ảo AI Chatbot tư vấn phong thủy và set quà Trung Thu.

