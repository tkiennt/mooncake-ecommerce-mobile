import { useEffect, useState } from 'react';
import { productService } from '../services/api/productService';
import { MOCK_PRODUCTS } from '../api/apiClient';
import { toMobileProduct } from '../api/mappers';

/**
 * Public catalog from GET /api/v1/products (q, page, pageSize…).
 * Falls back to the bundled demo products only when the backend cannot be reached.
 * source: 'api' | 'demo'
 */
export function useCatalogProducts({ q = '', pageSize = 40, debounceMs = 300 } = {}) {
  const [state, setState] = useState({ products: MOCK_PRODUCTS, source: 'demo', loading: true, error: null });

  useEffect(() => {
    const controller = new AbortController();
    const timer = setTimeout(async () => {
      try {
        const page = await productService.search({ q: q.trim() || undefined, page: 1, pageSize }, controller.signal);
        const items = (page?.items || []).map(toMobileProduct);
        setState({ products: items, source: 'api', loading: false, error: null, totalCount: page?.totalCount ?? items.length });
      } catch (error) {
        if (controller.signal.aborted) return;
        if (!error?.response) {
          setState({ products: MOCK_PRODUCTS, source: 'demo', loading: false, error: null });
        } else {
          setState((cur) => ({ ...cur, loading: false, error }));
        }
      }
    }, debounceMs);
    return () => { clearTimeout(timer); controller.abort(); };
  }, [q, pageSize, debounceMs]);

  return state;
}
