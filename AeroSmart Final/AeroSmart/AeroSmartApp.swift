import SwiftUI
import SwiftData

@main
struct AeroSmartApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Trip.self,
            ChecklistItem.self,
            FavoriteDestination.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
