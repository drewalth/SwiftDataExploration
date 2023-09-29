//
//  ContentView.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Post]

    @EnvironmentObject private var network: NetworkMonitor

    @State private var requestStatus: RequestStatus = .idle

    @ViewBuilder
    private func content() -> some View {
        switch requestStatus {
        case .loading:
            VStack {
                ProgressView()
                Text("Refreshing data")
            }

        case .error:
            Text("error")

        default:
            ForEach(items) { item in
                NavigationLink {
                    Text(item.title)
                } label: {
                    Text(item.title)
                }
            }
            .onDelete(perform: deleteItems)
        }
    }

    var body: some View {
        NavigationSplitView {
            List {
                content()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }.task {
            do {
                if !network.isConnected { return }

                requestStatus = .loading
                let postRepo = PostRepository(context: modelContext)

                let posts = try await PostAPI.getPosts()

                postRepo.sync(posts)

                requestStatus = .success
            } catch {
                print(error.localizedDescription)
                requestStatus = .error
            }
        }
    }

    private func addItem() {
        Task {
            do {
                let result = try await PostAPI.createPost(title: "foo", author: "bar")

                withAnimation {
                    modelContext.insert(result)
                }

            } catch {
                print(error.localizedDescription)
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Post.self, inMemory: true)
}
