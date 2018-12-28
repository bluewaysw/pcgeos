/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tiffload.c

AUTHOR:		Maryann Simmons, Jun 10, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/10/92   	Initial version.

DESCRIPTION:
	


	$Id: tiffload.c,v 1.1 97/04/07 11:27:45 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*********************************************************************
NAME        TIFLOAD.C

PURPOSE     TIFF Reader. This reader comply to TIFF 5.0 specification.
            Compression supported are as follow:

            TIFF B - monochrome image
               packit, ccitt g3

            TIFF G - gray scale image
            TIFF P - Palette color
            TIFF R - RGB color


HISTORY

06/51/89    Use stripByteCounts and rowsPerStipe to calcuate image stipe
            width when reading(WriteOutToFile)

06/27/89    Infile and Outfile must be external to this module to function
            properly, since they are not passed with function call(but,
            it can surely be done that way).

06/28/89    Handle color TIFF; PhotoMetric = 2, planarconfiguration=1,2

05/01/90    Convert to Windows 3.0

06/15/90    Handle ccitt large stripbytecount condition.

06/16/90    CCITT with

07/20/90    Buffered support for RGB 24 bit image. Use hpRGB to hold
            the image buffer (if sufficient memory is available). Flush
            image buffer out at the end.

04/05/91    Added support for compression 3 image. This is the CCITT G3
            compatible compression, where type 2 is modified G3 compression.

**********************************************************************/
#ifndef __WATCOMC__
#pragma Comment("@" __FILE__);
#endif

#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "hsidib.h"


#include <Ansi/stdlib.h>
#include <Ansi/string.h>    /*  _fmemcpy() */
/* #include <sys/types.h> */




#include "tif.h"
#include "lzw.h"

#define PACKBITSIZE 512

DWORD      stripbytecount;
short      ImportBmImageType;
short      totalstrip;
BOOL       fColor=FALSE;
BYTE       TypeSize[5]={1,1,2,4,8};
short      iGrayUnit=0;
int predictor=1;

// external function prototypes

int Unpackbit1s  (LPSTR, LPSTR, SHORT);
int  LzwDeChunk(LPSTR,DWORD,LPSTR,DCLPTREENODE,DWORD,LPSTR);

// local function prototypes

int    LzwDecompress     (DWORD, WORD );
int    LzwDeCompStrip    ( LPSTR, DWORD,/* WORD,*/ WORD );
int    parseTags         ( IFD *, Image *);
int    GetNextScanLine   ( LPSTR/*, WORD, WORD, WORD*/ );
int    PutNextScanLine   ( LPSTR/*, WORD, WORD*/ );
int    LoadOneStrip      ( LPSTR, WORD );
int    SaveOneStrip      ( LPSTR, WORD );
int    LoadLzwStrip      ( LPSTR, WORD );
int    LoadNextStrip     ( LPSTR, WORD );
int    LoadCCITTStrip    ( LPSTR, WORD );
int    WriteOutFile1       (void);
void swaprgb(LPSTR s,WORD n);

HSI_ERROR_CODE FAR PASCAL  HSILoadTIF  (FILE *,FILE *,LPCNVOPTION );
HSI_ERROR_CODE         LoadTIFFile     (void);
HSI_ERROR_CODE         WriteColor      (int);

DWORD MaskOffset[5] =
   {
       0xFFFFFFFF,
       0x000000FF,
       0x000000FF,
       0x0000FFFF,
       0xFFFFFFFF
   };


LPSTRIP    headStrip=NULL, ptStrip;
WORD       ImportWidthBytes;
IFD        *headIfd, *lastIfd;
Image      *image;

WORD       aBitsPerSample[8];
BYTE       filler[10];
char ImportStr[80];
int    Importn;
long   Importl;
short  err;
WORD   ImportCurrline;

/*********************************************************************

    FUNCTION HSILoadTIF(FILE * szInfile,FILE * szOutfile,LPCNVOPTION )

    PURPOSE        Convert TIF file to DIB

    Return         HSI ERROR CODE

**********************************************************************/

LPCNVOPTION   ImportszOption;

HSI_ERROR_CODE FAR PASCAL
HSILoadTIF(FILE * szInfile, FILE * szOutfile, LPCNVOPTION szOpt)
   {
   short               err=0;
   IFD                 *ifd;
   int                 i, version;
   static int          nRead;
   static short        ifdCount;
   static TifHeader    hdr;
   static long         offset;
   static char buf[128];


   ImportszOption = szOpt;
   ImportCurrline = 0;
   _fmemset((LPSTR)filler,0xFF,10);

   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

   // initialization
/*
   err = OpenInOutFile ( szInfile,
                         szOutfile );  // open input output files

   if ( err ) goto cu0;

*/
   // load the default color table (for Windows)

#ifdef WINVERSION
   LoadSystemColorTable(clrtbl256, &nRead);
#endif

   totalstrip = 1;             // default number of strip
   iGrayUnit=0;                // indicate no grayscale response curve
   predictor=1;


   fread( buf,                // read the tiff file header bytes
          1,
          SIZEOFTIFHEADER,
          Infile );

   hdr.byteOrder   = GetINTELWORD(buf);
   hdr.tiffVersion = GetINTELWORD(&buf[2]);
   hdr.ifdOffset   = GetINTELDWORD(&buf[4]);

   switch ( hdr.byteOrder )    // check which format we are
       {                       // using INTEL or MOTOROLA
       case 0x4949:
            brainDamage = TRUE;
            break;

       case 0x4d4d:
            brainDamage = FALSE;
            break;

       default:
           err = HSI_EC_UNSUPPORTED;
           goto cu1;
       }

   // version must be 0x2a

   version = fixshort(hdr.tiffVersion);

   if ( version != 0x2A )
       {
       err = HSI_EC_UNSUPPORTED;       // not a tiff file
       goto cu0;
       }

   offset = fixlong(hdr.ifdOffset);

   Importn=fseek( Infile, (long)offset, 0 ); // Seek to first IFD

   nRead = fread (buf,           // read IFD (Image Field Descriptor)
                  1,
                  2,                   // count
                  Infile );

   ifdCount=GetINTELWORD(buf);
   if (nRead <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   ifdCount = fixshort(ifdCount);

   if (ifdCount <= 0)
       {
       err = HSI_EC_UNSUPPORTED;
       goto cu0;
       }

   headIfd = lastIfd = NULL;           // initialize first and last
                                       // node for IFD link list
   for (i=0 ; i < ifdCount ; i++)
       {
       // allocate memory for new IFD node

       ifd = (IFD *)calloc(1,sizeof(IFD));

       if (!ifd)     // free up all nodes and return
          {
          err = HSI_EC_NOMEMORY;
          goto cu0;
          }

       if (!headIfd)
           {
           headIfd = ifd;
           lastIfd = ifd;
           }
       else
           {
           lastIfd -> next = ifd;
           lastIfd = ifd;
           }

       // read the content of each IFD from file

       nRead = fread ( buf,
                       1,
//                       SIZEOFIFD - sizeof (ifd->next),
                       SIZEOFIFD,
                       Infile);

       if (nRead <= 0 )
          {
          err = HSI_EC_SRCCANTREAD;
          goto cu0;
          }

       ifd -> tag      = GetINTELWORD(buf);
       ifd -> type     = GetINTELWORD(&buf[2]);
       ifd -> count    = GetINTELDWORD(&buf[4]);
       ifd -> offset   = GetINTELDWORD(&buf[8]);

       ifd -> next   = NULL;
       ifd -> tag    = fixshort (ifd -> tag);
       ifd -> type   = fixshort (ifd -> type);
       ifd -> count  = fixlong  (ifd -> count);

       // now, this is strange, the OFFSET field should ALWAYS be 4 bytes

       if ( ifd->count != 1L )
           ifd->offset = fixlong  ( ifd -> offset );
       else
          {  // ifd->count is equal to 1
          if ( ifd->type == 3 )
               ifd->offset = (WORD)fixshort((WORD)ifd->offset);
          else
              ifd->offset = fixlong(ifd->offset);
          }
       }

   // check whether there are more IFD entries, a LONG 0 indicate
   // there is no more IFDs. The first IFD should contain the image
   // with full resolution. Sub-images might be mask or scaled.

   // We do not process sub files at this point. (5/1/90)

   nRead = fread ( buf,
                   1,
                   4,
                   Infile );

   offset=GetINTELDWORD(buf);

   // allocate memory for image header

   image = (Image *)calloc(1,sizeof(Image));

   if (!image)
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // there is no default resolution value for TIFF, but 72 DPI seems
   // like a much safer assumption than 300 DPI. -Don 5/3/95

   image->xResolution = 72;    // default x resolution
   image->yResolution = 72;    // default y resolution
   image->resUnit     = 2;     // default to inch
   image->bogus       = 0;

   // Parse all IFD nodes

   {
   IFD *curIfd = headIfd;

   // initalize default value

   headStrip = NULL;
   fColor    = FALSE;          // use default color if no COLOR nor
                               // GRAY response curve
   image->samplesPerPixel = 1; // samplesPerPixel IFD might not exist
   image->rowsPerStrip    = 0; // rowsPerStrip IFD might not exist
   image->compression     = 1; // compression default to 1(no compression)
   image->photoMetric     = 0; //
   image->planeConfig     = 1; // default for color saving order
   image->bitsPerSample   = 0;

   while (curIfd != NULL)
       {
       err=parseTags(curIfd,image);
       if (err)
           goto cu0;

       curIfd = curIfd -> next;
       }
   }

   image->samplesPerPixel = (BYTE)max( image->samplesPerPixel, 1 );
   image->bitsPerSample   = (BYTE)max( image->bitsPerSample, 1);

   // decide image type

   if ( image->samplesPerPixel == 3 )
       ImportBmImageType = 2;        // RGB Full color image
   else
   if ( image->samplesPerPixel == 1 )
       {
       if ( image->photoMetric == 3 )
           ImportBmImageType = 3;     // palette color
       else
           {
           if ( image->bitsPerSample == 1 )
               ImportBmImageType = 0; // monochrome image */
           else
               ImportBmImageType = 1; // greyscale image */
           }
       }
   else
       {
       err = HSI_EC_UNSUPPORTED;   /* we don't support this type of image */
       goto cu0;                   
       }

   // Each image type can use certain compression algorithm

   switch ( ImportBmImageType )
       {
       case 0 :    // mono image can only use packbit or CCITT
                   // compression

           if ( image->compression == 5 )
               {                          // Gamma fax format?!
               err = HSI_EC_UNSUPTCOMP;
               goto cu0;
               }
           break;

       default :
           if ( image->compression != 5 &&
                image->compression != 32773 &&  // Storyboard use Packbit for
                image->compression != 1 )       // images!
               {
               err = HSI_EC_UNSUPTCOMP;
               goto cu0;
               }

           break;
       }

   // Load TIFF image to DIB file format

   err = LoadTIFFile();

   if ( err ) goto cu0;

   cu0:

   // free up all previously allocated memory

   if (headStrip)
       FreeStripNodes(headStrip); // free nodes for stripoffset if any

   if (headIfd)
       FreeAllNodes(headIfd);

   cu1:

   // close files is currently open
/*
   CloseInOutFile();
*/
   if (!err && ImportszOption && ImportszOption->Disp)
       (*(ImportszOption->Disp))(ImportszOption->end);

   return err;
   }



// release all IFD nodes allocated previously

void    FreeAllNodes( IFD *Ifd )
   {
   IFD        *tIfd;

   tIfd = Ifd;
   while ( tIfd != NULL )
        {
        tIfd = Ifd -> next;
        free((char *)Ifd);
        Ifd     = tIfd;
        }
   }


// release all Strip offset nodes if any */

void    FreeStripNodes(LPSTRIP pt )
   {
   LPSTRIP pt1=pt;

   while ( pt1 != NULL )
        {
        pt = pt1->next;
        free((LPSTR)pt1);
        pt1 = pt;
        }
   }



/*
    Load TIFF data to DIB format
*/

HSI_ERROR_CODE
LoadTIFFile (void)
   {
   short   err = 0, l=0;
   LPSTR   lpstr=NULL;

   extern HSI_ERROR_CODE  PrepDIBHeader(VOID);

   // prepare DIB file header info

   err = PrepDIBHeader();

   if (err) goto cu0;

//   if ( image->photoMetric == 2 && image->planeConfig == 1 )
//        num_x_bytes *= image->samplesPerPixel;

   // default rowsPerStrip to image height if necessary

   if ( image->rowsPerStrip == 0 ||
        image->stripByteCounts == 1 &&
        image->rowsPerStrip > bmihdr.biHeight )
        image->rowsPerStrip = bmihdr.biHeight;

   stripbytecount = (DWORD) nWidthBytes *
                           image->rowsPerStrip;

   // DIB is written backward, seek to the end of file (force FAT)
   // allocation.

   Importn=fseek ( Outfile,
           (long)bmfhdr.bfSize,
           0 );

   if (Importn != 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   Importn=fseek ( Outfile,                      // get ready for the 1st
           -1L * (LONG)nWidthBytes,        // output scanline
           1 );

   if (Importn != 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // Use different algorithm for RGB plane image (24 or 3 bit)

   if ( image->photoMetric == 2 && image->planeConfig == 2 )
       {/*
       extern HSI_ERROR_CODE LoadRGBImage(VOID);

       err=LoadRGBImage();
       */
	err = TE_IMPORT_NOT_SUPPORTED;
       return err;
       }

   if ( stripbytecount > 20480L  )
       {
       // not enought memory for large stripe, try another approach

       err = WriteOutFile1();

       return err;
       }


   // convert one strip at a time

   ptStrip = headStrip;
   l = 0;

   while (ptStrip)
        {

        WORD    height;

        // since it is possible for a TIFF not having stripbytecount
        // (ImageEdit), we need plug it in here.

        if (ptStrip->stripByteCount==0)
           ptStrip->stripByteCount = stripbytecount;

        // obtain number of rows to load. The last one will be different

        height = (WORD)(((l+1) * image->rowsPerStrip) > bmihdr.biHeight  ?
                  (bmihdr.biHeight % image->rowsPerStrip) :
                  image->rowsPerStrip);

        lpstr =_fmalloc((WORD)max(ptStrip->stripByteCount,height*nWidthBytes));

        if (!lpstr)
           {
           err=HSI_EC_NOMEMORY;
           goto cu0;
           }

        // seek to where the strip is

        Importn=fseek( Infile, (long)ptStrip->stripOffset, 0 );

        // load one strip of data to memory

        err = LoadOneStrip( lpstr, height );

        if ( err )  goto cu0;

        // save one strip of data to DIB file

        err = SaveOneStrip( lpstr, height );

        if ( err )  goto cu0;

        // get next strip, if any

        ptStrip = ptStrip->next;
        l++;

        _ffree(lpstr);
        }

   cu0:

   if (lpstr) _ffree(lpstr);

   return err;

   }  /* end of LoadTIFFile procedure */



HSI_ERROR_CODE
PrepDIBHeader()
   {
   short err=0;
   int   nWrite;
   static char buf2[40];

   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;

   bmihdr.biSize       = 40L;
   bmihdr.biClrUsed    = 0L;

   bmihdr.biCompression   = 0L;

   // calculate the pixel per meter from the dpi in X and Y resolution

   switch (image->resUnit)
       {
       case 1 :    // device unit
           bmihdr.biXPelsPerMeter = 0L;
           bmihdr.biYPelsPerMeter = 0L;
           break;

       case 2:     // inch
           bmihdr.biXPelsPerMeter = (long)(image->xResolution * 100 / 2.54);
           bmihdr.biYPelsPerMeter = (long)(image->yResolution * 100 / 2.54);
           break;

       case 3:     // in perspercentimeter
           bmihdr.biXPelsPerMeter = (long)image->xResolution;
           bmihdr.biYPelsPerMeter = (long)image->yResolution;
           break;
       }

   bmihdr.biClrImportant  = 0L;

   bmihdr.biHeight     = image->height;
   bmihdr.biWidth      = image->width;
   bmihdr.biPlanes     = 1;                // always 1

   // decide the bit depth

   switch ( ImportBmImageType )
       {
       case 0 :    // mono
           bmihdr.biBitCount   = 1;
           break;

       case 1 :    // gray, has to be 4 or 8 ?
           if ( image->bitsPerSample <= 4 )
               bmihdr.biBitCount   = 4;
           else
               bmihdr.biBitCount   = 8;
           break;

       case 2 :    // RGB 24 bit color
           if (image->bitsPerSample==8)
              bmihdr.biBitCount   = 24;
           else
           if (image->bitsPerSample==1)
               {
               if ( image->samplesPerPixel == 1 )
                  bmihdr.biBitCount = 4;   // 8 color image to 16 color
               else
                  bmihdr.biBitCount = 4;   // 8 color image to 16 color
               }
           else
              {
              err=HSI_EC_UNSUPPORTED;
              goto cu0;
              }
           break;

       case 3 :    // color palette
           if ( image->bitsPerSample == 1 )
               bmihdr.biBitCount   = 1;
           else
           if ( image->bitsPerSample <= 4 )
               bmihdr.biBitCount   = 4;
           else
           if ( image->bitsPerSample <= 8 )
               bmihdr.biBitCount   = 8;
           else
               {
               err = HSI_EC_UNSUPPORTED;
               goto cu0;
               }
           break;

       }

   // get total number of colors for this file
   nColors = GetNumColor();

   if ( ImportBmImageType == 2 )             // RGB Color
       {
       if (bmihdr.biBitCount==24)
           ImportWidthBytes = (WORD)image->width * 3;
       else
           ImportWidthBytes = (WORD)(image->width+7)/8;
       }
   else
       ImportWidthBytes = (WORD)( image->width * image->bitsPerSample + 7)/8;

   // calculate real size in byte of one scanline

   wWidthBytes = (WORD) ((bmihdr.biWidth * bmihdr.biBitCount ) +
                   7 ) / 8 * bmihdr.biPlanes;

   // normalize scanline width to LONG boundary

   nWidthBytes = ( wWidthBytes + sizeof(LONG)-1 ) /
                   sizeof(LONG) *
                   sizeof(LONG);

   bmihdr.biSizeImage = (DWORD)nWidthBytes * bmihdr.biHeight;

   // calculate offset to bitmap data

   bmfhdr.bfOffBits   = SIZEOFBMPFILEHDR +
                        SIZEOFBMPINFOHDR +
                        nColors * SIZEOFRGBQUAD;

   // calculate total size of this image

   bmfhdr.bfSize      = bmihdr.biSizeImage +
                        bmfhdr.bfOffBits;

   // write out file header

   copybmf2buf(&bmfhdr,buf2);

   nWrite = fwrite (  buf2,
                      SIZEOFBMPFILEHDR,
                      1,
                      Outfile );

   if (nWrite <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // write out header info

   copybmi2buf(&bmihdr,buf2);

   nWrite = fwrite(    buf2,
                       SIZEOFBMPINFOHDR,
                       1,
                       Outfile );

   if (nWrite <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // write out color palette

   err=WriteColor ( ImportBmImageType );

   if (err) goto cu0;

   cu0:

   return err;
   }


/*
  Load the strip of data to memory. Uncompress the data if necessary
*/
int LoadOneStrip( LPSTR lpstr, WORD height )
   {
   short     err = 0;

   // decompress the whole chunk for LZW compression. Skip the FOR loop

   switch ( image->compression )
       {
       case 5 : // LZW compression

           err = LoadLzwStrip( lpstr, height );
           if ( err ) goto cu0;

           /*
           ** adjust the image if the horizontal differencing
           ** predictor is set to 2
           */

           if (predictor==2)
               {
               int i,j,off;

               for (i=0;i<height;i++)
                   {
                   off = i * nWidthBytes;

                   for (j=1;j<nWidthBytes;j++)
                       {
                       lpstr[off+j] += (int)lpstr[off+j-1];
                       }
                   }
               }

           break;

       case 2 : // CCITT compression
       case 3 : // CCITT compression, GAMMA LINK

           // Decompress the lines in the strip before the ones
           // we want to advance the file pointer

           err = LoadCCITTStrip(lpstr, height );
           if ( err ) goto cu0;
           break;

       case 1 :
       case 32773 :

           err = LoadNextStrip ( lpstr, height );
           if ( err ) goto cu0;
           break;

       default :
           err = HSI_EC_UNSUPTCOMP;   // unsupported compression
           goto cu0;
       }

   cu0 :

   return err;
   }


int
LoadNextStrip (LPSTR lpStr, WORD height )
   {
   LPSTR   buf=NULL;
   /*LPSTR   t;*/
   short   cnt, err=0, i;
   long    nRead;
   WORD    iwidthBytes;

   // allocate memory to hold one scanline
   // the worst case compression for PackBit is 1 larger than original
   // (or might be two, due the the problem created by Micrografx TIFF
   // export filter!)

   buf = _fmalloc(max(ImportWidthBytes,PACKBITSIZE));
//   buf = _fmalloc(ImportWidthBytes+5);

   if ( !buf )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

  /* t = lpStr;*/

   if (image->compression == 32773)// worst case packbit has one more
       iwidthBytes = max(ImportWidthBytes,PACKBITSIZE); // byte. Somehow one of the Micrografx
                                          // file has two extra bytes!
   else
       iwidthBytes = ImportWidthBytes;

   /* load each scanline into memory. We don't have to worry too much
    about the bit alignment, since we can only have monochrome image
    with these type of compression(PackBit) or no compression. */

   for ( i=0;i!= (int)height;i++)
       {
       // read next scanline

       nRead = lfread( buf,
                      1,
                      iwidthBytes,
                      Infile );

       if ( nRead <= 0 )
           {
           err = HSI_EC_SRCCANTREAD;
           goto cu0;
           }

       // check compression scheme and act accordingly

       switch (image -> compression)
           {


           case 1 :
               // no compression, straight copy
               _fmemcpy((LPSTR)lpStr,(LPSTR)buf,ImportWidthBytes );
               break;

           case 32773 :    /* packbit */

               // unpack one scanline at a time

               cnt = Unpackbit1s((LPSTR)buf, (LPSTR)lpStr, ImportWidthBytes );

               if ( cnt == 0 )
                   {
                   err = HSI_EC_DSTCANTWRITE;
                   goto cu0;
                   }

               if ((WORD)cnt > (WORD)nRead)
                   {
                   err =HSI_EC_INVALIDFILE;
                   goto cu0;
                   }

               // go back to line offset

               Importn=fseek( Infile, (long)cnt - nRead, 1 );

               break;

           }       // end of switch

       // increment output buffer offset

       lpStr += nWidthBytes;

       } /* end each scanline */


   cu0:

   if (buf) _ffree(buf);

   return err;
   }



/*
   Decompress one strip of LZW data. Normalize it afterward. Normalize

      1. boundary condition
      2. contigous RGB color
      3. palette color bit depth
      4. grayscale bit depth

   LZW decompress one chunk at a time. The buffer needs to be
   rearranged to have proper LONG alignment. We can skip this step
   by writing each scanline out to file directly, although this is
   not always the case, since we might not load to file for
   performance reason.
*/

int
LoadLzwStrip(LPSTR outBuf, WORD height)
   {
   short     err=0, i;
   LPSTR     lpTStr=NULL, dst,src=outBuf;

   // decompress one strip of LZW image

   err = LzwDeCompStrip(src,
                        (DWORD)ptStrip->stripByteCount,
                        /*(WORD)ImportWidthBytes,*/
                        (WORD)height );

   if ( err ) goto cu0;

   // allocate a temporary buffer with equal size

   lpTStr = _fmalloc(nWidthBytes*height);

   if ( !lpTStr )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   dst = lpTStr;

   // normalize the buffer to comply to DIB format

   for ( i=0;i!=(int)height;i++)
       {
       // take care of palette color where bitspersample can be
       // between 1 and 8

       switch ( ImportBmImageType )
           {
           case 1 :    // gray
               if ( image->bitsPerSample == 4 ||
                    image->bitsPerSample == 8 )
                  _fmemcpy ( dst, src, ImportWidthBytes );
               else
                  {
                  // convert to 4 or 8 bits! ???

                  _fmemcpy ( dst, src, ImportWidthBytes );
                  }
               break;

           case 2 :    // 24 bit rgb color, straight copy
               _fmemcpy ( dst, src, ImportWidthBytes );
               break;

           case 3 :    // palette color
               if ( image->bitsPerSample == 4 ||
                    image->bitsPerSample == 8 )
                  _fmemcpy ( dst, src, ImportWidthBytes );
               else
                  {
                  // convert to 4 or 8 bits! ???

                  _fmemcpy ( dst, src, ImportWidthBytes );
                  }
               break;

           }

       src += ImportWidthBytes;
       dst += nWidthBytes;

       }

   // copy memory back

   _fmemcpy(outBuf,
            lpTStr,
            nWidthBytes * height );

   cu0:

   if (lpTStr ) _ffree(lpTStr);

   return err;
   }



/*
   Load the strip data that is compressed with CCITT group III
   method.
*/

int
LoadCCITTStrip( LPSTR outBuf, WORD height )
   {
   short     err=0, i;
   long      nRead=0;
   LPSTR     inBuf=NULL, src=outBuf, dst;


   inBuf = _fmalloc(nWidthBytes*height+(WORD)bmihdr.biWidth );

   if ( !inBuf )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   dst = inBuf;

   // read the strip data

   nRead = lfread (src,
                   1,
                   (WORD)ptStrip->stripByteCount,
                   Infile );

   if ( nRead <= 0 )
      {
      err = HSI_EC_SRCCANTREAD;
      goto cu0;
      }

   // decompress the strip of CCITT data

   for ( i=0;i< (int)height;i++)
      {
      int cnt;
      extern int dcpt4(LPSTR,LPSTR,WORD,WORD);

      cnt = dcpt4((LPSTR)src,
                  (LPSTR)dst,
                  (WORD)bmihdr.biWidth,
                  (WORD)nWidthBytes );

      if ( cnt == 0 )
           break;

      src += cnt;
      dst += nWidthBytes;

      }

   // copy the decompressed data back to input buffer

   _fmemcpy ( outBuf,
              inBuf,
              nWidthBytes*height );

   cu0:

   if (inBuf)  _ffree(inBuf);

   return err;
   }


/*
 * Save image data from memory to file
 */
int
SaveOneStrip( LPSTR lpStr, WORD height )
   {
   short    err = 0, i;

   for ( i=0; i < (int)height ; i++ )
       {
       if (image->photoMetric==2 &&   /* the RGB data needed to be written   */
           image->bitsPerSample==8 && /* backward for 8 bit per sample data  */
           image->samplesPerPixel==3)
           swaprgb(lpStr,nWidthBytes);/* flip the buffer backward.           */

       Importl=lfwrite( lpStr,
                  1,
                  nWidthBytes,
                  Outfile );

       if (Importl <= 0L) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       lpStr += nWidthBytes;

       Importn=fseek(Outfile, -2L * (long)nWidthBytes, 1);

       if (ImportszOption && ImportszOption->Disp)
           {
           static int clinel;
           int        i;

           i = (int)((DWORD) ImportCurrline++ *
                     (DWORD) (ImportszOption->end-ImportszOption->start) /
                     (DWORD)bmihdr.biHeight) +
                     ImportszOption->start;

           if (i!=clinel)
               {
               clinel = i;
               err=(*(ImportszOption->Disp))(clinel);
               if (err) goto cu0;
               }
           }

       }

   cu0:

   return err;
   }




DWORD  lsize;
short  currcolor;

int WriteOutFile1(void)
   {
   short    /*inbytes,*/ err=0;
  /* short    ByteOffset;*/
   WORD     l=0/*, k=0*/;
   LPSTR    buf=NULL;

   // the worst case for PackBits is 1 byte extra per scanline
/*
   if ( image->compression == 32773 )
       inbytes     = ImportWidthBytes + 1;
   else
       inbytes     = ImportWidthBytes;
*/
   buf  = _fmalloc(max(nWidthBytes+2,PACKBITSIZE));
//   buf  = _fmalloc(nWidthBytes+5);

   if ( !buf )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }
/*
   ByteOffset = nWidthBytes;
*/
   // convert one strip at a time

   ptStrip = headStrip;
   l = 0;

   lsize     = 0L; // used for interleaved RGB image only
   currcolor = 0;  //        "              "

   while (ptStrip )
       {
       short    j;

       WORD   height = (WORD)(((l+1) * image->rowsPerStrip) > bmihdr.biHeight ?
                           (bmihdr.biHeight % image->rowsPerStrip) :
                           image->rowsPerStrip);

       // seek to where the strip is

       Importn=fseek( Infile, (long)ptStrip->stripOffset, 0 );

       if (ptStrip->stripByteCount==0)
           ptStrip->stripByteCount=stripbytecount;

       // LZWcompression is handled with its own algorithm

       if ( image->compression == 5 )
           {
           err = LzwDecompress((DWORD)ptStrip->stripByteCount,
                               (WORD)height );
           if ( err ) goto cu0;

           // get next strip

           ptStrip = ptStrip->next;
           l++;
           continue;
           }


       for ( j=0;j != (int)height;j++)
           {


           // read from input file next scanline and write
           // it to temporary file

           err = GetNextScanLine(  (LPSTR)buf /*,
                                   (WORD)inbytes,
                                   (WORD)ImportWidthBytes,
                                   (WORD)height*/ );

           if (err) goto cu0;

           err = PutNextScanLine(  (LPSTR)buf/*,
                                   (WORD)height,
                                   (WORD)j*/ );

           if (err) goto cu0;
           }

       /* get next strip, if any */
       ptStrip = ptStrip->next;
       l++;
       }

   cu0:

   if (buf)
       _ffree(buf);

   return err;

   }  /* end of WriteOutputFile1 procedure */



/*
 * Read one scanline from input file and write it to the tempory file. Perform
 * decompression accordingly.

 * -NOTE- If an RGB image with PhotoMetric set to 2, then color planes are
 * stored in 'planes', if PhotoMetric is 1, then RGB will be stored within
 * each pixel(RGBRGBRGB...).
 *
 * Input Values
 *
 *         buf          buffer that hold the input scanline data
 *         inbytes      number of bytes contained in the buffer
 *         num_x_bytes  input scanline width(in bytes) w/o color consideration
 *         ImportWidthBytes   width(in bytes) for output(tempory) file.
 */

int  GetNextScanLine( LPSTR buf/*, WORD nbytes,WORD num_x_bytes,WORD height*/ )
   {
   int     cnt;
   long    nRead;
   short   err = 0;
   extern int dcpt4(LPSTR,LPSTR,WORD,WORD);

   LPSTR   outBuf=NULL;

   outBuf  = _fmalloc(max(nWidthBytes,PACKBITSIZE));
//   outBuf  = _fmalloc(nWidthBytes+5);

   if ( !outBuf )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // check compression scheme and act accordingly

   switch (image -> compression)
       {
       case 1 :    /* no compression */
           nRead = lfread(buf,1,(DWORD)ImportWidthBytes,Infile );
           break;

       case 2 :    // CCITT G3(t.4) compression
       case 3 :    // CCITT G3(t.4) compression, GAMMALINK

           nRead = lfread(buf,1,(DWORD)ImportWidthBytes,Infile );
           cnt = dcpt4  (  (LPSTR)buf,
                           (LPSTR)outBuf,
                           (WORD)bmihdr.biWidth,
                           (WORD)nWidthBytes );

           if ( cnt == 0 )
               {
               err = HSI_EC_INVALIDFILE;
               goto cu0;
               }

           // go back to line offset

           Importn=fseek( Infile, (long)cnt - nRead, 1 );

           // copy outbuffer to buf before write

           _fmemcpy( buf, outBuf, nWidthBytes );

           break;

       case 32773 : /* Packbit */
           {
   // note: nRead might not be equal to num_x_bytes for compressed
   // file or the last strip. For PackBit image, inbyte might be
   // one larger than num_x_bytes for the worst case(all bytes within
   // the scanline are different. We are adding two here, since files
   // generated by Micrografx has such worst case (strange!)

           nRead=lfread(buf,1,(DWORD)ImportWidthBytes+5,Infile );

           // unpack the line buffer

           cnt=Unpackbit1s((LPSTR)buf,(LPSTR)outBuf,ImportWidthBytes);

           if (cnt==0)
               {
               err = HSI_EC_DSTCANTWRITE;
               goto cu0;
               }

           if ((WORD)cnt > (WORD)nRead)
               {
               err =HSI_EC_INVALIDFILE;
               goto cu0;
               }

           // go back to line offset

           Importn=fseek( Infile, (long)cnt - nRead, 1 );

           // copy outbuffer to buf before write

           _fmemcpy( buf, outBuf, ImportWidthBytes );

           break;

           }

       default :
           err = HSI_EC_UNSUPPORTED;
           goto cu0;

       } /* end of switch */

   // reverse the image for bi-level
/*
   if ( image->photoMetric == 0 && image->bitsPerSample == 1 )
       {
       WORD     n = ImportWidthBytes;
       LPSTR    t = buf;

       while ( n-- )
           {
           *t = ~*t;
           t++;
           }
       }
*/
   cu0:

   // release memory no longer needed

   if ( outBuf )
       _ffree(outBuf);

   return err;
   }


/*
 * Write the scaline to output file.
 */
int PutNextScanLine( LPSTR buf/*, WORD height, WORD k */)
   {
   short    err = 0;

   if ( image->photoMetric==2 &&   /* the RGB data needed to be written    */
        image->bitsPerSample==8 && /* backward for 8 bit per sample data   */
        image->samplesPerPixel==3)
       swaprgb(buf,nWidthBytes);   /* flip the buffer backward.            */

   Importl=lfwrite(buf,
             1,
             (DWORD)nWidthBytes,
             Outfile );

   if (Importl <= 0L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // rewind one scanlines to previous position

   Importn=fseek ( Outfile, -2L * (long)nWidthBytes, 1 );

   if (ImportszOption && ImportszOption->Disp)
       {
       static int cline2l;
       int        i;

       i = (int)((DWORD) ImportCurrline++ *
                 (DWORD) (ImportszOption->end-ImportszOption->start) /
                 (DWORD)bmihdr.biHeight) +
                 ImportszOption->start;

       if (i!=cline2l)
           {
           cline2l = i;
           err=(*(ImportszOption->Disp))(cline2l);
           if (err) goto cu0;
           }
       }

   cu0:

   return err;
   }


/*
 * Parse each TIFF Tag to the Image file header data structure
 */
parseTags (
   IFD     *ifd,        // pointer to the IFD node in the link list
   Image   *image       // structure to hold image header information
   )
   {
   int     i;
   static char buf3[40];
   BYTE    byteSize;
   short   err=0;

   switch (ifd -> tag)
       {
       case TAG_NewSubfileType:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];

           if ( ifd->offset != 0L )
               break;    /* cannot handle sub-file yet */

           image -> resolution = (BYTE)ifd -> offset;
           break;

       case TAG_ImageWidth:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> width  = ifd -> offset;
           break;

       case TAG_ImageLength:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> height = ifd -> offset;
           break;

       case TAG_BitsPerSample:
           if ( ifd->count == 1 )
               {
               ifd->offset = ifd->offset & MaskOffset[ifd->type];

               image->bitsPerSample = (BYTE)ifd->offset;

               if ( image->bitsPerSample <= 0 || image->bitsPerSample > 8 )
                   return HSI_EC_UNSUPPORTED; // not supported format

               break;
               }

           // more than 1 value exist

           Importn=fseek ( Infile, (long)ifd->offset, 0 );

           for ( i=0;i!= (int)ifd->count ; i++)
               {
               fread( buf3,
                      1,
                      TypeSize[ifd->type],
                      Infile );

               switch(TypeSize[ifd->type])
                   {
                   DWORD dw;

                   case 1: aBitsPerSample[i]=*buf3;break;
                   case 2: aBitsPerSample[i]=GetINTELWORD(buf3);break;
                   case 4 :
                   case 8:
                       dw=GetINTELDWORD(buf3);
                       aBitsPerSample[i]=(WORD)fixlong(dw);
                       break;
                   }
               }

           image->bitsPerSample   = (BYTE)aBitsPerSample[0];
           break;

       case TAG_Compression:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> compression = (WORD)ifd -> offset;

           break;

       case TAG_PhotometricInterpretation:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> photoMetric = (BYTE)ifd -> offset;
           break;

       case TAG_SamplesPerPixel:

           /* 1: bi-level/grey/palette color, 3: RGB color */

           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> samplesPerPixel = (BYTE)ifd -> offset;

           /* if ( image->samplesPerPixel > 3 ) return 5; */

           break;

       case TAG_RowsPerStrip:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> rowsPerStrip = ifd -> offset & 0xffff;
           break;

       case TAG_StripByteCounts:
       case TAG_StripOffsets:
           // prep the first node

           if ( headStrip == NULL )
               {
               headStrip = (LPSTRIP)_fmalloc(sizeof(STRIP));

               if ( headStrip == NULL )
                  return HSI_EC_NOMEMORY; /* not enough memory */

               headStrip->next = NULL;
               headStrip->stripByteCount = 0;
               }

           byteSize = TypeSize[ ifd->type - 1 ];

           if ( ifd->count == 1 )
               {
               if ( ifd->tag == TAG_StripByteCounts )
                   {
                   image->stripByteCounts    = 1;
                   headStrip->stripByteCount = ifd -> offset;
                   }
               else
                   {
                   image->stripOffset        = 1;
                   headStrip->stripOffset    = ifd -> offset;
                   }
               break;
               }

           /* build the link list that contain all offsets. If link list adready
           * exist (StripByteCount comes before this tag), then fill in
           * the value.
           */
           ptStrip = headStrip;

           Importn=fseek    ( Infile, (long)ifd->offset, 0 );

           /* read the first offset value and put it in the link list */
           if ( ifd->tag == TAG_StripByteCounts )
               {
               static DWORD dword;

               image->stripByteCounts = ifd->count;

               fread(buf3,
                     1,
                     byteSize,
                     Infile );

               switch (byteSize)
                  {
                  case 1: dword=*buf3;break;
                  case 2: dword=GetINTELWORD(buf3);break;
                  case 4:
                  case 8: dword=GetINTELDWORD(buf3);break;
                  }

               ptStrip->stripByteCount = dword;

               /* take care of byte swap problem */
               if ( ifd->type == 3 )
                   ptStrip->stripByteCount = (WORD)fixshort((WORD)ptStrip->stripByteCount );
               else
               if ( ifd->type == 4 )
                   ptStrip->stripByteCount = fixlong(ptStrip->stripByteCount );
               }
           else
               {
               static DWORD dword1;

               image -> stripOffset    = ifd->count;

               fread(buf3,
                     byteSize,
                     1,
                     Infile );

               switch (byteSize)
                  {
                  case 1: dword1=*buf3;break;
                  case 2: dword1=GetINTELWORD(buf3);break;
                  case 8:
                  case 4: dword1=GetINTELDWORD(buf3);break;
                  }

               ptStrip->stripOffset = dword1;

               /* take care of byte swap problem */

               if ( ifd->type == 3 )
                ptStrip->stripOffset = (WORD)fixshort((WORD)ptStrip->stripOffset );
               else
               if ( ifd->type == 4 )
                   ptStrip->stripOffset = fixlong(ptStrip->stripOffset );
               }

           totalstrip = (short)ifd->count;

           /* get each offset values and put it in the link list */

           for ( i=1; i!= (int)ifd->count; i++)
               {
               // create the node on the fly

               if (!ptStrip->next)
                   {


                   ptStrip->next = (LPSTRIP)_fmalloc(sizeof(STRIP));

                   if (!ptStrip->next)
                       return HSI_EC_NOMEMORY; /* not enough memory */

                   ptStrip = ptStrip->next;

                   ptStrip->next = NULL;
                   ptStrip->stripByteCount = 0;
                   }
               else
                   ptStrip = ptStrip->next;

               /* read the first offset value and put it in the link list */

               if ( ifd->tag == TAG_StripByteCounts )
                   {
                   static DWORD dword2;

                   fread( buf3,
                          1,
                          byteSize,
                          Infile );

                   switch(byteSize)
                     {
                      case 1: dword2=*buf3;break;
                      case 2: dword2=GetINTELWORD(buf3);break;
                  case 8:
                      case 4: dword2=GetINTELDWORD(buf3);break;
                      }

                   ptStrip->stripByteCount=dword2;

                   /* take care of byte swap problem */
                   if ( ifd->type == 3 )
                       ptStrip->stripByteCount = (WORD)fixshort((WORD)ptStrip->stripByteCount );
                   else
                   if ( ifd->type == 4 )
                       ptStrip->stripByteCount = fixlong(ptStrip->stripByteCount );
                   }
               else
                   {
                   static DWORD dword3;

                   fread( buf3,
                          1,
                          byteSize,
                          Infile );

                   switch(byteSize)
                      {
                      case 1: dword3=*buf3;break;
                      case 2: dword3=GetINTELWORD(buf3);break;
                  case 8:
                      case 4: dword3=GetINTELDWORD(buf3);break;
                      }

                   ptStrip->stripOffset=dword3;

                   /* take care of byte swap problem */
                   if ( ifd->type == 3 )
                       ptStrip->stripOffset = (WORD)fixshort((WORD)ptStrip->stripOffset );
                   else
                   if ( ifd->type == 4 )
                       ptStrip->stripOffset = fixlong(ptStrip->stripOffset );
                   }
               }
           break;

       case TAG_ResolutionUnit:

           // Type = short
           //      1: device unit
           //      2: inch
           //      3: centimeter

           image -> resUnit = (BYTE)ifd->offset;

           break;

       case TAG_XResolution:

           // two longs; the first represent the numerator of a fraction
           // the 2nd denominator

           if (ifd->type != IFD_RATIONAL)    // should be RATIONAL
               break;

           fseek( Infile,                      // goto proper offset
                  (long)ifd->offset,
                  0 );

           {
           static long l,d;

           fread(buf3,1,4,Infile);    // fraction
           l = GetINTELDWORD(buf3);
           fread(buf3,1,4,Infile);    // denominator
           d = GetINTELDWORD(buf3);

           if (d)
              image->xResolution = fixlong((DWORD)l) / fixlong((DWORD)d);
           }

           break;

       case TAG_YResolution:

           // two longs; the first represent the numerator of a fraction
           // the 2nd denominator

           if (ifd->type != IFD_RATIONAL)    // should be RATIONAL
               break;

           fseek( Infile,                      // goto proper offset
                  (long)ifd->offset,
                  0 );

           {
           static long l2,d2;

           fread(buf3,1,4,Infile);    // fraction
           l2 = GetINTELDWORD(buf3);
           fread(buf3,1,4,Infile);    // denominator
           d2 = GetINTELDWORD(buf3);

           if (d2)
               image->yResolution = fixlong((DWORD)l2) / fixlong((DWORD)d2);
           }

           break;

       case TAG_PlanarConfiguration:
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           image -> planeConfig = (BYTE)ifd -> offset;
           break;

       case TAG_GrayResponseUnit:

           // 1: tenth, 2:hundredth, 3:thousandth, 4:ten-thousandth
           // 5: hundred-thousandths of a unit
           // default to 2, recomment 3

           iGrayUnit = (short)ifd->offset;

           break;

       case TAG_GrayResponseCurve:
           {

           // although not required for TIFF P, but this curve is
           // used by applications like Scanning Gallery. If not processed
           // the gray curve is reverse.

           // Meanwhile, we are not use this response curve values. In
           // stead, of will check the phometric flag to decide the
           // gray intensity.

           WORD    maxcolor=0;
           int     j,div;
           int iColors= 1 << image->bitsPerSample;  // level of grays
           static WORD kl;      // gray value

           Importn=fseek(Infile,(long)ifd->offset, 0 );   // goto proper offset

           for ( j=0;j<iColors;j++)
               {
               fread(buf3,                   // get the maximum value out
                     1,
                     2,
                     Infile );
               kl = GetINTELWORD(buf3);
               maxcolor = max(maxcolor,kl);
               }

           if (maxcolor < 256 )
               div=1;
           else
               div=(maxcolor+127)/256; // HPScanner use 2000 as maximum

           Importn=fseek(Infile, (long)ifd->offset, 0 );  // goto proper offset

           for ( j=0;j<iColors;j++)
               {
               fread(buf3,                   // read the next gray value
                     1,
                     2,
                     Infile );
               kl=GetINTELWORD(buf3);
               clrtbl[j].rgbRed    = (BYTE) (kl/div);
               clrtbl[j].rgbGreen  = (BYTE) (kl/div);
               clrtbl[j].rgbBlue   = (BYTE) (kl/div);
               }

           }
           break;

       case TAG_ColorMap :
           {
           int iColors, j;
           int div=1;
           WORD        maxcolor=0;
           static WORD k2l;      // color value from 0 to 65535

           // load the color table
           iColors = 1 << image->bitsPerSample;

           Importn=fseek(Infile, (long)ifd->offset, 0 );

           for ( j=0;j<iColors;j++)        // figure out the color range
               {                           // although TIFF 5.0 define
               fread(buf3,                   // read the next gray value
                     1,
                     2,
                     Infile );
               k2l=GetINTELWORD(buf3);

               maxcolor = max(maxcolor,k2l);
               }

           if (maxcolor < 256 )
               div=1;
           else
           if (maxcolor < 4096)
               div=16;
           else
               div=256;

           Importn=fseek(Infile, (long)ifd->offset, 0 );

           // load all three color curve

           for ( j=0;j<iColors;j++)
               {
               fread(buf3,                   // read the next gray value
                     1,
                     2,
                     Infile );
               k2l=GetINTELWORD(buf3);

               clrtbl[j].rgbRed = (BYTE) (k2l/div);
               }

           for ( j=0;j<iColors;j++)
               {
               fread(buf3,                   // read the next gray value
                     1,
                     2,
                     Infile );
               k2l=GetINTELWORD(buf3);

               clrtbl[j].rgbGreen = (BYTE) (k2l/div);
               }

           for ( j=0;j<iColors;j++)
               {
               fread(buf3,                   // read the next gray value
                     1,
                     2,
                     Infile );
               k2l=GetINTELWORD(buf3);

               clrtbl[j].rgbBlue = (BYTE) (k2l/div);
               }

           fColor=TRUE;
           }
           break;

       case TAG_Predictor :
           ifd->offset = ifd->offset & MaskOffset[ ifd->type ];
           predictor = ifd->offset;

           /*
           ** We dont support non-standard LZW compression
           */
/*
           if (ifd->offset!=1)
               err=HSI_EC_UNSUPPORTED;
*/
           break;

       case TAG_Group3Options:
       case TAG_Group4Options:
       case TAG_ColorResponseUnit:
       case TAG_ColorResponseCurves:
       case TAG_DocumentName:
       case TAG_PageName:
       case TAG_XPosition:
       case TAG_YPOsition:
       case TAG_PageNumber:
       case TAG_ImageDescription:
       case TAG_Make:
       case TAG_Model:

       /* obsolete tags */
       case TAG_CellWidth:
       case TAG_CellLength:
       case TAG_FreeOffsets:
       case TAG_FreeByteCounts:
       case TAG_Thresholding: /* NO LONGER USED */
       case TAG_FillOrder:    /* NO LONGER USED */
       case TAG_Orientation: /* NO LONGER USED */
       case TAG_MinSampleValue:
       case TAG_MaxSampleValue:
           break;

       default:
           break;
       }


   return err;
   }




/*
   Decompress one chunk full of LZW data to memory.
*/

LzwDecompress(DWORD bytecount, WORD height )
   {
   LPSTR       lpCodesBuf=NULL;
   DCLPTREENODE  lpTreeNode=NULL;
   LPSTR       lpGMem = NULL,lpstr=NULL;
   int         err = 0;
   DWORD       totalbyte=(DWORD)ImportWidthBytes * height;

   err = LzwDeOpen((DWORD)totalbyte,
                   &lpTreeNode,
                   &lpCodesBuf);

   if ( err ) goto cu0;

   // since one cannot allocate more than 64K contiguous bytes in GEOS,
   // one cannot use the current algorithm for large compressed files

   if (bytecount > 0xe000L) {
       err = HSI_EC_FAIL;
       goto cu0;
   }

   // allocate memory for compressed data chunk

   lpGMem = _fmalloc(bytecount);

   if (!lpGMem)
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   lfread (lpGMem,
           1,
           (DWORD)bytecount,
           Infile );

   lpstr = _fmalloc(totalbyte);    // memory to hold decompressed data

   if (!lpstr)
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // call the decompression routine to decompress the chunk of data

   err = LzwDeChunk(lpGMem,
                    (DWORD)bytecount,
                    lpCodesBuf,
                    lpTreeNode,
                    (DWORD)totalbyte,
                    lpstr );

   if ( err ) goto cu0;

   // write the uncompressed data to file. Take care of the word boundary
   // problem if any.

   if ( ImportWidthBytes == nWidthBytes )
       {
       Importl=lfwrite( lpstr,
                  1,
                  totalbyte,
                  Outfile );

       if (ImportszOption && ImportszOption->Disp)
           {
           static int cline3;
           int        i;

           i = (int)((DWORD) ImportCurrline++ *
                     (DWORD) (ImportszOption->end-ImportszOption->start) /
                     (DWORD) bmihdr.biHeight) +
                     ImportszOption->start;

           if (i!=cline3)
               {
               cline3 = i;
               err=(*(ImportszOption->Disp))(cline3);
               if (err) goto cu0;
               }
           }

       if (Importl <= 0L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }
   else
       {
       int i, offset = nWidthBytes - ImportWidthBytes;

       for (i=0;i!= (int)height;i++)
           {
           Importl=lfwrite(lpstr+i*ImportWidthBytes,
                     1,
                     ImportWidthBytes,
                     Outfile );

           if (Importl <= 0L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

           Importl=lfwrite(filler,
                     1,
                     (DWORD)offset,
                     Outfile );

           if (Importl <= 0L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

           if (ImportszOption && ImportszOption->Disp)
               {
               static int cline4;
               int        i;

               i = (int)((DWORD) ImportCurrline++ *
                         (DWORD) (ImportszOption->end-ImportszOption->start) /
                         (DWORD)bmihdr.biHeight) +
                         ImportszOption->start;

               if (i!=cline4)
                   {
                   cline4 = i;
                   err=(*(ImportszOption->Disp))(cline4);
                   if (err) goto cu0;
                   }
               }
           }
       }

   cu0 :

   // free buffer allocated for LZW if necessary

   LzwDeClose(lpTreeNode,lpCodesBuf);

   if (lpGMem)
       _ffree(lpGMem);

   if (lpstr)
       _ffree(lpstr);

   return err;
   }


// Decompress one chunk full of LZW data

int LzwDeCompStrip(
   LPSTR     lpstr,            // buffer to hold uncompressed data
   DWORD     bytecount,        // number of bytes in the compressed strip
   /*WORD      num_x_bytes,*/
   WORD      height
   )
   {
   static DCLPTREENODE   lpTreeNode;
   static LPSTR        lpCodesBuf;
   LPSTR        lpGMem=NULL;
   int          err = 0;
   long  nRead;
   DWORD        totalbyte = (DWORD)nWidthBytes * height;

   // initialize LZW decompression table

   err = LzwDeOpen( (DWORD)totalbyte,
                    &lpTreeNode,
                    &lpCodesBuf );
   if ( err ) goto cu0;

   // allocate memory for compressed data chunk

   lpGMem = _fmalloc(bytecount);

   if ( !lpGMem )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // read the compressed strip into memory

   nRead = lfread(lpGMem,1,bytecount,Infile);

   if ( nRead <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   // call the decompression routine to decompress the chunk of data

   err = LzwDeChunk(lpGMem,             // compressed data
                    (DWORD)nRead,
                    lpCodesBuf,
                    lpTreeNode,
                    (DWORD)totalbyte,
                    lpstr );            // decompressed data

   if ( err ) goto cu0;

   cu0:

   // free buffer allocated for LZW if necessary

   LzwDeClose( lpTreeNode, lpCodesBuf );

   if (lpGMem)
       _ffree(lpGMem);

   return err;
   }


/*
   Write out color palette quadruple depending upon the current
   setting.
*/

HSI_ERROR_CODE
WriteColor( int bmImageType )
   {
   int i;
   short err=0;

   static char buf4[1024];

   // write out color palette for color images

   if ( bmihdr.biBitCount == 1 )    // monochrome bitmap has two entries
       {                            // in the color table

       if (image->photoMetric==0 && // CCITT compressed image is already
           image->compression!=2 && // inverted
           image->compression!=3 )
           {
           clrtbl[0].rgbBlue     = 0xFF;   // photometric == zero
           clrtbl[0].rgbGreen    = 0xFF;   // zero is treated as WHITE
           clrtbl[0].rgbRed      = 0xFF;
           clrtbl[0].rgbReserved = 0x00;

           clrtbl[1].rgbBlue     = 0x00;
           clrtbl[1].rgbGreen    = 0x00;
           clrtbl[1].rgbRed      = 0x00;
           clrtbl[1].rgbReserved = 0x00;
           }
       else
           {
           clrtbl[0].rgbBlue     = 0x00;   // photometric non-zero
           clrtbl[0].rgbGreen    = 0x00;   // zero is treated as black
           clrtbl[0].rgbRed      = 0x00;
           clrtbl[0].rgbReserved = 0x00;

           clrtbl[1].rgbBlue     = 0xFF;
           clrtbl[1].rgbGreen    = 0xFF;
           clrtbl[1].rgbRed      = 0xFF;
           clrtbl[1].rgbReserved = 0x00;
           }

       copyclrtbl2buf(clrtbl,buf4,2);
       Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 2, Outfile);
       if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       goto cu0;
       }

   if ( bmihdr.biBitCount == 4 )
       {
       if ( fColor )     // color or gray loaded already
           {
           copyclrtbl2buf(clrtbl,buf4,16);
           Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 16, Outfile);
           if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           goto cu0;
           }

       if ( bmImageType == 1 )  // grayscale image
           {
           for (i=0;i<16;i++)
               {
               if ( image->photoMetric == 1)
                   {
                   clrtbl[i].rgbRed   = (BYTE)((i+1)*(i+1)-1);
                   clrtbl[i].rgbGreen = (BYTE)((i+1)*(i+1)-1);
                   clrtbl[i].rgbBlue  = (BYTE)((i+1)*(i+1)-1);
                   }
               else
                   {
                   clrtbl[i].rgbRed   = (BYTE)(255-((i+1)*(i+1)-1));
                   clrtbl[i].rgbGreen = (BYTE)(255-((i+1)*(i+1)-1));
                   clrtbl[i].rgbBlue  = (BYTE)(255-((i+1)*(i+1)-1));
                   }
               }

           copyclrtbl2buf(clrtbl,buf4,16);
           Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 16, Outfile);
           if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }
       else
          // color image use the default palette
          copyclrtbl2buf(clrtbl16,buf4,16);
          Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 16, Outfile);
          if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       goto cu0;
       }

   // take care of 256 color.

   if ( bmihdr.biBitCount == 8 )
       {
       if ( fColor )        // color or gray loaded already
           {
           copyclrtbl2buf(clrtbl,buf4,256);
           Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 256, Outfile);
           if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           goto cu0;
           }

       if ( bmImageType == 1 )     // grayscale image
           {
           for (i=0;i<256;i++)
               {
               if ( image->photoMetric == 1)
                   {
                   clrtbl[i].rgbRed   = (BYTE)i;
                   clrtbl[i].rgbGreen = (BYTE)i;
                   clrtbl[i].rgbBlue  = (BYTE)i;
                   }
               else
                   {
                   clrtbl[i].rgbRed   = (BYTE)(255-i);
                   clrtbl[i].rgbGreen = (BYTE)(255-i);
                   clrtbl[i].rgbBlue  = (BYTE)(255-i);
                   }
               }

           copyclrtbl2buf(clrtbl,buf4,256);
           Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 256, Outfile);
           if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }
       else
           {
           // TIFF file does not contain color table nor grayscale
           // response curve (should not be the case!). Although
           // this should not happen, but some TIFF writer does
           // have such behavior and we have to handle this problem.

           copyclrtbl2buf(clrtbl256,buf4,256);
           Importn=fwrite(buf4, 1, SIZEOFRGBQUAD * 256, Outfile);
           if (Importn <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }
       }

   cu0:

   return err;
   }


/*
   Swap the Red and Blue in each RGB sample.
*/

void swaprgb(LPSTR s,WORD n)
   {
   BYTE c;
   int  i = n/3;

   while (i--)
       {
       c = *s;     /* Red      */
       *s= *(s+2); /* Copy blue to Red */
       *(s+2) =c;  /* Copy red to blue */
       s+=3;
       }
   }





