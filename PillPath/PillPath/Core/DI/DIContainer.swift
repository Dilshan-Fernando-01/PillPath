//
//  DIContainer.swift
//  PillPath
//
//  Lightweight dependency injection container.
//  Register services once at app startup; resolve them anywhere.
//

import Foundation

/// Central DI container. Register all services in AppDependencies.swift.
final class DIContainer {

    static let shared = DIContainer()
    private init() {}

    private var factories: [ObjectIdentifier: () -> Any] = [:]
    private var singletons: [ObjectIdentifier: Any] = [:]

    // MARK: - Registration

    /// Register a transient factory (new instance every resolve).
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        factories[ObjectIdentifier(type)] = factory
    }

    /// Register a singleton (same instance every resolve).
    func registerSingleton<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = ObjectIdentifier(type)
        singletons[key] = factory()
    }

    // MARK: - Resolution

    func resolve<T>(_ type: T.Type) -> T {
        let key = ObjectIdentifier(type)
        if let singleton = singletons[key] as? T { return singleton }
        if let factory = factories[key], let instance = factory() as? T { return instance }
        fatalError("DIContainer: No registration found for \(type). Register it in AppDependencies.")
    }
}
