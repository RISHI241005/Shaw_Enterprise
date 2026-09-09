package com.shawenterprise.web;

import com.shawenterprise.service.CatalogService;
import com.shawenterprise.service.FeedbackService;
import com.shawenterprise.service.InquiryService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class PageController {
    private final CatalogService catalog;
    private final FeedbackService feedback;
    private final InquiryService inquiries;
    private final SessionContext sessions;
    private final RequestGuard guard;

    public PageController(CatalogService catalog, FeedbackService feedback, InquiryService inquiries, SessionContext sessions, RequestGuard guard) {
        this.catalog = catalog; this.feedback = feedback; this.inquiries = inquiries; this.sessions = sessions; this.guard = guard;
    }

    @GetMapping("/") String home(Model model) { model.addAttribute("products", catalog.featured(3)); model.addAttribute("metrics", catalog.metrics()); return "home"; }
    @GetMapping("/products") String products(Model model) { var products = catalog.all(); model.addAttribute("products", products); model.addAttribute("categories", products.stream().map(item -> item.category()).distinct().sorted().toList()); return "products"; }
    @GetMapping("/feedback") String feedback(HttpServletRequest request, Model model) { sessions.visitorId(request); model.addAttribute("identityJson", "null"); return "feedback"; }
    @GetMapping("/contact") String contact() { return "contact"; }

    @PostMapping("/contact") String contactSubmit(HttpServletRequest request, @RequestParam String name, @RequestParam String email, @RequestParam String phone, @RequestParam String message, RedirectAttributes redirect) {
        guard.csrf(request); guard.limit(request, "contact", 8, 600); inquiries.create(name, email, phone, message); redirect.addFlashAttribute("sent", true); return "redirect:/contact";
    }

    @GetMapping("/login") String login() { return "login"; }
    @GetMapping("/logout") String logout(HttpServletRequest request) { sessions.logout(request); return "redirect:/login"; }

    @GetMapping({"/admin", "/admin/{tab}"}) String admin(HttpServletRequest request, @PathVariable(required = false) String tab, Model model) {
        if (!sessions.isAdmin(request)) return "redirect:/login";
        var active = tab == null ? "products" : tab;
        if (!java.util.Set.of("products", "inquiries", "feedback", "audits", "settings").contains(active)) active = "products";
        model.addAttribute("activeTab", active); model.addAttribute("metrics", catalog.metrics()); return "admin";
    }
}
