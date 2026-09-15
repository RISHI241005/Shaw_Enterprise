package com.shawenterprise;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.jdbc.core.JdbcTemplate;
import java.net.CookieManager;
import java.net.URI;
import java.net.HttpURLConnection;
import java.nio.charset.StandardCharsets;
import java.util.regex.Pattern;
import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT, properties = {
 "spring.datasource.url=jdbc:h2:mem:flows;MODE=MySQL;DATABASE_TO_LOWER=TRUE;DB_CLOSE_DELAY=-1",
 "spring.datasource.username=sa", "spring.datasource.password=",
 "spring.flyway.enabled=false", "spring.sql.init.mode=always",
 "spring.sql.init.schema-locations=classpath:db/migration/V1__java_backend.sql,classpath:order-test-schema.sql",
 "spring.session.jdbc.initialize-schema=always", "app.production=false",
 "app.admin.username=flow-admin", "app.admin.password=flow-test-password-only"
})
class StorefrontFlowTest {
 @LocalServerPort int port;
 @Autowired JdbcTemplate jdbc;
 CookieManager cookies;
 String csrf;

 @BeforeEach void setup() throws Exception {
  cookies = new CookieManager();
  var page = send("GET", "/checkout", null);
  assertThat(page.statusCode()).isEqualTo(200);
  var token = Pattern.compile("name=\"csrf-token\" content=\"([^\"]+)\"").matcher(page.body());
  assertThat(token.find()).isTrue(); csrf = token.group(1);
 }
 record Response(int statusCode, String body) {}
 Response send(String method, String path, String body) throws Exception {
  var uri = URI.create("http://localhost:"+port+path);
  var request = (HttpURLConnection) uri.toURL().openConnection();
  request.setRequestMethod(method);
  request.setConnectTimeout(10000); request.setReadTimeout(10000);
  cookies.get(uri, java.util.Map.of()).forEach((key, values) -> request.setRequestProperty(key, String.join("; ",values)));
  if (body != null) {
   request.setRequestProperty("Content-Type", "application/json");
   if (csrf != null) request.setRequestProperty("X-CSRF-Token", csrf);
   request.setDoOutput(true);
   try (var output = request.getOutputStream()) { output.write(body.getBytes(StandardCharsets.UTF_8)); }
  }
  int status = request.getResponseCode();
  cookies.put(uri, request.getHeaderFields());
  var stream = status >= 400 ? request.getErrorStream() : request.getInputStream();
  String response = stream == null ? "" : new String(stream.readAllBytes(),StandardCharsets.UTF_8);
  if (stream != null) stream.close(); request.disconnect();
  return new Response(status,response);
 }
 void login() throws Exception {
  assertThat(send("POST", "/api/auth/login", "{\"username\":\"flow-admin\",\"password\":\"flow-test-password-only\"}").statusCode()).isEqualTo(200);
 }
 long product(String name, String price) throws Exception {
  var body = "{\"name\":\""+name+"\",\"category\":\"Flow tests\",\"unitPrice\":"+price+",\"stockQuantity\":10,\"orderingEnabled\":true}";
  assertThat(send("POST", "/api/admin/products", body).statusCode()).isEqualTo(201);
  return jdbc.queryForObject("SELECT id FROM products WHERE name=?",Long.class,name);
 }
 String order(long id, String fulfillment, int quantity) {
  return "{\"customerName\":\"Test Customer\",\"email\":\"customer@example.test\",\"phone\":\"9876543210\",\"fulfillmentMethod\":\""+fulfillment+"\",\"addressLine\":\"Test address\",\"city\":\"Kolkata\",\"state\":\"West Bengal\",\"postalCode\":\"700001\",\"items\":[{\"productId\":"+id+",\"quantity\":"+quantity+"}]}";
 }
 @Test void unpricedCheckoutHistoryRecoveryAndCancellation() throws Exception {
  login(); long id = product("Unpriced flow product", "null");
  var placed = send("POST","/api/orders",order(id,"delivery",2));
  assertThat(placed.statusCode()).withFailMessage(placed.body()).isEqualTo(201);
  assertThat(placed.body()).contains("pricingPending\":true");
  assertThat(jdbc.queryForObject("SELECT stock_quantity FROM products WHERE id=?",Integer.class,id)).isEqualTo(8);
  assertThat(send("GET","/api/orders",null).body()).contains("Unpriced flow product");
  var reference = jdbc.queryForObject("SELECT order_number FROM orders WHERE customer_name='Test Customer' ORDER BY id DESC LIMIT 1",String.class);
  assertThat(send("POST","/api/orders/lookup","{\"orderNumber\":\""+reference+"\",\"phone\":\"9876543210\"}").statusCode()).isEqualTo(200);
  assertThat(send("POST","/api/orders/lookup","{\"orderNumber\":\""+reference+"\",\"phone\":\"9876543211\"}").statusCode()).isEqualTo(404);
  long orderId = jdbc.queryForObject("SELECT id FROM orders WHERE order_number=?",Long.class,reference);
  assertThat(send("GET","/api/admin/orders",null).statusCode()).isEqualTo(200);
  assertThat(send("POST","/api/admin/orders/"+orderId+"/status","{\"status\":\"cancelled\"}").statusCode()).isEqualTo(200);
  assertThat(jdbc.queryForObject("SELECT stock_quantity FROM products WHERE id=?",Integer.class,id)).isEqualTo(10);
  assertThat(send("POST","/api/admin/orders/"+orderId+"/status","{\"status\":\"cancelled\"}").statusCode()).isEqualTo(409);
 }
 @Test void pricedPickupFulfillmentAndStockValidation() throws Exception {
  login(); long id = product("Priced flow product", "100.00");
  assertThat(send("POST","/api/orders",order(id,"delivery",11)).statusCode()).isEqualTo(409);
  assertThat(jdbc.queryForObject("SELECT stock_quantity FROM products WHERE id=?",Integer.class,id)).isEqualTo(10);
  var result = send("POST","/api/orders",order(id,"pickup",1));
  assertThat(result.statusCode()).withFailMessage(result.body()).isEqualTo(201);
  assertThat(result.body()).contains("pay_on_pickup").contains("\"total\":100.00");
  long orderId = jdbc.queryForObject("SELECT id FROM orders WHERE fulfillment_method='pickup' ORDER BY id DESC LIMIT 1",Long.class);
  assertThat(send("POST","/api/admin/orders/"+orderId+"/status","{\"status\":\"delivered\"}").statusCode()).isEqualTo(409);
  for (var status : new String[]{"confirmed","packing","ready","delivered"})
   assertThat(send("POST","/api/admin/orders/"+orderId+"/status","{\"status\":\""+status+"\"}").statusCode()).isEqualTo(200);
 }
 @Test void accessValidationAndInquiryFlows() throws Exception {
  assertThat(send("POST","/api/auth/verify-signup","{\"accountId\":\"invalid\"}").statusCode()).isEqualTo(400);
  assertThat(send("POST","/api/orders","{broken").statusCode()).isEqualTo(400);
  assertThat(send("GET","/api/admin/orders",null).statusCode()).isEqualTo(401);
  assertThat(send("POST","/api/orders","{}").statusCode()).isEqualTo(400);
  var savedCsrf = csrf; csrf = null;
  var missingCsrf = send("POST","/api/orders","{}"); csrf = savedCsrf;
  assertThat(missingCsrf.statusCode()).isEqualTo(403);
  assertThat(send("POST","/api/inquiries","{\"name\":\"Flow test\",\"email\":\"flow@example.test\",\"phone\":\"9876543210\",\"message\":\"Test enquiry\"}").statusCode()).isEqualTo(201);
  login();
  assertThat(send("GET","/api/admin/inquiries",null).body()).contains("Test enquiry");
  long inquiry = jdbc.queryForObject("SELECT id FROM inquiries ORDER BY id DESC LIMIT 1",Long.class);
  assertThat(send("POST","/api/admin/inquiries/"+inquiry+"/status","{\"status\":\"contacted\"}").statusCode()).isEqualTo(200);
  assertThat(send("POST","/api/admin/products","{\"name\":\"Name only flow product\"}").statusCode()).isEqualTo(201);
 }
 @Test void feedbackVerificationRepliesReactionsAndModeration() throws Exception {
  assertThat(send("POST","/api/feedback","{\"message\":\"Unverified feedback\"}").statusCode()).isEqualTo(403);
  var requested = send("POST","/api/feedback/request-otp","{\"email\":\"feedback@example.test\"}");
  assertThat(requested.statusCode()).isEqualTo(200);
  var otp = Pattern.compile("\"devOtp\":\"(\\d{6})\"").matcher(requested.body());
  assertThat(otp.find()).isTrue();
  assertThat(send("POST","/api/feedback/verify-otp","{\"email\":\"feedback@example.test\",\"otp\":\""+otp.group(1)+"\"}").statusCode()).isEqualTo(200);
  assertThat(send("POST","/api/feedback","{\"message\":\"Flow feedback root\"}").statusCode()).isEqualTo(201);
  long id = jdbc.queryForObject("SELECT id FROM feedback_comments WHERE message='Flow feedback root'",Long.class);
  assertThat(send("POST","/api/feedback","{\"message\":\"Flow reply\",\"parentId\":"+id+"}").statusCode()).isEqualTo(201);
  assertThat(send("POST","/api/feedback/"+id+"/react","{\"reaction\":\"heart\"}").statusCode()).isEqualTo(200);
  assertThat(send("GET","/api/feedback",null).body()).contains("Flow reply").contains("\"heart\":1");
  login();
  assertThat(send("GET","/api/admin/feedback",null).body()).contains("Flow feedback root");
  assertThat(send("POST","/api/admin/feedback/"+id+"/hide","{}").statusCode()).isEqualTo(200);
  assertThat(send("GET","/api/feedback",null).body()).doesNotContain("Flow feedback root");
  assertThat(send("DELETE","/api/admin/feedback/"+id,"{}").statusCode()).isEqualTo(200);
 }
 @Test void productEditingDeletionSettingsAndPublicPages() throws Exception {
  assertThat(send("POST","/api/auth/login","{\"username\":\"flow-admin\",\"password\":\"wrong\"}").statusCode()).isEqualTo(401);
  login(); long id = product("Editable flow product","150.00");
  assertThat(send("PUT","/api/admin/products/"+id,"{\"name\":\"Edited flow product\",\"stockQuantity\":5,\"orderingEnabled\":true}").statusCode()).isEqualTo(200);
  assertThat(send("GET","/api/products/"+id,null).body()).contains("Edited flow product");
  assertThat(jdbc.queryForObject("SELECT unit_price FROM products WHERE id=?",java.math.BigDecimal.class,id)).isNull();
  assertThat(send("DELETE","/api/admin/products/"+id,"{}").statusCode()).isEqualTo(200);
  assertThat(send("GET","/api/products/"+id,null).statusCode()).isEqualTo(404);
  assertThat(send("PUT","/api/admin/settings","{}").statusCode()).isEqualTo(400);
  assertThat(send("PUT","/api/admin/settings","{\"business_name\":\"Flow Shop\",\"phone\":\"9876543210\",\"email\":\"shop@example.test\",\"address\":\"Kolkata\",\"whatsapp\":\"919876543210\",\"hours\":\"9 to 5\"}").statusCode()).isEqualTo(200);
  for (var path : new String[]{"/","/products","/orders","/checkout","/feedback","/contact","/admin","/healthz"})
   assertThat(send("GET",path,null).statusCode()).as(path).isEqualTo(200);
 }
}
