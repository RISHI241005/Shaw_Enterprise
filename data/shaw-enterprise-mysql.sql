-- Shaw Enterprise full MySQL database
-- Generated from the local SQLite project database.
CREATE DATABASE IF NOT EXISTS shaw_enterprise CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE shaw_enterprise;
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS feedback_reactions;
DROP TABLE IF EXISTS feedback_comments;
DROP TABLE IF EXISTS feedback_identity_otps;
DROP TABLE IF EXISTS feedback_identities;
DROP TABLE IF EXISTS inquiries;
DROP TABLE IF EXISTS product_images;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS product_categories;
DROP TABLE IF EXISTS admin_audit_logs;
DROP TABLE IF EXISTS admin_users;
DROP TABLE IF EXISTS business_settings;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE product_categories (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE products (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  name VARCHAR(180) NOT NULL,
  sku VARCHAR(60) NOT NULL UNIQUE,
  price_label VARCHAR(80) NOT NULL,
  product_type VARCHAR(160) NOT NULL,
  summary TEXT NOT NULL,
  details TEXT NOT NULL,
  pack_size VARCHAR(160) NOT NULL,
  audience VARCHAR(180) NOT NULL,
  featured BOOLEAN NOT NULL DEFAULT FALSE,
  status ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  INDEX idx_products_category (category_id),
  INDEX idx_products_featured (featured),
  CONSTRAINT fk_products_category FOREIGN KEY (category_id) REFERENCES product_categories(id)
) ENGINE=InnoDB;

CREATE TABLE product_images (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  product_id BIGINT UNSIGNED NOT NULL,
  image_data LONGTEXT NOT NULL,
  alt_text VARCHAR(220) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_product_images_product (product_id),
  CONSTRAINT fk_product_images_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE admin_users (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(80) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('owner','manager','staff') NOT NULL DEFAULT 'owner',
  status ENUM('active','disabled') NOT NULL DEFAULT 'active',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE inquiries (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(160) NOT NULL,
  email VARCHAR(180) NOT NULL,
  phone VARCHAR(60) NOT NULL,
  message TEXT NOT NULL,
  status ENUM('new','contacted','closed') NOT NULL DEFAULT 'new',
  created_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE feedback_identities (
  visitor_id VARCHAR(80) PRIMARY KEY,
  email VARCHAR(180) NOT NULL UNIQUE,
  verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE feedback_identity_otps (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(80) NOT NULL,
  email VARCHAR(180) NOT NULL,
  otp_hash VARCHAR(255) NOT NULL,
  expires_at DATETIME NOT NULL,
  used_at DATETIME NULL,
  created_at DATETIME NOT NULL,
  INDEX idx_feedback_otps_visitor (visitor_id)
) ENGINE=InnoDB;

CREATE TABLE feedback_comments (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  visitor_id VARCHAR(80) NOT NULL,
  author_email VARCHAR(180) NOT NULL,
  message TEXT NOT NULL,
  parent_id BIGINT UNSIGNED NULL,
  product_id BIGINT UNSIGNED NULL,
  status ENUM('visible','hidden') NOT NULL DEFAULT 'visible',
  created_at DATETIME NOT NULL,
  INDEX idx_feedback_parent (parent_id),
  INDEX idx_feedback_product (product_id),
  CONSTRAINT fk_feedback_parent FOREIGN KEY (parent_id) REFERENCES feedback_comments(id) ON DELETE CASCADE,
  CONSTRAINT fk_feedback_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE feedback_reactions (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  feedback_id BIGINT UNSIGNED NOT NULL,
  visitor_id VARCHAR(80) NOT NULL,
  reaction ENUM('like','heart') NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uq_feedback_reaction_visitor (feedback_id, visitor_id),
  CONSTRAINT fk_reactions_feedback FOREIGN KEY (feedback_id) REFERENCES feedback_comments(id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE admin_audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  action_type VARCHAR(80) NOT NULL,
  target_type VARCHAR(80) NOT NULL,
  target_id VARCHAR(80),
  details TEXT NOT NULL,
  ip_address VARCHAR(80) NOT NULL,
  created_at DATETIME NOT NULL
) ENGINE=InnoDB;

CREATE TABLE business_settings (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(120) NOT NULL UNIQUE,
  setting_value TEXT NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

INSERT INTO product_categories (name, description) VALUES ('Bags', 'Bags products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Bowls', 'Bowls products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Containers', 'Containers products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Cups', 'Cups products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Cutlery', 'Cutlery products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Napkins', 'Napkins products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Plates', 'Plates products for Shaw Enterprise catalog');
INSERT INTO product_categories (name, description) VALUES ('Straws', 'Straws products for Shaw Enterprise catalog');
INSERT INTO admin_users (username, password_hash, role, status) VALUES ('admin', 'ccc0b903bce51fb554262d742d0a282e1f8a87d064f1cf44f8ff5148ca4beb42', 'owner', 'active');
INSERT INTO business_settings (setting_key, setting_value) VALUES
('business_name', 'Shaw Enterprise'),
('phone', '+91 00000 00000'),
('email', 'sales@shawenterprise.example'),
('address', 'Your shop address, city, state'),
('whatsapp', '910000000000');
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 1, id, 'Ripple Paper Cups', 'SE-0001', 'Rs. 95 / 50 pcs', 'Hot beverage disposable', 'Insulated cups for tea, coffee, and catering counters.', 'Triple-layer ripple cups with firm grip, strong rim, and dependable heat resistance for events, offices, food stalls, and cafes.', '50 pcs, 100 pcs, carton packs', 'Tea stalls, offices, cafes, events', 1, 'active', '2026-06-07 09:32:36', '2026-06-08 10:32:20'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (1, 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxISEhUTExIWEhUXFRcVFRIVEhUYFRcVFRIWFxUVFRoYHSggGBolGxUVITEhJSkrLi4uFx8zODMsNygtLisBCgoKDg0OGhAQGisdHR0xLSstLSstKystKy0tLi0uLS0tKy0uNS0tKy0tNy0tLS0tLS0tLS0tLS0tLS0tKy0tLf/AABEIANUA7QMBIgACEQEDEQH/xAAcAAEAAgMBAQEAAAAAAAAAAAAABQYBBAcDAgj/xABFEAACAQIBCQMHCQYFBQAAAAAAAQIDEQQFEiExQVFhcZEGUoEiQmKSocHhBxMUMnKCsdHwQ1Njg6LSM1ST4vEVI0Sywv/EABkBAQADAQEAAAAAAAAAAAAAAAABAgQFA//EACIRAQEAAgIBBAMBAAAAAAAAAAABAhEDBDEhIkFREhRhE//aAAwDAQACEQMRAD8A7iAAAAAAGAMgwAMgwAMgwAMgwAMgwAMgwAMgwAMgwAMgwAMgAAAAAAAAAAAAAAAAAAAaeU8qUcPDPrVI0475PW9yWtvkBuA5nl/5XKdNP6Lh54iWxyahHnbW10KPjPlPyzWvmujhY+jTUpLxk2B+hAfmnE9t8Y1apjqre3Nm4q/KNrEfPtnV/wAziH/Nn/cTpG36mB+WI9ta3+YxK/nT/uN/Cdv8TH6uNrr7UnL/ANrjSX6YBwfJ3ym49WtXp1uE6cbv1c1lmyf8rUlZYnC29OlL/wCJ/wBw0OpAgMh9sMHi7KlWSm/2c/In4J6/C5PkAAAAAAAAAAAAAAAAAAAAAAABgQva3L8cDh5Vms6X1acO9N6ly1t8EcDyzlatiqjq1pucn6sV3YrzUdA+UrKdPHRVPDS+c+j1H844/VcpRatF+daz08TmMokyIa/0ht2irv2LmeOJzX9ao5vuwWheOo+J0XfN2beJuYfBJ6vK4arfAsIj6PHZF+L/ACPqOFj3F7fzJieGUXZ6OjXsPPNIGjTwEWr5sejPR5Oj3YtfeWy+820rajOcwNWjQp7Yvwl+ZNYNxStGo7d2pHOj12EbY9ITt+QEjXw0XpS+blss705P0X5rLX2M+UOthpKjipOrRvbPempT431zitz07txSqdVxTs7ratjPjF2ztG5fhtA/T9GrGcVKLUoyScZLU01dNH2UH5JsuQnhYYadRfPQznGm9DdLPea495LStGqyL8VSAAAAAAAAAAAAAAAAAAAc9+V/tFOhRhh6cs2VbOc5LWqUbJpbs5u3JM6Ecq+VHCrFV1Gm/LowUXzk3JICn9jcUo/OQfnWkvu/8mzlbA0qjzv8OT1tK8X9pbHxRWcNKdKraSzZJ6Lqy4p7uZM18ZnLToe0uqjcTk6cdiku9F3XsNXNXI9sRXa1O3JkfXyjNbVLmkQltOG7St5iUHuI15Xa1wT5Noy8uR7j9YCQsZ07uWj9XI1ZbgvNlp4of9bjsi/WRAk/mna9tG/YIxS19CNWU29Ubc2z7p4qT3EiQu5PQrvgbNLAN6Zv7uvqa2GxB6YnHWWh+JKGcZjJRqwlTk4yp2zZRdmmne66ne+wPaH6dhI1Jf4kW6dS2rOSXlLmmn1PzhQUpPhve17ztnyNSjClVot2qOSq5voOKin1j7UVqY6OACEgAAAAAAAAAAAAAAABzHLOT5xxtdvQpvOT2OMkmujuvA6cR+V8mRrx06JL6svc+BMo5DlfD05eTXhp2VFrt7yFqZLaX/bnGrHZFu0l+Re8p4XNvCrHfoep22xZVsfkOL8qnLNe6V/Y0W2jSsY3BS2xlB8VddUQGLw01x5O/s1lnxka8NGe+qkiLrYmr6EucSBWatOS1xfRmvJllliJ/uoPk7Hk8Q/3HSRAr1z6jcnXW/ge34j5yWyklzfxGxHUM7c+huUqU38NP4GxGVTdCP65HorvXPwQ2PqjRlu08X7kbVPAp6Zy8PgjGHo32krhaMVx5lkMUYQgrqN919pb/krjUqY91NNo05Oo9lpWUY9dS9FmjkPs9UxlRQhaKteVSS0KKte296VoOvdnshUcHS+bpLjKb+tOW+X5bCLYnVSgAKpAAAAAAAAAAAAAAAAAABBZVoKTkpJNPY1oKdlXIq8yTj6L0rwesvWUo+VfeiDxsdFtCW6SvF8nsOZnnlx53Vb+LHHPGbjl+VclVVeyT8bfiVbG4KstdOT5K/4HW8oYXfFpb15USr43Bxb0L1ZNPoXncznn1Murj8OZV4yWtSXg0a/zz7z6sv2Iwz31V4mhPDr+K/BHpO5L5jyvV/qofPS70urCnJ7W/Flq+gr91UlzaXuPuOGiv2VOPGc7voT+1PpH61+1aw1OUnoi5ck2StLJ9Va45v2mk+msmqD2Kbfo0oZq6m9RpqL2QfDyp9dh55dzL4i860+a0cBkibs5vMW615PkizZOyXTi7tZzXe024vZfgeGGhzXjeb/InMJTt+X61spefPLzXpjw4z4WvsVQ8upLdFR6u9v6S3EB2OpWpSl3p+xJfEnzbwzWEZOa7zoAD1eQAAAAAAAAAAAAAAAAAANDKcdT5kJitG2y26LxfNbCfykvJXMgsSua4r3rajm9mazrb177UFioW0qMl6VKV16pX8a0/OUuElZljxdO92oqXpU5ZsvFEDj5bM98qkPeZmxA4qhr0NfZZG1KT3VXyZK4mHox+67e4jqtL+HL1yJVa1Hh/wCHN/anYwqSXm0485ZzPR0f4frVDEbL93HleTL7Q9qbvozpTW6Mc2JvUVbQrR4R0y8WakLvvT/pib1BbF0gtHjIrRv4VbNXDW/FkxhYkThVy5LV4vaTGGWgvih0Ps5TzcPDjd9ZNkkeGCp5tOEd0Yroj3OtjNYyOZld5WgALKgAAAAAAAAAAAAAAAAAA18cvIf62kBiFzvw+suW8sdeN4tcH+BXcQuHhe3R7GYO3PdK19aoXFxztkZvg8yp8SBx8redOPCpG666CwY1X0PNk+7PyZeEtpA49W78OflRMbd8ILExvsg+K0MjatH0E/v/AAJPEtPbCXNWZHVaS7kPWKzyhqypLuQXOYjK3nQXCMbvqfTilsprm7iNT01yhD3l1XtGN9LUpcZuy6G9h9K3rcvJgvzNOMdrXjN6ehvUdj17m9EfBFaJDCfrd4E/kqlnThHfKKfVEJgy1dlqV68OCcuif5ntxzdkVzusbV9QAOs5YAAAAAAAAAAAAAAAAAAAAAwyu4uNrrjbTq0byxkFlGNpS69dJk7c9srR177kBjXZWbsu7NZ0PCWwgMbC2pSjxhLOXQsWL0K92lvSzoeMdhXsbC+lKL405W6pnOrpTwgsVP0k/tRt7yNrJX1U/F/Ek8XLjJfajf3EbVku9D1WRFWs5LfSXJNn1Cd9UpPhCNvaYc/TX3afwPuF3+8lz8lFlXrTVtijzedI3qG/2y+s+S2I0aS3WXCKzn1N/Dq3PrL4ECVwSLr2KpeXOW6KXrP/AGlMwZf+xVK1Kct87eEYr82a+vN5x4891hVjAB0XPAAAAAAAAAAAAAAAAAAAAAAiMrR8rmiXI3K8dT5oz9mb469eG6zit4ta7Xb3x0TXNbSvZQs3rjJ8VmTLFjls0Pcm7erL3EBlLc21wqRuvCRy3UnhXsTo7y6SRHVZvvP/AE/gSeKjuT+7LR7SOqX31F4IqitVzb86b5QsZzN8XznO3sPpxb2VHzaXvPlQS2Rj9qWc+hdD3o7k78IKy6m7h93sXvZqU9O9rj5Meht4d/rZ4byIhL4M6V2Tp2w0eLk/6mvcc3wZ1HIMLYekvQT66feburPczdm+2N8AG5iAAAAAAAAAAAAAAAAAAAAAA1sfSzoO2taUbIK5Y/lLKmXV2puN1PUlturx8dz4lex6stsVwanD4F7yrkrOvKGiW4pGVcNKD0wcXvj5N/uvQ/A5XJxZYX1dTi5Mc56K1i0n3XydiOqxfdl4TJHGy06WvvRsyLqJbo+EjxXrwlB7Yv70zMWl3V9lXZ8SSWyC5ts+oS3P1Y29pZDZg9/WXuRvYZ/r9ajQpLwfV9SXyXgKlRpQg3x2eL1DGW30Vt15SeTqLnKMIq7k7LxOs4anmxjHupLorFa7L5HVJpvypa3LdwXiWk6fX4/xnqwc3J+V1PEAAaHiAAAAAAAAAAAAAAAAAAAAAAAAwyPxtJNWkk1uauvaSJ8zgnoautzIs2mXSlY/IWHl+zS5NogMV2Xo7G10Z0avkmnLVnR+zL3O6Iyv2Yb+rXa500/waPC8GN+I9Jy5T5c7n2XjfRVt/LifVLszT86rN8NCLy+yE3/5K/0P956UOx6X1685cIxjH8bkTr4fSf8AbP7V3AZMw9JeTCPOWl+0sOT8PKp9SOjvao/HwJbC5Aw9PSoZz3zk5ex6PYSSR7Y4SeHncrfLxwmGUFbW9r3nuAXVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH//2Q==', 'Ripple Paper Cups', 0);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 2, id, 'Premium Paper Plates', 'SE-0002', 'Rs. 120 / 100 pcs', 'Meal serving disposable', 'Strong round plates for parties and daily food service.', 'Leak-resistant disposable plates designed for snacks, meals, religious events, catering, and retail resale counters.', '100 pcs, 500 pcs, bulk carton', 'Caterers, households, wholesalers', 1, 'active', '2026-06-07 09:32:36', '2026-06-07 09:32:36'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (2, '/images/plate-1.svg', 'Premium Paper Plates', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (2, '/images/plate-2.svg', 'Premium Paper Plates', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (2, '/images/plate-3.svg', 'Premium Paper Plates', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 3, id, 'Food Container Set', 'SE-0003', 'Rs. 180 / 25 pcs', 'Takeaway packaging', 'Secure containers for restaurant packing and delivery.', 'Stackable food containers with fitted lids, suited for rice, curry, snacks, bakery, sweets, and takeaway operations.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, sweet shops', 1, 'active', '2026-06-07 09:32:36', '2026-06-07 09:32:36'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (3, '/images/container-1.svg', 'Food Container Set', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (3, '/images/container-2.svg', 'Food Container Set', 1);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 4, id, 'Wooden Cutlery Pack', 'SE-0004', 'Rs. 75 / 100 pcs', 'Eco-friendly disposable', 'Clean disposable spoons and forks for professional service.', 'Smooth finish disposable cutlery for events, takeaway counters, office pantry supply, and food sampling counters.', '100 pcs, 500 pcs, mixed carton', 'Event managers, food counters, retailers', 0, 'active', '2026-06-07 09:32:36', '2026-06-07 09:32:36'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (4, '/images/cutlery-1.svg', 'Wooden Cutlery Pack', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (4, '/images/cutlery-2.svg', 'Wooden Cutlery Pack', 1);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 5, id, 'Economy Tissue Napkin Pack 005', 'SE-0005', 'Rs. 66 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0005 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (5, '/images/generated-napkins-5-1.svg', 'Economy Tissue Napkin Pack 005', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (5, '/images/generated-napkins-5-2.svg', 'Economy Tissue Napkin Pack 005', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (5, '/images/generated-napkins-5-3.svg', 'Economy Tissue Napkin Pack 005', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 6, id, 'Small Paper Carry Bag 006', 'SE-0006', 'Rs. 165 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0006 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (6, '/images/generated-bags-6-1.svg', 'Small Paper Carry Bag 006', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (6, '/images/generated-bags-6-2.svg', 'Small Paper Carry Bag 006', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (6, '/images/generated-bags-6-3.svg', 'Small Paper Carry Bag 006', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 7, id, 'Medium Paper Straw Pack 007', 'SE-0007', 'Rs. 77 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0007 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (7, '/images/generated-straws-7-1.svg', 'Medium Paper Straw Pack 007', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (7, '/images/generated-straws-7-2.svg', 'Medium Paper Straw Pack 007', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (7, '/images/generated-straws-7-3.svg', 'Medium Paper Straw Pack 007', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 8, id, 'Large Paper Soup Bowl 008', 'SE-0008', 'Rs. 119 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0008 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (8, '/images/generated-bowls-8-1.svg', 'Large Paper Soup Bowl 008', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (8, '/images/generated-bowls-8-2.svg', 'Large Paper Soup Bowl 008', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (8, '/images/generated-bowls-8-3.svg', 'Large Paper Soup Bowl 008', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 9, id, 'Premium Plain Paper Cup 009', 'SE-0009', 'Rs. 124 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0009 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (9, '/images/generated-cups-9-1.svg', 'Premium Plain Paper Cup 009', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (9, '/images/generated-cups-9-2.svg', 'Premium Plain Paper Cup 009', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (9, '/images/generated-cups-9-3.svg', 'Premium Plain Paper Cup 009', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 10, id, 'Economy Compartment Meal Plate 010', 'SE-0010', 'Rs. 153 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0010 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (10, '/images/generated-plates-10-1.svg', 'Economy Compartment Meal Plate 010', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (10, '/images/generated-plates-10-2.svg', 'Economy Compartment Meal Plate 010', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (10, '/images/generated-plates-10-3.svg', 'Economy Compartment Meal Plate 010', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 11, id, 'Small Rectangular Meal Box 011', 'SE-0011', 'Rs. 185 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0011 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (11, '/images/generated-containers-11-1.svg', 'Small Rectangular Meal Box 011', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (11, '/images/generated-containers-11-2.svg', 'Small Rectangular Meal Box 011', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (11, '/images/generated-containers-11-3.svg', 'Small Rectangular Meal Box 011', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 12, id, 'Medium Disposable Fork Pack 012', 'SE-0012', 'Rs. 119 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0012 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 1, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (12, '/images/generated-cutlery-12-1.svg', 'Medium Disposable Fork Pack 012', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (12, '/images/generated-cutlery-12-2.svg', 'Medium Disposable Fork Pack 012', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (12, '/images/generated-cutlery-12-3.svg', 'Medium Disposable Fork Pack 012', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 13, id, 'Large Printed Napkin 013', 'SE-0013', 'Rs. 122 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0013 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (13, '/images/generated-napkins-13-1.svg', 'Large Printed Napkin 013', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (13, '/images/generated-napkins-13-2.svg', 'Large Printed Napkin 013', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (13, '/images/generated-napkins-13-3.svg', 'Large Printed Napkin 013', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 14, id, 'Premium Kraft Grocery Bag 014', 'SE-0014', 'Rs. 221 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0014 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (14, '/images/generated-bags-14-1.svg', 'Premium Kraft Grocery Bag 014', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (14, '/images/generated-bags-14-2.svg', 'Premium Kraft Grocery Bag 014', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (14, '/images/generated-bags-14-3.svg', 'Premium Kraft Grocery Bag 014', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 15, id, 'Economy Bendy Straw Pack 015', 'SE-0015', 'Rs. 133 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0015 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (15, '/images/generated-straws-15-1.svg', 'Economy Bendy Straw Pack 015', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (15, '/images/generated-straws-15-2.svg', 'Economy Bendy Straw Pack 015', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (15, '/images/generated-straws-15-3.svg', 'Economy Bendy Straw Pack 015', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 16, id, 'Small Salad Bowl 016', 'SE-0016', 'Rs. 175 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0016 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (16, '/images/generated-bowls-16-1.svg', 'Small Salad Bowl 016', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (16, '/images/generated-bowls-16-2.svg', 'Small Salad Bowl 016', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (16, '/images/generated-bowls-16-3.svg', 'Small Salad Bowl 016', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 17, id, 'Medium Printed Tea Cup 017', 'SE-0017', 'Rs. 180 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0017 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (17, '/images/generated-cups-17-1.svg', 'Medium Printed Tea Cup 017', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (17, '/images/generated-cups-17-2.svg', 'Medium Printed Tea Cup 017', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (17, '/images/generated-cups-17-3.svg', 'Medium Printed Tea Cup 017', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 18, id, 'Large Silver Laminated Plate 018', 'SE-0018', 'Rs. 90 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0018 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (18, '/images/generated-plates-18-1.svg', 'Large Silver Laminated Plate 018', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (18, '/images/generated-plates-18-2.svg', 'Large Silver Laminated Plate 018', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (18, '/images/generated-plates-18-3.svg', 'Large Silver Laminated Plate 018', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 19, id, 'Premium Clear Lid Container 019', 'SE-0019', 'Rs. 122 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0019 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (19, '/images/generated-containers-19-1.svg', 'Premium Clear Lid Container 019', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (19, '/images/generated-containers-19-2.svg', 'Premium Clear Lid Container 019', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (19, '/images/generated-containers-19-3.svg', 'Premium Clear Lid Container 019', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 20, id, 'Economy Dessert Spoon Pack 020', 'SE-0020', 'Rs. 56 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0020 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (20, '/images/generated-cutlery-20-1.svg', 'Economy Dessert Spoon Pack 020', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (20, '/images/generated-cutlery-20-2.svg', 'Economy Dessert Spoon Pack 020', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (20, '/images/generated-cutlery-20-3.svg', 'Economy Dessert Spoon Pack 020', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 21, id, 'Small Dinner Napkin 021', 'SE-0021', 'Rs. 62 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0021 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (21, '/images/generated-napkins-21-1.svg', 'Small Dinner Napkin 021', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (21, '/images/generated-napkins-21-2.svg', 'Small Dinner Napkin 021', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (21, '/images/generated-napkins-21-3.svg', 'Small Dinner Napkin 021', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 22, id, 'Medium Food Delivery Bag 022', 'SE-0022', 'Rs. 161 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0022 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (22, '/images/generated-bags-22-1.svg', 'Medium Food Delivery Bag 022', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (22, '/images/generated-bags-22-2.svg', 'Medium Food Delivery Bag 022', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (22, '/images/generated-bags-22-3.svg', 'Medium Food Delivery Bag 022', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 23, id, 'Large Milkshake Straw 023', 'SE-0023', 'Rs. 73 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0023 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (23, '/images/generated-straws-23-1.svg', 'Large Milkshake Straw 023', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (23, '/images/generated-straws-23-2.svg', 'Large Milkshake Straw 023', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (23, '/images/generated-straws-23-3.svg', 'Large Milkshake Straw 023', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 24, id, 'Premium Dessert Bowl 024', 'SE-0024', 'Rs. 115 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0024 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (24, '/images/generated-bowls-24-1.svg', 'Premium Dessert Bowl 024', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (24, '/images/generated-bowls-24-2.svg', 'Premium Dessert Bowl 024', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (24, '/images/generated-bowls-24-3.svg', 'Premium Dessert Bowl 024', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 25, id, 'Economy Double Wall Coffee Cup 025', 'SE-0025', 'Rs. 120 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0025 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (25, '/images/generated-cups-25-1.svg', 'Economy Double Wall Coffee Cup 025', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (25, '/images/generated-cups-25-2.svg', 'Economy Double Wall Coffee Cup 025', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (25, '/images/generated-cups-25-3.svg', 'Economy Double Wall Coffee Cup 025', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 26, id, 'Small Snack Paper Plate 026', 'SE-0026', 'Rs. 149 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0026 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (26, '/images/generated-plates-26-1.svg', 'Small Snack Paper Plate 026', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (26, '/images/generated-plates-26-2.svg', 'Small Snack Paper Plate 026', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (26, '/images/generated-plates-26-3.svg', 'Small Snack Paper Plate 026', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 27, id, 'Medium Sauce Cup Container 027', 'SE-0027', 'Rs. 181 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0027 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (27, '/images/generated-containers-27-1.svg', 'Medium Sauce Cup Container 027', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (27, '/images/generated-containers-27-2.svg', 'Medium Sauce Cup Container 027', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (27, '/images/generated-containers-27-3.svg', 'Medium Sauce Cup Container 027', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 28, id, 'Large Ice Cream Spoon Pack 028', 'SE-0028', 'Rs. 115 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0028 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (28, '/images/generated-cutlery-28-1.svg', 'Large Ice Cream Spoon Pack 028', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (28, '/images/generated-cutlery-28-2.svg', 'Large Ice Cream Spoon Pack 028', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (28, '/images/generated-cutlery-28-3.svg', 'Large Ice Cream Spoon Pack 028', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 29, id, 'Premium Cocktail Napkin 029', 'SE-0029', 'Rs. 118 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0029 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (29, '/images/generated-napkins-29-1.svg', 'Premium Cocktail Napkin 029', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (29, '/images/generated-napkins-29-2.svg', 'Premium Cocktail Napkin 029', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (29, '/images/generated-napkins-29-3.svg', 'Premium Cocktail Napkin 029', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 30, id, 'Economy Bakery Paper Bag 030', 'SE-0030', 'Rs. 217 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0030 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (30, '/images/generated-bags-30-1.svg', 'Economy Bakery Paper Bag 030', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (30, '/images/generated-bags-30-2.svg', 'Economy Bakery Paper Bag 030', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (30, '/images/generated-bags-30-3.svg', 'Economy Bakery Paper Bag 030', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 31, id, 'Small Wrapped Straw 031', 'SE-0031', 'Rs. 129 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0031 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (31, '/images/generated-straws-31-1.svg', 'Small Wrapped Straw 031', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (31, '/images/generated-straws-31-2.svg', 'Small Wrapped Straw 031', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (31, '/images/generated-straws-31-3.svg', 'Small Wrapped Straw 031', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 32, id, 'Medium Rice Bowl 032', 'SE-0032', 'Rs. 171 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0032 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (32, '/images/generated-bowls-32-1.svg', 'Medium Rice Bowl 032', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (32, '/images/generated-bowls-32-2.svg', 'Medium Rice Bowl 032', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (32, '/images/generated-bowls-32-3.svg', 'Medium Rice Bowl 032', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 33, id, 'Large Cold Drink Paper Cup 033', 'SE-0033', 'Rs. 176 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0033 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (33, '/images/generated-cups-33-1.svg', 'Large Cold Drink Paper Cup 033', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (33, '/images/generated-cups-33-2.svg', 'Large Cold Drink Paper Cup 033', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (33, '/images/generated-cups-33-3.svg', 'Large Cold Drink Paper Cup 033', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 34, id, 'Premium Heavy Duty Dinner Plate 034', 'SE-0034', 'Rs. 205 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0034 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (34, '/images/generated-plates-34-1.svg', 'Premium Heavy Duty Dinner Plate 034', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (34, '/images/generated-plates-34-2.svg', 'Premium Heavy Duty Dinner Plate 034', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (34, '/images/generated-plates-34-3.svg', 'Premium Heavy Duty Dinner Plate 034', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 35, id, 'Economy Bakery Clamshell Box 035', 'SE-0035', 'Rs. 118 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0035 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (35, '/images/generated-containers-35-1.svg', 'Economy Bakery Clamshell Box 035', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (35, '/images/generated-containers-35-2.svg', 'Economy Bakery Clamshell Box 035', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (35, '/images/generated-containers-35-3.svg', 'Economy Bakery Clamshell Box 035', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 36, id, 'Small Knife Pack 036', 'SE-0036', 'Rs. 52 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0036 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (36, '/images/generated-cutlery-36-1.svg', 'Small Knife Pack 036', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (36, '/images/generated-cutlery-36-2.svg', 'Small Knife Pack 036', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (36, '/images/generated-cutlery-36-3.svg', 'Small Knife Pack 036', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 37, id, 'Medium Soft Table Tissue 037', 'SE-0037', 'Rs. 55 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0037 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (37, '/images/generated-napkins-37-1.svg', 'Medium Soft Table Tissue 037', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (37, '/images/generated-napkins-37-2.svg', 'Medium Soft Table Tissue 037', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (37, '/images/generated-napkins-37-3.svg', 'Medium Soft Table Tissue 037', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 38, id, 'Large Gift Paper Bag 038', 'SE-0038', 'Rs. 154 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0038 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (38, '/images/generated-bags-38-1.svg', 'Large Gift Paper Bag 038', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (38, '/images/generated-bags-38-2.svg', 'Large Gift Paper Bag 038', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (38, '/images/generated-bags-38-3.svg', 'Large Gift Paper Bag 038', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 39, id, 'Premium Cocktail Straw 039', 'SE-0039', 'Rs. 66 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0039 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (39, '/images/generated-straws-39-1.svg', 'Premium Cocktail Straw 039', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (39, '/images/generated-straws-39-2.svg', 'Premium Cocktail Straw 039', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (39, '/images/generated-straws-39-3.svg', 'Premium Cocktail Straw 039', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 40, id, 'Economy Noodle Bowl 040', 'SE-0040', 'Rs. 108 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0040 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (40, '/images/generated-bowls-40-1.svg', 'Economy Noodle Bowl 040', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (40, '/images/generated-bowls-40-2.svg', 'Economy Noodle Bowl 040', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (40, '/images/generated-bowls-40-3.svg', 'Economy Noodle Bowl 040', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 41, id, 'Small Kulhad Style Cup 041', 'SE-0041', 'Rs. 116 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0041 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (41, '/images/generated-cups-41-1.svg', 'Small Kulhad Style Cup 041', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (41, '/images/generated-cups-41-2.svg', 'Small Kulhad Style Cup 041', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (41, '/images/generated-cups-41-3.svg', 'Small Kulhad Style Cup 041', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 42, id, 'Medium Eco Bagasse Plate 042', 'SE-0042', 'Rs. 145 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0042 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (42, '/images/generated-plates-42-1.svg', 'Medium Eco Bagasse Plate 042', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (42, '/images/generated-plates-42-2.svg', 'Medium Eco Bagasse Plate 042', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (42, '/images/generated-plates-42-3.svg', 'Medium Eco Bagasse Plate 042', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 43, id, 'Large Microwave Safe Container 043', 'SE-0043', 'Rs. 177 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0043 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (43, '/images/generated-containers-43-1.svg', 'Large Microwave Safe Container 043', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (43, '/images/generated-containers-43-2.svg', 'Large Microwave Safe Container 043', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (43, '/images/generated-containers-43-3.svg', 'Large Microwave Safe Container 043', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 44, id, 'Premium Mixed Cutlery Kit 044', 'SE-0044', 'Rs. 111 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0044 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (44, '/images/generated-cutlery-44-1.svg', 'Premium Mixed Cutlery Kit 044', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (44, '/images/generated-cutlery-44-2.svg', 'Premium Mixed Cutlery Kit 044', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (44, '/images/generated-cutlery-44-3.svg', 'Premium Mixed Cutlery Kit 044', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 45, id, 'Economy Dispenser Tissue 045', 'SE-0045', 'Rs. 114 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0045 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (45, '/images/generated-napkins-45-1.svg', 'Economy Dispenser Tissue 045', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (45, '/images/generated-napkins-45-2.svg', 'Economy Dispenser Tissue 045', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (45, '/images/generated-napkins-45-3.svg', 'Economy Dispenser Tissue 045', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 46, id, 'Small Retail Counter Bag 046', 'SE-0046', 'Rs. 213 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0046 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (46, '/images/generated-bags-46-1.svg', 'Small Retail Counter Bag 046', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (46, '/images/generated-bags-46-2.svg', 'Small Retail Counter Bag 046', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (46, '/images/generated-bags-46-3.svg', 'Small Retail Counter Bag 046', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 47, id, 'Medium Jumbo Drink Straw 047', 'SE-0047', 'Rs. 125 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0047 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (47, '/images/generated-straws-47-1.svg', 'Medium Jumbo Drink Straw 047', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (47, '/images/generated-straws-47-2.svg', 'Medium Jumbo Drink Straw 047', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (47, '/images/generated-straws-47-3.svg', 'Medium Jumbo Drink Straw 047', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 48, id, 'Large Laminated Snack Bowl 048', 'SE-0048', 'Rs. 167 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0048 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (48, '/images/generated-bowls-48-1.svg', 'Large Laminated Snack Bowl 048', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (48, '/images/generated-bowls-48-2.svg', 'Large Laminated Snack Bowl 048', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (48, '/images/generated-bowls-48-3.svg', 'Large Laminated Snack Bowl 048', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 49, id, 'Premium Ripple Paper Cup 049', 'SE-0049', 'Rs. 172 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0049 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (49, '/images/generated-cups-49-1.svg', 'Premium Ripple Paper Cup 049', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (49, '/images/generated-cups-49-2.svg', 'Premium Ripple Paper Cup 049', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (49, '/images/generated-cups-49-3.svg', 'Premium Ripple Paper Cup 049', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 50, id, 'Economy Round Paper Plate 050', 'SE-0050', 'Rs. 201 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0050 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (50, '/images/generated-plates-50-1.svg', 'Economy Round Paper Plate 050', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (50, '/images/generated-plates-50-2.svg', 'Economy Round Paper Plate 050', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (50, '/images/generated-plates-50-3.svg', 'Economy Round Paper Plate 050', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 51, id, 'Small Round Food Container 051', 'SE-0051', 'Rs. 233 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0051 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (51, '/images/generated-containers-51-1.svg', 'Small Round Food Container 051', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (51, '/images/generated-containers-51-2.svg', 'Small Round Food Container 051', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (51, '/images/generated-containers-51-3.svg', 'Small Round Food Container 051', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 52, id, 'Medium Wooden Spoon Pack 052', 'SE-0052', 'Rs. 48 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0052 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (52, '/images/generated-cutlery-52-1.svg', 'Medium Wooden Spoon Pack 052', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (52, '/images/generated-cutlery-52-2.svg', 'Medium Wooden Spoon Pack 052', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (52, '/images/generated-cutlery-52-3.svg', 'Medium Wooden Spoon Pack 052', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 53, id, 'Large Tissue Napkin Pack 053', 'SE-0053', 'Rs. 51 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0053 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (53, '/images/generated-napkins-53-1.svg', 'Large Tissue Napkin Pack 053', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (53, '/images/generated-napkins-53-2.svg', 'Large Tissue Napkin Pack 053', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (53, '/images/generated-napkins-53-3.svg', 'Large Tissue Napkin Pack 053', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 54, id, 'Premium Paper Carry Bag 054', 'SE-0054', 'Rs. 150 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0054 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (54, '/images/generated-bags-54-1.svg', 'Premium Paper Carry Bag 054', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (54, '/images/generated-bags-54-2.svg', 'Premium Paper Carry Bag 054', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (54, '/images/generated-bags-54-3.svg', 'Premium Paper Carry Bag 054', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 55, id, 'Economy Paper Straw Pack 055', 'SE-0055', 'Rs. 62 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0055 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (55, '/images/generated-straws-55-1.svg', 'Economy Paper Straw Pack 055', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (55, '/images/generated-straws-55-2.svg', 'Economy Paper Straw Pack 055', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (55, '/images/generated-straws-55-3.svg', 'Economy Paper Straw Pack 055', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 56, id, 'Small Paper Soup Bowl 056', 'SE-0056', 'Rs. 104 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0056 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (56, '/images/generated-bowls-56-1.svg', 'Small Paper Soup Bowl 056', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (56, '/images/generated-bowls-56-2.svg', 'Small Paper Soup Bowl 056', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (56, '/images/generated-bowls-56-3.svg', 'Small Paper Soup Bowl 056', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 57, id, 'Medium Plain Paper Cup 057', 'SE-0057', 'Rs. 109 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0057 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (57, '/images/generated-cups-57-1.svg', 'Medium Plain Paper Cup 057', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (57, '/images/generated-cups-57-2.svg', 'Medium Plain Paper Cup 057', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (57, '/images/generated-cups-57-3.svg', 'Medium Plain Paper Cup 057', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 58, id, 'Large Compartment Meal Plate 058', 'SE-0058', 'Rs. 138 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0058 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (58, '/images/generated-plates-58-1.svg', 'Large Compartment Meal Plate 058', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (58, '/images/generated-plates-58-2.svg', 'Large Compartment Meal Plate 058', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (58, '/images/generated-plates-58-3.svg', 'Large Compartment Meal Plate 058', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 59, id, 'Premium Rectangular Meal Box 059', 'SE-0059', 'Rs. 170 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0059 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (59, '/images/generated-containers-59-1.svg', 'Premium Rectangular Meal Box 059', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (59, '/images/generated-containers-59-2.svg', 'Premium Rectangular Meal Box 059', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (59, '/images/generated-containers-59-3.svg', 'Premium Rectangular Meal Box 059', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 60, id, 'Economy Disposable Fork Pack 060', 'SE-0060', 'Rs. 104 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0060 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (60, '/images/generated-cutlery-60-1.svg', 'Economy Disposable Fork Pack 060', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (60, '/images/generated-cutlery-60-2.svg', 'Economy Disposable Fork Pack 060', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (60, '/images/generated-cutlery-60-3.svg', 'Economy Disposable Fork Pack 060', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 61, id, 'Small Printed Napkin 061', 'SE-0061', 'Rs. 110 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0061 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (61, '/images/generated-napkins-61-1.svg', 'Small Printed Napkin 061', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (61, '/images/generated-napkins-61-2.svg', 'Small Printed Napkin 061', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (61, '/images/generated-napkins-61-3.svg', 'Small Printed Napkin 061', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 62, id, 'Medium Kraft Grocery Bag 062', 'SE-0062', 'Rs. 209 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0062 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (62, '/images/generated-bags-62-1.svg', 'Medium Kraft Grocery Bag 062', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (62, '/images/generated-bags-62-2.svg', 'Medium Kraft Grocery Bag 062', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (62, '/images/generated-bags-62-3.svg', 'Medium Kraft Grocery Bag 062', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 63, id, 'Large Bendy Straw Pack 063', 'SE-0063', 'Rs. 121 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0063 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (63, '/images/generated-straws-63-1.svg', 'Large Bendy Straw Pack 063', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (63, '/images/generated-straws-63-2.svg', 'Large Bendy Straw Pack 063', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (63, '/images/generated-straws-63-3.svg', 'Large Bendy Straw Pack 063', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 64, id, 'Premium Salad Bowl 064', 'SE-0064', 'Rs. 163 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0064 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (64, '/images/generated-bowls-64-1.svg', 'Premium Salad Bowl 064', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (64, '/images/generated-bowls-64-2.svg', 'Premium Salad Bowl 064', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (64, '/images/generated-bowls-64-3.svg', 'Premium Salad Bowl 064', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 65, id, 'Economy Printed Tea Cup 065', 'SE-0065', 'Rs. 168 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0065 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (65, '/images/generated-cups-65-1.svg', 'Economy Printed Tea Cup 065', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (65, '/images/generated-cups-65-2.svg', 'Economy Printed Tea Cup 065', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (65, '/images/generated-cups-65-3.svg', 'Economy Printed Tea Cup 065', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 66, id, 'Small Silver Laminated Plate 066', 'SE-0066', 'Rs. 197 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0066 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (66, '/images/generated-plates-66-1.svg', 'Small Silver Laminated Plate 066', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (66, '/images/generated-plates-66-2.svg', 'Small Silver Laminated Plate 066', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (66, '/images/generated-plates-66-3.svg', 'Small Silver Laminated Plate 066', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 67, id, 'Medium Clear Lid Container 067', 'SE-0067', 'Rs. 229 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0067 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (67, '/images/generated-containers-67-1.svg', 'Medium Clear Lid Container 067', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (67, '/images/generated-containers-67-2.svg', 'Medium Clear Lid Container 067', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (67, '/images/generated-containers-67-3.svg', 'Medium Clear Lid Container 067', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 68, id, 'Large Dessert Spoon Pack 068', 'SE-0068', 'Rs. 163 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0068 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (68, '/images/generated-cutlery-68-1.svg', 'Large Dessert Spoon Pack 068', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (68, '/images/generated-cutlery-68-2.svg', 'Large Dessert Spoon Pack 068', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (68, '/images/generated-cutlery-68-3.svg', 'Large Dessert Spoon Pack 068', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 69, id, 'Premium Dinner Napkin 069', 'SE-0069', 'Rs. 47 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0069 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (69, '/images/generated-napkins-69-1.svg', 'Premium Dinner Napkin 069', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (69, '/images/generated-napkins-69-2.svg', 'Premium Dinner Napkin 069', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (69, '/images/generated-napkins-69-3.svg', 'Premium Dinner Napkin 069', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 70, id, 'Economy Food Delivery Bag 070', 'SE-0070', 'Rs. 146 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0070 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (70, '/images/generated-bags-70-1.svg', 'Economy Food Delivery Bag 070', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (70, '/images/generated-bags-70-2.svg', 'Economy Food Delivery Bag 070', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (70, '/images/generated-bags-70-3.svg', 'Economy Food Delivery Bag 070', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 71, id, 'Small Milkshake Straw 071', 'SE-0071', 'Rs. 58 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0071 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (71, '/images/generated-straws-71-1.svg', 'Small Milkshake Straw 071', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (71, '/images/generated-straws-71-2.svg', 'Small Milkshake Straw 071', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (71, '/images/generated-straws-71-3.svg', 'Small Milkshake Straw 071', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 72, id, 'Medium Dessert Bowl 072', 'SE-0072', 'Rs. 100 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0072 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (72, '/images/generated-bowls-72-1.svg', 'Medium Dessert Bowl 072', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (72, '/images/generated-bowls-72-2.svg', 'Medium Dessert Bowl 072', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (72, '/images/generated-bowls-72-3.svg', 'Medium Dessert Bowl 072', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 73, id, 'Large Double Wall Coffee Cup 073', 'SE-0073', 'Rs. 105 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0073 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (73, '/images/generated-cups-73-1.svg', 'Large Double Wall Coffee Cup 073', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (73, '/images/generated-cups-73-2.svg', 'Large Double Wall Coffee Cup 073', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (73, '/images/generated-cups-73-3.svg', 'Large Double Wall Coffee Cup 073', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 74, id, 'Premium Snack Paper Plate 074', 'SE-0074', 'Rs. 134 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0074 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (74, '/images/generated-plates-74-1.svg', 'Premium Snack Paper Plate 074', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (74, '/images/generated-plates-74-2.svg', 'Premium Snack Paper Plate 074', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (74, '/images/generated-plates-74-3.svg', 'Premium Snack Paper Plate 074', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 75, id, 'Economy Sauce Cup Container 075', 'SE-0075', 'Rs. 166 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0075 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (75, '/images/generated-containers-75-1.svg', 'Economy Sauce Cup Container 075', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (75, '/images/generated-containers-75-2.svg', 'Economy Sauce Cup Container 075', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (75, '/images/generated-containers-75-3.svg', 'Economy Sauce Cup Container 075', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 76, id, 'Small Ice Cream Spoon Pack 076', 'SE-0076', 'Rs. 100 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0076 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (76, '/images/generated-cutlery-76-1.svg', 'Small Ice Cream Spoon Pack 076', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (76, '/images/generated-cutlery-76-2.svg', 'Small Ice Cream Spoon Pack 076', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (76, '/images/generated-cutlery-76-3.svg', 'Small Ice Cream Spoon Pack 076', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 77, id, 'Medium Cocktail Napkin 077', 'SE-0077', 'Rs. 103 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0077 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (77, '/images/generated-napkins-77-1.svg', 'Medium Cocktail Napkin 077', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (77, '/images/generated-napkins-77-2.svg', 'Medium Cocktail Napkin 077', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (77, '/images/generated-napkins-77-3.svg', 'Medium Cocktail Napkin 077', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 78, id, 'Large Bakery Paper Bag 078', 'SE-0078', 'Rs. 202 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0078 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (78, '/images/generated-bags-78-1.svg', 'Large Bakery Paper Bag 078', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (78, '/images/generated-bags-78-2.svg', 'Large Bakery Paper Bag 078', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (78, '/images/generated-bags-78-3.svg', 'Large Bakery Paper Bag 078', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 79, id, 'Premium Wrapped Straw 079', 'SE-0079', 'Rs. 114 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0079 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (79, '/images/generated-straws-79-1.svg', 'Premium Wrapped Straw 079', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (79, '/images/generated-straws-79-2.svg', 'Premium Wrapped Straw 079', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (79, '/images/generated-straws-79-3.svg', 'Premium Wrapped Straw 079', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 80, id, 'Economy Rice Bowl 080', 'SE-0080', 'Rs. 156 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0080 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (80, '/images/generated-bowls-80-1.svg', 'Economy Rice Bowl 080', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (80, '/images/generated-bowls-80-2.svg', 'Economy Rice Bowl 080', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (80, '/images/generated-bowls-80-3.svg', 'Economy Rice Bowl 080', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 81, id, 'Small Cold Drink Paper Cup 081', 'SE-0081', 'Rs. 164 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0081 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (81, '/images/generated-cups-81-1.svg', 'Small Cold Drink Paper Cup 081', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (81, '/images/generated-cups-81-2.svg', 'Small Cold Drink Paper Cup 081', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (81, '/images/generated-cups-81-3.svg', 'Small Cold Drink Paper Cup 081', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 82, id, 'Medium Heavy Duty Dinner Plate 082', 'SE-0082', 'Rs. 193 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0082 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (82, '/images/generated-plates-82-1.svg', 'Medium Heavy Duty Dinner Plate 082', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (82, '/images/generated-plates-82-2.svg', 'Medium Heavy Duty Dinner Plate 082', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (82, '/images/generated-plates-82-3.svg', 'Medium Heavy Duty Dinner Plate 082', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 83, id, 'Large Bakery Clamshell Box 083', 'SE-0083', 'Rs. 225 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0083 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (83, '/images/generated-containers-83-1.svg', 'Large Bakery Clamshell Box 083', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (83, '/images/generated-containers-83-2.svg', 'Large Bakery Clamshell Box 083', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (83, '/images/generated-containers-83-3.svg', 'Large Bakery Clamshell Box 083', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 84, id, 'Premium Knife Pack 084', 'SE-0084', 'Rs. 159 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0084 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (84, '/images/generated-cutlery-84-1.svg', 'Premium Knife Pack 084', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (84, '/images/generated-cutlery-84-2.svg', 'Premium Knife Pack 084', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (84, '/images/generated-cutlery-84-3.svg', 'Premium Knife Pack 084', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 85, id, 'Economy Soft Table Tissue 085', 'SE-0085', 'Rs. 162 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0085 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (85, '/images/generated-napkins-85-1.svg', 'Economy Soft Table Tissue 085', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (85, '/images/generated-napkins-85-2.svg', 'Economy Soft Table Tissue 085', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (85, '/images/generated-napkins-85-3.svg', 'Economy Soft Table Tissue 085', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 86, id, 'Small Gift Paper Bag 086', 'SE-0086', 'Rs. 142 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0086 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (86, '/images/generated-bags-86-1.svg', 'Small Gift Paper Bag 086', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (86, '/images/generated-bags-86-2.svg', 'Small Gift Paper Bag 086', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (86, '/images/generated-bags-86-3.svg', 'Small Gift Paper Bag 086', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 87, id, 'Medium Cocktail Straw 087', 'SE-0087', 'Rs. 54 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0087 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (87, '/images/generated-straws-87-1.svg', 'Medium Cocktail Straw 087', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (87, '/images/generated-straws-87-2.svg', 'Medium Cocktail Straw 087', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (87, '/images/generated-straws-87-3.svg', 'Medium Cocktail Straw 087', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 88, id, 'Large Noodle Bowl 088', 'SE-0088', 'Rs. 96 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0088 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (88, '/images/generated-bowls-88-1.svg', 'Large Noodle Bowl 088', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (88, '/images/generated-bowls-88-2.svg', 'Large Noodle Bowl 088', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (88, '/images/generated-bowls-88-3.svg', 'Large Noodle Bowl 088', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 89, id, 'Premium Kulhad Style Cup 089', 'SE-0089', 'Rs. 101 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0089 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (89, '/images/generated-cups-89-1.svg', 'Premium Kulhad Style Cup 089', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (89, '/images/generated-cups-89-2.svg', 'Premium Kulhad Style Cup 089', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (89, '/images/generated-cups-89-3.svg', 'Premium Kulhad Style Cup 089', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 90, id, 'Economy Eco Bagasse Plate 090', 'SE-0090', 'Rs. 130 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0090 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (90, '/images/generated-plates-90-1.svg', 'Economy Eco Bagasse Plate 090', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (90, '/images/generated-plates-90-2.svg', 'Economy Eco Bagasse Plate 090', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (90, '/images/generated-plates-90-3.svg', 'Economy Eco Bagasse Plate 090', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 91, id, 'Small Microwave Safe Container 091', 'SE-0091', 'Rs. 162 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0091 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (91, '/images/generated-containers-91-1.svg', 'Small Microwave Safe Container 091', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (91, '/images/generated-containers-91-2.svg', 'Small Microwave Safe Container 091', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (91, '/images/generated-containers-91-3.svg', 'Small Microwave Safe Container 091', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 92, id, 'Medium Mixed Cutlery Kit 092', 'SE-0092', 'Rs. 96 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0092 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (92, '/images/generated-cutlery-92-1.svg', 'Medium Mixed Cutlery Kit 092', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (92, '/images/generated-cutlery-92-2.svg', 'Medium Mixed Cutlery Kit 092', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (92, '/images/generated-cutlery-92-3.svg', 'Medium Mixed Cutlery Kit 092', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 93, id, 'Large Dispenser Tissue 093', 'SE-0093', 'Rs. 99 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0093 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (93, '/images/generated-napkins-93-1.svg', 'Large Dispenser Tissue 093', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (93, '/images/generated-napkins-93-2.svg', 'Large Dispenser Tissue 093', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (93, '/images/generated-napkins-93-3.svg', 'Large Dispenser Tissue 093', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 94, id, 'Premium Retail Counter Bag 094', 'SE-0094', 'Rs. 198 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0094 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (94, '/images/generated-bags-94-1.svg', 'Premium Retail Counter Bag 094', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (94, '/images/generated-bags-94-2.svg', 'Premium Retail Counter Bag 094', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (94, '/images/generated-bags-94-3.svg', 'Premium Retail Counter Bag 094', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 95, id, 'Economy Jumbo Drink Straw 095', 'SE-0095', 'Rs. 110 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0095 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (95, '/images/generated-straws-95-1.svg', 'Economy Jumbo Drink Straw 095', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (95, '/images/generated-straws-95-2.svg', 'Economy Jumbo Drink Straw 095', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (95, '/images/generated-straws-95-3.svg', 'Economy Jumbo Drink Straw 095', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 96, id, 'Small Laminated Snack Bowl 096', 'SE-0096', 'Rs. 152 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0096 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (96, '/images/generated-bowls-96-1.svg', 'Small Laminated Snack Bowl 096', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (96, '/images/generated-bowls-96-2.svg', 'Small Laminated Snack Bowl 096', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (96, '/images/generated-bowls-96-3.svg', 'Small Laminated Snack Bowl 096', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 97, id, 'Medium Ripple Paper Cup 097', 'SE-0097', 'Rs. 157 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0097 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (97, '/images/generated-cups-97-1.svg', 'Medium Ripple Paper Cup 097', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (97, '/images/generated-cups-97-2.svg', 'Medium Ripple Paper Cup 097', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (97, '/images/generated-cups-97-3.svg', 'Medium Ripple Paper Cup 097', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 98, id, 'Large Round Paper Plate 098', 'SE-0098', 'Rs. 186 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0098 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (98, '/images/generated-plates-98-1.svg', 'Large Round Paper Plate 098', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (98, '/images/generated-plates-98-2.svg', 'Large Round Paper Plate 098', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (98, '/images/generated-plates-98-3.svg', 'Large Round Paper Plate 098', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 99, id, 'Premium Round Food Container 099', 'SE-0099', 'Rs. 218 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0099 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (99, '/images/generated-containers-99-1.svg', 'Premium Round Food Container 099', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (99, '/images/generated-containers-99-2.svg', 'Premium Round Food Container 099', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (99, '/images/generated-containers-99-3.svg', 'Premium Round Food Container 099', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 100, id, 'Economy Wooden Spoon Pack 100', 'SE-0100', 'Rs. 152 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0100 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (100, '/images/generated-cutlery-100-1.svg', 'Economy Wooden Spoon Pack 100', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (100, '/images/generated-cutlery-100-2.svg', 'Economy Wooden Spoon Pack 100', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (100, '/images/generated-cutlery-100-3.svg', 'Economy Wooden Spoon Pack 100', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 101, id, 'Small Tissue Napkin Pack 101', 'SE-0101', 'Rs. 158 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0101 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (101, '/images/generated-napkins-101-1.svg', 'Small Tissue Napkin Pack 101', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (101, '/images/generated-napkins-101-2.svg', 'Small Tissue Napkin Pack 101', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (101, '/images/generated-napkins-101-3.svg', 'Small Tissue Napkin Pack 101', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 102, id, 'Medium Paper Carry Bag 102', 'SE-0102', 'Rs. 257 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0102 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (102, '/images/generated-bags-102-1.svg', 'Medium Paper Carry Bag 102', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (102, '/images/generated-bags-102-2.svg', 'Medium Paper Carry Bag 102', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (102, '/images/generated-bags-102-3.svg', 'Medium Paper Carry Bag 102', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 103, id, 'Large Paper Straw Pack 103', 'SE-0103', 'Rs. 50 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0103 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (103, '/images/generated-straws-103-1.svg', 'Large Paper Straw Pack 103', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (103, '/images/generated-straws-103-2.svg', 'Large Paper Straw Pack 103', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (103, '/images/generated-straws-103-3.svg', 'Large Paper Straw Pack 103', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 104, id, 'Premium Paper Soup Bowl 104', 'SE-0104', 'Rs. 92 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0104 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (104, '/images/generated-bowls-104-1.svg', 'Premium Paper Soup Bowl 104', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (104, '/images/generated-bowls-104-2.svg', 'Premium Paper Soup Bowl 104', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (104, '/images/generated-bowls-104-3.svg', 'Premium Paper Soup Bowl 104', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 105, id, 'Economy Plain Paper Cup 105', 'SE-0105', 'Rs. 97 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0105 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (105, '/images/generated-cups-105-1.svg', 'Economy Plain Paper Cup 105', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (105, '/images/generated-cups-105-2.svg', 'Economy Plain Paper Cup 105', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (105, '/images/generated-cups-105-3.svg', 'Economy Plain Paper Cup 105', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 106, id, 'Small Compartment Meal Plate 106', 'SE-0106', 'Rs. 126 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0106 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (106, '/images/generated-plates-106-1.svg', 'Small Compartment Meal Plate 106', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (106, '/images/generated-plates-106-2.svg', 'Small Compartment Meal Plate 106', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (106, '/images/generated-plates-106-3.svg', 'Small Compartment Meal Plate 106', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 107, id, 'Medium Rectangular Meal Box 107', 'SE-0107', 'Rs. 158 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0107 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (107, '/images/generated-containers-107-1.svg', 'Medium Rectangular Meal Box 107', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (107, '/images/generated-containers-107-2.svg', 'Medium Rectangular Meal Box 107', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (107, '/images/generated-containers-107-3.svg', 'Medium Rectangular Meal Box 107', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 108, id, 'Large Disposable Fork Pack 108', 'SE-0108', 'Rs. 92 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0108 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (108, '/images/generated-cutlery-108-1.svg', 'Large Disposable Fork Pack 108', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (108, '/images/generated-cutlery-108-2.svg', 'Large Disposable Fork Pack 108', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (108, '/images/generated-cutlery-108-3.svg', 'Large Disposable Fork Pack 108', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 109, id, 'Premium Printed Napkin 109', 'SE-0109', 'Rs. 95 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0109 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (109, '/images/generated-napkins-109-1.svg', 'Premium Printed Napkin 109', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (109, '/images/generated-napkins-109-2.svg', 'Premium Printed Napkin 109', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (109, '/images/generated-napkins-109-3.svg', 'Premium Printed Napkin 109', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 110, id, 'Economy Kraft Grocery Bag 110', 'SE-0110', 'Rs. 194 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0110 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (110, '/images/generated-bags-110-1.svg', 'Economy Kraft Grocery Bag 110', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (110, '/images/generated-bags-110-2.svg', 'Economy Kraft Grocery Bag 110', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (110, '/images/generated-bags-110-3.svg', 'Economy Kraft Grocery Bag 110', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 111, id, 'Small Bendy Straw Pack 111', 'SE-0111', 'Rs. 106 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0111 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (111, '/images/generated-straws-111-1.svg', 'Small Bendy Straw Pack 111', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (111, '/images/generated-straws-111-2.svg', 'Small Bendy Straw Pack 111', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (111, '/images/generated-straws-111-3.svg', 'Small Bendy Straw Pack 111', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 112, id, 'Medium Salad Bowl 112', 'SE-0112', 'Rs. 148 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0112 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (112, '/images/generated-bowls-112-1.svg', 'Medium Salad Bowl 112', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (112, '/images/generated-bowls-112-2.svg', 'Medium Salad Bowl 112', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (112, '/images/generated-bowls-112-3.svg', 'Medium Salad Bowl 112', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 113, id, 'Large Printed Tea Cup 113', 'SE-0113', 'Rs. 153 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0113 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (113, '/images/generated-cups-113-1.svg', 'Large Printed Tea Cup 113', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (113, '/images/generated-cups-113-2.svg', 'Large Printed Tea Cup 113', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (113, '/images/generated-cups-113-3.svg', 'Large Printed Tea Cup 113', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 114, id, 'Premium Silver Laminated Plate 114', 'SE-0114', 'Rs. 182 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0114 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (114, '/images/generated-plates-114-1.svg', 'Premium Silver Laminated Plate 114', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (114, '/images/generated-plates-114-2.svg', 'Premium Silver Laminated Plate 114', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (114, '/images/generated-plates-114-3.svg', 'Premium Silver Laminated Plate 114', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 115, id, 'Economy Clear Lid Container 115', 'SE-0115', 'Rs. 214 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0115 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (115, '/images/generated-containers-115-1.svg', 'Economy Clear Lid Container 115', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (115, '/images/generated-containers-115-2.svg', 'Economy Clear Lid Container 115', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (115, '/images/generated-containers-115-3.svg', 'Economy Clear Lid Container 115', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 116, id, 'Small Dessert Spoon Pack 116', 'SE-0116', 'Rs. 148 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0116 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (116, '/images/generated-cutlery-116-1.svg', 'Small Dessert Spoon Pack 116', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (116, '/images/generated-cutlery-116-2.svg', 'Small Dessert Spoon Pack 116', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (116, '/images/generated-cutlery-116-3.svg', 'Small Dessert Spoon Pack 116', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 117, id, 'Medium Dinner Napkin 117', 'SE-0117', 'Rs. 151 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0117 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (117, '/images/generated-napkins-117-1.svg', 'Medium Dinner Napkin 117', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (117, '/images/generated-napkins-117-2.svg', 'Medium Dinner Napkin 117', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (117, '/images/generated-napkins-117-3.svg', 'Medium Dinner Napkin 117', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 118, id, 'Large Food Delivery Bag 118', 'SE-0118', 'Rs. 250 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0118 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (118, '/images/generated-bags-118-1.svg', 'Large Food Delivery Bag 118', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (118, '/images/generated-bags-118-2.svg', 'Large Food Delivery Bag 118', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (118, '/images/generated-bags-118-3.svg', 'Large Food Delivery Bag 118', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 119, id, 'Premium Milkshake Straw 119', 'SE-0119', 'Rs. 162 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0119 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (119, '/images/generated-straws-119-1.svg', 'Premium Milkshake Straw 119', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (119, '/images/generated-straws-119-2.svg', 'Premium Milkshake Straw 119', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (119, '/images/generated-straws-119-3.svg', 'Premium Milkshake Straw 119', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 120, id, 'Economy Dessert Bowl 120', 'SE-0120', 'Rs. 85 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0120 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (120, '/images/generated-bowls-120-1.svg', 'Economy Dessert Bowl 120', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (120, '/images/generated-bowls-120-2.svg', 'Economy Dessert Bowl 120', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (120, '/images/generated-bowls-120-3.svg', 'Economy Dessert Bowl 120', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 121, id, 'Small Double Wall Coffee Cup 121', 'SE-0121', 'Rs. 93 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0121 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (121, '/images/generated-cups-121-1.svg', 'Small Double Wall Coffee Cup 121', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (121, '/images/generated-cups-121-2.svg', 'Small Double Wall Coffee Cup 121', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (121, '/images/generated-cups-121-3.svg', 'Small Double Wall Coffee Cup 121', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 122, id, 'Medium Snack Paper Plate 122', 'SE-0122', 'Rs. 122 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0122 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (122, '/images/generated-plates-122-1.svg', 'Medium Snack Paper Plate 122', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (122, '/images/generated-plates-122-2.svg', 'Medium Snack Paper Plate 122', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (122, '/images/generated-plates-122-3.svg', 'Medium Snack Paper Plate 122', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 123, id, 'Large Sauce Cup Container 123', 'SE-0123', 'Rs. 154 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0123 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (123, '/images/generated-containers-123-1.svg', 'Large Sauce Cup Container 123', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (123, '/images/generated-containers-123-2.svg', 'Large Sauce Cup Container 123', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (123, '/images/generated-containers-123-3.svg', 'Large Sauce Cup Container 123', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 124, id, 'Premium Ice Cream Spoon Pack 124', 'SE-0124', 'Rs. 88 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0124 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (124, '/images/generated-cutlery-124-1.svg', 'Premium Ice Cream Spoon Pack 124', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (124, '/images/generated-cutlery-124-2.svg', 'Premium Ice Cream Spoon Pack 124', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (124, '/images/generated-cutlery-124-3.svg', 'Premium Ice Cream Spoon Pack 124', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 125, id, 'Economy Cocktail Napkin 125', 'SE-0125', 'Rs. 91 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0125 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (125, '/images/generated-napkins-125-1.svg', 'Economy Cocktail Napkin 125', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (125, '/images/generated-napkins-125-2.svg', 'Economy Cocktail Napkin 125', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (125, '/images/generated-napkins-125-3.svg', 'Economy Cocktail Napkin 125', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 126, id, 'Small Bakery Paper Bag 126', 'SE-0126', 'Rs. 190 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0126 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (126, '/images/generated-bags-126-1.svg', 'Small Bakery Paper Bag 126', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (126, '/images/generated-bags-126-2.svg', 'Small Bakery Paper Bag 126', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (126, '/images/generated-bags-126-3.svg', 'Small Bakery Paper Bag 126', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 127, id, 'Medium Wrapped Straw 127', 'SE-0127', 'Rs. 102 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0127 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (127, '/images/generated-straws-127-1.svg', 'Medium Wrapped Straw 127', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (127, '/images/generated-straws-127-2.svg', 'Medium Wrapped Straw 127', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (127, '/images/generated-straws-127-3.svg', 'Medium Wrapped Straw 127', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 128, id, 'Large Rice Bowl 128', 'SE-0128', 'Rs. 144 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0128 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (128, '/images/generated-bowls-128-1.svg', 'Large Rice Bowl 128', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (128, '/images/generated-bowls-128-2.svg', 'Large Rice Bowl 128', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (128, '/images/generated-bowls-128-3.svg', 'Large Rice Bowl 128', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 129, id, 'Premium Cold Drink Paper Cup 129', 'SE-0129', 'Rs. 149 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0129 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (129, '/images/generated-cups-129-1.svg', 'Premium Cold Drink Paper Cup 129', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (129, '/images/generated-cups-129-2.svg', 'Premium Cold Drink Paper Cup 129', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (129, '/images/generated-cups-129-3.svg', 'Premium Cold Drink Paper Cup 129', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 130, id, 'Economy Heavy Duty Dinner Plate 130', 'SE-0130', 'Rs. 178 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0130 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (130, '/images/generated-plates-130-1.svg', 'Economy Heavy Duty Dinner Plate 130', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (130, '/images/generated-plates-130-2.svg', 'Economy Heavy Duty Dinner Plate 130', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (130, '/images/generated-plates-130-3.svg', 'Economy Heavy Duty Dinner Plate 130', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 131, id, 'Small Bakery Clamshell Box 131', 'SE-0131', 'Rs. 210 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0131 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (131, '/images/generated-containers-131-1.svg', 'Small Bakery Clamshell Box 131', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (131, '/images/generated-containers-131-2.svg', 'Small Bakery Clamshell Box 131', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (131, '/images/generated-containers-131-3.svg', 'Small Bakery Clamshell Box 131', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 132, id, 'Medium Knife Pack 132', 'SE-0132', 'Rs. 144 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0132 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (132, '/images/generated-cutlery-132-1.svg', 'Medium Knife Pack 132', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (132, '/images/generated-cutlery-132-2.svg', 'Medium Knife Pack 132', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (132, '/images/generated-cutlery-132-3.svg', 'Medium Knife Pack 132', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 133, id, 'Large Soft Table Tissue 133', 'SE-0133', 'Rs. 147 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0133 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (133, '/images/generated-napkins-133-1.svg', 'Large Soft Table Tissue 133', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (133, '/images/generated-napkins-133-2.svg', 'Large Soft Table Tissue 133', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (133, '/images/generated-napkins-133-3.svg', 'Large Soft Table Tissue 133', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 134, id, 'Premium Gift Paper Bag 134', 'SE-0134', 'Rs. 246 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0134 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (134, '/images/generated-bags-134-1.svg', 'Premium Gift Paper Bag 134', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (134, '/images/generated-bags-134-2.svg', 'Premium Gift Paper Bag 134', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (134, '/images/generated-bags-134-3.svg', 'Premium Gift Paper Bag 134', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 135, id, 'Economy Cocktail Straw 135', 'SE-0135', 'Rs. 158 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0135 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (135, '/images/generated-straws-135-1.svg', 'Economy Cocktail Straw 135', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (135, '/images/generated-straws-135-2.svg', 'Economy Cocktail Straw 135', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (135, '/images/generated-straws-135-3.svg', 'Economy Cocktail Straw 135', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 136, id, 'Small Noodle Bowl 136', 'SE-0136', 'Rs. 200 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0136 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (136, '/images/generated-bowls-136-1.svg', 'Small Noodle Bowl 136', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (136, '/images/generated-bowls-136-2.svg', 'Small Noodle Bowl 136', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (136, '/images/generated-bowls-136-3.svg', 'Small Noodle Bowl 136', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 137, id, 'Medium Kulhad Style Cup 137', 'SE-0137', 'Rs. 86 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0137 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (137, '/images/generated-cups-137-1.svg', 'Medium Kulhad Style Cup 137', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (137, '/images/generated-cups-137-2.svg', 'Medium Kulhad Style Cup 137', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (137, '/images/generated-cups-137-3.svg', 'Medium Kulhad Style Cup 137', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 138, id, 'Large Eco Bagasse Plate 138', 'SE-0138', 'Rs. 115 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0138 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (138, '/images/generated-plates-138-1.svg', 'Large Eco Bagasse Plate 138', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (138, '/images/generated-plates-138-2.svg', 'Large Eco Bagasse Plate 138', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (138, '/images/generated-plates-138-3.svg', 'Large Eco Bagasse Plate 138', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 139, id, 'Premium Microwave Safe Container 139', 'SE-0139', 'Rs. 147 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0139 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (139, '/images/generated-containers-139-1.svg', 'Premium Microwave Safe Container 139', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (139, '/images/generated-containers-139-2.svg', 'Premium Microwave Safe Container 139', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (139, '/images/generated-containers-139-3.svg', 'Premium Microwave Safe Container 139', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 140, id, 'Economy Mixed Cutlery Kit 140', 'SE-0140', 'Rs. 81 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0140 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (140, '/images/generated-cutlery-140-1.svg', 'Economy Mixed Cutlery Kit 140', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (140, '/images/generated-cutlery-140-2.svg', 'Economy Mixed Cutlery Kit 140', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (140, '/images/generated-cutlery-140-3.svg', 'Economy Mixed Cutlery Kit 140', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 141, id, 'Small Dispenser Tissue 141', 'SE-0141', 'Rs. 87 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0141 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (141, '/images/generated-napkins-141-1.svg', 'Small Dispenser Tissue 141', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (141, '/images/generated-napkins-141-2.svg', 'Small Dispenser Tissue 141', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (141, '/images/generated-napkins-141-3.svg', 'Small Dispenser Tissue 141', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 142, id, 'Medium Retail Counter Bag 142', 'SE-0142', 'Rs. 186 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0142 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (142, '/images/generated-bags-142-1.svg', 'Medium Retail Counter Bag 142', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (142, '/images/generated-bags-142-2.svg', 'Medium Retail Counter Bag 142', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (142, '/images/generated-bags-142-3.svg', 'Medium Retail Counter Bag 142', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 143, id, 'Large Jumbo Drink Straw 143', 'SE-0143', 'Rs. 98 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0143 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (143, '/images/generated-straws-143-1.svg', 'Large Jumbo Drink Straw 143', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (143, '/images/generated-straws-143-2.svg', 'Large Jumbo Drink Straw 143', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (143, '/images/generated-straws-143-3.svg', 'Large Jumbo Drink Straw 143', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 144, id, 'Premium Laminated Snack Bowl 144', 'SE-0144', 'Rs. 140 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0144 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (144, '/images/generated-bowls-144-1.svg', 'Premium Laminated Snack Bowl 144', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (144, '/images/generated-bowls-144-2.svg', 'Premium Laminated Snack Bowl 144', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (144, '/images/generated-bowls-144-3.svg', 'Premium Laminated Snack Bowl 144', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 145, id, 'Economy Ripple Paper Cup 145', 'SE-0145', 'Rs. 145 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0145 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (145, '/images/generated-cups-145-1.svg', 'Economy Ripple Paper Cup 145', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (145, '/images/generated-cups-145-2.svg', 'Economy Ripple Paper Cup 145', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (145, '/images/generated-cups-145-3.svg', 'Economy Ripple Paper Cup 145', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 146, id, 'Small Round Paper Plate 146', 'SE-0146', 'Rs. 174 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0146 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (146, '/images/generated-plates-146-1.svg', 'Small Round Paper Plate 146', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (146, '/images/generated-plates-146-2.svg', 'Small Round Paper Plate 146', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (146, '/images/generated-plates-146-3.svg', 'Small Round Paper Plate 146', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 147, id, 'Medium Round Food Container 147', 'SE-0147', 'Rs. 206 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0147 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (147, '/images/generated-containers-147-1.svg', 'Medium Round Food Container 147', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (147, '/images/generated-containers-147-2.svg', 'Medium Round Food Container 147', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (147, '/images/generated-containers-147-3.svg', 'Medium Round Food Container 147', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 148, id, 'Large Wooden Spoon Pack 148', 'SE-0148', 'Rs. 140 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0148 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (148, '/images/generated-cutlery-148-1.svg', 'Large Wooden Spoon Pack 148', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (148, '/images/generated-cutlery-148-2.svg', 'Large Wooden Spoon Pack 148', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (148, '/images/generated-cutlery-148-3.svg', 'Large Wooden Spoon Pack 148', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 149, id, 'Premium Tissue Napkin Pack 149', 'SE-0149', 'Rs. 143 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0149 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (149, '/images/generated-napkins-149-1.svg', 'Premium Tissue Napkin Pack 149', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (149, '/images/generated-napkins-149-2.svg', 'Premium Tissue Napkin Pack 149', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (149, '/images/generated-napkins-149-3.svg', 'Premium Tissue Napkin Pack 149', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 150, id, 'Economy Paper Carry Bag 150', 'SE-0150', 'Rs. 242 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0150 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (150, '/images/generated-bags-150-1.svg', 'Economy Paper Carry Bag 150', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (150, '/images/generated-bags-150-2.svg', 'Economy Paper Carry Bag 150', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (150, '/images/generated-bags-150-3.svg', 'Economy Paper Carry Bag 150', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 151, id, 'Small Paper Straw Pack 151', 'SE-0151', 'Rs. 154 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0151 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (151, '/images/generated-straws-151-1.svg', 'Small Paper Straw Pack 151', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (151, '/images/generated-straws-151-2.svg', 'Small Paper Straw Pack 151', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (151, '/images/generated-straws-151-3.svg', 'Small Paper Straw Pack 151', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 152, id, 'Medium Paper Soup Bowl 152', 'SE-0152', 'Rs. 196 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0152 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (152, '/images/generated-bowls-152-1.svg', 'Medium Paper Soup Bowl 152', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (152, '/images/generated-bowls-152-2.svg', 'Medium Paper Soup Bowl 152', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (152, '/images/generated-bowls-152-3.svg', 'Medium Paper Soup Bowl 152', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 153, id, 'Large Plain Paper Cup 153', 'SE-0153', 'Rs. 201 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0153 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (153, '/images/generated-cups-153-1.svg', 'Large Plain Paper Cup 153', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (153, '/images/generated-cups-153-2.svg', 'Large Plain Paper Cup 153', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (153, '/images/generated-cups-153-3.svg', 'Large Plain Paper Cup 153', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 154, id, 'Premium Compartment Meal Plate 154', 'SE-0154', 'Rs. 111 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0154 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (154, '/images/generated-plates-154-1.svg', 'Premium Compartment Meal Plate 154', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (154, '/images/generated-plates-154-2.svg', 'Premium Compartment Meal Plate 154', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (154, '/images/generated-plates-154-3.svg', 'Premium Compartment Meal Plate 154', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 155, id, 'Economy Rectangular Meal Box 155', 'SE-0155', 'Rs. 143 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0155 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (155, '/images/generated-containers-155-1.svg', 'Economy Rectangular Meal Box 155', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (155, '/images/generated-containers-155-2.svg', 'Economy Rectangular Meal Box 155', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (155, '/images/generated-containers-155-3.svg', 'Economy Rectangular Meal Box 155', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 156, id, 'Small Disposable Fork Pack 156', 'SE-0156', 'Rs. 77 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0156 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (156, '/images/generated-cutlery-156-1.svg', 'Small Disposable Fork Pack 156', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (156, '/images/generated-cutlery-156-2.svg', 'Small Disposable Fork Pack 156', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (156, '/images/generated-cutlery-156-3.svg', 'Small Disposable Fork Pack 156', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 157, id, 'Medium Printed Napkin 157', 'SE-0157', 'Rs. 80 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0157 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (157, '/images/generated-napkins-157-1.svg', 'Medium Printed Napkin 157', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (157, '/images/generated-napkins-157-2.svg', 'Medium Printed Napkin 157', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (157, '/images/generated-napkins-157-3.svg', 'Medium Printed Napkin 157', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 158, id, 'Large Kraft Grocery Bag 158', 'SE-0158', 'Rs. 179 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0158 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (158, '/images/generated-bags-158-1.svg', 'Large Kraft Grocery Bag 158', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (158, '/images/generated-bags-158-2.svg', 'Large Kraft Grocery Bag 158', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (158, '/images/generated-bags-158-3.svg', 'Large Kraft Grocery Bag 158', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 159, id, 'Premium Bendy Straw Pack 159', 'SE-0159', 'Rs. 91 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0159 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (159, '/images/generated-straws-159-1.svg', 'Premium Bendy Straw Pack 159', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (159, '/images/generated-straws-159-2.svg', 'Premium Bendy Straw Pack 159', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (159, '/images/generated-straws-159-3.svg', 'Premium Bendy Straw Pack 159', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 160, id, 'Economy Salad Bowl 160', 'SE-0160', 'Rs. 133 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0160 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (160, '/images/generated-bowls-160-1.svg', 'Economy Salad Bowl 160', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (160, '/images/generated-bowls-160-2.svg', 'Economy Salad Bowl 160', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (160, '/images/generated-bowls-160-3.svg', 'Economy Salad Bowl 160', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 161, id, 'Small Printed Tea Cup 161', 'SE-0161', 'Rs. 141 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0161 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (161, '/images/generated-cups-161-1.svg', 'Small Printed Tea Cup 161', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (161, '/images/generated-cups-161-2.svg', 'Small Printed Tea Cup 161', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (161, '/images/generated-cups-161-3.svg', 'Small Printed Tea Cup 161', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 162, id, 'Medium Silver Laminated Plate 162', 'SE-0162', 'Rs. 170 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0162 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (162, '/images/generated-plates-162-1.svg', 'Medium Silver Laminated Plate 162', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (162, '/images/generated-plates-162-2.svg', 'Medium Silver Laminated Plate 162', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (162, '/images/generated-plates-162-3.svg', 'Medium Silver Laminated Plate 162', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 163, id, 'Large Clear Lid Container 163', 'SE-0163', 'Rs. 202 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0163 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (163, '/images/generated-containers-163-1.svg', 'Large Clear Lid Container 163', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (163, '/images/generated-containers-163-2.svg', 'Large Clear Lid Container 163', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (163, '/images/generated-containers-163-3.svg', 'Large Clear Lid Container 163', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 164, id, 'Premium Dessert Spoon Pack 164', 'SE-0164', 'Rs. 136 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0164 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (164, '/images/generated-cutlery-164-1.svg', 'Premium Dessert Spoon Pack 164', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (164, '/images/generated-cutlery-164-2.svg', 'Premium Dessert Spoon Pack 164', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (164, '/images/generated-cutlery-164-3.svg', 'Premium Dessert Spoon Pack 164', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 165, id, 'Economy Dinner Napkin 165', 'SE-0165', 'Rs. 139 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0165 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (165, '/images/generated-napkins-165-1.svg', 'Economy Dinner Napkin 165', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (165, '/images/generated-napkins-165-2.svg', 'Economy Dinner Napkin 165', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (165, '/images/generated-napkins-165-3.svg', 'Economy Dinner Napkin 165', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 166, id, 'Small Food Delivery Bag 166', 'SE-0166', 'Rs. 238 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0166 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (166, '/images/generated-bags-166-1.svg', 'Small Food Delivery Bag 166', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (166, '/images/generated-bags-166-2.svg', 'Small Food Delivery Bag 166', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (166, '/images/generated-bags-166-3.svg', 'Small Food Delivery Bag 166', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 167, id, 'Medium Milkshake Straw 167', 'SE-0167', 'Rs. 150 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0167 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (167, '/images/generated-straws-167-1.svg', 'Medium Milkshake Straw 167', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (167, '/images/generated-straws-167-2.svg', 'Medium Milkshake Straw 167', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (167, '/images/generated-straws-167-3.svg', 'Medium Milkshake Straw 167', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 168, id, 'Large Dessert Bowl 168', 'SE-0168', 'Rs. 192 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0168 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (168, '/images/generated-bowls-168-1.svg', 'Large Dessert Bowl 168', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (168, '/images/generated-bowls-168-2.svg', 'Large Dessert Bowl 168', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (168, '/images/generated-bowls-168-3.svg', 'Large Dessert Bowl 168', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 169, id, 'Premium Double Wall Coffee Cup 169', 'SE-0169', 'Rs. 197 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0169 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (169, '/images/generated-cups-169-1.svg', 'Premium Double Wall Coffee Cup 169', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (169, '/images/generated-cups-169-2.svg', 'Premium Double Wall Coffee Cup 169', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (169, '/images/generated-cups-169-3.svg', 'Premium Double Wall Coffee Cup 169', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 170, id, 'Economy Snack Paper Plate 170', 'SE-0170', 'Rs. 226 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0170 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (170, '/images/generated-plates-170-1.svg', 'Economy Snack Paper Plate 170', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (170, '/images/generated-plates-170-2.svg', 'Economy Snack Paper Plate 170', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (170, '/images/generated-plates-170-3.svg', 'Economy Snack Paper Plate 170', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 171, id, 'Small Sauce Cup Container 171', 'SE-0171', 'Rs. 139 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0171 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (171, '/images/generated-containers-171-1.svg', 'Small Sauce Cup Container 171', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (171, '/images/generated-containers-171-2.svg', 'Small Sauce Cup Container 171', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (171, '/images/generated-containers-171-3.svg', 'Small Sauce Cup Container 171', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 172, id, 'Medium Ice Cream Spoon Pack 172', 'SE-0172', 'Rs. 73 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0172 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (172, '/images/generated-cutlery-172-1.svg', 'Medium Ice Cream Spoon Pack 172', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (172, '/images/generated-cutlery-172-2.svg', 'Medium Ice Cream Spoon Pack 172', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (172, '/images/generated-cutlery-172-3.svg', 'Medium Ice Cream Spoon Pack 172', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 173, id, 'Large Cocktail Napkin 173', 'SE-0173', 'Rs. 76 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0173 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (173, '/images/generated-napkins-173-1.svg', 'Large Cocktail Napkin 173', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (173, '/images/generated-napkins-173-2.svg', 'Large Cocktail Napkin 173', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (173, '/images/generated-napkins-173-3.svg', 'Large Cocktail Napkin 173', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 174, id, 'Premium Bakery Paper Bag 174', 'SE-0174', 'Rs. 175 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0174 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (174, '/images/generated-bags-174-1.svg', 'Premium Bakery Paper Bag 174', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (174, '/images/generated-bags-174-2.svg', 'Premium Bakery Paper Bag 174', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (174, '/images/generated-bags-174-3.svg', 'Premium Bakery Paper Bag 174', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 175, id, 'Economy Wrapped Straw 175', 'SE-0175', 'Rs. 87 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0175 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (175, '/images/generated-straws-175-1.svg', 'Economy Wrapped Straw 175', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (175, '/images/generated-straws-175-2.svg', 'Economy Wrapped Straw 175', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (175, '/images/generated-straws-175-3.svg', 'Economy Wrapped Straw 175', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 176, id, 'Small Rice Bowl 176', 'SE-0176', 'Rs. 129 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0176 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:09', '2026-06-08 09:43:09'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (176, '/images/generated-bowls-176-1.svg', 'Small Rice Bowl 176', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (176, '/images/generated-bowls-176-2.svg', 'Small Rice Bowl 176', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (176, '/images/generated-bowls-176-3.svg', 'Small Rice Bowl 176', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 177, id, 'Medium Cold Drink Paper Cup 177', 'SE-0177', 'Rs. 134 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0177 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (177, '/images/generated-cups-177-1.svg', 'Medium Cold Drink Paper Cup 177', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (177, '/images/generated-cups-177-2.svg', 'Medium Cold Drink Paper Cup 177', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (177, '/images/generated-cups-177-3.svg', 'Medium Cold Drink Paper Cup 177', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 178, id, 'Large Heavy Duty Dinner Plate 178', 'SE-0178', 'Rs. 163 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0178 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (178, '/images/generated-plates-178-1.svg', 'Large Heavy Duty Dinner Plate 178', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (178, '/images/generated-plates-178-2.svg', 'Large Heavy Duty Dinner Plate 178', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (178, '/images/generated-plates-178-3.svg', 'Large Heavy Duty Dinner Plate 178', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 179, id, 'Premium Bakery Clamshell Box 179', 'SE-0179', 'Rs. 195 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0179 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (179, '/images/generated-containers-179-1.svg', 'Premium Bakery Clamshell Box 179', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (179, '/images/generated-containers-179-2.svg', 'Premium Bakery Clamshell Box 179', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (179, '/images/generated-containers-179-3.svg', 'Premium Bakery Clamshell Box 179', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 180, id, 'Economy Knife Pack 180', 'SE-0180', 'Rs. 129 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0180 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (180, '/images/generated-cutlery-180-1.svg', 'Economy Knife Pack 180', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (180, '/images/generated-cutlery-180-2.svg', 'Economy Knife Pack 180', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (180, '/images/generated-cutlery-180-3.svg', 'Economy Knife Pack 180', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 181, id, 'Small Soft Table Tissue 181', 'SE-0181', 'Rs. 135 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0181 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (181, '/images/generated-napkins-181-1.svg', 'Small Soft Table Tissue 181', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (181, '/images/generated-napkins-181-2.svg', 'Small Soft Table Tissue 181', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (181, '/images/generated-napkins-181-3.svg', 'Small Soft Table Tissue 181', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 182, id, 'Medium Gift Paper Bag 182', 'SE-0182', 'Rs. 234 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0182 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (182, '/images/generated-bags-182-1.svg', 'Medium Gift Paper Bag 182', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (182, '/images/generated-bags-182-2.svg', 'Medium Gift Paper Bag 182', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (182, '/images/generated-bags-182-3.svg', 'Medium Gift Paper Bag 182', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 183, id, 'Large Cocktail Straw 183', 'SE-0183', 'Rs. 146 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0183 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (183, '/images/generated-straws-183-1.svg', 'Large Cocktail Straw 183', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (183, '/images/generated-straws-183-2.svg', 'Large Cocktail Straw 183', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (183, '/images/generated-straws-183-3.svg', 'Large Cocktail Straw 183', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 184, id, 'Premium Noodle Bowl 184', 'SE-0184', 'Rs. 188 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0184 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (184, '/images/generated-bowls-184-1.svg', 'Premium Noodle Bowl 184', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (184, '/images/generated-bowls-184-2.svg', 'Premium Noodle Bowl 184', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (184, '/images/generated-bowls-184-3.svg', 'Premium Noodle Bowl 184', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 185, id, 'Economy Kulhad Style Cup 185', 'SE-0185', 'Rs. 193 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0185 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (185, '/images/generated-cups-185-1.svg', 'Economy Kulhad Style Cup 185', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (185, '/images/generated-cups-185-2.svg', 'Economy Kulhad Style Cup 185', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (185, '/images/generated-cups-185-3.svg', 'Economy Kulhad Style Cup 185', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 186, id, 'Small Eco Bagasse Plate 186', 'SE-0186', 'Rs. 222 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0186 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (186, '/images/generated-plates-186-1.svg', 'Small Eco Bagasse Plate 186', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (186, '/images/generated-plates-186-2.svg', 'Small Eco Bagasse Plate 186', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (186, '/images/generated-plates-186-3.svg', 'Small Eco Bagasse Plate 186', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 187, id, 'Medium Microwave Safe Container 187', 'SE-0187', 'Rs. 254 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0187 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (187, '/images/generated-containers-187-1.svg', 'Medium Microwave Safe Container 187', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (187, '/images/generated-containers-187-2.svg', 'Medium Microwave Safe Container 187', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (187, '/images/generated-containers-187-3.svg', 'Medium Microwave Safe Container 187', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 188, id, 'Large Mixed Cutlery Kit 188', 'SE-0188', 'Rs. 69 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0188 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (188, '/images/generated-cutlery-188-1.svg', 'Large Mixed Cutlery Kit 188', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (188, '/images/generated-cutlery-188-2.svg', 'Large Mixed Cutlery Kit 188', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (188, '/images/generated-cutlery-188-3.svg', 'Large Mixed Cutlery Kit 188', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 189, id, 'Premium Dispenser Tissue 189', 'SE-0189', 'Rs. 72 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0189 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (189, '/images/generated-napkins-189-1.svg', 'Premium Dispenser Tissue 189', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (189, '/images/generated-napkins-189-2.svg', 'Premium Dispenser Tissue 189', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (189, '/images/generated-napkins-189-3.svg', 'Premium Dispenser Tissue 189', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 190, id, 'Economy Retail Counter Bag 190', 'SE-0190', 'Rs. 171 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0190 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (190, '/images/generated-bags-190-1.svg', 'Economy Retail Counter Bag 190', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (190, '/images/generated-bags-190-2.svg', 'Economy Retail Counter Bag 190', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (190, '/images/generated-bags-190-3.svg', 'Economy Retail Counter Bag 190', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 191, id, 'Small Jumbo Drink Straw 191', 'SE-0191', 'Rs. 83 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0191 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (191, '/images/generated-straws-191-1.svg', 'Small Jumbo Drink Straw 191', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (191, '/images/generated-straws-191-2.svg', 'Small Jumbo Drink Straw 191', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (191, '/images/generated-straws-191-3.svg', 'Small Jumbo Drink Straw 191', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 192, id, 'Medium Laminated Snack Bowl 192', 'SE-0192', 'Rs. 125 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0192 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (192, '/images/generated-bowls-192-1.svg', 'Medium Laminated Snack Bowl 192', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (192, '/images/generated-bowls-192-2.svg', 'Medium Laminated Snack Bowl 192', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (192, '/images/generated-bowls-192-3.svg', 'Medium Laminated Snack Bowl 192', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 193, id, 'Large Ripple Paper Cup 193', 'SE-0193', 'Rs. 130 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0193 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (193, '/images/generated-cups-193-1.svg', 'Large Ripple Paper Cup 193', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (193, '/images/generated-cups-193-2.svg', 'Large Ripple Paper Cup 193', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (193, '/images/generated-cups-193-3.svg', 'Large Ripple Paper Cup 193', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 194, id, 'Premium Round Paper Plate 194', 'SE-0194', 'Rs. 159 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0194 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (194, '/images/generated-plates-194-1.svg', 'Premium Round Paper Plate 194', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (194, '/images/generated-plates-194-2.svg', 'Premium Round Paper Plate 194', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (194, '/images/generated-plates-194-3.svg', 'Premium Round Paper Plate 194', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 195, id, 'Economy Round Food Container 195', 'SE-0195', 'Rs. 191 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0195 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (195, '/images/generated-containers-195-1.svg', 'Economy Round Food Container 195', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (195, '/images/generated-containers-195-2.svg', 'Economy Round Food Container 195', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (195, '/images/generated-containers-195-3.svg', 'Economy Round Food Container 195', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 196, id, 'Small Wooden Spoon Pack 196', 'SE-0196', 'Rs. 125 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0196 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (196, '/images/generated-cutlery-196-1.svg', 'Small Wooden Spoon Pack 196', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (196, '/images/generated-cutlery-196-2.svg', 'Small Wooden Spoon Pack 196', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (196, '/images/generated-cutlery-196-3.svg', 'Small Wooden Spoon Pack 196', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 197, id, 'Medium Tissue Napkin Pack 197', 'SE-0197', 'Rs. 128 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0197 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (197, '/images/generated-napkins-197-1.svg', 'Medium Tissue Napkin Pack 197', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (197, '/images/generated-napkins-197-2.svg', 'Medium Tissue Napkin Pack 197', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (197, '/images/generated-napkins-197-3.svg', 'Medium Tissue Napkin Pack 197', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 198, id, 'Large Paper Carry Bag 198', 'SE-0198', 'Rs. 227 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0198 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:10', '2026-06-08 09:43:10'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (198, '/images/generated-bags-198-1.svg', 'Large Paper Carry Bag 198', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (198, '/images/generated-bags-198-2.svg', 'Large Paper Carry Bag 198', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (198, '/images/generated-bags-198-3.svg', 'Large Paper Carry Bag 198', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 199, id, 'Premium Paper Straw Pack 199', 'SE-0199', 'Rs. 139 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0199 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (199, '/images/generated-straws-199-1.svg', 'Premium Paper Straw Pack 199', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (199, '/images/generated-straws-199-2.svg', 'Premium Paper Straw Pack 199', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (199, '/images/generated-straws-199-3.svg', 'Premium Paper Straw Pack 199', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 200, id, 'Economy Paper Soup Bowl 200', 'SE-0200', 'Rs. 181 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0200 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (200, '/images/generated-bowls-200-1.svg', 'Economy Paper Soup Bowl 200', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (200, '/images/generated-bowls-200-2.svg', 'Economy Paper Soup Bowl 200', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (200, '/images/generated-bowls-200-3.svg', 'Economy Paper Soup Bowl 200', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 201, id, 'Small Plain Paper Cup 201', 'SE-0201', 'Rs. 189 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0201 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (201, '/images/generated-cups-201-1.svg', 'Small Plain Paper Cup 201', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (201, '/images/generated-cups-201-2.svg', 'Small Plain Paper Cup 201', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (201, '/images/generated-cups-201-3.svg', 'Small Plain Paper Cup 201', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 202, id, 'Medium Compartment Meal Plate 202', 'SE-0202', 'Rs. 218 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0202 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (202, '/images/generated-plates-202-1.svg', 'Medium Compartment Meal Plate 202', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (202, '/images/generated-plates-202-2.svg', 'Medium Compartment Meal Plate 202', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (202, '/images/generated-plates-202-3.svg', 'Medium Compartment Meal Plate 202', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 203, id, 'Large Rectangular Meal Box 203', 'SE-0203', 'Rs. 250 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0203 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (203, '/images/generated-containers-203-1.svg', 'Large Rectangular Meal Box 203', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (203, '/images/generated-containers-203-2.svg', 'Large Rectangular Meal Box 203', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (203, '/images/generated-containers-203-3.svg', 'Large Rectangular Meal Box 203', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 204, id, 'Premium Disposable Fork Pack 204', 'SE-0204', 'Rs. 184 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0204 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (204, '/images/generated-cutlery-204-1.svg', 'Premium Disposable Fork Pack 204', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (204, '/images/generated-cutlery-204-2.svg', 'Premium Disposable Fork Pack 204', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (204, '/images/generated-cutlery-204-3.svg', 'Premium Disposable Fork Pack 204', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 205, id, 'Economy Printed Napkin 205', 'SE-0205', 'Rs. 68 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0205 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (205, '/images/generated-napkins-205-1.svg', 'Economy Printed Napkin 205', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (205, '/images/generated-napkins-205-2.svg', 'Economy Printed Napkin 205', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (205, '/images/generated-napkins-205-3.svg', 'Economy Printed Napkin 205', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 206, id, 'Small Kraft Grocery Bag 206', 'SE-0206', 'Rs. 167 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0206 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (206, '/images/generated-bags-206-1.svg', 'Small Kraft Grocery Bag 206', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (206, '/images/generated-bags-206-2.svg', 'Small Kraft Grocery Bag 206', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (206, '/images/generated-bags-206-3.svg', 'Small Kraft Grocery Bag 206', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 207, id, 'Medium Bendy Straw Pack 207', 'SE-0207', 'Rs. 79 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0207 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (207, '/images/generated-straws-207-1.svg', 'Medium Bendy Straw Pack 207', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (207, '/images/generated-straws-207-2.svg', 'Medium Bendy Straw Pack 207', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (207, '/images/generated-straws-207-3.svg', 'Medium Bendy Straw Pack 207', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 208, id, 'Large Salad Bowl 208', 'SE-0208', 'Rs. 121 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0208 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (208, '/images/generated-bowls-208-1.svg', 'Large Salad Bowl 208', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (208, '/images/generated-bowls-208-2.svg', 'Large Salad Bowl 208', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (208, '/images/generated-bowls-208-3.svg', 'Large Salad Bowl 208', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 209, id, 'Premium Printed Tea Cup 209', 'SE-0209', 'Rs. 126 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0209 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (209, '/images/generated-cups-209-1.svg', 'Premium Printed Tea Cup 209', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (209, '/images/generated-cups-209-2.svg', 'Premium Printed Tea Cup 209', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (209, '/images/generated-cups-209-3.svg', 'Premium Printed Tea Cup 209', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 210, id, 'Economy Silver Laminated Plate 210', 'SE-0210', 'Rs. 155 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0210 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (210, '/images/generated-plates-210-1.svg', 'Economy Silver Laminated Plate 210', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (210, '/images/generated-plates-210-2.svg', 'Economy Silver Laminated Plate 210', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (210, '/images/generated-plates-210-3.svg', 'Economy Silver Laminated Plate 210', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 211, id, 'Small Clear Lid Container 211', 'SE-0211', 'Rs. 187 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0211 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (211, '/images/generated-containers-211-1.svg', 'Small Clear Lid Container 211', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (211, '/images/generated-containers-211-2.svg', 'Small Clear Lid Container 211', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (211, '/images/generated-containers-211-3.svg', 'Small Clear Lid Container 211', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 212, id, 'Medium Dessert Spoon Pack 212', 'SE-0212', 'Rs. 121 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0212 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (212, '/images/generated-cutlery-212-1.svg', 'Medium Dessert Spoon Pack 212', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (212, '/images/generated-cutlery-212-2.svg', 'Medium Dessert Spoon Pack 212', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (212, '/images/generated-cutlery-212-3.svg', 'Medium Dessert Spoon Pack 212', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 213, id, 'Large Dinner Napkin 213', 'SE-0213', 'Rs. 124 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0213 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (213, '/images/generated-napkins-213-1.svg', 'Large Dinner Napkin 213', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (213, '/images/generated-napkins-213-2.svg', 'Large Dinner Napkin 213', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (213, '/images/generated-napkins-213-3.svg', 'Large Dinner Napkin 213', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 214, id, 'Premium Food Delivery Bag 214', 'SE-0214', 'Rs. 223 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0214 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (214, '/images/generated-bags-214-1.svg', 'Premium Food Delivery Bag 214', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (214, '/images/generated-bags-214-2.svg', 'Premium Food Delivery Bag 214', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (214, '/images/generated-bags-214-3.svg', 'Premium Food Delivery Bag 214', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 215, id, 'Economy Milkshake Straw 215', 'SE-0215', 'Rs. 135 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0215 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (215, '/images/generated-straws-215-1.svg', 'Economy Milkshake Straw 215', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (215, '/images/generated-straws-215-2.svg', 'Economy Milkshake Straw 215', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (215, '/images/generated-straws-215-3.svg', 'Economy Milkshake Straw 215', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 216, id, 'Small Dessert Bowl 216', 'SE-0216', 'Rs. 177 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0216 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (216, '/images/generated-bowls-216-1.svg', 'Small Dessert Bowl 216', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (216, '/images/generated-bowls-216-2.svg', 'Small Dessert Bowl 216', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (216, '/images/generated-bowls-216-3.svg', 'Small Dessert Bowl 216', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 217, id, 'Medium Double Wall Coffee Cup 217', 'SE-0217', 'Rs. 182 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0217 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (217, '/images/generated-cups-217-1.svg', 'Medium Double Wall Coffee Cup 217', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (217, '/images/generated-cups-217-2.svg', 'Medium Double Wall Coffee Cup 217', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (217, '/images/generated-cups-217-3.svg', 'Medium Double Wall Coffee Cup 217', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 218, id, 'Large Snack Paper Plate 218', 'SE-0218', 'Rs. 211 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0218 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (218, '/images/generated-plates-218-1.svg', 'Large Snack Paper Plate 218', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (218, '/images/generated-plates-218-2.svg', 'Large Snack Paper Plate 218', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (218, '/images/generated-plates-218-3.svg', 'Large Snack Paper Plate 218', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 219, id, 'Premium Sauce Cup Container 219', 'SE-0219', 'Rs. 243 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0219 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (219, '/images/generated-containers-219-1.svg', 'Premium Sauce Cup Container 219', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (219, '/images/generated-containers-219-2.svg', 'Premium Sauce Cup Container 219', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (219, '/images/generated-containers-219-3.svg', 'Premium Sauce Cup Container 219', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 220, id, 'Economy Ice Cream Spoon Pack 220', 'SE-0220', 'Rs. 177 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0220 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (220, '/images/generated-cutlery-220-1.svg', 'Economy Ice Cream Spoon Pack 220', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (220, '/images/generated-cutlery-220-2.svg', 'Economy Ice Cream Spoon Pack 220', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (220, '/images/generated-cutlery-220-3.svg', 'Economy Ice Cream Spoon Pack 220', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 221, id, 'Small Cocktail Napkin 221', 'SE-0221', 'Rs. 183 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0221 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (221, '/images/generated-napkins-221-1.svg', 'Small Cocktail Napkin 221', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (221, '/images/generated-napkins-221-2.svg', 'Small Cocktail Napkin 221', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (221, '/images/generated-napkins-221-3.svg', 'Small Cocktail Napkin 221', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 222, id, 'Medium Bakery Paper Bag 222', 'SE-0222', 'Rs. 163 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0222 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (222, '/images/generated-bags-222-1.svg', 'Medium Bakery Paper Bag 222', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (222, '/images/generated-bags-222-2.svg', 'Medium Bakery Paper Bag 222', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (222, '/images/generated-bags-222-3.svg', 'Medium Bakery Paper Bag 222', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 223, id, 'Large Wrapped Straw 223', 'SE-0223', 'Rs. 75 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0223 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (223, '/images/generated-straws-223-1.svg', 'Large Wrapped Straw 223', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (223, '/images/generated-straws-223-2.svg', 'Large Wrapped Straw 223', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (223, '/images/generated-straws-223-3.svg', 'Large Wrapped Straw 223', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 224, id, 'Premium Rice Bowl 224', 'SE-0224', 'Rs. 117 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0224 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (224, '/images/generated-bowls-224-1.svg', 'Premium Rice Bowl 224', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (224, '/images/generated-bowls-224-2.svg', 'Premium Rice Bowl 224', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (224, '/images/generated-bowls-224-3.svg', 'Premium Rice Bowl 224', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 225, id, 'Economy Cold Drink Paper Cup 225', 'SE-0225', 'Rs. 122 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0225 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (225, '/images/generated-cups-225-1.svg', 'Economy Cold Drink Paper Cup 225', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (225, '/images/generated-cups-225-2.svg', 'Economy Cold Drink Paper Cup 225', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (225, '/images/generated-cups-225-3.svg', 'Economy Cold Drink Paper Cup 225', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 226, id, 'Small Heavy Duty Dinner Plate 226', 'SE-0226', 'Rs. 151 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0226 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (226, '/images/generated-plates-226-1.svg', 'Small Heavy Duty Dinner Plate 226', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (226, '/images/generated-plates-226-2.svg', 'Small Heavy Duty Dinner Plate 226', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (226, '/images/generated-plates-226-3.svg', 'Small Heavy Duty Dinner Plate 226', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 227, id, 'Medium Bakery Clamshell Box 227', 'SE-0227', 'Rs. 183 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0227 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (227, '/images/generated-containers-227-1.svg', 'Medium Bakery Clamshell Box 227', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (227, '/images/generated-containers-227-2.svg', 'Medium Bakery Clamshell Box 227', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (227, '/images/generated-containers-227-3.svg', 'Medium Bakery Clamshell Box 227', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 228, id, 'Large Knife Pack 228', 'SE-0228', 'Rs. 117 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0228 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (228, '/images/generated-cutlery-228-1.svg', 'Large Knife Pack 228', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (228, '/images/generated-cutlery-228-2.svg', 'Large Knife Pack 228', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (228, '/images/generated-cutlery-228-3.svg', 'Large Knife Pack 228', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 229, id, 'Premium Soft Table Tissue 229', 'SE-0229', 'Rs. 120 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0229 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (229, '/images/generated-napkins-229-1.svg', 'Premium Soft Table Tissue 229', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (229, '/images/generated-napkins-229-2.svg', 'Premium Soft Table Tissue 229', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (229, '/images/generated-napkins-229-3.svg', 'Premium Soft Table Tissue 229', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 230, id, 'Economy Gift Paper Bag 230', 'SE-0230', 'Rs. 219 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0230 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (230, '/images/generated-bags-230-1.svg', 'Economy Gift Paper Bag 230', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (230, '/images/generated-bags-230-2.svg', 'Economy Gift Paper Bag 230', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (230, '/images/generated-bags-230-3.svg', 'Economy Gift Paper Bag 230', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 231, id, 'Small Cocktail Straw 231', 'SE-0231', 'Rs. 131 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0231 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (231, '/images/generated-straws-231-1.svg', 'Small Cocktail Straw 231', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (231, '/images/generated-straws-231-2.svg', 'Small Cocktail Straw 231', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (231, '/images/generated-straws-231-3.svg', 'Small Cocktail Straw 231', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 232, id, 'Medium Noodle Bowl 232', 'SE-0232', 'Rs. 173 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0232 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (232, '/images/generated-bowls-232-1.svg', 'Medium Noodle Bowl 232', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (232, '/images/generated-bowls-232-2.svg', 'Medium Noodle Bowl 232', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (232, '/images/generated-bowls-232-3.svg', 'Medium Noodle Bowl 232', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 233, id, 'Large Kulhad Style Cup 233', 'SE-0233', 'Rs. 178 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0233 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (233, '/images/generated-cups-233-1.svg', 'Large Kulhad Style Cup 233', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (233, '/images/generated-cups-233-2.svg', 'Large Kulhad Style Cup 233', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (233, '/images/generated-cups-233-3.svg', 'Large Kulhad Style Cup 233', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 234, id, 'Premium Eco Bagasse Plate 234', 'SE-0234', 'Rs. 207 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0234 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (234, '/images/generated-plates-234-1.svg', 'Premium Eco Bagasse Plate 234', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (234, '/images/generated-plates-234-2.svg', 'Premium Eco Bagasse Plate 234', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (234, '/images/generated-plates-234-3.svg', 'Premium Eco Bagasse Plate 234', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 235, id, 'Economy Microwave Safe Container 235', 'SE-0235', 'Rs. 239 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0235 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (235, '/images/generated-containers-235-1.svg', 'Economy Microwave Safe Container 235', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (235, '/images/generated-containers-235-2.svg', 'Economy Microwave Safe Container 235', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (235, '/images/generated-containers-235-3.svg', 'Economy Microwave Safe Container 235', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 236, id, 'Small Mixed Cutlery Kit 236', 'SE-0236', 'Rs. 173 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0236 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (236, '/images/generated-cutlery-236-1.svg', 'Small Mixed Cutlery Kit 236', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (236, '/images/generated-cutlery-236-2.svg', 'Small Mixed Cutlery Kit 236', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (236, '/images/generated-cutlery-236-3.svg', 'Small Mixed Cutlery Kit 236', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 237, id, 'Medium Dispenser Tissue 237', 'SE-0237', 'Rs. 176 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0237 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (237, '/images/generated-napkins-237-1.svg', 'Medium Dispenser Tissue 237', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (237, '/images/generated-napkins-237-2.svg', 'Medium Dispenser Tissue 237', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (237, '/images/generated-napkins-237-3.svg', 'Medium Dispenser Tissue 237', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 238, id, 'Large Retail Counter Bag 238', 'SE-0238', 'Rs. 275 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0238 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (238, '/images/generated-bags-238-1.svg', 'Large Retail Counter Bag 238', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (238, '/images/generated-bags-238-2.svg', 'Large Retail Counter Bag 238', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (238, '/images/generated-bags-238-3.svg', 'Large Retail Counter Bag 238', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 239, id, 'Premium Jumbo Drink Straw 239', 'SE-0239', 'Rs. 68 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0239 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (239, '/images/generated-straws-239-1.svg', 'Premium Jumbo Drink Straw 239', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (239, '/images/generated-straws-239-2.svg', 'Premium Jumbo Drink Straw 239', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (239, '/images/generated-straws-239-3.svg', 'Premium Jumbo Drink Straw 239', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 240, id, 'Economy Laminated Snack Bowl 240', 'SE-0240', 'Rs. 110 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0240 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (240, '/images/generated-bowls-240-1.svg', 'Economy Laminated Snack Bowl 240', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (240, '/images/generated-bowls-240-2.svg', 'Economy Laminated Snack Bowl 240', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (240, '/images/generated-bowls-240-3.svg', 'Economy Laminated Snack Bowl 240', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 241, id, 'Small Ripple Paper Cup 241', 'SE-0241', 'Rs. 118 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0241 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (241, '/images/generated-cups-241-1.svg', 'Small Ripple Paper Cup 241', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (241, '/images/generated-cups-241-2.svg', 'Small Ripple Paper Cup 241', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (241, '/images/generated-cups-241-3.svg', 'Small Ripple Paper Cup 241', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 242, id, 'Medium Round Paper Plate 242', 'SE-0242', 'Rs. 147 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0242 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (242, '/images/generated-plates-242-1.svg', 'Medium Round Paper Plate 242', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (242, '/images/generated-plates-242-2.svg', 'Medium Round Paper Plate 242', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (242, '/images/generated-plates-242-3.svg', 'Medium Round Paper Plate 242', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 243, id, 'Large Round Food Container 243', 'SE-0243', 'Rs. 179 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0243 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (243, '/images/generated-containers-243-1.svg', 'Large Round Food Container 243', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (243, '/images/generated-containers-243-2.svg', 'Large Round Food Container 243', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (243, '/images/generated-containers-243-3.svg', 'Large Round Food Container 243', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 244, id, 'Premium Wooden Spoon Pack 244', 'SE-0244', 'Rs. 113 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0244 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (244, '/images/generated-cutlery-244-1.svg', 'Premium Wooden Spoon Pack 244', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (244, '/images/generated-cutlery-244-2.svg', 'Premium Wooden Spoon Pack 244', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (244, '/images/generated-cutlery-244-3.svg', 'Premium Wooden Spoon Pack 244', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 245, id, 'Economy Tissue Napkin Pack 245', 'SE-0245', 'Rs. 116 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0245 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (245, '/images/generated-napkins-245-1.svg', 'Economy Tissue Napkin Pack 245', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (245, '/images/generated-napkins-245-2.svg', 'Economy Tissue Napkin Pack 245', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (245, '/images/generated-napkins-245-3.svg', 'Economy Tissue Napkin Pack 245', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 246, id, 'Small Paper Carry Bag 246', 'SE-0246', 'Rs. 215 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0246 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (246, '/images/generated-bags-246-1.svg', 'Small Paper Carry Bag 246', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (246, '/images/generated-bags-246-2.svg', 'Small Paper Carry Bag 246', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (246, '/images/generated-bags-246-3.svg', 'Small Paper Carry Bag 246', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 247, id, 'Medium Paper Straw Pack 247', 'SE-0247', 'Rs. 127 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0247 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (247, '/images/generated-straws-247-1.svg', 'Medium Paper Straw Pack 247', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (247, '/images/generated-straws-247-2.svg', 'Medium Paper Straw Pack 247', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (247, '/images/generated-straws-247-3.svg', 'Medium Paper Straw Pack 247', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 248, id, 'Large Paper Soup Bowl 248', 'SE-0248', 'Rs. 169 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0248 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (248, '/images/generated-bowls-248-1.svg', 'Large Paper Soup Bowl 248', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (248, '/images/generated-bowls-248-2.svg', 'Large Paper Soup Bowl 248', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (248, '/images/generated-bowls-248-3.svg', 'Large Paper Soup Bowl 248', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 249, id, 'Premium Plain Paper Cup 249', 'SE-0249', 'Rs. 174 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0249 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (249, '/images/generated-cups-249-1.svg', 'Premium Plain Paper Cup 249', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (249, '/images/generated-cups-249-2.svg', 'Premium Plain Paper Cup 249', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (249, '/images/generated-cups-249-3.svg', 'Premium Plain Paper Cup 249', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 250, id, 'Economy Compartment Meal Plate 250', 'SE-0250', 'Rs. 203 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0250 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (250, '/images/generated-plates-250-1.svg', 'Economy Compartment Meal Plate 250', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (250, '/images/generated-plates-250-2.svg', 'Economy Compartment Meal Plate 250', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (250, '/images/generated-plates-250-3.svg', 'Economy Compartment Meal Plate 250', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 251, id, 'Small Rectangular Meal Box 251', 'SE-0251', 'Rs. 235 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0251 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (251, '/images/generated-containers-251-1.svg', 'Small Rectangular Meal Box 251', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (251, '/images/generated-containers-251-2.svg', 'Small Rectangular Meal Box 251', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (251, '/images/generated-containers-251-3.svg', 'Small Rectangular Meal Box 251', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 252, id, 'Medium Disposable Fork Pack 252', 'SE-0252', 'Rs. 169 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0252 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (252, '/images/generated-cutlery-252-1.svg', 'Medium Disposable Fork Pack 252', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (252, '/images/generated-cutlery-252-2.svg', 'Medium Disposable Fork Pack 252', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (252, '/images/generated-cutlery-252-3.svg', 'Medium Disposable Fork Pack 252', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 253, id, 'Large Printed Napkin 253', 'SE-0253', 'Rs. 172 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0253 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (253, '/images/generated-napkins-253-1.svg', 'Large Printed Napkin 253', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (253, '/images/generated-napkins-253-2.svg', 'Large Printed Napkin 253', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (253, '/images/generated-napkins-253-3.svg', 'Large Printed Napkin 253', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 254, id, 'Premium Kraft Grocery Bag 254', 'SE-0254', 'Rs. 271 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0254 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (254, '/images/generated-bags-254-1.svg', 'Premium Kraft Grocery Bag 254', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (254, '/images/generated-bags-254-2.svg', 'Premium Kraft Grocery Bag 254', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (254, '/images/generated-bags-254-3.svg', 'Premium Kraft Grocery Bag 254', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 255, id, 'Economy Bendy Straw Pack 255', 'SE-0255', 'Rs. 183 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0255 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (255, '/images/generated-straws-255-1.svg', 'Economy Bendy Straw Pack 255', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (255, '/images/generated-straws-255-2.svg', 'Economy Bendy Straw Pack 255', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (255, '/images/generated-straws-255-3.svg', 'Economy Bendy Straw Pack 255', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 256, id, 'Small Salad Bowl 256', 'SE-0256', 'Rs. 106 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0256 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (256, '/images/generated-bowls-256-1.svg', 'Small Salad Bowl 256', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (256, '/images/generated-bowls-256-2.svg', 'Small Salad Bowl 256', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (256, '/images/generated-bowls-256-3.svg', 'Small Salad Bowl 256', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 257, id, 'Medium Printed Tea Cup 257', 'SE-0257', 'Rs. 111 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0257 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (257, '/images/generated-cups-257-1.svg', 'Medium Printed Tea Cup 257', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (257, '/images/generated-cups-257-2.svg', 'Medium Printed Tea Cup 257', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (257, '/images/generated-cups-257-3.svg', 'Medium Printed Tea Cup 257', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 258, id, 'Large Silver Laminated Plate 258', 'SE-0258', 'Rs. 140 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0258 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (258, '/images/generated-plates-258-1.svg', 'Large Silver Laminated Plate 258', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (258, '/images/generated-plates-258-2.svg', 'Large Silver Laminated Plate 258', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (258, '/images/generated-plates-258-3.svg', 'Large Silver Laminated Plate 258', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 259, id, 'Premium Clear Lid Container 259', 'SE-0259', 'Rs. 172 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0259 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (259, '/images/generated-containers-259-1.svg', 'Premium Clear Lid Container 259', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (259, '/images/generated-containers-259-2.svg', 'Premium Clear Lid Container 259', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (259, '/images/generated-containers-259-3.svg', 'Premium Clear Lid Container 259', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 260, id, 'Economy Dessert Spoon Pack 260', 'SE-0260', 'Rs. 106 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0260 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (260, '/images/generated-cutlery-260-1.svg', 'Economy Dessert Spoon Pack 260', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (260, '/images/generated-cutlery-260-2.svg', 'Economy Dessert Spoon Pack 260', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (260, '/images/generated-cutlery-260-3.svg', 'Economy Dessert Spoon Pack 260', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 261, id, 'Small Dinner Napkin 261', 'SE-0261', 'Rs. 112 / 25 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0261 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (261, '/images/generated-napkins-261-1.svg', 'Small Dinner Napkin 261', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (261, '/images/generated-napkins-261-2.svg', 'Small Dinner Napkin 261', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (261, '/images/generated-napkins-261-3.svg', 'Small Dinner Napkin 261', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 262, id, 'Medium Food Delivery Bag 262', 'SE-0262', 'Rs. 211 / 50 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0262 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (262, '/images/generated-bags-262-1.svg', 'Medium Food Delivery Bag 262', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (262, '/images/generated-bags-262-2.svg', 'Medium Food Delivery Bag 262', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (262, '/images/generated-bags-262-3.svg', 'Medium Food Delivery Bag 262', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 263, id, 'Large Milkshake Straw 263', 'SE-0263', 'Rs. 123 / 100 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0263 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (263, '/images/generated-straws-263-1.svg', 'Large Milkshake Straw 263', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (263, '/images/generated-straws-263-2.svg', 'Large Milkshake Straw 263', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (263, '/images/generated-straws-263-3.svg', 'Large Milkshake Straw 263', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 264, id, 'Premium Dessert Bowl 264', 'SE-0264', 'Rs. 165 / 200 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0264 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (264, '/images/generated-bowls-264-1.svg', 'Premium Dessert Bowl 264', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (264, '/images/generated-bowls-264-2.svg', 'Premium Dessert Bowl 264', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (264, '/images/generated-bowls-264-3.svg', 'Premium Dessert Bowl 264', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 265, id, 'Economy Double Wall Coffee Cup 265', 'SE-0265', 'Rs. 170 / 500 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0265 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (265, '/images/generated-cups-265-1.svg', 'Economy Double Wall Coffee Cup 265', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (265, '/images/generated-cups-265-2.svg', 'Economy Double Wall Coffee Cup 265', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (265, '/images/generated-cups-265-3.svg', 'Economy Double Wall Coffee Cup 265', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 266, id, 'Small Snack Paper Plate 266', 'SE-0266', 'Rs. 199 / 25 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0266 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (266, '/images/generated-plates-266-1.svg', 'Small Snack Paper Plate 266', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (266, '/images/generated-plates-266-2.svg', 'Small Snack Paper Plate 266', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (266, '/images/generated-plates-266-3.svg', 'Small Snack Paper Plate 266', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 267, id, 'Medium Sauce Cup Container 267', 'SE-0267', 'Rs. 231 / 50 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0267 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (267, '/images/generated-containers-267-1.svg', 'Medium Sauce Cup Container 267', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (267, '/images/generated-containers-267-2.svg', 'Medium Sauce Cup Container 267', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (267, '/images/generated-containers-267-3.svg', 'Medium Sauce Cup Container 267', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 268, id, 'Large Ice Cream Spoon Pack 268', 'SE-0268', 'Rs. 165 / 100 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0268 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (268, '/images/generated-cutlery-268-1.svg', 'Large Ice Cream Spoon Pack 268', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (268, '/images/generated-cutlery-268-2.svg', 'Large Ice Cream Spoon Pack 268', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (268, '/images/generated-cutlery-268-3.svg', 'Large Ice Cream Spoon Pack 268', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 269, id, 'Premium Cocktail Napkin 269', 'SE-0269', 'Rs. 168 / 200 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0269 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (269, '/images/generated-napkins-269-1.svg', 'Premium Cocktail Napkin 269', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (269, '/images/generated-napkins-269-2.svg', 'Premium Cocktail Napkin 269', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (269, '/images/generated-napkins-269-3.svg', 'Premium Cocktail Napkin 269', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 270, id, 'Economy Bakery Paper Bag 270', 'SE-0270', 'Rs. 267 / 500 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0270 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (270, '/images/generated-bags-270-1.svg', 'Economy Bakery Paper Bag 270', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (270, '/images/generated-bags-270-2.svg', 'Economy Bakery Paper Bag 270', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (270, '/images/generated-bags-270-3.svg', 'Economy Bakery Paper Bag 270', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 271, id, 'Small Wrapped Straw 271', 'SE-0271', 'Rs. 179 / 25 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0271 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (271, '/images/generated-straws-271-1.svg', 'Small Wrapped Straw 271', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (271, '/images/generated-straws-271-2.svg', 'Small Wrapped Straw 271', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (271, '/images/generated-straws-271-3.svg', 'Small Wrapped Straw 271', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 272, id, 'Medium Rice Bowl 272', 'SE-0272', 'Rs. 221 / 50 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0272 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (272, '/images/generated-bowls-272-1.svg', 'Medium Rice Bowl 272', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (272, '/images/generated-bowls-272-2.svg', 'Medium Rice Bowl 272', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (272, '/images/generated-bowls-272-3.svg', 'Medium Rice Bowl 272', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 273, id, 'Large Cold Drink Paper Cup 273', 'SE-0273', 'Rs. 107 / 100 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0273 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (273, '/images/generated-cups-273-1.svg', 'Large Cold Drink Paper Cup 273', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (273, '/images/generated-cups-273-2.svg', 'Large Cold Drink Paper Cup 273', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (273, '/images/generated-cups-273-3.svg', 'Large Cold Drink Paper Cup 273', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 274, id, 'Premium Heavy Duty Dinner Plate 274', 'SE-0274', 'Rs. 136 / 200 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0274 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (274, '/images/generated-plates-274-1.svg', 'Premium Heavy Duty Dinner Plate 274', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (274, '/images/generated-plates-274-2.svg', 'Premium Heavy Duty Dinner Plate 274', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (274, '/images/generated-plates-274-3.svg', 'Premium Heavy Duty Dinner Plate 274', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 275, id, 'Economy Bakery Clamshell Box 275', 'SE-0275', 'Rs. 168 / 500 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0275 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (275, '/images/generated-containers-275-1.svg', 'Economy Bakery Clamshell Box 275', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (275, '/images/generated-containers-275-2.svg', 'Economy Bakery Clamshell Box 275', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (275, '/images/generated-containers-275-3.svg', 'Economy Bakery Clamshell Box 275', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 276, id, 'Small Knife Pack 276', 'SE-0276', 'Rs. 102 / 25 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0276 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (276, '/images/generated-cutlery-276-1.svg', 'Small Knife Pack 276', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (276, '/images/generated-cutlery-276-2.svg', 'Small Knife Pack 276', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (276, '/images/generated-cutlery-276-3.svg', 'Small Knife Pack 276', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 277, id, 'Medium Soft Table Tissue 277', 'SE-0277', 'Rs. 105 / 50 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0277 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (277, '/images/generated-napkins-277-1.svg', 'Medium Soft Table Tissue 277', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (277, '/images/generated-napkins-277-2.svg', 'Medium Soft Table Tissue 277', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (277, '/images/generated-napkins-277-3.svg', 'Medium Soft Table Tissue 277', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 278, id, 'Large Gift Paper Bag 278', 'SE-0278', 'Rs. 204 / 100 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0278 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (278, '/images/generated-bags-278-1.svg', 'Large Gift Paper Bag 278', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (278, '/images/generated-bags-278-2.svg', 'Large Gift Paper Bag 278', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (278, '/images/generated-bags-278-3.svg', 'Large Gift Paper Bag 278', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 279, id, 'Premium Cocktail Straw 279', 'SE-0279', 'Rs. 116 / 200 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0279 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (279, '/images/generated-straws-279-1.svg', 'Premium Cocktail Straw 279', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (279, '/images/generated-straws-279-2.svg', 'Premium Cocktail Straw 279', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (279, '/images/generated-straws-279-3.svg', 'Premium Cocktail Straw 279', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 280, id, 'Economy Noodle Bowl 280', 'SE-0280', 'Rs. 158 / 500 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0280 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (280, '/images/generated-bowls-280-1.svg', 'Economy Noodle Bowl 280', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (280, '/images/generated-bowls-280-2.svg', 'Economy Noodle Bowl 280', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (280, '/images/generated-bowls-280-3.svg', 'Economy Noodle Bowl 280', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 281, id, 'Small Kulhad Style Cup 281', 'SE-0281', 'Rs. 166 / 25 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0281 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (281, '/images/generated-cups-281-1.svg', 'Small Kulhad Style Cup 281', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (281, '/images/generated-cups-281-2.svg', 'Small Kulhad Style Cup 281', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (281, '/images/generated-cups-281-3.svg', 'Small Kulhad Style Cup 281', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 282, id, 'Medium Eco Bagasse Plate 282', 'SE-0282', 'Rs. 195 / 50 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0282 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (282, '/images/generated-plates-282-1.svg', 'Medium Eco Bagasse Plate 282', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (282, '/images/generated-plates-282-2.svg', 'Medium Eco Bagasse Plate 282', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (282, '/images/generated-plates-282-3.svg', 'Medium Eco Bagasse Plate 282', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 283, id, 'Large Microwave Safe Container 283', 'SE-0283', 'Rs. 227 / 100 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0283 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (283, '/images/generated-containers-283-1.svg', 'Large Microwave Safe Container 283', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (283, '/images/generated-containers-283-2.svg', 'Large Microwave Safe Container 283', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (283, '/images/generated-containers-283-3.svg', 'Large Microwave Safe Container 283', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 284, id, 'Premium Mixed Cutlery Kit 284', 'SE-0284', 'Rs. 161 / 200 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0284 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:33', '2026-06-08 09:43:33'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (284, '/images/generated-cutlery-284-1.svg', 'Premium Mixed Cutlery Kit 284', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (284, '/images/generated-cutlery-284-2.svg', 'Premium Mixed Cutlery Kit 284', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (284, '/images/generated-cutlery-284-3.svg', 'Premium Mixed Cutlery Kit 284', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 285, id, 'Economy Dispenser Tissue 285', 'SE-0285', 'Rs. 164 / 500 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0285 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (285, '/images/generated-napkins-285-1.svg', 'Economy Dispenser Tissue 285', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (285, '/images/generated-napkins-285-2.svg', 'Economy Dispenser Tissue 285', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (285, '/images/generated-napkins-285-3.svg', 'Economy Dispenser Tissue 285', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 286, id, 'Small Retail Counter Bag 286', 'SE-0286', 'Rs. 263 / 25 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0286 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (286, '/images/generated-bags-286-1.svg', 'Small Retail Counter Bag 286', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (286, '/images/generated-bags-286-2.svg', 'Small Retail Counter Bag 286', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (286, '/images/generated-bags-286-3.svg', 'Small Retail Counter Bag 286', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 287, id, 'Medium Jumbo Drink Straw 287', 'SE-0287', 'Rs. 175 / 50 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0287 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (287, '/images/generated-straws-287-1.svg', 'Medium Jumbo Drink Straw 287', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (287, '/images/generated-straws-287-2.svg', 'Medium Jumbo Drink Straw 287', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (287, '/images/generated-straws-287-3.svg', 'Medium Jumbo Drink Straw 287', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 288, id, 'Large Laminated Snack Bowl 288', 'SE-0288', 'Rs. 217 / 100 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0288 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (288, '/images/generated-bowls-288-1.svg', 'Large Laminated Snack Bowl 288', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (288, '/images/generated-bowls-288-2.svg', 'Large Laminated Snack Bowl 288', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (288, '/images/generated-bowls-288-3.svg', 'Large Laminated Snack Bowl 288', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 289, id, 'Premium Ripple Paper Cup 289', 'SE-0289', 'Rs. 222 / 200 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0289 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (289, '/images/generated-cups-289-1.svg', 'Premium Ripple Paper Cup 289', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (289, '/images/generated-cups-289-2.svg', 'Premium Ripple Paper Cup 289', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (289, '/images/generated-cups-289-3.svg', 'Premium Ripple Paper Cup 289', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 290, id, 'Economy Round Paper Plate 290', 'SE-0290', 'Rs. 132 / 500 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0290 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (290, '/images/generated-plates-290-1.svg', 'Economy Round Paper Plate 290', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (290, '/images/generated-plates-290-2.svg', 'Economy Round Paper Plate 290', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (290, '/images/generated-plates-290-3.svg', 'Economy Round Paper Plate 290', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 291, id, 'Small Round Food Container 291', 'SE-0291', 'Rs. 164 / 25 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0291 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (291, '/images/generated-containers-291-1.svg', 'Small Round Food Container 291', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (291, '/images/generated-containers-291-2.svg', 'Small Round Food Container 291', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (291, '/images/generated-containers-291-3.svg', 'Small Round Food Container 291', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 292, id, 'Medium Wooden Spoon Pack 292', 'SE-0292', 'Rs. 98 / 50 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0292 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (292, '/images/generated-cutlery-292-1.svg', 'Medium Wooden Spoon Pack 292', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (292, '/images/generated-cutlery-292-2.svg', 'Medium Wooden Spoon Pack 292', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (292, '/images/generated-cutlery-292-3.svg', 'Medium Wooden Spoon Pack 292', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 293, id, 'Large Tissue Napkin Pack 293', 'SE-0293', 'Rs. 101 / 100 pcs', 'Table hygiene disposable', 'Soft napkins and tissues for tables, counters, and events.', 'Clean, absorbent napkins for food service and retail use, with multiple pack sizes for daily operations and wholesale customers. Item code SE-0293 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 200 pcs, carton packs', 'Restaurants, offices, hotels, party suppliers', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Napkins');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (293, '/images/generated-napkins-293-1.svg', 'Large Tissue Napkin Pack 293', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (293, '/images/generated-napkins-293-2.svg', 'Large Tissue Napkin Pack 293', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (293, '/images/generated-napkins-293-3.svg', 'Large Tissue Napkin Pack 293', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 294, id, 'Premium Paper Carry Bag 294', 'SE-0294', 'Rs. 200 / 200 pcs', 'Carry and retail packaging', 'Paper carry bags for packing, delivery, and retail counters.', 'Durable paper bags for shop counters and takeaway use, available in practical sizes for food packets, groceries, bakery, and gifting. Item code SE-0294 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, bulk carton', 'Retail shops, bakeries, groceries, restaurants', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Bags');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (294, '/images/generated-bags-294-1.svg', 'Premium Paper Carry Bag 294', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (294, '/images/generated-bags-294-2.svg', 'Premium Paper Carry Bag 294', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (294, '/images/generated-bags-294-3.svg', 'Premium Paper Carry Bag 294', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 295, id, 'Economy Paper Straw Pack 295', 'SE-0295', 'Rs. 112 / 500 pcs', 'Drink service disposable', 'Disposable straws for cold drinks, shakes, and event service.', 'Convenient straw packs for drink counters, available in different sizes for juices, milkshakes, cold coffee, parties, and retail sale. Item code SE-0295 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 250 pcs, bulk carton', 'Juice shops, cafes, restaurants, event counters', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Straws');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (295, '/images/generated-straws-295-1.svg', 'Economy Paper Straw Pack 295', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (295, '/images/generated-straws-295-2.svg', 'Economy Paper Straw Pack 295', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (295, '/images/generated-straws-295-3.svg', 'Economy Paper Straw Pack 295', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 296, id, 'Small Paper Soup Bowl 296', 'SE-0296', 'Rs. 154 / 25 pcs', 'Bowl serving disposable', 'Disposable bowls for soups, snacks, rice, desserts, and salads.', 'Strong bowl options for hot and cold food service, designed for counters, catering, parties, restaurant packing, and wholesale supply. Item code SE-0296 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, carton packs', 'Caterers, restaurants, food stalls, events', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Bowls');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (296, '/images/generated-bowls-296-1.svg', 'Small Paper Soup Bowl 296', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (296, '/images/generated-bowls-296-2.svg', 'Small Paper Soup Bowl 296', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (296, '/images/generated-bowls-296-3.svg', 'Small Paper Soup Bowl 296', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 297, id, 'Medium Plain Paper Cup 297', 'SE-0297', 'Rs. 159 / 50 pcs', 'Hot and cold beverage disposable', 'Disposable cups for tea, coffee, juice, events, and counters.', 'Food-grade disposable cups with dependable rim strength, practical insulation, and supply-ready packing for retail shelves and wholesale cartons. Item code SE-0297 is suited for regular replenishment and counter-ready presentation.', '50 pcs, 100 pcs, bulk carton', 'Tea stalls, cafes, offices, caterers', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (297, '/images/generated-cups-297-1.svg', 'Medium Plain Paper Cup 297', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (297, '/images/generated-cups-297-2.svg', 'Medium Plain Paper Cup 297', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (297, '/images/generated-cups-297-3.svg', 'Medium Plain Paper Cup 297', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 298, id, 'Large Compartment Meal Plate 298', 'SE-0298', 'Rs. 188 / 100 pcs', 'Meal serving disposable', 'Strong disposable plates for meals, snacks, events, and food counters.', 'Sturdy disposable plates for practical food service, designed for easy stacking, quick serving, and reliable handling in events and retail sale. Item code SE-0298 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, wholesale carton', 'Caterers, households, event managers, retailers', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Plates');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (298, '/images/generated-plates-298-1.svg', 'Large Compartment Meal Plate 298', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (298, '/images/generated-plates-298-2.svg', 'Large Compartment Meal Plate 298', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (298, '/images/generated-plates-298-3.svg', 'Large Compartment Meal Plate 298', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 299, id, 'Premium Rectangular Meal Box 299', 'SE-0299', 'Rs. 220 / 200 pcs', 'Takeaway packaging', 'Food containers for takeaway, delivery, storage, and display.', 'Stackable food containers with secure closure options for takeaway counters, food delivery, sweets, bakery products, and daily kitchen operations. Item code SE-0299 is suited for regular replenishment and counter-ready presentation.', '25 pcs, 100 pcs, carton packs', 'Restaurants, cloud kitchens, bakeries, sweet shops', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Containers');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (299, '/images/generated-containers-299-1.svg', 'Premium Rectangular Meal Box 299', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (299, '/images/generated-containers-299-2.svg', 'Premium Rectangular Meal Box 299', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (299, '/images/generated-containers-299-3.svg', 'Premium Rectangular Meal Box 299', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 300, id, 'Economy Disposable Fork Pack 300', 'SE-0300', 'Rs. 154 / 500 pcs', 'Disposable cutlery', 'Clean disposable spoons, forks, knives, and serving cutlery.', 'Smooth finish disposable cutlery suitable for events, takeaway orders, pantry supply, retail counters, and tasting or sampling counters. Item code SE-0300 is suited for regular replenishment and counter-ready presentation.', '100 pcs, 500 pcs, mixed carton', 'Food counters, event planners, tasting counters', 0, 'active', '2026-06-08 09:43:34', '2026-06-08 09:43:34'
FROM product_categories WHERE LOWER(name) = LOWER('Cutlery');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (300, '/images/generated-cutlery-300-1.svg', 'Economy Disposable Fork Pack 300', 0);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (300, '/images/generated-cutlery-300-2.svg', 'Economy Disposable Fork Pack 300', 1);
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (300, '/images/generated-cutlery-300-3.svg', 'Economy Disposable Fork Pack 300', 2);
INSERT INTO products (id, category_id, name, sku, price_label, product_type, summary, details, pack_size, audience, featured, status, created_at, updated_at)
SELECT 301, id, 'kids cup', 'SE-0301', 'Rs. 95 / 50 pcs', 'Hot beverage disposable', 'good for sipping', 'no much', '50 pcs, 100 pcs, carton packs', 'Tea stalls, offices, cafes, events', 1, 'active', '2026-06-08 10:47:10', '2026-06-08 10:47:10'
FROM product_categories WHERE LOWER(name) = LOWER('cups');
INSERT INTO product_images (product_id, image_data, alt_text, sort_order) VALUES (301, 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxISEhUTExIWEhUXFRcVFRIVEhUYFRcVFRIWFxUVFRoYHSggGBolGxUVITEhJSkrLi4uFx8zODMsNygtLisBCgoKDg0OGhAQGisdHR0xLSstLSstKystKy0tLi0uLS0tKy0uNS0tKy0tNy0tLS0tLS0tLS0tLS0tLS0tKy0tLf/AABEIANUA7QMBIgACEQEDEQH/xAAcAAEAAgMBAQEAAAAAAAAAAAAABQYBBAcDAgj/xABFEAACAQIBCQMHCQYFBQAAAAAAAQIDEQQFEiExQVFhcZEGUoEiQmKSocHhBxMUMnKCsdHwQ1Njg6LSM1ST4vEVI0Sywv/EABkBAQADAQEAAAAAAAAAAAAAAAABAgQFA//EACIRAQEAAgIBBAMBAAAAAAAAAAABAhEDBDEhIkFREhRhE//aAAwDAQACEQMRAD8A7iAAAAAAGAMgwAMgwAMgwAMgwAMgwAMgwAMgwAMgwAMgwAMgAAAAAAAAAAAAAAAAAAAaeU8qUcPDPrVI0475PW9yWtvkBuA5nl/5XKdNP6Lh54iWxyahHnbW10KPjPlPyzWvmujhY+jTUpLxk2B+hAfmnE9t8Y1apjqre3Nm4q/KNrEfPtnV/wAziH/Nn/cTpG36mB+WI9ta3+YxK/nT/uN/Cdv8TH6uNrr7UnL/ANrjSX6YBwfJ3ym49WtXp1uE6cbv1c1lmyf8rUlZYnC29OlL/wCJ/wBw0OpAgMh9sMHi7KlWSm/2c/In4J6/C5PkAAAAAAAAAAAAAAAAAAAAAAABgQva3L8cDh5Vms6X1acO9N6ly1t8EcDyzlatiqjq1pucn6sV3YrzUdA+UrKdPHRVPDS+c+j1H844/VcpRatF+daz08TmMokyIa/0ht2irv2LmeOJzX9ao5vuwWheOo+J0XfN2beJuYfBJ6vK4arfAsIj6PHZF+L/ACPqOFj3F7fzJieGUXZ6OjXsPPNIGjTwEWr5sejPR5Oj3YtfeWy+820rajOcwNWjQp7Yvwl+ZNYNxStGo7d2pHOj12EbY9ITt+QEjXw0XpS+blss705P0X5rLX2M+UOthpKjipOrRvbPempT431zitz07txSqdVxTs7ratjPjF2ztG5fhtA/T9GrGcVKLUoyScZLU01dNH2UH5JsuQnhYYadRfPQznGm9DdLPea495LStGqyL8VSAAAAAAAAAAAAAAAAAAAc9+V/tFOhRhh6cs2VbOc5LWqUbJpbs5u3JM6Ecq+VHCrFV1Gm/LowUXzk3JICn9jcUo/OQfnWkvu/8mzlbA0qjzv8OT1tK8X9pbHxRWcNKdKraSzZJ6Lqy4p7uZM18ZnLToe0uqjcTk6cdiku9F3XsNXNXI9sRXa1O3JkfXyjNbVLmkQltOG7St5iUHuI15Xa1wT5Noy8uR7j9YCQsZ07uWj9XI1ZbgvNlp4of9bjsi/WRAk/mna9tG/YIxS19CNWU29Ubc2z7p4qT3EiQu5PQrvgbNLAN6Zv7uvqa2GxB6YnHWWh+JKGcZjJRqwlTk4yp2zZRdmmne66ne+wPaH6dhI1Jf4kW6dS2rOSXlLmmn1PzhQUpPhve17ztnyNSjClVot2qOSq5voOKin1j7UVqY6OACEgAAAAAAAAAAAAAAABzHLOT5xxtdvQpvOT2OMkmujuvA6cR+V8mRrx06JL6svc+BMo5DlfD05eTXhp2VFrt7yFqZLaX/bnGrHZFu0l+Re8p4XNvCrHfoep22xZVsfkOL8qnLNe6V/Y0W2jSsY3BS2xlB8VddUQGLw01x5O/s1lnxka8NGe+qkiLrYmr6EucSBWatOS1xfRmvJllliJ/uoPk7Hk8Q/3HSRAr1z6jcnXW/ge34j5yWyklzfxGxHUM7c+huUqU38NP4GxGVTdCP65HorvXPwQ2PqjRlu08X7kbVPAp6Zy8PgjGHo32krhaMVx5lkMUYQgrqN919pb/krjUqY91NNo05Oo9lpWUY9dS9FmjkPs9UxlRQhaKteVSS0KKte296VoOvdnshUcHS+bpLjKb+tOW+X5bCLYnVSgAKpAAAAAAAAAAAAAAAAAABBZVoKTkpJNPY1oKdlXIq8yTj6L0rwesvWUo+VfeiDxsdFtCW6SvF8nsOZnnlx53Vb+LHHPGbjl+VclVVeyT8bfiVbG4KstdOT5K/4HW8oYXfFpb15USr43Bxb0L1ZNPoXncznn1Murj8OZV4yWtSXg0a/zz7z6sv2Iwz31V4mhPDr+K/BHpO5L5jyvV/qofPS70urCnJ7W/Flq+gr91UlzaXuPuOGiv2VOPGc7voT+1PpH61+1aw1OUnoi5ck2StLJ9Va45v2mk+msmqD2Kbfo0oZq6m9RpqL2QfDyp9dh55dzL4i860+a0cBkibs5vMW615PkizZOyXTi7tZzXe024vZfgeGGhzXjeb/InMJTt+X61spefPLzXpjw4z4WvsVQ8upLdFR6u9v6S3EB2OpWpSl3p+xJfEnzbwzWEZOa7zoAD1eQAAAAAAAAAAAAAAAAAANDKcdT5kJitG2y26LxfNbCfykvJXMgsSua4r3rajm9mazrb177UFioW0qMl6VKV16pX8a0/OUuElZljxdO92oqXpU5ZsvFEDj5bM98qkPeZmxA4qhr0NfZZG1KT3VXyZK4mHox+67e4jqtL+HL1yJVa1Hh/wCHN/anYwqSXm0485ZzPR0f4frVDEbL93HleTL7Q9qbvozpTW6Mc2JvUVbQrR4R0y8WakLvvT/pib1BbF0gtHjIrRv4VbNXDW/FkxhYkThVy5LV4vaTGGWgvih0Ps5TzcPDjd9ZNkkeGCp5tOEd0Yroj3OtjNYyOZld5WgALKgAAAAAAAAAAAAAAAAAA18cvIf62kBiFzvw+suW8sdeN4tcH+BXcQuHhe3R7GYO3PdK19aoXFxztkZvg8yp8SBx8redOPCpG666CwY1X0PNk+7PyZeEtpA49W78OflRMbd8ILExvsg+K0MjatH0E/v/AAJPEtPbCXNWZHVaS7kPWKzyhqypLuQXOYjK3nQXCMbvqfTilsprm7iNT01yhD3l1XtGN9LUpcZuy6G9h9K3rcvJgvzNOMdrXjN6ehvUdj17m9EfBFaJDCfrd4E/kqlnThHfKKfVEJgy1dlqV68OCcuif5ntxzdkVzusbV9QAOs5YAAAAAAAAAAAAAAAAAAAAAwyu4uNrrjbTq0byxkFlGNpS69dJk7c9srR177kBjXZWbsu7NZ0PCWwgMbC2pSjxhLOXQsWL0K92lvSzoeMdhXsbC+lKL405W6pnOrpTwgsVP0k/tRt7yNrJX1U/F/Ek8XLjJfajf3EbVku9D1WRFWs5LfSXJNn1Cd9UpPhCNvaYc/TX3afwPuF3+8lz8lFlXrTVtijzedI3qG/2y+s+S2I0aS3WXCKzn1N/Dq3PrL4ECVwSLr2KpeXOW6KXrP/AGlMwZf+xVK1Kct87eEYr82a+vN5x4891hVjAB0XPAAAAAAAAAAAAAAAAAAAAAAiMrR8rmiXI3K8dT5oz9mb469eG6zit4ta7Xb3x0TXNbSvZQs3rjJ8VmTLFjls0Pcm7erL3EBlLc21wqRuvCRy3UnhXsTo7y6SRHVZvvP/AE/gSeKjuT+7LR7SOqX31F4IqitVzb86b5QsZzN8XznO3sPpxb2VHzaXvPlQS2Rj9qWc+hdD3o7k78IKy6m7h93sXvZqU9O9rj5Meht4d/rZ4byIhL4M6V2Tp2w0eLk/6mvcc3wZ1HIMLYekvQT66feburPczdm+2N8AG5iAAAAAAAAAAAAAAAAAAAAAA1sfSzoO2taUbIK5Y/lLKmXV2puN1PUlturx8dz4lex6stsVwanD4F7yrkrOvKGiW4pGVcNKD0wcXvj5N/uvQ/A5XJxZYX1dTi5Mc56K1i0n3XydiOqxfdl4TJHGy06WvvRsyLqJbo+EjxXrwlB7Yv70zMWl3V9lXZ8SSWyC5ts+oS3P1Y29pZDZg9/WXuRvYZ/r9ajQpLwfV9SXyXgKlRpQg3x2eL1DGW30Vt15SeTqLnKMIq7k7LxOs4anmxjHupLorFa7L5HVJpvypa3LdwXiWk6fX4/xnqwc3J+V1PEAAaHiAAAAAAAAAAAAAAAAAAAAAAAAwyPxtJNWkk1uauvaSJ8zgnoautzIs2mXSlY/IWHl+zS5NogMV2Xo7G10Z0avkmnLVnR+zL3O6Iyv2Yb+rXa500/waPC8GN+I9Jy5T5c7n2XjfRVt/LifVLszT86rN8NCLy+yE3/5K/0P956UOx6X1685cIxjH8bkTr4fSf8AbP7V3AZMw9JeTCPOWl+0sOT8PKp9SOjvao/HwJbC5Aw9PSoZz3zk5ex6PYSSR7Y4SeHncrfLxwmGUFbW9r3nuAXVAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH//2Q==', 'kids cup', 0);
INSERT INTO inquiries (id, name, email, phone, message, created_at) VALUES (1, 'Rishi Gupta', 'rishigupta241005@gmail.com', '09007190201', 'hi', '2026-06-08 10:53:56');
INSERT INTO feedback_identities (visitor_id, email, verified, created_at, updated_at) VALUES ('55f3d2ade7463afef536bf9b', 'rishigupta241005@gmail.com', 1, '2026-06-08 09:22:50', '2026-06-08 09:22:50');
INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at) VALUES (9, 'update', 'product', '1', 'Ripple Paper Cups', '::1', '2026-06-08 10:15:29');
INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at) VALUES (10, 'update', 'product', '1', 'Ripple Paper Cups', '::1', '2026-06-08 10:16:33');
INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at) VALUES (11, 'update', 'product', '1', 'Ripple Paper Cups', '::1', '2026-06-08 10:31:54');
INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at) VALUES (12, 'update', 'product', '1', 'Ripple Paper Cups', '::1', '2026-06-08 10:32:20');
INSERT INTO admin_audit_logs (id, action_type, target_type, target_id, details, ip_address, created_at) VALUES (13, 'create', 'product', '301', 'kids cup', '::1', '2026-06-08 10:47:10');
ALTER TABLE products AUTO_INCREMENT = 1001;
ALTER TABLE product_images AUTO_INCREMENT = 1001;
ALTER TABLE inquiries AUTO_INCREMENT = 1001;
ALTER TABLE feedback_comments AUTO_INCREMENT = 1001;
ALTER TABLE feedback_reactions AUTO_INCREMENT = 1001;
ALTER TABLE admin_audit_logs AUTO_INCREMENT = 1001;
