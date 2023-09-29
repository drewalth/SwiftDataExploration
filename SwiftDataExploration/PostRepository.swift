//
//  PostRepository.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import Foundation
import SwiftData
import SwiftUI

struct PostRepository {
    private let repo: ModelRepository<Post>

    init(context: ModelContext) {
        repo = ModelRepository(context: context)
    }

    func sync(_ remoteModels: [Post]) {
        do {
            var localPosts = try repo.getAll()

            let postsToDelete = checkPostsForDeletion(localPosts: localPosts, remotePosts: remoteModels)

            repo.deleteEntities(postsToDelete)
            updateLocalPosts(with: remoteModels, in: &localPosts)
            repo.create(remoteModels)

            try repo.save()

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
