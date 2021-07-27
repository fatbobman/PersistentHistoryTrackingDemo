//
//  PersistentHistoryTrackManager.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import Combine
import CoreData
import Foundation

final class PersistentHistoryTrackerManager {
    init(container: NSPersistentContainer, currentActor: AppActor) {
        self.container = container
        self.currentActor = currentActor

        // 注册StoreRemoteChange的响应
        NotificationCenter.default.publisher(
            for: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
        .subscribe(on: queue, options: nil)
        .sink { _ in
            // notification的内容没有意义，仅起到提示需要处理的作用
            self.processor()
        }
        .store(in: &cancellables)
    }

    var container: NSPersistentContainer
    var currentActor: AppActor
    let userDefaults = UserDefaults.appGroup

    lazy var backgroundContext = { container.newBackgroundContext() }()

    private var cancellables: Set<AnyCancellable> = []
    private lazy var queue = {
        DispatchQueue(label: "com.fatbobman.\(self.currentActor.rawValue).processPersistentHistory")
    }()

    /// 处理persistent history
    private func processor() {
        // 在正确的上下文中进行操作，避免影响主线程
        backgroundContext.performAndWait {
            // fetcher用来获取需要处理的transaction
            guard let transactions = try? fetcher() else {
                print("没有需要处理的Transaction")
                return
            }
            // merger将transaction合并当当前的视图上下文中
            merger(transaction: transactions)
            print("合并了\(transactions.count)条Transaction")
        }
    }
}

enum AppActor: String, CaseIterable {
    case mainApp
    case safariExtension
}
