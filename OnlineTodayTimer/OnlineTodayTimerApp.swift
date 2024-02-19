//
//  OnlineTodayTimerApp.swift
//  OnlineTodayTimer
//
//  Created by Doan Van Minh on 20/12/2023.
//

import SwiftUI

class ThirdTimerStore: ObservableObject {
    let lastTimeKey = "lastTime"
    let totalTimeKey = "totalTime"
    
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
    
    var timer: Timer?
    
    init() {
        let lastTime = UserDefaults.standard.integer(forKey: lastTimeKey)
        startDate = Date(timeIntervalSince1970: TimeInterval(lastTime))
        if !Calendar.current.isDateInToday(startDate) {
            startDate = Date()
        }
        totalTime = UserDefaults.standard.string(forKey: totalTimeKey) ?? ""
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            let now = Date()
            if let endDate = self?.endDate, !Calendar.current.isDateInToday(endDate) {
                self?.startDate = now
            }
            self?.endDate = now
        })
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
        var time = store.endDate.timeIntervalSince(store.startDate)
        return formatter.string(from: totalTime - time) ?? "0h 0m"
    }
    
    var startFrom: String {
        dateFormatter.string(from: store.startDate)
    }
    
    var endAt: String {
        dateFormatter.string(from: store.startDate.addingTimeInterval(totalTime))
    }

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading) {
                Text("Start from \(startFrom) | End at \(endAt)")
                HStack {
                    Text("Total duration").layoutPriority(1)
                    TextField("hh:mm", text: $store.totalTime)
                        .multilineTextAlignment(.trailing)
                }
            }.padding(.all, 16)
        } label: {
            Text(displayTime)
        }.menuBarExtraStyle(.window)

        WindowGroup {
            ContentView()
        }
    }
}
