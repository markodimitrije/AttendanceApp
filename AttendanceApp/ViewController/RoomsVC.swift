//
//  ViewController.swift
//  tryObservableWebApiAndRealm
//
//  Created by Marko Dimitrijevic on 19/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Realm
import RealmSwift
import RxRealmDataSources

class RoomsVC: UIViewController {    

    @IBOutlet weak var tableView: UITableView!
    
    let disposeBag = DisposeBag()
    
    let roomViewModel = RoomViewModel()
    
    fileprivate let selRealmRoom = PublishSubject<Room?>()
    
    var selectedRealmRoom: Observable<Room?> { // exposed selectedRoomId
        return selRealmRoom.asObservable()
    }
    
    var selRoomDriver: SharedSequence<DriverSharingStrategy, Room?> {
        return selectedRealmRoom.asDriver(onErrorJustReturn: nil)
    }

    override func viewDidLoad() { super.viewDidLoad()
        bindUI()
    }

    private func bindUI() {
        // bind dataSource
        let dataSource = RxTableViewRealmDataSource<RealmRoom>(cellIdentifier:
        "cell", cellType: UITableViewCell.self) { cell, _, rRoom in
            cell.textLabel?.text = rRoom.name
        }
        
        roomViewModel.oRooms
            .bind(to: tableView.rx.realmChanges(dataSource))
            .disposed(by: disposeBag)
        
    }
    
}

extension RoomsVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // neka ti roomViewModel samo izracuna pa ti vrati settingsVC-u !
        
        let selectedRoom = roomViewModel.getRoom(forSelectedTableIndex: indexPath.item)
        
        settingsJourney.roomId = selectedRoom.id
        
        selRealmRoom.onNext(selectedRoom)
        
        navigationController?.popViewController(animated: true)
        
    }
}
