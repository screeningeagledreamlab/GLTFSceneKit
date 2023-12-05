//
//  KTXLoaderTests.swift
//  KTXLoaderTests
//
//  Created by Jesse Armand on 30/11/23.
//  Copyright © 2023 DarkHorse. All rights reserved.
//

import XCTest
@testable import KTXLoader

class KTXLoaderTests: XCTestCase {

    func testLoadTextureData() throws {
        guard let device = MTLCreateSystemDefaultDevice() else {
            XCTFail("Fail to create metal system default device")
            return
        }
        let resourceName = "Cube_BaseColor"

        guard let url = Bundle(for: KTXLoaderTests.self).url(forResource: resourceName, withExtension: "ktx2", subdirectory: "art.scnassets/Cube/") else {
            XCTFail("\(resourceName).ktx2 is not available to load")
            return
        }

        let data = try Data(contentsOf: url)

        let loader = try KTXLoader(data: data, device: device)
        let metalTexture = loader.loadTexture(using: device)
        Swift.debugPrint("MLTTexture size (width: \(metalTexture.width), height: \(metalTexture.height))")
        Swift.debugPrint("MLTTexture pixel format: \(metalTexture.pixelFormat)")
        Swift.debugPrint("MLTTexture compression type \(metalTexture.compressionType)")
        Swift.debugPrint("MLTTexture texture type \(metalTexture.textureType)")

        XCTAssertEqual(metalTexture.pixelFormat, MTLPixelFormat.astc_4x4_srgb)
        XCTAssertEqual(metalTexture.compressionType,  MTLTextureCompressionType.lossless)
        XCTAssertEqual(metalTexture.textureType, MTLTextureType.type2D)
        XCTAssertEqual(metalTexture.width, 256)
        XCTAssertEqual(metalTexture.height, 256)
    }

}
