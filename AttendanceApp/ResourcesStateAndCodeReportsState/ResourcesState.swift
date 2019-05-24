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
    
    private var downloads = PublishSubject<Bool>.init()
    
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
            .take(2) // room API and blocks API
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
        // MOCK
        //fetchRoomsAndSaveToRealmMOCK()
        //fetchSessionsAndSaveToRealmMOCK()
        
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
                                                     with_trashed: 0)
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
        
        let oDelegates = DelegatesAPIController.shared.getDelegates()
        oDelegates
            .subscribe(onNext: { [weak self] (delegates) in
                
                guard let strongSelf = self,
                    delegates.count > 0 else {return} // valid

                print("delegates = \(delegates)")
//                RealmDataPersister.shared.deleteAllObjects(ofTypes: [RealmBlock.self])
//                    .subscribe(onNext: { (success) in
//
//                        if success {
//
//                            RealmDataPersister.shared.save(blocks: delegates)
//                                .subscribe(onNext: { (success) in
//
//                                    strongSelf.downloads.onNext(success)
//
//                                })
//                                .disposed(by: strongSelf.bag)
//                        }
//
//                    }).disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
    }
    
    // MOCK
    /*
    private func fetchRoomsAndSaveToRealmMOCK() { // print("fetchRoomsAndSaveToRealm is called")
        
        let filename = getFilenameToReadRoomJsonDataFrom()
        
        guard let jsonSessions = JsonFromBundleParser.readJSONFromFile(fileName: filename) as? [String: Any],
            let sessions = jsonSessions["data"] as? [[String: Any]] else {fatalError("no sessions!!")}
        
        let rooms = sessions.map { (roomDict) -> Room in
            let data = try! JSONSerialization.data(withJSONObject: roomDict, options: .prettyPrinted)
            let decoder = JSONDecoder.init()
            guard let block = try? decoder.decode(Room.self, from: data) else {
                fatalError("cant convert....")
            }
            return block
        }
        
        guard rooms.count > 0 else { fatalError("rooms received == 0 !") }
        
        RealmDataPersister.shared.deleteAllObjects(ofTypes: [RealmRoom.self])
            .subscribe(onNext: { (success) in
                
                if success {
                    
                    RealmDataPersister.shared.save(rooms: rooms)
                        .subscribe(onNext: { (success) in
                            
                            self.downloads.onNext(success)
                            
                        })
                        .disposed(by: self.bag)
                }
                
            }).disposed(by: self.bag)
        
    } // hard coded off for testing
    
    private func fetchSessionsAndSaveToRealmMOCK() { // print("fetchSessionsAndSaveToRealm is called")
        
        let filename = getFilenameToReadBlockJsonDataFrom()
        
        guard let jsonSessions = JsonFromBundleParser.readJSONFromFile(fileName: filename) as? [String: Any],
            let sessions = jsonSessions["data"] as? [[String: Any]] else {fatalError("no sessions!!")}
        
        let blocks = sessions.map { (blockDict) -> Block in
            let data = try! JSONSerialization.data(withJSONObject: blockDict, options: .prettyPrinted)
            let decoder = JSONDecoder.init()
            guard let block = try? decoder.decode(Block.self, from: data) else {
                fatalError("cant convert....")
            }
            return block
        }
        
        guard blocks.count > 0 else { fatalError("blocks received == 0 !") }
        
        RealmDataPersister.shared.deleteAllObjects(ofTypes: [RealmBlock.self])
            .subscribe(onNext: { (success) in
                
                if success {
                    
                    RealmDataPersister.shared.save(blocks: blocks)
                        .subscribe(onNext: { (success) in
                            
                            self.downloads.onNext(success)
                            
                        })
                        .disposed(by: self.bag)
                }
                
            }).disposed(by: bag)
    }
    */
    
    
    deinit {
        print("ResourcesState.deinit is called")
    }
    
}

// MOCK
// mock block - test auto sync after update from web
/*
func getFilenameToReadBlockJsonDataFrom() -> String {
    guard let savedFilename = UserDefaults.standard.value(forKey: "jsonDataBundleBlocks") as? String else {
        UserDefaults.standard.setValue("cities", forKey: "jsonDataBundleBlocks")
        return "cities"
    }
    if savedFilename == "cities" {
        UserDefaults.standard.setValue("citiesUpdated", forKey: "jsonDataBundleBlocks")
        return "citiesUpdated"
    } else {
        UserDefaults.standard.setValue("cities", forKey: "jsonDataBundleBlocks")
        return "cities"
    }
}

func getFilenameToReadRoomJsonDataFrom() -> String {
    guard let savedFilename = UserDefaults.standard.value(forKey: "jsonDataBundleRooms") as? String else {
        UserDefaults.standard.setValue("rooms", forKey: "jsonDataBundleRooms")
        return "rooms"
    }
    if savedFilename == "rooms" {
        UserDefaults.standard.setValue("roomsUpdated", forKey: "jsonDataBundleRooms")
        return "roomsUpdated"
    } else {
        UserDefaults.standard.setValue("rooms", forKey: "jsonDataBundleRooms")
        return "rooms"
    }
}
*/
