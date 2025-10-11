# NavigationOverlayKit

NavigationOverlayKit is a Swift Package that provides a ready-to-use SwiftUI overlay component for displaying navigation instructions derived from `MKRoute` and `MKDirections`. The overlay shows a navigation arrow, a textual instruction, and distance information to help users stay on track during turn-by-turn navigation experiences.

## Features

- 📍 SwiftUI overlay view designed for in-app navigation experiences.
- 🧭 Support for `MKRoute` and `MKRoute.Step` instructions out-of-the-box.
- 🔁 Observable view model that can react to navigation progress updates.
- 🧰 Lightweight Swift Package ready for integration into other projects, including ToiletFinder.

## Requirements

- iOS 15.0+
- Xcode 15+

## Installation

### Swift Package Manager (SPM)

1. In Xcode, open **File → Add Packages...**
2. Enter the repository URL of NavigationOverlayKit.
3. Select **Add Package** and ensure the `NavigationOverlayKit` library is added to your target.

## Usage

### 1. Import the library

```swift
import NavigationOverlayKit
```

### 2. Create a view model

You can construct the provided `NavigationOverlayViewModel` with a MapKit `MKRoute`. The view model keeps track of the current instruction and updates the overlay automatically when you move between steps.

```swift
let directionsRequest = MKDirections.Request()
directionsRequest.source = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
directionsRequest.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))

let directions = MKDirections(request: directionsRequest)
directions.calculate { response, error in
    guard let route = response?.routes.first else { return }
    let viewModel = NavigationOverlayViewModel(route: route, unit: .kilometers)
    // Store viewModel for later use in your SwiftUI view hierarchy.
}
```

### 3. Display the overlay

Attach the overlay to any SwiftUI view (for example, a map) and provide the shared view model:

```swift
struct ContentView: View {
    @StateObject private var viewModel: NavigationOverlayViewModel

    init(route: MKRoute) {
        _viewModel = StateObject(wrappedValue: NavigationOverlayViewModel(route: route, unit: .kilometers))
    }

    var body: some View {
        ZStack {
            Map(route: route)
            NavigationOverlayView(viewModel: viewModel, alignment: .top)
        }
    }
}
```

### 4. Updating navigation progress

When you receive live navigation updates (e.g. from `CLLocationManager` callbacks), call the appropriate methods on the view model to refresh the overlay:

```swift
func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    guard let currentRoute = currentRoute else { return }
    let stepIndex = navigationEngine.currentStepIndex(for: locations.last, on: currentRoute)
    viewModel.update(step: stepIndex)
}
```

Alternatively, construct custom instructions directly:

```swift
let instruction = NavigationInstruction(
    text: "Turn right onto Market Street",
    distance: Measurement(value: 120, unit: .meters),
    symbol: .right
)
viewModel.update(with: instruction)
```

## Example

An end-to-end example showing how to use NavigationOverlayKit within a simple SwiftUI view:

```swift
struct RoutePreview: View {
    @State private var route: MKRoute?
    @StateObject private var viewModel = NavigationOverlayViewModel()

    var body: some View {
        ZStack {
            MapRouteView(route: $route)
            NavigationOverlayView(viewModel: viewModel)
        }
        .task {
            await loadRoute()
        }
    }

    private func loadRoute() async {
        do {
            let calculatedRoute = try await RouteLoader().route(from: startCoordinate, to: destinationCoordinate)
            route = calculatedRoute
            viewModel.update(step: 0)
        } catch {
            print("Failed to fetch route: \(error)")
        }
    }
}
```

> ℹ️ `MapRouteView` and `RouteLoader` are placeholders representing your map view and routing logic.

## Folder Structure

```
NavigationOverlayKit/
├── Package.swift
├── README.md
├── Sources/
│   └── NavigationOverlayKit/
│       ├── NavigationInstruction.swift
│       ├── NavigationOverlayView.swift
│       ├── NavigationOverlayViewModel.swift
│       └── Resources/
└── Tests/
    └── NavigationOverlayKitTests/
```

## Multilingual maneuver mapping (community‑maintained)

NavigationOverlayKit derives maneuver symbols (left/right/slight/sharp/U‑turn/arrive) from `MKRoute`/`MKRoute.Step`.

- MapKit provides localized, free‑text step instructions but no typed maneuver enum.
- To support multiple locales, the kit:
  - First tries a multilingual keyword map (English, German, French, Spanish, Italian, Japanese; easy to extend)
  - Then falls back to geometry‑based angle detection between step polylines
  - Finally defaults to straight when neither approach is decisive

Why this exists: Without a typed maneuver in MapKit, mapping across all locales requires heuristics. This hybrid approach is practical but community help improves coverage and accuracy.

### How you can help

- Add keywords for your language in `NavigationInstruction.symbolFromLocalizedInstruction(_:)`.
  - Include variants, gendered/plural forms, and common synonyms.
  - Keep tokens lowercase; accents are fine. Prefer short substrings that are unlikely to conflict.
- Add unit tests in `NavigationOverlayKitTests` with real instructions captured from MapKit for your locale.
- If you see a mis‑classified turn, open an issue and include:
  - Locale and full instruction text
  - Expected maneuver (e.g., sharpLeft)
  - Optional: previous/current step coordinates for geometry fallback validation

If you need guaranteed correctness across many languages, consider using a routing SDK that exposes typed maneuvers (e.g., Mapbox or HERE) and feed its steps into `NavigationOverlayViewModel`.

## License

NavigationOverlayKit is provided without a specific license. Add your preferred license here.
