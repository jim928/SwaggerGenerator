//
//  ViewController.swift
//  SwaggerGenerator
//
//  Created by jim on 2021/1/23.
//

import Cocoa
import SightKit

class ViewController: NSViewController {

    var textField:NSTextField!
    var panel:NSOpenPanel = NSOpenPanel()
    var json:SKJSON?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        let cView = NSView().addTo(self.view).csFullfill().csWidthGreaterThanOrEqual(600).csHeightGreaterThanOrEqual(500)
        textField = NSTextField().addTo(cView).csLeft().csTop().csRight()//.csHeight(30)
        textField.isEditable = false
        
        let bottomBar = NSView().addTo(self.view).csFullfillHorizontal().csBottom().csHeight(50).csTopGreaterThanOrEqual()
        
        let doneBtn = NSButton(title: "导出", target: self, action: #selector(exportTap)).addTo(bottomBar).csCenterY().csHeight(30).csRight(-10).csWidth(70)
        
        let compileBtn = NSButton(title: "生成", target: self, action: #selector(compileTap)).addTo(bottomBar).csCenterY().csHeight(30).csWidth(70).cstoLeftOf(view: doneBtn, constant: -10)
        
        let chooseBtn = NSButton(title: "选择文件", target: self, action: #selector(chooseTap)).addTo(bottomBar).csCenterY().csHeight(30).csWidth(70).cstoLeftOf(view: compileBtn, constant: -10)

        textField.stringValue = lastUrl?.absoluteString ?? ""
        
        print(getuserinfo)
        print(getuserinfo)

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
                if let url = panel.urls.first {
                    lastUrl = url
                    self.textField.stringValue = url.absoluteString
                    self.startProgress()
                }
            }else if response == .cancel {
                print("cancel")
            }
        }
    }
    func startProgress(){
        if let url = lastUrl,let data = try? Data(contentsOf: url) ,let json = try? SKJSON(data: data){
            self.json = json
        }else{
            let alert = NSAlert()
            alert.messageText = "提示"
            alert.informativeText = "解析失败"
            alert.addButton(withTitle: "确定")
            alert.alertStyle = .warning;
            alert.beginSheetModal(for: NSApp.mainWindow ?? NSWindow()) { (response) in
                
            }
            return
        }
        
        print(documentPath)
        var str = """
        //
        //  AppRqDefines.swift
        //
        //
        //  Created by SwaggerGenerator.
        //


        """
        var addStr = ""
        
        if var host = json?["host"].stringValue {
            if !host.hasPrefix("http://"){
                host = "http://" + host
            }
            if let basePath = json?["basePath"].stringValue{
                host = host + basePath
            }
            
            addStr = """
            var hostUrl = "\(host)"


            """
            str = String(format: "%@\n%@", str,addStr)
        }
        
        addStr = "enum AppURL : String{"
        str = String(format: "%@\n%@", str,addStr)
        addStr = "    case requestUserInfor = \"m/swift/url\""
        str = String(format: "%@\n%@", str,addStr)
        addStr = "}"
        str = String(format: "%@\n%@", str,addStr)

        let data1 = str.data(using: .utf8)
        data1?.saveToPath(path: documentPath + "/str.swift")
    }
    @objc func compileTap(){
        startProgress()
    }
    @objc func exportTap(){
        
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

let kLastUrlKey = "kLastUrlKey"
var lastUrl : URL? = {
    let str = UserDefaults.standard.url(forKey: kLastUrlKey)
    return str
}() {
    didSet{
        UserDefaults.standard.set(lastUrl, forKey: kLastUrlKey)
        UserDefaults.standard.synchronize()
    }
}

class UrlItem {
    var url:String = ""
    var method:String = "GET"
    var isParamInUrl:Bool = false
}

/** 会员登录
 ## 参数说明
 ```
 password:String
 username:String
 */
let getuserinfo:UrlItem = {
    let item = UrlItem()
    item.url = "this is url"
    item.method = "get or post"
    return item
}()

