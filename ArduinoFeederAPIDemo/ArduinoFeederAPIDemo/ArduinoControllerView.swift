import SwiftUI
import PhotosUI

struct ArduinoControllerView: View {
    let device: DetectedDevice
    @AppStorage("savedFeedingTime") private var savedTime: Double = 0
    @AppStorage("feededWeight") private var feededWeight: String = "-"
    @AppStorage("statusMessage") private var statusMessage: String = ""
    @AppStorage("WifiStrength") private var WifiStrength = ""
    @State private var feededWeightTimer: Timer? = nil
    @State private var deviceImage: Image? = nil
    @ObservedObject var store: DevicesStore
    @State private var showingImagePicker = false
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    @State private var isManualFeedActive = false
    @State private var isDeviceDataActive = false
    @State private var isAnimalDataActive = false
    @State private var isFeedLogActive = false

    private var imageKey: String {
        "deviceImage_" + device.name
    }
    @State private var hasEverConnected = false
    @State private var connectionStatus = ""

    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }()

    var wifiSignalColor: Color {
        switch WifiStrength {
        case let str where str.contains("Excellent"):
            return .green
        case let str where str.contains("Fair"):
            return .orange
        case let str where str.contains("Poor"):
            return .red
        default:
            return .gray
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    if let image = deviceImage {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 220)
                            .cornerRadius(20)
                            .overlay(
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .padding(8)
                                .onTapGesture {
                                    showingImagePicker = true
                                },
                                alignment: .bottomTrailing
                            )
                    } else {
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 220)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(20)
                            .overlay(
                                ZStack {
                                    Circle()
                                        .fill(Color.black.opacity(0.5))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "pencil")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .bold))
                                }
                                .padding(8)
                                .onTapGesture {
                                    showingImagePicker = true
                                },
                                alignment: .bottomTrailing
                            )
                    }
                }
                .photosPicker(isPresented: $showingImagePicker, selection: $selectedItem, matching: .images)
                .onChange(of: selectedItem) { newItem in
                    guard let newItem = newItem else { return }
                    Task {
                        do {
                            if let data = try await newItem.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                                deviceImage = Image(uiImage: uiImage)
                                saveImage(uiImage)
                            }
                        } catch {
                            print("Failed to load image: \(error.localizedDescription)")
                        }
                    }
                }

                Text(device.name)
                    .font(.title2)
                    .fontWeight(.bold)
                VStack(spacing: 8) {
                    HStack {
                        Label("Status", systemImage: "wifi")
                            .font(.headline)
                        Spacer()
                        Text(connectionStatus)
                            .foregroundColor(connectionStatus == "Connected" ? .green : .red)
                            .fontWeight(.semibold)
                    }
                    if connectionStatus == "Connected" {
                        HStack {
                            Label("Wi-Fi Signal", systemImage: "wifi.exclamationmark")
                                .font(.headline)
                            Spacer()
                            Text(WifiStrength)
                                .foregroundColor(wifiSignalColor)
                                .fontWeight(.semibold)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(15)
                .padding(.horizontal)

                VStack(spacing: 16) {
                    NavigationLink(destination: SetFeedingTime(device:device)) {
                        ControlRow(iconName: "clock", title: "Scheduled Feeding Time", subtitle: formattedTime(from: savedTime))
                            .foregroundColor(.black)
                    }

                    NavigationLink(destination: ManualFeed(device: device, store: store)) {
                        ControlRow(iconName: "bolt.fill", title: "Manual Feed")
                            .foregroundColor(.black)
                    }

                    NavigationLink(
                        destination: DeviceDataView(device: device, store: store, isActive: $isDeviceDataActive),
                        isActive: $isDeviceDataActive
                    ) {
                        ControlRow(iconName: "cpu", title: "Feeder Data")
                    }


                    NavigationLink(destination: AnimalData(device: device, store: store)) {
                        ControlRow(iconName: "pawprint.fill", title: "Animal Data")
                            .foregroundColor(.black)
                    }

                    NavigationLink(destination: FeedLogView(device: device)) {
                        ControlRow(iconName: "list.bullet.rectangle", title: "Feed Log")
                            .foregroundColor(.black)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Controller")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadImage()
            startFeededWeightTimer()
        }
        .onDisappear {
            feededWeightTimer?.invalidate()
            feededWeightTimer = nil
        }
    }


    func startFeededWeightTimer() {
        feededWeightTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { _ in
            getData(for: device)
        }
    }

    func loadImage() {
        if let data = UserDefaults.standard.data(forKey: imageKey),
           let uiImage = UIImage(data: data) {
            deviceImage = Image(uiImage: uiImage)
        }
    }

    func saveImage(_ uiImage: UIImage) {
        if let data = uiImage.jpegData(compressionQuality: 0.8) {
            UserDefaults.standard.set(data, forKey: imageKey)
        }
    }

    func formattedTime(from timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func getData(for device: DetectedDevice) {
        guard let url = URL(string: "http://208.126.17.44:8000/getData?key=Kg142791!&deviceName=\(device.name)") else { return }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    return
                }
                print("FeedStatus")
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let FeedStatus = json["FeedStatus"] as? String,
                        let animalWeightStr = json["AnimalWeight"] as? String,
                      let animalName = json["animalName"] as? String,
                      let animalDailyGainStr = json["animalDailyGain"] as? String,
                      let animalGender = json["animalGender"] as? String,
                      let animalSpecies = json["animalSpecies"] as? String,
                      let sw = json["WifiStrength"] as? String else {
                    return
                }
                if FeedStatus != "Disconnected"{
                    connectionStatus = "Connected"
                }
                else{
                    connectionStatus = "Disconnected"
                }
                

                
                if let swInt = Int(sw) {
                    if swInt >= -50 {
                        WifiStrength = "Excellent"
                    } else if swInt > -70 {
                        WifiStrength = "Fair"
                    } else {
                        WifiStrength = "Poor"
                    }
                } else {
                    WifiStrength = "Unknown"
                print(sw)
                }
                

                if let index = store.devices.firstIndex(where: { $0.id == device.id }) {
                    var updatedDevice = store.devices[index]
                    updatedDevice.animalWeight = Double(animalWeightStr) ?? updatedDevice.animalWeight
                    updatedDevice.animalName = animalName
                    updatedDevice.animalDailyGain = Double(animalDailyGainStr) ?? updatedDevice.animalDailyGain
                    updatedDevice.AnimalGender = animalGender
                    updatedDevice.AnimalSpecies = animalSpecies
                    store.devices[index] = updatedDevice
                    print(store.devices[index])
                }
            }
        }.resume()
    }

    func signalDescription(for rawSignal: String) -> String {
        guard let swInt = Int(rawSignal) else { return "Unknown" }
        if swInt >= -50 { return "Excellent" }
        else if swInt < -50 && swInt > -70 { return "Fair" }
        else { return "Poor" }
    }
}

struct ControlRow: View {
    let iconName: String
    let title: String
    var subtitle: String? = nil

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(.primary)
                .frame(width: 30)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
