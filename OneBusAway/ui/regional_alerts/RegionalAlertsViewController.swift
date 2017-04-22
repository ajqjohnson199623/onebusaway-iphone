//
//  RegionalAlertsViewController.swift
//  org.onebusaway.iphone
//
//  Created by Aaron Brethorst on 3/16/17.
//  Copyright © 2017 OneBusAway. All rights reserved.
//

import Foundation
import OBAKit
import SafariServices

class RegionalAlertsViewController: OBAStaticTableViewController {

    var focusedAlert: OBARegionalAlert?
    var regionalAlertsManager: RegionalAlertsManager
    let refreshControl = UIRefreshControl.init()

    convenience init(regionalAlertsManager: RegionalAlertsManager) {
        self.init(regionalAlertsManager: regionalAlertsManager, focusedAlert: nil)
    }

    init(regionalAlertsManager: RegionalAlertsManager, focusedAlert: OBARegionalAlert?) {
        self.regionalAlertsManager = regionalAlertsManager
        self.focusedAlert = focusedAlert
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.refreshControl.addTarget(self, action: #selector(reloadServerData), for: .valueChanged)
        self.tableView.addSubview(self.refreshControl)

        self.emptyDataSetDescription = NSLocalizedString("regional_alerts_controller.empty_description", comment: "Empty data set description for regional alerts controller")

        if let regionName = self.regionalAlertsManager.region?.regionName {
            let titleFormat = NSLocalizedString("regional_alerts_controller.title_format", comment: "Alerts for <REGION NAME>")
            self.title = String.init(format: titleFormat, regionName)
        }

        self.reloadData()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadData), name: RegionalAlertsManager.regionalAlertsUpdatedNotification, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let focusedAlert = self.focusedAlert {
            self.presentAlert(focusedAlert)
        }
    }

    // MARK: - Actions

    private func presentAlert(_ alert: OBARegionalAlert) {
        let safari = SFSafariViewController.init(url: alert.url)
        safari.modalPresentationStyle = .overFullScreen
        self.present(safari, animated: true) {
            self.regionalAlertsManager.markRead(alert)
            self.reloadData()
        }
    }

    // MARK: - Data Loading

    @objc private func reloadServerData() {
        self.regionalAlertsManager.update()
    }

    @objc private func reloadData() {
        let rows = self.regionalAlertsManager.regionalAlerts.map { alert -> OBAMessageRow in
            let tableRow = OBAMessageRow.init(action: { (row) in
                self.presentAlert(alert)
            })
            tableRow.accessoryType = .disclosureIndicator
            tableRow.date = alert.publishedAt
            tableRow.sender = alert.feedName
            tableRow.subject = alert.title
            tableRow.unread = alert.unread
            tableRow.highPriority = alert.priority == .high

            return tableRow
        }

        let section = OBATableSection.init(title: nil, rows: rows)
        self.sections = [section]
        self.refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
}
