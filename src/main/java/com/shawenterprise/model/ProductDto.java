package com.shawenterprise.model;

import java.util.List;

public record ProductDto(
    long id,
    String sku,
    String name,
    String category,
    String price,
    String productType,
    String summary,
    String details,
    String packSize,
    String audience,
    List<String> images,
    boolean featured
) {}
