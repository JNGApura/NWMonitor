//
//  ViewController.swift
//  NWMonitor
//
//  Created by João Nuno Gaspar Apura on 18/06/2019.
//  Copyright © 2019 João Apura. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var connection: UILabel!
    
    let monitor = ConnectionManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        monitor.addObserver(observer: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        monitor.removeObserver(observer: self)
    }
}

extension ViewController: ConnectionCheckObserver {
    
    func statusDidChange(status: ConnectivityStatus) {
        connection.text = (status == .connected) ? "Connected" : "Disconnected"
    }
}

