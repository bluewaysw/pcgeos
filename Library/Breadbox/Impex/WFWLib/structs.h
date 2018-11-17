/****************************************************************************
 *
 * ==CONFIDENTIAL INFORMATION== 
 * COPYRIGHT 1994-2000 BREADBOX COMPUTER COMPANY --
 * ALL RIGHTS RESERVED  --
 * THE FOLLOWING CONFIDENTIAL INFORMATION IS BEING DISCLOSED TO YOU UNDER A
 * NON-DISCLOSURE AGREEMENT AND MAY NOT BE DISCLOSED OR FORWARDED BY THE
 * RECIPIENT TO ANY OTHER PERSON OR ENTITY NOT COVERED BY THE SAME
 * NON-DISCLOSURE AGREEMENT COVERING THE RECIPIENT. USE OF THE FOLLOWING
 * CONFIDENTIAL INFORMATION IS RESTRICTED TO THE TERMS OF THE NON-DISCLOSURE
 * AGREEMENT.
 *
 * Project: Word For Windows Core Library
 * File:    structs.h
 *
 ***************************************************************************/

#ifndef __STRUCTS_H
#define __STRUCTS_H

/********************* Structures common to all formats **********************/

typedef unsigned char uchar;
typedef unsigned short ushort;
typedef unsigned int uint;
typedef unsigned long ulong;
typedef uint BF;
typedef long FC;
typedef long CP;
typedef long PN;
typedef ushort LID;
typedef ulong DTTM;
typedef wchar XCHAR;
typedef word FTC;

#define FC_MAX  0x0FFFFFFFL
#define FC_NIL  0xFFFFFFFFL

#define CP_TO_FC(fcStart,cpStart,cp,bDbl) ( (fcStart) + ((cp) - (cpStart)) * ((bDbl) ? 2 : 1) )

#define PN_TO_FC(pn) ((pn) << 9)

#define FKP_SIZE 512
#define FKP_CRUN (FKP_SIZE - sizeof(byte))

/* Compute a PLCF's byte length. */
#define PLCF_SIZE(iMac,cbStruct) ((iMac)*(4+(cbStruct))+4)

/* Structure used in the FIB FC/LCB pair array. */
typedef struct {
    long    fc;
    ulong   lcb;
} FIBFCLCB;

/* Property Modifier (variant 1) */
typedef struct {
    BF      fComplex : 1;   /* clear indicates this variety */
    BF      isprm : 7;
    BF      val : 8;
} PRM_1;

/* Property Modifier (variant 2) */
typedef struct {
    BF      fComplex : 1;   /* set indicates this variety */
    BF      igrpprl : 15;
} PRM_2;

typedef union {
    PRM_1   prm_1;
    PRM_2   prm_2;
} PRM;

#define PRM_TO_WORD(s) ( *(word *)(&(s)) )

/* Piece Descriptor */
typedef struct {
    BF      fNoParaLast : 1;
    BF      fPaphNil : 1;
    BF      fCopied : 1;
    BF      fUnused : 5;
    BF      fn : 8;
    FC      fc;
    PRM     prm;
} PCD;

/* This flag set in pcd.fc indicates the text for this piece is encoded as
   codepage-1252 single-byte chars instead of Unicode, and the real FC is
   (pcd.fc >> 1). */
#define PCD_FC_VIRTUAL  0x40000000UL

#define clxtGrpprl  1
#define clxtPlcfpcd 2

/* Line Spacing Descriptor */
typedef struct {
    short   dyaLine;
    short   fMultLinespace;
} LSPD;

/* Drop Cap Specifier */
typedef struct {
    BF      fdct : 3;
    BF      cLines : 5;
    byte    bRsv1;
} DCS;

/* Portion of File Information Block used to identify the file's format.
   The struct starts at byte 0 of the document stream. */
typedef struct {
    ushort  wIdent;                 // magic number
    ushort  nFib;                   // FIB version written. This will be >= 101
                                    // for all Word 6.0 for Windows and after
                                    // documents.
} FIB_HEADER_VERSION;

#define TWIPS_TO_POINTS(a) ( IntegerOf(GrSDivWWFixed(MakeWWFixed(a), MakeWWFixed(20))) )
#define TWIPS_TO_133(da) ( (word)(GrSDivWWFixed(MakeWWFixed(da), MakeWWFixed(20)) >> 13) )

/************************ Structures for Word 6.0/7.0 ************************/

/************************** Structures for Word 8.0 **************************/

/******** Border Code ********/
typedef struct {
    BF      dptLineWidth : 8;
    BF      brcType : 8;
    BF      ico : 8;
    BF      dptSpace : 5;
    BF      fShadow : 1;
    BF      fFrame : 1;
} BRC;

/******** Shading Descriptor ********/
typedef struct {
    BF      icoFore : 5;
    BF      icoBack : 5;
    BF      ipat : 6;
} SHD;
    
/******** Character Properties ********/
typedef struct {
    BF      fBold : 1;
    BF      fItalic : 1;
    BF      fRMarkDel : 1;
    BF      fOutline : 1;
    BF      fFldVanish : 1;
    BF      fSmallCaps : 1;
    BF      fCaps : 1;
    BF      fVanish : 1;
    BF      fRMark : 1;
    BF      fSpec : 1;
    BF      fStrike : 1;
    BF      fObj : 1;
    BF      fShadow : 1;
    BF      fLowerCase : 1;
    BF      fData : 1;
    BF      fOle2 : 1;
    BF      fEmboss : 1;
    BF      fImprint : 1;
    BF      fDStrike : 1;
    BF      fUsePgsuSettings : 1;
    BF      : 12;
    long    lRsv4;
    short   ftc;
    short   ftcAscii;
    short   ftcFE;
    short   ftcOther;
    ushort  hps;
    long    dxaSpace;
    BF      iss : 3;
    BF      kul : 4;
    BF      fSpecSymbol : 1;
    BF      ico : 5;
    BF      : 1;
    BF      fSysVanish : 1;
    short   hpsPos;
    LID     lid;
    LID     lidDefault;
    LID     lidFE;
    uchar   idct;
    uchar   idctHint;
    ushort  wCharScale;
    FC      fcPic;
    FC      fcObj;
    ulong   lTagObj;
    short   ibstRMark;
    short   ibstRMarkDel;
    DTTM    dttmRMark;
    DTTM    dttmRMarkDel;
    short   sRsv52;
    ushort  istd;
    short   ftcSym;
    XCHAR   xchSym;
    short   idslRMReason;
    short   idslReasonDel;
    uchar   ysr;
    uchar   chYsr;
    ushort  chse;
    ushort  hpsKern;
    BF      icoHighlight : 5;
    BF      fHighlight : 1;
    BF      kcd : 3;
    BF      fNavHighlight : 1;
    BF      fChsDiff : 1;
    BF      fMacChs : 1;
    BF      fFtcAsciSym : 1;
    ushort  fPropMark;
    short   ibstPropRMark;
    DTTM    dttmPropRMark;
    uchar   sfxtText;
    uchar   cRsv81;
    uchar   cRsv82;
    ushort  sRsv83;
    short   sRsv85;
    DTTM    dttmRsv87;
    byte    fDispFldRMark;
    short   ibstDispFldRMark;
    DTTM    dttmDispFldRMark;
    XCHAR   xstDispFldRMark[16];
    SHD     shd;
    BRC     brc;
} CHP;

/******** Paragraph Height ********/
typedef struct {
    BF      fSpare : 1;
    BF      fUnk : 1;
    BF      fDiffLines : 1;
    BF      : 5;
    BF      clMac : 8;
    short   sRsv2;
    long    dxaCol;
    long    dymLine;
} PHE;

/******** Autonumbered List Data Descriptor ********/
typedef struct {
    uchar   nfc;
    uchar   cxchTextBefore;
    uchar   cxchTextAfter;
    BF      jc : 2;
    BF      fPrev : 1;
    BF      fHang : 1;
    BF      fSetBold : 1;
    BF      fSetItalic : 1;
    BF      fSetSmallCaps : 1;
    BF      fSetCaps : 1;
    BF      fSetStrike : 1;
    BF      fSetKul : 1;
    BF      fPrevSpace : 1;
    BF      fBold : 1;
    BF      fItalic : 1;
    BF      fSmallCaps : 1;
    BF      fCaps : 1;
    BF      fStrike : 1;
    BF      kul : 3;
    BF      ico : 5;
    short   ftc;
    ushort  hps;
    ushort  iStartAt;
    ushort  dxaIndent;
    ushort  dxaSpace;
    uchar   fNumber1;
    uchar   fNumberAcross;
    uchar   fRestartHdn;
    uchar   fSpareX;
    XCHAR   rgxch[32];
} ANLD;

/******** Number Revision Mark Data ********/
typedef struct {
    uchar   fNumRM;
    uchar   Spare;
    short   ibstNumRM;
    DTTM    dttmNumRM;
    uchar   rgbxchNums[9];
    uchar   rgnfc[9];
    short   Spare2;
    dword   PNBR[9];
    XCHAR   xst[32];
} NUMRM;

#define PAP_ITBDMAX 64

/******** Paragraph Properties ********/
typedef struct {
    ushort  istd;
    uchar   jc;
    uchar   fKeep;
    uchar   fKeepFollow;
    uchar   fPageBreakBefore;
    BF      fBrLnAbove : 1;
    BF      fBrLnBelow : 1;
    BF      fUnused : 2;
    BF      pcVert : 2;
    BF      pcHorz : 2;
    uchar   brcp;
    uchar   brcl;
    uchar   cRsv9;
    uchar   ilvl;
    uchar   fNoLnn;
    short   ilfo;
    uchar   nLvlAnm;
    uchar   cRsv15;
    uchar   fSideBySide;
    uchar   cRsv17;
    uchar   fNoAutoHyph;
    uchar   fWidowControl;
    long    dxaRight;
    long    dxaLeft;
    long    dxaLeft1;
    LSPD    lspd;
    ulong   dyaBefore;
    ulong   dyaAfter;
    PHE     phe;
    uchar   fCrLf;
    uchar   fUsePgsuSettings;
    uchar   fAdjustRight;
    char    cRsv59;
    uchar   fKinsoku;
    uchar   fWordWrap;
    uchar   fOverflowPunct;
    uchar   fTopLinePunct;
    uchar   fAutoSpaceDE;
    uchar   fAutoSpaceDN;
    ushort  wAlignFont;
    BF      fVertical : 1;
    BF      fBackward : 1;
    BF      fRotateFont : 1;
    BF      : 13;
    word    wRsv70;
    char    fInTable;
    char    fTtp;
    byte    wr;
    byte    fLocked;
    long    pTap;
    long    dxaAbs;
    long    dyaAbs;
    long    dxaWidth;
    BRC     brcTop;
    BRC     brcLeft;
    BRC     brcBottom;
    BRC     brcRight;
    BRC     brcBetween;
    BRC     brcBar;
    long    dxaFromText;
    long    dyaFromText;
    BF      dyaHeight : 15;
    BF      fMinHeight : 1;
    SHD     shd;
    DCS     dcs;
    char    lvl;
    char    fNumRMIns;
    ANLD    anld;
    short   fPropRMark;
    short   ibstPropRMark;
    DTTM    dttmPropRMark;
    NUMRM   numrm;
    short   itbdMac;
    short   rgdxaTab[PAP_ITBDMAX];
    char    rgtbd[PAP_ITBDMAX];
} PAP;

typedef struct {
    BF      jc : 3;
    BF      tlc : 3;
    BF      : 2;
} TBD;

#define PAPX_FKP_BX_SIZE    13

typedef struct {
    BF      ispmd : 9;
    BF      fSpec : 1;
    BF      sgc : 3;
    BF      spra : 3;
} SPRM_Opcode;

#define SPRM_PIstd          0x4600
#define SPRM_PIncLvl        0x2602
#define SPRM_PIlfo          0x460B
#define SPRM_PChgTabsPapx   0xC60D
#define SPRM_PChgTabs       0xC615
#define SPRM_POutLvl        0x2640
#define SPRM_PHugePapx      0x6646
#define SPRM_CChs           0xEA08
#define SPRM_CSymbol        0x6A09
#define SPRM_CIstd          0x4A30
#define SPRM_CDefault       0x2A32
#define SPRM_CPlain         0x2A33
#define SPRM_CMajority      0xCA47
#define SPRM_SDxaColWidth   0xF203
#define SPRM_SDxaColSpacing 0xF204
#define SPRM_TDefTable10    0xD606
#define SPRM_TDefTable      0xD608

#define MAX_SPRM_OPERAND_SIZE 354

#define SPRM_TO_WORD(x) ( *(word *)&(x) )
#define WORD_TO_SPRM(x) ( *(SPRM_Opcode *)&(x) )

#define SGC_PAP 1
#define SGC_CHP 2
#define SGC_PIC 3
#define SGC_SEP 4
#define SGC_TAP 5

#define SPRA_BIT    0
#define SPRA_BYTE   1
#define SPRA_WORD   2
#define SPRA_DWORD  3
#define SPRA_COORD  4
#define SPRA_COORD2 5
#define SPRA_VAR    6
#define SPRA_WAAH   7

/******** Stylesheet Information ********/
typedef struct _STSHI
{
    ushort  cstd;                          // Count of styles in stylesheet
    ushort  cbSTDBaseInFile;               // Length of STD Base as stored in a file
    BF      fStdStylenamesWritten : 1;     // Are built-in stylenames stored?
    BF   :  15;                            // Spare flags
    ushort  stiMaxWhenSaved;               // Max sti known when this file was written
    ushort  istdMaxFixedWhenSaved;         // How many fixed-index istds are there?
    ushort  nVerBuiltInNamesWhenSaved;     // Current version of built-in stylenames
    FTC     rgftcStandardChpStsh[3];       // ftc used by StandardChpStsh for this document
} STSHI;

#define sgcPara 1
#define sgcChp  2

#define stiNil          0x0fff
#define stiNormal       0x0000

/******** Style Definition ********/
typedef struct _STD
{
    // Base part of STD:
    BF      sti : 12;          /* invariant style identifier */
    BF      fScratch : 1;      /* spare field for any temporary use,
                                  always reset back to zero! */
    BF      fInvalHeight : 1;  /* PHEs of all text with this style are wrong */
    BF      fHasUpe : 1;       /* UPEs have been generated */
    BF      fMassCopy : 1;     /* std has been mass-copied; if unused at
                                  save time, style should be deleted */
    BF      sgc : 4;           /* style type code */
    BF      istdBase : 12;     /* base style */
    BF      cupx : 4;          /* # of UPXs (and UPEs) */
    BF      istdNext : 12;     /* next style */
    ushort  bchUpe;            /* offset to end of upx's, start of upe's */

    BF      fAutoRedef : 1;    /* auto redefine style when appropriate */
    BF      fHidden : 1;       /* hidden from UI? */
    BF      : 14;              /* unused bits */

    // Variable length part of STD:
    XCHAR    xstzName[2];      /* sub-names are separated by chDelimStyle */
    /* char  grupx[]; */
    /* the UPEs are not stored on the file; they are a cache of the based-on
       chain */
    /* char  grupe[]; */
} STD;

#define cbMaxGrpprlStyleChpx 512

/******** Universal Property Descriptor ********/
typedef union
{
    PAP pap;
    CHP chp;
    struct
    {
        ushort  istd;
        uchar   cbGrpprl;
        uchar   grpprl[cbMaxGrpprlStyleChpx];
    } chpx;
} UPD;

/******** Section Descriptor ********/
typedef struct {
    short   fn;
    FC      fcSepx;
    short   fnMpr;
    FC      fcMpr;
} SED;

/******** Section Properties ********/
typedef struct {
//  uchar   bke;
//  uchar   fTitlePage;
//  char    fAutoPgn;
//  uchar   nfcPgn;
//  uchar   fUnlocked;
//  uchar   cnsPgn;
//  uchar   fPgnRestart;
//  uchar   fEndNote;
//  char    lnc;
//  char    grpflhdt;
//  ushort  nLnnMod;
//  long    dxaLnn;
//  short   dxaPgn;
//  short   dyaPgn;
    char    fLBetween;
//  char    vjc;
//  ushort  dmBinFirst;
//  ushort  dmBinOther;
//  ushort  dmPaperReq;
//  BRC     brcTop;
//  BRC     brcLeft;
//  BRC     brcBottom;
//  BRC     brcRight;
//  short   fPropRMark;
//  short   ibstPropRMark;
//  DTTM    dttmPropRMark;
//  long    dxtCharSpace;
//  long    dyaLinePitch;
//  ushort  clm;
//  short   sRsv62;
    uchar   dmOrientPage;
//  uchar   iHeadingPgn;
//  ushort  pgnStart;
//  short   lnnMin;
//  ushort  wTextFlow;
//  short   sRsv72;
//  short   pgbProp;
//  BF      pgbApplyTo : 3;
//  BF      pgbPageDepth : 2;
//  BF      pbgOffsetFrom : 3;
//  BF      bRsv74_8;
    ulong   xaPage;
    ulong   yaPage;
//  ulong   xaPageNUp;
//  ulong   yaPageNUp;
    ulong   dxaLeft;
    ulong   dxaRight;
    ulong   dyaTop;
    ulong   dyaBottom;
//  ulong   dzaGutter;
//  ulong   dyaHdrTop;
//  ulong   dyaHdrBottom;
    short   ccolM1;
    char    fEvenlySpaced;
//  char    cRsv123;
    long    dxaColumns;
//  long    rgdxaColumnWidthSpacing[89];
//  long    dxaColumnWidth;
//  uchar   dmOrientFirst;
//  uchar   fLayout;
//  short   sRsv490;
//  OLST    olstAnm;
} SEP;

/******** List LeVeL (on File) (LVLF) ********/
typedef struct {
    long    iStartAt;
    byte    nfc;
    BF      jc : 2;
    BF      fLegal : 1;
    BF      fNoRestart : 1;
    BF      fPrev : 1;
    BF      fPrevSpace : 1;
    BF      fWord6 : 1;
    uchar   rgbxchNums[9];
    uchar   ixchFollow;
    long    dxaSpace;
    long    dxaIndent;
    byte    cbGrpprlChpx;
    byte    cbGrpprlPapx;
    short   wRsv26;
} LVLF;

/******** LiST data (on File) (LSTF) ********/
typedef struct {
    long    lsid;
    long    tplc;
    short   rgistd[9];
    BF      fSimpleList : 1;
    BF      fRestartHdn : 1;
    BF      fRsv26_2 : 6;
    uchar   cRsv27;
} LSTF;

#define LIST_MAX_LVL_COUNT      9
#define LSTF_SIMPLE_LVL_COUNT   1
#define LSTF_COMPLEX_LVL_COUNT  LIST_MAX_LVL_COUNT

/******** List Format Override (LFO) ********/
typedef struct {
    long    lsid;
    long    lRsv4;
    long    lRsv8;
    uchar   clfolvl;
    uchar   cRsv13[3];
} LFO;

/******** List Format Override for a single LeVeL (LFOLVL) ********/
typedef struct {
    long    iStartAt;
    BF      ilvl : 4;
    BF      fStartAt : 1;
    BF      fFormatting : 1;
    BF      fRsv4_6 : 2;
    uchar   cRsv5[3];
} LFOLVL;

/******** DOcument Properties (DOP) ********/
typedef struct {
    BF      fFacingPages : 1;
    BF      fWidowControl : 1;
    BF      fPMHMainDoc : 1;
    BF      grfSuppression : 2;
    BF      fpc : 2;
    BF      : 1;
    BF      grpfIhdt : 8;
    BF      rncFtn : 2;
    BF      nFtn : 14;
    BF      fOutlineDirtySave : 1;
    BF      : 7;
    BF      fOnlyMacPics : 1;
    BF      fOnlyWinPics : 1;
    BF      fLabelDoc : 1;
    BF      fHyphCapitals : 1;
    BF      fAutoHyphen : 1;
    BF      fFormNoFields : 1;
    BF      fLinkStyles : 1;
    BF      fRevMarking : 1;
    BF      fBackup : 1;
    BF      fExactCWords : 1;
    BF      fPagHidden : 1;
    BF      fPagResults : 1;
    BF      fLockAtn : 1;
    BF      fMirrorMargins : 1;
    BF      fDfltTrueType : 1;
    BF      fPagSuppressTopSpacing : 1;
    BF      fProtEnabled : 1;
    BF      fDispFormFldSel : 1;
    BF      fRMView : 1;
    BF      fRMPrint : 1;
    BF      : 1;
    BF      fLockRev : 1;
    BF      fEmbedFonts : 1;
    word    copts;  /** moved below after nFib = 103 **/
    ushort  dxaTab;
    ushort  wSpare;
    ushort  dxaHotZ;
    ushort  cConsecHypLim;
    ushort  wSpare2;
    DTTM    dttmCreated;
    DTTM    dttmRevised;
    DTTM    dttmLastPrint;
    int     nRevision;
    long    tmEdited;
    long    cWords;
    long    cCh;
    int     cPg;
    long    cParas;
    BF      rncEdn : 2;
    BF      nEdn : 14;
    BF      epc : 2;
    BF      nfcFtnRef : 4;
    BF      nfcEdnRef : 4;
    BF      fPrintFormData : 1;
    BF      fSaveFormData : 1;
    BF      fShadeFormData : 1;
    BF      : 2;
    BF      fWCFtnEdn : 1;
    long    cLines;
    long    cWordsFtnEnd;
    long    cChFtnEdn;
    short   cPgFtnEdn;
    long    cParasFtnEdn;
    long    cLinesFtnEdn;
    long    lKeyProtDoc;
    BF      wvkSaved : 3;
    BF      wScaleSaved : 9;
    BF      zkSaved : 2;
    BF      fRotateFontW6 : 1;
    BF      iGutterPos : 1;
/** Valid for nFib >= 103 **/
    BF      fNoTabForInd : 1;
    BF      fNoSpaceRaiseLower : 1;
    BF      fSuppressSpbfAfterPageBreak : 1;
    BF      fWrapTrailSpaces : 1;
    BF      fMapPrintTextColor : 1;
    BF      fNoColumnBalance : 1;
    BF      fConvMailMergeEsc : 1;
    BF      fSupressTopSpacing : 1;
    BF      fOrigWordTableRules : 1;
    BF      fTransparentMetafiles : 1;
    BF      fShowBreaksInFrames : 1;
    BF      fSwapBordersFacingPgs : 1;
    BF      : 4;
    BF      fSuppressTopSpacingMac5 : 1;
    BF      fTruncDxaExpand : 1;
    BF      fPrintBodyBeforeHdr : 1;
    BF      fNoLeading : 1;
    BF      : 1;
    BF      fMWSmallCaps : 1;
    BF      : 10;
/** Some more stuff was added for nFib > 105, but we don't care. **/
} DOP;

/******** Font Family Name (FFN) ********/
typedef struct {
    BF      prq : 2;
    BF      fTrueType : 1;
    BF      : 1;
    BF      ff : 3;
    BF      : 1;
    short   wWeight;
    uchar   chs;
    uchar   ixchSzAlt;
    uchar   panose[10];
    uchar   fs[24];
} FFN;

/******** File Information Block ********/

/**** FIB header ****/
typedef struct {
    ushort  wIdent;                 // magic number
    ushort  nFib;                   // FIB version written. This will be >= 101
                                    // for all Word 6.0 for Windows and after
                                    // documents.
    ushort  nProduct;               // product version written by
    ushort  lid;                    // language stamp -- localized version
    short   pnNext;
    BF      fDot : 1;               // Set if this document is a template
    BF      fGlsy : 1;              // Set if this document is a glossary
    BF      fComplex : 1;           // when 1, file is in complex, fast-saved
                                    // format
    BF      fHasPic : 1;            // set if file contains 1 or more pictures
    BF      cQuickSaves : 4;        // count of times file was quicksaved
    BF      fEncrypted : 1;         // set if file is encrypted
    BF      fWhichTblStm : 1;       // When 0, this fib refers to the table
                                    // stream named "0Table", when 1, this fib
                                    // refers to the table stream named 
                                    // "1Table"
    BF      fReadOnlyRecommended:1; // Set when user has recommended that file
                                    // be read read-only
    BF      fWriteReservation : 1;  // Set when file owner has made the file
                                    // write reserved
    BF      fExtChar : 1;           // Set when using extended character set in
                                    // file
    BF      fLoadOverride : 1;
    BF      fFarEast : 1;
    BF      fCrypto : 1;
    ushort  nFibBack;               // This file format is compatible with
                                    // readers that understand nFib at or above
                                    // this value.
    ulong   lKey;                   // File encrypted key, only valid if 
                                    // fEncrypted.
    uchar   envr;                   // envrionment in which file was created
                                    // 0 created by Win Word
                                    // 1 created by Mac Word
    BF      fMac : 1;               // when 1, this file was last saved in the
                                    // Mac environment
    BF      fEmptySpecial : 1;
    BF      fLoadOverridePage : 1;
    BF      fFutureSavedUndo : 1;
    BF      fWord97Saved : 1;
    BF      fSpare0 : 3;
    ushort  chs;                    // Default extended character set id for
                                    // text in document stream. (overridden by
                                    // chp.chse)
    ushort  chsTables;              // Default extended character set id for
                                    // text in internal data structures
    long    fcMin;                  // file offset of first character of text.
                                    // In non-complex files a CP can be
                                    // transformed into an FC by the following
                                    // transformation: fc = cp + fib.fcMin.
    long    fcMac;                  // file offset of last character of text in
                                    // document text stream + 1
} FIB_FIBH;

/**** Array of shorts ****/
/* This array is located immediately after the FIB header. */

typedef struct {
    ushort  csw;                    // Count of fields in the array of "shorts"
    short   wMagicCreated;          // unique number identifying the file's
                                    // creator 0x6A62 is the creator ID for
                                    // Word and is reserved. Other creators
                                    // should choose a different value.
    short   wMagicRevised;          // identifies the File's last modifier
    short   wMagicCreatedPrivate;
    short   wMagicRevisedPrivate;
    short   pnFbpChpFirst_W6;
    short   pnChpFirst_W6;
    short   cpnBteChp_W6;
    short   pnFbpPapFirst_W6;
    short   pnPapFirst_W6;
    short   cpnBtePap_W6;
    short   pnFbpLvcFirst_W6;
    short   pnLvcFirst_W6;
    short   cpnBteLvc_W6;
    short   lidFE;                  // language ID if document was written by
                                    // Far East version of Word (i.e.
                                    // FIB.fFarEast is on)
} FIB_RGSW;

/**** Array of longs ****/
/* This array is located (fib.csw*sizeof(short)) bytes after fib.csw. */

typedef struct {
    ushort  clw;                    // Number of fields in the array of longs
    long    cbMac;                  // file offset of last byte written to
                                    // file + 1.
    long    lProductCreated;        // contains the build date of the creator.
    long    lProductRevised;        // contains the build date of the File's
                                    // last modifier
    long    ccpText;                // length of main document text stream
    long    ccpFtn;                 // length of footnote subdocument text
                                    // stream
    long    ccpHdd;                 // length of header subdocument text
                                    // stream
    long    cppMcr;                 // length of macro subdocument text
                                    // stream, which should now always be 0
    long    ccpAtn;                 // length of annotation subdocument text
                                    // stream
    long    ccpEdn;                 // length of endnote subdocument text
                                    // stream
    long    ccpTxbx;                // length of textbox subdocument text
                                    // stream
    long    ccpHdrTxbx;             // length of header textbox subdocument
                                    // text stream
    long    pnFbpChpFirst;          // when were was insufficient memory for
                                    // Word to expand the plcfbte at save time,
                                    // the plcfbte is written to the file in
                                    // a linked list of 512-byte pieces 
                                    // starting with this pn
    long    pnChpFirst;             // the page number of the lowest numbered
                                    // page in the document that records CHPX
                                    // FKP information
    long    cpnBteChp;              // count of CHPX FKPs recorded in file. In
                                    // non-complex files if the number of
                                    // entries in the plcfbteChpx is less than
                                    // this, the plcfbteChpx is incomplete.
    long    pnFbpPapFirst;          // when were was insufficient memory for
                                    // Word to expand the plcfbte at save time,
                                    // the plcfbte is written to the file in
                                    // a linked list of 512-byte pieces 
                                    // starting with this pn
    long    pnPapFirst;             // the page number of the lowest numbered
                                    // page in the document that records PAPX
                                    // FKP information
    long    cpnBtePap;              // count of PAPX FKPs recorded in file. In
                                    // non-complex files if the number of
                                    // entries in the plcfbteChpx is less than
                                    // this, the plcfbtePapx is incomplete.
    long    pnFbpLvcFirst;          // when were was insufficient memory for
                                    // Word to expand the plcfbte at save time,
                                    // the plcfbte is written to the file in
                                    // a linked list of 512-byte pieces 
                                    // starting with this pn
    long    pnLvcFirst;             // the page number of the lowest numbered
                                    // page in the document that records LVCX
                                    // FKP information
    long    cpnBteLvc;              // count of LVCX FKPs recorded in file. In
                                    // non-complex files if the number of
                                    // entries in the plcfbteChpx is less than
                                    // this, the plcfbteLvcx is incomplete.
    long    fcIslandFirst;
    long    fcIslandLim;
} FIB_RGLW;

/**** Array of FC/LCB pairs ****/
/* This array is located (fib.clw*sizeof(long)) bytes after fib.clw. */

typedef struct {
    ushort  cfclcb;
    long    fcStshfOrig;
    ulong   lcbStshfOrig;
    long    fcStshf;
    ulong   lcbStshf;
    long    fcPlcffndRef;
    ulong   lcbPlcffndRef;
    long    fcPlcffndTxt;
    ulong   lcbPlcffndTxt;
    long    fcPlcfandRef;
    ulong   lcbPlcfandRef;
    long    fcPlcfandTxt;
    ulong   lcbPlcfandTxt;
    long    fcPlcfsed;
    ulong   lcbPlcfsed;
    long    fcPlcpad;
    ulong   lcbPlcpad;
    long    fcPlcfphe;
    ulong   lcbPlcfphe;
    long    fcSttbfglsy;
    ulong   lcbSttbfglsy;
    long    fcPlcfglsy;
    ulong   lcbPlcfglsy;
    long    fcPlcfhdd;
    ulong   lcbPlcfhdd;
    long    fcPlcfbteChpx;
    ulong   lcbPlcfbteChpx;
    long    fcPlcfbtePapx;
    ulong   lcbPlcfbtePapx;
    long    fcPlcfsea;
    ulong   lcbPlcfsea;
    long    fcSttbfffn;
    ulong   lcbSttbfffn;
    long    fcPlcffldMom;
    ulong   lcbPlcffldMom;
    long    fcPlcffldHdr;
    ulong   lcbPlcffldHdr;
    long    fcPlcffldFtn;
    ulong   lcbPlcffldFtn;
    long    fcPlcffldAtn;
    ulong   lcbPlcffldAtn;
    long    fcPlcffldMcr;
    ulong   lcbPlcffldMcr;
    long	fcSttbfbkmk;
    ulong	lcbSttbfbkmk;
    long	fcPlcfbkf;
    ulong	lcbPlcfbkf;
    long	fcPlcfbkl;
    ulong	lcbPlcfbkl;
    long	fcCmds;
    ulong	lcbCmds;
    long	fcPlcmcr;
    ulong	lcbPlcmcr;
    long	fcSttbfmcr;
    ulong	lcbSttbfmcr;
    long	fcPrDrvr;
    ulong	lcbPrDrvr;
    long	fcPrEnvPort;
    ulong	lcbPrEnvPort;
    long	fcPrEnvLand;
    ulong	lcbPrEnvLand;
    long	fcWss;
    ulong	lcbWss;
    long	fcDop;
    ulong	lcbDop;
    long	fcSttbfAssoc;
    ulong	lcbSttbfAssoc;
    long	fcClx;
    ulong	lcbClx;
    long	fcPlcfpgdFtn;
    ulong	lcbPlcfpgdFtn;
    long	fcAutosaveSource;
    ulong	lcbAutosaveSource;
    long	fcGrpXstAtnOwners;
    ulong	lcbGrpXstAtnOwners;
    long	fcSttbfAtnbkmk;
    ulong	lcbSttbfAtnbkmk;
    long	fcPlcdoaMom;
    ulong	lcbPlcdoaMom;
    long	fcPlcdoaHdr;
    ulong	lcbPlcdoaHdr;
    long	fcPlcspaMom;
    ulong	lcbPlcspaMom;
    long	fcPlcspaHdr;
    ulong	lcbPlcspaHdr;
    long	fcPlcfAtnbkf;
    ulong	lcbPlcfAtnbkf;
    long	fcPlcfAtnbkl;
    ulong	lcbPlcfAtnbkl;
    long	fcPms;
    ulong	lcbPms;
    long	fcFormFldSttbs;
    ulong	lcbFormFldSttbs;
    long	fcPlcfendRef;
    ulong	lcbPlcfendRef;
    long	fcPlcfendTxt;
    ulong	lcbPlcfendTxt;
    long	fcPlcffldEdn;
    ulong	lcbPlcffldEdn;
    long	fcPlcfpgdEdn;
    ulong	lcbPlcfpgdEdn;
    long	fcDggInfo;
    ulong	lcbDggInfo;
    long	fcSttbfRMark;
    ulong	lcbSttbfRMark;
    long	fcSttbCaption;
    ulong	lcbSttbCaption;
    long	fcSttbAutoCaption;
    ulong	lcbSttbAutoCaption;
    long	fcPlcfwkb;
    ulong	lcbPlcfwkb;
    long	fcPlcfspl;
    ulong	lcbPlcfspl;
    long	fcPlcftxbxTxt;
    ulong	lcbPlcftxbxTxt;
    long	fcPlcffldTxbx;
    ulong	lcbPlcffldTxbx;
    long	fcPlcfhdrtxbxTxt;
    ulong	lcbPlcfhdrtxbxTxt;
    long	fcPlcffldHdrTxbx;
    ulong	lcbPlcffldHdrTxbx;
    long	fcStwUser;
    ulong	lcbStwUser;
    long	fcSttbttmbd;
    ulong	cbSttbttmbd;
    long	fcUnused;
    ulong	lcbUnused;
//  FCPGD	rgpgdbkd;
    long	fcPgdMother;
    ulong	lcbPgdMother;
    long	fcBkdMother;
    ulong	lcbBkdMother;
    long	fcPgdFtn;
    ulong	lcbPgdFtn;
    long	fcBkdFtn;
    ulong	lcbBkdFtn;
    long	fcPgdEdn;
    ulong	lcbPgdEdn;
    long	fcBkdEdn;
    ulong	lcbBkdEdn;
    long	fcSttbfIntlFld;
    ulong	lcbSttbfIntlFld;
    long	fcRouteSlip;
    ulong	lcbRouteSlip;
    long	fcSttbSavedBy;
    ulong	lcbSttbSavedBy;
    long	fcSttbFnm;
    ulong	lcbSttbFnm;
    long	fcPlcfLst;
    ulong	lcbPlcfLst;
    long	fcPlfLfo;
    ulong	lcbPlfLfo;
    long	fcPlcftxbxBkd;
    ulong	lcbPlcftxbxBkd;
    long	fcPlcftxbxHdrBkd;
    ulong	lcbPlcftxbxHdrBkd;
    long	fcDocUndo;
    ulong	lcbDocUndo;
    long	fcRgbuse;
    ulong	lcbRgbuse;
    long	fcUsp;
    ulong	lcbUsp;
    long	fcUskf;
    ulong	lcbUskf;
    long	fcPlcupcRgbuse;
    ulong	lcbPlcupcRgbuse;
    long	fcPlcupcUsp;
    ulong	lcbPlcupcUsp;
    long	fcSttbGlsyStyle;
    ulong	lcbSttbGlsyStyle;
    long	fcPlgosl;
    ulong	lcbPlgosl;
    long	fcPlcocx;
    ulong	lcbPlcocx;
    long	fcPlcfbteLvc;
    ulong	lcbPlcfbteLvc;
    ulong	dwLowDateTime;
    ulong	dwHighDateTime;
    long	fcPlcflvc;
    ulong	lcbPlcflvc;
    long	fcPlcasumy;
    ulong	lcbPlcasumy;
    long	fcPlcfgram;
    ulong	lcbPlcfgram;
    long	fcSttbListNames;
    ulong	lcbSttbListNames;
    long	fcSttbfUssr;
    ulong	lcbSttbfUssr;
} FIB_RGFCLCB;

#endif /* __STRUCTS_H */
