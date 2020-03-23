//
//  APIController.swift
//  tryObservableWebApiAndRealm
//
//  Created by Marko Dimitrijevic on 19/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import SwiftyJSON
import CoreLocation
import MapKit
import Reachability

class ApiController {
    
    struct Domain {
        //static let baseUrl = URL(string: "https://service.e-materials.com/api")!
        static let baseUrl = URL(string: "https://minjon.e-materials.com/api")!
        //static let baseUrl = URL(string: "https://b276c755-37f6-44d2-85af-6f3e654511ad.mock.pstmn.io/")! // hard-coded mock
        static let baseTrackerURL = URL(string: "http://tracker.e-materials.com/")!
//        static let baseTrackerURL = URL(string: "https://b276c755-37f6-44d2-85af-6f3e654511ad.mock.pstmn.io/")!
//        static let mockURL = URL(string: "https://b276c755-37f6-44d2-85af-6f3e654511ad.mock.pstmn.io/")!
    }
    
    /// The shared instance
    static var shared = ApiController()
    
    /// The api key to communicate with Navus
    private var apiKey: String {
        return conferenceState.apiKey ?? "fatal"
    }
    
    init() {
        Logging.URLRequests = { request in
            return true
        }
    }
    
    //MARK: - Api Calls
    func getRooms(updated_from: Date?, with_pagination: Int, with_trashed: Int) -> Observable<[Room]> {
        let updatedDate = updated_from?.toString(format: Date.defaultFormatString) ?? ""
        return buildRequest(pathComponent: "locations", //params: [])//,
                            params: [("updated_from", updatedDate),
                                     ("with_pagination", "\(with_pagination)"),
                                     ("with_trashed", "\(with_trashed)")])
            .map() { json in
                let decoder = JSONDecoder()
                guard let rooms = try? decoder.decode(Rooms.self, from: json) else {
                    throw ApiError.invalidJson
                }
                return rooms.data
            }
    }
    
    func getBlocks(updated_from: Date?, with_pagination: Int, with_trashed: Int, for_scanning: Int) -> Observable<[Block]> {
        let updatedDate = updated_from?.toString(format: Date.defaultFormatString) ?? ""
        return buildRequest(pathComponent: "blocks", //params: [ ])//,
                            params: [("updated_from", updatedDate),
                                     ("with_pagination", "\(with_pagination)"),
                                     ("with_trashed", "\(with_trashed)"),
                                     ("for_scanning", "\(for_scanning)"),
                                     ("type[]", "Oral")])
            .map() { json in
                let decoder = JSONDecoder()
                guard let blocks = try? decoder.decode(Blocks.self, from: json) else {
                    throw ApiError.invalidJson
                }
                return blocks.data
            }
    }
    
    //MARK: - Api Calls
    
    func reportSingleCode(report: CodeReport?) -> Observable<(CodeReport,Bool)> {
        
        guard let report = report else {return Observable.empty()}
        
        let params = report.getPayload()
        
        return buildRequest(base: Domain.baseTrackerURL,
                            method: "POST",
                            pathComponent: "attendances",
                            params: params)
            .map { data in
                guard let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let created = json["created"] as? Int, created == 201 else {
                        return (report, false)
                }
                return (report, true)
            }
            .catchErrorJustReturn((report, false))
    }
    
    func reportMultipleCodes(reports: [CodeReport]?) -> Observable<Bool> {
        
        guard let reports = reports else {return Observable.empty()}
        
        let params = CodeReport.getPayload(reports)
        
        return buildRequest(base: Domain.baseTrackerURL,
                            method: "POST",
                            pathComponent: "attendances",
                            params: params)
            .map() { data in
                guard let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let created = json["created"] as? Int, created == 201 else {
//                        print("reportCodes vraca FALSE!!")
                    return false
                }
//                print("reportCodes vraca TRUE!!")
            return true
        }
    }
    
    // Session
    
    func reportSelectedSession(report: SessionReport?) -> Observable<(SessionReport,Bool)> {
        
        guard let report = report else {return Observable.empty()}
        
        let params = report.getPayload()
        
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        return buildRequest(base: Domain.baseTrackerURL,
                            method: "PUT",
                            pathComponent: "devices/\(deviceId)",
                            params: params,
                            contentType: "text/plain")
            .map { data in
                guard let object = try? JSONSerialization.jsonObject(with: data),
                    let json = object as? [String: Any],
                    let created = json["created"] as? Int, created == 201 else {
                        return (report, false)
                }
                return (report, true)
            }
            .catchErrorJustReturn((report, false))
    }
 
    // MARK: - Api Key Sync
    func getApiKey() -> Observable<String?> {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
        let pathComponent = "devices" + "/" + deviceId
        return buildRequest(base: Domain.baseTrackerURL,
//        return buildRequest(base: Domain.mockURL,
                            method: "GET",
                            pathComponent: pathComponent,
                            params: [])
            .map() { data in
                guard let jsonObject = try? JSONSerialization.jsonObject(with: data),
                    let json = jsonObject as? [String: Any] else {return nil}
                print("vracam api_key = \(String(describing: json["api_key"] as? String))")
                return json["api_key"] as? String
        }
    }
    
    //MARK: - Private Methods
    
    /** * Private method to build a request with RxCocoa */
    
    // bez veze je Any... // treba ili [(String, String)] ili [String: Any]
    
     func buildRequest(base: URL = Domain.baseUrl,
                       method: String = "GET",
                       pathComponent: String,
                       params: Any = [],
                       contentType: String? = "application/json") -> Observable<Data> {
    
        print("APIController.buildingRequest.calling API !!!")
        
        let url = base.appendingPathComponent(pathComponent)
//        let url = URL.init(string: "https://b276c755-37f6-44d2-85af-6f3e654511ad.mock.pstmn.io/")!.appendingPathComponent(pathComponent)
        
        var request = URLRequest(url: url)
        
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        
        if method == "GET" || method == "PUT" {
            guard let params = params as? [(String, String)] else { // hard-coded off !!!
                return Observable.empty()
            }
            let queryItems = params.map { URLQueryItem(name: $0.0, value: $0.1) }
            urlComponents.queryItems = queryItems
        } else {
            guard let params = params as? [String: Any] else {
                return Observable.empty()
            }
            let jsonData = try! JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
            request.httpBody = jsonData
        }
        
        request.url = urlComponents.url!
        request.httpMethod = method
        
        let deviceUdid = UIDevice.current.identifierForVendor?.uuidString ?? ""
        
        request.allHTTPHeaderFields = ["Api-Key": apiKey,
                                       "device-id": deviceUdid,
                                       "Content-Type": contentType!]
        
        let session = URLSession.shared
        
        return session.rx.response(request: request).map() { response, data in
            
//            print("response.statusCode = \(response.statusCode)")
            
            if 201 == response.statusCode {
                return try! JSONSerialization.data(withJSONObject:  ["created": 201])
            } else if 200 ..< 300 ~= response.statusCode {
                print("buildRequest.imam data... all good, data = \(data)")
                return data
            } else if response.statusCode == 401 {
                print("buildRequest.ApiError.invalidKey")
                throw ApiError.invalidKey
            } else if 400 ..< 500 ~= response.statusCode {
                print("buildRequest.ApiError.cityNotFound")
                throw ApiError.cityNotFound
            } else {
                print("buildRequest.ApiError.serverFailure")
                throw ApiError.serverFailure
            }
        }
    }
    
}

enum ApiError: Error {
    case invalidJson
    case invalidKey
    case cityNotFound
    case serverFailure
}
