package com.shawenterprise.web;

import com.shawenterprise.service.BusinessService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

@ControllerAdvice
public class PageModelAdvice {
    private final BusinessService business;
    private final SessionContext sessions;
    private final boolean googleEnabled;
    private final boolean registrationEnabled;

    public PageModelAdvice(BusinessService business, SessionContext sessions,
                           @Value("${app.google.client-id:}") String googleClientId,
                           @Value("${app.google.client-secret:}") String googleClientSecret,
                           @Value("${app.admin.registration-enabled:false}") boolean registrationEnabled) {
        this.business = business; this.sessions = sessions; this.googleEnabled = !googleClientId.isBlank() && !googleClientSecret.isBlank(); this.registrationEnabled = registrationEnabled;
    }

    @ModelAttribute
    void common(HttpServletRequest request, org.springframework.ui.Model model) {
        model.addAttribute("business", business.settings());
        model.addAttribute("csrf", sessions.csrfToken(request));
        model.addAttribute("isAdmin", sessions.isAdmin(request));
        model.addAttribute("googleEnabled", googleEnabled);
        model.addAttribute("registrationEnabled", registrationEnabled);
    }
}
