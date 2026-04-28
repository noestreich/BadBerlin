import Cocoa

// MARK: - Model

struct SensorVal { var value = "–"; var date = "–" }

struct BadData {
    var quality    = "–"
    var ecoliMax   = "–"; var ecoliProb  = "–"; var ecoliDate  = "–"
    var temp       = "–"; var tempDate   = "–"
    var depth      = "–"; var depthDate  = "–"
    var rain       = "–"; var rainDate   = "–"
    var flow       = "–"; var flowDate   = "–"
    var overflow   = "–"; var overflowDate = "–"
    var sensor     = "–"; var sensorDate = "–"
    // Extended sensors  [sourceid: SensorVal]
    var ext: [Int: SensorVal] = [:]
}

// Sensors shown in the expandable section (sourceid, display-title, unit)
let extendedSensors: [(id: Int, title: String, unit: String)] = [
    ( 5, "Leitfähigkeit",     "µS/cm"),
    (10, "pH-Wert",           ""),
    (15, "TOC Equivalent",    "mg/L"),
    ( 8, "DOC Equivalent",    "mg/L"),
    (31, "UV254T",            ""),
    (16, "TSS Equivalent",    "mg/L"),
    (17, "Turbidity",         "FTUeq"),
    (19, "Chlorophyll-A",     "µg/L"),
    (22, "Ammonium NH₄-N",   "mg/L"),
    (23, "Nitrat-N",          "mg/L"),
]

// MARK: - Helpers

func classifyEcoli(_ kbe: Int) -> String {
    switch kbe {
    case ..<500:   return "gut"
    case ..<900:   return "ausreichend"
    case ..<1800:  return "grenzwertig"
    case ..<10000: return "mangelhaft"
    default:       return "mangelhaft+"
    }
}

func colorForQuality(_ q: String) -> NSColor {
    switch q {
    case "gut":         return NSColor(red: 0.76, green: 0.93, blue: 0.72, alpha: 1)
    case "ausreichend": return NSColor(red: 0.87, green: 0.95, blue: 0.66, alpha: 1)
    case "grenzwertig": return NSColor(red: 0.99, green: 0.88, blue: 0.62, alpha: 1)
    case "mangelhaft":  return NSColor(red: 0.99, green: 0.74, blue: 0.72, alpha: 1)
    case "mangelhaft+": return NSColor(red: 0.88, green: 0.74, blue: 0.93, alpha: 1)
    default:            return NSColor(white: 0.90, alpha: 1)
    }
}

func menuBarEmoji(_ q: String) -> String {
    switch q {
    case "gut":         return "🟢"
    case "ausreichend": return "🟡"
    case "grenzwertig": return "🟠"
    case "mangelhaft":  return "🔴"
    case "mangelhaft+": return "🟣"
    default:            return "⚫️"
    }
}

func shortDate(_ s: String) -> String {
    guard s.count >= 10 else { return s }
    let parts = String(s.prefix(10)).split(separator: "-")
    guard parts.count == 3 else { return String(s.prefix(10)) }
    return "\(parts[2]).\(parts[1]).\(String(parts[0]).suffix(2))"
}

func anyStr(_ v: Any?) -> String {
    if let i = v as? Int    { return "\(i)" }
    if let d = v as? Double { return String(format: "%.1f", d) }
    if let s = v as? String { return s }
    return "–"
}

// MARK: - ColorView

final class ColorView: NSView {
    var fillColor: NSColor = .clear { didSet { needsDisplay = true } }
    var cornerRadius: CGFloat = 0
    override func draw(_ dirtyRect: NSRect) {
        if cornerRadius > 0 {
            let p = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)
            fillColor.setFill(); p.fill()
        } else {
            fillColor.setFill()
            NSBezierPath(rect: bounds).fill()
        }
    }
}

// MARK: - Metric Card (main 6 tiles)

final class MetricCard: NSView {
    private let bg         = ColorView()
    private let titleField = NSTextField(labelWithString: "")
    private let unitField  = NSTextField(labelWithString: "")
    private let valueField = NSTextField(labelWithString: "–")
    private let dateField  = NSTextField(labelWithString: "")

    init(title: String, unit: String) {
        super.init(frame: .zero)
        bg.fillColor = NSColor(red: 0.84, green: 0.92, blue: 0.98, alpha: 1)
        bg.cornerRadius = 12
        bg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bg)
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        configure(titleField, size: 11, weight: .semibold, color: NSColor(white: 0.18, alpha: 1), align: .left)
        configure(unitField,  size: 10, weight: .regular,  color: NSColor(white: 0.45, alpha: 1), align: .left)
        configure(valueField, size: 24, weight: .bold,     color: NSColor(white: 0.07, alpha: 1), align: .right)
        configure(dateField,  size: 10, weight: .regular,  color: NSColor(white: 0.45, alpha: 1), align: .right)
        titleField.stringValue = title; unitField.stringValue = unit
        titleField.maximumNumberOfLines = 1; titleField.lineBreakMode = .byTruncatingTail
        unitField.maximumNumberOfLines  = 1; unitField.lineBreakMode  = .byTruncatingTail
        [titleField, unitField, valueField, dateField].forEach { f in
            f.translatesAutoresizingMaskIntoConstraints = false; addSubview(f)
        }
        NSLayoutConstraint.activate([
            titleField.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            titleField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            unitField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 1),
            unitField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            unitField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            dateField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            dateField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            dateField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            valueField.bottomAnchor.constraint(equalTo: dateField.topAnchor, constant: -1),
            valueField.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            valueField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    private func configure(_ f: NSTextField, size: CGFloat, weight: NSFont.Weight,
                           color: NSColor, align: NSTextAlignment) {
        f.font = .systemFont(ofSize: size, weight: weight); f.textColor = color
        f.alignment = align; f.drawsBackground = false; f.isBordered = false
        f.isEditable = false; f.isSelectable = false
    }
    func update(value: String, date: String) {
        valueField.stringValue = value; dateField.stringValue = date
    }
}

// MARK: - Compact Row (extended section)

final class CompactRow: NSView {
    private let titleField = NSTextField(labelWithString: "")
    private let unitField  = NSTextField(labelWithString: "")
    private let valueField = NSTextField(labelWithString: "–")
    private let dateField  = NSTextField(labelWithString: "")

    init(title: String, unit: String) {
        super.init(frame: .zero)
        style(titleField, size: 11, weight: .semibold, color: NSColor(white: 0.18, alpha: 1), align: .left)
        style(unitField,  size: 10, weight: .regular,  color: NSColor(white: 0.50, alpha: 1), align: .left)
        style(valueField, size: 15, weight: .bold,     color: NSColor(white: 0.08, alpha: 1), align: .right)
        style(dateField,  size: 10, weight: .regular,  color: NSColor(white: 0.50, alpha: 1), align: .right)
        titleField.stringValue = title
        unitField.stringValue  = unit.isEmpty ? "" : "[\(unit)]"
        [titleField, unitField, valueField, dateField].forEach { f in
            f.translatesAutoresizingMaskIntoConstraints = false; addSubview(f)
        }
        NSLayoutConstraint.activate([
            // Fixed right column (value + date), always flush to the right edge
            valueField.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            valueField.trailingAnchor.constraint(equalTo: trailingAnchor),
            valueField.widthAnchor.constraint(equalToConstant: 80),
            dateField.topAnchor.constraint(equalTo: valueField.bottomAnchor, constant: 1),
            dateField.trailingAnchor.constraint(equalTo: trailingAnchor),
            dateField.widthAnchor.constraint(equalToConstant: 80),
            // Left column fills remaining space
            titleField.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            titleField.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleField.trailingAnchor.constraint(equalTo: valueField.leadingAnchor, constant: -8),
            unitField.topAnchor.constraint(equalTo: titleField.bottomAnchor, constant: 1),
            unitField.leadingAnchor.constraint(equalTo: leadingAnchor),
            unitField.trailingAnchor.constraint(equalTo: valueField.leadingAnchor, constant: -8),
            unitField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }
    private func style(_ f: NSTextField, size: CGFloat, weight: NSFont.Weight,
                       color: NSColor, align: NSTextAlignment) {
        f.font = .systemFont(ofSize: size, weight: weight); f.textColor = color
        f.alignment = align; f.drawsBackground = false; f.isBordered = false
        f.isEditable = false; f.isSelectable = false
    }
    func update(value: String, date: String) {
        valueField.stringValue = value; dateField.stringValue = date
    }
}

// MARK: - Content View Controller

final class BadViewController: NSViewController {

    // Header
    private let headerBg: NSBox = {
        let b = NSBox(); b.boxType = .custom; b.borderWidth = 0; b.cornerRadius = 0
        b.fillColor = NSColor(white: 0.88, alpha: 1); return b
    }()
    private let locationField = NSTextField(labelWithString: "SPREEKANAL · BAD BERLIN")
    private let qualityField  = NSTextField(labelWithString: "🏊 …")
    private let ecoliField    = NSTextField(labelWithString: "")

    // Main cards
    let tempCard     = MetricCard(title: "Temperatur",     unit: "[°C]")
    let depthCard    = MetricCard(title: "Sichttiefe",     unit: "[cm]")
    let rainCard     = MetricCard(title: "Regen",          unit: "[mm, letzte 48h]")
    let flowCard     = MetricCard(title: "Durchfluss",     unit: "[m³/s]")
    let overflowCard = MetricCard(title: "Kanalüberläufe", unit: "[Tage seit Ereignis]")
    let sensorCard   = MetricCard(title: "Sauerstoffs.",   unit: "[%]")

    // Extended section
    private var isExpanded = false
    private var toggleBtn:               NSButton!
    private var expandedContainer:       NSView!
    private var expandedHeightConstraint: NSLayoutConstraint!  // active = collapsed (height 0)
    private var expandedContentConstraint: NSLayoutConstraint! // active = expanded  (last row → bottom)
    private var compactRows:             [CompactRow] = []

    // Footer
    private let updatedField = NSTextField(labelWithString: "")

    weak var appDelegate: AppDelegate?
    private var row2Bottom:      NSLayoutYAxisAnchor!
    private var expandableBottom: NSLayoutYAxisAnchor!

    // MARK: loadView

    override func loadView() {
        let root = ColorView()
        root.fillColor = NSColor(white: 0.97, alpha: 1)
        view = root
        buildHeader()
        buildGrid()
        buildExpandable()
        buildFooter()
    }

    // MARK: Build

    private func buildHeader() {
        headerBg.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerBg)
        label(locationField, size: 10, weight: .semibold, color: NSColor(white: 0.33, alpha: 1))
        label(qualityField,  size: 26, weight: .bold,     color: NSColor(white: 0.12, alpha: 1))
        label(ecoliField,    size: 11, weight: .regular,  color: NSColor(white: 0.28, alpha: 1))
        [locationField, qualityField, ecoliField].forEach { f in
            f.translatesAutoresizingMaskIntoConstraints = false; headerBg.addSubview(f)
        }
        NSLayoutConstraint.activate([
            headerBg.topAnchor.constraint(equalTo: view.topAnchor),
            headerBg.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBg.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerBg.heightAnchor.constraint(equalToConstant: 92),
            locationField.topAnchor.constraint(equalTo: headerBg.topAnchor, constant: 14),
            locationField.leadingAnchor.constraint(equalTo: headerBg.leadingAnchor, constant: 16),
            qualityField.topAnchor.constraint(equalTo: locationField.bottomAnchor, constant: 2),
            qualityField.leadingAnchor.constraint(equalTo: headerBg.leadingAnchor, constant: 16),
            ecoliField.topAnchor.constraint(equalTo: qualityField.bottomAnchor, constant: 3),
            ecoliField.leadingAnchor.constraint(equalTo: headerBg.leadingAnchor, constant: 16),
        ])
    }

    private func buildGrid() {
        let allCards = [tempCard, depthCard, rainCard, flowCard, overflowCard, sensorCard]
        allCards.forEach { c in
            c.translatesAutoresizingMaskIntoConstraints = false
            c.heightAnchor.constraint(equalToConstant: 92).isActive = true
        }
        let row1 = cardRow([tempCard, depthCard, rainCard])
        let row2 = cardRow([flowCard, overflowCard, sensorCard])
        NSLayoutConstraint.activate([
            row1.topAnchor.constraint(equalTo: headerBg.bottomAnchor, constant: 12),
            row1.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            row1.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            row2.topAnchor.constraint(equalTo: row1.bottomAnchor, constant: 8),
            row2.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            row2.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
        ])
        row2Bottom = row2.bottomAnchor
    }

    private func cardRow(_ cards: [MetricCard]) -> NSStackView {
        let s = NSStackView(views: cards)
        s.orientation = .horizontal; s.spacing = 8; s.distribution = .fillEqually
        s.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(s); return s
    }

    private func buildExpandable() {
        // Toggle button
        let btn = NSButton(title: "▶  Weitere Daten", target: self, action: #selector(onToggle))
        btn.bezelStyle = .inline
        btn.isBordered = false
        btn.font = .systemFont(ofSize: 11, weight: .medium)
        btn.contentTintColor = .tertiaryLabelColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btn)
        self.toggleBtn = btn

        // Container for compact rows (clipped when height = 0)
        expandedContainer = NSView()
        expandedContainer.wantsLayer = true
        expandedContainer.layer?.masksToBounds = true
        expandedContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(expandedContainer)

        // Build rows manually with explicit leading/trailing constraints
        // so every row spans the full container width regardless of content size
        var prevAnchor: NSLayoutYAxisAnchor = expandedContainer.topAnchor
        var prevConstant: CGFloat = 6

        for sensor in extendedSensors {
            if !compactRows.isEmpty {
                let sep = NSView()
                sep.wantsLayer = true
                sep.layer?.backgroundColor = NSColor(white: 0.85, alpha: 1).cgColor
                sep.translatesAutoresizingMaskIntoConstraints = false
                expandedContainer.addSubview(sep)
                NSLayoutConstraint.activate([
                    sep.topAnchor.constraint(equalTo: prevAnchor, constant: prevConstant),
                    sep.leadingAnchor.constraint(equalTo: expandedContainer.leadingAnchor, constant: 14),
                    sep.trailingAnchor.constraint(equalTo: expandedContainer.trailingAnchor, constant: -14),
                    sep.heightAnchor.constraint(equalToConstant: 0.5),
                ])
                prevAnchor = sep.bottomAnchor
                prevConstant = 0
            }
            let row = CompactRow(title: sensor.title, unit: sensor.unit)
            row.translatesAutoresizingMaskIntoConstraints = false
            expandedContainer.addSubview(row)
            NSLayoutConstraint.activate([
                row.topAnchor.constraint(equalTo: prevAnchor, constant: prevConstant),
                row.leadingAnchor.constraint(equalTo: expandedContainer.leadingAnchor, constant: 14),
                row.trailingAnchor.constraint(equalTo: expandedContainer.trailingAnchor, constant: -14),
            ])
            prevAnchor = row.bottomAnchor
            prevConstant = 0
            compactRows.append(row)
        }
        // These two constraints are mutually exclusive — only one active at a time:
        // collapsed: height=0 active, content-bottom inactive
        // expanded:  height=0 inactive, content-bottom active
        expandedContentConstraint = prevAnchor.constraint(equalTo: expandedContainer.bottomAnchor, constant: -6)
        expandedContentConstraint.isActive = false

        expandedHeightConstraint = expandedContainer.heightAnchor.constraint(equalToConstant: 0)
        expandedHeightConstraint.isActive = true

        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: row2Bottom, constant: 8),
            btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            btn.heightAnchor.constraint(equalToConstant: 22),

            expandedContainer.topAnchor.constraint(equalTo: btn.bottomAnchor, constant: 0),
            expandedContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            expandedContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        expandableBottom = expandedContainer.bottomAnchor
    }

    private func buildFooter() {
        label(updatedField, size: 10, weight: .regular, color: .secondaryLabelColor)
        updatedField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(updatedField)
        let refreshBtn = btn("↺  Aktualisieren", #selector(onRefresh))
        let quitBtn    = btn("Beenden",           #selector(onQuit))
        let btns = NSStackView(views: [refreshBtn, quitBtn])
        btns.orientation = .horizontal; btns.distribution = .fillEqually
        btns.spacing = 8; btns.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(btns)
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 380),
            updatedField.topAnchor.constraint(equalTo: expandableBottom, constant: 10),
            updatedField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 14),
            updatedField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -14),
            btns.topAnchor.constraint(equalTo: updatedField.bottomAnchor, constant: 6),
            btns.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            btns.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            btns.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            btns.heightAnchor.constraint(equalToConstant: 28),
        ])
    }

    // MARK: Helpers

    private func label(_ f: NSTextField, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
        f.font = .systemFont(ofSize: size, weight: weight); f.textColor = color
        f.drawsBackground = false; f.isBordered = false; f.isEditable = false; f.isSelectable = false
    }

    private func btn(_ title: String, _ action: Selector) -> NSButton {
        let b = NSButton(title: title, target: self, action: action)
        b.bezelStyle = .rounded; b.font = .systemFont(ofSize: 12); return b
    }

    // MARK: Actions

    @objc private func onRefresh() { appDelegate?.fetchAll() }
    @objc private func onQuit()    { NSApp.terminate(nil) }

    @objc private func onToggle() {
        isExpanded.toggle()
        toggleBtn.title = isExpanded ? "▼  Weitere Daten" : "▶  Weitere Daten"
        // Swap the two mutually-exclusive constraints, then force layout so
        // fittingSize reflects the new state before we resize the popover.
        expandedHeightConstraint.isActive  = !isExpanded
        expandedContentConstraint.isActive =  isExpanded
        view.layoutSubtreeIfNeeded()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.20
            ctx.allowsImplicitAnimation = true
            self.preferredContentSize = self.view.fittingSize
            self.view.layoutSubtreeIfNeeded()
        } completionHandler: {
            self.preferredContentSize = self.view.fittingSize
        }
    }

    // MARK: Update

    func applyData(_ d: BadData) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.headerBg.fillColor = colorForQuality(d.quality)
            self.qualityField.stringValue = "\(menuBarEmoji(d.quality))  \(d.quality.uppercased())"
            self.ecoliField.stringValue   =
                "Wasserhygiene: max \(d.ecoliMax) / wahrsch. \(d.ecoliProb) KBE/100ml (\(d.ecoliDate))"
            self.tempCard.update(value: d.temp,      date: d.tempDate)
            self.depthCard.update(value: d.depth,    date: d.depthDate)
            self.rainCard.update(value: d.rain,      date: d.rainDate)
            self.flowCard.update(value: d.flow,      date: d.flowDate)
            self.overflowCard.update(value: d.overflow, date: d.overflowDate)
            self.sensorCard.update(value: d.sensor,  date: d.sensorDate)

            // Extended rows
            for (i, sensor) in extendedSensors.enumerated() {
                guard i < self.compactRows.count else { break }
                let sv = d.ext[sensor.id] ?? SensorVal()
                self.compactRows[i].update(value: sv.value, date: sv.date)
            }

            let now = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
            self.updatedField.stringValue = "Aktualisiert: \(now)"
        }
    }
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover    = NSPopover()
    var contentVC  = BadViewController()
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        NSApp.setActivationPolicy(.accessory)
        contentVC.appDelegate = self
        popover.contentViewController = contentVC
        popover.behavior = .transient
        popover.animates = true
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🏊 …"
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.target = self
        _ = contentVC.view  // force loadView() so compactRows exist before first fetch
        fetchAll()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 600, repeats: true) { [weak self] _ in
            self?.fetchAll()
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        guard let btn = statusItem.button else { return }
        if popover.isShown { popover.performClose(sender) }
        else {
            popover.show(relativeTo: btn.bounds, of: btn, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: Fetch

    func fetchAll() {
        DispatchQueue.main.async { self.statusItem.button?.title = "🏊 …" }
        let group = DispatchGroup()
        let lock  = NSLock()
        var d     = BadData()
        func locked(_ block: () -> Void) { lock.lock(); block(); lock.unlock() }

        // Quality + E.coli
        group.enter()
        get("https://panel.badberlin.info/api/prediction") { json in
            defer { group.leave() }
            guard let arr = json as? [[String: Any]], let last = arr.last else { return }
            var kbe = 0
            if let p90 = last["p90"] as? Double { kbe = Int(pow(10, p90).rounded()) }
            if let p50 = last["p50"] as? Double {
                locked { d.ecoliMax = "\(kbe)"; d.ecoliProb = "\(Int(pow(10, p50).rounded()))" }
            }
            if let c = last["created_at"] as? String { locked { d.ecoliDate = shortDate(c) } }
            if kbe > 0 { locked { d.quality = classifyEcoli(kbe) } }
        }

        // Main sensors
        group.enter()
        get("https://panel.badberlin.info/api/data/depth") { json in
            defer { group.leave() }
            guard let j = json as? [String: Any] else { return }
            locked { d.depth = anyStr(j["value"]); d.depthDate = (j["dateFormatted"] as? String) ?? "" }
        }
        group.enter()
        get("https://panel.badberlin.info/api/sensor?sourceid=3&latest=true") { json in
            defer { group.leave() }
            guard let j = json as? [String: Any], let rows = j["rows"] as? [[String: Any]],
                  let row = rows.first else { return }
            locked {
                if let v = row["value"] as? Double { d.temp = String(format: "%.1f", v) }
                if let ts = row["timestamp"] as? String { d.tempDate = shortDate(ts) }
            }
        }
        group.enter()
        get("https://panel.badberlin.info/api/data/rain") { json in
            defer { group.leave() }
            guard let j = json as? [String: Any] else { return }
            locked { d.rain = anyStr(j["value"]); d.rainDate = (j["date"] as? String) ?? "" }
        }
        group.enter()
        get("https://panel.badberlin.info/api/data/flow") { json in
            defer { group.leave() }
            guard let j = json as? [String: Any] else { return }
            locked { d.flow = anyStr(j["value"]); d.flowDate = (j["date"] as? String) ?? "" }
        }
        group.enter()
        get("https://panel.badberlin.info/api/data/overflow") { json in
            defer { group.leave() }
            guard let j = json as? [String: Any], let cs = j["catchments"] as? [[String: Any]] else { return }
            let days = cs.compactMap { $0["value"] as? String }.compactMap { Int($0) }
            locked {
                d.overflow     = days.min().map { "\($0)" } ?? "–"
                d.overflowDate = cs.compactMap { $0["date"] as? String }.first ?? "–"
            }
        }
        group.enter()
        get("https://panel.badberlin.info/api/sensor?sourceid=2&latest=true") { json in
            defer { group.leave() }
            guard let j = json as? [String: Any], let rows = j["rows"] as? [[String: Any]],
                  let row = rows.first else { return }
            locked {
                if let v = row["value"] as? Double { d.sensor = String(format: "%.1f", v) }
                if let ts = row["timestamp"] as? String { d.sensorDate = shortDate(ts) }
            }
        }

        // Extended sensors
        for sensor in extendedSensors {
            group.enter()
            get("https://panel.badberlin.info/api/sensor?sourceid=\(sensor.id)&latest=true") { json in
                defer { group.leave() }
                guard let j = json as? [String: Any], let rows = j["rows"] as? [[String: Any]],
                      let row = rows.first else { return }
                var sv = SensorVal()
                if let v = row["value"] as? Double { sv.value = String(format: "%.1f", v) }
                if let ts = row["timestamp"] as? String { sv.date = shortDate(ts) }
                locked { d.ext[sensor.id] = sv }
            }
        }

        group.notify(queue: .global()) { [weak self] in
            guard let self else { return }
            self.contentVC.applyData(d)
            DispatchQueue.main.async {
                self.statusItem.button?.title = "\(menuBarEmoji(d.quality)) \(d.quality.uppercased())"
            }
        }
    }
}

// MARK: - Network

func get(_ urlString: String, completion: @escaping (Any?) -> Void) {
    guard let url = URL(string: urlString) else { completion(nil); return }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data, let json = try? JSONSerialization.jsonObject(with: data) else {
            completion(nil); return
        }
        completion(json)
    }.resume()
}

// MARK: - Entry Point

let app      = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
