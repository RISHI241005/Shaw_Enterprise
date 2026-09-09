package com.shawenterprise.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowCallbackHandler;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class BusinessService {
    private static final List<String> KEYS = List.of("business_name", "phone", "email", "address", "whatsapp", "hours");
    private final JdbcTemplate jdbc;
    private final LiveUpdateService live;

    public BusinessService(JdbcTemplate jdbc, LiveUpdateService live) {
        this.jdbc = jdbc;
        this.live = live;
    }

    public Map<String, String> settings() {
        var result = new LinkedHashMap<String, String>();
        jdbc.query("SELECT setting_key, setting_value FROM business_settings", (RowCallbackHandler) row -> result.put(row.getString(1), row.getString(2)));
        result.putIfAbsent("business_name", "Shaw Enterprise");
        result.putIfAbsent("phone", "+91 00000 00000");
        result.putIfAbsent("email", "sales@shawenterprise.example");
        result.putIfAbsent("address", "Kolkata, West Bengal, India");
        result.putIfAbsent("whatsapp", "910000000000");
        result.putIfAbsent("hours", "Monday to Saturday, 10:00 AM–7:00 PM");
        var encodedAddress = URLEncoder.encode(result.get("address"), StandardCharsets.UTF_8);
        result.put("mapEmbedUrl", "https://maps.google.com/maps?q=" + encodedAddress + "&z=16&output=embed");
        result.put("mapDirectionsUrl", "https://www.google.com/maps/dir/?api=1&destination=" + encodedAddress + "&dir_action=navigate");
        result.put("mapSearchUrl", "https://www.google.com/maps/search/?api=1&query=" + encodedAddress);
        return result;
    }

    @Transactional
    public Map<String, String> update(Map<String, String> values) {
        for (var key : KEYS) {
            var value = String.valueOf(values.getOrDefault(key, "")).trim();
            if (value.isBlank()) throw new IllegalArgumentException(key + " is required");
            jdbc.update("INSERT INTO business_settings(setting_key, setting_value) VALUES (?, ?) ON DUPLICATE KEY UPDATE setting_value=VALUES(setting_value)", key, value);
        }
        live.publish("settings");
        return settings();
    }
}
