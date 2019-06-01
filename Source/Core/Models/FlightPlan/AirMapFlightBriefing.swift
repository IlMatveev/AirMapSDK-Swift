//
//  AirMapFlightBriefing.swift
//  AirMapSDK
//
//  Created by Adolfo Martinelli on 5/21/17.
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

/// A pre-flight summary of the status, rulesets, validations, and authorizations pertinent to the operation of a flight
public struct AirMapFlightBriefing {
	
	/// The date and time the briefing was created
	public let createdAt: Date
	
	/// A list of rulesets containing rules selected and applicable to the operation
	public let rulesets: [Ruleset]
	
	/// The airspace and advisories that intersect with the flight plan
	public let status: AirMapAirspaceStatus
	
	/// The list of authorizations necessary to perform the flight
	public let authorizations: [Authorization]
	
	/// The list of validations performed on the flight plan's flight feature values
	public let validations: [Validation]
	
	/// A logical grouping of rules, typically under a specific jurisdiction
	public struct Ruleset {
		
		/// The unique identifier for the ruleset
		public let id: AirMapRulesetId
		
		/// A list of rules applicable to the operation
		public let rules: [AirMapRule]
	}
	
	/// A representation of the validation of a flight feature performed by AirMap or a third-party authority
	public struct Validation {
		
		/// The description of the validation
		public let description: String
		
		/// The status of the validation
		public let status: Status
		
		/// The authoritative entity performing the validation
		public let authority: AirMapAuthority
		
		/// A message returned by the validation engine or upstream entity
		public let message: String
		
		/// A enumeration of the possible validation states
		///
		/// - pending: The request with the authority has been made and a response is pending
		/// - accepted: The request with the authority has been accepted
		/// - rejected: The request with the authority has been rejected
		/// - notRequested: The request with the authority has not been requested
		public enum Status: String {
			case pending
			case accepted
			case rejected
			case notRequested = "not_requested"
			
			public var description: String {
				let localized = LocalizedStrings.Validation.self
				switch self {
				case .pending:
					return localized.pending
				case .accepted:
					return localized.accepted
				case .rejected:
					return localized.rejected
				case .notRequested:
					return localized.notRequested
				}
			}
		}
	}

	@available(*, renamed: "AirMapAuthorization")
	public typealias Authorization = AirMapAuthorization
}
