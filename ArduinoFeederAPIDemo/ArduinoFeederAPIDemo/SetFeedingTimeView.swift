import SwiftUI

struct SetFeedingTime: View {
    @State private var feedingTime: Date = Date()
    @AppStorage("savedFeedingTime") private var savedTime: Double = 0
    let device: DetectedDevice
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }()
    var body: some View {
        VStack(spacing: 30) {
            Text("Set Feeding Time")
                .font(.largeTitle)
                .bold()
            
            DatePicker("Select Time", selection: $feedingTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .frame(height: 150)
            
            Text("Selected Time: \(formattedTime(feedingTime))")
                .font(.headline)
            
            Button(action: {
                savedTime = feedingTime.timeIntervalSince1970
                setTargetTime(targetTimeFormatted(from: savedTime))
            }) {
                Text("Save Time")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            if savedTime != 0 {
                feedingTime = Date(timeIntervalSince1970: savedTime)
            }
        }
    }
    
    func setTargetTime(_ value: String) {
        sendCommand(value: value)
    print("set!")
    }
    
    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func targetTimeFormatted(from timeInterval: Double) -> String {
        let date = Date(timeIntervalSince1970: timeInterval)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    func sendCommand(value: String) {
        guard let url = URL(string: "http://208.126.17.44:8000/setAllData?key=Kg142791!&deviceName=\(device.APIUsername)&FeedStatus=\(device.FeedStatus)&FeededWeight=\(device.FeededWeight)&AnimalWeight=\(device.animalWeight)&setTime=\(value)&name=\(device.name)1&animalName=\(device.animalName)&animalDailyGain=\(device.animalName)&animalGender=\(device.AnimalGender)&animalSpecies=\(device.AnimalSpecies)&WifiStrength=\(device.WifiStrength)") else {
            return
        }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
            }
        }.resume()
    }
}
