//
//  PersistentHistoryTrackCleaner.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import CoreData
import Foundation

/// 删除已经处理过的transaction
public struct PersistentHistoryCleaner {
    /// NSPersistentCloudkitContainer
    let container: NSPersistentContainer
    /// app group userDefaults
    let userDefault = UserDefaults.appGroup
    /// 全部的appActor
    let appActors = AppActor.allCases

    /// 清除已经处理过的persistent history transaction
    public func clean() {
        guard let timestamp = userDefault.lastCommonTransactionTimestamp(in: appActors) else {
            return
        }

        // 获取可以删除的transaction的request
        let deleteHistoryRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: timestamp)

        // 只删除由App Group的成员产生的Transaction
        if let fetchRequest = NSPersistentHistoryTransaction.fetchRequest {
            var predicates: [NSPredicate] = []

            appActors.forEach { appActor in
                // 清理App Group成员创建的Transaction
                let perdicate = NSPredicate(format: "%K = %@",
                                            #keyPath(NSPersistentHistoryTransaction.author),
                                            appActor.rawValue)
                predicates.append(perdicate)
            }

            let compoundPredicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
            fetchRequest.predicate = compoundPredicate
            deleteHistoryRequest.fetchRequest = fetchRequest
        }

        container.performBackgroundTask { context in
            do {
                try context.execute(deleteHistoryRequest)
                print("清除了Transaction")
                // 重置全部appActor的时间戳
                appActors.forEach { actor in
                    userDefault.updateLastHistoryTransactionTimestamp(for: actor, to: nil)
                }
            } catch {
                print(error)
            }
        }
    }
}
