//
//  Persistence.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        return result
    }()

    let container: NSPersistentContainer
    let persistentHistoryTracker: PersistentHistoryTrackerManager

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PersistentTrackBlog")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        let desc = container.persistentStoreDescriptions.first!

        // 数据库保存在App Group Container中，其他的App或者App Extension也可以读取
        // 请在已经设置好app group的情况下再设置url

//        let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
//        desc.url = groupURL
        // 在该Description上启用Persistent History Track
        desc.setOption(true as NSNumber,
                       forKey: NSPersistentHistoryTrackingKey)
        // 接收有关的远程通知
        desc.setOption(true as NSNumber,
                       forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.persistentStoreDescriptions = [desc]

        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

        container.viewContext.transactionAuthor = AppActor.mainApp.rawValue
        persistentHistoryTracker = PersistentHistoryTrackerManager(
            container: container,
            currentActor: AppActor.mainApp
        )
    }
}

extension PersistenceController {
    func batchInsert() {
        let items = (0..<10).reduce(into: [[String: Any]()]) { result, _ in
            result.append(["timestamp": Date()])
        }
        let count = items.count
        var index = 0
        let request = NSBatchInsertRequest(entity: Item.entity(), dictionaryHandler: { dictionary in
            guard index < count else { return true }
            dictionary.addEntries(from: items[index])
            index += 1
            return false
        })
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        backgroundContext.name = "batchContext"
        backgroundContext.transactionAuthor = AppActor.mainApp.rawValue
        backgroundContext.perform {
            do {
                try backgroundContext.execute(request)
            } catch {
                print(error)
            }
        }
    }

    func batchDelete() {
        let context = PersistenceController.shared.container.newBackgroundContext()
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Item")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        context.transactionAuthor = AppActor.mainApp.rawValue
        context.name = "batchContext"
        context.perform {
            do {
                try context.execute(deleteRequest)
            } catch {
                print(error)
            }
        }
    }
}
