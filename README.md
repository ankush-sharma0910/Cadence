Cadence

Find your rhythm.

Cadence is a calm, minimal productivity app for macOS, built natively with Swift and SwiftUI. It helps you plan your day, keep your goals moving and see what you have actually finished, in one dark, distraction-free window.

Know what matters. Follow your rhythm. Show up every day.

<img width="1470" height="956" alt="image" src="https://github.com/user-attachments/assets/782547c6-2ffe-44dc-bfc7-2860a201f01b" />

Features
Goals
Circular progress rings, one per goal, with the percentage in the centre and the goal's name underneath.
Every goal has a unit (problems, km, hours...), a target and a period (daily, weekly or monthly). Progress starts again from zero each period.
Log progress from the left panel: finished 1 of 2 LeetCode problems, or ran 3.5 km. Entries can be removed, and everything you log is kept.
Add, edit and delete goals, and show or hide each one on the dashboard.
Schedule
A timetable for the day with a start and end time for every entry, such as 2:30 – 3:30 PM.
Set up your usual schedule once, for each weekday. It appears automatically every week.
Change one day only without touching your usual schedule, and reset it whenever you like.
The entry happening right now is highlighted, and the day scrolls to it.
To-do list
A clean list for any date, with checkboxes and strikethrough for finished tasks.
Add tasks, double-click to edit them, and delete them.
A completion percentage and progress line for the day.
A monthly average ring and a saved month-by-month history, so you can see how consistent you have been.
Everything else
Date search: jump to any date to see its schedule and to-dos.
An editable line at the top for something worth remembering, with your choice of font size and style.
The app moves on to the new day by itself at midnight.
Everything is stored locally on your Mac. No account, no server, no tracking.
Built with
Swift and SwiftUI
Xcode
The Observation framework (@Observable) for shared app state
JSON files for storage
Git and GitHub
Requirements
A Mac running macOS. The APIs used need macOS 14 or newer. It is built and tested on macOS 27.
Xcode, to build it from source.
Getting started
Clone this repository.
Open Cadence.xcodeproj in Xcode.
Choose My Mac as the run destination.
Press ⌘R.

No packages or extra dependencies need installing.

Build a standalone app
In Xcode, choose Product → Scheme → Edit Scheme…, select Run, and set Build Configuration to Release.
Choose Product → Build, then Product → Show Build Folder in Finder.
Open Products → Release and drag Cadence.app into your Applications folder.
Project structure
Cadence/
├── CadenceApp.swift        App entry point; creates the shared store
├── Models/                 Plain data types
│   ├── Goal.swift
│   ├── GoalLog.swift
│   ├── ScheduleEntry.swift
│   ├── DayOverride.swift
│   ├── TodoItem.swift
│   ├── MonthlyRecord.swift
│   └── LineFontStyle.swift
├── Services/               Logic that is not about drawing
│   ├── AppStore.swift      The single source of truth for app data
│   ├── Storage.swift       Saves and loads JSON files
│   └── CompletionStats.swift
├── Views/                  Whole sections of the screen
│   ├── ContentView.swift
│   ├── DashboardView.swift
│   ├── ScheduleView.swift
│   └── TodoView.swift
└── Components/             Smaller, reusable pieces
    ├── Theme.swift         Colours and spacing
    ├── GoalRingView.swift
    ├── MiniRingView.swift
    ├── EditableLineView.swift
    ├── GoalEditorView.swift
    ├── LogProgressView.swift
    ├── ScheduleEditorView.swift
    ├── DateSearchView.swift
    └── MonthlyHistoryView.swift
How it fits together
AppStore owns all of the data: goals, logged progress, the usual schedule, one-day schedules, tasks and monthly history. Every screen reads from it, so they always agree.
Each list saves itself to disk whenever it changes.
Views only draw what the store tells them, so changing the data redraws the screen automatically.
Your data and privacy
Cadence makes no network connections. Nothing leaves your Mac.
Goals, logs, schedules, tasks and history are saved as small JSON files in the app's own folder inside ~/Library/Containers/.
The line at the top and its font settings are saved with the app's preferences.
No API keys, passwords or personal credentials are stored in this repository.
Status and roadmap

Cadence is in active development and already usable every day.

Planned:

 Keyboard shortcuts and fuller VoiceOver support
 Protection against damaged save files, plus export and import of a backup
 Goal history over time
 Automated tests for the progress and schedule logic
 A final polish pass
About this project

Cadence is both a tool I want to use every day and a way to learn real software development: Swift and SwiftUI, version control with Git and GitHub, testing and project hygiene. It was built step by step with AI assistance, and every change was tested and committed along the way.

License

No license has been chosen yet, so all rights are reserved by default. Add a LICENSE file if you decide to share or open-source the project.
