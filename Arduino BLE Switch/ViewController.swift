//
//  ViewController.swift
//  Arduino BLE Switch
//
//  Created by Boyi Chen on 2/7/21.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    var manager: CBCentralManager? = nil
    var mainPeripheral: CBPeripheral? = nil
    var mainCharacteristic: CBCharacteristic? = nil
    
    let myBLEService = "FFE0"
    let myBLECharacteristic = "FFE1"
    
    enum Status {case ON, OFF}
    var currentStatus: Status = .OFF
    
    @IBOutlet weak var onButton: UIButton!
    @IBOutlet weak var offButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        manager = CBCentralManager(delegate: self, queue: nil);
        
        showBLEStatus()
        showOnOffStatus()

        // removes the navigation bar background
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if (segue.identifier == "scan-segue") {
            let scanController : ScanTableViewController = segue.destination as! ScanTableViewController

            //set the manager's delegate to the scan view so it can call relevant connection methods
            manager?.delegate = scanController
            scanController.manager = manager
            scanController.parentView = self
        }
    }
    
    // alert when onButton or offButton pressed when no device connected
    @IBAction func showAlertButtonTapped() {

        // create the alert
        let alert = UIAlertController(title: "Warning", message: "You are not connected to any device.", preferredStyle: UIAlertController.Style.alert)

        // add the actions (buttons)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))

        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onButtonPressed(_ sender: Any) {
        if (mainPeripheral == nil) {
            showAlertButtonTapped()
        } else {
            sendInstruction(instruction: "ON")
            currentStatus = .ON
            showOnOffStatus()
        }
    }
    
    @IBAction func offButtonPressed(_ sender: Any) {
        if (mainPeripheral == nil) {
            showAlertButtonTapped()
        } else {
            sendInstruction(instruction: "OFF")
            currentStatus = .OFF
            showOnOffStatus()
        }
    }
    
    @IBAction func disconnectButtonPressed(_ sender: Any) {
        if (mainPeripheral != nil) {
            manager?.cancelPeripheralConnection(mainPeripheral!)
        } 
    }
    
    // disable the button after the button is pressed, also generate color image to indicate
    func showOnOffStatus() {
        if (currentStatus == .OFF) {
            onButton.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
            offButton.backgroundColor = UIColor(red: 1.0, green: 38.0/255.0, blue: 0.0, alpha: 0.8)
            onButton.setTitle("ON", for: .normal)
            onButton.isEnabled = true
            offButton.setTitle("", for: .normal)
            offButton.isEnabled = false
        } else {
            onButton.backgroundColor = UIColor(red: 1.0, green: 251.0/255.0, blue: 0.0, alpha: 0.8)
            offButton.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
            onButton.setTitle("", for: .normal)
            onButton.isEnabled = false
            offButton.setTitle("OFF", for: .normal)
            offButton.isEnabled = true
        }
    }
    
    func showBLEStatus() {
        if (mainPeripheral != nil) {
            statusLabel.text = "Connected!"
        } else {
            statusLabel.text = "Disconnected!"
        }
    }
    
    func sendInstruction(instruction: String) {
        let data = instruction.data(using: String.Encoding.utf8)!
//        let data = withUnsafeBytes(of: instruction) {Data($0)}
        if (mainPeripheral != nil) {
            mainPeripheral?.writeValue(data, for: mainCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
            print("Instruction: \(instruction) is sent.")
        } else {
            print("No device is connected.")
        }
    }
    
    // react to the Arduino state sent from Arduino by BLE device
    func updateState(arduinoState: String) {
        if (arduinoState == "ON") {
            currentStatus = .ON
            showOnOffStatus()
        } else if (arduinoState == "OFF") {
            currentStatus = .OFF
            showOnOffStatus()
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods

    // called when peripheral is requested to be disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        mainPeripheral = nil
        showBLEStatus()
        showOnOffStatus()
        print("Disconnected from " + peripheral.name!)
    }

    // required but no use here
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print(central.state)
    }

    // MARK: CBPeripheralDelegate Methods
    // looping through peripheral services array
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {

        for service in peripheral.services! {

            print("Service found with UUID: " + service.uuid.uuidString)

            //device information service
            if (service.uuid.uuidString == "180A") {
                peripheral.discoverCharacteristics(nil, for: service)
            }

            //GAP (Generic Access Profile) for Device Name
            if (service.uuid.uuidString == "1800") {
                peripheral.discoverCharacteristics(nil, for: service)
            }

            // my BLE device service
            if (service.uuid.uuidString == myBLEService) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }


    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {

        //get device name
        if (service.uuid.uuidString == "1800") {
            for characteristic in service.characteristics! {
                if (characteristic.uuid.uuidString == "2A00") {
                    peripheral.readValue(for: characteristic)
                    print("Found Device Name Characteristic")
                }
            }
        }

        if (service.uuid.uuidString == "180A") {
            for characteristic in service.characteristics! {
                if (characteristic.uuid.uuidString == "2A29") {
                    peripheral.readValue(for: characteristic)
                    print("Found a Device Manufacturer Name Characteristic")
                } else if (characteristic.uuid.uuidString == "2A23") {
                    peripheral.readValue(for: characteristic)
                    print("Found System ID")
                }
            }
        }

        if (service.uuid.uuidString == myBLEService) {
            for characteristic in service.characteristics! {
                print(characteristic.uuid.uuidString)
                if (characteristic.uuid.uuidString == myBLECharacteristic) {
                    //we'll save the reference, we need it to write data
                    mainCharacteristic = characteristic

                    //Set Notify is useful to read incoming data async
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Found Characteristic")
                    if(characteristic.value != nil) {
                        let state = String(data: characteristic.value!, encoding: String.Encoding.utf8)!
                            print(state)
                            // react to the current Arduino state
                            updateState(arduinoState: state)
                    }
                }
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        if (characteristic.uuid.uuidString == "2A00") {
            //value for device name recieved
            let deviceName = characteristic.value
            print(deviceName ?? "No Device Name")
        } else if (characteristic.uuid.uuidString == "2A29") {
            //value for manufacturer name recieved
            let manufacturerName = characteristic.value
            print(manufacturerName ?? "No Manufacturer Name")
        } else if (characteristic.uuid.uuidString == "2A23") {
            //value for system ID recieved
            let systemID = characteristic.value
            print(systemID ?? "No System ID")
        } else if (characteristic.uuid.uuidString == myBLECharacteristic) {
            //data recieved
            if(characteristic.value != nil) {
                let state = String(data: characteristic.value!, encoding: String.Encoding.utf8)!
                    print(state)
                    // react to the current Arduino state
                    updateState(arduinoState: state)
            }
        }
    }
}

