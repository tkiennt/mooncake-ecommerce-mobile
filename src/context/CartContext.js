/**
 * CartContext for Mobile App
 * Xử lý giỏ hàng, chọn biến thể (Variant) bắt buộc, và tính chiết khấu số lượng bậc thang
 */

import React, { createContext, useState, useContext } from 'react';

const CartContext = createContext();

export const CartProvider = ({ children }) => {
  const [cartItems, setCartItems] = useState([]);

  // Thêm vào giỏ hàng
  const addToCart = (product, variant, quantity) => {
    setCartItems((prevItems) => {
      const existingIndex = prevItems.findIndex(
        (item) => item.product.id === product.id && item.variant.id === variant.id
      );

      if (existingIndex > -1) {
        const updated = [...prevItems];
        updated[existingIndex].quantity += quantity;
        return updated;
      } else {
        return [...prevItems, { product, variant, quantity }];
      }
    });
  };

  // Cập nhật số lượng
  const updateQuantity = (productId, variantId, newQty) => {
    if (newQty <= 0) {
      removeFromCart(productId, variantId);
      return;
    }
    setCartItems((prev) =>
      prev.map((item) =>
        item.product.id === productId && item.variant.id === variantId
          ? { ...item, quantity: newQty }
          : item
      )
    );
  };

  // Xóa khỏi giỏ
  const removeFromCart = (productId, variantId) => {
    setCartItems((prev) =>
      prev.filter(
        (item) => !(item.product.id === productId && item.variant.id === variantId)
      )
    );
  };

  // Làm rỗng giỏ
  const clearCart = () => setCartItems([]);

  // Tính chiết khấu bậc thang theo số lượng cho từng sản phẩm
  const calculateItemDiscount = (item) => {
    const unitPrice = item.product.basePrice + (item.variant.priceAdjustment || 0);
    const subtotal = unitPrice * item.quantity;
    let discountPercent = 0;

    if (item.product.tierPricing && item.product.tierPricing.length > 0) {
      for (const tier of item.product.tierPricing) {
        if (item.quantity >= tier.minQty && (!tier.maxQty || item.quantity <= tier.maxQty)) {
          discountPercent = Math.max(discountPercent, tier.discountPercent);
        }
      }
    }

    const discountAmount = Math.round((subtotal * discountPercent) / 100);
    return {
      unitPrice,
      subtotal,
      discountPercent,
      discountAmount,
      total: subtotal - discountAmount,
    };
  };

  // Tổng giá trị giỏ hàng
  const getCartTotals = () => {
    let rawSubtotal = 0;
    let totalDiscount = 0;
    let finalTotal = 0;
    let totalItems = 0;

    cartItems.forEach((item) => {
      const calc = calculateItemDiscount(item);
      rawSubtotal += calc.subtotal;
      totalDiscount += calc.discountAmount;
      finalTotal += calc.total;
      totalItems += item.quantity;
    });

    return { rawSubtotal, totalDiscount, finalTotal, totalItems };
  };

  return (
    <CartContext.Provider
      value={{
        cartItems,
        addToCart,
        updateQuantity,
        removeFromCart,
        clearCart,
        calculateItemDiscount,
        getCartTotals,
      }}
    >
      {children}
    </CartContext.Provider>
  );
};

export const useCart = () => useContext(CartContext);
