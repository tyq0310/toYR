<template>
  <main class="menu-page">
    <section class="hero">
      <div>
        <p class="eyebrow">今日营业中</p>
        <h1>福临鲁菜馆</h1>
        <p class="subtitle">
          新鲜热菜、招牌主食和饮品甜点，选好后右侧确认订单。
        </p>
      </div>
    </section>

    <section class="ordering-layout">
      <aside class="category-panel">
        <button
          v-for="category in categories"
          :key="category"
          class="category-button"
          :class="{ active: activeCategory === category }"
          type="button"
          @click="activeCategory = category"
        >
          {{ category }}
        </button>
      </aside>

      <section class="dish-panel" aria-label="菜单列表">
        <div class="panel-title">
          <div>
            <p class="eyebrow">推荐菜单</p>
            <h2>{{ activeCategory }}</h2>
          </div>
          <span>{{ filteredDishes.length }} 道菜</span>
        </div>

        <div class="dish-grid">
          <article
            v-for="dish in filteredDishes"
            :key="dish.id"
            class="dish-card"
          >
            <div class="dish-cover">
              <img
                v-lazy-image="dish.imageUrl"
                :alt="dish.name"
                decoding="async"
              />
              <span v-if="dish.tag">{{ dish.tag }}</span>
            </div>
            <div class="dish-content">
              <div class="dish-heading">
                <h3>{{ dish.name }}</h3>
                <strong>￥{{ dish.price }}</strong>
              </div>
              <p>{{ dish.desc }}</p>
              <div class="dish-footer">
                <span>{{ dish.sales }} 人点过</span>
                <button type="button" @click="addDish(dish)">加入</button>
              </div>
            </div>
          </article>
        </div>
      </section>

      <aside class="cart-panel">
        <div class="panel-title">
          <div>
            <p class="eyebrow">当前订单</p>
            <h2>已选菜品</h2>
          </div>
          <button
            v-if="cartItems.length"
            class="text-button"
            type="button"
            @click="clearCart"
          >
            清空
          </button>
        </div>

        <div v-if="cartItems.length" class="cart-list">
          <div v-for="item in cartItems" :key="item.id" class="cart-item">
            <div>
              <strong>{{ item.name }}</strong>
              <span>￥{{ item.price }} / 份</span>
            </div>
            <div class="quantity-control">
              <button type="button" @click="decreaseDish(item.id)">-</button>
              <span>{{ item.quantity }}</span>
              <button type="button" @click="increaseDish(item.id)">+</button>
            </div>
          </div>
        </div>

        <div v-else class="empty-cart">
          <strong>还没有选菜</strong>
          <span>从左侧菜单加入喜欢的菜品。</span>
        </div>

        <div class="order-summary">
          <div>
            <span>菜品数量</span>
            <strong>{{ totalCount }} 份</strong>
          </div>
          <div>
            <span>合计金额</span>
            <strong>￥{{ totalPrice }}</strong>
          </div>
          <button
            class="submit-button"
            type="button"
            :disabled="!cartItems.length || isSubmitting"
            @click="submitOrder"
          >
            提交订单
          </button>
        </div>
      </aside>
    </section>

    <div class="mobile-cart-bar">
      <button
        class="mobile-cart-info"
        type="button"
        @click="mobileCartOpen = true"
      >
        <span class="mobile-cart-icon">{{ totalCount }}</span>
        <span>
          <small>已选 {{ totalCount }} 份</small>
          <strong>￥{{ totalPrice }}</strong>
        </span>
      </button>
      <button
        class="mobile-submit-button"
        type="button"
        :disabled="!cartItems.length || isSubmitting"
        @click="submitOrder"
      >
        提交订单
      </button>
    </div>

    <div
      v-if="mobileCartOpen"
      class="mobile-cart-mask"
      @click.self="mobileCartOpen = false"
    >
      <section class="mobile-cart-sheet">
        <div class="mobile-cart-sheet-title">
          <h2>已选菜品</h2>
          <button type="button" @click="mobileCartOpen = false">关闭</button>
        </div>
        <div v-if="cartItems.length" class="mobile-cart-list">
          <div v-for="item in cartItems" :key="item.id" class="cart-item">
            <div>
              <strong>{{ item.name }}</strong>
              <span>￥{{ item.price }} / 份</span>
            </div>
            <div class="quantity-control">
              <button type="button" @click="decreaseDish(item.id)">-</button>
              <span>{{ item.quantity }}</span>
              <button type="button" @click="increaseDish(item.id)">+</button>
            </div>
          </div>
        </div>
        <div v-else class="empty-cart mobile-empty-cart">
          <strong>还没有选菜</strong>
          <span>先去菜单里挑几道吧。</span>
        </div>
        <div class="mobile-cart-sheet-footer">
          <strong>合计：￥{{ totalPrice }}</strong>
          <button
            class="submit-button"
            type="button"
            :disabled="!cartItems.length || isSubmitting"
            @click="submitOrder"
          >
            提交订单
          </button>
        </div>
      </section>
    </div>

    <div v-if="isSubmitting" class="submit-loading-mask">
      <div class="submit-loading-card">
        <span class="submit-loading-spinner"></span>
        <strong>正在提交订单</strong>
        <small>美味订单正在飞往厨房，请稍等一下～</small>
      </div>
    </div>
  </main>
</template>

<script setup>
import { computed, ref, onMounted } from "vue";
import emailjs from "@emailjs/browser";
import { ElMessage } from "element-plus";
import menuData from "../data/menu.json";

const dishImages = import.meta.glob("../assets/images/*", {
  eager: true,
  query: "?url",
  import: "default",
});

const categories = menuData.categories;
const dishes = menuData.dishes.map((dish) => ({
  ...dish,
  imageUrl: dishImages[`../assets/images/${dish.image}`],
}));

const lazyImageObservers = new WeakMap();

const observeLazyImage = (el, imageUrl) => {
  lazyImageObservers.get(el)?.disconnect();
  lazyImageObservers.delete(el);

  if (!imageUrl) return;

  if (!("IntersectionObserver" in window)) {
    el.src = imageUrl;
    return;
  }

  el.removeAttribute("src");
  const observer = new IntersectionObserver(
    ([entry]) => {
      if (!entry.isIntersecting) return;
      el.src = imageUrl;
      observer.disconnect();
      lazyImageObservers.delete(el);
    },
    { rootMargin: "120px 0px", threshold: 0.01 },
  );

  lazyImageObservers.set(el, observer);
  observer.observe(el);
};

const vLazyImage = {
  mounted(el, binding) {
    observeLazyImage(el, binding.value);
  },
  updated(el, binding) {
    if (binding.value !== binding.oldValue) {
      observeLazyImage(el, binding.value);
    }
  },
  unmounted(el) {
    lazyImageObservers.get(el)?.disconnect();
    lazyImageObservers.delete(el);
  },
};

const activeCategory = ref(categories[0]);
const cart = ref([]);
const mobileCartOpen = ref(false);
const isSubmitting = ref(false);

const getNowTime = () => {
  const now = new Date();

  const time =
    now.getFullYear() +
    "-" +
    String(now.getMonth() + 1).padStart(2, "0") +
    "-" +
    String(now.getDate()).padStart(2, "0") +
    " " +
    String(now.getHours()).padStart(2, "0") +
    ":" +
    String(now.getMinutes()).padStart(2, "0") +
    ":" +
    String(now.getSeconds()).padStart(2, "0");
  return time;
};
const filteredDishes = computed(() =>
  dishes.filter((dish) => dish.category === activeCategory.value),
);

const cartItems = computed(() =>
  cart.value.map((item) => ({
    ...dishes.find((dish) => dish.id === item.id),
    quantity: item.quantity,
  })),
);

const totalCount = computed(() =>
  cart.value.reduce((total, item) => total + item.quantity, 0),
);

const totalPrice = computed(() =>
  cartItems.value.reduce(
    (total, item) => total + item.price * item.quantity,
    0,
  ),
);

const addDish = (dish) => {
  const current = cart.value.find((item) => item.id === dish.id);

  if (current) {
    current.quantity += 1;
    return;
  }

  cart.value.push({ id: dish.id, quantity: 1 });
};

const increaseDish = (id) => {
  const current = cart.value.find((item) => item.id === id);
  if (current) current.quantity += 1;
};

const decreaseDish = (id) => {
  const current = cart.value.find((item) => item.id === id);
  if (!current) return;

  if (current.quantity === 1) {
    cart.value = cart.value.filter((item) => item.id !== id);
    return;
  }

  current.quantity -= 1;
};

const clearCart = () => {
  cart.value = [];
};

const submitOrder = async () => {
  if (!cartItems.value.length || isSubmitting.value) return "";

  const menuLines = cartItems.value
    .map((item, index) => `${index + 1}. ${item.name} × ${item.quantity} 份`)
    .join("\n");

  const orderText1 = [
    "🌷 亲爱的闫茹女士：",
    "",
    "您的小饭桌订单已经成功提交啦～",
    "厨房正在认真准备每一道菜，请稍等片刻呀！",
    "",
    "🍽️ 今日菜单",
    "————————————",
    menuLines,
    "————————————",
    "",
    "📋 订单小计",
    `共计：${totalCount.value} 份`,
    `合计：￥${totalPrice.value}`,
    "",
    "⏰ 温馨提示",
    "美味正在向您奔来，请耐心等候，稍后为您送达～",
    "愿这一餐热气腾腾，也愿您今天有个好心情！✨",
    "",
  ].join("\n");

  isSubmitting.value = true;
  try {
    await sentEmail(menuLines, "tyq");
    // await sentEmail(orderText1, "yr");
    clearCart();
    mobileCartOpen.value = false;
    ElMessage.success("订单提交成功，请耐心等待美味送达～");
  } catch (error) {
    ElMessage.error("订单提交失败，请稍后再试");
  } finally {
    isSubmitting.value = false;
  }

  return orderText1;
};

const sentEmail = (message, name) => {
  let template = name == "tyq" ? "template_o73uu26" : "template_6phm208";
  return emailjs.send(
    "service_vgfwo7x", // 唐雨强的qq授权id
    // "service_geuaxkt", // 闫茹的163授权id
    template, // 发给唐
    // "template_6phm208", // 发给闫
    {
      message: message.replace(/\n/g, "<br />"),
      time: getNowTime(),
    },
    "-IRUQuTGQ8XFTDZav", // PUBLIC_KEY
  );
};
</script>

<style scoped lang="scss">
.menu-page {
  display: flex;
  flex-direction: column;
  height: 100vh;
  box-sizing: border-box;
  overflow: hidden;
  padding: 28px;
  color: #1f2933;
  background: linear-gradient(
    135deg,
    rgba(255, 247, 237, 0.92),
    rgba(236, 253, 245, 0.88)
  );
  background-size: cover;
  background-position: center;
  font-family: "Microsoft YaHei", "PingFang SC", Arial, sans-serif;
}

.hero {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  max-width: 1280px;
  margin: 0 auto 22px;
  gap: 20px;

  h1 {
    margin: 6px 0 8px;
    font-size: 42px;
    line-height: 1.1;
    color: #111827;
  }
}

.eyebrow {
  margin: 0;
  color: #b45309;
  font-size: 13px;
  font-weight: 700;
}

.subtitle {
  margin: 0;
  max-width: 520px;
  color: #4b5563;
  font-size: 16px;
}

.table-badge {
  display: grid;
  place-items: center;
  width: 96px;
  height: 96px;
  border-radius: 8px;
  background: #111827;
  color: #fff;
  box-shadow: 0 14px 40px rgba(17, 24, 39, 0.2);

  span {
    color: #fde68a;
    font-size: 13px;
  }

  strong {
    font-size: 30px;
  }
}

.ordering-layout {
  display: grid;
  grid-template-columns: 156px minmax(0, 1fr) 360px;
  grid-template-rows: minmax(0, 1fr);
  flex: 1;
  min-height: 0;
  width: 100%;
  gap: 18px;
  max-width: 1280px;
  margin: 0 auto;
  align-items: stretch;
}

.category-panel,
.dish-panel,
.cart-panel {
  border: 1px solid rgba(17, 24, 39, 0.1);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.9);
  box-shadow: 0 18px 50px rgba(17, 24, 39, 0.12);
  backdrop-filter: blur(12px);
}

.category-panel {
  display: grid;
  gap: 10px;
  padding: 12px;
  position: sticky;
  top: 24px;
}

.category-button,
.dish-footer button,
.quantity-control button,
.submit-button,
.text-button {
  border: 0;
  cursor: pointer;
  font-family: inherit;
}

.category-button {
  min-height: 48px;
  border-radius: 6px;
  color: #374151;
  background: #f3f4f6;
  font-weight: 700;
  transition: 0.2s ease;

  &.active,
  &:hover {
    color: #fff;
    background: #b45309;
  }
}

.dish-panel,
.cart-panel {
  padding: 18px;
}

.dish-panel {
  display: flex;
  flex-direction: column;
  min-height: 0;
  overflow: hidden;
  background: #f3f4f6;
}

.panel-title {
  display: flex;
  flex-shrink: 0;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
  margin-bottom: 16px;

  h2 {
    margin: 4px 0 0;
    font-size: 24px;
    color: #111827;
  }

  > span {
    color: #6b7280;
    font-size: 14px;
  }
}

.dish-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  grid-auto-rows: 300px;
  flex: 1;
  align-content: start;
  min-height: 0;
  overflow-y: auto;
  padding-right: 4px;
  gap: 14px;

  &::-webkit-scrollbar {
    width: 8px;
  }

  &::-webkit-scrollbar-track {
    border-radius: 999px;
    background: #f3f4f6;
  }

  &::-webkit-scrollbar-thumb {
    border-radius: 999px;
    background: #d1a46f;
  }
}

.dish-card {
  height: 300px;
  box-sizing: border-box;
  overflow: hidden;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  background: #fff;
}

.dish-cover {
  position: relative;
  height: 150px;
  box-sizing: border-box;
  overflow: hidden;

  img {
    display: block;
    width: 100%;
    height: 100%;
    object-fit: cover;
  }

  span {
    position: absolute;
    top: 10px;
    right: 10px;
    padding: 5px 9px;
    border-radius: 999px;
    color: #fff;
    background: rgba(17, 24, 39, 0.74);
    font-size: 12px;
  }
}

.dish-content {
  padding: 13px;

  p {
    min-height: 42px;
    margin: 8px 0 16px;
    color: #6b7280;
    font-size: 14px;
    line-height: 1.5;
  }
}

.dish-heading,
.dish-footer,
.cart-item,
.order-summary > div {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.dish-heading {
  h3 {
    margin: 0;
    font-size: 18px;
    color: #111827;
  }

  strong {
    color: #b45309;
    font-size: 18px;
  }
}

.dish-footer {
  span {
    color: #9ca3af;
    font-size: 13px;
  }

  button {
    min-width: 66px;
    height: 34px;
    border-radius: 6px;
    color: #fff;
    background: #166534;
    font-weight: 700;
  }
}

.text-button {
  color: #b45309;
  background: transparent;
  font-weight: 700;
}

.cart-list {
  display: grid;
  gap: 12px;
  max-height: 390px;
  overflow: auto;
  padding-right: 4px;
}

.cart-item {
  padding-bottom: 12px;
  border-bottom: 1px solid #e5e7eb;

  div:first-child {
    display: grid;
    gap: 5px;
  }

  strong {
    color: #111827;
  }

  span {
    color: #6b7280;
    font-size: 13px;
  }
}

.quantity-control {
  display: grid;
  grid-template-columns: 30px 30px 30px;
  align-items: center;
  overflow: hidden;
  border: 1px solid #d1d5db;
  border-radius: 6px;

  button {
    height: 30px;
    color: #374151;
    background: #f9fafb;
    font-size: 18px;
  }

  span {
    text-align: center;
    color: #111827;
    font-weight: 700;
  }
}

.empty-cart {
  display: grid;
  place-items: center;
  min-height: 180px;
  border: 1px dashed #d1d5db;
  border-radius: 8px;
  color: #6b7280;
  text-align: center;

  strong {
    color: #111827;
  }
}

.order-summary {
  display: grid;
  gap: 12px;
  margin-top: 18px;
  padding-top: 16px;
  border-top: 1px solid #e5e7eb;

  span {
    color: #6b7280;
  }

  strong {
    color: #111827;
    font-size: 20px;
  }
}

.submit-button {
  height: 46px;
  border-radius: 6px;
  color: #fff;
  background: #b45309;
  font-size: 16px;
  font-weight: 800;

  &:disabled {
    cursor: not-allowed;
    background: #d1d5db;
  }
}

.submit-loading-mask {
  display: grid;
  place-items: center;
  position: fixed;
  z-index: 100;
  inset: 0;
  padding: 20px;
  background: rgba(17, 24, 39, 0.46);
  backdrop-filter: blur(4px);
}

.submit-loading-card {
  display: grid;
  place-items: center;
  gap: 10px;
  width: min(300px, 82vw);
  padding: 28px 22px;
  box-sizing: border-box;
  border-radius: 16px;
  background: #fff;
  box-shadow: 0 20px 50px rgba(17, 24, 39, 0.28);
  text-align: center;

  strong {
    color: #111827;
    font-size: 19px;
  }

  small {
    color: #6b7280;
    line-height: 1.5;
  }
}

.submit-loading-spinner {
  width: 34px;
  height: 34px;
  border: 4px solid #fde7cc;
  border-top-color: #b45309;
  border-radius: 50%;
  animation: submit-loading-spin 0.8s linear infinite;
}

@keyframes submit-loading-spin {
  to {
    transform: rotate(360deg);
  }
}

.mobile-cart-bar,
.mobile-cart-mask {
  display: none;
}

@media (max-width: 1100px) {
  .ordering-layout {
    grid-template-columns: 132px minmax(0, 1fr) 300px;
  }

  .cart-panel {
    grid-column: auto;
  }
}

@media (max-width: 760px) {
  .menu-page {
    height: 100dvh;
    padding: 12px 12px 76px;
  }

  .hero {
    align-items: flex-start;
    flex-direction: column;
    flex-shrink: 0;
    margin-bottom: 10px;
    gap: 4px;

    h1 {
      margin: 3px 0 4px;
      font-size: 27px;
    }
  }

  .subtitle {
    font-size: 13px;
    line-height: 1.5;
  }

  .table-badge {
    display: none;
  }

  .ordering-layout {
    grid-template-columns: 1fr;
    grid-template-rows: auto minmax(0, 1fr);
    gap: 8px;
    min-height: 0;
  }

  .category-panel {
    display: flex;
    gap: 6px;
    padding: 6px;
    overflow-x: auto;
    position: static;

    &::-webkit-scrollbar {
      display: none;
    }
  }

  .category-button {
    flex: 0 0 auto;
    min-height: 40px;
    padding: 0 15px;
  }

  .dish-panel {
    padding: 12px;
  }

  .panel-title {
    margin-bottom: 10px;

    h2 {
      margin-top: 2px;
      font-size: 21px;
    }
  }

  .dish-grid {
    grid-template-columns: 1fr;
    grid-auto-rows: 140px;
    gap: 10px;
    padding-right: 2px;
  }

  .dish-card {
    display: grid;
    grid-template-columns: 112px minmax(0, 1fr);
    height: 140px;
  }

  .dish-cover {
    height: 100%;

    span {
      top: 6px;
      right: 6px;
    }
  }

  .dish-content {
    display: flex;
    flex-direction: column;
    min-width: 0;
    padding: 12px;

    p {
      display: none;
    }
  }

  .dish-heading {
    align-items: flex-start;

    h3 {
      overflow: hidden;
      font-size: 16px;
      white-space: nowrap;
      text-overflow: ellipsis;
    }

    strong {
      flex-shrink: 0;
      font-size: 16px;
    }
  }

  .dish-footer {
    margin-top: auto;

    button {
      min-width: 56px;
      height: 32px;
    }
  }

  .cart-panel {
    display: none;
  }

  .mobile-cart-bar {
    display: flex;
    align-items: center;
    position: fixed;
    z-index: 20;
    right: 12px;
    bottom: 10px;
    left: 12px;
    height: 56px;
    overflow: hidden;
    border-radius: 14px;
    background: #111827;
    box-shadow: 0 10px 30px rgba(17, 24, 39, 0.28);
  }

  .mobile-cart-info,
  .mobile-submit-button,
  .mobile-cart-sheet button {
    border: 0;
    font-family: inherit;
  }

  .mobile-cart-info {
    display: flex;
    align-items: center;
    flex: 1;
    gap: 10px;
    height: 100%;
    padding: 0 14px;
    color: #fff;
    background: transparent;
    text-align: left;

    > span:last-child {
      display: grid;
      gap: 2px;
    }

    small {
      color: #d1d5db;
    }

    strong {
      font-size: 18px;
    }
  }

  .mobile-cart-icon {
    display: grid;
    place-items: center;
    width: 34px;
    height: 34px;
    border-radius: 50%;
    color: #fff;
    background: #b45309;
    font-weight: 800;
  }

  .mobile-submit-button {
    align-self: stretch;
    min-width: 112px;
    color: #fff;
    background: #b45309;
    font-size: 15px;
    font-weight: 800;

    &:disabled {
      color: #9ca3af;
      background: #374151;
    }
  }

  .mobile-cart-mask {
    display: flex;
    align-items: flex-end;
    position: fixed;
    z-index: 30;
    inset: 0;
    background: rgba(17, 24, 39, 0.42);
  }

  .mobile-cart-sheet {
    width: 100%;
    max-height: 72dvh;
    padding: 18px 16px calc(18px + env(safe-area-inset-bottom));
    box-sizing: border-box;
    border-radius: 20px 20px 0 0;
    background: #fff;
  }

  .mobile-cart-sheet-title,
  .mobile-cart-sheet-footer {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 12px;
  }

  .mobile-cart-sheet-title {
    margin-bottom: 16px;

    h2 {
      font-size: 22px;
    }

    button {
      padding: 6px 0 6px 12px;
      color: #b45309;
      background: transparent;
      font-weight: 700;
    }
  }

  .mobile-cart-list {
    display: grid;
    gap: 12px;
    max-height: 45dvh;
    overflow-y: auto;
  }

  .mobile-empty-cart {
    min-height: 150px;
  }

  .mobile-cart-sheet-footer {
    margin-top: 16px;
    padding-top: 14px;
    border-top: 1px solid #e5e7eb;

    > strong {
      font-size: 20px;
    }

    .submit-button {
      min-width: 130px;
      padding: 0 16px;
    }
  }
}
</style>
