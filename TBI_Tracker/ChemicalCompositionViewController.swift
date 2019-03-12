//
//  ChemicalCompositionViewController.swift
//  TBI_Tracker
//
//  Created by Aishwarya Pattar on 03/02/2019.
//  Copyright © 2019 Aishwarya Pattar. All rights reserved.
//

import UIKit
import Charts
import CoreBluetooth

class ChemicalCompositionViewController: UIViewController {

    // IBOutlets
    @IBOutlet weak var chemCompLineChartView: LineChartView!
    // add refresh button functionality in if it's not already predetermined
    
    // Initialise variables
    var centralManager: CBCentralManager!
    var bluefruitPeripheral: CBPeripheral!
    var txCharacteristic : CBCharacteristic?
    var rxCharacteristic : CBCharacteristic?
    var rxString = String()
    
    
    override func viewDidLoad() {
        // Initialise the CentralManager for BLE
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        super.viewDidLoad()
        
        // TODO: load graph.
            // call function that plots data
    }
    
    // TODO: receive data from bluetooth module
        // separate data into K+, glucose, lactate arrays
    
    // TODO: plot data onto graph
    

}


// Establish BLE Communication
extension ChemicalCompositionViewController: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            //centralManager.scanForPeripherals(withServices: nil)
            centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: nil)
        }
    }
    
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print(peripheral)
        bluefruitPeripheral = peripheral
        bluefruitPeripheral.delegate = self
        centralManager.stopScan()
        centralManager.connect(peripheral)
    }
    
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected!")
        bluefruitPeripheral.discoverServices(nil)
    }
    
}


extension ChemicalCompositionViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
            //print(service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        //print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                //print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                //print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic == rxCharacteristic {
            if let ASCIIstring = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
                
                rxString = ASCIIstring as String
                print(rxString)
                print(rxString.count)
                //let char = rxString.last
                //print(char?.unicodeScalars)
                
                
                /*characteristicASCIIValue = ASCIIstring
                print("Value Recieved: \((characteristicASCIIValue as String))")*/
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
            }
        }
        
        // categorise NSString
        // check is last character is \r\n to ensure string is not fragmented. if fragmented the value is discarded
        
        if rxString.last == "\r\n" {
            
            // Potassium values
            if rxString.first == "K" {
                
                //remove first and last character
                rxString.remove(at: rxString.startIndex)
                rxString.remove(at: rxString.endIndex)
                print(rxString)
                print(rxString.count)
                
                // extract time stamp and the K value as separate strings
                
                // append the values to corresponding array
                
            }
            // Glucose values
            else if rxString.first == "G" {
                
                //remove first and last character
                rxString.remove(at: rxString.startIndex)
                rxString.remove(at: rxString.endIndex)
                print(rxString)
                print(rxString.count)
                
            }
            // Lactate values
            else if rxString.first == "L" {
                
                //remove first and last character
                rxString.remove(at: rxString.startIndex)
                rxString.remove(at: rxString.endIndex)
                print(rxString)
                print(rxString.count)
                
            }
            
            
        }
        
        
        
        //let val = characteristicASCIIValue.doubleValue
        //values.append(val)
        //print(values)
        //print(temp)
        
    }
}

