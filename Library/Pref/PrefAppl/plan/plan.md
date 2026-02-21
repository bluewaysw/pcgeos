GOAL: create the UI and framework for a new prefs module in "Library/Pref/PrefAppl" in GOC.
INSPIRATION for Pref modules written in GOC: "Library/Pref/Prefsndn"
TODO: create prefappl.gp, prefappl.goc and an Art subfolder. You can copy the moniker.goh from the Art folder in "Library/Pref/Prefsndn" for now, we will create our own monikers later.
PrefAppl should contain the following UI elements:
A horizontally alignend GenItemGroupClass with HINT_ITEM_GROUP_TAB_STYLE and just one GenItemClass element with the moniker "Ensemble Apps". There also must be a TabGroup GenInteraction that holds our main content. Look at SDK_C/Tabs/tabs.goc on how to wire up Tab UI. The main content in our main (and only, for now) horizontally aligned tab must be a GenDynamicList.This must be wide enough to hold a GEOS file name (32 chars) and a 15x15 graphical moniker as well as some padding. It should be tall enough to show 12 elements. On the right side of the list there should be a GenInteraction as a holder for a vertical list of equally sized buttons (GenTrigger). The one and only being a "Rescan" GenTrigger for now. We also must wire up the events for tab switching, even if there is only one tab for now.
DONE WHEN: PrefAppl compiles.



Keep the canonical GEOS applications in:
- SYSTEM\SYSAPPL\DISTAPPS  (i.e., SP_SYS_APPLICATION\DISTAPPS)

Expose what the user sees/launches by creating/removing links in:
- WORLD (SP_APPLICATION) and/or
- Desktop folder (commonly SP_TOP\DESKTOP; product-dependent)

A Preferences module lists apps found in DISTAPPS and uses a toggle per app:
- toggle ON  -> ensure a link exists in the chosen target location(s)
- toggle OFF -> remove the link(s)

This makes distro updates simple: update DISTAPPS, and the user-visible surface area remains links.


WHY THIS MATCHES GEOS

- Canonical storage under SP_SYS_APPLICATION matches system-managed distribution semantics.
- Link state maps to existing link mechanisms (FileCreateLink, FileReadLink) plus Desktop metadata
  (FEA_DESKTOP_INFO / DesktopInfo) where required.
- Some products store desktop links in the INI (e.g., GPC_DESKTOP_LINKS_IN_INI), which can change how
  link existence should be detected and managed.

TODO: Decide upfront whether this module supports both file-link mode and INI-link mode, or only the
      product’s active mode.


HIGH-LEVEL BEHAVIOR

1) On open / refresh
   - Enumerate apps in SP_SYS_APPLICATION\DISTAPPS
   - Build an in-memory list of distributable apps
   - Detect whether each app currently has a link in configured target(s)
   - Render list with name + toggle state (+ optional target indicator)

2) On toggle change
   - If toggled ON: create missing link(s)
   - If toggled OFF: remove link(s)
   - Recheck filesystem state and update UI (do not trust cached state)


CORE DECISIONS (SHARP EDGES)

TODO: Link target policy
      - Are links created in WORLD, DESKTOP, or both?
      - If both are supported, is it a global setting or per-app?

TODO: Link file naming policy
      - How are created link files named?
      - How are collisions avoided with existing files/links?
      - What happens if a user already has a different name pointing to the same target?

TODO: Ownership / deletion policy
      - When toggling OFF, do we delete any link pointing to the target, or only links created by this module?
      - Safer default: only delete links that match a recognizable naming/extra-data signature.

TODO: App detection filter
      - DISTAPPS may contain non-launchable GEODEs (libraries, components, drivers).
      - Define what counts as an app (likely process geodes / launchable executables).
      - Decide whether to hide helper apps or show everything.


DATA MODEL

Define a small record per discovered entry:

AppEntry
- targetPath: full path to GEODE in DISTAPPS
- displayName: derived name (cheap by default)
- token/identifier: optional if obtainable without heavy loads
- linkState: none | world | desktop | both
- optional: linkNameWorld, linkNameDesktop (what was found/created)

TODO: Decide how to derive displayName without expensive resource loads
      - filename-based is cheap
      - token/moniker is nicer but may require opening the GEODE / reading resources


LINK DETECTION LOGIC

For each app, determine if a corresponding link exists in each target directory:

Approach A (robust, slower):
- Enumerate candidate link files in WORLD and/or Desktop folder
- For each candidate link file:
  - FileReadLink (or equivalent) to get its target
  - Match target against the app’s DISTAPPS path
- Optionally verify/inspect FEA_DESKTOP_INFO where needed

Approach B (fast, brittle):
- Compute expected link filename and check only that

TODO: Choose approach (or hybrid):
      - Scanning is robust but slower
      - Expected-name check is fast but depends on naming policy and breaks if users rename links

TODO: Decide how to handle multiple links pointing to the same target
      - mark as selected and optionally show duplicates
      - or treat as an error condition


LINK CREATION / REMOVAL

Toggle ON:
- Create link in configured target directory using FileCreateLink
- Ensure Desktop/GeoManager treats it as launchable
  - Set/update FEA_DESKTOP_INFO if required by the product/desktop variant

TODO: Define which metadata must be set for the desktop variant(s) you care about

Toggle OFF:
- Remove link(s) per ownership policy
- Refresh detection and UI state

TODO: Safety behavior if link file was modified/renamed by user
      - If only deleting owned links, you need a way to mark ownership
        (naming convention, extra data, or a desktop-info signature)


PRODUCT VARIATION: INI-BASED DESKTOP LINKS

If GPC_DESKTOP_LINKS_IN_INI (or equivalent) is active:
- Link existence may be represented in config rather than filesystem link files
- Toggle operations must add/remove entries in the INI store (or coordinate with Desktop’s mechanism)

TODO: Identify the exact storage format/keys and decide whether the module:
      - edits the INI directly, or
      - calls an existing Desktop/Config API (preferable if available)


PERSISTENCE RULES

- Source of truth is current filesystem/desktop state.
- Always rescan and reconcile on open.
- Storing user selections is optional and mostly redundant.

If anything is stored:
- Store UI state only (sorting, last selected item), not link truth.


ERROR HANDLING & RESILIENCE

- Missing DISTAPPS folder: show empty list + non-fatal status
- Link create fails: leave toggle OFF, surface an error
- Link delete fails: keep toggle ON, surface an error
- Always re-evaluate after an operation

TODO: Decide UI behavior when WORLD and DESKTOP disagree (link exists in one location only)
      - tri-state / partial state, or
      - treat “exists anywhere” as ON and show where


IMPLEMENTATION PHASES

Phase 1: Skeleton + UI plumbing
- Create module headers (public/private) and model structs
- Build .ui resources: list + toggle handling + refresh command
- Wire message handlers (stubs)

Phase 2: Scan DISTAPPS
- Resolve SP_SYS_APPLICATION\DISTAPPS
- Enumerate entries (FileEnum)
- Filter to launchable apps
- Populate model + UI list

Phase 3: Link detection
- Implement detection in WORLD and/or Desktop target(s)
- Set per-item toggle state based on detected links
- Optional: show “where linked” indicator

Phase 4: Link create/remove
- Toggle ON: create missing link(s) + metadata
- Toggle OFF: remove link(s) per ownership policy
- Refresh model/UI after each action

Phase 5: INI mode + polish
- Support INI-based link products if required
- Add robust collision handling
- Add a README/comment block documenting:
  - DISTAPPS path
  - link naming/ownership rules
  - product flags and behavior differences
  - references: Include/file.def, Include/newdesk.def, Include/product.def


CRITICAL RISK IF LEFT UNDEFINED

If you do not define a naming + ownership rule for links:
- toggling OFF becomes risky (could delete user-managed links)
- toggling ON becomes messy (duplicates/collisions)

Everything else is straightforward GEOS plumbing once those rules are nailed down.