# Legado iOS 开发方案

- 版本：0.1（2026-11-21）
- 代码基线：upstream-final / da17bb2（2026-04-27）
- 目标平台：iOS 17+
- 当前分支：iOS

## 1. 先明确边界

这不是把 Android APK 改个后缀就能完成的事。Legado 是 Kotlin/Android 原生应用，iOS 端必须重写 UI、存储、网络、阅读排版和书源执行引擎。可行路线是：

1. **原生 SwiftUI 重写**（本方案默认路线）。
2. 用 Kotlin Multiplatform 共享少量纯业务逻辑（规则解析、数据模型），但 Android 相关代码无法直接复用。
3. 早期用 WebView 承载 Web 书架/源编辑器作为辅助，不承担主阅读体验。

本分支已经提供一个可编译的 SwiftUI MVP 骨架，覆盖"本地 TXT 导入 + 书架 + 阅读器 + 主题/字号 + 进度"这条最小闭环。它不是完整 Legado，也不包含书源引擎、在线搜索、TTS、EPUB/MOBI/PDF、WebDAV 同步。

## 2. 现有 Android 代码审计

- Kotlin 844 个文件，Java 88 个，XML 496 个；app 模块 826 个源码文件。
- 构建：Kotlin 2.3.0、AGP 8.13.2、Gradle 8.13、compileSdk/targetSdk 36、JDK 17。
- 模块：
  - app：Android UI、阅读器、书源、订阅、TTS、同步、Web 服务。
  - modules/book：epublib、MOBI、UMD 等本地书解析。
  - modules/rhino：Rhino JS 引擎封装。
  - modules/web：Vue 3 + TypeScript + Vite 的 Web 书架/源编辑器。
- 关键 Android 依赖：
  - Android SDK：Context、Activity、Service、Notification、MediaSession、WebView、ContentProvider。
  - Room + KSP：数据库与迁移。
  - Cronet/OkHttp：网络。
  - Rhino：书源 JS 规则。
  - Jsoup/JsoupXpath/JsonPath：HTML/JSON 解析。
  - Android XML/View 体系：阅读界面、书架、设置页。
- 结论：这些依赖在 iOS 上都不存在对应物，必须逐层替换，不能直接编译。

## 3. 为什么不能在 Windows 上直接产出 IPA

- iOS 应用只能由 Xcode 的 iOS SDK 编译，并用 Apple 的签名体系产出 IPA。
- Windows 没有 Xcode、iOS SDK、codesign、simctl；本机也没有 Swift 工具链。
- 即使代码写完，也需要 macOS + Xcode 才能：
  - 编译 Swift/UIKit/SwiftUI；
  - 在 Simulator 运行；
  - 为真机签名；
  - 上传 TestFlight/App Store。
- 本仓库提供 Xcode 工程、XcodeGen 配置和 GitHub Actions macOS 构建流程；在 Mac 或 CI 上可以构建出 Simulator App。真机 IPA 还需要你的 Apple Developer Team 和证书。

## 4. 目标架构

采用 SwiftUI + MVVM + async/await，按 feature 分层：

    ios/
      LegadoiOS/
        App/                 应用入口、Tab 根视图
        Core/
          Models/            Book、Chapter、BookSource、ReadingProgress
          Storage/           JSON/SQLite、文件存储、备份
          Parsing/           TXT/EPUB/MOBI/PDF、编码识别、目录解析
          SourceEngine/      URL 模板、HTML/JSON 规则、JS 沙箱
          Network/           URLSession、Cookie、缓存、WebDAV
          Reader/            TextKit 2 分页、排版、主题
          TTS/               AVSpeechSynthesizer、后台音频
        Features/
          Bookshelf/         书架、分组、导入、排序
          Reader/            阅读器、目录、进度、设置
          Source/            书源管理、搜索、详情、发现
          Settings/          设置、备份、关于
        Resources/           Assets、示例文本
      LegadoiOS.xcodeproj
      project.yml            XcodeGen 配置（备用生成方式）

技术选型：

- UI：SwiftUI，复杂阅读排版用 UIViewRepresentable 包 TextKit 2/UITextView。
- 并发：Swift Concurrency；网络/解析用 actor 隔离。
- 存储：MVP 用 Codable JSON；正式版建议 GRDB（SQLite）或 SwiftData，按查询复杂度选。
- 网络：URLSession + async/await；需要 HTTP 明文站点时配置 ATS 例外并做用户提示。
- HTML：SwiftSoup；XML：XMLParser；JSON：JSONSerialization/Codable。
- JS：JavaScriptCore，限制执行时间、禁用文件/进程访问，书源 JS 运行在独立上下文。
- 压缩包：ZIPFoundation（EPUB）；PDF：PDFKit；MOBI：自研或移植 KF8 解析。
- 朗读：AVSpeechSynthesizer + AVAudioSession；后台播放需要 audio background mode。
- 同步：WebDAV 用 URLSession 手写 PROPFIND/PUT/GET；iCloud 用 CloudKit/Ubiquity 容器。
- Web 服务：如需要，用 Network.framework 起本地 HTTP 服务，承载 modules/web 构建产物。

## 5. Android 到 iOS 的模块映射

| Android | iOS 对应 | 说明 |
|---|---|---|
| data/entities/BookSource | Core/Models/BookSource.swift | 字段保持 JSON 兼容，未知字段原样保留 |
| model/analyzeRule/AnalyzeRule.kt | Core/SourceEngine/RuleEngine.swift | 规则链、默认规则、变量 |
| model/analyzeRule/AnalyzeUrl.kt | Core/SourceEngine/RuleRequest.swift | URL 模板、方法、Header、Body、Cookie |
| model/analyzeRule/AnalyzeByJSoup.kt | Core/SourceEngine/HTMLRuleParser.swift | SwiftSoup + XPath/CSS |
| model/analyzeRule/AnalyzeByJSonPath.kt | Core/SourceEngine/JSONRuleParser.swift | JSONPath |
| help/rhino + modules/rhino | JavaScriptCore | JS 规则沙箱、java.* 兼容层 |
| model/ReadBook.kt / ReadBookActivity.kt | Features/Reader/ReaderSession.swift | 章节、分页、进度 |
| ui/book/read/page/TextChapterLayout.kt | Core/Reader/TextPaginator.swift | TextKit 2 分页 |
| data/AppDatabase + Room | Core/Storage/Database.swift | 首选 GRDB，或 SwiftData |
| service/HttpReadAloudService.kt | Core/TTS/TTSPlayer.swift | AVSpeechSynthesizer/流式音频 |
| help/AppWebDav.kt + lib/webdav | Core/Network/WebDAVClient.swift | PROPFIND/PUT/GET |
| modules/web | WKWebView 或本地 Web 服务 | 可选，不作为主阅读 UI |
| modules/book（epublib/MOBI/UMD） | Core/Parsing/EPUB、MOBI | 需要移植/重写解析器 |

## 6. 分阶段路线图

### Phase 0：工程骨架与 MVP（本分支）

目标：可运行的本地阅读闭环。

- Xcode 工程、SwiftUI App、Tab 导航。
- 书架网格、示例书、删除。
- 本地 TXT 导入（Files/document picker）。
- UTF-8/UTF-16/GB18030/Big5 编码识别。
- 章节标题正则识别，失败时按长度切分。
- 阅读器：滚动阅读、上一章/下一章、字号、行距、纸色/护眼/夜间主题。
- 章节级进度持久化。
- 设置页、关于页。
- 预计：1-2 周（1 名 iOS 工程师）。

### Phase 1：本地书与书架完整化

- EPUB 解析（ZIPFoundation + OPF/NCX/XHTML）。
- MOBI/KF8、UMD、PDF（PDFKit）导入。
- 封面提取、目录、书籍详情、分组、排序、搜索。
- 导入 Legado 备份中的书籍与阅读进度。
- 大文件分页/懒加载，内存与启动性能优化。
- 预计：3-4 周。

### Phase 2：书源引擎核心

- BookSource 数据模型与 JSON 导入/导出。
- URL 规则、GET/POST、Header、Cookie、重定向、超时、并发限制。
- HTML（CSS/XPath）、JSON（JSONPath）、正则规则。
- JavaScriptCore 规则执行与 java.* 兼容层。
- 搜索、详情、目录、正文四条主链路。
- 发现/分类、登录、Cookie 持久化。
- 规则调试器与错误日志。
- 预计：6-10 周（最重、最需要测试的阶段）。

### Phase 3：阅读体验对齐

- TextKit 2 分页、覆盖/仿真/滑动/滚动模式。
- 字体、字重、简繁转换、段距、首行缩进、背景图。
- 目录、书签、高亮、笔记、全文搜索。
- TTS：系统语音、HTTP TTS、语速/音色、后台播放、锁屏控制。
- 阅读进度跨章/跨端同步。
- 预计：6-8 周。

### Phase 4：同步、备份与生态

- WebDAV 多配置、上传/下载/冲突处理。
- iCloud 备份（可选）。
- Legado 备份 JSON 导入/导出，书源、订阅源、替换规则、阅读配置。
- 本地 Web 服务 + modules/web 的 Web 书架（可选）。
- 预计：4-6 周。

### Phase 5：发布与打磨

- 中英文/简繁本地化、Dynamic Type、VoiceOver。
- 隐私清单、ATS、网络权限、后台音频说明。
- App Store 截图、隐私政策、审核说明。
- TestFlight、崩溃收集、性能监控。
- 预计：4-6 周。

总计：

- MVP：1-2 周。
- 可用版本（本地书 + 书源核心）：3-5 个月（2-3 名 iOS 工程师）。
- 功能基本对齐：9-15 个月（3-4 人，含 QA/设计）。
- 完整对齐 Legado 全部边缘功能：12 个月以上。

## 7. 本分支 MVP 已实现

- ios/LegadoiOS/App：应用入口、Tab 根视图。
- ios/LegadoiOS/Core/Models：Book、Chapter、ReadingProgress。
- ios/LegadoiOS/Core/Storage：LibraryStore、BookFileStore。
- ios/LegadoiOS/Core/Parsing：TXTBookParser、TextEncodingDetector。
- ios/LegadoiOS/Core/Theme：ReaderTheme。
- ios/LegadoiOS/Features/Bookshelf：书架、书籍卡片、导入。
- ios/LegadoiOS/Features/Reader：阅读器、阅读设置、进度。
- ios/LegadoiOS/Features/Settings：设置、关于。
- ios/LegadoiOS/Resources/Assets.xcassets：AppIcon、AccentColor。
- ios/LegadoiOS.xcodeproj：Xcode 工程。
- ios/project.yml：XcodeGen 备用配置。
- .github/workflows/ios.yml：macOS CI 构建 Simulator App。

MVP 明确不做：在线书源、搜索、订阅、TTS、EPUB/MOBI/PDF、WebDAV、备份恢复、漫画。这些在后续 Phase 实现。

## 8. 数据兼容与迁移

- Legado 备份 JSON 是跨端迁移的首选，不直接搬 Room 数据库文件。
- BookSource 字段按原 JSON 保留；iOS 模型使用可空字段 + 原始字典，避免新字段丢失。
- 阅读进度映射：
  - Android 的 durChapterIndex / durChapterPos 对应 iOS 的 chapterIndex / characterOffset。
  - MVP 只存章节索引；Phase 3 增加字符偏移和分页锚点。
- 书籍分组、书源分组、替换规则、阅读配置分别建模，不要塞进一个 Book。
- 备份导入要做版本号与字段校验，失败时给出可读错误，不静默丢数据。

## 9. 构建、签名与发布

### 本机（macOS）

需要 macOS 14+ 与 Xcode 16+。

    cd ios
    xcodegen generate          # 可选；仓库已带 xcodeproj
    open LegadoiOS.xcodeproj

或命令行构建 Simulator：

    xcodebuild -project LegadoiOS.xcodeproj \
      -scheme LegadoiOS \
      -sdk iphonesimulator \
      -configuration Debug \
      -derivedDataPath build \
      CODE_SIGNING_ALLOWED=NO \
      build

真机：

1. 在 Xcode 的 Signing & Capabilities 选择你的 Team。
2. 修改 PRODUCT_BUNDLE_IDENTIFIER 为你自己的唯一 ID。
3. 连接设备运行，或 Archive 后导出 IPA/上传 TestFlight。

### CI

.github/workflows/ios.yml 在 macOS runner 上：

- 安装 XcodeGen；
- 生成工程；
- 编译 Simulator App；
- 上传 zip artifact。

CI 构建的是未签名的 Simulator App，不能直接装到真机。真机 IPA 需要证书和 provisioning profile，建议用 fastlane 或 Xcode Cloud。

### 当前环境限制

本仓库是在 Windows 上准备的，无法在本机执行 xcodebuild，也无法生成/签名 IPA。所有 Swift 代码和工程文件需要在 macOS/Xcode 上做首次编译验证；如果编译报错，优先用 Xcode 的 Fix-it 修正，再把修复提交回 iOS 分支。

## 10. 测试与质量

- 单元测试：TXT 编码识别、章节正则、异常文本、空文件、超大文件。
- 数据测试：Legado 备份 JSON 导入/导出往返。
- 规则测试：用固定 HTML/JSON fixture 测 CSS/XPath/JSONPath/JS。
- UI 测试：导入→书架→阅读→切章→改主题→重启恢复进度。
- 性能：100 万字 TXT 的导入时间、内存峰值、首屏时间。
- 兼容：iPhone SE 小屏、Pro Max、iPad、横屏、动态字体。
- 发布前：隐私清单、ATS 配置、后台音频权限、崩溃率。

## 11. 风险与合规

- **版权/审核**：Legado 的书源机制可能被用于获取未经授权的内容。iOS 版本不应内置书源或正文，只提供用户自行导入规则的阅读器；App Store 审核需要准备版权说明、用户协议和投诉渠道。
- **JS 沙箱**：书源 JS 能力很强，必须限制执行时间、网络域、文件访问；不要让规则访问 App 私有数据。
- **HTTP 明文**：大量书源站点是 HTTP，ATS 需要例外；审核时需解释。
- **后台音频**：TTS 后台播放需要 audio background mode，滥用会被拒。
- **性能**：大书、复杂规则、图片缓存容易 OOM；需要分页、降级和缓存上限。
- **维护成本**：书源规则变化频繁，规则引擎和调试工具要优先做。

## 12. 团队与排期建议

- 1 名 iOS 工程师：先做 MVP 和本地书，2-4 周可见 demo。
- 2-3 名 iOS 工程师 + 1 名 QA：Phase 1-3 并行，3-5 个月可用版本。
- 3-4 名工程师 + 设计/QA：9-15 个月基本对齐。
- 关键角色：iOS 架构、书源规则引擎、阅读排版/TextKit、数据与同步、QA/合规。

## 13. 下一步

1. 在 macOS/Xcode 上打开 ios/LegadoiOS.xcodeproj，完成首次编译。
2. 决定优先路线：本地阅读器优先，还是书源引擎优先。
3. 定 iOS 最低版本（当前 17.0）和 bundle id。
4. 准备 Apple Developer Team、证书、TestFlight。
5. 用 Legado 备份 JSON 做第一版导入器。
6. 把书源规则引擎拆成独立 Swift Package，便于单测和复用。
