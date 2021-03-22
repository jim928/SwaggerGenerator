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

    var tableview:NSTableView!
    var textField:NSTextField!
    var panel:NSOpenPanel = NSOpenPanel()
    var pathArray:[(className:String,url:String,method:String,paramMap:[SGParamItem])] = []
    var jsonModel:SGModel!
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
        
        self.jsonModel = SGModel(json: json)
        
        makeUrlFile()
        makeModelFile()
        makeRequestFile()
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

    func makeUrlFile(){
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
        var host = self.jsonModel.host ?? ""
        if !host.hasPrefix("http://"){
            host = "http://" + host
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
        for pathItem in self.jsonModel.paths {
            for methodItem in pathItem.methods {
                //类名
                var itemName = String(format: "%@", pathItem.path)
                if itemName.hasPrefix("/") {
                    itemName = String(itemName.suffix(itemName.count-1))
                }
                
                //处理样例 "/brand/detail/{brandId}"
                itemName = itemName.replacingOccurrences(of: "/{", with: "_").replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "}", with: "")
                itemName = itemName+"_"+methodItem.method

                //summary
                var desStr = methodItem.summary ?? "";
                if (methodItem.tags.count > 0){
                    desStr += "  ("
                    for tag in methodItem.tags {
                        for (name,des) in self.jsonModel.tags {
                            if tag == name {
                                desStr += des + ","
                            }
                        }
                    }
                    if desStr.hasSuffix(",") {
                        desStr = desStr.subString(from: 0, length: desStr.count-2)
                    }
                    desStr += ")"
                }
                
                //参数说明
                str.newLine(2)
                let params = methodItem.parameters
                if (params.count > 0){
                    str += """
                    /** \(desStr)
                    ## 参数说明
                    ```
                """
                    str.newLine()
                    
                    for paramItem in params {
                        str.addSpace(1)
                        str += "   \(paramItem.name.orEmpty):\(paramItem.type.orEmpty.typeFix)"
                        if paramItem.required.orFalse {
                            str += " required"
                        }
                        if paramItem.default != nil {
                            str += " default:\(paramItem.default!)"
                        }
                        if paramItem.description.orEmpty.count > 0 {
                            str += " " + paramItem.description.orEmpty
                        }
                        str.newLine()
                    }
                    str += """
                        */
                    """
                }else{
                    str += "    /// \(desStr)"
                }

                //类
                str += """

                        public class \(itemName):SGCommonUrlProtocol {
                            public var url = "\(pathItem.path)"
                            public var method = "\(methodItem.method)"
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
                        
                        let isRequiredStr = paramItem.required.orFalse ? "true" : "false"
                        let isRequired = paramItem.required.orFalse
                        
                        if (paramItem.in.orEmpty == "query") {
                            positionStr = ".inQuery"
                            position = .inQuery
                        }
                        if (paramItem.in.orEmpty == "path") {
                            positionStr = ".inPath"
                            position = .inPath
                        }
                        if (paramItem.in.orEmpty == "header") {
                            positionStr = ".header"
                            position = .inHeader
                        }
                        
                        var elementType = paramItem.schema?.originalRef.orEmpty.classFix ?? ""
                        if elementType.count == 0 {
                            if paramItem.type.orEmpty == "array" {
                                elementType = "[\((paramItem.items?.type).orEmpty.typeFix)]"
                            }else{
                                elementType = paramItem.type.orEmpty.typeFix
                                
                                if elementType == "ref"{
                                    elementType = "Int"
                                }
                            }
                        }
                        if elementType.count == 0 || elementType == "object" {
                            elementType = "Any"
                        }

                        
                        str += """
                                    "\(paramItem.name.orEmpty)":SGParamItem(name: "\(paramItem.name.orEmpty)", typeStr: "\(elementType)", paramPosition: \(positionStr), isRequired: \(isRequiredStr), value: nil),
                        """
                        
                        paramsArray.append(SGParamItem(name: paramItem.name.orEmpty, typeStr: elementType, paramPosition: position, isRequired: isRequired, value: nil))
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
                
                self.pathArray.append((className: itemName, url: pathItem.path, method: methodItem.method, paramMap: paramsArray))

            }
        }
        
        str += """


            }
            """

        //写入文件 AppURLDefines
        let data1 = str.data(using: .utf8)
        data1?.saveToPath(path: documentPath + "/AppURLDefines.swift")
    }
    func makeModelFile(){
        //数据model
        var str = """
        //
        //  AppModelDefines.swift
        //
        //
        //  Created by SwaggerGenerator on \(Date().stringWith(format: .yyyy_MM_ddHHmmssSSS))
        //


        import Foundation
        import SightKit

        """

        for define in self.jsonModel.definitions {
            let className = define.title.orEmpty.classFix
            let type = define.type.orEmpty
            if type == "object" {
                str += """

                public class \(className): SGResponseItem {

                """
                
                for property in define.properties {
                    let propertyDes = property.description.orEmpty
                    if propertyDes.count > 0 {
                        str += """
                            /// \(propertyDes)

                        """
                    }
                    let keyFix = property.name.orEmpty.keyFix
                    if property.type.orEmpty == "array"{
                        var elementType = (property.items?.originalRef).orEmpty.classFix
                        if elementType.count == 0 {
                            elementType = (property.items?.type).orEmpty.typeFix
                        }
                        if elementType.count == 0 { elementType = "Any" }
                        str += """
                            public var \(keyFix):[\(elementType)] = []

                        """
                    }
                    else {
                        var elementType = property.originalRef.orEmpty.classFix
                        if elementType.count == 0 {
                            elementType = property.type.orEmpty.typeFix
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
                
                for property in define.properties {
                    let keyFix = property.name.orEmpty.keyFix
                    if property.type.orEmpty == "array"{
                        var elementType = (property.items?.originalRef).orEmpty.classFix
                        if elementType.count > 0 {
                            str += """
                                    for value in json["\(keyFix)"].arrayValue{
                                        \(keyFix).append(\(elementType)(json: value))
                                    }

                            """
                        }
                        else {
                            elementType = (property.items?.type).orEmpty.jsonValueFix
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
                        var elementType = property.originalRef.orEmpty.classFix
                        if elementType.count > 0 {
                            str += """
                                    \(keyFix) = \(elementType)(json:json["\(keyFix)"])

                            """
                        }
                        else{
                            elementType = property.type.orEmpty.jsonValueFix
                            str += """
                                    \(keyFix) = json["\(keyFix)"].\(elementType)

                            """
                            
                            if elementType == property.type.orEmpty {
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
        data1?.saveToPath(path: documentPath + "/AppModelDefines.swift")
    }
    func makeRequestFile(){
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
                    #warning("todo value 可能是 自定义对象 待处理")
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
}

