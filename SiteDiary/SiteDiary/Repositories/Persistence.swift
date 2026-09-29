import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview = PersistenceController(inMemory: true)

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SiteDiary")
        if let description = container.persistentStoreDescriptions.first {
            if inMemory {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                description.url = DiaryAppGroup.storeURL()
            }
        }
        let loaded = DispatchSemaphore(value: 0)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            loaded.signal()
        })
        waitUntilStoreLoads(loaded)
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private func waitUntilStoreLoads(_ loaded: DispatchSemaphore) {
        let deadline = Date().addingTimeInterval(5)
        if Thread.isMainThread {
            while loaded.wait(timeout: .now()) == .timedOut {
                if Date() > deadline {
                    fatalError("The site diary store did not load.")
                }
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
            }
            return
        }
        if loaded.wait(timeout: .now() + 5) == .timedOut {
            fatalError("The site diary store did not load.")
        }
    }
}
