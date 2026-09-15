package com.shawenterprise.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.ConcurrentWebSocketSessionDecorator;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class LiveUpdateService {
    private final Set<SseEmitter> eventClients = ConcurrentHashMap.newKeySet();
    private final Map<String, WebSocketSession> socketClients = new ConcurrentHashMap<>();
    private final Map<String, Long> knownVersions = new ConcurrentHashMap<>();
    private final JdbcTemplate jdbc;
    private final ApplicationEventPublisher events;

    public LiveUpdateService(JdbcTemplate jdbc, ApplicationEventPublisher events) {
        this.jdbc = jdbc;
        this.events = events;
    }

    public SseEmitter connectEvents() {
        var emitter = new SseEmitter(0L);
        eventClients.add(emitter);
        emitter.onCompletion(() -> eventClients.remove(emitter));
        emitter.onTimeout(() -> eventClients.remove(emitter));
        emitter.onError(ignored -> eventClients.remove(emitter));
        try {
            emitter.send(SseEmitter.event().name("connected").data("ready"));
        } catch (IOException error) {
            eventClients.remove(emitter);
        }
        return emitter;
    }

    public void connectSocket(WebSocketSession session) throws IOException {
        var safeSession = new ConcurrentWebSocketSessionDecorator(session, 5_000, 64 * 1024);
        socketClients.put(session.getId(), safeSession);
        safeSession.sendMessage(message("connected", "ready"));
    }

    public void disconnectSocket(WebSocketSession session) {
        socketClients.remove(session.getId());
    }

    public void publish(String topic) {
        // Persist the version inside the business transaction, not on its already
        // committed connection during afterCommit.
        bumpVersion(topic);
        var action = (Runnable) () -> broadcast(topic);
        if (TransactionSynchronizationManager.isSynchronizationActive()) {
            TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
                @Override public void afterCommit() { action.run(); }
            });
        } else action.run();
    }

    private void bumpVersion(String topic) {
        try {
            jdbc.update("INSERT INTO sync_state(topic,version) VALUES (?,1) ON DUPLICATE KEY UPDATE version=version+1", topic);
            var version = jdbc.queryForObject("SELECT version FROM sync_state WHERE topic=?", Long.class, topic);
            if (version != null) knownVersions.put(topic, version);
        } catch (RuntimeException ignored) {
            // Local WebSocket delivery remains available while the database recovers.
        }
    }

    private void broadcast(String topic) {
        events.publishEvent(new LiveTopicEvent(topic));
        var socketMessage = message("sync", topic);
        for (var entry : socketClients.entrySet()) {
            var client = entry.getValue();
            try {
                if (client.isOpen()) client.sendMessage(socketMessage);
                else socketClients.remove(entry.getKey());
            } catch (IOException error) {
                socketClients.remove(entry.getKey());
                try { client.close(); } catch (IOException ignored) { }
            }
        }
        for (var client : eventClients) {
            try {
                client.send(SseEmitter.event().name("sync").data(topic));
            } catch (IOException error) {
                client.complete();
                eventClients.remove(client);
            }
        }
    }

    @Scheduled(fixedDelay = 2_000)
    void relayDatabaseUpdates() {
        try {
            jdbc.query("SELECT topic,version FROM sync_state", row -> {
                var topic = row.getString("topic");
                var version = row.getLong("version");
                var previous = knownVersions.put(topic, version);
                if (previous != null && previous != version) broadcast(topic);
            });
        } catch (RuntimeException ignored) {
            // A later poll catches up after a temporary database interruption.
        }
    }

    @Scheduled(fixedRate = 25_000)
    void heartbeat() {
        var heartbeat = message("heartbeat", "alive");
        for (var entry : socketClients.entrySet()) {
            try {
                if (entry.getValue().isOpen()) entry.getValue().sendMessage(heartbeat);
                else socketClients.remove(entry.getKey());
            } catch (IOException error) {
                socketClients.remove(entry.getKey());
            }
        }
    }

    public int socketCount() { return socketClients.size(); }

    private TextMessage message(String type, String topic) {
        return new TextMessage("{\"type\":\"" + type + "\",\"topic\":\"" + topic + "\",\"timestamp\":\"" + Instant.now() + "\"}");
    }
}
