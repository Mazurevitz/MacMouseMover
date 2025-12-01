import SwiftUI

@main
struct MacMouseMoverApp: App {
    @StateObject private var mouseMover = MouseMover()
    @StateObject private var schedule = Schedule()

    var body: some Scene {
        MenuBarExtra("Mouse Mover", systemImage: mouseMover.isRunning ? "cursorarrow.motionlines" : "cursorarrow") {
            MenuBarView(mouseMover: mouseMover, schedule: schedule)
        }
        .menuBarExtraStyle(.window)
    }
}

struct MenuBarView: View {
    @ObservedObject var mouseMover: MouseMover
    @ObservedObject var schedule: Schedule

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Mouse Jiggler", isOn: $mouseMover.isRunning)
                .toggleStyle(.switch)
                .font(.headline)

            Divider()

            Toggle("Enable Schedule", isOn: $schedule.isEnabled)
                .toggleStyle(.switch)

            if schedule.isEnabled {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Start:")
                            .frame(width: 40, alignment: .leading)
                        DatePicker("", selection: $schedule.startTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                    }

                    HStack {
                        Text("Stop:")
                            .frame(width: 40, alignment: .leading)
                        DatePicker("", selection: $schedule.stopTime, displayedComponents: .hourAndMinute)
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
        .onAppear {
            schedule.onScheduleChange = { shouldRun in
                mouseMover.isRunning = shouldRun
            }
        }
    }
}
