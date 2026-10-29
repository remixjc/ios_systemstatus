import AVFAudio
import Combine

struct AudioOutputReading: Equatable {
    let volume: Double?
    let route: String
    var error: String?
}

@MainActor
protocol AudioOutputSource: AnyObject {
    var onChange: ((AudioOutputReading) -> Void)? { get set }
    func start()
    func stop()
    func refresh()
}

/// Observes media output volume without playing audio or requesting microphone access.
@MainActor
final class AudioOutputMonitor: AudioOutputSource {
    var onChange: ((AudioOutputReading) -> Void)?
    private var session = AVAudioSession.sharedInstance()
    private var volumeObservation: NSKeyValueObservation?
    private var notifications = Set<AnyCancellable>()
    private var active = false
    private var ready = false

    func start() {
        guard !active else { return }
        active = true
        observeVolume()
        for name in [AVAudioSession.routeChangeNotification,
                     AVAudioSession.interruptionNotification,
                     AVAudioSession.mediaServicesWereResetNotification] {
            NotificationCenter.default.publisher(for: name)
                .sink { [weak self] notification in
                    Task { @MainActor [weak self] in self?.handle(notification) }
                }.store(in: &notifications)
        }
        activate()
    }

    func stop() {
        active = false
        volumeObservation = nil
        notifications.removeAll()
        if ready {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
        }
        ready = false
    }

    func refresh() {
        guard active, ready else { return }
        onChange?(AudioOutputReading(volume: Double(session.outputVolume), route: route))
    }

    private var route: String {
        let names = session.currentRoute.outputs.map(\.portName).joined(separator: "、")
        return names.isEmpty ? "系统音频输出" : names
    }

    private func observeVolume() {
        volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, _ in
            // KVO may arrive off the main thread; all published UI state lives on MainActor.
            Task { @MainActor [weak self] in self?.refresh() }
        }
    }

    private func activate() {
        guard active else { return }
        do {
            // Ambient mixes with other apps by default. The default soloAmbient category
            // would interrupt their playback when activating the session.
            try session.setCategory(.ambient, mode: .default)
            try session.setActive(true)
            ready = true
            refresh()
        } catch {
            ready = false
            onChange?(AudioOutputReading(volume: nil, route: route, error: "音量读取暂不可用，请重新打开 App。"))
        }
    }

    private func handle(_ notification: Notification) {
        guard active else { return }
        switch notification.name {
        case AVAudioSession.mediaServicesWereResetNotification:
            ready = false
            volumeObservation = nil
            session = .sharedInstance()
            observeVolume()
            activate()
        case AVAudioSession.interruptionNotification:
            guard let value = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: value) else { return }
            if type == .began {
                ready = false
                onChange?(AudioOutputReading(volume: nil, route: route, error: "音频会话暂时中断，结束后自动更新。"))
            } else {
                activate()
            }
        default:
            refresh()
        }
    }
}
