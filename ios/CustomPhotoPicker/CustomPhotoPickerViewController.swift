//
//  CustomPhotoPickerViewController.swift
//  MultipleImagePicker
//
//  Created by Bảo on 17/01/2021.
//  Copyright © 2021 Facebook. All rights reserved.
//

import Foundation
import Photos
import TLPhotoPicker

class CustomPhotoPickerViewController: TLPhotosPickerViewController {
    var dismissPhotoPicker: ((_ withTLPHAssets: [TLPHAsset]) -> Void)?

    var viewerController: ViewerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        if config.isPreview {
            NotificationCenter.default.addObserver(self, selector: #selector(self.handleCellLongPress(_:)), name: Cell.longPressNotification, object: nil)
        }

        if config.isCrop {
            self.doneButton.title = nil
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            collectionView.addGestureRecognizer(tapGesture)
        }
    }

    deinit {
        // Hủy đăng ký khi ViewController bị giải phóng
        NotificationCenter.default.removeObserver(self)
    }

    func getTotalCount() -> Int {
        var count = 0

        for section in 0 ..< collectionView.numberOfSections {
            count += collectionView.numberOfItems(inSection: section)
        }

        return count
    }

    @objc func handleCellLongPress(_ notification: Notification) {
        if let cell = notification.object as? Cell {
            if let indexPath = collectionView.indexPath(for: cell) {
                self.viewerController = ViewerController(initialIndexPath: indexPath, collectionView: collectionView)

                self.viewerController!.dataSource = self

                let headerView = PreviewHeaderView()
                headerView.viewDelegate = self

                self.viewerController!.headerView = headerView

                if config.singleSelectedMode != true {
                    let footerView = PreviewFooterView()
                    footerView.viewDelegate = self

                    self.viewerController!.footerView = footerView
                }

                self.viewerController?.delegate = self

                self.present(self.viewerController!, animated: true, completion: nil)
            }
        }
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: collectionView)

        if let indexPath = collectionView.indexPathForItem(at: point) {
            handlePhotoTap(at: indexPath)
        }
    }

    func handlePhotoTap(at indexPath: IndexPath) {
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell, let localID = cell.asset?.localIdentifier else { return }

        if let asset = TLPHAsset.asset(with: localID) {
            self.dismissPhotoPicker!([asset])
        }
    }

    override func makeUI() {
        super.makeUI()
        self.collectionView.backgroundColor = .white
        self.customNavItem.leftBarButtonItem?.tintColor = .black
        self.customNavItem.rightBarButtonItem?.tintColor = config.selectedColor

        for subview in self.view.subviews {
            guard let navbar = subview as? UINavigationBar else {
                break
            }
            if #available(iOS 13.0, *) {
                navbar.barTintColor = .systemBackground
            } else {
                navbar.barTintColor = UIColor.white
            }
        }

        if #available(iOS 13.0, *) {
            self.customNavItem.leftBarButtonItem?.tintColor = .label
            self.collectionView.backgroundColor = .systemBackground
            self.view.backgroundColor = .systemBackground
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
}

extension CustomPhotoPickerViewController: ViewerControllerDataSource {
    func numberOfItemsInViewerController(_: ViewerController) -> Int {
        return self.getTotalCount()
    }

    func viewerController(_: ViewerController, viewableAt indexPath: IndexPath) -> Viewable {
        let viewable = PreviewItem(id: UUID().uuidString)

        if let cell = collectionView?.cellForItem(at: indexPath) as? Cell, let placeholder = cell.imageView?.image, let asset = cell.asset {
            viewable.assetID = asset.localIdentifier

            if asset.duration > 0 {
                viewable.type = .video
            }

            viewable.placeholder = placeholder
        }

        return viewable
    }
}

extension CustomPhotoPickerViewController: PreviewHeaderViewDelegate {
    func headerView(_: PreviewHeaderView, didPressClearButton _: UIButton) {
        self.viewerController?.dismiss(nil)
    }

    func headerView(_: PreviewHeaderView, didPressDoneButton _: UIButton) {
        DispatchQueue.main.async {
            self.viewerController?.dismiss {
                DispatchQueue.main.async {
                    if config.singleSelectedMode || (self.selectedAssets.count == 0) {
                        guard
                            let indexPath = self.viewerController?.currentIndexPath,

                                let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell,

                                let localID = cell.asset?.localIdentifier,

                                var asset = TLPHAsset.asset(with: localID),

                                let phAsset = asset.phAsset,

                                self.canSelect(phAsset: phAsset)

                        else { return }

                        self.logDelegate?.selectedPhoto(picker: self, at: indexPath.row)

                        asset.selectedOrder = 1
                        if !config.singleSelectedMode {
                            cell.selectedAsset = true
                            cell.orderLabel?.text = "\(asset.selectedOrder)"
                        }
                        self.selectedAssets = [asset]
                    }

                    self.dismissPhotoPicker!(self.selectedAssets)
                }
            }
        }
    }
}

extension CustomPhotoPickerViewController: PreviewFooterViewDelegate {
    private func canSelect(phAsset: PHAsset) -> Bool {
        if let closure = self.canSelectAsset {
            return closure(phAsset)
        } else if let delegate = self.delegate {
            return delegate.canSelectAsset(phAsset: phAsset)
        }
        return true
    }

    private func getSelectedAssets(_ asset: TLPHAsset) -> TLPHAsset? {
        if let index = self.selectedAssets.firstIndex(where: { $0.phAsset == asset.phAsset }) {
            return self.selectedAssets[index]
        }
        return nil
    }

    private func orderUpdateCells() {
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems.sorted(by: { $0.row < $1.row })

        for indexPath in visibleIndexPaths {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell,
                  let localID = cell.asset?.localIdentifier,
                  let asset = TLPHAsset.asset(with: localID) else { continue }

            if let selectedAsset = getSelectedAssets(asset) {
                cell.selectedAsset = true
                cell.orderLabel?.text = "\(selectedAsset.selectedOrder)"
            } else {
                cell.selectedAsset = false
            }
        }
    }

    func footerView(_: PreviewFooterView, didPressSelectButton button: SelectButton) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        if let indexPath = self.viewerController?.currentIndexPath {
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell, let localID = cell.asset?.localIdentifier else { return }

            guard var asset = TLPHAsset.asset(with: localID), let phAsset = asset.phAsset else { return }

            if let index = selectedAssets.firstIndex(where: { $0.phAsset == asset.phAsset }) {
                // deselect
                logDelegate?.deselectedPhoto(picker: self, at: indexPath.row)
                selectedAssets.remove(at: index)
#if swift(>=4.1)
                selectedAssets = selectedAssets.enumerated().compactMap { offset, asset -> TLPHAsset? in
                    var asset = asset
                    asset.selectedOrder = offset + 1
                    return asset
                }
#else
                selectedAssets = selectedAssets.enumerated().flatMap { offset, asset -> TLPHAsset? in
                    var asset = asset
                    asset.selectedOrder = offset + 1
                    return asset
                }
#endif
                cell.selectedAsset = false
                button.selectedAsset = false
                self.orderUpdateCells()

            } else {
                // select
                logDelegate?.selectedPhoto(picker: self, at: indexPath.row)
                guard !maxCheck(), self.canSelect(phAsset: phAsset) else { return }

                asset.selectedOrder = selectedAssets.count + 1
                selectedAssets.append(asset)
                cell.selectedAsset = true
                button.selectedAsset = true
                cell.orderLabel?.text = "\(asset.selectedOrder)"
                button.setTitle("\(asset.selectedOrder)", for: .normal)
            }
        }
    }
}

extension CustomPhotoPickerViewController: ViewerControllerDelegate {
    func viewerController(_ viewerController: ViewerController, didChangeFocusTo indexPath: IndexPath) {
        if indexPath.row == 0 {
            let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell

            if cell?.isCameraCell == true {
                viewerController.dismiss(nil)
                return
            }
        }

        guard let footerView = viewerController.footerView as? PreviewFooterView
        else { return }

        guard let button = footerView.selectButton else { return }

        guard let cell = self.collectionView.cellForItem(at: indexPath) as? TLPhotoCollectionViewCell, let localID = cell.asset?.localIdentifier
        else { return }

        guard let asset = TLPHAsset.asset(with: localID) else { return }

        if let index = selectedAssets.firstIndex(where: { $0.phAsset == asset.phAsset }) {
            button.selectedAsset = true
            button.setTitle("\(index + 1)", for: .normal)
        } else {
            button.selectedAsset = false
        }
    }

    func viewerControllerDidDismiss(_: ViewerController) {
        //
    }

    func viewerController(_: ViewerController, didFailDisplayingViewableAt _: IndexPath, error _: NSError) {
        //
    }

    func viewerController(_: ViewerController, didLongPressViewableAt _: IndexPath) {
        //
    }
}
