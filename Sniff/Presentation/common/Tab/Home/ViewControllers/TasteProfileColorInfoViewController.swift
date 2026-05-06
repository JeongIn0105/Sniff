//
//  TasteProfileColorInfoViewController.swift
//  Sniff
//

import SwiftUI
import UIKit

final class TasteProfileColorInfoViewController: UIViewController {
    private var hostingController: UIHostingController<TasteProfileColorInfoSheetView>?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
    }
}

private extension TasteProfileColorInfoViewController {
    func setupHostingView() {
        view.backgroundColor = .systemBackground

        let rootView = TasteProfileColorInfoSheetView(
            onClose: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .systemBackground

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }
}

private struct TasteProfileColorInfoSheetView: View {
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, 40)
                .padding(.horizontal, 24)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    descriptionSection

                    ForEach(TasteProfileGradientPreset.presets) { preset in
                        TasteProfileColorInfoRow(preset: preset)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemBackground))
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("취향 프로필(홈 색상) 정보")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("*취향 프로필은 총 9종류로, 각각의 취향 프로필은 가장 두드러지는 향 계열을 바탕으로 색상이 결정됩니다.")
            Text("*취향 프로필은 보유 향수와 시향기록이 쌓여지는 것에 따라 변경될 수 있습니다. 같은 취향 프로필 안에서도 중심 향 계열은 달라질 수 있으며, 색상은 취향 프로필 기준으로 유지될 수 있습니다.")
        }
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(Color(red: 0.443, green: 0.443, blue: 0.443))
        .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TasteProfileColorInfoRow: View {
    let preset: TasteProfileGradientPreset

    var body: some View {
        HStack(spacing: 14) {
            TasteProfileColorInfoIcon(preset: preset)
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(preset.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(red: 0.102, green: 0.102, blue: 0.102))
                    .lineLimit(1)

                Text(preset.subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.443, green: 0.443, blue: 0.443))
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
    }
}

private struct TasteProfileColorInfoIcon: View {
    let preset: TasteProfileGradientPreset

    var body: some View {
        RadialGradient(
            gradient: Gradient(stops: preset.gradientStops),
            center: UnitPoint(x: 0.5, y: 0.04),
            startRadius: 0,
            endRadius: 62
        )
    }
}

private extension TasteProfileGradientPreset {
    var gradientStops: [Gradient.Stop] {
        zip(colors, locations).map {
            Gradient.Stop(color: Color(uiColor: $0.0), location: CGFloat(truncating: $0.1))
        }
    }
}
