# 拼豆图制作 App

将人像照片转换为拼豆图案的 Flutter 安卓应用。

## 功能

- **像素风格模式** — 将人像转为像素艺术风格再映射到拼豆色板
- **写实拼豆模式** — 直接将人像颜色映射到最接近的拼豆颜色
- 支持 Perler / Hama / Artkal 三大品牌色板
- 智能人脸检测与裁剪
- 可调节网格尺寸（29×29 / 58×58 / 87×87）
- 可限制最大颜色数
- 导出带网格线、色号标注和用色统计的高清图片

## 环境要求

- Flutter 3.2+
- Android SDK 24+
- Dart 3.2+

## 开始使用

```bash
# 安装依赖
flutter pub get

# 运行调试版
flutter run

# 构建 APK
flutter build apk --release
```

## 项目结构

```
lib/
  main.dart              # 入口
  app.dart               # MaterialApp 配置
  models/                # 数据模型
  data/                  # 品牌色板数据加载
  services/              # 核心服务（图像处理、颜色匹配、导出）
  screens/               # 页面
  widgets/               # 可复用组件
assets/
  brand_colors/          # 品牌色板 JSON 数据
```

## 核心算法

颜色匹配使用 CIE Lab 色彩空间的 Delta E (CIE76) 算法，比 RGB 欧氏距离更符合人眼感知。

## 品牌支持

| 品牌 | 颜色数 | 说明 |
|------|--------|------|
| Perler | 70 | 北美主流 |
| Hama | 58 | 欧洲主流 |
| Artkal | 100 | 色彩最丰富 |
