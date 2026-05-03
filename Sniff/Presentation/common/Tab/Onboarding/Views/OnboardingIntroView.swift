//
//  OnboardingIntroView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI

struct OnboardingIntroView: View {
    let onStart: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let topTextInset = geometry.size.height * 0.15
            let bottomButtonInset = geometry.size.height * 0.145

            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: topTextInset)

                    Text(AppStrings.AppShell.Intro.title)
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(.black)
                        .lineSpacing(8)

                    Text(AppStrings.AppShell.Intro.subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: "#6F6F6F"))
                        .lineSpacing(5)
                        .padding(.top, 18)

                    Spacer()

                    PerfumeIntroIllustration()
                        .frame(maxWidth: .infinity)
                        .frame(height: 190)
                        .padding(.bottom, 22)

                    Button(action: onStart) {
                        Text(AppStrings.AppShell.Intro.start)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color(hex: "#242424"))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .padding(.bottom, bottomButtonInset)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
            }
        }
    }
}

private struct PerfumeIntroIllustration: View {
    var body: some View {
        HStack(alignment: .bottom, spacing: 9) {
            AtomizerBottleView()
                .frame(width: 70, height: 120)

            BlackBottleView()
                .frame(width: 70, height: 128)

            TallGreenBottleView()
                .frame(width: 58, height: 170)

            RoundBlueBottleView()
                .frame(width: 66, height: 100)
        }
        .padding(.horizontal, 6)
    }
}

private struct AtomizerBottleView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(Color.black)
                .frame(width: 48, height: 70)
                .offset(x: -20, y: -42)

            Capsule()
                .fill(Color.black)
                .frame(width: 12, height: 38)
                .offset(x: 7, y: -80)

            Path { path in
                path.move(to: CGPoint(x: 32, y: 104))
                path.addLine(to: CGPoint(x: 48, y: 26))
                path.addLine(to: CGPoint(x: 66, y: 104))
                path.closeSubpath()
            }
            .fill(Color(hex: "#F5D2B8"))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 32, y: 104))
                    path.addLine(to: CGPoint(x: 48, y: 26))
                    path.addLine(to: CGPoint(x: 66, y: 104))
                    path.closeSubpath()
                }
                .stroke(Color.black.opacity(0.18), lineWidth: 1)
            )

            HStack(spacing: 4) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule()
                        .fill(Color(hex: "#F9A987"))
                        .frame(width: 8, height: 24)
                }
            }
            .offset(y: 2)
        }
    }
}

private struct BlackBottleView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(hex: "#111111"))
                .frame(width: 58, height: 88)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#D8C8EA"), Color(hex: "#A18AB8")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 52, height: 20)
                .offset(y: -88)

            Rectangle()
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
                .frame(width: 30, height: 38)
                .offset(y: -26)
        }
    }
}

private struct TallGreenBottleView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Path { path in
                path.move(to: CGPoint(x: 14, y: 164))
                path.addLine(to: CGPoint(x: 24, y: 48))
                path.addLine(to: CGPoint(x: 38, y: 48))
                path.addLine(to: CGPoint(x: 50, y: 164))
                path.closeSubpath()
            }
            .fill(Color(hex: "#A7D7C1"))
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 14, y: 164))
                    path.addLine(to: CGPoint(x: 24, y: 48))
                    path.addLine(to: CGPoint(x: 38, y: 48))
                    path.addLine(to: CGPoint(x: 50, y: 164))
                    path.closeSubpath()
                }
                .stroke(Color.black.opacity(0.18), lineWidth: 1)
            )

            Diamond()
                .fill(Color(hex: "#111111"))
                .frame(width: 24, height: 34)
                .offset(y: -126)

            Diamond()
                .fill(Color(hex: "#85C1E3"))
                .frame(width: 10, height: 24)
                .offset(y: -129)

            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule()
                        .stroke(Color.black.opacity(0.22), lineWidth: 1)
                        .frame(width: 4, height: 112)
                }
            }
            .offset(y: -3)
        }
    }
}

private struct RoundBlueBottleView: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F8F7F4"), Color(hex: "#B9D9F0")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 62, height: 62)
                .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 1))

            Circle()
                .fill(Color(hex: "#EFA28A"))
                .frame(width: 36, height: 36)
                .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 1))
                .offset(y: -50)

            Rectangle()
                .fill(Color(hex: "#C9D9E6"))
                .frame(width: 20, height: 18)
                .offset(y: -37)

            WaveLine()
                .stroke(Color(hex: "#EB8E7A"), lineWidth: 1.4)
                .frame(width: 34, height: 28)
                .offset(y: -12)
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

private struct WaveLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY),
            control1: CGPoint(x: rect.width * 0.25, y: rect.minY),
            control2: CGPoint(x: rect.width * 0.75, y: rect.maxY)
        )
        return path
    }
}
