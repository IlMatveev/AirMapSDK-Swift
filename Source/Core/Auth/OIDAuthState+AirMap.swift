//
//  OIDAuthState+AirMap.swift
//  AirMapSDK
//
//  Created by Michael Odere on 3/26/20.
//

import AppAuth

extension OIDAuthState {
	var isAccessTokenFresh: Bool {
		return lastTokenResponse?.accessTokenExpirationDate ?? .distantPast > Date()
	}
}
