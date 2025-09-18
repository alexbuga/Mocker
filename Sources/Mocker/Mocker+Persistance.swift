//
//  File.swift
//  Mocker
//
//  Created by Alex Buga on 17.09.2025.
//

import Foundation

extension Mocker {
    enum MockerPersistanceError: Error {
        case pathNotFound
        case corruptData
        case serializationError(String)
        case dataWriteError(String)
    }
    
    static public let mockerLaunchArgument = "--use-mocker"
    
    static private let mocksFilename = "mocks.json"
    
    static public func loadMocksFromSharedFolder() throws -> [Mock] {
        guard let path = ProcessInfo().environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] else {
            throw MockerPersistanceError.pathNotFound
        }
        
        let url = URL(fileURLWithPath: path).appendingPathComponent(Self.mocksFilename)
        
        do {
            let data = try Data(contentsOf: url)
            let mocks = try JSONDecoder().decode([Mock].self, from: data)
            return mocks
        } catch {
            throw MockerPersistanceError.corruptData
        }
    }
    
    static public func saveMocksToSharedFolder(_ mocks: [Mock]) throws {
        guard let path = ProcessInfo().environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] else {
            throw MockerPersistanceError.pathNotFound
        }
        
        let url = URL(fileURLWithPath: path).appendingPathComponent(Self.mocksFilename)
        
        do {
            let data = try JSONEncoder().encode(mocks)
            try data.write(to: url)
        } catch(let error) {
            switch error {
            case is EncodingError:
                throw MockerPersistanceError.serializationError(error.localizedDescription)
            default:
                throw MockerPersistanceError.dataWriteError(error.localizedDescription)
            }
        }
    }
    
    static public func clearMocksCache() throws {
        guard let path = ProcessInfo().environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"] else {
            throw MockerPersistanceError.pathNotFound
        }
        
        let url = URL(fileURLWithPath: path).appendingPathComponent(Self.mocksFilename)
        
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw MockerPersistanceError.dataWriteError(error.localizedDescription)
        }
    }
    
    static public func loadAndRegisterMocksIfFlagIsEnabled() throws {
        
        guard Mocker.isMockerLaunchArgumentEnabled() else {
            return
        }
                
        let mocks = try Mocker.loadMocksFromSharedFolder()
        Mocker.mode = .optin
        Mocker.removeAll()
        mocks.forEach { $0.register() }
    }
    
    static public func isMockerLaunchArgumentEnabled() -> Bool {
        let args = CommandLine.arguments
        guard let _ = args.first(where: { $0.contains(Self.mockerLaunchArgument) }) else {
            return false
        }
        return true
    }
}

public extension URLSessionConfiguration {
    func addMockingSupportIfFlagIsEnabled() {
        guard Mocker.isMockerLaunchArgumentEnabled() else {
            return
        }
        self.protocolClasses?.insert(MockingURLProtocol.self, at: 0)
    }
}
