const qs = (selector, root = document) => root.querySelector(selector);
const qsa = (selector, root = document) => Array.from(root.querySelectorAll(selector));

const state = {
  feedbackLimit: 6,
  openReplies: new Set(),
  activeReplyId: null,
  feedbackIdentity: null,
  productPanelProduct: null,
  productPanelReviews: [],
  adminProducts: [],
  adminInquiries: [],
  productFormImages: [],
  activeCategory: "all"
};

const reduceMotion = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
const rootStyle = document.documentElement.style;

window.addEventListener("load", () => {
  window.setTimeout(() => document.body.classList.add("is-ready"), reduceMotion ? 0 : 620);
}, { once: true });

if (!reduceMotion) {
  let pointerFrame = 0;
  document.addEventListener("pointermove", (event) => {
    if (event.pointerType === "touch") return;
    document.body.classList.add("has-pointer");
    cancelAnimationFrame(pointerFrame);
    pointerFrame = requestAnimationFrame(() => {
      rootStyle.setProperty("--aura-x", `${event.clientX}px`);
      rootStyle.setProperty("--aura-y", `${event.clientY}px`);
      rootStyle.setProperty("--cursor-x", `${(event.clientX / window.innerWidth) * 100}%`);
      rootStyle.setProperty("--cursor-y", `${(event.clientY / window.innerHeight) * 100}%`);
      const hero = qs(".hero");
      if (hero) {
        const bounds = hero.getBoundingClientRect();
        rootStyle.setProperty("--hero-x", `${(event.clientX - bounds.left - bounds.width / 2) / 18}px`);
        rootStyle.setProperty("--hero-y", `${(event.clientY - bounds.top - bounds.height / 2) / 18}px`);
      }
    });
  }, { passive: true });

  const updateScrollSignal = () => {
    const max = Math.max(1, document.documentElement.scrollHeight - window.innerHeight);
    rootStyle.setProperty("--scroll-progress", `${(window.scrollY / max) * 100}%`);
  };
  window.addEventListener("scroll", updateScrollSignal, { passive: true });
  updateScrollSignal();

  qsa(".product-card, .feature-grid article").forEach((card) => {
    card.addEventListener("pointermove", (event) => {
      const box = card.getBoundingClientRect();
      const rx = ((event.clientY - box.top) / box.height - .5) * -5;
      const ry = ((event.clientX - box.left) / box.width - .5) * 6;
      card.style.transform = `perspective(900px) rotateX(${rx}deg) rotateY(${ry}deg) translateY(-7px)`;
    });
    card.addEventListener("pointerleave", () => { card.style.transform = ""; });
  });
}

function escapeHtml(value = "") {
  return String(value).replace(/[&<>"']/g, (char) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;"
  })[char]);
}

function fetchJson(url, options = {}) {
  const csrfToken = qs("meta[name='csrf-token']")?.content || "";
  return fetch(url, {
    headers: { "Content-Type": "application/json", ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}), ...(options.headers || {}) },
    ...options
  }).then(async (response) => {
    const data = await response.json().catch(() => ({}));
    if (!response.ok) throw new Error(data.error || "Request failed");
    return data;
  });
}

function avatarTone(label = "") {
  const tones = ["#0f2f2e", "#7f3f1d", "#6f5b1f", "#214f68", "#6a343f", "#315e42"];
  const total = Array.from(label).reduce((sum, char) => sum + char.charCodeAt(0), 0);
  return tones[total % tones.length];
}

function avatar(label = "") {
  const initial = escapeHtml(label.trim()[0] || "S").toUpperCase();
  return `<span class="avatar" style="background:${avatarTone(label)}">${initial}</span>`;
}

function relativeTime(value) {
  const seconds = Math.max(1, Math.floor((Date.now() - new Date(value).getTime()) / 1000));
  if (seconds < 60) return "just now";
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return `${minutes} min ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours} hr ago`;
  const days = Math.floor(hours / 24);
  return `${days} day${days > 1 ? "s" : ""} ago`;
}

function identityHtml(identity) {
  if (identity?.verified) {
    const method = identity.channel === "phone" ? "phone" : "email";
    return `<div class="feedback-identity-card"><strong>Verified ${method}</strong><span>${escapeHtml(identity.contact || identity.email)}</span></div>`;
  }
  return `
    <div class="verify-box">
      <div class="verification-heading"><strong>Verify your identity</strong><span>Required before posting</span></div>
      <label>Verification method
        <select name="verificationChannel">
          <option value="email">Email</option>
          <option value="phone">Phone (SMS)</option>
        </select>
      </label>
      <label><span class="verification-destination-label">Email address</span><input name="verificationDestination" type="email" autocomplete="email" placeholder="your@email.com" required /></label>
      <div class="otp-row">
        <button class="button ghost request-otp" type="button">Send code</button>
        <input name="otp" inputmode="numeric" autocomplete="one-time-code" placeholder="Verification code" />
        <button class="button ghost verify-otp" type="button">Verify</button>
      </div>
      <p class="form-note" aria-live="polite">Choose email or SMS. Include the country code for phone numbers (for example +91 98765 43210).</p>
    </div>`;
}

function setFeedbackIdentity(identity) {
  state.feedbackIdentity = identity;
  qsa("#feedbackIdentity, .reviewIdentity").forEach((target) => {
    target.innerHTML = identityHtml(identity);
  });
}

async function requestOtp(root) {
  const channel = qs("select[name='verificationChannel']", root)?.value || "email";
  const destination = qs("input[name='verificationDestination']", root)?.value.trim();
  if (!destination) throw new Error(`Enter your ${channel === "phone" ? "phone number" : "email address"} first`);
  const result = await fetchJson("/api/feedback/request-otp", {
    method: "POST",
    body: JSON.stringify(channel === "phone" ? { channel, phone: destination } : { channel, email: destination })
  });
  const note = qs(".form-note", root) || qs("#otpNote");
  if (note) {
    note.classList.remove("error");
    note.textContent = result.devOtp ? `Local test code: ${result.devOtp}` : result.message;
  }
}

async function verifyOtp(root) {
  const channel = qs("select[name='verificationChannel']", root)?.value || "email";
  const destination = qs("input[name='verificationDestination']", root)?.value.trim();
  const otp = qs("input[name='otp']", root)?.value.trim();
  if (!destination || !otp) throw new Error(`Enter your ${channel === "phone" ? "phone number" : "email address"} and verification code`);
  const result = await fetchJson("/api/feedback/verify-otp", {
    method: "POST",
    body: JSON.stringify(channel === "phone" ? { channel, phone: destination, otp } : { channel, email: destination, otp })
  });
  setFeedbackIdentity(result.identity);
}

function updateVerificationForm(select) {
  const root = select.closest(".verify-box");
  const input = qs("input[name='verificationDestination']", root);
  const label = qs(".verification-destination-label", root);
  if (!input || !label) return;
  const phone = select.value === "phone";
  label.textContent = phone ? "Mobile number" : "Email address";
  input.type = phone ? "tel" : "email";
  input.autocomplete = phone ? "tel" : "email";
  input.placeholder = phone ? "+91 98765 43210" : "your@email.com";
  input.value = "";
  qs("input[name='otp']", root).value = "";
  const note = qs(".form-note", root);
  if (note) {
    note.classList.remove("error");
    note.textContent = phone ? "We will text a one-time code. Include your country code." : "We will email a one-time verification code.";
  }
}

function reactionButtons(item) {
  return `
    <button class="feedback-like-button ${item.myReaction === "like" ? "active" : ""}" data-feedback-id="${item.id}" data-reaction="like" type="button" title="Like">
      <span>&#128077;</span> ${item.reactions.like || 0}
    </button>
    <button class="feedback-like-button ${item.myReaction === "heart" ? "active" : ""}" data-feedback-id="${item.id}" data-reaction="heart" type="button" title="Heart">
      <span>&#10084;</span> ${item.reactions.heart || 0}
    </button>`;
}

function replyForm(parentId, productId = "") {
  return `
    <form class="feedback-inline-reply" data-parent-id="${parentId}" data-product-id="${productId || ""}">
      <textarea name="message" rows="2" placeholder="Write a reply" required></textarea>
      <div><button class="button small primary" type="submit">Reply</button><button class="button small ghost cancel-reply" type="button">Cancel</button></div>
    </form>`;
}

function commentHtml(item, isReply = false, productId = "") {
  const label = item.displayLabel || item.authorEmail || "Verified customer";
  const repliesOpen = state.openReplies.has(item.id);
  const replies = item.replies || [];
  return `
    <article class="feedback-item ${isReply ? "reply" : ""}" data-feedback-id="${item.id}">
      <div class="feedback-main">
        ${avatar(label)}
        <div class="feedback-body">
          <div class="feedback-line">
            <strong>${escapeHtml(label)}</strong>
            ${label.includes("shawenterprise") ? '<span class="feedback-badge owner">Owner</span>' : ""}
            <span>${relativeTime(item.createdAt)}</span>
          </div>
          <p>${escapeHtml(item.message)}</p>
          <div class="feedback-actions">
            ${reactionButtons(item)}
            ${!isReply ? `<button class="text-button reply-toggle" data-feedback-id="${item.id}" type="button">Reply</button>` : ""}
            ${replies.length ? `<button class="text-button replies-toggle" data-feedback-id="${item.id}" type="button">${repliesOpen ? "Hide" : "Show"} ${replies.length} replies</button>` : ""}
          </div>
          ${state.activeReplyId === item.id ? replyForm(item.id, productId) : ""}
          ${replies.length && repliesOpen ? `<div class="reply-list">${replies.map((reply) => commentHtml(reply, true, productId)).join("")}</div>` : ""}
        </div>
      </div>
    </article>`;
}

function renderFeedbackThreads(threads, rootId = "feedbackList", productId = "") {
  const root = qs(`#${rootId}`);
  if (!root) return;
  const visible = rootId === "feedbackList" ? threads.slice(0, state.feedbackLimit) : threads;
  root.innerHTML = visible.length ? visible.map((item) => commentHtml(item, false, productId)).join("") : `<p class="empty">No comments yet.</p>`;
  const loadMore = qs("#loadMoreFeedback");
  if (loadMore && rootId === "feedbackList") loadMore.hidden = state.feedbackLimit >= threads.length;
}

function applyProductFilters() {

    const cards = qsa("#productGrid .product-card");

    if (!cards.length) return;

    const query = (qs("#productSearch")?.value || "")
        .trim()
        .toLowerCase();

    const sort =
        qs("#productSort")?.value || "featured";

    let visibleCount = 0;

    cards.forEach((card) => {

       const searchableText = [

    card.dataset.name || "",

    card.dataset.category || "",

    card.dataset.summary || "",

    card.dataset.details || "",

    card.dataset.pack || "",

    card.dataset.audience || "",

    card.dataset.tags || "",

    card.textContent || ""

]
.join(" ")
.toLowerCase();

        const cardCategory = (card.dataset.category || "").trim().toLowerCase();
const activeCategory = (state.activeCategory || "all").trim().toLowerCase();

const matchesCategory =
    activeCategory === "all" ||
    cardCategory === activeCategory;

        const matchesSearch =
            !query ||
            searchableText.includes(query);

        const visible =
            matchesCategory &&
            matchesSearch;

        card.hidden = !visible;

        if (visible) {

            visibleCount++;

            card.classList.remove("is-filtered-out");

        } else {

            card.classList.add("is-filtered-out");

        }

    });

    const grid = qs("#productGrid");

    if (grid && sort !== "featured") {

        cards
            .sort((a, b) => {

                const A =
                    a.dataset.name || "";

                const B =
                    b.dataset.name || "";

                if (sort === "name-asc")
                    return A.localeCompare(B);

                if (sort === "name-desc")
                    return B.localeCompare(A);

                return 0;

            })
            .forEach(card => grid.appendChild(card));

    }

    const empty = qs(".catalog-empty");

    if (empty)
        empty.hidden = visibleCount > 0;

    const counter = qs("#catalogCount");

    if (counter) {

        counter.textContent =
            visibleCount
                ? `Showing ${visibleCount} product${visibleCount === 1 ? "" : "s"}`
                : "No matching products";

    }

}

function openCommandPalette() {
  let palette = qs("#commandPalette");
  if (!palette) {
    palette = document.createElement("div");
    palette.id = "commandPalette";
    palette.className = "command-palette";
    palette.innerHTML = `
      <div class="command-palette-card">
        <button class="panel-close close-command-palette" type="button">Close</button>
        <p class="eyebrow">Command palette</p>
        <h2>Jump to workflow</h2>
        <div class="command-list">
          <a href="/products">Browse products</a>
          <a href="/feedback">Open feedback</a>
          <a href="/contact">Create enquiry</a>
          <a href="/admin">Admin dashboard</a>
        </div>
      </div>`;
    document.body.appendChild(palette);
  }
  palette.classList.add("open");
}

function closeCommandPalette() {
  qs("#commandPalette")?.classList.remove("open");
}

async function refreshFeedback() {
  const list = qs("#feedbackList");
  if (!list) return;
  const sort = qs("#feedbackSort")?.value || "top";
  const result = await fetchJson(`/api/feedback?sort=${encodeURIComponent(sort)}`);
  setFeedbackIdentity(result.identity);
  renderFeedbackThreads(result.threads);
}

async function reactToFeedback(button) {
  const id = button.dataset.feedbackId;
  const reaction = button.dataset.reaction;
  await fetchJson(`/api/feedback/${id}/react`, {
    method: "POST",
    body: JSON.stringify({ reaction })
  });
  if (state.productPanelProduct) await openProduct(state.productPanelProduct.id);
  await refreshFeedback().catch(() => {});
}

async function postFeedback(form, productId = "") {
  if (!state.feedbackIdentity?.verified) throw new Error("Verify your email or phone first");
  const message = form.elements.message.value.trim();
  const parentId = form.dataset.parentId || "";
  await fetchJson("/api/feedback", {
    method: "POST",
    body: JSON.stringify({ message, parentId, productId })
  });
  form.reset();
  state.activeReplyId = null;
  if (productId) await openProduct(productId);
  else await refreshFeedback();
}

async function submitInquiry(form) {
  const payload = Object.fromEntries(new FormData(form));
  const result = await fetchJson("/api/inquiries", {
    method: "POST",
    body: JSON.stringify(payload)
  });
  const note = qs(".contact-note", form);
  if (note) {
    note.textContent = `Enquiry saved for ${result.inquiry.name}. Check Admin > Inquiries or MySQL Workbench.`;
  }
  form.reset();
}

function productPanelHtml(product, reviews) {
  const images = product.images?.length ? product.images : ["/images/product.svg"];
  return `
    <div class="product-panel-backdrop" data-close-panel></div>
    <div class="product-panel-card">
      <button class="panel-close" data-close-panel type="button">Close</button>
      <div class="panel-gallery">
        <img class="panel-main-img" src="${escapeHtml(images[0])}" alt="${escapeHtml(product.name)}" />
        <div class="panel-thumbs">${images.map((src) => `<button type="button" class="panel-thumb"><img src="${escapeHtml(src)}" alt="" /></button>`).join("")}</div>
      </div>
      <div class="panel-info">
        <p class="tag">${escapeHtml(product.category)}</p>
        <h2>${escapeHtml(product.name)}</h2>
        <strong class="panel-price">${escapeHtml(product.price)}</strong>
        <p>${escapeHtml(product.details)}</p>
        <dl>
          <div><dt>Type</dt><dd>${escapeHtml(product.productType)}</dd></div>
          <div><dt>Pack size</dt><dd>${escapeHtml(product.packSize)}</dd></div>
          <div><dt>Best for</dt><dd>${escapeHtml(product.audience)}</dd></div>
        </dl>
        <a class="button primary" href="/contact">Ask for Quote</a>
      </div>
      <section class="panel-reviews">
        <h3>Product Reviews</h3>
        <form class="review-form" data-product-id="${product.id}">
          <div class="reviewIdentity">${identityHtml(state.feedbackIdentity)}</div>
          <textarea name="message" rows="3" placeholder="Write a product review" required></textarea>
          <button class="button primary small" type="submit">Post Review</button>
        </form>
        <div id="productReviews">${reviews.length ? reviews.map((item) => commentHtml(item, false, product.id)).join("") : '<p class="empty">No product reviews yet.</p>'}</div>
      </section>
    </div>`;
}

async function openProduct(id) {
  const panel = qs("#productPanel");
  if (!panel) return;
  const result = await fetchJson(`/api/products/${id}`);
  state.productPanelProduct = result.product;
  state.productPanelReviews = result.reviews || [];
  panel.innerHTML = productPanelHtml(result.product, result.reviews || []);
  panel.setAttribute("aria-hidden", "false");
  document.body.classList.add("panel-open");
}

function closeProductPanel() {
  const panel = qs("#productPanel");
  if (!panel) return;
  panel.setAttribute("aria-hidden", "true");
  panel.innerHTML = "";
  state.productPanelProduct = null;
  document.body.classList.remove("panel-open");
}

function setProductFormImages(images = []) {
  state.productFormImages = images.filter(Boolean);
  const form = qs("#productForm");
  const preview = qs("#imagePreviewGrid");
  if (form?.elements.images) form.elements.images.value = JSON.stringify(state.productFormImages);
  if (!preview) return;
  preview.innerHTML = state.productFormImages.length
    ? state.productFormImages.map((src, index) => `
      <div class="image-preview">
        <img src="${escapeHtml(src)}" alt="Selected product ${index + 1}" />
        <button class="remove-image" data-image-index="${index}" type="button" title="Remove image">x</button>
      </div>`).join("")
    : `<p>No product images selected yet.</p>`;
}

function readImageFile(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = () => reject(new Error(`Could not read ${file.name}`));
    reader.readAsDataURL(file);
  });
}

function productFormData(form) {
  return {
    id: form.elements.id.value,
    name: form.elements.name.value,
    category: form.elements.category.value,
    price: form.elements.price.value,
    productType: form.elements.productType.value,
    packSize: form.elements.packSize.value,
    audience: form.elements.audience.value,
    summary: form.elements.summary.value,
    details: form.elements.details.value,
    images: state.productFormImages,
    featured: form.elements.featured.checked
  };
}

function fillProductForm(product) {
  const form = qs("#productForm");
  if (!form) return;
  form.elements.id.value = product.id;
  form.elements.name.value = product.name;
  form.elements.category.value = product.category;
  form.elements.price.value = product.price;
  form.elements.productType.value = product.productType;
  form.elements.packSize.value = product.packSize;
  form.elements.audience.value = product.audience;
  form.elements.summary.value = product.summary;
  form.elements.details.value = product.details;
  setProductFormImages(product.images || []);
  form.elements.featured.checked = product.featured;
  form.scrollIntoView({ behavior: "smooth", block: "start" });
}

function renderAdminProducts(products) {
  const root = qs("#adminProducts");
  if (!root) return;
  state.adminProducts = products || state.adminProducts;
  root.innerHTML = state.adminProducts.map((product) => `
    <article class="admin-row">
      <img src="${escapeHtml(product.images?.[0] || "/images/product.svg")}" alt="" />
      <div><strong>${escapeHtml(product.name)}</strong><p>${escapeHtml(product.price)} | ${escapeHtml(product.category)}</p></div>
      <button class="button small ghost edit-product" data-product-id="${product.id}" type="button">Edit</button>
      <button class="button small danger delete-product" data-product-id="${product.id}" type="button">Delete</button>
    </article>`).join("") || "<p>No products found.</p>";
}

function renderAdminFeedback(items) {
  const root = qs("#adminFeedback");
  if (!root) return;
  root.innerHTML = (items || []).map((item) => `
    <article class="admin-row feedback-moderation ${item.status === "hidden" ? "muted" : ""}">
      <div>
        <strong>${escapeHtml(item.displayLabel)}</strong>
        <p>${escapeHtml(item.message)}</p>
        <small>${escapeHtml(item.productName)} | ${escapeHtml(item.status)} | ${relativeTime(item.createdAt)}</small>
      </div>
      <button class="button small ghost hide-feedback" data-feedback-id="${item.id}" type="button">${item.status === "hidden" ? "Restore" : "Hide"}</button>
      <button class="button small danger delete-feedback" data-feedback-id="${item.id}" type="button">Delete</button>
    </article>`).join("") || "<p>No feedback yet.</p>";
}

function renderAdminInquiries(items) {
  const root = qs("#adminInquiries");
  if (!root) return;
  state.adminInquiries = items || [];
  root.innerHTML = state.adminInquiries.map((item) => `
    <article class="admin-row inquiry-row status-${escapeHtml(item.status || "new")}">
      <div>
        <strong>${escapeHtml(item.name)}</strong>
        <p>${escapeHtml(item.message)}</p>
        <small>${escapeHtml(item.email)} | ${escapeHtml(item.phone)} | ${escapeHtml(item.status || "new")} | ${relativeTime(item.created_at)}</small>
      </div>
      <select class="inquiry-status" data-inquiry-id="${item.id}">
        ${["new", "contacted", "closed"].map((status) => `<option value="${status}" ${status === (item.status || "new") ? "selected" : ""}>${status}</option>`).join("")}
      </select>
    </article>`).join("") || "<p>No inquiries yet.</p>";
}

function renderAuditLog(items) {
  const root = qs("#auditLog");
  if (!root) return;
  root.innerHTML = (items || []).map((item) => `
    <article>
      <strong>${escapeHtml(item.action_type)} ${escapeHtml(item.target_type)}</strong>
      <p>${escapeHtml(item.details || "")}</p>
      <small>${escapeHtml(item.created_at)}</small>
    </article>`).join("") || "<p>No admin actions yet.</p>";
}

async function refreshAdmin() {
  if (qs("#auditLog")) {
    const audits = await fetchJson("/api/admin/audits");
    renderAuditLog(audits.auditLogs);
  }
  if (qs("#adminProducts")) {
    const products = await fetchJson("/api/admin/products");
    renderAdminProducts(products.products);
  }
  if (qs("#adminFeedback")) {
    const feedback = await fetchJson("/api/admin/feedback");
    renderAdminFeedback(feedback.feedback);
    renderAuditLog(feedback.auditLogs);
  }
  if (qs("#adminInquiries")) {
    const inquiries = await fetchJson("/api/admin/inquiries");
    renderAdminInquiries(inquiries.inquiries);
    renderAuditLog(inquiries.auditLogs);
  }
}

document.addEventListener("click", async (event) => {
  const target = event.target.closest("button, a");
  if (!target) return;

  try {
    if (target.matches(".nav-toggle")) {
      qs(".site-nav")?.classList.toggle("open");
    }
    if (target.matches(".filter-chip")) {

    state.activeCategory = (target.dataset.category || "all")
        .trim()
        .toLowerCase();

    qsa(".filter-chip").forEach(button => {
        button.classList.remove("active");
    });

    target.classList.add("active");

    applyProductFilters();
}
    if (target.matches(".open-command-palette")) {
      openCommandPalette();
    }
    if (target.matches(".catalog-search-result")) {
      await openProduct(target.dataset.productId);
    }
    if (target.matches(".quick-command")) {
      qsa(".quick-command").forEach((button) => button.classList.toggle("active", button === target));
      qs(target.dataset.jump)?.scrollIntoView({ behavior: "smooth", block: "start" });
    }
    if (target.matches(".close-command-palette") || target.matches("#commandPalette")) {
      closeCommandPalette();
    }
    if (target.matches(".view-product")) {
      await openProduct(target.dataset.productId);
    }
    if (target.matches("[data-close-panel]")) {
      closeProductPanel();
    }
    if (target.matches(".panel-thumb")) {
      const img = qs("img", target)?.src;
      if (img) qs(".panel-main-img").src = img;
    }
    if (target.matches(".request-otp")) {
      await requestOtp(target.closest("form") || target.closest(".verify-box"));
    }
    if (target.matches(".verify-otp")) {
      await verifyOtp(target.closest("form") || target.closest(".verify-box"));
    }
    if (target.matches(".feedback-like-button")) {
      await reactToFeedback(target);
    }
    if (target.matches(".reply-toggle")) {
      state.activeReplyId = state.activeReplyId === Number(target.dataset.feedbackId) ? null : Number(target.dataset.feedbackId);
      if (state.productPanelProduct) await openProduct(state.productPanelProduct.id);
      else await refreshFeedback();
    }
    if (target.matches(".replies-toggle")) {
      const id = Number(target.dataset.feedbackId);
      if (state.openReplies.has(id)) state.openReplies.delete(id);
      else state.openReplies.add(id);
      if (state.productPanelProduct) await openProduct(state.productPanelProduct.id);
      else await refreshFeedback();
    }
    if (target.matches(".cancel-reply")) {
      state.activeReplyId = null;
      if (state.productPanelProduct) await openProduct(state.productPanelProduct.id);
      else await refreshFeedback();
    }
    if (target.matches("#loadMoreFeedback")) {
      state.feedbackLimit += 6;
      await refreshFeedback();
    }
    if (target.matches("#resetProductForm")) {
      qs("#productForm").reset();
      qs("#productForm").elements.id.value = "";
      setProductFormImages([]);
    }
    if (target.matches(".remove-image")) {
      state.productFormImages.splice(Number(target.dataset.imageIndex), 1);
      setProductFormImages(state.productFormImages);
    }
    if (target.matches(".edit-product")) {
      fillProductForm(state.adminProducts.find((product) => String(product.id) === target.dataset.productId));
    }
    if (target.matches(".delete-product")) {
      if (!window.confirm("Delete this product permanently?")) return;
      await fetchJson(`/api/admin/products/${target.dataset.productId}`, { method: "DELETE" });
      await refreshAdmin();
    }
    if (target.matches(".hide-feedback")) {
      const result = await fetchJson(`/api/admin/feedback/${target.dataset.feedbackId}/hide`, { method: "POST" });
      renderAdminFeedback(result.feedback);
      renderAuditLog(result.auditLogs);
    }
    if (target.matches(".delete-feedback")) {
      if (!window.confirm("Delete this feedback and its replies permanently?")) return;
      const result = await fetchJson(`/api/admin/feedback/${target.dataset.feedbackId}`, { method: "DELETE" });
      renderAdminFeedback(result.feedback);
      renderAuditLog(result.auditLogs);
    }
  } catch (error) {
    if (target.matches(".request-otp, .verify-otp")) {
      const note = qs(".form-note", target.closest("form") || target.closest(".verify-box")) || qs("#otpNote");
      if (note) {
        note.textContent = error.message;
        note.classList.add("error");
      }
    } else {
      alert(error.message);
    }
  }
});

document.addEventListener("change", (event) => {
  if (event.target.matches("select[name='verificationChannel']")) updateVerificationForm(event.target);
});

document.addEventListener("submit", async (event) => {
  const form = event.target;
  try {
    if (form.matches("#feedbackForm")) {
      event.preventDefault();
      await postFeedback(form);
    }
    if (form.matches(".feedback-inline-reply")) {
      event.preventDefault();
      await postFeedback(form, form.dataset.productId);
    }
    if (form.matches(".review-form")) {
      event.preventDefault();
      await postFeedback(form, form.dataset.productId);
    }
    if (form.matches(".contact-form")) {
      event.preventDefault();
      await submitInquiry(form);
    }
    if (form.matches("#productForm")) {
      event.preventDefault();
      const data = productFormData(form);
      const url = data.id ? `/api/admin/products/${data.id}` : "/api/admin/products";
      const method = data.id ? "PUT" : "POST";
      const result = await fetchJson(url, { method, body: JSON.stringify(data) });
      renderAdminProducts(result.products);
      renderAuditLog(result.auditLogs);
      form.reset();
      form.elements.id.value = "";
      setProductFormImages([]);
    }
    if (form.matches("#businessSettingsForm")) {
      event.preventDefault();
      const settings = Object.fromEntries(new FormData(form));
      const result = await fetchJson("/api/admin/settings", { method: "PUT", body: JSON.stringify(settings) });
      const status = qs("#settingsStatus");
      if (status) status.textContent = "Saved. The map and business details are now synced across all open pages.";
      if (result.settings?.mapSearchUrl) form.querySelector("a[target='_blank']")?.setAttribute("href", result.settings.mapSearchUrl);
    }
  } catch (error) {
    alert(error.message);
  }
});

document.addEventListener("change", async (event) => {
  const input = event.target;
  if (input.matches(".inquiry-status")) {
    try {
      const result = await fetchJson(`/api/admin/inquiries/${input.dataset.inquiryId}/status`, {
        method: "POST",
        body: JSON.stringify({ status: input.value })
      });
      renderAdminInquiries(result.inquiries);
      renderAuditLog(result.auditLogs);
    } catch (error) {
      alert(error.message);
      await refreshAdmin();
    }
    return;
  }
  if (!input.matches("input[name='imageFiles']")) return;
  try {
    const selected = await Promise.all(Array.from(input.files || []).map(readImageFile));
    setProductFormImages(state.productFormImages.concat(selected));
    input.value = "";
  } catch (error) {
    alert(error.message);
  }
});

qs("#feedbackSort")?.addEventListener("change", () => {
  state.feedbackLimit = 6;
  refreshFeedback();
});

qs("#productSearch")?.addEventListener("input", applyProductFilters);
qs("#productSort")?.addEventListener("change", applyProductFilters);

// The admin portal uses small, live API calls instead of page-to-page mock states.
const authViews = {
  login: ["Welcome back", "Sign in to continue to your dashboard.", "New to the workspace?", "Create an account"],
  register: ["Create secure access", "Verify both contact channels before you can enter.", "Already have access?", "Sign in"],
  verify: ["Verify your account", "A six-digit code is required for each contact channel.", "", ""],
  forgot: ["Reset your password", "We’ll send a one-time code to your work email.", "Remembered it?", "Sign in"],
  reset: ["Choose a new password", "Use a fresh password with at least 12 characters.", "", ""]
};
let resetEmail = "";

function showAuthView(view) {
  if (!qs(".auth-card")) return;
  ["login", "register", "verify", "forgot", "reset"].forEach((name) => qs(`#${name}Form`)?.classList.toggle("hidden", name !== view));
  const [title, subtitle, prefix, action] = authViews[view];
  qs("#authTitle").textContent = title; qs("#authSubtitle").textContent = subtitle;
  const switcher = qs("#authSwitch");
  const canRegister = Boolean(qs("#registerForm"));
  if (switcher && view === "login" && !canRegister) switcher.textContent = "Administrator access is owner-managed.";
  else if (switcher) switcher.innerHTML = prefix ? `${prefix} <button class="link-button" type="button" data-auth-view="${view === "login" ? "register" : "login"}">${action}</button>` : "";
  qs("#authStatus").textContent = "";
}

function authStatus(message) { const node = qs("#authStatus"); if (node) node.textContent = message || ""; }
function devCodeMessage(result) {
  const values = [["email", result.devEmailCode], ["phone", result.devPhoneCode], ["reset", result.devCode]].filter(([, value]) => value);
  return values.length ? ` Development codes — ${values.map(([label, value]) => `${label}: ${value}`).join(" · ")}` : "";
}

document.addEventListener("click", async (event) => {
  const button = event.target.closest(".password-toggle, [data-auth-view], .resend-code");
  if (!button) return;
  if (button.matches(".password-toggle")) {
    const input = button.parentElement.querySelector("input"); input.type = input.type === "password" ? "text" : "password"; button.textContent = input.type === "password" ? "Show" : "Hide"; return;
  }
  if (button.dataset.authView) { showAuthView(button.dataset.authView); return; }
  if (button.matches(".resend-code")) {
    try {
      const result = await fetchJson("/api/auth/resend-signup", { method: "POST", body: JSON.stringify({ accountId: sessionStorage.getItem("shawPendingAccount") }) });
      authStatus(result.message + devCodeMessage(result));
    } catch (error) { authStatus(error.message); }
  }
});

document.addEventListener("submit", async (event) => {
  const form = event.target;
  if (!form.matches("#loginForm, #registerForm, #verifyForm, #forgotForm, #resetForm")) return;
  event.preventDefault();
  try {
    if (form.matches("#loginForm")) {
      const result = await fetchJson("/api/auth/login", { method: "POST", body: JSON.stringify(Object.fromEntries(new FormData(form))) });
      window.location.assign(result.redirect || "/admin");
      return;
    }
    if (form.matches("#registerForm")) {
      const data = Object.fromEntries(new FormData(form));
      const result = await fetchJson("/api/auth/register", { method: "POST", body: JSON.stringify(data) });
      sessionStorage.setItem("shawPendingAccount", result.accountId); showAuthView("verify"); authStatus(result.message + devCodeMessage(result));
    }
    if (form.matches("#verifyForm")) {
      const result = await fetchJson("/api/auth/verify-signup", { method: "POST", body: JSON.stringify({ accountId: sessionStorage.getItem("shawPendingAccount"), ...Object.fromEntries(new FormData(form)) }) });
      sessionStorage.removeItem("shawPendingAccount"); showAuthView("login"); authStatus(result.message);
    }
    if (form.matches("#forgotForm")) {
      resetEmail = form.elements.email.value.trim().toLowerCase(); const result = await fetchJson("/api/auth/request-reset", { method: "POST", body: JSON.stringify({ email: resetEmail }) }); showAuthView("reset"); authStatus(result.message + devCodeMessage(result));
    }
    if (form.matches("#resetForm")) {
      const result = await fetchJson("/api/auth/reset-password", { method: "POST", body: JSON.stringify({ email: resetEmail, ...Object.fromEntries(new FormData(form)) }) }); showAuthView("login"); authStatus(result.message);
    }
  } catch (error) { authStatus(error.message); }
});

document.addEventListener("keydown", (event) => {
  if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "k") {
    event.preventDefault();
    openCommandPalette();
  }
  if (event.key === "Escape") {
    closeCommandPalette();
    closeProductPanel();
  }
  if (event.key === "/" && qs("#productSearch") && document.activeElement === document.body) {
    event.preventDefault();
    qs("#productSearch").focus();
  }
});

const shell = qs(".feedback-shell");
if (shell) {
  try {
    setFeedbackIdentity(JSON.parse(shell.dataset.identity || "null"));
  } catch {
    setFeedbackIdentity(null);
  }
  refreshFeedback();
}

refreshAdmin();

setProductFormImages([]);

const revealObserver = "IntersectionObserver" in window ? new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      entry.target.classList.add("is-visible");
      revealObserver.unobserve(entry.target);
    }
  });
}, { threshold: 0.12 }) : null;

qsa(".feature-grid article, .feedback-item, .admin-section, .contact-card, .contact-form").forEach((item, index) => {
  item.classList.add("reveal");
  item.style.setProperty("--reveal-delay", `${Math.min(index * 35, 280)}ms`);
  if (revealObserver) revealObserver.observe(item);
  else item.classList.add("is-visible");
});

applyProductFilters();

// One lightweight stream keeps every open storefront/admin tab consistent with MySQL writes.
if ("EventSource" in window) {
  const live = new EventSource("/api/live");
  let liveTimer = 0;
  live.addEventListener("sync", (event) => {
    window.clearTimeout(liveTimer);
    liveTimer = window.setTimeout(async () => {
      const topic = event.data;
      if (document.querySelector(".admin-shell")) {
        await refreshAdmin().catch(() => {});
        if (topic === "settings" && document.querySelector("#businessSettingsForm")) window.location.reload();
        return;
      }
      if (topic === "feedback" && document.querySelector("#feedbackList")) await refreshFeedback().catch(() => {});
      else if (topic === "feedback" && state.productPanelProduct) await openProduct(state.productPanelProduct.id).catch(() => {});
      else if ((topic === "products" && (location.pathname === "/" || location.pathname === "/products")) || (topic === "settings" && location.pathname === "/contact")) window.location.reload();
    }, 250);
  });
}
