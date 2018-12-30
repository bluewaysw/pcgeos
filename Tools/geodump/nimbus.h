/*
        NIMBUS.H

        by Marcus Gr”ber 1995

        Include file for PC/Geos font file format

        Most of the following structures were decoded from the SDK's
        nimbus.sym and geos.sym files using the printobj utility.
*/

#if !defined(_NIMBUS_H)
#define _NIMBUS_H

#pragma pack(1)

/******************************************************************************
 *                        GEOS font files (BSWF files)                        *
 ******************************************************************************/
#define BSWF_ID 0x46575342              // identification "magic" for BSWF

typedef struct {                /*** Common font file header */
  long          ID;                     // identification "magic" (signature)
  unsigned      ver;                    // format version (Hi=major, Lo=minor)
  unsigned      hdrSize;                // total size of following header
  unsigned      fontID;                 // font ID number
  unsigned      rasterizer;             // Rasterizer ID
  char          family;                 // Font family flags
  char          name[20];               // name of font
  unsigned      pointSizeTab;           // start of point size tables-6
  unsigned      pointSizeEnd;           // end of point size tables-6
  unsigned      outlineTab;             // start of outline tables-6
  unsigned      outlineEnd;             // end of outline tables-6
} BSWFheader;

typedef struct {                /*** Entry of point size table */
  unsigned char PSE_style;              // struct TextStyle
  unsigned char PSE_pointSize[3];       // struct WBFixed
  unsigned      PSE_dataSize;           // size of data block
  long          PSE_filePos;            // position of data block
} my_PointSizeEntry;

typedef struct {                /*** Entry of outline data table */
  unsigned char ODE_style;              // struct TextStyle
  unsigned char ODE_weight;             // struct FontWeight
  long ODE_headerPos, ODE_headerSize;   // position and size of NimbusFontHeader
  long ODE_firstPos, ODE_firstSize;     // position and size of 32..127 chars
  long ODE_secondPos, ODE_secondSize;   // position and size of 128..255 chars
} my_OutlineDataEntry;


/******************************************************************************
 *                            Nimbus-Q font files                             *
 ******************************************************************************/
typedef struct {                /*** Header for a specific typeface */
  struct NimbusFontHeader {
    unsigned NFH_h_height;
    unsigned NFH_x_height;
    unsigned NFH_ascender;
    unsigned NFH_descender;
  } NFH_nimbus;
  unsigned NFH_avgwidth;
  unsigned NFH_maxwidth;
  unsigned NFH_height;
  unsigned NFH_accent;
  unsigned NFH_ascent;
  unsigned NFH_descent;
  unsigned NFH_baseAdjust;
  unsigned char NFH_firstchar;
  unsigned char NFH_lastchar;
  unsigned char NFH_defaultchar;
  unsigned NFH_underPos;
  unsigned NFH_underThick;
  unsigned NFH_strikePos;
  unsigned NFH_numchars;
  int NFH_minLSB;
  int NFH_minTSB;
  int NFH_maxBSB;
  int NFH_maxRSB;
  int NFH_continuitySize;
} NimbusNewFontHeader;

/*
 * The NimbusNewFontHeader is immediately followed by as many copies of
 * the NimbusNewWidth structure as necessary for (NFH_lastchar-NFH_firstchar+1)
 * characters:
 */
typedef struct {                /*** Width table entry */
  unsigned NW_width;                    // unsigned character width
  unsigned char NW_flags;               // struct unsigned charTableFlags
} NimbusNewWidth;

/* byte flags type charTableFlags: attributes of individual characters */
#define CTF_NEGATIVE_LSB   0x40
#define CTF_ABOVE_ASCENT   0x20
#define CTF_BELOW_DESCENT  0x10
#define CTF_NO_DATA        0x08
// The following two flags mark characters for which kerning information
// is available. FIRST_KERN means that the character appears as "left"
// partner in a kern pair, while SECOND_KERN means it appears one the
// "right" side. Note the reversed order of "left" and "right" chracter
// in the kern pair table!
#define CTF_IS_FIRST_KERN  0x04
#define CTF_IS_SECOND_KERN 0x02
#define CTF_NOT_VISIBLE    0x01

typedef struct {                /*** Header for individual character */
  int ND_xmin;
  int ND_ymin;
  int ND_xmax;
  int ND_ymax;
} NimbusData;

typedef struct {                /*** Pair of hinting lines */
  int NT_start;
  int NT_end;
  int NT_width;
} NimbusTuple;

/* enumerated type "NimbusCommands" (byte): opcodes in character description */
#define NIMBUS_REL_CURVE 9
#define NIMBUS_REL_LINE  8
#define NIMBUS_HORZ_LINE 7
#define NIMBUS_VERT_LINE 6
#define NIMBUS_ACCENT    5
#define NIMBUS_ILLEGAL   4
#define NIMBUS_DONE      3
#define NIMBUS_BEZIER    2
#define NIMBUS_LINE      1
#define NIMBUS_MOVE      0

typedef struct {                /*** Args to "move"/"line" opcode */
  int NLD_x;
  int NLD_y;
} NimbusLineData;

typedef struct {                /*** Args to "Bezier" opcode */
  int NBD_x1;
  int NBD_y1;
  int NBD_x2;
  int NBD_y2;
  int NBD_x3;
  int NBD_y3;
} NimbusBezierData;

typedef struct {                /*** Arguments to "accent" opcode */
  unsigned char NAD_char1;
  int NAD_x;
  int NAD_y;
  unsigned char NAD_char2;
} NimbusAccentData;

typedef struct {                /*** Arguments to "Rel Line" opcode */
  char NRLD_y;
  char NRLD_x;
} NimbusRelLineData;

typedef struct {                /*** Arguments to "Rel Bezier" opcode */
  char NRBD_x1;
  char NRBD_y1;
  char NRBD_x2;
  char NRBD_y2;
  char NRBD_x3;
  char NRBD_y3;
} NimbusRelBezierData;

#pragma pack()

#endif
