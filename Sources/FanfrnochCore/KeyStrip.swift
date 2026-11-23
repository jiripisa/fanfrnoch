/// How a press on the app's keys or pads becomes a hit: soft at the top, firmer further down,
/// the hardest hit at the bottom.
public enum KeyStrip {

    /// The softest hit, at the top of a key, and the hardest, at its bottom.
    public static let softest = 40, hardest = 127

    /// The velocity of a press `depth` of the way down (0 at the top, 1 at the bottom); a
    /// depth outside that counts as the nearest edge.
    public static func velocity(depth: Double) -> Int {
        guard !depth.isNaN else { return softest }
        return softest + Int((Double(hardest - softest) * min(max(depth, 0), 1)).rounded())
    }

    /// The velocity of a press `y` points from the top of a key or pad `height` points tall, 1...127.
    public static func velocity(at y: Double, height: Double) -> Int {
        guard height > 0 else { return softest }
        return min(max(velocity(depth: y / height), 1), 127)
    }
}
