import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ShiftListView()
                .tabItem { Label("Schedule", systemImage: "calendar") }
            PayView()
                .tabItem { Label("Pay", systemImage: "dollarsign.circle") }
            SwapBoardView()
                .tabItem { Label("Swaps", systemImage: "arrow.left.arrow.right") }
        }
    }
}
