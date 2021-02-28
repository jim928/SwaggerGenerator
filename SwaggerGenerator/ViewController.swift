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
        
        let scrollView = NSScrollView().addTo(cView).csFullfillHorizontal().cstoBottomOf(view: textField).cstoTopOf(view: bottomBar)
        print(documentPath)
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
        guard let fileUrl = lastUrl,let data = try? Data(contentsOf: fileUrl) ,let json = try? SKJSON(data: data) else{
            let alert = NSAlert()
            alert.messageText = "提示"
            alert.informativeText = "解析失败"
            alert.addButton(withTitle: "确定")
            alert.alertStyle = .warning;
            alert.beginSheetModal(for: NSApp.mainWindow ?? NSWindow()) { (response) in
                
            }
            return
        }
        
        //预设文件开头
        var str = """
        //
        //  AppRqDefines.swift
        //
        //
        //  Created by SwaggerGenerator on \(Date().stringWith(format: .yyyy_MM_ddHHmmssSSS))
        //


        import Foundation


        /** 参数处理方式（where to put the parameter
         ## 使用示例
         ```
         path, e.g. /users/{id};
         query, e.g. /users?role=admin;
         header, e.g. X-MyHeader: Value;
         cookie, e.g. Cookie: debug=0;
        */
        enum SGParamPosition {
            case inBody,inQuery,inPath
        }

        class SGItem {
            var url:String = ""
            var method:String = "GET"
            var paramMap:[(name:String,typeStr:String,paramPosition:SGParamPosition,isRequied:Bool)] = []
        }

        """
        var addStr = ""
        
        //解析host
        var host = json["host"].stringValue
        if !host.hasPrefix("http://"){
            host = "http://" + host
        }
        let basePath = json["basePath"].stringValue
        host = host + basePath
        addStr = """
            var hostUrl = "\(host)"

            """
        str = String(format: "%@\n%@", str,addStr)
            
        str.newLine(1)
        str += """
            // MARK: - UrlItems

            extension SGItem {
            """

        //创建url对象
        let paths = json["paths"].dictionaryValue
        let pathsAllKeys = paths.keys.sorted()
        for url in pathsAllKeys {
            let value = json["paths"][url]
            let allMethods = value.dictionaryValue.keys.sorted()
            for method in allMethods {
                //(method,valueMethod)
                let valueMethod = value[method]
                let fixUrl = url.components(separatedBy: "/{").first!
                
                //样例 "/brand/detail/{brandId}"
                var itemName = String(format: "%@", url)
                if itemName.hasPrefix("/") {
                    itemName = String(itemName.suffix(itemName.count-1))
                }
                
                let array = itemName.components(separatedBy: "/{")
                if array.count >= 2 {
                    itemName = array.first!
                }
                
                itemName = itemName.replacingOccurrences(of: "/", with: "_")
                itemName = itemName+"_"+method
                
                //summary
                var desStr = valueMethod["summary"].stringValue
                if (valueMethod["tags"].arrayValue.count > 0){
                    desStr += "  ("
                    for (index,tag) in valueMethod["tags"].arrayValue.enumerated(){
                        for tagDic in json["tags"].arrayValue {
                            if tagDic["name"].stringValue == tag.stringValue {
                                desStr += tagDic["description"].stringValue
                                if index != valueMethod["tags"].arrayValue.count - 1 {
                                    desStr += ","
                                }
                            }
                        }
                    }
                    desStr += ")"
                }
                
                str.newLine(2)
                let params = valueMethod["parameters"].arrayValue
                if (params.count > 0){
                    str += """
                    /** \(desStr)
                    ## 参数说明
                    ```
                """
                    str.newLine()
                    
                    for paramItem in params {
                        str.addSpace(1)
                        str += "    \(paramItem["name"].stringValue):\(paramItem["type"].stringValue.typeFix)"
                        if paramItem["required"].boolValue {
                            str += "  required"
                        }
                        if paramItem["default"].stringValue.count > 0 {
                            str += "  default:\(paramItem["default"].stringValue)"
                        }
                        str.newLine()
                    }
                    str += """
                        */
                    """
                }else{
                    str += "    /// \(desStr)"
                }
                
                str += """

                        static let \(itemName):SGItem = {
                            let item = SGItem()
                            item.url = "\(fixUrl)"
                            item.method = "\(method)"
                    """
                str.newLine()
                
                if (params.count > 0){
                    str += """
                            item.paramMap = [
                    """
                    for (_,paramItem) in params.enumerated(){
                        str.newLine()
                        var positionStr = ".inBody"
                        let isRequiredStr = paramItem["required"].boolValue ? "true" : "false"
                        if (paramItem["in"].stringValue == "query") {
                            positionStr = ".inQuery"
                        }
                        if (paramItem["in"].stringValue == "path") {
                            positionStr = ".inPath"
                        }
                        
                        str += """
                                    ("\(paramItem["name"].stringValue)","\(paramItem["type"].stringValue.typeFix)",\(positionStr),\(isRequiredStr)),
                        """
                    }
                    str.newLine()
                    str += """
                            ]
                    """
                    str.newLine()
                }
                str += """
                        return item
                    }()
                """
            }
        }
        
        str += """


            }
            """
        //数据model
        str.newLine(2)
        str += """
            // MARK: - Models

            """

        
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

class SGItem {
    var url:String = ""
    var method:String = "GET"
    var paramMap:[String:(SGParamPosition,Bool)] = [:]
}

enum SGParamPosition {
    case inBody,inQuerry,inPath
}

/** 修改密码
 ## 参数说明
 ```
 authCode:String  required
 password:String  required
 telephone:String  required
*/
let sso_updatePassword_post:SGItem = {
    let item = SGItem()
    item.url = "/sso/updatePassword"
    item.method = "post"
    item.paramMap = [
        "authCode":(.inBody,true)
    ]
    return item
}()




extension String {
    func subString(from: Int, length:Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: from)
        let endIndex = self.index(self.startIndex, offsetBy: from + length)
        return String(self[startIndex...endIndex])
    }
}

extension String {
    mutating func addSpace(_ num:Int){
        self = self+String(repeating: " ", count: num)
    }
    mutating func newLine(_ num:Int = 1){
        self = self+String(repeating: "\n", count: num)
    }
}

extension String {
    var typeFix:String {
        if (self == "string"){
            return "String"
        }
        if (self == "integer"){
            return "Int"
        }
        if (self == "array"){
            return "Array"
        }
        return self
    }
}
