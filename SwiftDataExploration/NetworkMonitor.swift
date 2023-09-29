//
//  NetworkMonitor.swift
//  SwiftDataExploration
//
//  Created by Andrew Althage on 9/29/23.
//

import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    private var monitor: NWPathMonitor
    private var queue: DispatchQueue

    @Published var isConnected: Bool = true

    init() {
        monitor = NWPathMonitor()
        queue = DispatchQueue(label: "NetworkMonitor")

        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                DispatchQueue.main.async {
                    self?.isConnected = true
                }
            } else {
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }

        monitor.start(queue: queue)
    }
}
