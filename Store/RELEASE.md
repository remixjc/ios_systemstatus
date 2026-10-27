# 发布记录 · 2026-10-27

## 当前交付

- 应用名称：系统状态
- Bundle ID：com.chengwang.systemstatus
- 版本：1.0.0 (1)
- 最低系统：iOS 17
- 签名团队：6NZHLN3MUD（Bundle ID 已在当前登录的 App Store Connect 账号中核对）
- 商店名称：系统状态 - 设备监测（“系统状态”被 App Store Connect 判定已被使用；桌面名称仍为“系统状态”）
- Apple ID：6827463949；SKU：systemstatus-ios-001
- 发布状态：已创建商店记录并保存部分资料；**构建上传失败、未提交审核、未上架**。

## App Store Connect 操作记录 · 2026-10-27

- 创建应用记录：`https://appstoreconnect.apple.com/apps/6827463949/distribution`
- 已保存：简体中文介绍、推广文本、关键词、版本 1.0.0、副标题、工具/效率分类、无需登录、审核操作说明。
- 内容版权：不包含、显示或访问第三方内容。
- 年龄分级问卷已保存，全球主要分级为 4+，部分地区按当地规则显示。
- 隐私问卷：不收集数据；已执行发布，页面发布结果需下轮复核。隐私政策 URL 尚空缺。
- 已上传 1206 × 2622 的 iPhone 16 Pro 实际界面截图，以及 2064 × 2752 的 iPad 13 英寸实际界面截图；页面均显示 1/10。上传后提交校验提示至少一张截图仍在处理，需复核最终处理状态。
- 截图保留模拟器数据说明，不将宿主机读数宣称为真机指标。原图位于 `artifacts/StoreScreenshots/`。
- 尝试通过 `xcodebuild -exportArchive`、destination=upload 上传当前归档，失败：`Failed to Use Accounts`，缺少团队 App Store Connect 访问。日志：`artifacts/upload-appstore.log`。Xcode 的 Apple Accounts 页面显示 Sign In，网页登录不等于 Xcode 登录。
- 点击“添加以供审核”后，苹果返回必填项：构建版本、截图完成处理、隐私政策 URL、价格等级，以及审核联系人名字、姓氏、电子邮件、电话号码。版本状态仍为“准备提交”。
- 应用列表另提示账号持有人需接受更新后的 Paid Applications Schedule，并先接受最新 Apple Developer Program License Agreement；尚未代签。
- 尚未填写：支持 URL、版权主体、审核联系人、价格和首发地区；未猜测这些资料。

交付文件：

- `SystemStatus.xcodeproj`
- `artifacts/SystemStatus.xcarchive`
- `artifacts/AppStore/SystemStatus.ipa`
- `Store/zh-Hans/metadata.json`
- `Store/privacy.html`
- `Store/support.html`

## 验证

- 一屏布局更新：缩小首页字体、卡片与间距，竖屏展示时钟、CPU、网络、双列容量卡和两行三列状态卡；横屏重排。详情与设置继续使用系统字号。
- 一屏布局验证：iOS 18.5 / iPhone SE（第 3 代）通过 5 项单元测试和 2 项 UI 测试。全部 10 张指标卡在竖屏、横屏均位于视口内、无需滚动且可点击，详情、暂停/恢复、设置、报告流程也通过。日志：`artifacts/test-one-screen-se.log`，结果：`artifacts/Tests-OneScreen-SE.xcresult`。
- 在底部留白微调后，iOS 18.5 / iPhone 16 Pro 的一屏布局测试通过，额外验证底部说明也完整位于视口内。日志：`artifacts/test-one-screen-pro.log`，原始结果：`/tmp/SystemStatus-OneScreen-Pro.xcresult`，截图导出：`artifacts/QA-OneScreen-Pro/`。
- 本轮首次 Pro UI 测试服务无响应，SE 末次重跑遇到 Mach 服务错误；保留日志，不将这些环境故障记为通过。之后在 Pro 上完成上述最新版布局复核。
- 模拟器 Debug 构建成功。
- 真机架构 Release 编译、归档成功，自动签名成功。
- App Store Connect 分发导出成功；导出不代表已经上传或通过 App Store 验证。
- iOS 18.5 / iPhone 16 Pro：5 项单元测试和 1 项完整 UI 流程测试全部通过。覆盖 CPU 详情、暂停/继续、设置、报告预览/关闭及横屏重排。日志：`artifacts/test-ios18.log`，结果：`artifacts/Tests-iOS18.xcresult`。
- iOS 27 / iPhone 18 Pro：首次 5 项单元测试通过，UI 执行到报告返回时出现 Accessibility IPC timeout；重跑出现 Mach server died。保留原始日志，不将此环境的 UI 验证记为通过。
- 没有连接真实 iPhone，因此 CPU、VM、网络计数、音频路由、电量更新和能耗仍需真机验收。不能用模拟器宿主数据替代真机结论。

## iPhone Duo 未完成项

当前机器：Xcode 27.0 (27A266a)，iOS SDK 27.0。已安装的设备类型中无 Duo。

苹果文档 *Optimizing your app for iPhone Duo* 指出完整支持需要 27.1 SDK，并涉及展开布局、折痕区域、侧边导航及姿态变化。当前交付完成通用宽窄布局、横竖屏与活动屏幕读取，**没有宣称已完成 Duo 专项适配或折叠实测**。

后续须：

1. 安装包含 27.1 SDK 的 Xcode 和 Duo 模拟器运行时。
2. 按届时 SDK 的公开 API 处理折痕保留区域与侧边导航，验证不同姿态下的触控可达性。
3. 验证折叠/展开的实时重排，保持采样与详情状态，检查安全区、大字号、专注时钟及屏幕切换。
4. 使用真机验证热状态、汇总电量、网络接口、前后台恢复与耗电。

官方资料：

- https://developer.apple.com/documentation/uikit/optimizing-your-app-for-iphone-duo
- https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app-for-review/

## 提交前的外部条件

1. App Store Connect 网页已登录；需要账号所有者在 Xcode > Settings > Apple Accounts 登录，获得构建上传权限。无需向助手发送密码或验证码。
2. 需确认免费或付费、首发地区、版权主体、审核联系人和有效支持联系方式；不从证书姓名推断这些发布信息。若面向中国大陆分发，需核对 App 备案条件和 ICP 备案号。
3. 将已写好的隐私政策与帮助网页托管到开发者控制的公开 HTTPS 地址，在帮助网页加入有效联系方式，并在 App Store Connect 填写相应 URL。本次没有编造域名或联系邮箱。
4. 商店记录、分类、年龄分级和部分资料已填写；截图已上传，需复核处理状态。继续补齐隐私 URL、分发信息、联系人并上传构建；复核隐私发布与加密信息。
5. 完成上述专项适配和验收后，再提交审核。发布是苹果审核与开发者分发设置共同决定的结果，归档成功不等于上架。

## 数据接口说明

本应用不访问 systemUptime、mach_absolute_time、文件时间戳或私有 API。磁盘 E174.1 仅用于本机展示，报告不包含磁盘数据；UserDefaults CA92.1 仅用于应用内部设置。后续新增 API、SDK 或采集行为时，应重新核对隐私清单及商店隐私回答。
