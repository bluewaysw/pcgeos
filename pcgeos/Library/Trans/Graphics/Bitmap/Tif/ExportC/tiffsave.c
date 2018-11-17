/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		tiffsave.c

AUTHOR:		Maryann Simmons, Feb 13, 1992

METHODS:

Name			Description
----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	2/13/92   	Initial version.

DESCRIPTION:
	

	$Id: tiffsave.c,v 1.1 97/04/07 11:27:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/************************************************************************

       ----- Copyright(c), 1990-91  Halcyon Software -----


   tifsave.c

Description

   Convert DIB to TIFF format. 

HISTORY    

   02/16/89 Created
   05/04/90 Ported to Windows 3.0 DIB

*************************************************************************/
#pragma Comment("@" __FILE__);

#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "hsidib.h"    /*global variables*/
#include <Ansi/stdlib.h>
#include <Ansi/string.h>

/*
#include <sys/types.h>
*/
#include <math.h>




#include "tif.h"
#include "packbit.h"
#include "lzwc.h"
#include "tiffopt.h"       /*tiff options, t:\include\tiffopt.h*/

#define TIFFSTRIPSIZE    10240  /*recommended stipe size before compression*/

/*function prototypes*/

void   Flip24BitRGB(LPSTR buf,WORD nWidthBytes);;

#ifndef TATE
HSI_ERROR_CODE EXPORT HSISaveTIF(FILE *,FILE *,LPCNVOPTION);
#else
HSI_ERROR_CODE EXPORT HSIExportFilter(LPSTR,LPSTR,LPCNVOPTION);
#endif

long XResolution=300L, YResolution=300L, One=1L;

int  UpdateStripByteCount      ( DWORD, long, int );
int  WriteIFD                  (VOID);
void fixifd                    ( IFD * );
int  WriteOffsets              (VOID);
int  WriteImage                (VOID);
int  WriteLzwImage             (VOID);
int  ParseIFDs                 (VOID);

HSI_ERROR_CODE  WriteNextScanLine ( LPSTR, WORD );     
HSI_ERROR_CODE  ReadNextScanLine  ( LPSTR, LPSTR,/* WORD,*/ WORD *);
HSI_ERROR_CODE  ReadOneStrip      ( LPSTR, WORD );
HSI_ERROR_CODE  WriteOneStrip  (LPSTR, WORD );

/* value for TIFF options */

short   fCompression=TIFF_NOCOMP;
short   fFormat=TIFF_INTEL;

BOOL    fTifCat=FALSE, fTifInvert=TRUE;

IFD     ifd;

/* grayscale response curve for 4-bit grey */ 

WORD    greyresponse[16] =
    {
    2000, 1177, 875, 699, 
    574, 477, 398, 331, 
    273, 222, 176, 135, 
    97, 62, 30, 0
   };

/* long variables to store tag offsets for StripByteCount, StripByteOffset,*/

long   lTagByteCount, lTagOffset, lTagSoftware=0L, lTagGrayCurve=0L;
long   lTagXResolution, lTagYResolution, lTagBPS=0L, lTagColorMap=0L;
BYTE   resUnit=0;
WORD   rowsperstrip, numofstrip;
BYTE   bmImageType;
WORD   widthBytes;         /*input string buffer width*/
int    IFDCOUNT[] = { 18, 20, 22 };
DWORD  IFDoffset;

struct ifd1 
   {
   WORD tag;
   WORD type;           /* see defines below            */
   } ifdtable[] = {
    { 0xff,     3 },   /* subfile type*/
    { 0x100,    3 },   /* image width*/
    { 0x101,    3 },   /* image height*/
    { 0x102,    3 },   /* bitspersample*/
    { 0x103,    3 },   /* compression*/
    { 0x106,    3 },   /* photometriinterpretation*/
    { 0x107,    3 },   /* thresholding*/
    { 0x10a,    3 },   /* fill order*/
    { 0x111,    4 },   /* stripoffset */
    { 0x112,    3 },   /* orientation*/
    { 0x115,    3 },   /* samples per pixel*/
    { 0x116,    4 },   /* rows per strip*/
    { 0x117,    4 },   /* stripbytecount */
    { 0x118,    IFD_SHORT },       /* min sample value*/
    { 0x119,    IFD_SHORT },       /* max sample value*/
    { 0x11a,    IFD_RATIONAL },    /* x resolution*/
    { 0x11b,    IFD_RATIONAL },    /* y resolution*/
    { 0x11c,    IFD_SHORT },       /* planar configuration*/
    { 0x122,    IFD_SHORT },       /* TAG_GrayResponseUnit */
    { 0x123,    IFD_SHORT },       /* TAG_GrayResponseCurve*/
    { 0x128,    IFD_SHORT },       /* resolution unit*/
    { 0x131,    2 },   /* TAG_Software*/
    { 0x140,    IFD_SHORT },       /* ColorMap*/
    { 0x00,     0 }
};

/*short    planeConfig=1;    non-interleaved color planes*/ 
char   str[80];
int    n;
long   l;


/************************************************************************

FUNCTION    HSISaveTIF    ( szInfile, szOutfile, LPCNVOPTION szOption )

PURPOSE        Save tempory file to TIFF format. 

PARAMETER 
   LPSTR   szInfile        Input file name
   LPSTR   szOutfile       Output file name
   LPCNVOPTION         (see tiffopt.h for more information)
   DWORD   dwOption
                 {
                 0-2     compression;  0 TIFF_NOCOMP
                                       1 TIFF_PACKBIT
                                       2 TIFF_LZW
                                       3 TIFF_CCITT
                                       4 auto detection

                 3-4     format;       0 TIFF_INTEL
                                       1 TIFF_MOTOR

                 5       invert;       TRUE, FALSE

                 7,8     res. unit    0: use default
                                      1: device unit
                                      2: inch
                                      3: centimeter

                 BYTE    type;         0 Class B, bilevel/mono
                                       1 Class G, grayscale
                                       2 Class R, RGB color
                                       3 Class P, palette
                 }

HISTORY    

   02/16/89   Created
   05/05/90   Ported to Windows 3.0. Don Hsi
   08/02/90   Use DWORD as option. Set the option bits. Added TIFFOPT.H
              in t:\include directory.
   08/03/90    Process compression type 5; auto selection. color DIB use
               LZW, mono use Packbit

   01/24/90   Make sure LZW is not used by monochrome image

*************************************************************************/

LPCNVOPTION szOption;
WORD        currline;

HSI_ERROR_CODE EXPORT
HSISaveTIF( FILE * szInfile, FILE * szOutfile, LPCNVOPTION szOpt )
   {
   short       err = 0;
/*   HANDLE      hInst;
   WORD        n;*/
   DWORD       dwOption;
  /* static char str[80];*/

   szOption = szOpt;
   currline = 0;

   if (szOption)
       dwOption = (DWORD)szOption->dwOption;
   else
       dwOption = 0x00;    // default to no compression, INTEL format

   /* cannot use OpenInOutFile() call, since we need to read the
   output file as well*/
/*
   _fstrcpy( (LPSTR)str, szInfile );
*/
   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;
   /*
   if ( !Infile )
       {
       err = HSI_EC_SRCCANTOPEN;
       goto cu0;
       }

   _fstrcpy( (LPSTR)str, szOutfile );
    
   if ( !Outfile )
       {
       err = HSI_EC_DSTCANTOPEN; 
       goto cu0;
       }
   */
   err = ReadHeaderInfo(Infile);

   if ( err ) goto cu0;
           

   /* decide the option */ 

   if ( dwOption & 0x0004 )   /* auto detection for compression */
       {
       if (bmihdr.biBitCount == 1 )
           fCompression = 1;   /* packbit */
       else
           fCompression = 2;   /* LZW */
       }
   else
       {
       fCompression = (WORD)(0x0007 & dwOption);           // 0-2 bits

       if (bmihdr.biBitCount==1 && fCompression==2)    // monochrome cannot
           fCompression = 1;                           // use LZW
       }

   fFormat      = (WORD)((0x0018 & dwOption) > 3);     // 3-4 bits
   fTifInvert   = (WORD)((0x0020 & dwOption) > 5);     // 5 bit
   resUnit      = (WORD)((0x00C0 & dwOption) > 7);     // 7,8 bits

   if ( nColors > 2 && IsGray(nColors,clrtbl))
       bmImageType = 3;
   else
       bmImageType  = 3;       // palette color

   // Does not support CCITT with color or gray image

   if ( fCompression == TIFF_CCITT && bmihdr.biBitCount != 1 )
       {
       err = HSI_EC_INVALIDOPTION;
       goto cu0;
       }

   /* decide rows per strip based upon image size */ 

   widthBytes = (bmihdr.biWidth*bmihdr.biBitCount+7) / 8;

   // keep each stripe under 8K of uncompressed data. 

   rowsperstrip = (WORD) (TIFFSTRIPSIZE/widthBytes) < bmihdr.biHeight ?
                  (TIFFSTRIPSIZE/widthBytes) : bmihdr.biHeight;

   // calculate number of stripes there are in the image 
   numofstrip = bmihdr.biHeight / rowsperstrip  +
                ((bmihdr.biHeight%rowsperstrip) == 0 ? 0 : 1) ;

   // Write all directory entries within the IFD. (Need to take care of 
   // multiple IFDs later).
   
   err = WriteIFD();
   if ( err )    goto cu0;

    
   // Write out extra values if any. StripByteCount, StripOffset, Gray
   // response curve, etc.
   
   err = WriteOffsets();
   if ( err )    goto cu0;

   // Write out image data, with appropriate compression method.
   // if the image is mono, then use either CCITT or PACKBIT. If
   // image is color(palette,RGB) or gray, use LZW
   
   if ( fCompression == TIFF_LZW )
       err = WriteLzwImage();
   else
       err = WriteImage();
                             
   cu0:
/*
   CloseInOutFile();
*/
   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(100);

   return err;
   }


/*
 * Write out all directory entries within the IFD.
 */

int        WriteIFD(void)
   {
   static TifHeader   hdrs;
   long        coffset, lTagCount;
   WORD        i;
/*   DWORD       toffset = 0L, toffset1=0L;*/
   static DWORD       zero=0L;
/*   int         nResult;*/
   static short       tagcount;
   short   err;

   tagcount=0;

   /* prepare TIF Header information */ 

   if ( fFormat == TIFF_INTEL )
       {
       brainDamage = TRUE;
       hdrs.byteOrder   = 0x4949; /* INTEL format */

       XResolution = 300L;
       YResolution = 300L;
       }
   else
       {
       brainDamage = FALSE;
       hdrs.byteOrder    = 0x4D4D; /* Motorola format */

       XResolution = 72L;  /* set to mac default dpi */
       YResolution = 72L;
       }

   hdrs.tiffVersion = 0x2a;   /* version number */
   hdrs.tiffVersion = fixshort( hdrs.tiffVersion );

   hdrs.ifdOffset   = 8L;     /* Offset for 1st IFD */
   hdrs.ifdOffset   = fixlong ((DWORD)hdrs.ifdOffset);

   // write the header bytes out 

   n=fwrite (  &hdrs, 
             1,
             sizeof(TifHeader),
             Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // save IFD count location and update it later 

   lTagCount = ftell( Outfile );
   n=fseek ( Outfile, 0L, SEEK_CUR );

   // write out the IFDCOUNT as the first entry in IFD 

   n=fwrite(  &tagcount, 
            sizeof(WORD),
            1,
            Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   /* write one directory at a time with this IFD */

   for ( i=0; ifdtable[i].tag ; i++)
       {
       ifd.tag  = ifdtable[ i ].tag;
       ifd.type = ifdtable[ i ].type;
       ifd.count = 1L;

       err = ParseIFDs();

       if ( err == -1 )    /* skip this entry */
           continue;

       if ( err ) /*****goto *****/  
	 {
	   fixifd( (IFD *)&ifd ) ;
	   return err;
	 }

       n= fwrite( &ifd, 
                  1,
                  sizeof(IFD)-sizeof(ifd.next),
                  Outfile);

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       /* increment TAG count */
       tagcount++;
       }

   err = 0;

   // put 0L in the next IFD field */

   n = fwrite ( &zero, 
                 1, 
                 sizeof(DWORD),
                 Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           
   coffset = ftell ( Outfile );    // save current offset location 

   n=fseek ( Outfile,              // update the number of TAG for the IFD 
           lTagCount, 
           0 );

   tagcount = fixshort( tagcount );

   n=fwrite( &tagcount, 
           1,
           sizeof(WORD),
           Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   n=fseek ( Outfile,              // restore current offset location 
           coffset, 
           0 );

   cu0:

   return err;
   }




int ParseIFDs(void)
   {
/*   int     i;
   char    str[80];
*/
   switch ( ifd.tag ) 
       {
       case TAG_NewSubfileType:
       /* ??? */
           /* decide whether there is a need to create catalog, mask, etc. */
           ifd.offset = (DWORD) 0;
           break;

       case TAG_ImageWidth:       /* image width */
           // normalize the image witdth 
//           {
//           int i= (bmihdr.biWidth+7)/8;
//           int j= (bmihdr.biWidth+15)/16*2;
//
//           if ( j > i )
//               bmihdr.biWidth += j * 8 - 8 - bmihdr.biWidth + 1;
//           }

           ifd.offset = (DWORD) bmihdr.biWidth;
           break;

       case TAG_ImageLength:      /* Image height */
           ifd.offset = (DWORD) bmihdr.biHeight;
           break;

       case TAG_Compression:
           /* decide which compression was selected */
           switch ( fCompression )
               {
               case TIFF_NOCOMP :
                   ifd.offset  = 1L;   /* no compression */
                   break;

               case TIFF_LZW :
                   ifd.offset = 5L;    /* LZW compression */
                   break;

               case TIFF_PACKBIT :
                   ifd.offset = 32773L;
                   break;

               case TIFF_CCITT :
                   ifd.offset = 2L;
                   break;
               }
           break;
    
       case TAG_BitsPerSample:
           // if samplesperplane is more than one, then write out equal 
           // number of samples
           ifd.offset = (DWORD) bmihdr.biBitCount;
           lTagBPS = ftell ( Outfile );
           break;
    
       case TAG_SamplesPerPixel:
           if ( bmihdr.biBitCount == 24 )
              {
              ifd.offset = 3;      // RGB full color
              bmImageType = 2;     // rgb full color
              }
           else
              ifd.offset = 1;

           break;

       case TAG_RowsPerStrip:
           ifd.offset = (DWORD)rowsperstrip;
           break;
        
       case TAG_StripByteCounts:
           /* save current file offset for update later on */
           lTagByteCount = ftell ( Outfile );

           /* for now, write the dummy data out so that the tag can take up
           * the position in the file. If there is only 1 stripe for the
           * image, then use the correct value.
           */
           ifd.offset = (DWORD) (bmihdr.biWidth * bmihdr.biBitCount + 7 ) / 8
                                   * bmihdr.biHeight;

           /*
           * Delay write for the bytes per stripe, since the bytes might be
           * compressed.
           */
        
           break;
    
       case TAG_StripOffsets  :
           /* save current file offset for update later on */
           lTagOffset    = ftell ( Outfile );

           /* delay write of strip offsets until later. */
           break;

       case TAG_XResolution:
           lTagXResolution= ftell ( Outfile );

           break;
    
       case TAG_YResolution:
           lTagYResolution= ftell ( Outfile );

           break;

       case TAG_GrayResponseUnit:

  //         if ( bmihdr.biBitCount == 1 )
              return -1;

           /* Unit measure - 1: 1/10, 2: 1/100 (default),
           *                3: 1/1000(recommended)
           *                4: ten-thousandths, 5: hundred-thousandths
           
           ifd.offset  = 3L;     1/1000 unit */

       case TAG_GrayResponseCurve:
//           if ( bmihdr.biBitCount == 1 )
               return -1;

           /* save current file offset 
           lTagGrayCurve = ftell ( Outfile );

            number of values 
           ifd.count   = (long) 1 << bmihdr.biBitCount;*/


       case TAG_PhotometricInterpretation:

           // 24 bit RGB always has 2

           if ( bmihdr.biBitCount == 24 ||
                bmihdr.biBitCount == 0 )
               {
               ifd.offset = 2L;
               bmImageType = 2;    // rgb color
               break;
               }

           /* mono image */

           if ( bmihdr.biBitCount == 1 )
               {
               bmImageType = 0;    // mono

               if ( fTifInvert )
                   ifd.offset = 0L; /* inversed image */
               else
                   ifd.offset = 1L;
               }
           else
               {
               if ( bmImageType == 1 )
                   ifd.offset = 1L;    // gray image
               else
                   {
                   ifd.offset = 3L; /* palette color image */
                   bmImageType = 3;    /* palette color */
                   }
               }

           break;

       case TAG_Software : /* name of the software that create this image */
           /* save current file offset */
           lTagSoftware = ftell ( Outfile );
           break;
        
       case TAG_PlanarConfiguration:
           /* no need for this flag for mono nor
            palette color image */

           if ( bmihdr.biBitCount == 24 )
               ifd.offset = 1;
           else
               return -1;

           break;

       case TAG_ResolutionUnit:

           /* Set the resolution unit only if not specified by the caller */
           /* 1 for pixel, 2: inch, 3: centimeter */

           if (!resUnit)
               {
               if (bmihdr.biXPelsPerMeter != 0 ||
                   bmihdr.biYPelsPerMeter != 0)
                   ifd.offset = 3L;        // centimeter
               else
                   ifd.offset = 1L;        // device unit

               resUnit = ifd.offset;
               }

           break;

       case TAG_ColorMap :

           // no color map for non-palette image.  We use color map for
           // Grayscale image at this time, since the grayscale response
           // curve is not a popular tag for other TIFF reader.

           if ( bmImageType != 3 )
               return -1;

           lTagColorMap = ftell ( Outfile );

           break;

       case TAG_Group3Options:
       case TAG_Group4Options:
       case TAG_DocumentName:
       case TAG_PageName:
       case TAG_XPosition:
       case TAG_YPOsition:
       case TAG_PageNumber:
       case TAG_ImageDescription:
       case TAG_Make:
       case TAG_Model:

       /* obsolete tags */
       case TAG_FreeOffsets:
       case TAG_FreeByteCounts:
       case TAG_Thresholding:
       case TAG_Orientation:
       case TAG_FillOrder:
       case TAG_CellWidth:
       case TAG_CellLength:
       default : /* do not add this unsupported tag */
           return -1;       

       }
   return 0;
   }


/* 
 * Write out extra offset values if any. Which could include StripByteCount,
 * StripOffset, Grayscale response curve, Color map, etc.
 */

int        WriteOffsets(void)
   {
   static short    i, k;
   short    err = 0;
/*   WORD     nRead, nWrite; */
   static IFD      ifd;
   long     coffset;
   long     offset1, offset2; 
   static long     val;

   val = 0;
   i=k=0;

   n=fseek ( Outfile, 0L, 2 );           // make sure we are at EOF

   // Write out grayscale response curve if necessary 

   if ( lTagGrayCurve != 0L )
       {
       int     level;
       static short   ks;

       coffset = ftell ( Outfile );        // save current offset

       // write out the response curve 
       level = 1 << bmihdr.biBitCount;

       for ( i=0 ; i < level ; i++ )
           {
           ks = 255-i;
           n=fwrite(  &ks,
                    sizeof(short),
                    1,
                    Outfile );

           if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }
        
       // now, it is time to update the TAG entry... 1st, seek to the tag 

       n=fseek ( Outfile, lTagGrayCurve, 0 );

       // update the tag with correct values ... 

       ifd.tag   = TAG_GrayResponseCurve;
       ifd.type  = 3;  /* short */
       ifd.count = 1 << bmihdr.biBitCount;
       ifd.offset= coffset;
       fixifd ( (IFD *)&ifd );

       n=fwrite( &ifd,                      // write out the new tag values ... 
               1,
               sizeof(IFD)-sizeof(ifd.next),
               Outfile );

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       n=fseek ( Outfile, 0L, 2 );   /* go to the end of output file */ 
       }


   /* Write strip byte count TAG. If only one strip, then store the
   // offset in the TAG itself, if more than one, then store the list
   // of to end of file */

   offset2 = ftell ( Outfile );    /* save current location */

   /* 
   * Write out dummy data to StripByteCount extra data if necessary, so that
   * we can save these data before image data area.
   */

   if ( numofstrip > 1 )
       {
       for ( i=0 ; i < numofstrip;i++)
           {
           n=fwrite(&val,
                    1,
                    sizeof(long),
                    Outfile );

           if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }
   
       }

   /* seek to StripByteCount TAG offset */

   n=fseek ( Outfile, lTagByteCount, 0 );

   // Update the offset value to the TAG 

   ifd.tag   = TAG_StripByteCounts;
   ifd.type  = 4;                     // 4 byte integer 
   ifd.count = (long)numofstrip;      // number of stripes 
   ifd.offset= (DWORD)offset2;        // offset value. If only one strip
                                      // this value is updated later
   fixifd ( (IFD *)&ifd );

   // update the TAG entry with correct info. 

   n = fwrite (   &ifd, 
                  1,
                  sizeof(IFD)-sizeof(ifd.next),
                  Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // re-seek to EOF

   n=fseek ( Outfile, 0L, 2 );


   // --------- update stripe offset TAG ---------

   // save current location
   offset1 = ftell ( Outfile );

   /* 
   * Write out dummy data to stripOffset extra data if necessary, these value
   * can be obtained only after image is written. But we have to take up the
   * space now, so that image data can be written afterward. Although it is
   * not a must to put TAG info before image, but I think it is better(?).
   */

   if ( numofstrip > 1 )
       {
       for ( i=0 ; i < numofstrip ; i++ )
           {
           n= fwrite ( &val, 
                           1,
                           sizeof(long),
                           Outfile );
           if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

           }
       }

   // seek to StripOffset TAG offset 

   n=fseek ( Outfile, lTagOffset, 0 );

   // write the offset value to the TAG 

   ifd.tag  = TAG_StripOffsets;
   ifd.type = 4;                       /* 4 byte integer */
   ifd.count = (DWORD)numofstrip;      /* number of stripes */
   ifd.offset= (DWORD)offset1;         /* 1st offset value */

   fixifd( (IFD *)&ifd );

   // update the TAG entry with correct info. 

   n = fwrite (  &ifd, 
                       1,
                       sizeof(IFD)-sizeof(ifd.next),
                       Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // go to end of file position 

   n=fseek ( Outfile, 0L, 2 );


   /* --- Add software name to the TAG_Software field */

   // first, save the current offset in output file 

   coffset = ftell ( Outfile );

   // write the name of the software(DoDOT, of course) 
   _fstrcpy( (LPSTR)str, "DoDOT" );

   n=fwrite (str, 
           1,
           strlen( str ),
           Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // go back to where the tag is... 

   n=fseek ( Outfile, lTagSoftware, 0 );

   // reassign values to the tag entry 

   ifd.tag   = TAG_Software;
   ifd.type  = 2;                  // ASCII type 
   ifd.count = _fstrlen( "DoDOT" );
   ifd.offset= coffset;
   fixifd( (IFD *)&ifd );

   // update the tag entry 

   n=fwrite (    &ifd, 
               1,
               sizeof(IFD)-sizeof(ifd.next),
               Outfile );
   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // seek to the end of output file 

   n=fseek ( Outfile, 0L, 2 );

   // ------------- write bitspersample if it is a color image -------

   if ( bmihdr.biBitCount == 24 )
       {
       static WORD j;

       j=fixshort(8);

       // save current offset 

       coffset = ftell ( Outfile );

       // write out 8,8,8

       n=fwrite ( &j, 1, sizeof(WORD), Outfile );
       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       n=fwrite ( &j, 1, sizeof(WORD), Outfile );
       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       n=fwrite ( &j, 1, sizeof(WORD), Outfile );
       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       // go to the Tag_BitsPixel TAG 

       n=fseek ( Outfile, lTagBPS, 0 );

       ifd.tag    = TAG_BitsPerSample;
       ifd.type   = 3;
       ifd.count  = 3;
       ifd.offset = coffset;

       fixifd( (IFD *)&ifd );

       n=fwrite( &ifd, 
               1,
               sizeof(IFD)-sizeof(ifd.next),
               Outfile );

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       // seek to the end of output file 

       n=fseek ( Outfile, 0L, 2 );
       }

   /* --------------- write x and y resolution -------------- */

   // xResolution and yResolution all have RATIONAL type; i.e. first
   // long is fractional, 2nd long is denominator

   // save current offset 

   coffset = ftell( Outfile );     

   // write out 4 long values 

   switch(resUnit)
       {
       case 1 :    // device unit
           XResolution = fixlong((DWORD)XResolution);
           YResolution = fixlong((DWORD)YResolution);
           break;

       case 2 :    // inch
           XResolution = fixlong((DWORD)(bmihdr.biXPelsPerMeter/254));
           YResolution = fixlong((DWORD)(bmihdr.biYPelsPerMeter/254));
           break;

       case 3 :    // per centimeter
           XResolution = fixlong((DWORD)(bmihdr.biXPelsPerMeter/100));
           YResolution = fixlong((DWORD)(bmihdr.biYPelsPerMeter/100));
           break;
       }

   One = fixlong((DWORD)One);

   n=fwrite (  &XResolution, 
               1,
               sizeof(long),
               Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   n=fwrite (  &One,
               1,
               sizeof(long),
               Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   n=fwrite (  &YResolution, 
               1,
               sizeof(long),
               Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   n=fwrite (  &One,
               1,
               sizeof(long),
               Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // goto the TAG_XResolution tag offset 

   n=fseek(Outfile,lTagXResolution, 0 );

   ifd.tag    = TAG_XResolution;
   ifd.type   = IFD_RATIONAL;
   ifd.count  = 1;
   ifd.offset = coffset;

   fixifd( (IFD *)&ifd );

   n=fwrite (  &ifd, 
               1,
               sizeof(IFD)-sizeof(ifd.next),
               Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // goto the TAG_YResolution tag offset 

   n=fseek(Outfile,lTagYResolution, 0 );

   ifd.tag    = TAG_YResolution;
   ifd.type   = IFD_RATIONAL;
   ifd.count  = 1;
   ifd.offset = coffset+8;

   fixifd( (IFD *)&ifd );

   n=fwrite (  &ifd, 
               1,
               sizeof(IFD)-sizeof(ifd.next),
               Outfile );

   if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   if ( bmImageType != 3 )     // skip color map for non-palette image
       {
       err = 0;
       goto cu0;
       }

   n=fseek ( Outfile, 0L, 2 );               // goto EOF

   coffset = ftell ( Outfile );            // save current file position

   if (bmImageType == 3)                   // save color palette for 
       {                                   // palette color image
       // goto the TAG_ColorMap tag offset 

       n=fseek ( Outfile, lTagColorMap, 0 );

       ifd.tag    = TAG_ColorMap;
       ifd.type   = 3;            // short
       ifd.count  = nColors * 3;
       ifd.offset = coffset;
       fixifd( (IFD *)&ifd );

       n=fwrite (   &ifd, 
                   1,
                   sizeof(IFD)-sizeof(ifd.next),
                   Outfile );

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       n=fseek ( Outfile, 0L, 2 );               // goto EOF

       for ( i=0; i<nColors ; i++ )
           {                           
           k = clrtbl[i].rgbRed * 256;       
           n=fwrite ( &k, sizeof(short), 1, Outfile );
           if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }

       for ( i=0; i<nColors ; i++ )
           {
           k = clrtbl[i].rgbGreen * 256;
           n=fwrite ( &k, sizeof(short), 1, Outfile );
           if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }

       for ( i=0; i<nColors ; i++ )
           {
           k = clrtbl[i].rgbBlue * 256;
           n=fwrite ( &k, sizeof(short), 1, Outfile );
           if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
           }
       }

   cu0:

   // seek to the end of file 

   n=fseek ( Outfile, 0L, 2 );

   return err;
   }


/*
 * Write tempory file data to tif format without desired compression
 * method.
 */
int WriteImage(void)
   {
   int     i,/* j,*/ k,/* l,*/ err=0;
   /*char    str[20];*/
   static WORD    widthbytes;
   LPSTR   buf, outbuf;
   WORD    wLength/*, inLength, nRead, nWrite*/;
   /*WORD    scanline=0;*/

   wLength   = nWidthBytes;

//   if ( bmihdr.biBitCount == 24 )   planeConfig = 1;

   // allocate memory for input scanline 

   buf =(LPSTR) _fmalloc(wLength+1);  /*just malloc*/

   if ( !buf )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // CCITT worst case is horiable!! e.g. interchanged b/w dots will
   // surely expand the output string, or images with many patterns

   outbuf =(LPSTR) _fmalloc((WORD)max(wLength,bmihdr.biWidth)+1);

   if ( outbuf == NULL )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // move file pointer to the end of image in input file since
   // DIB is store backward

   n=fseek ( Infile, 
           (LONG)bmfhdr.bfSize,
           0 );

   // write out one stripe at a time 

   for ( k=0;k!=numofstrip;k++)
       {
       DWORD   stripbytecount=0L;
       long    stripoffset = ftell( Outfile );
       /*long    infileoffset= ftell( Infile );*/
       /*long    coffset;  current file offset 
       long    lSeek;*/
       int     tRPS = rowsperstrip;

       if ( numofstrip > 1 && k == (numofstrip-1) )
           {
           tRPS = bmihdr.biHeight % rowsperstrip;
           if (tRPS==0)
               tRPS=rowsperstrip;
           }

       /* write out one scanline at a time */

       for ( i=0;i!=tRPS;i++)
           {

           err = ReadNextScanLine( buf, 
                                   outbuf, 
                                   /*wLength,*/ 
                                   &widthbytes
                                   /*inLength*/);

           if ( err ) goto cu0;

           err = WriteNextScanLine( outbuf, widthbytes );

           if ( err ) goto cu0;

           // update bytes per stripe 

           stripbytecount += (long)widthbytes;

           } /* end of each stripe */

       // update the TAG offset for this stripe; both StripByteCount
       // and StripOffset.
       
       UpdateStripByteCount( stripbytecount, stripoffset, k );

       }    /* end of all stripe */

   cu0:

   if (buf)
       _ffree(buf);

   if (outbuf)
       _ffree(outbuf);

   return err;
   }



HSI_ERROR_CODE    
ReadNextScanLine   ( 
   LPSTR buf, LPSTR outbuf,
   /*WORD  wLength,*/ WORD *outLength/*, WORD inLength*/)
   {
   /*WORD    nRead;*/
   HSI_ERROR_CODE      err=0;

   // rewind one row backward

   n=fseek ( Infile, -1L * (long)nWidthBytes, 1 );

   // read one scanline from input file 

  lfread ( buf, 1,(long)nWidthBytes,Infile );
        
   n=fseek ( Infile, -1L * (long)nWidthBytes, 1 );

   /* 24 bit DIB has the color reversed, normalize it */

   if (bmihdr.biBitCount==24)
      Flip24BitRGB(buf,nWidthBytes);

   if (szOption && szOption->Disp)       
       {
       static int cline;
       int        i;

       i=  (int)((long)currline++ * 100L / (long)bmihdr.biHeight);

       if (i!=cline)
           {
           cline = i;
           err=(*(szOption->Disp))(cline);
           if (err) goto cu0;
           }
       }

   /* RGB color is written with contiguous color bytes, i.e. RGBRGB... 
   * Rearrange the input buffer, so that each sample contains three color
   * values.
   */

/* -------------------------------------
   if ( planeConfig == 2 )
       {
       // I don't think anyone would be so fuck up to use this 
       // option. Although that sample file that we got from microtech
       // does generate this type of file!

       }
  -------------------------------------- */

   // compress the line if necessary 

   switch ( fCompression )
       {
       WORD    bitwidth;
       extern int cpt4( LPSTR, LPSTR, WORD );

       case TIFF_PACKBIT : // packbit 

           *outLength = BigPackBits ( 
                          buf,             // input string 
                          outbuf,          // compressed(output) string 
                          widthBytes );   // bytes to compress 

           if ( *outLength <= 0 )
               {
               err =  HSI_EC_UNSUPPORTED;  // strange error
               goto cu0;
               }
           break;

       case TIFF_CCITT : // t.4 compression 
           // make sure to clean up the output buffer first

           _fmemset(outbuf,zero,(WORD)bmihdr.biWidth);

	        bitwidth = cpt4( outbuf, buf,(WORD)bmihdr.biWidth );

           *outLength = (bitwidth+7)/8;

           break;
   
       default :
           *outLength = widthBytes;
           _fmemcpy ( outbuf, buf, nWidthBytes );
           break;
       }

   cu0:
   return err;
   }



HSI_ERROR_CODE  
WriteNextScanLine( LPSTR outbuf, WORD outLength )
   {        
   short   err = 0;

   // write out 1 scanline 

   l = lfwrite( outbuf, 
               1,
               (DWORD)outLength,
               Outfile);

   if (l <= 0L ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   cu0:

   return err;
   }



/*
   Save image with LZW compression. This is applicable only for
   COLOR and GRAY images.
*/
int WriteLzwImage(void)
   {
   short           err=0, i;
   DWORD           dwInCount;      /* byte count for each uncompressed strip */
   DWORD           dwInCnt;
   static DWORD    dwOutCount;     /* compressed byte count for each strip */
   LPSTR           lpGMem=NULL;
   static PLZWSTRUCT pLzw;      /* used for LZW compression */
   long            offset;
   
 

   dwInCount = (DWORD)nWidthBytes * rowsperstrip;

   // we need to allocate enough buffer to hold the DIB image with
   // normalized nWidthBytes. The performance will be louzy,
   // if we read each scanline wWidthBytes and fseek backward.
 
   lpGMem = _fmalloc((WORD)dwInCount);

   if ( !lpGMem )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // open LZW buffer 

   err = LzwCmOpen((PLZWSTRUCT *)&pLzw, 
                   (DWORD)dwInCount);

   if ( err ) goto cu0;

   n=fseek ( Infile, 
             (long)bmfhdr.bfSize,
             0 );        // seek to end of input DIB file

   if (n != 0 ) { err=HSI_EC_SRCCANTSEEK; goto cu0; }

   n=fseek ( Infile, 
             -1L * (long)nWidthBytes, 
             1 );

   // compress one strip at a time 

   for (i=0;i!=numofstrip;i++)
       {
       /*char str[40];*/
       WORD height=rowsperstrip;  // rowsperstrip 

       // take care of last strip rowsperstrip value 

       if ( numofstrip > 1 && i == (numofstrip-1) )
           {
           height = bmihdr.biHeight % rowsperstrip;

           if (height==0)
               height=rowsperstrip;
           }

       dwInCount = (DWORD)nWidthBytes * height;
       dwInCnt   = (DWORD)wWidthBytes * height;

       // read one strip of data from tmp file 
       
       err = ReadOneStrip( lpGMem, height );
       
       if ( err ) goto cu0;

       // compress this strip of data 

       err = LzwCmStrip ( pLzw, 
                         (DWORD)dwInCnt, 
                          (LPBYTE)lpGMem, 
                          (DWORD *)&dwOutCount);

       if ( err ) goto cu0;

       // save current file location in output file 

       offset = ftell( Outfile );

       // write out the strip to output file 

       err = WriteOneStrip(pLzw->lpOutStripBuf, 
                           (WORD)dwOutCount );

       if ( err ) goto cu0;

       // update stripoffset and stripbytecount tags 

       err = UpdateStripByteCount( dwOutCount, offset, i );

       if ( err ) goto cu0;

       }

   // take care of buffer allocated for LZW 

   LzwCmClose(pLzw);

   cu0:

   if (lpGMem)
       _ffree(lpGMem);
   return err;
   }



/*
  Read one strip of uncompressed data from file to strip buffer.
  Please note the strip buffer is NOT in the correct orientation,
  scanline will be written out 'backward' later!
 */
HSI_ERROR_CODE 
ReadOneStrip ( LPSTR lpGMem, WORD height )
   {
   short   err = 0/*,n*/;
   short   i/*, j*/;

   // read the whole strip one scanline at a time
/*

   fseek( Infile,              // go to the right location before read
          -1L * (LONG)(height-1)*(LONG)nWidthBytes,
          1 );

   n=lfread ( lpGMem,             // read the whole strip
             1,
             nWidthBytes * height,
             Infile );

   if ( n <= 0)
       {
       err=HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   fseek( Infile,              // rewind properly
          -1L * (LONG)(height+1)*(LONG)nWidthBytes,
          1 );

*/

   for ( i=0; i < height ; i++ )
       {
       l=lfread( lpGMem, 
                 1,
                 (DWORD)nWidthBytes,
                 Infile );

       if (l <= 0L) { err=HSI_EC_SRCCANTREAD; goto cu0; }
        
       fseek ( Infile, 
                 -2L * (long)nWidthBytes, 
                 1 );

       // update buffer pointer. Note that we increment only with
       // wWidthBytes, NOT nWidthBytes

       lpGMem += wWidthBytes;     

       if (szOption && szOption->Disp)       
           {
           static int cline2;
           int        i;

           i=  (int)((long)currline++ * 100L / (long)bmihdr.biHeight);

           if (i!=cline2)
               {
               cline2 = i;
               err=(*(szOption->Disp))(cline2);
               if (err) goto cu0;
               }
           }

       }

   cu0:

   return err;
   }


/* 
 * Save the strip of compressed data to file.
 */
HSI_ERROR_CODE
WriteOneStrip ( LPSTR lpGMem, WORD totalbytes )
   {
   short     err=0;

   // write the strip to output file 

   l=lfwrite ( lpGMem, 
               1,
               (DWORD)totalbytes,
               Outfile );

   if (l <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
   
   cu0:

   return err;
   }




/* 
   Update StripByteCount tag with the nth value and bytecount 
*/

int UpdateStripByteCount( DWORD bytecount, long offset, int k )
   {
   short   err = 0;
   static IFD     ifd2;
   WORD    nRead/*, nWrite*/;
   long    coffset = ftell (Outfile ); // save current position 

   /* ------- update TAG_StripByteCount ------------ */

   // seek to stripbytecount tag */

   n=fseek ( Outfile, lTagByteCount, 0 );

   // read the TAG for stripByteCount TAG 

   nRead = fread ( &ifd2, 
                   1,
                   sizeof(IFD) - sizeof(ifd2.next),
                   Outfile );

   if ( nRead <= 0 )
       {
       err = HSI_EC_UNKNOWNFAILURE;
       goto cu0;
       }

   if ( numofstrip == 1 )
       {
       // write the total bytes if there is only one stripe 

       ifd2.offset = fixlong((DWORD)bytecount);

       n=fseek ( Outfile, lTagByteCount, 0 );

       n=fwrite( &ifd2, 
               1,
               sizeof(IFD)-sizeof(ifd2.next),
               Outfile);

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }
   else
       {
       // update the bytecount at the appropriate location 
       int i;
       static DWORD dwbytecount;

       dwbytecount=fixlong((DWORD)bytecount);

       // seek to the stripe offset 

       n=fseek ( Outfile, fixlong((DWORD)ifd2.offset), 0 );

       // go the nth value */

       for ( i=0 ; i < k ; i++ )
           fseek ( Outfile, (long)sizeof(long), FILE_POS_RELATIVE );

       // update the byte count at that location     
       n=fwrite (    &dwbytecount, 
                   1,
                   sizeof(long),
                   Outfile );

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }

   /* ------- update TAG_StripOffset ------------ */

   n=fseek ( Outfile, lTagOffset, 0 );

   // read the TAG for stripOffset TAG 

   nRead = fread (    &ifd2, 
                       1,
                       sizeof(IFD) - sizeof(ifd2.next),
                       Outfile );

   /* write the total bytes if there is only one stripe */
   if ( numofstrip == 1 )
       {
       ifd2.offset = fixlong((DWORD)offset);
       fseek ( Outfile, lTagOffset, 0 );

       n=fwrite(   &ifd2, 
                   1,
                   sizeof(IFD)-sizeof(ifd2.next),
                   Outfile );

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }
   /* update the offset at the appropriate location */
   else
       {
       int i;
       static DWORD dwOffset;
       
       dwOffset=fixlong((DWORD)offset);

       // seek to the stripe offset 

       n=fseek ( Outfile, fixlong((DWORD)ifd2.offset), 0 );

       // go to the nth value */

       for ( i=0; i < k ;i++)
           fseek ( Outfile, (long)sizeof(long),FILE_POS_RELATIVE );

       // update the byte count at that location 

       n=fwrite ( &dwOffset, 
                1,
                sizeof(long),
                Outfile );

       if (n <= 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }

   // restore current file position 

   n=fseek ( Outfile, coffset, 0 );

   cu0 :

   return err;
   }


/*
   Go through each entry in the IFD list and fix up the byte swap
   problem if needed.
*/

void  fixifd(IFD *ifd )
   {
   // write the Diretory entry 

   ifd->tag  = fixshort( ifd->tag);

   if ( ifd->count != 1L )
       ifd->offset = fixlong( (DWORD)ifd->offset );
   else
       {
       if ( ifd->type == 4 )
           ifd->offset = fixlong((DWORD)ifd->offset );
       else
           ifd->offset = (WORD)fixshort((WORD)ifd->offset );
       }

   ifd->count= fixlong ( ifd->count);
   ifd->type = fixshort( ifd->type );
   }

/*
   The DIB 24 bit image is stored with B-G-R byte order where TIF is stored
   as R-G-B.  This routine flip the B and R within a scanline.
*/

void   Flip24BitRGB(LPSTR buf,WORD nWidthBytes)
   {
   WORD i=nWidthBytes/3;
   BYTE c;

   while (i--)
       {
       c = *buf;
       *buf = *(buf+2);
       *(buf+2)=c;
       buf+=3;
       }
   }













