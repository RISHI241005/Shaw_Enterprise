package com.shawenterprise.service;

import com.shawenterprise.model.ProductDto;
import com.shawenterprise.model.ProductRequest;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.sql.PreparedStatement;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class CatalogService {
    private final JdbcTemplate jdbc;
    private final LiveUpdateService live;

    public CatalogService(JdbcTemplate jdbc, LiveUpdateService live) {
        this.jdbc = jdbc;
        this.live = live;
    }

    public List<ProductDto> all() {
        return query("WHERE p.status='active' ORDER BY p.featured DESC, p.id ASC", new Object[0]);
    }

    public List<ProductDto> featured(int limit) {
        return query("WHERE p.status='active' AND p.featured=TRUE ORDER BY p.id ASC LIMIT ?", new Object[]{limit});
    }

    public ProductDto get(long id) {
        return query("WHERE p.id=? AND p.status='active'", new Object[]{id}).stream().findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found"));
    }

    public Map<String, Object> metrics() {
        var products = all();
        var categories = products.stream().map(ProductDto::category).distinct().sorted().toList();
        var featured = products.stream().filter(ProductDto::featured).count();
        var inquiries = jdbc.queryForList("SELECT status, COUNT(*) count FROM inquiries GROUP BY status");
        var inquiryMap = new LinkedHashMap<String, Long>();
        inquiryMap.put("new", 0L); inquiryMap.put("contacted", 0L); inquiryMap.put("closed", 0L);
        inquiries.forEach(row -> inquiryMap.put(String.valueOf(row.get("status")), ((Number) row.get("count")).longValue()));
        inquiryMap.put("total", inquiryMap.values().stream().mapToLong(Long::longValue).sum());
        var feedback = jdbc.queryForObject("SELECT COUNT(*) FROM feedback_comments WHERE status='visible'", Long.class);
        return Map.of("totalProducts", products.size(), "categories", categories, "featured", featured, "inquiries", inquiryMap, "feedback", feedback == null ? 0L : feedback);
    }

    @Transactional
    public ProductDto create(ProductRequest request) {
        var categoryId = category(request.category());
        var now = LocalDateTime.now();
        var key = new GeneratedKeyHolder();
        jdbc.update(connection -> {
            var statement = connection.prepareStatement("""
                INSERT INTO products(category_id,name,sku,price_label,product_type,summary,details,pack_size,audience,featured,status,created_at,updated_at)
                VALUES (?,?,?, ?,?,?,?,?,?,?, 'active',?,?)
                """, Statement.RETURN_GENERATED_KEYS);
            statement.setLong(1, categoryId);
            statement.setString(2, clean(request.name()));
            statement.setString(3, "PENDING-" + System.nanoTime());
            statement.setString(4, clean(request.price()));
            statement.setString(5, clean(request.productType()));
            statement.setString(6, clean(request.summary()));
            statement.setString(7, clean(request.details()));
            statement.setString(8, clean(request.packSize()));
            statement.setString(9, clean(request.audience()));
            statement.setBoolean(10, request.featured());
            statement.setTimestamp(11, Timestamp.valueOf(now));
            statement.setTimestamp(12, Timestamp.valueOf(now));
            return statement;
        }, key);
        var id = key.getKey().longValue();
        jdbc.update("UPDATE products SET sku=? WHERE id=?", "SE-" + String.format("%04d", id), id);
        replaceImages(id, request.images(), request.name());
        live.publish("products");
        return get(id);
    }

    @Transactional
    public ProductDto update(long id, ProductRequest request) {
        get(id);
        var changed = jdbc.update("""
            UPDATE products SET category_id=?,name=?,price_label=?,product_type=?,summary=?,details=?,pack_size=?,audience=?,featured=?,updated_at=? WHERE id=?
            """, category(request.category()), clean(request.name()), clean(request.price()), clean(request.productType()), clean(request.summary()),
            clean(request.details()), clean(request.packSize()), clean(request.audience()), request.featured(), Timestamp.valueOf(LocalDateTime.now()), id);
        if (changed == 0) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
        replaceImages(id, request.images(), request.name());
        live.publish("products");
        return get(id);
    }

    @Transactional
    public void delete(long id) {
        if (jdbc.update("DELETE FROM products WHERE id=?", id) == 0) throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Product not found");
        live.publish("products");
    }

    private List<ProductDto> query(String suffix, Object[] args) {
        var rows = jdbc.queryForList("""
            SELECT p.id,p.sku,p.name,c.name category,p.price_label,p.product_type,p.summary,p.details,p.pack_size,p.audience,p.featured
            FROM products p JOIN product_categories c ON c.id=p.category_id
            """ + suffix, args);
        var ids = rows.stream().map(row -> ((Number) row.get("id")).longValue()).toList();
        var images = new LinkedHashMap<Long, List<String>>();
        if (!ids.isEmpty()) {
            var marks = String.join(",", ids.stream().map(ignored -> "?").toList());
            jdbc.query("SELECT product_id,image_data FROM product_images WHERE product_id IN (" + marks + ") ORDER BY product_id,sort_order,id",
                (RowCallbackHandler) result -> images.computeIfAbsent(result.getLong(1), ignored -> new ArrayList<>()).add(result.getString(2)), ids.toArray());
        }
        return rows.stream().map(row -> new ProductDto(
            ((Number) row.get("id")).longValue(), string(row, "sku"), string(row, "name"), string(row, "category"), string(row, "price_label"),
            string(row, "product_type"), string(row, "summary"), string(row, "details"), string(row, "pack_size"), string(row, "audience"),
            images.getOrDefault(((Number) row.get("id")).longValue(), List.of()), truthy(row.get("featured"))
        )).toList();
    }

    private long category(String name) {
        var clean = clean(name);
        jdbc.update("INSERT INTO product_categories(name,description) VALUES (?,?) ON DUPLICATE KEY UPDATE description=description", clean, clean + " products for Shaw Enterprise catalog");
        return jdbc.queryForObject("SELECT id FROM product_categories WHERE name=?", Long.class, clean);
    }

    private void replaceImages(long productId, List<String> values, String name) {
        jdbc.update("DELETE FROM product_images WHERE product_id=?", productId);
        if (values == null) return;
        var index = 0;
        for (var image : values) {
            if (image == null || image.isBlank()) continue;
            jdbc.update("INSERT INTO product_images(product_id,image_data,alt_text,sort_order) VALUES (?,?,?,?)", productId, image.trim(), clean(name), index++);
        }
    }

    private String clean(String value) { return value == null ? "" : value.trim(); }
    private String string(Map<String, Object> row, String key) { return row.get(key) == null ? "" : String.valueOf(row.get(key)); }
    private boolean truthy(Object value) { return Boolean.TRUE.equals(value) || value instanceof Number number && number.intValue() == 1; }
}
