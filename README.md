# Personal Cards Manager

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][views-shield]][views-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]

<p align="center">
<!-- PROJECT LOGO -->
<br />

<p align="center">
  <a href="https://github.com/CambriaTech/personal_cards_manager">
    <img src="assets/images/logo-full.png" alt="Logo" width="250">
  </a>

<h3 align="center">Personal Cards Manager - 个人安全卡包</h3>
<p align="center">
    一款纯本地、端到端加密的个人卡片与凭证管理系统，支持完整银行卡、会员卡、身份类证件的沉浸式收纳、归档、高强度 AES-256 跨设备备份及生物识别级安全保护。
    <br />
    <a href="https://github.com/CambriaTech/personal_cards_manager"><strong>查看详细文档 »</strong></a>
    <br />
    <br />
    <a href="https://github.com/CambriaTech/personal_cards_manager">演示</a>
    ·
    <a href="https://github.com/CambriaTech/personal_cards_manager/issues">报告Bug</a>
    ·
    <a href="https://github.com/CambriaTech/personal_cards_manager/issues">功能请求</a>
</p>

## 目录

- [Personal Cards Manager](#personal-cards-manager)
  - [目录](#目录)
  - [快速开始](#快速开始)
    - [环境要求](#环境要求)
    - [安装步骤](#安装步骤)
  - [项目结构](#项目结构)
  - [UI 与模块引擎](#ui-与模块引擎)
  - [核心功能](#核心功能)
  - [技术栈](#技术栈)
    - [核心框架](#核心框架)
    - [本地库与状态管理](#本地库与状态管理)
    - [认证与安全](#认证与安全)
  - [文档](#文档)
  - [贡献](#贡献)
  - [许可证](#许可证)
  - [联系方式](#联系方式)

## 快速开始

### 环境要求

- Flutter 3.24.0+
- Dart 3.5.0+
- iOS 12.0+ / Android 6.0+

### 安装步骤

1. **克隆仓库**

   ```sh
   git clone https://github.com/CambriaTech/personal_cards_manager.git
   cd personal_cards_manager
   ```

2. **安装依赖**

   ```sh
   # 获取 Flutter 包
   flutter pub get
   
   # 如果需要重新生成 Isar / Riverpod 或 JSON 代码
   dart run build_runner build -d
   ```

3. **进入 iOS 目录安装 Pods（如需部署 iOS）**

   ```sh
   cd ios
   pod install
   cd ..
   ```

4. **启动服务**

   ```sh
   flutter run
   ```

## 项目结构

```text
personal_cards_manager/
├── android/                # Android 原生宿主
├── ios/                    # iOS 原生宿主
├── lib/                    # 核心库代码
│   ├── core/               # 核心常量、安全路由 (如 AutoLockWrapper)
│   ├── data/               # 数据库处理：Isar Models 及本地服务
│   ├── features/           # 工具层与特性封装 (认证、状态初始化、备份逻辑)
│   ├── screens/            # 页面组件树 (Home, Cards, Documents, Settings)
│   └── main.dart           # 应用启动入口
├── pubspec.yaml            # 依赖配置管理
└── README.md               # 项目主说明文档
```

## UI 与模块引擎

> 项目使用纯正模块化的架构切割管理逻辑与业务逻辑。

```text
├── 核心架构面板
│   ├── 银行卡模块库 (Bank Cards)
│   ├── 会员证卡模块 (Member Cards - 积分与条码)
│   └── 隐私证件系统 (ID Documents - 护照、驾照展开样式)
├── 辅助管理组件
│   ├── 用户分类 (Tags & Custom Groups 管理)
│   ├── 本地消息及到期通知队列
│   └── 跨设备 AES-256 加解密库
```

## 核心功能

- **无内网及纯本地隔离**：100% 本地数据库（不外联任何形式的中心化服务器），绝对的数据所有权与阻断外部泄露。
- **三重身份防护锁定**：FaceID/TouchID 无感接入验证、PIN 码机制，与应用退后台即时封禁锁定的自动计时监听器。
- **极致的感官互动**：采用纯粹流式构建的多卡片渲染模板及主题抽色，护照、ID支持特定的纵横向展开动画。
- **全要素 AES-256 导出迁移**：针对无账户的缺点进行补偿——建立强密码导出的 JSON-Payloads `(.pcmbak)`，可投递至任意终端精准重写隔离存储区。
- **数据结构与归属生态**：引入了细颗粒度的动态分组、标记（Tags）、收藏列表与基于 IsarLink 的智能搜索。

## 技术栈

### 核心框架

- **Flutter** - 高性能跨平台原生 UI 引擎的代表
- **Dart** - 以极简流式的构建方式掌控所有异步处理

### 本地库与状态管理

- **Riverpod 2.0** (`flutter_riverpod`) - 实现顶级声明式及健壮的全局状态注射和视图绑定
- **Isar Database** - 超高性能、全方位支持加密和复杂索引关系的跨平台 NoSQL 嵌入数据库库
- **Shared Preferences** - 轻量键值记录系统设置与首选项

### 认证与安全

- **Local Auth** (`local_auth`) - 底层生物特征传感器及密码的拦截验证桥层
- **Flutter Secure Storage** - 调取 iOS KeyChain / Android Keystore 完成敏感散列或 Isar 初始加密键的安全存放
- **Encrypt** - 执行设备外数据导出的 AES-256 和 Base64 标准算法

## 文档

详细设计规范和底层需求列表记录于 `docs/` 目录：

- **[项目需求](docs/requirements/项目需求.md)**
- **[应用框架开发与安全基建](docs/requirements/1.应用框架开发与安全基建.md)**
- **[银行卡功能开发](docs/requirements/2.银行卡功能开发.md)**
- **[证件功能开发](docs/requirements/4.证件功能开发.md)**

## 贡献

欢迎贡献！请遵循以下步骤：

1. Fork 本仓库
2. 创建特性分支（`git checkout -b feature/AmazingFeature`）
3. 提交更改（`git commit -m 'feat: 增加加密模块'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 开启 Pull Request

## 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 联系方式

Felix Liu

项目链接：<https://github.com/CambriaTech/personal_cards_manager>

---

<!-- links -->

[contributors-shield]: https://img.shields.io/github/contributors/CambriaTech/personal_cards_manager.svg?style=for-the-badge
[contributors-url]: https://github.com/CambriaTech/personal_cards_manager/graphs/contributors
[views-shield]: https://img.shields.io/github/forks/CambriaTech/personal_cards_manager.svg?style=for-the-badge
[views-url]: https://github.com/CambriaTech/personal_cards_manager/network/members
[stars-shield]: https://img.shields.io/github/stars/CambriaTech/personal_cards_manager.svg?style=for-the-badge
[stars-url]: https://github.com/CambriaTech/personal_cards_manager/stargazers
[issues-shield]: https://img.shields.io/github/issues/CambriaTech/personal_cards_manager.svg?style=for-the-badge
[issues-url]: https://github.com/CambriaTech/personal_cards_manager/issues
[license-shield]: https://img.shields.io/github/license/CambriaTech/personal_cards_manager.svg?style=for-the-badge
[license-url]: https://github.com/CambriaTech/personal_cards_manager/blob/master/LICENSE
