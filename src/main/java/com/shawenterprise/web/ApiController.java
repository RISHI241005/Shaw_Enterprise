package com.shawenterprise.web;

import com.shawenterprise.model.ProductRequest;
import com.shawenterprise.service.AuditService;
import com.shawenterprise.service.AuthService;
import com.shawenterprise.service.BusinessService;
import com.shawenterprise.service.CatalogService;
import com.shawenterprise.service.FeedbackService;
import com.shawenterprise.service.InquiryService;
import com.shawenterprise.service.LiveUpdateService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.Map;

@RestController
public class ApiController {
    private final CatalogService catalog;
    private final InquiryService inquiries;
    private final FeedbackService feedback;
    private final AuthService auth;
    private final AuditService audits;
    private final BusinessService business;
    private final LiveUpdateService live;
    private final SessionContext sessions;
    private final RequestGuard guard;
    private final JdbcTemplate jdbc;

    public ApiController(CatalogService catalog, InquiryService inquiries, FeedbackService feedback, AuthService auth, AuditService audits,
                         BusinessService business, LiveUpdateService live, SessionContext sessions, RequestGuard guard, JdbcTemplate jdbc) {
        this.catalog = catalog; this.inquiries = inquiries; this.feedback = feedback; this.auth = auth; this.audits = audits; this.business = business;
        this.live = live; this.sessions = sessions; this.guard = guard; this.jdbc = jdbc;
    }

    @GetMapping("/healthz") Map<String, Object> health() {
        var products = jdbc.queryForObject("SELECT COUNT(*) FROM products", Long.class);
        return Map.of("ok", true, "service", "shaw-enterprise-java", "database", "mysql", "products", products == null ? 0 : products, "liveSync", true);
    }

    @GetMapping("/api/live") SseEmitter live() { return live.connect(); }
    @GetMapping("/api/products") Map<String, Object> products() { return Map.of("products", catalog.all()); }
    @GetMapping("/api/products/{id}") Map<String, Object> product(HttpServletRequest request, @PathVariable long id) {
        return Map.of("product", catalog.get(id), "reviews", feedback.threads(sessions.visitorId(request), "top", id, false));
    }

    @PostMapping("/api/inquiries") ResponseEntity<Map<String, Object>> inquiry(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        guard.csrf(request); guard.limit(request, "inquiries", 8, 600);
        var item = inquiries.create(text(body, "name"), text(body, "email"), text(body, "phone"), text(body, "message"));
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("inquiry", item, "message", "Enquiry saved"));
    }

    @PostMapping("/api/feedback/request-otp") Map<String, Object> requestFeedbackOtp(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        guard.csrf(request); guard.limit(request, "feedback-otp", 5, 600); return feedback.requestOtp(sessions.visitorId(request), text(body, "email"));
    }
    @PostMapping("/api/feedback/verify-otp") Map<String, Object> verifyFeedbackOtp(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        guard.csrf(request); return Map.of("identity", feedback.verifyOtp(sessions.visitorId(request), text(body, "email"), text(body, "otp")));
    }
    @GetMapping("/api/feedback") Map<String, Object> feedback(HttpServletRequest request, @RequestParam(defaultValue = "top") String sort) {
        var visitor = sessions.visitorId(request); return Map.of("identity", nullable(feedback.identity(visitor)), "threads", feedback.threads(visitor, sort, null, false));
    }
    @PostMapping("/api/feedback") ResponseEntity<Map<String, Object>> postFeedback(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        guard.csrf(request); guard.limit(request, "feedback", 20, 600);
        feedback.post(sessions.visitorId(request), text(body, "message"), number(body.get("parentId")), number(body.get("productId")));
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("ok", true));
    }
    @PostMapping("/api/feedback/{id}/react") Map<String, Object> react(HttpServletRequest request, @PathVariable long id, @RequestBody Map<String, Object> body) {
        guard.csrf(request); feedback.react(sessions.visitorId(request), id, text(body, "reaction")); return Map.of("message", "Reaction saved");
    }

    @PostMapping("/api/auth/login") Map<String, Object> login(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        guard.csrf(request); guard.limit(request, "login", 10, 600); var identity = auth.authenticate(text(body, "username"), text(body, "password"));
        if (identity == null) { audits.log(request, "login_failed", "admin", text(body, "username"), "Invalid admin login attempt"); throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid username or password"); }
        sessions.login(request, identity); audits.log(request, "login", "admin", identity, "Admin login successful"); return Map.of("message", "Signed in successfully.", "redirect", "/admin");
    }
    @PostMapping("/api/auth/register") ResponseEntity<Map<String, Object>> register(HttpServletRequest request, @RequestBody Map<String, Object> body) {
        guard.csrf(request); guard.limit(request, "register", 5, 3600); return ResponseEntity.status(HttpStatus.CREATED).body(auth.register(text(body,"username"),text(body,"email"),text(body,"phone"),text(body,"password")));
    }
    @PostMapping("/api/auth/resend-signup") Map<String, Object> resend(HttpServletRequest request, @RequestBody Map<String, Object> body) { guard.csrf(request); return auth.resend(Long.parseLong(text(body,"accountId"))); }
    @PostMapping("/api/auth/verify-signup") Map<String, Object> verify(HttpServletRequest request, @RequestBody Map<String, Object> body) { guard.csrf(request); auth.verify(Long.parseLong(text(body,"accountId")),text(body,"emailCode"),text(body,"phoneCode")); return Map.of("message","Account verified. You can now sign in."); }
    @PostMapping("/api/auth/request-reset") Map<String, Object> requestReset(HttpServletRequest request, @RequestBody Map<String, Object> body) { guard.csrf(request); guard.limit(request,"reset",5,600); return auth.requestReset(text(body,"email")); }
    @PostMapping("/api/auth/reset-password") Map<String, Object> reset(HttpServletRequest request, @RequestBody Map<String, Object> body) { guard.csrf(request); auth.resetPassword(text(body,"email"),text(body,"code"),text(body,"password")); return Map.of("message","Password updated. You can now sign in."); }

    @GetMapping("/api/admin/products") Map<String, Object> adminProducts(HttpServletRequest request) { admin(request); return Map.of("products", catalog.all()); }
    @PostMapping("/api/admin/products") ResponseEntity<Map<String, Object>> createProduct(HttpServletRequest request, @Valid @RequestBody ProductRequest body) {
        adminWrite(request); var product = catalog.create(body); audits.log(request,"create","product",product.id(),product.name()); return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("products",catalog.all(),"auditLogs",audits.latest()));
    }
    @PutMapping("/api/admin/products/{id}") Map<String, Object> updateProduct(HttpServletRequest request, @PathVariable long id, @Valid @RequestBody ProductRequest body) {
        adminWrite(request); var product = catalog.update(id,body); audits.log(request,"update","product",id,product.name()); return Map.of("products",catalog.all(),"auditLogs",audits.latest());
    }
    @DeleteMapping("/api/admin/products/{id}") Map<String, Object> deleteProduct(HttpServletRequest request, @PathVariable long id) {
        adminWrite(request); catalog.delete(id); audits.log(request,"delete","product",id,"Product deleted"); return Map.of("products",catalog.all(),"auditLogs",audits.latest());
    }
    @GetMapping("/api/admin/inquiries") Map<String, Object> adminInquiries(HttpServletRequest request) { admin(request); return Map.of("inquiries",inquiries.all(),"auditLogs",audits.latest()); }
    @PostMapping("/api/admin/inquiries/{id}/status") Map<String, Object> inquiryStatus(HttpServletRequest request,@PathVariable long id,@RequestBody Map<String,Object> body) {
        adminWrite(request); var status=text(body,"status"); var result=inquiries.status(id,status); audits.log(request,"update_status","inquiry",id,"Inquiry marked "+status); return Map.of("inquiries",result,"auditLogs",audits.latest());
    }
    @GetMapping("/api/admin/feedback") Map<String, Object> adminFeedback(HttpServletRequest request) { admin(request); return Map.of("feedback",feedback.adminList(),"auditLogs",audits.latest()); }
    @PostMapping("/api/admin/feedback/{id}/hide") Map<String, Object> hideFeedback(HttpServletRequest request,@PathVariable long id) { adminWrite(request); feedback.toggleVisibility(id); audits.log(request,"toggle_visibility","feedback",id,"Feedback visibility changed"); return Map.of("feedback",feedback.adminList(),"auditLogs",audits.latest()); }
    @DeleteMapping("/api/admin/feedback/{id}") Map<String, Object> deleteFeedback(HttpServletRequest request,@PathVariable long id) { adminWrite(request); feedback.delete(id); audits.log(request,"delete","feedback",id,"Feedback deleted"); return Map.of("feedback",feedback.adminList(),"auditLogs",audits.latest()); }
    @GetMapping("/api/admin/audits") Map<String, Object> adminAudits(HttpServletRequest request) { admin(request); return Map.of("auditLogs",audits.latest()); }
    @GetMapping("/api/admin/settings") Map<String, Object> settings(HttpServletRequest request) { admin(request); return Map.of("settings",business.settings()); }
    @PutMapping("/api/admin/settings") Map<String, Object> settings(HttpServletRequest request,@RequestBody Map<String,String> body) { adminWrite(request); try { var values=business.update(body); audits.log(request,"update","settings","business","Business details updated"); return Map.of("settings",values,"auditLogs",audits.latest()); } catch (IllegalArgumentException error) { throw new org.springframework.web.server.ResponseStatusException(HttpStatus.BAD_REQUEST,error.getMessage()); } }

    private void admin(HttpServletRequest request) { guard.admin(request); }
    private void adminWrite(HttpServletRequest request) { guard.admin(request); guard.csrf(request); guard.limit(request,"admin-write",100,600); }
    private static String text(Map<String, ?> body, String key) { var value=body.get(key); return value==null?"":String.valueOf(value).trim(); }
    private static Long number(Object value) { if(value==null||String.valueOf(value).isBlank())return null; try{return Long.valueOf(String.valueOf(value));}catch(NumberFormatException ignored){return null;} }
    private static Object nullable(Object value) { return value == null ? new java.util.LinkedHashMap<>() : value; }
}
