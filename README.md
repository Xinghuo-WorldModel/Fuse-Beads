<p align="center">
  <img src="assets/icon.png" width="120" alt="酥豆 Logo">
</p>

<h1 align="center">酥豆 Fuse Beads</h1>

<p align="center">
  <strong>一张照片，变成一颗颗拼豆</strong><br>
  把你喜欢的人像、风景、宠物照片转换为可直接制作的拼豆图案
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter" alt="Flutter">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Web%20%7C%20Windows-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-blue" alt="License">
</p>

---

## 它能做什么

| 像素风格 | 写实风格 |
|---------|---------|
| 将照片转为复古像素艺术，再映射到拼豆色板 | 直接将照片颜色匹配到最接近的拼豆颜色，保留更多细节 |

- 支持 **7 大主流品牌** 色板（Perler、Hama、Artkal、MARD、Yant、Nabbi、Artkal-R）
- 自定义网格尺寸，从 29×29 小挂件到 300×300 巨幅作品
- **交互编辑** — 点击任意位置修改单颗豆子颜色
- 导出高清 PNG，带网格线 + 色号标注 + 用色统计
- Android 端自动保存到相册

## 核心算法

- **CIEDE2000** 色差公式 — 比传统 RGB 距离更贴近人眼感知
- **K-Means++ 聚类** — 智能挑选最优调色板
- **蛇形 Floyd-Steinberg 抖动** — 平滑颜色过渡，减少色带
- **自动白平衡 + CLAHE 自适应对比度** — 改善偏色照片效果
- **肤色优先策略** — 人像皮肤区域降低抖动强度，保持自然

## 快速开始

```bash
# 克隆仓库
git clone https://github.com/Xinghuo-WorldModel/Fuse-Beads.git
cd Fuse-Beads

# 安装依赖
flutter pub get

# Web 端运行
flutter run -d chrome

# Android APK 打包
flutter build apk --release

# Windows 桌面
flutter run -d windows
```

## 项目结构

```
lib/
├── main.dart                # 入口
├── app.dart                 # MaterialApp 配置
├── models/                  # 数据模型（品牌、颜色、配置、转换结果）
├── data/                    # 品牌色板 JSON 加载器
├── services/                # 核心服务
│   ├── pixel_converter.dart # 像素化 + 颜色映射
│   ├── color_matcher.dart   # CIEDE2000 颜色匹配
│   ├── image_processor.dart # 图像预处理 + Isolate 并发
│   ├── export_service.dart  # 高清图导出
│   └── file_saver*.dart     # 跨平台文件保存
├── screens/                 # 首页 / 配置 / 预览
└── widgets/                 # 网格绘制 / 调色板 / 颜色选择器
assets/
└── brand_colors/            # 7 大品牌色板数据
```

## 品牌支持

| 品牌 | 颜色数 | 地区 |
|------|--------|------|
| Perler | 70 | 北美 |
| Hama | 58 | 欧洲 |
| Artkal-C | 100 | 国际 |
| Artkal-R | 90 | 国际 |
| MARD | 72 | 亚洲 |
| Yant | 68 | 亚洲 |
| Nabbi | 50 | 北欧 |

## 环境要求

- Flutter 3.2+
- Dart 3.2+
- Android SDK 24+（Android 端）
- Chrome（Web 端）

## 版本历史

- **v2.0** — 修复 Web 端拍照问题；优化 README
- **v1.0** — 首个完整版本，支持 Android/Web/Windows

## 许可证

MIT License

---

<p align="center">给酥圆圆的第一颗豆子</p>
