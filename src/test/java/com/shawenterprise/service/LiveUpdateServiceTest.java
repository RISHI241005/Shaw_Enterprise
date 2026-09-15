package com.shawenterprise.service;

import org.junit.jupiter.api.Test;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.socket.WebSocketSession;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class LiveUpdateServiceTest {
    @Test
    void broadcastsCommittedTopicsToConnectedWebSockets() throws Exception {
        var jdbc = mock(JdbcTemplate.class);
        var events = mock(ApplicationEventPublisher.class);
        var socket = mock(WebSocketSession.class);
        when(socket.getId()).thenReturn("socket-1");
        when(socket.isOpen()).thenReturn(true);
        when(jdbc.queryForObject(anyString(), eq(Long.class), eq("products"))).thenReturn(4L);
        var live = new LiveUpdateService(jdbc, events);

        live.connectSocket(socket);
        live.publish("products");

        assertThat(live.socketCount()).isEqualTo(1);
        verify(socket, times(2)).sendMessage(any());
        verify(events).publishEvent(new LiveTopicEvent("products"));
        live.disconnectSocket(socket);
        assertThat(live.socketCount()).isZero();
    }
}
