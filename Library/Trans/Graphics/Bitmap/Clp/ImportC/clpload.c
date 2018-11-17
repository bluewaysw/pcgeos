/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clpload.c

AUTHOR:		Maryann Simmons, May 12, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	5/12/92   	Initial version.

DESCRIPTION:
	

	$Id: clpload.c,v 1.1 97/04/07 11:26:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


/**************************************************************\

   NAME    CLPLOAD

   PURPOSE Load Windows and Presentation Manager Clipboard 
           formatted file.  There can be three flavors:

           Windows 2.x
           Windows 3.x
           Presentation Manager

   HISTORY

   06/06/90    Support both Windows 2.x and 3.0 Bitmap Clipboard
               format. Windows 3.0 Bitmap can be either CF_BITMAP
               or CF_DIB, we support both.

   01/04/91    add checking for DIB entries. Make sure the bitmap
               info header is correct.  Since there could be
               multiple data items, we will read the correct 
               bitmap size for each one.

\**************************************************************/
#pragma Comment("@"__FILE__);

#pragma Code ("MainImportC");

#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>
#include <Ansi/stdlib.h>

#include "clp.h"

// function prototypes


HSI_ERROR_CODE EXPORT HSILoadCLP    ( FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE        Load20CLP  (VOID);
HSI_ERROR_CODE        Load30CLP  (VOID);
HSI_ERROR_CODE        Load30CLPDIB  (VOID);
HSI_ERROR_CODE        Load30CLPDDB  (VOID);
HSI_ERROR_CODE        Load30CLPPalette(VOID);
HSI_ERROR_CODE        Load201CLP (VOID);
HSI_ERROR_CODE        Load301CLP (VOID);
HSI_ERROR_CODE        UpdateDDBPalette (VOID);

void   rgb82dib(LPSTR inbuf, LPSTR outbuf, WORD n, WORD outlength);

WORD       bmWidthBytes;
BITMAP     bmp;

char    str[80];
short   planes;
WORD    headersize;
BYTE    ftype;
BOOL    bUsePalette;
LPCNVOPTION    ImportszOption;
static BOOL bPlanar;
static int     isdibddb = 0;

CLPHDR         *clphdr;
CLP30FILEHDR   *pclp30,clp30filehdr;
CLP30HDR       clp30hdr;

HSI_ERROR_CODE EXPORT
HSILoadCLP ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt )
   {
   short   err = 0;
   int     nRead;
/*   static  int nColors;*/

   ImportszOption   = szOpt;
   ftype      = 0;     // set file type to zero first
   bPlanar    = FALSE; // default to packed data (non-planar)
   bUsePalette=TRUE;   // use palette in clipboard file is one is
                       // available

   bmihdr.biBitCount= 0;

   /*Infile and Outfile are defined in dib.c */
   Infile =  (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;
/* open file
   err = OpenRawInOutFile( szInfile, szOutfile );

   if ( err ) goto cu0;

*/
   // read the header first to verify whether this is a good CLP file 

   nRead = _lread ( Infile,str, sizeof(CLPHDR));
   if ( nRead <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
   clphdr   = (CLPHDR *)   &str;
   pclp30   = (CLP30FILEHDR *) &str;

   // load screen color table 
#ifdef WINVERSION

   LoadSystemColorTable(clrtbl256,(short *)&nColors);

#endif
      if ( (clphdr->byte1 == 0xE3 && clphdr->byte2 == 0xC7) ||
        (clphdr->byte1 == 0x00 && clphdr->byte2 == 0x00)  ) /* petzold's file */
       {
       // Windows 2.x Clipboard format
       err = Load20CLP ();
       if ( err ) goto cu0;
       }
   else
   if ( pclp30->fileid == CLP_ID )  // count is not always 1
       {
       err = Load30CLP ();
       if ( err ) goto cu0;
       }
   else
       {
       err = HSI_EC_UNSUPPORTED;
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
   Load Windows 2.x Clipboard format file
*/

HSI_ERROR_CODE  
Load20CLP (void)
   {
   short   err=0;
   int     nWrite;

   bmWidthBytes = clphdr->widthbyte;

   // write header info to tempory file 

   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;

   bmihdr.biSize       = 40L;
   bmihdr.biWidth		= clphdr->width;
   bmihdr.biHeight		= clphdr->height;
   bmihdr.biPlanes		= 1;
   bmihdr.biClrUsed    = 0L;
   nColors             = 0;
   planes              = clphdr->planes;
   headersize          = sizeof(CLPHDR);

   switch ( clphdr->planes )
       {
       case 1 :
           nColors = 1 << clphdr->bitspixel;
           bmihdr.biBitCount = clphdr->bitspixel;
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
       
   bmihdr.biCompression   = 0L;
   bmihdr.biXPelsPerMeter = 0L;
   bmihdr.biYPelsPerMeter = 0L;
   bmihdr.biClrImportant  = 0L;

   // calculate real size in byte of one scanline

   wWidthBytes = (WORD)(((bmihdr.biWidth * bmihdr.biBitCount ) + 
                   7 ) / 8 * bmihdr.biPlanes);

   // normalize scanline width to LONG boundary

   nWidthBytes = ( wWidthBytes + sizeof(LONG)-1 ) / 
                   sizeof(LONG) *
                   sizeof(LONG); 

   bmihdr.biSizeImage = (DWORD)nWidthBytes * bmihdr.biHeight;

   // calculate offset to bitmap data

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) +
                        sizeof(BITMAPINFOHEADER) +
                        nColors * sizeof(RGBQUAD);

   // calculate total size of this image

   bmfhdr.bfSize      = bmihdr.biSizeImage +
                        bmfhdr.bfOffBits;

   // write out file header

   nWrite = _lwrite ( Outfile,
                      (LPSTR)&bmfhdr, 
                      sizeof(BITMAPFILEHEADER));

   if (nWrite == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // write out header info 

   nWrite = _lwrite(   Outfile,
                       (LPSTR)&bmihdr,
                       sizeof(BITMAPINFOHEADER));

   if (nWrite == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

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

   nWrite= _lwrite (Outfile,
                    (LPSTR)clrtbl,            // write the color table to file
                    sizeof(RGBQUAD)*nColors);

   if (nWrite == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   err = Load201CLP();

   cu0:

   return err;

   }





/*
   Load Windows 3.0 Clipboard format file
*/

HSI_ERROR_CODE  
Load30CLP (void)
   {

   short   err=0,k;
   int     datacount = 0;
   long    l;
   long    lsk;

   lsk = _llseek(Infile, 0L, 0);
   if (lsk == -1 )
      {
      err = HSI_EC_SRCCANTSEEK;
      goto cu0;
      }

   // read clipboard file header
   l = _lread (Infile,  (LPSTR)&clp30filehdr,  SIZEOFCLP30FILEHDR);
   if (l <= 0 )
      {
      err = HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   datacount = clp30filehdr.count ;
   if (datacount >= 3)
       {
       while (datacount > 0)
           {
           l = _lread (Infile, (LPSTR)&clp30hdr.fmtid,  SIZEOFWORD);
           if (l <= 0 )
              {
              err = HSI_EC_SRCCANTREAD;
              goto cu0;
              }

           if (clp30hdr.fmtid == CF_DIB)
              {
              isdibddb = 1;
              break;
              }

           l = _llseek(Infile, 87L, 1);
           if ( l == -1 )
              {
              err = HSI_EC_SRCCANTSEEK;
              goto cu0;
              }

           datacount--;
           }
       }

   l = _llseek(Infile,4L,0);          // save position
   if ( l == -1 )
      {
      err = HSI_EC_SRCCANTSEEK;
      goto cu0;
      }


   for (k=0; k < (int)clp30filehdr.count;k++)
       {
       lsk = _llseek(Infile,l,0);               // restore current position
       if (lsk == -1 )
          {
          err = HSI_EC_SRCCANTSEEK;
          goto cu0;
          }

       // read clipboard record header
       l = _lread (Infile, (LPSTR)&clp30hdr.fmtid,  sizeof(WORD));
       l = _lread (Infile, (LPSTR)&clp30hdr.length, sizeof(DWORD));
       l = _lread (Infile, (LPSTR)&clp30hdr.offset, sizeof(DWORD));
       l = _lread (Infile, (LPSTR)&clp30hdr.name,   79);

       if (l <= 0 )
          {
          err = HSI_EC_SRCCANTREAD;
          goto cu0;
          }

       l = _llseek(Infile,0L,1);          // save current position
       if ( l == -1 )
          {
          err = HSI_EC_SRCCANTSEEK;
          goto cu0;
          }


       // seek to where the info start

       lsk = _llseek(Infile, (long)clp30hdr.offset, 0 );
       if (lsk == -1 )
          {
          err = HSI_EC_SRCCANTSEEK;
          goto cu0;
          }

       switch (clp30hdr.fmtid)
          {
          case CF_DIB :
               err = Load30CLPDIB ();
               if (err) goto cu0;

               ftype = CF_DIB;
               break;

          case CF_BITMAP :
               if (!isdibddb)
                  {
                  err=Load30CLPDDB();
                  if (err) goto cu0;

                  ftype = CF_BITMAP;
                  }
               else
                  {
                  // seek to where next info start
                  lsk = _llseek(Infile, (long)clp30hdr.length, 1 );
                  if (lsk == -1 )
                     {
                     err = HSI_EC_SRCCANTSEEK;
                     goto cu0;
                     }
                  }

               break;

          case CF_PALETTE :
               err=Load30CLPPalette();
               if (err) goto cu0;

// there should be a dialog box that ask for user to select either
// default palette or palette stored in file. For now, we will use
// the default palette

//             if (ftype==CF_BITMAP)

               /* always read the palette.  The palette might or might */
               /* be used in the output file. If the DIB does not have */
               /* the same bit depth, then ignore the palette          */

               if (bUsePalette)
                   UpdateDDBPalette();

               ftype = CF_PALETTE;

               break;

          default :

	      	break;
	   }
   }
               /*
   /* If we haven't yet imported anything, then return an error */

   if (!ftype)
       err=HSI_EC_UNSUPTCLP;

   cu0:
   return err;
}



HSI_ERROR_CODE
Load30CLPDDB(void)
   {
   int   err=0;
   int   nWrite;

   // read BITMAP information
   nWrite = _lread (Infile, (LPSTR)&bmp.bmType,       sizeof(WORD));
   nWrite = _lread (Infile, (LPSTR)&bmp.bmWidth,      sizeof(WORD));
   nWrite = _lread (Infile, (LPSTR)&bmp.bmHeight,     sizeof(WORD));
   nWrite = _lread (Infile, (LPSTR)&bmp.bmWidthBytes, sizeof(WORD));
   nWrite = _lread (Infile, (LPSTR)&bmp.bmPlanes,     sizeof(BYTE));
   nWrite = _lread (Infile, (LPSTR)&bmp.bmBitsPixel,  sizeof(BYTE));
   nWrite = _lread (Infile, (LPSTR)&bmp.bmBits,       sizeof(DWORD));

   if (nWrite <= 0 )
      {
      err = HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   bmWidthBytes = bmp.bmWidthBytes;
   planes       = bmp.bmPlanes;

   // write header info to tempory file

   bmfhdr.bfType      = BFT_BITMAP;
   bmfhdr.bfReserved1 = 0;
   bmfhdr.bfReserved2 = 0;

   bmihdr.biSize      = 40L;
   bmihdr.biWidth     = bmp.bmWidth;
   bmihdr.biHeight    = bmp.bmHeight;
   bmihdr.biPlanes    = 1;
   bmihdr.biClrUsed   = 0L;
   nColors            = 0;
   planes             = bmp.bmPlanes;
   headersize         = sizeof(CLP30HDR) + sizeof(BITMAP);

   switch ( planes )
      {
      case 1 :
           bPlanar=FALSE;
           nColors = 1 << bmp.bmBitsPixel;
           bmihdr.biBitCount = bmp.bmBitsPixel;
           break;

      case 2 :
      case 3 :
      case 4 :
           nColors = 16;
           bmihdr.biBitCount = 4;
           break;

      case 8 :                    // pain in the neck, we need to convert
           nColors = 256;          // 8 planes to 8 bits per pixel.
           bmihdr.biBitCount = 8;
           bPlanar=TRUE;
           break;

      default :
           err = HSI_EC_UNSUPPORTED;
           goto cu0;
       }

   bmihdr.biCompression   = 0L;
   bmihdr.biXPelsPerMeter = 0L;
   bmihdr.biYPelsPerMeter = 0L;
   bmihdr.biClrImportant  = 0L;

   // calculate real size in byte of one scanline

   wWidthBytes = (WORD)(((bmihdr.biWidth * bmihdr.biBitCount ) +
                   7 ) / 8 * bmihdr.biPlanes);

   // normalize scanline width to LONG boundary

   nWidthBytes = ( wWidthBytes + sizeof(LONG)-1) / sizeof(LONG) * sizeof(LONG);

   bmihdr.biSizeImage = (DWORD)nWidthBytes * bmihdr.biHeight;

   // calculate offset to bitmap data

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) +
                        sizeof(BITMAPINFOHEADER) +
                        nColors * sizeof(RGBQUAD);

   // calculate total size of this image
   bmfhdr.bfSize      = (DWORD) bmihdr.biSizeImage + bmfhdr.bfOffBits;

   // write out file header

   nWrite = _lwrite (Outfile, (LPSTR)&bmfhdr, sizeof(BITMAPFILEHEADER));
   if (nWrite == 0) 
      { 
      err=HSI_EC_DSTCANTWRITE;
      goto cu0;
      }

   // write out header info

   nWrite = _lwrite (Outfile, (LPSTR)&bmihdr, sizeof(BITMAPINFOHEADER));
   if (nWrite == 0 ) 
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

   nWrite = _lwrite( Outfile,
            (LPSTR)clrtbl,                // write the color table to file
            sizeof(RGBQUAD)*nColors);

   if (nWrite == 0 )
      {
      err=HSI_EC_DSTCANTWRITE; 
      goto cu0;
      }

   err = Load301CLP();

   cu0:
     return err;
   }



/*
   Read next DIB entry.  We will read only what we need.
*/

HSI_ERROR_CODE
Load30CLPDIB(void)
   {
   short err=0;
   MemHandle lpStrHandle;
   LPSTR   lpStr=NULL;
   int     size,n;
   WORD    nWrite;
   long    lsize;

   // read CLP file DIB bitmap info header

   n = _lread ( Infile,
                (LPSTR)&bmihdr,
                sizeof(BITMAPINFOHEADER));

   if (n!=sizeof(BITMAPINFOHEADER))
       {
       err=HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   if (bmihdr.biSize != sizeof(BITMAPCOREHEADER) && // make sure this is 
       bmihdr.biSize != sizeof(BITMAPINFOHEADER))  // Win30 or OS/2 DIB
       {
       err=HSI_EC_INVALIDBMPHEADER;
       goto cu0;
       }

   if (bmihdr.biSizeImage == 0 )
       {
       wWidthBytes = (WORD)((bmihdr.biWidth * bmihdr.biBitCount+7)/8);
       nWidthBytes = ALIGNULONG(wWidthBytes);

       bmihdr.biSizeImage = (DWORD)nWidthBytes *   // calculate the size of
                           bmihdr.biHeight;       // image
       }

   // prepare DIB file header

   bmfhdr.bfType    = BFT_BITMAP;
   bmfhdr.bfSize    = 
   bmfhdr.bfReserved1 = 0;
   bmfhdr.bfReserved2 = 0;

   nColors = GetNumColor();

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) +
                        sizeof(BITMAPINFOHEADER) +
                        nColors * sizeof(RGBQUAD);

   // calculate total size of this image

   bmfhdr.bfSize      = bmihdr.biSizeImage +
                        bmfhdr.bfOffBits;

   // write out the DIB file header

   nWrite = _lwrite (Outfile,
            (LPSTR)&bmfhdr,
            sizeof(BITMAPFILEHEADER));

   if (!nWrite) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // write out DIB info header

   nWrite= _lwrite (Outfile,
            (LPSTR)&bmihdr,
            sizeof(BITMAPINFOHEADER));

   if (!nWrite) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // read color palette in the clp file

   if (nColors)
       {
       nWrite = _lread (Infile,
               (LPSTR)clrtbl, 
               sizeof(RGBQUAD)*nColors);
      if (nWrite <= 0 )
         {
         err = HSI_EC_SRCCANTREAD;
         goto cu0;
         }
       nWrite= _lwrite(Outfile,
               (LPSTR)clrtbl,
               sizeof(RGBQUAD)*nColors);

       if (!nWrite) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }

   // copy over data. Use memory if possible.

   lpStrHandle = allocmax(&size);
   lpStr = MemLock(lpStrHandle);

   if (!lpStr)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   lsize=bmihdr.biSizeImage;   

   while ((n = (int) _lread(Infile,lpStr,(DWORD)min((DWORD)size,(DWORD)lsize))) > 0 )
       {

       if (ImportszOption && ImportszOption->Disp)       
           {
           static int cline;
           int        i;

           i = (int)((DWORD) (bmihdr.biSizeImage-lsize) * 
                     (DWORD) (ImportszOption->end - ImportszOption->start) / 
                   (DWORD) bmihdr.biSizeImage + ImportszOption->start);

           if (i!=cline)
               {
               cline = i;
               err=(*(ImportszOption->Disp))(cline);
               if (err) goto cu0;
               }
           }

       nWrite= _lwrite(Outfile,lpStr, n);

       if (nWrite == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       lsize -= (long)n;       // update bytes count left to read

       }

   cu0:

   if ( lpStr )
       MemFree(lpStrHandle);       /*_ffree(lpStr);*/

   return err;       
   }



HSI_ERROR_CODE
Load201CLP(void)
   {
   short   err=0, i, j;
   LPSTR   lpStr=NULL, lpOutStr=NULL;
   WORD    nLineWidth;
   DWORD   lStripSize;
   WORD    nWrite;
   long    l;
   extern  void EXPORT rgb2dib( LPSTR, LPSTR, WORD );
   
   // allocate scanline buffer

   lpStr = _fmalloc(nWidthBytes);

   if ( !lpStr )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // allocate scanline buffer

   lpOutStr = _fmalloc(wWidthBytes);

   if ( !lpOutStr )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   _fmemset ( lpStr, zero, nWidthBytes );    // init to zeros (or ones?)
   _fmemset ( lpOutStr, zero, nWidthBytes ); // init to zeros (or ones?)

   l = _llseek ( Outfile,                        // seek to the end of output
             bmfhdr.bfSize,                  // file, DIB has lower left
             0 );                            // origin

   if (l == -1L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   _llseek ( Outfile,                        // seek one scanline backward
             -1L * (long)nWidthBytes,
             1 );

   lStripSize = (long) bmWidthBytes * bmihdr.biHeight;

   nLineWidth = nWidthBytes / 4;

   for ( i=0 ; i < (int)bmihdr.biHeight ; i++ )
       {
       DWORD   lWidthBytes = (long)bmWidthBytes * i;

       // 2.x bitmap is stored with R-G-B interleaved plane, we need
       // to get them into B-G-R-I interleaved scanlines

       if ( planes == 1 )       // single plane image
          {
          l =  _lread(Infile,  (LPSTR)lpOutStr,  bmWidthBytes);
          if (l <= 0 )
             {
             err = HSI_EC_SRCCANTREAD;
             goto cu0;
             }
          }
       else
           {
           for ( j=0; j < planes ; j++ )      // read all planes into
               {                              // the input scanline buffer
               int k = ( j == 3 ) ? 3 : (2-j);

               l = _llseek(  Infile, 
                       (long)j * lStripSize + lWidthBytes +
                       (long)headersize,
                       0 );
              if (l == -1L) 
                 { 
                 err=HSI_EC_DSTCANTSEEK; 
                 goto cu0; 
                 }                         
               l = _lread(Infile,
                       (LPSTR)lpStr + k*nLineWidth,        
                       bmWidthBytes);
              if (l <= 0 )
                 {
                 err = HSI_EC_SRCCANTREAD;
                 goto cu0;
                 }
               }

           rgb2dib((LPSTR)lpStr,       // input buffer 
                   (LPSTR)lpOutStr,    // output buffer
                   nWidthBytes );      // convert interleave single bpp RGB
                                       // color image to muti bpp image
           }

       nWrite = _lwrite (Outfile,
                (LPSTR)lpOutStr,       // write mutl-bits-per-pixel image
                nWidthBytes);

       if (nWrite == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       _llseek  ( Outfile,             // seek backward two scanlines
                -2L * (long)nWidthBytes,
                1 );

       if (ImportszOption && ImportszOption->Disp)       
           {
           static int cline2;
           int        ii;

           ii = (int)((DWORD) i * 
                      (DWORD) (ImportszOption->end - ImportszOption->start) / 
                      (DWORD)bmihdr.biHeight +
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

   if ( lpStr )
       _ffree(lpStr);

   if ( lpOutStr )
       _ffree(lpOutStr);

   return err;
   }

#define ENTRIES 4
#define MAXBUFS 10

HSI_ERROR_CODE
Load301CLP(void)
   {
   short   err=0, i;
   LPSTR   lpStr, lpOutStr = (LPSTR) 0;
   long    l;
   WORD    length;
   WORD    width,iwidth;
#ifdef dummy
   extern  void EXPORT rgb2dib( LPSTR, LPSTR, WORD );
#endif

   int biHeight, ToDo, Batch, Done, offset, entry, buf;
   LPSTR OutStrArray[MAXBUFS];
   LPSTR outStr;
   long dataStart, currentStart, entryGap;


   for (buf = 0; buf < MAXBUFS; buf++)
       OutStrArray[buf] = (LPSTR) 0;

   wWidthBytes = bmp.bmWidthBytes * bmp.bmPlanes;

   length = max(wWidthBytes,nWidthBytes);

   // allocate scanline buffer

   lpStr = _fmalloc(max(nWidthBytes,wWidthBytes));

   if ( !lpStr )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   iwidth = wWidthBytes / 4;
   width  = nWidthBytes / 4;

#ifdef dummy
   // allocate scanline buffer

   lpOutStr = _fmalloc(max(nWidthBytes,wWidthBytes));

   if ( !lpOutStr )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   _fmemset ( lpStr, zero, length );         // init to zeros (or ones?)
   _fmemset ( lpOutStr, zero, length );      // init to zeros (or ones?)
#endif

   _fmemset ( lpStr, zero, length );         // init to zeros (or ones?)

   l = _llseek ( Outfile,                  // seek to the end of output
           bmfhdr.bfSize,                  // file, DIB has lower left
           0 );                            // origin

   if (l == -1L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   l = _llseek ( Outfile,                        // seek one scanline backward
             -1L * (long)nWidthBytes,
             1 );
   if (l == -1L ) { err=HSI_EC_DSTCANTSEEK; goto cu0; }


/* GeoComment: This loop makes thousands of FileReads and so takes forever
               to get through. I've replaced it with a loop down below.
	           -jenny 5/26/93 */
#ifdef dummy

   for ( i=0 ; i < (int)bmihdr.biHeight ; i++ )
       {
       if (bmp.bmBitsPixel == 1 && bmp.bmPlanes == 4)
          {
          l = _lread (Infile,  (LPSTR)lpOutStr,  iwidth);
          if (l <= 0 )
             {
             err = HSI_EC_SRCCANTREAD;
             goto cu0;
             }

          lpOutStr += iwidth;
          l = _llseek(Infile,  iwidth * (bmihdr.biHeight - 1),  1);
          if (l == -1L ) 
             {
             err=HSI_EC_DSTCANTSEEK; 
             goto cu0;
             }

          l = _lread (Infile,  (LPSTR)lpOutStr,  iwidth);
          if (l <= 0 )
             {
             err = HSI_EC_SRCCANTREAD;
             goto cu0;
             }

          lpOutStr += iwidth;
          l = _llseek(Infile,  iwidth * (bmihdr.biHeight - 1),  1);
          if (l == -1L ) 
             {
             err=HSI_EC_DSTCANTSEEK; 
             goto cu0;
             }

          l = _lread (Infile,  (LPSTR)lpOutStr,  iwidth);
          if (l <= 0 )
             {
             err = HSI_EC_SRCCANTREAD;
             goto cu0;
             }

          lpOutStr += iwidth;
          l = _llseek(Infile,  iwidth * (bmihdr.biHeight - 1),  1);
          if (l == -1L ) 
             {
             err=HSI_EC_DSTCANTSEEK; 
             goto cu0;
             }

          l = _lread (Infile,  (LPSTR)lpOutStr,  iwidth);
          if (l <= 0 )
             {
             err = HSI_EC_SRCCANTREAD;
             goto cu0;
             }

          lpOutStr += iwidth;
          
          l = 3 * iwidth * bmihdr.biHeight;
          l = (long) -1 * l;
          l = _llseek(Infile,  l,  1);
          // l = _llseek(infile,  -3 * iwidth * bmihdr.biHeight,  1);
          if (l == -1L ) 
             {
             err=HSI_EC_DSTCANTSEEK; 
             goto cu0;
             }

          lpOutStr -= wWidthBytes;
          }
       else
          {
          l = _lread (Infile,  (LPSTR)lpOutStr,  wWidthBytes);
          if (l <= 0 )
             {
             err = HSI_EC_SRCCANTREAD;
             goto cu0;
             }
          }

       if ( bmihdr.biBitCount == 4 )
          {
          _fmemcpy ( lpStr,           lpOutStr+2*iwidth,  width );
          _fmemcpy ( lpStr+width,     lpOutStr+iwidth,    width );
          _fmemcpy ( lpStr+2*width,   lpOutStr,           width );
          _fmemcpy ( lpStr+3*width,   lpOutStr+3*iwidth,  width );

          rgb2dib((LPSTR)lpStr,       // input buffer
                  (LPSTR)lpOutStr,    // output buffer
                  nWidthBytes );      // convert interleave single bpp RGB
                                      // color image to muti bpp image
          l = _lwrite (Outfile, (LPSTR)lpOutStr,  nWidthBytes);
          if (l <= 0 )
             {
             err = HSI_EC_DSTCANTWRITE;
             goto cu0;
             }
          }
       else
       if ( bmihdr.biBitCount == 8 && bPlanar)
          {
          rgb82dib((LPSTR)lpOutStr,    // input buffer
                   (LPSTR)lpStr,       // output buffer
                   wWidthBytes,        // input byte length
                   nWidthBytes );      // output byte length

          l = _lwrite (Outfile,  (LPSTR)lpStr,  nWidthBytes);
          if (l <= 0 )
             {
             err = HSI_EC_DSTCANTWRITE;
             goto cu0;
             }
          }
       else
          {
          l = _lwrite (Outfile,  (LPSTR)lpOutStr,  nWidthBytes);
          if (l <= 0 )
             {
             err = HSI_EC_DSTCANTWRITE;
             goto cu0;
             }
          }

       l = _llseek(Outfile,  -2L * (long)nWidthBytes,  1);

       if (ImportszOption && ImportszOption->Disp)
          {
          static int cline3;
          int        ii;

          ii = (int)((DWORD) i *
                     (DWORD) (ImportszOption->end - ImportszOption->start) /
                     (DWORD) bmihdr.biHeight + ImportszOption->start);

          if (ii !=cline3)
             {
             cline3 = ii;
             err=(*(ImportszOption->Disp))(cline3);
             if (err) goto cu0;
             }
          }
       }
#endif


/**************************************************************************/
/* GeoComment: The following hunk of code is ours. */

   biHeight = bmihdr.biHeight;

   if (bmp.bmBitsPixel == 1 && bmp.bmPlanes == 4) {

   /* In order to cut down on disk accesses, we process data buffers in
      batches, reading in all the first entries, then all the second
      entries, etc., until all the entries for each buffer have been read
      in, and then using all that data before refilling the buffers.
      This loop takes a long time to get through but is MUCH faster than
      the original Halcyon loop above. - jenny 5/26/93 */

   /* ToDo is the number of buffers left to read and process. */
   /* Batch is the number of buffers we deal with per go-round. */

       if ((ToDo = biHeight) < MAXBUFS)
	   Batch = ToDo;
       else
	   Batch = MAXBUFS;

   /* Allocate the buffers. */

       for (buf = 0; buf < Batch; buf++) {
	   outStr = _fmalloc(max(nWidthBytes,wWidthBytes));

	   /* If the malloc fails for our first buffer, we're out of luck.
	      Otherwise, we free the one or two most recently created
	      buffers to give the system more memory (320 bytes/buffer
	      for the current test file, BALLOONS.CLP), reset the value for
	      Batch to the modest number of buffers we actually have, and
	      go ahead. This allows relatively speedy import when enough
	      memory is available to support MAXBUFS buffers, and a graceful
	      decline in import speed as the available memory goes down. */

	   if (!outStr) {

	   /* Give up if this is our first buffer. */

	       if (buf == 0) {
		   err = HSI_EC_NOMEMORY;
		   goto cu0;
	       }

	   /* Free one or two buffers, depending how many we have. */

	       else if (buf > 2) {
		   buf--;
		   _ffree(OutStrArray[buf]);
	       }
	       buf--;
	       _ffree(OutStrArray[buf]);
	       Batch = buf;
	       break;
	   }
	   _fmemset ( outStr, zero, length );
	   OutStrArray[buf] = outStr;
       }

   /* Set up variables we'll use to jump around in the file. */ 
   /* Note: iwidth = space from start of entry X for buffer Y to
      start of entry X for buffer Y+1 */

       dataStart = ftell(Infile);   /* file position where data starts */

       currentStart = dataStart;    /* file position where data starts for
				       current batch of buffers */

       entryGap = biHeight * iwidth;/* space from START of entry X for buffer Y
				       to start of entry X+1 for buffer Y */

       Done = 0;                    /* number of buffers processed so far */

       while (ToDo > 0) {

      /* Fill this batch of buffers */

	   offset = 0;
	   entry = 0;

	   while (entry < ENTRIES) {

	/* Get the current entry for each buffer. */

	       for (buf = 0; buf < Batch; buf++) {
		   outStr = OutStrArray[buf] + offset;
		   l = _lread (Infile, outStr, iwidth);
		   if (l <= 0 ) {
		       err = HSI_EC_SRCCANTREAD;
		       goto cu0;
		   }
	       }

	/* Position file at the next entry for the first buffer of
	   this batch */

	       entry++;
	       fseek (Infile, currentStart + (entry * entryGap),
		      FILE_POS_START);

	/* Adjust the offset at which to read into the buffers. */

	       offset += iwidth;
	   }

     /* Use the data in this batch of buffers. */

	   for (buf = 0; buf < Batch; buf++) {

	       err = UseBufferData(Done + buf, lpStr, OutStrArray[buf],
				   biHeight, iwidth, width);
	       if (err)
		   goto cu0;
	   }

     /* Reposition file so as to start on the next batch. */

	   Done += Batch;
           currentStart = dataStart + (Done * iwidth);
	   fseek (Infile, currentStart, FILE_POS_START);

	   ToDo -= Batch;
	   if (ToDo < Batch)
	       Batch = ToDo;
       }
   }
   else {

   /* The data is laid out sequentially in the file, so we need only
      allocate a single buffer, fill it, use the data, refill it...
      This is the same as Halcyon's strategy, except that I've made
      UseBufferData into a separate routine. */

   /* Allocate the buffer. */

       lpOutStr = _fmalloc(max(nWidthBytes,wWidthBytes));

       if ( !lpOutStr )
	   {
	       err = HSI_EC_NOMEMORY;
	       goto cu0;
	   }

       _fmemset ( lpOutStr, zero, length );

   /* Fill and use, fill and use... */

       for ( i=0 ; i < biHeight ; i++ ) {
	   l = _lread (Infile,  lpOutStr,  wWidthBytes);
	   if (l <= 0 )
	       {
		   err = HSI_EC_SRCCANTREAD;
		   goto cu0;
	       }
	   err = UseBufferData(i, lpStr, lpOutStr, biHeight, iwidth, width);
	   if (err)
	       goto cu0;
       }
   }

/**************************************************************************/

   cu0:

   if ( lpStr )
       _ffree(lpStr);

   if ( lpOutStr )
       _ffree(lpOutStr);

    for (buf = 0; buf < MAXBUFS; buf++)
	if ( OutStrArray[buf])
	    _ffree(OutStrArray[buf]);

   return err;
}


int UseBufferData(int i, LPSTR lpStr, LPSTR lpOutStr, int biHeight,
		  int iwidth, int width)
{
    long l;
    extern  void EXPORT rgb2dib( LPSTR, LPSTR, WORD );

       if ( bmihdr.biBitCount == 4 )
          {
          _fmemcpy ( lpStr,           lpOutStr+2*iwidth,  width );
          _fmemcpy ( lpStr+width,     lpOutStr+iwidth,    width );
          _fmemcpy ( lpStr+2*width,   lpOutStr,           width );
          _fmemcpy ( lpStr+3*width,   lpOutStr+3*iwidth,  width );

          rgb2dib((LPSTR)lpStr,       // input buffer
                  (LPSTR)lpOutStr,    // output buffer
                  nWidthBytes );      // convert interleave single bpp RGB
                                      // color image to muti bpp image
          l = _lwrite (Outfile, (LPSTR)lpOutStr,  nWidthBytes);
          if (l <= 0 )
             {
	     return (HSI_EC_DSTCANTWRITE);
             }
          }
       else
       if ( bmihdr.biBitCount == 8 && bPlanar)
          {
          rgb82dib((LPSTR)lpOutStr,    // input buffer
                   (LPSTR)lpStr,       // output buffer
                   wWidthBytes,        // input byte length
                   nWidthBytes );      // output byte length

          l = _lwrite (Outfile,  (LPSTR)lpStr,  nWidthBytes);
          if (l <= 0 )
             {
	     return (HSI_EC_DSTCANTWRITE);
             }
          }
       else
          {
          l = _lwrite (Outfile,  (LPSTR)lpOutStr,  nWidthBytes);
          if (l <= 0 )
             {
	     return (HSI_EC_DSTCANTWRITE);
             }
          }

       l = _llseek(Outfile,  -2L * (long)nWidthBytes,  1);

       if (ImportszOption && ImportszOption->Disp)
          {
          static int cline4;
          int        ii;

          ii = (int)((DWORD) i *
                     (DWORD) (ImportszOption->end - ImportszOption->start) /
                     (DWORD) biHeight + ImportszOption->start);

          if (ii !=cline4)
             {
             cline4 = ii;
	     return ((*(ImportszOption->Disp))(cline4));
             }
          }
    return (0);
   }


/*
   Convert from 8 planes DDB to 8 bit DIB.
*/

void   rgb82dib(LPSTR inbuf, LPSTR outbuf, WORD n, WORD outlength )
   {
   int nbytes= n/8;    // loop counter
   int i,j,k;
   WORD    l=0;

   for (i=0;i<nbytes;i++)  
       {
       for (j=0;j<8;j++)       // go thru 8 bit for each byte
           {
           BYTE c=0;

           for (k=0;k<8;k++)   // go thru 8 scanlines
               {
               if (inbuf[k*nbytes+i] & BitPatternOr[j])
                   c |= BitPatternOr[7-k];
               }

           if (l>=outlength)   // enough data is collected.
               return;

           outbuf[l++] = c;
           }
       }
   }


/*
   Load the palette information to global palette array
*/

HSI_ERROR_CODE
Load30CLPPalette(void)
   {
   static WORD word;
   static WORD cnt;
   int i;
   static PALETTEENTRY rgb;
   short  err=0;
   long l;

   l = _lread(Infile,(LPSTR)&word,sizeof(WORD));  // should be 0x0300
   if (l <= 0 )
      {
      err = HSI_EC_SRCCANTREAD;
      goto cu0;
      }
   l = _lread(Infile,(LPSTR)&cnt,sizeof(WORD));   // number of colors
   if (l <= 0 )
      {
      err = HSI_EC_SRCCANTREAD;
      goto cu0;
      }
   /* the palette might be different from the bitmap. Do not save */
   /* the palette in the DIB if number of colors do not match.    */
   /* We will read the palette even if we are not going to use it */

   if (cnt != bmihdr.biBitCount)
       bUsePalette = FALSE;

   for (i=0;i< (int)cnt;i++)   // read all color palette entries
       {                       // and save to our global clr table

       l = _lread(Infile,(LPSTR)&rgb,sizeof(RGBQUAD));  // read next color entry
       if (l <= 0 )
          {
          err = HSI_EC_SRCCANTREAD;
          goto cu0;
          }
       if (bUsePalette)
           {
           clrtbl[i].rgbRed    = rgb.peRed;
           clrtbl[i].rgbGreen  = rgb.peGreen;
           clrtbl[i].rgbBlue   = rgb.peBlue;
           }
       }

 cu0:

   return err;
   }



/*
   The palette was read after the DDB data. We will seek to where
   the output file is and use the palette just read from CLP file.
*/

HSI_ERROR_CODE
UpdateDDBPalette(void)
   {
   short err=0;
   long  l;

   l = _llseek(Outfile,                        // seek to where palette is
           (long)sizeof(BITMAPFILEHEADER)+
           (long)sizeof(BITMAPINFOHEADER),
           0);                 
   if (l == -1L ) 
      {
      err=HSI_EC_DSTCANTSEEK; 
      goto cu0;
      }
   l = _lwrite(Outfile,
               (LPSTR)clrtbl,
               nColors * sizeof(RGBQUAD));

   if (l==0L) {err=HSI_EC_DSTCANTWRITE; goto cu0;}

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

*/


void EXPORT rgb2dib(LPSTR ibuf,LPSTR obuf,WORD n)
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















