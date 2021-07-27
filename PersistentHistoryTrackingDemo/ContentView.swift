//
//  ContentView.swift
//  PersistentHistoryTrackingDemo
//
//  Created by Yang Xu on 2021/7/26.
//

import CoreData
import SwiftUI

struct ContentView: View {
    @FetchRequest(
        entity: Item.entity(),
        sortDescriptors: [NSSortDescriptor(key: #keyPath(Item.timestamp), ascending: true)]
    ) var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            List {
                ForEach(items) { item in
                    Text("\(item.timestamp ?? Date())")
                }
            }
            .navigationTitle("持久化历史跟踪演示")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("批量添加") {
                        PersistenceController.shared.batchInsert()
                    }
                }
                ToolbarItem {
                    Button("批量删除") {
                        PersistenceController.shared.batchDelete()
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
