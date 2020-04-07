//
//  BlockProviderWorker.swift
//  AttendanceApp
//
//  Created by Marko Dimitrijevic on 29/03/2020.
//  Copyright © 2020 Navus. All rights reserved.
//

import RxSwift

class BlockProviderWorker: IBlockProviderWorker {
    private let apiController: IBlockApiController
    private let repository: IBlockMutableRepository
    init(apiController: IBlockApiController, repository: IBlockMutableRepository) {
        self.apiController = apiController
        self.repository = repository
    }
    
    func fetchBlocksAndPersistOnDevice()  -> Observable<Bool> {
        apiController
            .getBlocks(updated_from: nil, with_pagination: 0, with_trashed: 0, for_scanning: 1 )
            .do(onNext: { (blocks) in
                //self.repository.save(blocks: blocks)
                self.repository.replaceExistingWith(blocks: blocks)
            })
        .map {_ in true}
    }
}
