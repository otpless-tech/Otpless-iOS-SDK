//
//  OtplessSimStateAnalyzer.swift
//  OtplessSDK
//
//  Created by Sparsh on 20/08/24.
//

import Foundation
import CoreTelephony
import Network

@available(iOS 12, *)
internal class OtplessSimStateAnalyzer {
    static let shared = OtplessSimStateAnalyzer()
    private let majorOsVersion = ProcessInfo().operatingSystemVersion.majorVersion
    private let networkInfo = CTTelephonyNetworkInfo()
    private var analysisJson: [String: Any] = [:]
    private var isMobileNetworkEnabled: String = ""
    private var networkMonitor: NWPathMonitor?
    
    /// Depicts whether a sim card is inserted in the device and performs network analysis.
    ///
    /// For iOS version < 16, we can use CTCarrier to fetch carrier details. If carrier details are nil, it implies no sim card is present
    /// For iOS version >= 16 and iOS version < 18, we cannot concretely determine whether sim card is available or not because of deprecations by Apple.
    /// For iOS version >= 18, we can use isSIMInserted of CTSubscriber
    func performAnalysis() {
        monitorCurrentNetworkType()
        monitorMobileNetwork()
        
        switch majorOsVersion {
        case ..<16:
            below16Handler()
            break
        case 16..<18:
            between16And18Handler()
            break
        case 18...:
            print("To be implemented for iOS 18 and above after iOS 18 is released.")
            break
        default:
            print("Unknown iOS version")
        }
    }
    
    
    /// Fetches sim card carrier details for iOS version < 16
    private func below16Handler() {
        var isSimInserted = false
        var carriersArr: [[String: Any]] = []

        if let carriers = networkInfo.serviceSubscriberCellularProviders {
            for (_, carrier) in carriers {
                var currentCarrierDetails: [String: Any] = [:]
                
                if let carrierName = carrier.carrierName {
                    currentCarrierDetails["carrierName"] = carrierName
                }

                if let mobileCountryCode = carrier.mobileCountryCode {
                    currentCarrierDetails["mobileCountryCode"] = mobileCountryCode
                }

                if let mobileNetworkCode = carrier.mobileNetworkCode {
                    currentCarrierDetails["mobileNetworkCode"] = mobileNetworkCode
                }

                if let isoCountryCode = carrier.isoCountryCode {
                    currentCarrierDetails["isoCountryCode"] = isoCountryCode
                }

                if !currentCarrierDetails.isEmpty {
                    isSimInserted = true
                    carriersArr.append(currentCarrierDetails)
                }
            }
        } else {
            print("No carriers found")
        }

        analysisJson["isSimInserted"] = isSimInserted.description
        analysisJson["carriers"] = carriersArr
    }
    
    
    /// Handles scenarios for iOS versions between 16 and 18 (exclusive).
    private func between16And18Handler() {
        // Intentionally left blank because we cannot concretely determine whether sim card is inserted or not.
    }

    /// Monitor the mobile network
    private func monitorMobileNetwork() {
        if let monitor = networkMonitor { monitor.cancel() }
        
        networkMonitor = NWPathMonitor(requiredInterfaceType: .cellular)
        
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    self.isMobileNetworkEnabled = true.description
                    self.analysisJson["isMobileNetworkEnabled"] = true.description
                } else {
                    self.isMobileNetworkEnabled = false.description
                    self.analysisJson["isMobileNetworkEnabled"] = false.description
                }

                if self.majorOsVersion >= 16 && self.majorOsVersion < 18 {
                    self.analysisJson["isSimInserted"] = (path.status == .satisfied).description
                }
                
                OtplessLogger.log(string: "Mobile network status: \(path.status == .satisfied)", type: "Mobile data states")
            }
        }
        
        networkMonitor?.start(queue: .main)
    }
    
    /// Monitor the current network type (Wi-Fi, Cellular, etc.)
    private func monitorCurrentNetworkType() {
        if let monitor = networkMonitor { monitor.cancel() }
        
        networkMonitor = NWPathMonitor()
        
        networkMonitor?.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            var networkType = "Unknown"
            
            if path.usesInterfaceType(.wifi) {
                networkType = "WiFi"
            } else if path.usesInterfaceType(.cellular) {
                networkType = "Mobile Data"
            } else if path.usesInterfaceType(.wiredEthernet) {
                networkType = "Ethernet"
            } else if path.usesInterfaceType(.loopback) {
                networkType = "Loopback"
            } else if path.usesInterfaceType(.other) {
                networkType = "Other"
            }

            self.analysisJson["currentTransportType"] = networkType
            OtplessLogger.log(string: "Current network type: \(networkType)", type: "Network status")
        }
        
        networkMonitor?.start(queue: .main)
    }
    
    func getAnalysisJson() -> [String: Any] {
        return analysisJson
    }
}
