import SwiftUI
import ShiftSync

struct ShiftFormView: View {
    @Environment(ScheduleViewModel.self) private var schedule
    @Environment(\.dismiss) private var dismiss

    let existing: Shift?

    @State private var start: Date
    @State private var end: Date
    @State private var role: String
    @State private var hourlyRate: Double
    @State private var notes: String

    init(shift: Shift?) {
        self.existing = shift
        let fallbackStart = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        let fallbackEnd = Calendar.current.date(byAdding: .hour, value: 8, to: fallbackStart) ?? Date()
        _start = State(initialValue: shift?.start ?? fallbackStart)
        _end = State(initialValue: shift?.end ?? fallbackEnd)
        _role = State(initialValue: shift?.role ?? "")
        _hourlyRate = State(initialValue: shift?.hourlyRate ?? 0)
        _notes = State(initialValue: shift?.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Starts", selection: $start)
                    DatePicker("Ends", selection: $end)
                }
                Section("Details") {
                    TextField("Role (e.g. Cashier)", text: $role)
                    TextField("Hourly rate", value: $hourlyRate, format: .currency(code: "CAD"))
                        .keyboardType(.decimalPad)
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                }
                if hourlyRate > 0 {
                    Section("Estimate") {
                        let hours = max(0, end.timeIntervalSince(start) / 3_600)
                        Text(String(format: "%.1f h × $%.2f = $%.2f", hours, hourlyRate, hours * hourlyRate))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(existing == nil ? "Add Shift" : "Edit Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(role.trimmingCharacters(in: .whitespaces).isEmpty || end <= start)
                }
            }
        }
    }

    private func save() {
        if var existing {
            existing.start = start
            existing.end = end
            existing.role = role
            existing.hourlyRate = hourlyRate
            existing.notes = notes
            schedule.update(existing)
        } else {
            schedule.add(Shift(start: start, end: end, role: role, hourlyRate: hourlyRate, notes: notes))
        }
        if schedule.lastError == nil { dismiss() }
    }
}
