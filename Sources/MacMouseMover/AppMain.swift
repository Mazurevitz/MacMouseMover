import SwiftUI
import AppKit

class AppState: ObservableObject {
    static let shared = AppState()
    @Published var mouseMover = MouseMover()
    @Published var schedule = Schedule()
    @Published var launchAtLogin = LaunchAtLogin()
    @Published var powerMonitor = PowerMonitor()

    private var wasRunningBeforeBattery = false

    private init() {
        schedule.onScheduleChange = { [weak self] shouldRun in
            self?.mouseMover.isRunning = shouldRun
        }

        powerMonitor.onPowerChange = { [weak self] isOnBattery in
            guard let self = self else { return }
            if isOnBattery {
                self.wasRunningBeforeBattery = self.mouseMover.isRunning
                if self.mouseMover.isRunning {
                    self.mouseMover.isRunning = false
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateIcon"), object: nil)
                }
            } else {
                if self.wasRunningBeforeBattery {
                    self.mouseMover.isRunning = true
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateIcon"), object: nil)
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            updateIcon()
            button.action = #selector(handleClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover = NSPopover()
        popover.contentSize = NSSize(width: 220, height: 200)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(AppState.shared)
        )

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover.isShown == true {
                self?.popover.performClose(nil)
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateIcon),
            name: NSNotification.Name("UpdateIcon"),
            object: nil
        )
    }

    @objc func handleClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            showPopover()
        } else {
            AppState.shared.mouseMover.isRunning.toggle()
            updateIcon()
        }
    }

    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc func updateIcon() {
        if let button = statusItem.button {
            let iconName = AppState.shared.mouseMover.isRunning ? "cursorarrow.motionlines" : "cursorarrow"
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Mouse Mover")
        }
    }
}

@main
struct MacMouseMoverApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Mouse Jiggler", isOn: $appState.mouseMover.isRunning)
                .toggleStyle(.switch)
                .font(.headline)
                .onChange(of: appState.mouseMover.isRunning) { _ in
                    NotificationCenter.default.post(name: NSNotification.Name("UpdateIcon"), object: nil)
                }

            Divider()

            Toggle("Launch at Login", isOn: $appState.launchAtLogin.isEnabled)
                .toggleStyle(.switch)

            Toggle("Enable Schedule", isOn: $appState.schedule.isEnabled)
                .toggleStyle(.switch)

            Toggle("Pause on Battery", isOn: $appState.powerMonitor.pauseOnBattery)
                .toggleStyle(.switch)

            if appState.schedule.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Start:")
                            .frame(width: 40, alignment: .leading)
                        DatePicker("", selection: $appState.schedule.startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    HStack {
                        Text("Stop:")
                            .frame(width: 40, alignment: .leading)
                        DatePicker("", selection: $appState.schedule.stopTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }
                }
                .padding(.leading, 4)
            }

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 220)
    }
}
