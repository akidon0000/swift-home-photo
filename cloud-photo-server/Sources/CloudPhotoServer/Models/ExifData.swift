import Foundation

/// EXIF データ構造体
struct ExifData: Codable, Sendable {
    /// カメラメーカー
    let cameraMake: String?
    /// カメラモデル
    let cameraModel: String?
    /// レンズモデル
    let lensModel: String?
    /// 焦点距離 (mm)
    let focalLength: Double?
    /// F値
    let aperture: Double?
    /// シャッタースピード (例: "1/125")
    let shutterSpeed: String?
    /// ISO感度
    let iso: Int?
    /// GPS緯度
    let latitude: Double?
    /// GPS経度
    let longitude: Double?
    /// GPS高度
    let altitude: Double?
    /// 撮影日時
    let dateTimeOriginal: Date?

    init(
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        lensModel: String? = nil,
        focalLength: Double? = nil,
        aperture: Double? = nil,
        shutterSpeed: String? = nil,
        iso: Int? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        dateTimeOriginal: Date? = nil
    ) {
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.lensModel = lensModel
        self.focalLength = focalLength
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.iso = iso
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.dateTimeOriginal = dateTimeOriginal
    }
}
