//
//  LockscreenData.swift
//  Widget
//
//  Created by Marino Faggiana on 13/10/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import WidgetKit
import NextcloudKit

struct LockscreenData: TimelineEntry {
    let date: Date
    let isPlaceholder: Bool
    let activity: String
    let link: URL
    let quotaRelative: Float
    let quotaUsed: String
    let quotaTotal: String
}

func getLockscreenDataEntry(configuration: AccountIntent?, isPreview: Bool, completion: @escaping (_ entry: LockscreenData) -> Void) {

    var account: tableAccount?

    if isPreview {
        return completion(LockscreenData(date: Date(), isPlaceholder: true, activity: "", link: URL(string: "https://")!, quotaRelative: 0, quotaUsed: "", quotaTotal: ""))
    }

    let accountIdentifier: String = configuration?.Accounts?.identifier ?? "active"
    if accountIdentifier == "active" {
        account = NCManageDatabase.shared.getActiveAccount()
    } else {
        account = NCManageDatabase.shared.getAccount(predicate: NSPredicate(format: "account == %@", accountIdentifier))
    }

    guard let account = account else {
        return completion(LockscreenData(date: Date(), isPlaceholder: true, activity: "", link: URL(string: "https://")!, quotaRelative: 0, quotaUsed: "", quotaTotal: ""))
    }

    var quotaRelative: Float = 0
    if account.quotaRelative > 0 {
        quotaRelative = Float(account.quotaRelative) / 100
    }
    let quotaUsed: String = CCUtility.transformedSize(account.quotaUsed)
    var quotaTotal: String = ""

    switch account.quotaTotal {
    case -1:
        quotaTotal = ""
    case -2:
        quotaTotal = ""
    case -3:
        quotaTotal = ""
    default:
        quotaTotal = CCUtility.transformedSize(account.quotaTotal)
    }

    let serverVersionMajor = NCManageDatabase.shared.getCapabilitiesServerInt(account: account.account, elements: NCElementsJSON.shared.capabilitiesVersionMajor)
    if serverVersionMajor >= NCGlobal.shared.nextcloudVersion25 {

        // NETWORKING
        let password = CCUtility.getPassword(account.account)!
        NKCommon.shared.setup(
            account: account.account,
            user: account.user,
            userId: account.userId,
            password: password,
            urlBase: account.urlBase,
            userAgent: CCUtility.getUserAgent(),
            nextcloudVersion: 0,
            delegate: NCNetworking.shared)

        let options = NKRequestOptions(timeout: 15, queue: NKCommon.shared.backgroundQueue)
        NextcloudKit.shared.getDashboardWidgetsApplication("activity", options: options) { _, results, _, error in
            var activity: String = NSLocalizedString("_no_data_available_", comment: "")
            var link = URL(string: "https://")!
            if error == .success, let result = results?.first {
                if let item = result.items?.first {
                    if let title = item.title {  activity = title }
                    if let itemLink = item.link, let url = URL(string: itemLink) { link = url }
                }
            }
            completion(LockscreenData(date: Date(), isPlaceholder: false, activity: activity, link: link, quotaRelative: quotaRelative, quotaUsed: quotaUsed, quotaTotal: quotaTotal))
        }
    } else {
        completion(LockscreenData(date: Date(), isPlaceholder: false, activity: NSLocalizedString("_widget_available_nc25_", comment: ""), link: URL(string: "https://")!, quotaRelative: quotaRelative, quotaUsed: quotaUsed, quotaTotal: quotaTotal))
    }
}
