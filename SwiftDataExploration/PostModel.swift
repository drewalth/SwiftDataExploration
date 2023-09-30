//
//  PostModel.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import Foundation
import SwiftData

@Model
class Post: Codable, Equatable {
    @Attribute(.unique)
    var id: Int
    var title: String
    var author: String
    /// post is waiting to be synced. Local only value.
    var pending: Bool?

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(author, forKey: .author)
    }

    enum CodingKeys: CodingKey {
        case id, title, author
    }
}
