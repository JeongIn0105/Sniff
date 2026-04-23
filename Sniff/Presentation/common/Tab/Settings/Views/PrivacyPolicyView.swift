//
//  PrivacyPolicyView.swift
//  Sniff
//

import SwiftUI

struct PrivacyPolicyView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    titleSection

                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }

    private var headerView: some View {
        HStack(spacing: 4) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44)
            }

            Text(AppStrings.PrivacyPolicy.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppStrings.PrivacyPolicy.title)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.primary)

            Text(AppStrings.PrivacyPolicy.updatedAt)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
    }

    private func sectionView(_ section: PolicySection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(section.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)

            if let body = section.body {
                Text(body)
                    .font(.system(size: 17))
                    .foregroundColor(Color(.label))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !section.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(section.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Text(AppStrings.PrivacyPolicy.bullet)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.primary)

                            Text(bullet)
                                .font(.system(size: 17))
                                .foregroundColor(Color(.label))
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if let footer = section.footer {
                Text(footer)
                    .font(.system(size: 17))
                    .foregroundColor(Color(.label))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let email = section.email {
                HStack(alignment: .top, spacing: 10) {
                    Text(AppStrings.PrivacyPolicy.bullet)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("\(AppStrings.PrivacyPolicy.emailPrefix) \(email)")
                        .font(.system(size: 17))
                        .foregroundColor(Color(.label))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private let sections: [PolicySection] = AppStrings.PrivacyPolicy.sections.map(PolicySection.init)
}

private struct PolicySection: Identifiable {
    let id = UUID()
    let title: String
    var body: String? = nil
    var bullets: [String] = []
    var footer: String? = nil
    var email: String? = nil

    nonisolated init(content: PolicySectionContent) {
        self.title = content.title
        self.body = content.body
        self.bullets = content.bullets
        self.footer = content.footer
        self.email = content.email
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
