package com.shawenterprise.config;

import com.shawenterprise.service.BusinessService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

import java.util.ArrayList;

@Component
public class ProductionReadinessValidator {
    private final boolean production;
    private final String adminPassword;
    private final String mysqlPassword;
    private final String otpSecret;
    private final BusinessService business;

    public ProductionReadinessValidator(@Value("${app.production:false}") boolean production,
                                        @Value("${app.admin.password}") String adminPassword,
                                        @Value("${spring.datasource.password:}") String mysqlPassword,
                                        @Value("${app.otp.secret}") String otpSecret,
                                        BusinessService business) {
        this.production = production; this.adminPassword = adminPassword; this.mysqlPassword = mysqlPassword; this.otpSecret = otpSecret; this.business = business;
    }

    @EventListener(ApplicationReadyEvent.class)
    public void validate() {
        if (!production) return;
        var errors = new ArrayList<String>();
        var settings = business.settings();
        if (adminPassword.length() < 14 || adminPassword.toLowerCase().contains("change")) errors.add("ADMIN_PASSWORD must be a unique 14+ character secret");
        if (mysqlPassword.isBlank()) errors.add("MYSQL_PASSWORD is required");
        if (otpSecret.length() < 32 || otpSecret.toLowerCase().contains("change")) errors.add("OTP_SECRET must be a unique 32+ character secret");
        if (settings.get("address").toLowerCase().contains("your shop address")) errors.add("set the exact enterprise address in Admin > Business & Map");
        if (settings.get("email").endsWith(".example")) errors.add("set a real business email in Admin > Business & Map");
        if (settings.get("phone").contains("00000")) errors.add("set a real business phone in Admin > Business & Map");
        if (!errors.isEmpty()) throw new IllegalStateException("Production configuration is not ready:\n- " + String.join("\n- ", errors));
    }
}
