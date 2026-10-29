import AppIntents

enum WidgetMetricChoice: String, AppEnum {
    case appDefault, battery, memory, storage, thermal, cpu, network, connection, brightness, audio, session
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "展示指标"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .appDefault: "跟随 App 设置", .battery: "电池", .memory: "内存", .storage: "存储",
        .thermal: "温度状态", .cpu: "CPU（App 快照）", .network: "网络下载（App 快照）",
        .connection: "网络连接（App 快照）", .brightness: "亮度（App 快照）",
        .audio: "音量（App 快照）", .session: "本次监测（App 快照）"
    ]
    func resolved(_ fallback: WidgetMetric) -> WidgetMetric {
        WidgetMetric(rawValue: rawValue) ?? fallback
    }
}

enum WidgetStyleChoice: String, AppEnum {
    case appDefault, standard, matrix
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "小组件样式"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .appDefault: "跟随 App 设置", .standard: "基础仪表盘", .matrix: "信息矩阵"
    ]
}

enum WidgetAccentChoice: String, AppEnum {
    case appDefault, blue, green, purple, orange
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "主题配色"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .appDefault: "跟随 App 设置", .blue: "天空蓝", .green: "薄荷绿", .purple: "星空紫", .orange: "活力橙"
    ]
}

enum WidgetClockChoice: String, AppEnum {
    case appDefault, show, hide
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "时钟"
    static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .appDefault: "跟随 App 设置", .show: "显示", .hide: "隐藏"
    ]
}

struct StatusWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "自定义系统状态"
    static var description = IntentDescription("基础款和信息矩阵均支持小、中、大号。每个小组件可独立选择样式、指标和配色。")

    @Parameter(title: "主指标", default: WidgetMetricChoice.appDefault)
    var primary: WidgetMetricChoice
    @Parameter(title: "第二项", default: WidgetMetricChoice.appDefault)
    var second: WidgetMetricChoice
    @Parameter(title: "第三项", default: WidgetMetricChoice.appDefault)
    var third: WidgetMetricChoice
    @Parameter(title: "第四项", default: WidgetMetricChoice.appDefault)
    var fourth: WidgetMetricChoice
    @Parameter(title: "主题配色", default: WidgetAccentChoice.appDefault)
    var accent: WidgetAccentChoice
    @Parameter(title: "时钟", default: WidgetClockChoice.appDefault)
    var clock: WidgetClockChoice
    @Parameter(title: "样式", default: WidgetStyleChoice.appDefault)
    var style: WidgetStyleChoice

    func resolved(defaults: WidgetPreferences) -> WidgetPreferences {
        WidgetPreferences(primary: primary.resolved(defaults.primary),
                          second: second.resolved(defaults.second),
                          third: third.resolved(defaults.third),
                          fourth: fourth.resolved(defaults.fourth),
                          accent: WidgetAccent(rawValue: accent.rawValue) ?? defaults.accent,
                          showClock: clock == .appDefault ? defaults.showClock : clock == .show,
                          style: WidgetStyle(rawValue: style.rawValue) ?? defaults.style)
    }
}
