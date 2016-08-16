//
//  AirMapAircraftViewController.swift
//  AirMapSDK
//
//  Created by Adolfo Martinelli on 7/18/16.
//  Copyright © 2016 AirMap, Inc. All rights reserved.
//

import RxSwift
import RxCocoa

class AirMapAircraftViewController: UITableViewController {
	
	let selectedAircraft = Variable(nil as AirMapAircraft?)
	
	private let aircraft = Variable([AirMapAircraft]())
	private let disposeBag = DisposeBag()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		setupBindings()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		
		AirMap
			.rx_listAircraft()
			.bindTo(aircraft)
			.addDisposableTo(disposeBag)
	}
	
	@IBAction func dismiss() {
		dismissViewControllerAnimated(true, completion: nil)
	}
	
	private func setupBindings() {
	
		tableView.dataSource = nil
		tableView.delegate = nil
		
		aircraft
			.asObservable()
			.bindTo(tableView.rx_itemsWithCellIdentifier("aircraftCell")) {
				(index, aircraft, cell) in
				cell.textLabel?.text = aircraft.nickname
				cell.detailTextLabel?.text = [aircraft.model.manufacturer.name, aircraft.model.name]
					.flatMap {$0}.joinWithSeparator(" ")
			}
			.addDisposableTo(disposeBag)
		
		tableView
			.rx_modelSelected(AirMapAircraft)
			.doOnNext { [weak self] _ in
				self?.dismissViewControllerAnimated(true, completion: nil)
			}
			.asOptional()
			.bindTo(selectedAircraft)
			.addDisposableTo(disposeBag)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let identifier = segue.identifier else { return }
		
		switch identifier {
			
			case "editAircraft":
				let cell = sender as! UITableViewCell
				let indexPath = tableView.indexPathForCell(cell)!
				let aircraft = try! tableView.rx_modelAtIndexPath(indexPath) as AirMapAircraft
				let nav = segue.destinationViewController as! AirMapAircraftModelNavController
				let aircraftVC = nav.viewControllers.last as! AirMapCreateAircraftViewController
				aircraftVC.aircraft = aircraft
			
		default:
			break
		}
	}
	
	@IBAction func unwindToAircraft(segue: UIStoryboardSegue) { /* unwind hook; keep */ }
}