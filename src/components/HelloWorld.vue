<template>
  <div class="dashboard-container">
    <!-- 顶部标题栏 -->
    <header class="header">
      <div class="header-left">
        <h2>无人机任务调度指挥中心</h2>
      </div>
      <div class="header-right">
        <span class="refresh-time">数据更新时间：2026-04-19 13:11</span>
        <button class="btn">报表下载</button>
        <button class="btn btn-primary">综合看板管理</button>
      </div>
    </header>

    <!-- 第一行：关键指标卡片 -->
    <section class="grid-row row-1">
      <div
        class="card stat-card"
        v-for="(item, index) in statData"
        :key="index"
      >
        <div class="stat-icon">
          <i :class="item.icon"></i>
        </div>
        <div class="stat-content">
          <div class="stat-value">{{ item.value }}</div>
          <div class="stat-label">{{ item.label }}</div>
        </div>
      </div>
    </section>

    <!-- 第二行：趋势图与类型分布 -->
    <section class="grid-row row-2">
      <!-- 左侧：任务执行率趋势 -->
      <div class="card chart-card half-width">
        <div class="card-header">
          <span class="card-header-title">近一年任务执行率趋势</span>
        </div>
        <div ref="trendChartRef" class="chart-body"></div>
      </div>

      <!-- 右侧：报批任务类型 -->
      <div class="card chart-card half-width">
        <div class="card-header">
          <span class="card-header-title">近一年报批任务类型</span>
        </div>
        <div ref="typeChartRef" class="chart-body"></div>
      </div>
    </section>

    <!-- 第三行：无人机类型与飞行频次 -->
    <section class="grid-row row-3">
      <!-- 左侧：无人机类型占比 -->
      <div class="card chart-card half-width">
        <div class="card-header">
          <span class="card-header-title">近一年无人机类型占比</span>
        </div>
        <div ref="droneTypeChartRef" class="chart-body"></div>
      </div>

      <!-- 右侧：单位飞行频次排行 -->
      <div class="card chart-card half-width">
        <div class="card-header">
          <span class="card-header-title">近一年单位飞行频次排行</span>
        </div>
        <div ref="barChartRef" class="chart-body"></div>
      </div>
    </section>

    <!-- 第四行：底部列表排行 -->
    <section class="grid-row row-4">
      <div class="card list-card third-width">
        <div class="card-header">
          <span class="card-header-title">近一年任务执行率区县排行</span>
        </div>
        <div class="list-body">
          <div v-for="i in 5" :key="i" class="list-item">
            <div class="rank-info">
              <span class="rank-num">{{ i }}</span>
              <span class="name">区县名称 {{ toChineseNum(i) }}</span>
            </div>
            <el-progress
              :percentage="50"
              :stroke-width="12"
              style="flex: 1"
              class="custom-progress"
            />
          </div>
        </div>
      </div>

      <div class="card list-card third-width">
        <div class="card-header">
          <span class="card-header-title">近一年任务执行率飞行单位排行</span>
        </div>
        <div class="list-body">
          <div v-for="i in 5" :key="i" class="list-item">
            <div class="rank-info">
              <span class="rank-num">{{ i }}</span>
              <span class="name">飞行单位名称 {{ i }}</span>
            </div>
            <el-progress
              :percentage="50"
              :stroke-width="12"
              style="flex: 1"
              class="custom-progress"
            />
          </div>
        </div>
      </div>

      <div class="card list-card third-width">
        <div class="card-header">
          <span class="card-header-title"
            >近一年任务执行率飞行单位负向排行</span
          >
        </div>
        <div class="list-body">
          <div v-for="i in 5" :key="i" class="list-item">
            <div class="rank-info">
              <span class="rank-num">{{ i }}</span>
              <span class="name">飞行单位名称 {{ i }}</span>
            </div>
            <el-progress
              :percentage="50"
              :stroke-width="12"
              style="flex: 1"
              class="custom-progress"
            />
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from "vue";
import * as echarts from "echarts";

// --- 顶部统计数据 ---
const statData = [
  { label: "近一年年均上报计划数", value: "14,028", icon: "icon-upload" },
  { label: "近一年执行计划数量", value: "3,652", icon: "icon-play" },
  { label: "近一年延误计划数量", value: "567", icon: "icon-delay" },
  { label: "近一年取消计划数量", value: "642", icon: "icon-cancel" },
];

// --- 图表引用 ---
const trendChartRef = ref(null);
const typeChartRef = ref(null);
const droneTypeChartRef = ref(null);
const barChartRef = ref(null);

let trendChart, typeChart, droneTypeChart, barChart;

// --- 辅助函数：数字转中文 ---
const toChineseNum = (num) => {
  const arr = ["一", "二", "三", "四", "五"];
  return arr[num - 1];
};

const customColorMethod = (percentage) => {
  // 这里可以写死，也可以根据百分比变化
  return "linear-gradient(90deg, #00DBFF 0%, #0083C2 100%)";
};

// --- 模拟数据：无人机图例 ---
const droneLegend = [
  { name: "微型", percent: "6%", color: "#5470C6" },
  { name: "轻型", percent: "9%", color: "#91CC75" },
  { name: "小型", percent: "14%", color: "#FAC858" },
  { name: "中型", percent: "11%", color: "#EE6666" },
  { name: "大型", percent: "13%", color: "#73C0DE" },
];

// --- 初始化图表 ---
const initCharts = () => {
  // 1. 趋势图 (Line)
  trendChart = echarts.init(trendChartRef.value);
  const trendOption = {
    tooltip: { trigger: "axis" },
    grid: { left: "3%", right: "4%", bottom: "3%", containLabel: true },
    xAxis: {
      type: "category",
      boundaryGap: false,
      data: [
        "1月",
        "2月",
        "3月",
        "4月",
        "5月",
        "6月",
        "7月",
        "8月",
        "9月",
        "10月",
        "11月",
        "12月",
      ],
      axisLine: { lineStyle: { color: "#406A80" } },
      axisLabel: { color: "#AABCCD" },
    },
    yAxis: {
      type: "value",
      axisLine: { show: false },
      splitLine: { lineStyle: { color: "#1C2E40", type: "dashed" } },
      axisLabel: { color: "#AABCCD" },
    },
    series: [
      {
        name: "执行率",
        type: "line",
        smooth: true,
        symbol: "circle",
        symbolSize: 6,
        itemStyle: { color: "#33C3F0" },
        lineStyle: { color: "#33C3F0", width: 2 },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: "rgba(51, 195, 240, 0.4)" },
            { offset: 1, color: "rgba(51, 195, 240, 0)" },
          ]),
        },
        data: [55, 60, 65, 63, 68, 70, 75, 72, 60, 65, 62, 60],
      },
    ],
  };
  trendChart.setOption(trendOption);

  // 2. 环形图 (Pie) - 任务类型
  typeChart = echarts.init(typeChartRef.value);
  const typeOption = {
    tooltip: { trigger: "item" },
    legend: {
      right: "10%",
      top: "center",
      orient: "vertical",
      itemGap: 15,
      textStyle: { color: "#fff", fontSize: 12 },
    },
    series: [
      {
        name: "任务类型",
        type: "pie",
        radius: ["40%", "60%"],
        center: ["35%", "50%"],
        avoidLabelOverlap: false,
        label: { show: false },
        emphasis: { label: { show: true, fontSize: "14", fontWeight: "bold" } },
        labelLine: { show: false },
        data: [
          { value: 5, name: "个人娱乐", itemStyle: { color: "#FAC858" } },
          { value: 11, name: "植保", itemStyle: { color: "#91CC75" } },
          { value: 14, name: "科学实验", itemStyle: { color: "#5470C6" } },
          { value: 12, name: "空中巡查", itemStyle: { color: "#73C0DE" } },
          { value: 16, name: "电力作业", itemStyle: { color: "#EE6666" } },
          { value: 13, name: "应急救援", itemStyle: { color: "#3BA272" } },
          { value: 9, name: "集群表演", itemStyle: { color: "#FC8452" } },
          { value: 13, name: "其他", itemStyle: { color: "#9A60B4" } },
        ],
      },
    ],
  };
  typeChart.setOption(typeOption);

  // 3. 半圆环 + 列表 (Drone Type)
  // 这里为了简化，ECharts部分只做一个简单的半圆环或者小饼图，列表用HTML写
  droneTypeChart = echarts.init(droneTypeChartRef.value);
  const droneOption = {
    tooltip: { trigger: "item" },
    legend: {
      right: "10%",
      top: "center",
      orient: "vertical",
      itemGap: 15,
      textStyle: { color: "#fff", fontSize: 12 },
    },
    series: [
      {
        name: "测试类型",
        type: "pie",
        radius: ["60%", "80%"],
        silent: false,
        avoidLabelOverlap: false,
        label: { show: false },
        emphasis: { label: { show: true, fontSize: "14", fontWeight: "bold" } },
        labelLine: { show: false },
        data: droneLegend.map((item) => ({
          value: parseInt(item.percent),
          name: item.name,
          itemStyle: { color: item.color },
        })),
      },
    ],
  };
  droneTypeChart.setOption(droneOption);

  // 4. 柱状图 (Bar) - 飞行频次
  barChart = echarts.init(barChartRef.value);
  const barOption = {
    tooltip: {
      trigger: "axis",
      axisPointer: { type: "shadow" },
    },
    grid: {
      left: "3%",
      right: "4%",
      bottom: "10%", // 留出一点底部空间
      top: "10%",
      containLabel: true,
    },
    // 1. Y轴：显示数值，开启分割线（对应图中的横线）
    yAxis: {
      type: "value",
      axisLine: { show: false },
      axisTick: { show: false },
      axisLabel: { color: "#fff" },
      splitLine: {
        // 图中有淡淡的横向网格线
        lineStyle: {
          color: "rgba(255, 255, 255, 0.1)",
          type: "dashed", // 图中看起来像虚线或细实线，这里设为虚线更美观
        },
      },
    },
    // 2. X轴：显示类别名称
    xAxis: {
      type: "category",
      // 数据顺序调整为从高到低，与图片一致
      data: [
        "飞行单位1",
        "飞行单位2",
        "飞行单位3",
        "飞行单位4",
        "飞行单位5",
        "飞行单位6",
      ],
      axisTick: { show: false },
      axisLine: {
        show: true,
        lineStyle: { color: "rgba(255, 255, 255, 0.1)" },
      },
      axisLabel: { color: "#fff" },
    },
    series: [
      {
        name: "频次",
        type: "bar",
        barWidth: "20%", // 调整柱子宽度
        itemStyle: {
          // 3. 圆角调整到顶部（左上、右上）
          borderRadius: [10, 10, 0, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: "#33C3F0" }, // 顶部颜色
            { offset: 1, color: "#1C2E40" }, // 底部颜色
          ]),
        },
        label: {
          show: true,
          position: "top",
          color: "#fff",
          fontSize: 12,
        },
        data: [9420, 7140, 6816, 6408, 5316, 3924],
      },
    ],
  };
  barChart.setOption(barOption);
};

// --- 自适应处理 ---
const handleResize = () => {
  trendChart?.resize();
  typeChart?.resize();
  droneTypeChart?.resize();
  barChart?.resize();
};

onMounted(() => {
  initCharts();
  window.addEventListener("resize", handleResize);
});

onBeforeUnmount(() => {
  window.removeEventListener("resize", handleResize);
});
</script>

<style scoped lang="scss">
/* --- 基础变量 --- */
:root {
  --bg-color: #06152b;
  --card-bg: rgba(11, 34, 61, 0.6);
  --primary-color: #00d8ff;
  --text-color: #fff;
  --border-color: #1c2e40;
}

/* --- 布局容器 --- */
.dashboard-container {
  width: 100vw;
  height: 100vh;
  background-color: var(--bg-color);
  /* 背景图可以换成你喜欢的科技风底图 */
  background-image: radial-gradient(
    circle at 50% 50%,
    #102a43 0%,
    #06152b 100%
  );
  color: var(--text-color);
  font-family: "Microsoft YaHei", sans-serif;
  padding: 20px;
  box-sizing: border-box;
  display: flex;
  flex-direction: column;
  gap: 20px;
  overflow: hidden;
}

/* --- 头部 --- */
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0 20px;
  /* 简单的下边框装饰 */
  border-bottom: 2px solid var(--primary-color);
  margin-bottom: 10px;
}
.header h2 {
  margin: 0;
  font-weight: normal;
  letter-spacing: 2px;
  color: var(--primary-color);
  text-shadow: 0 0 10px var(--primary-color);
}
.header-right {
  display: flex;
  align-items: center;
  gap: 15px;
  font-size: 14px;
  color: #aabccd;
}
.btn {
  background: transparent;
  border: 1px solid var(--primary-color);
  color: var(--primary-color);
  padding: 5px 15px;
  cursor: pointer;
  font-size: 12px;
  transition: all 0.3s;
}
.btn-primary {
  background: var(--primary-color);
  color: #000;
  font-weight: bold;
}
.btn:hover {
  background: rgba(0, 216, 255, 0.2);
}

/* --- 网格布局系统 --- */
.grid-row {
  display: flex;
  gap: 20px;
  width: 100%;
}
.half-width {
  flex: 1;
}
.third-width {
  flex: 1;
}
.row-1 {
  flex: 0 0 auto;
} /* 固定高度 */
.row-2,
.row-3 {
  flex: 1;
  min-height: 0;
} /* 自动填充高度 */
.row-4 {
  flex: 0 0 200px;
} /* 底部固定高度 */

/* --- 卡片通用样式 --- */
.card {
  background: var(--card-bg);
  border: 1px solid var(--border-color);
  border-radius: 4px;
  position: relative;
  /* 边角装饰效果 (模拟截图的切角) */
  box-shadow: inset 0 0 20px rgba(0, 216, 255, 0.1);
  display: flex;
  flex-direction: column;
  padding: 15px;
}
/* 简单的四角边框装饰 */
.card::before {
  content: "";
  position: absolute;
  top: 0;
  left: 0;
  width: 10px;
  height: 10px;
  border-top: 2px solid var(--primary-color);
  border-left: 2px solid var(--primary-color);
}
.card::after {
  content: "";
  position: absolute;
  bottom: 0;
  right: 0;
  width: 10px;
  height: 10px;
  border-bottom: 2px solid var(--primary-color);
  border-right: 2px solid var(--primary-color);
}

.card-header {
  display: flex;
  text-align: center;
  justify-content: center;
  align-items: center;
  margin-bottom: 15px;
  padding-left: 10px;
  border-left: 4px solid var(--primary-color);
  .card-header-title {
    font-size: 18px;
    font-weight: bold;
    color: #fff;
    text-align: center;
    /* 1. 文字渐变：从淡蓝到亮青 */
    background: linear-gradient(
      to right,
      #4facfe 0%,
      #00f2fe 50%,
      #4facfe 100%
    );
    background-size: 200% 100%;
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    /* 2. 加上一点阴影，让字浮起来 */
    filter: drop-shadow(0 0 5px rgba(79, 172, 254, 0.5));
    /* 3. 动画：让光泽流动 */
    animation: shine 3s infinite linear;
  }
}

.chart-body {
  flex: 1;
  width: 100%;
  position: relative;
}
.flex-center {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
}

/* --- 统计卡片 (第一行) --- */
.stat-card {
  flex: 1;
  flex-direction: row;
  align-items: center;
  padding: 20px;
  background: linear-gradient(
    90deg,
    rgba(11, 34, 61, 0.8) 0%,
    rgba(16, 42, 67, 0.8) 100%
  );
}
.stat-icon {
  font-size: 40px;
  margin-right: 20px;
  color: var(--primary-color);
  opacity: 0.8;
}
.stat-content {
  display: flex;
  flex-direction: column;
}
.stat-value {
  font-size: 32px;
  font-weight: bold;
  font-family: "Arial";
  margin-bottom: 5px;
}
.stat-label {
  font-size: 14px;
  color: #aabccd;
}

/* --- 列表样式 (底部) --- */
.list-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
  padding: 0 20px;
}
.list-item {
  display: flex;
  align-items: center;
  font-size: 14px;
  gap: 10px;
  display: flex;
}
.rank-info {
  flex: 0.2;
}
.rank-num {
  width: 20px;
  text-align: center;
  color: #fff;
  font-weight: bold;
}
.name {
  width: 120px;
  color: #aabccd;
}

/* --- 图表图例模拟 --- */
.chart-legend {
  display: flex;
  flex-direction: column;
  gap: 8px;
  font-size: 12px;
  color: #aabccd;
}
.legend-item {
  display: flex;
  align-items: center;
  gap: 5px;
}
.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  display: inline-block;
}

/* 修改轨道背景颜色 (未完成的灰色部分) */
.custom-progress :deep(.el-progress-bar__outer) {
  background-color: transparent; /* 先清空默认背景 */
  /* 设置你想要的轨道渐变：从左边的半透明白 到 右边的深色 */
  background-image: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.1) 0%,
    rgba(0, 0, 0, 0.2) 100%
  );
  border-radius: 6px;
  border: none;
}
</style>
