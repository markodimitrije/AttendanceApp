//
//  Logic.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 30/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RealmSwift
import Realm

class ResourcesState {
    
    var resourcesDownloaded: Bool? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaults.keyResourcesDownloaded) as? Bool
        }
        set {
            UserDefaults.standard.set(true, forKey: UserDefaults.keyResourcesDownloaded)
        }
    }
    
    var shouldDownloadResources: Bool {
//        if resourcesDownloaded == nil || resourcesDownloaded == false {
//            return true
//        } else {
//            return false
//        }
        return true // hard-coded
    }
    
    var oAppDidBecomeActive = BehaviorSubject<Void>.init(value: ())
    
    private var timer: Timer?
    
    private let bag = DisposeBag()
    
    private var downloads = PublishSubject<Bool>.init() // refactor u tuple or dict ["blocks": true, "rooms": false]...
    
    init() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.appWillEnterBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil)
        
        downloads
            .take(3) // room API and blocks API
            .reduce(true) { (sum, last) -> Bool in
                sum && last
            }
            .subscribe(onNext: { [weak self] success in
                guard let sSelf = self else {return}
                sSelf.resourcesDownloaded = success
//                sSelf.timer?.invalidate() hard-coded (there is no silent notification to force download resources)
                // thats why timer should be always alive, to force download resources every 30 min for example
                
            })
            .disposed(by: bag)
        
    }
    
    @objc private func appDidBecomeActive() { // print("ResourcesState/ appDidBecomeActive/ appDidBecomeActive is called")
        
        oAppDidBecomeActive.onNext(())
        
        downloadResources()
        
    }
    
    private func downloadResources() {
        
        if shouldDownloadResources {
            
            fetchResourcesFromWeb()
            
            if timer == nil {
                
                timer = Timer.scheduledTimer(
                    timeInterval: MyTimeInterval.timerForFetchingRoomAndBlockResources,
                    target: self,
                    selector: #selector(ResourcesState.fetchResourcesFromWeb),
                    userInfo: nil,
                    repeats: true)
            } else {
                print("else - leave fetching loop, timer != nil ?!??!?!??!?!")
            }
        }
        
    }
    
    @objc private func appWillEnterBackground() {// print("ResourcesState/ appWillEnterForeground is called")
        
        timer?.invalidate()
    }
    
    @objc private func fetchResourcesFromWeb() { // print("fetchRoomsAndBlocksResources is called")
        
        print("ResourceState.fetchRoomsAndBlocksResources is called, date = \(Date.now)")
        
        fetchRoomsAndSaveToRealm()
        fetchSessionsAndSaveToRealm()
        fetchDelegatesAndSaveToRealm()
        
    }
    
    private func fetchRoomsAndSaveToRealm() { // print("fetchRoomsAndSaveToRealm is called")
        
        let oRooms = ApiController.shared.getRooms(updated_from: nil,
                                                   with_pagination: 0,
                                                   with_trashed: 0)
        oRooms
            .subscribe(onNext: { [ weak self] (rooms) in
                
                guard let strongSelf = self,
                    rooms.count > 0 else {return} // valid
                
                RealmDataPersister.shared.deleteAllObjects(ofTypes: [RealmRoom.self])
                    .subscribe(onNext: { (success) in
    
                        if success {
                            
                            RealmDataPersister.shared.save(rooms: rooms)
                                .subscribe(onNext: { (success) in
                                    
                                    strongSelf.downloads.onNext(success)
                                    
                                })
                                .disposed(by: strongSelf.bag)
                        }
                        
                }).disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
        
    } // hard coded off for testing
    
    private func fetchSessionsAndSaveToRealm() { // print("fetchSessionsAndSaveToRealm is called")
        
        let oBlocks = ApiController.shared.getBlocks(updated_from: nil,
                                                     with_pagination: 0,
                                                     with_trashed: 0,
                                                     for_scanning: 1)
        oBlocks
            .subscribe(onNext: { [weak self] (blocks) in
                
                guard let strongSelf = self,
                    blocks.count > 0 else {return} // valid
                
                RealmDataPersister.shared.deleteAllObjects(ofTypes: [RealmBlock.self])
                    .subscribe(onNext: { (success) in
                        
                        if success {
                            
                            RealmDataPersister.shared.save(blocks: blocks)
                                .subscribe(onNext: { (success) in
                                    
                                    strongSelf.downloads.onNext(success)
                                    
                                })
                                .disposed(by: strongSelf.bag)
                        }
                        
                    }).disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
    } // hard coded off for testing
    
    private func fetchDelegatesAndSaveToRealm() {
        
        let oNewDelegates = DelegatesAPIController.shared.getDelegates()
        
        let oOldDeleted = RealmDelegatesPersister.shared
            .deleteAllObjects(ofTypes: [RealmDelegate.self])
            .filter {$0}
        
        let result = Observable.combineLatest(oNewDelegates, oOldDeleted) { (delegates, success) -> [Delegate] in
            return success ? delegates : [ ]
        }
        
        result.flatMap(RealmDelegatesPersister.shared.save)
            .subscribe(onNext: { [weak self] delegatesSaved in guard let sSelf = self else {return}
                sSelf.downloads.onNext(delegatesSaved)
            })
            .disposed(by: self.bag)
        
    }
    
    deinit {
        print("ResourcesState.deinit is called")
    }
    
}
