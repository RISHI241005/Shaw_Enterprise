package com.shawenterprise.service;

import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class LiveUpdateService {
    private final Set<SseEmitter> clients = ConcurrentHashMap.newKeySet();

    public SseEmitter connect() {
        var emitter = new SseEmitter(0L);
        clients.add(emitter);
        emitter.onCompletion(() -> clients.remove(emitter));
        emitter.onTimeout(() -> clients.remove(emitter));
        emitter.onError(ignored -> clients.remove(emitter));
        try {
            emitter.send(SseEmitter.event().name("connected").data("ready"));
        } catch (IOException error) {
            clients.remove(emitter);
        }
        return emitter;
    }

    public void publish(String topic) {
        for (var client : clients) {
            try {
                client.send(SseEmitter.event().name("sync").data(topic));
            } catch (IOException error) {
                client.complete();
                clients.remove(client);
            }
        }
    }
}
