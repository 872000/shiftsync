import SwiftUI
import ShiftSync

struct PayView: View {
    @Environment(ScheduleViewModel.self) private var schedule

    private enum Period: String, CaseIterable {
        case thisWeek = "This Week"
        case lastWeek = "Last Week"
        case thisMonth = "This Month"
    }

    @State private var period: Period = .thisWeek

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Period", selection: $period) {
                    ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                let interval = intervalFor(period)
                let breakdown = PayEstimator.breakdown(
                    for: schedule.store.shifts,
                    in: interval,
                    policy: schedule.payPolicy
                )

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Estimated pay")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.2f", breakdown.totalPay))
                                .font(.largeTitle.bold())
                            Text("\(breakdown.shiftCount) shifts · \(String(format: "%.1f", breakdown.totalHours)) h")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 8)
                    }

                    Section("Breakdown") {
                        payRow(label: "Regular", hours: breakdown.regularHours, pay: breakdown.regularPay)
                        payRow(label: "Overtime ×\(schedule.payPolicy.overtimeMultiplier, specifier: "%.1f")",
                               hours: breakdown.overtimeHours, pay: breakdown.overtimePay,
                               highlight: breakdown.overtimeHours > 0)
                    }

                    Section("Overtime policy") {
                        HStack {
                            Text("OT after (h/week)")
                            Spacer()
                            TextField("40", value: $schedule.payPolicy.regularHoursPerWeek, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                        }
                        HStack {
                            Text("OT multiplier")
                            Spacer()
                            TextField("1.5", value: $schedule.payPolicy.overtimeMultiplier, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 70)
                        }
                    }

                    Section("Details") {
                        Text(String(format: "Effective rate: $%.2f/h", breakdown.effectiveHourlyRate))
                        Text("\(interval.start, style: .date) – \(interval.end, style: .date)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Pay Estimator")
        }
    }

    private func payRow(label: String, hours: Double, pay: Double, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: "%.1f h · $%.2f", hours, pay))
                .foregroundStyle(highlight ? .orange : .secondary)
        }
    }

    private func intervalFor(_ period: Period) -> DateInterval {
        let now = Date()
        switch period {
        case .thisWeek:
            return PayPeriod.week(containing: now)
        case .lastWeek:
            let thisWeek = PayPeriod.week(containing: now)
            let start = Calendar.current.date(byAdding: .day, value: -7, to: thisWeek.start) ?? thisWeek.start
            return DateInterval(start: start, duration: 7 * 86_400)
        case .thisMonth:
            return PayPeriod.month(containing: now)
        }
    }
}
