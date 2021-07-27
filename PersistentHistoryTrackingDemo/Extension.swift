//
//  Extension.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import Foundation

extension UserDefaults {
    static let appGroup = UserDefaults(suiteName: appGroupID)!
}

extension UserDefaults {
    /// 从全部的app actor的最后时间戳中获取最晚的时间戳
    /// 只删除最晚的时间戳之前的transaction，这样可以保证其他的appActor
    /// 都可以正常的获取未处理的transaction
    /// 设置了一个7天的界限。即使有的appActor没有使用（没有创建userdefauls）
    /// 也会至多只保留7天的transaction
    /// - Parameter appActors: app角色，比如healthnote ,widget
    /// - Returns: 日期（时间戳）, 返回值为nil时会处理全部未处理的transaction
    func lastCommonTransactionTimestamp(in appActors: [AppActor]) -> Date? {
        // 七天前
        let sevenDaysAgo = Date().addingTimeInterval(-604800)
        let timestamp = appActors
            .compactMap { lastHistoryTransactionTimestamp(for: $0) }
            .min() ?? sevenDaysAgo
        return max(timestamp, sevenDaysAgo)
    }

    /// 获取指定的appActor最后处理的transaction的时间戳
    /// - Parameter appActore: app角色，比如healthnote ,widget
    /// - Returns: 日期（时间戳）, 返回值为nil时会处理全部未处理的transaction
    func lastHistoryTransactionTimestamp(for appActor: AppActor) -> Date? {
        let key = "PersistentHistoryTracker.lastToken.\(appActor.rawValue)"
        return object(forKey: key) as? Date
    }

    /// 给指定的appActor设置最新的transaction时间戳
    /// - Parameters:
    ///   - appActor: app角色，比如healthnote ,widget
    ///   - newDate: 日期（时间戳）
    func updateLastHistoryTransactionTimestamp(for appActor: AppActor, to newDate: Date?) {
        let key = "PersistentHistoryTracker.lastToken.\(appActor.rawValue)"
        set(newDate, forKey: key)
    }
}
