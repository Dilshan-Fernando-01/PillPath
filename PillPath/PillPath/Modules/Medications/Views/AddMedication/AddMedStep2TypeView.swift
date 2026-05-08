
import SwiftUI

struct AddMedStep2TypeView: View {

    @ObservedObject var viewModel: AddMedicationViewModel

    private let primaryForms: [MedicationForm] = [.tablet, .capsule, .liquid, .injection]
    private let secondaryForms: [MedicationForm] = [.patch, .inhaler, .other]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "What type of medication is it?",
                subtitle: "Select the form that matches your medication."
            )

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: AppSpacing.md
            ) {
                ForEach(primaryForms) { form in
                    MedicationTypeCard(
                        form: form,
                        isSelected: viewModel.selectedForm == form
                    ) {
                        viewModel.selectedForm = form
                    }
                }
            }

            HStack(spacing: AppSpacing.sm) {
                ForEach(secondaryForms) { form in
                    compactTypeCard(form)
                }
            }

            Spacer()
        }
    }


    private func compactTypeCard(_ form: MedicationForm) -> some View {
        let isSelected = viewModel.selectedForm == form
        return Button {
            viewModel.selectedForm = form
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimaryLight)
                        .frame(width: 44, height: 44)
                    Image(systemName: form.systemIcon)
                        .font(.system(size: 18))
                        .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                }
                Text(form.displayName)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(Color.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(isSelected ? Color.brandPrimary : Color.appBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
