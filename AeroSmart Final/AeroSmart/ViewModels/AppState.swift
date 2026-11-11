import Foundation
import Observation

@MainActor
@Observable
final class AppState {
    var selectedTab = 0
    var searchResetToken = 0
}
