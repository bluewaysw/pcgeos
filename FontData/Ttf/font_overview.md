# PC/GEOS TrueType Font Overview

This document provides an overview of the TrueType fonts included in the PC/GEOS distribution. It lists relevant information for each font, including the original and modified filename, available styles, license, and any adjustments made.

## Font Table

|Font Family Name|Source<br>URL   |License          |Styles     |Original<br>Filename       |PC/GEOS<br>Filename|Kerning|Hinting|Mapped to<br>Original Font| Changes<br>for PC/GEOS |
|----------------|----------------|-----------------|-----------|---------------------------|-------------------|-------|-------|--------------------------|------------------------|
|Century 59      |[[S1]](#sources)|[[L1]](#licenses)|Regular    |C059-Roman.ttf             |c059re.ttf         |no     |yes    |Cranbrook    | [[C1]](#changes), [[C2]](#changes)  |
|                |                |                 |Bold       |C059-Bold.ttf              |c059bo.ttf         |       |       |             |                                     |
|                |                |                 |Italic     |C059-Italic.ttf            |c059it.ttf         |       |       |             |                                     |
|                |                |                 |Bold Italic|C059-Bdita.ttf             |c059bi.ttf         |       |       |             |                                     |
|NYTFranklin     |[[S2]](#sources)|                 |Regular    | ???                       |franklin.ttf       |yes    |yes    |Sather Gothic| [[C1]](#changes), [[C2]](#changes)  |
|                |                |                 |Bold       | ???                       | ???               |       |       |             |                                     |
|                |                |                 |Italic     | ???                       | ???               |       |       |             |                                     |
|                |                |                 |Bold Italic| ???                       | ???               |       |       |             |                                     |
|Nimbus Mono     |[[S1]](#sources)|[[L1]](#licenses)|Regular    |NimbusMonoPS-Regular.ttf   |nmonore.ttf        |no     |yes    |URW Mono     | [[C1]](#changes), [[C2]](#changes)  |
|                |                |                 |Bold       |NimbusMonoPS-Bold.ttf      |nmonobo.ttf        |       |       |             |                                     |
|                |                |                 |Italic     |NimbusMonoPS-Italic.ttf    |nmonori.ttf        |       |       |             |                                     |
|                |                |                 |Bold Italic|NimbusMonoPS-BoldItalic.ttf|nmonobi.ttf        |       |       |             |                                     |
|Nimbus Roman    |[[S1]](#sources)|[[L1]](#licenses)|Regular    |NimbusRoman-Regular.ttf    |nromre.ttf         |no     |yes    |URW Roman    | [[C1]](#changes), [[C2]](#changes)  |
|                |                |                 |Bold       |NimbusRoman-Bold.ttf       |nrombo.ttf         |       |       |             |                                     |
|                |                |                 |Italic     |NimbusRoman-Italic.ttf     |nromri.ttf         |       |       |             |                                     |
|                |                |                 |Bold Italic|NimbusRoman-BoldItalic.ttf |nrombi.ttf         |       |       |             |                                     |
|Nimbus Sans     |[[S1]](#sources)|[[L1]](#licenses)|Regular    |NimbusSans-Regular.ttf     |nsansre.ttf        |yes    |yes    |URW Sans     | [[C1]](#changes), [[C2]](#changes)  |
|                |                |                 |Bold       |NimbusSans-Bold.ttf        |nsansbo.ttf        |       |       |             |                                     |
|                |                |                 |Italic     |NimbusSans-Italic.ttf      |nsansri.ttf        |       |       |             |                                     |
|                |                |                 |Bold Italic|NimbusSans-BoldItalic.ttf  |nsansbi.ttf        |       |       |             |                                     |
|Standard Symbols PS|[[S1]](#sources)|[[L1]](#licenses)|Regular |StandardSymbolPS.ttf       |symbolps.ttf       |no     |yes    |URW SymbolPS | [[C1]](#changes), [[C2]](#changes)  |

## Sources
The original font files were obtained from various sources. Below is a list of the sources for each font.

S1. **URW++ base 35 fonts**: [https://github.com/ArtifexSoftware/urw-base35-fonts/tree/master](https://github.com/ArtifexSoftware/urw-base35-fonts/tree/master)
S2. **New York Times Community**: [https://github.com/FrancesCoronel/nyt-comm/tree/master/fonts/franklin](https://github.com/FrancesCoronel/nyt-comm/tree/master/fonts/franklin)

## Licenses
The fonts included in this distribution are subject to their respective licenses. Please review the individual license terms for each font.

L1. **GNU Aferro General Public License**: [https://www.gnu.org/licenses/agpl-3.0.txt](https://www.gnu.org/licenses/agpl-3.0.txt)
L2. **MIT License**:

## Changes
If any modifications have been made to the fonts (e.g. renaming or hinting optimization), they are noted in the "Changes for PC/GEOS" column of the table.

C1. **Character set**: The included characters have been reduced to the PC/GEOS character set. 
C2. **Automatic hinting**: Auto-hinting applied to improve on-screen readability and rendering quality. 

## Mapping the GEOS Character Set to Unicode

The PC/GEOS distribution uses a custom character set that differs from standardized Unicode assignments. To ensure proper display and conversion of characters between the GEOS character set and TrueType fonts, the following mapping is defined:  

| GEOS Code (Hex) | Character | Unicode (Hex) | Description      |
|-----------------|-----------|---------------|------------------|
| 0x20            | &#x0020;  | U+0020        | space            |
| 0x21            | &#x0021;  | U+0021        | exclamation mark |
| 0x22            | &#x0022;  | U+0022        | quotation mark   |
| 0x23            | &#x0023;  | U+0023        | number sign      |
| 0x24            | &#x0024;  | U+0024        | dollar sign      |
| 0x25            | &#x0025;  | U+0025        | percent sign     |

This table serves as a reference for correctly mapping characters between the GEOS character set and Unicode-compliant TrueType fonts.
