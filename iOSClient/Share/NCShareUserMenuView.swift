//
//  NCShareUserMenuView.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 25/07/2019.
//  Copyright © 2019 Marino Faggiana. All rights reserved.
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

import Foundation
import FSCalendar

class NCShareUserMenuView: UIView, UIGestureRecognizerDelegate, NCShareNetworkingDelegate, FSCalendarDelegate, FSCalendarDelegateAppearance {
    
    @IBOutlet weak var switchCanReshare: UISwitch!
    @IBOutlet weak var labelCanReshare: UILabel!
    
    @IBOutlet weak var switchCanCreate: UISwitch!
    @IBOutlet weak var labelCanCreate: UILabel!
    
    @IBOutlet weak var switchCanChange: UISwitch!
    @IBOutlet weak var labelCanChange: UILabel!
    
    @IBOutlet weak var switchCanDelete: UISwitch!
    @IBOutlet weak var labelCanDelete: UILabel!
    
    @IBOutlet weak var switchSetExpirationDate: UISwitch!
    @IBOutlet weak var labelSetExpirationDate: UILabel!
    @IBOutlet weak var fieldSetExpirationDate: UITextField!
    
    @IBOutlet weak var imageNoteToRecipient: UIImageView!
    @IBOutlet weak var labelNoteToRecipient: UILabel!
    @IBOutlet weak var fieldNoteToRecipient: UITextField!
    
    @IBOutlet weak var buttonUnshare: UIButton!
    @IBOutlet weak var labelUnshare: UILabel!
    @IBOutlet weak var imageUnshare: UIImageView!
    
    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var width: CGFloat = 0
    var height: CGFloat = 0
    
    private var tableShare: tableShare?
    var metadata: tableMetadata?
    var shareViewController: NCShare?
    
    var viewWindow: UIView?
    var viewWindowCalendar: UIView?
    
    override func awakeFromNib() {
        
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 5
        layer.masksToBounds = false
        layer.shadowOffset = CGSize(width: 2, height: 2)
        layer.shadowOpacity = 0.2
        
        switchCanReshare.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanReshare.onTintColor = NCBrandColor.sharedInstance.brand
        switchCanCreate?.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanCreate?.onTintColor = NCBrandColor.sharedInstance.brand
        switchCanChange?.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanChange?.onTintColor = NCBrandColor.sharedInstance.brand
        switchCanDelete?.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchCanDelete?.onTintColor = NCBrandColor.sharedInstance.brand
        switchSetExpirationDate.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        switchSetExpirationDate.onTintColor = NCBrandColor.sharedInstance.brand
        
        fieldSetExpirationDate.inputView = UIView()
        
        imageNoteToRecipient.image = CCGraphics.changeThemingColorImage(UIImage.init(named: "file_txt"), width: 100, height: 100, color: UIColor(red: 76/255, green: 76/255, blue: 76/255, alpha: 1))
        imageUnshare.image = CCGraphics.changeThemingColorImage(UIImage.init(named: "trash"), width: 100, height: 100, color: UIColor(red: 76/255, green: 76/255, blue: 76/255, alpha: 1))
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        
        if newWindow == nil {
            // UIView disappear
            shareViewController?.reloadData()
        } else {
            // UIView appear
        }
    }
    
    func unLoad() {
        viewWindowCalendar?.removeFromSuperview()
        viewWindow?.removeFromSuperview()
        
        viewWindowCalendar = nil
        viewWindow = nil
    }
    
    func reloadData(idRemoteShared: Int) {
        
        guard let metadata = self.metadata else { return }
        tableShare = NCManageDatabase.sharedInstance.getTableShare(account: metadata.account, idRemoteShared: idRemoteShared)
        guard let tableShare = self.tableShare else { return }

        // Can reshare (file)
        let canReshare = UtilsFramework.isPermission(toCanShare: tableShare.permissions)
        switchCanReshare.setOn(canReshare, animated: false)
        
        if metadata.directory {
            // Can create (folder)
            let canCreate = UtilsFramework.isPermission(toCanCreate: tableShare.permissions)
            switchCanCreate.setOn(canCreate, animated: false)
            
            // Can change (folder)
            let canChange = UtilsFramework.isPermission(toCanChange: tableShare.permissions)
            switchCanChange.setOn(canChange, animated: false)
            
            // Can delete (folder)
            let canDelete = UtilsFramework.isPermission(toCanDelete: tableShare.permissions)
            switchCanDelete.setOn(canDelete, animated: false)
        }
        
        // Set expiration date
        if tableShare.expirationDate != nil {
            switchSetExpirationDate.setOn(true, animated: false)
            fieldSetExpirationDate.isEnabled = true
            
            let dateFormatter = DateFormatter()
            dateFormatter.formatterBehavior = .behavior10_4
            dateFormatter.dateStyle = .medium
            fieldSetExpirationDate.text = dateFormatter.string(from: tableShare.expirationDate! as Date)
        } else {
            switchSetExpirationDate.setOn(false, animated: false)
            fieldSetExpirationDate.isEnabled = false
            fieldSetExpirationDate.text = ""
        }
        
        // Note to recipient
        fieldNoteToRecipient.text = tableShare.note
    }
    
    // MARK: - IBAction

    // Can reshare
    @IBAction func switchCanReshareChanged(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }

        let canEdit = UtilsFramework.isAnyPermission(toEdit: tableShare.permissions)
        let canCreate = UtilsFramework.isPermission(toCanCreate: tableShare.permissions)
        let canChange = UtilsFramework.isPermission(toCanChange: tableShare.permissions)
        let canDelete = UtilsFramework.isPermission(toCanDelete: tableShare.permissions)
        
        var permission: Int = 0
        
        if metadata.directory {
            permission = UtilsFramework.getPermissionsValue(byCanEdit: canEdit, andCanCreate: canCreate, andCanChange: canChange, andCanDelete: canDelete, andCanShare: sender.isOn, andIsFolder: metadata.directory)
        } else {
            if sender.isOn {
                if canEdit {
                    permission = UtilsFramework.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                } else {
                    permission = UtilsFramework.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                }
            } else {
                if canEdit {
                    permission = UtilsFramework.getPermissionsValue(byCanEdit: true, andCanCreate: true, andCanChange: true, andCanDelete: true, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                } else {
                    permission = UtilsFramework.getPermissionsValue(byCanEdit: false, andCanCreate: false, andCanChange: false, andCanDelete: false, andCanShare: sender.isOn, andIsFolder: metadata.directory)
                }
            }
        }
        
        let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: permission, note: nil, expirationTime: nil, hideDownload: tableShare.hideDownload, metadata: metadata)
    }
    
    @IBAction func switchCanCreate(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }

        let canEdit = UtilsFramework.isAnyPermission(toEdit: tableShare.permissions)
        let canChange = UtilsFramework.isPermission(toCanChange: tableShare.permissions)
        let canDelete = UtilsFramework.isPermission(toCanDelete: tableShare.permissions)
        let canShare = UtilsFramework.isPermission(toCanShare: tableShare.permissions)

        let permission = UtilsFramework.getPermissionsValue(byCanEdit: canEdit, andCanCreate: sender.isOn, andCanChange: canChange, andCanDelete: canDelete, andCanShare: canShare, andIsFolder: metadata.directory)

        let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: permission, note: nil, expirationTime: nil, hideDownload: tableShare.hideDownload, metadata: metadata)
    }
    
    @IBAction func switchCanChange(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }
        
        let canEdit = UtilsFramework.isAnyPermission(toEdit: tableShare.permissions)
        let canCreate = UtilsFramework.isPermission(toCanCreate: tableShare.permissions)
        let canDelete = UtilsFramework.isPermission(toCanDelete: tableShare.permissions)
        let canShare = UtilsFramework.isPermission(toCanShare: tableShare.permissions)
        
        let permission = UtilsFramework.getPermissionsValue(byCanEdit: canEdit, andCanCreate: canCreate, andCanChange: sender.isOn, andCanDelete: canDelete, andCanShare: canShare, andIsFolder: metadata.directory)

        let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: permission, note: nil, expirationTime: nil, hideDownload: tableShare.hideDownload, metadata: metadata)
    }
    
    @IBAction func switchCanDelete(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }
        
        let canEdit = UtilsFramework.isAnyPermission(toEdit: tableShare.permissions)
        let canCreate = UtilsFramework.isPermission(toCanCreate: tableShare.permissions)
        let canChange = UtilsFramework.isPermission(toCanChange: tableShare.permissions)
        let canShare = UtilsFramework.isPermission(toCanShare: tableShare.permissions)
        
        let permission = UtilsFramework.getPermissionsValue(byCanEdit: canEdit, andCanCreate: canCreate, andCanChange: canChange, andCanDelete: sender.isOn, andCanShare: canShare, andIsFolder: metadata.directory)

        let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: permission, note: nil, expirationTime: nil, hideDownload: tableShare.hideDownload, metadata: metadata)
    }
    
    // Set expiration date
    @IBAction func switchSetExpirationDate(sender: UISwitch) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }
        
        if sender.isOn {
            fieldSetExpirationDate.isEnabled = true
            fieldSetExpirationDate(sender: fieldSetExpirationDate)
        } else {
            let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
            networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: 0, note: nil, expirationTime: "", hideDownload: tableShare.hideDownload, metadata: metadata)
        }
    }
    
    @IBAction func fieldSetExpirationDate(sender: UITextField) {
        
        let calendar = NCShareCommon.sharedInstance.openCalendar(view: self, width: width, height: height)
        calendar.calendarView.delegate = self
        viewWindowCalendar = calendar.viewWindow
    }
    
    // Note to recipient
    @IBAction func fieldNoteToRecipientDidEndOnExit(textField: UITextField) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }
        if fieldNoteToRecipient.text == nil { return }
        
        let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: 0, note: fieldNoteToRecipient.text, expirationTime: nil, hideDownload: tableShare.hideDownload, metadata: metadata)
    }
    
    // Unshare
    @IBAction func buttonUnshare(sender: UIButton) {
        
        guard let tableShare = self.tableShare else { return }
        guard let metadata = self.metadata else { return }

        let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
        
        networking.unShare(idRemoteShared: tableShare.idRemoteShared)
    }
    
    // MARK: - Delegate networking
    
    func readShareCompleted() {
        reloadData(idRemoteShared: tableShare?.idRemoteShared ?? 0)
    }
    
    func shareCompleted() {
        unLoad()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadDataNCShare"), object: nil, userInfo: nil)
    }
    
    func unShareCompleted() {
        unLoad()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadDataNCShare"), object: nil, userInfo: nil)
    }
    
    func updateShareWithError(idRemoteShared: Int) {
        reloadData(idRemoteShared: idRemoteShared)
    }
    
    func getUserAndGroup(items: [OCShareUser]?) { }
    
    // MARK: - Delegate calendar

    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        
        if monthPosition == .previous || monthPosition == .next {
            calendar.setCurrentPage(date, animated: true)
        } else {
            let dateFormatter = DateFormatter()
            dateFormatter.formatterBehavior = .behavior10_4
            dateFormatter.dateStyle = .medium
            fieldSetExpirationDate.text = dateFormatter.string(from:date)
            fieldSetExpirationDate.endEditing(true)
            
            viewWindowCalendar?.removeFromSuperview()
            
            guard let tableShare = self.tableShare else { return }
            guard let metadata = self.metadata else { return }
            
            let networking = NCShareNetworking.init(account: metadata.account, activeUrl: appDelegate.activeUrl,  view: self, delegate: self)
            dateFormatter.dateFormat = "YYYY-MM-dd"
            let expirationTime = dateFormatter.string(from: date)
            networking.updateShare(idRemoteShared: tableShare.idRemoteShared, password: nil, permission: 0, note: nil, expirationTime: expirationTime, hideDownload: tableShare.hideDownload, metadata: metadata)
        }
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return date > Date()
    }
    
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if date > Date() {
            return UIColor(red: 60/255, green: 60/255, blue: 60/255, alpha: 1)
        } else {
            return UIColor(red: 190/255, green: 190/255, blue: 190/255, alpha: 1)
        }
    }
}
