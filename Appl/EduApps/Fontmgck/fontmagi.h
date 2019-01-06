/***********************************************************************
 *
 * PROJECT:       FontMagick
 * FILE:          FontMagi.h
 *
 * AUTHOR:        Marcus Gr”ber
 *
 ***********************************************************************/

#define DIST_NONE      0        /* no distortion */

#define DIST_PERS_BF   1
#define DIST_PERS_AB   2

#define DIST_INFLATE   1
#define DIST_INFLATE_P 2
#define DIST_BEND      3
#define DIST_BOOK      4
#define DIST_SINE      5
#define DIST_CIRC      6

#define EFFECT_PLAIN 1
#define EFFECT_FOG 2
#define EFFECT_3D 3
#define EFFECT_SHADOW 4
#define EFFECT_DOUBLE 5
#define EFFECT_SOLID 6
#define EFFECT_OUTLINE 7

#define EFFECT_VPERS    0x0001
#define EFFECT_HPERS    0x0002
#define EFFECT_ROUND    0x0004
#define EFFECT_EMBOSSED 0x0008
#define EFFECT_OUTLSHAD 0x0010

#define OUTL_PROPS (EFFECT_ROUND | EFFECT_EMBOSSED | EFFECT_OUTLSHAD)
#define SHAD_PROPS (EFFECT_VPERS | EFFECT_HPERS)

#define N_COLITEM 9
#define COLITEM_TEXT            0
#define COLITEM_TEXT_BACK       1
#define COLITEM_OUTLINE1        2
#define COLITEM_OUTLINE2a       3
#define COLITEM_OUTLINE2b       4
#define COLITEM_SHADOW          5
#define COLITEM_SHADOW2         6
#define COLITEM_SHADOW_BACK     7
#define COLITEM_VIEW            8       /* background color of view */

#define GRID_BOTH     1
#define GRID_ONLY     2
#define GRID_CHARONLY 3

struct Distortion_struct {
  /* distortion(s) to use: */
  word distortion;              /* key of distortion to use (embedded fonts) */
  word dist_pers;               /* key of perspective distortion to use */

  /* distortion parmeters: */
  sword angle;
  word waveNumber;
  word sizeFactor,perspectiveFactor;
  word options;                 

    #define OPT_VREF            0x03    /* vertical reference line */
    #define OPT_VREF_OFFSET     0
      #define VREF_TOP          1
      #define VREF_CENTER       2
      #define VREF_BOTTOM       3
    #define OPT_BEND_UP         0x04
};


#define PROTO_MAJOR 2           // GSOL protocol level of Effect_struct
#define PROTO_MINOR 0

struct Effect_struct {
  sword type;                   /* type of effect */
  unsigned shad_thickness;      /* thickness of shadow (in point) */
  unsigned outl1_thickness;     /* thickness of inner outline (in point) */
  unsigned outl2_thickness;     /* thickness of outer outline (in point) */
  sword    xdir,ydir;           /* direction of shadow */
  struct {
    ColorQuad col;              /* color to be used */
    SystemDrawMask mask;        /* fill pattern of shadow */
  } item[N_COLITEM];
  word ShadowProperties;
};

#define MAX_TEXT 99             /* maximum text size (in characters) */

struct State_struct {
  dword magic;                  /* this should contain MAGIC_FMGK... */
  struct Effect_struct e;       /* specific effect data */
  WWFixedAsDWord size;          /* point size of font */
  FontID fid;                   /* id of font */
  TextStyle style;              /* style bits set */
  char text[MAX_TEXT+1];        /* text to be used */
  sword skew_angle;             /* skew angle (in degrees) */
  unsigned squish_ratio;        /* squish factor (in percent) */
  FontWeight fontWeight;
  FontWidth fontWidth;
  word trackKerning;
  Boolean embedFonts;           /* draw fonts via path outlines? */
  Boolean mixedColors;          /* avoid using halftone masks */
  Boolean gsolEnable;           /* create GSOL comments? */

  /* flags describing if and when to draw the grid: */
  sword drawGrid;               /* draw grid around font? */
  sword exportGrid;             /* export grid around font? */

  struct Distortion_struct dist;/* distortion settings */
};

#define MAGIC_FMGK 0x4B474D46   /* "FMGK" - added security for owner link */

extern PointDWord corner1,corner2;

void _far _pascal Font_Gen_Path(GStateHandle gstate,word ch,word flags);

void DrawGStringNonlinearTransform(GStateHandle gstate,GStateHandle gstate2,
  sword x,sword y,struct Distortion_struct *trans);

void FontInit(void);
Boolean FontRecalc(struct State_struct *eff,RectDWord *boundsEstimate);
void FontDraw(GStateHandle gstate,Boolean export);
void FontExit(void);

