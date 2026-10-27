# 系统状态

一款使用 SwiftUI 开发的原生 iOS 系统监测应用。根据参考界面实现深色卡片仪表盘，去除广告，使用原创图标与原生控件。无需注册，不包含第三方 SDK。

**当前状态：首版功能已实现，包含应用内隐私政策和帮助支持页面。“系统状态 - 设备监测”（Apple ID：6827463949）的 1.0.0 (1) 已于 2026 年 10 月 27 日提交 App Store 审核，当前状态为“等待审核”；设置为中国大陆免费发行、审核通过后自动发布，尚未上架。iPhone Duo 专项适配和真机验收仍待完成。**

## 功能

| 模块 | 支持内容 |
| --- | --- |
| CPU | 用户与系统使用率、最近 60 秒曲线、核心数量 |
| 网络 | 上传与下载速率、60 秒曲线、本次前台采样累计、连接和低数据模式 |
| 内存与存储 | 虚拟内存分布、物理内存、数据卷容量及可用空间 |
| 设备状态 | 电量、充电、热状态、低电量模式、屏幕亮度、音量和音频路由 |
| 时钟 | 日期、12/24 小时制、秒数、专注时钟、可选屏幕常亮 |
| 采样与报告 | 0.5/1/2 秒刷新、暂停与恢复、清空历史、报告预览及系统分享 |
| 隐私与支持 | 设置内离线隐私政策、常见问题、开发者邮件联系和网页版入口 |
| 布局与辅助功能 | 首页一屏展示全部指标、横竖屏重排、辅助功能标签，详情页支持系统字号 |

进入后台后自动停止采样，重新激活时重建 CPU 与网络采样基线。各指标卡片可点击查看详情和数据来源。

首页按参考图排列：时钟、CPU、网络、并排的内存与存储，以及两行三列的状态卡片。根据安全区域宽高缩放紧凑布局，全部 10 个指标无需滚动即可查看；横屏重新组合为两排。首页使用紧凑字号以保证信息完整，详情与设置保留系统字号设置。

## 开发环境

- macOS 与 Xcode，包含 iOS SDK 和至少一个 iOS 模拟器运行时。
- 最低部署版本：iOS 17.0；Swift 语言模式：5.0。
- XcodeGen：用于从 `project.yml` 重新生成工程。可通过 `brew install xcodegen` 安装。
- 真机运行和分发归档需要有效的 Apple 开发者签名配置；模拟器构建不需要签名。

开发时使用 Xcode 27.0。已提交生成后的 `.xcodeproj` 和共享 Scheme，可直接打开；修改工程配置时以 `project.yml` 为源，再运行 `xcodegen generate`。

## 获取与运行

```sh
git clone git@github.com:remixjc/ios_systemstatus.git
cd ios_systemstatus
open SystemStatus.xcodeproj
```

在 Xcode 中选择 `SystemStatus` Scheme 和可用模拟器后运行。项目目前没有外部包依赖。

如需重新生成工程：

```sh
xcodegen generate
```

纯命令行构建：

```sh
xcrun simctl list devices available
xcodebuild -project SystemStatus.xcodeproj \
  -scheme SystemStatus \
  -destination 'platform=iOS Simulator,id=<模拟器 UUID>' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO build
```

将 `<模拟器 UUID>` 替换为本机列表中的设备标识。设备 UUID 是本地配置，不保证其他机器存在相同设备。

## 测试

```sh
zsh scripts/verify.sh <模拟器 UUID>
```

该脚本重新生成工程并运行单元测试及 UI 测试。不传参数时使用原开发机的 iPhone 18 Pro UUID；其他机器请显式传入设备 UUID。

测试覆盖网络速率的实际时间差、接口重连、计数重置、格式边界、报告排除磁盘容量，以及详情、暂停/恢复、设置、报告返回和横屏交互。一屏布局测试还会检查全部 10 个指标在竖屏、横屏中均位于视口内且可点击。

已有验证记录：

- iOS 18.5 / iPhone 16 Pro：5 项单元测试及 1 项完整 UI 流程测试通过。
- 一屏布局更新：iOS 18.5 / iPhone SE（第 3 代）通过 5 项单元测试及 2 项 UI 测试，验证竖屏、横屏全部 10 张卡片无需滚动且可点击。
- 底部留白微调后，iOS 18.5 / iPhone 16 Pro 的一屏布局复核通过，包含底部说明的完整可见性检查。
- iOS 27 / iPhone 18 Pro：首次单元测试通过，UI 自动化出现 Accessibility IPC 超时和 Mach 服务错误，未记为通过。
- Release 真机架构编译、归档、App Store 分发导出及导出 IPA 签名校验通过。

测试日志与结果包属于本地产物，不提交到 Git。当前没有真实 iPhone 验收结果；完整记录见 [发布记录](Store/RELEASE.md)。

## 签名与发布

当前版本为 `1.0.0 (1)`，Bundle ID 为 `com.chengwang.systemstatus`。默认签名团队写在 `project.yml` 和 `Store/ExportOptions.plist` 中；使用其他开发者账号时需同步更新。也可在 Xcode 中临时选择 Team，但重新生成工程会恢复 `project.yml` 的配置。

```sh
# 生成 Release 归档，使用 Xcode 中已配置的开发者账号
zsh scripts/archive.sh

# 导出本地 App Store 分发包，不执行上传
xcodebuild -exportArchive \
  -archivePath artifacts/SystemStatus.xcarchive \
  -exportOptionsPlist Store/ExportOptions.plist \
  -exportPath artifacts/AppStore \
  -allowProvisioningUpdates
```

归档输出为 `artifacts/SystemStatus.xcarchive`，导出安装包为 `artifacts/AppStore/SystemStatus.ipa`。归档中间文件存放在本机 `~/Library/Developer/Xcode/DerivedData/SystemStatusArchive`，以避免同步目录的文件扩展属性干扰签名。

商店中文文案位于 [metadata.json](Store/zh-Hans/metadata.json)。公开页面通过 GitHub Pages 从 `main` 分支的 `docs/` 目录发布：

- [隐私政策](https://remixjc.github.io/ios_systemstatus/privacy.html)
- [使用帮助与技术支持](https://remixjc.github.io/ios_systemstatus/support.html)

页面源文件为 `Store/privacy.html` 和 `Store/support.html`，修改后运行 `zsh scripts/sync-store-pages.sh` 同步到 `docs/`。应用内在“设置 → 隐私政策”和“设置 → 使用帮助与技术支持”提供原生页面，内容离线可读；公开网页链接用于商店资料。应用内文本与网页更新时应同步核对。不要把账号密码、API 私钥、签名证书或描述文件提交到仓库。

## 数据范围与隐私

应用仅展示所用公开接口可读取的指标。实时 CPU 主频、硬件摄氏温度、亮度尼特数、电池健康度和未知芯片营销名称不使用猜测值。开机时长替换为本次应用打开时长。

- 网络累计只覆盖本次前台有效采样，不等于运营商账单或本月流量。
- 内存占用不代表内存压力，非活跃内存可能由系统回收。
- 模拟器读数可能反映 Mac 宿主环境，不能据此判断 iPhone 性能。
- 采样曲线只保存在进程内存中，设置保存在应用本地，无自动上传。
- 隐私清单声明 DiskSpace `E174.1` 和 UserDefaults `CA92.1`。磁盘容量仅在设备内展示，报告排除磁盘容量及其派生数据。
- 报告先预览，仅在用户主动分享后交给所选目标。

新增接口、SDK、持久化或采集行为时，需要重新核对隐私清单和商店隐私回答。

## iPhone Duo 适配进度

已实现通用宽窄窗口重排、横竖屏布局和当前活动屏幕读取。原开发环境没有 27.1 SDK 或 Duo 模拟器；折痕避让、侧边栏、全部折叠姿态和 Duo 真机测试尚未完成。普通宽屏或 iPad 测试不计作 Duo 实测。

具体待办与发布条件见 [Store/RELEASE.md](Store/RELEASE.md)。

## 工程结构

```text
SystemStatus/
├── App/                  应用入口与前后台生命周期
├── Models/               指标模型、格式化、网络差值计算
├── Services/             系统接口、采样、历史与报告
├── Views/                仪表盘、图形、详情、设置与隐私政策
└── Resources/            图标资源与隐私清单
SystemStatusTests/        单元测试
SystemStatusUITests/      UI 流程测试
SystemStatus.xcodeproj/   Xcode 工程与共享 Scheme
Store/                   商店文案、网页、导出配置与发布记录
scripts/                 测试、归档和图标生成脚本
project.yml              XcodeGen 工程配置源
```

## 仓库约定

提交源码、资源、工程配置、共享 Scheme、测试和发布文档。忽略 `build/`、`DerivedData/`、`artifacts/`、日志、测试结果、安装包、Xcode 用户状态、编辑器缓存及本地密钥。`.env.example` 可作为无敏感值的配置示例提交。

工程没有声明开源许可证；仓库可访问性不代表授予开源使用许可。
