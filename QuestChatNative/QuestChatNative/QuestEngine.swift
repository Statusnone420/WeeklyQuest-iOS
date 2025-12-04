import Foundation
import GameKit

// MARK: - Quest Models

enum QuestType: String, Codable, CaseIterable {
    case dailyCore = "daily_core"
    case dailyHabit = "daily_habit"
    case bonus
    case weekly
}

enum QuestCategory: String, Codable, CaseIterable {
    case focus
    case hydration
    case hpCore = "hp_core"
    case choresWork = "chores_work"
    case meta
}

enum QuestDifficulty: String, Codable, CaseIterable {
    case tiny
    case small
    case medium
    case big

    var xpReward: Int {
        switch self {
        case .tiny: return 10
        case .small: return 20
        case .medium: return 35
        case .big: return 60
        }
    }
}

enum QuestStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case failed
}

struct QuestDefinition: Codable, Identifiable {
    let id: String
    let type: QuestType
    let category: QuestCategory
    let difficulty: QuestDifficulty
    let xpReward: Int
    let title: String
    let subtitle: String
    let countsForDailyChestDefault: Bool
    let target: Int
}

struct QuestInstance: Identifiable, Codable {
    let id: UUID
    let definitionId: String
    let createdAt: Date
    var status: QuestStatus
    var progress: Int
    var target: Int
    var countsForDailyChest: Bool
    var xpGranted: Bool

    var isComplete: Bool { status == .completed }
}

struct PlayerProgress: Codable {
    var totalXP: Int
    var todayXP: Int
    var lastDailyReset: Date

    var level: Int { totalXP / 100 }
    var xpIntoCurrentLevel: Int { totalXP % 100 }
    var xpToNextLevel: Int { 100 - xpIntoCurrentLevel }
}

// MARK: - Quest Engine

final class QuestEngine: ObservableObject {
    @Published private(set) var dailyQuests: [QuestInstance] = []
    @Published private(set) var weeklyQuests: [QuestInstance] = []
    @Published private(set) var playerProgress: PlayerProgress
    @Published private(set) var dailyChestReady: Bool = false
    @Published private(set) var rerollUsedToday: Bool = false

    private let calendar: Calendar
    private let userDefaults: UserDefaults
    private let definitions: [QuestDefinition]

    private var dailyKey: String {
        let components = calendar.dateComponents([.year, .month, .day], from: Date())
        return String(format: "quests-%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private var weeklyKey: String {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return String(format: "weekly-%04d-%02d", components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }

    private struct StorageKeys {
        static let daily = "quest_engine_daily"
        static let weekly = "quest_engine_weekly"
        static let progress = "quest_engine_progress"
        static let reroll = "quest_engine_reroll"
        static let chest = "quest_engine_chest"
    }

    init(userDefaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.userDefaults = userDefaults
        self.calendar = calendar
        self.definitions = QuestEngine.buildDefinitions()

        if let stored = QuestEngine.loadProgress(from: userDefaults) {
            playerProgress = stored
        } else {
            playerProgress = PlayerProgress(totalXP: 0, todayXP: 0, lastDailyReset: calendar.startOfDay(for: Date()))
        }

        loadState()
        refreshIfNeeded()
    }

    // MARK: Loading & Generation

    private func loadState() {
        if let data = userDefaults.data(forKey: StorageKeys.daily),
           let decoded = try? JSONDecoder().decode([String: [QuestInstance]].self, from: data),
           let quests = decoded[dailyKey] {
            dailyQuests = quests
        }

        if let data = userDefaults.data(forKey: StorageKeys.weekly),
           let decoded = try? JSONDecoder().decode([String: [QuestInstance]].self, from: data),
           let quests = decoded[weeklyKey] {
            weeklyQuests = quests
        }

        rerollUsedToday = userDefaults.bool(forKey: rerollKey(for: dailyKey))
        dailyChestReady = userDefaults.bool(forKey: chestKey(for: dailyKey))
    }

    private func refreshIfNeeded(now: Date = Date()) {
        let today = calendar.startOfDay(for: now)
        if !calendar.isDate(playerProgress.lastDailyReset, inSameDayAs: today) {
            playerProgress.lastDailyReset = today
            playerProgress.todayXP = 0
            rerollUsedToday = false
            dailyChestReady = false
            generateDailyQuests(for: today)
        } else if dailyQuests.isEmpty {
            generateDailyQuests(for: today)
        }

        if weeklyQuests.isEmpty || !calendar.isDate(dailyAnchorDate(for: weeklyQuests), equalTo: today, toGranularity: .weekOfYear) {
            generateWeeklyQuests(for: today)
        }

        persistProgress()
    }

    private func dailyAnchorDate(for quests: [QuestInstance]) -> Date {
        quests.first?.createdAt ?? Date()
    }

    private func generateDailyQuests(for date: Date) {
        var rng = SeededGenerator(date: date)
        let anchors = definitions.filter { $0.id == "LOAD_QUEST_LOG" || $0.id == "PLAN_FOCUS_SESSION" || $0.id == "HEALTHBAR_CHECKIN" }
        var quests = anchors.map { QuestInstance(definitionId: $0.id, createdAt: date, status: .pending, progress: 0, target: $0.target, countsForDailyChest: true, xpGranted: false, id: UUID()) }

        let corePool = definitions.filter { $0.type == .dailyCore && !anchors.contains(where: { $0.id == $1.id }) }
        let hydrationDisabled = false // placeholder for future settings
        let filteredCore = hydrationDisabled ? corePool.filter { $0.category != .hydration } : corePool
        quests.append(contentsOf: filteredCore.shuffled(using: &rng).prefix(2).map { def in
            QuestInstance(definitionId: def.id, createdAt: date, status: .pending, progress: 0, target: def.target, countsForDailyChest: false, xpGranted: false, id: UUID())
        })

        let habitCategories: [QuestCategory] = [.hydration, .focus, .hpCore, .choresWork]
        for category in habitCategories {
            if let pick = definitions.first(where: { $0.type == .dailyHabit && $0.category == category }) ?? definitions.first(where: { $0.type == .dailyHabit && $0.category == category && ($0.difficulty == .tiny || $0.difficulty == .small) }) {
                quests.append(QuestInstance(definitionId: pick.id, createdAt: date, status: .pending, progress: 0, target: pick.target, countsForDailyChest: false, xpGranted: false, id: UUID()))
            }
        }

        if quests.count >= 4 {
            quests[3].countsForDailyChest = true
        }

        dailyQuests = quests
        persistDaily()
    }

    private func generateWeeklyQuests(for date: Date) {
        var rng = SeededGenerator(date: date)
        let required = ["WEEK_FOCUS_10_SESSIONS", "WEEK_HYDRATE_4_DAYS_64OZ", "WEEK_HP_5_CHECKINS", "WEEK_DAILY_CORE_4_DAYS"]
        var quests = required.compactMap { id -> QuestInstance? in
            guard let def = definitions.first(where: { $0.id == id }) else { return nil }
            return QuestInstance(definitionId: def.id, createdAt: date, status: .pending, progress: 0, target: def.target, countsForDailyChest: false, xpGranted: false, id: UUID())
        }

        let optionalWeekly = definitions.filter { $0.type == .weekly && !required.contains($0.id) }
        quests.append(contentsOf: optionalWeekly.shuffled(using: &rng).prefix(2).map { def in
            QuestInstance(definitionId: def.id, createdAt: date, status: .pending, progress: 0, target: def.target, countsForDailyChest: false, xpGranted: false, id: UUID())
        })

        weeklyQuests = quests
        persistWeekly()
    }

    // MARK: Events

    func handleFocusSessionStarted(minutes: Int) {
        guard minutes > 0 else { return }
        applyProgress(for: ["PLAN_FOCUS_SESSION"], increment: 1)
    }

    func handleFocusSessionCompleted(minutes: Int, category: TimerCategory.Kind?) {
        guard minutes > 0 else { return }
        if minutes >= 25 { applyProgress(for: ["COMPLETE_FOCUS_SESSION"], increment: 1) }
        if minutes >= 45 { applyProgress(for: ["WEEK_FOCUS_3_DEEP"], increment: 1, weekly: true) }

        applyProgress(for: ["WEEK_FOCUS_10_SESSIONS"], increment: 1, weekly: true)

        if let category {
            switch category {
            case .deepFocus:
                applyProgress(for: ["FOCUS_DOUBLE_RUN"], increment: 1)
            case .workSprint:
                applyProgress(for: ["CHORE_BLITZ", "WORK_SPRINT_25", "WEEK_CHORE_5_TIMERS"], increment: 1, weekly: true)
            case .choresSprint:
                applyProgress(for: ["CHORE_BLITZ", "CHORE_THREE_SMALL", "WEEK_CHORE_5_TIMERS"], increment: 1, weekly: true)
            case .selfCare:
                applyProgress(for: ["SELFCARE_SHORT", "WEEK_SELFCARE_3_DAYS"], increment: 1, weekly: true)
            case .gamingReset, .quickBreak:
                break
            }
        }
    }

    func handleHydrationLogged(ounces: Int, totalToday: Int, logCount: Int) {
        guard ounces > 0 else { return }
        if totalToday >= 8 { applyProgress(for: ["HYDRATE_NOW_GLASS"], increment: 1) }
        if totalToday >= 16 { applyProgress(for: ["HYDRATE_CHECKPOINT_16OZ"], increment: 1) }
        if totalToday >= 32 { applyProgress(for: ["HYDRATE_32OZ"], increment: 1) }
        if totalToday >= 48 { applyProgress(for: ["HYDRATE_CHECKPOINT_48OZ"], increment: 1) }
        if totalToday >= 64 { applyProgress(for: ["HYDRATE_64OZ"], increment: 1); applyProgress(for: ["WEEK_HYDRATE_4_DAYS_64OZ"], increment: 1, weekly: true, uniquePerDay: true) }
        if logCount >= 3 { applyProgress(for: ["HYDRATE_MULTI_CHECKPOINT"], increment: 1) }
    }

    func handleHPCheckinCompleted() {
        applyProgress(for: ["HEALTHBAR_CHECKIN", "HP_CHECKIN_COMBO", "WEEK_HP_5_CHECKINS"], increment: 1, weekly: true)
    }

    func handleQuestsTabOpened() {
        applyProgress(for: ["LOAD_QUEST_LOG"], increment: 1)
    }

    func handleStatsTabOpened(afterEveningOnly: Bool) {
        if afterEveningOnly {
            applyProgress(for: ["STATS_REVIEW"], increment: 1)
        }
    }

    func handleDailyCoreSetCompleted() {
        applyProgress(for: ["WEEK_DAILY_CORE_4_DAYS"], increment: 1, weekly: true)
    }

    // MARK: Reroll

    func reroll(questId: UUID) {
        guard let index = dailyQuests.firstIndex(where: { $0.id == questId }) else { return }
        guard dailyQuests[index].status != .completed else { return }
        guard !rerollUsedToday else { return }

        let current = dailyQuests[index]
        guard let currentDefinition = definitions.first(where: { $0.id == current.definitionId }) else { return }

        let candidates = definitions.filter { $0.type == currentDefinition.type && $0.difficulty == currentDefinition.difficulty && $0.category == currentDefinition.category && $0.id != current.definitionId }
        guard let replacement = candidates.randomElement() else { return }

        dailyQuests[index] = QuestInstance(
            definitionId: replacement.id,
            createdAt: current.createdAt,
            status: .pending,
            progress: 0,
            target: replacement.target,
            countsForDailyChest: current.countsForDailyChest,
            xpGranted: false,
            id: UUID()
        )

        rerollUsedToday = true
        userDefaults.set(true, forKey: rerollKey(for: dailyKey))
        persistDaily()
    }

    func markCompleted(instanceId: UUID) {
        guard let index = dailyQuests.firstIndex(where: { $0.id == instanceId }) else { return }
        guard dailyQuests[index].status != .completed else { return }
        dailyQuests[index].status = .completed
        if !dailyQuests[index].xpGranted {
            grantXP(for: dailyQuests[index])
            dailyQuests[index].xpGranted = true
        }
        persistDaily()
        evaluateChest()
    }

    func markChestClaimed() {
        dailyChestReady = false
        userDefaults.set(false, forKey: chestKey(for: dailyKey))
    }

    // MARK: Progress

    private func applyProgress(for ids: [String], increment: Int, weekly: Bool = false, uniquePerDay: Bool = false) {
        guard increment > 0 else { return }
        var updatedDaily = dailyQuests
        var updatedWeekly = weeklyQuests

        func update(_ quests: inout [QuestInstance], ids: [String]) {
            for idx in quests.indices {
                guard ids.contains(quests[idx].definitionId) else { continue }
                guard quests[idx].status != .completed else { continue }
                if uniquePerDay {
                    let today = calendar.startOfDay(for: Date())
                    let markerKey = "quest-engine-unique-\(quests[idx].definitionId)-\(today.timeIntervalSince1970)"
                    if userDefaults.bool(forKey: markerKey) { continue }
                    userDefaults.set(true, forKey: markerKey)
                }
                quests[idx].progress += increment
                quests[idx].status = quests[idx].progress >= quests[idx].target ? .completed : .inProgress
                if quests[idx].status == .completed, !quests[idx].xpGranted {
                    grantXP(for: quests[idx])
                    quests[idx].xpGranted = true
                }
            }
        }

        if weekly {
            update(&updatedWeekly, ids: ids)
            weeklyQuests = updatedWeekly
            persistWeekly()
        } else {
            update(&updatedDaily, ids: ids)
            dailyQuests = updatedDaily
            persistDaily()
            evaluateChest()
        }
    }

    private func grantXP(for quest: QuestInstance) {
        guard let def = definitions.first(where: { $0.id == quest.definitionId }) else { return }
        guard !quest.xpGranted else { return }

        playerProgress.totalXP += def.xpReward
        playerProgress.todayXP += def.xpReward
        persistProgress()
    }

    private func evaluateChest() {
        let chestQuests = dailyQuests.filter { $0.countsForDailyChest }
        guard !chestQuests.isEmpty else { return }
        let completed = chestQuests.allSatisfy { $0.status == .completed }
        if completed && !dailyChestReady {
            dailyChestReady = true
            playerProgress.totalXP += 75
            playerProgress.todayXP += 75
            userDefaults.set(true, forKey: chestKey(for: dailyKey))
            persistProgress()
        }
    }

    // MARK: Persistence

    private func persistDaily() {
        let payload = [dailyKey: dailyQuests]
        if let data = try? JSONEncoder().encode(payload) {
            userDefaults.set(data, forKey: StorageKeys.daily)
        }
    }

    private func persistWeekly() {
        let payload = [weeklyKey: weeklyQuests]
        if let data = try? JSONEncoder().encode(payload) {
            userDefaults.set(data, forKey: StorageKeys.weekly)
        }
    }

    private func persistProgress() {
        if let data = try? JSONEncoder().encode(playerProgress) {
            userDefaults.set(data, forKey: StorageKeys.progress)
        }
    }

    private func rerollKey(for dayKey: String) -> String { "\(StorageKeys.reroll)-\(dayKey)" }
    private func chestKey(for dayKey: String) -> String { "\(StorageKeys.chest)-\(dayKey)" }

    func definition(for id: String) -> QuestDefinition? {
        definitions.first { $0.id == id }
    }

    // MARK: Definition catalog

    private static func buildDefinitions() -> [QuestDefinition] {
        var defs: [QuestDefinition] = []
        func add(_ id: String, _ type: QuestType, _ category: QuestCategory, _ difficulty: QuestDifficulty, _ title: String, _ subtitle: String, countsForChest: Bool = false, target: Int = 1) {
            defs.append(QuestDefinition(id: id, type: type, category: category, difficulty: difficulty, xpReward: difficulty.xpReward, title: title, subtitle: subtitle, countsForDailyChestDefault: countsForChest, target: target))
        }

        // Core
        add("LOAD_QUEST_LOG", .dailyCore, .meta, .tiny, "Load today’s quest log", "Open the Quests tab", countsForChest: true)
        add("PLAN_FOCUS_SESSION", .dailyCore, .focus, .medium, "Plan one focus session", "Start a 15+ minute timer", countsForChest: true)
        add("COMPLETE_FOCUS_SESSION", .dailyCore, .focus, .big, "Finish a focus session", "Complete a 25+ minute timer")
        add("HEALTHBAR_CHECKIN", .dailyCore, .hpCore, .medium, "HealthBar check-in", "Update mood, gut, and sleep", countsForChest: true)
        add("HYDRATE_CHECKPOINT_16OZ", .dailyCore, .hydration, .small, "Hydrate checkpoint", "Reach 16 oz of water")
        add("HYDRATE_CHECKPOINT_48OZ", .dailyCore, .hydration, .medium, "Hydrate halfway", "Reach 48 oz of water")
        add("IRL_PATCH_UPDATE", .dailyCore, .hpCore, .small, "IRL patch update", "Stretch or move for 2 minutes")
        add("CHORE_BLITZ", .dailyCore, .choresWork, .medium, "Chore blitz", "Complete a chores timer")
        add("STATS_REVIEW", .dailyCore, .meta, .tiny, "Check your stats", "Open stats after 7pm")
        add("WINDDOWN_ROUTINE", .dailyCore, .hpCore, .small, "Wind-down routine", "Evening check-in")

        // Habits - hydration
        add("HYDRATE_NOW_GLASS", .dailyHabit, .hydration, .tiny, "Potion sip", "Drink a glass right now")
        add("HYDRATE_32OZ", .dailyHabit, .hydration, .small, "Halfway to full flask", "Hit 32 oz today")
        add("HYDRATE_64OZ", .dailyHabit, .hydration, .medium, "Full flask kind of day", "Hit 64 oz today")
        add("HYDRATE_MULTI_CHECKPOINT", .dailyHabit, .hydration, .medium, "Split the potions", "Log water 3 times", target: 3)

        // Habits - focus
        add("FOCUS_DOUBLE_RUN", .dailyHabit, .focus, .small, "Two focus runs", "Finish two focus sessions", target: 2)
        add("FOCUS_DEEP_SESSION", .dailyHabit, .focus, .medium, "Deep focus", "Finish a 45+ minute session")

        // Habits - hp core
        add("HP_CHECKIN_COMBO", .dailyHabit, .hpCore, .medium, "Triple check-in", "Mood, gut, sleep set")
        add("HP_STRETCH_TRIPLE", .dailyHabit, .hpCore, .medium, "Stretch combo", "Stretch three times", target: 3)

        // Habits - chores/work
        add("CHORE_THREE_SMALL", .dailyHabit, .choresWork, .medium, "Three tiny wins", "Three chores timers", target: 3)
        add("WORK_SPRINT_25", .dailyHabit, .choresWork, .big, "Work sprint", "25 minute work timer")
        add("WORK_EARLY_BLOCK", .dailyHabit, .choresWork, .small, "Early shift", "Work before noon")

        // Bonus
        add("BONUS_DEEP_FOCUS", .bonus, .focus, .medium, "Bonus: Deep focus", "Finish a long session")

        // Weekly
        add("WEEK_FOCUS_10_SESSIONS", .weekly, .focus, .medium, "Weekly focus grind", "Complete 10 focus sessions", target: 10)
        add("WEEK_FOCUS_3_DEEP", .weekly, .focus, .big, "Deep work trilogy", "Finish 3 long sessions", target: 3)
        add("WEEK_HYDRATE_4_DAYS_64OZ", .weekly, .hydration, .medium, "Hydration hero", "Hit 64 oz on 4 days", target: 4)
        add("WEEK_CHORE_5_TIMERS", .weekly, .choresWork, .medium, "Dungeon janitor", "Run 5 chores timers", target: 5)
        add("WEEK_HP_5_CHECKINS", .weekly, .hpCore, .medium, "Keep an eye on the bar", "5 HP check-ins", target: 5)
        add("WEEK_DAILY_CORE_4_DAYS", .weekly, .meta, .big, "Four solid days", "Finish core dailies on 4 days", target: 4)
        add("WEEK_SELFCARE_3_DAYS", .weekly, .hpCore, .medium, "Pamper the protagonist", "Self-care on 3 days", target: 3)
        add("WEEK_MOVEMENT_3_DAYS", .weekly, .hpCore, .medium, "Keep moving", "Move on 3 days", target: 3)

        return defs
    }

    private static func loadProgress(from userDefaults: UserDefaults) -> PlayerProgress? {
        guard let data = userDefaults.data(forKey: StorageKeys.progress) else { return nil }
        return try? JSONDecoder().decode(PlayerProgress.self, from: data)
    }
}

// MARK: - Seeded RNG

private struct SeededGenerator: RandomNumberGenerator {
    private var generator: GKMersenneTwisterRandomSource

    init(date: Date) {
        let seed = UInt64(abs(Int(date.timeIntervalSince1970)))
        generator = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        UInt64(bitPattern: Int64(generator.nextInt()))
    }
}
