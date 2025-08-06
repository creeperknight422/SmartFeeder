//
//  ArduinoFeederAPIDemoApp.swift
//  ArduinoFeederAPIDemo
//
//  Created by Keegan Grundmeier on 7/25/25.
//

import SwiftUI

@main
struct ArduinoFeederAPIDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                NetworkScanView()
            }
        }
    }
}
