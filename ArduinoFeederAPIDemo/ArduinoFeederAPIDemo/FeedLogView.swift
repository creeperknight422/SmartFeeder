import SwiftUI

struct FeedLogAPIResponse: Codable {
    let feedLog: [String]
}

struct FeedLogView: View {
    let device: DetectedDevice
    
    @State private var feedLog: [String] = []
    @State private var isLoading = true
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }()
    
    var body: some View {
        VStack(alignment: .leading) {
            if isLoading {
                ProgressView("Loading Feed Log...")
                    .padding()
            } else if feedLog.isEmpty {
                Text("No feed log entries.")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(feedLog, id: \.self) { line in
                    Text(line)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                }
                Divider()
            }
            Spacer()
            Button(action: {
                clearFeedLog()
            }) {
                DeviceDataControlRow2(title: "Clear Log")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Feed Log")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchFeedLog()
        }
    }
    
    func fetchFeedLog() {
        let encodedDeviceName = device.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? device.name
        let urlString = "http://208.126.17.44:8000/clearFeedLog?key=Kg142791!&deviceName=\(device.name)"
        
        guard let url = URL(string: urlString) else {
            isLoading = false
            print("Invalid URL.")
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                
                guard let data = data else {
                    print("No data received.")
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(FeedLogAPIResponse.self, from: data)
                    feedLog = Array(decoded.feedLog.suffix(200))
                    
                } catch {
                    print("Failed to decode feed log: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    func clearFeedLog(){
        guard let url = URL(string: "http://208.126.17.44:8000/clearFeededLog?key=Kg142791!&deviceName=\(device.name)") else {
                return
            }

            session.dataTask(with: url) { data, response, error in
                DispatchQueue.main.async {
                }
            }.resume()
        }
}
