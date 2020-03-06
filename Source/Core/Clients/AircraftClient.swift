//
//  AircraftClient.swift
//  AirMapSDK
//
//  Created by Rocky Demoff on 7/21/16.
//  Copyright 2018 AirMap, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import RxSwift

internal class AircraftClient: HTTPClient {
	
	init() {
		super.init(basePath: Constants.Api.aircraftUrl)
	}
	
	func listManufacturers() -> Observable<[AirMapAircraftManufacturer]> {
		AirMap.logger.debug("Get Aircraft Manufacturers")
		return perform(method: .get, path: "/manufacturer")
	}
	
	func searchManufacturers(by name: String) -> Observable<[AirMapAircraftManufacturer]> {
		AirMap.logger.debug("Search Aircraft Manufacturers", metadata: ["name": .string(name)])
		return perform(method: .get, path: "/manufacturer", params: ["q": name])
	}

	func listModels(by manufacturerId: AirMapAircraftManufacturerId) -> Observable<[AirMapAircraftModel]> {
		AirMap.logger.debug("Get Manufacturer Models", metadata: ["manufacturer": .stringConvertible(manufacturerId)])
		return perform(method: .get, path: "/model", params: ["manufacturer": manufacturerId])
	}

	func searchModels(by name: String) -> Observable<[AirMapAircraftModel]> {
		AirMap.logger.debug("Search Aircraft Models by Name", metadata: ["name": .string(name)])
		return perform(method: .get, path: "/model", params: ["q": name])
	}

	func getModel(_ modelId: AirMapAircraftModelId) -> Observable<AirMapAircraftModel> {
		AirMap.logger.debug("Get Model", metadata: ["model": .stringConvertible(modelId)])
		return perform(method: .get, path: "/model/\(modelId)")
	}
}
