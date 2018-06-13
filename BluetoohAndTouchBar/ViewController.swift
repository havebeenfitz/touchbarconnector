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
}

//MARK:- Controller

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource,
                      NSScrubberDelegate, NSScrubberDataSource,
                      IOBluetoothDeviceInquiryDelegate, IOBluetoothDevicePairDelegate {
   
    //MARK:- Outlets
    
    @IBOutlet weak var clipView: NSClipView!
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var scrubber: NSScrubber!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    //MARK: Vars
    
    var ioDevices = [IOBluetoothDevice]()
    let ioBluetoothInquiryManager = IOBluetoothDeviceInquiry()
    let pairingDevice = IOBluetoothDevicePair()

    var timer: Timer? = nil
    
    var scrubberDeviceItemID = NSUserInterfaceItemIdentifier("Device")
    
    //MARK: LifeCycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        
        scrubber.delegate = self
        scrubber.dataSource = self
        scrubber.register(NSScrubberTextItemView.self, forItemIdentifier: scrubberDeviceItemID)
        //scrubber.register(NSScrubberImageItemView.self, forItemIdentifier: scrubberDeviceItemID)
        
        ioBluetoothInquiryManager.searchType = kIOBluetoothDeviceSearchLE.rawValue
        ioBluetoothInquiryManager.updateNewDeviceNames = true
        ioBluetoothInquiryManager.delegate = self
        pairingDevice.delegate = self
        
        ioBluetoothInquiryManager.start()
        progressIndicator.startAnimation(self)
        loadPairedDevices()
        
        timer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(repeatScan), userInfo: nil, repeats: true)

        
    }
    
    override func viewDidDisappear() {
        timer?.invalidate()
    }

    //MARK:- Tableview delegate and datasource
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return ioDevices.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var text = ""
        var cellIdentifier: String = ""
        
        let item = ioDevices[row]
    
        text = item.nameOrAddress
        cellIdentifier = CellIdentifiers.NameCell
            
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            
            cell.textField?.stringValue = text
            return cell
        }
        
        return nil
    }
    
    //MARK: IOBluetooth Devices Inquiry Delegate
    
    func deviceInquiryStarted(_ sender: IOBluetoothDeviceInquiry!) {
        print("started")
        
        progressIndicator.startAnimation(self)
        progressIndicator.isHidden = false
        
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
        
        progressIndicator.stopAnimation(self)
        progressIndicator.isHidden = true
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
        
        if !ioDevices[index].isPaired() {
            itemView.layer?.backgroundColor = NSColor(calibratedRed: 255, green: 0, blue: 0, alpha: 0.5).cgColor
        }
        
        if ioDevices[index].isPaired(), !ioDevices[index].isConnected()  {
            itemView.layer?.backgroundColor = NSColor.clear.cgColor
        }
    
        if ioDevices[index].isConnected() {
            itemView.layer?.backgroundColor = NSColor(calibratedRed: 50/255, green: 200/255, blue: 100/255, alpha: 0.5).cgColor
        }

        return itemView
    }
    
//    Pictures for scrubber. Выглядит пока хреново
    
//    func scrubber(_ scrubber: NSScrubber, viewForItemAt index: Int) -> NSScrubberItemView {
//
//        let itemView = scrubber.makeItem(withIdentifier: scrubberDeviceItemID, owner: nil) as! NSScrubberImageItemView
//
//        if ioDevices[index].nameOrAddress.contains("iPhone") {
//            itemView.image = #imageLiteral(resourceName: "iphone")
//        } else if ioDevices[index].nameOrAddress.contains("Mouse") {
//            itemView.image = #imageLiteral(resourceName: "mouse")
//        } else if ioDevices[index].nameOrAddress.contains("Keyboard") {
//            itemView.image = #imageLiteral(resourceName: "keyboard")
//        } else if ioDevices[index].nameOrAddress.contains("Trackpad") {
//            itemView.image = #imageLiteral(resourceName: "trackpad")
//        } else if ioDevices[index].nameOrAddress.contains("Watch") {
//            itemView.image = #imageLiteral(resourceName: "watch")
//        } else if ioDevices[index].nameOrAddress.contains("Airpods") {
//            itemView.image = #imageLiteral(resourceName: "airpods")
//        }
//        return itemView
//    }
//
    
    func scrubber(_ scrubber: NSScrubber, didHighlightItemAt highlightedIndex: Int) {
        
        ioBluetoothInquiryManager.stop()
        timer?.invalidate()
        
        if ioDevices[highlightedIndex].isConnected() {
            
            print("cancel connection")
            ioDevices[highlightedIndex].closeConnection()
            scrubber.itemViewForItem(at: highlightedIndex)?.layer?.backgroundColor = NSColor.clear.cgColor
            
        } else if !ioDevices[highlightedIndex].isConnected(), ioDevices[highlightedIndex].isPaired()  {
            
            DispatchQueue.global(qos: .background).async {
                self.ioDevices[highlightedIndex].openConnection()
                print("connecting to \(self.ioDevices[highlightedIndex].nameOrAddress ?? "no name")")
            }
            
            scrubber.itemViewForItem(at: highlightedIndex)?.isSelected = !(scrubber.itemViewForItem(at: highlightedIndex)?.isSelected)!
            scrubber.itemViewForItem(at: highlightedIndex)?.layer?.backgroundColor = NSColor(calibratedRed: 50/255, green: 200/255, blue: 100/255, alpha: 0.5).cgColor
            
        } else if !ioDevices[highlightedIndex].isPaired() {
        
            print("Attempt to pair")
            
            pairingDevice.setDevice(ioDevices[highlightedIndex])
            pairingDevice.start()

        }
    }
    
    //MARK: Device Pairing delegate
    
    func devicePairingStarted(_ sender: Any!) {
        print("Pairing started")
    }
    
    func devicePairingConnecting(_ sender: Any!) {
        print("Connecting")
    }
    
    func devicePairingUserPasskeyNotification(_ sender: Any!, passkey: BluetoothPasskey) {
        print(passkey)
        pairingDevice.replyUserConfirmation(true)
    }
    
    func devicePairingPINCodeRequest(_ sender: Any!) {
        print("PIN requested")
    }
    
    func deviceSimplePairingComplete(_ sender: Any!, status: BluetoothHCIEventStatus) {
        print(status)
    }
    
    func devicePairingFinished(_ sender: Any!, error: IOReturn) {
        print("finished")
        scrubber.reloadData()
    }
    
    //MARK: Misc
    
    
    func loadPairedDevices() {
        
        for device in IOBluetoothDevice.pairedDevices() {
            ioDevices.append(device as! IOBluetoothDevice)
            tableView.reloadData()
            scrubber.reloadData()
        }
        
        if scrubber.numberOfItems == 0 {
            scrubber.showsArrowButtons = false
        } else {
            scrubber.showsArrowButtons = true
        }
        
    }
    
    
    @objc func repeatScan() {
        ioBluetoothInquiryManager.clearFoundDevices()
        ioBluetoothInquiryManager.start()
    }
    
    //MARK: Actions
    
    @IBAction func rescanButtonPressed(_ sender: Any) {
        print("rescan")
        
        progressIndicator.startAnimation(self)
        progressIndicator.isHidden = false
    
        timer?.fire()
        ioDevices.removeAll()
        repeatScan()
        loadPairedDevices()
        
        tableView.reloadData()
        scrubber.reloadData()
 
    }
    
    @IBAction func rescanUI(_ sender: NSButton) {
        print("rescan")
        
        progressIndicator.startAnimation(self)
        progressIndicator.isHidden = false
        
        timer?.fire()
        ioDevices.removeAll()
        ioBluetoothInquiryManager.clearFoundDevices()
        
        tableView.reloadData()
        scrubber.reloadData()
        
        repeatScan()
        loadPairedDevices()
    }
    
    @IBAction func stopButtonPressed(_ sender: Any) {
        timer?.invalidate()
        ioBluetoothInquiryManager.stop()
        progressIndicator.stopAnimation(self)
        progressIndicator.isHidden = true
    }
}

