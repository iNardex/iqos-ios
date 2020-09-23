//
//  ViewController.swift
//  iquos
//
//  Created by William Nardo on 21/09/2020.
//

import UIKit
import CoreBluetooth
import UserNotifications

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
    @IBOutlet weak var batterLabel: UILabel!
    @IBOutlet weak var holder: UILabel!
    @IBOutlet weak var logValue: UILabel!
    @IBOutlet weak var pairingLabel: UILabel!
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    let iquos  = CBUUID.init(string: "daebb240-b041-11e4-9e45-0002a5d5c51b")
    let batteria  = CBUUID.init(string: "f8a54120-b041-11e4-9be7-0002a5d5c51b")

    var oldMsg: IquosBatteryMsg?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            if granted {
                print("Yay!")
            } else {
                print("D'oh")
            }
        }
        
        batterLabel.alpha = 0
        holder.alpha = 0
        logValue.alpha = 0

        pairingLabel.blink()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
           
            centralManager.scanForPeripherals(withServices: [iquos],
                                              options: [CBCentralManagerScanOptionAllowDuplicatesKey : true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {

        // We've found it so stop scan
        self.centralManager.stopScan()

        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self

        // Connect!
        self.centralManager.connect(self.peripheral, options: nil)
        
        pairingLabel.text = "Connected! Reading value"

    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            print("Connected to your " + (peripheral.name ?? "Unknow"))
            peripheral.discoverServices([iquos])
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == iquos {
                    print("LED service found")
                    //Now kick off discovery of characteristics
                    peripheral.discoverCharacteristics([batteria], for: service)

                    return
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == batteria {
                    guard characteristic.value != nil else {return }
                    
                    peripheral.setNotifyValue(true, for: characteristic)
                    let msg = IquosBatteryMsg(data: characteristic.value!)

                    pairingLabel.removeFromSuperview()
                    batterLabel.alpha = 1
                    holder.alpha = 1
                    logValue.alpha = 1
                    
                    logValue.text = ""
                    characteristic.value!.forEach { (UInt8) in
                        self.logValue.text! += " \(UInt8)"
                    }
                    
                    UserDefaults.standard.set("Batteria: \(msg.batteryPercentage)%", forKey: "battery")
                    UserDefaults.standard.set("Holder: \(msg.holderStatus)", forKey: "holder")
                    
                    print("Batteria: \(msg.batteryPercentage)%")
                    batterLabel.text = "Batteria: \(msg.batteryPercentage)%"

                    print ("Holder: \(msg.holderStatus)")
                    holder.text = "Holder: \(msg.holderStatus)"

    
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        if characteristic.uuid == batteria {
            guard characteristic.value != nil else {return }

            let msg = IquosBatteryMsg(data: characteristic.value!)

            if(msg.holderStatus == .charged && oldMsg != nil && oldMsg?.holderStatus == .inRecharge){
                let center = UNUserNotificationCenter.current()
                let content = UNMutableNotificationContent()
                content.title = "Holder is charged"
                content.body = "Your holder is ready to be used"
                content.sound = UNNotificationSound.default

                let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
                center.add(request) { (error : Error?) in
                     if let theError = error {
                        print(theError)
                     }
                }
                
            }
            
            logValue.text = ""
            characteristic.value!.forEach { (UInt8) in
                self.logValue.text! += " \(UInt8)"
            }
            
            print("Batteria: \(msg.batteryPercentage)%")
            batterLabel.text = "Batteria: \(msg.batteryPercentage)%"

            print ("Holder: \(msg.holderStatus)")
            holder.text = "Holder: \(msg.holderStatus)"
            
            oldMsg = msg
        }
    }
    


}

