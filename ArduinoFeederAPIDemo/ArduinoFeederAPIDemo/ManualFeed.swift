import SwiftUI

struct ManualFeed: View {
    @State private var amountToFeed: Double = 2.5
    @State private var isFeeding: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""
    let device: DetectedDevice
    @ObservedObject var store: DevicesStore
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()
    
    @State private var feededWeightTimer: Timer? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Select Amount\nto feed:")
                .font(.title)
                .multilineTextAlignment(.center)
            
            VStack {
                if !isFeeding {
                    Slider(value: $amountToFeed, in: 0...15, step: 0.1)
                        .padding()
                    Text(String(format: "%.1f lbs", amountToFeed))
                        .font(.largeTitle)
                        .bold()
                } else {
                    Text("\(device.FeededWeight) lbs")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                }
            }
            
            Button(action: {
                if isFeeding {
                    TurnOffFeeder()
                    isFeeding = false
                    print("Stopped feeding manually")
                } else {
                    TurnOnFeeder()
                    isFeeding = true
                    print("Feeding \(amountToFeed) lbs")
                }
            }) {
                Text(isFeeding ? "Stop" : "Feed")
                    .font(.title2)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isFeeding ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            
            Text(isFeeding
                 ? "Target: \(String(format: "%.1f", amountToFeed)) lbs"
                 : "Amount Already Fed: \(device.FeededWeight) lbs")
            .font(.subheadline)
            .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .navigationTitle("Feed Control")
        .onAppear {
            startFeededWeightTimer()
        }
        .onDisappear {
            feededWeightTimer?.invalidate()
            feededWeightTimer = nil
        }
        .onChange(of: device.FeededWeight) { newValue in
            if isFeeding,
               newValue >= amountToFeed - 0.01 {
                TurnOffFeeder()
                isFeeding = false
                print("Auto-stopped feeding at \(newValue) lbs (target: \(amountToFeed) lbs)")
            }
        }

        .alert("Feeding Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func startFeededWeightTimer() {
        feededWeightTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            getData()
        }
    }
    
    func TurnOffFeeder(){
        guard let url = URL(string: "http://208.126.17.44:8000/setAllData?key=Kg142791!&deviceName=\(device.APIUsername)&FeedStatus=Off&FeededWeight=\(device.FeededWeight)&AnimalWeight=\(device.animalWeight)&setTime=\(device.setTime)&name=\(device.name)1&animalName=\(device.animalName)&animalDailyGain=\(device.animalName)&animalGender=\(device.AnimalGender)&animalSpecies=\(device.AnimalSpecies)&WifiStrength=\(device.WifiStrength)") else {
            return
        }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
            }
        }.resume()
    }
    
    func TurnOnFeeder(){
        guard let url = URL(string: "http://208.126.17.44:8000/setAllData?key=Kg142791!&deviceName=\(device.APIUsername)&FeedStatus=On&FeededWeight=\(device.FeededWeight)&AnimalWeight=\(device.animalWeight)&setTime=\(device.setTime)&name=\(device.name)1&animalName=\(device.animalName)&animalDailyGain=\(device.animalName)&animalGender=\(device.AnimalGender)&animalSpecies=\(device.AnimalSpecies)&WifiStrength=\(device.WifiStrength)") else {
            return
        }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
            }
        }.resume()
    }
    
    func getData() {
        guard let url = URL(string: "http://208.126.17.44:8000/getData?key=Kg142791!&deviceName=\(device.name)") else {
            return
        }
        
        
        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    if error.code == NSURLErrorTimedOut {
                    } else {
                    }
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let feededWeight = json["FeededWeight"] as? String,
                      let WifiStrength = json["WifiStrength"] as? String else {
                    return
                }
                
                if let index = store.devices.firstIndex(where: { $0.id == device.id }) {
                    var updatedDevice = store.devices[index]
                    updatedDevice.FeededWeight = Double(feededWeight) ?? updatedDevice.FeededWeight
                    store.devices[index] = updatedDevice
                }
            }
        }.resume()
    }
    
    
    func handleError(_ message: String) {
        /*        statusMessage = message
         errorMessage = message
         
         showErrorAlert = false
         DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
         showErrorAlert = true
         }*/
    }
}
