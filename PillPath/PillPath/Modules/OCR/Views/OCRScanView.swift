//
//  OCRScanView.swift
//  PillPath — OCR Module
//
//  Root container for the prescription scan flow.
//  Routes between camera → analyzing → review → success screens.
//

import SwiftUI

struct OCRScanView: View {

    @StateObject private var viewModel = PrescriptionScanViewModel()
    @EnvironmentObject private var settings: SettingsViewModel
    @State private var showCamera = false
    @State private var showGallery = false

    var body: some View {
        NavigationStack {
            ZStack {
                switch viewModel.step {
                case .camera:
                    PrescriptionCameraView(viewModel: viewModel,
                                          showCamera: $showCamera,
                                          showGallery: $showGallery)
                case .analyzing:
                    PrescriptionAnalyzingView()
                case .review:
                    PrescriptionReviewView(viewModel: viewModel)
                case .done:
                    prescriptionSuccessView
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.step == .camera)
            .navigationBarHidden(viewModel.step == .camera)
        }
        .fullScreenCover(isPresented: $showCamera) {
            ImagePickerView(source: .camera) { image in
                showCamera = false
                viewModel.processImage(image)
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showGallery) {
            ImagePickerView(source: .photoLibrary) { image in
                showGallery = false
                viewModel.processImage(image)
            } onCancel: {
                showGallery = false
            }
        }
        // Advanced edit redirect
        .sheet(item: $viewModel.advancedEditViewModel) { vm in
            AddMedicationFlowView(viewModel: vm)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Success view

    private var prescriptionSuccessView: some View {
        SuccessView(
            title: "\(viewModel.savedMedications.count) Medication\(viewModel.savedMedications.count == 1 ? "" : "s") Saved!",
            subtitle: "Your schedule has been updated.",
            items: viewModel.savedMedications.map { med in
                SuccessItem(title: med.name, subtitle: "\(med.dosageDisplay) • Once daily")
            },
            primaryActionLabel: "Go to Home",
            secondaryActionLabel: "Scan Another",
            onPrimary: {
                NotificationCenter.default.post(name: .switchToHomeTab, object: nil)
            },
            onSecondary: { viewModel.scanAnother() }
        )
    }
}

// MARK: - Camera / Landing screen

struct PrescriptionCameraView: View {

    @ObservedObject var viewModel: PrescriptionScanViewModel
    @Binding var showCamera: Bool
    @Binding var showGallery: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                cameraFrameGuide
                Spacer()
            }

            // Top nav overlay
            VStack {
                HStack {
                    Spacer()
                    Text("Scan Prescription")
                        .foregroundStyle(.white)
                        .font(AppFont.headline())
                    Spacer()
                }
                .padding(.top, AppSpacing.lg)
                Spacer()
            }
        }
        // Use safeAreaInset so controls sit above the custom bottom nav bar
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomControls
        }
    }

    private var cameraFrameGuide: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Align your prescription within the frame")
                .font(AppFont.subheadline())
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.brandPrimary, lineWidth: 2)
                    .frame(width: 280, height: 380)

                // Corner accent marks
                Group {
                    cornerMark(xSign: -1, ySign: -1)
                    cornerMark(xSign:  1, ySign: -1)
                    cornerMark(xSign: -1, ySign:  1)
                    cornerMark(xSign:  1, ySign:  1)
                }
            }
        }
    }

    private func cornerMark(xSign: CGFloat, ySign: CGFloat) -> some View {
        ZStack {
            Rectangle().fill(Color.brandPrimary).frame(width: 24, height: 3)
            Rectangle().fill(Color.brandPrimary).frame(width: 3, height: 24)
        }
        .offset(x: xSign * 140, y: ySign * 190)
    }

    private var bottomControls: some View {
        VStack(spacing: AppSpacing.md) {
            Button { showCamera = true } label: {
                ZStack {
                    Circle()
                        .fill(Color.brandPrimary)
                        .frame(width: 72, height: 72)
                        .appButtonShadow()
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }
            }

            Button { showGallery = true } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 16))
                    Text("Upload from gallery")
                        .font(AppFont.subheadline())
                }
                .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.vertical, AppSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.7))
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
    static let switchToTab     = Notification.Name("switchToTab")
}

#Preview {
    OCRScanView()
        .environmentObject(SettingsViewModel())
}
