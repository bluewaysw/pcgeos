/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pcxload.c

AUTHOR:		Maryann Simmons, Feb 20, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/20/92   	Initial version.

DESCRIPTION:
	

	$Id: pcxload.c,v 1.1 97/04/07 11:28:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
 
NAME   LOADPCX.C
 
PURPOSE    Convert PCX file to DIB format. PCX file might have
           the following variabtions:
 
           monochrome  1 bit per pixel. DIB contain 2 color entry
                       00 00 00 and FF FF FF.
 
           4 colors    2 bit per pixel in PCX file. Will be converted
                       to 4 bpp DIB format, with first colors set
                       in the palette and rest of them zeros. We
                       did not set biClrUsed in BITMAPINFOHEADER to
                       4, since it is very unlikely the case. 
                       But, it can be the case if needed.
 
           8 colors    3 planes. Will be converted to 4 bpp in DIB.
                       First 8 colors in DIB palette will be set and
                       rest will be zeros.
 
           16 colors   4 planes, convert RGBI to IRGB.
 
           256 colors  1 byte per pixel, color palette is obtained

                       from the end of PCX file.  There should be
                       a 0x0C at 769th byte count from the end.
 
 
History
 
   01/30/90    Separated from convert.c 
               Per Rober Hanes input, PC World, looking into 
               PCX color problem.
 
   01/31/90    Fixed problem with RGBI alignment. 4 plane PCX 
               file use BGRI sequence(brain dead!)
 
   04/07/90    Support DIB metafile
 
   04/14/90    Support 2/8 bpp, 3/4 planes PCX files, also
               support monochrome.
 
   08/20/90    Use 8 color palette for 3 plane image.
 
   03/12/91    Ignore color palette for version 3.0.  Version 3.0 does
               use the grayscale palette, however.
   05/25/91    Start to port to SUN4
   06/01/91    Ported to SUN4 using C++ 2.1 compiler

*/

/*
#include "Internal/prodFeatures.uih"
*/ 
#ifndef __WATCOMC__
#pragma Comment("@" __FILE__);
#endif
#pragma Code ("MainImportC");

#include "hsimem.h"
#include "hsierror.h"
 
#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>
#include <Ansi/stdlib.h>     /* for _fmemxxx calls */
/*
#include <fcntl.h>
*/ 

#include "pcx.h"

 
/* function prototypes */
 
HSI_ERROR_CODE EXPORT  HSILoadPCX( FILE *, FILE *, LPCNVOPTION);
BOOL         encget          ( int *, int *);
HSI_ERROR_CODE   Write4Colors    ( LPSTR);
HSI_ERROR_CODE   FlushItOut      ( LPSTR );
 
/* assembly routine written by Gary Carter to convert 4 color PCX */
/* image to 4 color DIB scanline */
 
void rgb2dib(LPSTR,LPSTR, WORD);
 
/* color table */
struct rgbTriple
   {
   BYTE red, green, blue;
   };
 
WORD               bmWidthBytes;
LPSTR              szOutBuf=NULL;
MemHandle          szOutBufHandle;
struct pcx_header  Importheader;
 
WORD   csize, cidx;
int    size;
LPSTR  inBuf;
MemHandle inBufHandle;


int    Importl;
long   Importll;

MemHandle    lpstrHandle;

LPSTR        lpstr;
static int   Importtsize;
int          theight,tidx;
 
 
int                            /* read next byte from input buffer and */
GetNextByte(BYTE *i)           /* update the index */
   {
   if (cidx >= csize)
       {
       csize = _lread(Infile,(LPSTR)inBuf,size);
       if (csize <= 0 )
           return -1;  /* end of file encountered */
 
       cidx=0;
       }
 
   *i = inBuf[cidx++];
 
   return 1;
   }
 
 
 
/*
 
   FUNCTION        HSILoadPCX( FILE * szInfile, FILE * szOutfile )
 
   PURPOSE                Load PCX file to Windows 3.0 DIB format
 
*/
 
HSI_ERROR_CODE EXPORT
HSILoadPCX( FILE * szInfile, FILE * szOutfile, LPCNVOPTION szOption )
   {
   int        /*num_y_lines,             # of scan lines        */
              nx, ny,/* bmPlane,*/ DONE,/* count=0,*/ i, j,
              tPlane=0;
 
   static int cnt;
   static int chr; /* I spent over 8 hours on decoding bug which turned  */
                   /* that I use UNSIGNED INT for CHR !@#$#@$  12/4/88   */
 
   int        p, index;
   WORD       idx[8] /*,*q*/;
   MemHandle  szOutBufferHandle;
   LPSTR      szOutBuffer=NULL;
 /*  char       str[80];*/
 /*   WORD       wLength;*/
 /*  OFSTRUCT   of;*/
   short      nRead, /*nWrite,*/ err=0;
   DWORD      l, resX, resY;
   static char ptr[1024];
   LPSTR  s=(LPSTR)ptr;
 
   szOutBuf = NULL;
   inBuf    = NULL;
   lpstr    = NULL;
   /* open input and output files */
 /***
   already open(ms)
   err = OpenRawInOutFile( szInfile, szOutfile );
 
   if ( err ) goto cu0;
 *****/

   /* read off file PCX header info to buffer  */
/*Infile and Outfile are globals defined in dib.c(ms) */ 

   Infile = (FILE *)szInfile;
   Outfile =(FILE *)szOutfile;

   nRead = _lread( Infile,
                   (LPSTR)s, 
                   SIZEOFPCXHEADER );
 
   if ( nRead != SIZEOFPCXHEADER)
            {
            err = HSI_EC_SRCCANTREAD;
            goto cu0;
            }
 
   Importheader.manf         = *s++;
   Importheader.version      = *s++;
   Importheader.encoding     = *s++;
   Importheader.bpp          = *s++;
   Importheader.Xmin         = GetINTELWORD(s); s+=2;
   Importheader.Ymin         = GetINTELWORD(s); s+=2;
   Importheader.Xmax         = GetINTELWORD(s); s+=2;
   Importheader.Ymax         = GetINTELWORD(s); s+=2;
   Importheader.H_res        = GetINTELWORD(s); s+=2;
   Importheader.V_res        = GetINTELWORD(s); s+=2;
   for (i=0;i<16;i++)
       for (j=0;j<3;j++)
           Importheader.colormap[i][j] = *s++;

   Importheader.reserve      = *s++;
   Importheader.nplanes      = *s++;
   Importheader.bpl          = GetINTELWORD(s); s+=2;
   _fmemcpy(Importheader.tag,s,60);
   
   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;
 
   bmihdr.biSize       = (DWORD)40;
   bmihdr.biWidth      = Importheader.Xmax - Importheader.Xmin + 1 ;
   bmihdr.biHeight     = Importheader.Ymax - Importheader.Ymin + 1 ; /* # of scanlines */
   bmihdr.biPlanes     = 1;
   bmihdr.biClrUsed    = 0L;
   nColors             = 0;

#if FLOPPY_BASED_DOCUMENTS

   if ((((unsigned long)Importheader.H_res) * 
        ((unsigned long)Importheader.V_res) * 
        ((unsigned long)Importheader.nplanes) / 8) > MAX_TOTAL_FILE_SIZE) {
                   err = HSI_EC_FILETOOBIG;
                   goto cu0;
		 }
#endif
 
   switch ( Importheader.nplanes )
       {
       case 1 :
           switch ( Importheader.bpp )
               {
               case 8 :
                  bmihdr.biBitCount   = 8;
                  nColors             = 256;
                  break;
 
               case 2 :
                  bmihdr.biBitCount   = 4;
                  nColors             = 16;
                  break;
 
               case 1 :
                  bmihdr.biBitCount   = 1;
                  nColors             = 2;
                  break;
 
               default :
                   err = HSI_EC_UNSUPPORTED;
                   goto cu0;
               }
           break;
 
       case 2 :
       case 4 :
           bmihdr.biBitCount   = 4;
           nColors             = 16;
           break;

       case 3 :
	   if ( Importheader.bpp == 8)
	       {
		   /* this is 24-bit- not supported yet- Maryann */
		   err = HSI_EC_UNSUPPORTED;
		   goto cu0;
	       }
           bmihdr.biBitCount   = 4;
           nColors             = 16;
           break;
 
       default :
           err = HSI_EC_UNSUPPORTED;
           goto cu0;
       }
 
   bmihdr.biCompression   = 0L;
   bmihdr.biXPelsPerMeter = 0L;
   bmihdr.biYPelsPerMeter = 0L;
   bmihdr.biClrImportant  = 0L;
 
   /* header.bpl is on BYTE boundary, NOT on WORD boundary */
 
   if ( bmihdr.biBitCount == 8 )
/*           bmWidthBytes = bmihdr.biWidth + bmihdr.biWidth%2; */
           bmWidthBytes = Importheader.bpl;
   else
           bmWidthBytes = (bmihdr.biWidth+15)/16*2;
 
   /* calculate real size in byte of one scanline */
 
   wWidthBytes = ( (bmihdr.biWidth * bmihdr.biBitCount ) + 
                   7 ) / 8 * bmihdr.biPlanes;
 
   /* normalize scanline width to LONG boundary */
 
   nWidthBytes = ALIGNULONG(wWidthBytes);

   bmihdr.biSizeImage = (DWORD)nWidthBytes * bmihdr.biHeight;
 
   /* calculate offset to bitmap data */
 
   bmfhdr.bfOffBits   = SIZEOFBMPFILEHDR +
                        SIZEOFBMPINFOHDR +
                        nColors * SIZEOFRGBQUAD;
 
   /* calculate total size of this image */
 
   bmfhdr.bfSize      = bmihdr.biSizeImage +
                        bmfhdr.bfOffBits;

   /* Calculate the resolution of the bitmap, in pixels/meter. The
    * resolution found in PCX files is generally one of the following:
    *	- resolution in DPI (we'll enfore limitos of 30 -> 360
    *	- screen size (we'll look for 640x480, 640x350, 640x200 & 320x200
    *	- some other random garbage, in which we'll assume 72 DPI
    */
   resX	= (DWORD)Importheader.H_res;
   resY	= (DWORD)Importheader.V_res;

   /*
    * Check for standard screen sizes
    */
   if (((resX == 640) && ((resY == 480) || (resY == 320) || (resY == 200))) ||
       ((resX == 320) && (resY == 200))) {
       	resX = resX * 72 / 640;
	resY = resY * 72 / 480;
   }

   /*
    * Check to ensure resolution isn't the bitmap size (or size -1), and
    * that each resolution is within reasonable bounds.
    */
   if (((resX == bmihdr.biWidth) && (resY == bmihdr.biHeight)) ||
       ((resX == (bmihdr.biWidth-1)) && (resY == (bmihdr.biHeight-1))) ||
       (((resX > 360) || (resX < 36) || (resY > 360) || (resY < 30)))) {
       resX = 72;
       resY = 72;
   }

   /*
    * Resolution is in pixels per inch - want pixels/meter
    */
   bmihdr.biXPelsPerMeter =  resX * 10000 / 254;
   bmihdr.biYPelsPerMeter =  resY * 10000 / 254;

   /* write out file header */
 
   copybmf2buf(&bmfhdr,ptr);

   l = _lwrite (Outfile,
                (LPSTR)ptr, 
                SIZEOFBMPFILEHDR);
 
   if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
   /* write out header info  */
 
   copybmi2buf(&bmihdr,ptr);

   l = _lwrite(Outfile,
               (LPSTR)ptr,
               SIZEOFBMPINFOHDR);
 
   if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
   /* write out color palette for color images */
 
   if ( bmihdr.biBitCount == 1 )   /* monochrome bitmap has two entries */
       {                           /* in the color table */
       clrtbl[0].rgbBlue     = 0x00;
       clrtbl[0].rgbGreen    = 0x00;
       clrtbl[0].rgbRed      = 0x00;
       clrtbl[0].rgbReserved = 0x00;
 
       clrtbl[1].rgbBlue     = 0xFF;
       clrtbl[1].rgbGreen    = 0xFF;
       clrtbl[1].rgbRed      = 0xFF;
       clrtbl[1].rgbReserved = 0x00;
       }
   else
   if ( Importheader.bpp == 2 )
       {
       for ( i=0;i < 4 ; i++)
           {
           clrtbl[i].rgbBlue   = Importheader.colormap[i][2];
           clrtbl[i].rgbGreen  = Importheader.colormap[i][1];
           clrtbl[i].rgbRed    = Importheader.colormap[i][0];
           clrtbl[i].rgbReserved  = 0x00;
           }
 
       /* color is swapped */
 
       clrtbl[1].rgbBlue   = Importheader.colormap[2][2];
       clrtbl[1].rgbGreen  = Importheader.colormap[2][1];
       clrtbl[1].rgbRed    = Importheader.colormap[2][0];
 
       clrtbl[2].rgbBlue   = Importheader.colormap[1][2];
       clrtbl[2].rgbGreen  = Importheader.colormap[1][1];
       clrtbl[2].rgbRed    = Importheader.colormap[1][0];
 
       _fmemset ( &clrtbl[4].rgbBlue, zero, 12 * sizeof(RGBQUAD));
 
       }
   else
   if ( Importheader.nplanes == 3 )     /* 4 bits/pixel */
       {
 
       _fmemset ( clrtbl,                  /* set to all zeros */
                  zero, 
                  sizeof(RGBQUAD)*16 );
 
       _fmemcpy ((LPSTR)clrtbl,                  /* copy default 8 color */
                 (LPSTR)clrtbl8,                 /* pcx palette */
                 sizeof(RGBQUAD)*8 );
 
       /* write the color map out */
 
       }
 
   else 
   if (Importheader.nplanes == 4 )
       {
       BOOL fGray=FALSE;
 
       /* make sure color is not NULL. If NULL, use the default color */
       /* otherwise, use what is there */
 
       for ( i=0;i!=16;i++)
           {
           if ( Importheader.colormap[i][0] != 0 ||
                Importheader.colormap[i][1] != 0 ||
                Importheader.colormap[i][2] != 0 )
                {
                fGray = TRUE;  /* color given, use it! */
                break;
                }
           }
 
/* Version 3.0 does not have color pallette definition */
 
       if (Importheader.version == 3)
           {
           fGray = FALSE;
           }
 
/* !NOTE! Once we have a dialog box in place, use can decide to */
/*        load the image with default system color table! */
 
       if (fGray)
           {
           /* use the gray map in the PCX file */
 
           for ( i=0 ; i < 16 ; i++ )
                    {
               /* the color in PCX is stored B-G-R ! which is not what */
               /* the DOC say. This work! */
 
               clrtbl[i].rgbBlue   = Importheader.colormap[i][2];
               clrtbl[i].rgbGreen  = Importheader.colormap[i][1];
               clrtbl[i].rgbRed    = Importheader.colormap[i][0];
               clrtbl[i].rgbReserved  = 0x00;
               }
           }
       else
           {
           /* use the default palette for 8/16 color PCX file (took me */
           /* a while to figure this out! 4/17/90 */
 
           _fmemcpy ( clrtbl, clrtbl16, sizeof(RGBQUAD)*16 );
           }
 
       /* write the color map out */
 
       if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
       }
 
   /* take care of 256 color. Color is stored at the end of PCX file */
   /* the version has to be 5. And the 769th byte from the end should */
   /* be 0x0C ! */
 
   if ( bmihdr.biBitCount == 8 && Importheader.version == 0x05 )
       {
       int     i/* j*/;
       BYTE    c;
       long    dw, /*lfp*/ cfp;
       struct rgbTriple rgbClr;
 
       cfp = _llseek(Infile,0L,1); /* save current file position */
 
       dw = -1L * (long)769;
 
       _llseek( Infile, dw, 2 );
 
       _lread ( Infile,(LPSTR)&c,1);
 
       if ( c == 0x0C )    /* should be 0x0C to indicate the 256 RGB */
           {               /* triplets follow ! */
           for ( i=0; i < 256; i++)
               {
               _lread (Infile,
                       (LPSTR)&rgbClr, 
                       sizeof(struct rgbTriple));
 
               clrtbl[i].rgbBlue   = rgbClr.blue;
               clrtbl[i].rgbGreen  = rgbClr.green;
               clrtbl[i].rgbRed    = rgbClr.red;
               clrtbl[i].rgbReserved  = 0x00;
               }
 
           }
 
       /* we will load anyway for 256 color image without color palette */
       /* most likely, the image will be blank, since color palette will */
       /* be all zeros! */
 
       _llseek ( Infile, cfp, 0 );   /* seek to current file position */
 
     }
 
   copyclrtbl2buf(clrtbl,ptr,nColors);
  
   l = _lwrite(Outfile,(LPSTR)ptr,nColors*SIZEOFRGBQUAD);
   if (l<=0) 
       {
       err=HSI_EC_DSTCANTWRITE;
       goto cu0;
       }


   for (i=0;i!=bmihdr.biBitCount;i++)        
       idx[i]=0;
/* 
   szOutBuffer=(LPSTR)malloc(max(nWidthBytes,bmWidthBytes*Importheader.nplanes));
*/ 
   szOutBufferHandle = 
                  MemAlloc(max(nWidthBytes,bmWidthBytes*Importheader.nplanes),
			   HF_DYNAMIC,0);
   szOutBuffer =  MemLock(szOutBufferHandle);

   if (!szOutBuffer)
            {
            err = HSI_EC_NOMEMORY;
            goto cu0;
            }
/*
   szOutBuf =(LPSTR)malloc(max(nWidthBytes,bmWidthBytes*Importheader.nplanes));
*/
   szOutBufHandle= MemAlloc(max(nWidthBytes,bmWidthBytes*Importheader.nplanes),
			    HF_DYNAMIC,0);
   szOutBuf = MemLock(szOutBufHandle);

   if (!szOutBuf)
            {
            err = HSI_EC_NOMEMORY;
            goto cu0;
            }
 
   /* initialize buffer to zero  */
 
   _fmemset((LPSTR)szOutBuffer, (BYTE)zero, nWidthBytes );
 
   /* this is a special case where Importheader.bpl * 4 is greater than */
   /* nWidthBytes. e.g. width=501, bpl=64, yet nWidthBytes=252 */
 
   if ( bmihdr.biBitCount == 4 )                   
      bmWidthBytes = nWidthBytes/4;
 
   DONE=0;
   nx=ny=0;
 
   /* DIB has IRGB alignment, not IBGR alignment as palette index. This */
   /* took me 10 hours to figure out! shiiiiiittt...  The input PCX file */
   /* has BGRI format. */
 
   p=0;
   tPlane  = 0;
   index   = 0;
 
   inBufHandle = allocmax(&size);            /* allocate input buffer */
   inBuf  = MemLock(inBufHandle);

   if (!inBuf) {err=HSI_EC_NOMEMORY;goto cu0;}
 
   csize = _lread(Infile,(LPSTR)inBuf,size);
   cidx=0;
 
   /* fseek to the end of file first, since we will start writing */
   /* each scanline backward */
 
   Importll= _llseek ( Outfile, (long)bmfhdr.bfSize, 0 );
   if (Importll== -1L) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}

 
   
   lpstrHandle = allocmax(&Importtsize);       /* allocate buffer for output */
   lpstr = MemLock(lpstrHandle);
   if (!lpstr) {err=HSI_EC_NOMEMORY; goto cu0; }
 
   theight = Importtsize / nWidthBytes;
   tidx    = theight;
   if ( tidx == 0 )
     {
       err = HSI_EC_NOMEMORY;
       goto cu0;
     }
   while (!DONE) 
      {   
      if ( !encget( &chr, &cnt) ) /* Decode compressed file  */
              goto cu0;
 
      for (i=0; i != cnt && DONE == 0; i++)
          {
 
          /* write character found to temporary buffer  */
 
          szOutBuffer[ index++ + ( p * bmWidthBytes ) ] = chr;
 
          if ( ++nx >= Importheader.bpl )
             {
             nx = 0;
 
             if ( ++tPlane >= Importheader.nplanes )
                {
                /*int k;*/
 
             /* check whether user wish to stop or pause */
             /* CheckUserAbort(bmihdr.biHeight,ny); */
 
                tPlane = 0;
 
                /* write the buffer to output file */
 
               err=FlushItOut( szOutBuffer );
               if (err) goto cu0;
 
               if ( ++ny >= bmihdr.biHeight ) /* done with current bitplane  */
                   DONE = 1;
 
               if (szOption && szOption->Disp)       
                 {
                 static int clinel;
                 int        ii;
 
                 ii = (int)((DWORD) ny * 100L / (DWORD)bmihdr.biHeight);
 
                 if (ii !=clinel)
                     {
                     clinel = ii;
                     err=(*(szOption->Disp))(clinel);
                     if (err) goto cu0;
                     }
                 }
              }
 
         index=0;
         p++;
 
         if ( p >= Importheader.nplanes )
             p = 0;
 
         }
       }
    }
 
   /* flush the buffer to file if data is in the buffer */
 
   if (tidx != theight)       /* flush the buffer to tmp file */
       {
       _llseek( Outfile,      /* rewind first before write */
                -1L * (long)nWidthBytes * (long)(theight-tidx), 
                1 );
 
       l= _lwrite( Outfile,
                   lpstr+      /* flush the buffer out to tmp file */
                       nWidthBytes*tidx, 
                   nWidthBytes*(theight-tidx));
 
       if (l==0) {err=HSI_EC_DSTCANTWRITE;goto cu0;}
       }
 
   cu0:
 
   if (szOutBuffer)   /* _ffree(szOutBuffer);*/
     MemFree(szOutBufferHandle);

   if (szOutBuf)    /* _ffree(szOutBuf);*/
     MemFree(szOutBufHandle);

   if (inBuf)         /* _ffree(inBuf);*/
     MemFree(inBufHandle);

   if (lpstr)        /*  _ffree(lpstr);*/
     MemFree(lpstrHandle);
 /*
   CloseRawInOutFile();               release file buffer 
 */
   return err;        
   }
 
/* #pragma Code (); */

/* #pragma Code ("ExportCCode1"); */
 
/* 
 * Encode next data bytes 
 */
 
BOOL         encget( int *pbyt,  /* bit value */
               int *pcnt ) /* bit count */
   {
   static BYTE i;
 
   *pcnt = 1;                           /* bit count default to 1                  */
 
   if (!GetNextByte((BYTE *)&i))
       return FALSE;
 
   if (0xc0 == (0xc0 & i )) 
            {                 
       /* one more data byte to read          */
 
            *pcnt = 0x3f & i;        /* get 6 bits counter */
 
            if (GetNextByte((BYTE *)&i) != 1 )
                    return FALSE;
            }
 
   *pbyt = i;
   return TRUE;
   }
 
/*
   Convert the output buffer to DIB format and write out to
   DIB file. Be aware that the file is written backward!
*/
 
HSI_ERROR_CODE
FlushItOut( LPSTR szOutBuffer )
   {
   short err=0;
 
   switch ( bmihdr.biBitCount )
       {
       case 4 :
           switch ( Importheader.bpp )
               {
               case 2 :
                   err=Write4Colors ( szOutBuffer );
                   if (err) goto cu0;
 
                   break;
 
               default :
                  rgb2dib( (LPSTR)szOutBuffer,     /* rgb input */
                           (LPSTR)szOutBuf,        /* dib output */
                           (WORD)nWidthBytes );
 
                  break;
               }
 
           break;
 
       case 1 :
       case 8 :
 
           _fmemcpy(szOutBuf,szOutBuffer,nWidthBytes);
 
           break;
       }
 
   tidx--;
 
   _fmemcpy(lpstr + tidx*nWidthBytes,    /* copy output scanline */
            (LPSTR)szOutBuf,             /* to output buffer */
            nWidthBytes);
 
   if (tidx==0)            /* flush the buffer to tmp file */
      {
      _llseek( Outfile,      /* rewind first before write */
               -1L * (long)nWidthBytes * (long)theight, 
               1 );
 
      Importl = _lwrite( Outfile,
                   lpstr,      /* flush the buffer out to tmp file */
                   (WORD)((DWORD)nWidthBytes*theight) );
 
      if (Importl==0) {err=HSI_EC_DSTCANTWRITE;goto cu0;}
       
      _llseek( Outfile,      /* rewind first before write */
               -1L * (long)nWidthBytes * (long)theight, 
               1 );
 
      tidx=theight;
      }
 
 
   cu0:
 
   return err;
   }
 
 
/*
   Input PCX file has 2 bits per pixel, 4 color image. DIB file support
   only 4 bit image, we need to expand the 2 bit per pixel to 4.
 
 
*/
 
/* Use lookup table to increase the performance. Each nibble range  */
/* from 0 to 15, the table contain the BYTE value for eacah nibble. */
 
BYTE LookUpTable[16] =
       {
           0x00,       /* 0000 */
           0x02,       /* 0001 */
           0x01,       /* 0010 */
           0x03,       /* 0011 */
           0x20,       /* 0100 */
           0x22,       /* 0101 */
           0x21,       /* 0110 */
           0x23,       /* 0111 */
           0x10,       /* 1000 */
           0x12,       /* 1001 */
           0x11,       /* 1010 */
           0x13,       /* 1011 */
           0x30,       /* 1100 */
           0x32,       /* 1101 */
           0x31,       /* 1110 */
           0x33,       /* 1111 */
       };
/*
       {
           0x00,       // 0000
           0x01,       // 0001
           0x02,       // 0010
           0x03,       // 0011
           0x10,       // 0100
           0x11,       // 0101
           0x12,       // 0110
           0x13,       // 0111
           0x20,       // 1000
           0x21,       // 1001
           0x22,       // 1010
           0x23,       // 1011
           0x30,       // 1100
           0x31,       // 1101
           0x32,       // 1110
           0x33,       // 1111
       };
*/
 
 
HSI_ERROR_CODE 
Write4Colors ( LPSTR szOutBuffer )
{
   LPSTR p;
   register BYTE c;
   register int  i/*,j,k*/;
   short err=0;
 
   p = szOutBuf;
 
   /* process each 2 bpp pixel and write it to a 4 bpp buffer */
   /* each byte will be converted to 2 bytes */
 
   for ( i=0 ; i < Importheader.bpl ; i++ )
       {
 
       /* get next byte from input buffer that has 4 pixel. */
 
       c = (*szOutBuffer >> 4) & 0x0F;   /* get first nibble */
 
       *p++ = LookUpTable[c];
 
       c = *szOutBuffer++ & 0x0F;        /* get 2nd nibble */
 
       *p++ = LookUpTable[c];
 
       }
 
   cu0:
 
   return err;
 
   }
 

/*
   rgb2dib

Description

   convert 4-bitplaned image scanline to 4 bpp packed image scanline
   For the INTEL version, we have rgbdib.asm assembly routine to perform
   the same conversion.  This C code is used for easy porting.
   It is possible, when necessary, to code the equivalent assembly for other
   CPU architechure. (Why bother, the machine will be fast enough!! )

   The PCX file is R-G-B-I where DIB is I-B-G-R
*/


void rgb2dib(LPSTR ibuf,LPSTR obuf,WORD n)
   {
   int i=n/4,j,k,l=0,m;
   LPSTR ar[4];

   _fmemset(obuf,0,n);

   ar[3] = ibuf;
   ar[2] = ibuf+i;
   ar[1] = ibuf+i*2;
   ar[0] = ibuf+i*3;

   for (j=0;j<i;j++)
       {
       for (m=0;m<8;m++)
           {
           for (k=0;k<4;k++)
               {
               if (ar[k][j] & BitPatternOr[m])
                   obuf[l/8] |= BitPatternOr[l%8];
               l++;
               }
           }
       }
 }

#pragma Code ();


