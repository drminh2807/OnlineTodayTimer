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
    
    @Published var startDate = Date()
    
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
            UserDefaults.standard.setValue(startDate.timeIntervalSince1970, forKey: lastTimeKey)
        }
        totalTime = UserDefaults.standard.string(forKey: totalTimeKey) ?? ""
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            self?.endDate = Date()
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
    
    var displayTime: String {
        var time = store.endDate.timeIntervalSince(store.startDate)
        let totalTime = store.totalTime.split(separator: ":")
        if totalTime.count == 2,
            let hours = Double(totalTime[0]),
            let minutes = Double(totalTime[1]) {
            time = hours * 3600 + minutes * 60 - time
        }
        return formatter.string(from: time) ?? "0h 0m"
    }

    var body: some Scene {
        MenuBarExtra {
            VStack(alignment: .leading) {
                Text("Start from \(dateFormatter.string(from: store.startDate))")
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
