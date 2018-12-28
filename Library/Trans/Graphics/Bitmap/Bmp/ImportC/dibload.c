/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dibload.c

AUTHOR:		Maryann Simmons, Mar 30, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	3/30/92   	Initial version.

DESCRIPTION:
	

	$Id: dibload.c,v 1.1 97/04/07 11:26:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*

   Routines to load various bitmap file into Windows 3.0 DIB.

   Notice that the caller can invoke HSILoadBMP() which performs 
   auto-detection that will call the proper module.  The caller can
   call the individual module is so desired.

   HSILoadBMP()        Load BMP file (Windows 2.x, Windows 3.0, OS/2)

   HSILoadDIB  ()      Load 3.0 to 3.0 (ha..)
   HSILoadPMDIB()      Load Presentation Manager DIB to Windows 3.0
   HSILoadBMP20()      Load Windows 2.0 bitmap to Windows 3.0 DIB

   rgb2dib() Because it was only defined in pcxload??
12/28/91 Now support RLE -DH

*/

#ifndef __WATCOMC__
#pragma Comment ("@" __FILE__);
#endif
#pragma Code ("MainImportC");

#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>        /* used for memcpy() and memset() */
#include <Ansi/stdlib.h>



#define BMP_WIN20      5
#define BMP_WIN30      6
#define BMP_PM10       7
  

HSI_ERROR_CODE EXPORT  HSILoadPMDIB (FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE EXPORT  HSILoadBMP20 (FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE EXPORT  HSILoadDIB   (FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE HSILoadWRLE       (VOID);

HSI_ERROR_CODE    LoadBMP20DIB     (void);
HSI_ERROR_CODE    LoadBMP204       (void);
HSI_ERROR_CODE    HSICheckBMP      (FILE *);
HSI_ERROR_CODE RLEUncmpr(VOID);

int  Importn;
long Importl;
static int  ImportbiCompression;
static LPCNVOPTION ImportszOption;
static long    Importlfsize;

/* rgb2dib


Description
 
   convert 4-bitplaned image scanline to 4 bpp packed image scanline
   For the INTEL version we have rgb2dib.asm assembly routine to perform
   the same conversion. This C code is used for easy porting.
   It is possible, when necessary, to code the equivalent assembly for other
   CPU architechure.

   The PCX file id R-G-B-I where DIB is I-B-G-R
*/

void rgb2dib(LPSTR ibuf,LPSTR obuf,WORD n)
{
  int i=n/4,j,k,l=0,m;
  LPSTR ar[4];

  _fmemset(obuf,0,n);

  ar[1] = ibuf;
  ar[2] = ibuf+i;
  ar[3] = ibuf+i*2;
  ar[0] = ibuf+i*3;

  for (j=0;j<i;j++)
    {
      for( m=0;m<8;m++)
	{
	  for (k=0;k<4;k++)
	    {
	      if(ar[k][j] & BitPatternOr[m])
		obuf[l/8] |= BitPatternOr[l%8];
	      l++;
	    }
	}
    }
}

/*
   The caller has option to call into this routine without the need
   to know which flavor of BMP file it is; BMP, DIB Windows or DIB OS/2.
   This routine does auto-detection first prior calling the 
   appropriate routine.

   If the caller decide decide to come in thru the specific API for
   different flvor of BMP, then it has to call HSIDIB2WMF specifically
   if the desired output is WMF.  The HSIImportFilter() entry calls
   HSILoadBMP() only.
*/

HSI_ERROR_CODE EXPORT
HSILoadBMP(FILE * szInfile,FILE * szOutfile,LPCNVOPTION szOpt)
   {
   short err=0;

   // check the BMP flavor

   switch (HSICheckBMP(szInfile))
       {
       case BMP_WIN20:
           err = HSILoadBMP20 ( (FILE *)szInfile, 
                                (FILE *)szOutfile,
                                (LPCNVOPTION)szOpt);
           break;

       case BMP_WIN30:
           err = HSILoadDIB ( (FILE *)szInfile, 
                              (FILE *)szOutfile,
                              (LPCNVOPTION)szOpt);
           break;

       case BMP_PM10:
           err = HSILoadPMDIB((FILE *)szInfile, 
                              (FILE *)szOutfile,
                              (LPCNVOPTION)szOpt);
           break;

       default :
          err = HSI_EC_INVALIDFILE;   // file not found
          break;
       }

   
   return err;
   }


/*
   We really don't need to create a brand new file. In stead, a new
   reference to the file is suffice. Unfortunately, there is no 'ln'
   in MS-DOS file system. Meanwhile, let's make a duplicate.
*/

HSI_ERROR_CODE EXPORT
HSILoadDIB ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt)
   { 
   short   err=0;
   LPSTR   buf=NULL;
   int    size;
   static DWORD   l;
   
   MemHandle bufHandle;

   ImportszOption = szOpt;

    
/*open input and output file
   err = OpenInOutFile ( szInfile, szOutfile );
   if ( err ) goto cu0;
*/
   /*
   ** Load the header info to find out whether this is RLE compressed
   ** or not
   */
  Infile = (FILE *)szInfile;
  Outfile = (FILE *)szOutfile;

   err= ReadHeaderInfo(Infile);
   if (err) goto cu0;

   /*
   ** Load RLE DIB
   */

   if (bmihdr.biCompression)
       {
       HSILoadWRLE();
       goto cu0;
       }
   else
       {
       /*
       ** Rewind the file
       */

       fseek(Infile,0L,0);
       }

   
   bufHandle = allocmax(&size);
   buf = MemLock(bufHandle);

   if (!buf)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   fseek(Infile,0L,2);     // get file size
   Importlfsize = ftell(Infile); 
   fseek(Infile,0L,0);     // rewind the file

   while ( (l=lfread(buf,1,(DWORD)size,Infile)) > 0 )
       {
       DWORD dw;

       dw= lfwrite(buf,1,l,Outfile);

       if (dw==0)
           {
           err=HSI_EC_OUTOFTMPDISK;
           goto cu0;
           }

       if (ImportszOption && ImportszOption->Disp)
           {
           static int cline1;
           int        ii;
           DWORD      dw;

           dw = ftell(Infile);  // get current offset

           ii = (int)((DWORD) dw * 
                      (DWORD)(ImportszOption->end-ImportszOption->start) / 
                      (DWORD)Importlfsize) + 
                      ImportszOption->start;

           if (ii !=cline1)
               {
               cline1 = ii;
               err=(*(ImportszOption->Disp))(cline1);
               if (err) goto cu0;
               }
           }
       }

   cu0:

   if (buf) 
                        /*_ffree(buf);*/
     MemFree(bufHandle);
                        /*CloseInOutFile (); */

   if (!err && ImportszOption && ImportszOption->Disp)
       (*(ImportszOption->Disp))(ImportszOption->end);

   return err;
   }



/*
   Load Presentation Manager DIB to Windows DIB. The only difference 
   is with the header information. Window 30 has 40 bytes (BITMAPINFOHEADER),
   where PM has 12 bytes (BITMAPCOREINFOHEADER).
*/

HSI_ERROR_CODE EXPORT
HSILoadPMDIB ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt)
   { 
   int     err=0;
   int     i;
   static BITMAPCOREHEADER   bmchdr;
   LPSTR   buf=NULL;
   int     size;
   int clrsize;
   long    lfsize,lsize,offset;

   MemHandle bufHandle;

   ImportszOption = szOpt;

   // open the input file and outfile 
/*
   err = OpenInOutFile ( szInfile, szOutfile );

   if ( err ) goto cu0;
*/
     
   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

   fseek(Infile,0L,2);
   lfsize = ftell(Infile);   // get file size
   fseek(Infile,0L,0);            // rewind the file

   // read the PM DIB header

   if (!fread(&bmfhdr,1,SIZEOFBMPFILEHDR,Infile))
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   /*
   ** Save the offset to where the data start
   */

   offset = bmfhdr.bfOffBits;  

   if (!fread(&bmchdr,1,sizeof(BITMAPCOREHEADER),Infile))
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   // get number of colors

   switch ( bmchdr.bcBitCount )
       {
       case 1 :
           nColors = 2;
           break;

       case 4 :
           nColors = 16;
           break;

       case 8 :
           nColors = 256;
           break;

       case 24 :
           nColors = 0;
           break;

       default :
           err = HSI_EC_INVALIDFILE; // invalid file
           goto cu0;
      }

   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;

   bmihdr.biSize       = 40L;
   bmihdr.biWidth		= bmchdr.bcWidth;
   bmihdr.biHeight		= bmchdr.bcHeight;
   bmihdr.biPlanes		= bmchdr.bcPlanes;
   bmihdr.biBitCount	= bmchdr.bcBitCount;
   bmihdr.biClrUsed    = 0L;

   wWidthBytes = (WORD)( (bmchdr.bcWidth * bmchdr.bcBitCount ) + 
                   7 ) / 8 * bmchdr.bcPlanes;

   // normalize scanline width to LONG boundary

   nWidthBytes = ( wWidthBytes + sizeof(LONG)-1 ) / 
                   sizeof(LONG) *
                   sizeof(LONG); 


   if ( err ) goto cu0;

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) +
                        sizeof(BITMAPINFOHEADER) +
                        nColors * sizeof(RGBQUAD);

   bmihdr.biSizeImage = bmihdr.biHeight * nWidthBytes;

   bmfhdr.bfSize      = bmfhdr.bfOffBits +
                        bmihdr.biSizeImage;

   /*
   ** Read the PM DIB color palette info and write it to
   ** Windows 30 header.  It is possible that the PM file might have
   ** the RGBQUAD for each palette 
   */
/*
   if ((offset-14-12) == SIZEOFRGBQUAD * nColors)
       clrsize = SIZEOFRGBQUAD;
   else
*/
       clrsize = sizeof(RGBTRIPLE);

   for ( i=0; (WORD)i < nColors ; i++ )
       {
       fread(&clrtbl[i],
             1,
             clrsize,
             Infile);
       }

   err=WriteHeaderInfo();
   if (err) goto cu0;

   
   bufHandle = allocmax(&size);
   buf = MemLock(bufHandle);

   if (!buf)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   lsize = bmihdr.biSizeImage;

   // copy data over as is by copying each scanline over. 

   fseek(Infile,(long)offset,0);

   while ( lsize > 0 && (Importl= lfread(buf,1,(DWORD)size,Infile)) > 0 )
       {
       DWORD dw;

       dw = lfwrite(buf,1,min(lsize,Importl),Outfile);

       if (!dw)
          {
          err=HSI_EC_DSTCANTWRITE;
          goto cu0;
          }

       lsize -= dw;

       if (ImportszOption && ImportszOption->Disp)
           {
           static int cline2;
           int        ii;
           DWORD      dw;

           dw = ftell(Infile);  // get current offset

           ii = (int)((DWORD) dw * 
                      (DWORD) (ImportszOption->end - ImportszOption->start) / 
                      (DWORD)lfsize +
                      ImportszOption->start);

           if (ii !=cline2)
               {
               cline2 = ii;
               err=(*(ImportszOption->Disp))(cline2);
               if (err) goto cu0;
               }
           }
       }

   cu0:

   if (buf) 
/*
       _ffree(buf);
*/
     MemFree(bufHandle);
/*
   CloseInOutFile();
*/
   if (!err && ImportszOption && ImportszOption->Disp)
       (*(ImportszOption->Disp))(ImportszOption->end);

   return err;
   }



/* used for internal standard bitmap */
typedef struct
	{
	WORD    dummy1;
	short	bmType; 
	short 	bmWidth;
	short 	bmHeight;
	short 	bmWidthBytes;
	BYTE 	bmPlanes;
	BYTE	bmBitsPixel;
	WORD	scnWidth, scnHeight;
	}
BMFILEHDR;

BMFILEHDR   Importbmhdr;

/*
   Load Windows 20 BMP to Windows 3.0 DIB. The Windows 2.0 bitmap might 
   have different variations:

       1 bpp   1 plane
       4 bpp   1 plane
       8 bpp   1 plane
       1 bpp   3 plane (most common)
       1 bpp   2 plane (unlikely)
       1 bpp   4 plane (possible)

   We will handle all above cases, all other combinations are not 
   supported.

*/


HSI_ERROR_CODE EXPORT
HSILoadBMP20 ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt )
   { 
   short   err=0;


   ImportszOption = szOpt;

   // open the input file and outfile 
/*
   err = OpenRawInOutFile ( szInfile, szOutfile );

   if ( err ) goto cu0;
*/
   Infile = (FILE *)szInfile;
   Outfile =(FILE *)szOutfile;

   Importlfsize = _llseek(Infile,0L,2);   // get file size
   _llseek(Infile,0L,0);            // rewind the file

   // read the Windows 2.0 bitmap header

   if ( !_lread  (Infile,(LPSTR)&Importbmhdr,
                   sizeof(BMFILEHDR)))
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   // decide number of colors

   switch ( Importbmhdr.bmPlanes )
       {
       case 1 :
           nColors = 1 << Importbmhdr.bmBitsPixel;
           bmihdr.biBitCount = Importbmhdr.bmBitsPixel;
           break;

       case 2 :
       case 3 :
       case 4 :
           nColors = 16;
           bmihdr.biBitCount = 4;
           break;

       default :
           err = HSI_EC_UNSUPPORTED;
           goto cu0;
       }

   // decide DIB header

   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;

   bmihdr.biSize       = 40L;
   bmihdr.biWidth		= Importbmhdr.bmWidth;
   bmihdr.biHeight		= Importbmhdr.bmHeight;
   bmihdr.biPlanes		= 1;
   bmihdr.biClrUsed    = 0L;

   wWidthBytes = (WORD)( (bmihdr.biWidth * bmihdr.biBitCount ) + 
                   7 ) / 8 * bmihdr.biPlanes;

   // normalize scanline width to LONG boundary

   nWidthBytes = ( wWidthBytes + sizeof(LONG)-1 ) / 
                   sizeof(LONG) *
                   sizeof(LONG); 


   if ( err ) goto cu0;

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) +
                        sizeof(BITMAPINFOHEADER) +
                        nColors * sizeof(RGBQUAD);

   bmihdr.biSizeImage = bmihdr.biHeight * nWidthBytes;

   bmfhdr.bfSize      = bmfhdr.bfOffBits +
                        bmihdr.biSizeImage;

   // write the PM DIB header

   Importn = _lwrite ( Outfile,
            (LPSTR)&bmfhdr,
            sizeof(BITMAPFILEHEADER));

   if (!Importn)
       {
       err=HSI_EC_DSTCANTWRITE;
       goto cu0;
       }

   // write the DIB info header

   Importn= _lwrite ( Outfile,
            (LPSTR)&bmihdr,
            sizeof(BITMAPINFOHEADER));

   if (!Importn)
       {
       err=HSI_EC_DSTCANTWRITE;
       goto cu0;
       }

   // write color plane
   
   switch ( bmihdr.biBitCount )
       {
       case 1 :
           clrtbl[0].rgbBlue     = 0x00;
           clrtbl[0].rgbGreen    = 0x00;
           clrtbl[0].rgbRed      = 0x00;
           clrtbl[0].rgbReserved = 0x00;

           clrtbl[1].rgbBlue     = 0xFF;
           clrtbl[1].rgbGreen    = 0xFF;
           clrtbl[1].rgbRed      = 0xFF;
           clrtbl[1].rgbReserved = 0x00;

           break;

       case 4 :
           _fmemcpy  ( clrtbl, clrtbl16, sizeof(RGBQUAD)*16 );
           break;

       case 8 :
           _fmemcpy  ( clrtbl, clrtbl256, sizeof(RGBQUAD)*256 );
           break;
       }

   Importn = _lwrite ( Outfile,
            (LPSTR)clrtbl,                // write the color table to file
            sizeof(RGBQUAD)*nColors);

   if (!Importn)
       {
       err=HSI_EC_DSTCANTWRITE;
       goto cu0;
       }

   // decide what type of image this is...

   switch ( Importbmhdr.bmPlanes )
       {
       case 1 :
           err = LoadBMP20DIB ();            // single plane    
           break;

       case 2 :
       case 3 :
       case 4 :
           err = LoadBMP204();               // 4 planes
           break;

       default :
           err = HSI_EC_UNSUPPORTED;   // not supported option
           goto cu0;
       }

   cu0:
/*
   CloseRawInOutFile();
*/
   if (!err && ImportszOption && ImportszOption->Disp)
       (*(ImportszOption->Disp))(ImportszOption->end);

   return err;
   }

/*
   Single plane, multi bits image. Similar to DIB. Straight dump.
*/

HSI_ERROR_CODE LoadBMP20DIB(void)
   {

   short   err=0;
/*
   HANDLE  hHandle=0;
*/
   MemHandle hHandle =(MemHandle)0;
   LPSTR   lpStr;
   WORD    w;

   // allocate scanline output buffer
/*
   hHandle = GlobalAlloc ( GPTR, (DWORD)nWidthBytes );
*/
   hHandle = MemAlloc( (WORD)nWidthBytes,HF_FIXED,HAF_ZERO_INIT );
   if ( !hHandle )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }
/*
   lpStr = (LPSTR)GlobalLock ( hHandle );
*/
   lpStr = (LPSTR)MemLock ( hHandle );
   if ( !lpStr )
       {
/*
       GlobalFree ( hHandle );
*/
       MemFree(hHandle);
       hHandle = (MemHandle)0;
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // copy data over as is by copying each scanline over. The
   // 20 bitmap is on WORD boundary where Windows 30 is on 
   // LONG boundary

   Importl = _llseek(Outfile,                   // seek to the end of output
               bmfhdr.bfSize,                  // file, DIB has lower left
               0 );                            // origin

   if (Importl == -1L)
       {
       err=HSI_EC_OUTOFTMPDISK;
       goto cu0;
       }

   _llseek(Outfile,                        // seek one scanline backward
           -1L * (long)nWidthBytes,
           1 );

   w = 0;                                  // no. of scanline processed

   while ( _lread( Infile,lpStr, Importbmhdr.bmWidthBytes) > 0 )
       {
       Importn = _lwrite (Outfile,
                    lpStr,             // write scanline to output 
                    nWidthBytes);

       if (!Importn)
          {
          err=HSI_EC_DSTCANTWRITE;
          goto cu0;
          }

       _llseek( Outfile,             // seek backward two scanlines
                -2L * (long)nWidthBytes,
                1 );

       if (ImportszOption && ImportszOption->Disp)
           {
           static int cline3;
           int        ii;

           ii = (int)((DWORD) w * 
                      (DWORD) (ImportszOption->end - ImportszOption->start) / 
                      (DWORD)Importbmhdr.bmHeight) +
                      ImportszOption->start;

           if (ii !=cline3)
               {
               cline3 = ii;
               err=(*(ImportszOption->Disp))(cline3);
               if (err) goto cu0;
               }
           }
       w++;
       }

   cu0:

   if ( hHandle )
       {
/*
       GlobalUnlock ( hHandle );
       GlobalFree   ( hHandle );
*/
       MemFree( hHandle);
     }

   return err;
   }


/* 
   Windows 2.0 8 color bitmap, convert it to 4 bpp, 16 color bitmap
   Use rgb2dib() assembly routine to speed up the conversion for 
   each scanline.  Window 2.0 BMP file has interleaved RGB planes,
   this is very painful and slow conversion process.
*/


HSI_ERROR_CODE LoadBMP204(void)
   {
   int   err=0, i, j;
  /* HANDLE  hHandle=0,hOutHandle=0;*/
   LPSTR   lpStr, lpOutStr;
   BYTE    zero=0x00;
   WORD    nLineWidth;
   DWORD   lStripSize;
#ifdef __HIGHC__
   extern  void EXPORT rgb2dib( LPSTR, LPSTR, WORD );
#endif

   MemHandle hHandle=(MemHandle)0,hOutHandle = (MemHandle)0;

   if ( Importbmhdr.bmBitsPixel != 1 )   // image must be single plane
       {
       err = HSI_EC_UNSUPPORTED;
       goto cu0;
       }

   // allocate scanline buffer

/*   hHandle = GlobalAlloc ( GPTR, (DWORD)nWidthBytes );*/
     hHandle = MemAlloc((WORD)nWidthBytes,HF_FIXED,HAF_ZERO_INIT);

   if ( !hHandle )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }
/*
   lpStr = (LPSTR)GlobalLock ( hHandle );
*/
      lpStr = (LPSTR)MemLock ( hHandle );
   if ( !lpStr )
       {
/*
       GlobalFree ( hHandle );
*/
	 MemFree(hHandle);
         hHandle =(MemHandle) 0;
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }


   // allocate scanline buffer
/*
   hOutHandle = GlobalAlloc ( GPTR, (DWORD)nWidthBytes );
*/
   hOutHandle = MemAlloc ((WORD)nWidthBytes,HF_FIXED,HAF_ZERO_INIT );
   if ( !hOutHandle )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   lpOutStr = (LPSTR)MemLock ( hOutHandle );

   if ( !lpOutStr )
       {
/*
       GlobalFree ( hOutHandle );
*/
       MemFree(hOutHandle);
       hOutHandle = (MemHandle)0;
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   _fmemset ( lpStr, zero, nWidthBytes );    // init to zeros (or ones?)
   _fmemset ( lpOutStr, zero, nWidthBytes ); // init to zeros (or ones?)

   _llseek(Outfile,                        // seek to the end of output
           bmfhdr.bfSize,                  // file, DIB has lower left
           0 );                            // origin

   if (Importl == -1L)
       {
       err=HSI_EC_OUTOFTMPDISK;
       goto cu0;
       }

   _llseek(Outfile,                        // seek one scanline backward
           -1L * (long)nWidthBytes,
           1 );

   lStripSize = (long)Importbmhdr.bmWidthBytes * Importbmhdr.bmHeight;
   nLineWidth = nWidthBytes / 4;

   for ( i=0 ; i < Importbmhdr.bmHeight ; i++ )
       {
       DWORD   lWidthBytes = (long)Importbmhdr.bmWidthBytes * i;

       // 2.x bitmap is stored with R-G-B interleaved plane, we need
       // to get them into B-G-R-I interleaved scanlines

       for ( j=0; j < (int)Importbmhdr.bmPlanes;j++ )   // read all planes into
           {                                   // the input scanline buffer
           int k = ( j == 3 ) ? 3 : (2-j);

           _llseek(Infile, 
                   (long)j * lStripSize + lWidthBytes +
                   (long)sizeof(BMFILEHDR),
                   0 );
                         
           _lread( Infile,
                   (LPSTR)lpStr + k*nLineWidth,        
                   Importbmhdr.bmWidthBytes);
           }

       rgb2dib( (LPSTR)lpStr,        // input buffer 
                (LPSTR)lpOutStr,     // output buffer
                nWidthBytes );       // convert interleave single bpp RGB
                                     // color image to muti bpp image

       Importn= _lwrite ( Outfile,
                lpOutStr,            // write mutl-bits-per-pixel image
                nWidthBytes);

       if (!Importn)
           {
           err=HSI_EC_OUTOFTMPDISK;
           goto cu0;
           }

       _llseek( Outfile,             // seek backward two scanlines
                -2L * (long)nWidthBytes,
                1 );

       if (ImportszOption && ImportszOption->Disp)
           {
           static int cline4;
           int        ii;

           ii = (int)((DWORD) i * 
                      (DWORD)(ImportszOption->end - ImportszOption->start) / 
                      (DWORD)Importbmhdr.bmHeight) +
                      ImportszOption->start;

           if (ii !=cline4)
               {
               cline4 = ii;
               err=(*(ImportszOption->Disp))(cline4);
               if (err) goto cu0;
               }
           }
       }

   cu0:

   if ( hHandle )
       {/*
       GlobalUnlock ( hHandle );
       GlobalFree   ( hHandle );
       */
       MemFree( hHandle);
       }

   if ( hOutHandle )
       {
       /*
       GlobalUnlock ( hOutHandle );
       GlobalFree   ( hOutHandle );
       */
       MemFree( hOutHandle );
       }

   return err;
   }


/*
** Load the RLE compressed data.  The headers are read and placed
** in bmihdr, bmfhdr and clrtbl.
*/

HSI_ERROR_CODE
HSILoadWRLE(void)
   {
   int err=0;

   /*
   ** Save the compression type for the current DIB
   */

   ImportbiCompression = bmihdr.biCompression;

   bmihdr.biCompression  = 0;
   bmihdr.biSizeImage    = nWidthBytes * bmihdr.biHeight;

   bmfhdr.bfOffBits  = SIZEOFBMPFILEHDR +
                       SIZEOFBMPINFOHDR +
                       nColors * SIZEOFRGBQUAD;

   bmfhdr.bfSize = bmfhdr.bfOffBits +
                   bmihdr.biSizeImage;
   
   err=WriteHeaderInfo();
   if (err) goto cu0;
   
   err=RLEUncmpr();

   cu0:

   return err;
   }


HSI_ERROR_CODE RLEUncmpr(void)
   {
   int err=0,n,line=0;
   int width=0;
   static BYTE right,down,c,d;
   char *str=NULL,*t;

   str = malloc(nWidthBytes);
   if (!str)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   t = str;

   while (1)
       {

       /*
       ** Read next byte and decide what to do
       */

       n=fread(&c,1,1,Infile);

       if (n<=0)
           break;

       switch (c)
           {
           case 0:
               /*
               ** This is an absolute run, read the next byte to decide
               ** what to do.
               */
           
               fread(&c,1,1,Infile);
           
               switch(c)
                   {
                   case 0:   /* end of line */

                       if (ImportszOption && ImportszOption->Disp)
                           {
                           static int cline5;
                           int        ii;
                           /*DWORD      dw;*/

                           ii = (int)((DWORD) line * 
                             (DWORD)(ImportszOption->end-ImportszOption->start) / 
                                   (DWORD) bmihdr.biHeight) + 
                                   ImportszOption->start;

                           if (ii !=cline5)
                               {
                               cline5 = ii;
                               err=(*(ImportszOption->Disp))(cline5);
                               if (err) goto cu0;
                               }
                           }

                       line++;

                       /*
                       ** Re-position the buffer pointer
                       */

                       t = str;  

                       /* 
                       ** Reset current width counter
                       */

                       width = 0;

                       /*
                       ** Write out one scanline
                       */

                       fwrite(str,1,nWidthBytes,Outfile);

                       break;

                   case 1:   /* end of bitmap */

                       /*
                       ** There might be a line buffer needed to be
                       ** flushed.  The end-of-bitmap is not clearly defined
                       ** in as to whether end-of-line has to precede this
                       ** code.  However, by check the buffer width, we now
                       ** can handle it properly.  The 'width' will be set
                       ** to the LONG boundary, therefore it is not valid
                       ** to match it against 'biWidth' value.  As long as
                       ** 'width' is non-zero, we will assume there is a
                       ** scanline outstanding.
                       */

                       if (width)
                           fwrite(str,1,nWidthBytes,Outfile);

                       line++;
                       goto cu0;

                   case 2:   /* delta to right and down */
                       fread(&right,1,1,Infile);
                       fread(&down,1,1,Infile);
                       line +=down;
                       width+=right;
                       break;

                   default : /* this is an abolute run. Notice that the data */
                             /* has to be on WORD boundary */


                       if (ImportbiCompression == BI_RLE8)
                           {
                           width += c;
                           fread(t,1,ALIGNWORD(c),Infile);
                           t+=c;
                           }
                       else
                           {
                           fread(t,1,ALIGNWORD(ALIGNWORD(c)/2),Infile);
                           t+=c/2;
                           width += c;
                           }
                           
                       break;
                   }

               break;

           default :

               /* 
               ** This is the encode run
               */

               fread(&d,1,1,Infile);


               if (ImportbiCompression == BI_RLE8)
                   {
                   width += c;

                   while (c--)
                       *t++ = d;
                   }
               else
                   {
                   int i;

                   for (i=0;i<c;i++)
                       {
                       /*
                       ** Check the current width and decide how to
                       ** process the nibble
                       */

                       if (width%2)
                           {

                           /*
                           ** Store the low nibble 
                           */

                           if (i%2)
                               *t |= (d & 0x0F);
                           else
                               *t |= (d >> 4);

                           t++;
                           }
                       else
                           {
                           if (i%2)
                               *t = (d << 4);
                           else
                               *t = (d & 0xF0);
                           }

                       width++;
                       }
                   }

               break;
           }
       }

   cu0:

   if (str)
       free(str);

   return err;
   }


#pragma Code ();



