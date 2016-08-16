//
//  AirMapApiData.swift
//  AirMapSDK
//
//  Created by Rocky Demoff on 7/20/16.
//  Copyright © 2016 AirMap, Inc. All rights reserved.
//

import ObjectMapper

public class AirMapPath: AirMapGeometry {

	public var coordinates: [CLLocationCoordinate2D]!
}

extension AirMapPath: Mappable {

	public func mapping(map: Map) {
		coordinates	<-  map["coordinates"]
	}

	/**
	Returns key value parameters

	- returns: [String: AnyObject]
	*/
	override public func params() -> [String: AnyObject] {

		var params = [String: AnyObject]()

		if let coords = coordinates {
			params["type"] = "LineString"
			params["coordinates"] = coords.map { [$0.latitude, $0.longitude] } as [[Double]]
		}

		return params
	}

}