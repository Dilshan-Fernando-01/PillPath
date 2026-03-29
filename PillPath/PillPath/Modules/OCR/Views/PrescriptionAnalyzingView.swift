//
//  PrescriptionAnalyzingView.swift
//  PillPath — OCR Module
//
//  Step 2: Animated loading screen shown during OCR + FDA validation.
//  Matches Figma: spinning ring, document icon, "Analyzing prescription..." text.
//

import SwiftUI

struct PrescriptionAnalyzingView: View {

    @State private var rotation: Double = 0
    @State private var dotOpacities: [Double] = [1, 0.4, 0.4]

    var body: some View {
        VStack(spacing: AppSpacing.xl) {
            Spacer()

            // Spinning ring + icon
            ZStack {
                Circle()
                    .stroke(Color.brandPrimaryLight, lineWidth: 6)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(
                        LinearGradient(colors: [Color.brandPrimary, Color.brandAccent],
                                       startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(rotation))
                    .animation(.linear(duration: 1.2).repeatForever(autoreverses: false), value: rotation)

                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 42))
                    .foregroundStyle(Color.brandPrimary)
            }

            // Text
            VStack(spacing: AppSpacing.sm) {
                Text("Analyzing prescription...")
                    .font(AppFont.title())
                    .foregroundStyle(Color.textPrimary)

                Text("This will only take a moment.")
                    .font(AppFont.body())
                    .foregroundStyle(Color.textSecondary)

                // Animated dots
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.brandPrimary)
                            .frame(width: 8, height: 8)
                            .opacity(dotOpacities[i])
                    }
                }
                .padding(.top, AppSpacing.sm)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground.ignoresSafeArea())
        .onAppear {
            rotation = 360
            animateDots()
        }
    }

    private func animateDots() {
        let delay = 0.3
        for i in 0..<3 {
            withAnimation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * delay)) {
                dotOpacities[i] = dotOpacities[i] == 1.0 ? 0.2 : 1.0
            }
        }
    }
}

#Preview { PrescriptionAnalyzingView() }
