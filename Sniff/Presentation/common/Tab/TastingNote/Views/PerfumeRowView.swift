//
//  PerfumeRowView.swift
//  Sniff
//

// MARK: - 보유/LIKE 향수 목록 공통 행 뷰
import SwiftUI

struct PerfumeRowView: View {

    let name: String
    let brand: String
    let scentFamilies: [String]
    let imageURL: String?
    let date: Date?

    var body: some View {
        HStack(spacing: 12) {
            PerfumeCardArtworkView(
                imageURL: imageURL,
                perfumeName: name,
                style: .listThumbnail
            )
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(PerfumePresentationSupport.displayPerfumeName(name))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(PerfumePresentationSupport.displayBrand(brand))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)

                    if !scentFamilies.isEmpty {
                        Text("|")
                            .font(.system(size: 13))
                            .foregroundColor(Color(.systemGray4))
                        ForEach(PerfumePresentationSupport.displayAccords(Array(scentFamilies.prefix(2))), id: \.self) { family in
                            (Text("● ").foregroundColor(family.accordColor)
                                + Text(family).foregroundColor(.secondary))
                                .font(.system(size: 13))
                                .lineLimit(1)
                        }
                    }
                }

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
