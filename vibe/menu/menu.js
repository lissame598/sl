// ---- 1. Where the JSON lives ----
// Which menu file to load is chosen by a ?menu= query param, e.g.:
//   menu.html            -> loads the default menu
//   menu.html?menu=food  -> loads menu-food.json
//   menu.html?menu=bar   -> loads menu-bar.json
//
// MENUS maps the short URL key to an actual filename. Using a whitelist
// like this (rather than building the filename directly from the URL)
// keeps things predictable and stops someone from passing in an
// arbitrary path via the query string.
const MENUS = {
    default: "menu-lovense.json",
    lovense: "menu-lovense.json",
    male: "menu-male.json",
    female: "menu-female.json",
    // add more entries here as you create more menu-*.json files
};

const params = new URLSearchParams(window.location.search);
const requestedKey = params.get("menu") || "default";
const MENU_JSON_PATH = MENUS[requestedKey] || MENUS.default;

// ---- 2. Parse the flat array into a page title + a list of sections ----
// A section starts at "subtitle" and can contain multiple minititle
// groups, each with its own items (e.g. "Cocktails" -> "Classics" [items],
// then "Cocktails" -> "House Specials" [items]). "comment" attaches to
// the section as a whole.
function parseMenu(data) {
    let pageTitle = "";
    const sections = [];
    let currentSection = null;
    let currentGroup = null;

    function ensureGroup() {
        // If items show up before any minititle, put them in an
        // unlabeled group rather than dropping them.
        if (!currentGroup) {
            currentGroup = { minititle: null, items: [] };
            currentSection.groups.push(currentGroup);
        }
        return currentGroup;
    }

    data.forEach((entry) => {
        if ("title" in entry) {
            pageTitle = entry.title;
        } else if ("subtitle" in entry) {
            currentSection = { subtitle: entry.subtitle, groups: [], comment: null };
            currentGroup = null;
            sections.push(currentSection);
        } else if ("minititle" in entry) {
            if (currentSection) {
                currentGroup = { minititle: entry.minititle, items: [] };
                currentSection.groups.push(currentGroup);
            }
        } else if ("item" in entry) {
            if (currentSection) {
                ensureGroup().items.push({ name: entry.item, price: entry.price });
            }
        } else if ("comment" in entry) {
            if (currentSection) currentSection.comment = entry.comment;
        }
        // Unrecognized keys are silently ignored, so the parser won't
        // break if new fields get added later.
    });

    return { pageTitle, sections };
}

// ---- 3. Build DOM for a single section ----
function renderSection(section) {
    const wrap = document.createElement("div");
    wrap.className = "section";

    const subtitle = document.createElement("h2");
    subtitle.className = "subtitle";
    subtitle.textContent = section.subtitle;
    wrap.appendChild(subtitle);

    section.groups.forEach((group) => {
        if (group.minititle) {
            const mini = document.createElement("div");
            mini.className = "minititle";
            mini.textContent = group.minititle;
            wrap.appendChild(mini);
        }

        if (group.items.length) {
            const list = document.createElement("ul");
            list.className = "items";
            group.items.forEach((it) => {
                const li = document.createElement("li");

                const name = document.createElement("span");
                name.className = "item-name";
                name.textContent = it.name;

                const price = document.createElement("span");
                price.className = "item-price";
                price.textContent = it.price;

                li.appendChild(name);
                li.appendChild(price);
                list.appendChild(li);
            });
            wrap.appendChild(list);
        }
    });

    if (section.comment) {
        const comment = document.createElement("p");
        comment.className = "comment";
        comment.textContent = section.comment;
        wrap.appendChild(comment);
    }

    return wrap;
}

// ---- 4. Render everything: title + sections split across two columns ----
function renderMenu(data) {
    const { pageTitle, sections } = parseMenu(data);

    document.getElementById("page-title").textContent = pageTitle || "Menu";
    document.title = pageTitle || "Menu";

    const colLeft = document.getElementById("col-left");
    const colRight = document.getElementById("col-right");
    colLeft.innerHTML = "";
    colRight.innerHTML = "";

    // Alternate sections between columns so reading order flows
    // top-to-bottom on the left, then top-to-bottom on the right.
    sections.forEach((section, i) => {
        const target = i % 2 === 0 ? colLeft : colRight;
        target.appendChild(renderSection(section));
    });
}

// ---- 5. Load menu.json and render, with basic error handling ----
fetch(MENU_JSON_PATH)
    .then((res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status} loading ${MENU_JSON_PATH}`);
        return res.json();
    })
    .then((data) => renderMenu(data))
    .catch((err) => {
        console.error("Failed to load menu data:", err);
        document.getElementById("page-title").textContent = "Menu unavailable";
        const colLeft = document.getElementById("col-left");
        colLeft.innerHTML =
            "<p class='comment'>Could not load menu.json. If you're opening this file " +
            "directly (file://), run it through a local web server instead — browsers " +
            "block fetch() for local files otherwise.</p>";
    });
