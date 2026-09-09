package com.shawenterprise.model;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public record ProductRequest(
    @NotBlank @Size(max = 180) String name,
    @NotBlank @Size(max = 120) String category,
    @NotBlank @Size(max = 80) String price,
    @NotBlank @Size(max = 160) String productType,
    @NotBlank @Size(max = 2000) String summary,
    @NotBlank @Size(max = 10000) String details,
    @NotBlank @Size(max = 160) String packSize,
    @NotBlank @Size(max = 180) String audience,
    List<@Size(max = 2_500_000) String> images,
    boolean featured
) {}
