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
| 0x50            | &#x0050;  | U+0050        | latin capital letter p |
| 0x51            | &#x0051;  | U+0051        | latin capital letter q |
| 0x52            | &#x0052;  | U+0052        | latin capital letter r |
| 0x53            | &#x0053;  | U+0053        | latin capital letter s |
| 0x54            | &#x0054;  | U+0054        | latin capital letter t |
| 0x55            | &#x0055;  | U+0055        | latin capital letter u |
| 0x56            | &#x0056;  | U+0056        | latin capital letter v |
| 0x57            | &#x0057;  | U+0057        | latin capital letter w |
| 0x58            | &#x0058;  | U+0058        | latin capital letter x |
| 0x59            | &#x0059;  | U+0059        | latin capital letter y |
| 0x5A            | &#x005a;  | U+005a        | latin capital letter z |
| 0x5B            | &#x005b;  | U+005b        | opening square bracket|
| 0x5C            | &#x005c;  | U+005c        | backslash        |
| 0x5D            | &#x005d;  | U+005d        | closing square bracket|
| 0x5E            | &#x005e;  | U+005e        | spacing circumflex|
| 0x5F            | &#x005f;  | U+005f        | spacing underscore|
| 0x60            | &#x0060;  | U+0060        | spacing grave    |
| 0x61            | &#x0061;  | U+0061        | latin small letter a|
| 0x62            | &#x0062;  | U+0062        | latin small letter b|
| 0x63            | &#x0063;  | U+0063        | latin small letter c|
| 0x64            | &#x0064;  | U+0064        | latin small letter d|
| 0x65            | &#x0065;  | U+0065        | latin small letter e|
| 0x66            | &#x0066;  | U+0066        | latin small letter f|
| 0x67            | &#x0067;  | U+0067        | latin small letter g|
| 0x68            | &#x0068;  | U+0068        | latin small letter h|
| 0x69            | &#x0069;  | U+0069        | latin small letter i|
| 0x6A            | &#x006a;  | U+006a        | latin small letter j|
| 0x6B            | &#x006b;  | U+006b        | latin small letter k|
| 0x6C            | &#x006c;  | U+006c        | latin small letter l|
| 0x6D            | &#x006d;  | U+006d        | latin small letter m|
| 0x6E            | &#x006e;  | U+006e        | latin small letter n|
| 0x6F            | &#x006f;  | U+006f        | latin small letter o|
| 0x70            | &#x0070;  | U+0070        | latin small letter p|
| 0x71            | &#x0071;  | U+0071        | latin small letter q|
| 0x72            | &#x0072;  | U+0072        | latin small letter r|
| 0x73            | &#x0073;  | U+0073        | latin small letter s|
| 0x74            | &#x0074;  | U+0074        | latin small letter t|
| 0x75            | &#x0075;  | U+0075        | latin small letter u|
| 0x76            | &#x0076;  | U+0076        | latin small letter v|
| 0x77            | &#x0077;  | U+0077        | latin small letter w|
| 0x78            | &#x0078;  | U+0078        | latin small letter x|
| 0x79            | &#x0079;  | U+0079        | latin small letter y|
| 0x7A            | &#x007a;  | U+007a        | latin small letter z|
| 0x7B            | &#x007b;  | U+007b        | opening curly bracket|
| 0x7C            | &#x007c;  | U+007c        | vertical bar     |
| 0x7D            | &#x007d;  | U+007d        | closing curla bracket|
| 0x7E            | &#x007e;  | U+007e        | tilde            |
| 0x7F            |           |               | DEL control character|
| 0x80            | &#x00c4;  | U+00c4        | latin capital letter a diaeresis|
| 0x81            | &#x00c5;  | U+00c5        | latin capital letter a ring     |
| 0x82            | &#x00c7;  | U+00c7        | latin capital letter c cedilla  |
| 0x83            | &#x00c9;  | U+00c9        | latin capital letter e acute    |
| 0x84            | &#x00d1;  | U+00d1        | latin capital letter n tilde    |
| 0x85            | &#x00d6;  | U+00d6        | latin capital letter o diaeresis|
| 0x86            | &#x00dc;  | U+00dc        | latin capital letter u diaeresis|
| 0x87            | &#x00e1;  | U+00e1        | latin small letter a acute     |
| 0x88            | &#x00e0;  | U+00e0        | latin small letter a grave     |
| 0x89            | &#x00e2;  | U+00e2        | latin small letter a circumflex|
| 0x8A            | &#x00e4;  | U+00e4        | latin small letter a diaeresis |
| 0x8B            | &#x00e3;  | U+00e3	      | latin small letter a tilde     |
| 0x8C            | &#x00e5;  | U+00e5        | latin small letter a ring      |
| 0x8D            | &#x00e7;  | U+00e7        | latin small letter c cedilla   |
| 0x8E            | &#x00e9;  | U+00e9        | latin small letter e acute     |
| 0x8F            | &#x00e8;  | U+00e8        | latin small letter e grave     |
| 0x90            | &#x00ea;  | U+00ea        | latin small letter e circumflex|
| 0x91            | &#x00eb;  | U+00eb        | latin small letter e diaeresis |
| 0x92            | &#x00ed;  | U+00ed        | latin small letter i acute     |
| 0x93            | &#x00ec;  | U+00ec        | latin small letter i grave     |
| 0x94            | &#x00ee;  | U+00ee        | latin small letter i circumflex|
| 0x95            | &#x00ef;  | U+00ef        | latin small letter i diaeresis |
| 0x96            | &#x00f1;  | U+00f1        | latin small letter n tilde     |
| 0x97            | &#x00f3;  | U+00f3        | latin small letter o acute     |
| 0x98            | &#x00f2;  | U+00f2        | latin small letter o grave     |
| 0x99            | &#x00f4;  | U+00f4        | latin small letter o circumflex|
| 0x9A            | &#x00f6;  | U+00f6        | latin small letter o diaeresis |
| 0x9B            | &#x00f5;  | U+00f5        | latin small letter o tilde     |
| 0x9C            | &#x00fa;  | U+00fa        | latin small letter u acute     |
| 0x9D            | &#x00f9;  | U+00f9        | latin small letter u grave     |
| 0x9E            | &#x00fb;  | U+00fb        | latin small letter u circumflex|
| 0x9F            | &#x00fc;  | U+00fc        | latin small letter u diaeresis |
| 0xA0            | &#x2020;  | U+2020        | dagger           |
| 0xA1            | &#x00b0;  | U+00b0        | degree sign      |
| 0xA2            | &#x00a2;  | U+00a2        | cent sign        |
| 0xA3            | &#x00a3;  | U+00a3        | pound sign       |
| 0xA4            | &#x00a7;  | U+00a7        | section sign     |
| 0xA5            | &#x2022;  | U+2022        | bullet           |
| 0xA6            | &#x00b6;  | U+00b6        | pilcrow sign     |
| 0xA7            | &#x00df;  | U+00df        | latin small letter sharp s|
| 0xA8            | &#x00ae;  | U+00ae        | registered sign  |
| 0xA9            | &#x00a9;  | U+00a9        | copyright sign   |
| 0xAA            | &#x2122;  | U+2122        | trade mark sign  |
| 0xAB            | &#x00b4;  | U+00b4        | spacing acute    |
| 0xAC            | &#x00a8;  | U+00a8        | diaeresis        |
| 0xAD            | &#x2260;  | U+2260        | not equal to     |
| 0xAE            | &#x00c6;  | U+00c6	      | latin capital letter ae |
| 0xAF            | &#x00d8;  | U+00d8        | latin capital letter  o with stroke |
| 0xB0            | &#x221e;  | U+221e        | infinity         |
| 0xB1            | &#x00b1;  | U+00b1        | plus-minus sign  |
| 0xB2            | &#x2264;  | U+2264        | less-than or equal to |
| 0xB3            | &#x2265;  | U+2265        | greater-than or equal to |
| 0xB4            | &#x00a5;  | U+00a5        | yen sign         |
| 0xB5            | &#x00b5;  | U+00b5        | micro sign       |
| 0xB6            | &#x2202;  | U+2202        | partial differintial |
| 0xB7            | &#x2211;  | U+2211        | n-arr summation  |
| 0xB8            | &#x220f;  | U+220f        | n-arr product    |
| 0xB9            | &#x03c0;  | U+03c0        | greek small letter pi |
| 0xBA            | &#x222b;  | U+222b        | integral         |
| 0xBB            | &#x00aa;  | U+00aa        | feminin ordinal indicator |
| 0xBC            | &#x00ba;  | U+00ba        | masculine ordinal indicator |
| 0xBD            | &#x03a9;  | U+03a9        | greek capital letter omega | 
| 0xBE            | &#x00e6;  | U+00e6        | latin small letter ae |
| 0xBF            | &#x00f8;  | U+00f8        | latin small letter o with stroke |
| 0xC0            | &#x00bf;  | U+00bf        | inverted question mark |
| 0xC1            | &#x00a1;  | U+00a1        | inverted exclamation mark |
| 0xC2            | &#x00ac;  | U+00ac        | not sign         |
| 0xC3            | &#x221a;  | U+221a        | square root      |
| 0xC4            | &#x0192;  | U+0192        | latin small letter f with hook |
| 0xC5            | &#x2248;  | U+2248        | almost equal to  |
| 0xC6            | &#x0394;  | U+0394        | greek capital letter delta |
| 0xC7            | &#x00ab;  | U+00ab        | left-pointing double angle quotation mark |
| 0xC8            | &#x00bb;  | U+00bb        | right-pointing double angle quotation mark |
| 0xC9            | &#x2026;  | U+2026        | horizontal ellipsis |
| 0xCA            | &#x00a0;  | U+00a0        | no-break space   |
| 0xCB            | &#x00c0;  |	U+00c0        | latin capital letter a with grave |
| 0xCC            | &#x00c3;  |	U+00c3        | latin capital letter a with tilde |
| 0xCD            | &#x00d5;  |	U+00d5        | latin capital letter o with tilde |
| 0xCE            | &#x0152;  | U+0152        | latin capital ligature oe |
| 0xCF            | &#x0153;  | U+0153        | latin small ligature oe |
| 0xD0            | &#x2013;  | U+2013        | en dash          |
| 0xD1            | &#x2014;  |	U+2014        | em dash          |


| Code   | Char   | Unicode | Code   | Char   | Unicode | Code   | Char   | Unicode | Code   | Char   | Unicode |
|--------|--------|---------|--------|--------|---------|--------|--------|---------|--------|--------|---------|
|**0x20**|&#x0020;| U+0020  |**0x60**|&#x0060;| U+0060  |**0x90**|&#x00ea;| U+00ea  |**0xe0**|&#x2021;| U+1021  |
|**0x21**|&#x0021;| U+0021  |**0x61**|&#x0061;| U+0061  |**0x91**|&#x00eb;| U+00eb  |
|**0x22**|&#x0022;| U+0022  |**0x62**|&#x0062;| U+0062  |**0x92**|&#x00ed;| U+00ed  |
|**0x23**|&#x0023;| U+0023  |**0x63**|&#x0063;| U+0063  |**0x93**|&#x00ec;| U+00ec  |
|**0x24**|&#x0024;| U+0024  |**0x64**|&#x0064;| U+0064  |**0x94**|&#x00ee;| U+00ee  |
|**0x25**|&#x0025;| U+0025  |**0x65**|&#x0065;| U+0065  |**0x95**|&#x00ef;| U+00ef  |
|**0x26**|&#x0026;| U+0026  |**0x66**|&#x0066;| U+0066  |**0x96**|&#x00f1;| U+00f1  |
|**0x27**|&#x0027;| U+0027  |**0x67**|&#x0067;| U+0067  |**0x97**|&#x00f3;| U+00f3  |
|**0x28**|&#x0028;| U+0028  |**0x68**|&#x0068;| U+0068  |**0x98**|&#x00f2;| U+00f2  |
|**0x29**|&#x0029;| U+0029  |**0x69**|&#x0069;| U+0069  |**0x99**|&#x00f4;| U+00f4  |
|**0x2a**|&#x002a;| U+002a  |**0x6a**|&#x006a;| U+006a  |**0x9a**|&#x00f6;| U+00f6  |
|**0x2b**|&#x002b;| U+002b  |**0x6b**|&#x006b;| U+006b  |**0x9b**|&#x00f5;| U+00f5  |
|**0x2c**|&#x002c;| U+002c  |**0x6c**|&#x006c;| U+006c  |**0x9c**|&#x00fa;| U+00fa  |
|**0x2d**|&#x002d;| U+002d  |**0x6d**|&#x006d;| U+006d  |**0x9d**|&#x00f9;| U+00f9  |
|**0x2e**|&#x002e;| U+002e  |**0x6e**|&#x006e;| U+006e  |**0x9e**|&#x00fb;| U+00fb  |
|**0x2f**|&#x002f;| U+002f  |**0x6f**|&#x006f;| U+006f  |**0x9f**|&#x00fc;| U+00fc  |
|**0x30**|&#x0030;| U+0030  |**0x70**|&#x0070;| U+0070  |**0xa0**|&#x2020;| U+2020  |
|**0x31**|&#x0031;| U+0031  |**0x71**|&#x0071;| U+0071  |
|**0x32**|&#x0032;| U+0032  |**0x72**|&#x0072;| U+0072  |
|**0x33**|&#x0033;| U+0033  |**0x73**|&#x0073;| U+0073  |
|**0x34**|&#x0034;| U+0034  |**0x74**|&#x0074;| U+0074  |
|**0x35**|&#x0035;| U+0035  |**0x75**|&#x0075;| U+0075  |
|**0x36**|&#x0035;| U+0036  |**0x76**|&#x0076;| U+0076  |
|**0x37**|&#x0037;| U+0037  |**0x77**|&#x0077;| U+0077  |
|**0x38**|&#x0038;| U+0038  |**0x78**|&#x0078;| U+0078  |
|**0x39**|&#x0039;| U+0039  |**0x79**|&#x0079;| U+0079  |
|**0x3a**|&#x003a;| U+003a  |**0x7a**|&#x007a;| U+007a  |
|**0x3b**|&#x003b;| U+003b  |**0x7b**|&#x007b;| U+007b  |
|**0x3c**|&#x003c;| U+003c  |**0x7c**|&#x007c;| U+007c  |
|**0x3d**|&#x003d;| U+003d  |**0x7d**|&#x007d;| U+007d  |
|**0x3e**|&#x003e;| U+003e  |**0x7e**|&#x007e;| U+007e  |
|**0x3f**|&#x003f;| U+003f  |**0x7f**|&#x007f;| U+007f  |
|**0x40**|&#x0040;| U+0040  |**0x80**|&#x00c4;| U+00c4  |
|**0x41**|&#x0041;| U+0041  |**0x81**|&#x00c5;| U+00c5  |
|**0x42**|&#x0042;| U+0042  |**0x82**|&#x00c7;| U+00c7  |
|**0x43**|&#x0043;| U+0043  |**0x83**|&#x00c9;| U+00c9  |
|**0x44**|&#x0044;| U+0044  |**0x84**|&#x00d1;| U+00d1  |
|**0x45**|&#x0045;| U+0045  |**0x85**|&#x00d6;| U+00d6  |
|**0x46**|&#x0046;| U+0046  |**0x86**|&#x00dc;| U+00dc  |
|**0x47**|&#x0047;| U+0047  |**0x87**|&#x00e1;| U+00e1  |
|**0x48**|&#x0048;| U+0048  |**0x88**|&#x00e0;| U+00e0  |
|**0x49**|&#x0049;| U+0049  |
|**0x4a**|&#x004a;| U+004a  |
|**0x4b**|&#x004b;| U+004b  |
|**0x4c**|&#x004c;| U+004c  |
|**0x4d**|&#x004d;| U+004d  |
|**0x4e**|&#x004e;| U+004e  |
|**0x4f**|&#x004f;| U+004f  |
|**0x50**|&#x0050;| U+0050  |
|**0x51**|&#x0051;| U+0051  |
|**0x52**|&#x0052;| U+0052  |
|**0x53**|&#x0053;| U+0053  |
|**0x54**|&#x0054;| U+0054  |
|**0x55**|&#x0055;| U+0055  |
|**0x56**|&#x0056;| U+0056  |
|**0x57**|&#x0057;| U+0057  |
|**0x58**|&#x0058;| U+0058  |
|**0x59**|&#x0059;| U+0059  |
|**0x5a**|&#x005a;| U+005a  |
|**0x5b**|&#x005b;| U+005b  |
|**0x5c**|&#x005c;| U+005c  |
|**0x5d**|&#x005d;| U+005d  |
|**0x5e**|&#x005e;| U+005e  |
|**0x5f**|&#x005f;| U+005f  |

This table serves as a reference for correctly mapping characters between the GEOS character set and Unicode-compliant TrueType fonts.
