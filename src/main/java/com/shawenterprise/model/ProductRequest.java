package com.shawenterprise.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

public record ProductRequest(
    @NotBlank @Size(max = 180) String name,
    @Size(max = 120) String category,
    @Size(max = 80) String price,
    @DecimalMin("0.01") BigDecimal unitPrice,
    @Min(0) @Max(100000) int stockQuantity,
    boolean orderingEnabled,
    @Size(max = 160) String productType,
    @Size(max = 2000) String summary,
    @Size(max = 10000) String details,
    @Size(max = 160) String packSize,
    @Size(max = 180) String audience,
    List<@Size(max = 2_500_000) String> images,
    boolean featured
) {}
