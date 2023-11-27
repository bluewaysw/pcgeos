/*
        NIMBUS.H

        by Marcus Gr�ber 1995

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
  unsigned short      ver;                    // format version (Hi=major, Lo=minor)
  unsigned short     hdrSize;                // total size of following header
  unsigned short     fontID;                 // font ID number
  unsigned short     rasterizer;             // Rasterizer ID
  char          family;                 // Font family flags
  char          name[20];               // name of font
  unsigned short     pointSizeTab;           // start of point size tables-6
  unsigned short     pointSizeEnd;           // end of point size tables-6
  unsigned short     outlineTab;             // start of outline tables-6
  unsigned short     outlineEnd;             // end of outline tables-6
} BSWFheader;

typedef struct {                /*** Entry of point size table */
  unsigned char PSE_style;              // struct TextStyle
  unsigned char PSE_pointSize[3];       // struct WBFixed
  unsigned short     PSE_dataSize;           // size of data block
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
    unsigned short NFH_h_height;
    unsigned short NFH_x_height;
    unsigned short NFH_ascender;
    unsigned short NFH_descender;
  } NFH_nimbus;
  unsigned short NFH_avgwidth;
  unsigned short NFH_maxwidth;
  unsigned short NFH_height;
  unsigned short NFH_accent;
  unsigned short NFH_ascent;
  unsigned short NFH_descent;
  unsigned short NFH_baseAdjust;
  unsigned char NFH_firstchar;
  unsigned char NFH_lastchar;
  unsigned char NFH_defaultchar;
  unsigned short NFH_underPos;
  unsigned short NFH_underThick;
  unsigned short NFH_strikePos;
  unsigned short NFH_numchars;
  short int NFH_minLSB;
  short int NFH_minTSB;
  short int NFH_maxBSB;
  short int NFH_maxRSB;
  short int NFH_continuitySize;
} NimbusNewFontHeader;

/*
 * The NimbusNewFontHeader is immediately followed by as many copies of
 * the NimbusNewWidth structure as necessary for (NFH_lastchar-NFH_firstchar+1)
 * characters:
 */
typedef struct {                /*** Width table entry */
  unsigned short NW_width;                    // unsigned character width
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
  short int ND_xmin;
  short int ND_ymin;
  short int ND_xmax;
  short int ND_ymax;
} NimbusData;

typedef struct {                /*** Pair of hinting lines */
  short int NT_start;
  short int NT_end;
  short int NT_width;
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
  short int NLD_x;
  short int NLD_y;
} NimbusLineData;

typedef struct {                /*** Args to "Bezier" opcode */
  short int NBD_x1;
  short int NBD_y1;
  short int NBD_x2;
  short int NBD_y2;
  short int NBD_x3;
  short int NBD_y3;
} NimbusBezierData;

typedef struct {                /*** Arguments to "accent" opcode */
  unsigned char NAD_char1;
  short int NAD_x;
  short int NAD_y;
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
