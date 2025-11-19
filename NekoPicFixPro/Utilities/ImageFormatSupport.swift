//
//  ImageFormatSupport.swift
//  NekoPicFixPro
//
//  圖片格式支援定義
//

import Foundation
import UniformTypeIdentifiers

/// 支援的圖片格式
enum SupportedImageFormat: String, CaseIterable {
    case jpeg = "JPEG"
    case png = "PNG"
    case heic = "HEIC"
    case bmp = "BMP"
    case tiff = "TIFF"
    case webp = "WebP"

    /// UTType 定義
    var utType: UTType {
        switch self {
        case .jpeg: return .jpeg
        case .png: return .png
        case .heic: return .heic
        case .bmp: return .bmp
        case .tiff: return .tiff
        case .webp: return .webP
        }
    }

    /// 支援的副檔名
    var fileExtensions: [String] {
        switch self {
        case .jpeg: return ["jpg", "jpeg"]
        case .png: return ["png"]
        case .heic: return ["heic", "heif"]
        case .bmp: return ["bmp"]
        case .tiff: return ["tiff", "tif"]
        case .webp: return ["webp"]
        }
    }

    /// 格式描述
    var description: String {
        switch self {
        case .jpeg: return "JPEG 圖片"
        case .png: return "PNG 圖片"
        case .heic: return "HEIC 圖片"
        case .bmp: return "BMP 點陣圖"
        case .tiff: return "TIFF 圖片"
        case .webp: return "WebP 圖片"
        }
    }

    /// 所有支援的 UTType
    static var allUTTypes: [UTType] {
        allCases.map { $0.utType }
    }

    /// 所有支援的副檔名
    static var allExtensions: [String] {
        allCases.flatMap { $0.fileExtensions }
    }

    /// 根據副檔名取得格式
    static func format(for extension: String) -> SupportedImageFormat? {
        let ext = `extension`.lowercased()
        return allCases.first { $0.fileExtensions.contains(ext) }
    }

    /// 支援格式的友善字串（用於顯示）
    static var supportedFormatsString: String {
        allCases.map { $0.rawValue }.joined(separator: "、")
    }
}
