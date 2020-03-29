//
//  BlockViewModel.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 20/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import RxSwift
import RxRealm
import RxCocoa

class BlockViewModel {
    
    let disposeBag = DisposeBag()
    
    // ovi treba da su ti SUBJECTS! sta je poenta imati ih ovako ??
    
    private var blocks: Results<RealmBlock>! // ostavio sam zbog vc-a.. (nije dobro ovo)
//    private (set) var blocksSortedByDate = [RealmBlock]()

    private (set) var sectionBlocks = [[RealmBlock]]() // niz nizova jer je tableView sa sections
    
    private var blocksSortedByDate = [RealmBlock]()
    
    // INPUT (javice ti neko, ono sto procita drugi model...)
    
    var oAutoSelSessInterval = BehaviorRelay.init(value: MyTimeInterval.waitToMostRecentSession)
    
    // output 1 - za prikazivanje blocks na tableView...
    
    var sectionsHeadersAndItems = [SectionOfCustomData]()
    
    var oSectionsHeadersAndItems = BehaviorRelay<[SectionOfCustomData]>.init(value: [])
    
    // output 2 - expose your calculated stuff
    var oAutomaticSession = BehaviorRelay<Block?>.init(value: nil)
    
    //var oAutomaticSessionDriver: SharedSequence<DriverSharingStrategy, RealmBlock?> {
    var oAutomaticSessionDriver: Driver<Block?> {
        return oAutomaticSession.asDriver(onErrorJustReturn: nil)
    }
    
    let roomId: Int?
    
    var selInterval: Int?
    
    private var mostRecentSessionBlock: RealmBlock? {
        
        let todayBlocks = blocksSortedByDate.filter { // mock za test !
            return Calendar.current.compare(NOW,
                                            to: Date.parse($0.starts_at),
                                            toGranularity: Calendar.Component.day) == ComparisonResult.orderedSame
        }
        
        let actualOrNextInFiftheenMinutes = todayBlocks.filter { block -> Bool in
            let startsAt = Date.parse(block.starts_at)
            
            return startsAt.addingTimeInterval(-MyTimeInterval.waitToMostRecentSession) < NOW
            }
            .last
        
        return actualOrNextInFiftheenMinutes
    }
    
    
    // 1 - dependencies-init
    init(roomId: Int? = nil) {
        self.roomId = roomId
        bindOutput()
        bindAutomaticSession()
    }
    
    //... 2 - input
    
    // 3 - output
    
    private(set) var oBlocks: Observable<(AnyRealmCollection<RealmBlock>, RealmChangeset?)>!
    
    private func bindOutput() { // hook-up se za Realm, sada su Rooms synced sa bazom
        
        guard let realm = try? Realm() else { return }
        
        // ovde mi treba jos da su od odgovarajuceg Room-a
        
        blocks = realm.objects(RealmBlock.self)
        
        if let roomId = roomId {
            blocks = blocks.filter("location_id = %@", roomId)
        }
        
        oBlocks = Observable.changeset(from: blocks)
        
        oBlocks
            .subscribe(onNext: { (collection, changeset) in
                
                self.sectionBlocks = self.sortBlocksByDay(blocksArray: collection.toArray())
                
                self.blocksSortedByDate = collection.toArray().sorted(by: {
                    return Date.parse($0.starts_at) < Date.parse($1.starts_at)
                })
                
                self.loadSectionsHeadersAndItems(blocksByDay: self.sectionBlocks)
                
            }).disposed(by: disposeBag)
        
    }
    
    private func loadSectionsHeadersAndItems(blocksByDay: [[RealmBlock]]) {
        sectionsHeadersAndItems = blocksByDay.map({ (blocks) -> SectionOfCustomData in
            let sectionName = blocks.first?.starts_at.components(separatedBy: " ").first ?? ""
            //let itemTupols = blocks.map {(($0.starts_at + " " + $0.name), Date.parse($0.starts_at))}
            let items = blocks.map({ (rBlock) -> SectionOfCustomData.Item in
                let fullname = rBlock.starts_at + " " + rBlock.name
                let name = rBlock.name
                let date = Date.parse(rBlock.starts_at)
                return SectionOfCustomData.Item(fullname: fullname, name: name, date: date)
            })
            return SectionOfCustomData.init(header: sectionName, items: items)
        })
        oSectionsHeadersAndItems.accept(sectionsHeadersAndItems)
    }
    
    // ako ima bilo koji session u zadatom Room, na koji se ceka krace od 2 sata, emituj SessionId; ako nema, emituj nil.
    private func bindAutomaticSession(interval: TimeInterval = MyTimeInterval.waitToMostRecentSession) {
        
        let sessionAvailable = autoSessionIsAvailable(inLessThan: interval)
        
        if sessionAvailable {
            //let block = Block(with: mostRecentSessionBlock!)
            let block = BlockFactory.make(from: mostRecentSessionBlock!) as! Block
            settingsJourney.blockId = block.id
            oAutomaticSession.accept(block)
        } else {
            settingsJourney.blockId = nil
            oAutomaticSession.accept(nil)
        }
        
    }
    
    private func autoSessionIsAvailable(inLessThan interval: TimeInterval) -> Bool { // implement me
        
        return mostRecentSessionBlock != nil
        
    }
    
    private func sortBlocksByDay(blocksArray:[RealmBlock]) -> [[RealmBlock]] {
        
        if blocksArray.isEmpty { return [] }
        
        let inputArray = blocksArray.sorted { Date.parse($0.starts_at) < Date.parse($1.starts_at) }
        
        var resultArray = [[inputArray[0]]]
        
        let calendar = Calendar(identifier: .gregorian)
        for (prevBlock, nextBlock) in zip(inputArray, inputArray.dropFirst()) {
            let prevDate = Date.parse(prevBlock.starts_at)
            let nextDate = Date.parse(nextBlock.starts_at)
            if !calendar.isDate(prevDate, equalTo: nextDate, toGranularity: .day) {
                resultArray.append([]) // Start new row
            }
            resultArray[resultArray.count - 1].append(nextBlock)
        }
        return resultArray
    }
    
    //deinit { print("deinit/BlockViewModel is deinit") }
    
}
