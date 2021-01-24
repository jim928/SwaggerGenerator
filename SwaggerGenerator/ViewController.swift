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
        let cView = NSView().addTo(self.view).csFullfill().csWidthGreaterThanOrEqual(900).csHeightGreaterThanOrEqual(700)
        let bottomBar = NSView().addTo(self.view).csFullfillHorizontal().csBottom().csHeight(50).csTopGreaterThanOrEqual()
        let doneBtn = NSButton().addTo(bottomBar).csCenterY().csHeight(30).csRight(-10).csWidth(70)
        doneBtn.title = "导出"
        let chooseBtn = NSButton().addTo(bottomBar).csCenterY().csHeight(30).csWidth(70).cstoLeftOf(view: doneBtn, constant: -10)
        chooseBtn.title = "选择文件"
        chooseBtn.action = #selector(chooseTap)
    }
    @objc func chooseTap(){
        panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.delegate = self
        let finded = panel.runModal()
        if finded == .OK {
            
        }
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController : NSOpenSavePanelDelegate {
    func panelSelectionDidChange(_ sender: Any?) {
        print("zlog",#file,#function,#line,panel.url)
    }
}
