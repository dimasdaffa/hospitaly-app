//
//  ProfilePhoto.swift
//  Hospitaly
//
//  Created by DIMAS DAFFA ERNANDA on 25/11/26.
//

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct ProfilePhoto: Sendable {
    let thumbnail: CGImage
    let jpeg: Data

    @concurrent
    static func prepare(_ data: Data) async throws -> ProfilePhoto {
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let sourceType = CGImageSourceGetType(source),
              UTType(sourceType as String)?.conforms(to: .image) == true,
              let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 800
              ] as CFDictionary) else { throw APIError.invalidPayload }

        let jpeg = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(jpeg, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw APIError.invalidPayload
        }
        CGImageDestinationAddImage(destination, thumbnail, [
            kCGImageDestinationLossyCompressionQuality: 0.82
        ] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw APIError.invalidPayload }
        try Task.checkCancellation()
        return ProfilePhoto(thumbnail: thumbnail, jpeg: jpeg as Data)
    }
}
