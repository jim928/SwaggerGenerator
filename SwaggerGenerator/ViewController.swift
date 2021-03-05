//
//  ViewController.swift
//  SwaggerGenerator
//
//  Created by jim on 2021/1/23.
//

import Cocoa
import SightKit

//https://wdpm.gitbook.io/swagger-documentation/swagger-specification/describing-parameters
class ViewController: NSViewController {

    var textField:NSTextField!
    var panel:NSOpenPanel = NSOpenPanel()
    var pathArray:[(className:String,url:String,method:String,paramMap:[SGParamItem])] = []
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
        
        pathArray.removeAll()
        
        //预设文件开头
        var str = """
        //
        //  AppURLDefines.swift
        //
        //
        //  Created by SwaggerGenerator on \(Date().stringWith(format: .yyyy_MM_ddHHmmssSSS))
        //


        import Foundation
        import SightKit


        /** 参数处理方式（where to put the parameter
         ## 使用示例
         ```
         path, e.g. /users/{id};
         query, e.g. /users?role=admin;
         header, e.g. X-MyHeader: Value;
         cookie, e.g. Cookie: debug=0;
        */
        public enum SGParamPosition : Int {
            case inBody = 0,inQuery,inPath,inHeader
        }

        public struct SGParamItem{
            public var name:String = ""
            public var typeStr:String = "String"
            public var paramPosition:SGParamPosition = .inBody
            public var isRequired = false
            public var value:Any? = nil
        }

        public protocol SGCommonUrlProtocol {
            var url:String { get set }
            var method:String { get set }
            var paramMap:[String:SGParamItem] { get set }
        }
        
        public class SGResponseItem: NSObject {
            public enum CodingKeys: String, CodingKey {
                case description_str = "description"
            }
        }

        """
        
        //解析host
        var host = json["host"].stringValue
        if !host.hasPrefix("http://"){
            host = "http://" + host
        }
        let basePath = json["basePath"].stringValue
        host = host + basePath
        if host.hasSuffix("/") {
            host = String(host.prefix(host.count-1))
        }
        str += """

            public var hostUrl = "\(host)"

            """
            
        str.newLine(1)
        str += """
            // MARK: - UrlItems

            public struct SGUrl {
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
                let fixUrl = url
                
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

                        public class \(itemName):SGCommonUrlProtocol {
                            public var url = "\(fixUrl)"
                            public var method = "\(method)"
                    """
                str.newLine()
                
                var paramsArray:[SGParamItem] = []
                if (params.count > 0){
                    str += """
                            public var paramMap:[String:SGParamItem] = [
                    """
                    for (_,paramItem) in params.enumerated(){
                        str.newLine()
                        var positionStr = ".inBody"
                        var position = SGParamPosition.inBody
                        
                        let isRequiredStr = paramItem["required"].boolValue ? "true" : "false"
                        let isRequired = paramItem["required"].boolValue
                        
                        if (paramItem["in"].stringValue == "query") {
                            positionStr = ".inQuery"
                            position = .inQuery
                        }
                        if (paramItem["in"].stringValue == "path") {
                            positionStr = ".inPath"
                            position = .inPath
                        }
                        if (paramItem["in"].stringValue == "header") {
                            positionStr = ".header"
                            position = .inHeader
                        }
                        
                        var elementType = paramItem["schema"]["originalRef"].stringValue.classFix
                        if elementType.count == 0 {
                            if paramItem["type"].stringValue == "array" {
                                elementType = "[\(paramItem["items"]["type"].stringValue.typeFix)]"
                            }else{
                                elementType = paramItem["type"].stringValue.typeFix
                                
                                if elementType == "ref"{
                                    elementType = "Int"
                                }
                            }
                        }
                        if elementType.count == 0 || elementType == "object" {
                            elementType = "Any"
                        }

                        
                        str += """
                                    "\(paramItem["name"].stringValue)":SGParamItem(name: "\(paramItem["name"].stringValue)", typeStr: "\(elementType)", paramPosition: \(positionStr), isRequired: \(isRequiredStr), value: nil),
                        """
                        
                        paramsArray.append(SGParamItem(name: paramItem["name"].stringValue, typeStr: elementType, paramPosition: position, isRequired: isRequired, value: nil))
                    }
                    str.newLine()
                    str += """
                            ]
                    """
                    str.newLine()
                }else{
                    str += """
                            public var paramMap:[String:SGParamItem] = [:]

                    """
                }
                str += """
                    }
                """
                
                self.pathArray.append((className: itemName, url: fixUrl, method: method, paramMap: paramsArray))
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

        let definitions = json["definitions"].dictionaryValue
        for (_,key) in definitions.keys.sorted().enumerated(){
            let className = key.classFix
            let value = json["definitions"][key]
            let type = value["type"].stringValue
            if type == "object" {
                str += """

                public class \(className): SGResponseItem {

                """
                
                let pKeys = value["properties"].dictionaryValue.keys.sorted()
                for (_,propertyKey) in pKeys.enumerated(){
                    let propertyValue = value["properties"][propertyKey]
                    let propertyDes = propertyValue["description"].stringValue
                    if propertyDes.count > 0 {
                        str += """
                            /// \(propertyDes)

                        """
                    }
                    let keyFix = propertyKey.keyFix
                    if propertyValue["type"].stringValue == "array"{
                        var elementType = propertyValue["items"]["originalRef"].stringValue.classFix
                        if elementType.count == 0 {
                            elementType = propertyValue["items"]["type"].stringValue.typeFix
                        }
                        if elementType.count == 0 { elementType = "Any" }
                        str += """
                            public var \(keyFix):[\(elementType)] = []

                        """
                    }
                    else {
                        var elementType = propertyValue["originalRef"].stringValue.classFix
                        if elementType.count == 0 {
                            elementType = propertyValue["type"].stringValue.typeFix
                        }
                        if elementType.count == 0 || elementType == "object" {
                            elementType = "Any"
                        }
                        str += """
                            public var \(keyFix):\(elementType)?

                        """
                    }
                }
                
                str += """

                    required convenience init(json:SKJSON) {
                        self.init()

                """
                
                for (_,propertyKey) in pKeys.enumerated(){
                    let propertyValue = value["properties"][propertyKey]
                    let keyFix = propertyKey.keyFix
                    if propertyValue["type"].stringValue == "array"{
                        var elementType = propertyValue["items"]["originalRef"].stringValue.classFix
                        if elementType.count > 0 {
                            str += """
                                    for value in json["\(keyFix)"].arrayValue{
                                        \(keyFix).append(\(elementType)(json: value))
                                    }

                            """
                        }
                        else {
                            elementType = propertyValue["items"]["type"].stringValue.jsonValueFix
                            if (elementType.count > 0){
                                str += """
                                    for value in json["\(keyFix)"].arrayValue{
                                        \(keyFix).append(value.\(elementType))
                                    }

                            """
                            }else{
                                str += """
                                    //\(keyFix) = json["\(keyFix)"]//解析缺陷

                            """
                                print("解析缺陷位置 ： ",className,keyFix)
                            }
                        }
                    }
                    else {
                        var elementType = propertyValue["originalRef"].stringValue.classFix
                        if elementType.count > 0 {
                            str += """
                                    \(keyFix) = \(elementType)(json:json["\(keyFix)"])

                            """
                        }
                        else{
                            elementType = propertyValue["type"].stringValue.jsonValueFix
                            str += """
                                    \(keyFix) = json["\(keyFix)"].\(elementType)

                            """
                            
                            if elementType == propertyValue["type"].stringValue {
                                print("解析缺陷位置 ： ",className,keyFix)
                            }
                        }
                    }
                }
                
                str += """
                    }
                }
                """
            }else{
                str.newLine()
                str += """
                public typealias \(className) = \(type.typeFix)
                """
            }
        }

        //写入文件 AppURLDefines
        let data1 = str.data(using: .utf8)
        data1?.saveToPath(path: documentPath + "/AppURLDefines.swift")
        
        
        
        //组装 所有请求
        //预设文件开头
        var rqstr = """
        //
        //  AppRequestDefines.swift
        //
        //
        //  Created by SwaggerGenerator on \(Date().stringWith(format: .yyyy_MM_ddHHmmssSSS))
        //


        import Foundation
        import SightKit

        func sgRequest(item:SGCommonUrlProtocol,result:@escaping ((SKResult)->Void)){
            let rq = SKRq().wUrl(hostUrl + item.url).wMethod(item.method)
            for element in item.paramMap.values {
                if let value = element.value , let  position = SKParamPosition.init(rawValue:element.paramPosition.rawValue) {
                    rq.wParam(key: element.name, value: value, position: position)
                }
            }
            rq.resume(result)
        }

        """
        for (_,path) in self.pathArray.enumerated(){
            rqstr += """

            public extension SGUrl.\(path.className) {
                static func rq(
            """
            
            for (_,param) in path.paramMap.enumerated(){
                rqstr += "\(param.name):\(param.typeStr)?,"
            }
            
            rqstr += "result:@escaping ((SKResult)->Void)"
            
            rqstr += "){"
            rqstr += """
                    
                    let item = SGUrl.\(path.className)()
            """
            for (_,param) in path.paramMap.enumerated(){
                rqstr += """

                    item.paramMap["\(param.name)"]?.value = \(param.name)
            """
            }
            rqstr += """

                    sgRequest(item: item, result: result)
                }
            }
            """
        }
        
        //写入文件 AppURLDefines
        let data2 = rqstr.data(using: .utf8)
        data2?.saveToPath(path: documentPath + "/AppRequestDefines.swift")

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

/** 参数处理方式（where to put the parameter
 ## 使用示例
 ```
 path, e.g. /users/{id};
 query, e.g. /users?role=admin;
 header, e.g. X-MyHeader: Value;
 cookie, e.g. Cookie: debug=0;
*/
public enum SGParamPosition {
    case inBody,inQuery,inPath,inHeader
}

public struct SGParamItem{
    public var name:String = ""
    public var typeStr:String = "String"
    public var paramPosition:SGParamPosition = .inBody
    public var isRequired = false
    public var value:Any? = nil
}

public class SGResponseItem: NSObject {
    public enum CodingKeys: String, CodingKey {
        case description_str = "description"
    }
}



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
        if (self == "number"){
            return "Float"
        }
        if (self == "object"){
            return "Any"
        }
        return self
    }
    var jsonValueFix:String {
        if (self == "string"){
            return "stringValue"
        }
        if (self == "integer"){
            return "intValue"
        }
        if (self == "array"){
            return "arrayValue"
        }
        if (self == "number"){
            return "floatValue"
        }
        return self
    }
}

extension String {
    var keyFix:String {
        if (self == "description") {
            return "description_str"
        }
        return self
    }
}

extension String {
    var defaultValue:String {
        if (self == "String"){
            return ""
        }
        if (self == "Int"){
            return "0"
        }
        if (self == "Array"){
            return "[]"
        }
        if (self == "Float"){
            return "0"
        }
        return self
    }
}

extension String {
    var classFix:String {
        //  获取类名的修正，例如： "originalRef":"CommonPage«AgCommission»", 修正为类名 CommonPage_AgCommission
        //  特殊样例 : "CommonResult«Map«string,object»»"
        return self.replacingOccurrences(of: "«", with: "_").replacingOccurrences(of: "»", with: "").replacingOccurrences(of: ",", with: "_")
    }
}
