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
                let array = itemName.components(separatedBy: "/{")
                if array.count >= 2 {
                    itemName = array.first!
                }
                
                itemName = itemName.replacingOccurrences(of: "/", with: "_")
                itemName = itemName+"_"+methodItem.method


            }
        }
    }
    func makeModelFile(){
        
    }
    func makeRequestFile(){
        
    }
}

