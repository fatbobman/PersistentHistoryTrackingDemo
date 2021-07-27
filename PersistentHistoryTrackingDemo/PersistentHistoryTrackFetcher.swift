//
//  PersistentHistoryTrackFetcher.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import CoreData
import Foundation

extension PersistentHistoryTrackerManager {
    enum Error: String, Swift.Error {
        case historyTransactionConvertionFailed
    }

    func fetcher() throws -> [NSPersistentHistoryTransaction] {
        let fromDate = userDefaults.lastHistoryTransactionTimestamp(for: currentActor) ?? Date.distantPast

        let historyFetchRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: fromDate)
        if let fetchRequest = NSPersistentHistoryTransaction.fetchRequest {
            var predicates: [NSPredicate] = []

            AppActor.allCases.forEach { appActor in
                if appActor == currentActor {
                    // 本代码假设在App中，即时通过backgroud进行的操作也已经被即时合并到了ViewContext中
                    // 因此对于当前appActor，只处理名称为batchContext上下文产生的transaction
                    let perdicate = NSPredicate(format: "%K = %@ AND %K = %@",
                                                #keyPath(NSPersistentHistoryTransaction.author),
                                                appActor.rawValue,
                                                #keyPath(NSPersistentHistoryTransaction.contextName),
                                                "batchContext")
                    predicates.append(perdicate)
                } else {
                    // 其他的appActor产生的transactions，全部都要进行处理
                    let perdicate = NSPredicate(format: "%K = %@",
                                                #keyPath(NSPersistentHistoryTransaction.author),
                                                appActor.rawValue)
                    predicates.append(perdicate)
                }
            }

            let compoundPredicate = NSCompoundPredicate(type: .or, subpredicates: predicates)
            fetchRequest.predicate = compoundPredicate
            historyFetchRequest.fetchRequest = fetchRequest
        }

        guard let historyResult = try backgroundContext.execute(historyFetchRequest) as? NSPersistentHistoryResult,
              let history = historyResult.result as? [NSPersistentHistoryTransaction]
        else {
            throw Error.historyTransactionConvertionFailed
        }
        return history
    }
}
