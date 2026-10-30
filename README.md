# 🥮 Nguyệt Phố B2B - Mobile Application (Customer App)

> **Cổng Mua Sắm & Đấu Thầu Quà Tặng Trung Thu Doanh Nghiệp (Mobile Client).**  
> Kết nối trực tiếp với backend ASP.NET Core 8 Clean Architecture (`mooncake-ecommerce-platform`) và đồng bộ hệ thống nhận diện với web (`mooncake-fe`).

---

## 🌿 Chiến Lược Nhánh Git (Git Branching Strategy)

Dự án áp dụng mô hình phân nhánh theo tính năng chuẩn doanh nghiệp (**Feature-based Branching Workflow**):

```text
main (Nhánh production ổn định)
  ├── feature/auth-profile                (Xác thực, phân quyền & hồ sơ doanh nghiệp)
  ├── feature/product-catalog             (Khám phá, danh mục & chi tiết biến thể)
  ├── feature/b2b-bulk-order-cart         (Giỏ hàng, chiết khấu bậc thang & đặt hàng VNPay)
  ├── feature/b2b-rfq-bidding             (Mở thầu RFQ & so sánh báo giá cạnh tranh)
  ├── feature/econtract-milestone         (Hợp đồng điện tử, ký số OTP & mốc đặt cọc M1)
  ├── feature/realtime-notifications      (Thông báo thời gian thực qua SignalR Hub)
  ├── feature/logistics-delivery-pod      (Giám sát vận chuyển xe lạnh & ảnh bàn giao PoD)
  └── feature/ai-assistant-reviews        (Trợ lý AI tư vấn quà tặng & đánh giá 4 tiêu chí)
```

### 📌 Quy định bắt buộc:
1. Mỗi tính năng được phát triển trên nhánh riêng biệt với tiền tố: `feature/<tên-tính-năng>`.
2. Sau khi hoàn thành và kiểm thử tính năng (Definition of Done), tiến hành commit và **push trực tiếp lên branch feature tương ứng trên GitHub**.
3. Tích hợp định kỳ vào nhánh `main` để kiểm thử toàn diện.

---

## 📋 Bảng Danh Mục Tính Năng & Trạng Thái Nhánh

| Mã Feature | Tên Nhánh Git | Phân Hệ Backend / API Controller | Mô Tả Nghiệp Vụ Chính | Trạng Thái |
| :--- | :--- | :--- | :--- | :---: |
| **F1** | `feature/auth-profile` | Module 1 (`AuthController`, `UsersController`) | Đăng nhập SĐT/Email, Google OAuth, lưu JWT qua AsyncStorage, hồ sơ công ty & MST. | ✅ **Đã hoàn thành** |
| **F2** | `feature/product-catalog` | Module 3 (`ProductsController`, `CatalogMetadataController`) | Banner hoàng gia, FTS Search, lọc vỏ/nhân, bắt buộc chọn Biến thể (Variant), bảng giá bậc thang. | ✅ **Đã hoàn thành** |
| **F3** | `feature/b2b-bulk-order-cart` | Module 4 & 10 (`OrdersController`, `PaymentsController`) | Giỏ hàng tự động chiết khấu sỉ theo MOQ, checkout xuất hóa đơn VAT, thanh toán VNPay / Escrow / COD. | ✅ **Đã hoàn thành** |
| **F4** | `feature/b2b-rfq-bidding` | Module 5 (`RfqsController`) | Mở thầu RFQ, so sánh Bids side-by-side từ nhiều xưởng, thao tác Accept Bid chuyển đổi sang hợp đồng. | ✅ **Đã hoàn thành** |
| **F5** | `feature/econtract-milestone` | Module 6 (`ContractsController`) | Xem dự thảo e-Contract, ký số bằng mã OTP SMS 6 số, quản lý tiến độ Milestone M1 đặt cọc 30%. | ✅ **Đã hoàn thành** |
| **F6** | `feature/realtime-notifications` | Module 11 (`NotificationHub`, SignalR) | Lắng nghe sự kiện WebSocket thời gian thực khi có Bid mới, thay đổi hợp đồng, nhắc nợ cọc M1. | ✅ **Đã hoàn thành** |
| **F7** | `feature/logistics-delivery-pod` | Module 7 (`DeliveriesController`) | Theo dõi hành trình xe lạnh, kiểm tra ảnh chụp bàn giao thực tế (PoD), chữ ký và tọa độ GPS. | ⏳ **Đang triển khai** |
| **F8** | `feature/ai-assistant-reviews` | Module 8 & 9 (`AiChatController`, `ReviewsController`) | Trợ lý RAG tư vấn chọn vị bánh theo ngân sách, đánh giá đơn hàng 4 tiêu chí kèm ảnh thực tế. | ⏳ **Kế hoạch tiếp theo** |

---

## 📁 Cấu Trúc Thư Mục Chuẩn Hóa

```text
mooncake-mobile/
├── assets/                         # Icons, hình ảnh mẫu, logo vector
├── src/
│   ├── api/
│   │   ├── apiClient.js            # Axios client tập trung, tự động gắn JWT Bearer, Mock fallback
│   │   └── endpoints.js            # Mapping toàn bộ endpoint RESTful v1
│   ├── theme/
│   │   └── colors.js               # Design tokens hoàng gia: Crimson (#8C1524) & Gold (#D48806)
│   ├── context/
│   │   ├── AuthContext.js          # Quản lý phiên đăng nhập & thông tin doanh nghiệp
│   │   ├── CartContext.js          # Quản lý giỏ hàng & tính chiết khấu số lượng bậc thang
│   │   └── NotificationContext.js  # Quản lý thông báo & đếm tin chưa đọc
│   ├── services/
│   │   └── signalrService.js       # Client kết nối Hub SignalR thời gian thực
│   ├── components/
│   │   └── common/
│   │       ├── AppHeader.js        # Header chuẩn hóa có nút Back, Title, Subtitle, Right Action
│   │       ├── CustomButton.js     # Nút bấm Primary, Secondary, Outline có loading spinner
│   │       └── ProductCard.js      # Thẻ sản phẩm hiển thị giá, badge in logo, chiết khấu sỉ
│   ├── navigation/
│   │   └── AppNavigator.js         # Bottom Tab Navigator (5 Tabs) & Root Stack Navigator
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

## 🚀 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### Yêu cầu môi trường:
- **Node.js** >= 20.x
- **Expo CLI** (tích hợp sẵn trong package)
- Thiết bị thật có cài app **Expo Go** (Android/iOS) hoặc Trình giả lập (Android Emulator / iOS Simulator)

### Khởi chạy:
```bash
# 1. Di chuyển vào thư mục dự án
cd mooncake-mobile

# 2. Cài đặt các gói phụ thuộc
npm install --legacy-peer-deps

# 3. Chạy máy chủ Metro bundler
npx expo start
```

---

## 🛠️ Quy Trình Làm Việc Với Feature Branches

Khi nhận task hoặc bắt đầu phát triển tính năng mới:
```bash
# 1. Checkout sang branch tính năng tương ứng
git checkout feature/<tên-tính-năng>

# 2. Thực hiện code và kiểm thử giao diện
# 3. Commit thay đổi
git add .
git commit -m "feat(<feature>): mô tả thay đổi"

# 4. Push lên đúng branch tính năng trên GitHub
git push origin feature/<tên-tính-năng>
```
