package com.shawenterprise.service;

import com.shawenterprise.model.OrderDto;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
public class OrderService {
    private static final BigDecimal DELIVERY_FEE = new BigDecimal("99.00");
    private static final BigDecimal FREE_DELIVERY_MINIMUM = new BigDecimal("1000.00");
    private static final Map<String, List<String>> TRANSITIONS = Map.of(
        "placed", List.of("confirmed", "cancelled"), "confirmed", List.of("packing", "cancelled"),
        "packing", List.of("ready", "cancelled"), "ready", List.of("out_for_delivery", "delivered", "cancelled"),
        "out_for_delivery", List.of("delivered", "cancelled"), "delivered", List.of(), "cancelled", List.of()
    );

    private final JdbcTemplate jdbc;
    private final LiveUpdateService live;

    public OrderService(JdbcTemplate jdbc, LiveUpdateService live) { this.jdbc = jdbc; this.live = live; }

    public List<OrderDto> forVisitor(String visitorId) { return list("WHERE visitor_id=? ORDER BY created_at DESC LIMIT 25", visitorId); }
    public List<OrderDto> all() { return list("ORDER BY created_at DESC LIMIT 100"); }

    public OrderDto lookup(String reference, String phone) {
        var normalizedPhone = normalizePhone(phone);
        var orderNumber = text(reference, 32).toUpperCase(Locale.ROOT);
        if (!orderNumber.matches("SE-\\d{8}-[A-F0-9]{8}") || normalizedPhone == null) bad("Enter a valid order number and phone number.");
        return list("WHERE order_number=? AND phone=? LIMIT 1", orderNumber, normalizedPhone).stream().findFirst()
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No order matched those details."));
    }

    @Transactional
    public OrderDto create(String visitorId, Map<String, Object> body) {
        var customerName = text(body.get("customerName"), 160);
        var email = text(body.get("email"), 180).toLowerCase(Locale.ROOT);
        var phone = normalizePhone(text(body.get("phone"), 40));
        var fulfillment = "pickup".equals(body.get("fulfillmentMethod")) ? "pickup" : "delivery";
        var payment = "pickup".equals(fulfillment) ? "pay_on_pickup" : "cash_on_delivery";
        var address = "delivery".equals(fulfillment) ? text(body.get("addressLine"), 255) : "";
        var city = "delivery".equals(fulfillment) ? text(body.get("city"), 120) : "";
        var region = "delivery".equals(fulfillment) ? text(body.get("state"), 120) : "";
        var postalCode = "delivery".equals(fulfillment) ? text(body.get("postalCode"), 20).toUpperCase(Locale.ROOT) : "";
        var notes = text(body.get("notes"), 1000);
        if (customerName.length() < 2) bad("Enter the customer's full name.");
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) bad("Enter a valid email address.");
        if (phone == null) bad("Enter a valid phone number.");
        if ("delivery".equals(fulfillment) && (address.isBlank() || city.isBlank() || region.isBlank() || !postalCode.matches("^[A-Z0-9][A-Z0-9 -]{2,18}[A-Z0-9]$"))) bad("Enter a complete delivery address and valid postal code.");

        var quantities = orderQuantities(body.get("items"));
        var ids = new ArrayList<>(quantities.keySet());
        var marks = String.join(",", ids.stream().map(ignored -> "?").toList());
        var rows = jdbc.queryForList("SELECT id,sku,name,price_label,unit_price,stock_quantity,ordering_enabled,status FROM products WHERE id IN (" + marks + ") FOR UPDATE", ids.toArray());
        if (rows.size() != ids.size()) conflict("One or more products are no longer available.");
        var orderItems = new ArrayList<Map<String, Object>>();
        var subtotal = BigDecimal.ZERO;
        for (var row : rows) {
            var id = ((Number) row.get("id")).longValue();
            var quantity = quantities.get(id);
            var stock = ((Number) row.get("stock_quantity")).intValue();
            var enabled = truthy(row.get("ordering_enabled"));
            var price = (BigDecimal) row.get("unit_price");
            var name = String.valueOf(row.get("name"));
            if (!"active".equals(row.get("status")) || !enabled) conflict(name + " is not available for online ordering.");
            if (quantity > stock) conflict("Only " + stock + " pack(s) of " + name + " are currently available.");
            if (price == null || price.signum() <= 0) conflict(name + " does not have a valid online price.");
            var lineTotal = price.multiply(BigDecimal.valueOf(quantity)).setScale(2, RoundingMode.HALF_UP);
            subtotal = subtotal.add(lineTotal);
            orderItems.add(Map.of("productId", id, "sku", row.get("sku"), "name", name, "priceLabel", row.get("price_label"), "unitPrice", price, "quantity", quantity, "lineTotal", lineTotal));
        }
        subtotal = subtotal.setScale(2, RoundingMode.HALF_UP);
        var deliveryFee = "delivery".equals(fulfillment) && subtotal.compareTo(FREE_DELIVERY_MINIMUM) < 0 ? DELIVERY_FEE : BigDecimal.ZERO.setScale(2);
        var total = subtotal.add(deliveryFee);
        var created = LocalDateTime.now();
        var reference = "SE-" + LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE) + "-" + UUID.randomUUID().toString().replace("-", "").substring(0, 8).toUpperCase(Locale.ROOT);
        var key = new GeneratedKeyHolder();
        var finalSubtotal = subtotal;
        jdbc.update(connection -> {
            var statement = connection.prepareStatement("INSERT INTO orders(order_number,visitor_id,customer_name,email,phone,fulfillment_method,payment_method,address_line,city,state,postal_code,notes,status,subtotal,delivery_fee,total,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?, 'placed',?,?,?,?,?)", Statement.RETURN_GENERATED_KEYS);
            statement.setString(1, reference); statement.setString(2, visitorId); statement.setString(3, customerName); statement.setString(4, email); statement.setString(5, phone); statement.setString(6, fulfillment); statement.setString(7, payment); statement.setString(8, address); statement.setString(9, city); statement.setString(10, region); statement.setString(11, postalCode); statement.setString(12, notes); statement.setBigDecimal(13, finalSubtotal); statement.setBigDecimal(14, deliveryFee); statement.setBigDecimal(15, total); statement.setTimestamp(16, Timestamp.valueOf(created)); statement.setTimestamp(17, Timestamp.valueOf(created)); return statement;
        }, key);
        var orderId = key.getKey().longValue();
        for (var item : orderItems) {
            jdbc.update("INSERT INTO order_items(order_id,product_id,sku,product_name,price_label,unit_price,quantity,line_total,created_at) VALUES (?,?,?,?,?,?,?,?,?)", orderId,item.get("productId"),item.get("sku"),item.get("name"),item.get("priceLabel"),item.get("unitPrice"),item.get("quantity"),item.get("lineTotal"),Timestamp.valueOf(created));
            jdbc.update("UPDATE products SET stock_quantity=stock_quantity-?,updated_at=? WHERE id=?", item.get("quantity"),Timestamp.valueOf(created),item.get("productId"));
        }
        live.publish("orders"); live.publish("products");
        return get(orderId);
    }

    @Transactional
    public List<OrderDto> updateStatus(long id, String next) {
        var row = jdbc.queryForList("SELECT status,fulfillment_method FROM orders WHERE id=? FOR UPDATE", id).stream().findFirst().orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Order not found"));
        var current = String.valueOf(row.get("status"));
        var nextStatuses = "ready".equals(current) ? ("pickup".equals(row.get("fulfillment_method")) ? List.of("delivered","cancelled") : List.of("out_for_delivery","cancelled")) : TRANSITIONS.getOrDefault(current, List.of());
        if (!nextStatuses.contains(next)) conflict("Order cannot move from " + current + " to " + next + ".");
        if ("cancelled".equals(next)) jdbc.queryForList("SELECT product_id,quantity FROM order_items WHERE order_id=?", id).forEach(item -> { if (item.get("product_id") != null) jdbc.update("UPDATE products SET stock_quantity=stock_quantity+?,updated_at=? WHERE id=?", item.get("quantity"),Timestamp.valueOf(LocalDateTime.now()),item.get("product_id")); });
        jdbc.update("UPDATE orders SET status=?,updated_at=? WHERE id=?", next, Timestamp.valueOf(LocalDateTime.now()), id);
        live.publish("orders"); if ("cancelled".equals(next)) live.publish("products");
        return all();
    }

    private OrderDto get(long id) { return list("WHERE id=?", id).stream().findFirst().orElseThrow(); }

    private List<OrderDto> list(String suffix, Object... args) {
        var rows = jdbc.queryForList("SELECT * FROM orders " + suffix, args);
        if (rows.isEmpty()) return List.of();
        var ids = rows.stream().map(row -> ((Number) row.get("id")).longValue()).toList();
        var marks = String.join(",", ids.stream().map(ignored -> "?").toList());
        var itemRows = jdbc.queryForList("SELECT * FROM order_items WHERE order_id IN (" + marks + ") ORDER BY id", ids.toArray());
        return rows.stream().map(row -> {
            var id = ((Number) row.get("id")).longValue();
            var items = itemRows.stream().filter(item -> ((Number) item.get("order_id")).longValue() == id).map(item -> new OrderDto.OrderItemDto(((Number)item.get("id")).longValue(), item.get("product_id") == null ? null : ((Number)item.get("product_id")).longValue(), String.valueOf(item.get("sku")), String.valueOf(item.get("product_name")), String.valueOf(item.get("price_label")), (BigDecimal)item.get("unit_price"), ((Number)item.get("quantity")).intValue(), (BigDecimal)item.get("line_total"))).toList();
            return new OrderDto(id,String.valueOf(row.get("order_number")),String.valueOf(row.get("customer_name")),String.valueOf(row.get("email")),String.valueOf(row.get("phone")),String.valueOf(row.get("fulfillment_method")),String.valueOf(row.get("payment_method")),String.valueOf(row.get("address_line")),String.valueOf(row.get("city")),String.valueOf(row.get("state")),String.valueOf(row.get("postal_code")),String.valueOf(row.get("notes")),String.valueOf(row.get("status")),(BigDecimal)row.get("subtotal"),(BigDecimal)row.get("delivery_fee"),(BigDecimal)row.get("total"),((Timestamp)row.get("created_at")).toLocalDateTime(),((Timestamp)row.get("updated_at")).toLocalDateTime(),items);
        }).toList();
    }

    private Map<Long, Integer> orderQuantities(Object value) {
        if (!(value instanceof List<?>)) bad("Your cart must contain between 1 and 50 products.");
        var list = (List<?>) value;
        if (list.isEmpty() || list.size() > 50) bad("Your cart must contain between 1 and 50 products.");
        var result = new LinkedHashMap<Long, Integer>();
        for (var raw : list) {
            if (!(raw instanceof Map<?,?>)) bad("Invalid cart item.");
            var item = (Map<?,?>) raw;
            try {
                var id = Long.parseLong(String.valueOf(item.get("productId"))); var quantity = Integer.parseInt(String.valueOf(item.get("quantity")));
                if (id < 1 || quantity < 1 || quantity > 99) bad("Each cart quantity must be between 1 and 99 packs.");
                result.merge(id, quantity, Integer::sum);
            } catch (NumberFormatException error) { bad("Invalid cart item."); }
        }
        if (result.values().stream().anyMatch(quantity -> quantity > 99)) bad("A product cannot exceed 99 packs per order.");
        return result;
    }

    private static String normalizePhone(String value) { var compact = value.replaceAll("[\\s().-]", ""); if (compact.matches("\\d{10}")) compact = "+91" + compact; return compact.matches("\\+[1-9]\\d{7,14}") ? compact : null; }
    private static String text(Object value, int max) { var result = value == null ? "" : String.valueOf(value).trim(); return result.substring(0, Math.min(max, result.length())); }
    private static boolean truthy(Object value) { return Boolean.TRUE.equals(value) || value instanceof Number number && number.intValue() == 1; }
    private static void bad(String message) { throw new ResponseStatusException(HttpStatus.BAD_REQUEST, message); }
    private static void conflict(String message) { throw new ResponseStatusException(HttpStatus.CONFLICT, message); }
}
