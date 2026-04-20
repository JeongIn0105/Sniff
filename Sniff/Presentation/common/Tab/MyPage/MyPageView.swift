//
//  MyPageView.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct MyPageView: View {

    @StateObject private var viewModel: MyPageViewModel

    init(viewModel: MyPageViewModel = MyPageViewModel()) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    // 프로필 이미지 관련 상태
    @State private var showImageOptions = false
    @State private var showPhotoPicker = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil

    // 보유 향수 미리보기: 2열
    private let ownedPreviewColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    // LIKE 향수 미리보기: 3열
    private let likedPreviewColumns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    headerSection
                    profileSection
                    ownedSection
                        .padding(.top, 12)
                    likedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .task {
                await viewModel.load()
            }
            .onAppear {
                profileImage = loadLocalProfileImage()
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .onChange(of: selectedPhoto) { item in
                Task {
                    guard let item,
                          let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else { return }
                    profileImage = image
                    saveLocalProfileImage(image)
                    selectedPhoto = nil
                }
            }
            .alert("오류", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )) {
                Button("확인") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("마이페이지")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
    }

    private var profileSection: some View {
        HStack(spacing: 16) {
            // 프로필 이미지 (탭 시 변경 옵션 표시)
            Button {
                showImageOptions = true
            } label: {
                Group {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 72, height: 72)
                            .foregroundColor(Color(.systemGray4))
                    }
                }
            }
            .buttonStyle(.plain)
            .confirmationDialog("프로필 이미지", isPresented: $showImageOptions, titleVisibility: .visible) {
                Button("앨범에서 선택") {
                    showPhotoPicker = true
                }
                if profileImage != nil {
                    Button("기본 이미지로 변경", role: .destructive) {
                        profileImage = nil
                        deleteLocalProfileImage()
                    }
                }
                Button("취소", role: .cancel) {}
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.profileInfo?.nickname ?? "사용자")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)

                Text(viewModel.profileInfo?.email ?? "등록된 이메일이 없어요")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }

    private var ownedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("보유 향수")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(viewModel.ownedCount)개")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    OwnedPerfumeListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.ownedPerfumes.isEmpty {
                emptySection(
                    title: "등록된 보유 향수가 없어요",
                    message: "향수 정보 페이지에서 보유 향수를 등록해주세요"
                )
            } else {
                LazyVGrid(columns: ownedPreviewColumns, spacing: 18) {
                    ForEach(viewModel.ownedPerfumes) { perfume in
                        previewCard(
                            imageURL: perfume.imageURL,
                            brand: perfume.brand,
                            name: perfume.name,
                            accords: perfume.accordTags,
                            hasTastingRecord: perfume.hasTastingRecord,
                            isLiked: perfume.isLiked
                        )
                    }
                }
            }
        }
    }

    private var likedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text("LIKE 향수")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)

                Text("\(viewModel.likedCount)개")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                NavigationLink {
                    LikedPerfumeListView()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            if viewModel.likedPerfumes.isEmpty {
                emptySection(
                    title: "등록된 LIKE 향수가 없어요",
                    message: "향수 카드의 하트 아이콘을 눌러 추가해주세요"
                )
            } else {
                // LIKE 향수: 3열 그리드 (와이어프레임 기준)
                LazyVGrid(columns: likedPreviewColumns, spacing: 14) {
                    ForEach(viewModel.likedPerfumes) { perfume in
                        likedPreviewCard(
                            imageURL: perfume.imageURL,
                            brand: perfume.brand,
                            name: perfume.name,
                            accords: perfume.accordTags
                        )
                    }
                }
            }
        }
    }

    private func emptySection(title: String, message: String) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(.systemGray2))

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Color(.systemGray3))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private func previewCard(
        imageURL: String?,
        brand: String,
        name: String,
        accords: [String],
        hasTastingRecord: Bool,
        isLiked: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottomTrailing) {
                    perfumeImage(url: imageURL, height: 152)

                    if isLiked {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(.systemGray2))
                            .padding(.trailing, 10)
                            .padding(.bottom, 10)
                    }
                }

                if hasTastingRecord {
                    tastingRecordBadge
                        .padding(.top, 0)
                        .padding(.leading, 0)
                }
            }

            Text(brand)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
                .lineSpacing(2)
                .lineLimit(2)

            accordTextLine(accords)
        }
    }

    // MARK: - LIKE 향수 3열 미리보기 카드 (하트 아이콘 포함)
    private func likedPreviewCard(
        imageURL: String?,
        brand: String,
        name: String,
        accords: [String]
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))

                    if let urlString = imageURL, let resolvedURL = URL(string: urlString) {
                        KFImage(resolvedURL)
                            .placeholder {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(.systemGray3))
                            }
                            .resizable()
                            .scaledToFit()
                            .padding(12)
                    } else {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 20))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
                .aspectRatio(1, contentMode: .fit)

                // 하트 아이콘 (LIKE 표시)
                Image(systemName: "heart.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray2))
                    .padding(.trailing, 7)
                    .padding(.bottom, 7)
            }

            Text(brand)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)

            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .lineSpacing(1)

            accordTextLine(Array(accords.prefix(2)))
        }
    }

    private func perfumeImage(url: String?, height: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))

            if let url, let imageURL = URL(string: url) {
                KFImage(imageURL)
                    .placeholder {
                        Image(systemName: "shippingbox")
                            .font(.system(size: 28))
                            .foregroundColor(Color(.systemGray3))
                    }
                    .resizable()
                    .scaledToFit()
                    .padding(18)
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: 28))
                    .foregroundColor(Color(.systemGray3))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
    }

    private func accordTextLine(_ accords: [String]) -> some View {
        let displayAccords = Array(accords.prefix(2))

        return HStack(spacing: 8) {
            ForEach(Array(displayAccords.enumerated()), id: \.offset) { index, accord in
                HStack(spacing: 4) {
                    Circle()
                        .fill(index == 0 ? Color(red: 0.97, green: 0.67, blue: 0.67) : Color(.systemGray3))
                        .frame(width: 8, height: 8)

                    Text(accord)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color(.systemGray2))
                        .lineLimit(1)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - 프로필 이미지 로컬 저장

    private static var profileImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sniff_profile_image.jpg")
    }

    private func saveLocalProfileImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: Self.profileImageURL)
    }

    private func loadLocalProfileImage() -> UIImage? {
        guard let data = try? Data(contentsOf: Self.profileImageURL) else { return nil }
        return UIImage(data: data)
    }

    private func deleteLocalProfileImage() {
        try? FileManager.default.removeItem(at: Self.profileImageURL)
    }

    private var tastingRecordBadge: some View {
        Text("시향 기록")
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.leading, 12)
            .padding(.trailing, 18)
            .padding(.vertical, 7)
            .background(Color(.systemGray))
            .clipShape(AttachedTastingRecordBadgeShape())
    }
}

private struct AttachedTastingRecordBadgeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = rect.height / 2

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.midY),
            radius: radius,
            startAngle: .degrees(-90),
            endAngle: .degrees(90),
            clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}

#Preview("데이터 없음") {
    MyPageView()
}

#Preview("데이터 있음") {
    MyPageView(viewModel: .mock())
}
