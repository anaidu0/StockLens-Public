//
//  SheetController.swift
//  StockLens
//
//  Created by viget on 6/15/19.
//  Copyright © 2019 Anirudh Naidu. All rights reserved.
//

import UIKit

class SheetController: UIViewController {
    
    var company:String = ""
    var ticker:String = ""
    var price:String = ""
    var change:String = ""
    
    @IBOutlet weak var companyLabel:UILabel?
    @IBOutlet weak var tickerLabel:UILabel?
    @IBOutlet weak var priceLabel:UILabel?
    @IBOutlet weak var changeLabel:UILabel?
    @IBOutlet weak var searchButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        companyLabel?.text = company
        tickerLabel?.text = ticker
        priceLabel?.text = price
        changeLabel?.text = change
        changeLabel?.textColor = change.range(of: "-") != nil ? .red : betterGreen() //red or green depending on whether change is positive or negative

        // Do any additional setup after loading the view.
    }
    
    @IBAction func searchWeb(_ sender: Any) {
        guard let url = URL(string: "http://www.google.com/search?q=" + company + "+stock") else { return }
        UIApplication.shared.open(url)
    }
    
    private func betterGreen() -> UIColor{
        let green = UIColor.init(red: 77.0/255.0, green: 168.0/255.0, blue: 92.0/255.0, alpha: 1.0)
        return green
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
