# 🥮 Nguyệt Phố B2B - Mobile Application (Customer App)

> **Ứng dụng di động mua sắm & đấu thầu B2B Bánh Trung Thu Hoàng Gia dành cho Khách hàng doanh nghiệp và người mua sỉ.**  
> Kết nối trực tiếp với backend ASP.NET Core 8 Clean Architecture (`mooncake-ecommerce-platform`) và đồng bộ trải nghiệm với web frontend (`mooncake-fe`).

---

## 📱 Tính Năng Đã Triển Khai (Giai Đoạn 1 - MVP Core)

1. **Xác thực & Quản lý Phiên (Authentication & Session)**:
   - Đăng nhập Số điện thoại / Mật khẩu cho khách hàng B2B.
   - Hỗ trợ đăng nhập Google Doanh Nghiệp.
   - Quản lý JWT Token tự động qua `AsyncStorage` và Axios Interceptor.
   - Cơ chế fallback demo mode mượt mà khi môi trường backend offline.

2. **Trang Chủ & Khám Phá (Home & Discovery)**:
   - Banner lễ hội Trung Thu phong cách hoàng gia Crimson & Gold.
   - Trust Badges B2B: Ký quỹ an toàn SafeTrade, e-Contract OTP, Giao xe lạnh PoD.
   - Phân loại danh mục: Hộp Quà Cao Cấp, Set Doanh Nghiệp, Bánh Dẻo Nghệ Nhân.
   - Bộ sưu tập bánh nổi bật kèm tag giảm giá sỉ theo số lượng.

3. **Tìm Kiếm & Bộ Lọc Nâng Cao (Search & Multi-filter)**:
   - Tìm kiếm thời gian thực theo tên bánh, xưởng nghệ nhân, hương vị.
   - Lọc nhanh: Hỗ trợ in logo công ty, Chiết khấu ≥ 15%, Bánh nướng, Bánh dẻo.

4. **Chi Tiết Sản Phẩm & Chọn Biến Thể (Product Detail & Variant Selection)**:
   - **Bắt buộc chọn Biến thể (Variant)** theo đúng quy định nghiệp vụ Module 3 của Backend (loại vỏ, nhân, trọng lượng).
   - **Bảng giá bậc thang (Tiered Pricing)**: Tự động hiển thị mức giảm giá tương ứng với số lượng đặt.
   - Tính toán tạm tính giá trị đơn hàng tức thì.

5. **Giỏ Hàng & Tự Động Tính Chiết Khấu Sỉ (Cart & Tiered Discount)**:
   - Quản lý giỏ hàng theo từng biến thể sản phẩm.
   - Tự động áp dụng mức chiết khấu bậc thang theo số lượng (5%, 10%, 15%, 18%).
   - Tóm tắt hóa đơn: Tổng tiền thô, tiền chiết khấu được giảm, tổng thanh toán.

6. **Đặt Hàng & Thanh Toán (Checkout & Orders)**:
   - Biểu mẫu thông tin giao hàng doanh nghiệp, xuất hóa đơn VAT, ghi chú bảo quản xe lạnh.
   - Lựa chọn phương thức thanh toán: VNPay / Mobile Banking VietQR, SafeTrade Escrow, COD.
   - Gửi đơn hàng về Backend (`/api/v1/orders`).

7. **Lịch Sử Đơn Hàng & Hồ Sơ Doanh Nghiệp (Orders & Profile)**:
   - Theo dõi danh sách đơn hàng (`/api/v1/orders/mine`) theo các trạng thái: Chờ xác nhận, Đang sản xuất, Đã bàn giao PoD.
   - Quản lý thông tin doanh nghiệp, Mã số thuế (MST), hotline hỗ trợ thu mua 24/7.

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
