import SwiftUI
import Foundation

struct DetectedDevice: Identifiable, Codable {
    var id: UUID
    var FeedStatus: String
    var FeededWeight: Double
    var name: String
    var animalWeight: Double
    var animalName: String
    var animalDailyGain: Double
    var AnimalGender: String
    var AnimalSpecies: String
    var WifiStrength: Double
    var setTime: String
    var APIUsername: String
}

class DevicesStore: ObservableObject {
    @Published var devices: [DetectedDevice] = []
    
    
    func removeDevice(_ device: DetectedDevice) {
        devices.removeAll { $0.id == device.id }
    }
}

extension DetectedDevice {
    static let gigaDevice = DetectedDevice(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, // fixed UUID
        FeedStatus: "Off",
        FeededWeight: 0.0,
        name: "giga",
        animalWeight: 300.0,
        animalName: "Bull",
        animalDailyGain: 1.5,
        AnimalGender: "Male",
        AnimalSpecies: "Cattle",
        WifiStrength: -77,
        setTime: "9:30",
        APIUsername: "giga"
    )
    
    static let esp32Device = DetectedDevice(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, // fixed UUID
        FeedStatus: "Off",
        FeededWeight: 0.0,
        name: "ESP32",
        animalWeight: 250.0,
        animalName: "Bessie",
        animalDailyGain: 2.5,
        AnimalGender: "Female",
        AnimalSpecies: "Cattle",
        WifiStrength: -77,
        setTime: "9:30",
        APIUsername: "ESP32"
    )
}

struct NetworkScanView: View {
    @StateObject private var store = DevicesStore()
    @State private var isScanning = false
    @State private var pollingTimers: [UUID: Timer] = [:]
    @State private var wifiStrengths: [UUID: String] = [:]
    @State private var notificationPermissionGranted = false
    @State private var feedingStates: [UUID: Bool] = [:]
    @AppStorage("DarkModeEnabled") private var isEnabled = false
    

    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
    
    var body: some View {
            VStack {
                List(store.devices) { device in
                    NavigationLink(destination: ArduinoControllerView(device: device, store: store)) {
                        NetworkScanControlRow(
                            title: device.name,
                            data: wifiStrengths[device.id] ?? "Unknown",
                            subtitle: device.animalName
                        )
                    }
                    .listRowBackground(Color(.secondarySystemBackground))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
                .scrollContentBackground(.hidden)
                
                Divider()
                
                Toggle(isOn: $isEnabled) {
                    Text(isEnabled ? "Disable Dark Mode" : "Enable Dark Mode")
                        .font(.headline)
                }
                .padding()
            }
            .navigationTitle("Feeders")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        scanForArduino()
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Find New Feeders")
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isScanning) {
                //    ScanningView()
            }
            .onAppear {
                let defaultDevices = [DetectedDevice.gigaDevice, DetectedDevice.esp32Device]

                for device in defaultDevices {
                    if !store.devices.contains(where: { $0.id == device.id }) {
                        store.devices.append(device)
                    }
                }


                
                for device in store.devices {
                    startPolling(for: device)
                }
            }
            .onDisappear {
                stopAllPollingTimers()
            }
            
            .preferredColorScheme(isEnabled ? .dark : .light)
        }
    
    func scanForArduino() {
    }
    
    func stopAllPollingTimers() {
        for (_, timer) in pollingTimers {
            timer.invalidate()
        }
        pollingTimers.removeAll()
    }

    
    func startPolling(for device: DetectedDevice) {
        guard pollingTimers[device.id] == nil else { return } // Don't duplicate timers

        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            getData(for: device)
        }
        pollingTimers[device.id] = timer
    }

    
    func getData(for device: DetectedDevice) {
        guard let url = URL(string: "http://208.126.17.44:8000/getData?key=Kg142791!&deviceName=\(device.name)") else { return }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {

                    wifiStrengths[device.id] = "Disconnected"
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let FeedStatus = json["FeedStatus"] as? String,
                      let animalWeightStr = json["AnimalWeight"] as? String,
                      let animalName = json["animalName"] as? String,
                      let animalDailyGainStr = json["animalDailyGain"] as? String,
                      let animalGender = json["animalGender"] as? String,
                      let animalSpecies = json["animalSpecies"] as? String,
                      let sw = json["WifiStrength"] as? String else {
                    wifiStrengths[device.id] = "Unknown"
                    return
                }

                if let index = store.devices.firstIndex(where: { $0.id == device.id }) {
                    var updatedDevice = store.devices[index]
                    updatedDevice.animalWeight = Double(animalWeightStr) ?? updatedDevice.animalWeight
                    updatedDevice.animalName = animalName
                    updatedDevice.animalDailyGain = Double(animalDailyGainStr) ?? updatedDevice.animalDailyGain
                    updatedDevice.WifiStrength = Double(sw) ?? updatedDevice.WifiStrength
                    updatedDevice.AnimalGender = animalGender
                    updatedDevice.AnimalSpecies = animalSpecies
                    store.devices[index] = updatedDevice
                }


                if FeedStatus != "Disconnected"{
                    if let swInt = Int(sw) {
                        if swInt >= -50 {
                            wifiStrengths[device.id] = "Signal Strength: Excellent"
                        } else if swInt > -70 {
                            wifiStrengths[device.id] = "Signal Strength: Fair"
                        } else {
                            wifiStrengths[device.id] = "Signal Strength: Poor"
                        }
                    } else {
                        wifiStrengths[device.id] = "Signal Strength: Unknown"
                        print(sw)
                    }
                }
                else{
                    wifiStrengths[device.id] = "Disconnected"
                }
            }
        }.resume()
    }

}


struct NetworkScanControlRow: View {
    let title: String
    let data: String
    var subtitle: String? = nil
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Text(data)
                .font(.headline)
                .foregroundColor(
                    (data.lowercased().contains("unknown") || data.lowercased().contains("disconnected"))
                    ? .red
                    : .primary
                )
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
