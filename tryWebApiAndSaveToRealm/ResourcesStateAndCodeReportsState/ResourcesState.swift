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
        if resourcesDownloaded == nil || resourcesDownloaded == false {
            return true
        } else {
            return false
        }
    }
    
    private var timer: Timer?
    
    private let bag = DisposeBag()
    
    private var downloads = PublishSubject<Bool>.init()
    
    init() {
        
        print("creating ResourcesState")
        
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
                sSelf.timer?.invalidate()
            })
            .disposed(by: bag)
    }
    
    @objc private func appDidBecomeActive() {
        
        print("ResourcesState/ appDidBecomeActive is called")
        
        if shouldDownloadResources {
            
            fetchRoomsAndBlocksResources()
            
            if timer == nil {
                
                timer = Timer.scheduledTimer(
                    timeInterval: TimeInterval.timerForFetchingRoomAndBlockResources,
                    target: self,
                    selector: #selector(ResourcesState.fetchRoomsAndBlocksResources),
                    userInfo: nil,
                    repeats: true)
            }
        }
    }
    
    @objc private func appWillEnterBackground() {
        
        //        print("ResourcesState/ appWillEnterForeground is called")
        
        timer?.invalidate()
        //timer = nil
    }
    
//    @objc private func fetchRoomsAndBlocksResources() {
//
//        //        print("fetchRoomsAndBlocksResources is called")
//
//        RealmDataPersister.shared.deleteDataIfAny()
//            .subscribe(onNext: { [weak self] (realmIsEmpty) in
//
//                guard let strongSelf = self else {return}
//
//                if realmIsEmpty {
//
//                    strongSelf.fetchRoomsAndSaveToRealm()
//                    strongSelf.fetchSessionsAndSaveToRealm()
//                }
//            })
//            .disposed(by: bag)
//
//    }
    
    
    
    @objc private func fetchRoomsAndBlocksResources() {
        
        //        print("fetchRoomsAndBlocksResources is called")
        
        RealmDataPersister.shared.deleteDataIfAny()
            .subscribe(onNext: { [weak self] (realmIsEmpty) in
                
                guard let strongSelf = self else {return}
                
                if realmIsEmpty {
                    
//                    strongSelf.fetchRoomsAndSaveToRealm()
//                    strongSelf.fetchSessionsAndSaveToRealm()
                    strongSelf.fetchRoomsAndSaveToRealm_MOCK() // MOCK
                    strongSelf.fetchSessionsAndSaveToRealm_MOCK() // MOCK
                    
                }
            })
            .disposed(by: bag)
        
    }
    
    
    
    private func fetchRoomsAndSaveToRealm() {
        
        //        print("fetchRoomsAndSaveToRealm is called")
        
        let oRooms = ApiController.shared.getRooms(updated_from: nil,
                                                   with_pagination: 0,
                                                   with_trashed: 0)
        oRooms
            .subscribe(onNext: { [ weak self] (rooms) in
                
                guard let strongSelf = self else {return}
                
                RealmDataPersister.shared.saveToRealm(rooms: rooms)
                    .subscribe(onNext: { (success) in
                        
                        strongSelf.downloads.onNext(success)
                        
                    })
                    .disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
        
    }
    
    private func fetchSessionsAndSaveToRealm() {
        
        //        print("fetchSessionsAndSaveToRealm is called")
        
        let oBlocks = ApiController.shared.getBlocks(updated_from: nil,
                                                     with_pagination: 0,
                                                     with_trashed: 0)
        oBlocks
            .subscribe(onNext: { [weak self] (blocks) in
                
                guard let strongSelf = self else {return}
                
                RealmDataPersister.shared.saveToRealm(blocks: blocks)
                    .subscribe(onNext: { (success) in
                        
                        strongSelf.downloads.onNext(success) // okini na svom observable, njega monitor
                        
                    })
                    .disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
    }
    
    
    
    // TEMP for TESTING
    
    private func fetchRoomsAndSaveToRealm_MOCK() {
        
        print("fetchRoomsAndSaveToRealm_MOCK is called")
        
        let oRooms = ApiController.shared.getRooms(updated_from: nil,
                                                   with_pagination: 0,
                                                   with_trashed: 0)
        oRooms
            .subscribe(onNext: { [ weak self] (rooms) in
                
                guard let strongSelf = self else {return}
                
                let mock = rooms.first(where: {$0.id == 4008})!
                
                RealmDataPersister.shared.saveToRealm(rooms: [mock])
                    .subscribe(onNext: { (success) in
                        
                        strongSelf.downloads.onNext(success)
                        
                    })
                    .disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
        
    }
    
    private func fetchSessionsAndSaveToRealm_MOCK() {
        
        let oBlocks = ApiController.shared.getBlocks(updated_from: nil,
                                                     with_pagination: 0,
                                                     with_trashed: 0)
        oBlocks
            .subscribe(onNext: { [weak self] (blocks) in
                
                guard let strongSelf = self else {return}
                
                let mock = blocks.map { (block) -> Block in
                    block.starts_at = mockDates[block.id] ?? block.starts_at
                    print("id \(block.id) starts_at \(block.starts_at)")
                    return block
                }
                
                RealmDataPersister.shared.saveToRealm(blocks: mock)
                    .subscribe(onNext: { (success) in
                        
                        strongSelf.downloads.onNext(success) // okini na svom observable, njega monitor
                        
                    })
                    .disposed(by: strongSelf.bag)
                
            })
            .disposed(by: bag)
    }
    
    
    
    
    
    
    
    
    
    deinit {
        print("ResourcesState.deinit is called")
    }
    
}




class CodeReport: Object { // Realm Entity
    
    var code: String = ""
    var sessionId: Int = -1
    var date: Date = Date(timeIntervalSinceNow: 0)
    
    init(code: String, sessionId: Int, date: Date) {
        self.code = code
        self.sessionId = sessionId
        self.date = date
        super.init()
    }
    
    init(realmCodeReport: RealmCodeReport) {
        self.code = realmCodeReport.code
        self.sessionId = realmCodeReport.sessionId
        self.date = realmCodeReport.date ?? Date(timeIntervalSinceNow: 0)
        super.init()
    }
    
    func getPayload() -> [String: String] {
        
        return [
            "block_id": "\(sessionId)",
            "code": code,
            "time_of_scan": date.toString(format: Date.defaultFormatString) ?? ""
        ]
    }
    
    static func getPayload(_ report: CodeReport) -> [String: String] {
        
        return [
            "block_id": "\(report.sessionId)",
            "code": report.code,
            "time_of_scan": report.date.toString(format: Date.defaultFormatString) ?? ""
        ]
    }
    
    static func getPayload(_ reports: [CodeReport]) -> [String: Any] {
        
        let listOfReports = reports.map {getPayload($0)}
        
        return ["data": listOfReports]
    }
    
    // kompajler me tera da implementiram, mogu li ikako bez toga ? ...
    
    required init() {
        super.init()
    }

    required init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }

    required init(value: Any, schema: RLMSchema) {
        super.init(value: value, schema: schema)
    }
    
}


let mockDates = [7266: "2018-11-07 17:00:00",
                7257: "2018-11-07 17:00:00",
                7330: "2018-11-07 17:00:00",
                7748: "2018-11-07 17:00:00",
                8612: "2018-11-07 17:00:00"]
