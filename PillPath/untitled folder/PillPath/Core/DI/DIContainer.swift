

import Foundation


final class DIContainer {

    static let shared = DIContainer()
    private init() {}

    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]

   
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[ObjectIdentifier(type)] = factory
    }

   
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        singletons[key] = factory()
    }

    
    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let singleton = singletons[key] as? T { return singleton }
        if let factory = factories[key], let instance = factory() as? T { return instance }
        fatalError("DIContainer: No registration found for \(type). Register it in AppDependencies.")
    }
}
