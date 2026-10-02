import SwiftUI
import ShiftSync

struct ShiftListView: View {
    @Environment(ScheduleViewModel.self) private var schedule
    @State private var showingForm = false
    @State private var editingShift: Shift?

    var body: some View {
        NavigationStack {
            List {
                nextShiftSection
                ForEach(groupedDays, id: \.key) { day, shifts in
                    Section(dayHeader(for: day)) {
                        ForEach(shifts) { shift in
                            ShiftRow(shift: shift)
                                .swipeActions {
                                    Button("Delete", role: .destructive) {
                                        schedule.remove(shift)
                                    }
                                    Button("Edit") {
                                        editingShift = shift
                                    }
                                    .tint(.blue)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .toolbar {
                Button { showingForm = true } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showingForm) {
                ShiftFormView(shift: nil)
            }
            .sheet(item: $editingShift) { shift in
                ShiftFormView(shift: shift)
            }
            .alert("Couldn't save shift",
                   isPresented: Binding(
                    get: { schedule.lastError != nil },
                    set: { if !$0 { schedule.lastError = nil } }
                   )) {
                Button("OK", role: .cancel) { schedule.lastError = nil }
            } message: {
                Text(schedule.lastError ?? "")
            }
        }
    }

    @ViewBuilder
    private var nextShiftSection: some View {
        Section {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let now = context.date
                if let current = schedule.currentShift(now: now) {
                    ShiftCountdownCard(
                        title: "On shift now",
                        subtitle: "\(current.role) · ends \(current.end, style: .time)",
                        accent: .green
                    )
                } else if let next = schedule.nextShift(now: now) {
                    let countdown = NextShiftResolver.countdown(to: next, from: now)
                    ShiftCountdownCard(
                        title: "Next shift in \(countdown.displayString)",
                        subtitle: "\(next.role) · \(next.start, style: .date) \(next.start, style: .time)",
                        accent: countdown.isImminent ? .orange : .blue
                    )
                } else {
                    Text("No upcoming shifts — enjoy the time off.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var groupedDays: [(key: Date, value: [Shift])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: schedule.upcomingShifts()) { shift in
            calendar.startOfDay(for: shift.start)
        }
        return groups.sorted { $0.key < $1.key }
            .map { (key: $0.key, value: $0.value.sorted { $0.start < $1.start }) }
    }

    private func dayHeader(for day: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: day)
    }
}

struct ShiftCountdownCard: View {
    let title: String
    let subtitle: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(accent)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ShiftRow: View {
    let shift: Shift

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(shift.role).font(.headline)
                Text("\(shift.start, style: .time) – \(shift.end, style: .time)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if shift.isOvernight() {
                    Text("Overnight")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(String(format: "%.1f h", shift.durationHours))
                    .font(.subheadline)
                Text(String(format: "$%.2f", shift.grossPay))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
