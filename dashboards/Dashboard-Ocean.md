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
    habits: "ocean-habits",
    cards: "ocean-cards"
};

let bannerTitle = localStorage.getItem(LS.title) || "DASHBOARD OCEAN";
let bannerSubtitle = localStorage.getItem(LS.subtitle) || "";
let activeTag = localStorage.getItem(LS.tag) || "__all__";

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
    getTopTags: (limit = 14) => {
        const counts = {};
        for (const p of dv.pages()) {
            if (!p.file.tags) continue;
            for (const t of p.file.tags) counts[t] = (counts[t] || 0) + 1;
        }
        return Object.entries(counts)
            .sort((a, b) => b[1] - a[1])
            .slice(0, limit)
            .map(([tag, count]) => ({ tag, count }));
    },
    getNotes: (limit = 8) => {
        let pages = dv.pages();
        if (activeTag !== "__all__") {
            pages = pages.where(p => p.file.tags && p.file.tags.includes(activeTag));
        }
        return pages.sort(p => p.file.mtime, "desc").slice(0, limit);
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
// 1. HERO HEADER (Zen Inspired, No Drop Shadow)
// ══════════════════════════════════════════════
const header = container.createDiv({ cls: "ocean-header" });
const heroText = header.createDiv({ cls: "ocean-hero-text" });
const heroTitleEl = heroText.createEl("h1", { text: bannerTitle });
const heroSubEl = heroText.createDiv({
    cls: "ocean-hero-sub",
    text: bannerSubtitle || `${Utils.getGreeting()} — Systems active & ready.`
});

const headerRight = header.createDiv({ cls: "ocean-header-right" });

// Header Quick Stats
const statsCont = headerRight.createDiv({ cls: "ocean-hero-stats" });
const allTasks = dv.pages().file.tasks;
const openTasksCount = allTasks ? allTasks.where(t => !t.completed).length : 0;

[
    { v: dv.pages().length, l: "Notes" },
    { v: openTasksCount, l: "Tasks" }
].forEach(st => {
    const box = statsCont.createDiv({ cls: "ocean-stat-box" });
    box.createDiv({ cls: "ocean-stat-val", text: String(st.v) });
    box.createDiv({ cls: "ocean-stat-label", text: st.l });
});

// Settings Button
const setBtn = headerRight.createDiv({ cls: "ocean-settings-btn", attr: { title: "Edit Header" } });
Utils.icon(setBtn, "settings", "⚙️");

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
// 2. MAIN 2-COLUMN GRID
// ══════════════════════════════════════════════
const mainGrid = container.createDiv({ cls: "ocean-grid" });
const colLeft = mainGrid.createDiv({ cls: "ocean-col-left" });
const colCenter = mainGrid.createDiv({ cls: "ocean-col-center" });

// ── LEFT: SYSTEM ACTIONS (Komorebi + Omnisearch) ─────────────
const sysCard = colLeft.createDiv({ cls: "ocean-card" });
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

// ── LEFT: JUMP BACK IN (Atlas Widget) ────────────────────────
const jumpCard = colLeft.createDiv({ cls: "ocean-card" });
const jumpHdr = jumpCard.createDiv({ cls: "ocean-card-hdr" });
jumpHdr.createDiv({ cls: "ocean-card-title", text: "↩️ JUMP BACK IN" });

const jumpList = jumpCard.createDiv({ cls: "ocean-jump-list" });
const recentFiles = Utils.getRecentlyOpened();

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

// ── LEFT: BROWSE BY TOPIC (Atlas Widget) ─────────────────────
const tagCard = colLeft.createDiv({ cls: "ocean-card" });
const tagHdr = tagCard.createDiv({ cls: "ocean-card-hdr" });
tagHdr.createDiv({ cls: "ocean-card-title", text: "🏷️ BROWSE BY TOPIC" });

const tagWrap = tagCard.createDiv({ cls: "ocean-tag-wrap" });
const topTags = Utils.getTopTags();

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

    topTags.forEach(({ tag, count }) => {
        const pill = tagWrap.createDiv({ cls: "ocean-tag-pill" + (activeTag === tag ? " active" : "") });
        pill.createSpan({ text: tag });
        pill.createSpan({ cls: "ocean-tag-count", text: String(count) });
        pill.onclick = () => {
            activeTag = tag;
            localStorage.setItem(LS.tag, activeTag);
            renderTopicTags();
            renderRecentNotes();
        };
    });
}
renderTopicTags();

// ── CENTER: COLLECTION CARDS (Komorebi Widget) ───────────────
const colCardSection = colCenter.createDiv({ cls: "ocean-card" });
const colHdr = colCardSection.createDiv({ cls: "ocean-card-hdr" });
colHdr.createDiv({ cls: "ocean-card-title", text: "🗂️ COLLECTION" });

const addColBtn = colHdr.createDiv({ cls: "ocean-add-btn", text: "+ ADD CARD" });
const collectionContainer = colCardSection.createDiv({ cls: "ocean-collection-container" });

function renderCollectionCards() {
    collectionContainer.innerHTML = "";
    savedCards.forEach((c, idx) => {
        const cardEl = collectionContainer.createDiv({ cls: "ocean-col-card" });
        
        const topRow = cardEl.createDiv({ cls: "ocean-col-card-top" });
        topRow.createDiv({ cls: "ocean-col-card-emoji", text: c.emoji || "📁" });

        const actions = topRow.createDiv({ cls: "ocean-col-card-actions" });
        const editBtn = actions.createDiv({ cls: "ocean-col-card-btn", text: "✎", attr: { title: "Edit Card" } });
        const delBtn = actions.createDiv({ cls: "ocean-col-card-btn", text: "✕", attr: { title: "Delete Card" } });

        editBtn.onclick = (e) => { e.stopPropagation(); showCardModal(c, idx); };
        delBtn.onclick = (e) => {
            e.stopPropagation();
            savedCards.splice(idx, 1);
            localStorage.setItem(LS.cards, JSON.stringify(savedCards));
            renderCollectionCards();
        };

        const bottomInfo = cardEl.createDiv();
        bottomInfo.createDiv({ cls: "ocean-col-card-title", text: c.title });
        if (c.subtitle) bottomInfo.createDiv({ cls: "ocean-col-card-sub", text: c.subtitle });

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

// ── CENTER: RECENTLY EDITED NOTES (Atlas Widget) ─────────────
const recentCard = colCenter.createDiv({ cls: "ocean-card" });
const recentHdr = recentCard.createDiv({ cls: "ocean-card-hdr" });
const recentTitleEl = recentHdr.createDiv({ cls: "ocean-card-title", text: "📄 RECENTLY EDITED" });

const notesList = recentCard.createDiv({ cls: "ocean-notes-list" });

function renderRecentNotes() {
    notesList.innerHTML = "";
    recentTitleEl.textContent = activeTag === "__all__" ? "📄 RECENTLY EDITED" : `📄 NOTES IN ${activeTag.toUpperCase()}`;
    
    const notes = Utils.getNotes(7);
    if (notes.length === 0) {
        notesList.createDiv({ text: "No matching notes found.", attr: { style: "padding:16px; font-size:0.85rem; color:var(--ocean-muted); text-align:center;" } });
        return;
    }

    notes.forEach(p => {
        const row = notesList.createDiv({ cls: "ocean-note-row" });
        const info = row.createDiv({ cls: "ocean-note-info" });
        info.createDiv({ cls: "ocean-note-name", text: p.file.name });
        info.createDiv({ cls: "ocean-note-folder", text: p.file.folder || "Vault Root" });

        row.createDiv({ cls: "ocean-note-time", text: Utils.relTime(p.file.mtime) });
        row.onclick = () => app.workspace.openLinkText(p.file.path, "", false);
    });
}
renderRecentNotes();

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

function renderHabitsTracker() {
    habitGrid.innerHTML = "";
    savedHabits.forEach((h, idx) => {
        const row = habitGrid.createDiv({ cls: "ocean-habit-row" });
        row.createDiv({ cls: "ocean-habit-title", text: h });

        // Right click to edit or delete
        row.oncontextmenu = (e) => {
            e.preventDefault();
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
        };

        const dotGrid = row.createDiv({ cls: "ocean-dot-grid" });
        for (let day = 1; day <= 7; day++) {
            const key = `ocean-h-${h}-${day}`;
            const dot = dotGrid.createDiv({ cls: "ocean-dot" + (localStorage.getItem(key) ? " active" : "") });
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
