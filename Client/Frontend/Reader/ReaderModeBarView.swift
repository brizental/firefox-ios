// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

enum ReaderModeBarButtonType {
    case markAsRead, markAsUnread, settings, addToReadingList, removeFromReadingList

    fileprivate var localizedDescription: String {
        switch self {
        case .markAsRead: return .ReaderModeBarMarkAsRead
        case .markAsUnread: return .ReaderModeBarMarkAsUnread
        case .settings: return .ReaderModeBarSettings
        case .addToReadingList: return .ReaderModeBarAddToReadingList
        case .removeFromReadingList: return .ReaderModeBarRemoveFromReadingList
        }
    }

    fileprivate var imageName: String {
        switch self {
        case .markAsRead: return "MarkAsRead"
        case .markAsUnread: return "MarkAsUnread"
        case .settings: return "SettingsSerif"
        case .addToReadingList: return ImageIdentifiers.addToReadingList
        case .removeFromReadingList: return ImageIdentifiers.removeFromReadingList
        }
    }

    fileprivate var image: UIImage? {
        let image = UIImage(named: imageName)
        image?.accessibilityLabel = localizedDescription
        return image
    }
}

protocol ReaderModeBarViewDelegate {
    func readerModeBar(_ readerModeBar: ReaderModeBarView, didSelectButton buttonType: ReaderModeBarButtonType)
}

class ReaderModeBarView: UIView, AlphaDimmable, TopBottomInterchangeable {
    var delegate: ReaderModeBarViewDelegate?

    var parent: UIStackView?
    private var isBottomPresented: Bool {
        BrowserViewController.foregroundBVC().isBottomSearchBar
    }
    var readStatusButton: UIButton!
    var settingsButton: UIButton!
    var listStatusButton: UIButton!

    @objc dynamic var buttonTintColor = UIColor.clear {
        didSet {
            readStatusButton.tintColor = self.buttonTintColor
            settingsButton.tintColor = self.buttonTintColor
            listStatusButton.tintColor = self.buttonTintColor
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        readStatusButton = createButton(.markAsRead, action: #selector(tappedReadStatusButton))
        readStatusButton.accessibilityIdentifier = "ReaderModeBarView.readStatusButton"
        readStatusButton.snp.makeConstraints { (make) -> Void in
            make.left.equalTo(self.safeArea.left)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        settingsButton = createButton(.settings, action: #selector(tappedSettingsButton))
        settingsButton.accessibilityIdentifier = "ReaderModeBarView.settingsButton"
        settingsButton.snp.makeConstraints { (make) -> Void in
            make.height.centerX.centerY.equalTo(self)
            make.width.equalTo(80)
        }

        listStatusButton = createButton(.addToReadingList, action: #selector(tappedListStatusButton))
        listStatusButton.accessibilityIdentifier = "ReaderModeBarView.listStatusButton"
        listStatusButton.snp.makeConstraints { (make) -> Void in
            make.right.equalTo(self.safeArea.right)
            make.height.centerY.equalTo(self)
            make.width.equalTo(80)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(0.5)
        context.setStrokeColor(UIColor.Photon.Grey50.cgColor)
        context.beginPath()
        let yPosition = isBottomPresented ? 0 : frame.height
        context.move(to: CGPoint(x: 0, y: yPosition))
        context.addLine(to: CGPoint(x: frame.width, y: yPosition))
        context.strokePath()
    }

    fileprivate func createButton(_ type: ReaderModeBarButtonType, action: Selector) -> UIButton {
        let button = UIButton()
        addSubview(button)
        button.setImage(type.image, for: [])
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func updateAlphaForSubviews(_ alpha: CGFloat) {
        self.alpha = alpha
    }

    @objc func tappedReadStatusButton(_ sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: unread ? .markAsRead : .markAsUnread)
    }

    @objc func tappedSettingsButton(_ sender: UIButton!) {
        delegate?.readerModeBar(self, didSelectButton: .settings)
    }

    @objc func tappedListStatusButton(_ sender: UIButton!) {
        TelemetryWrapper.recordEvent(category: .action, method: added ? .delete : .add, object: .readingListItem, value: .readerModeToolbar)
        delegate?.readerModeBar(self, didSelectButton: added ? .removeFromReadingList : .addToReadingList)
    }

    var unread: Bool = true {
        didSet {
            let buttonType: ReaderModeBarButtonType = unread && added ? .markAsRead : .markAsUnread
            readStatusButton.setImage(buttonType.image, for: [])
            readStatusButton.isEnabled = added
            readStatusButton.alpha = added ? 1.0 : 0.6
        }
    }

    var added: Bool = false {
        didSet {
            let buttonType: ReaderModeBarButtonType = added ? .removeFromReadingList : .addToReadingList
            listStatusButton.setImage(buttonType.image, for: [])
        }
    }
}

extension ReaderModeBarView: NotificationThemeable {

    func applyTheme() {
        backgroundColor = UIColor.theme.browser.background
        buttonTintColor = UIColor.theme.browser.tint
    }
}
