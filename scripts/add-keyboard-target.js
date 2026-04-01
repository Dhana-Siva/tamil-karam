/**
 * Adds the TamilKaramKeyboard extension target to the Xcode project.
 * Creates Swift source files, adds the Xcode target, and embeds it
 * in the main app using correct PBXBuildFile entries.
 *
 * Run AFTER `npx expo prebuild --platform ios --clean`.
 * Safe to re-run — skips steps already done.
 */

const xcode  = require('xcode');
const fs     = require('fs');
const path   = require('path');
const crypto = require('crypto');

// ── Config ────────────────────────────────────────────────────────────────────
const ROOT         = path.join(__dirname, '..');
const PROJECT_PATH = path.join(ROOT, 'ios/app.xcodeproj/project.pbxproj');
const EXT_DIR      = path.join(ROOT, 'ios/TamilKaramKeyboard');
const EXT_NAME     = 'TamilKaramKeyboard';
const EXT_BUNDLE   = 'app.tamilkaram.keyboard';
const WORKER_URL   = 'https://tamil-grammar-fix.dhanageetha2000.workers.dev/';

function uuid24() {
  return crypto.randomBytes(12).toString('hex').toUpperCase();
}

// ── 1. Write Swift + plist source files ───────────────────────────────────────
fs.mkdirSync(EXT_DIR, { recursive: true });

fs.writeFileSync(path.join(EXT_DIR, 'KeyboardViewController.swift'), `
import UIKit

class KeyboardViewController: UIInputViewController {

    private let workerURL = "${WORKER_URL}"
    private var isLoading = false

    private lazy var fixButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("\\u2713  Fix Tamil Grammar", for: .normal)
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
        btn.setTitle("\\u{1F310}", for: .normal)
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

        NSLayoutConstraint.activate([
            nextKeyboardButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            fixButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 14),
            fixButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            fixButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            fixButton.heightAnchor.constraint(equalToConstant: 50),

            statusLabel.topAnchor.constraint(equalTo: fixButton.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        fixButton.addTarget(self, action: #selector(fixGrammarTapped), for: .touchUpInside)
    }

    @objc private func fixGrammarTapped() {
        guard !isLoading else { return }
        let before  = textDocumentProxy.documentContextBeforeInput ?? ""
        let after   = textDocumentProxy.documentContextAfterInput  ?? ""
        let text    = (before + after).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { setStatus("No text found. Type some Tamil first."); return }

        setLoading(true); setStatus("Fixing grammar\\u2026")

        guard let url = URL(string: workerURL) else { return }
        var req = URLRequest(url: url, timeoutInterval: 15)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? "keyboard-ext"
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["text": text, "deviceId": deviceId])

        URLSession.shared.dataTask(with: req) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.setLoading(false)
                guard error == nil,
                      let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let corrected = json["corrected"] as? String
                else { self?.setStatus("Could not fix. Try again."); return }

                let bc = (self?.textDocumentProxy.documentContextBeforeInput ?? "").count
                let ac = (self?.textDocumentProxy.documentContextAfterInput  ?? "").count
                for _ in 0..<ac  { self?.textDocumentProxy.adjustTextPosition(byCharacterOffset: 1) }
                for _ in 0..<(bc + ac) { self?.textDocumentProxy.deleteBackward() }
                self?.textDocumentProxy.insertText(corrected)
                self?.setStatus("\\u2705 Done!")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self?.setStatus("Type Tamil, then tap Fix")
                }
            }
        }.resume()
    }

    private func setLoading(_ on: Bool) {
        isLoading = on
        fixButton.isEnabled = !on
        fixButton.alpha = on ? 0.5 : 1
    }
    private func setStatus(_ msg: String) { statusLabel.text = msg }
}
`.trimStart());

fs.writeFileSync(path.join(EXT_DIR, 'Info.plist'), `<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key><string>Tamil Fix</string>
    <key>CFBundleExecutable</key><string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key><string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key><string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>IsASCIICapable</key><false/>
            <key>PrefersRightToLeft</key><false/>
            <key>PrimaryLanguage</key><string>ta</string>
            <key>RequestsOpenAccess</key><true/>
        </dict>
        <key>NSExtensionPointIdentifier</key><string>com.apple.keyboard-service</string>
        <key>NSExtensionPrincipalClass</key><string>$(PRODUCT_MODULE_NAME).KeyboardViewController</string>
    </dict>
</dict>
</plist>`);

console.log('✅  Swift source files written.');

// ── 2. Parse Xcode project ────────────────────────────────────────────────────
const project = xcode.project(PROJECT_PATH);
project.parseSync();

const nativeTargets = project.pbxNativeTargetSection();

// ── 3. Find main app target ───────────────────────────────────────────────────
const [appTargetUUID, appTarget] = Object.entries(nativeTargets).find(
  ([, t]) => t && typeof t === 'object' && t.name === 'app'
) || [];
if (!appTargetUUID) { console.error('❌  Cannot find "app" target'); process.exit(1); }

// ── 4. Add extension target (skip if exists) ──────────────────────────────────
const alreadyExists = Object.values(nativeTargets).some(
  t => t && typeof t === 'object' && t.name === EXT_NAME
);

if (!alreadyExists) {
  console.log(`➕  Adding target "${EXT_NAME}"…`);

  // File group
  const group = project.addPbxGroup(
    ['KeyboardViewController.swift', 'Info.plist'], EXT_NAME, EXT_NAME
  );
  project.addToPbxGroup(group.uuid, project.findPBXGroupKey({ name: undefined, path: undefined }));

  // Target
  const extTarget = project.addTarget(EXT_NAME, 'app_extension', EXT_NAME, EXT_BUNDLE);

  // Build phases
  project.addBuildPhase(['KeyboardViewController.swift'], 'PBXSourcesBuildPhase',    'Sources',    extTarget.uuid);
  project.addBuildPhase([],                               'PBXResourcesBuildPhase',  'Resources',  extTarget.uuid);
  project.addBuildPhase([],                               'PBXFrameworksBuildPhase', 'Frameworks', extTarget.uuid);

  // Build settings
  Object.values(project.pbxXCBuildConfigurationSection()).forEach(cfg => {
    if (!cfg?.buildSettings) return;
    const pn = cfg.buildSettings.PRODUCT_NAME;
    if (pn !== `"${EXT_NAME}"` && pn !== EXT_NAME) return;
    Object.assign(cfg.buildSettings, {
      SWIFT_VERSION:               '5.0',
      IPHONEOS_DEPLOYMENT_TARGET:  '15.1',
      INFOPLIST_FILE:              `${EXT_NAME}/Info.plist`,
      PRODUCT_BUNDLE_IDENTIFIER:   `"${EXT_BUNDLE}"`,
      CODE_SIGN_STYLE:             'Automatic',
      DEVELOPMENT_TEAM:            'H72SV43N57',
      SKIP_INSTALL:                'NO',
    });
  });

  console.log(`✅  Target "${EXT_NAME}" added.`);
} else {
  console.log(`ℹ️   Target "${EXT_NAME}" already exists.`);
}

// ── 5. Embed extension in main app (direct JSON — avoids xcode-package bug) ───
// Check if embed phase already present
const embedAlready = (appTarget.buildPhases || []).some(
  bp => (bp.comment || '').includes('Embed App Extensions')
);

if (!embedAlready) {
  console.log('➕  Adding "Embed App Extensions" phase…');

  // Find the .appex PBXFileReference created by addTarget
  const fileRefs = project.pbxFileReferenceSection();
  const [appexRefUUID] = Object.entries(fileRefs).find(
    ([, f]) => f?.path === `"${EXT_NAME}.appex"` || f?.path === `${EXT_NAME}.appex`
  ) || [];

  if (!appexRefUUID) {
    console.warn('⚠️  .appex file reference not found — skipping embed phase.');
  } else {
    // Create a PBXBuildFile wrapping the .appex reference
    const buildFileUUID = uuid24();
    const buildFileComment = `${EXT_NAME}.appex in Embed App Extensions`;
    project.hash.project.objects['PBXBuildFile'] = project.hash.project.objects['PBXBuildFile'] || {};
    project.hash.project.objects['PBXBuildFile'][buildFileUUID] = {
      isa: 'PBXBuildFile',
      fileRef: appexRefUUID,
      settings: { ATTRIBUTES: ['RemoveHeadersOnCopy'] },
    };
    project.hash.project.objects['PBXBuildFile'][`${buildFileUUID}_comment`] = buildFileComment;

    // Create the PBXCopyFilesBuildPhase
    const embedPhaseUUID = uuid24();
    project.hash.project.objects['PBXCopyFilesBuildPhase'] =
      project.hash.project.objects['PBXCopyFilesBuildPhase'] || {};
    project.hash.project.objects['PBXCopyFilesBuildPhase'][embedPhaseUUID] = {
      isa: 'PBXCopyFilesBuildPhase',
      buildActionMask: '2147483647',
      dstPath: '""',
      dstSubfolderSpec: '13',
      files: [{ value: buildFileUUID, comment: buildFileComment }],
      name: '"Embed App Extensions"',
      runOnlyForDeploymentPostprocessing: '0',
    };
    project.hash.project.objects['PBXCopyFilesBuildPhase'][`${embedPhaseUUID}_comment`] = 'Embed App Extensions';

    // Add phase to main app target's buildPhases array
    appTarget.buildPhases.push({ value: embedPhaseUUID, comment: 'Embed App Extensions' });

    console.log('✅  Embed App Extensions phase added.');
  }
} else {
  console.log('ℹ️   Embed App Extensions phase already present.');
}

// ── 6. Save ───────────────────────────────────────────────────────────────────
fs.writeFileSync(PROJECT_PATH, project.writeSync());
console.log('💾  project.pbxproj saved successfully.');
