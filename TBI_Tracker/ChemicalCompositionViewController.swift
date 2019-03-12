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

// initialise arrays
var timeK : [Double] = []
var Karr : [Double] = []
var timeG : [Double] = []
var Garr : [Double] = []
var timeL : [Double] = []
var Larr : [Double] = []

class ChemicalCompositionViewController: UIViewController {

    // IBOutlets
    @IBOutlet weak var chemCompLineChartView: LineChartView!
    @IBAction func refreshButton(_ sender: Any) {
        viewDidLoad()
    }
    
    
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
        
        // initialise graph
        setChartValues()
        
        // makes bubbles appear when you click on data
        let marker:BalloonMarker = BalloonMarker(color: UIColor(white: 180/255, alpha: 1),
                                                 font: .systemFont(ofSize: 12),
                                                 textColor: .white,
                                                 insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = chemCompLineChartView
        marker.minimumSize = CGSize(width: 80, height: 40)
        chemCompLineChartView.marker = marker
        
        // modify the LineChartView
        self.chemCompLineChartView.dragYEnabled = false
        self.chemCompLineChartView.rightAxis.enabled = false
        self.chemCompLineChartView.backgroundColor = .white
        
        //TODO: titles and axes labels to graphs
        
        // TODO: automatically refresh graph every 15 seconds
    }
    
    
    

    func setChartValues() {
        
        //TODO: multiple graphs plotted on one
        
        // sets x and y values for K+
        let entriesK = (0..<Karr.count).map { (i) -> ChartDataEntry in
            let Kval = Karr[i]
            let timeValK = timeK[i]
            return ChartDataEntry(x: timeValK, y: Kval)
        }
        let setK = LineChartDataSet(values: entriesK, label: "[K+]")
        
        // sets x and y values for Glucose
        let entriesG = (0..<Garr.count).map { (i) -> ChartDataEntry in
            let Gval = Garr[i]
            let timeValG = timeG[i]
            return ChartDataEntry(x: timeValG, y: Gval)
        }
        let setG = LineChartDataSet(values: entriesG, label: "[Glucose]")
        
        // sets x and y values for Lactate
        let entriesL = (0..<Larr.count).map { (i) -> ChartDataEntry in
            let Lval = Larr[i]
            let timeValL = timeL[i]
            return ChartDataEntry(x: timeValL, y: Lval)
        }
        let setL = LineChartDataSet(values: entriesL, label: "[Lactate]")
        
        
        let dataSets = [setK, setG, setL]
        let data = LineChartData(dataSets: dataSets)
        self.chemCompLineChartView.data = data
        
        // modify line plot
        setK.drawCirclesEnabled = false
        setK.drawValuesEnabled = false
        setK.lineWidth = 2
    }
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
                    /*print(rxString)
                    print(rxString.count)
                    let char = rxString.last
                    print(char?.unicodeScalars)*/
                
                
                /*characteristicASCIIValue = ASCIIstring
                print("Value Recieved: \((characteristicASCIIValue as String))")*/
                NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: nil)
            }
        }
        
        // categorise NSString
        // check is last character is \r\n to ensure string is not fragmented. if fragmented the value is discarded
        
        if rxString.last == "\r\n" && rxString.count > 5 {

            // store the first letter
            let firstLetter = rxString.first
            
            // remove first and last character
            rxString.remove(at: rxString.startIndex)
            rxString.remove(at: rxString.index(before: rxString.endIndex))
            
            // extract time stamp and values
            let space = rxString.firstIndex(of: " ") ?? rxString.endIndex
            let time = rxString[..<space]
            let val = rxString.dropFirst(time.count + 1)
            
            // store in corresponding array depending on firstLetter
            if firstLetter == "K" {
                timeK.append(Double(time)!/1000)
                Karr.append(Double(val)!)
            } else if firstLetter == "G" {
                timeG.append(Double(time)!/1000)
                Garr.append(Double(val)!)
            } else if firstLetter == "L" {
                timeL.append(Double(time)!/1000)
                Larr.append(Double(val)!)
            }
        }
    }
}
