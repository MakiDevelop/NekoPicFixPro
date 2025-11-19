#!/usr/bin/env swift

import Foundation

print("🔍 Model File Diagnostic Tool\n")
print("=" * 50)

let modelName = "realesrgan512"
let expectedPath = "/Users/maki/Xcode/NekoPicFixPro/NekoPicFixPro/Models/\(modelName).mlmodel"

print("\n1. Checking file system:")
print("   Expected path: \(expectedPath)")

let fileManager = FileManager.default
if fileManager.fileExists(atPath: expectedPath) {
    print("   ✅ File exists on disk")

    do {
        let attributes = try fileManager.attributesOfItem(atPath: expectedPath)
        if let size = attributes[.size] as? UInt64 {
            let sizeMB = Double(size) / 1024.0 / 1024.0
            print("   ✅ File size: \(String(format: "%.1f", sizeMB)) MB")
        }
    } catch {
        print("   ⚠️  Could not read file attributes: \(error)")
    }
} else {
    print("   ❌ File NOT found on disk")
}

print("\n2. Checking Bundle:")
if let bundlePath = Bundle.main.path(forResource: modelName, ofType: "mlmodel") {
    print("   ✅ Model found in Bundle at: \(bundlePath)")
} else {
    print("   ❌ Model NOT found in Bundle")
    print("   ⚠️  This means the model file is not added to the Xcode project target")
}

if let compiledPath = Bundle.main.path(forResource: modelName, ofType: "mlmodelc") {
    print("   ✅ Compiled model found at: \(compiledPath)")
} else {
    print("   ⚠️  Compiled model (.mlmodelc) not found")
}

print("\n" + "=" * 50)
print("\n💡 Solution:")
print("   If model is NOT in Bundle, you need to:")
print("   1. Open Xcode project")
print("   2. Drag realesrgan512.mlmodel into the Models group")
print("   3. Check 'Add to targets: NekoPicFixPro'")
print("   4. Clean and rebuild (⌘⇧K then ⌘B)")
print()
