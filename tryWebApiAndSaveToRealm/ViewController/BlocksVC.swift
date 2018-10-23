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
    
    let disposeBag = DisposeBag()
    
    lazy var blockViewModel = BlockViewModel(roomId: selectedRoomId)
    
    fileprivate let selRealmBlock = PublishSubject<RealmBlock>()
    var selectedRealmBlock: Observable<RealmBlock> { // exposed selRealmBlock
        return selRealmBlock.asObservable()
    }
    
    override func viewDidLoad() { super.viewDidLoad()
        bindUI()
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
        
        Observable.just(blockViewModel.sectionsHeadersAndItems) // imas data u svom viewmodel
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        // tableView didSelect
        tableView.rx.itemSelected // (**)
            .subscribe(onNext: { [weak self] ip in
                guard let strongSelf = self else {return}
                let selectedBlock = strongSelf.blockViewModel.blocks[ip.item]
                strongSelf.selRealmBlock.onNext(selectedBlock)
                strongSelf.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
    }

}
