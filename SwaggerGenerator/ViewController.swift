//
//  ViewController.swift
//  SwaggerGenerator
//
//  Created by jim on 2021/1/23.
//

import Cocoa
import SightKit

class ViewController: NSViewController {

    var panel:NSOpenPanel = NSOpenPanel()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let cView = NSView().addTo(self.view).csFullfill().csWidthGreaterThanOrEqual(600).csHeightGreaterThanOrEqual(500)
        let bottomBar = NSView().addTo(self.view).csFullfillHorizontal().csBottom().csHeight(50).csTopGreaterThanOrEqual()
        let doneBtn = NSButton(title: "导出", target: self, action: #selector(exportTap)).addTo(bottomBar).csCenterY().csHeight(30).csRight(-10).csWidth(70)
        let chooseBtn = NSButton(title: "选择文件", target: self, action: #selector(chooseTap)).addTo(bottomBar).csCenterY().csHeight(30).csWidth(70).cstoLeftOf(view: doneBtn, constant: -10)
    }
    @objc func chooseTap(){
        let panel = NSOpenPanel()
        panel.prompt = "确定";
        panel.message = "选择swagger的json文件"
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["json"]
        panel.beginSheetModal(for: NSApp.mainWindow ?? NSWindow()) { (response) in
            if response == .OK {
                print(panel.urls)
                if let url = panel.urls.first ,let data = try? Data(contentsOf: url) ,let json = try? SKJSON(data: data){
                    
                }
            }else if response == .cancel {
                print("cancel")
            }
        }
    }
    @objc func exportTap(){
        
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

