import Foundation

struct PaperSlip: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    var x: Double
    var y: Double
    var rotation: Double

    init(id: UUID = UUID(), text: String, x: Double, y: Double, rotation: Double) {
        self.id = id
        self.text = text
        self.x = x
        self.y = y
        self.rotation = rotation
    }
}
