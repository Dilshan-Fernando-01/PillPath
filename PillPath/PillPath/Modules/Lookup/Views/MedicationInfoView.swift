

import SwiftUI

struct MedicationInfoView: View {

    let result: MedicationSearchResult
    @Environment(\.dismiss) private var dismiss
    @State private var showAddFlow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {

                  headerSection

                    if let indications = result.indications, !indications.isEmpty {
                        infoSection(title: "WHAT IT IS USED FOR") {
                            Text(indications)
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if !result.dosageAndAdministration.isEmpty {
                        infoSection(title: "HOW TO USE") {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                ForEach(Array(result.dosageAndAdministration.prefix(4).enumerated()), id: \.offset) { index, step in
                                    HStack(alignment: .top, spacing: AppSpacing.sm) {
                                        Text("\(index + 1)")
                                            .font(AppFont.caption())
                                            .fontWeight(.bold)
                                            .foregroundStyle(.white)
                                            .frame(width: 20, height: 20)
                                            .background(Color.brandPrimary)
                                            .clipShape(Circle())

                                        Text(step.truncated(to: 180))
                                            .font(AppFont.body())
                                            .foregroundStyle(Color.textPrimary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                    }

                  if !result.sideEffects.isEmpty {
                        infoSection(title: "SIDE EFFECTS") {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                let effects = sideEffectLines
                                ForEach(effects, id: \.self) { effect in
                                    HStack(spacing: AppSpacing.sm) {
                                        Circle()
                                            .stroke(Color.textSecondary, lineWidth: 1)
                                            .frame(width: 7, height: 7)
                                        Text(effect)
                                            .font(AppFont.body())
                                            .foregroundStyle(Color.textPrimary)
                                    }
                                }
                                if let disclaimer = sideEffectDisclaimer {
                                    Text(disclaimer)
                                        .font(AppFont.caption())
                                        .foregroundStyle(Color.textSecondary)
                                        .padding(.top, AppSpacing.xs)
                                }
                            }
                        }
                    }

                  if let warnings = result.warnings, !warnings.isEmpty {
                        warningsSection(warnings)
                    }

                   specificationsSection

                    Spacer().frame(height: 100)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.md)
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Medication Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }
           .safeAreaInset(edge: .bottom, spacing: 0) {
                footerButtons
            }
        }
        .sheet(isPresented: $showAddFlow) {
            AddMedicationFlowView(viewModel: AddMedicationViewModel.prefilled(
                name: result.brandName,
                form: dosageFormEnum
            ))
        }
    }

   

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
          
            if let cls = result.pharmClass.first {
                Text(cls.uppercased())
                    .font(AppFont.label())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, 4)
                    .background(Color.brandPrimaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm))
            }

            Text(result.brandName)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Color.textPrimary)

            if let generic = result.genericName {
                Text("Common name: \(generic)")
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

   

    private func infoSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)

            Divider()

            content()
        }
    }

  

    private func warningsSection(_ raw: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
           
            HStack(spacing: AppSpacing.sm) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.semanticWarning)
                Text("CRITICAL WARNINGS")
                    .font(AppFont.label())
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.semanticWarning.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(Array(warningBullets(raw).enumerated()), id: \.offset) { _, bullet in
                    Text(bullet)
                        .font(AppFont.caption())
                        .foregroundStyle(Color.semanticError)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.semanticWarning.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md)
                .stroke(Color.semanticWarning.opacity(0.3), lineWidth: 1)
        )
    }



    private var specificationsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("SPECIFICATIONS")
                .font(AppFont.label())
                .foregroundStyle(Color.textSecondary)
                .kerning(0.5)

            Divider()

            VStack(spacing: 0) {
                if let cls = result.pharmClass.first {
                    specRow(label: "Classification", value: cls)
                    Divider().padding(.leading, AppSpacing.md)
                }
                if !result.dosageForms.isEmpty {
                    specRow(label: "Form", value: result.dosageForms.joined(separator: " / "))
                    Divider().padding(.leading, AppSpacing.md)
                }
                if let mfr = result.manufacturer {
                    specRow(label: "Manufacturer", value: mfr)
                }
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
            .appCardShadow()
        }
    }

    private func specRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(AppFont.body())
                .foregroundStyle(Color.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.body())
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

   

    private var footerButtons: some View {
        VStack(spacing: AppSpacing.sm) {
            Button {
                showAddFlow = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add to My Medications")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.md)
                .background(Color.brandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .appButtonShadow()
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                Text("Save for Later")
                    .font(AppFont.body())
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.md)
                            .stroke(Color.brandPrimary, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(Color.appBackground)
    }

  

    private var dosageFormEnum: MedicationForm {
        let raw = result.dosageForms.first?.lowercased() ?? ""
        if raw.contains("capsule") { return .capsule }
        if raw.contains("liquid") || raw.contains("solution") || raw.contains("suspension") { return .liquid }
        if raw.contains("inject") { return .injection }
        if raw.contains("patch") { return .patch }
        if raw.contains("inhaler") || raw.contains("inhal") { return .inhaler }
        return .tablet
    }

   private var sideEffectLines: [String] {
        let raw = result.sideEffects.first ?? ""
        if raw.isEmpty { return result.sideEffects }
        let splitOn: Character = raw.contains(";") ? ";" : ","
        return raw.split(separator: splitOn)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .prefix(6)
            .map { $0.capitalized }
    }

    private var sideEffectDisclaimer: String? {
        guard !result.sideEffects.isEmpty else { return nil }
        return "Most people do not experience significant side effects when taken at the recommended dose."
    }

     private func warningBullets(_ raw: String) -> [String] {
       let sentences = raw.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return Array(sentences.prefix(3))
    }
}


private extension String {
    func truncated(to length: Int) -> String {
        count > length ? String(prefix(length)) + "…" : self
    }
}
