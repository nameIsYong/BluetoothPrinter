//
//  ViewController.swift
//  BluethPrint
//
//  Created by administrator on 2018/11/19.
//  Copyright © 2018 administrator. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    var mamager:BaseManager?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if mamager == nil{
            mamager = BaseManager()
            mamager!.connectPrinter()
        }else{
            mamager!.testPrint()
        }
    }

}

