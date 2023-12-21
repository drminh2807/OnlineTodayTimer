//
//  OnlineTodayTimerApp.swift
//  OnlineTodayTimer
//
//  Created by Doan Van Minh on 20/12/2023.
//

import SwiftUI

class ThirdTimerStore: ObservableObject {
    let key = "lastTime"
    
    @Published var startDate = Date()
    
    @Published var endDate = Date()
    
    var timer: Timer?
    
    init() {
        let lastTime = UserDefaults.standard.integer(forKey: key)
        startDate = Date(timeIntervalSince1970: TimeInterval(lastTime))
        if !Calendar.current.isDateInToday(startDate) {
            startDate = Date()
            UserDefaults.standard.setValue(startDate.timeIntervalSince1970, forKey: key)
        }
        
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

    var body: some Scene {
        MenuBarExtra {
            Button(action: {}, label: {
                Text("Button")
            })
        } label: {
            Text("\(formatter.string(from: store.endDate.timeIntervalSince(store.startDate)) ?? "0:0")")
        }

        WindowGroup {
            ContentView()
        }
    }
}
