# Article

Build an offline-first iOS app prototype using SwiftData and the Codable protocol in 45 minutes.

This is a quick proof of concept for building offline-first iOS apps using the new SwiftData framework and the Codable
protocol to
make working with remote AND local persisted data a little easier.

This is the follow-up to my previous post [CoreDataExploration](https://github.com/drewalth/CoreDataExploration) where
we experimented with vanilla CoreData and Codable.

## Use Case

The use case for this approach is an offline-first app that needs to work with remote data. The app should be able to
work offline and sync with the remote data source when it's available. This also assumes that the remote data source
is the source of truth.

## The Problem

Traditionally, when building an iOS app that needs to work with remote data, we would have to write a lot of boilerplate
and structures that mirror our CoreData models.

For example, if we have a CoreData model called `Person` that looks like this:

```swift
class Person: NSManagedObject {
    @NSManaged var id: Int
    @NSManaged var name: String
    @NSManaged var age: Int
}
```

We would also need to create a struct that mirrors this model to use when decoding our remote data:

```swift
struct PersonRemote: Codable {
    let id: Int
    let name: String
    let age: Int
}
```

This is a lot of boilerplate and it's easy to make mistakes when writing the struct. For example, if we forget to add
a property to the struct, the compiler won't complain, but we'll get a runtime error when we try to decode the data. In
addition, updating the local CoreData model with this approach is not very clean either.

## Previous Approach

Previously, we were able to use the `Codable` protocol to decode our remote data into our CoreData models. This was
great because we didn't have to write a lot of boilerplate and we could use the same model for both CoreData and
decoding our remote data.

This approach works, however, it has some notable drawbacks:

- Contenxt/thread safety. Very fragile.
- Too many "hacky" workarounds related to JSONDecoder and JSONEncoder
- And more...

## SwiftData Approach

Ever since the announcement of the new SwiftData framework, I've been SUPER excited to try it out. It's a new framework
that Apple has recently released and aims to make working with CoreData a lot easier.

Like SwiftUI, SwiftData is declarative and uses a lot of the same concepts. For example, we can declare our CoreData
model like this:

```swift
import SwiftData

@Model
struct Person {
    let id: Int
    let name: String
    let age: Int
}
```

Boom. That's it. We don't need to create a CoreData model or anything. SwiftData will automatically create the model for
us.

## The Fun Part

Okay, now that we've got an idea of what SwiftData is and the problem we're trying to solve, let's start coding!

If you want to skip all of this, I've put together a sample application with the final code. You can find it
[here]()

### Core Features

- Fetch remote data
- Persist remote data
- Sync local data with remote data source
- Create new local data and sync with remote data source

### Project Setup

#### System Requirements

- Xcode 15
- iOS 17
- Nodejs LTS (currently v18)

First, we need to create a new Xcode project. I'm going to call mine `SwiftDataExploration`. I'm also going to select
`SwiftUI` as the user interface and `SwiftData` as the storage option. This will add a few things to our project and a
default model called `Item` --we'll delete this later.

### Remote Data

Next, we need to create a remote data source. For this example, we're going to use a mock API that returns a list of
Posts. For our server, we'll use [json-server](https://www.npmjs.com/package/json-server).

From the project root, run the following commands:

```shell
npm init -y
npm install --save-dev json-server
```

Next, create a file called `db.json` in the project root and add the following:

```json
{
  "posts": [
    {
      "id": 1,
      "title": "Post 1",
      "author": "Johnny Appleseed"
    }
  ]
}
```

Next, add the following to your `package.json` file:

```json
"scripts": {
"start": "json-server --watch db.json"
}
```

Now, we can start our server by running `npm start` from the project root.

### Local Data Model

Next, we need to create our local data model. Create a new file called `PostModel`, that contains the following:

```swift
import SwiftData

@Model
class Post {
    let id: Int
    let title: String
    let author: String
}
```

Now let's add this model to our schema. In the `SwiftDataExplorationApp.swift` file, you'll see the following variable:

```swift
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
```

Replace `Item.self` with `Post.self`.

Now in the `ContentView.swift` file, replace the `Item` model with `Post`:

```swift
@Query private var items: [Item]

// replace with 

@Query private var items: [Item]
```

Fix the compiler errors which will pop up in the `ForEach` and do the same in for the preview:

```swift
#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

// replace with

#Preview {
    ContentView()
        .modelContainer(for: Post.self, inMemory: true)
}
```

Great. Now we have our local data model setup. Next, we need to fetch our remote data.

### Fetch Remote Data

Before we can fetch our remote data and decode it, our model needs to conform to the `Codable` protocol. We can do this
by adding the following extension to our `Post` model:

```swift
@Model
class Post: Codable {
    // other stuff...
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.author = try container.decode(String.self, forKey: .author)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.author, forKey: .author)
    }

    enum CodingKeys: CodingKey {
        case id, title, author
    }
}
```

Incredible. Now in just a few short steps, we've created our local data model and made it conform to the `Codable`
without any goofy hacks.

Create a new file called `PostService.swift` with a struct called `PostService` and add the following method:

```swift
    static func getPosts() async throws -> [Post] {
        let url = URL(string: "http://localhost:3000/posts")!

        let session = URLSession.shared

        // Make the network request
        let (data, response) = try await session.data(from: url)

        // Check for HTTP errors
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        // Decode the data into an array of Post
        let decoder = JSONDecoder()
        let posts = try decoder.decode([Post].self, from: data)

        return posts
    }
```

Now in the `ContentView.swift` file add a `.task` modifier to the `NavigationSplitView`:

```swift

NavigationSplitView {
    // stuff
}.task {
    do {
        let posts = try await PostService.getPosts()
        print(posts)
    } catch {
        // handle error
    }
}
```

Run the app and you should see the following in the console:

```shell
[SwiftDataExploration.Post(id: 1, title: "Post 1", author: "Johnny Appleseed")]
```

### Persist Remote Data

Now that we have our remote data, we need to persist it locally. To do this, we're going to create two new
files; `ModelRepository.swift` and `PostRepository.swift`.

The `ModelRepository.swift` file will provide a generic interface for our local models that can be used inside and
outside of SwiftUI views.

Inside the `ModelRepository.swift` file, add the following:

```swift
import SwiftData

struct ModelRepository<Model: PersistentModel> {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }
    
    func getAll() throws -> [Model] {
        let params = FetchDescriptor<Model>()
        let result = try context.fetch(params)
        return result
    }
}
```

Now in the `PostRepository.swift` file we'll create an interface for our `Post` model that uses the `ModelRepository`
and we'll add a method called `sync` that will sync our local data with the remote data source.

```swift
import SwiftData

struct PostRepository {
    private let repository: ModelRepository<Post>

    init(context: ModelContext) {
        self.repository = ModelRepository(context: context)
    }

    func sync(_ remotePosts: [Post]) throws -> [Post] {
        do {
            var localPosts = try repository.getAll()
            print(localPosts)
        } catch {
            print(error.localizedDescription)
        }
    }
}
```

Back in the `ContentView.swift` file, let's adjust our `.task` modifier to use the `PostRepository`:

```swift
.task {
    do {
        let postRepository = PostRepository(context: modelContext)
        let remotePosts = try await PostService.getPosts()
        postRepository.sync(remotePosts)
    } catch {
        print(error.localizedDescription)
    }
}
```

Run the app and you should see the following in the console:

```shell
[]
```

That's because we haven't added any posts to our local data store yet. Let's do that now.

In `ModelRepository.swift` add the following methods:

```swift
    /// Add models to the local data store
    func create(_ models: [Model]) {
        for model in models {
            context.insert(model)
        }
    }
    
    /// Save changes made to the local data store
    func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
```

Then back in the `PostRepository.swift` file, add the following to the `sync` method:

```swift
    func sync(_ remotePosts: [Post]) throws -> [Post] {
        do {
            var localPosts = try repository.getAll()
            print(localPosts)
            repository.create(remotePosts)
            
            try repository.save()
            
            // verify that the posts were saved
            localPosts = try repository.getAll()
            print(localPosts)
        } catch {
            print(error.localizedDescription)
        }
    }
```

Awesome! Now run the app and you should see some posts in the console and in the UI. Stop the app and restart it. You
should now see two posts with the same title, "Post 1." This is because we're not specifying a unique identifier (or
primary key) for
our posts. Let's fix that now.

In the `PostModel.swift` file, update the `id` property to the following:

```swift
    @Attribute(.unique)
    var id: Int
```

Now in the simulator, delete the app. Then run it, close it, and run it again. You should now see only one post with
the title "Post 1."

Let's verify that this is working by adding a new post to our remote data source. In the `db.json` file, add a new post:

```json
{
  "posts": [
    {
      "id": 1,
      "title": "Post 1",
      "author": "Johnny Appleseed"
    },
    {
      "id": 2,
      "title": "Post 2",
      "author": "Johnny Appleseed"
    }
  ]
}
```

Now run the app and you should see two posts in the console and in the UI :party_parrot:

### Update Local Data with Remote Data

Now that we have our local data store syncing with our remote data source, let's update the PostRepository to update
existing posts. To do this we'll create a function called `updateLocalPosts` that will compare the remote posts with the
local posts. We'll also need to make our `Post` model conform to the `Equatable` protocol so that we can compare posts.

```swift
// PostModel.swift

@Model
class Post: Codable, Equatable {
    // other stuff...    
}
```

Now in the `PostRepository.swift` file, add the following method:

```swift
    func updateLocalPosts(with remotePosts: [Post], in localPosts: inout [Post]) {
        for (index, localPost) in localPosts.enumerated() {
            if let matchingRemotePost = remotePosts.first(where: { $0.id == localPost.id }),
               localPost != matchingRemotePost
            {
                localPosts[index] = matchingRemotePost
            }
        }
    }
```

Then lets call it in the sync method and remove the verifying print statement. We'll also want to
call `updateLocalPosts` before we create any new posts.

```swift
    func sync(_ remotePosts: [Post]) throws -> [Post] {
        do {
            var localPosts = try repository.getAll()
            updateLocalPosts(with: remotePosts, in: &localPosts)
            repository.create(remotePosts)
            
            try repository.save()
        } catch {
            print(error.localizedDescription)
        }
    }
```

Now lets verify this is working as expected. In the `db.json` file, update the title of the first post to "Post 1
Updated." Then run the app and you should see the new title in the UI.

So cool.

### Offline Support

Now that we have our local data store syncing with our remote data source, let's add some offline support. We want to
allow people the ability to create new posts while offline and then sync them when they come back online.

