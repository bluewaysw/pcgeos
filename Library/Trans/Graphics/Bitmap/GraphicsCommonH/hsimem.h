/*********************************************************************/
/*								     */
/*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     */
/*								     */
/* 	PROJECT:	PC GEOS					     */
/* 	MODULE:							     */	
/* 	FILE:		hsimem.h				     */
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
/*	$Id: hsimem.h,v 1.1 97/04/07 11:28:24 newdeal Exp $
/*							   	     */
/*********************************************************************/


/**************************************************************************\
  HSIMEM.H - Header file for MEMMGR.C
\**************************************************************************/

#ifdef __HIGHC__
pragma Off(Prototype_conversion_warn);
#endif

#include <hsiport.h>
#include <hsiwin.h>
#include <heap.h>
#include <Ansi/stdlib.h>


#ifdef VFIO
#include "hsivfio.h"
#endif
 
#define FIXWORD(x)        x
#define FIXDWORD(x)       x
 


#define fixshortnow(x)  ((WORD) (LOBYTE(x) << 8) | (WORD) HIBYTE(x))
#define fixlongnow(x) (((DWORD)fixshortnow(LOWORD(x))) << 16 | (DWORD)fixshortnow(HIWORD(x)))

WORD   GetINTELWORD    (LPSTR);    /* defined in hsiport.c     */
DWORD  GetINTELDWORD   (LPSTR);    /* defined in hsiport.c     */
WORD   GetMOTORWORD    (LPSTR);    /* defined in hsiport.c     */
DWORD  GetMOTORDWORD   (LPSTR);    /* defined in hsiport.c     */

void   SetINTELWORD    (LPSTR,WORD);    /* defined in hsiport.c     */
void   SetINTELDWORD   (LPSTR,DWORD);    /* defined in hsiport.c     */
void   SetMOTORWORD    (LPSTR,WORD);    /* defined in hsiport.c     */
void   SetMOTORDWORD   (LPSTR,DWORD);    /* defined in hsiport.c     */

#define SIZEOFBYTE          1
#define SIZEOFCHAR          1
#define SIZEOFINT          2
#define SIZEOFWORD          2
#define SIZEOFSHORT  2
#define SIZEOFLONG          4
#define SIZEOFDWORD  4
#define SIZEOFDOUBLE 4
#define SIZEOFPOINT  4
#define SIZEOFRECT   8
 
#define EXPORT FAR PASCAL
 
#define BOUND(x,min,max) ((x) < (min) ? (min) : ((x) > (max) ? (max) : (x)))
#define ISDIB(bft) ((bft) == BFT_BITMAP)
#define ALIGNULONG(i)   ((i+3)/4*4)        /* ULONG aligned ! */
#define ALIGNWORD(i)   ((i+1)/2*2)        /* WORD  aligned ! */
#define WIDTHBYTES(i)  ((i+31)/32*4)  // ULONG aligned ! 
#define RGB2GRAY(r,g,b) (BYTE)(((WORD)r*30+(WORD)g*59+(WORD)b*11)/100)
#define CMY2GRAY(c,m,y) (BYTE)(((WORD)(255-c)*30+(WORD)(255-m)*59+(WORD)(255-y)*11)/100)
 
#define SCROLLLINE 8
#define SCROLLPAGE 32
 
/* NULL shorthands: */
 
#define HNULL   ((HANDLE)NULL)
#define BFNULL  ((BYTE FAR *)NULL)
#define LPNULL  ((LPSTR)NULL)
 
/****************** typedefs ********************/
 
typedef short           RC;
typedef char            SINT;   /* 8-bit, signed integer. */
/* typedef SINT FAR        *LPSINT;  */
typedef PVOID           PDLOC;  /* to allow imaging routines to pass a hidden
                                 * data location structure, for eventual
typedef struct
   {
   BOOL     bNoDialog;     // TRUE - print without opening dialog box
   RECT     bbox;          // bounding box of image
   POINT    dpi;           // Dot Per Inch in both direction
   BOOL     bKeepAsp;      // TRUE = keep aspect ratio
   BOOL     bFit2Page;     // TRUE = Fit the image to the print page
   int      leftMargin;
   int      topMargin;
   RECT     gMargins;
   BOOL     keepRatio;     // status of check button in print dialog
   int      unit;
   BOOL     bMono;
   BOOL     bDraftMode;

   char     reserved[38];

   } PRNOPT;

typedef PRNOPT FAR   *LPPRNOPT;


#define OPT_WMFHEADER 0x0001       /* create Placable WMF */
#define FLAG_COMMENT  0x00100000
#define FLAG_PREVIEW  0x08         /* Preview header for EPS file */
#define  MF_D_DIB      0x00        /* DIB disk file */
#define  MF_D_WMF      0x01        /* WMF disk file */
#define  MF_D_SYMBOL   0x02        /* SYMBOL disk file */
#define  MF_M_DIB      0x10        /* DIB in memory */
#define  MF_M_WMF      0x11        /* WMF in memory */
#define  MF_M_SYMBOL   0x12        /* SYMBOL list in memory */

#define  MF_DISK       0x00        /* the 5nd bit is used to decide memory */
#define  MF_MEMORY     0x10  

#define  MF_DIB        0x00        /* DIB */
#define  MF_WMF        0x01        /* Windows WMF */
#define ID_FONTFACE      1
#define ID_FONTID        2



typedef struct
   {
   BYTE    type;
   char    ext[10];                /* default file extension */
#ifdef WINVERSION
   int (FAR PASCAL *Disp) (int);   /* display call back function */
#else
   int (*Disp)(int);
#endif


   DWORD   dwOption;               /* double word option field */
   RECT    rect;                   /* left,top,width,height in deci-inch(1/100) */
   char    hostname[10];           /* Host Id */
   char    string[112];            /* any ascii string */
   WORD    dpi;                    /* set to zero for default value (72) */
   WORD    end;                    /* end of completion, default to 100 */
   WORD    start;                  /* starting percentage, default to 0   */
   HWND    hwnd;                   /* window handle (if any) */
   WORD    fld;                    /* control ID for window */


   BYTE    metafile;

   void  *lpstr;                /* This field is used only for in memory */
                                   /* conversion routine.  It is the locked */
                                   /* memory pointer that points to graphics*/
                                   /* data.                                 */

   long     bsize;                 /* size of the data being referenced by  */
                                   /* the lpstr                             */

   int ( *cbComment)(void   **,int *,int *);

   int ( *cbFontMap)(WORD,WORD,void   *);
                                   /* Call back routines for speical font    */
                                   /* handling.                              */
                                   /* Parameter:                             */
                                   /*     1st: Flag: ID_FONTFACE             */
                                   /*                ID_FONTID               */
                                   /*     2nd: ID for face or font           */
                                   /*     3rd: Any additional info. Set to   */
                                   /*          NULL for don't care.          */
                                   /* Return:                                */
                                   /*     ID for font face (ID_FONTFACE)     */
                                   /*     ID for font id (ID_FONTID)         */
   char CmdLine[80];
   char Filler [176];

   } CNVOPTION;
 
typedef CNVOPTION *LPCNVOPTION;
typedef CNVOPTION     *PCNVOPTION;

/* Option */

#define OPT_WMFHEADER  0x0001      /* create Placable WMF */
 
 

/*
   display attributes for Vector Graphics Viewer
 
*/
 
typedef struct strVECTPROP

   {
   BYTE    mode;   /* isotropic(7), anisotropic(8) */
 
   BYTE    opt;    /* bit 0: 1:use PlayMetaFile(), 0: use ShowMetaFile() */
                   /* bit 1: 1: wirefreame, 0: as is */
                   /* bit 2: 1: process bitmap data */
 
#define    OPT_PLAYMETAFILE    0x01
#define    OPT_WIREFRAME       0x02
#define    OPT_SHWBITMAP       0x04
 
   POINT   zoom;   /* zoom factor x 100.  100:original size, 50:half size */
                   /* max zoom factor 65000 */
 
   POINT   trans;  /* translation (x,y) */
 
   WORD    rotate; /* rotation angle 0 - 360 (not used) */
 
   POINT   viewport;   /* width and height of viewport */
   POINT   size;       /* picture size (not used) */
 
   } VECTORPROP;
 
typedef VECTORPROP *       PVECTORPROP;
typedef VECTORPROP   *   LPVECTORPROP;
 
 
#include <fileio.h>
 
 
/* odd, even, and com are shorthand for simple stuff.  */
 
#define ODD(X)      ((X) & 1)       /* Returns TRUE if X is odd */
#define EVEN(X)     (!((X) & 1))    /* Returns TRUE if X is even */
#define COM(X)      (~(X))          /* XyWrite users:  hidden tilda */
 
#define _fmalloc    malloc
#define _falloc	    malloc 
#define _frealloc   realloc 
#define _fstrcpy    strcpy

#define _ffree(p)   {free(p); \
		     p = NULL; }
#define _fmemcpy    memcpy
#define _fmemset    memset
#define _fstrlen    strlen
