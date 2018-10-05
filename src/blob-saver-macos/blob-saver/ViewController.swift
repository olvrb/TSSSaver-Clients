//
//  ViewController.swift
//  blob-saver
//
//  Created by oliver on 2018-09-24.
//  Copyright © 2018 oliver. All rights reserved.
//

import Cocoa
import Foundation
import SwiftyJSON

// Thanks to Lars Blumberg for this method.
// https://stackoverflow.com/a/40040472/8611114
extension String {
    func matchingStrings(regex: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: regex, options: []) else { return [] }
        let nsString = self as NSString
        let results  = regex.matches(in: self, options: [], range: NSMakeRange(0, nsString.length))
        return results.map { result in
            (0..<result.numberOfRanges).map { result.range(at: $0).location != NSNotFound
                ? nsString.substring(with: result.range(at: $0))
                : ""
            }
        }
    }
}
class ViewController: NSViewController {

    @IBOutlet var spinner: NSProgressIndicator!
    @IBOutlet var infoText: NSTextView!
    func setTextInfo() {
        let task = Process();
        task.launchPath = "/bin/sh";
        task.arguments = [ "-c", "/usr/local/bin/ideviceinfo" ];
        let pipe = Pipe();
        task.standardOutput = pipe;
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile();
        var out = "";
        if let output = String(data: data, encoding: String.Encoding.utf8) {
            out += output + "\n";
        }
        task.waitUntilExit()
        let UDID = out.matchingStrings(regex: "(?<=UniqueDeviceID: ).*")
        let DeviceName = out.matchingStrings(regex: "(?<=DeviceName: ).*")
        let ProductVersion = out.matchingStrings(regex: "(?<=ProductVersion: ).*")
        if UDID.count == 0 || DeviceName.count == 0 || ProductVersion.count == 0 {
            self.infoText.string = "No device found."
            return;
        }
        DispatchQueue.main.async {
            self.spinner.isHidden = true
            self.infoText.string = "Device name: " + DeviceName[0][0] + "\niOS version: " + ProductVersion[0][0] + "\nUDID: " + UDID[0][0]
        }
        
    }
    @IBOutlet var field: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setTextInfo()
    }

    @IBAction func refresh(_ sender: Any) {
        self.setTextInfo()
    }
    @IBAction func aboutClick(_ sender: NSButtonCell) {
        let alert = NSAlert()
        alert.messageText = "About TSSSaver Client."
        alert.informativeText = """
        Twitter: https://twitter.com/olvier_
        Donate to TSSSaver (@1Conan): https://tsssaver.1conan.com
        Donate to me: https://paypal.me/OBoudet
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal();
    }
    @IBAction func click(_ sender: Any) {
        spinner.isHidden = false
        spinner.startAnimation(Any?.self)
        let task = Process();
        task.launchPath = "/bin/sh";
        task.arguments = [ "-c", "/usr/local/bin/ideviceinfo" ];
        let pipe = Pipe();
        task.standardOutput = pipe;
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile();
        var out = "";
        if let output = String(data: data, encoding: String.Encoding.utf8) {
            out += output + "\n";
        }
        
        let uniqueChipID = out.matchingStrings(regex: "(?<=UniqueChipID: ).*")
        let hardwareModel = out.matchingStrings(regex: "(?<=HardwareModel: ).*")
        let productType = out.matchingStrings(regex: "(?<=ProductType: ).*")
        task.waitUntilExit()
        if uniqueChipID.count == 0 || hardwareModel.count == 0 || productType.count == 0 {
            let alert = NSAlert()
            alert.messageText = "No device connected."
            alert.informativeText = "Please connect yout device and try again."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal();
            return;
        }
        let url = URL(string: "https://tsssaver.1conan.com/app.php")!
        var request = URLRequest(url: url)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let postString = "ecid=" + uniqueChipID[0][0] + "&boardConfig=" + hardwareModel[0][0] + "&deviceID=" + productType[0][0];
        request.httpBody = postString.data(using: .utf8)
        let HTTPTask = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                DispatchQueue.main.async {
                    self.field.stringValue = error!.localizedDescription
                }
                return
            }
            
            let responseString = String(data: data, encoding: .utf8)
            if let dataFromString = responseString!.data(using: .utf8, allowLossyConversion: false) {
                let json = try! JSON(data: dataFromString)
                DispatchQueue.main.async {
                    self.spinner.isHidden = true
                    self.spinner.stopAnimation(Any?.self)
                    if json["success"] == false {
                        self.field.stringValue = "Error: " + json["error"]["message"].stringValue
                    } else {
                        self.field.stringValue = json["url"].stringValue
                    }
                }
                
            }
            
        }
        self.field.stringValue = "Please wait..."

        HTTPTask.resume()
        
        
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func copyToClipButtonClick(_ sender: NSButtonCell) {
        let pasteBoard = NSPasteboard.general
        pasteBoard.clearContents()
        pasteBoard.writeObjects([self.field.stringValue as String as NSPasteboardWriting])
        
    }
    
}

