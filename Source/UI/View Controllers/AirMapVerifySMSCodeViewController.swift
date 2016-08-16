//
//  AirMapVerifySMSCodeViewController.swift
//  Pods
//
//  Created by Adolfo Martinelli on 8/8/16.
//
//

import RxSwift
import RxCocoa

class AirMapVerifySMSCodeViewController: UITableViewController {
	
	@IBOutlet var submitButton: UIButton!
	@IBOutlet weak var smsCode: UITextField!
	@IBOutlet weak var smsTextField: UITextField!
	
	private let disposeBag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupBindings()
	}
	
	override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
	override var inputAccessoryView: UIView? {
		return submitButton
	}
	
	private func setupBindings() {
		
		smsTextField.rx_text.asObservable()
			.map { $0.characters.count == Config.AirMapApi.smsCodeLength }
			.bindTo(submitButton.rx_enabled)
			.addDisposableTo(disposeBag)
	}
	
	@IBAction func submitSMSCode() {
		
		AirMap.rx_verifySMS(smsTextField.text!)
			.subscribeNext { [weak self] response in
				if response.verified {
					self?.performSegueWithIdentifier("unwindToPilotProfile", sender: self)
				} else {
					//TODO: Handle error
					self?.navigationController?.popViewControllerAnimated(true)
				}
			}
			.addDisposableTo(disposeBag)
	}
	
}