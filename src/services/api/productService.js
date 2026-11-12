// Ported from mooncake-fe/src/services/productService.js — keep both in sync.
import { apiClient } from '../../api/apiClient';
import { API_ENDPOINTS } from '../../api/apiEndpoints';

const unwrap = (response) => response.data;
const headers = (key) => ({ headers: { 'Idempotency-Key': key } });

const serializeParams = (params) => {
  const searchParams = new URLSearchParams();
  Object.entries(params || {}).forEach(([key, value]) => {
    if (value === undefined || value === null || value === '') return;
    if (Array.isArray(value)) {
      value.forEach((item) => {
        if (item !== undefined && item !== null && item !== '') {
          searchParams.append(key, String(item));
        }
      });
      return;
    }
    searchParams.append(key, String(value));
  });
  return searchParams.toString();
};

const getPublic = (path, params, signal) => apiClient.get(path, {
  params,
  paramsSerializer: { serialize: serializeParams },
  signal,
  skipAuthHeader: true,
  skipAuthRefresh: true,
}).then(unwrap);
const write = (method, path, body, key) => apiClient[method](path, body, headers(key)).then(unwrap);

export const productService = {
  search: (params, signal) => getPublic(API_ENDPOINTS.PRODUCTS.LIST, params, signal),
  autocomplete: (params, signal) => getPublic(API_ENDPOINTS.PRODUCTS.AUTOCOMPLETE, params, signal),
  detail: (id, signal) => getPublic(API_ENDPOINTS.PRODUCTS.DETAILS(id), undefined, signal),
  related: (id, signal) => getPublic(API_ENDPOINTS.PRODUCTS.RELATED(id), undefined, signal),
  recommendations: (params, signal) => getPublic(API_ENDPOINTS.PRODUCTS.RECOMMENDATIONS, params, signal),
  categories: (signal) => getPublic(API_ENDPOINTS.PRODUCTS.CATEGORIES, undefined, signal),
  getCategories: (signal) => getPublic(API_ENDPOINTS.PRODUCTS.CATEGORIES, undefined, signal),
  regions: (signal) => getPublic(API_ENDPOINTS.PRODUCTS.REGIONS, undefined, signal),
  recordView: (id, body) => apiClient.post(API_ENDPOINTS.PRODUCTS.VIEW(id), body).then(unwrap),

  mine: (params, signal) => apiClient.get(API_ENDPOINTS.PRODUCTS.MINE, { params, signal }).then(unwrap),
  mineDetail: (id, signal) => apiClient.get(API_ENDPOINTS.PRODUCTS.MINE_DETAIL(id), { signal }).then(unwrap),
  create: (body, key) => write('post', API_ENDPOINTS.PRODUCTS.MINE, body, key),
  update: (id, body, key) => write('put', API_ENDPOINTS.PRODUCTS.MINE_DETAIL(id), body, key),
  addVariant: (id, body, key) => write('post', API_ENDPOINTS.PRODUCTS.VARIANTS(id), body, key),
  updateVariant: (id, variantId, body, key) => write('put', API_ENDPOINTS.PRODUCTS.VARIANT(id, variantId), body, key),
  deleteVariant: (id, variantId, expectedVersion, key) => apiClient.delete(
    API_ENDPOINTS.PRODUCTS.VARIANT(id, variantId), { params: { expectedVersion }, ...headers(key) },
  ).then(unwrap),
  adjustInventory: (id, variantId, body, key) => write('post', API_ENDPOINTS.PRODUCTS.INVENTORY(id, variantId), body, key),
  gallery: (id, body, key) => write('put', API_ENDPOINTS.PRODUCTS.GALLERY(id), body, key),
  publication: (id, body, key) => write('patch', API_ENDPOINTS.PRODUCTS.PUBLICATION(id), body, key),
  remove: (id, expectedVersion, key) => apiClient.delete(
    API_ENDPOINTS.PRODUCTS.MINE_DETAIL(id), { params: { expectedVersion }, ...headers(key) },
  ).then(unwrap),
  async uploadMedia(file, purpose, key) {
    const form = new FormData();
    form.append('file', file);
    form.append('purpose', purpose);
    return unwrap(await apiClient.post(API_ENDPOINTS.PRODUCTS.MEDIA, form, { ...headers(key), timeout: 90000 }));
  },
};

export default productService;
