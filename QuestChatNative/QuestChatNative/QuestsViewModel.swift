import Foundation
import Combine

struct Quest: Identifiable, Equatable {
    enum Tier: String, CaseIterable {
        case core
        case habit
        case bonus

        var displayName: String {
            switch self {
            case .core:
                return QuestChatStrings.QuestsPool.coreTier
            case .habit:
                return QuestChatStrings.QuestsPool.habitTier
            case .bonus:
                return QuestChatStrings.QuestsPool.bonusTier
            }
        }
    }

    let id: String
    let instanceId: UUID
    let title: String
    let detail: String
    let xpReward: Int
    let tier: Tier
    var isCompleted: Bool
    var isCoreToday: Bool = false
    var progress: Int
    var target: Int
}

final class QuestsViewModel: ObservableObject {
    @Published var dailyQuests: [Quest] = []
    @Published private(set) var hasUsedRerollToday: Bool = false
    @Published var hasQuestChestReady: Bool = false
    @Published private(set) var playerLevel: Int = 0
    @Published private(set) var xpIntoCurrentLevel: Int = 0
    @Published private(set) var xpToNextLevel: Int = 100
    @Published private(set) var weeklyQuests: [Quest] = []

    private let questEngine: QuestEngine
    private var cancellables = Set<AnyCancellable>()

    init(
        questEngine: QuestEngine
    ) {
        self.questEngine = questEngine
        bind()
    }

    var completedQuestsCount: Int {
        dailyQuests.filter { $0.isCompleted }.count
    }

    var totalQuestsCount: Int {
        dailyQuests.count
    }

    var totalDailyXP: Int {
        dailyQuests.reduce(0) { $0 + $1.xpReward }
    }

    var remainingQuestsUntilChest: Int {
        max(dailyQuests.filter { !$0.isCompleted && $0.isCoreToday }.count, 0)
    }

    var allQuestsComplete: Bool {
        dailyQuests.allSatisfy { $0.isCompleted }
    }

    var incompleteQuests: [Quest] {
        dailyQuests.filter { !$0.isCompleted }
    }

    var canRerollToday: Bool { !hasUsedRerollToday }

    func toggleQuest(_ quest: Quest) {
        guard !quest.isCompleted else { return }
        questEngine.markCompleted(instanceId: quest.instanceId)
    }

    func reroll(quest: Quest) {
        guard !hasUsedRerollToday else { return }
        guard !quest.isCompleted else { return }
        questEngine.reroll(questId: quest.instanceId)
    }

    func claimQuestChest() {
        questEngine.markChestClaimed()
    }

    var questChestRewardAmount: Int { 75 }

    func markCoreQuests(for focusArea: FocusArea) {
        // Core quests are simply the daily chest quests; mark them for UI emphasis.
        dailyQuests = dailyQuests.map { quest in
            var updated = quest
            updated.isCoreToday = quest.isCoreToday
            return updated
        }
    }
}

private extension QuestsViewModel {
    func bind() {
        questEngine.$dailyQuests
            .receive(on: RunLoop.main)
            .sink { [weak self] instances in
                self?.dailyQuests = self?.map(instances: instances) ?? []
            }
            .store(in: &cancellables)

        questEngine.$weeklyQuests
            .receive(on: RunLoop.main)
            .sink { [weak self] instances in
                self?.weeklyQuests = self?.map(instances: instances) ?? []
            }
            .store(in: &cancellables)

        questEngine.$dailyChestReady
            .receive(on: RunLoop.main)
            .assign(to: &self.$hasQuestChestReady)

        questEngine.$rerollUsedToday
            .receive(on: RunLoop.main)
            .assign(to: &self.$hasUsedRerollToday)

        questEngine.$playerProgress
            .receive(on: RunLoop.main)
            .sink { [weak self] progress in
                self?.playerLevel = progress.level
                self?.xpIntoCurrentLevel = progress.xpIntoCurrentLevel
                self?.xpToNextLevel = progress.xpToNextLevel
            }
            .store(in: &cancellables)
    }

    func map(instances: [QuestInstance]) -> [Quest] {
        instances.compactMap { instance in
            guard let definition = questEngine.definition(for: instance.definitionId) else { return nil }
            let tier: Quest.Tier
            switch definition.type {
            case .dailyCore: tier = .core
            case .dailyHabit: tier = .habit
            case .bonus: tier = .bonus
            case .weekly: tier = .bonus
            }

            return Quest(
                id: definition.id,
                instanceId: instance.id,
                title: definition.title,
                detail: definition.subtitle,
                xpReward: definition.xpReward,
                tier: tier,
                isCompleted: instance.status == .completed,
                isCoreToday: instance.countsForDailyChest,
                progress: instance.progress,
                target: instance.target
            )
        }
    }
}
