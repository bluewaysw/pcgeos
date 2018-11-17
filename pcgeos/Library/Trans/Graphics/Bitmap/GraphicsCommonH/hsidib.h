/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		hsidib.h				     */
/*								     */
/*	AUTHOR:		jimmy lefkowitz				     */
/*								     */
/*	REVISION HISTORY:					     */
/*								     */
/*	Name	Date		Description			     */
/*	----	----		-----------			     */
/*	jimmy	1/27/92		Initial version			     */
/*								     */
/*	DESCRIPTION:						     */
/*								     */
/*	$Id: hsidib.h,v 1.1 97/04/07 11:28:22 newdeal Exp $
/*							   	     */
/*********************************************************************/

 
/**************************************************************************\
  HSIDIB.H - Header file for DIB.C
\**************************************************************************/
 
#define SIZEOFBMPFILEHDR   14
#define SIZEOFPALETTEENTRY 13
#define SIZEOFBMPCOREHDR   12
#define SIZEOFBMPINFOHDR   40
#define SIZEOFRGBQUAD      4
#define SIZEOFRGBTRIPLE    3
#define SIZEOFBITMAP       14
 
#define BMP_WIN20      5
#define BMP_WIN30      6
#define BMP_PM10       7
#define BMP_RLE30      8
 
#define BFT_ICON   0x4349         /* 'IC' */
#define BFT_BITMAP 0x4d42         /* 'BM' */
#define BFT_CURSOR 0x5450         /* 'PT' */
 
#ifdef DOSVERSION
   #define MAXREAD        32767
   #define STRIPSIZE      4096
#endif
 
#ifdef WINVERSION
   #define MAXREAD        32767
   #define STRIPSIZE      4096
#endif
 
#ifdef SUN
#define MAXREAD        65535
#define STRIPSIZE      8162
#endif
 
#ifdef MACVERSION
   #define MAXREAD        32767
   #define STRIPSIZE      4096
#endif
 
typedef struct _tagThreshold
   {
   BYTE    Black, Red, Green, Blue;
   }strThreshold;
 
extern FILE                 *Infile, *Outfile;
extern FILE                 *infile, *outfile;

extern BITMAPFILEHEADER   bmfhdr;
extern BITMAPINFOHEADER   bmihdr;
extern WORD               nWidthBytes, wWidthBytes, nColors;
extern BOOL               brainDamage;
extern RGBQUAD            clrtbl[], clrtbl16[], clrtbl256[], clrtbl2[],clrtbl8[];
 
extern BYTE               BitPatternOr[];
extern BYTE               BitPatternAnd[];
extern BYTE               zero, ones;
 
/* function prototypes */
 
WORD   fixshort    (WORD);
LONG   fixlong     (DWORD);

 
LPSTR  ParseExt    (LPSTR);
 
HSI_ERROR_CODE     ReadHeaderInfo  (FILE *);
HSI_ERROR_CODE     WriteHeaderInfo (VOID);
HSI_ERROR_CODE     OpenInOutFile   (LPSTR,LPSTR);
HSI_ERROR_CODE     OpenInFile      (LPSTR);
HSI_ERROR_CODE     OpenOutFile     (LPSTR);
HSI_ERROR_CODE     CloseInOutFile  (VOID);

int  _lread(FILE *,LPSTR , DWORD);
 
/*
HSI_ERROR_CODE     ReadRawHeaderInfo  (VOID);
*/

HSI_ERROR_CODE     ReadRawHeaderInfo  (FILE *);

HSI_ERROR_CODE     WriteRawHeaderInfo (VOID);

#ifndef GEOSVERSION
HSI_ERROR_CODE     OpenRawInOutFile   (LPSTR,LPSTR);
#endif

HSI_ERROR_CODE     OpenRawInFile      (LPSTR);
HSI_ERROR_CODE     OpenRawOutFile     (LPSTR);
void               CloseRawInOutFile  (VOID);
HSI_ERROR_CODE     copyfile           (LPSTR,LPSTR);
BOOL               IsGray             (WORD,RGBQUAD *);
void               flipbuf            (LPSTR s,WORD n);
HSI_ERROR_CODE     GetBitmapInfo      (LPSTR,
                                       LPBITMAPINFOHEADER,
                                       LPBITMAPFILEHEADER);


#ifdef MACVERSION
PASCAL SHORT ShowStatus(SHORT);
#else
SHORT FAR PASCAL ShowStatus(SHORT);
#endif


 
WORD               DibNumColors(VOID FAR * pv);
SHORT              GetNumColor(VOID);

#ifdef WINVERSION
void               LoadSystemColorTable(RGBQUAD *, SHORT *);
#endif

SHORT FAR PASCAL         GetTempFileName(BYTE,LPSTR,WORD,LPSTR);
 
#if FLATMEMORY==0
void               _ffmemcpy(LPSTR s, LPSTR t, DWORD l );
#endif
 
MemHandle          allocmax            (int *);
MemHandle          allocmaxhandle      (int FAR *);
 
void   dib2mono(LPSTR,LPSTR,
                /*WORD,*/ WORD,
                BYTE,
                RGBQUAD *,
                BYTE,
                strThreshold);
#ifndef GEOSVERSION
void lunlink   (LPSTR);
#endif

void lrename   (LPSTR,LPSTR);
 
#ifndef GEOSVERSION

#ifdef WINVERSION
void          DebugOut ( LPSTR, ... );
#else
void          DebugOut ( char *, ... );
#endif

#endif 
 
/* Compatibility function prototypes */
 
void   copybmf2buf (LPBITMAPFILEHEADER,LPSTR);
void   copybmi2buf (LPBITMAPINFOHEADER,LPSTR);
void   copybmp2buf (LPBITMAP,LPSTR);
void   copybmf4buf (LPBITMAPFILEHEADER,LPSTR);
void   copybmi4buf (LPBITMAPINFOHEADER,LPSTR);
void   copybmp4buf (LPBITMAP,LPSTR);
void   copybmc4buf (LPBITMAPCOREHEADER,LPSTR); 
void   copyclrtbl2buf (RGBQUAD FAR *,LPSTR,WORD);
void   copyclrtbl4buf (RGBQUAD FAR *,LPSTR,WORD);
 




