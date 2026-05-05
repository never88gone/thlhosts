# 🍡 糖葫芦 Hosts (THLHosts)

[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20tvOS-blue?logo=apple)](https://developer.apple.com)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

一款为 **iOS** 和 **tvOS** 打造的纯本地 Hosts 管理工具。通过建立本地 VPN 隧道，实现 DNS 级别的 Hosts 劫持，无需越狱，完全离线运行，保护您的隐私与数据安全。

---

## ✨ 功能特性

- **DNS 级别的 Hosts 拦截**：基于 `NetworkExtension` 的 Packet Tunnel 实现 DNS 代理，对系统全局生效
- **多配置管理**：支持创建、编辑、导入、切换多个 Hosts 配置文件
- **一键切换**：通过主开关快速启停服务
- **URL 远程订阅**：支持从远程 URL 下载并同步 Hosts 配置（如 neoHosts 等开源列表）
- **本地文件导入**：支持从本地文件系统导入 `.hosts` / `.txt` 格式的配置
- **tvOS 扫码上传**：内置 HTTP 服务器，在 tvOS 设备上通过手机扫码快速上传配置
- **IPv6 防绕过**：自动拦截已命中域名的 `AAAA` 查询，防止浏览器通过 IPv6 绕过规则
- **实时日志**：内置日志面板，可实时查看 DNS 拦截状态，方便调试
- **多语言支持**：支持简体中文 / English
- **多主题**：内置多套暗色主题

---

## 📱 平台支持

| 平台 | 最低版本 | 说明 |
|------|---------|------|
| iOS / iPadOS | 16.0+ | iPhone 支持下拉导航，iPad 支持分栏布局 |
| tvOS | 16.0+ | 支持 Apple TV，含二维码上传功能 |

---

## 🏗 项目架构

```
THLHOSTSApp/
├── Models/
│   ├── HostsFile.swift          # 数据模型
│   ├── HostsStorage.swift       # 持久化存储
│   └── HostsViewModel.swift     # 业务逻辑 ViewModel
├── NetworkExtension/
│   ├── PacketTunnelProvider.swift  # VPN 核心：DNS 拦截与转发
│   └── HostsManager.swift          # Extension 内部管理
├── Utils/
│   ├── HSBHostsManager.swift    # VPN 配置与启动管理
│   └── HSBLogger.swift          # 应用内日志
├── Views/SwiftUI/
│   ├── MainView.swift           # 主视图（iOS SplitView / tvOS Stack）
│   ├── HostsListView.swift      # 配置列表
│   ├── HostsDetailView.swift    # 配置详情与编辑
│   ├── SettingsView.swift       # 设置页
│   └── LogView.swift            # 日志面板
└── Resources/
    ├── zh-Hans.lproj/           # 简体中文
    └── en.lproj/                # English
```

---

## 🔧 工作原理

```
用户请求域名
     │
     ▼
[系统 DNS 查询] ──────────────────────────────────┐
     │                                            │
     ▼                                            │
[PacketTunnelProvider (本地 VPN)]                 │
     │                                            │
     ├─ 命中 Hosts (A 记录)  → 返回自定义 IP ←──┘
     ├─ 命中 Hosts (AAAA 记录) → 返回空响应 (强制 IPv4 降级)
     └─ 未命中 → 转发至上游 DNS (默认 114.114.114.114)
```

> 所有流量处理均在设备本地进行，不经过任何外部服务器。

---

## 🚀 构建与运行

### 依赖

- Xcode 15+
- CocoaPods

### 步骤

```bash
# 克隆仓库
git clone <repo-url>
cd thlhosts

# 安装依赖
pod install

# 用 Xcode 打开工程
open THLHOSTS.xcworkspace
```

### 配置要求

在 Xcode 中需要配置以下内容：

1. **Bundle ID**：修改主 App 和 NetworkExtension Target 的 Bundle Identifier
2. **App Group**：在两个 Target 中配置同一个 App Group（格式：`group.xxx.thlhosts`）
3. **Capabilities**：
   - 主 App：`Personal VPN`、`App Groups`
   - Network Extension：`Network Extensions`（Packet Tunnel）、`App Groups`
4. **Provisioning Profile**：需要在 Apple Developer 后台开启上述权限并下载对应描述文件

> ⚠️ VPN 功能需要真机运行，模拟器不支持 `NetworkExtension`。

---

## 📖 使用说明

1. **添加配置**：点击右上角 `+` 新建本地配置，或通过 URL 订阅远程 Hosts 列表
2. **编辑配置**：点击配置项进入详情，直接编辑内容或从文件导入
3. **激活配置**：点击配置列表项左侧的圆点开启/停用该配置（同时只能有一个激活）
4. **启动服务**：切换主开关启动 VPN 服务
5. **验证生效**：如果拦截未立即生效，尝试开关一次**飞行模式**以刷新系统 DNS 缓存

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建你的分支 (`git checkout -b feature/awesome-feature`)
3. 提交更改 (`git commit -m 'Add awesome feature'`)
4. 推送分支 (`git push origin feature/awesome-feature`)
5. 发起 Pull Request

---

## 📄 许可证

本项目基于 [MIT License](LICENSE) 开源。

---

## 🔒 隐私政策

请查阅 [PRIVACY_POLICY.md](PRIVACY_POLICY.md)。

---

## 📬 联系

如有问题欢迎通过 Issue 反馈。
