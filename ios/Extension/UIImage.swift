//
//  UIColor.swift
//  CocoaAsyncSocket
//
//  Created by BẢO HÀ on 12/09/2023.
//

import UIKit

extension UIImage {
    func setTintColor(_ color: UIColor) -> UIImage? {
        if #available(iOS 13.0, *) {
            return self.withTintColor(color, renderingMode: .alwaysOriginal)
        } else {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            // 1
            let drawRect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
            // 2
            color.setFill()
            UIRectFill(drawRect)
            // 3
            draw(in: drawRect, blendMode: .destinationIn, alpha: 1)
            
            let tintedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            return tintedImage!
        }
    }
    
    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        self.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
    
    func getFileSize(_ path: String) -> Int64? {
        // Remove "file://" prefix if it exists
        var cleanedPath = path
        if let url = URL(string: path), url.scheme == "file" {
            cleanedPath = url.path
        }
        
        let fileURL = URL(fileURLWithPath: cleanedPath)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("Invalid file path.")
            return nil
        }
        
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let fileSize = fileAttributes[.size] as? Int64 {
                return fileSize
            } else {
                print("File size attribute is not available.")
                return nil
            }
        } catch {
            print("Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func resizedImageToFit(in boundingSize: CGSize, scaleIfSmaller scale: Bool) -> UIImage? {
        guard let imgRef = self.cgImage else { return nil }
        
        var srcSize = CGSize(width: imgRef.width, height: imgRef.height)
        
        // Adjust boundingSize to make it independent on imageOrientation too for further computations
        var adjustedBoundingSize = boundingSize
        let orient = self.imageOrientation
        switch orient {
        case .left, .right, .leftMirrored, .rightMirrored:
            adjustedBoundingSize = CGSize(width: boundingSize.height, height: boundingSize.width)
        default:
            break
        }
        
        // Compute the target CGRect in order to keep aspect ratio
        let dstSize: CGSize
        
        if !scale && (srcSize.width < adjustedBoundingSize.width) && (srcSize.height < adjustedBoundingSize.height) {
            // Image is smaller, and we asked not to scale it in this case
            dstSize = srcSize
        } else {
            let wRatio = adjustedBoundingSize.width / srcSize.width
            let hRatio = adjustedBoundingSize.height / srcSize.height
            
            if wRatio < hRatio {
                // Width imposed, Height scaled
                dstSize = CGSize(width: adjustedBoundingSize.width, height: floor(srcSize.height * wRatio))
            } else {
                // Height imposed, Width scaled
                dstSize = CGSize(width: floor(srcSize.width * hRatio), height: adjustedBoundingSize.height)
            }
        }
        
        return resizedImage(to: dstSize)
    }
    
    func resizedImage(to dstSize: CGSize) -> UIImage? {
        guard let imgRef = self.cgImage else { return nil }
        
        let srcSize = CGSize(width: imgRef.width, height: imgRef.height)
        
        // Don't resize if we already meet the required destination size.
        if srcSize.equalTo(dstSize) {
            return self
        }
        
        let scaleRatio = dstSize.width / srcSize.width
        let orient = self.imageOrientation
        var transform = CGAffineTransform.identity
        
        switch orient {
        case .up:
            transform = .identity
        case .upMirrored:
            transform = CGAffineTransform(translationX: srcSize.width, y: 0.0)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
        case .down:
            transform = CGAffineTransform(translationX: srcSize.width, y: srcSize.height)
            transform = transform.rotated(by: CGFloat.pi)
        case .downMirrored:
            transform = CGAffineTransform(translationX: 0.0, y: srcSize.height)
            transform = transform.scaledBy(x: 1.0, y: -1.0)
        case .leftMirrored:
            let newDstSize = CGSize(width: dstSize.height, height: dstSize.width)
            transform = CGAffineTransform(translationX: srcSize.height, y: srcSize.width)
            transform = transform.scaledBy(x: -1.0, y: 1.0)
            transform = transform.rotated(by: 3.0 * CGFloat.pi / 2.0)
            return drawImage(with: imgRef, srcSize: srcSize, dstSize: newDstSize, transform: transform, scaleRatio: scaleRatio)
        case .left:
            let newDstSize = CGSize(width: dstSize.height, height: dstSize.width)
            transform = CGAffineTransform(translationX: 0.0, y: srcSize.width)
            transform = transform.rotated(by: 3.0 * CGFloat.pi / 2.0)
            return drawImage(with: imgRef, srcSize: srcSize, dstSize: newDstSize, transform: transform, scaleRatio: scaleRatio)
        case .rightMirrored:
            let newDstSize = CGSize(width: dstSize.height, height: dstSize.width)
            transform = CGAffineTransform(scaleX: -1.0, y: 1.0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            return drawImage(with: imgRef, srcSize: srcSize, dstSize: newDstSize, transform: transform, scaleRatio: scaleRatio)
        case .right:
            let newDstSize = CGSize(width: dstSize.height, height: dstSize.width)
            transform = CGAffineTransform(translationX: srcSize.height, y: 0.0)
            transform = transform.rotated(by: CGFloat.pi / 2.0)
            return drawImage(with: imgRef, srcSize: srcSize, dstSize: newDstSize, transform: transform, scaleRatio: scaleRatio)
        default:
            fatalError("Invalid image orientation")
        }
        
        return drawImage(with: imgRef, srcSize: srcSize, dstSize: dstSize, transform: transform, scaleRatio: scaleRatio)
    }
    
    private func drawImage(with imgRef: CGImage, srcSize: CGSize, dstSize: CGSize, transform: CGAffineTransform, scaleRatio: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(dstSize, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        if self.imageOrientation == .right || self.imageOrientation == .left {
            context.scaleBy(x: -scaleRatio, y: scaleRatio)
            context.translateBy(x: -srcSize.height, y: 0)
        } else {
            context.scaleBy(x: scaleRatio, y: -scaleRatio)
            context.translateBy(x: 0, y: -srcSize.height)
        }
        
        context.concatenate(transform)
        context.draw(imgRef, in: CGRect(x: 0, y: 0, width: srcSize.width, height: srcSize.height))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
