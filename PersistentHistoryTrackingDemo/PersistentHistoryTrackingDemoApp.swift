//
//  PersistentHistoryTrackingDemoApp.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/27.
//

import SwiftUI

@main
struct PersistentHistoryTrackingDemoApp: App {
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onChange(of: scenePhase) { scenePhase in
                    switch scenePhase {
                    case .active:
                        break
                    case .background:
                        let clean = PersistentHistoryCleaner(container: persistenceController.container)
                        clean.clean()
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }
}
