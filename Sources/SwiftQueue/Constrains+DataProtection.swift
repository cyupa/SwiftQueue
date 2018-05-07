//
// Created by Ciprian Redinciuc on 07/05/2018.
//

import Foundation
#if os(iOS)
import UIKit
#endif

#if os(iOS)
internal final class DataProtectionConstraint: JobConstraint {

    // To avoid cyclic ref
    private weak var actual: SqOperation?

    func dataProtectionStateDidChange(notification: NSNotification) {
        DispatchQueue.main.async {
            let isLocked = !UIApplication.shared.isProtectedDataAvailable
            if isLocked {
                actual?.run()
                NotificationCenter.default.removeObserver(self)
            }
        }
    }

    func willSchedule(queue: SqOperationQueue, operation: SqOperation) throws {}

    func willRun(operation: SqOperation) throws {}

    func run(operation: SqOperation) -> Bool {
        guard operation.info.requireDataProtection else {
            return true
        }

        var isLocked = false
        DispatchQueue.main.sync {
            isLocked = !UIApplication.shared.isProtectedDataAvailable

        }
        
        if isLocked {
            return true
        }

        NotificationCenter.default.addObserver(self, selector: Selector(("dataProtectionStateDidChange:")), name: NSNotification.Name.UIApplicationProtectedDataDidBecomeAvailable, object: nil)

        operation.logger.log(.verbose, jobId: operation.info.uuid, message: "Unsatisfied data protection requirement")
        return false
    }

}

#else

internal final class DataProtectionConstraint: DefaultNoConstraint {}

#endif
