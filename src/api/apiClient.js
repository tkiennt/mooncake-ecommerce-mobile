/**
 * Centralized Axios Client for Mobile
 * Tích hợp interceptor gắn JWT token và fallback mock data khi chạy offline
 */

import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { API_BASE_URL, ENDPOINTS } from './endpoints';

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
});

// Interceptor: Tự động đính kèm Bearer Token
apiClient.interceptors.request.use(
  async (config) => {
    try {
      const token = await AsyncStorage.getItem('@auth_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    } catch (e) {
      console.warn('Lỗi khi đọc token từ AsyncStorage:', e);
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Interceptor: unwrap the body; on 401 refresh the token pair once and retry (same flow as web).
let refreshPromise = null;
const refreshAccessToken = async () => {
  const refreshToken = await AsyncStorage.getItem('@refresh_token');
  if (!refreshToken) throw new Error('Phiên đăng nhập đã hết hạn.');
  const body = await axios.post(`${API_BASE_URL}${ENDPOINTS.REFRESH_TOKEN}`, { refreshToken });
  const { accessToken, refreshToken: nextRefresh } = body?.data?.data || {};
  if (!accessToken || !nextRefresh) throw new Error('Phiên đăng nhập đã hết hạn.');
  await AsyncStorage.multiSet([['@auth_token', accessToken], ['@refresh_token', nextRefresh]]);
  return accessToken;
};

apiClient.interceptors.response.use(
  (response) => response.data,
  async (error) => {
    const original = error.config;
    if (error.response?.status === 401 && original && !original._retried && !original.url?.includes('/auth/')) {
      original._retried = true;
      try {
        refreshPromise = refreshPromise || refreshAccessToken().finally(() => { refreshPromise = null; });
        const accessToken = await refreshPromise;
        original.headers.Authorization = `Bearer ${accessToken}`;
        return apiClient(original);
      } catch {
        await AsyncStorage.multiRemove(['@auth_token', '@refresh_token', '@user_profile']);
      }
    }
    return Promise.reject(error);
  }
);

// Mock catalog fallback cho Giai đoạn 1 khi chưa chạy Backend
export const MOCK_PRODUCTS = [
  {
    id: 'prod-001',
    name: 'Hộp Hoàng Triều Thượng Hạng (4 Bánh + Trà Ô Long)',
    shopName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    category: 'Hộp Quà Cao Cấp',
    coverImage: require('../../assets/products/hop-son-mai.jpg'),
    soldCount: 1240,
    shopCity: 'Hà Nội',
    basePrice: 650000,
    minOrderQty: 10,
    maxOrderQty: 5000,
    rating: 4.9,
    reviewCount: 128,
    isCustomPackagingSupported: true,
    description: 'Bộ sưu tập quà tặng Trung Thu hoàng gia với 4 vị bánh nghệ nhân hảo hạng, hộp sơn mài đỏ lụa dập kim biểu tượng trăng tròn sum vầy.',
    variants: [
      { id: 'var-101', name: 'Thập Cẩm Gà Quay Vi Cá (180g)', crustType: 'Bánh nướng', filling: 'Thập cẩm vi cá', priceAdjustment: 0, stock: 250 },
      { id: 'var-102', name: 'Đậu Xanh Hạt Sen Hạnh Nhân (180g)', crustType: 'Bánh nướng', filling: 'Đậu xanh sen', priceAdjustment: -30000, stock: 300 },
      { id: 'var-103', name: 'Lava Trứng Chảy Hồng Kông (150g)', crustType: 'Bánh tuyết (Snow-skin)', filling: 'Lava trứng muối', priceAdjustment: 20000, stock: 180 },
    ],
    tierPricing: [
      { minQty: 10, maxQty: 49, discountPercent: 5 },
      { minQty: 50, maxQty: 199, discountPercent: 10 },
      { minQty: 200, maxQty: 1000, discountPercent: 15 },
    ],
  },
  {
    id: 'prod-002',
    name: 'Hộp Nguyệt Dạ Thưởng Hoa (6 Bánh Nghệ Thuật)',
    shopName: 'Tiệm Bánh Thủ Công An Lạc',
    category: 'Set Doanh Nghiệp',
    coverImage: require('../../assets/products/banh-nuong.jpg'),
    soldCount: 860,
    shopCity: 'TP. Hồ Chí Minh',
    basePrice: 880000,
    minOrderQty: 20,
    maxOrderQty: 3000,
    rating: 4.8,
    reviewCount: 94,
    isCustomPackagingSupported: true,
    description: 'Thiết kế sang trọng dành riêng cho quà biếu đối tác chiến lược. Hỗ trợ in logo doanh nghiệp ép kim nổi, lời chúc mạ vàng.',
    variants: [
      { id: 'var-201', name: 'Hạt Sen Trà Xanh Matcha Nhật (150g)', crustType: 'Bánh dẻo', filling: 'Matcha sen', priceAdjustment: 0, stock: 400 },
      { id: 'var-202', name: 'Tiramisu Cacao Mascarpone (150g)', crustType: 'Hiện đại', filling: 'Tiramisu', priceAdjustment: 40000, stock: 150 },
    ],
    tierPricing: [
      { minQty: 20, maxQty: 99, discountPercent: 8 },
      { minQty: 100, maxQty: 499, discountPercent: 12 },
      { minQty: 500, maxQty: 3000, discountPercent: 18 },
    ],
  },
  {
    id: 'prod-003',
    name: 'Bánh Dẻo Tuyết Ngọc Ngân Hà (Hộp 4 Bánh)',
    shopName: 'Bảo Ngọc Đường',
    category: 'Bánh Dẻo Nghệ Nhân',
    coverImage: require('../../assets/products/banh-deo.jpg'),
    soldCount: 415,
    shopCity: 'Huế',
    basePrice: 420000,
    minOrderQty: 5,
    maxOrderQty: 1000,
    rating: 4.7,
    reviewCount: 65,
    isCustomPackagingSupported: false,
    description: 'Bánh dẻo thủ công gia truyền làm từ nếp cái hoa vàng, nhân dừa non sợi và lá dứa thanh mát, vị ngọt thanh tự nhiên.',
    variants: [
      { id: 'var-301', name: 'Dừa Non Sữa Tươi (120g)', crustType: 'Bánh dẻo', filling: 'Dừa non', priceAdjustment: 0, stock: 120 },
      { id: 'var-302', name: 'Khoai Môn Hạt Sen (120g)', crustType: 'Bánh dẻo', filling: 'Khoai môn', priceAdjustment: 10000, stock: 90 },
    ],
    tierPricing: [
      { minQty: 5, maxQty: 29, discountPercent: 5 },
      { minQty: 30, maxQty: 100, discountPercent: 10 },
    ],
  },
  {
    id: 'prod-004',
    name: 'Bánh nướng dinh dưỡng ít đường (Hộp 4 bánh)',
    shopName: 'Xưởng Bánh Nghệ Nhân Kinh Đô Cổ',
    category: 'Bánh Dẻo Nghệ Nhân',
    coverImage: require('../../assets/products/banh-dinh-duong.jpg'),
    soldCount: 2310,
    shopCity: 'Hà Nội',
    basePrice: 360000,
    minOrderQty: 10,
    maxOrderQty: 2000,
    rating: 4.8,
    reviewCount: 212,
    isCustomPackagingSupported: true,
    description: 'Vỏ bánh nướng nguyên cám, nhân hạt sen và hạt điều ít đường, phù hợp quà tặng cho đối tác quan tâm sức khỏe.',
    variants: [
      { id: 'var-401', name: 'Hạt sen hạt điều (150g)', crustType: 'Bánh nướng', filling: 'Hạt sen', priceAdjustment: 0, stock: 500 },
    ],
    tierPricing: [
      { minQty: 10, maxQty: 99, discountPercent: 6 },
      { minQty: 100, maxQty: 2000, discountPercent: 12 },
    ],
  },
];

