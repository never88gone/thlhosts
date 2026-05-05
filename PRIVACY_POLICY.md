# 隐私政策 / Privacy Policy

**糖葫芦 Hosts (THLHosts)**

最后更新：2026 年 5 月 5 日 / Last updated: May 5, 2026

---

## 简体中文

### 概述

糖葫芦 Hosts（以下简称"本应用"）是一款完全离线的 iOS / tvOS Hosts 管理工具。我们非常重视您的隐私，本政策说明了本应用如何处理您的数据。

### 数据收集

**本应用不收集任何个人数据。** 具体而言：

- ❌ 不收集您的姓名、邮箱或任何账号信息
- ❌ 不收集您的位置信息
- ❌ 不收集您的浏览历史或网络访问记录
- ❌ 不向任何第三方服务器发送任何数据
- ❌ 不使用任何分析或追踪 SDK

### 本地数据处理

本应用的所有功能均在您的设备本地运行：

- **Hosts 配置文件**：您创建、编辑或导入的所有配置文件，仅保存在您设备的本地存储（App Group 容器）中，不会上传至任何服务器。
- **DNS 解析**：本应用通过建立本地 VPN 隧道来拦截 DNS 查询。所有 DNS 解析流量仅在您的设备上处理，不经过本应用的任何服务器。未命中 Hosts 规则的查询会直接转发至您设置的上游 DNS 服务器（默认为 `114.114.114.114`）。
- **应用日志**：运行日志仅存储在设备内存中，关闭应用后自动清除，不会持久化保存或上传。

### VPN 权限说明

本应用需要申请"个人 VPN"权限，仅用于建立本地 DNS 代理隧道，以实现 Hosts 规则的系统级生效。此 VPN 连接：

- 仅将目标为本地虚拟 IP（`10.0.0.1`）的 DNS 流量引入隧道
- 不会代理您设备上的任何 HTTP/HTTPS 网页流量
- 不会将您的流量路由至任何远程服务器

### 远程 URL 订阅

如果您选择使用"从 URL 下载"功能，应用会从您指定的 URL 下载 Hosts 文件。这一网络请求由您的设备直接发起，本应用不会中转或记录该请求内容。

### 儿童隐私

本应用不面向 13 岁以下儿童，也不会故意收集儿童的个人信息。

### 隐私政策变更

如果本隐私政策发生重大变更，我们将通过更新本文件并修改"最后更新"日期的方式进行通知。

### 联系我们

如对本隐私政策有任何疑问，欢迎通过 GitHub Issue 联系我们。

---

## English

### Overview

THLHosts is a fully offline Hosts management tool for iOS and tvOS. We take your privacy seriously. This policy explains how the app handles your data.

### Data Collection

**This app does not collect any personal data.** Specifically:

- ❌ No names, emails, or account information collected
- ❌ No location data collected
- ❌ No browsing history or network access records collected
- ❌ No data sent to any third-party servers
- ❌ No analytics or tracking SDKs used

### Local Data Processing

All app functionality runs entirely on your device:

- **Hosts Configuration Files**: All configurations you create, edit, or import are stored only in your device's local storage (App Group container) and are never uploaded to any server.
- **DNS Resolution**: The app establishes a local VPN tunnel to intercept DNS queries. All DNS processing happens on your device only, without passing through any of our servers. Queries that don't match any Hosts rules are forwarded directly to your configured upstream DNS server (default: `114.114.114.114`).
- **Application Logs**: Runtime logs are stored only in device memory and are automatically cleared when the app is closed. They are never persisted or uploaded.

### VPN Permission

The app requires the "Personal VPN" entitlement solely to establish a local DNS proxy tunnel, enabling system-wide Hosts rule enforcement. This VPN connection:

- Only routes DNS traffic destined for the local virtual IP (`10.0.0.1`) into the tunnel
- Does **not** proxy any HTTP/HTTPS web traffic on your device
- Does **not** route your traffic through any remote servers

### Remote URL Subscription

If you use the "Download from URL" feature, the app will download a Hosts file from the URL you specify. This network request is made directly from your device, and the app does not relay or log the request content.

### Children's Privacy

This app is not directed at children under the age of 13 and does not knowingly collect personal information from children.

### Changes to This Policy

If we make material changes to this privacy policy, we will notify you by updating this file and revising the "Last updated" date.

### Contact

If you have any questions about this privacy policy, please contact us via a GitHub Issue.
