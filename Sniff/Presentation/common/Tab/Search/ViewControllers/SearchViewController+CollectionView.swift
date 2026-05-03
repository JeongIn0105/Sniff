//
//  SearchViewController+CollectionView.swift
//  Sniff
//

import UIKit
import RxSwift

// MARK: - UICollectionViewDataSource & Delegate

extension SearchViewController: UICollectionViewDataSource, UICollectionViewDelegate {

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
        cell.configure(with: perfume, isLiked: likedPerfumeIDs.contains(collectionID))

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
        let perfume = filteredPerfumeResults[indexPath.item]
        let detailVC = PerfumeDetailSceneFactory.makeViewController(perfume: perfume)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
