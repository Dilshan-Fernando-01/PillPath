//
//  CropImageView.swift
//  PillPath — OCR Module
//
//  Lets the user select a rectangular region of the captured image before
//  OCR processing. Drag corners to resize, drag inside to reposition.
//  Helps eliminate non-medication text (hospital name, address, etc.).
//

import SwiftUI

struct CropImageView: View {

    let image: UIImage
    var onConfirm: (UIImage) -> Void
    var onSkip: () -> Void

    // Crop rect in normalised image coordinates (0 … 1)
    @State private var norm = CGRect(x: 0.08, y: 0.08, width: 0.84, height: 0.84)
    @State private var dragOrigin: CGRect?

    private enum CornerHandle: CaseIterable, Hashable {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private let handleSize: CGFloat = 28
    private let minNormSize: CGFloat = 0.08

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let imgFrame = displayFrame(for: image, in: geo.size)

                ZStack {
                    // The image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imgFrame.width, height: imgFrame.height)
                        .position(x: imgFrame.midX, y: imgFrame.midY)

                    // Dark vignette outside crop hole (even-odd fill creates the hole)
                    CropMaskShape(normRect: norm)
                        .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
                        .frame(width: imgFrame.width, height: imgFrame.height)
                        .position(x: imgFrame.midX, y: imgFrame.midY)
                        .allowsHitTesting(false)

                    // Crop border + grid
                    let cf = cropScreenFrame(imgFrame: imgFrame)
                    cropBorderAndGrid(cf)

                    // Body drag to reposition
                    bodyDrag(cf, imgFrame: imgFrame)

                    // Four corner drag handles
                    ForEach(CornerHandle.allCases, id: \.self) { handle in
                        cornerHandle(handle, cropFrame: cf, imgFrame: imgFrame)
                    }
                }
            }

            // Bottom controls always visible
            VStack {
                Spacer()
                bottomControls
            }
        }
    }

    // MARK: - Controls

    private var bottomControls: some View {
        VStack(spacing: 12) {
            Text("Drag corners to select the medication text area")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button {
                    onSkip()
                } label: {
                    Text("Use Full Image")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)

                Button {
                    onConfirm(croppedImage())
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "crop")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Crop & Scan")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brandPrimary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 40)
    }

    // MARK: - Crop border + grid

    @ViewBuilder
    private func cropBorderAndGrid(_ cf: CGRect) -> some View {
        // Border
        Rectangle()
            .stroke(Color.white, lineWidth: 2)
            .frame(width: cf.width, height: cf.height)
            .position(x: cf.midX, y: cf.midY)
            .allowsHitTesting(false)

        // Rule-of-thirds grid
        let col1 = cf.minX + cf.width / 3
        let col2 = cf.minX + cf.width * 2 / 3
        let row1 = cf.minY + cf.height / 3
        let row2 = cf.minY + cf.height * 2 / 3

        Path { p in
            p.move(to: .init(x: col1, y: cf.minY)); p.addLine(to: .init(x: col1, y: cf.maxY))
            p.move(to: .init(x: col2, y: cf.minY)); p.addLine(to: .init(x: col2, y: cf.maxY))
            p.move(to: .init(x: cf.minX, y: row1)); p.addLine(to: .init(x: cf.maxX, y: row1))
            p.move(to: .init(x: cf.minX, y: row2)); p.addLine(to: .init(x: cf.maxX, y: row2))
        }
        .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        .allowsHitTesting(false)
    }

    // MARK: - Body drag

    private func bodyDrag(_ cf: CGRect, imgFrame: CGRect) -> some View {
        Color.clear
            .frame(width: max(0, cf.width - handleSize * 2),
                   height: max(0, cf.height - handleSize * 2))
            .position(x: cf.midX, y: cf.midY)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if dragOrigin == nil { dragOrigin = norm }
                        guard let origin = dragOrigin else { return }
                        let dx = value.translation.width  / imgFrame.width
                        let dy = value.translation.height / imgFrame.height
                        var n = origin.offsetBy(dx: dx, dy: dy)
                        n.origin.x = max(0, min(n.origin.x, 1 - n.width))
                        n.origin.y = max(0, min(n.origin.y, 1 - n.height))
                        norm = n
                    }
                    .onEnded { _ in dragOrigin = nil }
            )
    }

    // MARK: - Corner handle

    private func cornerHandle(_ handle: CornerHandle, cropFrame cf: CGRect, imgFrame: CGRect) -> some View {
        let pos = cornerPoint(handle, in: cf)
        return ZStack {
            Circle().fill(Color.white).frame(width: handleSize, height: handleSize)
            Circle().fill(Color.brandPrimary).frame(width: handleSize - 6, height: handleSize - 6)
        }
        .position(pos)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if dragOrigin == nil { dragOrigin = norm }
                    guard let origin = dragOrigin else { return }
                    let dx = value.translation.width  / imgFrame.width
                    let dy = value.translation.height / imgFrame.height
                    norm = updatedNorm(origin, handle: handle, dx: dx, dy: dy)
                }
                .onEnded { _ in dragOrigin = nil }
        )
    }

    private func updatedNorm(_ n: CGRect, handle: CornerHandle, dx: CGFloat, dy: CGFloat) -> CGRect {
        var out = n
        switch handle {
        case .topLeft:
            let nx = max(0,           min(n.maxX - minNormSize, n.minX + dx))
            let ny = max(0,           min(n.maxY - minNormSize, n.minY + dy))
            out = CGRect(x: nx, y: ny, width: n.maxX - nx, height: n.maxY - ny)
        case .topRight:
            let ny = max(0,           min(n.maxY - minNormSize, n.minY + dy))
            let nw = max(minNormSize, min(1 - n.minX,           n.width  + dx))
            out = CGRect(x: n.minX, y: ny, width: nw, height: n.maxY - ny)
        case .bottomLeft:
            let nx = max(0,           min(n.maxX - minNormSize, n.minX + dx))
            let nh = max(minNormSize, min(1 - n.minY,           n.height + dy))
            out = CGRect(x: nx, y: n.minY, width: n.maxX - nx, height: nh)
        case .bottomRight:
            let nw = max(minNormSize, min(1 - n.minX, n.width  + dx))
            let nh = max(minNormSize, min(1 - n.minY, n.height + dy))
            out = CGRect(x: n.minX, y: n.minY, width: nw, height: nh)
        }
        return out
    }

    // MARK: - Helpers

    private func displayFrame(for img: UIImage, in size: CGSize) -> CGRect {
        let ia = img.size.width / img.size.height
        let ca = size.width / size.height
        let w, h: CGFloat
        if ia > ca { w = size.width; h = size.width / ia }
        else        { h = size.height; w = size.height * ia }
        return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
    }

    private func cropScreenFrame(imgFrame: CGRect) -> CGRect {
        CGRect(
            x: imgFrame.minX + norm.minX * imgFrame.width,
            y: imgFrame.minY + norm.minY * imgFrame.height,
            width:  norm.width  * imgFrame.width,
            height: norm.height * imgFrame.height
        )
    }

    private func cornerPoint(_ handle: CornerHandle, in cf: CGRect) -> CGPoint {
        switch handle {
        case .topLeft:     return CGPoint(x: cf.minX, y: cf.minY)
        case .topRight:    return CGPoint(x: cf.maxX, y: cf.minY)
        case .bottomLeft:  return CGPoint(x: cf.minX, y: cf.maxY)
        case .bottomRight: return CGPoint(x: cf.maxX, y: cf.maxY)
        }
    }

    /// Crops UIImage to the normalised selection rect.
    private func croppedImage() -> UIImage {
        let pw = image.size.width
        let ph = image.size.height
        let pxRect = CGRect(x: norm.minX * pw, y: norm.minY * ph,
                            width: norm.width * pw, height: norm.height * ph)
        guard let cg = image.cgImage?.cropping(to: pxRect) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }
}

// MARK: - Mask shape (full rect minus crop hole using even-odd winding)

private struct CropMaskShape: Shape {
    let normRect: CGRect

    func path(in rect: CGRect) -> Path {
        var p = Path(rect)
        p.addRect(CGRect(
            x: normRect.minX * rect.width,
            y: normRect.minY * rect.height,
            width:  normRect.width  * rect.width,
            height: normRect.height * rect.height
        ))
        return p
    }
}

#Preview {
    CropImageView(
        image: UIImage(systemName: "photo.fill")!,
        onConfirm: { _ in },
        onSkip: {}
    )
}
