# PC/GEOS TrueType Font Overview

This document provides an overview of the TrueType fonts included in the PC/GEOS distribution. It lists relevant information for each font, including the original and modified filename, available styles, license, and any adjustments made.

## Font Table

|Font Family Name|Source<br>URL   |License          |Styles     |Original<br>Filename       |PC/GEOS<br>Filename|Kerning|Hinting|Mapped to<br>Original Font| Changes<br>for PC/GEOS |
|----------------|----------------|-----------------|-----------|---------------------------|-------------------|-------|-------|--------------------------|------------------------|
|Century 59      |[[S1]](#sources)|[[L1]](#licenses)|Regular    |C059-Roman.ttf             |c059re.ttf         |no     |yes    |Cranbrook    | [[C1]](#changes), [[C2]](#changes)  |
|                |                |                 |Bold       |C059-Bold.ttf              |c059bo.ttf         |       |       |             |                                     |
|                |                |                 |Italic     |C059-Italic.ttf            |c059it.ttf         |       |       |             |                                     |
|                |                |                 |Bold Italic|C059-Bdita.ttf             |c059bi.ttf         |       |       |             |                                     |
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
|Standard Symbol PS|[[S1]](#sources)|[[L1]](#licenses)|Regular  |StandardSymbolPS.ttf       |symbolps.ttf       |no     |yes    |

## Sources
The original font files were obtained from various sources. Below is a list of the sources for each font.

S1. **URW++ base 35 fonts**: [https://github.com/ArtifexSoftware/urw-base35-fonts/tree/master](https://github.com/ArtifexSoftware/urw-base35-fonts/tree/master)

## Licenses
The fonts included in this distribution are subject to their respective licenses. Please review the individual license terms for each font.

L1. **GNU Aferro General Public License**: [https://www.gnu.org/licenses/agpl-3.0.txt](https://www.gnu.org/licenses/agpl-3.0.txt)

## Changes
If any modifications have been made to the fonts (e.g. renaming or hinting optimization), they are noted in the "Changes for PC/GEOS" column of the table.

C1. **Character set**: The included characters have been reduced to the PC/GEOS character set.
C2. **Automatic hinting**: Auto-hinting applied to improve on-screen readability and rendering quality.
