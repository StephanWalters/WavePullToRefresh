//
//  WavePullToRefreshView.swift
//  WavePullToRefresh
//
//  Created by Daisuke Kobayashi on 2016/02/18.
//  (C) 2016 RECRUIT LIFESTYLE CO., LTD.
//

import UIKit
import WavePullToRefresh

class ViewController: UIViewController {
    
    // MARK:- Properties
    fileprivate var items = (0...10).map{ "test\($0)" }
    
    @IBOutlet weak var tableView: UITableView?
    
    // MARK:- Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 106/255, green: 172/255, blue: 184/255, alpha: 1)
        
        self.tableView?.dataSource = self
        
        self.tableView!.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        let options = WavePullToRefreshOption()
        options.fillColor = UIColor(red: 106/255, green: 172/255, blue: 184/255, alpha: 1).cgColor
        
        // add pull to refresh
        self.tableView!.addPullToRefresh(options: options) { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {
                guard let s = self else { return }
                s.items.shuffleInPlace()
                s.tableView?.reloadData()
                s.tableView?.stopPullToRefresh()
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: UITableViewDataSource {
    // MARK:- Internal Methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        if let textLabel = cell.textLabel {
            textLabel.text = "\(items[indexPath.row])"
        }
        
        return cell
    }
}
