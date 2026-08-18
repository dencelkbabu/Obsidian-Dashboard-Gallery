---
cssclasses:
  - dashboard-layout
  - dashboard-ocean
---

```dataviewjs
// ── DASHBOARD OCEAN ──────────────────────────────────────────────
// Zen Minimalism · Atlas Discovery · Komorebi System & Collections
// ─────────────────────────────────────────────────────────────────

const { setIcon } = require("obsidian");

// --- ⚙️ PERSISTENCE KEYS ---
const LS = {
    theme: "ocean-theme-preset",
    themeMode: "ocean-theme-mode",
    title: "ocean-title",
    subtitle: "ocean-subtitle",
    tag: "ocean-active-tag",
    tagSort: "ocean-tag-sort",
    pinnedTags: "ocean-pinned-tags",
    pinnedNotes: "ocean-pinned-notes",
    habits: "ocean-habits",
    habitWeek: "ocean-last-habit-week",
    cards: "ocean-cards",
    targets: "ocean-targets-v2",
    scratchpad: "ocean-scratchpad-v1",
    settings: "ocean-master-settings-v1"
};

const defaultSettings = {
    widgets: {
        targets: true,
        tasks: true,
        topics: true,
        jump: true,
        recent: true,
        scratchpad: true,
        collections: true,
        actions: true,
        habits: true
    },
    gridHeight: 550,
    fontSize: 16,
    recentLimit: 50,
    tagLimit: 35,
    weekStart: "monday",
    autoResetHabits: true
};

let masterSettings = Object.assign({}, defaultSettings, JSON.parse(localStorage.getItem(LS.settings) || "{}"));
masterSettings.widgets = Object.assign({}, defaultSettings.widgets, masterSettings.widgets || {});

let currentTheme = localStorage.getItem(LS.theme) || "zen";
let currentThemeMode = localStorage.getItem(LS.themeMode) || "auto";

let bannerTitle = localStorage.getItem(LS.title) || "DASHBOARD OCEAN";
let bannerSubtitle = localStorage.getItem(LS.subtitle) || "";
let activeTag = localStorage.getItem(LS.tag) || "__all__";
let tagSortMode = localStorage.getItem(LS.tagSort) || "count"; // "count" or "name"
let pinnedTags = JSON.parse(localStorage.getItem(LS.pinnedTags) || "[]");
let pinnedNotes = JSON.parse(localStorage.getItem(LS.pinnedNotes) || "[]");

const defaultHabits = ["Reading", "Deep Work", "Exercise", "Meditation"];
let savedHabits = JSON.parse(localStorage.getItem(LS.habits)) || defaultHabits;
localStorage.setItem(LS.habits, JSON.stringify(savedHabits));

let savedCards = JSON.parse(localStorage.getItem(LS.cards)) || [
    { title: "Project Alpha", subtitle: "Active Workspace & Tasks", emoji: "🚀", link: "" },
    { title: "Knowledge Base", subtitle: "Core Notes & Wiki Hub", emoji: "📚", link: "" },
    { title: "Reading List", subtitle: "Books, Papers & Articles", emoji: "📖", link: "" },
    { title: "Daily Journal", subtitle: "Thoughts & Reflections", emoji: "📅", link: "" }
];
localStorage.setItem(LS.cards, JSON.stringify(savedCards));

let savedTargets = JSON.parse(localStorage.getItem(LS.targets)) || [
    { title: "Project Launch Milestone", date: "2026-10-15", emoji: "🚀", link: "" },
    { title: "Certification Exam", date: "2026-12-31", emoji: "🎯", link: "" },
    { title: "Quarterly Review", date: "2027-03-31", emoji: "📈", link: "" }
];
localStorage.setItem(LS.targets, JSON.stringify(savedTargets));

const container = dv.container.createDiv({ cls: "ocean-dashboard animate-in" });
container.setAttribute("data-theme", currentTheme);
container.setAttribute("data-mode", currentThemeMode);
const initialScale = (masterSettings.fontSize || 16) / 16;
container.style.setProperty("--ocean-font-size", `${masterSettings.fontSize || 16}px`);
container.style.setProperty("--ocean-scale", `${initialScale}`);

const isMobilePlatform = app.isMobile || (typeof Platform !== "undefined" && Platform.isMobile);
if (isMobilePlatform) {
    container.classList.add("ocean-is-mobile");
}

if (typeof ResizeObserver !== "undefined") {
    const ro = new ResizeObserver((entries) => {
        for (const entry of entries) {
            const scale = parseFloat(container.style.getPropertyValue("--ocean-scale")) || 1;
            const physicalW = entry.contentRect.width * scale;
            const isNarrow = physicalW >= 680 && physicalW < 1120;
            const isCompact = physicalW < 680;
            const isPhone = physicalW < 480;
            container.classList.toggle("ocean-narrow", isNarrow);
            container.classList.toggle("ocean-compact", isCompact);
            container.classList.toggle("ocean-phone-view", isPhone);
        }
    });
    ro.observe(container);
}

// Helper Utilities
const Utils = {
    getGreeting: () => {
        const h = new Date().getHours();
        if (h < 5) return "Night of Stillness 🌙";
        if (h < 12) return "Morning Clarity ☀️";
        if (h < 18) return "Deep Focus ⚡";
        return "End of Day 🌌";
    },
    relTime: (d) => {
        if (!d) return "";
        let ms = 0;
        if (typeof d === "number") {
            ms = d;
        } else if (typeof d.toMillis === "function") {
            ms = d.toMillis();
        } else if (d instanceof Date) {
            ms = d.getTime();
        }
        if (!ms) return "";
        const m = Math.floor((Date.now() - ms) / 60000);
        if (m < 1) return "just now";
        if (m < 60) return `${m}m ago`;
        const h = Math.floor(m / 60);
        if (h < 24) return `${h}h ago`;
        const day = Math.floor(h / 24);
        if (day < 7) return `${day}d ago`;
        if (typeof d.toFormat === "function") return d.toFormat("dd LLL");
        const dt = new Date(ms);
        return dt.toLocaleDateString(undefined, { month: "short", day: "numeric" });
    },
    taskTime: (d) => {
        if (!d) return "";
        let ms = 0;
        if (typeof d === "number") {
            ms = d;
        } else if (typeof d.toMillis === "function") {
            ms = d.toMillis();
        } else if (d instanceof Date) {
            ms = d.getTime();
        }
        if (!ms) return "";
        const m = Math.floor((Date.now() - ms) / 60000);
        const day = Math.floor(m / 1440);
        const year = d.year || new Date(ms).getFullYear();
        
        let rel = "";
        if (m < 1) rel = "just now";
        else if (m < 60) rel = `${m}m ago`;
        else if (m < 1440) rel = `${Math.floor(m / 60)}h ago`;
        else if (day === 1) rel = "1d ago";
        else rel = `${day}d ago`;

        return `${rel} • ${year}`;
    },
    getProcessedTags: (limit = 35) => {
        let counts = {};
        try {
            const metaTags = app.metadataCache.getTags();
            if (metaTags && Object.keys(metaTags).length > 0) {
                counts = Object.assign({}, metaTags);
            } else {
                for (const p of dv.pages()) {
                    if (!p.file.tags) continue;
                    for (const t of p.file.tags) counts[t] = (counts[t] || 0) + 1;
                }
            }
        } catch (e) {
            for (const p of dv.pages()) {
                if (!p.file.tags) continue;
                for (const t of p.file.tags) counts[t] = (counts[t] || 0) + 1;
            }
        }
        const allEntries = Object.entries(counts).map(([tag, count]) => ({
            tag,
            count,
            pinned: pinnedTags.includes(tag)
        }));

        const sortFn = tagSortMode === "name"
            ? (a, b) => a.tag.localeCompare(b.tag)
            : (a, b) => b.count - a.count;

        const pinned = allEntries.filter(e => e.pinned).sort(sortFn);
        const unpinned = allEntries.filter(e => !e.pinned).sort(sortFn);

        return [...pinned, ...unpinned].slice(0, limit);
    },
    getNotes: (limit = 50, query = "") => {
        try {
            if (activeTag === "__all__" && !query) {
                const mdFiles = app.vault.getMarkdownFiles()
                    .filter(f => f && f.stat)
                    .sort((a, b) => (b.stat?.mtime || 0) - (a.stat?.mtime || 0))
                    .slice(0, limit + pinnedNotes.length);
                
                const noteList = mdFiles.map(f => ({
                    page: {
                        file: {
                            name: f.basename,
                            path: f.path,
                            folder: f.parent ? f.parent.path : "",
                            mtime: f.stat?.mtime || 0
                        }
                    },
                    isPinned: pinnedNotes.includes(f.path)
                }));

                const getMs = (p) => {
                    const m = p.page.file.mtime;
                    return typeof m === "number" ? m : (typeof m?.toMillis === "function" ? m.toMillis() : 0);
                };

                const pinned = noteList.filter(p => p.isPinned).sort((a, b) => getMs(b) - getMs(a));
                const unpinned = noteList.filter(p => !p.isPinned).sort((a, b) => getMs(b) - getMs(a));
                return [...pinned, ...unpinned].slice(0, limit);
            }
        } catch(e) {
            console.error("Fast notes lookup error:", e);
        }

        try {
            let pList = dv.pages();
            if (activeTag !== "__all__") {
                pList = pList.where(p => p.file.tags && p.file.tags.includes(activeTag));
            }

            if (query && query.trim()) {
                const q = query.trim().toLowerCase();
                pList = pList.where(p => 
                    (p.file.name && p.file.name.toLowerCase().includes(q)) || 
                    (p.file.folder && p.file.folder.toLowerCase().includes(q)) ||
                    (p.file.tags && p.file.tags.some(t => t.toLowerCase().includes(q)))
                );
            }

            const allPages = pList.array().map(p => ({
                page: p,
                isPinned: pinnedNotes.includes(p.file.path)
            }));

            const getMs = (p) => {
                const m = p.page.file.mtime;
                return typeof m === "number" ? m : (typeof m?.toMillis === "function" ? m.toMillis() : 0);
            };

            const pinned = allPages.filter(p => p.isPinned).sort((a, b) => getMs(b) - getMs(a));
            const unpinned = allPages.filter(p => !p.isPinned).sort((a, b) => getMs(b) - getMs(a));

            return [...pinned, ...unpinned].slice(0, limit);
        } catch (e) {
            console.error("Dataview notes lookup error:", e);
            return [];
        }
    },
    getRecentlyOpened: (limit = 5) => {
        try {
            return (app.workspace.getLastOpenFiles() || [])
                .filter(p => p.endsWith(".md") && !p.includes("Dashboard"))
                .slice(0, limit);
        } catch (e) { return []; }
    },
    getWeekId: (startDay = "monday") => {
        const now = new Date();
        const day = now.getDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat
        let offset = 0;
        if (startDay === "sunday") {
            offset = day;
        } else if (startDay === "saturday") {
            offset = (day + 1) % 7;
        } else { // monday
            offset = (day + 6) % 7;
        }
        const startOfWeek = new Date(now.getFullYear(), now.getMonth(), now.getDate() - offset);
        const y = startOfWeek.getFullYear();
        const m = String(startOfWeek.getMonth() + 1).padStart(2, "0");
        const d = String(startOfWeek.getDate()).padStart(2, "0");
        return `${y}-${m}-${d}-${startDay}`;
    },
    getHabitStats: () => {
        let totalDots = savedHabits.length * 7;
        let activeDots = 0;
        savedHabits.forEach(h => {
            for (let i = 1; i <= 7; i++) {
                if (localStorage.getItem(`ocean-h-${h}-${i}`)) activeDots++;
            }
        });
        const pct = totalDots > 0 ? (activeDots / totalDots) * 100 : 0;
        return { total: totalDots, active: activeDots, percent: pct };
    },
    bindModalBackdropClose: (overlay, closeModal) => {
        let isMouseDownOnOverlay = false;
        overlay.addEventListener("mousedown", (e) => {
            isMouseDownOnOverlay = (e.target === overlay);
        });
        overlay.addEventListener("mouseup", (e) => {
            if (isMouseDownOnOverlay && e.target === overlay) {
                closeModal();
            }
            isMouseDownOnOverlay = false;
        });
    },
    icon: (parent, name, fallback = "•") => {
        const el = parent.createDiv();
        try {
            setIcon(el, name);
            if (!el.hasChildNodes() && !el.innerHTML.trim()) {
                el.textContent = fallback;
            }
        } catch (e) {
            el.textContent = fallback;
        }
        return el;
    }
};

// Auto-Reset Check: resets at most once per calendar week
const currentHabitWeekId = Utils.getWeekId(masterSettings.weekStart || "monday");
const lastResetWeek = localStorage.getItem(LS.habitWeek);
if (masterSettings.autoResetHabits !== false) {
    if (lastResetWeek && lastResetWeek !== currentHabitWeekId) {
        savedHabits.forEach(h => {
            for (let day = 1; day <= 7; day++) {
                localStorage.removeItem(`ocean-h-${h}-${day}`);
            }
        });
        localStorage.setItem(LS.habitWeek, currentHabitWeekId);
        new Notice("🧬 Bio-Metrics weekly tracker reset for the new week!");
    } else if (!lastResetWeek) {
        localStorage.setItem(LS.habitWeek, currentHabitWeekId);
    }
}

// ══════════════════════════════════════════════
const header = container.createDiv({ cls: "ocean-header" });

// Banner settings gear button in top-right corner
const setBtn = header.createDiv({ cls: "ocean-banner-settings-btn", attr: { title: "Edit Header" } });
Utils.icon(setBtn, "settings", "⚙️");

const heroText = header.createDiv({ cls: "ocean-hero-text" });
const heroTitleEl = heroText.createEl("h1", { text: bannerTitle });
const heroSubEl = heroText.createDiv({
    cls: "ocean-hero-sub",
    text: bannerSubtitle || `${Utils.getGreeting()} — Systems active & ready.`
});

// Center Clock Widget (Big HH:MM:SS with Day & Date)
const clockCont = header.createDiv({ cls: "ocean-header-clock" });
const timeEl = clockCont.createDiv({ cls: "ocean-clock-time" });
const dateEl = clockCont.createDiv({ cls: "ocean-clock-date" });

function updateClock() {
    const now = new Date();
    const pad = (n) => String(n).padStart(2, "0");
    timeEl.textContent = `${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;
    
    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    dateEl.textContent = `${days[now.getDay()]}, ${now.getDate()} ${months[now.getMonth()]} ${now.getFullYear()}`;
}
updateClock();
const clockTimer = setInterval(() => {
    if (!clockCont.isConnected) {
        clearInterval(clockTimer);
        return;
    }
    updateClock();
}, 1000);

// Daily Bible Verse (Dynamic Fetching with RSV Translation & Fast Timeout)
const todayDateStr = new Date().toISOString().slice(0, 10);
const cachedVerseRaw = localStorage.getItem("ocean-daily-verse");
let currentVerse = null;

const FALLBACK_VERSES = [
    { text: "Trust in the Lord with all your heart, and do not rely on your own insight.", ref: "Proverbs 3:5" },
    { text: "I can do all things through him who strengthens me.", ref: "Philippians 4:13" },
    { text: "The Lord is my shepherd; I shall not want.", ref: "Psalm 23:1" },
    { text: "Be strong and courageous; do not be frightened or dismayed, for the Lord your God is with you wherever you go.", ref: "Joshua 1:9" },
    { text: "For I know the plans I have for you, plans for welfare and not for evil, to give you a future and a hope.", ref: "Jeremiah 29:11" },
    { text: "Do not worry about anything, but in everything by prayer and supplication with thanksgiving let your requests be made known to God.", ref: "Philippians 4:6" },
    { text: "The light shines in the darkness, and the darkness did not overcome it.", ref: "John 1:5" },
    { text: "Commit your work to the Lord, and your plans will be established.", ref: "Proverbs 16:3" },
    { text: "Come to me, all you that are weary and are carrying heavy burdens, and I will give you rest.", ref: "Matthew 11:28" },
    { text: "Peace I leave with you; my peace I give to you. Not as the world gives do I give to you. Let not your hearts be troubled, neither let them be afraid.", ref: "John 14:27" },
    { text: "He has told you, O mortal, what is good; and what does the Lord require of you but to do justice, and to love kindness, and to walk humbly with your God?", ref: "Micah 6:8" },
    { text: "Let all that you do be done in love.", ref: "1 Corinthians 16:14" }
];

if (cachedVerseRaw) {
    try {
        const parsed = JSON.parse(cachedVerseRaw);
        if (parsed && parsed.date === todayDateStr && parsed.text && parsed.ref) {
            currentVerse = parsed;
        }
    } catch (e) {}
}

const defaultVerse = currentVerse || FALLBACK_VERSES[0];
const verseWrap = clockCont.createDiv({
    cls: "ocean-bible-verse-wrap",
    attr: { title: "Daily Verse • Click to copy • Right-click to refresh" }
});
const verseQuoteEl = verseWrap.createSpan({ cls: "ocean-bible-quote", text: `“${defaultVerse.text}”` });
const verseRefEl = verseWrap.createSpan({ cls: "ocean-bible-ref", text: `— ${defaultVerse.ref}` });

async function loadVerse(forceRefresh = false) {
    if (!forceRefresh && currentVerse) return;

    let newVerse = null;
    try {
        const fetchPromise = requestUrl({ url: "https://bible-api.com/?random=verse&translation=rsv" });
        const timeoutPromise = new Promise((_, reject) => setTimeout(() => reject(new Error("Timeout")), 3000));
        const res = await Promise.race([fetchPromise, timeoutPromise]);

        if (res && res.json && res.json.text && res.json.reference) {
            const cleanText = res.json.text.trim().replace(/\s+/g, " ");
            const refStr = res.json.reference;
            newVerse = { date: todayDateStr, text: cleanText, ref: refStr };
        }
    } catch (err) {
        // Use random fallback from curated RSV collection if API is offline or slow
        const pool = FALLBACK_VERSES.filter(v => !currentVerse || v.ref !== currentVerse.ref);
        const fallback = pool[Math.floor(Math.random() * pool.length)] || FALLBACK_VERSES[0];
        newVerse = { date: todayDateStr, text: fallback.text, ref: fallback.ref };
    }

    if (newVerse) {
        currentVerse = newVerse;
        localStorage.setItem("ocean-daily-verse", JSON.stringify(currentVerse));
        verseQuoteEl.textContent = `“${currentVerse.text}”`;
        verseRefEl.textContent = `— ${currentVerse.ref}`;
    }
}

loadVerse();

verseWrap.onclick = () => {
    if (currentVerse) {
        navigator.clipboard.writeText(`${currentVerse.ref} - "${currentVerse.text}"`);
        new Notice(`📖 Copied: ${currentVerse.ref}`);
    }
};

verseWrap.oncontextmenu = (e) => {
    e.preventDefault();
    verseQuoteEl.textContent = "Fetching new scripture...";
    verseRefEl.textContent = "";
    loadVerse(true).then(() => {
        new Notice("✨ Loaded new scripture verse");
    }).catch(() => {
        if (currentVerse) {
            verseQuoteEl.textContent = `“${currentVerse.text}”`;
            verseRefEl.textContent = `— ${currentVerse.ref}`;
        }
    });
};

// Header Stats Cubes (Instant 0ms lookup)
const statsCont = header.createDiv({ cls: "ocean-hero-stats" });
const totalNotesCount = app.vault.getMarkdownFiles().length;

const notesCube = statsCont.createDiv({ cls: "ocean-stat-cube" });
const notesTopRow = notesCube.createDiv({ cls: "ocean-stat-top-row" });
notesTopRow.createDiv({ cls: "ocean-stat-star", text: "⭐" });
notesTopRow.createDiv({ cls: "ocean-stat-val", text: String(totalNotesCount) });
notesCube.createDiv({ cls: "ocean-stat-lab", text: "Notes" });

const goalsCube = statsCont.createDiv({
    cls: "ocean-stat-cube",
    attr: { title: "Weekly Bio-Metrics Tracker (Click to jump to metrics)", style: "cursor: pointer;" }
});
const goalsTopRow = goalsCube.createDiv({ cls: "ocean-stat-top-row" });
goalsTopRow.createDiv({ cls: "ocean-stat-star", text: "🎯" });
const goalsValEl = goalsTopRow.createDiv({ cls: "ocean-stat-val", text: "0/0" });
goalsCube.createDiv({ cls: "ocean-stat-lab", text: "Weekly Goals" });

let updateHeaderGoals = () => {
    const stats = Utils.getHabitStats();
    goalsValEl.textContent = stats.total > 0 ? `${stats.active}/${stats.total}` : "0";
};
updateHeaderGoals();

setBtn.onclick = () => openMasterSettingsModal();

function openMasterSettingsModal() {
    const overlay = document.body.createDiv({ cls: "ocean-modal-overlay animate-in" });
    overlay.setAttribute("data-theme", currentTheme);
    overlay.setAttribute("data-mode", currentThemeMode);
    const modal = overlay.createDiv({ cls: "ocean-modal ocean-settings-modal" });

    let tempTheme = currentTheme;
    let tempThemeMode = currentThemeMode;
    let tempFontSize = masterSettings.fontSize || 16;

    const closeModal = () => {
        // Revert live preview if not saved
        container.setAttribute("data-theme", currentTheme);
        container.setAttribute("data-mode", currentThemeMode);
        const savedScale = (masterSettings.fontSize || 16) / 16;
        container.style.setProperty("--ocean-font-size", `${masterSettings.fontSize || 16}px`);
        container.style.setProperty("--ocean-scale", `${savedScale}`);
        document.removeEventListener("keydown", escHandler);
        overlay.remove();
    };

    const escHandler = (ev) => {
        if (ev.key === "Escape") closeModal();
    };
    document.addEventListener("keydown", escHandler);
    
    // Header
    const hdr = modal.createDiv({ cls: "ocean-settings-hdr" });
    hdr.createDiv({ cls: "ocean-modal-title", text: "⚙️ DASHBOARD MASTER SETTINGS" });
    const closeIcon = hdr.createDiv({ cls: "ocean-settings-close", text: "✕", attr: { title: "Close (Esc)" } });
    closeIcon.onclick = closeModal;

    // Tab Switcher (4 Tabs)
    const tabsRow = modal.createDiv({ cls: "ocean-settings-tabs" });
    const tabWidgetsBtn = tabsRow.createDiv({ cls: "ocean-settings-tab active", text: "🎛️ WIDGETS" });
    const tabThemesBtn = tabsRow.createDiv({ cls: "ocean-settings-tab", text: "🎨 THEMES" });
    const tabGeneralBtn = tabsRow.createDiv({ cls: "ocean-settings-tab", text: "⚙️ GENERAL" });
    const tabDataBtn = tabsRow.createDiv({ cls: "ocean-settings-tab", text: "💾 DATA" });

    const contentArea = modal.createDiv({ cls: "ocean-settings-content" });

    // TAB 1: WIDGETS
    const widgetsPanel = contentArea.createDiv({ cls: "ocean-settings-panel active" });
    widgetsPanel.createDiv({ cls: "ocean-settings-desc", text: "Toggle individual widgets on/off. Surrounding cards will dynamically stretch or collapse." });

    const widgetDefs = [
        { key: "targets", icon: "🎯", name: "Active Targets & Countdowns", desc: "Panoramic runway showing milestone countdowns" },
        { key: "tasks", icon: "⚡", name: "Live Tasks & Pending Notes", desc: "Panoramic feed of notes tagged #pending, #todo, and checklists" },
        { key: "topics", icon: "🏷️", name: "Browse by Topic (Tag Cloud)", desc: "Left column tag pill directory with sorting & pin support" },
        { key: "jump", icon: "↩️", name: "Jump Back In (Recent Notes)", desc: "Left column quick shortcuts to recently opened notes" },
        { key: "recent", icon: "📄", name: "Recently Edited Feed", desc: "Middle column live feed of recent notes with search" },
        { key: "scratchpad", icon: "📝", name: "Persistent Scratchpad", desc: "Middle column auto-saving temporary notepad" },
        { key: "collections", icon: "🗂️", name: "Collection Cards Directory", desc: "Right column custom bookmark cards to workspaces" },
        { key: "actions", icon: "⚡", name: "System Quick Actions", desc: "Right column Obsidian command launcher buttons" },
        { key: "habits", icon: "🧬", name: "Bio-Metrics Tracker", desc: "Bottom weekly metric tracking bar and 7-day checkboxes" }
    ];

    const widgetGrid = widgetsPanel.createDiv({ cls: "ocean-settings-toggle-grid" });
    const tempWidgets = Object.assign({}, masterSettings.widgets);

    widgetDefs.forEach(w => {
        const item = widgetGrid.createDiv({ cls: "ocean-settings-toggle-item" });
        const textWrap = item.createDiv({ cls: "ocean-toggle-text-wrap" });
        textWrap.createDiv({ cls: "ocean-toggle-name", text: `${w.icon} ${w.name}` });
        textWrap.createDiv({ cls: "ocean-toggle-sub", text: w.desc });

        const toggleSwitch = item.createDiv({ cls: "ocean-toggle-switch" + (tempWidgets[w.key] ? " active" : "") });
        toggleSwitch.createDiv({ cls: "ocean-toggle-knob" });

        toggleSwitch.onclick = () => {
            tempWidgets[w.key] = !tempWidgets[w.key];
            toggleSwitch.classList.toggle("active", tempWidgets[w.key]);
        };
    });

    // TAB 2: THEMES & MODES
    const themesPanel = contentArea.createDiv({ cls: "ocean-settings-panel" });
    themesPanel.createDiv({ cls: "ocean-settings-desc", text: "Choose a visual design language and appearance mode. Click any theme to preview live in the background." });

    themesPanel.createDiv({ text: "Appearance Mode:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:6px;" } });
    
    // Segmented Mode Controls
    const modeSegmented = themesPanel.createDiv({ cls: "ocean-mode-segmented" });
    const modes = [
        { id: "auto", label: "🌗 Auto (Obsidian)" },
        { id: "dark", label: "🌙 Dark Mode" },
        { id: "light", label: "☀️ Light Mode" }
    ];
    const modeButtons = [];

    modes.forEach(m => {
        const btn = modeSegmented.createDiv({
            cls: "ocean-mode-btn" + (tempThemeMode === m.id ? " active" : ""),
            text: m.label
        });
        modeButtons.push({ id: m.id, el: btn });

        btn.onclick = () => {
            tempThemeMode = m.id;
            modeButtons.forEach(b => b.el.classList.toggle("active", b.id === tempThemeMode));
            container.setAttribute("data-mode", tempThemeMode);
            overlay.setAttribute("data-mode", tempThemeMode);
        };
    });

    themesPanel.createDiv({ text: "Theme Presets:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:6px; margin-top:8px;" } });
    
    const themeDefs = [
        {
            id: "ocean",
            name: "Ocean Deep",
            icon: "🌊",
            desc: "Bioluminescent cyan, deep navy glass, and wave glowing borders.",
            swatches: ["#38bdf8", "#818cf8", "#34d399", "#0b1120"]
        },
        {
            id: "zen",
            name: "Zen Minimalist",
            icon: "🌬️",
            desc: "Wabi-sabi charcoal, sand stone, calm sage green, and flat 8px borders.",
            swatches: ["#a3e635", "#18181b", "#78716c", "#f43f5e"]
        },
        {
            id: "synthwave",
            name: "Warm Synthwave",
            icon: "🌆",
            desc: "Pastel sunset rose, lavender mist, soft apricot, and sharp zero-radius corners.",
            swatches: ["#f472b6", "#c084fc", "#7dd3fc", "#fde047"]
        },
        {
            id: "tailwind",
            name: "Tailwind Slate",
            icon: "⚡",
            desc: "Modern web slate/zinc, electric indigo, emerald, and sharp 10px borders.",
            swatches: ["#6366f1", "#0f172a", "#10b981", "#f43f5e"]
        },
        {
            id: "macos",
            name: "macOS Sequoia",
            icon: "🍎",
            desc: "Frosted acrylic glassmorphism, SF vibrant colors, and Apple 18px radii.",
            swatches: ["#0a84ff", "#242426", "#ffd60a", "#bf5af2"]
        },
        {
            id: "material",
            name: "Material You (M3)",
            icon: "🤖",
            desc: "Android MD3 elevations, expressive pastel lavender pills, and 22px pill radii.",
            swatches: ["#d0bcff", "#1d1b20", "#a8eff0", "#ffdf9a"]
        }
    ];

    const themeGrid = themesPanel.createDiv({ cls: "ocean-theme-grid" });
    const themeCards = [];

    themeDefs.forEach(t => {
        const card = themeGrid.createDiv({
            cls: "ocean-theme-card" + (tempTheme === t.id ? " active" : "")
        });
        themeCards.push({ id: t.id, el: card });

        const cardHdr = card.createDiv({ cls: "ocean-theme-card-hdr" });
        const nameEl = cardHdr.createDiv({ cls: "ocean-theme-name" });
        nameEl.createSpan({ text: t.icon });
        nameEl.createSpan({ text: t.name });
        cardHdr.createDiv({ cls: "ocean-theme-active-tag", text: "Active" });

        card.createDiv({ cls: "ocean-theme-desc", text: t.desc });

        const swatchWrap = card.createDiv({ cls: "ocean-theme-swatches" });
        t.swatches.forEach(c => {
            swatchWrap.createDiv({ cls: "ocean-theme-swatch", attr: { style: `background: ${c};` } });
        });

        card.onclick = () => {
            tempTheme = t.id;
            themeCards.forEach(c => c.el.classList.toggle("active", c.id === tempTheme));
            container.setAttribute("data-theme", tempTheme);
            overlay.setAttribute("data-theme", tempTheme);
        };
    });

    // TAB 3: GENERAL
    const generalPanel = contentArea.createDiv({ cls: "ocean-settings-panel" });
    generalPanel.createDiv({ cls: "ocean-settings-desc", text: "Customize dashboard branding, layout heights, and limits." });

    generalPanel.createDiv({ text: "Dashboard Banner Title:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const titleInp = generalPanel.createEl("input", { cls: "ocean-modal-input", attr: { value: bannerTitle } });

    generalPanel.createDiv({ text: "Subtitle / Motto:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px; margin-top:10px;" } });
    const subInp = generalPanel.createEl("input", { cls: "ocean-modal-input", attr: { value: bannerSubtitle, placeholder: "Leave empty for dynamic time greeting" } });

    generalPanel.createDiv({ text: "Dashboard Font Size Scale:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px; margin-top:10px;" } });
    const fzRow = generalPanel.createDiv({ cls: "ocean-stepper-row" });
    const fzMinusBtn = fzRow.createEl("button", { cls: "ocean-stepper-btn", text: "➖ 1" });
    const fzDisplay = fzRow.createDiv({ cls: "ocean-stepper-display", text: `${tempFontSize}px` });
    const fzPlusBtn = fzRow.createEl("button", { cls: "ocean-stepper-btn", text: "➕ 1" });
    const fzResetBtn = fzRow.createEl("button", { cls: "ocean-stepper-btn ocean-stepper-reset", text: "Reset (16px)" });

    fzMinusBtn.onclick = () => {
        if (tempFontSize > 11) {
            tempFontSize--;
            fzDisplay.innerText = `${tempFontSize}px`;
            container.style.setProperty("--ocean-font-size", `${tempFontSize}px`);
            container.style.setProperty("--ocean-scale", `${tempFontSize / 16}`);
        }
    };

    fzPlusBtn.onclick = () => {
        if (tempFontSize < 28) {
            tempFontSize++;
            fzDisplay.innerText = `${tempFontSize}px`;
            container.style.setProperty("--ocean-font-size", `${tempFontSize}px`);
            container.style.setProperty("--ocean-scale", `${tempFontSize / 16}`);
        }
    };

    fzResetBtn.onclick = () => {
        tempFontSize = 16;
        fzDisplay.innerText = "16px";
        container.style.setProperty("--ocean-font-size", "16px");
        container.style.setProperty("--ocean-scale", "1");
    };

    generalPanel.createDiv({ text: "Bento Grid Height (px):", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px; margin-top:10px;" } });
    const heightInp = generalPanel.createEl("input", { cls: "ocean-modal-input", attr: { type: "number", value: String(masterSettings.gridHeight || 550), min: "400", max: "1000", step: "25" } });

    generalPanel.createDiv({ text: "Max Recent Notes to Load:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px; margin-top:10px;" } });
    const limitInp = generalPanel.createEl("input", { cls: "ocean-modal-input", attr: { type: "number", value: String(masterSettings.recentLimit || 50), min: "10", max: "150", step: "5" } });

    generalPanel.createDiv({ text: "Max Topic Tags to Load:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px; margin-top:10px;" } });
    const tagLimitInp = generalPanel.createEl("input", { cls: "ocean-modal-input", attr: { type: "number", value: String(masterSettings.tagLimit || 35), min: "10", max: "100", step: "5" } });

    generalPanel.createDiv({ text: "First Day of the Week (Weekly Metrics Tracker):", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px; margin-top:10px;" } });
    const weekStartSelect = generalPanel.createEl("select", { cls: "ocean-modal-input" });
    [
        { val: "monday", label: "Monday (Default, ISO 8601)" },
        { val: "sunday", label: "Sunday" },
        { val: "saturday", label: "Saturday" }
    ].forEach(opt => {
        const optionEl = weekStartSelect.createEl("option", { value: opt.val, text: opt.label });
        if ((masterSettings.weekStart || "monday") === opt.val) optionEl.selected = true;
    });

    const autoResetRow = generalPanel.createDiv({ attr: { style: "display:flex; align-items:center; gap:8px; margin-top:12px;" } });
    const autoResetChk = autoResetRow.createEl("input", { attr: { type: "checkbox" } });
    autoResetChk.checked = masterSettings.autoResetHabits !== false;
    autoResetRow.createEl("label", { text: "Automatically reset weekly metrics tracker at start of each new week", attr: { style: "font-size:0.82rem; color:var(--ocean-text); cursor:pointer;" } });
    autoResetRow.onclick = (e) => {
        if (e.target !== autoResetChk) autoResetChk.checked = !autoResetChk.checked;
    };

    // TAB 4: DATA & BACKUP
    const dataPanel = contentArea.createDiv({ cls: "ocean-settings-panel" });
    dataPanel.createDiv({ cls: "ocean-settings-desc", text: "Reset individual component caches or backup/restore your dashboard configuration." });

    const dataBtnGrid = dataPanel.createDiv({ cls: "ocean-settings-data-grid" });

    // Clear Current Week Habits
    const clearWeekBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn", text: "🧹 Clear Current Week's Metric Tracking checkmarks" });
    clearWeekBtn.onclick = () => {
        savedHabits.forEach(h => {
            for (let day = 1; day <= 7; day++) {
                localStorage.removeItem(`ocean-h-${h}-${day}`);
            }
        });
        new Notice("🧹 Current week's metric tracker checkmarks cleared!");
    };

    // Reset Targets
    const resetTargetsBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn", text: "🎯 Reset Targets to Placeholders" });
    resetTargetsBtn.onclick = () => {
        savedTargets = [
            { title: "Project Launch Milestone", date: "2026-10-15", emoji: "🚀", link: "" },
            { title: "Certification Exam", date: "2026-12-31", emoji: "🎯", link: "" },
            { title: "Quarterly Review", date: "2027-03-31", emoji: "📈", link: "" }
        ];
        localStorage.setItem(LS.targets, JSON.stringify(savedTargets));
        new Notice("🎯 Targets reset to default placeholders!");
    };

    // Reset Collections
    const resetCardsBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn", text: "🗂️ Reset Collection Cards to Placeholders" });
    resetCardsBtn.onclick = () => {
        savedCards = [
            { title: "Project Alpha", subtitle: "Active Workspace & Tasks", emoji: "🚀", link: "" },
            { title: "Knowledge Base", subtitle: "Core Notes & Wiki Hub", emoji: "📚", link: "" },
            { title: "Reading List", subtitle: "Books, Papers & Articles", emoji: "📖", link: "" },
            { title: "Daily Journal", subtitle: "Thoughts & Reflections", emoji: "📅", link: "" }
        ];
        localStorage.setItem(LS.cards, JSON.stringify(savedCards));
        new Notice("🗂️ Collection cards reset to default placeholders!");
    };

    // Reset Habits
    const resetHabitsBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn", text: "🧬 Reset Habit Tracker to Defaults" });
    resetHabitsBtn.onclick = () => {
        savedHabits = ["Reading", "Deep Work", "Exercise", "Meditation"];
        localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
        new Notice("🧬 Metric Tracker reset to defaults!");
    };

    // Clear Scratchpad
    const clearScratchBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn", text: "🧹 Clear Persistent Scratchpad" });
    clearScratchBtn.onclick = () => {
        localStorage.setItem(LS.scratchpad, "");
        new Notice("🧹 Scratchpad buffer cleared!");
    };

    // Export Settings JSON
    const exportBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn primary", text: "💾 Export Config JSON (Copy)" });
    exportBtn.onclick = () => {
        const fullBackup = {
            version: "ocean-v2",
            theme: currentTheme,
            themeMode: currentThemeMode,
            date: new Date().toISOString(),
            settings: masterSettings,
            title: localStorage.getItem(LS.title) || bannerTitle,
            subtitle: localStorage.getItem(LS.subtitle) || bannerSubtitle,
            targets: savedTargets,
            cards: savedCards,
            habits: savedHabits,
            pinnedNotes: pinnedNotes,
            pinnedTags: pinnedTags,
            scratchpad: localStorage.getItem(LS.scratchpad) || ""
        };
        navigator.clipboard.writeText(JSON.stringify(fullBackup, null, 2));
        new Notice("💾 Copied complete Dashboard configuration to clipboard!");
    };

    // Import Settings JSON with in-app Modal (Fixes Electron prompt() not supported error)
    const importBtn = dataBtnGrid.createEl("button", { cls: "ocean-btn", text: "📥 Import Config JSON" });
    importBtn.onclick = () => {
        const importOverlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
        importOverlay.setAttribute("data-theme", currentTheme);
        if (currentThemeMode === "dark" || (currentThemeMode === "auto" && document.body.classList.contains("theme-dark"))) {
            importOverlay.setAttribute("data-mode", "dark");
        }

        const importModal = importOverlay.createDiv({ cls: "ocean-modal", attr: { style: "max-width: 580px; width: 92%;" } });
        Utils.bindModalBackdropClose(importOverlay, () => importOverlay.remove());
        const importHdr = importModal.createDiv({ cls: "ocean-modal-hdr" });
        importHdr.createDiv({ cls: "ocean-modal-title", text: "📥 Import Dashboard JSON" });
        const closeImportBtn = importHdr.createDiv({ cls: "ocean-modal-close", text: "✕" });
        closeImportBtn.onclick = () => importOverlay.remove();

        const importBody = importModal.createDiv({ cls: "ocean-modal-body", attr: { style: "display:flex; flex-direction:column; gap:12px;" } });
        importBody.createDiv({
            text: "Paste your exported Dashboard Ocean JSON configuration below, or click 'Paste from Clipboard':",
            attr: { style: "font-size:0.85rem; color:var(--ocean-muted); line-height:1.4;" }
        });

        const jsonArea = importBody.createEl("textarea", {
            cls: "ocean-modal-input",
            attr: {
                placeholder: "{\n  \"version\": \"ocean-v2\",\n  \"targets\": [...]\n}",
                style: "height: 200px; font-family: var(--ocean-font-mono); font-size: 0.8rem; line-height: 1.4; resize: vertical; width: 100%; white-space: pre;"
            }
        });

        const importActions = importModal.createDiv({ cls: "ocean-modal-actions", attr: { style: "display:flex; justify-content:space-between; align-items:center; margin-top:16px;" } });
        
        const pasteBtn = importActions.createEl("button", {
            cls: "ocean-btn",
            text: "📋 Paste from Clipboard",
            attr: { style: "font-size:0.8rem;" }
        });

        pasteBtn.onclick = async () => {
            try {
                const text = await navigator.clipboard.readText();
                if (text) jsonArea.value = text;
            } catch(e) {
                new Notice("⚠️ Could not read clipboard automatically. Please press Ctrl+V inside the box.");
            }
        };

        const rightBtns = importActions.createDiv({ attr: { style: "display:flex; gap:8px;" } });
        const cancelBtn = rightBtns.createEl("button", { cls: "ocean-btn", text: "Cancel" });
        cancelBtn.onclick = () => importOverlay.remove();

        const applyImportBtn = rightBtns.createEl("button", { cls: "ocean-btn primary", text: "✅ Apply & Import" });
        applyImportBtn.onclick = () => {
            const jsonInput = jsonArea.value.trim();
            if (!jsonInput) {
                new Notice("⚠️ Please paste valid JSON before importing.");
                return;
            }

            try {
                const parsed = JSON.parse(jsonInput);
                if (parsed.theme) localStorage.setItem(LS.theme, parsed.theme);
                if (parsed.themeMode) localStorage.setItem(LS.themeMode, parsed.themeMode);
                if (parsed.settings) localStorage.setItem(LS.settings, JSON.stringify(parsed.settings));
                if (parsed.title) localStorage.setItem(LS.title, parsed.title);
                if (parsed.subtitle !== undefined) localStorage.setItem(LS.subtitle, parsed.subtitle);
                if (parsed.targets) localStorage.setItem(LS.targets, JSON.stringify(parsed.targets));
                if (parsed.cards) localStorage.setItem(LS.cards, JSON.stringify(parsed.cards));
                if (parsed.habits) localStorage.setItem(LS.habits, JSON.stringify(parsed.habits));
                if (parsed.pinnedNotes) localStorage.setItem(LS.pinnedNotes, JSON.stringify(parsed.pinnedNotes));
                if (parsed.pinnedTags) localStorage.setItem(LS.pinnedTags, JSON.stringify(parsed.pinnedTags));
                if (parsed.scratchpad !== undefined) localStorage.setItem(LS.scratchpad, parsed.scratchpad);

                new Notice("✨ Dashboard configuration successfully imported! Reloading...", 4000);
                importOverlay.remove();
                overlay.remove();

                setTimeout(() => {
                    try {
                        const activeView = app.workspace.getActiveViewOfType(tp => true);
                        if (activeView && activeView.leaf) activeView.leaf.rebuildView();
                    } catch(e) {
                        location.reload();
                    }
                }, 300);
            } catch(e) {
                new Notice(`⚠️ Invalid JSON: ${e.message}`, 6000);
            }
        };
    };

    // 1. Clear Everything & Start from Scratch (Clean Slate)
    const cleanSlateBtn = dataBtnGrid.createEl("button", {
        cls: "ocean-btn",
        text: "🧹 Clear Everything & Start From Scratch",
        attr: { style: "grid-column: 1 / -1; color: #38bdf8; border-color: rgba(56,189,248,0.4); margin-top:8px;" }
    });
    cleanSlateBtn.onclick = () => {
        if (!confirm("Are you sure you want to clear all custom widgets, cards, targets, scratchpad, and metrics tracker to start completely from a clean blank slate?")) return;
        localStorage.setItem(LS.theme, "zen");
        localStorage.setItem(LS.themeMode, "auto");
        localStorage.setItem(LS.targets, "[]");
        localStorage.setItem(LS.cards, "[]");
        localStorage.setItem(LS.habits, "[]");
        localStorage.setItem(LS.scratchpad, "");
        localStorage.setItem(LS.pinnedNotes, "[]");
        localStorage.setItem(LS.pinnedTags, "[]");
        localStorage.setItem(LS.tag, "__all__");
        localStorage.setItem(LS.title, "DASHBOARD OCEAN");
        localStorage.setItem(LS.subtitle, "");

        // Remove all habit day checkboxes
        const keysToRemove = [];
        for (let i = 0; i < localStorage.length; i++) {
            const k = localStorage.key(i);
            if (k && k.startsWith("ocean-h-")) keysToRemove.push(k);
        }
        keysToRemove.forEach(k => localStorage.removeItem(k));

        new Notice("🧹 Dashboard wiped clean to a blank slate! Please press Ctrl + R to reload the dashboard.", 5000);
        overlay.remove();
        setTimeout(() => {
            try {
                const activeView = app.workspace.getActiveViewOfType(tp => true);
                if (activeView && activeView.leaf) activeView.leaf.rebuildView();
            } catch(e) {}
        }, 300);
    };

    // 2. Factory Reset to Default Placeholders
    const factoryResetBtn = dataBtnGrid.createEl("button", {
        cls: "ocean-btn",
        text: "🎯 Reset to Default Placeholders",
        attr: { style: "grid-column: 1 / -1; color: var(--ocean-rose); border-color: rgba(244,63,94,0.4); margin-top:4px;" }
    });
    factoryResetBtn.onclick = () => {
        if (!confirm("Are you sure you want to reset the dashboard back to the initial sample milestone targets, collection cards, and metric tracker placeholders?")) return;
        Object.values(LS).forEach(k => localStorage.removeItem(k));
        new Notice("✨ Reset to default placeholders complete! Please press Ctrl + R to reload the dashboard.", 5000);
        overlay.remove();
        setTimeout(() => {
            try {
                const activeView = app.workspace.getActiveViewOfType(tp => true);
                if (activeView && activeView.leaf) activeView.leaf.rebuildView();
            } catch(e) {}
        }, 300);
    };

    // Tab Navigation Logic
    const allTabBtns = [tabWidgetsBtn, tabThemesBtn, tabGeneralBtn, tabDataBtn];
    const allPanels = [widgetsPanel, themesPanel, generalPanel, dataPanel];

    tabWidgetsBtn.onclick = () => {
        allTabBtns.forEach(b => b.classList.remove("active"));
        allPanels.forEach(p => p.classList.remove("active"));
        tabWidgetsBtn.classList.add("active");
        widgetsPanel.classList.add("active");
    };

    tabThemesBtn.onclick = () => {
        allTabBtns.forEach(b => b.classList.remove("active"));
        allPanels.forEach(p => p.classList.remove("active"));
        tabThemesBtn.classList.add("active");
        themesPanel.classList.add("active");
    };

    tabGeneralBtn.onclick = () => {
        allTabBtns.forEach(b => b.classList.remove("active"));
        allPanels.forEach(p => p.classList.remove("active"));
        tabGeneralBtn.classList.add("active");
        generalPanel.classList.add("active");
    };

    tabDataBtn.onclick = () => {
        allTabBtns.forEach(b => b.classList.remove("active"));
        allPanels.forEach(p => p.classList.remove("active"));
        tabDataBtn.classList.add("active");
        dataPanel.classList.add("active");
    };

    // Bottom Action Row
    const bottomRow = modal.createDiv({ cls: "ocean-modal-btns", attr: { style: "margin-top:18px;" } });
    const cancelBtn = bottomRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const saveApplyBtn = bottomRow.createEl("button", { cls: "ocean-btn primary", text: "💾 Save & Apply" });

    cancelBtn.onclick = closeModal;
    saveApplyBtn.onclick = () => {
        currentTheme = tempTheme;
        currentThemeMode = tempThemeMode;
        localStorage.setItem(LS.theme, currentTheme);
        localStorage.setItem(LS.themeMode, currentThemeMode);

        masterSettings.widgets = tempWidgets;
        masterSettings.gridHeight = parseInt(heightInp.value, 10) || 550;
        masterSettings.fontSize = tempFontSize;
        masterSettings.recentLimit = parseInt(limitInp.value, 10) || 50;
        masterSettings.tagLimit = parseInt(tagLimitInp.value, 10) || 35;
        masterSettings.weekStart = weekStartSelect.value;
        masterSettings.autoResetHabits = autoResetChk.checked;

        bannerTitle = titleInp.value.trim() || "DASHBOARD OCEAN";
        bannerSubtitle = subInp.value.trim();
        localStorage.setItem(LS.title, bannerTitle);
        localStorage.setItem(LS.subtitle, bannerSubtitle);
        localStorage.setItem(LS.settings, JSON.stringify(masterSettings));

        document.removeEventListener("keydown", escHandler);
        new Notice("✨ Settings & Theme saved! Please press Ctrl + R to reload the dashboard.", 5000);
        overlay.remove();

        setTimeout(() => {
            try {
                const activeView = app.workspace.getActiveViewOfType(tp => true);
                if (activeView && activeView.leaf) activeView.leaf.rebuildView();
            } catch(e) {}
        }, 200);
    };

    Utils.bindModalBackdropClose(overlay, closeModal);
}

// ══════════════════════════════════════════════
// 1.5 DUAL RUNWAY: TARGETS (LEFT) & TASKS (RIGHT)
// ══════════════════════════════════════════════
const showTargets = masterSettings.widgets.targets !== false;
const showTasks = masterSettings.widgets.tasks !== false;

let runwayGrid = null;
let runwayTrack = null;
let tasksTrack = null;

const enableHorizontalWheel = (el) => {
    if (!el) return;
    el.addEventListener("wheel", (e) => {
        // If the container is in narrow, compact, or mobile downward flow, let native vertical scrolling work
        if (container.classList.contains("ocean-narrow") || 
            container.classList.contains("ocean-compact") || 
            container.classList.contains("ocean-is-mobile") ||
            container.classList.contains("ocean-phone-view")) {
            return;
        }

        // Only redirect horizontal scroll when the track has horizontal overflow
        if (el.scrollWidth > el.clientWidth && e.deltaY !== 0) {
            e.preventDefault();
            el.scrollLeft += e.deltaY;
        }
    }, { passive: false });
};

if (showTargets || showTasks) {
    runwayGrid = container.createDiv({ cls: "ocean-runway-grid" });
    if (!showTargets || !showTasks) {
        runwayGrid.style.gridTemplateColumns = "1fr";
    }

    if (showTargets) {
        const targetsCard = runwayGrid.createDiv({ cls: "ocean-card ocean-runway-card" });
        const targetsHdr = targetsCard.createDiv({ cls: "ocean-runway-hdr" });
        targetsHdr.createDiv({ cls: "ocean-card-title", text: "🎯 TARGETS & COUNTDOWNS" });

        const addTargetBtn = targetsHdr.createDiv({ cls: "ocean-add-btn", text: "+ ADD TARGET" });
        runwayTrack = targetsCard.createDiv({ cls: "ocean-targets-track" });
        enableHorizontalWheel(runwayTrack);
        addTargetBtn.onclick = () => showTargetModal();
    }

    if (showTasks) {
        const tasksCard = runwayGrid.createDiv({ cls: "ocean-card ocean-runway-card" });
        const tasksHdr = tasksCard.createDiv({ cls: "ocean-runway-hdr" });
        tasksHdr.createDiv({ cls: "ocean-card-title", text: "⚡ LIVE TASKS / PENDING" });

        tasksTrack = tasksCard.createDiv({ cls: "ocean-targets-track" });
        enableHorizontalWheel(tasksTrack);
    }
}

function renderTargets() {
    runwayTrack.innerHTML = "";
    if (savedTargets.length === 0) {
        runwayTrack.createDiv({ text: "No active targets. Click + ADD TARGET to set a milestone!", attr: { style: "font-size:0.85rem; color:var(--ocean-muted); padding:4px;" } });
        return;
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    savedTargets.forEach((tg, idx) => {
        const capsule = runwayTrack.createDiv({ cls: "ocean-target-capsule" });

        capsule.createDiv({ cls: "ocean-target-emoji", text: tg.emoji || "🎯" });

        const info = capsule.createDiv({ cls: "ocean-target-info" });
        info.createDiv({ cls: "ocean-target-title", text: tg.title });
        
        let dateFormatted = tg.date;
        let daysLeft = 0;
        let badgeCls = "ocean-target-badge";
        let badgeText = "";

        if (tg.date) {
            const targetDate = new Date(tg.date);
            targetDate.setHours(0, 0, 0, 0);
            const diffTime = targetDate - today;
            daysLeft = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
            
            const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            dateFormatted = `${targetDate.getDate()} ${months[targetDate.getMonth()]} ${targetDate.getFullYear()}`;

            if (daysLeft > 1) {
                badgeText = `${daysLeft}d left`;
                badgeCls += " upcoming";
            } else if (daysLeft === 1) {
                badgeText = "Tomorrow";
                badgeCls += " soon";
            } else if (daysLeft === 0) {
                badgeText = "Today 🎉";
                badgeCls += " today";
            } else {
                badgeText = `${Math.abs(daysLeft)}d overdue`;
                badgeCls += " overdue";
            }
        }

        const metaRow = info.createDiv({ cls: "ocean-target-meta" });
        metaRow.createSpan({ cls: "ocean-target-date", text: dateFormatted });

        if (badgeText) {
            metaRow.createSpan({ cls: badgeCls, text: badgeText });
        }

        const actions = capsule.createDiv({ cls: "ocean-target-actions" });
        const editBtn = actions.createDiv({ cls: "ocean-col-card-btn", text: "✎", attr: { title: "Edit Target" } });
        const delBtn = actions.createDiv({ cls: "ocean-col-card-btn", text: "✕", attr: { title: "Delete Target" } });

        editBtn.onclick = (e) => { e.stopPropagation(); showTargetModal(tg, idx); };
        delBtn.onclick = (e) => {
            e.stopPropagation();
            savedTargets.splice(idx, 1);
            localStorage.setItem(LS.targets, JSON.stringify(savedTargets));
            renderTargets();
            new Notice(`🗑️ Removed target: ${tg.title}`);
        };

        capsule.onclick = () => {
            if (tg.link) app.workspace.openLinkText(tg.link, "", false);
        };
    });
}

function showTargetModal(targetToEdit = null, idx = null) {
    const overlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
    const modal = overlay.createDiv({ cls: "ocean-modal" });

    // Header with Title & Close '✕'
    const modalHdr = modal.createDiv({ cls: "ocean-settings-hdr" });
    modalHdr.createDiv({ cls: "ocean-modal-title", text: targetToEdit ? "✎ Edit Target Milestone" : "🎯 Add Target Milestone" });
    const closeBtn = modalHdr.createDiv({ cls: "ocean-settings-close", text: "✕", attr: { title: "Close (Esc)" } });

    const closeModal = () => {
        document.removeEventListener("keydown", escHandler);
        overlay.remove();
    };
    closeBtn.onclick = closeModal;

    const escHandler = (ev) => {
        if (ev.key === "Escape") closeModal();
    };
    document.addEventListener("keydown", escHandler);

    modal.createDiv({ text: "Milestone / Target Title:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const titleInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: targetToEdit ? targetToEdit.title : "", placeholder: "E.g.: Heavy Commercial License Exam" } });

    modal.createDiv({ text: "Target Date:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, "0")}-${String(now.getDate()).padStart(2, "0")}`;
    const dateInp = modal.createEl("input", {
        cls: "ocean-modal-input",
        attr: { type: "date", min: todayStr, value: targetToEdit ? (targetToEdit.date || "") : "" }
    });

    modal.createDiv({ text: "Emoji Icon:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const emojiInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: targetToEdit ? (targetToEdit.emoji || "🎯") : "🎯", placeholder: "🎯" } });

    modal.createDiv({ text: "Target Note Link (Optional):", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const linkInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: targetToEdit ? (targetToEdit.link || "") : "", placeholder: "E.g.: Future or Roadmaps/License" } });

    const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
    
    if (targetToEdit !== null && idx !== null) {
        const delModalBtn = btnRow.createEl("button", {
            cls: "ocean-btn",
            text: "🗑️ Delete",
            attr: { style: "margin-right:auto; color:var(--ocean-rose);" }
        });
        delModalBtn.onclick = () => {
            savedTargets.splice(idx, 1);
            localStorage.setItem(LS.targets, JSON.stringify(savedTargets));
            if (showTargets && runwayTrack) renderTargets();
            new Notice(`🗑️ Deleted target ${targetToEdit.title}`);
            closeModal();
        };
    }

    const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: targetToEdit ? "Save Changes" : "Save Target" });

    cancel.onclick = closeModal;
    save.onclick = () => {
        const title = titleInp.value.trim();
        if (!title) {
            new Notice("⚠️ Please enter a milestone title");
            return;
        }
        if (dateInp.value && dateInp.value < todayStr) {
            new Notice("⚠️ Target date cannot be in the past!");
            return;
        }
        const newTarget = {
            title: title,
            date: dateInp.value,
            emoji: emojiInp.value.trim() || "🎯",
            link: linkInp.value.trim()
        };

        if (targetToEdit !== null && idx !== null) {
            savedTargets[idx] = newTarget;
        } else {
            savedTargets.push(newTarget);
        }
        localStorage.setItem(LS.targets, JSON.stringify(savedTargets));
        if (showTargets && runwayTrack) renderTargets();
        closeModal();
    };
    Utils.bindModalBackdropClose(overlay, closeModal);
}

if (showTargets && runwayTrack) {
    renderTargets();
}

function renderLiveTasks() {
    if (!tasksTrack) return;
    tasksTrack.innerHTML = "";

    // 1. Query notes with #pending or #todo
    let pendingNotes = [];
    try {
        const pages = dv.pages("#pending or #todo or #tasks or #task");
        pages.forEach(p => {
            const rawTags = (p.file.tags && p.file.tags.values) ? p.file.tags.values : (p.file.tags || []);
            const tags = Array.isArray(rawTags) ? rawTags : [rawTags];
            const matching = tags.filter(t => typeof t === "string" && ["#pending", "#todo", "#task", "#tasks"].includes(t.toLowerCase()));
            if (matching.length > 0) {
                pendingNotes.push({ page: p, tag: matching[0] });
            }
        });
        pendingNotes.sort((a, b) => (b.page.file.mtime ? b.page.file.mtime.toMillis() : 0) - (a.page.file.mtime ? a.page.file.mtime.toMillis() : 0));
    } catch(e) {
        pendingNotes = [];
    }

    // 2. Query checklist tasks (fast targeted scan)
    let todoTasks = [];
    try {
        const taskPages = dv.pages('#tasks or #todo or #task or #pending or "daily" or "Daily"');
        if (taskPages && taskPages.length > 0) {
            todoTasks = taskPages.file.tasks.where(t => !t.completed).slice(0, 10);
        }
        if (!todoTasks || todoTasks.length === 0) {
            const recentPages = dv.pages().sort(p => p.file.mtime, 'desc').slice(0, 40);
            todoTasks = recentPages.file.tasks.where(t => !t.completed).slice(0, 10);
        }
    } catch(e) {
        todoTasks = [];
    }

    if (pendingNotes.length === 0 && (!todoTasks || todoTasks.length === 0)) {
        tasksTrack.createDiv({
            text: "No pending tasks. Tag notes with #pending or #todo to track them here!",
            attr: { style: "font-size:0.82rem; color:var(--ocean-muted); padding:4px;" }
        });
        return;
    }

    // Render Tagged Notes (Primary)
    pendingNotes.forEach(({ page: p, tag }) => {
        const capsule = tasksTrack.createDiv({ cls: "ocean-target-capsule" });
        capsule.createDiv({ cls: "ocean-target-emoji", text: "📝" });

        const info = capsule.createDiv({ cls: "ocean-target-info" });
        info.createDiv({ cls: "ocean-target-title", text: p.file.name });

        const metaRow = info.createDiv({ cls: "ocean-target-meta" });
        metaRow.createSpan({ cls: "ocean-target-date", text: Utils.taskTime(p.file.mtime) });
        const tagType = tag.toLowerCase().replace("#", "");
        metaRow.createSpan({ cls: `ocean-task-tag-badge ${tagType === "pending" ? "pending" : "todo"}`, text: tag });

        const actions = capsule.createDiv({ cls: "ocean-target-actions" });
        const checkBtn = actions.createDiv({
            cls: "ocean-col-card-btn ocean-task-complete-btn",
            text: "✓",
            attr: { title: `Mark Done: Remove ${tag} tag from note` }
        });

        checkBtn.onclick = async (e) => {
            e.stopPropagation();
            try {
                const file = app.vault.getAbstractFileByPath(p.file.path);
                if (!file) return;
                const content = await app.vault.read(file);
                const tagBare = tag.replace("#", "");
                
                // Remove tag from inline or yaml
                const regexInline = new RegExp(`#${tagBare}\\b`, "gi");
                const regexYamlList = new RegExp(`^\\s*-\\s*#?${tagBare}\\s*$\\n?`, "gim");
                
                let newContent = content
                    .replace(regexYamlList, "")
                    .replace(regexInline, "");

                await app.vault.modify(file, newContent);
                new Notice(`🎉 Cleared ${tag} from ${p.file.name}!`);
                setTimeout(() => renderLiveTasks(), 250);
            } catch(err) {
                new Notice(`Error updating note: ${err.message}`);
            }
        };

        capsule.onclick = () => app.workspace.openLinkText(p.file.path, "", false);
    });

    // Render Checklist Tasks (Secondary)
    if (todoTasks && todoTasks.length > 0) {
        todoTasks.forEach(t => {
            const capsule = tasksTrack.createDiv({ cls: "ocean-target-capsule" });
            capsule.createDiv({ cls: "ocean-target-emoji", text: "☑️" });

            const info = capsule.createDiv({ cls: "ocean-target-info" });
            const cleanTitle = (t.text || "Task item")
                .replace(/#\S+/g, "")
                .replace(/\[\[([^\]|]+)(?:\|[^\]]+)?\]\]/g, "$1")
                .replace(/\*\*([^*]+)\*\*/g, "$1")
                .replace(/\*([^*]+)\*/g, "$1")
                .trim();
            info.createDiv({ cls: "ocean-target-title", text: cleanTitle });

            const metaRow = info.createDiv({ cls: "ocean-target-meta" });
            if (t.link) {
                let noteName = "";
                if (typeof t.link.fileName === "function") {
                    noteName = t.link.fileName();
                } else if (typeof t.link.fileName === "string") {
                    noteName = t.link.fileName;
                } else if (t.link.display) {
                    noteName = t.link.display;
                } else if (t.link.path) {
                    noteName = t.link.path.replace(/\.md$/i, "").split("/").pop();
                }
                const parentPage = dv.page(t.link.path);
                const timeStr = parentPage && parentPage.file.mtime ? Utils.taskTime(parentPage.file.mtime) : "";
                metaRow.createSpan({ cls: "ocean-target-date", text: (noteName || "Note") + (timeStr ? ` • ${timeStr}` : "") });
            }
            metaRow.createSpan({ cls: "ocean-task-tag-badge todo", text: "TODO" });

            const actions = capsule.createDiv({ cls: "ocean-target-actions" });
            const checkBtn = actions.createDiv({
                cls: "ocean-col-card-btn ocean-task-complete-btn",
                text: "✓",
                attr: { title: "Mark task completed" }
            });

            checkBtn.onclick = async (e) => {
                e.stopPropagation();
                try {
                    if (!t.link || !t.link.path) return;
                    const file = app.vault.getAbstractFileByPath(t.link.path);
                    if (!file) return;
                    const content = await app.vault.read(file);
                    const lines = content.split("\n");
                    let modified = false;

                    if (typeof t.line === "number" && lines[t.line] && lines[t.line].includes("- [ ]")) {
                        lines[t.line] = lines[t.line].replace("- [ ]", "- [x]");
                        modified = true;
                    } else {
                        const cleanText = t.text.trim();
                        for (let i = 0; i < lines.length; i++) {
                            if (lines[i].includes("- [ ]") && (lines[i].includes(cleanText) || cleanText.includes(lines[i].replace(/^.*-\s*\[\s*\]\s*/, "").trim()))) {
                                lines[i] = lines[i].replace("- [ ]", "- [x]");
                                modified = true;
                                break;
                            }
                        }
                    }

                    if (modified) {
                        await app.vault.modify(file, lines.join("\n"));
                        new Notice(`✅ Task completed!`);
                        setTimeout(() => renderLiveTasks(), 250);
                    }
                } catch(err) {
                    new Notice(`Error completing task: ${err.message}`);
                }
            };

            capsule.onclick = () => {
                if (t.link) app.workspace.openLinkText(t.link.path, "", false);
            };
        });
    }
}

if (showTasks && tasksTrack) {
    renderLiveTasks();
}

// ══════════════════════════════════════════════
// 2. MAIN 3-COLUMN BENTO GRID
// ══════════════════════════════════════════════
const showTopics = masterSettings.widgets.topics !== false;
const showJump = masterSettings.widgets.jump !== false;
const showRecent = masterSettings.widgets.recent !== false;
const showScratchpad = masterSettings.widgets.scratchpad !== false;
const showCollections = masterSettings.widgets.collections !== false;
const showActions = masterSettings.widgets.actions !== false;

const hasLeft = showTopics || showJump;
const hasCenter = showRecent || showScratchpad;
const hasRight = showCollections || showActions;

let renderRecentNotesFn = null;

if (hasLeft || hasCenter || hasRight) {
    const mainGrid = container.createDiv({ cls: "ocean-grid" });
    if (!isMobilePlatform) {
        mainGrid.style.setProperty("--ocean-custom-grid-height", `${masterSettings.gridHeight || 550}px`);

        // Dynamic 3-Column Template
        let colTemplates = [];
        if (hasLeft) colTemplates.push("1fr");
        if (hasCenter) colTemplates.push(hasLeft && hasRight ? "3fr" : (hasLeft || hasRight ? "2fr" : "1fr"));
        if (hasRight) colTemplates.push("1fr");
        mainGrid.style.setProperty("--ocean-custom-cols", colTemplates.join(" "));
    }

    // ── LEFT COLUMN ──────────────────────────────
    if (hasLeft) {
        const colLeft = mainGrid.createDiv({ cls: "ocean-col-left" });

        // 1. BROWSE BY TOPIC (Atlas Widget - Top)
        if (showTopics) {
            const tagCard = colLeft.createDiv({ cls: "ocean-card ocean-tag-card" });
            const tagHdr = tagCard.createDiv({ cls: "ocean-card-hdr" });
            tagHdr.createDiv({ cls: "ocean-card-title", text: "🏷️ BROWSE BY TOPIC" });

            const sortBtn = tagHdr.createDiv({
                cls: "ocean-tag-sort-btn",
                text: tagSortMode === "count" ? "🔢 Count" : "🔤 A-Z",
                attr: { title: "Click to toggle sort: Count vs A-Z (Right-click tags to Pin/Unpin)" }
            });

            sortBtn.onclick = () => {
                tagSortMode = tagSortMode === "count" ? "name" : "count";
                localStorage.setItem(LS.tagSort, tagSortMode);
                sortBtn.textContent = tagSortMode === "count" ? "🔢 Count" : "🔤 A-Z";
                renderTopicTags();
            };

            const tagWrap = tagCard.createDiv({ cls: "ocean-tag-wrap" });

            function renderTopicTags() {
                tagWrap.innerHTML = "";
                
                // All Notes pill
                const allPill = tagWrap.createDiv({ cls: "ocean-tag-pill" + (activeTag === "__all__" ? " active" : "") });
                allPill.createSpan({ text: "All Notes" });
                allPill.onclick = () => {
                    activeTag = "__all__";
                    localStorage.setItem(LS.tag, activeTag);
                    renderTopicTags();
                    if (renderRecentNotesFn) renderRecentNotesFn();
                };

                const tags = Utils.getProcessedTags(masterSettings.tagLimit || 35);
                tags.forEach(({ tag, count, pinned }) => {
                    const pill = tagWrap.createDiv({
                        cls: "ocean-tag-pill" + (activeTag === tag ? " active" : "") + (pinned ? " pinned" : ""),
                        attr: { title: `${pinned ? "Pinned tag" : "Tag"}: ${tag} (${count} notes). Right-click to toggle pin.` }
                    });

                    if (pinned) {
                        pill.createSpan({ cls: "ocean-pin-icon", text: "📌" });
                    }

                    pill.createSpan({ text: tag });
                    pill.createSpan({ cls: "ocean-tag-count", text: String(count) });

                    pill.onclick = () => {
                        activeTag = tag;
                        localStorage.setItem(LS.tag, activeTag);
                        renderTopicTags();
                        if (renderRecentNotesFn) renderRecentNotesFn();
                    };

                    // Right-click to toggle Pin / Unpin
                    pill.oncontextmenu = (e) => {
                        e.preventDefault();
                        if (pinnedTags.includes(tag)) {
                            pinnedTags = pinnedTags.filter(t => t !== tag);
                            new Notice(`📍 Unpinned ${tag}`);
                        } else {
                            pinnedTags.push(tag);
                            new Notice(`📌 Pinned ${tag}`);
                        }
                        localStorage.setItem(LS.pinnedTags, JSON.stringify(pinnedTags));
                        renderTopicTags();
                    };
                });
            }
            renderTopicTags();
        }

        // 2. JUMP BACK IN (Atlas Widget - Bottom)
        if (showJump) {
            const jumpCard = colLeft.createDiv({ cls: "ocean-card" });
            const jumpHdr = jumpCard.createDiv({ cls: "ocean-card-hdr" });
            jumpHdr.createDiv({ cls: "ocean-card-title", text: "↩️ JUMP BACK IN" });

            const jumpList = jumpCard.createDiv({ cls: "ocean-jump-list" });
            const recentFiles = Utils.getRecentlyOpened(3);

            if (recentFiles.length > 0) {
                recentFiles.forEach(path => {
                    const item = jumpList.createDiv({ cls: "ocean-jump-item" });
                    const ico = item.createDiv({ cls: "ocean-jump-icon" });
                    Utils.icon(ico, "corner-up-left", "↩");
                    item.createSpan({ text: path.split("/").pop().replace(".md", "") });
                    item.onclick = () => app.workspace.openLinkText(path, "", false);
                });
            } else {
                jumpList.createDiv({ text: "No recently opened notes", attr: { style: "font-size:0.8rem; color:var(--ocean-muted);" } });
            }
        }
    }

    // ── CENTER COLUMN ────────────────────────────
    if (hasCenter) {
        const colCenter = mainGrid.createDiv({ cls: "ocean-col-center" });
        if (!showRecent || !showScratchpad) {
            colCenter.style.gridTemplateColumns = "1fr";
        }

        // 1. RECENTLY EDITED NOTES
        if (showRecent) {
            const recentCard = colCenter.createDiv({ cls: "ocean-card ocean-recent-card" });
            const recentHdr = recentCard.createDiv({ cls: "ocean-card-hdr" });
            const recentTitleEl = recentHdr.createDiv({ cls: "ocean-card-title", text: "📄 RECENTLY EDITED" });

            let noteSearchQuery = "";
            const recentSearchInput = recentHdr.createEl("input", {
                cls: "ocean-search-input",
                attr: { type: "text", placeholder: "🔍 SEARCH", spellcheck: "false" }
            });

            recentSearchInput.oninput = () => {
                noteSearchQuery = recentSearchInput.value;
                renderRecentNotes();
            };

            const notesList = recentCard.createDiv({ cls: "ocean-notes-list" });

            function renderRecentNotes() {
                notesList.innerHTML = "";
                recentTitleEl.textContent = activeTag === "__all__" 
                    ? (noteSearchQuery ? `📄 SEARCH: "${noteSearchQuery}"` : "📄 RECENTLY EDITED") 
                    : (noteSearchQuery ? `📄 SEARCH IN ${activeTag.toUpperCase()}: "${noteSearchQuery}"` : `📄 NOTES IN ${activeTag.toUpperCase()}`);
                
                const notes = Utils.getNotes(masterSettings.recentLimit || 50, noteSearchQuery);
                if (notes.length === 0) {
                    notesList.createDiv({ text: "No matching notes found.", attr: { style: "padding:16px; font-size:0.85rem; color:var(--ocean-muted); text-align:center;" } });
                    return;
                }

                notes.forEach(({ page: p, isPinned }) => {
                    const row = notesList.createDiv({
                        cls: "ocean-note-row" + (isPinned ? " pinned" : ""),
                        attr: { title: `${isPinned ? "Pinned note" : "Note"}: ${p.file.name}. Right-click to toggle pin.` }
                    });

                    const info = row.createDiv({ cls: "ocean-note-info" });
                    const nameRow = info.createDiv({ cls: "ocean-note-name-row" });
                    
                    if (isPinned) {
                        nameRow.createSpan({ cls: "ocean-pin-icon", text: "📌" });
                    }
                    nameRow.createSpan({ cls: "ocean-note-name", text: p.file.name });
                    info.createDiv({ cls: "ocean-note-folder", text: p.file.folder || "Vault Root" });

                    row.createDiv({ cls: "ocean-note-time", text: Utils.relTime(p.file.mtime) });
                    row.onclick = () => app.workspace.openLinkText(p.file.path, "", false);

                    // Right-click to toggle Pin / Unpin
                    row.oncontextmenu = (e) => {
                        e.preventDefault();
                        if (pinnedNotes.includes(p.file.path)) {
                            pinnedNotes = pinnedNotes.filter(path => path !== p.file.path);
                            new Notice(`📍 Unpinned ${p.file.name}`);
                        } else {
                            pinnedNotes.push(p.file.path);
                            new Notice(`📌 Pinned ${p.file.name}`);
                        }
                        localStorage.setItem(LS.pinnedNotes, JSON.stringify(pinnedNotes));
                        renderRecentNotes();
                    };
                });
            }
            renderRecentNotesFn = renderRecentNotes;
            renderRecentNotes();
        }

        // 2. PERSISTENT SCRATCHPAD
        if (showScratchpad) {
            const scratchpadCard = colCenter.createDiv({ cls: "ocean-card ocean-scratchpad-card" });
            const scratchpadHdr = scratchpadCard.createDiv({ cls: "ocean-card-hdr" });
            scratchpadHdr.createDiv({ cls: "ocean-card-title", text: "📝 QUICK SCRATCHPAD" });

            const scratchActions = scratchpadHdr.createDiv({ cls: "ocean-scratchpad-hdr-actions" });
            const saveIndicator = scratchActions.createSpan({ cls: "ocean-scratchpad-stat", text: "● Saved" });
            const copyScratchBtn = scratchActions.createDiv({ cls: "ocean-scratch-btn", text: "📋 COPY", attr: { title: "Copy to Clipboard" } });
            const clearScratchBtn = scratchActions.createDiv({ cls: "ocean-scratch-btn", text: "🧹 CLEAR", attr: { title: "Clear Scratchpad" } });
            const toDailyBtn = scratchActions.createDiv({ cls: "ocean-scratch-btn", text: "📤 DAILY", attr: { title: "Append to Today's Daily Note" } });

            const scratchTextarea = scratchpadCard.createEl("textarea", {
                cls: "ocean-scratchpad-textarea",
                attr: {
                    placeholder: "Type quick thoughts, markdown snippets, or temporary tasks... (Auto-saves continuously)"
                }
            });

            let savedScratchText = localStorage.getItem(LS.scratchpad) || "";
            scratchTextarea.value = savedScratchText;

            let saveTimeout = null;
            scratchTextarea.oninput = () => {
                saveIndicator.textContent = "● Saving...";
                saveIndicator.style.color = "#fbbf24";
                clearTimeout(saveTimeout);
                saveTimeout = setTimeout(() => {
                    localStorage.setItem(LS.scratchpad, scratchTextarea.value);
                    saveIndicator.textContent = "● Saved";
                    saveIndicator.style.color = "var(--ocean-muted)";
                }, 300);
            };

            copyScratchBtn.onclick = () => {
                const text = scratchTextarea.value.trim();
                if (!text) {
                    new Notice("Scratchpad is empty");
                    return;
                }
                navigator.clipboard.writeText(text);
                new Notice("📋 Copied scratchpad to clipboard!");
            };

            clearScratchBtn.onclick = () => {
                if (!scratchTextarea.value.trim()) return;
                scratchTextarea.value = "";
                localStorage.setItem(LS.scratchpad, "");
                new Notice("🧹 Scratchpad cleared");
            };

            toDailyBtn.onclick = async () => {
                const text = scratchTextarea.value.trim();
                if (!text) {
                    new Notice("Scratchpad is empty");
                    return;
                }
                const today = new Date();
                const dateStr = `${today.getFullYear()}-${String(today.getMonth() + 1).padStart(2, "0")}-${String(today.getDate()).padStart(2, "0")}`;
                const dailyPath = `Daily/${dateStr}.md`;
                
                let file = app.vault.getAbstractFileByPath(dailyPath);
                if (!file) {
                    file = app.vault.getAbstractFileByPath(`${dateStr}.md`);
                }

                try {
                    if (file) {
                        const existing = await app.vault.read(file);
                        await app.vault.modify(file, `${existing}\n\n### Scratchpad Note (${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })})\n${text}\n`);
                        new Notice(`📤 Appended scratchpad to ${file.name}!`);
                    } else {
                        await app.vault.create(dailyPath, `# ${dateStr}\n\n### Scratchpad Note\n${text}\n`);
                        new Notice(`📤 Created ${dailyPath} and saved scratchpad!`);
                    }
                } catch(e) {
                    new Notice(`Notice: ${e.message}`);
                }
            };
        }
    }

    // ── RIGHT COLUMN ─────────────────────────────
    if (hasRight) {
        const colRight = mainGrid.createDiv({ cls: "ocean-col-right" });

        // 1. COLLECTION CARDS
        if (showCollections) {
            const colCardSection = colRight.createDiv({ cls: "ocean-card" });
            const colHdr = colCardSection.createDiv({ cls: "ocean-card-hdr" });
            colHdr.createDiv({ cls: "ocean-card-title", text: "🗂️ COLLECTION" });

            const addColBtn = colHdr.createDiv({ cls: "ocean-add-btn", text: "+ ADD CARD" });
            const collectionContainer = colCardSection.createDiv({ cls: "ocean-collection-container" });

            function renderCollectionCards() {
                collectionContainer.innerHTML = "";
                if (savedCards.length === 0) {
                    collectionContainer.createDiv({
                        text: "No collection cards yet. Click + ADD CARD to create your first shortcut!",
                        attr: { style: "font-size:0.82rem; color:var(--ocean-muted); padding:12px 6px; text-align:center; line-height:1.4;" }
                    });
                    return;
                }

                savedCards.forEach((c, idx) => {
                    const cardEl = collectionContainer.createDiv({ cls: "ocean-col-card" });
                    
                    cardEl.createDiv({ cls: "ocean-col-card-emoji", text: c.emoji || "📁" });

                    const info = cardEl.createDiv({ cls: "ocean-col-card-info" });
                    info.createDiv({ cls: "ocean-col-card-title", text: c.title });
                    if (c.subtitle) info.createDiv({ cls: "ocean-col-card-sub", text: c.subtitle });

                    const actions = cardEl.createDiv({ cls: "ocean-col-card-actions" });
                    const editBtn = actions.createDiv({ cls: "ocean-col-card-btn", text: "✎", attr: { title: "Edit Card" } });
                    const delBtn = actions.createDiv({ cls: "ocean-col-card-btn", text: "✕", attr: { title: "Delete Card" } });

                    editBtn.onclick = (e) => { e.stopPropagation(); showCardModal(c, idx); };
                    delBtn.onclick = (e) => {
                        e.stopPropagation();
                        savedCards.splice(idx, 1);
                        localStorage.setItem(LS.cards, JSON.stringify(savedCards));
                        renderCollectionCards();
                    };

                    cardEl.onclick = () => {
                        if (c.link) app.workspace.openLinkText(c.link, "", false);
                    };
                });
            }

            function showCardModal(cardToEdit = null, idx = null) {
                const overlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
                const modal = overlay.createDiv({ cls: "ocean-modal" });

                // Header with Title & Close '✕'
                const modalHdr = modal.createDiv({ cls: "ocean-settings-hdr" });
                modalHdr.createDiv({ cls: "ocean-modal-title", text: cardToEdit ? "✎ Edit Card" : "➕ Add Collection Card" });
                const closeBtn = modalHdr.createDiv({ cls: "ocean-settings-close", text: "✕", attr: { title: "Close (Esc)" } });

                const closeModal = () => {
                    document.removeEventListener("keydown", escHandler);
                    overlay.remove();
                };
                closeBtn.onclick = closeModal;

                const escHandler = (ev) => {
                    if (ev.key === "Escape") closeModal();
                };
                document.addEventListener("keydown", escHandler);

                modal.createDiv({ text: "Card Title:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
                const titleInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: cardToEdit ? cardToEdit.title : "", placeholder: "E.g.: Academic Hub" } });

                modal.createDiv({ text: "Subtitle / Tagline:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
                const subInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: cardToEdit ? (cardToEdit.subtitle || "") : "", placeholder: "E.g.: Notes & Syllabus" } });

                modal.createDiv({ text: "Emoji Icon:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
                const emojiInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: cardToEdit ? (cardToEdit.emoji || "📁") : "📁", placeholder: "📁" } });

                modal.createDiv({ text: "Target Note Link (Path):", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
                const linkInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: cardToEdit ? (cardToEdit.link || "") : "", placeholder: "E.g.: Academics/BCom/BCom" } });

                const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
                
                if (cardToEdit !== null && idx !== null) {
                    const delModalBtn = btnRow.createEl("button", {
                        cls: "ocean-btn",
                        text: "🗑️ Delete",
                        attr: { style: "margin-right:auto; color:var(--ocean-rose);" }
                    });
                    delModalBtn.onclick = () => {
                        savedCards.splice(idx, 1);
                        localStorage.setItem(LS.cards, JSON.stringify(savedCards));
                        renderCollectionCards();
                        new Notice(`🗑️ Deleted ${cardToEdit.title}`);
                        closeModal();
                    };
                }

                const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
                const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Save Card" });

                cancel.onclick = closeModal;
                save.onclick = () => {
                    const title = titleInp.value.trim();
                    if (!title) {
                        new Notice("⚠️ Card title is required");
                        return;
                    }
                    const newCard = {
                        title: title,
                        subtitle: subInp.value.trim(),
                        emoji: emojiInp.value.trim() || "📁",
                        link: linkInp.value.trim()
                    };

                    if (cardToEdit !== null && idx !== null) {
                        savedCards[idx] = newCard;
                    } else {
                        savedCards.push(newCard);
                    }
                    localStorage.setItem(LS.cards, JSON.stringify(savedCards));
                    renderCollectionCards();
                    closeModal();
                };
                Utils.bindModalBackdropClose(overlay, closeModal);
            }

            addColBtn.onclick = () => showCardModal();
            renderCollectionCards();
        }

        // 2. SYSTEM QUICK ACTIONS
        if (showActions) {
            const actionsSection = colRight.createDiv({ cls: "ocean-card ocean-actions-card" });
            const actHdr = actionsSection.createDiv({ cls: "ocean-card-hdr" });
            actHdr.createDiv({ cls: "ocean-card-title", text: "⚡ SYSTEM ACTIONS" });

            const actGrid = actionsSection.createDiv({ cls: "ocean-act-grid" });

            const SYS_ACTIONS = [
                { icon: "search",      lbl: "Omni-Search",cmd: "switcher:open",  em: "🔍" },
                { icon: "calendar",    lbl: "Daily",      cmd: "daily-notes",   em: "📅" },
                { icon: "share-2",     lbl: "Graph",      cmd: "graph:open",    em: "🕸️" },
                { icon: "file-plus",   lbl: "New Note",   cmd: "file-explorer:new-file", em: "📝" },
                { icon: "settings",    lbl: "Settings",   cmd: "app:open-settings", em: "⚙️" },
                { icon: "bookmark",    lbl: "Bookmarks",  cmd: "bookmarks:open", em: "🔖" }
            ];

            SYS_ACTIONS.forEach(act => {
                const btn = actGrid.createDiv({ cls: "ocean-act-btn" });
                const ico = btn.createDiv({ cls: "ocean-act-icon" });
                Utils.icon(ico, act.icon, act.em);
                btn.createDiv({ cls: "ocean-act-lbl", text: act.lbl });

                btn.onclick = () => {
                    if (act.lbl === "Daily") {
                        const today = new Date();
                        const dateStr = today.toISOString().split("T")[0];
                        const fileName = `daily/${dateStr}.md`;
                        const existingFile = app.vault.getAbstractFileByPath(fileName);
                        if (existingFile) {
                            app.workspace.openLinkText(fileName, "", false);
                        } else {
                            try { app.commands.executeCommandById("daily-notes"); }
                            catch(e) { app.workspace.openLinkText(dateStr, "", false); }
                        }
                        return;
                    }

                    try {
                        if (app.commands.commands[act.cmd]) {
                            app.commands.executeCommandById(act.cmd);
                        } else if (act.fallbackCmd && app.commands.commands[act.fallbackCmd]) {
                            app.commands.executeCommandById(act.fallbackCmd);
                        } else {
                            new Notice(`Command for ${act.lbl} triggered`);
                        }
                    } catch(e) {
                        new Notice(`Failed to execute ${act.lbl}`);
                    }
                };
            });
        }
    }
}

// ══════════════════════════════════════════════
// 3. BIO-METRICS (WEEKLY) (Zen Habits Tracker)
// ══════════════════════════════════════════════
if (masterSettings.widgets.habits !== false) {
    const habitsCard = container.createDiv({ cls: "ocean-card ocean-habits-card" });
    goalsCube.onclick = () => habitsCard.scrollIntoView({ behavior: "smooth" });
    const habHdr = habitsCard.createDiv({ cls: "ocean-card-hdr" });
    habHdr.createDiv({ cls: "ocean-card-title", text: "🧬 BIO-METRICS (WEEKLY TRACKING)" });

    const habHdrBtns = habHdr.createDiv({ attr: { style: "display:flex; gap:8px; align-items:center;" } });
    const resetWeekBtn = habHdrBtns.createDiv({ cls: "ocean-add-btn", text: "🧹 RESET WEEK", attr: { title: "Clear current week checkmarks" } });
    const addHabitBtn = habHdrBtns.createDiv({ cls: "ocean-add-btn", text: "+ ADD METRIC" });

    resetWeekBtn.onclick = () => {
        if (!confirm("Are you sure you want to clear all checkmarks for the current week?")) return;
        savedHabits.forEach(h => {
            for (let day = 1; day <= 7; day++) {
                localStorage.removeItem(`ocean-h-${h}-${day}`);
            }
        });
        renderHabitsTracker();
        updateConsistencyBar();
        if (typeof updateHeaderGoals === "function") updateHeaderGoals();
        new Notice("🧹 Current week's metric tracking cleared!");
    };

    const barWrap = habitsCard.createDiv({ cls: "ocean-consistency-bar-wrap" });
    const barFill = barWrap.createDiv({ cls: "ocean-consistency-bar-fill" });

    const habitGrid = habitsCard.createDiv({ cls: "ocean-habit-grid" });

    function updateConsistencyBar() {
        const stats = Utils.getHabitStats();
        barFill.style.width = `${stats.percent}%`;
        if (typeof updateHeaderGoals === "function") {
            updateHeaderGoals();
        }
    }

    function openEditHabitModal(h, idx) {
        const overlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
        const modal = overlay.createDiv({ cls: "ocean-modal" });

        // Header with Title & Close '✕'
        const modalHdr = modal.createDiv({ cls: "ocean-settings-hdr" });
        modalHdr.createDiv({ cls: "ocean-modal-title", text: `Edit Metric: ${h}` });
        const closeBtn = modalHdr.createDiv({ cls: "ocean-settings-close", text: "✕", attr: { title: "Close (Esc)" } });

        const closeModal = () => {
            document.removeEventListener("keydown", escHandler);
            overlay.remove();
        };
        closeBtn.onclick = closeModal;

        const escHandler = (ev) => {
            if (ev.key === "Escape") closeModal();
        };
        document.addEventListener("keydown", escHandler);

        const inp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: h } });
        const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
        const delBtn = btnRow.createEl("button", { cls: "ocean-btn", text: "🗑️ Delete", attr: { style: "margin-right:auto; color:var(--ocean-rose);" } });
        const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
        const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Save" });

        cancel.onclick = closeModal;
        delBtn.onclick = () => {
            savedHabits.splice(idx, 1);
            localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
            renderHabitsTracker();
            updateConsistencyBar();
            new Notice(`🗑️ Deleted ${h}`);
            closeModal();
        };
        save.onclick = () => {
            const updated = inp.value.trim();
            if (updated) {
                savedHabits[idx] = updated;
                localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
                renderHabitsTracker();
                updateConsistencyBar();
            }
            closeModal();
        };
        Utils.bindModalBackdropClose(overlay, closeModal);
    }

    function renderHabitsTracker() {
        habitGrid.innerHTML = "";
        if (savedHabits.length === 0) {
            habitGrid.createDiv({
                text: "No weekly metrics tracked yet. Click + ADD METRIC to start tracking!",
                attr: { style: "font-size:0.82rem; color:var(--ocean-muted); padding:16px 6px; grid-column: 1 / -1; text-align:center; line-height:1.4;" }
            });
            updateConsistencyBar();
            return;
        }

        const weekStart = masterSettings.weekStart || "monday";
        let DAYS = ["M", "T", "W", "T", "F", "S", "S"];
        let DAY_NAMES = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
        let todayDayIndex = 1;

        const nowDay = new Date().getDay(); // 0 = Sun, 1 = Mon, ..., 6 = Sat
        if (weekStart === "sunday") {
            DAYS = ["S", "M", "T", "W", "T", "F", "S"];
            DAY_NAMES = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
            todayDayIndex = nowDay + 1;
        } else if (weekStart === "saturday") {
            DAYS = ["S", "S", "M", "T", "W", "T", "F"];
            DAY_NAMES = ["Saturday", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
            todayDayIndex = ((nowDay + 1) % 7) + 1;
        } else {
            // Monday default
            todayDayIndex = ((nowDay + 6) % 7) + 1;
        }

        savedHabits.forEach((h, idx) => {
            const row = habitGrid.createDiv({ cls: "ocean-habit-row" });
            
            const leftWrap = row.createDiv({ cls: "ocean-habit-left" });
            leftWrap.createDiv({ cls: "ocean-habit-title", text: h });

            const actions = leftWrap.createDiv({ cls: "ocean-habit-actions" });
            const editBtn = actions.createDiv({ cls: "ocean-habit-act-btn", text: "✎", attr: { title: "Edit Metric" } });
            const delBtn = actions.createDiv({ cls: "ocean-habit-act-btn del", text: "✕", attr: { title: "Delete Metric" } });

            editBtn.onclick = (e) => { e.stopPropagation(); openEditHabitModal(h, idx); };
            delBtn.onclick = (e) => {
                e.stopPropagation();
                savedHabits.splice(idx, 1);
                localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
                renderHabitsTracker();
                updateConsistencyBar();
                new Notice(`🗑️ Deleted ${h}`);
            };

            // Right click to edit or delete
            row.oncontextmenu = (e) => {
                e.preventDefault();
                openEditHabitModal(h, idx);
            };

            const dotGrid = row.createDiv({ cls: "ocean-dot-grid" });
            for (let day = 1; day <= 7; day++) {
                const key = `ocean-h-${h}-${day}`;
                const isToday = day === todayDayIndex;
                const isActive = !!localStorage.getItem(key);

                const dot = dotGrid.createDiv({
                    cls: "ocean-dot" + (isActive ? " active" : "") + (isToday ? " today" : ""),
                    text: DAYS[day - 1],
                    attr: { title: `${isToday ? "Today • " : ""}${DAY_NAMES[day - 1]}` }
                });

                dot.onclick = () => {
                    dot.classList.toggle("active");
                    if (localStorage.getItem(key)) {
                        localStorage.removeItem(key);
                    } else {
                        localStorage.setItem(key, "1");
                    }
                    updateConsistencyBar();
                };
            }
        });
        updateConsistencyBar();
    }

    addHabitBtn.onclick = () => {
        const overlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
        const modal = overlay.createDiv({ cls: "ocean-modal" });

        // Header with Title & Close '✕'
        const modalHdr = modal.createDiv({ cls: "ocean-settings-hdr" });
        modalHdr.createDiv({ cls: "ocean-modal-title", text: "➕ Add New Weekly Metric" });
        const closeBtn = modalHdr.createDiv({ cls: "ocean-settings-close", text: "✕", attr: { title: "Close (Esc)" } });

        const closeModal = () => {
            document.removeEventListener("keydown", escHandler);
            overlay.remove();
        };
        closeBtn.onclick = closeModal;

        const escHandler = (ev) => {
            if (ev.key === "Escape") closeModal();
        };
        document.addEventListener("keydown", escHandler);

        const inp = modal.createEl("input", { cls: "ocean-modal-input", attr: { placeholder: "E.g.: 45 min German Reading" } });
        const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
        const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
        const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Add Metric" });

        cancel.onclick = closeModal;
        save.onclick = () => {
            const val = inp.value.trim();
            if (val) {
                savedHabits.push(val);
                localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
                renderHabitsTracker();
                updateConsistencyBar();
            }
            closeModal();
        };
        Utils.bindModalBackdropClose(overlay, closeModal);
    };

    renderHabitsTracker();
}
```
