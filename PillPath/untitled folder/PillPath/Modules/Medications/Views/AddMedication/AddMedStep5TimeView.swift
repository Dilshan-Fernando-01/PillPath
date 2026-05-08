

import SwiftUI

struct AddMedStep5TimeView: View {

    @ObservedObject var viewModel: AddMedicationViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xl) {

            stepHeader(
                title: "When do you take it?",
                subtitle: "Select all time slots that apply. You can add a custom time too."
            )

           
            TimeOfDayGrid(selected: $viewModel.selectedTimeLabels)

        
            customTimesSection

            Spacer()
        }
    }

  

    private var customTimesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionLabel(text: "Custom Times")

           
            if !viewModel.customTimes.isEmpty {
                VStack(spacing: 0) {
                    ForEach(viewModel.customTimes) { time in
                        HStack {
                            Image(systemName: "clock")
                                .foregroundStyle(Color.brandPrimary)
                                .frame(width: 20)
                            Text(time.displayString)
                                .font(AppFont.body())
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Button {
                                viewModel.removeCustomTime(time)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(Color.semanticError)
                            }
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .padding(.horizontal, AppSpacing.md)
                        if time.id != viewModel.customTimes.last?.id {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .background(Color.appSurface)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                .appCardShadow()
            }

            
            if viewModel.showCustomTimePicker {
                customTimePicker
            } else {
                Button {
                    viewModel.showCustomTimePicker = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                        Text("Add Custom Time")
                            .font(AppFont.subheadline())
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(Color.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppSpacing.md)
                    .background(Color.brandPrimaryLight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                }
                .buttonStyle(.plain)
            }
        }
    }

   

    private var customTimePicker: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: 0) {
             
                Picker("Hour", selection: $viewModel.customTimePickerHour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Text(":")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                
                Picker("Minute", selection: $viewModel.customTimePickerMinute) {
                    ForEach([0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55], id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
            }
            .frame(height: 120)

            HStack(spacing: AppSpacing.sm) {
                SecondaryButton(title: "Cancel") {
                    viewModel.showCustomTimePicker = false
                }
                PrimaryButton(title: "Add Time") {
                    viewModel.addCustomTime()
                }
            }
        }
        .padding(AppSpacing.md)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
        .appCardShadow()
    }
}
