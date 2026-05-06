//
//  SearchViewController+CollectionView.swift
//  Sniff
//

import UIKit
import RxSwift
import RxCocoa

// MARK: - UICollectionViewDataSource & Delegate

extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredPerfumeResults.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PerfumeGridCell.identifier,
            for: indexPath
        ) as! PerfumeGridCell
        let perfume = filteredPerfumeResults[indexPath.item]
        let collectionID = perfume.collectionDocumentID
        let hasTastingRecord = !tastingNoteKeys.isDisjoint(
            with: PerfumePresentationSupport.recordMatchingKeys(
                perfumeName: perfume.name,
                brandName: perfume.brand
            )
        )
        cell.configure(
            with: perfume,
            isLiked: likedPerfumeIDs.contains(collectionID),
            hasTastingRecord: hasTastingRecord
        )

        cell.wishlistButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self else { return }
                if self.likedPerfumeIDs.contains(collectionID) {
                    self.deleteLikedPerfume(id: collectionID)
                } else {
                    self.saveLikedPerfume(perfume)
                }
            })
            .disposed(by: cell.disposeBag)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard filteredPerfumeResults.indices.contains(indexPath.item) else { return }
        let perfume = filteredPerfumeResults[indexPath.item]
        if mode == .register {
            registerCollectedPerfume(perfume)
            return
        }

        let detailVC = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let horizontalInset: CGFloat = 48
        let spacing: CGFloat = 16
        let width = floor((collectionView.bounds.width - horizontalInset - spacing) / 2)
        return CGSize(width: width, height: width + 100)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(top: 18, left: 24, bottom: 110, right: 24)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        20
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        16
    }
}
