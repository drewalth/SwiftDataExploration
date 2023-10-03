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

    var body: some View {
        NavigationSplitView {
            List {
                switch requestStatus {
                case .loading:
                    ProgressView()
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
                }
            }.navigationTitle("Posts")
        } detail: {
            Text("Select an item")
        }.task {
            do {
                guard network.isConnected else { return }

                requestStatus = .loading

                let postRepository = PostRepository(context: modelContext)

                let remotePosts = try await PostService.getPosts()
                await postRepository.sync(remotePosts)

                requestStatus = .success
            } catch {
                print(error.localizedDescription)
                requestStatus = .error
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Post.self, inMemory: true)
}
