## 4 Font Driver

AUTHOR:	Gene Anderson (01/21/91)

This document describes the interface and interactions of font drivers in
PC/GEOS.

### 4.1 Overview

In PC/GEOS, outline font drivers play a vital role in the
WYSIWYG rendering engine.  They are called to generate the metrics for
a font at any pointsize, rotation or scale factor that a program may
request, making this information transparently available.  When the
font is actually drawn to the screen (or to memory for printing), the
font drivers are called to generate bitmaps for the actual images of
the characters.

A program will normally specify a particular typeface
(FontIDs) and pointsize (WBFixed) using GrSetFont().  Additional
styles (TextStyles) may be specified using GrSetTextStyle().  Some
programs, such as GeoDraw, may also specify an angle of rotation using
GrApplyRotation() or scale factor using GrApplyScale().  Beyond this,
the system may specify an angle of rotation and scale factor for
printing or rendering to a different device, using window routines
similar to the graphics transformation routines above.  All these
elements combine to specify a unique 'font' to the system.

A typeface is referred to by a 16-bit ID (FontIDs).  Part of
the PC/GEOS kernel is a Font Manager, and it tracks the requests and
usage of fonts in the system via these IDs and other font attributes.
It maintains an array of structures (FontsAvailEntry) for each font in
the system that is used to let programs know which fonts are available
to it, and is usually used to generate the "Fonts" menu that programs
display.  Each of these entries has a corresponding chunk of data
(FontInfo), which specifies more information about the typeface, such
as the ASCII name, and which styles are available as direct outlines.

When a routine needs a particular piece of font information,
it asks the Font Manager to get the font in question.  This may be
accomplished simply if the font has a hand-tuned bitmap that is
appropriate.  If no bitmap exists, however, the font driver will be
called to create the appropriate font using the driver function
DR_FONT_GEN_WIDTHS.  The font that is created includes almost all
metrics information, and references to each character in the font
indicating whether it exists or not, and whether a bitmap for it has
been built.

When the video driver renders text on screen, it checks to see
if a bitmap for the character it is about to draw exists or not.  If
not, it asks the Font Manager to get a bitmap for the character.  The
Font Manager in turn calls the appropriate font driver and requests
the bitmap using the function DR_FONT_GEN_CHAR.

This process goes on as the system runs.  Eventually, the font
may be unused for such a time period as to cause the data block to be
discarded by the Heap Manager.  If the font is requested again, the
Font Manager will call the font driver with DR_FONT_GEN_WIDTHS, and
the whole process starts over.

In addition to the process of requesting font metrics and
corresponding character bitmaps, programs may request metrics about a
particular character in which case the Font Manager calls the font
driver with DR_FONT_CHAR_METRICS.  Alternatively, a program may
request the outline data for a particular character, in which case the
font driver is called with DR_FONT_GEN_PATH.

There are also a number of initialization routines that the
font driver must support.  These are used to start and stop the font
driver, as well as give it a chance to initialize any of its own
fonts.

Finally, there are a number of driver 'escape functions',
which the font driver may choose to support or not, as is appropriate.
These include functions such as adding or deleting a font from the
system.

### 4.2 Initialization Routines

*DR_INIT*

DR_INIT is called for all drivers.  This should be used to
initialize any necessary data structures and memory.  However, care
should be taken to keep memory usage at this stage at an absolute
minimum as the driver may never get called again during this session.

For example, the Nimbus driver allocates handles for a variety
of blocks it uses (one for variables, one for the generated bitmap),
but without allocating the associated memory (ie. HF_DISCARDED).  They
are also marked as discardable (ie. HF_DISCARDABLE), so the first
attempt at using them forces them to be 'reallocated'.  This way, no
additional memory is used until a Nimbus font is requested, and only
two handles are used.  If the Nimbus driver is unused for a long
period of time, these blocks may eventually be discarded as well.


*DR_EXIT*

DR_EXIT is also called for all drivers, and is the counterpart
of DR_INIT.  This function should clean up any memory or resources
that have been allocated by the driver, generally things that were
allocated in DR_INIT.


*DR_FONT_INIT_FONTS*

DR_FONT_INIT_FONTS is intended to allow the font driver to
inform the system of any additional fonts it may have.  The PC/GEOS
kernel searches the disk for any fonts in it's format, but by
definition most font drivers will be dealing with non-PC/GEOS fonts.

To add a font to the system, two structures must be modified
or created.  Both of these structures reside in the font manager's
information block, which is passed to the various font driver
functions.

First, a FontsAvailEntry must be added, which specifies to the
system that this particular FontIDs value is available, and where
additional information about the font is stored.

The additional information is a separate chunk in the font
manager's block.  It consists of a FontInfo structure, followed by as
many PointSizeEntry structures (for bitmap fonts) and OutlineDataEntry
structures (for outline fonts) as is appropriate.

"As many is appropriate" for bitmap fonts constitutes one
PointSizeEntry for each pointsize/style/weight combination.  If there
are no bitmaps for the FontIDs value in question, FI_pointSizeTab is
zero (0) and there are no PointSizeEntry structures.

"As many is appropriate" for outline fonts constitutes one
OutlineDataEntry for each style/weight combination (note this does not
include pointsize, as that is irrelevant for outline fonts).  If there
are no outlines for the FontIDs value in question, FI_outlineTab is
zero (0) and there are no OutlineDataEntry structures.

### 4.3 Data Routines

*DR_FONT_GEN_WIDTHS*

DR_FONT_GEN_WIDTHS is called to generate the metrics and basic
information for one font.  In PC/GEOS, a different font is constituted
by:
* typeface (FontIDs)
* pointsize (WBFixed)
* style (TextStyle)
* weight (FontWeight)
* width (FontWidth)
* transformation (TMatrix)

What the system expects back from this routine is a buffer
containing the following:

        FontBuf - font header and metrics information
                +
        CharTableEntry #1
        CharTableEntry #2
                [...]
        CharTableEntry #n
                +
        [optional cached data]
                +
        [optional KernPair[1..m]]
        [optional BBFixed[1..m]]

Each CharTableEntry contains the pen width of the character,
flags about the size and shape of the character, and the offset to the
actual bitmap data for the character if it is built (or a flag
indicating it hasn't yet been built).

Given this structure, the system will call the font driver
back for each character when it is needed, via the DR_FONT_GEN_CHAR
routine.

The kerning information is a pair of matched tables.
FB_kernCount contains the number of kerning pairs.  FB_kernPairPtr
points to an array of KernPair structures, which are left char / right
char combinations that specify each kerning pair.  FB_kernValuePtr
points to an array of BBFixed structures, which are signed values
specifying the adjustment for the corresponding character pair.  Negative
values mean move the characters closer; positive values mean move them
further apart.

A note about DR_FONT_GEN_WIDTHS: outlines for all styles and
all style combinations are generally not available.  Underline and
strikethrough are rendered by the kernel, and so need not be worried
about.  Some fonts have plain, bold, italic, and bold-italic
available.  Others, however simply have plain version available.  In
the best case, this leaves superscript and subscript or any
combination involving them unaccounted for.  In the worst case, this
may leave every combination of TextStyles except plain unaccounted for!

In the case a direct outline is not available, the font driver
is expected to "do its best".  This involves tricks like scaling and
translating for superscript and subscript, and obliquing for creating
italic.  To this end, a kernel routine (XXX: not yet written) is
provided for finding the largest subset of styles available from which
to generate the font.  For example, if a program requests 'Bold
Superscript', and 'Plain' and 'Bold' outlines are available, the best
thing to do is to select the 'Bold' outline and scale and translate it
to simulate the 'Superscript' attribute.

The "optional cached data" is just that: data that the font
driver may choose to store in the font.  There is no explicit
reference to this data, but it can quickly be found by adding the size
of the FontBuf plus the appropriate number of CharTableEntry
structures.  This data should be reasonable small, and is intended for
things that cannot be quickly computed.  For example, the Nimbus
driver stores the final transformation matrix (including any
transformations for simulated styles), several default hints for the
font, and a reference to which set of routines will be used for
rasterizing the bitmap or region data.


*DR_FONT_GEN_CHAR*

DR_FONT_GEN_CHAR is called to generate the bitmap for a single
character.  The resulting data should be added to the FontBuf block
returned by DR_FONT_GEN_WIDTHS after it has been resized
appropriately.  The system supports two varieties of character data,
one simple and the other compacted.

The first format is simple bitmap data, comprised of a header
(CharData) containing the bounds and offset of the bitmap (in device
coordinates) for where it should drawn relative to the top of the
nominal font box.

This is followed by the data bytes.  The data should be
byte-padded, and the in the data, ones are 'on' and zeroes are 'off'.

Shown below is an example of the letter 'i':

        byte    6               ;width (CD_pictureWidth)
        byte    10              ;height (CD_numRows)
        byte    3               ;y offset (CD_yoff)
        byte    2               ;x offset (CD_xoff)
        byte    00110000b       ;(CD_data)
        byte    00110000b
        byte    00000000b
        byte    11110000b
        byte    00110000b
        byte    00110000b
        byte    00110000b
        byte    00110000b
        byte    00110000b
        byte    11111100b

        (0,0)
        |
        |
        |
        +--* (2,3)
             (CD_xoff, CD_yoff)
           +----------+
           |    ##    |
           |    ##    |
           |          |
           |  ####    |
           |    ##    |
           |    ##    |
           |    ##    |
           |    ##    |
           |    ##    |
           |  ######  |
           +----------+

The second format is storing the character as a region.  This
amounts to a scanline compression format, and works quite well for
characters at 0, 90, 180 and 270 degree rotations.  It works
reasonably well for characters at an arbitrary angle of rotation, and
less well for characters that are highly angled to begin with, such as
in a script font like Shattuck Avenue.  The cutoff point between
storing characters as bitmaps and as regions is 125 lines high (eg.
125 point at 72 DPI, 30 point at 300 DPI, etc.)

There is a header (RegionCharData) similar to the header for
bitmap characters.  There are two additional pieces of information:
the size of the data for the region (in bytes), and the full bounds of
the region data, which are used for drawing the region.

More details about the region format can be found in the
documentation about the graphics system.

A note about DR_FONT_GEN_CHAR: characters are requested on an
as-needed basis.  The means the font will start with the
FontBuf+CharTableEntry+KernPair+BBFixed information in the block.  As
characters are added, the font driver will be adding data to this
block.  Eventually, the block may get large enough that adding another
character would push the size over 64K, which on the 80x86
architecture, is known as a bad thing.  Rather than wait until the
block has gotten close to 64K, the Font Manager attempts to keep
individual FontBuf blocks below 10K in size.  This may not be possible
at very large pointsizes, but is a general goal of the system to
improve performance.

To this end, the font driver should use information which is
maintained in the CharTableEntry for each character and the FontBuf.
FB_heapCount is the current usage counter for the font.  CTE_usage is
the current usage counter for that character.  Given these values, it
is possible to determine which character was the "least recently
used", or LRU.  A fine heuristic for discarding characters is to
delete this LRU character, thereby freeing up space for additional
character(s) in the FontBuf block.  A kernel routine (XXX: not
written) is provided to do this.

After DR_FONT_GEN_WIDTHS is called, then DR_FONT_GEN_CHAR
is called several times, the results will be something like what is
below.  The FontBuf block will have been expanded to include the
character bitmap/region data, although because of the LRU caching
scheme, the characters may not be in any particular order.

        FontBuf - font header and metrics information
                +
        CharTableEntry #1
        CharTableEntry #2
                [...]
        CharTableEntry #n
                +
        [optional cached data]
                +
        [optional KernPair[1..m]]
        [optional BBFixed[1..m]]
                +
        Region/CharData #a
        Region/CharData #b
                [...]
        Region/CharData #c

### 4.4 Metrics Routines

*DR_FONT_CHAR_METRICS*

DR_FONT_CHAR_METRICS is called to return metrics information
about a particular character in a font.  The information is in
document coordinates, which is to say it is not affected by scaling,
rotation, etc. that modifies the way the document is viewed, but
simply by the pointsize and font attributes requested.

There are currently four pieces of information returned: min
x, min y, max x and max y.  These values are relative to (0,0) at the
baseline/starting pen position:

      (xmin,ymax)      (xmax,ymax)
                +------+
                |    ##|
                |    ##|
                |      |
                |  ####|
                |    ##|
                |    ##|
                |    ##|
                |    ##|
                |    ##|
                |    ##|
           (0,0)+----##+
                |    ##|
                |   ###|
                |####  |
                +------+
      (xmin,ymin)      (xmax,ymin)

Note that any of the values can be negative.  Normally, the
data will be returned as a WBFixed, but there is an optional flag
which may be passed, indicating the data should be rounded and
returned as a word.


*DR_FONT_GEN_PATH*

DR_FONT_GEN_PATH is called to return an outline description of
a character at a particular pointsize, rotation, etc.  It is used by
things like the Postscript(tm) printer driver for building Adobe Type
3 fonts to download to printers when the font is not resident in the
printer.  For example, Shattuck Avenue (aka Park Avenue) is generally
not in Postscript printers, and so a Type 3 font would be built and
downloaded for it.

This outline description should be comprised of lines, Bezier
curves, pen moves, and in some cases, a translation.  Composite
characters, such as accented letters, can be rendered by rendering the
accent character, translating, and then rendering the unaccented
letter.

The use for generating Postscript fonts is strong enough that
there is a special FGPF_POSTSCRIPT flag which can be passed to the
function.  The font driver is expected to rotate and scale the
outlines such that (0,0) is the baseline/starting pen position, and
the data is sized for a 1000 unit em-square.

If the FGPF_POSTSCRIPT flag is passed, the font driver is also
expected to emit a comment at the start of the graphics string which
contains information for the Postscript "setcachedevice" command.
This information is the pen width and bounding box information, in the
order: width(x),width(y),ll(x),ll(y),ur(x),ur(y).


*DR_FONT_GEN_IN_REGION*

DR_FONT_GEN_IN_REGION is called to add the definition of a
character to a passed RegionPath. It is used by the graphics path code
for filling and/or creating clip paths that contain text strings &
characters.

The outline description of a font is normally comprised of
lines, Bezier curves & pen moves. At large point sizes (for the
Nimbus font driver, above 500 points), this data is "played" into a
RegionPath, and then handed to the video driver which draws the region
on the screen. For paths, characters are always generated using regions,
regardless of point size, and use this routine as the method for
incorporating text into a path.

An implementation of this call should be careful to include
the transformations contained in both the GState & Window (ie. use the
W_curTMatrix) for generating the font, and the font must be carefully
drawn into the correct location (GS_penPos in the GState) in the
RegionPath, rather than the origin (as the large character generation
code might normally do). Finally, one may not assume that this will
be the only routine called to add data to the RegionPath, so the
integrity of RegionPath data must be ensured.


### 4.5 Debugging Tips

To assist in debugging font drivers and their interaction with
the Font Manager, there are a number of useful TCL commands available:

* fonts - print various items about fonts and font drivers in the system
* pfontinfo - print the FontInfo structure for a font
* pfont - print the FontBuf structure for a font and any bitmaps that
        have been built for it
* pchar - print the bitmap for a character in a font, if it has been
        built
* pusage - print the usage values for all characters that have been
        built, and which of them will be discarded next


A typical series of commands might be something like:

    (geos:0) 1 => fonts -d                      ;show the available font drivers
    (geos:0) 2 => fonts -a                      ;show the available fonts
    (geos:0) 3 => pfontinfo FONT_URW_ROMAN      ;show FontInfo for URW Roman

        <...call GEN_WIDTHS here...>            ;now we've got a FontBuf...

    (geos:0) 4 => fonts -u FONT_URW_ROMAN       ;show sizes of URW Roman in use
    (geos:0) 5 => pfont ^h1ab0h                 ;print the FontBuf for a font

        <...call GEN_CHAR here...>              ;now we've got a bitmap...

     (geos:0) 6 => pchar C_CAP_A ^h1ab0h        ;print the bitmap for 'A'

        <...call GEN_CHAR here...>              ;now we've got two bitmaps...

     (geos:0) 7 => pusage ^h1ab0h               ;print the LRU information
