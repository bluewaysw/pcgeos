# Font Documentation: Cooper* Black

## 1. General Information
* **Original File Name:** Cooper-Black.ttf
* **GEOS File Name:** cooper.ttf
* **License:** [SIL Open Font License](https://openfontlicense.org/open-font-license-official-text/)
* **Upstream Source:** https://indestructibletype.com/Home.html

## 2. PC/GEOS Specifics
* **GEOS Font ID:** Mapped in geos.ini to 0x5604
* **Supported Styles:** Bold

## 3. Modifications
*Document any changes made to the original font for optimal display in PC/GEOS.*

### Technical Adjustments:
- [x] **Charset Reduction:** Removed all non-GEOS glyphs to save memory.
- [ ] **Kerning Pairs:** Reduced to a minimum to optimize driver performance and memory.
- [ ] **Character Mapping:** Re-mapped specsymbol characters to GEOS code page.
- [x] **OS/2 Metrics:** (Adjusted WinAscent/WinDescent to fix line clipping in GeoWrite)
- [ ] **Em-Size Scaling:** (Standardized to 2048 units for consistency)
- [x] **Naming:** Sub-Family name changed to "Bold" to ensure correct style recognition.

### Visual Optimizations / Hinting:
- [x] **Auto-Hinting:** Applied auto-hinting for low-resolution screens
- [ ] **Optimized Hinting:** (Hinting specifically for **Black & White rendering** to ensure sharp stems and consistent glyph heights)
- [ ] **Manual Deltas:** (Specific tweaks for legibility at 10pt or 12pt)
- [ ] **Blue Values:** (Alignment zones adjusted for typical 72dpi screens)

## 4. Known Issues / To-Do
- [ ] **Priority:** Fine-tune Hinting for B/W rendering to eliminate "blurry" pixels in 1-bit mode.

---
*Last updated: 16.04.2026 by jkunze*
