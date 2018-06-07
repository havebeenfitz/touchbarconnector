//
//  ViewController.swift
//  BluetoohAndTouchBar
//
//  Created by Max Kraev on 17/05/2018.
//  Copyright © 2018 Max Kraev. All rights reserved.
//

import Cocoa
import CoreBluetooth
import IOBluetooth
import ColorSync

//MARK: Enums

fileprivate enum CellIdentifiers {
    static let NameCell = "NameCellID"
    static let UUIDCell = "UUIDCellID"
    static let StatusCell = "StatusCellID"
}

fileprivate enum DeviceType {
    case oldDevice
    case newDevice
}

//MARK:- Controller

class ViewController: NSViewController, CBCentralManagerDelegate, CBPeripheralDelegate, NSTableViewDelegate, NSTableViewDataSource, NSScrubberDelegate, NSScrubberDataSource, IOBluetoothDeviceInquiryDelegate {
   
    
    
    //MARK:- Outlets
    
    @IBOutlet weak var clipView: NSClipView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var scrubber: NSScrubber!
    
    //MARK:- Vars

    let bluetoothManager = CBCentralManager()
    let cbuuids = [CBUUID]()
    
    var devices = [CBPeripheral]()
    var tempDevice = [CBPeripheral]()
    var devicesPictures = [Int: NSImage]()
    var pictures = [#imageLiteral(resourceName: "airpods"), #imageLiteral(resourceName: "watch"), #imageLiteral(resourceName: "iphone")]
    
    var legacyDevices = [IOBluetoothDevice]()
    let legacyBluetoothManager = IOBluetoothDeviceInquiry(delegate: self)
    
    var timer: Timer? = nil
    
    var scrubberDeviceItemID = NSUserInterfaceItemIdentifier("Device")
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        bluetoothManager.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        scrubber.delegate = self
        scrubber.dataSource = self
        scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: scrubberDeviceItemID)
        
        bluetoothManager.delegate = self
        
//        legacyBluetoothManager?.delegate = self
//        legacyBluetoothManager?.start()
//        loadConnectedDevices()
//        timer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(repeatScan), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear() {
        print("kill timer")
        //timer!.invalidate()
    }
    
    //MARK:- Tableview delegate and datasource
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text = ""
        var cellIdentifier: String = ""
        
        let item = devices[row]
        
        if tableColumn == tableView.tableColumns[0] {
            
            if let name = item.name {
                text = name
            } else {
                text = "Unnamed device"
            }
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.identifier.uuidString
            cellIdentifier = CellIdentifiers.UUIDCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = String(item.state.rawValue)
            cellIdentifier = CellIdentifiers.StatusCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return devices.count
    }
    
    //MARK:- Bluetooth Central manager delegate
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("powered on")
            central.scanForPeripherals(withServices: cbuuids, options: nil)
        case .unknown:
            print("state unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("powered off")
            bluetoothManager.stopScan()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("found", peripheral.name ?? "default")
        
        if !devices.contains(peripheral) && peripheral.name != nil {
            devices.append(peripheral)
            tableView.reloadData()
            scrubber.reloadData()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("connected")
        central.stopScan()
        tableView.reloadData()
        tempDevice.append(peripheral)
        tempDevice.first!.delegate = self
        tempDevice.first!.discoverServices(nil)
        
        
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("fail to connect")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnected")
        tableView.reloadData()
    }
    
    //MARK: CBPeripherial Delegate
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        //tempDevice.append(peripheral)
        print(peripheral.services ?? "no services")
    }
    
    //MARK: IOBluetooth Devices Inquiry Delegate
    
    func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry!) {
        print("started")
    }
    
    func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        print("found device")
        legacyDevices.append(device)
        scrubber.reloadData()
        tableView.reloadData()
    }
    
    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        print("completed")
    }
    
    //MARK: Scrubber Delegate and Datasource
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return devices.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        
        let itemView = scrubber.makeItem(withIdentifier: scrubberDeviceItemID, owner: nil) as! NSScrubberTextItemView
        
        guard let name = devices[index].name else { return itemView }
        itemView.title = name
        
        return itemView
    }
    
    func scrubber(_ scrubber: NSScrubber, didHighlightItemAt highlightedIndex: Int) {
        
        if (scrubber.itemViewForItem(at: highlightedIndex)?.isSelected)! {
            print("cancel connection")
            bluetoothManager.cancelPeripheralConnection(devices[highlightedIndex])
            scrubber.itemViewForItem(at: highlightedIndex)?.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            bluetoothManager.connect(devices[highlightedIndex], options: nil)
            scrubber.itemViewForItem(at: highlightedIndex)?.layer?.backgroundColor = NSColor.gray.cgColor
            print("connecting to \(devices[highlightedIndex].name ?? "no name")")
        }
        
        scrubber.itemViewForItem(at: highlightedIndex)?.isSelected = !(scrubber.itemViewForItem(at: highlightedIndex)?.isSelected)!
        
    }
    
    //MARK: Misc
    
    @objc func repeatScan() {
        legacyBluetoothManager?.stop()
        legacyBluetoothManager?.delegate = self
        legacyBluetoothManager?.start()
        
    }
    
    func loadConnectedDevices() {
        
        legacyDevices += (legacyBluetoothManager?.foundDevices() as! [IOBluetoothDevice])
        tableView.reloadData()
        scrubber.reloadData()
        
    }
    
    //MARK: Actions
    
    @IBAction func connectButtonPressed(_ sender: Any) {
        print("rescan")
        
        //timer?.fire()
        //legacyDevices.removeAll()
        //legacyBluetoothManager?.start()
        
        devices.removeAll()
        tableView.reloadData()
        scrubber.reloadData()
        
        bluetoothManager.scanForPeripherals(withServices: cbuuids, options: nil)
        
    }
    
    @IBAction func stopScanPressed(_ sender: NSButton) {
        
        legacyBluetoothManager?.stop()
        bluetoothManager.stopScan()
        print("scan stopped, timer killed")
        timer?.invalidate()
    }
    
}

