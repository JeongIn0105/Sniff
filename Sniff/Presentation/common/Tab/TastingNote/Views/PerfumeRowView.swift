//
//  PerfumeRowView.swift
//  Sniff
//

// MARK: - 보유/LIKE 향수 목록 공통 행 뷰
import SwiftUI
import Kingfisher

struct PerfumeRowView: View {

    let name: String
    let brand: String
    let scentFamilies: [String]
    let imageURL: String?
    let date: Date?

    var body: some View {
        HStack(spacing: 12) {
            // 썸네일
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))

                if let urlString = imageURL,
                   let url = URL(string: urlString) {
                    KFImage(url)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 4) {
                // 향수명
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                // 브랜드 | 향 계열
                HStack(spacing: 4) {
                    Text(brand)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if !scentFamilies.isEmpty {
                        Text("|")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray4))

                        ForEach(scentFamilies.prefix(2), id: \.self) { family in
                            HStack(spacing: 3) {
                                Circle()
                                    .frame(width: 4, height: 4)
                                    .foregroundColor(family.accordColor)
                                Text(family)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // 날짜
                if let date {
                    Text(date.tastingNoteFormat)
                        .font(.system(size: 12))
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }

            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .contentShape(Rectangle())
    }
}
