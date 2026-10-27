import SwiftUI

@main
struct SystemStatusApp: App {
    @StateObject private var monitor = SystemMonitor()
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("keepAwake") private var keepAwake = false

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(monitor)
                .preferredColorScheme(.dark)
                .tint(Palette.blue)
                .onAppear { updateActivity() }
                .onChange(of: scenePhase) { _, _ in updateActivity() }
                .onChange(of: keepAwake) { _, _ in updateActivity() }
        }
    }

    private func updateActivity() {
        let active = scenePhase == .active
        monitor.setActive(active)
        UIApplication.shared.isIdleTimerDisabled = active && keepAwake
    }
}
