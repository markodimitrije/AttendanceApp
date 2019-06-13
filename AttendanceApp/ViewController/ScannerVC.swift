//
//  ScannerVC.swift
//  tryWebApiAndSaveToRealm
//
//  Created by Marko Dimitrijevic on 22/10/2018.
//  Copyright © 2018 Marko Dimitrijevic. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import AVFoundation
import RealmSwift
import ScanditBarcodeScanner

class ScannerVC: UIViewController {

    @IBOutlet weak var scannerView: UIView!
    @IBOutlet weak var arrowImageView: UIImageView!
    @IBOutlet weak var sessionConstLbl: UILabel!
    @IBOutlet weak var sessionNameLbl: UILabel!
    @IBOutlet weak var sessionTimeAndRoomLbl: UILabel!
    
    lazy private var scanerViewModel = ScannerViewModel.init(dataAccess: DataAccess.shared)
    
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    private (set) var scanedCode = BehaviorSubject<String>.init(value: "")
    var code: String {
        return try! scanedCode.value()
    }
    
    private let codeReporter = CodeReportsState.init() // vrsta viewModel-a ?
    private let delegatesSessionValidation = RealmDelegatesSessionValidation()
    
    private let realmInvalidAttedanceReportPersister = RealmInvalidAttedanceReportPersister(realmObjectPersister: RealmObjectPersister())
    
    var settingsVC: SettingsVC!
    
    // interna upotreba:
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() { super.viewDidLoad()
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        setupScanner()
        
        sessionConstLbl.text = SessionTextData.sessionConst
        bindUI()
        
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    private func bindUI() { // glue code for selected Room
        
        scanerViewModel.sessionName//.map {$0+$0} (test text length) // SESSION NAME
            .bind(to: sessionNameLbl.rx.text)
            .disposed(by: disposeBag)
        
        scanerViewModel.sessionInfo // SESSION INFO
            .bind(to: sessionTimeAndRoomLbl.rx.text)
            .disposed(by: disposeBag)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let name = segue.identifier, name == "segueShowSettings",
            let navVC = segue.destination as? UINavigationController,
            let settingsVC = navVC.children.first as? SettingsVC else { return }
        
        self.settingsVC = settingsVC
        
        hookUpScanedCode(on: settingsVC)
        
    }
    
    private func hookUpScanedCode(on settingsVC: SettingsVC) {
        
        settingsVC.codeScaned = self.scanedCode
        
    }
    
    private func failed() { print("failed.....")

        self.alert(title: AlertInfo.Scan.ScanningNotSupported.title,
                   text: AlertInfo.Scan.ScanningNotSupported.msg,
                   btnText: AlertInfo.ok)
            .subscribe {
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func showAlertFailedDueToNoRoomOrSessionSettings() {
        
        self.alert(title: AlertInfo.Scan.NoSettings.title,
                   text: AlertInfo.Scan.NoSettings.msg,
                   btnText: AlertInfo.ok)
            .subscribe {
                self.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    func found(code: String, picker: SBSBarcodePicker) { // ovo mozes da report VM-u kao append novi code
        
        if scanerViewModel.sessionId != -1 {
            scanditSuccessfull(code: code, picker: picker)
        } else {
            showAlertFailedDueToNoRoomOrSessionSettings()
            restartCameraForScaning(picker)
        }
        
    }
    
    fileprivate func restartCameraForScaning(_ picker: SBSBarcodePicker) {
        delay(1.0) { // ovoliko traje anim kada prikazujes arrow
            DispatchQueue.main.async {
                self.scannerView.subviews.first(where: {$0.tag == 20})?.removeFromSuperview()
                picker.resumeScanning()
            }
        }
    }
    
    private func scanditSuccessfull(code: String, picker: SBSBarcodePicker) { // hard-coded implement me
        
        if self.scannerView.subviews.contains(where: {$0.tag == 20}) { return } // already arr on screen...
        
        // hard-coded off - main event
//        if delegatesSessionValidation.isScannedDelegate(withBarcode: code,
//                                                        allowedToAttendSessionWithId: scanerViewModel.sessionId) {
//            delegateIsAllowedToAttendSession(code: code, picker: picker)
//        } else {
//            delegateAttendanceInvalid(code: code, picker: picker)
//        }
        // hard-coded on
        delegateIsAllowedToAttendSession(code: code, picker: picker)
        restartCameraForScaning(picker)
    }
    
    private func delegateIsAllowedToAttendSession(code: String, picker: SBSBarcodePicker) {
        
        scanedCode.onNext(code)
        playSound(name: "codeSuccess")
        self.scannerView.addSubview(getArrowImgView(frame: scannerView.bounds, validAttendance: true))
        codeReporter.codeReport.accept(getActualCodeReport())
    }
    
    private func delegateAttendanceInvalid(code: String, picker: SBSBarcodePicker) {
        persistInAttendanceInvalid(code: code)
        uiEffectsForAttendanceInvalid()
    }
    
    private func persistInAttendanceInvalid(code: String) {
        realmInvalidAttedanceReportPersister
            .saveToRealm(invalidAttendanceCode: code)
            .subscribe(onNext: { success in
                print("invalid codes saved = \(success)")
            }).disposed(by: disposeBag)
    }
    
    private func uiEffectsForAttendanceInvalid() {
        playSound(name: "codeRejected")
        self.scannerView.addSubview(getArrowImgView(frame: scannerView.bounds, validAttendance: false))
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape //[.landscapeLeft, .landscapeRight]
    }
    
    // MARK:- Private
    
    private func getActualCodeReport() -> CodeReport {
       
        print("getActualCodeReport = \(code)")
        
        return CodeReport.init(code: code,
                               sessionId: scanerViewModel.sessionId,
                               date: Date.now)
    }
    
    
    // SCANDIT
    
    private func setupScanner() {
        
        // Create the scan settings and enabling some symbologies
        let settings = SBSScanSettings.default()
        let symbologies: Set<SBSSymbology> = [.aztec, .codabar, .code11, .code128, .code25, .code32, .code39, .code93, .datamatrix, .dotCode, .ean8, .ean13, .fiveDigitAddOn, .gs1Databar, .gs1DatabarExpanded, .gs1DatabarLimited, .itf, .kix, .lapa4sc, .maxiCode, .microPDF417, .microQR, .msiPlessey, .pdf417,.qr, .rm4scc, .twoDigitAddOn, .upc12, .upce]
        for symbology in symbologies {
            settings.setSymbology(symbology, enabled: true)
        }
        
        //settings.cameraFacingPreference = .front//settings.cameraFacingPreference = .back
        settings.cameraFacingPreference = getCameraDeviceDirection() ?? .back
        
        let symSettings = settings.settings(for: .code25)
        symSettings.activeSymbolCounts = [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
        
        // Create the barcode picker with the settings just created
        let barcodePicker = SBSBarcodePicker(settings:settings)
        barcodePicker.view.frame = self.scannerView.bounds
        
        // Add the barcode picker as a child view controller
        addChild(barcodePicker)
        
        self.scannerView.addSubview(barcodePicker.view)
        barcodePicker.didMove(toParent: self)
        
        // Set the allowed interface orientations. The value UIInterfaceOrientationMaskAll is the
        // default and is only shown here for completeness.
        barcodePicker.allowedInterfaceOrientations = .all
        // Set the delegate to receive scan event callbacks
        barcodePicker.scanDelegate = self
        barcodePicker.startScanning()
    }
    
}

extension ScannerVC: SBSScanDelegate {
    // This delegate method of the SBSScanDelegate protocol needs to be implemented by
    // every app that uses the Scandit Barcode Scanner and this is where the custom application logic
    // goes. In the example below, we are just showing an alert view with the result.
    func barcodePicker(_ picker: SBSBarcodePicker, didScan session: SBSScanSession) {

        session.pauseScanning()
        
        let code = session.newlyRecognizedCodes[0]
        
        DispatchQueue.main.async { [weak self] in
            self?.found(code: code.data ?? "", picker: picker)
        }
    }
    
    
}
