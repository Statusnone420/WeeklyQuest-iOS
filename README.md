# **WeeklyQuest-iOS**

*A SwiftUI gamified self-care and productivity app.*

WeeklyQuest turns real-life routines into a lightweight RPG. Users build momentum through **focus sessions, daily check-ins, hydration, mood, sleep, and gut tracking**—earning XP, leveling up, unlocking talents, and completing quests along the way.

This repo contains the fully native iOS implementation of WeeklyQuest, built on a clean SwiftUI + MVVM architecture with a Coordinator and DependencyContainer at the core.

---

## **✨ Features**

### **Game-Inspired Self-Care**

* Level up through real-life actions
* Earn XP, complete quests, unlock achievements
* Potions, buffs, streaks, and seasonal progression

### **Focus Sessions**

* Guided deep-focus timers
* Streaks, XP boosts, session stats
* Energy/HP impact & recovery

### **Daily Health Check-Ins**

* Hydration, mood, sleep, gut sliders
* Automatic quest completions tied to behaviors
* Smart reminders for hydration and posture

### **Talent Tree (10 Stages, 20 Nodes)**

* Unlock perks that evolve gameplay and visuals
* Tree image grows every two nodes
* High-resolution PNGs rendered in-app

### **Dynamic Player Card**

* Avatar, title, stats, buffs, HP/XP bars
* Responsive layout for all modern iPhones

---

## **🧱 Architecture**

WeeklyQuest-iOS uses a stable, transparent structure:

### **Core**

* `QuestChatApp.swift` — Single @main entry point
* `AppCoordinator` — Builds and routes root views
* `DependencyContainer` — Central dependency graph

### **UI**

* SwiftUI views (FocusView, PlayerCard, TalentsView, OnboardingView, etc.)
* Glass-style cards, gradients, Adaptive layouts
* Dynamic backgrounds and motion

### **ViewModels**

ObservableObject-driven models for:

* Player state
* Session stats
* Talent tree
* Quest logic
* Onboarding flows

### **Storage**

* Lightweight JSON/UserDefaults persistence
* Future-proofed for CloudKit migration

---

## **🧪 Debug / Dev Mode**

* Local dev mode enabled through:

  ```js
  localStorage.setItem("questchat_dev", "true"); location.reload();
  ```
* Debug buttons for achievements, XP, quest triggers, and more
* Simulator-friendly testing for timers, hydration reminders, and notifications

---

## **🚀 Roadmap**

* CloudKit sync for player profile + progress
* Achievement popovers with HQ badge previews
* Polish pass for onboarding with new sliders
* Expanded potion/buff system
* Weekly quest improvements

---

## **📦 Requirements**

* iOS 17+
* Xcode 15+
* Swift 5.9+

---

## **📁 Project Structure**

```
WeeklyQuest-iOS/
├─ QuestChatNative/
│  ├─ App/
│  ├─ Coordinator/
│  ├─ DependencyContainer/
│  ├─ Features/
│  │   ├─ Focus
│  │   ├─ Player
│  │   ├─ Talents
│  │   ├─ Quests
│  │   ├─ Onboarding
│  │   └─ Achievements
│  └─ Storage/
├─ QuestCatalog.md
├─ README.md
```

---

## **🧑‍💻 Contributors**

* **@Statusnone420** — Lead dev / designer

---

## **📣 About**

WeeklyQuest is an independent well-being project blending RPG mechanics with real-life behavior tracking. Designed for clarity, momentum, and mental health support without pressure.
