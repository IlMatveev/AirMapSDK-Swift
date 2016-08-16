//
//  AirMap+Flights.swift
//  AirMapSDK
//
//  Created by Adolfo Martinelli on 6/28/16.
//  Copyright © 2016 AirMap, Inc. All rights reserved.
//

private typealias AirMap_Flights = AirMap
extension AirMap_Flights {

	public typealias AirMapFlightResponseHandler = (AirMapFlight?, NSError?) -> Void
	public typealias AirMapFlightCollectionResponseHandler = ([AirMapFlight]?, NSError?) -> Void

	/**
	Get the all public `AirMapFlight`s including private flights, if available, of the authenticated user.

	- parameter startBefore: `NSDate` of when the flights should start
	- parameter endAfter: `NSDate` of when the flights should end
	- parameter handler: `(AirMapFlight?, NSError?) -> Void`

	*/
	public class func listAllPublicAndAuthenticatedUserFlights(startBefore: NSDate = NSDate(), endAfter: NSDate = NSDate(), limit: Int? = nil, handler: AirMapFlightCollectionResponseHandler) {
		flightClient.listAllPublicAndAuthenticatedPilotFlights(startBefore: startBefore, endAfter: endAfter).subscribe(handler)
	}

	/**
	Get the current `AirMapFlight` belonging to the authenticated user

	- parameter handler: `(AirMapFlight?, NSError?) -> Void`

	*/
	public class func getCurrentAuthenticatedPilotFlight(handler: AirMapFlightResponseHandler) {
		
		flightClient.list(startBefore: NSDate(), endAfter: NSDate(), pilotId: AirMap.authSession.userId, enhanced: true, authCheck:true).map { $0.first }.subscribe(handler)
	}

	/**
	Get an `AirMapFlight` by flightId

	- parameter handler: `(AirMapFlight?, NSError?) -> Void`

	*/
	public class func getFlight(flightId: String, handler: AirMapFlightResponseHandler) {
		flightClient.get(flightId).subscribe(handler)
	}

	/**

	Lists all `AirMapFlight`s belonging to a pilot

	- parameter pilot: `AirMapPilot`
	- parameter limit: `Int` Optional, Defines the number of records returned.
	- parameter handler: `([AirMapFlight]?, NSError?) -> Void`

	*/
	public class func listFlights(pilot: AirMapPilot, limit: Int? = 100, handler: AirMapFlightCollectionResponseHandler) {
		flightClient.list(limit, pilotId: pilot.pilotId).subscribe(handler)
	}

	/**
	Creates a new `AirMapFlight` belonging to the authenticated user

	- parameter flight: The `AirMapFlight` to create
	- parameter geometryType: The `AirMapFlight.FlightGeometryType` Point, Path, or Polygon (Defaults to Point)
	- parameter handler: `(AirMapFlight?, NSError?) -> Void`

	*/
	public class func createFlight(flight flight: AirMapFlight, handler: AirMapFlightResponseHandler) {
		flightClient.create(flight).subscribe(handler)
	}

	/**

	Closes the `AirMapFlight` by setting `endsAt` to the current date and time

	- parameter flight: The `AirMapFlight` to close
	- parameter handler: `(AirMapFlight?, NSError?) -> Void`

	*/
	public class func endFlight(flight: AirMapFlight, handler: AirMapFlightResponseHandler) {
		flightClient.end(flight).subscribe(handler)
	}

	/**

	Deletes an `AirMapFlight` belonging to the authenticated user

	- parameter flight: The `AirMapFlight` to delete
	- parameter handler: `(error: NSError?) -> Void`

	*/
	public class func deleteFlight(flight: AirMapFlight, handler: AirMapErrorHandler) {
		flightClient.delete(flight).subscribe(handler)
	}

}