import Foundation
import Observation

@MainActor
@Observable
final class TripClock {
    var now = Date()
    private var task: Task<Void, Never>?

    func start() {
        guard task == nil else { return }
        now = Date()
        task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(30))
                guard !Task.isCancelled else { break }
                now = Date()
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
