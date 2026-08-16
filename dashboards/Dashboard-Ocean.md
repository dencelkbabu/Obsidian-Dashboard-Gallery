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
    title: "ocean-title",
    subtitle: "ocean-subtitle",
    tag: "ocean-active-tag",
    tagSort: "ocean-tag-sort",
    pinnedTags: "ocean-pinned-tags",
    pinnedNotes: "ocean-pinned-notes",
    habits: "ocean-habits",
    cards: "ocean-cards",
    targets: "ocean-targets"
};

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
    { title: "Heavy License Exam (CE)", date: "2026-09-30", emoji: "🚛", link: "Future" },
    { title: "German A2 Certification", date: "2027-06-30", emoji: "🇩🇪", link: "Future" },
    { title: "University Application", date: "2030-05-15", emoji: "🎓", link: "Future" }
];
localStorage.setItem(LS.targets, JSON.stringify(savedTargets));

const container = dv.container.createDiv({ cls: "ocean-dashboard animate-in" });

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
        const m = Math.floor((Date.now() - d.toMillis()) / 60000);
        if (m < 1) return "just now";
        if (m < 60) return `${m}m ago`;
        const h = Math.floor(m / 60);
        if (h < 24) return `${h}h ago`;
        const day = Math.floor(h / 24);
        if (day < 7) return `${day}d ago`;
        return d.toFormat("dd LLL");
    },
    taskTime: (d) => {
        if (!d) return "";
        const m = Math.floor((Date.now() - d.toMillis()) / 60000);
        const day = Math.floor(m / 1440);
        const year = d.year || new Date(d.toMillis()).getFullYear();
        
        let rel = "";
        if (m < 1) rel = "just now";
        else if (m < 60) rel = `${m}m ago`;
        else if (m < 1440) rel = `${Math.floor(m / 60)}h ago`;
        else if (day === 1) rel = "1d ago";
        else rel = `${day}d ago`;

        return `${rel} • ${year}`;
    },
    getProcessedTags: (limit = 24) => {
        const counts = {};
        for (const p of dv.pages()) {
            if (!p.file.tags) continue;
            for (const t of p.file.tags) counts[t] = (counts[t] || 0) + 1;
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
        let pages = dv.pages();
        if (activeTag !== "__all__") {
            pages = pages.where(p => p.file.tags && p.file.tags.includes(activeTag));
        }

        if (query && query.trim()) {
            const q = query.trim().toLowerCase();
            pages = pages.where(p => 
                p.file.name.toLowerCase().includes(q) || 
                (p.file.folder && p.file.folder.toLowerCase().includes(q)) ||
                (p.file.tags && p.file.tags.some(t => t.toLowerCase().includes(q)))
            );
        }

        const allPages = pages.array().map(p => ({
            page: p,
            isPinned: pinnedNotes.includes(p.file.path)
        }));

        const pinned = allPages.filter(p => p.isPinned).sort((a, b) => b.page.file.mtime - a.page.file.mtime);
        const unpinned = allPages.filter(p => !p.isPinned).sort((a, b) => b.page.file.mtime - a.page.file.mtime);

        return [...pinned, ...unpinned].slice(0, limit);
    },
    getRecentlyOpened: (limit = 5) => {
        try {
            return (app.workspace.getLastOpenFiles() || [])
                .filter(p => p.endsWith(".md") && !p.includes("Dashboard"))
                .slice(0, limit);
        } catch (e) { return []; }
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
    icon: (parent, name, fallback = "•") => {
        const el = parent.createDiv();
        try { setIcon(el, name); } catch (e) { el.textContent = fallback; }
        return el;
    }
};

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

// Daily Bible Verse (Dynamic Fetching with RSV Translation)
const todayDateStr = new Date().toISOString().slice(0, 10);
const cachedVerseRaw = localStorage.getItem("ocean-daily-verse");
let currentVerse = null;

if (cachedVerseRaw) {
    try {
        const parsed = JSON.parse(cachedVerseRaw);
        if (parsed && parsed.date === todayDateStr && parsed.text && parsed.ref) {
            currentVerse = parsed;
        }
    } catch (e) {}
}

const verseWrap = clockCont.createDiv({
    cls: "ocean-bible-verse-wrap",
    attr: { title: "Daily Verse • Click to copy • Right-click to refresh" }
});
const verseQuoteEl = verseWrap.createSpan({ cls: "ocean-bible-quote", text: currentVerse ? `“${currentVerse.text}”` : "Loading daily scripture..." });
const verseRefEl = verseWrap.createSpan({ cls: "ocean-bible-ref", text: currentVerse ? `— ${currentVerse.ref}` : "" });

async function loadVerse(forceRefresh = false) {
    if (!forceRefresh && currentVerse) return;

    try {
        // Fetch dynamic verse from Bible API (RSV translation)
        const res = await requestUrl({ url: "https://bible-api.com/?random=verse&translation=rsv" });
        if (res && res.json && res.json.text && res.json.reference) {
            const cleanText = res.json.text.trim().replace(/\s+/g, " ");
            const refStr = res.json.reference;
            currentVerse = { date: todayDateStr, text: cleanText, ref: refStr };
            localStorage.setItem("ocean-daily-verse", JSON.stringify(currentVerse));
            
            verseQuoteEl.textContent = `“${cleanText}”`;
            verseRefEl.textContent = `— ${refStr}`;
            return;
        }
    } catch (err) {
        // Graceful offline fallback
    }

    if (!currentVerse) {
        currentVerse = {
            date: todayDateStr,
            text: "Trust in the Lord with all your heart, and do not rely on your own insight.",
            ref: "Proverbs 3:5"
        };
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
        new Notice("✨ Loaded new daily verse");
    });
};

// Header Stats Cubes
const statsCont = header.createDiv({ cls: "ocean-hero-stats" });
const allTasks = dv.pages().file.tasks;
const completedTasksCount = allTasks ? allTasks.where(t => t.completed).length : 0;

[
    { v: dv.pages().length, l: "Notes" },
    { v: completedTasksCount, l: "Achievements" }
].forEach(st => {
    const cube = statsCont.createDiv({ cls: "ocean-stat-cube" });
    const topRow = cube.createDiv({ cls: "ocean-stat-top-row" });
    topRow.createDiv({ cls: "ocean-stat-star", text: "⭐" });
    topRow.createDiv({ cls: "ocean-stat-val", text: String(st.v) });
    cube.createDiv({ cls: "ocean-stat-lab", text: st.l });
});

setBtn.onclick = () => {
    const overlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
    const modal = overlay.createDiv({ cls: "ocean-modal" });
    modal.createDiv({ cls: "ocean-modal-title", text: "⚙️ Edit Dashboard Header" });

    modal.createDiv({ text: "Dashboard Title:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const titleInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: bannerTitle } });

    modal.createDiv({ text: "Subtitle / Motto:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const subInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: bannerSubtitle } });

    const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
    const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Save" });

    cancel.onclick = () => overlay.remove();
    save.onclick = () => {
        bannerTitle = titleInp.value.trim() || "DASHBOARD OCEAN";
        bannerSubtitle = subInp.value.trim();
        localStorage.setItem(LS.title, bannerTitle);
        localStorage.setItem(LS.subtitle, bannerSubtitle);
        heroTitleEl.innerText = bannerTitle;
        heroSubEl.innerText = bannerSubtitle || `${Utils.getGreeting()} — Systems active & ready.`;
        overlay.remove();
    };
    overlay.onclick = (e) => { if (e.target === overlay) overlay.remove(); };
};

// ══════════════════════════════════════════════
// ══════════════════════════════════════════════
// 1.5 DUAL RUNWAY: TARGETS (LEFT) & TASKS (RIGHT)
// ══════════════════════════════════════════════
const runwayGrid = container.createDiv({ cls: "ocean-runway-grid" });

// ── LEFT RUNWAY: TARGETS & COUNTDOWNS ────────
const targetsCard = runwayGrid.createDiv({ cls: "ocean-card ocean-runway-card" });
const targetsHdr = targetsCard.createDiv({ cls: "ocean-runway-hdr" });
targetsHdr.createDiv({ cls: "ocean-card-title", text: "🎯 TARGETS & COUNTDOWNS" });

const addTargetBtn = targetsHdr.createDiv({ cls: "ocean-add-btn", text: "+ ADD TARGET" });
const runwayTrack = targetsCard.createDiv({ cls: "ocean-targets-track" });

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
    modal.createDiv({ cls: "ocean-modal-title", text: targetToEdit ? "✎ Edit Target Milestone" : "🎯 Add Target Milestone" });

    modal.createDiv({ text: "Milestone / Target Title:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const titleInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: targetToEdit ? targetToEdit.title : "", placeholder: "E.g.: Heavy Commercial License Exam" } });

    modal.createDiv({ text: "Target Date:", attr: { style: "font-size:0.75rem; font-weight:700; color:var(--ocean-muted); margin-bottom:4px;" } });
    const dateInp = modal.createEl("input", { cls: "ocean-modal-input", attr: { type: "date", value: targetToEdit ? (targetToEdit.date || "") : "" } });

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
            renderTargets();
            new Notice(`🗑️ Deleted target ${targetToEdit.title}`);
            overlay.remove();
        };
    }

    const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Save Target" });

    cancel.onclick = () => overlay.remove();
    save.onclick = () => {
        const title = titleInp.value.trim();
        if (!title) return;
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
        renderTargets();
        overlay.remove();
    };
    overlay.onclick = (e) => { if (e.target === overlay) overlay.remove(); };
}

addTargetBtn.onclick = () => showTargetModal();
renderTargets();

// ── RIGHT RUNWAY: LIVE TASKS & PENDING FEED ──
const tasksCard = runwayGrid.createDiv({ cls: "ocean-card ocean-runway-card" });
const tasksHdr = tasksCard.createDiv({ cls: "ocean-runway-hdr" });
tasksHdr.createDiv({ cls: "ocean-card-title", text: "⚡ LIVE TASKS / PENDING" });

const tasksTrack = tasksCard.createDiv({ cls: "ocean-targets-track" });

function renderLiveTasks() {
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

    // 2. Query checklist tasks
    let todoTasks = [];
    try {
        todoTasks = dv.pages().file.tasks.where(t => !t.completed).slice(0, 10);
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
        const capsule = tasksTrack.createDiv({ cls: "ocean-task-capsule" });
        capsule.createDiv({ cls: "ocean-target-emoji", text: "📝" });

        const info = capsule.createDiv({ cls: "ocean-target-info" });
        info.createDiv({ cls: "ocean-target-title", text: p.file.name });

        const metaRow = info.createDiv({ cls: "ocean-target-meta" });
        metaRow.createSpan({ cls: "ocean-target-date", text: Utils.taskTime(p.file.mtime) });
        const tagType = tag.toLowerCase().replace("#", "");
        metaRow.createSpan({ cls: `ocean-task-tag-badge ${tagType === "pending" ? "pending" : "todo"}`, text: tag });

        capsule.onclick = () => app.workspace.openLinkText(p.file.path, "", false);
    });

    // Render Checklist Tasks (Secondary)
    if (todoTasks && todoTasks.length > 0) {
        todoTasks.forEach(t => {
            const capsule = tasksTrack.createDiv({ cls: "ocean-task-capsule" });
            capsule.createDiv({ cls: "ocean-target-emoji", text: "☑️" });

            const info = capsule.createDiv({ cls: "ocean-target-info" });
            info.createDiv({ cls: "ocean-target-title", text: t.text.replace(/#\S+/g, "").trim() || "Task item" });

            const metaRow = info.createDiv({ cls: "ocean-target-meta" });
            if (t.link) {
                const parentPage = dv.page(t.link.path);
                const timeStr = parentPage && parentPage.file.mtime ? Utils.taskTime(parentPage.file.mtime) : "";
                metaRow.createSpan({ cls: "ocean-target-date", text: (t.link.fileName || "") + (timeStr ? ` • ${timeStr}` : "") });
            }
            metaRow.createSpan({ cls: "ocean-task-tag-badge todo", text: "TODO" });

            capsule.onclick = () => {
                if (t.link) app.workspace.openLinkText(t.link.path, "", false);
            };
        });
    }
}
renderLiveTasks();

// ══════════════════════════════════════════════
// 2. MAIN 3-COLUMN BENTO GRID
// ══════════════════════════════════════════════
const mainGrid = container.createDiv({ cls: "ocean-grid" });
const colLeft = mainGrid.createDiv({ cls: "ocean-col-left" });
const colCenter = mainGrid.createDiv({ cls: "ocean-col-center" });
const colRight = mainGrid.createDiv({ cls: "ocean-col-right" });

// ── LEFT COLUMN ──────────────────────────────
// 1. JUMP BACK IN (Atlas Widget)
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

// 2. BROWSE BY TOPIC (Atlas Widget)
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
        renderRecentNotes();
    };

    const tags = Utils.getProcessedTags(35);
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
            renderRecentNotes();
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

// ── CENTER COLUMN: RECENTLY EDITED NOTES (MAX SPACE) ─────────
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
    
    const notes = Utils.getNotes(50, noteSearchQuery);
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
renderRecentNotes();

// ── RIGHT COLUMN: 1. COLLECTION CARDS (FIRST) ────────────────
const colCardSection = colRight.createDiv({ cls: "ocean-card" });
const colHdr = colCardSection.createDiv({ cls: "ocean-card-hdr" });
colHdr.createDiv({ cls: "ocean-card-title", text: "🗂️ COLLECTION" });

const addColBtn = colHdr.createDiv({ cls: "ocean-add-btn", text: "+ ADD CARD" });
const collectionContainer = colCardSection.createDiv({ cls: "ocean-collection-container" });

function renderCollectionCards() {
    collectionContainer.innerHTML = "";
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
    modal.createDiv({ cls: "ocean-modal-title", text: cardToEdit ? "✎ Edit Card" : "➕ Add Collection Card" });

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
            overlay.remove();
        };
    }

    const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Save Card" });

    cancel.onclick = () => overlay.remove();
    save.onclick = () => {
        const title = titleInp.value.trim();
        if (!title) return;
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
        overlay.remove();
    };
    overlay.onclick = (e) => { if (e.target === overlay) overlay.remove(); };
}

addColBtn.onclick = () => showCardModal();
renderCollectionCards();

// ── RIGHT COLUMN: 2. SYSTEM QUICK ACTIONS (AFTER COLLECTION) ─
const sysCard = colRight.createDiv({ cls: "ocean-card" });
const sysHdr = sysCard.createDiv({ cls: "ocean-card-hdr" });
sysHdr.createDiv({ cls: "ocean-card-title", text: "⚡ SYSTEM QUICK ACTIONS" });

const actGrid = sysCard.createDiv({ cls: "ocean-act-grid" });
const SYS_ACTIONS = [
    { icon: "search",      lbl: "Omnisearch", cmd: "omnisearch:show-modal", fallbackCmd: "global-search:open", em: "🔍" },
    { icon: "calendar",    lbl: "Daily",      cmd: "daily-notes", em: "📅" },
    { icon: "share-2",     lbl: "Graph",      cmd: "graph:open", em: "🕸️" },
    { icon: "file-plus",   lbl: "New Note",   cmd: "file-explorer:new-file", em: "➕" },
    { icon: "terminal",    lbl: "Commands",   cmd: "command-palette:open", em: "⌘" },
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

// ══════════════════════════════════════════════
// 3. BIO-METRICS (WEEKLY) (Zen Habits Tracker)
// ══════════════════════════════════════════════
const habitsCard = container.createDiv({ cls: "ocean-card ocean-habits-card" });
const habHdr = habitsCard.createDiv({ cls: "ocean-card-hdr" });
habHdr.createDiv({ cls: "ocean-card-title", text: "🧬 BIO-METRICS (WEEKLY CONSISTENCY)" });

const addHabitBtn = habHdr.createDiv({ cls: "ocean-add-btn", text: "+ ADD HABIT" });

const barWrap = habitsCard.createDiv({ cls: "ocean-consistency-bar-wrap" });
const barFill = barWrap.createDiv({ cls: "ocean-consistency-bar-fill" });

const habitGrid = habitsCard.createDiv({ cls: "ocean-habit-grid" });

function updateConsistencyBar() {
    const stats = Utils.getHabitStats();
    barFill.style.width = `${stats.percent}%`;
}

function openEditHabitModal(h, idx) {
    const overlay = document.body.createDiv({ cls: "ocean-modal-overlay" });
    const modal = overlay.createDiv({ cls: "ocean-modal" });
    modal.createDiv({ cls: "ocean-modal-title", text: `Edit Habit: ${h}` });

    const inp = modal.createEl("input", { cls: "ocean-modal-input", attr: { value: h } });
    const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
    const delBtn = btnRow.createEl("button", { cls: "ocean-btn", text: "🗑️ Delete", attr: { style: "margin-right:auto; color:var(--ocean-rose);" } });
    const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Save" });

    cancel.onclick = () => overlay.remove();
    delBtn.onclick = () => {
        savedHabits.splice(idx, 1);
        localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
        renderHabitsTracker();
        updateConsistencyBar();
        new Notice(`🗑️ Deleted ${h}`);
        overlay.remove();
    };
    save.onclick = () => {
        const updated = inp.value.trim();
        if (updated) {
            savedHabits[idx] = updated;
            localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
            renderHabitsTracker();
            updateConsistencyBar();
        }
        overlay.remove();
    };
    overlay.onclick = (ev) => { if (ev.target === overlay) overlay.remove(); };
}

function renderHabitsTracker() {
    habitGrid.innerHTML = "";
    savedHabits.forEach((h, idx) => {
        const row = habitGrid.createDiv({ cls: "ocean-habit-row" });
        
        const leftWrap = row.createDiv({ cls: "ocean-habit-left" });
        leftWrap.createDiv({ cls: "ocean-habit-title", text: h });

        const actions = leftWrap.createDiv({ cls: "ocean-habit-actions" });
        const editBtn = actions.createDiv({ cls: "ocean-habit-act-btn", text: "✎", attr: { title: "Edit Habit" } });
        const delBtn = actions.createDiv({ cls: "ocean-habit-act-btn del", text: "✕", attr: { title: "Delete Habit" } });

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

        const DAYS = ["M", "T", "W", "T", "F", "S", "S"];
        const todayDayIndex = ((new Date().getDay() + 6) % 7) + 1; // 1 = Monday, 7 = Sunday

        const dotGrid = row.createDiv({ cls: "ocean-dot-grid" });
        for (let day = 1; day <= 7; day++) {
            const key = `ocean-h-${h}-${day}`;
            const isToday = day === todayDayIndex;
            const isActive = !!localStorage.getItem(key);

            const dot = dotGrid.createDiv({
                cls: "ocean-dot" + (isActive ? " active" : "") + (isToday ? " today" : ""),
                text: DAYS[day - 1],
                attr: { title: `${isToday ? "Today • " : ""}${['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'][day - 1]}` }
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
    modal.createDiv({ cls: "ocean-modal-title", text: "➕ Add New Weekly Metric" });

    const inp = modal.createEl("input", { cls: "ocean-modal-input", attr: { placeholder: "E.g.: 45 min German Reading" } });
    const btnRow = modal.createDiv({ cls: "ocean-modal-btns" });
    const cancel = btnRow.createEl("button", { cls: "ocean-btn", text: "Cancel" });
    const save = btnRow.createEl("button", { cls: "ocean-btn primary", text: "Add Metric" });

    cancel.onclick = () => overlay.remove();
    save.onclick = () => {
        const val = inp.value.trim();
        if (val) {
            savedHabits.push(val);
            localStorage.setItem(LS.habits, JSON.stringify(savedHabits));
            renderHabitsTracker();
            updateConsistencyBar();
        }
        overlay.remove();
    };
    overlay.onclick = (e) => { if (e.target === overlay) overlay.remove(); };
};

renderHabitsTracker();
```
