//
// Created by Lucas Nelaupe on 29/8/17.
// Copyright (c) 2017 Lucas Nelaupe. All rights reserved.
//

import XCTest
@testable import SwiftQueue

class StartStopTests: XCTestCase {

    func testScheduleWhenQueueStop() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator)
                .set(persister: NoSerializer.shared)
                .set(isSuspended: true)
                .build()

        JobBuilder(type: type).schedule(manager: manager)

        // No run
        job.assertNoRun()

        manager.start()

        job.awaitForRemoval()
        job.assertSingleCompletion()
    }

    func testSchedulePeriodicJobThenStart() {
        let (type, job) = (UUID().uuidString, TestJob())

        let creator = TestCreator([type: job])

        let manager = SwiftQueueManagerBuilder(creator: creator).set(persister: NoSerializer.shared).build()

        manager.pause()

        JobBuilder(type: type).periodic(limit: .limited(4), interval: 0).schedule(manager: manager)

        // No run
        job.assertNoRun()

        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()
        manager.start()

        job.awaitForRemoval()

        job.assertRunCount(expected: 4)
        job.assertCompletedCount(expected: 1)
        job.assertRetriedCount(expected: 0)
        job.assertCanceledCount(expected: 0)
        job.assertNoError()
    }

}
