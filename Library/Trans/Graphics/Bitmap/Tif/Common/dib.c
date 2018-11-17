/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		dib.c<2>				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	1/27/92		Initial version			     
*								     
*	DESCRIPTION:						     
*								     
*	$Id: dib.c,v 1.1 97/04/07 11:28:30 newdeal Exp $
*							   	     
*********************************************************************/



/*************************************************************************\
   DIB.C - Routines used for manipulate DIB file.
\*************************************************************************/

#pragma Comment("@" __FILE__)
 
/**
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
**/


#include <hsimem.h>
#include <hsierror.h>

#include <Ansi/string.h>
#include <Ansi/stdio.h>
#include <hsidib.h>

FILE          *Infile, *Outfile;
FILE          *infile, *outfile;



BITMAPCOREHEADER bmchdr;
BITMAPFILEHEADER   bmfhdr;
BITMAPINFOHEADER   bmihdr;
WORD               nWidthBytes, wWidthBytes, nColors;
BOOL               brainDamage=TRUE;
 
BYTE BitPatternOr[8] = {0x80,0x40,0x20,0x10,0x08,0x04,0x02,0x01 };
BYTE BitPatternAnd[8]= {0x7F,0xBF,0xDF,0xEF,0xF7,0xFB,0xFD,0xFE };
 
#define READBUFSIZE   1024
#define WRITEBUFSIZE  1024
 
RGBQUAD clrtbl[256]={0};
 
RGBQUAD clrtbl256[256] =      /* default 256 color table */
   {
      {  0x00, 0x00, 0x00, 0x00 },
      {  0x00, 0x00, 0x55, 0x00 },
      {  0x00, 0x00, 0x80, 0x00 },
      {  0x00, 0x00, 0xAA, 0x00 },
      {  0x00, 0x00, 0xD5, 0x00 },
      {  0x00, 0x00, 0xFF, 0x00 },
      {  0x00, 0x2B, 0x00, 0x00 },
      {  0x00, 0x2B, 0x55, 0x00 },
      {  0x00, 0x2B, 0x80, 0x00 },
      {  0x00, 0x2B, 0xAA, 0x00 },
      {  0x00, 0x2B, 0xD5, 0x00 },
      {  0x00, 0x2B, 0xFF, 0x00 },
      {  0x00, 0x55, 0x00, 0x00 },
      {  0x00, 0x55, 0x55, 0x00 },
      {  0x00, 0x55, 0x80, 0x00 },
      {  0x00, 0x55, 0xAA, 0x00 },
      {  0x00, 0x55, 0xD5, 0x00 },
      {  0x00, 0x55, 0xFF, 0x00 },
      {  0x00, 0x80, 0x00, 0x00 },
      {  0x00, 0x80, 0x55, 0x00 },
      {  0x00, 0x80, 0x80, 0x00 },
      {  0x00, 0x80, 0xAA, 0x00 },
      {  0x00, 0x80, 0xD5, 0x00 },
      {  0x00, 0x80, 0xFF, 0x00 },
      {  0x00, 0xAA, 0x00, 0x00 },
      {  0x00, 0xAA, 0x55, 0x00 },
      {  0x00, 0xAA, 0x80, 0x00 },
      {  0x00, 0xAA, 0xAA, 0x00 },
      {  0x00, 0xAA, 0xD5, 0x00 },
      {  0x00, 0xAA, 0xFF, 0x00 },
      {  0x00, 0xD5, 0x00, 0x00 },
      {  0x00, 0xD5, 0x55, 0x00 },
      {  0x00, 0xD5, 0x80, 0x00 },
      {  0x00, 0xD5, 0xAA, 0x00 },
      {  0x00, 0xD5, 0xD5, 0x00 },
      {  0x00, 0xD5, 0xFF, 0x00 },
      {  0x00, 0xFF, 0x00, 0x00 },
      {  0x00, 0xFF, 0x55, 0x00 },
      {  0x00, 0xFF, 0x80, 0x00 },
      {  0x00, 0xFF, 0xAA, 0x00 },
      {  0x00, 0xFF, 0xD5, 0x00 },
      {  0x00, 0xFF, 0xFF, 0x00 },
      {  0x55, 0x00, 0x00, 0x00 },
      {  0x55, 0x00, 0x55, 0x00 },
      {  0x55, 0x00, 0x80, 0x00 },
      {  0x55, 0x00, 0xAA, 0x00 },
      {  0x55, 0x00, 0xD5, 0x00 },
      {  0x55, 0x00, 0xFF, 0x00 },
      {  0x55, 0x2B, 0x00, 0x00 },
      {  0x55, 0x2B, 0x55, 0x00 },
      {  0x55, 0x2B, 0x80, 0x00 },
      {  0x55, 0x2B, 0xAA, 0x00 },
      {  0x55, 0x2B, 0xD5, 0x00 },
      {  0x55, 0x2B, 0xFF, 0x00 },
      {  0x55, 0x55, 0x00, 0x00 },
      {  0x55, 0x55, 0x55, 0x00 },
      {  0x55, 0x55, 0x80, 0x00 },
      {  0x55, 0x55, 0xAA, 0x00 },
      {  0x55, 0x55, 0xD5, 0x00 },
      {  0x55, 0x55, 0xFF, 0x00 },
      {  0x55, 0x80, 0x00, 0x00 },
      {  0x55, 0x80, 0x55, 0x00 },
      {  0x55, 0x80, 0x80, 0x00 },
      {  0x55, 0x80, 0xAA, 0x00 },
      {  0x55, 0x80, 0xD5, 0x00 },
      {  0x55, 0x80, 0xFF, 0x00 },
      {  0x55, 0xAA, 0x00, 0x00 },
      {  0x55, 0xAA, 0x55, 0x00 },
      {  0x55, 0xAA, 0x80, 0x00 },
      {  0x55, 0xAA, 0xAA, 0x00 },
      {  0x55, 0xAA, 0xD5, 0x00 },
      {  0x55, 0xAA, 0xFF, 0x00 },
      {  0x55, 0xD5, 0x00, 0x00 },
      {  0x55, 0xD5, 0x55, 0x00 },
      {  0x55, 0xD5, 0x80, 0x00 },
      {  0x55, 0xD5, 0xAA, 0x00 },
      {  0x55, 0xD5, 0xD5, 0x00 },
      {  0x55, 0xD5, 0xFF, 0x00 },
      {  0x55, 0xFF, 0x00, 0x00 },
      {  0x55, 0xFF, 0x55, 0x00 },
      {  0x55, 0xFF, 0x80, 0x00 },
      {  0x55, 0xFF, 0xAA, 0x00 },
      {  0x55, 0xFF, 0xD5, 0x00 },
      {  0x55, 0xFF, 0xFF, 0x00 },
      {  0x80, 0x00, 0x00, 0x00 },
      {  0x80, 0x00, 0x55, 0x00 },
      {  0x80, 0x00, 0x80, 0x00 },
      {  0x80, 0x00, 0xAA, 0x00 },
      {  0x80, 0x00, 0xD5, 0x00 },
      {  0x80, 0x00, 0xFF, 0x00 },
      {  0x80, 0x2B, 0x00, 0x00 },
      {  0x80, 0x2B, 0x55, 0x00 },
      {  0x80, 0x2B, 0x80, 0x00 },
      {  0x80, 0x2B, 0xAA, 0x00 },
      {  0x80, 0x2B, 0xD5, 0x00 },
      {  0x80, 0x2B, 0xFF, 0x00 },
      {  0x80, 0x55, 0x00, 0x00 },
      {  0x80, 0x55, 0x55, 0x00 },
      {  0x80, 0x55, 0x80, 0x00 },
      {  0x80, 0x55, 0xAA, 0x00 },
      {  0x80, 0x55, 0xD5, 0x00 },
      {  0x80, 0x55, 0xFF, 0x00 },
      {  0x80, 0x80, 0x00, 0x00 },
      {  0x80, 0x80, 0x55, 0x00 },
      {  0x80, 0x80, 0x80, 0x00 },
      {  0x80, 0x80, 0xAA, 0x00 },
      {  0x80, 0x80, 0xD5, 0x00 },
      {  0x80, 0x80, 0xFF, 0x00 },
      {  0x80, 0xAA, 0x00, 0x00 },
      {  0x80, 0xAA, 0x55, 0x00 },
      {  0x80, 0xAA, 0x80, 0x00 },
      {  0x80, 0xAA, 0xAA, 0x00 },
      {  0x80, 0xAA, 0xD5, 0x00 },
      {  0x80, 0xAA, 0xFF, 0x00 },
      {  0x80, 0xD5, 0x00, 0x00 },
      {  0x80, 0xD5, 0x55, 0x00 },
      {  0x80, 0xD5, 0x80, 0x00 },
      {  0x80, 0xD5, 0xAA, 0x00 },
      {  0x80, 0xD5, 0xD5, 0x00 },
      {  0x80, 0xD5, 0xFF, 0x00 },
      {  0x80, 0xFF, 0x00, 0x00 },
      {  0x80, 0xFF, 0x55, 0x00 },
      {  0x80, 0xFF, 0x80, 0x00 },
      {  0x80, 0xFF, 0xAA, 0x00 },
      {  0x80, 0xFF, 0xD5, 0x00 },
      {  0x80, 0xFF, 0xFF, 0x00 },
      {  0xAA, 0x00, 0x00, 0x00 },
      {  0xAA, 0x00, 0x55, 0x00 },
      {  0xAA, 0x00, 0x80, 0x00 },
      {  0xAA, 0x00, 0xAA, 0x00 },
      {  0xAA, 0x00, 0xD5, 0x00 },
      {  0xAA, 0x00, 0xFF, 0x00 },
      {  0xAA, 0x2B, 0x00, 0x00 },
      {  0xAA, 0x2B, 0x55, 0x00 },
      {  0xAA, 0x2B, 0x80, 0x00 },
      {  0xAA, 0x2B, 0xAA, 0x00 },
      {  0xAA, 0x2B, 0xD5, 0x00 },
      {  0xAA, 0x2B, 0xFF, 0x00 },
      {  0xAA, 0x55, 0x00, 0x00 },
      {  0xAA, 0x55, 0x55, 0x00 },
      {  0xAA, 0x55, 0x80, 0x00 },
      {  0xAA, 0x55, 0xAA, 0x00 },
      {  0xAA, 0x55, 0xD5, 0x00 },
      {  0xAA, 0x55, 0xFF, 0x00 },
      {  0xAA, 0x80, 0x00, 0x00 },
      {  0xAA, 0x80, 0x55, 0x00 },
      {  0xAA, 0x80, 0x80, 0x00 },
      {  0xAA, 0x80, 0xAA, 0x00 },
      {  0xAA, 0x80, 0xD5, 0x00 },
      {  0xAA, 0x80, 0xFF, 0x00 },
      {  0xAA, 0xAA, 0x00, 0x00 },
      {  0xAA, 0xAA, 0x55, 0x00 },
      {  0xAA, 0xAA, 0x80, 0x00 },
      {  0xAA, 0xAA, 0xAA, 0x00 },
      {  0xAA, 0xAA, 0xD5, 0x00 },
      {  0xAA, 0xAA, 0xFF, 0x00 },
      {  0xAA, 0xD5, 0x00, 0x00 },
      {  0xAA, 0xD5, 0x55, 0x00 },
      {  0xAA, 0xD5, 0x80, 0x00 },
      {  0xAA, 0xD5, 0xAA, 0x00 },
      {  0xAA, 0xD5, 0xD5, 0x00 },
      {  0xAA, 0xD5, 0xFF, 0x00 },
      {  0xAA, 0xFF, 0x00, 0x00 },
      {  0xAA, 0xFF, 0x55, 0x00 },
      {  0xAA, 0xFF, 0x80, 0x00 },
      {  0xAA, 0xFF, 0xAA, 0x00 },
      {  0xAA, 0xFF, 0xD5, 0x00 },
      {  0xAA, 0xFF, 0xFF, 0x00 },
      {  0xD5, 0x00, 0x00, 0x00 },
      {  0xD5, 0x00, 0x55, 0x00 },
      {  0xD5, 0x00, 0x80, 0x00 },
      {  0xD5, 0x00, 0xAA, 0x00 },
      {  0xD5, 0x00, 0xD5, 0x00 },
      {  0xD5, 0x00, 0xFF, 0x00 },
      {  0xD5, 0x2B, 0x00, 0x00 },
      {  0xD5, 0x2B, 0x55, 0x00 },
      {  0xD5, 0x2B, 0x80, 0x00 },
      {  0xD5, 0x2B, 0xAA, 0x00 },
      {  0xD5, 0x2B, 0xD5, 0x00 },
      {  0xD5, 0x2B, 0xFF, 0x00 },
      {  0xD5, 0x55, 0x00, 0x00 },
      {  0xD5, 0x55, 0x55, 0x00 },
      {  0xD5, 0x55, 0x80, 0x00 },
      {  0xD5, 0x55, 0xAA, 0x00 },
      {  0xD5, 0x55, 0xD5, 0x00 },
      {  0xD5, 0x55, 0xFF, 0x00 },
      {  0xD5, 0x80, 0x00, 0x00 },
      {  0xD5, 0x80, 0x55, 0x00 },
      {  0xD5, 0x80, 0x80, 0x00 },
      {  0xD5, 0x80, 0xAA, 0x00 },
      {  0xD5, 0x80, 0xD5, 0x00 },
      {  0xD5, 0x80, 0xFF, 0x00 },
      {  0xD5, 0xAA, 0x00, 0x00 },
      {  0xD5, 0xAA, 0x55, 0x00 },
      {  0xD5, 0xAA, 0x80, 0x00 },
      {  0xD5, 0xAA, 0xAA, 0x00 },
      {  0xD5, 0xAA, 0xD5, 0x00 },
      {  0xD5, 0xAA, 0xFF, 0x00 },
      {  0xD5, 0xD5, 0x00, 0x00 },
      {  0xD5, 0xD5, 0x55, 0x00 },
      {  0xD5, 0xD5, 0x80, 0x00 },
      {  0xD5, 0xD5, 0xAA, 0x00 },
      {  0xD5, 0xD5, 0xD5, 0x00 },
      {  0xD5, 0xD5, 0xFF, 0x00 },
      {  0xD5, 0xFF, 0x00, 0x00 },
      {  0xD5, 0xFF, 0x55, 0x00 },
      {  0xD5, 0xFF, 0x80, 0x00 },
      {  0xD5, 0xFF, 0xAA, 0x00 },
      {  0xD5, 0xFF, 0xD5, 0x00 },
      {  0xD5, 0xFF, 0xFF, 0x00 },
      {  0xFF, 0x00, 0x00, 0x00 },
      {  0xFF, 0x00, 0x55, 0x00 },
      {  0xFF, 0x00, 0x80, 0x00 },
      {  0xFF, 0x00, 0xAA, 0x00 },
      {  0xFF, 0x00, 0xD5, 0x00 },
      {  0xFF, 0x00, 0xFF, 0x00 },
      {  0xFF, 0x2B, 0x00, 0x00 },
      {  0xFF, 0x2B, 0x55, 0x00 },
      {  0xFF, 0x2B, 0x80, 0x00 },
      {  0xFF, 0x2B, 0xAA, 0x00 },
      {  0xFF, 0x2B, 0xD5, 0x00 },
      {  0xFF, 0x2B, 0xFF, 0x00 },
      {  0xFF, 0x55, 0x00, 0x00 },
      {  0xFF, 0x55, 0x55, 0x00 },
      {  0xFF, 0x55, 0x80, 0x00 },
      {  0xFF, 0x55, 0xAA, 0x00 },
      {  0xFF, 0x55, 0xD5, 0x00 },
      {  0xFF, 0x55, 0xFF, 0x00 },
      {  0xFF, 0x80, 0x00, 0x00 },
      {  0xFF, 0x80, 0x55, 0x00 },
      {  0xFF, 0x80, 0x80, 0x00 },
      {  0xFF, 0x80, 0xAA, 0x00 },
      {  0xFF, 0x80, 0xD5, 0x00 },
      {  0xFF, 0x80, 0xFF, 0x00 },
      {  0xFF, 0xAA, 0x00, 0x00 },
      {  0xFF, 0xAA, 0x55, 0x00 },
      {  0xFF, 0xAA, 0x80, 0x00 },
      {  0xFF, 0xAA, 0xAA, 0x00 },
      {  0xFF, 0xAA, 0xD5, 0x00 },
      {  0xFF, 0xAA, 0xFF, 0x00 },
      {  0xFF, 0xD5, 0x00, 0x00 },
      {  0xFF, 0xD5, 0x55, 0x00 },
      {  0xFF, 0xD5, 0x80, 0x00 },
      {  0xFF, 0xD5, 0xAA, 0x00 },
      {  0xFF, 0xD5, 0xD5, 0x00 },
      {  0xFF, 0xD5, 0xFF, 0x00 },
      {  0xFF, 0xFF, 0x00, 0x00 },
      {  0xFF, 0xFF, 0x55, 0x00 },
      {  0xFF, 0xFF, 0x80, 0x00 },
                   
      /* for some reason, the color palette for the next 6 is as follow, */
      /* in stead of what should be on the right.  This is the result */
      /* after using 256 color driver on Paradize. */
 
      {  0x00, 0x00, 0xFF, 0x00 }, /* F9 Red     0xFF, 0xFF, 0xAA, 0x00 */
      {  0x00, 0xFF, 0x00, 0x00 }, /* FA Green   0xFF, 0xFF, 0xD5, 0x00 */
      {  0x00, 0xFF, 0xFF, 0x00 }, /* FB Yellow  0x3F, 0x3F, 0x3F, 0x00 */
      {  0xFF, 0x00, 0x00, 0x00 }, /* FC Blue    0x6B, 0x6B, 0x6B, 0x00 */
      {  0xFF, 0x00, 0xFF, 0x00 }, /* FD Magenta 0x95, 0x95, 0x95, 0x00 */
      {  0xFF, 0xFF, 0x00, 0x00 }, /* FE Cyan    0xC3, 0xC3, 0xC3, 0x00 */
 
      {  0xFF, 0xFF, 0xFF, 0x00 }  /* FF */
   };
 
RGBQUAD clrtbl16[16] = 
   {
      {  0x00, 0x00, 0x00, 0x00 },
      {  0x00, 0x00, 0x80, 0x00 },
      {  0x00, 0x80, 0x00, 0x00 },
      {  0x00, 0x80, 0x80, 0x00 },
      {  0x80, 0x00, 0x00, 0x00 },
      {  0x80, 0x00, 0x80, 0x00 },
      {  0x80, 0x80, 0x00, 0x00 },
      {  0x80, 0x80, 0x80, 0x00 },
      {  0xC0, 0xC0, 0xC0, 0x00 },
      {  0x00, 0x00, 0xFF, 0x00 },
      {  0x00, 0xFF, 0x00, 0x00 },
      {  0x00, 0xFF, 0xFF, 0x00 },
      {  0xFF, 0x00, 0x00, 0x00 },
      {  0xFF, 0x00, 0xFF, 0x00 },
      {  0xFF, 0xFF, 0x00, 0x00 },
      {  0xFF, 0xFF, 0xFF, 0x00 }
   };
 
RGBQUAD clrtbl8[8] = 
   {
      {  0x00, 0x00, 0x00, 0x00 },
      {  0xFF, 0x00, 0x00, 0x00 },
      {  0x00, 0xFF, 0x00, 0x00 },
      {  0xFF, 0xFF, 0x00, 0x00 },
      {  0x00, 0x00, 0xFF, 0x00 },
      {  0xFF, 0x00, 0xFF, 0x00 },
      {  0x00, 0xFF, 0xFF, 0x00 },
      {  0xFF, 0xFF, 0xFF, 0x00 }
   };
RGBQUAD clrtbl2[2] = 
   {
      {  0x00, 0x00, 0x00, 0x00 }, /* bit zero is black (OFF) */
      {  0xFF, 0xFF, 0xFF, 0x00 }  /* bit one if white (ON) */
   };
 
BYTE   zero=0x00, ones=0xFF;
 
 
#ifndef WINVERSION
#ifndef GEOSVERSION 
 
/*
   Equivalent to Windows API.
*/
SHORT FAR PASCAL
GetTempFileName(BYTE n, LPSTR prefix, WORD m, LPSTR fname)
  {
  static SHORT count;
  static char str[83];
  static char nam[13];
 
  strcpy(nam, prefix);
  sprintf (str, "%s%d.tmp", nam, count++);
  strcpy(fname, str);
 
  return 0;
  }
 
#endif
#endif
 
 
/*
   Copy the bitmap file header information to the buffer pointer.  This
   routine (and with others) allows the software to be compatible with
   all platforms.  Especially with system that always has fixed size
   boundary on structure packing.
*/
 
void copybmf2buf(LPBITMAPFILEHEADER bf, LPSTR s)
   {
   SetINTELWORD (s,bf->bfType);             s+=2;
   SetINTELDWORD(s,bf->bfSize);             s+=4;
   SetINTELWORD (s,bf->bfReserved1);        s+=2;
   SetINTELWORD (s,bf->bfReserved2);        s+=2;
   SetINTELDWORD(s,bf->bfOffBits);          s+=4;
   }
 
/*
   copy the data from buffer to bitmap info header structure.
*/
 
void copybmf4buf(LPBITMAPFILEHEADER bf, LPSTR s)
   {
/***
   DWORD l;
   WORD wh, wl;
***/
   bf->bfType      =  GetINTELWORD(s);  s+=2;
   bf->bfSize      =  GetINTELDWORD(s); s+=4;
   bf->bfReserved1 =  GetINTELWORD(s);  s+=2;
   bf->bfReserved2 =  GetINTELWORD(s);  s+=2;
   bf->bfOffBits   =  GetINTELDWORD(s); s+=4;
   }
 
 
 
/*
   Copy the bitmap info header information to the buffer pointer.  This
   routine (and with others) allows the software to be compatible with
   all platforms.  Especially with system that always has fixed size
   boundary on structure packing.
*/
 
void copybmi2buf(LPBITMAPINFOHEADER bi,LPSTR s)
   {
   SetINTELDWORD(s,bi->biSize);              s+=4;
   SetINTELDWORD(s,bi->biWidth);             s+=4;
   SetINTELDWORD(s,bi->biHeight);            s+=4;
   SetINTELWORD (s,bi->biPlanes);            s+=2;
   SetINTELWORD (s,bi->biBitCount);          s+=2;
   SetINTELDWORD(s,bi->biCompression);       s+=4;        
   SetINTELDWORD(s,bi->biSizeImage);         s+=4;
   SetINTELDWORD(s,bi->biXPelsPerMeter);     s+=4;
   SetINTELDWORD(s,bi->biYPelsPerMeter);     s+=4;
   SetINTELDWORD(s,bi->biClrUsed);           s+=4;
   SetINTELDWORD(s,bi->biClrImportant);      s+=4;
   }
 
void copybmi4buf(LPBITMAPINFOHEADER bi,LPSTR s)
   {
   bi->biSize            =   GetINTELDWORD(s);   s+=4;
   bi->biWidth           =   GetINTELDWORD(s);   s+=4;
   bi->biHeight          =   GetINTELDWORD(s);   s+=4;
   bi->biPlanes          =   GetINTELWORD (s);   s+=2;
   bi->biBitCount        =   GetINTELWORD (s);   s+=2;
   bi->biCompression     =   GetINTELDWORD(s);   s+=4;
   bi->biSizeImage       =   GetINTELDWORD(s);   s+=4;
   bi->biXPelsPerMeter   =   GetINTELDWORD(s);   s+=4;
   bi->biYPelsPerMeter   =   GetINTELDWORD(s);   s+=4;
   bi->biClrUsed         =   GetINTELDWORD(s);   s+=4;
   bi->biClrImportant    =   GetINTELDWORD(s);   s+=4;
   }
 

/* Copy the buffer to OS2 bitmap core info header
*/ 
void copybmc4buf(LPBITMAPCOREHEADER bc,LPSTR s)
  {
   bc->bcSize            =   GetINTELDWORD(s);  s+=4;
   bc->bcWidth           =   GetINTELWORD(s);   s+=2;
   bc->bcHeight          =   GetINTELWORD(s);   s+=2;
   bc->bcPlanes          =   GetINTELWORD (s);  s+=2;
   bc->bcBitCount        =   GetINTELWORD (s);  s+=2;
   }

/*
   copy the buffer data to BITMAP structure (14 bytes)
*/
 
void copybmp2buf(LPBITMAP bm, LPSTR s)
   {
   SetINTELWORD(s,bm->bmType);              s+=2;
   SetINTELWORD(s,bm->bmWidth);             s+=2;
   SetINTELWORD(s,bm->bmHeight);            s+=2;
   SetINTELWORD(s,bm->bmWidthBytes);        s+=2;
   *s++ = bm->bmPlanes;               
   *s++ = bm->bmBitsPixel;            
   s = bm->bmBits;                                          
   }
 
/*
   copy the buffer data from BITMAP structure (14 bytes)
*/
 
void copybmp4buf(LPBITMAP bm, LPSTR s)
   {
   bm->bmType        = GetINTELWORD(s);     s+=2;       
   bm->bmWidth       = GetINTELWORD(s);     s+=2;       
   bm->bmHeight      = GetINTELWORD(s);     s+=2;       
   bm->bmWidthBytes  = GetINTELWORD(s);     s+=2;       
   bm->bmPlanes      = *s++;
   bm->bmBitsPixel   = *s++;
   bm->bmBits        = s;                      
   }
 
 
void copyclrtbl2buf(RGBQUAD FAR *clrtbl, LPSTR s, WORD n)
   {
  WORD i;
 
   for (i=0;i<n;i++)
       {
       *s++ = (BYTE)clrtbl[i].rgbBlue;
       *s++ = (BYTE)clrtbl[i].rgbGreen;
       *s++ = (BYTE)clrtbl[i].rgbRed;
       *s++ = (BYTE)clrtbl[i].rgbReserved;
       }
   }
 
/*
   copy color values in the string to color table array
*/
 
void copyclrtbl4buf(RGBQUAD FAR *clrtbl,LPSTR s,WORD n)
   {
   WORD i;
 
   for (i=0;i<n;i++)
       {
       clrtbl[i].rgbBlue     = (BYTE)*s++; 
       clrtbl[i].rgbGreen    = (BYTE)*s++; 
       clrtbl[i].rgbRed      = (BYTE)*s++; 
       clrtbl[i].rgbReserved = (BYTE)*s++; 
       }
   }
 
 
/*
   Obtain number of colors from the DIB file information header.
*/
 
SHORT
GetNumColor(VOID)
   {
   SHORT   i=0;
 
   if (bmihdr.biClrUsed != 0)
       return (WORD)bmihdr.biClrUsed;
 
   switch ( bmihdr.biBitCount )
       {
       case 1 :
           i = 2;
           break;
 
       case 4 :
           i = 16;
           break;
 
       case 8 :
           i = 256;
           break;
 
       case 0 :
           i = 0;
           break;
       }
 
/*   if ( bmihdr.biClrUsed != 0 ) */
/*       i = bmihdr.biClrUsed; */
 
    return i;
 
}
 
 
/*  
   How Many colors does this DIB have?
   this will work on both PM and Windows bitmap info structures.
*/
 
WORD DibNumColors(VOID FAR *pv)
   {
 
#define lpbi ((LPBITMAPINFOHEADER)pv)
#define lpbc ((LPBITMAPCOREHEADER)pv)
 
   SHORT bits;
 
   /*
    *  with the new format headers, the size of the palette is in biClrUsed
    *  else is dependent on bits per pixel
    */
 
   if (lpbi->biSize != sizeof(BITMAPCOREHEADER))
      {
      if (lpbi->biClrUsed != 0)
          return (WORD)lpbi->biClrUsed;
 
      bits = lpbi->biBitCount;
      }
    else
      {
      bits = lpbc->bcBitCount;
      }
 
   switch (bits)
      {
      case 1:
           return 2;
      case 4:
           return 16;
      case 8:
           return 256;
      default:
           break; 
      }
 
#undef lpbi
#undef lpbc
 
   return 0;
   }




#ifndef GEOSVERSION
/*
   Get the bitmap information from the file passed
*/
 
HSI_ERROR_CODE
GetBitmapInfo(LPSTR szFile, LPBITMAPINFOHEADER bi, LPBITMAPFILEHEADER bf)
{
   short err=0;
   FILE * infile;
   long  l;
   static char s6[40];
 
   infile = _lopen(szFile,0);    /* open input file */
 
   if (infile <= 0 )
       {
       err=HSI_EC_SRCCANTOPEN;
       goto cu0;
       }
 
   l = _lread( infile,                     /* read the file header */
               (LPSTR)s6,
               (WORD)SIZEOFBMPFILEHDR);
 
   copybmf4buf(bf,s6);
 
   if (l==0) 
   {
       err=HSI_EC_SRCCANTREAD; 
       goto cu0;
   }
 
   l = _lread( infile,
               (LPSTR)s6,                  /* read the info header */
               (WORD)SIZEOFBMPINFOHDR);
 
   if (l==0) 
   {
   	err=HSI_EC_SRCCANTREAD;
    	goto cu0;
   }
 
   copybmi4buf(bi,s6);
 
   cu0: /* exit, close file if no errors occured */
 
   if (infile>0)
       _lclose(infile);

   return err;
}
 
#endif     /*GEOSVERSION*/ 
/*
   Read the DIB header information and set up widthbytes.
 
   Global Variables:
 
   Infile, Outfile     File pointers
   wWidthBytes         number of bytes per scanline in BYTE bounary
   nWidthBytes         number of bytes per scanline in LONG boundary
   clrtbl              Color table that contain 256 entries
*/
 
HSI_ERROR_CODE
ReadHeaderInfo(FILE * Infile)
{
   short   err        = 0;
   LONG    l, hdrsize = 0, sizeFile;
   static char dibbuf[40];
   int type;
 
   /* get file header */
 
   if (fread(dibbuf,1,SIZEOFBMPFILEHDR,Infile ) <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
 
   copybmf4buf(&bmfhdr,dibbuf);       
 
   /* make sure this is a Bitmap file */
 
   if ( bmfhdr.bfType != BFT_BITMAP )
       {
       err = HSI_EC_UNSUPPORTED;
       goto cu0;
       }
 
   if (fread(dibbuf,1,SIZEOFBMPINFOHDR, Infile) <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
     if (*dibbuf==0x28)
      {
      copybmi4buf(&bmihdr,dibbuf);
      type=0;
      }
   else
   {
       if (*dibbuf==0x0c)
	   {
	       type=1; /* OS2 DIB */
	       fseek(Infile,-1L*(long)SIZEOFBMPINFOHDR,1);
	       if (fread(dibbuf,1,SIZEOFBMPCOREHDR,Infile) <= 0)
		   {
		       err = HSI_EC_SRCCANTREAD;
		       goto cu0;
		   }

	       copybmc4buf(&bmchdr,dibbuf);

	       _fmemset(&bmihdr,zero,SIZEOFBMPINFOHDR);

	       bmihdr.biHeight  = bmchdr.bcHeight;
	       bmihdr.biWidth   = bmchdr.bcWidth;
	       bmihdr.biBitCount= bmchdr.bcBitCount;
	       bmihdr.biPlanes  = bmchdr.bcPlanes;
	       bmihdr.biSize    = 0x28;
	   }
       else
	   {
	       err=HSI_EC_UNSUPPORTED;
	       goto cu0;
	   }
   }
   if (bmihdr.biWidth==0 ||                   /* validity check */
       bmihdr.biHeight==0)
       {
       err=HSI_EC_INVALIDBMPHEADER;
       goto cu0;
       }

   /* get number of colors */
 
   nColors = GetNumColor();
 
   /* load color table */
   
   if ( nColors > 0 )
       {
       static char s7[SIZEOFRGBQUAD];
       int n,size;
       WORD i;
 
 
       for (i=0;i<nColors;i++)
           {
             if (type==1)
               size=3;
           else
               size=SIZEOFRGBQUAD;

           n = fread(s7,1,size,Infile);
           if  (n<=0)
               {
               err = HSI_EC_SRCCANTREAD;
               goto cu0;
               }

           clrtbl[i].rgbBlue      = s7[0];
           clrtbl[i].rgbGreen     = s7[1];
           clrtbl[i].rgbRed       = s7[2];
           clrtbl[i].rgbReserved  = s7[3];
	 }
   }

  
  if (type==0)
      {
      hdrsize = (LONG)SIZEOFBMPINFOHDR +  /* calculate the correct */
                SIZEOFBMPFILEHDR +        /* header size  */
                SIZEOFRGBQUAD * nColors;
      }
   else
      {
      hdrsize = (LONG)SIZEOFBMPCOREHDR +  /* calculate the correct */
                SIZEOFBMPFILEHDR +        /* header size  */
                SIZEOFRGBTRIPLE * nColors;
      }

   if (hdrsize != (LONG)bmfhdr.bfOffBits)    /* check whether header size is ok  */
      {
      err=HSI_EC_INVALIDBMPHEADER;
      goto cu0;
      }

   if (bmihdr.biBitCount>8)
      wWidthBytes = (WORD)bmihdr.biWidth * 3;
   else
      wWidthBytes = (WORD)((bmihdr.biWidth * bmihdr.biBitCount ) +
                           7 ) / 8 * bmihdr.biPlanes;

   /* normalize scanline width to LONG boundary */
 
   nWidthBytes = ALIGNULONG(wWidthBytes);
 
   /* make sure the Bitmap file has correct FILE SIZE data */
 
   l = ftell(Infile);  /* save current position */

   /*
   if (bmfhdr.bfSize == (DWORD)l )    // empty file! This check is result
       {                       // from emtpy file generated by PSI. 
       err=HSI_EC_INVALIDBMPHEADER;
       goto cu0;
       }
   */


   fseek( Infile, 0L,SEEK_END ); /* goto end of file */   

/*
   if ( bmfhdr.bfSize > ftell(Infile) )
      {
      err=HSI_EC_INVALIDBMPHEADER;
      goto cu0;
      }
*/
 
   if (bmihdr.biSizeImage == 0)        /* some DIB file has zero size in   */
      {                               /* this field. We will fill it in   */
      bmihdr.biSizeImage = (DWORD)nWidthBytes * bmihdr.biHeight;
      }


   bmfhdr.bfSize = bmihdr.biSizeImage + bmfhdr.bfOffBits;   
   sizeFile = bmihdr.biSizeImage + hdrsize;
   if ( sizeFile > ftell(Infile) )
      {
      err=HSI_EC_INVALIDBMPHEADER;
      goto cu0;
      }


   cu0:
     fseek( Infile, l, 0 );  /* restore prevous position */
 
   return err;
   }
 
/*
   Write the image file header info to Buffered file pointer Outfile
 
   bmihdr and bmfhdr should already have following data:
 
   bmihdr.biWidth
   bmihdr.biHeight
   bmihdr.biBitCount
 
*/
 
HSI_ERROR_CODE
WriteHeaderInfo(VOID)
   {
   short  err=0;
   SHORT  i;
   int n;
   static char dibbuf2[40];
 
   bmfhdr.bfType           = BFT_BITMAP;
   bmfhdr.bfReserved1      = 0;
   bmfhdr.bfReserved2      = 0;
 
   bmihdr.biSize           = 40L;
   bmihdr.biPlanes                  = 1;
   bmihdr.biClrUsed        = 0L;
   bmihdr.biCompression    = 0L;
   bmihdr.biXPelsPerMeter  = 0L;
   bmihdr.biYPelsPerMeter  = 0L;
   bmihdr.biClrImportant   = 0L;
 
   switch (bmihdr.biBitCount)
       {
       case 1:
           nColors = 2;
           break;
 
       case 4 :
           nColors = 16;
           break;
 
       case 8 :
           nColors = 256;
           break;

       case 16 :
       case 24 :
           nColors = 0;
           wWidthBytes = (WORD)bmihdr.biWidth * 3;
           break;

       }
   
   nWidthBytes = ALIGNULONG(wWidthBytes);
 
   bmihdr.biSizeImage = (DWORD)nWidthBytes *   /* calculate the size of  */
                        bmihdr.biHeight;       /* image */
 
   /* calculate offset to bitmap data */
 
   bmfhdr.bfOffBits= SIZEOFBMPFILEHDR +
                     SIZEOFBMPINFOHDR +
                     nColors * SIZEOFRGBQUAD;
 
   /* calculate total size of this image */
 
   bmfhdr.bfSize = bmihdr.biSizeImage + bmfhdr.bfOffBits;
 
   fseek(Outfile,0L,0);            /* make sure we are at the BOF */
 
   copybmf2buf(&bmfhdr,dibbuf2);
 
   n =  fwrite(dibbuf2,                     /* write out file header */
          1,
          SIZEOFBMPFILEHDR,
          Outfile);
     if( n <= 0)
     {
       err = HSI_EC_DSTCANTWRITE;
       goto cu0;
     }

   copybmi2buf(&bmihdr,dibbuf2);
 
   n = fwrite(dibbuf2,                     /* write out header info  */
          1,
          SIZEOFBMPINFOHDR,
          Outfile);
   
    
   if ( n <= 0)
     {
       err = HSI_EC_DSTCANTWRITE;
       goto cu0;
     }
 
   for (i=0;i< (SHORT)nColors;i++)
       {
 
       dibbuf2[0]    = clrtbl[i].rgbBlue;
       dibbuf2[1]    = clrtbl[i].rgbGreen;
       dibbuf2[2]    = clrtbl[i].rgbRed;
       dibbuf2[3]    = clrtbl[i].rgbReserved;
 
       n=fwrite(dibbuf2,   1,    SIZEOFRGBQUAD,    Outfile);
 
       if (n <= 0)
           {
           err=HSI_EC_DSTCANTWRITE;
           goto cu0;
           }
       }
 
   cu0:
 
   return err;
   }
 
/*
   Write the image file header info to Raw file handle outfile
*/
 
HSI_ERROR_CODE
WriteRawHeaderInfo(void)
   {
   short err=0;
   long  l;
   static char s3[40];
 
   bmfhdr.bfType           = BFT_BITMAP;
   bmfhdr.bfReserved1      = 0;
   bmfhdr.bfReserved2      = 0;
 
   bmihdr.biSize           = 40L;
   bmihdr.biPlanes         = 1;
   bmihdr.biClrUsed        = 0L;
   bmihdr.biCompression    = 0L;
   bmihdr.biXPelsPerMeter  = 0L;
   bmihdr.biYPelsPerMeter  = 0L;
   bmihdr.biClrImportant   = 0L;
 
   switch (bmihdr.biBitCount)
       {
       case 1:
           nColors = 2;
           wWidthBytes = (WORD)(bmihdr.biWidth * bmihdr.biBitCount+7)/8;
           break;
 
       case 4 :
           nColors = 16;
           wWidthBytes = (WORD)(bmihdr.biWidth * bmihdr.biBitCount+7)/8;
           break;
 
       case 8 :
           nColors = 256;
           wWidthBytes = (WORD)(bmihdr.biWidth * bmihdr.biBitCount+7)/8;
           break;
       
       case 16 :
           nColors = 0;
           wWidthBytes = (WORD)bmihdr.biWidth * 2;
           break;

       case 24 :
           nColors = 0;
           wWidthBytes = (WORD)bmihdr.biWidth * 3;
           break;

       }

   nWidthBytes = ALIGNULONG(wWidthBytes);
 
   bmihdr.biSizeImage = (DWORD)nWidthBytes *   /* calculate the size of */
                        bmihdr.biHeight;       /* image */
 
   /* calculate offset to bitmap data */
 
   bmfhdr.bfOffBits= SIZEOFBMPFILEHDR +
                     SIZEOFBMPINFOHDR +
                     nColors * SIZEOFRGBQUAD;
 
   /* calculate total size of this image */
 
   bmfhdr.bfSize   = bmihdr.biSizeImage +
                     bmfhdr.bfOffBits;
 
   _llseek(outfile,0L,0);             /* make sure we are at the BOF */
 
   copybmf2buf(&bmfhdr,s3);
 
   l = _lwrite(outfile,                            /* write the file header */
               (LPSTR)s3,
               SIZEOFBMPFILEHDR);
 
   if (l==0) {err=HSI_EC_DSTCANTWRITE; goto cu0;}
 
   copybmi2buf(&bmihdr,s3);
 
   l = _lwrite(outfile,                            /* write the info header */
               (LPSTR)s3,
               SIZEOFBMPINFOHDR);
 
   if (l==0) {err=HSI_EC_DSTCANTWRITE; goto cu0;}
 
   {
   LPSTR s3 = (LPSTR)malloc(nColors * SIZEOFRGBQUAD); 
 
   copyclrtbl2buf(clrtbl,s3,nColors);
 
   l = _lwrite(outfile,                            /* write color table */
               (LPSTR)s3,
               nColors * SIZEOFRGBQUAD); 
 
   _ffree(s3);
 
   if (l==0) {err=HSI_EC_DSTCANTWRITE; goto cu0;}
   }
 
   cu0:
 
   return err;
   }
 
/*
   Read the DIB header information and set up widthbytes.
 
   Global Variables:
 
   Infile, Outfile     File handle
   wWidthBytes         number of bytes per scanline in BYTE bounary
   nWidthBytes         number of bytes per scanline in LONG boundary
   clrtbl              Color table that contain 256 entries
*/
HSI_ERROR_CODE 
ReadRawHeaderInfo(FILE * infile)
   {
   short err=0;
   LONG    l,hdrsize,lsize;
   static char s4[40];
 
   /* get file header */ 
 
   if (_lread(infile,(LPSTR)s4,SIZEOFBMPFILEHDR) <=0)
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
 
   copybmf4buf(&bmfhdr,(LPSTR)s4);
 
   /* make sure this is a Bitmap file */
 
   if ( bmfhdr.bfType != BFT_BITMAP )
       {
       err = HSI_EC_UNSUPPORTED;
       goto cu0;
       }
 
   if (_lread(infile,(LPSTR)s4,SIZEOFBMPINFOHDR) <= 0)
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
 
  if ((BYTE)*s4 != 0x28) {err=HSI_EC_UNSUPPORTED;goto cu0;}


   copybmi4buf(&bmihdr,(LPSTR)s4);
 
   /* get number of colors */
 
   nColors = GetNumColor();
 
   /* load color table */
   
   if ( nColors > 0 )
       {
       LPSTR p= (LPSTR)malloc(SIZEOFRGBQUAD*nColors);
 
       if (!p) {err = HSI_EC_SRCCANTREAD;goto cu0;}
 
       if (_lread (infile,p,SIZEOFRGBQUAD*nColors) <= 0)
           {
           err = HSI_EC_SRCCANTREAD;
           _ffree(p);
           goto cu0;
           }
 
       copyclrtbl4buf(clrtbl,p,nColors);
       _ffree(p);
       }
 
   hdrsize = SIZEOFBMPINFOHDR +    /* calculate the correct */
             SIZEOFBMPFILEHDR +    /* header size */ 
             SIZEOFRGBQUAD * nColors;
 
   if (hdrsize != (LONG)bmfhdr.bfOffBits)    /* check whether header size is ok */
       {
       err=HSI_EC_INVALIDBMPHEADER;
       goto cu0;
       }
 

     switch (bmihdr.biBitCount)
       {
       case 16 :
       case 24 :
           wWidthBytes = (WORD)bmihdr.biWidth * 3;
           break;

       default :
           wWidthBytes = (WORD)( (bmihdr.biWidth * bmihdr.biBitCount ) +
                   7 ) / 8 * bmihdr.biPlanes;
           break;
       }

   /* normalize scanline width to LONG boundary */

   nWidthBytes  = ALIGNULONG(wWidthBytes);

   /* make sure the Bitmap file has correct FILE SIZE data */

   l = _llseek(infile,0L,1);  /* save current position */

   if (bmfhdr.bfSize==(DWORD)l)/* empty file! This check is result  */
       {                       /* from emtpy file generated by PSI. */
       err=HSI_EC_INVALIDBMPHEADER;
       goto cu0;
       }

   lsize = (DWORD)nWidthBytes * bmihdr.biHeight;

   if (bmihdr.biSizeImage == 0)        /* some DIB file has zero size in   */
       {                               /* this field. We will fill it in   */
       bmihdr.biSizeImage= lsize;
       }

   if ((LONG)bmihdr.biSizeImage != lsize)
       {
       bmihdr.biSizeImage = lsize;
       bmfhdr.bfSize = bmihdr.biSizeImage + bmfhdr.bfOffBits;
       }
 /*

   ** 'correct' (calculated file size), we will make sure it
   ** is correct. The host app should not rely upon the bfSize
   ** field for the actual (physical) file size. - 3/21/92 DH
   */

   bmfhdr.bfSize = bmihdr.biSizeImage + bmfhdr.bfOffBits;

   cu0:

   _llseek( infile, l, 0 );  /* restore prevous position */

   return err;
   }

 
#ifndef GEOSVERSION

/***************************************************************************
 
   FUNCTION    Parse the file extension position. 
               Return the pointer to caller.
 
****************************************************************************/
 
LPSTR ParseExt( LPSTR s )
   {
   while ( *s && *s != '.' && *s != ' ' )
            s++;
 
   if ( *s == '.' && *(s+1) == 0 )
       {
       *s = 0;
       return NULL;
       }
 
   if ( *s == '.' && *(s+1) != 0 )
            return s+1;
 
   return NULL;
   }
 
 
/*
   File open/close routines. Variable BIGBUFFER is used to decide
   whether we need to use our own buffering scheme or not. If set,
   maximun buffer allocation is attempted.
*/
 	    
HSI_ERROR_CODE 
OpenInOutFile(LPSTR szInfile, LPSTR szOutfile)
   {
   static char    str[80];
   short   err=0;
 
   	Infile = Outfile = NullHandle;
 
   if ( !szInfile )
       {
       err = HSI_EC_NOINPUTFILE;
       goto cu0;
       }
 
   _fstrcpy( (LPSTR)str, szInfile );
 
   Infile = fopen ( str,"r" );
 
   if ( !Infile )
       {
       err = HSI_EC_SRCCANTOPEN;
       goto cu0;
       }
 
   if ( !szOutfile )
       {
       err = HSI_EC_NOOUTPUTFILE;
       goto cu0;
       }
 
   _fstrcpy( (LPSTR)str, szOutfile );
 
   Outfile = fopen ( str, "w" );
 
   if ( !Outfile )
       {
       err = HSI_EC_DSTCANTOPEN; 
       goto cu0;
       }
 
   cu0:
 
   if (err)
       {
       if (Infile)  fclose(Infile);
       if (Outfile) fclose(Outfile);
       }
 
   return err;
   }

/*
   Open input file
*/

HSI_ERROR_CODE
OpenInFile(LPSTR szInfile)
   {
   static char    str[80];
   short   err=0;
 
   Infile = NullHandle;
 
   if ( !szInfile )
       {
       err = HSI_EC_NOINPUTFILE;
       goto cu0;
       }
 
   _fstrcpy( (LPSTR)str, szInfile );
 
   Infile    = fopen ( str, "r" );
 
   if ( !Infile )
       {
       err = HSI_EC_SRCCANTOPEN;
       goto cu0;
       }
 
   cu0:
 
   return err;
   }

/*
   Open output file 
*/

HSI_ERROR_CODE
OpenOutFile(LPSTR szOutfile)
   {
   short   err=0;
 
   Outfile = NullHandle;
 
   if ( !szOutfile )
       {
       err = HSI_EC_NOOUTPUTFILE;
       goto cu0;
       }

#ifdef dummy
   if (!*szOutfile)
       {
       /* the output file is actually a memory data. We will use Vitural */
       /* File I/O routines to process it. */

       Outfile = fopen(szOutfile,"wbm");   
       }
   else
#endif
       {
       static char    str[80];

       /* take care of Medium, Small model junk for DOS/Windows */
       _fstrcpy((LPSTR)str, szOutfile );  

       Outfile = fopen(str,"w");
       }

   if ( !Outfile )
       {
       err = HSI_EC_DSTCANTOPEN;
       goto cu0;
       }
 
   cu0:
 
   return err;
   }
 
/*
   Load the default color palette to global color table. Default color
   is defined as the color device being used when DoDOT is run. This
   routine is called during Initialization process. Color are loaded
   to the global color table clrtbl256[].
 
   If there are not 256 colors, then the first 2 or 16 entries are
   used for mono and 4 bit color device.  
*/

void
LoadSystemColorTable( RGBQUAD *clr, SHORT *n )
   {
   HDC         hdc;
   LPPALETTEENTRY      lppal=NULL;
   SHORT       i;
   WORD        nColors;
   short       err;
   HBITMAP     hbm=NULL;
   BITMAP      bm;
   BITMAPINFOHEADER    bi;
   static char s2[40];
 
   hdc = GetDC(NULL);
 
   hbm = CreateCompatibleBitmap(hdc,1,1); /* crate a dummy bitmap */
 
   GetObject(hbm, sizeof(BITMAP), (LPSTR)s2);
 
   copybmp4buf(&bm,s2); /* copy the buffer data to BITMAP */
 
   bi.biSize               = SIZEOFBMPINFOHDR;
   bi.biWidth              = bm.bmWidth;
   bi.biHeight             = bm.bmHeight;
   bi.biPlanes             = 1;
   bi.biBitCount           = bm.bmPlanes * bm.bmBitsPixel;
   bi.biCompression        = 0;
   bi.biSizeImage          = 0;
   bi.biXPelsPerMeter      = 0;
   bi.biYPelsPerMeter      = 0;
   bi.biClrUsed            = 0;
   bi.biClrImportant       = 0;
 
   nColors = DibNumColors((LPBITMAPINFO)&bi);
 
   *n = nColors;
 
   if (nColors==0) return;
 
   lppal = (LPPALETTEENTRY) malloc(nColors * sizeof(PALETTEENTRY));
 
#ifdef WINVERSION
   err=GetSystemPaletteEntries(hdc,0,nColors,lppal);
#else
   err=NULL;
#endif
 
   /* copy system palette to local palette */
 
   if (!err)   /* load default color */
       {
       switch (nColors)    
           {
           case 2 : 
               _fmemcpy(clr, clrtbl2,  sizeof(RGBQUAD)*nColors);
               break;
 
           case 16 : 
               _fmemcpy(clr, clrtbl16, sizeof(RGBQUAD)*nColors);
               break;
 
           case 256 : 
               _fmemcpy(clr, clrtbl256,sizeof(RGBQUAD)*nColors);
               break;
           }
       }
   else
       {
       for ( i=0; i<nColors; i++ )
           {
           clr[i].rgbRed    = lppal[i].peRed;
           clr[i].rgbGreen  = lppal[i].peGreen;
           clr[i].rgbBlue   = lppal[i].peBlue;
           }
       }
   cu0:
 
   if ( hdc )
      ReleaseDC(NULL, hdc );
 
   if (lppal)
       _ffree(lppal);
 
   if (hbm)
       DeleteObject(hbm);
 

 
   return;
   }
 
#ifndef GEOSVERSION
 
void
CloseInOutFile(void)
   {
   extern File * Infile, *Outfile;
 
   if ( Infile )
       {
       fclose ( Infile );
       Infile = NullHandle;
       }
 
   if ( Outfile )
       {
       fclose ( Outfile );
       Outfile = NullHandle;
       }
   }
 
 
 
 
/*
   File open/close routines. Variable BIGBUFFER is used to decide
   whether we need to use our own buffering scheme or not. If set,
   maximun buffer allocation is attempted.
*/
 
HSI_ERROR_CODE 
OpenRawInOutFile( LPSTR szInfile, LPSTR szOutfile )
   {
   short   err=0;
   /*LONG    l;*/
 
/**
   infile  = 0;
   outfile = 0;
**/
   if ( !szInfile )
       {
       err = HSI_EC_NOINPUTFILE;
       goto cu0;
       }
 
   infile = _lopen(szInfile,0);  /* open in read mode */
 
   if ( infile <= 0 )
       {
       err = HSI_EC_SRCCANTOPEN;
       goto cu0;
       }
 
   if ( !szOutfile )
       {
       err = HSI_EC_NOOUTPUTFILE;
       goto cu0;
       }

#if OWNRAWIO
   outfile = _lcreat( szOutfile,   
             0x00 );
                                   
#else
   outfile = _lcreat( szOutfile,   /* truncate the output file and */
              S_IREAD | S_IWRITE );/* return handle. Create if the file */
                                   /* does not exist already. */
#endif

   if ( outfile <= 0 )             /* file does not exist, create it */
       {
       err = HSI_EC_DSTCANTOPEN; 
       goto cu0;
       }
 
   _llseek(outfile,0L,2);
 
   cu0:
 
   if (err)
       {
       if (infile>0)  _lclose(infile);
       if (outfile>0) _lclose(outfile);
       }
 
   return err;
   }
 
HSI_ERROR_CODE 
OpenRawOutFile( LPSTR szOutfile )
   {
   short   err=0;
/***
   LONG    l;
 **/
   outfile = 0;
 
   if ( !szOutfile )
       {
       err = HSI_EC_NOOUTPUTFILE;
       goto cu0;
       }
 

#if OWNRAWIO
   outfile = _lcreat( szOutfile,   
             0x00 );
                                   
#else
   outfile = _lcreat( szOutfile,   /* truncate the output file and */
              S_IREAD | S_IWRITE );/* return handle. Create if the file */
                                   /* does not exist already. */
#endif
 
   if ( outfile <= 0 )     /* file does not exist, create it */
       {
       err = HSI_EC_DSTCANTOPEN; 
       goto cu0;
       }
 
   /*l =*/ _llseek(outfile,0L,2);
 
   cu0:
 
   if (err)
       {
       if (outfile>0) _lclose(outfile);
       }
 
   return err;
   }
 
 
HSI_ERROR_CODE 
OpenRawInFile(LPSTR szInfile)
   {
   short   err=0;

/**
   infile = 0;
**/
   if ( !szInfile )
       {
       err = HSI_EC_NOINPUTFILE;
       goto cu0;
       }
 
   infile = _lopen ( szInfile,0);  /* open in read mode */
 
   if ( infile <= 0 )
       {
       err = HSI_EC_SRCCANTOPEN;
       goto cu0;
       }
 
   cu0:
 
   if (err)
       {
       if (infile>0)  _lclose(infile);
       }
 
   return err;
   }
 
void
CloseRawInOutFile(VOID)
   {
   if ( infile>0 )
       {
       _lclose ( infile );
       infile=0;
       }
 
   if ( outfile>0 )
       {
       _lclose ( outfile );
       outfile=0;
       }
   }
 
#endif /* GEOSVERSION */ 
#endif
 
/*
   Option byte decide which color plane to save to the monochrome
   image.
 
   0x80    Black & White color
   0x40    Red plane
   0x20    Green plane
   0x10    Blue plane
 
   Black and White is compared against with the threshold value, which
   can be modified to obtain different result.
 
*/
 
void
dib2mono(  LPSTR   InBuffer, 
           LPSTR   OutBuffer, 
           /*WORD    wInLength,*/
           WORD    wOutLength,
           BYTE    bitcount,
           RGBQUAD *clrtbl,
           BYTE    option,
            strThreshold Thres )
   {
   DWORD inten;              /* color intensity */
   SHORT  i;
   BYTE    k;
   BYTE    red, green, blue;
 
   /* threshold is a percentage */
 
   Thres.Black = (BYTE)((float)Thres.Black * 255 / 100);
   Thres.Red   = (BYTE)((float)Thres.Red   * 255 / 100);
   Thres.Green = (BYTE)((float)Thres.Green * 255 / 100);
   Thres.Blue  = (BYTE)((float)Thres.Blue  * 255 / 100);
       
   /* no conversion for mono DIB */ 
 
   if ( bitcount == 1 ) 
       {
       _fmemcpy ( OutBuffer, InBuffer, wOutLength );
       return;
       }
 
   /* zap output buffer to all C_WHITE (ones) */
 
   _fmemset ( OutBuffer, ones, wOutLength );
 
   /* convert the color image to mono based upon desired option */
                              
   for ( i=0 ; i < (SHORT)bmihdr.biWidth ; i++ )
            {
       switch ( bitcount )
           {
           case 4 :
               k = (BYTE)( (InBuffer[i/2] >> ( (i%2) ? 0:4 )) & 0x0F);
 
               red   = (clrtbl+k)->rgbRed;
               green = (clrtbl+k)->rgbGreen;
               blue  = (clrtbl+k)->rgbBlue;
               break;
 
           case 8 :
               k = (BYTE)InBuffer[ i ];
 
               red   = (clrtbl+k)->rgbRed;
               green = (clrtbl+k)->rgbGreen;
               blue  = (clrtbl+k)->rgbBlue;
               break;
 
           case 24 :
               blue  = InBuffer[i*3]; 
               green = InBuffer[i*3+1]; 
               red   = InBuffer[i*3+2]; 
               break;
           }
 
#define    FLAG_COLOR      0x80
#define    FLAG_RED        0x40
#define    FLAG_GREEN      0x20
#define    FLAG_BLUE       0x10
 
       if ( option & FLAG_COLOR )
           {
           inten = (DWORD)11* blue +  /* calculate intensity for the color */
                      59* green +     /* triplet */
                      30 * red;
 
           if (inten < (DWORD)(Thres.Black * 100L) )
               OutBuffer[i/8] &= BitPatternAnd[i%8];
           }
 
       if ( (option & FLAG_RED) && (red < Thres.Red))
           OutBuffer[i/8] &= BitPatternAnd[i%8];
       
       if ( (option & FLAG_GREEN) && (green < Thres.Green))
           OutBuffer[i/8] &= BitPatternAnd[i%8];
       
       if ( (option & FLAG_BLUE) && (blue < Thres.Blue))
           OutBuffer[i/8] &= BitPatternAnd[i%8];
           
       }
   }
 
 
/* lfread,lfwrite are necessary only for DOS and Windows 3.0 */
int _lread(FILE * fh, LPSTR buff, DWORD siz)
{
  int fr;
 
  if( siz > 65535)           
    return(-1);

  fr = (int)fread( buff,1,siz,fh);
  if( !fr)
    return( -1 );
  return( fr );
}

#ifndef FLATMEMORY

void 
_ffmemcpy(LPSTR s, LPSTR t, DWORD l )
   {
   while ( l > (LONG)MAXREAD )
       {
       _fmemcpy(s,t,(WORD)MAXREAD);
 
       l -= (LONG)MAXREAD;
 
       s += (LONG)MAXREAD;
       t += (LONG)MAXREAD;
       }
 
   _fmemcpy(s,t,(WORD)l);
   }

#endif /* FLATMEMORY */


/* 
   Allocate the maximum memory starting from 32k
*/
 
MemHandle allocmax(int *size)
   {
   MemHandle mh = NullHandle;

   *size = (DWORD)MAXREAD;
 
again:
 
   mh = MemAlloc(*size, HF_DYNAMIC, 0);
 
   if (!mh)                   /* decrement buffer size by 4K until */
       {                       /* enough is found */
       *size -= STRIPSIZE;
 
       if (*size <= 0 )
           goto cu0;
 
       goto again;
       }
 
   cu0:
 
   return mh;
   }
 
#ifndef MACVERSION
 
/* 
   Allocate the maximum memory starting from 32k
*/
 
MemHandle allocmaxhandle(int FAR *size)
   {
   MemHandle h;
 
   *size = MAXREAD;
 
again:
 
   h = MemAlloc((WORD)*size, HF_DYNAMIC, 0);
 
   if (!h)                     /* decrement buffer size by 4K until */
       {                       /* enough is found */
       *size -= STRIPSIZE;
 
       if (*size <= 0 )
           goto cu0;
 
       goto again;
       }
 
   cu0:
 
   return h;
   }
#endif
 
#ifndef GEOSVERSION
/*
   Copy the content of input file to output file. Use 32K buffer
   raw I/O, should be very fast.
*/
 
HSI_ERROR_CODE
copyfile(LPSTR szInfile,LPSTR szOutfile)
   {
   short err=0;
   MemHandle	buf_mh;
   LPSTR buf=NULL;
   int n;
   DWORD size;

   err=OpenRawInOutFile(szInfile,szOutfile);
   if (err) goto cu0;
 
   buf_mh  = allocmax(&size);  /* allocate memory up to 32K  */
   buf = (LPSTR)MemLock(buf_mh);
   while ((n= _lread(infile,buf,size))>0)    /* copy the file body */
       _lwrite(outfile,buf,n);
 
   cu0:
 
   if (buf_mh) MemFree(buf_mh);
 
   CloseRawInOutFile();
   return err;
  
   }
#endif
 
/* 
   Check the color table and decide whether it is a gray image.
   Return TRUE if it is gray, FALSE if not.
*/
 
BOOL IsGray(WORD nColors, RGBQUAD *clrtbl)
   {
 
   SHORT i;
 
   if (nColors == 0)   /* 24bit image */
       return FALSE;
 
   /* go through all color triplets in header and compare their */
   /* RGB values */
 
   for (i=0;i<nColors;i++)
       {
 
       if (clrtbl[i].rgbRed != clrtbl[i].rgbGreen ||
           clrtbl[i].rgbRed != clrtbl[i].rgbBlue )
          return FALSE;
 
       }
 
   return TRUE;    /* RGB are all equal */
 
   }
 
/*
   Display percentage based upon range and value passed.  A message pointer
   is optional for displaying messages along with the percentage.  If range
   is zero, then the percentage is not used. Only the message is 
   displayed.
 
   type can be:
 
       0:       Default, percentage
       1:       Thermostate
 
   This routine is used among different environment.
*/

#ifndef	GEOSVERSION 
#ifdef MACVERSION
PASCAL SHORT
#else
SHORT FAR PASCAL
#endif
ShowStatus(SHORT percent)
   {
 
#ifdef DOSVERSION
 
   /* DOS version */

   if (kbhit())
       return HSI_EC_ABORT;

   printf("%d%% \b\b\b\b\b\b\b",percent);
 
#endif
#ifdef sun
printf("%d%% \b\b\b\b\b\b\b",percent);
#endif

#ifdef WINVERSION
#endif
 
   return 0;
 
   }

#endif
 
#ifndef MACVERSION
#ifndef GEOSVERSION
 
void lunlink(LPSTR s)
   {
   static char s1[80];
 
   _fstrcpy((LPSTR)s1,s);
   unlink(s1);
   }
#endif
 
void lrename(LPSTR s, LPSTR t)
   {
   static char s5[80];
   static char t1[80];
 
   _fstrcpy((LPSTR)s5,s);
   _fstrcpy((LPSTR)t1,t);
 
   rename(s5,t1);
   }
 
#endif
 
 
/*
   Flip the buffer backward so that 1st byte will be last and last byte
   will be 1st byte.
*/
 
void flipbuf(LPSTR s,WORD n)
   {
   BYTE c;
   SHORT  i=0;
 
   while (n--)
       {
       if (i>=n) 
           return;                 /* all done when i and n meet   */
 
       c       = *(s+i);           /* save the begining byte       */
       *(s+i)  =(BYTE)*(s+n-1);    /* put the back to front        */
       *(s+n-1)=(BYTE)c;
       i++;
       }
   }
 
 
/*
   Read the file header to decide what type of BMP file this is.
 
   Return 
       FALSE       File error
 
       BMP_WIN20   Windows 2.x 
       BMP_WIN30   Windows 3.0
       BMP_PM10    Presentation Manager 1.x
 
*/
 
#ifndef MACVERSION
 
#include "isfile.h"
 
HSI_ERROR_CODE HSICheckBMP ( FILE * szInfile )
   {
   static  char   dibbuf3[80];
   SHORT   err=0;
   WORD    wHeader;
   int nRead;
   /*SHORT   infile;*/
   FILE * infile;

 /*
   infile = _lopen( szInfile, 0);
      open it in read mode 
   if( infile <= 0 )                    cannot open 
       {
       err = HSI_EC_SRCCANTREAD;       return FALSE 
       goto cu0;
       }
*/
   infile = (FILE *)szInfile;
   nRead = fread ((LPSTR)dibbuf3,1,40,infile);
 
   if ( nRead <= 0 )                   /* read error, return FALSE */
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
 
   wHeader = *(LPWORD)&dibbuf3[0];         /* get 1st two bytes */
 
   if ( wHeader == BFT_BITMAP )        /* Windows 3.0 or PM DIB */

       {
       wHeader = (WORD)*(LPDWORD)&dibbuf3[14];   /* get biSize */
 
       if ( wHeader == 0x28 )
          err = BMP_WIN30;             /* Windows 30 BMP */
       else
       if ( wHeader == 0x0C )
          err = BMP_PM10;              /* OS/2 PM BMP */
       else
          err = 0;                     /* neither, return FALSE */
 
       goto cu0;
       }
 
 
   if ( dibbuf3[11] == 1 ||                /* check for window 2.0 bitmap */
        dibbuf3[11] == 4 ||                /* assuming BitsPixel should be */
        dibbuf3[11] == 8 )                 /* 1, 4 or 8 */
        {
        err = BMP_WIN20;
        goto cu0;
        }
 
   err = 0;                            /* format not recognized, return */ 
                                       /* FALSE */

   cu0:
  fseek( infile, 0L, SEEK_SET); /* goto begining of file */
 /*
   if (infile )                        close the file if open 
       _lclose(infile);
 */
   return err;                         /* return error code */
 
   }
 
#endif








