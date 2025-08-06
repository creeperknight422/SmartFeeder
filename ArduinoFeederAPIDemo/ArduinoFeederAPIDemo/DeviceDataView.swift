import SwiftUI

struct DeviceDataView: View {
    let device: DetectedDevice
    @ObservedObject var store: DevicesStore
    @Environment(\.presentationMode) var presentationMode
    @AppStorage("storage") private var storage: String = "-"
    @AppStorage("feededWeight") private var feededWeight: String = "-"
    @AppStorage("statusMessage") private var statusMessage: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @AppStorage("DarkModeEnabled") private var isEnabled = false
    @Binding var isActive: Bool
    @State private var editableName: String = ""
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }()

    var body: some View {
        Form {
            Section(header: Text("Device Info")) {
                HStack {
                    Text("Name")
                        .font(.headline)
                    Spacer()
                    TextField(device.name, text: $editableName, onCommit: {
                        updateDeviceName(editableName)
                        setName(editableName)
                    })
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                    .submitLabel(.done)
                }

                DeviceDataControlRow(title: "Storage", data: storage)
                DeviceDataControlRow(title: "API Username", data: "Giga")
            }
            .listRowBackground(Color(.secondarySystemBackground))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            
            Section {
                NavigationLink(destination: TroubleshootView(device:device,store:store)) {
                    DeviceDataControlRow2(title: "Troubleshoot Screen")
                }
                
                Button(action: {
                 //   sendCommand("/TareScale")
                }) {
                    Text("Tare Scale")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                
                Button(action: {
                    if let device = store.devices.first(where: { $0.name == "ESP32" }) {
                        store.removeDevice(device)
                        isActive = false
                    }}) {
                    DeviceDataControlRow2(title: "Forget/Disconnect")
                        .foregroundColor(.red)
                }
                .alert(isPresented: $showAlert) {
                    Alert(title: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .buttonStyle(.borderless)
            }
            .listRowBackground(Color(.secondarySystemBackground))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .navigationTitle("Feeder Data")
        .preferredColorScheme(isEnabled ? .dark : .light)
        .scrollContentBackground(.hidden)
    }


    func updateDeviceName(_ newName: String) {
        if let index = store.devices.firstIndex(where: { $0.id == device.id }) {
            var updatedDevice = store.devices[index]
            updatedDevice.name = newName
            store.devices[index] = updatedDevice
        }
    }
    
    func setName(_ value: String) {

    }
    
}

struct DeviceDataControlRow: View {
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
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

struct DeviceDataControlRow2: View {
    let title: String
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
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
