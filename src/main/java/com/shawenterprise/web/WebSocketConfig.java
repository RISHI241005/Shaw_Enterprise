package com.shawenterprise.web;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfig implements WebSocketConfigurer {
    private final LiveWebSocketHandler liveHandler;

    public WebSocketConfig(LiveWebSocketHandler liveHandler) {
        this.liveHandler = liveHandler;
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // Spring's default same-origin policy protects this read-only broadcast channel.
        registry.addHandler(liveHandler, "/ws/live");
    }
}
