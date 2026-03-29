//
//  OCRScanView.swift
//  PillPath — OCR Module
//
//  Root container for the prescription scan flow.
//  Routes between camera → analyzing → review → success screens.
//

import SwiftUI
import PhotosUI

struct OCRScanView: View {

    @StateObject private var viewModel = PrescriptionScanViewModel()
    @EnvironmentObject private var settings: SettingsViewModel

    // Picker state lives here — no binding tunnelling required
    @State private var showCamera  = false
    @State private var showGallery = false

    var body: some View {
        ZStack {
            switch viewModel.step {
            case .camera:
                cameraLandingScreen
            case .analyzing:
                PrescriptionAnalyzingView()
            case .review:
                NavigationStack { PrescriptionReviewView(viewModel: viewModel) }
            case .done:
                NavigationStack { prescriptionSuccessView }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.step == .camera)
        // Camera picker
        .fullScreenCover(isPresented: $showCamera) {
            ImagePickerView(source: .camera) { image in
                showCamera = false
                viewModel.processImage(image)
            } onCancel: {
                showCamera = false
            }
            .ignoresSafeArea()
        }
        // Gallery picker
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

    // MARK: - Camera landing screen (inline — no sub-view binding tunnel)

    private var cameraLandingScreen: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Title
                Text("Scan Prescription")
                    .foregroundStyle(.white)
                    .font(AppFont.headline())
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.md)

                Spacer()

                // Viewfinder frame guide
                cameraFrameGuide

                Spacer()

                // Buttons — live here, read @State directly
                cameraButtons
            }
        }
    }

    private var cameraFrameGuide: some View {
        VStack(spacing: AppSpacing.lg) {
            Text("Point your camera at the prescription label")
                .font(AppFont.subheadline())
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)

            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.brandPrimary, lineWidth: 2)
                    .frame(width: 280, height: 340)

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
        .offset(x: xSign * 140, y: ySign * 170)
    }

    private var cameraButtons: some View {
        VStack(spacing: AppSpacing.lg) {

            // Camera button
            Button {
                showCamera = true
            } label: {
                VStack(spacing: AppSpacing.sm) {
                    ZStack {
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 72, height: 72)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    Text("Take Photo")
                        .font(AppFont.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .buttonStyle(.plain)

            // Gallery button — clearly labelled
            Button {
                showGallery = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 18))
                    Text("Choose from Gallery")
                        .font(AppFont.body())
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, AppSpacing.xl)
                .padding(.vertical, AppSpacing.md)
                .background(Color.white.opacity(0.15))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, AppSpacing.xl)
        .frame(maxWidth: .infinity)
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

// MARK: - Notification names

extension Notification.Name {
    static let switchToHomeTab = Notification.Name("switchToHomeTab")
    static let switchToTab     = Notification.Name("switchToTab")
}

#Preview {
    OCRScanView()
        .environmentObject(SettingsViewModel())
}
