# Legado iOS

这是 Legado 的 iOS 重写分支（MVP），不是 Android 工程的直接打包。Android 的 Kotlin/Android SDK 代码不能编译成 iOS App，因此这里用 SwiftUI 重写了最小阅读闭环。

- 分支：iOS
- 代码基线：upstream-final / da17bb2
- 最低系统：iOS 17
- UI：SwiftUI
- 当前版本：0.1.0 MVP

## 已实现

- 书架网格、示例书、删除。
- 本地 TXT 导入（Files / document picker）。
- UTF-8、UTF-16、GB18030、Big5 编码识别。
- 章节标题识别，失败时按长度切分。
- 阅读器：滚动阅读、上一章/下一章。
- 阅读设置：纸白/护眼/夜间主题、字号、行距。
- 章节级阅读进度持久化。
- 设置页与关于页。

## 未实现（后续 Phase）

- 在线书源、搜索、发现、订阅。
- EPUB/MOBI/PDF、漫画。
- TTS、后台播放。
- WebDAV/iCloud 同步。
- Legado 备份导入。
- 书源 JS 规则、调试器。

完整路线见 DEVELOPMENT_PLAN.md。

## 目录

    ios/
      LegadoiOS/
        App/                 应用入口、Tab
        Core/
          Models/            Book、Chapter、SampleBook
          Storage/           LibraryStore、BookFileStore
          Parsing/           TXT 编码与章节解析
          Theme/             阅读主题、颜色扩展
        Features/
          Bookshelf/         书架与导入
          Reader/            阅读器与阅读设置
          Settings/          设置
        Resources/           Assets.xcassets、AppIcon
      LegadoiOS.xcodeproj   Xcode 工程
      project.yml           XcodeGen 配置（可选）
      DEVELOPMENT_PLAN.md   开发方案

## 在 macOS 上构建

需要 macOS + Xcode 16 或更高版本（工程使用 Xcode 16 的 objectVersion 77）。

直接打开：

    cd ios
    open LegadoiOS.xcodeproj

如果没有 Xcode 工程或想重新生成：

    brew install xcodegen
    cd ios
    xcodegen generate
    open LegadoiOS.xcodeproj

一键构建 Simulator：

    cd ios
    bash scripts/build-simulator.sh

或手动执行：

    cd ios
    xcodebuild -project LegadoiOS.xcodeproj \
      -scheme LegadoiOS \
      -sdk iphonesimulator \
      -configuration Debug \
      -derivedDataPath build \
      CODE_SIGNING_ALLOWED=NO \
      build

真机运行：

1. 在 Xcode 的 Signing & Capabilities 里选择你的 Apple Developer Team。
2. 把 PRODUCT_BUNDLE_IDENTIFIER 改成你自己的唯一 ID。
3. 连接 iPhone，选择设备运行；或 Archive 后导出 IPA/上传 TestFlight。

也可以用命令行归档/导出（需要证书和 provisioning profile）：

    export DEVELOPMENT_TEAM=你的TeamID
    export BUNDLE_ID=com.example.legado
    cd ios
    bash scripts/archive.sh

导出结果在 ios/build/export/。默认 ExportOptions.plist 使用 development 方式；上架 App Store 前改成 app-store-connect。

## 重要限制

- Windows 上无法运行 xcodebuild，也无法生成/签名 IPA；必须在 macOS + Xcode 上构建。
- 仓库里的 .xcodeproj 是用文本方式生成的，尚未在 Xcode 中实际编译过；如果打开或编译报错，优先用 Xcode 的 Fix-it 修正，并同步更新 project.pbxproj 和 project.yml。
- CI 使用 macOS runner 构建未签名的 Simulator App，不能直接安装到真机。
- 本 MVP 不内置书源或正文；示例文本为原创。正式产品需要处理版权、App Store 审核和书源合规问题。

## 验证状态（2026-11-21）

本工程是在 Windows 上准备的，已完成：

- 全部 Swift 文件通过 tree-sitter 语法解析，0 个语法错误节点。
- project.pbxproj 通过 pbxproj 解析器，15 个对象引用完整。
- project.yml、LegadoiOS.xcscheme、Assets JSON 均通过解析。
- 应用图标已生成（1024x1024，无 alpha）。

尚未完成：

- 未在 Xcode 中实际编译、链接、启动 Simulator。
- 未做真机签名，未产出 IPA。
- 未跑单元测试/UI 测试。

因此，这个分支交付的是 **可在 macOS/Xcode 上继续构建的完整工程骨架**，不是已经签名好的 IPA。首次编译时如遇 API 版本或工程格式问题，按 Xcode Fix-it 修正即可。

## 下一步

1. 在 Mac 上完成首次编译，修掉 Swift/Xcode 兼容问题。
2. 决定优先做本地书（EPUB/MOBI/PDF）还是书源引擎。
3. 用 Legado 备份 JSON 做导入器。
4. 为书源规则引擎建立独立 Swift Package 和 fixture 测试。
