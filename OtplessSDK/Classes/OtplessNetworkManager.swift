//
//  OtplessNetworkManager.swift
//  OtplessSDK
//
//  Created by Digvijay Singh on 28/07/23.
//

import Foundation
import Network


internal enum NetworkType {
    case wifi, cellular
}

internal enum NetworkData {
    case disabled
    case enabled(type: NetworkType)
}

internal protocol OnNetworkChange {
    func onNetworkChange(data networkData: NetworkData)
    func isEqual(rhs: OnNetworkChange) -> Bool
}

extension OnNetworkChange {
    
    func isEqual(rhs: OnNetworkChange) -> Bool {
        guard let lns = self as? NSObject else {
            return false
        }
        guard let rns = rhs as? NSObject else {
            return false
        }
        return lns === rns
    }
}

internal class OtplessNetworkManager {
    
    private static var _sharedInstance: OtplessNetworkManager? = nil
    private static let lock = NSObject()
    static var sharedInstance: OtplessNetworkManager {
        if let si = _sharedInstance {
            return si
        }
        objc_sync_enter(lock)
        defer {
            objc_sync_exit(lock)
        }
        if _sharedInstance == nil {
            _sharedInstance = OtplessNetworkManager()
        }
        return _sharedInstance!
    }
    
    private(set) var networkData: NetworkData = .disabled
    
    private var _monitor: Any? = nil
    @available(iOS 12.0, *)
    private var monitor: NWPathMonitor {
        if _monitor == nil {
            _monitor = NWPathMonitor()
        }
        return _monitor as! NWPathMonitor
    }
    
    private var callbacks: [OnNetworkChange] = []
    
    private init() {
        if #available(iOS 12.0, *) {
            self.monitor.pathUpdateHandler = self.onNetworkChange
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 12.0, *)
    private func onNetworkChange(_ path: NWPath) {
        let networkData: NetworkData
        if path.status == .satisfied {
            if path.isExpensive {
                networkData = NetworkData.enabled(type: .cellular)
            } else {
                networkData = NetworkData.enabled(type: .wifi)
            }
        } else {
            networkData = NetworkData.disabled
        }
        self.networkData = networkData
        // send the callbacks on main thread
        DispatchQueue.main.async {
            for cb in self.callbacks {
                cb.onNetworkChange(data: networkData)
            }
        }
    }
    
    func addListener(callback: OnNetworkChange) {
        self.callbacks.append(callback)
    }
    
    func removeListener(callback: OnNetworkChange) {
        self.callbacks.removeAll(where: {item in
            return item.isEqual(rhs: callback)
        })
    }
}
