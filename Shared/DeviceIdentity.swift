import UIKit

/// Offline product-name lookup, shared by the app and widget. Names are not device-unique.
/// Identifiers: Apple's Xcode CoreSimulator device profiles (Xcode 27.0).
/// Chips: Apple technical specifications, checked 2026-10-29.
struct DeviceIdentity: Equatable {
    let modelName: String
    let chipName: String?

    static var current: DeviceIdentity {
        resolve(SystemReader.hardwareIdentifier, fallbackModel: UIDevice.current.model)
    }

    static func resolve(_ identifier: String, fallbackModel: String = "设备") -> DeviceIdentity {
        switch identifier {
        case "iPhone19,2":
            return DeviceIdentity(modelName: "iPhone 18 Pro", chipName: "A20 Pro")
        case "iPhone19,3", "iPhone19,7":
            return DeviceIdentity(modelName: "iPhone 18 Pro Max", chipName: "A20 Pro")
        case "iPhone18,1":
            return DeviceIdentity(modelName: "iPhone 17 Pro", chipName: "A19 Pro")
        case "iPhone18,2":
            return DeviceIdentity(modelName: "iPhone 17 Pro Max", chipName: "A19 Pro")
        case "iPhone18,5":
            return DeviceIdentity(modelName: "iPhone 17e", chipName: "A19")
        case "iPhone18,4":
            return DeviceIdentity(modelName: "iPhone Air", chipName: "A19 Pro")
        case "iPhone18,3":
            return DeviceIdentity(modelName: "iPhone 17", chipName: "A19")
        case "iPhone17,1":
            return DeviceIdentity(modelName: "iPhone 16 Pro", chipName: "A18 Pro")
        case "iPhone17,2":
            return DeviceIdentity(modelName: "iPhone 16 Pro Max", chipName: "A18 Pro")
        case "iPhone17,5":
            return DeviceIdentity(modelName: "iPhone 16e", chipName: "A18")
        case "iPhone17,3":
            return DeviceIdentity(modelName: "iPhone 16", chipName: "A18")
        case "iPhone17,4":
            return DeviceIdentity(modelName: "iPhone 16 Plus", chipName: "A18")
        case "iPhone16,1":
            return DeviceIdentity(modelName: "iPhone 15 Pro", chipName: "A17 Pro")
        case "iPhone16,2":
            return DeviceIdentity(modelName: "iPhone 15 Pro Max", chipName: "A17 Pro")
        case "iPhone15,4":
            return DeviceIdentity(modelName: "iPhone 15", chipName: "A16 Bionic")
        case "iPhone15,5":
            return DeviceIdentity(modelName: "iPhone 15 Plus", chipName: "A16 Bionic")
        case "iPhone15,2":
            return DeviceIdentity(modelName: "iPhone 14 Pro", chipName: "A16 Bionic")
        case "iPhone15,3":
            return DeviceIdentity(modelName: "iPhone 14 Pro Max", chipName: "A16 Bionic")
        case "iPhone14,7":
            return DeviceIdentity(modelName: "iPhone 14", chipName: "A15 Bionic")
        case "iPhone14,8":
            return DeviceIdentity(modelName: "iPhone 14 Plus", chipName: "A15 Bionic")
        case "iPhone14,6":
            return DeviceIdentity(modelName: "iPhone SE (第 3 代)", chipName: "A15 Bionic")
        case "iPhone14,2":
            return DeviceIdentity(modelName: "iPhone 13 Pro", chipName: "A15 Bionic")
        case "iPhone14,3":
            return DeviceIdentity(modelName: "iPhone 13 Pro Max", chipName: "A15 Bionic")
        case "iPhone14,5":
            return DeviceIdentity(modelName: "iPhone 13", chipName: "A15 Bionic")
        case "iPhone14,4":
            return DeviceIdentity(modelName: "iPhone 13 mini", chipName: "A15 Bionic")
        case "iPhone13,3":
            return DeviceIdentity(modelName: "iPhone 12 Pro", chipName: "A14 Bionic")
        case "iPhone13,4":
            return DeviceIdentity(modelName: "iPhone 12 Pro Max", chipName: "A14 Bionic")
        case "iPhone13,2":
            return DeviceIdentity(modelName: "iPhone 12", chipName: "A14 Bionic")
        case "iPhone13,1":
            return DeviceIdentity(modelName: "iPhone 12 mini", chipName: "A14 Bionic")
        case "iPhone12,8":
            return DeviceIdentity(modelName: "iPhone SE (第 2 代)", chipName: "A13 Bionic")
        case "iPhone12,3":
            return DeviceIdentity(modelName: "iPhone 11 Pro", chipName: "A13 Bionic")
        case "iPhone12,5":
            return DeviceIdentity(modelName: "iPhone 11 Pro Max", chipName: "A13 Bionic")
        case "iPhone12,1":
            return DeviceIdentity(modelName: "iPhone 11", chipName: "A13 Bionic")
        case "iPhone11,8":
            return DeviceIdentity(modelName: "iPhone XR", chipName: "A12 Bionic")
        case "iPhone11,2":
            return DeviceIdentity(modelName: "iPhone XS", chipName: "A12 Bionic")
        case "iPhone11,4", "iPhone11,6":
            return DeviceIdentity(modelName: "iPhone XS Max", chipName: "A12 Bionic")
        case "iPad17,3", "iPad17,4":
            return DeviceIdentity(modelName: "iPad Pro 13-inch (M5)", chipName: "M5")
        case "iPad17,1", "iPad17,2":
            return DeviceIdentity(modelName: "iPad Pro 11-inch (M5)", chipName: "M5")
        case "iPad16,3", "iPad16,4":
            return DeviceIdentity(modelName: "iPad Pro 11-inch (M4)", chipName: "M4")
        case "iPad16,5", "iPad16,6":
            return DeviceIdentity(modelName: "iPad Pro 13-inch (M4)", chipName: "M4")
        case "iPad16,10", "iPad16,11":
            return DeviceIdentity(modelName: "iPad Air 13-inch (M4)", chipName: "M4")
        case "iPad16,8", "iPad16,9":
            return DeviceIdentity(modelName: "iPad Air 11-inch (M4)", chipName: "M4")
        case "iPad15,7", "iPad15,8":
            return DeviceIdentity(modelName: "iPad (A16)", chipName: "A16")
        case "iPad15,5", "iPad15,6":
            return DeviceIdentity(modelName: "iPad Air 13-inch (M3)", chipName: "M3")
        case "iPad15,3", "iPad15,4":
            return DeviceIdentity(modelName: "iPad Air 11-inch (M3)", chipName: "M3")
        case "iPad14,8", "iPad14,9":
            return DeviceIdentity(modelName: "iPad Air 11-inch (M2)", chipName: "M2")
        case "iPad14,10", "iPad14,11":
            return DeviceIdentity(modelName: "iPad Air 13-inch (M2)", chipName: "M2")
        case "iPad16,1", "iPad16,2":
            return DeviceIdentity(modelName: "iPad mini (A17 Pro)", chipName: "A17 Pro")
        case "iPad14,3", "iPad14,4":
            return DeviceIdentity(modelName: "iPad Pro (11-inch) (4th generation)", chipName: "M2")
        case "iPad14,5", "iPad14,6":
            return DeviceIdentity(modelName: "iPad Pro (12.9-inch) (6th generation)", chipName: "M2")
        case "iPad13,18", "iPad13,19":
            return DeviceIdentity(modelName: "iPad (10th generation)", chipName: "A14 Bionic")
        case "iPad13,16", "iPad13,17":
            return DeviceIdentity(modelName: "iPad Air (5th generation)", chipName: "M1")
        case "iPad14,1", "iPad14,2":
            return DeviceIdentity(modelName: "iPad mini (6th generation)", chipName: "A15 Bionic")
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7":
            return DeviceIdentity(modelName: "iPad Pro (11-inch) (3rd generation)", chipName: "M1")
        case "iPad13,10", "iPad13,11", "iPad13,8", "iPad13,9":
            return DeviceIdentity(modelName: "iPad Pro (12.9-inch) (5th generation)", chipName: "M1")
        case "iPad12,1", "iPad12,2":
            return DeviceIdentity(modelName: "iPad (9th generation)", chipName: "A13 Bionic")
        case "iPad13,1", "iPad13,2":
            return DeviceIdentity(modelName: "iPad Air (4th generation)", chipName: "A14 Bionic")
        case "iPad11,6", "iPad11,7":
            return DeviceIdentity(modelName: "iPad (8th generation)", chipName: "A12 Bionic")
        case "iPad11,3", "iPad11,4":
            return DeviceIdentity(modelName: "iPad Air (3rd generation)", chipName: "A12 Bionic")
        case "iPad11,1", "iPad11,2":
            return DeviceIdentity(modelName: "iPad mini (5th generation)", chipName: "A12 Bionic")
        case "iPad8,10", "iPad8,9":
            return DeviceIdentity(modelName: "iPad Pro (11-inch) (2nd generation)", chipName: "A12Z Bionic")
        case "iPad8,11", "iPad8,12":
            return DeviceIdentity(modelName: "iPad Pro (12.9-inch) (4th generation)", chipName: "A12Z Bionic")
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":
            return DeviceIdentity(modelName: "iPad Pro (11-inch) (1st generation)", chipName: "A12X Bionic")
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":
            return DeviceIdentity(modelName: "iPad Pro (12.9-inch) (3rd generation)", chipName: "A12X Bionic")
        case "iPad7,11", "iPad7,12":
            return DeviceIdentity(modelName: "iPad (7th generation)", chipName: "A10 Fusion")
        case "iPad7,3", "iPad7,4":
            return DeviceIdentity(modelName: "iPad Pro (10.5-inch)", chipName: "A10X Fusion")
        case "iPad7,1", "iPad7,2":
            return DeviceIdentity(modelName: "iPad Pro (12.9-inch) (2nd generation)", chipName: "A10X Fusion")
        case "iPad7,5", "iPad7,6":
            return DeviceIdentity(modelName: "iPad (6th generation)", chipName: "A10 Fusion")
        case "iPad6,3", "iPad6,4":
            return DeviceIdentity(modelName: "iPad Pro (9.7-inch)", chipName: "A9X")
        case "iPad6,7", "iPad6,8":
            return DeviceIdentity(modelName: "iPad Pro (12.9-inch) (1st generation)", chipName: "A9X")
        case "iPad6,11", "iPad6,12":
            return DeviceIdentity(modelName: "iPad (5th generation)", chipName: "A9")
        case "iPad5,3", "iPad5,4":
            return DeviceIdentity(modelName: "iPad Air 2", chipName: "A8X")
        case "iPad5,1", "iPad5,2":
            return DeviceIdentity(modelName: "iPad mini 4", chipName: "A8")
        default:
            // Never extrapolate a marketing name from an unrecognized identifier.
            return DeviceIdentity(modelName: "\(fallbackModel) · \(identifier)", chipName: nil)
        }
    }
}
