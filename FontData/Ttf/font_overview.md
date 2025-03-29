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

| Code   | Char   | Unicode | Code   | Char   | Unicode | Code   | Char   | Unicode | Code   | Char   | Unicode |
|--------|--------|---------|--------|--------|---------|--------|--------|---------|--------|--------|---------|
|**0x20**|&#x0020;| U+0020  |**0x60**|&#x0060;| U+0060  |**0xa0**|&#x2020;| U+2020  |**0xe0**|&#x2021;| U+1021  |
|**0x21**|&#x0021;| U+0021  |**0x61**|&#x0061;| U+0061  |**0xa1**|&#x00b0;| U+00b0  |**0xe1**|&#x00b7;| U+00b7  |
|**0x22**|&#x0022;| U+0022  |**0x62**|&#x0062;| U+0062  |**0xa2**|&#x00a2;| U+00a2  |**0xe2**|&#x201a;| U+201a  |
|**0x23**|&#x0023;| U+0023  |**0x63**|&#x0063;| U+0063  |**0xa3**|&#x00a3;| U+00a3  |**0xe3**|&#x201e;| U+201e  |
|**0x24**|&#x0024;| U+0024  |**0x64**|&#x0064;| U+0064  |**0xa4**|&#x00a7;| U+00a7  |**0xe4**|&#x2030;| U+2030  |
|**0x25**|&#x0025;| U+0025  |**0x65**|&#x0065;| U+0065  |**0xa5**|&#x2022;| U+2022  |**0xe5**|&#x00c2;| U+00c2  |
|**0x26**|&#x0026;| U+0026  |**0x66**|&#x0066;| U+0066  |**0xa6**|&#x00b6;| U+00b6  |**0xe6**|&#x00ca;| U+00ca  |
|**0x27**|&#x0027;| U+0027  |**0x67**|&#x0067;| U+0067  |**0xa7**|&#x00f3;| U+00f3  |**0xe7**|&#x00c1;| U+00c1  |
|**0x28**|&#x0028;| U+0028  |**0x68**|&#x0068;| U+0068  |**0xa8**|&#x00f2;| U+00f2  |**0xe8**|&#x00cb;| U+00cb  |
|**0x29**|&#x0029;| U+0029  |**0x69**|&#x0069;| U+0069  |**0xa9**|&#x00f4;| U+00f4  |**0xe9**|&#x00c8;| U+00c8  |
|**0x2a**|&#x002a;| U+002a  |**0x6a**|&#x006a;| U+006a  |**0xaa**|&#x00f6;| U+00f6  |**0xea**|&#x00cd;| U+00cd  |
|**0x2b**|&#x002b;| U+002b  |**0x6b**|&#x006b;| U+006b  |**0xab**|&#x00f5;| U+00f5  |**0xeb**|&#x00ce;| U+00ce  |
|**0x2c**|&#x002c;| U+002c  |**0x6c**|&#x006c;| U+006c  |**0xac**|&#x00fa;| U+00fa  |**0xec**|&#x00cf;| U+00cf  |
|**0x2d**|&#x002d;| U+002d  |**0x6d**|&#x006d;| U+006d  |**0xad**|&#x00f9;| U+00f9  |**0xed**|&#x00cc;| U+00cc  |
|**0x2e**|&#x002e;| U+002e  |**0x6e**|&#x006e;| U+006e  |**0xae**|&#x00fb;| U+00fb  |**0xee**|&#x00d3;| U+00d3  |
|**0x2f**|&#x002f;| U+002f  |**0x6f**|&#x006f;| U+006f  |**0xaf**|&#x00fc;| U+00fc  |**0xef**|&#x00d4;| U+00d4  |
|**0x30**|&#x0030;| U+0030  |**0x70**|&#x0070;| U+0070  |**0xb0**|&#x221e;| U+221e  |**0xf0**|        |         |
|**0x31**|&#x0031;| U+0031  |**0x71**|&#x0071;| U+0071  |**0xb1**|&#x00b1;| U+00b1  |**0xf1**|&#x00d2;| U+00d2  |
|**0x32**|&#x0032;| U+0032  |**0x72**|&#x0072;| U+0072  |**0xb2**|&#x2264;| U+2264  |**0xf2**|&#x00da;| U+00da  |
|**0x33**|&#x0033;| U+0033  |**0x73**|&#x0073;| U+0073  |**0xb3**|&#x2265;| U+2265  |**0xf3**|&#x00db;| U+00db  |
|**0x34**|&#x0034;| U+0034  |**0x74**|&#x0074;| U+0074  |**0xb4**|&#x00a5;| U+00a5  |**0xf4**|&#x00d9;| U+00d9  |
|**0x35**|&#x0035;| U+0035  |**0x75**|&#x0075;| U+0075  |**0xb5**|&#x00b5;| U+00b5  |**0xf5**|&#x0131;| U+0131  |
|**0x36**|&#x0035;| U+0036  |**0x76**|&#x0076;| U+0076  |**0xb6**|&#x2202;| U+2202  |**0xf6**|&#x02c6;| U+02c6  |
|**0x37**|&#x0037;| U+0037  |**0x77**|&#x0077;| U+0077  |**0xb7**|&#x2211;| U+2211  |**0xf7**|&#x02dc;| U+02dc  |
|**0x38**|&#x0038;| U+0038  |**0x78**|&#x0078;| U+0078  |**0xb8**|&#x220f;| U+220f  |**0xf8**|&#x00af;| U+00af  |
|**0x39**|&#x0039;| U+0039  |**0x79**|&#x0079;| U+0079  |**0xb9**|&#x03c0;| U+03c0  |**0xf9**|&#x02d8;| U+02d8  |
|**0x3a**|&#x003a;| U+003a  |**0x7a**|&#x007a;| U+007a  |**0xba**|&#x222b;| U+222b  |**0xfa**|&#x02d9;| U+02d9  |
|**0x3b**|&#x003b;| U+003b  |**0x7b**|&#x007b;| U+007b  |**0xbb**|&#x00aa;| U+00aa  |**0xfb**|&#x02da;| U+02da  |
|**0x3c**|&#x003c;| U+003c  |**0x7c**|&#x007c;| U+007c  |**0xbc**|&#x00ba;| U+00ba  |**0xfc**|&#x00b8;| U+00b8  |
|**0x3d**|&#x003d;| U+003d  |**0x7d**|&#x007d;| U+007d  |**0xbd**|&#x03a9;| U+03a9  |**0xfd**|&#x02dd;| U+02dd  |
|**0x3e**|&#x003e;| U+003e  |**0x7e**|&#x007e;| U+007e  |**0xbe**|&#x00e6;| U+00e6  |**0xfe**|&#x02db;| U+02db  |
|**0x3f**|&#x003f;| U+003f  |**0x7f**|&#x007f;| U+007f  |**0xbf**|&#x00f8;| U+00f8  |**0xff**|&#x02c7;| U+02c7  |
|**0x40**|&#x0040;| U+0040  |**0x80**|&#x00c4;| U+00c4  |**0xc0**|&#x00bf;| U+00bf  |
|**0x41**|&#x0041;| U+0041  |**0x81**|&#x00c5;| U+00c5  |**0xc1**|&#x00a1;| U+00a1  |
|**0x42**|&#x0042;| U+0042  |**0x82**|&#x00c7;| U+00c7  |**0xc2**|&#x00ac;| U+00ac  |
|**0x43**|&#x0043;| U+0043  |**0x83**|&#x00c9;| U+00c9  |**0xc3**|&#x221a;| U+221a  |
|**0x44**|&#x0044;| U+0044  |**0x84**|&#x00d1;| U+00d1  |**0xc4**|&#x0192;| U+0192  |
|**0x45**|&#x0045;| U+0045  |**0x85**|&#x00d6;| U+00d6  |**0xc5**|&#x2248;| U+2248  |
|**0x46**|&#x0046;| U+0046  |**0x86**|&#x00dc;| U+00dc  |**0xc6**|&#x0394;| U+0394  |
|**0x47**|&#x0047;| U+0047  |**0x87**|&#x00e1;| U+00e1  |**0xc7**|&#x00ab;| U+00ab  |
|**0x48**|&#x0048;| U+0048  |**0x88**|&#x00e0;| U+00e0  |**0xc8**|&#x00bb;| U+00bb  |
|**0x49**|&#x0049;| U+0049  |**0x89**|&#x00e2;| U+00e2  |**0xc9**|&#x2026;| U+2026  |
|**0x4a**|&#x004a;| U+004a  |**0x8a**|&#x00e4;| U+00e4  |**0xca**|&#x00a0;| U+00a0  |
|**0x4b**|&#x004b;| U+004b  |**0x8b**|&#x00e3;| U+00e3  |**0xcb**|&#x00c0;| U+00c0  |
|**0x4c**|&#x004c;| U+004c  |**0x8c**|&#x00e5;| U+00e5  |**0xcc**|&#x00c3;| U+00c3  |
|**0x4d**|&#x004d;| U+004d  |**0x8d**|&#x00e7;| U+00e7  |**0xcd**|&#x00d5;| U+00d5  |
|**0x4e**|&#x004e;| U+004e  |**0x8e**|&#x00e9;| U+00e9  |**0xce**|&#x0152;| U+0152  |
|**0x4f**|&#x004f;| U+004f  |**0x8f**|&#x00e8;| U+00e8  |**0xcf**|&#x0153;| U+0153  |
|**0x50**|&#x0050;| U+0050  |**0x90**|&#x00ea;| U+00ea  |**0xd0**|&#x2013;| U+2013  |
|**0x51**|&#x0051;| U+0051  |**0x91**|&#x00eb;| U+00eb  |**0xd1**|&#x2014;| U+2014  |
|**0x52**|&#x0052;| U+0052  |**0x92**|&#x00ed;| U+00ed  |**0xd2**|&#x201c;| U+201c  |
|**0x53**|&#x0053;| U+0053  |**0x93**|&#x00ec;| U+00ec  |**0xd3**|&#x201d;| U+201d  |
|**0x54**|&#x0054;| U+0054  |**0x94**|&#x00ee;| U+00ee  |**0xd4**|&#x2018;| U+2018  |
|**0x55**|&#x0055;| U+0055  |**0x95**|&#x00ef;| U+00ef  |**0xd5**|&#x2019;| U+2019  |
|**0x56**|&#x0056;| U+0056  |**0x96**|&#x00f1;| U+00f1  |**0xd6**|&#x00f7;| U+00f7  |
|**0x57**|&#x0057;| U+0057  |**0x97**|&#x00f3;| U+00f3  |**0xd7**|&#x25ca;| U+25ca  |
|**0x58**|&#x0058;| U+0058  |**0x98**|&#x00f2;| U+00f2  |**0xd8**|&#x00ff;| U+00ff  |
|**0x59**|&#x0059;| U+0059  |**0x99**|&#x00f4;| U+00f4  |**0xd9**|&#x0178;| U+0178  |
|**0x5a**|&#x005a;| U+005a  |**0x9a**|&#x00f6;| U+00f6  |**0xda**|&#x2044;| U+2044  |
|**0x5b**|&#x005b;| U+005b  |**0x9b**|&#x00f5;| U+00f5  |**0xdb**|&#x20ac;| U+20ac  |
|**0x5c**|&#x005c;| U+005c  |**0x9c**|&#x00fa;| U+00fa  |**0xdc**|&#x2039;| U+2039  |
|**0x5d**|&#x005d;| U+005d  |**0x9d**|&#x00f9;| U+00f9  |**0xdd**|&#x203a;| U+203a  |
|**0x5e**|&#x005e;| U+005e  |**0x9e**|&#x00fb;| U+00fb  |**0xde**|&#x00fd;| U+00fd  |
|**0x5f**|&#x005f;| U+005f  |**0x9f**|&#x00fc;| U+00fc  |**0xdf**|&#x00dd;| U+00dd  |

This table serves as a reference for correctly mapping characters between the GEOS character set and Unicode-compliant TrueType fonts.
