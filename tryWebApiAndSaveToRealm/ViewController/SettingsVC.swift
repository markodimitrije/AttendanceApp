//
//  SettingsVC.swift
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

//class SettingsVC: UIViewController {
class SettingsVC: UITableViewController {

    @IBOutlet weak var roomLbl: UILabel!
    @IBOutlet weak var sessionLbl: UILabel!
    
    @IBOutlet weak var saveSettingsAndExitBtn: UIButton!
    @IBOutlet weak var cancelSettingsBtn: UIBarButtonItem!
    
    let disposeBag = DisposeBag()
    
    // output
    var roomId: Int!
    let roomSelected = PublishSubject<RealmRoom>.init()
    let sessionSelected = PublishSubject<RealmBlock?>.init()
    
    fileprivate let roomViewModel = RoomViewModel()
    //var settingsViewModel = SettingsViewModel(unsyncedConnections: 0)
    lazy var settingsViewModel = SettingsViewModel(unsyncedConnections: 0, saveSettings: saveSettingsAndExitBtn.rx.controlEvent(.touchUpInside), cancelSettings: cancelSettingsBtn.rx.tap)
    
    override func viewDidLoad() { super.viewDidLoad()
        bindUI()
        bindControlEvents()
    }
    
    private func bindUI() { // glue code for selected Room
        
        roomSelected // ROOM
            .map { $0.name }
            .bind(to: roomLbl.rx.text)
            .disposed(by: disposeBag)

        sessionSelected // SESSION
            .map {
                guard let session = $0 else { return "Select session" }
                return session.starts_at + " " + session.name
            }
            .bind(to: sessionLbl.rx.text)
            .disposed(by: disposeBag)
        
    }
    
    private func bindControlEvents() {
        // ova 2 su INPUT za settingsViewModel - start
        roomSelected
            .subscribe(onNext: { [weak self] (selectedRoom) in
                guard let strongSelf = self else {return}
                strongSelf.settingsViewModel.roomSelected.onNext(selectedRoom)
            })
            .disposed(by: disposeBag)
        
        sessionSelected
            .subscribe(onNext: { [weak self] (sessionSelected) in
                guard let strongSelf = self else {return}
                strongSelf.settingsViewModel.sessionSelected.onNext(sessionSelected)
            })
            .disposed(by: disposeBag)
        // ova 2 su INPUT za settingsViewModel - end
        
        settingsViewModel.shouldCloseSettingsVC
            .subscribe(onNext: {
                if $0 {
                    print("uradi dismiss koji treba....")
                    self.dismiss(animated: true)
                } else {
                    print("prikazi alert da izabere room....")
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        hookUpIfRoomSegue(for: segue, sender: sender)
    
    }
    
    private func hookUpIfRoomSegue(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard let name = segue.identifier, name == "segueShowRooms",
            let roomsVC = segue.destination as? RoomsVC else { return }
        
        roomsVC.selectedRealmRoom
            .subscribe(onNext: { [weak self] (room) in
                guard let strongSelf = self else {return}
                print("room.name is \(room.name)")
                strongSelf.roomId = room.id // sranje, kako izvuci val iz PublishSubj? necu Variable..
                strongSelf.roomSelected.onNext(room)
                strongSelf.sessionSelected.onNext(nil)
            })
            .disposed(by: disposeBag)
        
    }
    
    private func navigateToSessionVCAndSubscribeForSelectedSession(roomId: Int) {
        
        guard let blocksVC = storyboard?.instantiateViewController(withIdentifier: "BlocksVC") as? BlocksVC else {return}
        
        blocksVC.selectedRoomId = roomId
        navigationController?.pushViewController(blocksVC, animated: true)
    
        blocksVC.selectedRealmBlock
            .subscribe(onNext: { [weak self] block in
                guard let strongSelf = self else {return}
                strongSelf.sessionSelected.onNext(block)
            })
            .disposed(by: disposeBag)
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.item) {
        case (0, 0): print("auto segue ka rooms...")
        case (1, 0):
            guard let roomId = roomId else {return}
            navigateToSessionVCAndSubscribeForSelectedSession(roomId: roomId)
        default: break
        }
    }
    
}

enum AnError: Error {
    case sessionNotSelected
}
