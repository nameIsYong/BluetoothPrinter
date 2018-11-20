//
//  BaseManager.swift
//  WorldDoctor
//
//  Created by administrator on 2018/9/5.
//  Copyright © 2018年 CxDtreeg. All rights reserved.
//

import UIKit
import CoreBluetooth

class BaseManager: NSObject {
    
    var command = Printer()
    var manager: CBCentralManager!
    var currentPeripheral:CBPeripheral?
    var writeCharacteristic: CBCharacteristic!
    var readCharacteristic: CBCharacteristic!
    var currentServiceUUID: String?
    var currentWriteUUID: String?
    var currentScanName: String?
    let serviceId = "49535343-FE7D-4AE5-8FA9-9FAFD205E455"
    let WriteUUID = "49535343-8841-43F4-A8D4-ECBE34729BB3"
    
    override init() {
        super.init()
        self.manager = CBCentralManager(delegate: nil, queue: nil)
        self.manager.delegate = self;
    }
    
    func connectPrinter() {
        
        currentServiceUUID = serviceId
        currentWriteUUID = WriteUUID
        currentScanName = "Printer"
        manager.scanForPeripherals(withServices: nil, options: nil)
    }
    
}

extension BaseManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        var message = "";
        switch central.state {
        case .unknown:
            message = "蓝牙系统错误"
        case .resetting:
            message = "请重新开启手机蓝牙"
        case .unsupported:
            message = "该手机不支持蓝牙"
        case .unauthorized:
            message = "蓝牙验证失败"
        case .poweredOff://蓝牙没开启，直接到设置
            message = "蓝牙没有开启"
            
        case .poweredOn:
            central.scanForPeripherals(withServices: nil, options: nil)
        }
        print(message)
    }
    
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("设备名-->"+(peripheral.name ?? ""))
        let peripheralName = peripheral.name ?? ""
        let contains = (self.currentScanName != nil) && peripheralName.contains(self.currentScanName!)
        
        if contains {
            currentPeripheral = peripheral
            central.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        central.stopScan()
        
        //蓝牙连接成功
        if currentPeripheral != nil {
            currentPeripheral!.delegate = self
            currentPeripheral!.discoverServices([CBUUID(string: self.currentServiceUUID!)])
        }
        
    }
}
extension BaseManager: CBPeripheralDelegate {
    //发现服务
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("当前currentServiceUUID-->"+(self.currentServiceUUID ?? ""))
        for service in peripheral.services! {
            print("寻找服务，服务有：\(service)"+"   id-->"+service.uuid.uuidString)
            if service.uuid.uuidString == self.currentServiceUUID {
                peripheral.discoverCharacteristics(nil, for: service)
                print("找到当前服务了。。。。")
                break
            }
        }
    }
    
    //发现特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            print("特征有\(characteristic)")
            
            if characteristic.uuid.uuidString == self.currentWriteUUID {
                self.writeCharacteristic = characteristic
                print("-找到了写服务----\(characteristic)")
            }
        }
    }
    
    ///发送指令给打印机
    private func send(value:Data) {
        
        currentPeripheral!.writeValue(value, for: writeCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    ///打印文字
    func printText(_ str:String) {
        
        let enc = CFStringConvertEncodingToNSStringEncoding(UInt32(CFStringEncodings.GB_18030_2000.rawValue))
        
        ///这里一定要GB_18030_2000，测试过用utf-系列是乱码，踩坑了。
        let data = str.data(using: String.Encoding(rawValue: enc), allowLossyConversion: false)
        if data != nil{
            sendCommand(data!)
        }
    }
    ///发送指令
    func sendCommand(_ data:Data) {
        send(value: data)
    }
    
    ///测试打印
    func testPrint() {
        sendCommand(command.clear())
        sendCommand(command.mergerPaper())
        sendCommand(command.alignCenter())
        printText("------------------")
        sendCommand(command.nextLine(number: 1))
        sendCommand(command.alignCenter())
        sendCommand(command.nextLine(number: 1))
        printText("这是测试标题OK?")
        sendCommand(command.alignLeft())
        printText("血糖:")
        sendCommand(command.alignRight())
        printText("90")
        sendCommand(command.alignLeft())
        printText("THIS IS CONTENT大了就发的垃圾发来得及发链接发的垃圾发的垃圾发链接发的垃圾发链接")
    }
}


///这个类参考的 https://blog.csdn.net/a214024475/article/details/52996047 ，向大神致敬。
class Printer
{
    ///一行最多打印字符个数
    let kRowMaxLength = 32
    
    let ESC:UInt8 = 27//换码
    let FS:UInt8 = 28//文本分隔符
    let GS:UInt8 = 29//组分隔符
    let DLE:UInt8 = 16//数据连接换码
    let EOT:UInt8 = 4//传输结束
    let ENQ:UInt8 = 5//询问字符
    let SP:UInt8 = 32//空格
    let HT:UInt8 = 9//横向列表
    let LF:UInt8 = 10//打印并换行（水平定位）
    let CR:UInt8 = 13//归位键
    let FF:UInt8 = 12//走纸控制（打印并回到标准模式（在页模式下） ）
    
    
    ///初始化打印机
    func clear() -> Data {
        return Data.init(bytes:[ESC, 64])
    }
    
    ///打印空格
    func printBlank(number:Int) -> Data {
        var foo:[UInt8] = []
        for _ in 0..<number {
            foo.append(SP)
        }
        return Data.init(bytes:foo)
    }
    
    ///换行
    func nextLine(number:Int) -> Data {
        var foo:[UInt8] = []
        for _ in 0..<number {
            foo.append(LF)
        }
        return Data.init(bytes:foo)
    }
    
    ///绘制下划线
    func printUnderline() -> Data {
        var foo:[UInt8] = []
        foo.append(ESC)
        foo.append(45)
        foo.append(1)//一个像素
        return Data.init(bytes:foo)
    }
    
    ///取消绘制下划线
    func cancelUnderline() -> Data {
        var foo:[UInt8] = []
        foo.append(ESC)
        foo.append(45)
        foo.append(0)
        return Data.init(bytes:foo)
    }
    
    ///加粗文字
    func boldOn() -> Data {
        var foo:[UInt8] = []
        foo.append(ESC)
        foo.append(69)
        foo.append(0xF)
        return Data.init(bytes:foo)
    }
    
    ///取消加粗
    func boldOff() -> Data {
        var foo:[UInt8] = []
        foo.append(ESC)
        foo.append(69)
        foo.append(0)
        return Data.init(bytes:foo)
    }
    
    ///左对齐
    func alignLeft() -> Data {
        return Data.init(bytes:[ESC,97,0])
    }
    
    ///居中对齐
    func alignCenter() -> Data {
        return Data.init(bytes:[ESC,97,1])
    }
    
    ///右对齐
    func alignRight() -> Data {
        return Data.init(bytes:[ESC,97,2])
    }
    
    ///水平方向向右移动col列
    func alignRight(col:UInt8) -> Data {
        var foo:[UInt8] = []
        foo.append(ESC)
        foo.append(68)
        foo.append(col)
        foo.append(0)
        return Data.init(bytes:foo)
    }
    
    ///字体变大为标准的n倍
    func fontSize(font:Int8) -> Data {
        var realSize:UInt8 = 0
        switch font {
        case 1:
            realSize = 0
        case 2:
            realSize = 17
        case 3:
            realSize = 34
        case 4:
            realSize = 51
        case 5:
            realSize = 68
        case 6:
            realSize = 85
        case 7:
            realSize = 102
        case 8:
            realSize = 119
        default:
            break
        }
        var foo:[UInt8] = []
        foo.append(GS)
        foo.append(33)
        foo.append(realSize)
        return Data.init(bytes:foo)
    }
    
    ///进纸并全部切割
    func feedPaperCutAll() -> Data {
        var foo:[UInt8] = []
        foo.append(GS)
        foo.append(86)
        foo.append(65)
        foo.append(0)
        return Data.init(bytes:foo)
    }
    
    ///进纸并切割（左边留一点不切）
    func feedPaperCutPartial() -> Data {
        var foo:[UInt8] = []
        foo.append(GS)
        foo.append(86)
        foo.append(66)
        foo.append(0)
        return Data.init(bytes:foo)
    }
    
    ///设置纸张间距为默认
    func mergerPaper() -> Data {
        return Data.init(bytes:[ESC,109])
    }
}















