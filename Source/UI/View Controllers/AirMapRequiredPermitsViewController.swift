//
//  AirMapRequiredPermitsViewController.swift
//  AirMapSDK
//
//  Created by Adolfo Martinelli on 7/18/16.
//  Copyright © 2016 AirMap, Inc. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

class AirMapRequiredPermitsViewController: UIViewController {
	
	@IBOutlet weak var permitComplianceStatus: UILabel!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var nextButton: UIButton!
	
	private var permittableAdvisories = Variable([AirMapStatusAdvisory]())
	
	override var navigationController: AirMapFlightPlanNavigationController? {
		return super.navigationController as? AirMapFlightPlanNavigationController
	}
	private var requiredPermits: Variable<[AirMapAvailablePermit]> {
		return navigationController!.requiredPermits
	}
	private var existingPermits: Variable<[AirMapPilotPermit]> {
		return navigationController!.existingPermits
	}
	private var selectedPermits: Variable<[(advisory: AirMapStatusAdvisory, permit: AirMapAvailablePermit, pilotPermit: AirMapPilotPermit)]> {
		return navigationController!.selectedPermits
	}
	private var draftPermits: Variable<[AirMapPilotPermit]> {
		return navigationController!.draftPermits
	}

	private typealias RowData = (advisory: AirMapStatusAdvisory, permit: AirMapPilotPermit?)
	private let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<AirMapStatusAdvisory, RowData>>()
	
	private let disposeBag = DisposeBag()
	
	// MARK: - View Lifecycle

	override func viewDidLoad() {
		super.viewDidLoad()
		
		loadData()
		setupBindings()
		setupTableView()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		tableView.indexPathsForSelectedRows?.forEach { indexPath in
			if let row = try? tableView.rx_modelAtIndexPath(indexPath) as RowData
				where row.permit == nil {
				tableView.deselectRowAtIndexPath(indexPath, animated: true)
			}
		}
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		guard let identifier = segue.identifier else { return }
		
		switch identifier {
			
		case "modalPermitQuestionFlow":
			guard let
				nav = segue.destinationViewController as? AirMapPermitDecisionNavController,
				firstQuestionVC = nav.viewControllers.last as? AirMapPermitQuestionViewController,
				indexPath = tableView.indexPathForCell(sender as! UITableViewCell),
				section = try? self.tableView.rx_modelAtIndexPath(indexPath) as RowData?,
				decisionFlow = section?.advisory.requirements?.permitDecisionFlow,
				firstQuestion = decisionFlow.questions.filter({ $0.id == decisionFlow.firstQuestionId}).first,
				advisory = section?.advisory
				else { assertionFailure(); return }

			nav.permitDecisionFlowDelegate = self
			firstQuestionVC.decisionFlow = decisionFlow
			firstQuestionVC.question = firstQuestion
			firstQuestionVC.advisory = advisory
			
		default:
			break
		}
	}

	@IBAction func unwindToRequiredPermits(segue: UIStoryboardSegue) { /* Hook for Interface Builder; keep. */ }
	
	// MARK: - Setup
	
	private func setupTableView() {
		
		tableView.rx_setDelegate(self)
		
		dataSource.configureCell = { dataSource, tableView, indexPath, rowData in
			
			let cell: UITableViewCell
			
			if let permit = rowData.permit,
				avilablePermit = self.availablePermit(from: permit) {
				cell = tableView.dequeueReusableCellWithIdentifier("usePermitCell", forIndexPath: indexPath)
				cell.textLabel?.text = avilablePermit.name
			} else {
				cell = tableView.dequeueReusableCellWithIdentifier("helpMeDecide", forIndexPath: indexPath)
				if indexPath.row > 0 {
					cell.textLabel?.text = "Select a different Permit"
				} else {
					cell.textLabel?.text = "Select Permit"
				}
			}
			return cell
		}
		
		dataSource.titleForHeaderInSection = { dataSource, section in
			return dataSource.sectionAtIndex(section).model.name
		}
	}
	
	private func setupBindings() {
		
		Observable.combineLatest(requiredPermits.asObservable(), existingPermits.asObservable(), draftPermits.asObservable(), permittableAdvisories.asObservable()) { ($0, $1, $2, $3) }
			.observeOn(MainScheduler.instance)
			.map(unowned(self, AirMapRequiredPermitsViewController.sectionModels))
			.bindTo(tableView.rx_itemsWithDataSource(dataSource))
			.addDisposableTo(disposeBag)
		
		Observable.combineLatest(selectedPermits.asObservable(), permittableAdvisories.asObservable()) { ($0, $1) }
			.observeOn(MainScheduler.instance)
			.doOnNext { [weak self] selected, advisories in
				self?.permitComplianceStatus.text = "You have selected \(selected.count) of \(advisories.count) permits required for this flight"
			}
			.map { $0.count == $1.count }
			.bindTo(nextButton.rx_enabled)
			.addDisposableTo(disposeBag)
	}
	
	private func loadData() {
		
		AirMap
			.rx_listPilotPermits()
			.map(unowned(self, AirMapRequiredPermitsViewController.filterOutInvalidPermits))
			.bindTo(existingPermits)
			.addDisposableTo(disposeBag)

		permittableAdvisories.value = navigationController!.status.value!.advisories.filter { advisory in
			advisory.requirements?.permitsAvailable.count > 0
		}
		
		requiredPermits.value = permittableAdvisories.value
			.map { $0.requirements!.permitsAvailable }
			.flatMap { $0 }		
	}
	
	private func filterOutInvalidPermits(permits: [AirMapPilotPermit]) -> [AirMapPilotPermit] {
		
		return permits
			.filter { $0.permitDetails.singleUse == false }
			.filter { $0.status != .Rejected }
			.filter { $0.status != .Pending }
	}
	
	func availablePermit(from permit: AirMapPilotPermit) -> AirMapAvailablePermit? {
		return requiredPermits.value .filter { $0.id == permit.permitId } .first
	}
	
	// MARK: - Instance Methods
	
	private func sectionModels(requiredPermits: [AirMapAvailablePermit], existingPermits: [AirMapPilotPermit], draftPermits: [AirMapPilotPermit], advisories: [AirMapStatusAdvisory]) -> [SectionModel<AirMapStatusAdvisory, RowData>] {
		
		return advisories.map { advisory in
			
			let requiredPermits = advisory.requirements!.permitsAvailable
			
			let draftPermitRows: [RowData] = draftPermits
				.filter { requiredPermits.map{ $0.id }.contains($0.permitId) }
				.map { (advisory: advisory, permit: $0) }
			
			let existingPermitRows: [RowData] = existingPermits
				.filter { requiredPermits.map{ $0.id }.contains($0.permitId) }
				.map { (advisory: advisory, permit: $0) }

			let newPermitRow: RowData = (advisory: advisory, permit: nil)
			
			return SectionModel(model: advisory, items: draftPermitRows + existingPermitRows + [newPermitRow])
		}
	}
	
	private func uncheckRowsInSection(section: Int) {
		for index in 0..<dataSource.sectionAtIndex(section).items.count-1 {
			let ip = NSIndexPath(forRow: index, inSection: section)
			tableView.cellForRowAtIndexPath(ip)?.accessoryType = .None
		}
	}
	
}

extension AirMapRequiredPermitsViewController: AirMapPermitDecisionFlowDelegate {
	
	func decisionFlowDidSelectPermit(permit: AirMapAvailablePermit, requiredBy advisory: AirMapStatusAdvisory, with customProperties: [AirMapPilotPermitCustomProperty]) {
		
		let draftPermit = AirMapPilotPermit()
		draftPermit.permitId = permit.id
		draftPermit.customProperties = customProperties

		let matchingDraftPermits = draftPermits.value
			.filter { $0.permitId == draftPermit.permitId }
		
		let matchingExistingPermits = existingPermits.value
			.filter { $0.permitId == draftPermit.permitId }

		let matchingSelectedAdvisoryPermits = selectedPermits.value
			.filter { $0.advisory.id == advisory.id }
		
		if matchingDraftPermits.count == 0 && matchingExistingPermits.count == 0 {
			draftPermits.value.append(draftPermit)
		}

		selectedPermits.value = selectedPermits.value.filter {
			let permitIds = matchingSelectedAdvisoryPermits.map { $0.permit.id }
			return !permitIds.contains($0.permit.id)
		}
		selectedPermits.value.append((advisory: advisory, permit: permit, pilotPermit: draftPermit))
		tableView.reloadData()
	}
}

extension AirMapRequiredPermitsViewController: UITableViewDelegate {
	
	func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let header = TableHeader(dataSource.sectionAtIndex(section).model.name)!
		header.textLabel.textAlignment = .Center
		header.textLabel.font = UIFont.boldSystemFontOfSize(17)
		return header
	}
	
	func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 45
	}
	
	func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
		
		guard let row = try? dataSource.modelAtIndexPath(indexPath) as? RowData,
			rowAdvisory = row?.advisory,
			pilotPermit = row?.permit else { return }
		
		if selectedPermits.value.filter ({$0.permit.id == pilotPermit.permitId && $0.advisory.id == rowAdvisory.id }).first != nil {
			cell.accessoryType = .Checkmark
		} else {
			cell.accessoryType = .None
		}
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
				
		tableView.deselectRowAtIndexPath(indexPath, animated: false)
		
		if let row = try? dataSource.modelAtIndexPath(indexPath) as? RowData,
			rowAdvisory = row?.advisory,
			pilotPermit = row?.permit {
			
			if let alreadySelectedPermit = selectedPermits.value.filter({$0.permit.id == pilotPermit.permitId && $0.advisory.id == rowAdvisory.id}).first {
				selectedPermits.value = selectedPermits.value.filter { $0 != alreadySelectedPermit }
				tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .None
			} else {
				uncheckRowsInSection(indexPath.section)
				if let previousSelectedAdvisoryPermit = selectedPermits.value.filter({$0.advisory.id == rowAdvisory.id}).first {
					selectedPermits.value = selectedPermits.value.filter { $0 != previousSelectedAdvisoryPermit }
				}
				
				let availablePermit = requiredPermits.value.filter {$0.id == pilotPermit.permitId }.first!
				selectedPermits.value.append((advisory: rowAdvisory, permit: availablePermit, pilotPermit: pilotPermit))
				tableView.cellForRowAtIndexPath(indexPath)?.accessoryType = .Checkmark
			}
		}
	}
	
}