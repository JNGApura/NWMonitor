//
//  ConnectionManager.swift
//  NWMonitor
//
//  Created by João Nuno Gaspar Apura on 18/06/2019.
//  Copyright © 2019 João Apura. All rights reserved.
//

import Network

protocol ConnectionCheckObserver: class {
    func statusDidChange(status: ConnectivityStatus)
}

enum ConnectivityStatus {
    case connected
    case disconnected
    case requiresConnection
}

class ConnectionManager {
    
    struct ConnectionChangeObservation {
        weak var observer: ConnectionCheckObserver?
    }
    
    // Path monitor
    private var monitor = NWPathMonitor()
    
    // Shared instance
    static let shared = ConnectionManager()
    
    // Dictionary of delegates to observe for network connectivity change
    private var observations = [ObjectIdentifier: ConnectionChangeObservation]()
    
    // Whether we are listening for changes in connectivity
    fileprivate var isObservingConnectivity = false
    
    // Tracks connectivity status
    var connectivityStatus: ConnectivityStatus {
        get {
            return getConnectivityFrom(status: monitor.currentPath.status)
        }
    }
    
    init() {
        startMonitor()
    }

    // Starts monitoring connectivity changes
    func startMonitor() {
        
        if !isObservingConnectivity { // to prevent being called multiple times
            isObservingConnectivity = true
            
            monitor.pathUpdateHandler = { [unowned self] path in
                for (id, obs) in self.observations {
                    
                    guard let observer = obs.observer else {
                        self.observations.removeValue(forKey: id) // remove observer if nil
                        continue
                    }
                    
                    DispatchQueue.main.async(execute: {
                        observer.statusDidChange(status: self.getConnectivityFrom(status: path.status))
                    })
                }
            }
            
            monitor.start(queue: DispatchQueue.global(qos: .background))
        }
    }
    
    // Stops monitoring connectivity changes
    func stopMonitor() {
        
        if isObservingConnectivity {
            isObservingConnectivity = false
            
            observations.removeAll()
            monitor.cancel()
        }
    }
    
    // Adds a new observer to the observations dictionary
    func addObserver(observer: ConnectionCheckObserver) {
        
        let id = ObjectIdentifier(observer)
        observations[id] = ConnectionChangeObservation(observer: observer)
        
        observer.statusDidChange(status: self.connectivityStatus)
    }
    
    // Removes an observer from the observations dictionary
    func removeObserver(observer: ConnectionCheckObserver) {
        let id = ObjectIdentifier(observer)
        observations.removeValue(forKey: id)
    }
    
    // Converts NWPath.Status into ConnectivityStatus
    func getConnectivityFrom(status: NWPath.Status) -> ConnectivityStatus {
        
        switch status {
            case .satisfied: return .connected
            case .unsatisfied: return .disconnected
            case .requiresConnection: return .requiresConnection
            @unknown default: fatalError()
        }
    }
}
