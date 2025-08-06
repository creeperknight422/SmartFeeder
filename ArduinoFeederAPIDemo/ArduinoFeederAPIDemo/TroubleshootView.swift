import SwiftUI

struct TroubleshootView: View {
    @AppStorage("DarkModeEnabled") private var isEnabled = false
    @State private var statusMessage: String = ""
    @State private var connectionStatus: String = ""
    let device: DetectedDevice
    @ObservedObject var store: DevicesStore

    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }()

    var body: some View {
        Form {
            Section {
                Button(action: {
                    getData()
                })
                {
                    DeviceDataControlRow2(title: "Troubleshoot")
                        .foregroundColor(.primary)
                }
            }
            
            .listRowBackground(Color(.secondarySystemBackground))
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))

            if !statusMessage.isEmpty {
                DeviceDataControlRow2(title: statusMessage)
                    .foregroundColor(connectionStatus == "Disconnected" ? .red : .green)
                    .listRowBackground(Color(.secondarySystemBackground))
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            }
        }
        .navigationTitle("Troubleshooting")
        .preferredColorScheme(isEnabled ? .dark : .light)
        .scrollContentBackground(.hidden)
    }

    func getData() {
        guard let encodedDeviceName = device.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "http://208.126.17.44:8000/getData?key=Kg142791!&deviceName=\(encodedDeviceName)") else {
            statusMessage = "Invalid URL"
            connectionStatus = "Disconnected"
            return
        }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    switch error.code {
                    case NSURLErrorTimedOut:
                        statusMessage = "Request timed out. Please reset feeder or phone."
                        connectionStatus = "Disconnected"
                    case NSURLErrorNotConnectedToInternet:
                        statusMessage = "No internet connection. Please check your phone's connection."
                        connectionStatus = "Disconnected"
                    case NSURLErrorNetworkConnectionLost:
                        statusMessage = "Feeder lost internet. Please reconnect."
                        connectionStatus = "Disconnected"
                    default:
                        statusMessage = "Send failed: \(error.localizedDescription)"
                        connectionStatus = "Disconnected"
                    }
                } else {
                    statusMessage = "Command sent successfully."
                    connectionStatus = "Connected"
                }
            }
        }.resume()
    }
}
