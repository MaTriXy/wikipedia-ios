import Foundation
import CocoaLumberjackSwift
import WMF

extension TalkPageTopicComposeViewController: TalkPageFormattingToolbarViewDelegate {

    func didSelectBold() {
        bodyTextView.addOrRemoveStringFormattingCharacters(formattingString: "'''")
    }

    func didSelectItalics() {
        bodyTextView.addOrRemoveStringFormattingCharacters(formattingString: "''")
    }

    func didSelectInsertLink() {
        if let range =  bodyTextView.selectedTextRange {
            let text = bodyTextView.text(in: range)
            preselectedTextRange = range

            var doesLinkExist = false

            if let start = bodyTextView.position(from: range.start, offset: -2),
               let end = bodyTextView.position(from: range.end, offset: 2),
               let newSelectedRange = bodyTextView.textRange(from: start, to: end) {

                if let newText = bodyTextView.text(in: newSelectedRange) {
                    if newText.contains("[") || newText.contains("]") {
                        doesLinkExist = true
                    } else {
                        doesLinkExist = false
                    }
                }
            }

            guard let link = Link(page: text, label: text, exists: doesLinkExist) else {
                return
            }

            if link.exists {
                guard let editLinkViewController = EditLinkViewController(link: link, siteURL: viewModel.siteURL, dataStore: MWKDataStore.shared()) else {
                    return
                }
                editLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: editLinkViewController, theme: self.theme)
                navigationController.isNavigationBarHidden = true
                present(navigationController, animated: true)
            } else {
                let insertLinkViewController = InsertLinkViewController(link: link, siteURL: viewModel.siteURL, dataStore: MWKDataStore.shared())
                insertLinkViewController.delegate = self
                let navigationController = WMFThemeableNavigationController(rootViewController: insertLinkViewController, theme: self.theme)
                present(navigationController, animated: true)
            }
        }
    }

}

extension TalkPageTopicComposeViewController: InsertLinkViewControllerDelegate {
    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func insertLinkViewController(_ insertLinkViewController: InsertLinkViewController, didInsertLinkFor page: String, withLabel label: String?) {
        insertLink(page: page)
        dismiss(animated: true)
    }

    func insertLink(page: String) {
        let content = "[[\(page)]]"
        bodyTextView.replace(preselectedTextRange, withText: content)

        let newStartPosition = bodyTextView.position(from: preselectedTextRange.start, offset: 2)
        let newEndPosition = bodyTextView.position(from: preselectedTextRange.start, offset: content.count-2)
        bodyTextView.selectedTextRange = bodyTextView.textRange(from: newStartPosition ?? bodyTextView.endOfDocument, to: newEndPosition ?? bodyTextView.endOfDocument)
    }
}

extension TalkPageTopicComposeViewController: EditLinkViewControllerDelegate {
    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didTapCloseButton button: UIBarButtonItem) {
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFinishEditingLink displayText: String?, linkTarget: String) {
        editLink(page: linkTarget, label: displayText)
        dismiss(animated: true)
    }

    func editLinkViewController(_ editLinkViewController: EditLinkViewController, didFailToExtractArticleTitleFromArticleURL articleURL: URL) {
        DDLogError("Failed to extract article title from \(articleURL)")
        dismiss(animated: true)
    }

    func editLinkViewControllerDidRemoveLink(_ editLinkViewController: EditLinkViewController) {
        if let range =  bodyTextView.selectedTextRange {
            preselectedTextRange = range

            if let start = bodyTextView.position(from: range.start, offset: -2),
               let end = bodyTextView.position(from: range.end, offset: 2),
               let newSelectedRange = bodyTextView.textRange(from: start, to: end) {
                bodyTextView.replace(newSelectedRange, withText: bodyTextView.text(in: preselectedTextRange) ?? String())

                let newStartPosition = bodyTextView.position(from: range.start, offset: -2)
                let newEndPosition = bodyTextView.position(from: range.end, offset: -2)
                bodyTextView.selectedTextRange = bodyTextView.textRange(from: newStartPosition ?? bodyTextView.endOfDocument, to: newEndPosition ?? bodyTextView.endOfDocument)
            }
        }
        dismiss(animated: true)
    }

    func editLink(page: String, label: String?) {
        if let label {
            bodyTextView.replace(preselectedTextRange, withText: "\(page)|\(label)")
        } else {
            bodyTextView.replace(preselectedTextRange, withText: "\(page)")
        }
    }

}
