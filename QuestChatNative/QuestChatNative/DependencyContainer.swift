import Foundation

/// A simple container responsible for building view models.
/// This can later be expanded to manage shared services and dependencies.
final class DependencyContainer {
    static let shared = DependencyContainer()
    private init() {}

    private let statsStore = SessionStatsStore()
    private let healthBarStatsStore = HealthBarIRLStatsStore()
    private lazy var healthBarViewModel = HealthBarViewModel()
    private lazy var questsViewModel = QuestsViewModel(statsStore: statsStore)

    func makeFocusViewModel() -> FocusViewModel {
        FocusViewModel(
            statsStore: statsStore,
            healthStatsStore: healthBarStatsStore,
            healthBarViewModel: healthBarViewModel
        )
    }

    func makeHealthBarViewModel() -> HealthBarViewModel {
        healthBarViewModel
    }

    func makeStatsStore() -> SessionStatsStore {
        statsStore
    }

    func makeHealthBarStatsStore() -> HealthBarIRLStatsStore {
        healthBarStatsStore
    }

    func makeHealthStatsViewModel() -> StatsViewModel {
        StatsViewModel(healthStore: healthBarStatsStore)
    }

    func makeQuestsViewModel() -> QuestsViewModel {
        questsViewModel
    }
}
