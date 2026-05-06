//
//  HomeViewController.swift
//  Sniff
//
//  Created by t2025-m0239 on 2026.04.13.
//

import Combine
import Kingfisher
import RxCocoa
import RxSwift
import SnapKit
import SwiftUI
import UIKit

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private let userTasteRepository: UserTasteRepositoryType
    private let collectionRepository: CollectionRepositoryType
    private let tastingRecordRepository: TastingRecordRepositoryType
    private let localTastingNoteRepository: LocalTastingNoteRepository
    private let disposeBag = DisposeBag()
    private let homeRefreshRelay = PublishRelay<Void>()
    private let state = HomeScreenState()
    private var profileChangeObserver: NSObjectProtocol?
    private var hostingController: UIHostingController<HomeScreenView>?

    init(
        viewModel: HomeViewModel,
        userTasteRepository: UserTasteRepositoryType,
        collectionRepository: CollectionRepositoryType,
        tastingRecordRepository: TastingRecordRepositoryType,
        localTastingNoteRepository: LocalTastingNoteRepository
    ) {
        self.viewModel = viewModel
        self.userTasteRepository = userTasteRepository
        self.collectionRepository = collectionRepository
        self.tastingRecordRepository = tastingRecordRepository
        self.localTastingNoteRepository = localTastingNoteRepository
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        if let profileChangeObserver {
            NotificationCenter.default.removeObserver(profileChangeObserver)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupHostingView()
        bind()
        observeProfileChange()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        loadLikedPerfumes()
        loadTastingNoteKeys()
    }
}

private extension HomeViewController {
    func setupHostingView() {
        view.backgroundColor = .systemBackground

        let rootView = HomeScreenView(
            state: state,
            onAddPerfume: { [weak self] in
                self?.navigateToOwnedPerfumeRegistration()
            },
            onProfileTap: { [weak self] in
                self?.navigateToTasteProfile()
            },
            onPerfumeTap: { [weak self] item in
                self?.navigateToPerfumeDetail(item.perfume)
            },
            onLikeTap: { [weak self] item in
                self?.toggleLike(for: item)
            },
            onRefresh: { [weak self] in
                self?.homeRefreshRelay.accept(())
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.view.backgroundColor = .systemBackground
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }

    func observeProfileChange() {
        profileChangeObserver = NotificationCenter.default.addObserver(
            forName: .tasteProfileDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            self.homeRefreshRelay.accept(())
            guard
                let title = notification.userInfo?["title"] as? String,
                let families = notification.userInfo?["families"] as? [String]
            else { return }

            self.state.banner = HomeTasteBannerItem(
                title: title,
                summary: self.state.banner.summary,
                familyText: families.joined(separator: "·")
            )
            self.state.profileTitleOverride = title
            self.state.profileFamiliesOverride = families
        }
    }

    func bind() {
        let collectionNotifications = NotificationCenter.default.rx
            .notification(.perfumeCollectionDidChange)
            .share()

        collectionNotifications
            .subscribe(onNext: { [weak self] _ in
                self?.loadLikedPerfumes()
            })
            .disposed(by: disposeBag)

        let tastingNoteNotifications = NotificationCenter.default.rx
            .notification(.tastingNotesDidChange)
            .share()

        tastingNoteNotifications
            .subscribe(onNext: { [weak self] _ in
                self?.loadTastingNoteKeys()
            })
            .disposed(by: disposeBag)

        let recommendationRefresh = Observable.merge(
            collectionNotifications
                .filter { $0.shouldRefreshHomeRecommendations }
                .map { _ in },
            tastingNoteNotifications.map { _ in }
        )

        let homeRefresh = Observable.merge(
            homeRefreshRelay.asObservable(),
            recommendationRefresh
        )
        .throttle(.milliseconds(500), scheduler: MainScheduler.instance)

        let input = HomeViewModel.Input(
            viewDidLoad: Observable.just(()),
            refresh: homeRefresh,
            perfumeRegisterTap: .never(),
            tastingNoteTap: .never(),
            reportTap: .never(),
            perfumeSelect: .never()
        )

        let output = viewModel.transform(input: input)

        bindBanner(output.banner)
        bindProfile(output.profile)
        bindRecommendations(output.recommendations)
        bindPopularRecommendations(output.popularRecommendations)
        bindRecommendationEmptyState(output.recommendationEmptyState)
        bindRoute(output.route)
    }

    func bindBanner(_ banner: Driver<HomeTasteBannerItem>) {
        banner
            .drive(with: self) { owner, item in
                owner.state.banner = item
            }
            .disposed(by: disposeBag)
    }

    func bindProfile(_ profile: Driver<HomeViewModel.HomeProfileItem?>) {
        profile
            .drive(with: self) { owner, item in
                owner.state.profileTitleOverride = nil
                owner.state.profileFamiliesOverride = nil
                owner.state.profileItem = item
            }
            .disposed(by: disposeBag)
    }

    func bindRecommendations(_ recommendations: Driver<[HomePerfumeItem]>) {
        recommendations
            .drive(with: self) { owner, items in
                owner.state.recommendations = items
            }
            .disposed(by: disposeBag)
    }

    func bindPopularRecommendations(_ recommendations: Driver<[HomePerfumeItem]>) {
        recommendations
            .drive(with: self) { owner, items in
                owner.state.popularRecommendations = items
            }
            .disposed(by: disposeBag)
    }

    func bindRecommendationEmptyState(_ emptyState: Driver<HomeRecommendationEmptyState>) {
        emptyState
            .drive(with: self) { owner, state in
                owner.state.recommendationEmptyState = state
            }
            .disposed(by: disposeBag)
    }

    func bindRoute(_ route: Signal<HomeRoute>) {
        route
            .emit(with: self) { owner, route in owner.handleRoute(route) }
            .disposed(by: disposeBag)
    }
}

private extension HomeViewController {
    func handleRoute(_ route: HomeRoute) {
        switch route {
        case .perfumeRegister:
            navigateToOwnedPerfumeRegistration()
        case .tastingNoteWrite:
            presentAlert(AppStrings.UIKitScreens.Home.routeTastingNote)
        case .tasteReport:
            presentAlert(AppStrings.UIKitScreens.Home.routeTasteReport)
        case .perfumeDetail(let perfume):
            navigateToPerfumeDetail(perfume)
        }
    }

    func navigateToOwnedPerfumeRegistration() {
        Task { @MainActor in
            let registrationViewController = SearchSceneFactory.makeOwnedPerfumeRegistrationViewController(
                dependencyContainer: AppDependencyContainer.shared
            )
            navigationController?.pushViewController(registrationViewController, animated: true)
        }
    }

    func navigateToTasteProfile() {
        guard let item = state.profileItem else { return }
        let profileVC = TasteProfileViewController(profileItem: item, userTasteRepository: userTasteRepository)
        navigationController?.pushViewController(profileVC, animated: true)
    }

    func navigateToPerfumeDetail(_ perfume: Perfume) {
        let detailViewController = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailViewController, animated: true)
    }

    func presentAlert(_ message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AppStrings.UIKitScreens.confirm, style: .default))
        present(alert, animated: true)
    }
}

private extension HomeViewController {
    func loadLikedPerfumes() {
        collectionRepository.fetchLikedPerfumes()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] items in
                self?.state.likedPerfumeIDs = Set(items.map(\.id))
            })
            .disposed(by: disposeBag)
    }

    func loadTastingNoteKeys() {
        if let localNotes = try? localTastingNoteRepository.loadNotes() {
            state.tastingNoteKeys = Set(localNotes.flatMap {
                PerfumePresentationSupport.recordMatchingKeys(
                    perfumeName: $0.perfumeName,
                    brandName: $0.brandName
                )
            })
        }

        tastingRecordRepository.fetchTastingRecords()
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] records in
                guard let self else { return }
                let remoteKeys = Set(records.flatMap {
                    PerfumePresentationSupport.recordMatchingKeys(
                        perfumeName: $0.perfumeName,
                        brandName: $0.brandName
                    )
                })
                self.state.tastingNoteKeys = self.state.tastingNoteKeys.union(remoteKeys)
            }, onFailure: { _ in })
            .disposed(by: disposeBag)
    }

    func toggleLike(for item: HomePerfumeItem) {
        let collectionID = Perfume.collectionDocumentID(from: item.id)
        if state.likedPerfumeIDs.contains(collectionID) {
            deleteLike(id: collectionID)
        } else {
            saveLike(for: item)
        }
    }

    func saveLike(for item: HomePerfumeItem) {
        let collectionID = Perfume.collectionDocumentID(from: item.id)
        let perfume = Perfume(
            id: item.id,
            name: item.perfumeName,
            brand: item.brandName,
            imageUrl: item.imageURL,
            rawMainAccords: item.parsedAccords,
            mainAccords: item.parsedAccords,
            topNotes: nil,
            middleNotes: nil,
            baseNotes: nil,
            concentration: nil,
            gender: nil,
            season: nil,
            situation: nil,
            longevity: nil,
            sillage: nil
        )

        collectionRepository.saveLikedPerfume(perfume)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                self.state.likedPerfumeIDs = self.state.likedPerfumeIDs.union([collectionID])
                NotificationCenter.default.postPerfumeCollectionDidChange(scope: .liked)
            }, onError: { [weak self] error in
                self?.presentLikeMutationError(error)
            })
            .disposed(by: disposeBag)
    }

    func deleteLike(id: String) {
        collectionRepository.deleteLikedPerfume(id: id)
            .observe(on: MainScheduler.instance)
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                self.state.likedPerfumeIDs = self.state.likedPerfumeIDs.subtracting([id])
                NotificationCenter.default.postPerfumeCollectionDidChange(scope: .liked)
            }, onError: { [weak self] error in
                self?.presentLikeMutationError(error)
            })
            .disposed(by: disposeBag)
    }

    func presentLikeMutationError(_ error: Error) {
        if let limitError = error as? CollectionUsageLimitError {
            showAppToast(message: limitError.localizedDescription, bottomOffset: 84)
        } else {
            presentAlert(error.localizedDescription)
        }
    }
}

private final class HomeScreenState: ObservableObject {
    @Published var banner = HomeTasteBannerItem(
        title: AppStrings.Home.pendingTitle,
        summary: AppStrings.Home.emptySummary,
        familyText: ""
    )
    @Published var profileItem: HomeViewModel.HomeProfileItem?
    @Published var profileTitleOverride: String?
    @Published var profileFamiliesOverride: [String]?
    @Published var recommendations: [HomePerfumeItem] = []
    @Published var popularRecommendations: [HomePerfumeItem] = []
    @Published var recommendationEmptyState: HomeRecommendationEmptyState = .insufficientData
    @Published var likedPerfumeIDs = Set<String>()
    @Published var tastingNoteKeys = Set<String>()
}

private struct HomeScreenView: View {
    @ObservedObject var state: HomeScreenState
    let onAddPerfume: () -> Void
    let onProfileTap: () -> Void
    let onPerfumeTap: (HomePerfumeItem) -> Void
    let onLikeTap: (HomePerfumeItem) -> Void
    let onRefresh: () -> Void
    @State private var showsPopularRecommendationInfo = false

    private var visibleRecommendations: [HomePerfumeItem] {
        Array(state.recommendations.prefix(5))
    }

    private var visiblePopularRecommendations: [HomePerfumeItem] {
        Array(state.popularRecommendations.prefix(5))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                profileHero
                    .padding(.horizontal, 16)
                    .padding(.top, 18)

                recommendationSection
                    .padding(.top, 24)

                popularRecommendationSection
                    .padding(.top, 28)

                guideView
                    .padding(.horizontal, 16)
                    .padding(.top, 34)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .refreshable {
            onRefresh()
        }
        .alert(
            AppStrings.Home.popularRecommendInfoTitle,
            isPresented: $showsPopularRecommendationInfo
        ) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(AppStrings.Home.popularRecommendInfoMessage)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            Text(AppStrings.UIKitScreens.Home.title)
                .font(.custom("Hahmlet-Bold", size: 24))
                .tracking(2)
                .foregroundColor(.primary)

            Spacer(minLength: 0)

            Button(action: onAddPerfume) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.UIKitScreens.PerfumeDetail.addCollection)
        }
    }

    private var profileHero: some View {
        Button(action: onProfileTap) {
            ZStack(alignment: .topLeading) {
                HomeProfileGradientBackground(
                    title: profileTitle,
                    fallbackFamilies: profileFamilies
                )

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(profileTitle)
                            .font(.custom("Hahmlet-Bold", size: 24))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer(minLength: 0)
                    }

                    Text(profileSummary)
                        .font(.custom("Pretendard-Medium", size: 13))
                        .foregroundColor(Color(red: 0.30, green: 0.30, blue: 0.30))
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        ForEach(profileTags, id: \.self) { tag in
                            profileTag(tag)
                        }
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 18)
                .padding(.top, 24)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
            .frame(height: 334)
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.10), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var recommendationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(AppStrings.Home.recommendTitle)
                .padding(.horizontal, 16)

            if visibleRecommendations.isEmpty {
                recommendationEmptyView
                    .padding(.horizontal, 16)
            } else {
                perfumeRail(visibleRecommendations)
            }
        }
    }

    @ViewBuilder
    private var popularRecommendationSection: some View {
        if !visiblePopularRecommendations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                popularRecommendationHeader
                    .padding(.horizontal, 16)
                perfumeRail(visiblePopularRecommendations)
            }
        }
    }

    private var popularRecommendationHeader: some View {
        HStack(spacing: 6) {
            sectionTitle(AppStrings.Home.popularRecommendTitle)

            Button {
                showsPopularRecommendationInfo = true
            } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(red: 0.60, green: 0.60, blue: 0.60).opacity(0.55))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppStrings.Home.popularRecommendInfoTitle)

            Spacer(minLength: 0)
        }
    }

    private func perfumeRail(_ items: [HomePerfumeItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 16) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HomePerfumeCardView(
                        item: item,
                        isLiked: isLiked(item),
                        hasTastingRecord: hasTastingRecord(item),
                        onTap: { onPerfumeTap(item) },
                        onLikeTap: { onLikeTap(item) }
                    )
                    .frame(width: 132, height: 226)
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var recommendationEmptyView: some View {
        VStack(spacing: 10) {
            Image(systemName: state.recommendationEmptyState.systemImageName)
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(Color(red: 0.69, green: 0.69, blue: 0.69))

            Text(state.recommendationEmptyState.message)
                .font(.custom("Pretendard-Medium", size: 14))
                .foregroundColor(Color(red: 0.45, green: 0.45, blue: 0.45))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 226)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var guideView: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.69, green: 0.69, blue: 0.69))
                .frame(width: 20, height: 20)

            Text(AppStrings.UIKitScreens.Home.guide)
                .font(.custom("Pretendard-Medium", size: 12))
                .foregroundColor(Color(red: 0.69, green: 0.69, blue: 0.69))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.leading, 12)
        .padding(.trailing, 12)
        .padding(.vertical, 16)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.custom("Pretendard-SemiBold", size: 18))
            .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
    }

    private func profileTag(_ tag: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color(uiColor: ScentFamilyColor.color(for: tag)))
                .frame(width: 8, height: 8)

            Text(tag)
                .font(.custom("Pretendard-Medium", size: 12))
                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.82))
        .clipShape(Capsule())
    }

    private var profileTitle: String {
        state.profileTitleOverride ?? state.profileItem?.profile.displayTitle ?? state.banner.title
    }

    private var profileSummary: String {
        if let profile = state.profileItem?.profile, state.banner.title.isEmpty {
            return profile.analysisSummary
        }
        return state.banner.summary
    }

    private var profileFamilies: [String] {
        if let override = state.profileFamiliesOverride {
            return Array(override.prefix(2))
        }
        if let profile = state.profileItem?.profile {
            return Array(profile.displayFamilies.prefix(2))
        }
        return state.banner.familyText
            .components(separatedBy: "·")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private var profileTags: [String] {
        let tags = profileFamilies.map(displayName(for:))
        return tags.isEmpty ? ["취향 분석", "추천 업데이트"] : Array(tags.prefix(2))
    }

    private func isLiked(_ item: HomePerfumeItem) -> Bool {
        state.likedPerfumeIDs.contains(Perfume.collectionDocumentID(from: item.id))
    }

    private func hasTastingRecord(_ item: HomePerfumeItem) -> Bool {
        let keys = PerfumePresentationSupport.recordMatchingKeys(
            perfumeName: item.perfumeName,
            brandName: item.brandName
        )
        return item.hasTastingRecord || !state.tastingNoteKeys.isDisjoint(with: keys)
    }

    private func displayName(for family: String) -> String {
        switch family {
        case "Soft Floral": return "소프트 플로럴"
        case "Floral": return "플로럴"
        case "Floral Amber": return "플로럴 앰버"
        case "Soft Amber": return "소프트 앰버"
        case "Amber": return "앰버"
        case "Woody Amber": return "우디 앰버"
        case "Woods": return "우디"
        case "Mossy Woods": return "모시 우즈"
        case "Dry Woods": return "드라이 우즈"
        case "Citrus": return "시트러스"
        case "Fruity": return "프루티"
        case "Green": return "그린"
        case "Water": return "워터"
        case "Aromatic": return "아로마틱"
        default: return family
        }
    }
}

private struct HomePerfumeCardView: View {
    let item: HomePerfumeItem
    let isLiked: Bool
    let hasTastingRecord: Bool
    let onTap: () -> Void
    let onLikeTap: () -> Void

    private var accords: [String] {
        item.accordsText
            .components(separatedBy: "  ")
            .map { $0.replacingOccurrences(of: "• ", with: "").trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .map { PerfumePresentationSupport.displayAccord($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            imageCard

            Text(PerfumePresentationSupport.displayBrand(item.brandName))
                .font(.custom("Pretendard-Medium", size: 14))
                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                .lineLimit(1)
                .frame(height: 16)
                .padding(.top, 10)

            Text(PerfumePresentationSupport.displayPerfumeName(item.perfumeName))
                .font(.custom("Pretendard-Medium", size: 15))
                .foregroundColor(Color(red: 0.13, green: 0.13, blue: 0.13))
                .lineLimit(2)
                .frame(height: 40, alignment: .topLeading)
                .padding(.top, 2)

                FlowLayout(spacing: 6) {
                    ForEach(Array(accords.enumerated()), id: \.offset) { _, accord in
                        accordPill(accord)
                    }
                }
            .padding(.top, 4)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    private var imageCard: some View {
        ZStack(alignment: .topLeading) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))

                perfumeImage
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(.separator).opacity(0.12), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if hasTastingRecord {
                Text("시향 기록")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(red: 0.47, green: 0.39, blue: 0.31))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.95, green: 0.92, blue: 0.88))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(Color(red: 0.80, green: 0.75, blue: 0.68), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(8)
            }

            Button(action: onLikeTap) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isLiked ? PerfumeHeartStyle.activeColor : PerfumeHeartStyle.inactiveColor)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        }
        .frame(width: 132, height: 132)
    }

    @ViewBuilder
    private var perfumeImage: some View {
        if let urlString = item.imageURL, let url = URL(string: urlString) {
            KFImage(url)
                .resizable()
                .placeholder { placeholderBottle }
                .scaledToFit()
        } else {
            placeholderBottle
        }
    }

    private var placeholderBottle: some View {
        VStack(spacing: 8) {
            VStack(spacing: 0) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(red: 0.86, green: 0.83, blue: 0.79))
                    .frame(width: 18, height: 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(.systemBackground).opacity(0.90))
                        .frame(width: 80, height: 80)

                    Text(String(item.brandName.prefix(1)).uppercased())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(red: 0.55, green: 0.48, blue: 0.40))
                }
            }

            Text(AppStrings.UIKitScreens.PerfumeDetail.imagePlaceholder)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(Color(red: 0.55, green: 0.48, blue: 0.40))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
    }

    private func accordPill(_ accord: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(uiColor: ScentFamilyColor.color(for: accord)))
                .frame(width: 8, height: 8)

            Text(accord)
                .font(.custom("Pretendard-Medium", size: 13))
                .foregroundColor(Color(red: 0.52, green: 0.52, blue: 0.52))
                .lineLimit(1)
        }
        .frame(height: 18)
    }
}

private struct HomeProfileGradientBackground: View {
    let title: String
    let fallbackFamilies: [String]

    var body: some View {
        RadialGradient(
            gradient: Gradient(colors: colors),
            center: UnitPoint(x: 0.48, y: 0),
            startRadius: 0,
            endRadius: 360
        )
    }

    private var colors: [Color] {
        if let preset = TasteProfileGradientIconView.profilePreset(forTitle: title) {
            return preset.colors.map { Color(uiColor: $0) }
        }

        if let palette = FragranceProfileText.profileColorPalette(forTitle: title) {
            return [
                Color(hex: palette.accentHex),
                Color(hex: palette.primaryHex),
                Color(hex: palette.baseHex)
            ]
        }

        let top1Color = fallbackFamilies.first.map { ScentFamilyColor.color(for: $0) }
        let top2Color = fallbackFamilies.dropFirst().first.map { ScentFamilyColor.color(for: $0) }

        let color20 = (top2Color ?? top1Color?.softened(amount: 0.25)
            ?? UIColor(red: 0.95, green: 0.90, blue: 0.68, alpha: 1))
            .softened(amount: 0.20)
        let color45 = (top1Color
            ?? UIColor(red: 0.66, green: 0.81, blue: 0.91, alpha: 1))
            .softened(amount: 0.30)

        return [
            Color(uiColor: color20),
            Color(uiColor: color45),
            Color(red: 0.95, green: 0.91, blue: 0.87)
        ]
    }
}
