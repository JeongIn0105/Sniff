//
//  OwnedPerfumeRegistrationView.swift
//  Sniff
//

import SwiftUI

struct OwnedPerfumeRegistrationView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: OwnedPerfumeRegistrationViewModel
    @FocusState private var isSearchFocused: Bool

    init(viewModel: OwnedPerfumeRegistrationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    private var isSearchResultMode: Bool {
        !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && viewModel.selectedPerfume == nil
    }

    private var displayedSearchResults: [Perfume] {
        Array(viewModel.searchResults.prefix(3))
    }

    private var memoBinding: Binding<String> {
        Binding(
            get: { viewModel.memo },
            set: { viewModel.updateMemo($0) }
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                headerView

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        searchSection
                            .padding(.top, 28)

                        Divider()
                            .padding(.top, viewModel.selectedPerfume == nil && isSearchResultMode ? 40 : 28)

                        disabledAwareForm
                            .padding(.top, 32)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 118)
                }
            }
            .background(Color(.systemBackground).ignoresSafeArea())

            bottomRegisterButton

            if let message = viewModel.toastMessage {
                toastView(message)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 94)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .task {
            await viewModel.loadOwnedPerfumes()
        }
        .onChange(of: viewModel.searchText) { _ in
            viewModel.scheduleSearch()
        }
        .onChange(of: viewModel.didSave) { didSave in
            guard didSave else { return }
            dismiss()
        }
        .alert(AppStrings.UIKitScreens.error, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(AppStrings.UIKitScreens.confirm) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.toastMessage)
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 34, height: 44)
            }

            Text("보유 향수 등록")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 4)
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            requiredSectionTitle("향수")

            if let perfume = viewModel.selectedPerfume {
                selectedPerfumeSection(perfume)
            } else {
                searchField

                if viewModel.isSearching {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else if isSearchResultMode {
                    searchResultsList
                }
            }
        }
    }

    private func requiredSectionTitle(_ title: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.primary)

            Text("필수")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(.systemGray3))
        }
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(.systemGray3))

            TextField("향수명 또는 브랜드명", text: $viewModel.searchText)
                .focused($isSearchFocused)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit {
                    viewModel.submitSearch()
                }

            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    viewModel.clearSelectedPerfume()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(.systemGray3))
                }
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 64)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    isSearchFocused || !viewModel.searchText.isEmpty ? Color.primary : Color(.systemGray5),
                    lineWidth: isSearchFocused || !viewModel.searchText.isEmpty ? 2 : 1.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var searchResultsList: some View {
        VStack(spacing: 0) {
            Text(viewModel.searchResultCountText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.systemGray2))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

            if displayedSearchResults.isEmpty {
                Text(AppStrings.TastingNoteFormUI.noSearchResult)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(.systemGray2))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 22)
            } else {
                ForEach(Array(displayedSearchResults.enumerated()), id: \.element.id) { index, perfume in
                    Button {
                        viewModel.selectPerfume(perfume)
                        isSearchFocused = false
                    } label: {
                        perfumeResultRow(perfume, isHighlighted: index == 0)
                    }
                    .buttonStyle(.plain)

                    if index < displayedSearchResults.count - 1 {
                        Divider()
                            .padding(.leading, 92)
                    }
                }
            }
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.systemGray5), lineWidth: 1.2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 12)
    }

    private func perfumeResultRow(_ perfume: Perfume, isHighlighted: Bool) -> some View {
        HStack(spacing: 18) {
            CollectedPerfumeThumbnailView(imageURL: perfume.imageUrl, size: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(PerfumePresentationSupport.displayBrand(perfume.brand))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(1)

                Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(resultAccordText(for: perfume))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color(.systemGray4))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(isHighlighted ? Color(hex: "#F4F2EF") : Color(.systemBackground))
    }

    private func selectedPerfumeSection(_ perfume: Perfume) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            selectedPerfumeCard(perfume)

            HStack(spacing: 0) {
                Text("다른 향수라면 ")
                    .foregroundColor(Color(.systemGray2))

                Button {
                    viewModel.clearSelectedPerfume()
                    isSearchFocused = true
                } label: {
                    Text("다시 검색")
                        .foregroundColor(.primary)
                        .underline()
                }
                .buttonStyle(.plain)

                Text("할 수 있어요")
                    .foregroundColor(Color(.systemGray2))
            }
            .font(.system(size: 14, weight: .semibold))
        }
    }

    private func selectedPerfumeCard(_ perfume: Perfume) -> some View {
        HStack(spacing: 20) {
            CollectedPerfumeThumbnailView(imageURL: perfume.imageUrl, size: 76)

            VStack(alignment: .leading, spacing: 5) {
                Text(PerfumePresentationSupport.displayBrand(perfume.brand))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(1)

                Text(PerfumePresentationSupport.displayPerfumeName(perfume.name))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(resultAccordText(for: perfume))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(.systemGray2))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var disabledAwareForm: some View {
        VStack(alignment: .leading, spacing: 28) {
            registrationOptionGroup(
                title: "사용 상태",
                options: CollectedPerfumeUsageStatus.allCases,
                selection: $viewModel.usageStatus,
                isEnabled: viewModel.canEditDetails
            )

            registrationOptionGroup(
                title: "사용 빈도",
                options: CollectedPerfumeUsageFrequency.allCases,
                selection: $viewModel.usageFrequency,
                isEnabled: viewModel.canEditDetails
            )

            registrationOptionGroup(
                title: "취향 강도",
                options: CollectedPerfumePreferenceLevel.allCases,
                selection: $viewModel.preferenceLevel,
                isEnabled: viewModel.canEditDetails
            )

            memoSection
        }
        .opacity(viewModel.canEditDetails ? 1 : 0.28)
    }

    private func registrationOptionGroup<Value: Hashable>(
        title: String,
        options: [Value],
        selection: Binding<Value?>,
        isEnabled: Bool
    ) -> some View {
        CollectedPerfumeOptionGroup(
            title: title,
            options: options,
            selectedValue: selection.wrappedValue,
            isEnabled: isEnabled,
            isRequiredTitle: true,
            titleFontSize: 17,
            cornerRadius: 26,
            onSelect: { selection.wrappedValue = $0 }
        )
    }

    private var memoSection: some View {
        CollectedPerfumeMemoEditor(
            text: memoBinding,
            titleFontSize: 17,
            height: 112,
            countText: viewModel.memoCountText,
            isEnabled: viewModel.canEditDetails,
            disabledMessage: "향수를 먼저 선택해야 입력할 수 있어요"
        )
    }

    private var bottomRegisterButton: some View {
        VStack(spacing: 0) {
            Divider()

            Button {
                Task { await viewModel.register() }
            } label: {
                ZStack {
                    Text(viewModel.isSaving ? "작성 중" : "작성완료")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(viewModel.isSaving ? 0 : 1)

                    if viewModel.isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(viewModel.canRegister ? Color.primary : Color(.systemGray5))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(!viewModel.canRegister)
            .padding(.horizontal, 20)
            .padding(.top, 5)
            .padding(.bottom, 17)
            .background(Color(.systemBackground))
        }
    }

    private func toastView(_ message: String) -> some View {
        Text(message)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.84))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func resultAccordText(for perfume: Perfume) -> String {
        let accords = PerfumePresentationSupport
            .displayAccords(Array(perfume.mainAccords.prefix(2)))
        return accords.isEmpty ? "향 정보 없음" : accords.joined(separator: " · ")
    }
}

#Preview {
    NavigationStack {
        OwnedPerfumeRegistrationView(
            viewModel: OwnedPerfumeRegistrationViewModel(
                perfumeCatalogRepository: AppDependencyContainer.shared.makePerfumeCatalogRepository(),
                collectionRepository: AppDependencyContainer.shared.makeCollectionRepository()
            )
        )
    }
}
