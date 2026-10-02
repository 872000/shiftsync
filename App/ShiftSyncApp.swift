import SwiftUI

@main
struct ShiftSyncApp: App {
    @State private var schedule = ScheduleViewModel()
    @State private var swaps = SwapBoardViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(schedule)
                .environment(swaps)
        }
    }
}
