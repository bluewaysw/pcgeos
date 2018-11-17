/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		clpsave.c

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
	

	$Id: clpsave.c,v 1.1 97/04/07 11:26:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*
   CLPSAVE.C

Description

   Save DIB file to clipboard internal bitmap format. 

History
   06/06/90    Support both Windows 2.x and 3.0 bitmap format. For
               Windows 2.x, it is the brain-damage interleaved
               color plane format. For windows 3.0, we support the
               CF_DIB ouput. If there is a need, we can also support
               the Windows 3.0 CF_BITMAP format.
*/

#pragma Code ("MainExportC");

#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"    

#include <Ansi/stdlib.h>
#include <Ansi/string.h>



#include "clp.h"

extern CLP30FILEHDR   clp30filehdr;
extern CLP30HDR       clp30hdr;



// function prototypes

HSI_ERROR_CODE  SaveCLP20       (VOID);
HSI_ERROR_CODE  SaveCLP30       (VOID);
HSI_ERROR_CODE  SaveCLPPM       (VOID);

char szDIB[]= "Device Independent Bitmap";
LPCNVOPTION    szOption;

/*

   FUNCTION    HSISaveCLP    (FILE *, FILE *, dwOption )

   PURPOSE     Save the DIB formatted file to Clipboard format.

   PARAMETER   szInfile    Input file name (DIB)
               szOutfil    Output file name (CLP)
               dwOption    
                       BYTE    11, NULL - Windows 3.0
                               10       - Windows 2.x
                               12       - PM
*/

HSI_ERROR_CODE EXPORT
HSISaveCLP ( FILE * szInfile, FILE * szOutfile, LPCNVOPTION szOpt)
   {
   DWORD dwOption;
   short err=0;

/*   int result = 0, tPlane=0, bmPlane=0; */
  

   szOption = szOpt;

   if (szOption)                           // check whether option is
       dwOption = szOption -> dwOption;    // provided.
   else
       dwOption = 0L;

   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

    
   /*open input and output files
   err = OpenRawInOutFile ( szInfile, szOutfile );

   if ( err ) goto cu0;

   */
   // read header information from DIB file

   err = ReadRawHeaderInfo(Infile);

   if (err) goto cu0;

   // check option byte

   if ( dwOption == 0L || dwOption == 11L )
       SaveCLP30 ();                 // default to Windows 30 format
   else
   if ( dwOption == 10L )
       SaveCLP20();
   else
   if ( dwOption == 12L ) 
       SaveCLPPM();
   else
       {
       err = HSI_EC_UNSUPPORTED;
       goto cu0;
       }

   cu0:
/*
   CloseRawInOutFile ();
*/
   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(szOption->end);

   return err;

   }



/*
   Save to Windows 2.x Clipboard bitmap format.
*/

HSI_ERROR_CODE
SaveCLP20(void)
   {
   LPSTR       inBuffer=NULL;
   CLPHDR      clphdr;
   short       err=0;
   int         nRead;
   WORD        n;

   clphdr.byte1 = 0xE3;    // 
   clphdr.byte2 = 0xC7;

   clphdr.width    = nWidthBytes * 8 / bmihdr.biBitCount;
   clphdr.height   = (WORD)bmihdr.biHeight;

   clphdr.width1   = nWidthBytes * 8 / bmihdr.biBitCount;
   clphdr.height1  = (WORD)bmihdr.biHeight;

   clphdr.widthbyte= nWidthBytes;

   clphdr.bitspixel= (BYTE)bmihdr.biBitCount;
   clphdr.planes   = (BYTE)bmihdr.biPlanes;


   // Clipboard file does not support 24bit image

   if ( nColors == 0 )
       {
       err = HSI_EC_UNSUPPORTED;
       goto cu0;
       }

   // write CLP file header info

   if ( !_lwrite ( Outfile,
                   (LPSTR)&clphdr,
                   sizeof(CLPHDR)))
       {
       err = HSI_EC_DSTCANTWRITE;
       goto cu0;
       }


   inBuffer  = _fmalloc( nWidthBytes );

   if ( !inBuffer ) 
       {
       err         = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // DIB is store 'backward', we will read from the end of file,
   // one scanline at a time

   _llseek ( Infile, 
           (LONG)bmfhdr.bfSize,
           0 );        // seek to end of file

   _llseek ( Infile, 
           -1L * (long)nWidthBytes, 
           1 );                    // seek one scanline backward

   // go through all scanlines from input file

   while ( bmihdr.biHeight-- )
       {

       nRead = _lread (Infile,
                       (LPSTR)inBuffer,       // read one scanline into 
                       nWidthBytes);

       if ( nRead <= 0 )
           {
           err = HSI_EC_SRCCANTREAD;
           goto cu0;
           }

       n = _lwrite (  Outfile,
                  inBuffer,           // write out one compressed
                  nWidthBytes);

       if (n == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

       _llseek ( Infile,                 // seek tw0 scanline backward, since
                 -2L * (long)nWidthBytes,// CmpOneScanline() will move current
                 1 );                    // file position forward
       }


   cu0:

   if ( inBuffer ) 
       _ffree(inBuffer);

   return err;
   }


HSI_ERROR_CODE
SaveCLP30(void)
   {
   short       err=0;
   MemHandle   lpStrHandle;
   LPSTR       lpStr=NULL;
   int         size,n;

   clp30filehdr.fileid = CLP_ID;
   clp30filehdr.count  = 1;

   clp30hdr.fmtid  = CF_DIB;
   clp30hdr.length = sizeof(BITMAPINFOHEADER)+
                     nColors*sizeof(RGBQUAD) +
                     bmihdr.biSizeImage;

   clp30hdr.offset = sizeof(CLP30HDR) +
                     sizeof(CLP30FILEHDR);

   _fstrcpy( (LPSTR)clp30hdr.name, 
             szDIB );

   n = _lwrite(Outfile,
               (LPSTR)&clp30filehdr,
               sizeof(CLP30FILEHDR));

   if (n == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   n = _lwrite(Outfile,
               (LPSTR)&clp30hdr,
               sizeof(CLP30HDR));

   if (n == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   n = _lwrite(Outfile,
            (LPSTR)&bmihdr,
            sizeof(BITMAPINFOHEADER));
   
   if (n == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // write out color palette

   n = _lwrite(Outfile,
               (LPSTR)clrtbl, 
               sizeof(RGBQUAD)*nColors);

   if (n == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }

   // copy over data. Use memory if possible.

   lpStrHandle = allocmax(&size);
   lpStr = MemLock(lpStrHandle);

   if (!lpStr)
       {
       err=HSI_EC_NOMEMORY;    // no memory at all!!
       goto cu0;
       }

   while ((n=_lread(Infile,lpStr,size)) > 0 )
       {
       n = _lwrite(Outfile,lpStr, n);

       if (n == 0 ) { err=HSI_EC_DSTCANTWRITE; goto cu0; }
       }

   cu0:


   if ( lpStr )
     MemFree(lpStrHandle);                 /*_ffree(lpStr);*/

   return err;
   }




HSI_ERROR_CODE
SaveCLPPM(void)
   {
   short err=0;

   err = HSI_EC_UNSUPPORTED;

   return err;
   }


#pragma Code ();
