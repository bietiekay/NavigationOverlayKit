import Foundation
import MapKit

/// Represents a single navigation instruction that can be rendered by ``NavigationOverlayView``.
///
/// The information can be derived from either a ``MKRouteStep`` or a ``MKRoute``.
public struct NavigationInstruction: Equatable, Identifiable {
    public enum Symbol: String, CaseIterable, Codable {
        case straight
        case slightRight
        case right
        case sharpRight
        case slightLeft
        case left
        case sharpLeft
        case uTurn
        case arrive

        /// Maps the symbol to the appropriate SF Symbol that can be rendered in ``NavigationOverlayView``.
        public var systemImageName: String {
            switch self {
            case .straight:
                return "arrow.up"
            case .slightRight:
                return "arrow.up.right"
            case .right:
                return "arrow.turn.up.right"
            case .sharpRight:
                return "arrow.right"
            case .slightLeft:
                return "arrow.up.left"
            case .left:
                return "arrow.turn.up.left"
            case .sharpLeft:
                return "arrow.left"
            case .uTurn:
                return "arrow.uturn.backward"
            case .arrive:
                return "checkmark.circle"
            }
        }
    }

    public let id: UUID
    public let text: String
    public let distance: Measurement<UnitLength>
    public let symbol: Symbol

    public init(id: UUID = UUID(), text: String, distance: Measurement<UnitLength>, symbol: Symbol) {
        self.id = id
        self.text = text
        self.distance = distance
        self.symbol = symbol
    }
}

public extension NavigationInstruction {
    /// Creates a ``NavigationInstruction`` for the provided route step.
    /// - Parameters:
    ///   - step: The MapKit route step from which to extract the navigation data.
    ///   - unit: Desired unit for the distance. Defaults to meters.
    /// - Returns: A filled ``NavigationInstruction`` instance or `nil` if MapKit does not provide the required data.
    static func from(step: MKRoute.Step, unit: UnitLength = .meters) -> NavigationInstruction? {
        let distanceMeasurement = Measurement(value: step.distance, unit: UnitLength.meters).converted(to: unit)
        let instructionText = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !instructionText.isEmpty else { return nil }

        // Use multilingual text-based mapping; default to straight if unknown.
        let symbol = symbolFromLocalizedInstruction(instructionText) ?? .straight
        return NavigationInstruction(text: instructionText, distance: distanceMeasurement, symbol: symbol)
    }

    /// Creates an instruction for the provided route steps, automatically selecting the current one.
    /// - Parameters:
    ///   - route: The route containing the steps.
    ///   - currentStepIndex: The index of the step that should be displayed.
    ///   - unit: The unit the distance should be converted into.
    static func from(route: MKRoute, currentStepIndex: Int, unit: UnitLength = .meters) -> NavigationInstruction? {
        guard route.steps.indices.contains(currentStepIndex) else { return nil }
        let step = route.steps[currentStepIndex]
        let distanceMeasurement = Measurement(value: step.distance, unit: UnitLength.meters).converted(to: unit)

        // Arrival handling: show arrival symbol on the last step
        if currentStepIndex >= route.steps.count - 1 {
            let instructionText = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            return NavigationInstruction(text: instructionText.isEmpty ? "Arrive" : instructionText,
                                         distance: distanceMeasurement,
                                         symbol: .arrive)
        }

        // Prefer multilingual instruction text mapping first (supports several locales)
        let instructionText = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        if let textSymbol = symbolFromLocalizedInstruction(instructionText) {
            return NavigationInstruction(text: instructionText.isEmpty ? defaultInstructionText(for: textSymbol) : instructionText,
                                         distance: distanceMeasurement,
                                         symbol: textSymbol)
        }

        // Fallback to geometry-based turn detection when text is ambiguous
        if let previousIndex = previousStepIndex(withPolylineIn: route, before: currentStepIndex),
           let turnSymbol = geometryTurnSymbol(previous: route.steps[previousIndex].polyline, current: step.polyline) {
            let geometryText = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
            return NavigationInstruction(text: geometryText.isEmpty ? defaultInstructionText(for: turnSymbol) : geometryText,
                                         distance: distanceMeasurement,
                                         symbol: turnSymbol)
        }

        // Final fallback: default to straight
        let fallbackText = step.instructions.trimmingCharacters(in: .whitespacesAndNewlines)
        return NavigationInstruction(text: fallbackText.isEmpty ? defaultInstructionText(for: .straight) : fallbackText,
                                     distance: distanceMeasurement,
                                     symbol: .straight)
    }

    // MARK: - Helpers

    private static func previousStepIndex(withPolylineIn route: MKRoute, before index: Int) -> Int? {
        guard index > 0 else { return nil }
        var i = index - 1
        while route.steps.indices.contains(i) {
            if route.steps[i].polyline.pointCount >= 2 {
                return i
            }
            i -= 1
        }
        return nil
    }

    private static func defaultInstructionText(for symbol: NavigationInstruction.Symbol) -> String {
        switch symbol {
        case .straight: return NSLocalizedString("Continue", comment: "Default instruction text for straight maneuver")
        case .slightRight: return NSLocalizedString("Slight right", comment: "Default instruction text for slight right turn")
        case .right: return NSLocalizedString("Turn right", comment: "Default instruction text for right turn")
        case .sharpRight: return NSLocalizedString("Sharp right", comment: "Default instruction text for sharp right turn")
        case .slightLeft: return NSLocalizedString("Slight left", comment: "Default instruction text for slight left turn")
        case .left: return NSLocalizedString("Turn left", comment: "Default instruction text for left turn")
        case .sharpLeft: return NSLocalizedString("Sharp left", comment: "Default instruction text for sharp left turn")
        case .uTurn: return NSLocalizedString("Make a U-turn", comment: "Default instruction text for U-turn")
        case .arrive: return NSLocalizedString("Arrive", comment: "Default instruction text for arrival")
        }
    }

    /// Computes a turn symbol using the signed angle between previous and current step polylines.
    /// Positive angles are treated as left turns, negative as right turns.
    private static func geometryTurnSymbol(previous prev: MKPolyline, current cur: MKPolyline) -> NavigationInstruction.Symbol? {
        guard let v1 = lastNonZeroSegmentVector(of: prev),
              let v2 = firstNonZeroSegmentVector(of: cur) else { return nil }
        let angle = signedAngleDegrees(between: v1, and: v2)
        let absAngle = abs(angle)

        if absAngle < 15 { return .straight }
        if absAngle < 45 { return angle >= 0 ? .slightLeft : .slightRight }
        if absAngle < 120 { return angle >= 0 ? .left : .right }
        if absAngle < 170 { return angle >= 0 ? .sharpLeft : .sharpRight }
        return .uTurn
    }

    private static func firstNonZeroSegmentVector(of polyline: MKPolyline) -> (dx: Double, dy: Double)? {
        let count = polyline.pointCount
        guard count >= 2 else { return nil }
        var coords = Array(repeating: kCLLocationCoordinate2DInvalid, count: count)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
        for i in 0..<(count - 1) {
            let a = MKMapPoint(coords[i])
            let b = MKMapPoint(coords[i + 1])
            let dx = b.x - a.x
            let dy = b.y - a.y
            let len = hypot(dx, dy)
            if len > 1e-6 { return (dx / len, dy / len) }
        }
        return nil
    }

    private static func lastNonZeroSegmentVector(of polyline: MKPolyline) -> (dx: Double, dy: Double)? {
        let count = polyline.pointCount
        guard count >= 2 else { return nil }
        var coords = Array(repeating: kCLLocationCoordinate2DInvalid, count: count)
        polyline.getCoordinates(&coords, range: NSRange(location: 0, length: count))
        for i in stride(from: count - 2, through: 0, by: -1) {
            let a = MKMapPoint(coords[i])
            let b = MKMapPoint(coords[i + 1])
            let dx = b.x - a.x
            let dy = b.y - a.y
            let len = hypot(dx, dy)
            if len > 1e-6 { return (dx / len, dy / len) }
        }
        return nil
    }

    private static func signedAngleDegrees(between v1: (dx: Double, dy: Double), and v2: (dx: Double, dy: Double)) -> Double {
        // atan2 of cross and dot gives signed angle from v1 to v2
        let cross = v1.dx * v2.dy - v1.dy * v2.dx
        let dot = v1.dx * v2.dx + v1.dy * v2.dy
        let radians = atan2(cross, dot)
        return radians * 180.0 / .pi
    }
}

// MARK: - Multilingual instruction parsing and geometry helpers

private extension NavigationInstruction {
    static func symbolFromLocalizedInstruction(_ text: String) -> NavigationInstruction.Symbol? {
        let t = text.lowercased()

        // U-turn
        if LocalizedManeuverTokens.uTurnTokens.contains(where: { t.contains($0) }) { return .uTurn }

        // Arrive
        if LocalizedManeuverTokens.arriveTokens.contains(where: { t.contains($0) }) { return .arrive }

        // Modifiers
        let slightTokens = LocalizedManeuverTokens.slightTokens
        let sharpTokens = LocalizedManeuverTokens.sharpTokens

        // Left/Right
        let leftTokens = LocalizedManeuverTokens.leftTokens
        let rightTokens = LocalizedManeuverTokens.rightTokens

        let isLeft = leftTokens.contains(where: { t.contains($0) })
        let isRight = rightTokens.contains(where: { t.contains($0) })
        let isSlight = slightTokens.contains(where: { t.contains($0) })
        let isSharp = sharpTokens.contains(where: { t.contains($0) })

        if isLeft {
            if isSharp { return .sharpLeft }
            if isSlight { return .slightLeft }
            return .left
        }
        if isRight {
            if isSharp { return .sharpRight }
            if isSlight { return .slightRight }
            return .right
        }

        // Unrecognized
        return nil
    }
}
