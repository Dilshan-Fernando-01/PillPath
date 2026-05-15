

import SwiftUI

struct DosagePicker: View {
    @Binding var amount: Double
    @Binding var unit: DosageUnit
    var form: MedicationForm = .tablet

    private var quickValues: [Double] {
        switch form {
        case .inhaler:            return [1, 2, 3, 4]
        case .liquid, .injection: return [5, 10, 15, 20]
        default:                  return [0.5, 1, 1.5, 2]
        }
    }

    private var toggleUnits: [DosageUnit] {
        switch form {
        case .liquid, .injection: return [.ml, .mg]
        case .patch, .inhaler, .other: return [.pills, .mg, .ml]
        default:                 return [.pills, .mg]
        }
    }

    private func unitLabel(_ u: DosageUnit) -> String {
        switch (form, u) {
        case (.inhaler, .pills): return "Puffs"
        case (.patch, .pills):   return "Patch"
        case (.tablet, .pills):  return "Tablet"
        case (.capsule, .pills): return "Capsule"
        case (.other, .pills):   return "Count"
        case (_, .pills):        return "Count"
        case (_, .mg):           return "mg"
        case (_, .ml):           return "mL"
        }
    }

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
        
            HStack(spacing: 0) {
                ForEach(toggleUnits, id: \.self) { u in
                    unitToggle(label: unitLabel(u), unit: u)
                }
            }
            .background(Color.appBackground)
            .clipShape(Capsule())

            HStack(alignment: .lastTextBaseline, spacing: AppSpacing.sm) {
                Text(amountText)
                    .font(.system(size: 72, weight: .black))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.25), value: amount)

                Text(displayUnitLabel)
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(Color.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)

           
            HStack(spacing: AppSpacing.md) {
                ForEach(quickValues, id: \.self) { value in
                    quickChip(value: value)
                }
            }
        }
    }

  

    private func unitToggle(label: String, unit: DosageUnit) -> some View {
        let isSelected = self.unit == unit
        return Button(label) { self.unit = unit }
            .font(AppFont.subheadline())
            .fontWeight(isSelected ? .semibold : .regular)
            .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.appSurface : Color.clear)
            .clipShape(Capsule())
            .padding(4)
    }

    private func quickChip(value: Double) -> some View {
        let isSelected = amount == value
        return Button(action: { withAnimation { amount = value } }) {
            Text(chipLabel(value))
                .font(AppFont.body())
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundStyle(isSelected ? Color.brandPrimary : Color.textPrimary)
                .frame(width: 60, height: 44)
                .background(isSelected ? Color.brandPrimaryLight : Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
                )
        }
        .buttonStyle(.plain)
    }

  

    private var displayUnitLabel: String {
        if form == .inhaler && unit == .pills {
            return amount == 1 ? "puff" : "puffs"
        }
        if form == .patch && unit == .pills {
            return amount == 1 ? "patch" : "patches"
        }
        return unit.displayName
    }

    private var amountText: String {
        amount.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(amount)) : String(amount)
    }

    private func chipLabel(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(value)) : String(value)
    }
}

#Preview {
    @State var amount: Double = 1
    @State var unit: DosageUnit = .pills
    return DosagePicker(amount: $amount, unit: $unit, form: .tablet)
        .padding()
        .background(Color.appBackground)
}
