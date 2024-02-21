//
//  OnlineTodayTimerApp.swift
//  OnlineTodayTimer
//
//  Created by Doan Van Minh on 20/12/2023.
//

import SwiftUI
import Combine

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
    
    @Published var totalTime = "" {
        didSet {
            UserDefaults.standard.setValue(totalTime, forKey: totalTimeKey)
        }
    }
    
    @Published var lockedDate: Date?
    
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
        // TODO: alksjdlkas
    }


    var body: some Scene {
        WindowGroup {
            VStack(alignment: .leading) {
                Text("Start from \(startFrom) | End at \(endAt) | Last locked at \(lockedDate)")
                HStack {
                    Text("Total duration \(store.totalTime)").layoutPriority(1)
                    TextField("hh:mm", text: $store.totalTime)
                        .multilineTextAlignment(.trailing)
                }
            }.padding(.all, 16)
        }.windowResizability(.contentMinSize)
        MenuBarExtra {
            Button(action: openApp, label: { Text("Happy coding!") })
        } label: {
            Text(displayTime)
        }
    }
}
