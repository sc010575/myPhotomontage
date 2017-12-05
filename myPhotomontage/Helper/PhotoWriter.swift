//
//  PhotoWriter.swift
//  myPhotomontage
//
//  Created by Suman Chatterjee on 05/12/2017.
//  Copyright © 2017 Suman Chatterjee. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class PhotoWriter: NSObject {
  typealias Callback = (NSError?)->Void
    
  private var callback: Callback
  fileprivate init(callback: @escaping Callback) {
        self.callback = callback
    }

  func image(_ image: UIImage, didFinishSavingWithError error: NSError?,
               contextInfo: UnsafeRawPointer) {
        callback(error)
    }
}

// MARK: Static methods
extension PhotoWriter {
    
    static func save(_ image: UIImage) -> Observable<Void> {
        return Observable.create({ observer in
            
            let writer = PhotoWriter(callback: { error in
                if let error = error {
                    observer.onError(error)
                } else {
                    observer.onCompleted()
                }
            })
            UIImageWriteToSavedPhotosAlbum(image, writer,
                                           #selector(PhotoWriter.image(_:didFinishSavingWithError:contextInfo:)),
                                           nil)
            return Disposables.create()
        })
        
    }
}
