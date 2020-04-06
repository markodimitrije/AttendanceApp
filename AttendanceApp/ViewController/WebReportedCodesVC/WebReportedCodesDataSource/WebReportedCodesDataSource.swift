//
//  WebReportedCodesDataSource.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 06/04/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

import UIKit
import RxSwift

class WebReportedCodesDataSource: NSObject, UITableViewDataSource {
    
    private var data = [CodeReportCellModel]() {
        didSet {
            self.tableView.reloadData()
        }
    } // hooked with realm in func: "hookUpDataFromRealm"
    
    private let tableView: UITableView
    private let repository: ICodeReportsRepository
    init(tableView: UITableView, repository: ICodeReportsRepository) {
        self.tableView = tableView
        self.repository = repository
        super.init()
        self.hookUpDataFromRealm()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = "code= \(data[indexPath.row].code)" + " acc= \(data[indexPath.row].accepted)" + " synced= \(data[indexPath.row].reported)"
        return cell
    }
    
    private func hookUpDataFromRealm() {
        
        self.repository.getObsCodeReports()
            .subscribeOn(MainScheduler.init())
            .subscribe(onNext: { [weak self] array in
            guard let sSelf = self else {return}
//                let reports = array.sorted(by: { (rCode1, rCode2) -> Bool in
//                    return (rCode1.getDate()) > (rCode2.getDate())
//                })
                let reports = array.sorted(by: { $0.getDate() > $1.getDate() })
                sSelf.data = reports.map(CodeReportCellModelFactory.make)
            })
            .disposed(by: bag)
    }
    
    private let bag = DisposeBag()
}
