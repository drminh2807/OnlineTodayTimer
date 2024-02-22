//
//  OnlineTodayTimerApp.swift
//  OnlineTodayTimer
//
//  Created by Doan Van Minh on 20/12/2023.
//

import SwiftUI
import Combine
import ServiceManagement

class ThirdTimerStore: ObservableObject {
    let lastTimeKey = "lastTime"
    let totalTimeKey = "totalTime"
    
    var bag = Set<AnyCancellable>()

    let dnc = DistributedNotificationCenter.default()
    
    @Published var startDate = Date() {
        didSet {
            UserDefaults.standard.setValue(startDate.timeIntervalSince1970, forKey: lastTimeKey)
        }
    }
    
    @Published var endDate = Date()
    
    @Published var totalTime = "9:30" {
        didSet {
            UserDefaults.standard.setValue(totalTime, forKey: totalTimeKey)
        }
    }
    
    @Published var lockedDate: Date?
    
    @Published var isEditingStartDate = false
    
    @Published var editingStartTime = ""
    
    @Published var isEditingTotalDuration = false
    
    @Published var editingTotalDuration = ""
    
    var timer: Timer?
    
    init() {
        let lastTime = UserDefaults.standard.integer(forKey: lastTimeKey)
        startDate = Date(timeIntervalSince1970: TimeInterval(lastTime))
        if !Calendar.current.isDateInToday(startDate) {
            startDate = Date()
        }
        totalTime = UserDefaults.standard.string(forKey: totalTimeKey) ?? ""
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.endDate = Date()
        })
        
        dnc.publisher(for: Notification.Name(rawValue: "com.apple.screenIsLocked"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.lockedDate = Date()
                print("Locked")
            }.store(in: &bag)

        dnc.publisher(for: Notification.Name(rawValue: "com.apple.screenIsUnlocked"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if let lockedDate = self?.lockedDate, !Calendar.current.isDateInToday(lockedDate) {
                    self?.startDate = Date()
                }
            }.store(in: &bag)
    }
    deinit {
        timer?.invalidate()
    }
}

@main
struct OnlineTodayTimerApp: App {
    @StateObject var store = ThirdTimerStore()

    let formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
    var totalTime: TimeInterval {
        let totalTime = store.totalTime.split(separator: ":")
        if totalTime.count == 2,
            let hours = Double(totalTime[0]),
            let minutes = Double(totalTime[1]) {
            return hours * 3600 + minutes * 60
        }
        return 0
    }
    
    var displayTime: String {
        let time = store.endDate.timeIntervalSince(store.startDate)
        return (formatter.string(from: totalTime - time) ?? "0h 0m")
    }
    
    var startFrom: String {
        dateFormatter.string(from: store.startDate)
    }
    
    var endAt: String {
        dateFormatter.string(from: store.startDate.addingTimeInterval(totalTime))
    }
    
    var lockedDate: String {
        guard let lockedDate = store.lockedDate else { return "--" }
        return dateFormatter.string(from: lockedDate)
    }
    
    func openApp() {
        NSApp.setActivationPolicy(.regular)
    }
    
    func onEditStart() {
        store.isEditingStartDate = true
    }
    
    func onEditTotalDuration() {
        store.isEditingTotalDuration = true
    }
    
    func onUpdateStart() {
        let components = store.editingStartTime.split(separator: ":")
        guard components.count == 2,
              let hours = Int(components[0]),
              let minutes = Int(components[1]) else {
            store.isEditingStartDate = false
            return
        }
        let date = Calendar.current.date(bySettingHour: hours, minute: minutes, second: 0, of: Date())!
        store.startDate = date
        store.isEditingStartDate = false
    }
    
    func onUpdateTotalDuration() {
        store.isEditingTotalDuration = false
        let components = store.editingTotalDuration.split(separator: ":")
        guard components.count == 2 else { return }
        store.totalTime = store.editingTotalDuration
    }

    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading) {
                if store.isEditingStartDate {
                    HStack {
                        Text("Start at")
                        TextField("hh:mm", text: $store.editingStartTime)
                            .multilineTextAlignment(.trailing)
                        Button(action: onUpdateStart) { Text("Update") }
                    }
                } else {
                    HStack {
                        Text("Start at \(startFrom)")
                        Button(action: onEditStart) { Text("Edit") }
                    }
                }
                if store.isEditingTotalDuration {
                    HStack {
                        Text("Total duration")
                        TextField("hh:mm", text: $store.editingTotalDuration)
                            .multilineTextAlignment(.trailing)
                        Button(action: onUpdateTotalDuration) { Text("Update") }
                    }
                } else {
                    HStack {
                        Text("Total duration \(store.totalTime)")
                        Button(action: onEditTotalDuration) { Text("Edit") }
                    }
                }
                Text("End at \(endAt)")
            }
            .padding(.all, 16)
            .frame(width: 300, height: 110, alignment: .leading)
            .onAppear {
                try? SMAppService.mainApp.register()
            }
        }.windowResizability(.contentSize)
        MenuBarExtra {
            Button(action: openApp, label: { Text("Happy coding!") })
        } label: {
            Text(displayTime)
        }
    }
}
