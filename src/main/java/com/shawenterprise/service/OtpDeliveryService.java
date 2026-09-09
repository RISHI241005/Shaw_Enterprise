package com.shawenterprise.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Base64;

@Service
public class OtpDeliveryService {
    private final String emailProvider;
    private final String resendKey;
    private final String emailFrom;
    private final String smsProvider;
    private final String twilioSid;
    private final String twilioToken;
    private final String twilioFrom;

    public OtpDeliveryService(@Value("${app.email.provider:dev}") String emailProvider,
                              @Value("${app.email.resend-api-key:}") String resendKey,
                              @Value("${app.email.from:}") String emailFrom,
                              @Value("${app.sms.provider:dev}") String smsProvider,
                              @Value("${app.sms.twilio-account-sid:}") String twilioSid,
                              @Value("${app.sms.twilio-auth-token:}") String twilioToken,
                              @Value("${app.sms.twilio-from:}") String twilioFrom) {
        this.emailProvider=emailProvider; this.resendKey=resendKey; this.emailFrom=emailFrom; this.smsProvider=smsProvider;
        this.twilioSid=twilioSid; this.twilioToken=twilioToken; this.twilioFrom=twilioFrom;
    }

    public void deliver(String destination, String channel, String code) {
        if ("email".equals(channel)) deliverEmail(destination, code); else deliverSms(destination, code);
    }

    private void deliverEmail(String destination, String code) {
        if ("dev".equalsIgnoreCase(emailProvider)) return;
        if (!"resend".equalsIgnoreCase(emailProvider) || resendKey.isBlank() || emailFrom.isBlank())
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "Email verification provider is not configured");
        var body = "{\"from\":\""+json(emailFrom)+"\",\"to\":[\""+json(destination)+"\"],\"subject\":\"Your Shaw Enterprise verification code\",\"text\":\"Your verification code is "+json(code)+". It expires in 10 minutes.\"}";
        send(HttpRequest.newBuilder(URI.create("https://api.resend.com/emails")).timeout(Duration.ofSeconds(15))
            .header("Authorization", "Bearer " + resendKey).header("Content-Type", "application/json").POST(HttpRequest.BodyPublishers.ofString(body)).build(), "Email verification could not be delivered");
    }

    private void deliverSms(String destination, String code) {
        if ("dev".equalsIgnoreCase(smsProvider)) return;
        if (!"twilio".equalsIgnoreCase(smsProvider) || twilioSid.isBlank() || twilioToken.isBlank() || twilioFrom.isBlank())
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "SMS verification provider is not configured");
        var form = "To="+url(destination)+"&From="+url(twilioFrom)+"&Body="+url("Your Shaw Enterprise verification code is " + code + ". It expires in 10 minutes.");
        var auth = Base64.getEncoder().encodeToString((twilioSid + ":" + twilioToken).getBytes(StandardCharsets.UTF_8));
        send(HttpRequest.newBuilder(URI.create("https://api.twilio.com/2010-04-01/Accounts/"+urlPath(twilioSid)+"/Messages.json")).timeout(Duration.ofSeconds(15))
            .header("Authorization", "Basic " + auth).header("Content-Type", "application/x-www-form-urlencoded").POST(HttpRequest.BodyPublishers.ofString(form)).build(), "SMS verification could not be delivered");
    }

    private void send(HttpRequest request, String failure) {
        try {
            var response = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(8))
                    .build()
                    .send(request, HttpResponse.BodyHandlers.discarding());
            if (response.statusCode() < 200 || response.statusCode() >= 300) throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, failure);
        } catch (InterruptedException error) {
            Thread.currentThread().interrupt(); throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, failure);
        } catch (java.io.IOException error) { throw new ResponseStatusException(HttpStatus.BAD_GATEWAY, failure); }
    }

    private String json(String value) { return value.replace("\\","\\\\").replace("\"","\\\"").replace("\r","").replace("\n","\\n"); }
    private String url(String value) { return URLEncoder.encode(value, StandardCharsets.UTF_8); }
    private String urlPath(String value) { return value.replaceAll("[^A-Za-z0-9]", ""); }
}
