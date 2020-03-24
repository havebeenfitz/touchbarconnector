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
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

    func applicationDidFinishLaunching(_: Notification) {
        guard let button = statusItem.button else { return }
        button.image = NSImage(named: NSImage.Name("StatusBarButtonImage"))
        button.action = #selector(applicationShouldHandleReopen(_:hasVisibleWindows:))
        NSApp.setActivationPolicy(NSApplication.ActivationPolicy.regular)
        NSApp.activate(ignoringOtherApps: true)
        constructMenu()
    }

    func applicationWillTerminate(_: Notification) {}

    func applicationDidHide(_: Notification) {}

    func applicationShouldHandleReopen(_: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if flag {
            NSApp.windows.last?.makeKeyAndOrderFront(self)
            return true
        } else {
            return false
        }
    }

    // MARK: Custom methods

    func constructMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Show", action: #selector(NSApplicationDelegate.applicationShouldHandleReopen(_:hasVisibleWindows:)), keyEquivalent: "w"))
        menu.addItem(NSMenuItem(title: "Hide", action: #selector(NSApplication.hide(_:)), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    @objc func launchFromTray() {
        NSApp.unhide(self)
        NSApp.activate(ignoringOtherApps: true)
    }
}
