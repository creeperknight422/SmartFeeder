import SwiftUI

// MARK: - Done Button Toolbar Extension
extension View {
    func addDoneButtonOnKeyboard(action: @escaping () -> Void) -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    action()
                }
            }
        }
    }
}

// MARK: - EditableDeviceDataControlRow
struct EditableDeviceDataControlRow: View {
    let title: String
    @Binding var textValue: String
    var pickerOptions: [String]? = nil
    var keyboardType: UIKeyboardType = .decimalPad
    var showDoneButton: Bool = false  // Control whether to add Done toolbar

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            if let options = pickerOptions {
                Picker("", selection: $textValue) {
                    ForEach(options, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .foregroundColor(.primary)
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: 150)
            } else {
                let textField = TextField("", text: $textValue)
                    .multilineTextAlignment(.trailing)
                    .keyboardType(keyboardType)
                    .submitLabel(.done)
                    .frame(maxWidth: 150)

                if showDoneButton {
                    textField
                        .addDoneButtonOnKeyboard {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        }
                } else {
                    textField
                }
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}

// MARK: - AnimalData View
struct AnimalData: View {
    let device: DetectedDevice
    @ObservedObject var store: DevicesStore

    @State private var editableName: String
    @State private var editableGender: String
    @State private var editableSpecies: String
    @State private var localWeightText: String
    @State private var localDailyGainText: String

    let genderOptions = ["Male", "Female"]
    let typeOptions = ["Cow", "Pig", "Sheep", "Chicken", "Goat", "Other"]

    @AppStorage("DarkModeEnabled") private var isEnabled = false
    @AppStorage("statusMessage") private var statusMessage: String = ""
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        return URLSession(configuration: config)
    }()
    
    private let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 1
        return nf
    }()

    init(device: DetectedDevice, store: DevicesStore) {
        self.device = device
        self.store = store

        _editableName = State(initialValue: device.animalName)
        _editableGender = State(initialValue: device.AnimalGender)
        _editableSpecies = State(initialValue: device.AnimalSpecies)
        _localWeightText = State(initialValue: String(format: "%.1f", device.animalWeight))
        _localDailyGainText = State(initialValue: String(format: "%.1f", device.animalDailyGain))
    }

    var body: some View {
        Form {
            Section {
                EditableDeviceDataControlRow(
                    title: "Name",
                    textValue: $editableName,
                    keyboardType: .default
                )

                EditableDeviceDataControlRow(
                    title: "Weight",
                    textValue: $localWeightText,
                    showDoneButton: true     // Only this row gets Done button toolbar
                )

                EditableDeviceDataControlRow(
                    title: "Daily Gain",
                    textValue: $localDailyGainText
                )

                EditableDeviceDataControlRow(
                    title: "Gender",
                    textValue: $editableGender,
                    pickerOptions: genderOptions
                )

                EditableDeviceDataControlRow(
                    title: "Species",
                    textValue: $editableSpecies,
                    pickerOptions: typeOptions
                )
            }

            Section {
                Button("Save") {
                    saveAllChanges()
                }
                .font(.headline)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .navigationTitle("Animal Data")
        .preferredColorScheme(isEnabled ? .dark : .light)
    }

    private func saveAllChanges() {
        guard let weight = numberFormatter.number(from: localWeightText)?.doubleValue,
              let dailyGain = numberFormatter.number(from: localDailyGainText)?.doubleValue else {
            statusMessage = "Invalid number input"
            return
        }

        if let index = store.devices.firstIndex(where: { $0.id == device.id }) {
            store.devices[index].animalName = editableName
            store.devices[index].animalWeight = weight
            store.devices[index].animalDailyGain = dailyGain
            store.devices[index].AnimalGender = editableGender
            store.devices[index].AnimalSpecies = editableSpecies

            // Now send updated data immediately, passing from store
            let updatedDevice = store.devices[index]
            setData(with: updatedDevice)
        }
    }


    func setData(with updatedDevice: DetectedDevice){
        guard let url = URL(string: "http://208.126.17.44:8000/setAllData?key=Kg142791!&deviceName=\(updatedDevice.APIUsername)&FeedStatus=\(updatedDevice.FeedStatus)&FeededWeight=\(updatedDevice.FeededWeight)&AnimalWeight=\(updatedDevice.animalWeight)&setTime=\(updatedDevice.setTime)&name=\(updatedDevice.name)1&animalName=\(updatedDevice.animalName)&animalDailyGain=\(updatedDevice.animalDailyGain)&animalGender=\(updatedDevice.AnimalGender)&animalSpecies=\(updatedDevice.AnimalSpecies)&WifiStrength=\(updatedDevice.WifiStrength)") else {
            return
        }

        session.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                // Handle response or errors if needed
            }
        }.resume()
    }

}
