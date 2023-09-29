//
//  ModelRepository.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import Foundation
import SwiftData

struct ModelRepository<Entity: PersistentModel> {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getAll() throws -> [Entity] {
        let params: FetchDescriptor<Entity> = .init()

        let result = try context.fetch(params)

        return result
    }

    func deleteEntities(_ entities: [Entity]) {
        for entity in entities {
            context.delete(entity)
        }
    }

    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }

    func create(_ entities: [Entity]) {
        for entity in entities {
            context.insert(entity)
        }
    }
}
