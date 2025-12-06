import Foundation
import Combine

struct DailyHealthRatings: Codable {
    var mood: Int?      // 1–5, nil means Not set
    var gut: Int?
    var sleep: Int?
    var activity: Int?
}

final class DailyHealthRatingsStore: ObservableObject {
    private struct Entry: Codable {
        let day: Date
        let ratings: DailyHealthRatings
    }

    private let userDefaults: UserDefaults
    private let storageKey = "daily_health_ratings_v1"
    private let calendar = Calendar.current

    @Published private(set) var ratingsByDay: [Date: DailyHealthRatings] = [:]

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func ratings(for date: Date = Date()) -> DailyHealthRatings {
        let day = calendar.startOfDay(for: date)
        return ratingsByDay[day] ?? DailyHealthRatings(mood: nil, gut: nil, sleep: nil, activity: nil)
    }

    func update(_ transform: (inout DailyHealthRatings) -> Void, on date: Date = Date()) {
        let day = calendar.startOfDay(for: date)
        var current = ratingsByDay[day] ?? DailyHealthRatings(mood: nil, gut: nil, sleep: nil, activity: nil)
        transform(&current)
        ratingsByDay[day] = current
        save()
    }

    func setMood(_ value: Int?, on date: Date = Date()) { update { $0.mood = value } }
    func setGut(_ value: Int?, on date: Date = Date()) { update { $0.gut = value } }
    func setSleep(_ value: Int?, on date: Date = Date()) { update { $0.sleep = value } }
    func setActivity(_ value: Int?, on date: Date = Date()) { update { $0.activity = value } }

    private func save() {
        let entries: [Entry] = ratingsByDay.map { Entry(day: $0.key, ratings: $0.value) }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        guard let entries = try? JSONDecoder().decode([Entry].self, from: data) else { return }
        var map: [Date: DailyHealthRatings] = [:]
        for entry in entries {
            let day = calendar.startOfDay(for: entry.day)
            map[day] = entry.ratings
        }
        ratingsByDay = map
    }
}
