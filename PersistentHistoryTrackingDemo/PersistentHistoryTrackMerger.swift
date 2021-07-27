//
//  PersistentHistoryTrackMerger.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import CoreData
import Foundation

extension PersistentHistoryTrackerManager {
    func merger(transaction: [NSPersistentHistoryTransaction]) {
        let viewContext = container.viewContext
        viewContext.perform {
            transaction.forEach { transaction in
                let userInfo = transaction.objectIDNotification().userInfo ?? [:]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: userInfo, into: [viewContext])
            }
        }

        // 更新最后的transaction时间戳
        guard let lastTimestamp = transaction.last?.timestamp else { return }
        userDefaults.updateLastHistoryTransactionTimestamp(for: currentActor, to: lastTimestamp)
    }
}
