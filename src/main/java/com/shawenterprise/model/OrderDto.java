package com.shawenterprise.model;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record OrderDto(
    long id,
    String orderNumber,
    String customerName,
    String email,
    String phone,
    String fulfillmentMethod,
    String paymentMethod,
    String addressLine,
    String city,
    String state,
    String postalCode,
    String notes,
    String status,
    BigDecimal subtotal,
    BigDecimal deliveryFee,
    BigDecimal total,
    LocalDateTime createdAt,
    LocalDateTime updatedAt,
    List<OrderItemDto> items
) {
    public record OrderItemDto(long id, Long productId, String sku, String productName, String price,
                               BigDecimal unitPrice, int quantity, BigDecimal lineTotal) {}
}
