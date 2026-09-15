package com.shawenterprise.web;

import com.shawenterprise.service.LiveUpdateService;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.CloseStatus;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class LiveWebSocketHandler extends TextWebSocketHandler {
    private final LiveUpdateService live;

    public LiveWebSocketHandler(LiveUpdateService live) {
        this.live = live;
    }

    @Override
    public void afterConnectionEstablished(WebSocketSession session) throws Exception {
        live.connectSocket(session);
    }

    @Override
    public void afterConnectionClosed(WebSocketSession session, CloseStatus status) {
        live.disconnectSocket(session);
    }

    @Override
    public void handleTransportError(WebSocketSession session, Throwable exception) throws Exception {
        live.disconnectSocket(session);
        if (session.isOpen()) session.close(CloseStatus.SERVER_ERROR);
    }
}
