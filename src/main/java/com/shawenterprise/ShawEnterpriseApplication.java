package com.shawenterprise;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class ShawEnterpriseApplication {
    public static void main(String[] args) {
        SpringApplication.run(ShawEnterpriseApplication.class, args);
    }
}
