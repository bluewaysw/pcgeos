## 2 Greyscale Text

This chapter describes greyscale (anti-aliased) text rendering: characters
whose pixels carry a coverage value that the video driver blends with the
background, instead of being either ink or background. It is available in
protected mode only, because greyscale characters need larger font blocks
than real mode can afford.

### 2.1 Overview

Greyscale text involves four parts of the system:

- the **font manager** in the kernel decides per GState whether greyscale
  characters are wanted and requests them from the font driver;
- the **font driver** (TrueType) renders greyscale characters into the
  font buffer, or 1 bit characters if it doesn't grant the request;
- the **font buffer** carries the format in its flags (`FBF_IS_GREY`,
  `FBF_GREY_PHASES`), so every other part knows how to read it;
- the **video driver** (VGA16) blends greyscale characters into the
  screen.

The request goes from the kernel to the font driver; the result (the font
buffer's flags) goes from the font driver to the video driver. A part
that doesn't know about greyscale never sees greyscale characters: font
drivers other than TrueType ignore the request, and the kernel only
requests greyscale for windows on a video driver that has said it can
draw them.

### 2.2 Switching It On

Greyscale text is off by default. It is switched on in the `[text]`
category of the GEOS.INI file:

```
[text]
greyscale = true
```

The key must go into the existing `[text]` category; a second `[text]`
category further down is not read.

Further keys, in the `[truetype]` category:

| Key | Default | Meaning |
|---|---|---|
| `greyHinting` | `false` | `true` hints greyscale glyphs like 1 bit glyphs (crisper stems, less even spacing, see 2.6.2) |
| `forceGrey` | `false` | test switch: request greyscale for every TrueType font, including GStates the kernel wouldn't request it for (bitmaps, gstrings). Not for normal use: drivers that can't draw greyscale characters draw garbage |

### 2.3 The Request

#### 2.3.1 When Greyscale Is Requested

`FontGreyRequested` (`Library/Kernel/Graphics/graphicsChars.asm`)
decides for a GState. Greyscale is requested when all of these hold:

- greyscale text is switched on (`[text] greyscale`, read once by
  `GrInitFonts` at startup);
- a video driver that draws greyscale characters has registered itself
  with `GrSetGreyTextDriver`;
- the GState draws to a window on that driver (`W_driverStrategy` of
  `GS_window` matches).

GStates without a window (gstrings, printing) and windows on other
drivers (bitmaps in memory, VidMem) keep 1 bit characters.

`FontGreyRequested` is called while font blocks are locked. It therefore
only compares values that were set beforehand and calls nothing that
could block. An earlier version read the INI file and queried the video
driver from there; that could deadlock at startup against threads
holding the INI file or the video driver and waiting for fonts, and it
decided before the video driver was even loaded.

#### 2.3.2 Video Driver Registration

A video driver that draws greyscale characters:

- lists `VID_ESC_GREY_TEXT` in its escape table (`videoDr.def`), so that
  the capability can be queried with `DRV_ESC_QUERY_ESC`;
- calls `GrSetGreyTextDriver` (cx:dx = its strategy routine) when its
  device is set. VGA16 does so at the end of `VidSetVESA`.

The registration is protected mode only; in real mode
`GrSetGreyTextDriver` does nothing.

#### 2.3.3 Font Cache Key and the Font Driver

Whether greyscale was requested is part of the key of the font cache
(`FontsInUseEntry`): `FIUE_flags` holds `FBF_IS_GREY` for a request,
next to `FBF_IS_COMPLEX`. `IsFontInUse` compares the flags exactly, and
`AddInUseEntry` sets them. So the 1 bit and the greyscale version of the
same font can be in use at the same time, e.g. on screen and on the
printer.

The request reaches the font driver through `GS_fontFlags`:
`CheckCallDriver` sets `FBF_IS_GREY` there before `DR_FONT_GEN_WIDTHS`.
After the call, `UpdateFontOpts` replaces the bit with the font buffer's
own `FB_flags`, so that for the video driver `GS_fontFlags` describes the
current font buffer: greyscale or not, with phases or not.

### 2.4 Font Buffer Format

#### 2.4.1 Flags

| Flag | Meaning |
|---|---|
| `FBF_IS_GREY` | the characters are `GreyCharData`. Never together with `FBF_IS_REGION` (EC checked) |
| `FBF_GREY_PHASES` | the characters have `GREY_PHASES` subpixel phases (2.4.3). Only together with `FBF_IS_GREY` (EC checked) |

#### 2.4.2 GreyCharData

`GreyCharData` (`Include/Internal/fontDr.def`) has the same header as
`CharData`, so that everything that only follows `CTE_dataOffset` works
unchanged:

| Field | Meaning |
|---|---|
| `GCD_pictureWidth` | width in pixels (not bits) |
| `GCD_numRows` | number of rows |
| `GCD_yoff`, `GCD_xoff` | offset of the first row and column |
| `GCD_data` | coverage data |

The data has 4 bits per pixel: the high nibble of a byte is the left
pixel, rows are padded to a byte, 0 is background and
`GREY_LEVELS - 1` (15) is full ink.

#### 2.4.3 Subpixel Phases

The video driver draws a character at its pen position rounded to a
whole pixel. The rounding error of up to half a pixel is clearly visible
at small sizes, where the gaps between letters are only 1 to 3 pixels:
letters look unevenly spaced.

With `FBF_GREY_PHASES`, a character therefore holds `GREY_PHASES` (4)
bitmaps of the glyph, one after the other, shifted by -1/2, -1/4, 0 and
+1/4 pixel relative to the rounded position (`GREY_PHASE_ZERO` = 2 is the
unshifted one). The video driver picks the phase closest to the fraction
of the pen position, so the remaining error is at most a quarter pixel.
`GCD_pictureWidth` includes one empty column on each side for the
shifts, and `GCD_xoff` is one less.

Phases cost four times the data, while the rounding matters less the
larger the letters get. The TrueType driver therefore uses them up to
`MAX_SUBPIXEL_PIXEL_HEIGHT` (24 pixels) only; larger greyscale sizes have
one unshifted bitmap and no extra columns.

Size of a greyscale character:

```
SIZE_GREY_CHAR_HEADER + phases * GCD_numRows * ((GCD_pictureWidth + 1) / 2)
phases = GREY_PHASES with FBF_GREY_PHASES, else 1
```

### 2.5 Font Buffer Size Limits

A font buffer grows as characters are built. When it would grow beyond
its limit, the least recently used characters are deleted.

The limit is a property of the font buffer and decided in one place,
`FontDrGetMaxBufSize` (`graphicsFontDriver.asm`):

| Font buffer | Limit |
|---|---|
| greyscale (`FBF_IS_GREY`), protected mode | `MAX_FONT_SIZE_GREY` (48 KB) |
| everything else, and real mode | `MAX_FONT_SIZE` (10 KB) |

48 KB leaves room below the 64 KB segment limit for the header of fonts
with many kern pairs and for the reallocation with the next character.

The size of a character's data is computed in one place as well,
`FontDrCharDataSize`, for bitmap, region and greyscale characters alike.
Both routines are exported, with C stubs (`FontDrGetMaxBufSize`,
`FontDrCharDataSize`; the C stubs expect the `FontBuf` pointer to point
to the start of its block, which is EC checked).

Users of the routines:

- the kernel: `FontDrDeleteLRUChar`, `FindLRUChar`, and the EC check
  `ECCheckFontBufAX`;
- Nimbus and Bitstream before calling `FontDrDeleteLRUChar`;
- TrueType in `ShrinkFontBuf`/`RemoveCharData`, and in the EC check of its
  glyph cache (`ECCheckCacheBufSize`, which used to assume a fixed
  13000 bytes).

`RCD_size` of a region character is the size including its header, for
all font drivers. TrueType used to store the size without the header,
which was harmless as long as it had its own LRU code, but not with the
common routines.

### 2.6 Rendering in the TrueType Driver

#### 2.6.1 When Greyscale Is Granted

`TrueType_Gen_Widths` gets the request from `GS_fontFlags` (passed in by
`truetypeWidths.asm` as `requestGrey`) and sets `FBF_IS_GREY` if:

- greyscale was requested,
- the characters are not regions (`IsRegionNeeded`), and
- `FB_pixHeight` is at most `MAX_GREY_PIXEL_HEIGHT` (96).

This includes scaled (zoom) and rotated fonts: the outline is transformed
with `TM_matrix` before it is rendered, for 1 bit and greyscale glyphs
alike. `FBF_GREY_PHASES` is set as well up to
`MAX_SUBPIXEL_PIXEL_HEIGHT` (24). The request is also recorded in the
driver-private `TransformMatrix` (`TM_greyRequest`) for the glyph cache
key in `TrueType_Gen_Chars`.

#### 2.6.2 Hinting

Greyscale glyphs are loaded without hinting by default
(`TTLOAD_SCALE_GLYPH`). The text layout uses the linear (unhinted)
advance widths, so that line breaks are the same on screen, at every zoom
level and in print. Hinting snaps a glyph's stems and edges to whole
pixels and so changes its effective width and side bearings by up to a
pixel; at small sizes that shows as uneven gaps between letters. Unhinted
glyphs keep the proportions the advance widths assume; the smoothing
makes up for the softer stems. `[truetype] greyHinting = true` hints them
like 1 bit glyphs.

#### 2.6.3 Oversampling

`RenderGreyChar` (`ttchars.c`) renders each glyph once with the 1 bit
rasterizer, scaled by `GREY_OVERSAMPLING` (4) into a 4x4 times larger
bitmap, and then counts the set subpixels of each 4x4 block: 0 to 16 set
subpixels map to coverage 0 to 15. With 4x oversampling, a quarter pixel
is exactly one oversampled column, so each subpixel phase is the same
count with the window shifted by one column; no extra rendering is
needed.

The rasterizer sizes its render pool, and its precision, by the
outline's `y_ppem`. For the oversampled outline, `y_ppem` is multiplied
by `GREY_OVERSAMPLING` while it is rendered; otherwise glyphs with many
edges (like "w") overflow the pool and come out empty. If rendering fails
anyway, `RenderGreyFallback` renders the glyph 1 bit at the real size and
uses full coverage for its pixels.

The FreeType version in the tree has no greyscale pixmap API; its own
greyscale rasterizer (`TT_CONFIG_OPTION_GRAY_SCALING`, 5 levels) is not
used.

#### 2.6.4 Glyph Cache

TrueType keeps font buffers in a cache file (`TTF_CACH.000`). The key
(`TrueTypeCacheBufSpec`) includes `TTCBS_flags`: `FBF_IS_GREY` for a
greyscale request, plus `TTCBS_GREY_HINTED` if greyscale glyphs are
hinted. The cache version is 2.4; older cache files are discarded. The
cache file is written when GEOS shuts down.

### 2.7 Drawing in the Video Driver

#### 2.7.1 Code Paths

The VGA16 character code (`vga16GenChar.asm`) has several paths. For
greyscale characters (`vga16Grey.asm`):

| Situation | Path | Greyscale handling |
|---|---|---|
| fully visible, `MM_COPY`, solid mask | `FastCharCommon` | `GreyBlit`: blend |
| clipped by the simple clip rectangle | `CLCh_CharClip` | `GreyClipChar`: blend, clipped to the rectangle |
| partially visible in a complex clip region | `CharClip` | `GreyMaskChar`: blend, clipped row by row (`WinValClipLine`), if every row lies in a null or simple clip band |
| clip band with holes, pattern, other mix modes, pointer collision | `CharClip` / `CharGeneralRealSlow` | `GreyToMono`: converted to 1 bit (coverage >= 8 is ink), drawn by the 1 bit code |

`CharGeneralSlow` draws 1 bit characters itself when the mask is solid,
so the conversion happens at `CharClip` already; `GreyToMono` recognizes
data it has converted and doesn't convert it twice.

#### 2.7.2 Blending

The screen is 16 bit (5-6-5). For each text color, `GreyEnsureTables`
computes one table per color component:

```
tab[c][d] = d + (ink - d) * c / 15       (computed as ((ink - d) * c * 273 + 2048) >> 12)
```

for coverage `c` and screen value `d`; coverage 15 gives the ink color
exactly. The tables are recomputed only when the text color changes.
Coverage 0 leaves the pixel alone, coverage 15 writes the ink color.

Blending reads the screen. Read and write window of the VESA mode may
differ, so `GreyBlit` addresses the screen with `CalcScanLineBoth` /
`NextScanBoth`: ds:di reads, es:di writes.

#### 2.7.3 Subpixel Phase

`CharLowFast` and `CharLowCheck` round the pen position to a pixel and
advance `fracPosition` to the next character before the character is
drawn. They now save the fraction of the character's own position in
`greyFrac` first. With `FBF_GREY_PHASES`, `GreyBlit` takes the fraction
as a signed byte (the shift relative to the rounded position, -1/2 to
+1/2 pixel) and picks the nearest phase. `GreyToMono` always uses the
unshifted phase.

#### 2.7.4 Building VGA16

`vga16Grey.asm` is a separate file. Its dependency is listed in
`dependencies.mk`; without it (before `pmake depend`), changes to
`vga16Grey.asm` alone didn't rebuild the driver.

### 2.8 Tests

The test application (`Appl/RstTest`) has these modes, set in the
`[rsttest]` category:

| Key | Test |
|---|---|
| `fonttest = 1` | font buffer LRU: draw a text, push the font buffer beyond its limit, draw the text again, compare both bitmaps (Nimbus and TrueType, 60 pt and 200 pt); unit test of `FontDrGetMaxBufSize` and `FontDrCharDataSize` |
| `greytest = 1` | with `forceGrey`: write greyscale glyphs from the font buffer as PGM files (`PRIVDATA`) |
| `rebuildtest = 1` | with `forceGrey`: dump characters before and after eviction and rebuild; they must be byte-identical (60 pt without, 18 pt with phases) |
| `greyview = 1` | window with greyscale text: 9 to 36 pt, color on color, a clip region with a hole, zoom, rotation, a character map, a spacing test line |
| `greyviewexit = 1` | with `greyview`: shut down cleanly 45 s after drawing (so that the glyph cache file is written) |

Results (NC and EC):

- all LRU tests and the unit test pass; greyscale characters are
  byte-identical after eviction and rebuild;
- the greyscale view renders correctly, including clipped characters at
  the view edge and around a clip hole;
- spacing of 30 identical letters ("l") at 12 pt, measured from a 1:1
  screenshot: standard deviation 0.63 pixel without subpixel phases,
  0.19 pixel with them;
- GeoWrite with TrueType text (Nimbus fonts mapped to TrueType) gets
  greyscale text.

Bitmaps are drawn by VidMem, which doesn't draw greyscale characters; with
`forceGrey`, the bitmap comparison of `fonttest` therefore doesn't apply
to greyscale fonts (`rebuildtest` compares the data instead).

### 2.9 Limitations and Open Points

- Only VGA16 draws greyscale characters. Other video drivers (VGA24,
  VGA15, VidMem) don't register and keep 1 bit characters.
- Characters that go the 1 bit way (2.7.1) are not smoothed. Once, a
  stripe pattern was seen on that path after blended drawing, which
  could not be explained; it no longer occurs on the paths that now
  blend, and not in the clip hole test.
- The limits (`MAX_GREY_PIXEL_HEIGHT`, `MAX_SUBPIXEL_PIXEL_HEIGHT`,
  `MAX_FONT_SIZE_GREY`) are chosen by reasoning and a few measurements;
  they may be tuned.
- Real-mode builds never request greyscale fonts.
