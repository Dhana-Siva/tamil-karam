import UIKit

class KeyboardViewController: UIInputViewController {

    private let workerURL = "https://tamil-grammar-fix.dhanageetha2000.workers.dev/"
    private var isLoading = false
    private var heightConstraint: NSLayoutConstraint?

    private lazy var fixButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✓  Fix Tamil Grammar", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        btn.backgroundColor = UIColor(red: 0.90, green: 0.22, blue: 0.27, alpha: 1)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 12
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private lazy var statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Type Tamil, then tap Fix"
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 13)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var changeLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.textAlignment = .left
        lbl.font = .systemFont(ofSize: 12)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.isHidden = true
        lbl.layer.cornerRadius = 8
        lbl.clipsToBounds = true
        lbl.backgroundColor = UIColor.systemBackground
        return lbl
    }()

    private lazy var nextKeyboardButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("\u{1F310}", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground
        view.addSubview(nextKeyboardButton)
        view.addSubview(fixButton)
        view.addSubview(statusLabel)
        view.addSubview(changeLabel)

        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            fixButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),
            fixButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fixButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fixButton.heightAnchor.constraint(equalToConstant: 50),

            statusLabel.topAnchor.constraint(equalTo: fixButton.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            changeLabel.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 6),
            changeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            changeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        fixButton.addTarget(self, action: #selector(fixGrammarTapped), for: .touchUpInside)
    }

    @objc private func fixGrammarTapped() {
        guard !isLoading else { return }
        let before  = textDocumentProxy.documentContextBeforeInput ?? ""
        let after   = textDocumentProxy.documentContextAfterInput  ?? ""
        let originalText = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !originalText.isEmpty else { setStatus("No text found. Type some Tamil first."); return }

        hideChangeLabel()
        setLoading(true); setStatus("Fixing grammar…")

        guard let url = URL(string: workerURL) else { return }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "keyboard-ext"
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": originalText, "deviceId": deviceId])

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let corrected = json["corrected"] as? String
                else { self?.setStatus("Could not fix. Try again."); return }

                // Move cursor to end of text
                let ac = (self?.textDocumentProxy.documentContextAfterInput ?? "").count
                if ac > 0 {
                    self?.textDocumentProxy.adjustTextPosition(byCharacterOffset: ac)
                }
                // Loop to delete all text (documentContextBeforeInput can be truncated by iOS)
                var attempts = 0
                while attempts < 20 {
                    guard let before = self?.textDocumentProxy.documentContextBeforeInput, !before.isEmpty else { break }
                    for _ in 0..<before.count { self?.textDocumentProxy.deleteBackward() }
                    attempts += 1
                }
                self?.textDocumentProxy.insertText(corrected)

                // Show what changed
                if corrected.trimmingCharacters(in: .whitespacesAndNewlines) == originalText {
                    self?.setStatus("✅ No changes needed")
                } else {
                    self?.setStatus("✅ Fixed!")
                    self?.showChangeLabel(original: originalText, corrected: corrected)
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self?.setStatus("Type Tamil, then tap Fix")
                    self?.hideChangeLabel()
                }
            }
        }.resume()
    }

    private func showChangeLabel(original: String, corrected: String) {
        let attr = NSMutableAttributedString()

        // Before line
        attr.append(NSAttributedString(string: "Before: ", attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]))
        attr.append(NSAttributedString(string: original + "\n", attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.systemRed,
            .strikethroughStyle: NSUnderlineStyle.single.rawValue
        ]))

        // After line
        attr.append(NSAttributedString(string: "After:    ", attributes: [
            .font: UIFont.systemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: UIColor.secondaryLabel
        ]))
        attr.append(NSAttributedString(string: corrected, attributes: [
            .font: UIFont.systemFont(ofSize: 12),
            .foregroundColor: UIColor.systemGreen
        ]))

        changeLabel.attributedText = attr
        changeLabel.isHidden = false
        expandKeyboard()
    }

    private func hideChangeLabel() {
        changeLabel.isHidden = true
        collapseKeyboard()
    }

    private func expandKeyboard() {
        if heightConstraint == nil {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: 200)
            heightConstraint?.priority = .required
        }
        heightConstraint?.isActive = true
    }

    private func collapseKeyboard() {
        heightConstraint?.isActive = false
    }

    private func setLoading(_ on: Bool) {
        isLoading = on
        fixButton.isEnabled = !on
        fixButton.alpha = on ? 0.5 : 1
    }
    private func setStatus(_ msg: String) { statusLabel.text = msg }
}
