---
name: THLHOSTS Development
description: THLHOSTSApp 开发的专业技能和指南（UI、tvOS、双语代码）。
---

# 项目技能与标准

本文档概述了 **THLHOSTSApp** 开发的专业技能和指南。

## 1. UI 美学技能 (毛玻璃效果 & SF Symbols)
**目标：** 创建在 Apple 平台上感觉原生且视觉震撼的现代化界面。

### 指南：
- **背景：** 使用 `UIVisualEffectView`（或自定义 `HSBLiquidGlassView`）作为背景，以创造深度感和高级感。避免在主要容器背景中使用扁平的纯色。
- **排版：** 使用 **San Francisco (SF)** 字体。
    - **标题：** `UIFont.systemFont(ofSize: 40+, weight: .bold)`
    - **正文：** `UIFont.monospacedSystemFont(ofSize: ..., weight: .regular)` 用于代码/日志。
- **图标：** 使用 **SF Symbols** (`UIImage(systemName: "...")`).
    - **填充：** 实心形状使用 `.fill` 变体。
    - **配置：** 使用 `UIImage.SymbolConfiguration(pointSize: ..., weight: ...)` 进行配置以匹配文本大小。
- **颜色：** 尽可能使用语义颜色 (`.label`, `.systemBackground`, `.secondaryLabel`)，但针对特定主题（例如暗色毛玻璃上的白色文本）进行覆盖。
- **布局：** 使用 `SnapKit` 编写简洁的 Auto Layout 代码。

---

## 2. tvOS 交互技能
**目标：** 确保应用在大屏幕上使用遥控器输入时感觉直观且响应迅速。

### 指南：
- **焦点引擎 (Focus Engine)：**
    - 在 `UITableViewCell` and `UICollectionViewCell` 中实现 `didUpdateFocus(in:with:)`。
    - **缩放效果：** 放大获得焦点的元素（例如 `1.05x` 或 `1.1x`）。
    - **阴影/颜色：** 获得焦点时改变背景颜色或添加阴影。
- **遥控器输入：**
    - 使用标准的 `UIButton` 动作或 `UITapGestureRecognizer`。
    - 如果需要，处理自定义遥控器按钮（播放/暂停、菜单）的 `pressesBegan(_:with:)`。
- **尺寸：**
    - **文本：** tvOS 上的字体大小应**显著更大**（例如，正文文本从 30pt 开始）。
    - **触摸目标：** 按钮和单元格必须足够大，以便轻松选中。
- **安全区域：** 遵守 `safeAreaLayoutGuide`，特别是考虑到电视的过扫描 (overscan)。

---

## 3. 双语代码技能 (英语 & 中文)
**目标：** 确保精通英语或中文的开发者都能理解代码。

### 指南：
- **注释：** 所有功能注释必须提供 **英文** 和 **中文**。
    - **格式：**
      ```swift
      // [EN] Function description
      // [ZH] 函数描述
      func myFunction() { ... }
      ```
    - 或者在适当的情况下使用并排/多行注释。
- **字符串：** 所有面向用户的字符串必须本地化。
    - 使用 `NSLocalizedString("Key", comment: "English Default")`.
    - 运行时切换使用 `HSBHostsLanguageManager`。

---

## 4. 平台适配 (iOS vs. tvOS)
- **代码：** 使用 `#if os(tvOS)` 专门为电视功能编写分支逻辑。
- **UI：** 使用 `traitCollection.userInterfaceIdiom` 或 `#if os(...)` 来调整约束、字体和布局轴。
