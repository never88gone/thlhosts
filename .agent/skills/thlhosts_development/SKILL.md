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
    - **对比度 (CRITICAL):** 按钮/Cell 的文字与背景在**默认**和**选中/聚焦**状态下都必须保持高对比度。
    - **禁止：** 选中/聚焦时文字颜色与背景颜色相同或相近（例如白色文字 + 白色高亮背景）。必须反转颜色（例如白色背景 -> 黑色文字）。
- **布局：** 使用 `SnapKit` 编写简洁的 Auto Layout 代码。

---

## 2. tvOS 交互技能
**目标：** 确保应用在大屏幕上使用遥控器输入时感觉直观且响应迅速。

### 指南：
- **焦点引擎 (Focus Engine)：**
    - 在 `UITableViewCell` and `UICollectionViewCell` 中实现 `didUpdateFocus(in:with:)`。
    - **缩放效果：** 放大获得焦点的元素（推荐 `1.05x` - `1.1x`）。
    - **对比度 (CRITICAL):**
        - **必须**确保在焦点状态下文字与背景有极高的对比度。
        - **推荐做法：** 使用 `UIListContentConfiguration` (iOS 14+)，它会自动处理焦点时的颜色反转（例如：未选中时白字，选中时白底黑字）。
        - **禁止：** 出现“白底白字”或“黑底黑字”的情况。需在 `didUpdateFocus` 或 `configurationUpdateHandler` 中明确处理颜色状态。
- **布局与安全区域：**
    - **安全区域：** tvOS 的安全区域边距应至少为 **60pt** (iOS 通常为 20pt)，以避免过扫描 (overscan) 导致内容被切除。
    - **间距：** 组件之间的间距应更大，避免密集排列。
- **尺寸与排版 (10-Foot UI)：**
    - **大标题：** `54pt+` (Bold)
    - **正文/代码：** `31pt+` (Medium/Regular) - *小于 29pt 的文字在电视上很难阅读。*
    - **触摸目标：** 最小可点击区域应显著大于 iOS。
- **遥控器输入：**
    - 使用标准的 `UIButton` 动作或 `UITapGestureRecognizer`。
    - 既然没有鼠标，所有交互必须可以通过“上/下/左/右”的焦点移动来完成。

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
