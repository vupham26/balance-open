//
//  AddAccountViewController.swift
//  Bal
//
//  Created by Benjamin Baron on 4/27/16.
//  Copyright © 2016 Balanced Software, Inc. All rights reserved.
//

import Foundation
import SnapKit

class AddAccountViewController: NSViewController {
    
    typealias ButtonFunction = (_ bounds: NSRect, _ original: Bool, _ hover: Bool, _ pressed: Bool) -> (Void)
    fileprivate let buttonVertPadding = 12.0
    
    //
    // MARK: - Properties -
    //
    
    var allowSelection = true
    var backFunction: (() -> Void)?
    
    // Container views
    fileprivate let containerView = View()
    fileprivate let buttonContainerView = View()
    
    // Main fields
    fileprivate let welcomeField = LabelField()
    fileprivate let subtitleField = LabelField()
    fileprivate let requestExplanationField = LabelField()
    fileprivate let backButton = Button()
    fileprivate let statusField = LabelField()
    fileprivate let preferencesButton = Button()
    
    // Buttons
    fileprivate var buttons = [HoverButton]()
    fileprivate let buttonDrawFunctions: [Source: ButtonFunction] = [.coinbase: AddAccountButtons.drawBoaButton,
                                                                     .gdax:     AddAccountButtons.drawBoaButton,
                                                                     .poloniex: AddAccountButtons.drawBoaButton,
                                                                     .bitfinex: AddAccountButtons.drawBoaButton]
    fileprivate let buttonSourceOrder: [Source] = [.coinbase, .gdax, .poloniex, .bitfinex]
    
    //
    // MARK: - Lifecycle -
    //
    
    init() {
        super.init(nibName: nil, bundle: nil)!
    }
    
    required init?(coder: NSCoder) {
        fatalError("unsupported")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Block preferences if no institutions
        if !Institution.hasInstitutions {
            addShortcutMonitor()
        }
    }
    
    deinit {
        removeShortcutMonitor()
    }
    
    fileprivate var hackDelay = 0.25
    fileprivate var hackDelayCount = 2
    override func viewWillAppear() {
        super.viewWillAppear()
        
        welcomeField.stringValue = "Balance"
        subtitleField.stringValue = "Connect to an exchange"
        requestExplanationField.stringValue = "Read-only API access to your account"
        
        backButton.isHidden = !Institution.hasInstitutions && allowSelection
    }
    
    //
    // MARK: - Create View -
    //
    
    override func loadView() {
        self.view = View()
        
        self.view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.equalTo(self.view)
            make.right.equalTo(self.view)
            make.top.equalTo(self.view)
            make.bottom.equalTo(self.view)
        }
        
        let logoImage = #imageLiteral(resourceName: "intro-logo")
        let logoImageView = ImageView()
        logoImageView.image = logoImage
        containerView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { make in
            make.width.equalTo(logoImage.size.width)
            make.height.equalTo(logoImage.size.height)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(25)
        }
        
//        let trianglesImage = isLight ? #imageLiteral(resourceName: "intro-light-triangles") : #imageLiteral(resourceName: "intro-dark-triangles")
        let trianglesImage = #imageLiteral(resourceName: "intro-dark-triangles")
        let trianglesImageView = ImageView()
        trianglesImageView.image = trianglesImage
        containerView.addSubview(trianglesImageView)
        trianglesImageView.snp.makeConstraints { make in
            make.width.equalTo(trianglesImage.size.width)
            make.height.equalTo(trianglesImage.size.height)
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        welcomeField.font = NSFont.mediumSystemFont(ofSize: 28)//CurrentTheme.addAccounts.welcomeFont
        welcomeField.textColor = CurrentTheme.defaults.foregroundColor
        welcomeField.alignment = .center
        welcomeField.usesSingleLineMode = true
        containerView.addSubview(welcomeField)
        welcomeField.snp.makeConstraints { make in
            make.leading.equalTo(containerView).inset(10)
            make.trailing.equalTo(containerView).inset(10)
            make.top.equalTo(logoImageView.snp.bottom).offset(25)
        }
        
        subtitleField.font = NSFont.mediumSystemFont(ofSize: 18)//CurrentTheme.addAccounts.welcomeFont
        subtitleField.textColor = CurrentTheme.defaults.foregroundColor
        subtitleField.alignment = .center
        subtitleField.usesSingleLineMode = true
        containerView.addSubview(subtitleField)
        subtitleField.snp.makeConstraints { make in
            make.leading.equalTo(containerView).inset(10)
            make.trailing.equalTo(containerView).inset(10)
            make.top.equalTo(welcomeField.snp.bottom).offset(10)
        }
        
        requestExplanationField.font = NSFont.mediumSystemFont(ofSize: 14)//CurrentTheme.addAccounts.welcomeFont
        requestExplanationField.textColor = CurrentTheme.defaults.foregroundColor
        requestExplanationField.alignment = .center
        requestExplanationField.alphaValue = 0.6
        requestExplanationField.usesSingleLineMode = true
        containerView.addSubview(requestExplanationField)
        requestExplanationField.snp.makeConstraints { make in
            make.leading.equalTo(containerView).inset(10)
            make.trailing.equalTo(containerView).inset(10)
            make.top.equalTo(subtitleField.snp.bottom).offset(10)
        }
        
        backButton.isHidden = true
        backButton.bezelStyle = .rounded
        backButton.font = NSFont.systemFont(ofSize: 14)
        backButton.title = "Back"
        backButton.setAccessibilityLabel("Back")
        backButton.sizeToFit()
        backButton.target = self
        backButton.action = #selector(back)
        containerView.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.height.equalTo(25)
            make.bottom.equalTo(containerView).inset(15)
            make.left.equalTo(containerView).inset(15)
        }
        
        containerView.addSubview(buttonContainerView)
        buttonContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(requestExplanationField.snp.bottom).offset(15)
            make.bottom.equalTo(backButton.snp.top).offset(-10)
        }
        
        createButtons()
        
        var isLight = false
        
        let buttonBlueColor = isLight ? NSColor(deviceRedInt: 39, green: 132, blue: 240) : NSColor(deviceRedInt: 71, green: 152, blue: 244)
        let buttonAltBlueColor = isLight ? NSColor(deviceRedInt: 39, green: 132, blue: 240, alpha: 0.7) : NSColor(deviceRedInt: 71, green: 152, blue: 244, alpha: 0.7)
        
        let buttonAttributes = [NSForegroundColorAttributeName: buttonBlueColor,
                                NSFontAttributeName: NSFont.semiboldSystemFont(ofSize: 13)]
        let buttonAltAttributes = [NSForegroundColorAttributeName: buttonAltBlueColor,
                                   NSFontAttributeName: NSFont.semiboldSystemFont(ofSize: 13)]
        
        let securityButton = Button()
        securityButton.attributedTitle = NSAttributedString(string:"Security", attributes: buttonAttributes)
        securityButton.attributedAlternateTitle = NSAttributedString(string:"Security", attributes: buttonAltAttributes)
        securityButton.setAccessibilityLabel("Security")
        securityButton.isBordered = false
        securityButton.setButtonType(.momentaryChange)
        securityButton.target = self
        securityButton.sizeToFit()
//        securityButton.action = #selector(restoreSubscription)
        containerView.addSubview(securityButton)
        securityButton.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(containerView).offset(13)
            make.bottom.equalTo(containerView.snp.bottom).inset(10)
        }
//        subscribeButtons.append(securityButton)
        
        let dotLabel1 = LabelField()
        dotLabel1.stringValue = "•"
        dotLabel1.font = .semiboldSystemFont(ofSize: 13)
        dotLabel1.textColor = buttonBlueColor
        dotLabel1.verticalAlignment = .center
        dotLabel1.sizeToFit()
        containerView.addSubview(dotLabel1)
        dotLabel1.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(securityButton.snp.right).offset(5)
            make.top.equalTo(securityButton)
        }
        
        let privacyButton = Button()
        privacyButton.attributedTitle = NSAttributedString(string:"Privacy", attributes: buttonAttributes)
        privacyButton.attributedAlternateTitle = NSAttributedString(string:"Privacy", attributes: buttonAltAttributes)
        privacyButton.setAccessibilityLabel("Privacy")
        privacyButton.isBordered = false
        privacyButton.setButtonType(.momentaryChange)
        privacyButton.target = self
        privacyButton.sizeToFit()
//        privacyButton.action = #selector(privacy)
        containerView.addSubview(privacyButton)
        privacyButton.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(dotLabel1.snp.right).offset(5)
            make.top.equalTo(securityButton)
        }
        
        let dotLabel2 = LabelField()
        dotLabel2.stringValue = "•"
        dotLabel2.font = .semiboldSystemFont(ofSize: 13)
        dotLabel2.textColor = buttonBlueColor
        dotLabel2.verticalAlignment = .center
        dotLabel2.sizeToFit()
        containerView.addSubview(dotLabel2)
        dotLabel2.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(privacyButton.snp.right).offset(5)
            make.top.equalTo(securityButton)
        }
        
        let termsButton = Button()
        termsButton.attributedTitle = NSAttributedString(string:"Terms", attributes: buttonAttributes)
        termsButton.attributedAlternateTitle = NSAttributedString(string:"Terms", attributes: buttonAltAttributes)
        termsButton.setAccessibilityLabel("Terms")
        termsButton.isBordered = false
        termsButton.setButtonType(.momentaryChange)
        termsButton.target = self
        termsButton.sizeToFit()
//        termsButton.action = #selector(terms)
        containerView.addSubview(termsButton)
        termsButton.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(dotLabel2.snp.right).offset(5)
            make.top.equalTo(securityButton)
        }
        
        let dotLabel3 = LabelField()
        dotLabel3.stringValue = "•"
        dotLabel3.font = .semiboldSystemFont(ofSize: 13)
        dotLabel3.textColor = buttonBlueColor
        dotLabel3.verticalAlignment = .center
        dotLabel3.sizeToFit()
        containerView.addSubview(dotLabel3)
        dotLabel3.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(termsButton.snp.right).offset(5)
            make.top.equalTo(securityButton)
        }
        
        let githubButton = Button()
        githubButton.attributedTitle = NSAttributedString(string:"GitHub", attributes: buttonAttributes)
        githubButton.attributedAlternateTitle = NSAttributedString(string:"GitHub", attributes: buttonAltAttributes)
        githubButton.setAccessibilityLabel("GitHub")
        githubButton.isBordered = false
        githubButton.setButtonType(.momentaryChange)
        githubButton.target = self
        githubButton.sizeToFit()
//        contactButton.action = #selector(contact)
        containerView.addSubview(githubButton)
        githubButton.snp.makeConstraints { make in
            make.height.equalTo(20)
            make.left.equalTo(dotLabel3.snp.right).offset(5)
            make.top.equalTo(securityButton)
        }
        
        if allowSelection && Institution.institutionsCount == 0 {
            // Preferences button
            preferencesButton.target = self
            preferencesButton.action = #selector(showSettingsMenu(_:))
            let preferencesIcon = CurrentTheme.tabs.footer.preferencesIcon
            preferencesButton.image = preferencesIcon
            preferencesButton.setButtonType(.momentaryChange)
            preferencesButton.setAccessibilityLabel("Preferences")
            preferencesButton.isBordered = false
            self.view.addSubview(preferencesButton)
            preferencesButton.snp.makeConstraints { make in
                make.bottom.equalTo(self.view).offset(-11)
                make.trailing.equalTo(self.view).offset(-11)
                make.width.equalTo(16)
                make.height.equalTo(16)
            }
        }
    }
    
    fileprivate func createButtons() {
        func assignBlocks(button: HoverButton, bounds: NSRect, function: @escaping ButtonFunction) {
            button.originalBlock = {
                function(bounds, true, false, false)
            }
            
            if allowSelection {
                button.hoverBlock = {
                    function(bounds, false, true, false)
                }
                button.pressedBlock = {
                    function(bounds, false, false, true)
                }
            }
        }
        
        let buttonWidth = 191.0
        let buttonHeight = 56.0
        let buttonHorizPadding = 8.5
        let buttonVertPadding = -1
        let buttonSize = NSRect(x: 0, y: 0, width: buttonWidth, height: buttonHeight)
        
        var tag = 0
        var isRightColumn = false
        var topView: NSView? = nil
        for source in buttonSourceOrder {
            if let drawFunction = buttonDrawFunctions[source] {
                let button = HoverButton(frame: buttonSize)
                
                button.target = self
                button.action = #selector(buttonAction(_:))
                button.tag = tag
                button.setAccessibilityLabel(source.description)
                
                assignBlocks(button: button, bounds: buttonSize, function: drawFunction)
                buttonContainerView.addSubview(button)
                button.snp.makeConstraints { make in
                    make.width.equalTo(buttonWidth)
                    make.height.equalTo(buttonHeight)
                    
                    if let topView = topView {
                        make.top.equalTo(topView.snp.bottom).offset(buttonVertPadding)
                    } else {
                        make.top.equalTo(buttonContainerView)
                    }
                    
                    if isRightColumn {
                        make.right.equalTo(buttonContainerView).inset(buttonHorizPadding + 0.5)
                    } else {
                        make.left.equalTo(buttonContainerView).offset(buttonHorizPadding + 0.5)
                    }
                }
                
                buttons.append(button)
                
                if isRightColumn {
                    topView = button
                }
                isRightColumn = !isRightColumn
            }
            tag += 1
        }
    }
    
    fileprivate func removeButtons() {
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons = []
    }
    
    // MARK: - Actions -
    
    @objc fileprivate func back() {
        if let backFunction = backFunction {
            backFunction()
        } else {
            NotificationCenter.postOnMainThread(name: Notifications.ShowTabIndex, object: nil, userInfo: [Notifications.Keys.TabIndex: Tab.accounts.rawValue])
            NotificationCenter.postOnMainThread(name: Notifications.ShowTabs)
        }
    }
    
    @objc fileprivate func buttonAction(_ sender: NSButton) {
        if allowSelection, let source = Source(rawValue: sender.tag) {
            // TODO: Implement this
        }
    }
    
    func showSettingsMenu(_ sender: NSButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Send Feedback", action: #selector(sendFeedback), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit Balance", action: #selector(quitApp), keyEquivalent: "q")
        
        let event = NSApplication.shared().currentEvent ?? NSEvent()
        NSMenu.popUpContextMenu(menu, with: event, for: sender)
    }
    
    func sendFeedback() {
        AppDelegate.sharedInstance.sendFeedback()
    }
    
    func quitApp() {
        AppDelegate.sharedInstance.quitApp()
    }
    
    // MARK: - Prefs Window Blocking -
    
    // Block preferences window from opening
    fileprivate var shortcutMonitor: Any?
    func addShortcutMonitor() {
        if shortcutMonitor == nil {
            shortcutMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event -> NSEvent? in
                if let characters = event.charactersIgnoringModifiers {
                    if event.modifierFlags.contains(.command) && characters.length == 1 {
                        if characters == "," {
                            // Return nil to eat the event
                            return nil
                        } else if characters == "h" {
                            NotificationCenter.postOnMainThread(name: Notifications.HidePopover)
                            return nil
                        }
                    }
                }
                return event
            }
        }
    }
    
    func removeShortcutMonitor() {
        if let monitor = shortcutMonitor {
            NSEvent.removeMonitor(monitor)
            shortcutMonitor = nil
        }
    }
}