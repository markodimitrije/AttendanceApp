//
//  BlocksVC.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 20/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Realm
import RealmSwift
import RxRealmDataSources
import RxDataSources // ovaj ima rx Sectioned TableView

class BlocksVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var selectedRoomId: Int! // ovo ce ti setovati segue // moze li preko Observable ?
    
    lazy var blockViewModel = BlockViewModel(roomId: selectedRoomId)
    
    fileprivate let selBlock = PublishSubject<Block>()
    var selectedBlock: Observable<Block> { // exposed selRealmBlock
        return selBlock.asObservable()
    }
    
    var selectedInterval = BehaviorRelay.init(value: MyTimeInterval.waitToMostRecentSession)
    
    override func viewDidLoad() { super.viewDidLoad()
        bindUI()
        navigationItem.title = "SESSIONS"
    }
    
    private func bindUI() {
        
        let dataSource = RxTableViewSectionedReloadDataSource<SectionOfCustomData>(
            configureCell: { dataSource, tableView, indexPath, item in
                let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
                cell.textLabel?.text = item
                return cell
        })
        
        dataSource.titleForHeaderInSection = { dataSource, index in
            return dataSource.sectionModels[index].header
        }
        
        blockViewModel.oSectionsHeadersAndItems
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        // tableView didSelect
        tableView.rx.itemSelected // (**)
            .subscribe(onNext: { [weak self] ip in
                guard let strongSelf = self else {return}
                let rBlock = strongSelf.blockViewModel.sectionBlocks[ip.section][ip.row]
                let selectedBlock = Block(with: rBlock)
                strongSelf.selBlock.onNext(selectedBlock)
                strongSelf.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        
        blockViewModel.oAutoSelSessInterval
            .asObservable()
            .subscribe(onNext: { [weak self] seconds in
                guard let sSelf = self else {return}
                sSelf.selectedInterval.accept(seconds)
            })
            .disposed(by: disposeBag)
    }
    
    private let disposeBag = DisposeBag()
    
}
