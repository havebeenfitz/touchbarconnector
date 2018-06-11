//
//  ViewController.swift
//  BluetoohAndTouchBar
//
//  Created by Max Kraev on 17/05/2018.
//  Copyright © 2018 Max Kraev. All rights reserved.
//

import Cocoa
import IOBluetooth
import IOBluetoothUI
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

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource,
                      NSScrubberDelegate, NSScrubberDataSource,
                      IOBluetoothDeviceInquiryDelegate {
   
    //MARK:- Outlets
    
    @IBOutlet weak var clipView: NSClipView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var scrubber: NSScrubber!
    
    //MARK:- Vars
    
    var ioDevices = [IOBluetoothDevice]()
    let ioBluetoothManager = IOBluetoothDeviceInquiry()
    let pairingController = IOBluetoothPairingController(windowNibName: NSNib.Name(rawValue: "PairingController"))
    
    var timer: Timer? = nil
    
    var scrubberDeviceItemID = NSUserInterfaceItemIdentifier("Device")
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        scrubber.delegate = self
        scrubber.dataSource = self
        scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: scrubberDeviceItemID)
        
        ioBluetoothManager.searchType = kIOBluetoothDeviceSearchLE.rawValue
        ioBluetoothManager.updateNewDeviceNames = true
        ioBluetoothManager.delegate = self
        
        loadPairedDevices()
        
        ioBluetoothManager.start()
        
        
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(repeatScan), userInfo: nil, repeats: true)

        
    }
    
    override func viewWillDisappear() {
        print("kill timer")
    }
    
    func loadPairedDevices() {
        
        for device in IOBluetoothDevice.pairedDevices() {
            ioDevices.append(device as! IOBluetoothDevice)
            
            tableView.reloadData()
            scrubber.reloadData()
        }
        
    }
    
    
    //MARK:- Tableview delegate and datasource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ioDevices.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text = ""
        var cellIdentifier: String = ""
        
        let item = ioDevices[row]
        
        if tableColumn == tableView.tableColumns[0] {
            
            if let name = item.nameOrAddress {
                text = name
            } else {
                text = "Unnamed device"
            }
            cellIdentifier = CellIdentifiers.NameCell
        } else if tableColumn == tableView.tableColumns[1] {
            text = item.addressString
            cellIdentifier = CellIdentifiers.UUIDCell
        } else if tableColumn == tableView.tableColumns[2] {
            text = String(item.isConnected())
            cellIdentifier = CellIdentifiers.StatusCell
        }
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
    
    //MARK: IOBluetooth Devices Inquiry Delegate
    
    func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry!) {
        print("started")
    }

    func deviceInquiryDeviceFound(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!) {
        print("found device", device.nameOrAddress)
        if !ioDevices.contains(device) {
            ioDevices.append(device)
            scrubber.reloadData()
            tableView.reloadData()
        }
        
    }

    func deviceInquiryComplete(_ sender: IOBluetoothDeviceInquiry!, error: IOReturn, aborted: Bool) {
        print("completed")
    }
    
    func deviceInquiryDeviceNameUpdated(_ sender: IOBluetoothDeviceInquiry!, device: IOBluetoothDevice!, devicesRemaining: UInt32) {
        print("name updated")
    }
    
    //MARK: Scrubber Delegate and Datasource
    
    func numberOfItems(for scrubber: NSScrubber) -> Int {
        return ioDevices.count
    }
    
    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
        
        let itemView = scrubber.makeItem(withIdentifier: scrubberDeviceItemID, owner: nil) as! NSScrubberTextItemView
        guard let name = ioDevices[index].nameOrAddress else { return itemView }
        
        itemView.title = name
        
        if ioDevices[index].isConnected() {
            itemView.layer?.backgroundColor = NSColor.gray.cgColor
        }
        
        return itemView
    }
    
    func scrubber(_ scrubber: NSScrubber, didHighlightItemAt highlightedIndex: Int) {
        
        if ioDevices[highlightedIndex].isConnected() {
            print("cancel connection")
            ioDevices[highlightedIndex].closeConnection()
            scrubber.itemViewForItem(at: highlightedIndex)?.layer?.backgroundColor = NSColor.clear.cgColor
        } else if !ioDevices[highlightedIndex].isConnected() {
            DispatchQueue.global(qos: .background).async {
                if !self.ioDevices[highlightedIndex].isPaired() {
                    
                    self.pairingController.runModal()
                    self.pairingController.getResults()
                }
                self.ioDevices[highlightedIndex].openConnection()
            }
            
            scrubber.itemViewForItem(at: highlightedIndex)?.layer?.backgroundColor = NSColor.gray.cgColor
            print("connecting to \(ioDevices[highlightedIndex].nameOrAddress ?? "no name")")
        }

        scrubber.itemViewForItem(at: highlightedIndex)?.isSelected = !(scrubber.itemViewForItem(at: highlightedIndex)?.isSelected)!
        ioBluetoothManager.stop()
        timer?.invalidate()
        print("timer killed")
    }
    
    //MARK: Misc
    
    @objc func repeatScan() {
        ioBluetoothManager.stop()
        ioBluetoothManager.start()
    }
    
    //MARK: Actions
    
    @IBAction func rescanButtonPressed(_ sender: Any) {
        print("rescan")
    
        timer?.fire()
        ioDevices.removeAll()
        loadPairedDevices()
        repeatScan()

        tableView.reloadData()
        scrubber.reloadData()
 
    }
    
    
    
    @IBAction func setClassic(_ sender: NSButton) {
        
        ioBluetoothManager.searchType = kIOBluetoothDeviceSearchClassic.rawValue
        
        print("Search type Classic", kIOBluetoothDeviceSearchClassic.rawValue)
        
    }
    @IBAction func setLE(_ sender: NSButton) {
        print("Search type LE", kIOBluetoothDeviceSearchLE.rawValue)
        ioBluetoothManager.searchType = kIOBluetoothDeviceSearchLE.rawValue
        
    }
    
    @IBAction func rescanUI(_ sender: NSButton) {
        print("rescan")
        
        timer?.fire()
        ioDevices.removeAll()
        repeatScan()
        loadPairedDevices()
        
        tableView.reloadData()
        scrubber.reloadData()
        
    }
}

