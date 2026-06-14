# Font Documentation: StandardSymbolPS

## 1. General Information
* **Original File Name:** StandardSymbolPS.ttf
* **GEOS File Name:** symbolps.ttf
* **License:** [GNU Aferro General Public License](https://github.com/ArtifexSoftware/urw-base35-fonts/blob/master/COPYING)
* **Upstream Source:** https://github.com/ArtifexSoftware/urw-base35-fonts/tree/master

## 2. PC/GEOS Specifics
* **GEOS Font ID:** Mapped in geos.ini to 0x5800
* **Supported Styles:** Regular

## 3. Modifications
*Document any changes made to the original font for optimal display in PC/GEOS.*

### Technical Adjustments:
- [x] **Charset Reduction:** Removed all non-GEOS glyphs to save memory.
- [ ] **Kerning Pairs:** Reduced to a minimum to optimize driver performance and memory.
- [x] **Character Mapping:** Re-mapped specsymbol characters to GEOS code page.
- [ ] **OS/2 Metrics:** (Adjusted WinAscent/WinDescent to fix line clipping in GeoWrite)
- [ ] **Em-Size Scaling:** (Standardized to 2048 units for consistency)
- [ ] **Naming:** (Shortened internal font names to comply with older GEOS conventions if necessary)

### Visual Optimizations / Hinting:
- [x] **Auto-Hinting:** Applied auto-hinting for low-resolution screens
- [ ] **Optimized Hinting:** (Hinting specifically for **Black & White rendering** to ensure sharp stems and consistent glyph heights)
- [ ] **Manual Deltas:** (Specific tweaks for legibility at 10pt or 12pt)
- [ ] **Blue Values:** (Alignment zones adjusted for typical 72dpi screens)

## 4. Known Issues / To-Do
- [ ] **Priority:** Fine-tune Hinting for B/W rendering to eliminate "blurry" pixels in 1-bit mode.

---
*Last updated: 04.04.2026 by jkunze*
