
import SwiftUI

struct RestockSheet: View {

    let medication: Medication
    var onConfirm: (Int) -> Void
    var onDismiss: () -> Void

    @State private var amountText: String = ""
    @State private var validationError: String?

    private var amount: Int { Int(amountText.trimmingCharacters(in: .whitespaces)) ?? 0 }
    private var newTotal: Int { medication.currentQuantity + amount }

    private var unitName: String {
        let units = medication.dosageUnit.displayName
        if medication.dosageUnit == .pills {
            return amount == 1 ? "pill" : "pills"
        }
        return units
    }

    private var formIcon: String {
        switch medication.dosageUnit {
        case .pills: return "pills.fill"
        case .ml:    return "drop.fill"
        case .mg:    return "capsule.fill"
        }
    }

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Color.appBorder)
                .frame(width: 40, height: 4)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.md)

            VStack(spacing: 4) {
                Text("Restock Medication")
                    .font(AppFont.headline())
                    .foregroundStyle(Color.textPrimary)
                Text(medication.name)
                    .font(AppFont.caption())
                    .foregroundStyle(Color.textSecondary)
            }
            .padding(.bottom, AppSpacing.lg)

            VStack(spacing: AppSpacing.md) {

                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimaryLight)
                            .frame(width: 48, height: 48)
                        Image(systemName: formIcon)
                            .font(.system(size: 20))
                            .foregroundStyle(Color.brandPrimary)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Stock")
                            .font(AppFont.caption())
                            .foregroundStyle(Color.textSecondary)
                        Text("\(medication.currentQuantity) \(medication.dosageUnit.displayName)")
                            .font(AppFont.body())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.textPrimary)
                    }
                    Spacer()
                }
                .padding(AppSpacing.md)
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Add Quantity")
                        .font(AppFont.caption())
                        .foregroundStyle(Color.textSecondary)
                    HStack(spacing: AppSpacing.sm) {
                        TextField("0", text: $amountText)
                            .keyboardType(.numberPad)
                            .font(AppFont.body())
                            .padding(AppSpacing.md)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(Color.appBorder, lineWidth: 1))
                        Text(unitName)
                            .font(AppFont.body())
                            .foregroundStyle(Color.textSecondary)
                            .frame(minWidth: 50, alignment: .leading)
                    }
                }

                HStack(spacing: AppSpacing.sm) {
                    ForEach([10, 30, 60], id: \.self) { preset in
                        Button {
                            amountText = String(preset)
                        } label: {
                            Text("+\(preset)")
                                .font(AppFont.caption())
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.brandPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppSpacing.sm)
                                .background(Color.brandPrimaryLight)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }

                if amount > 0 {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(Color.semanticSuccess)
                        Text("New total: \(newTotal) \(medication.dosageUnit.displayName)")
                            .font(AppFont.body())
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.semanticSuccess)
                        Spacer()
                    }
                    .padding(AppSpacing.md)
                    .background(Color.semanticSuccess.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }

                if let err = validationError {
                    Text(err)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.semanticError)
                }
            }
            .padding(.horizontal, AppSpacing.md)

            Spacer().frame(height: AppSpacing.lg)

            VStack(spacing: AppSpacing.sm) {
                Button {
                    guard amount > 0 else {
                        validationError = "Enter an amount greater than 0."
                        return
                    }
                    onConfirm(amount)
                } label: {
                    Text("Confirm Restock")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(amount > 0 ? Color.brandPrimary : Color.brandPrimary.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
                .disabled(amount <= 0)

                Button {
                    onDismiss()
                } label: {
                    Text("Cancel")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppSpacing.md)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(Color.appBackground)
    }
}
