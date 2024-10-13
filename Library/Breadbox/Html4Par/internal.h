/***********************************************************************
 *
 * PROJECT:       HTML3Par
 * FILE:          internal.h
 *
 * AUTHOR:    Marcus Gr�ber
 *
 * NOTES:         This file contains internal declarations used only for
 *                communications between various modules within the library.
 *
 ***********************************************************************/

#include <awatcher.h>
#include <hwlib.h>
#include "regiont.h"

#ifdef DO_DBCS
/* simple SB AnsiC versions */
#define STRCPYSB(s,t) strcpysbcs(s,t)
#define STRLENSB(s) strlensbcs(s)
#define VSPRINTFSB vsprintfsbcs
#define ATOISB(a) atoisbcs(a)
#define STRCHRSB(s,c) strchrsbcs(s,c)
#define SPRINTFSB sprintfsbcs
#define STRCATSB(s,t) strcatsbcs(s,t)
#define STRCMPSB(s,t) strcmpsbcs(s,t)
/* local SB versions */
extern sword strncmpisb(const char *str1, const char *str2, word strSize);
extern void _pascal struprsb(char *str);
#define STRCMPISB(s,t) strncmpisb(s,t,0)
#define STRUPRSB(s) struprsb(s)
#define STRNCMPISB(s,t,n) strncmpisb(s,t,n)
extern NameToken _pascal NamePoolConcatStrDOS(optr pool, NameToken tok, char *str);
#else
/* simple SB AnsiC versions */
#define STRCPYSB(s,t) strcpy(s,t)
#define STRLENSB(s) strlen(s)
#define VSPRINTFSB vsprintf
#define ATOISB(a) atoi(a)
#define STRCHRSB(s,c) strchr(s,c)
#define SPRINTFSB sprintf
#define STRCATSB(s,t) strcat(s,t)
#define STRCMPSB(s,t) strcmp(s,t)
/* local SB versions */
#define STRCMPISB(s,t) strcmpi(s,t)
#define STRUPRSB(s) strupr(s)
#define STRNCMPISB(s,t,n) LocalCmpStringsNoCase(s,t,n)
#define NamePoolConcatStrDOS(p,t,s) NamePoolConcatStr(p,t,s)
#endif

#define EXPORT _export _pascal          /* external entry into library */
#define EXPORT_CDECL _export _cdecl     /* external entry, variable args */
#define LOCAL _near _pascal             /* only used within that module */

#if defined(__WATCOM__)
void _EC_PurgeES();
#pragma aux _EC_PurgeES = "push cs" "pop es";
#define EC_PurgeES()   EC(_EC_PurgeES());

#else
#define EC_PurgeES() EC(_asm{ push cs; pop es })
#endif

/* Definitons for a "guarded" HugeArrayLock that causes an EC fatal if
 * the item doesn't exist. Use if no other error checking is performed
 * on the result of HugeArrayLock(). */
#if ERROR_CHECK
  #define HAL_EC(_hal) EC_ERROR_IF(!HAL_COUNT(_hal), -1)
#else
  #define HAL_EC(_hal) _hal
#endif

#ifdef DO_DBCS
/* something recognizable */
#define DEFCHAR '@'
#endif

typedef struct {
  optr text;
  word i;
} OPTRFILE;

extern ReadHTML_getc getcOptrURL;
#if JAVASCRIPT_SUPPORT
extern ReadHTML_getc getcScriptURL;
#endif

VMBlockHandle ChunksToVMChainBlock(VMFileHandle vmf,MemHandle heap,
  ChunkHandle *chunks,word n_chunks);
void VMChainBlockToChunks(VMFileHandle vmf,VMBlockHandle vmb,MemHandle heap,
  ChunkHandle *chunks,word n_chunks);

void VMChainifyLMemBlock(VMFileHandle vmf, VMChain vmc);

word LengthResolve(word total, HTMLmultiLength length);


/***************************************************************************
 *        Internal HTML style sheets
 ***************************************************************************/

#define CSD_FONT   0x01                 /* change font */
#define CSD_SIZE   0x02                 /* change character size */
#define CSD_COLOR  0x04                 /* change color */
#define CSD_BASE   0x08                 /* revert to a basic font (cannot be
                                           used together with CSD_FONT) */
#define CSD_EXTENDED 0x10               /* Change extended flags */
#define CSD_RESET  0x80                 /* reset everything to default */

#define CSD_BASE_PLAIN          0       /* style is based on normal text */
#define CSD_BASE_EXAMPLE        1       /* style is based on example text */

typedef struct
{
  WordFlags CSD_which;                  /* which attributes to change */
  union {
    FontID    fontID;
    word      baseStyle;
  } CSD_fontOrBase;
  sword       CSD_pointSize;            /* point size (1..7) */
  ColorQuad CSD_color;
  TextStyle CSD_textStyles;             /* style flags - added to current */
  VisTextExtendedStyles CSD_extendedStyles ;
} CharStyleDelta;

/*
 * value to be added to VTPA_spaceOnBottom for additional
 * inter-paragraph spacing:
 */
#define INTER_PARAGRAPH_SPACING (12*8)

#define PSD_MARGINS     0x01            /* change margins */
#define PSD_MARGINS_ADD 0x02            /* change margins (additive) -
                                           left and right margin contain the
                                           amount to add to current value,
                                           paraMargin contains the offset
                                           onto leftMargin */
#define PSD_JUSTIFY     0x04            /* use justification from attributes */
#define PSD_SPACING     0x08            /* change spacing above/below */
#define PSD_RESET       0x80            /* reset everything to default */

typedef struct
{
  WordFlags                 PSD_which;          /* which attributes to change */
  sword                     PSD_leftMargin,     /* margin settings or offsets */
                            PSD_rightMargin,
                            PSD_paraMargin;
  VisTextParaAttrAttributes PSD_attributes;     /* justifications/attributes
                                                   (added to current) */
} ParaStyleDelta;

/*
 * flags describing special tag properties
 */
#define TAG_PAR_SPACING         0x0001  /* blank line before/after */
#define TAG_IGNORE_TAGS         0x0004  /* ignore enclosed tags */
#define TAG_FLUSH_TEXT          0x0008  /* do not show text inside tag */
#define TAG_IMPLICIT_TERM       0x0010  /* may be terminated implicitly by a
                                           new paragraph style with the same
                                           flag (special handling for list
                                           items, definitions etc.) */
#define TAG_NO_FORMATTING       0x0020  /* do not cause visible change */

#define TAG_IS_PAR_STYLE        0x0040  /* affects paragraph style */
#define TAG_IS_CHAR_STYLE       0x0080  /* affects character style */
#define TAG_IS_BOTH             (TAG_IS_CHAR_STYLE | TAG_IS_PAR_STYLE)
/* If neither of the attributes is specified, the tag is an "empty" tag,
   meaning that no end tag is ever expected. */

#define TAG_PREPEND             0x0100  /* prepend string to start of para */
#define TAG_PREPEND_MAYBE       0x0200  /* inherit prepend from environment */

/* flags that are "inherited" by other styles embedded in them: */
#define TAG_CUMULATIVE_FLAGS (TAG_FLUSH_TEXT | TAG_IGNORE_TAGS)

/* additional flags used for communications within the parser */
#define BREAK_END_OF_CELL       0x2000  /* Ending last paragraph in a cell */
#define BREAK_LINE_BREAK        0x4000  /* insert line break, not para break */
#define BREAK_INSERT_HR         0x8000  /* insert hrule at para break */

/*
 * enumerated type describing tag types which require special handling
 */
typedef enum {
  SPEC_NONE,

  SPEC_A,
  SPEC_P,       SPEC_Hx,
  SPEC_HTML,    SPEC_HEAD,      SPEC_BODY,
  SPEC_TITLE,   SPEC_BASE,
  SPEC_HR,      SPEC_BR,        SPEC_IMG,
  SPEC_LI,      SPEC_OL,        SPEC_UL,
  SPEC_FONT,    SPEC_BASEFONT,
  SPEC_FRAME,   SPEC_FRAMESET,
  SPEC_FORM,    SPEC_INPUT,     SPEC_SELECT,      SPEC_OPTION,   SPEC_TEXTAREA,
  SPEC_TABLE,   SPEC_TR,        SPEC_TD,
  SPEC_Q,
  SPEC_CONTAIN,
  SPEC_MAP,     SPEC_AREA,
  SPEC_DIV,
  SPEC_META,
  SPEC_DL,      SPEC_DTDD,
  SPEC_MENU,
  SPEC_PRE,     SPEC_PLAINTEXT,
  SPEC_BLOCKQUOTE,
#if EMBED_SUPPORT
  SPEC_EMBED,
#endif
  SPEC_NOEMBED,
  SPEC_OBJECT,  SPEC_STYLE,
  SPEC_NOSCRIPT, SPEC_SCRIPT,
  SPEC_DONT_MATCH,
} SpecialTagType;

typedef struct {
  char name[11];
  ChunkHandle ca,pa;                    /* handles of "delta" chunks */
  SpecialTagType spec;
  word flags;
} HTMLStylesTable;

typedef struct {
  char name[7];
  unsigned int num;
  unsigned int c;
} HTMLEntityTable;

typedef struct {
    char string[5] ;
} HTMLEntityString ;

typedef struct {
  char name[22];
  ColorQuad qc;
} HTMLColorTable;

typedef struct {
    FontID FCA_font ;
    word FCA_pointSize ;
    FontID FCA_newFont ;
    word FCA_newPointSize ;
    byte FCA_fontWeight ;
    byte FCA_fontWidth ;
    sword FCA_trackKerning ;
} FontCharacterAdjustment ;

#ifdef DO_DBCS
typedef struct {
    DosCodePage cp;
    optr table;
} CodePageFontAdjEntry;

#define NUM_CODE_PAGE_FONT_ADJ_ENTRIES 6
#endif

/* Interpret the passed string and parse the applicable attributes into
   our own style structures */ 
void InterpretCSS(char *p, ParaStyleDelta *psd, CharStyleDelta *csd);

/***************************************************************************
 *        HTML and plain text import
 ***************************************************************************/

#define HTML_READBUF 1024

typedef struct {
  FileHandle fileHTML;
  byte *HTMLbuf;
  word HTMLbufp,HTMLbufl;
} HTMLFILE;

extern HTMLextra *HTMLext;
extern TextTransferBlockHeader *ttbh;
extern HypertextTransferBlockHeader *htbh;
extern MemHandle transferHeaderMem, hypertextHeaderMem;
extern optr NamePool;
extern dword textpos;

extern word            currentFlags;
extern VisTextCharAttr currentCS;
extern VisTextParaAttr currentS;
extern sword           currentBaseFont;

extern VisTextCharAttr vcaBase;

extern Boolean insertCell;
extern HTMLcellData insertCellData;

extern int c2;

/* Buffer for stored contents of TITLE, OPTION, TEXTAREA elements */
extern NameToken storedContent;

extern AllocWatcherHandle G_allocWatcher ;
extern dword G_amountAllocated ;
extern Boolean G_hitAllocLimit ;
extern Boolean G_abortParse ;
extern Boolean G_isParsing ;

VMBlockHandle InitTransferItem(void);
void FinishTransferItem(void);
dword OpenFileURL(FileHandle fh, HTMLFILE *f);
void CloseFileURL(HTMLFILE *f);

word ModifyHypertextArray(word array, void *rec, word elsize, word element);
  #define HTA_IMAGE_ARRAY       0
  #define HTA_ANCHOR_ARRAY      1
  #define HTA_FRAME_ARRAY       2
  #define HTA_FORM_ARRAY        3
  #define HTA_TABLE_ARRAY       4
  #define HTA_CELL_ARRAY        5
  #define HTA_MAP_ARRAY         6
  #define HTA_META_ARRAY        7
  #define HTA_EVENT_ARRAY       8

#define AppendToHypertextArray(array, rec) \
  ModifyHypertextArray(array, rec, 0, CA_NULL_ELEMENT);

/* Appending cells are handled differently -- we'll use a macro */
/* to do the standard optr append action, or else we'll just do */
/* a routine of our own */
#if COMPILE_OPTION_HUGE_ARRAY_CELLS
word AppendToHypertextArrayCell(HTMLcellData *p_cell) ;
#else
#define AppendToHypertextArrayCell(p_cell) \
            AppendToHypertextArray(HTA_CELL_ARRAY, p_cell)
#endif
#if COMPILE_OPTION_HUGE_ARRAY_TABLES
word AppendToHypertextArrayTable(HTMLtableData *p_table) ;
word ModifyHypertextArrayTable(HTMLtableData *p_table, word element) ;
#else
#define AppendToHypertextArrayTable(p_table) \
            AppendToHypertextArray(HTA_TABLE_ARRAY, p_table)
#define ModifyHypertextArrayTable(p_table, element) \
            ModifyHypertextArray(HTA_TABLE_ARRAY, p_table, 0, element)
#endif
word MergeIntoHypertextArrayImage(HTMLimageData *p_image) ;

void EndParagraph(char *p);
void EndLine(char *p);
void EndCell(void);
void InsertHRule(word size, VisTextParaAttrAttributes align);

void AddAttrRun(VMChain attrs, VMChain runs, void *rec, dword pos);
void ApplyCharacterDelta(VisTextCharAttr *cs,CharStyleDelta *cd);
long AddText(VisTextCharAttr *ca,char *text);
long GetTextpos(void);
Boolean AddCellRecord(void);
word GetCellLevel(void);
void AddParaCond(void);
void AddParaCondBeforeTable(void);

void GetCharacterBase(VisTextCharAttr *cs);
void GetParagraphBase(VisTextParaAttr *cs);

word EnclosingCount(SpecialTagType spec, word *top);
void GetCurrentStyles(void);
void FixupStartPos(dword pos);
void InitTagStacks(MemHandle localHeap);
void EmptyStacks(void);
void OpenTag(word tagStyle, HTMLStylesTable *tagStyleEntry, optr paramArray);
void CloseTag(word tagStyle, HTMLStylesTable *tagStyleEntry, optr paramArray);
word ICellGetNextIndex(HTMLTextInstance *pself, word cellIndex) ;

Boolean TranslateColor(char *p,ColorQuad *qc);
char *GetParamValue(optr array, char *par);
void ForceCloseStyle(SpecialTagType spec, SpecialTagType upTo);
void AddQuote(char *quoteList);
word AddFormElement(HTMLformData *fd);
word ParseHREF(optr paramArray, dword pos, WordFlags flags);
HTMLmultiLength ParseMultiLength(char *p, word n);
Boolean ParseBGCOLOR(optr paramArray, ByteFlags *cellFlags, ColorQuad *qc);
Boolean ParseVALIGN(optr paramArray, ByteFlags *cellFlags);
Boolean ParseALIGN(optr paramArray, VisTextParaAttrAttributes *vtpaa);
void ParseEvents(optr paramArray, HTMLEventObjectType type, word obj);

word FindRegionAtPosition(T_regionArrayHandle regionArray, dword pos) ;

#ifdef DO_DBCS
void ConvertGeosCharEntities(TCHAR *str, word *len);
#endif


/***************************************************************************
 *        Handlers for dealing with opening/closing specific tags
 ***************************************************************************/

typedef struct {
  word           style;
  Boolean        noterm;
  word           count;
  Boolean        linebr;
  SpecialTagType spec;
  word           flags;
  dword          startPos;
  ParaStyleDelta delta;
  CharStyleDelta charDelta;
  optr           param;
} TagStackElement;

typedef struct {
  SpecialTagType spec;
  optr paramArray;
  TagStackElement *tagStack;
  CharStyleDelta ca;
  ParaStyleDelta pa;
  Boolean preserveParams;
  word countStart;
  word flags;
} TagOpenArguments;

typedef void _pascal TagOpenHandler(TagOpenArguments *arg);

typedef struct {
  SpecialTagType spec;
  TagOpenHandler *proc;
} OpenHandlerEntry;

typedef void _pascal pcfm_TagOpenHandler(TagOpenArguments *arg, void *pf);

extern OpenHandlerEntry OpenHandlers[];


/***************************************************************************
 *        Global limitations
 ***************************************************************************/

#define TABLE_MAX_COLUMNS            250
#define TABLE_MAX_USED_COLUMNS       32
typedef byte T_columnIndex ;            /* Type value for accessing columns in index arrays */
                                        /* Change to word if TABLE_MAX_COLUMNS goes over 255 */
#define TABLE_COLUMN_INDEX_BAD       ((T_columnIndex)-1)

#define HTML_MAXTAG       20            /* maximum tag size */
#define HTML_MAXSTACK     40            /* maximum # of tag nesting levels */
#define HTML_MAXTABLE     16            /* maximum # of table nesting levels */
#define HTML_MAXPOLYCOORD 32            /* maximum # of coords in map POLY */

/* When we limit the number of cells, we are also limiting the number of regions. */
#if COMPILE_OPTION_HUGE_ARRAY_CELLS && COMPILE_OPTION_HUGE_ARRAY_REGIONS
#define DEFAULT_CELL_LIMIT 50000        /* no real limit */
#else
#  if COMPILE_OPTION_HUGE_ARRAY_CELLS
#    define DEFAULT_CELL_LIMIT 500      /* If huge array of cells, we can handle more regions */
#  else
#    define DEFAULT_CELL_LIMIT 250
#  endif
#endif
#define DEFAULT_IMAGE_LIMIT 200

#define MIN_LIST_WIDTH    10            /* minimumum width of form entry lists
                                           (in characters) */

#define MAX_STORED_CONTENT 8192

/***************************************************************************
 *        Table limits
 ***************************************************************************/

#define MAX_GROW_TRIES        3
#define DEFAULT_START_WIDTH   600

#define REGION_MINIMUM_WIDTH  3
#define MINIMUM_COLUMN_WIDTH  1
#define INITIAL_COLUMN_WIDTH  600
#define MAXIMUM_COLUMN_WIDTH  2000
#define REASONABLE_COLUMN_WIDTH  16
#define MAX_REGION_HEIGHT     20000
#define COLUMN_WIDTH_WHEN_PAST_MAX_TABLE_COLUMNS   32  /* Note, faster if power of two */

#define DEFAULT_TABLE_CELLSPACING       2
#define DEFAULT_TABLE_CELLPADDING       1


/***************************************************************************
 *        Spread Table calculation
 ***************************************************************************/

MemHandle SpreadCreate(word numColumns, word interspacing, word availableWidth) ;
void SpreadDestroy(MemHandle spread) ;
void SpreadAdd(
         MemHandle state,
         word fromLeft,
         word toRight,
         sword pixels,
         sword percent,
         sword desiredWidth,
         sword hardMinWidth) ;
word SpreadCalculateLayout(MemHandle state, word totalWidth, word wantedWidth) ;
word SpreadGetColumnWidth(MemHandle state, word column) ;
void SpreadMarkColumnUsed(MemHandle state, word column) ;
void SpreadCopyIndexArray(MemHandle state, T_columnIndex *p_indexArray) ;

#define ESTIMATED_SCROLL_BAR_WIDTH 18

/***************************************************************************
 *        Form related constants
 ***************************************************************************/

#define FORM_SIZE_SELECT_EDGE 3

/***************************************************************************
 *        Image related constants and routines
 ***************************************************************************/

/* The following 'fudge' factor is used to declared to trick the system */
/* into thinking it has an image that is one (or more) pixels shorter than */
/* it is so that the bitmap is drawn one pixel lower causing it to properly */
/* sit lower.  This avoids lines between graphics placed vertically. */
#define IMAGE_HEIGHT_FUDGE_FACTOR   1

void DrawVarGraphic(GStateHandle gstate, HTMLimageData *iae, optr namePool,
                    word invalFrom, word invalTo);

/***************************************************************************
 *              Structures describing tag stacks used during parsing
 ***************************************************************************/

typedef struct {
  /* element index of this table in table array */
  word element;

  /* current position within table */
  word currentRow;
  byte currentCol;

  /* Last column with span consideration */
  byte lastCol ;         

  /* global attributes specified in cell header */
  HTMLtableData tableData;
  HTMLcellData lastCellData;

  ByteFlags cellFlagMask;               /* set bits specify cell defaults */
  ByteFlags cellFlagValue;              /* cell flag defaults if mask bit set */
  ColorQuad rowBackColor;               /* HCD_backColor default, if any */

  struct {
    byte remainingRowSpan;              /* count down for row spans */
  } col[TABLE_MAX_COLUMNS];

  ByteFlags flags ;
  #define TABLE_STACK_HAS_RECEIVED_TR_TAG  0x80
} TableStackElement;

/***************************************************************************
 *              Other constants
 ***************************************************************************/

#ifdef DO_DBCS
#define HTML_SPECIAL_ENTITY_BASE   0xee00  /* must use Unicode user area */
#else
#define HTML_SPECIAL_ENTITY_BASE   10000
#endif
#define HTML_TEXT_REGION_HIDDEN_Y  0x4000000

#define PROGRESSIVE_FORMATTING_MINIMUM_UPDATE_HEIGHT 500

#define HTML_BODY_TAG_DEFAULT_LEFT_MARGIN   7
#define HTML_BODY_TAG_DEFAULT_TOP_MARGIN    4

#define DEFAULT_IMAGE_HEIGHT  20
#define DEFAULT_IMAGE_WIDTH 20

#define PARSE_ABORT_TIMEOUT  (3*60)

