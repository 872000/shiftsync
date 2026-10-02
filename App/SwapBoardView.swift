import SwiftUI
import ShiftSync

struct SwapBoardView: View {
    @Environment(SwapBoardViewModel.self) private var swaps
    @Environment(ScheduleViewModel.self) private var schedule

    @State private var showingNamePrompt = false
    @State private var draftName = ""
    @State private var postingShift: Shift?
    @State private var postNote = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("Your name", text: $draftName)
                            .onAppear { draftName = swaps.myName }
                        Button("Save") { swaps.saveName(draftName) }
                            .disabled(draftName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                } header: {
                    Text("Identify yourself to post & claim")
                }

                Section("Open swaps") {
                    let open = swaps.board.openPosts()
                    if open.isEmpty {
                        Text("Nothing up for swap right now.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(open) { post in
                        SwapPostRow(post: post, isMine: post.ownerName == swaps.myName) {
                            swaps.claim(post)
                        } onCancel: {
                            swaps.cancel(post)
                        }
                    }
                }

                Section("Post one of your shifts") {
                    ForEach(schedule.upcomingShifts().prefix(10)) { shift in
                        Button {
                            postingShift = shift
                            postNote = ""
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(shift.role).foregroundStyle(.primary)
                                    Text("\(shift.start, style: .date) · \(shift.start, style: .time)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.left.arrow.right.circle")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Swap Board")
            .sheet(item: $postingShift) { shift in
                NavigationStack {
                    Form {
                        Section("Post for swap") {
                            Text("\(shift.role) · \(shift.start, style: .date) \(shift.start, style: .time)")
                            TextField("Note for coworkers (optional)", text: $postNote, axis: .vertical)
                        }
                    }
                    .navigationTitle("Offer Swap")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { postingShift = nil }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Post") {
                                swaps.post(shift: shift, note: postNote)
                                postingShift = nil
                            }
                        }
                    }
                }
            }
            .alert("Swap board",
                   isPresented: Binding(
                    get: { swaps.lastError != nil },
                    set: { if !$0 { swaps.lastError = nil } }
                   )) {
                Button("OK", role: .cancel) { swaps.lastError = nil }
            } message: {
                Text(swaps.lastError ?? "")
            }
        }
    }
}

struct SwapPostRow: View {
    let post: SwapPost
    let isMine: Bool
    let onClaim: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(post.shift.role).font(.headline)
                Spacer()
                Text(post.ownerName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isMine ? Color.blue.opacity(0.15) : Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
            Text("\(post.shift.start, style: .date) · \(post.shift.start, style: .time) – \(post.shift.end, style: .time)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !post.note.isEmpty {
                Text(post.note).font(.subheadline)
            }
            HStack {
                if isMine {
                    Button("Cancel post", role: .destructive, action: onCancel)
                } else {
                    Button("Claim this shift", action: onClaim)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
