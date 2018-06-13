//
//  AppDelegate.swift
//  BluetoohAndTouchBar
//
//  Created by Max Kraev on 17/05/2018.
//  Copyright © 2018 Max Kraev. All rights reserved.
//

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        guard let button = statusItem.button else { return }
        button.image = NSImage(named:NSImage.Name("StatusBarButtonImage"))
        button.action = #selector(applicationShouldHandleReopen(_:hasVisibleWindows:))
        constructMenu()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        
    }

    func applicationDidHide(_ notification: Notification) {
        
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }
    
    //MARK: Custom methods

    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show", action: #selector(NSApplicationDelegate.applicationShouldHandleReopen(_:hasVisibleWindows:)), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func launchFromTray() {
        NSApp.unhide(self)
        NSApp.activate(ignoringOtherApps: true)
    }
    

}
