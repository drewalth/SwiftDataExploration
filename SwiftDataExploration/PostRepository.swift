//
//  PostRepository.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import SwiftData

struct PostRepository {
    private let repository: ModelRepository<Post>

    init(context: ModelContext) {
        repository = ModelRepository(context: context)
    }

    func sync(_ remotePosts: [Post]) async {
        do {
            // load local posts
            var localPosts = try repository.getAll()

            await syncPendingPosts(localPosts)

            try repository.save()

            // first delete stale posts
            let postsToDelete = checkPostsForDeletion(localPosts: localPosts, remotePosts: remotePosts)
            repository.deleteEntities(postsToDelete)

            updateLocalPosts(with: remotePosts, in: &localPosts)

            repository.create(remotePosts)

            try repository.save()
        } catch {
            print(error.localizedDescription)
        }
    }

    func updateLocalPosts(with remotePosts: [Post], in localPosts: inout [Post]) {
        for (index, localPost) in localPosts.enumerated() {
            if let matchingRemotePost = remotePosts.first(where: { $0.id == localPost.id }),
               localPost != matchingRemotePost
            {
                localPosts[index] = matchingRemotePost
            }
        }
    }

    func syncPendingPosts(_ posts: [Post]) async {
        await withTaskGroup(of: Post?.self) { group in
            for post in posts where post.pending == true {
                group.addTask {
                    try? await PostService.createPost(title: post.title, author: post.author)
                }
            }

            for await result in group {
                if let post = result {
                    repository.deleteEntities([post])
                } else {
                    print("Failed to upload post.")
                }
            }
        }
    }

    private func checkPostsForDeletion(localPosts: [Post], remotePosts: [Post]) -> [Post] {
        var postsToDelete: [Post] = []

        let remotePostIds = Set(remotePosts.map { $0.id })

        for localPost in localPosts {
            if !remotePostIds.contains(localPost.id) {
                postsToDelete.append(localPost)
            }
        }

        return postsToDelete
    }
}
