import UIKit

class KeyboardViewController: UIInputViewController {

    private let workerURL = "https://tamil-grammar-fix.dhanageetha2000.workers.dev/"
    private var isLoading = false
    private var heightConstraint: NSLayoutConstraint?
    private var lastOriginal: String = ""
    private var lastCorrected: String = ""

    // MARK: - Main keyboard UI

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

    private lazy var nextKeyboardButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("\u{1F310}", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 20)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        return btn
    }()

    // MARK: - Popup card UI

    private lazy var popupCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBackground
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowOffset = CGSize(width: 0, height: -2)
        v.layer.shadowRadius = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private lazy var beforeTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Before"
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var beforeTextLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 16)
        lbl.textColor = UIColor.systemRed
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var afterTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "After"
        lbl.font = .systemFont(ofSize: 12, weight: .semibold)
        lbl.textColor = .secondaryLabel
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var afterTextLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.font = .systemFont(ofSize: 16, weight: .medium)
        lbl.textColor = UIColor.systemGreen
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var divider: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.separator
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var acceptButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✓ Keep", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor.systemGreen
        btn.layer.cornerRadius = 10
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(acceptTapped), for: .touchUpInside)
        return btn
    }()

    private lazy var undoButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("✕ Undo", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        btn.setTitleColor(UIColor(red: 0.90, green: 0.22, blue: 0.27, alpha: 1), for: .normal)
        btn.backgroundColor = UIColor.systemRed.withAlphaComponent(0.1)
        btn.layer.cornerRadius = 10
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        return btn
    }()

    // MARK: - Limit reached card

    private lazy var limitCard: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.12)
        v.layer.cornerRadius = 14
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.4).cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.isHidden = true
        return v
    }()

    private lazy var limitTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "🎉 You've used your 50 free corrections!"
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = UIColor.systemOrange
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var limitBodyLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Tamil Karam uses Claude AI to fix your grammar — a small subscription helps cover the AI cost and keeps corrections fast & accurate. 🙏\n\nYour 50 free corrections reset on the 1st of next month."
        lbl.font = .systemFont(ofSize: 12)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private lazy var limitDismissButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Got it", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.addTarget(self, action: #selector(dismissLimitCard), for: .touchUpInside)
        return btn
    }()

    // MARK: - viewDidLoad

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemGroupedBackground

        view.addSubview(nextKeyboardButton)
        view.addSubview(fixButton)
        view.addSubview(statusLabel)

        // Limit card
        limitCard.addSubview(limitTitleLabel)
        limitCard.addSubview(limitBodyLabel)
        limitCard.addSubview(limitDismissButton)
        view.addSubview(limitCard)

        // Popup card
        popupCard.addSubview(beforeTitleLabel)
        popupCard.addSubview(beforeTextLabel)
        popupCard.addSubview(divider)
        popupCard.addSubview(afterTitleLabel)
        popupCard.addSubview(afterTextLabel)
        popupCard.addSubview(acceptButton)
        popupCard.addSubview(undoButton)
        view.addSubview(popupCard)

        NSLayoutConstraint.activate([
            // Keyboard globe button
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            // Fix button
            fixButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),
            fixButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fixButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fixButton.heightAnchor.constraint(equalToConstant: 50),

            // Status label
            statusLabel.topAnchor.constraint(equalTo: fixButton.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            // Limit card
            limitCard.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            limitCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            limitCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            limitTitleLabel.topAnchor.constraint(equalTo: limitCard.topAnchor, constant: 12),
            limitTitleLabel.leadingAnchor.constraint(equalTo: limitCard.leadingAnchor, constant: 12),
            limitTitleLabel.trailingAnchor.constraint(equalTo: limitCard.trailingAnchor, constant: -12),

            limitBodyLabel.topAnchor.constraint(equalTo: limitTitleLabel.bottomAnchor, constant: 6),
            limitBodyLabel.leadingAnchor.constraint(equalTo: limitCard.leadingAnchor, constant: 12),
            limitBodyLabel.trailingAnchor.constraint(equalTo: limitCard.trailingAnchor, constant: -12),

            limitDismissButton.topAnchor.constraint(equalTo: limitBodyLabel.bottomAnchor, constant: 8),
            limitDismissButton.centerXAnchor.constraint(equalTo: limitCard.centerXAnchor),
            limitDismissButton.bottomAnchor.constraint(equalTo: limitCard.bottomAnchor, constant: -10),

            // Popup card
            popupCard.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 10),
            popupCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            popupCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            // Before section
            beforeTitleLabel.topAnchor.constraint(equalTo: popupCard.topAnchor, constant: 12),
            beforeTitleLabel.leadingAnchor.constraint(equalTo: popupCard.leadingAnchor, constant: 14),

            beforeTextLabel.topAnchor.constraint(equalTo: beforeTitleLabel.bottomAnchor, constant: 4),
            beforeTextLabel.leadingAnchor.constraint(equalTo: popupCard.leadingAnchor, constant: 14),
            beforeTextLabel.trailingAnchor.constraint(equalTo: popupCard.trailingAnchor, constant: -14),

            // Divider
            divider.topAnchor.constraint(equalTo: beforeTextLabel.bottomAnchor, constant: 10),
            divider.leadingAnchor.constraint(equalTo: popupCard.leadingAnchor, constant: 14),
            divider.trailingAnchor.constraint(equalTo: popupCard.trailingAnchor, constant: -14),
            divider.heightAnchor.constraint(equalToConstant: 1),

            // After section
            afterTitleLabel.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 10),
            afterTitleLabel.leadingAnchor.constraint(equalTo: popupCard.leadingAnchor, constant: 14),

            afterTextLabel.topAnchor.constraint(equalTo: afterTitleLabel.bottomAnchor, constant: 4),
            afterTextLabel.leadingAnchor.constraint(equalTo: popupCard.leadingAnchor, constant: 14),
            afterTextLabel.trailingAnchor.constraint(equalTo: popupCard.trailingAnchor, constant: -14),

            // Buttons
            acceptButton.topAnchor.constraint(equalTo: afterTextLabel.bottomAnchor, constant: 12),
            acceptButton.leadingAnchor.constraint(equalTo: popupCard.leadingAnchor, constant: 14),
            acceptButton.trailingAnchor.constraint(equalTo: popupCard.centerXAnchor, constant: -6),
            acceptButton.heightAnchor.constraint(equalToConstant: 40),
            acceptButton.bottomAnchor.constraint(equalTo: popupCard.bottomAnchor, constant: -12),

            undoButton.topAnchor.constraint(equalTo: afterTextLabel.bottomAnchor, constant: 12),
            undoButton.leadingAnchor.constraint(equalTo: popupCard.centerXAnchor, constant: 6),
            undoButton.trailingAnchor.constraint(equalTo: popupCard.trailingAnchor, constant: -14),
            undoButton.heightAnchor.constraint(equalToConstant: 40),
        ])

        fixButton.addTarget(self, action: #selector(fixGrammarTapped), for: .touchUpInside)
    }

    // MARK: - Fix Grammar

    @objc private func fixGrammarTapped() {
        guard !isLoading else { return }
        let before  = textDocumentProxy.documentContextBeforeInput ?? ""
        let after   = textDocumentProxy.documentContextAfterInput  ?? ""
        let originalText = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !originalText.isEmpty else { setStatus("No text found. Type some Tamil first."); return }

        hidePopup()
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

                // Network error
                guard error == nil, let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                else { self?.setStatus("⚠️ Could not connect. Try again."); return }

                // Limit reached — show friendly message
                if let errCode = json["error"] as? String, errCode == "limit_reached" {
                    self?.setStatus("🙏 50 free corrections used this month!")
                    self?.showLimitMessage()
                    return
                }

                // Other errors
                guard let corrected = json["corrected"] as? String else {
                    self?.setStatus("⚠️ Could not fix. Try again.")
                    return
                }

                // Move cursor to end of text
                let ac = (self?.textDocumentProxy.documentContextAfterInput ?? "").count
                if ac > 0 {
                    self?.textDocumentProxy.adjustTextPosition(byCharacterOffset: ac)
                }
                // Loop to delete all text
                var attempts = 0
                while attempts < 20 {
                    guard let before = self?.textDocumentProxy.documentContextBeforeInput, !before.isEmpty else { break }
                    for _ in 0..<before.count { self?.textDocumentProxy.deleteBackward() }
                    attempts += 1
                }
                self?.textDocumentProxy.insertText(corrected)

                // Save for undo
                self?.lastOriginal = originalText
                self?.lastCorrected = corrected

                if corrected.trimmingCharacters(in: .whitespacesAndNewlines) == originalText {
                    self?.setStatus("✅ No changes needed")
                } else {
                    self?.setStatus("✅ Fixed!")
                    self?.showPopup(original: originalText, corrected: corrected)
                }
            }
        }.resume()
    }

    // MARK: - Popup Actions

    @objc private func acceptTapped() {
        hidePopup()
        setStatus("Type Tamil, then tap Fix")
    }

    @objc private func undoTapped() {
        // Replace corrected text back with original
        let ac = (textDocumentProxy.documentContextAfterInput ?? "").count
        if ac > 0 { textDocumentProxy.adjustTextPosition(byCharacterOffset: ac) }
        var attempts = 0
        while attempts < 20 {
            guard let before = textDocumentProxy.documentContextBeforeInput, !before.isEmpty else { break }
            for _ in 0..<before.count { textDocumentProxy.deleteBackward() }
            attempts += 1
        }
        textDocumentProxy.insertText(lastOriginal)
        hidePopup()
        setStatus("Undone ↩️")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.setStatus("Type Tamil, then tap Fix")
        }
    }

    // MARK: - Limit Card Show/Hide

    private func showLimitMessage() {
        hidePopup()
        limitCard.isHidden = false
        expandKeyboard()
    }

    @objc private func dismissLimitCard() {
        limitCard.isHidden = true
        collapseKeyboard()
        setStatus("Type Tamil, then tap Fix")
    }

    // MARK: - Popup Show/Hide

    private func showPopup(original: String, corrected: String) {
        let strikeAttr: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: UIColor.systemRed
        ]
        beforeTextLabel.attributedText = NSAttributedString(string: original, attributes: strikeAttr)
        afterTextLabel.text = corrected
        popupCard.isHidden = false
        expandKeyboard()
    }

    private func hidePopup() {
        popupCard.isHidden = true
        limitCard.isHidden = true
        collapseKeyboard()
    }

    private func expandKeyboard() {
        if heightConstraint == nil {
            heightConstraint = view.heightAnchor.constraint(equalToConstant: 280)
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
