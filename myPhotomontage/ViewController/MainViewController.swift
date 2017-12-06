//
//  MainViewController.swift
//  myPhotomontage
//
//  Created by Suman Chatterjee on 05/12/2017.
//  Copyright © 2017 Suman Chatterjee. All rights reserved.
//

import UIKit
import RxSwift

class MainViewController: UIViewController {

  @IBOutlet weak var imagePreview: UIImageView!
  @IBOutlet weak var buttonClear: UIButton!
  @IBOutlet weak var buttonSave: UIButton!
  @IBOutlet weak var itemAdd: UIBarButtonItem!

  private let bag = DisposeBag()
  fileprivate let images = Variable<[UIImage]>([])
    
  override func viewDidLoad() {
    super.viewDidLoad()
    images.asObservable()
        .subscribe(onNext: { [weak self] photos in
            self?.updateUI(photos: photos)
            guard let preview = self?.imagePreview else { return }
            preview.image = UIImage.collage(images: photos,
                                            size: preview.frame.size)

        })
        .disposed(by: bag)
    
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    print("resources: \(RxSwift.Resources.total)")
  }

  @IBAction func actionClear() {

    images.value = []
  }

  @IBAction func actionSave() {
    guard let image = imagePreview.image else { return }
    
    let photoWriterObserVable :Observable<Void> = PhotoWriter.save(image)
    
    photoWriterObserVable
        .subscribe(onError: { [weak self] error in
            self?.showMessage("Error", description: error.localizedDescription)
            }, onCompleted: { [weak self] in
                self?.showMessage("Saved successfully.")
                self?.actionClear()
        })
        .disposed(by: bag)
  }

  @IBAction func actionAdd() {
   guard  let photosViewController = storyboard?.instantiateViewController(
    withIdentifier: "PhotosViewController") as? PhotosViewController else { return }
    
    let newPhoto = photosViewController.selectedPhotos.share()
    
    newPhoto
        .takeWhile { [weak self] image in
            return (self?.images.value.count ?? 0) < 6
        }
        .subscribe(onNext: { [weak self] newImage in
            guard let images = self?.images else { return }
            images.value.append(newImage)
            
            }, onDisposed: {
                print("completed photo selection")
        })
        .disposed(by: photosViewController.bag)
    
    newPhoto.ignoreElements()
        .subscribe(onCompleted:{ [weak self] in
            self?.updateNavigationIcon()
        })
        .disposed(by: photosViewController.bag)
    

    navigationController!.pushViewController(photosViewController, animated:
        true)

  }

    
  func showMessage(_ title: String, description: String? = nil) {
    let alert = UIAlertController(title: title, message: description, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { [weak self] _ in self?.dismiss(animated: true, completion: nil)}))
    present(alert, animated: true, completion: nil)
  }
}

// MARK: Private Extension

private extension MainViewController {
    
    func updateUI(photos: [UIImage]) {
        buttonSave.isEnabled = photos.count > 0 && photos.count % 2 == 0
        buttonClear.isEnabled = photos.count > 0
        itemAdd.isEnabled = photos.count < 6
        title = photos.count > 0 ? "\(photos.count) photos" : "Collage"
    }

    func updateNavigationIcon() {
        let icon = imagePreview.image?
            .scaled(CGSize(width: 22, height: 22))
            .withRenderingMode(.alwaysOriginal)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: icon,
                                                           style: .done, target: nil, action: nil)
    }
}
