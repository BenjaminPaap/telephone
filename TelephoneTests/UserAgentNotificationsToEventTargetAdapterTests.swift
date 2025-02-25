//
//  UserAgentNotificationsToObservingAdapterTests.swift
//  Telephone
//
//  Copyright (c) 2008-2016 Alexey Kuznetsov
//  Copyright (c) 2016 64 Characters
//
//  Telephone is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Telephone is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

import UseCases
import UseCasesTestDoubles
import XCTest

class UserAgentNotificationsToEventTargetAdapterTests: XCTestCase {
    private var target: UserAgentEventTargetSpy!
    private var sut: UserAgentNotificationsToEventTargetAdapter!
    private var userAgent: UserAgent!
    private var notificationCenter: NSNotificationCenter!

    override func setUp() {
        super.setUp()
        target = UserAgentEventTargetSpy()
        userAgent = UserAgentSpy()
        sut = UserAgentNotificationsToEventTargetAdapter(target: target, userAgent: userAgent)
        notificationCenter = NSNotificationCenter.defaultCenter()
    }

    func testCallsDidFinishStarting() {
        notificationCenter.postNotification(notificationWithName(AKSIPUserAgentDidFinishStartingNotification))

        XCTAssertTrue(target.didCallUserAgentDidFinishStarting)
    }

    func testCallsDidFinishStopping() {
        notificationCenter.postNotification(notificationWithName(AKSIPUserAgentDidFinishStoppingNotification))

        XCTAssertTrue(target.didCallUserAgentDidFinishStopping)
    }

    func testCallsDidDetectNAT() {
        notificationCenter.postNotification(notificationWithName(AKSIPUserAgentDidDetectNATNotification))

        XCTAssertTrue(target.didCallUserAgentDidDetectNAT)
    }

    private func notificationWithName(name: String) -> NSNotification {
        return NSNotification(name: name, object: userAgent)
    }
}
