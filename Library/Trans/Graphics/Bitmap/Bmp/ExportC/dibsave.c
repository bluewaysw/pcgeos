/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dibsave.c

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
	

	$Id: dibsave.c,v 1.1 97/04/07 11:26:09 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

/*

Revision History

12/29/91   Now support RLE for 4,8 bit Windows 3 DIB

*/

#pragma Code ("MainExportC");

#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"

#ifndef BMP_RLE30
#define BMP_RLE30 9
#endif

/*
** Local function prototypes
*/

HSI_ERROR_CODE EXPORT  HSISaveDIB  (FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE EXPORT  HSISaveWRLE (FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE EXPORT  HSISaveBMP20(FILE *,FILE *,LPCNVOPTION);
HSI_ERROR_CODE EXPORT  HSISavePMDIB(FILE *,FILE *,LPCNVOPTION);

HSI_ERROR_CODE HSIRLECmpr(VOID);


int RLE8CmprLine(char *src, char *dst, int n);
int RLE4CmprLine(char *src, char *dst, int n);


/*
** Local variables
*/

int n;
DWORD l;
static LPCNVOPTION szOption;
static DWORD       lfsize;
static int  biCompression;

/*
   This API can be used to generate different flavors of BMP files.
   The options should be provided in the dwOption field.  If dwOption
   is 0, then default to Windows 3.0 DIB.
*/

HSI_ERROR_CODE EXPORT
HSISaveBMP(FILE * szInfile,FILE * szOutfile,LPCNVOPTION szOpt)
   {
   DWORD   dwOption;
   short   err;

   if (szOpt)
       dwOption = szOpt->dwOption;
   else
       dwOption = BMP_WIN30;

   switch (dwOption)
       {
       case BMP_WIN20:
           err=HSISaveBMP20(szInfile,szOutfile,szOpt);
           break;

       case BMP_PM10:
           err=HSISavePMDIB(szInfile,szOutfile,szOpt);
           break;

       case BMP_RLE30:
           err=HSISaveWRLE(szInfile,szOutfile,szOpt);
           break;

       default :
           err=HSISaveDIB(szInfile,szOutfile,szOpt);
           break;
       }

   return err;
   }

/*
   Save internal Metafile to Windows 3.0 DIB. Currently they are
   the same.
*/

HSI_ERROR_CODE EXPORT
HSISaveDIB (FILE * szInfile,FILE * szOutfile,LPCNVOPTION szOpt)
   { 
   short   err=0;
   LPSTR   buf=NULL;
   int   size;

   MemHandle bufHandle;

   szOption = szOpt;
/*
   err = OpenInOutFile ( szInfile, szOutfile );

   if (err) 
       goto cu0;
*/
   
   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

   fseek(Infile,0L,2);
   lfsize = ftell(Infile);
   fseek(Infile,0L,0);            // rewind the file

   // copy the DIB file to something with BMP extension
   // copy over data. Use memory if possible.

   bufHandle = allocmax(&size);

   buf = MemLock(bufHandle);

   if (!buf)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   while ((l = lfread(buf,1,(DWORD)size,Infile)) > 0 )
       {
       DWORD dw;

       dw = lfwrite(buf,1,l,Outfile);

       if (dw<=0)
           {
           err=HSI_EC_NODISKSPACE;
           goto cu0;
           }

       if (szOption && szOption->Disp)
           {
           static int cline1s;
           int        ii;
           DWORD      dw;

           dw = fseek(Infile,0L,1);  // get current offset

           ii = (int)((DWORD) dw *
                       (DWORD)(szOption->end-szOption->start) / 
                       (DWORD)lfsize) +
                       szOption->start;

           if (ii !=cline1s)
               {
               cline1s = ii;
               err=(*(szOption->Disp))(cline1s);
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

   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(szOption->end);

   return err; 
   }

/*
   Save internal Metafile to Windows 3.0 compressed DIB. (RLE)
*/

HSI_ERROR_CODE EXPORT
HSISaveWRLE(FILE * szInfile,FILE * szOutfile,LPCNVOPTION szOpt)
   { 
   short   err=0;
/*   LPSTR   buf=NULL;
   int     size;
*/

   szOption = szOpt;
/*
   err = OpenInOutFile ( szInfile, szOutfile );
   if (err) goto cu0;
*/
   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

   err = ReadHeaderInfo(Infile);
   if (err) goto cu0;
  
   if (bmihdr.biBitCount==4)
       biCompression = BI_RLE4;
   else
   if (bmihdr.biBitCount==8)
       biCompression = BI_RLE8;
   else
       {
       /*
       ** RLE supports only 4 and 8 bit DIB. We will save this file
       ** as uncompressed BMP
       */
/*
       CloseInOutFile();
*/
       return HSISaveDIB(szInfile,szOutfile,szOpt);
       }

   err=HSIRLECmpr();

   cu0:
/*
   CloseInOutFile();
*/
   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(szOption->end);

   return err; 
   }


/*
   Save the Internal DIB file (Windows 3.0) to Presenation Manager
   DIB format.
*/

HSI_ERROR_CODE EXPORT
HSISavePMDIB ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt)
   { 
   short   err=0;
   int     i;
   static BITMAPCOREHEADER    bmchdrS;
   LPSTR   buf=NULL;
   int     n;
   int size;
   MemHandle bufHandle;

   szOption = szOpt;

   // open the input file and outfile 
/*
   err = OpenInOutFile ( szInfile, szOutfile );

   if ( err ) goto cu0;
*/
   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

   fseek(Infile,0L,2);   // get file size
   lfsize = ftell(Infile); 
   fseek(Infile,0L,0);            // rewind the file

   // read the Windows 30 DIB header information

   err = ReadHeaderInfo(Infile);

   if ( err ) goto cu0;

   // prepare PM DIB file header

   bmchdrS.bcSize       = 12L;
   bmchdrS.bcWidth      = bmihdr.biWidth;
   bmchdrS.bcHeight     = bmihdr.biHeight;
   bmchdrS.bcPlanes     = bmihdr.biPlanes;
   bmchdrS.bcBitCount   = bmihdr.biBitCount;
   
   // PM has smaller info header size and RGB palette entry

   bmfhdr.bfOffBits    = sizeof(BITMAPFILEHEADER) +
                         sizeof(BITMAPCOREHEADER) +
                         nColors * sizeof(RGBTRIPLE);

   bmfhdr.bfSize       = bmihdr.biSizeImage +
                         bmfhdr.bfOffBits;

   // write out PM file header

   n= fwrite(&bmfhdr,1,sizeof(BITMAPFILEHEADER),Outfile);

   if (n<=0)
       {
       err=HSI_EC_OUTOFTMPDISK;
       goto cu0;
       }

   // write out PM info header

   n= fwrite(&bmchdrS,1,sizeof(BITMAPCOREHEADER),Outfile);

   if (n<=0)
       {
       err=HSI_EC_OUTOFTMPDISK;
       goto cu0;
       }

   // write out color palette

   for ( i=0 ; i < nColors ; i++ )
       {
       n = fwrite(&clrtbl[i],        // Write out only the RGB as required
                  1,
                  sizeof(RGBTRIPLE),
                  Outfile);
       if (n<=0)
          {
          err=HSI_EC_OUTOFTMPDISK;
          goto cu0;
          }
       }

   // copy the DIB file content to PM DIB

   
   bufHandle = allocmax(&size);
   buf = MemLock(bufHandle);

   if (!buf)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   while ((l= lfread(buf,1,(DWORD)size,Infile)) > 0 )
       {
       long dw;

       dw= lfwrite(buf,1,l,Outfile);
       
       if (dw<=0)
           {
           err=HSI_EC_NODISKSPACE; 
           goto cu0;
           }

       if (szOption && szOption->Disp)
           {
           static int cline2s;
           int        ii;
           DWORD      dw;

           dw = ftell(Infile);  // get current offset

           ii = (int)((DWORD) dw * 
                      (DWORD) (szOption->end-szOption->start) / 
                      (DWORD)lfsize) +
                      szOption->start;

           if (ii !=cline2s)
               {
               cline2s = ii;
               err=(*(szOption->Disp))(cline2s);
               if (err) goto cu0;
               }
           }
       }

   cu0:

   if (buf) /* _ffree(buf);*/
     MemFree(bufHandle);

/*
   CloseInOutFile();
*/
   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(szOption->end);

   return err; 
   }



/* 
   Save Windows 3.0 DIB to Windows 2.0 BMP format. Window

       1 bpp   1 plane
       4 bpp   1 plane
       8 bpp   1 plane
       1 bpp   3 plane (most common)
       1 bpp   2 plane (unlikely)
       1 bpp   4 plane (possible)

   Since Windows 3.0 DIB only has 1, 4, 8, and 24 bits-per-pixel. We will
   support the equivalent for the Windows 2.0 format. This might cause
   potential problems; if 20 Bitmap viewer is not intelligent enough,
   then it can not view the image (This will be corrected, although
   painful, if user scream!).

*/

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
	} BMFILEHDR;

BMFILEHDR   bmhdr;


HSI_ERROR_CODE EXPORT
HSISaveBMP20 ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt)
   {
   short       err=0, i;
/*   HANDLE      hHandle;*/
   MemHandle   hHandle;
   LPSTR       lpStr;
   long        l;

   szOption = szOpt;

   // open input and output file
/*
   err = OpenRawInOutFile ( szInfile, szOutfile );

   if ( err ) goto cu0;
*/

   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;

 // read header information

   err = ReadRawHeaderInfo(Infile);

   if ( err ) goto cu0;

   // prepare 2.0 header

   bmhdr.dummy1        = 0;
   bmhdr.bmType        = 0;
   bmhdr.bmWidth       = bmihdr.biWidth;
   bmhdr.bmHeight      = bmihdr.biHeight;
   bmhdr.bmWidthBytes  = nWidthBytes;
   bmhdr.bmPlanes      = bmihdr.biPlanes;
   bmhdr.bmBitsPixel   = bmihdr.biBitCount;
   bmhdr.scnWidth      = 640;
   bmhdr.scnHeight     = 480;

   n = _lwrite ( Outfile,
            (LPSTR)&bmhdr,             // write out the bitmap header
            sizeof(BMFILEHDR));
   
   if (n<=0)
       {
       err=HSI_EC_OUTOFTMPDISK;
       goto cu0;
       }

   l = _llseek( Infile,                    // DIB is stored backward, seek
            (long)bmfhdr.bfSize,       // to end of file
            0 );

   if (l==-1L) {err=HSI_EC_DSTCANTWRITE; goto cu0;}

   _llseek  ( Infile,                    // rewind one scanline
            -1L * (long)nWidthBytes,
            1 );

   // allocate scanline output buffer
/*
   hHandle = GlobalAlloc ( GPTR, (DWORD)nWidthBytes );
*/
     hHandle =  MemAlloc ( (WORD)nWidthBytes,HF_FIXED,HAF_ZERO_INIT );
   if ( !hHandle )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }
/*
   lpStr = (LPSTR)GlobalLock ( hHandle );
*/
   lpStr = (LPSTR)MemDeref ( hHandle );
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

   for ( i=0 ; i < bmihdr.biHeight ; i++ )
       {           

       _lread ( Infile,
               (LPSTR)lpStr,           // read next scanline from DIB
               nWidthBytes);

       _llseek ( Infile,               // rewind two scanlines, the DIB
               -2L * (long)nWidthBytes,// is stored backward
               1 );

       n = _lwrite( Outfile,
                    lpStr,                
                    nWidthBytes);

       if (n<=0)
           {
           err=HSI_EC_NODISKSPACE;
           goto cu0;
           }

       if (szOption && szOption->Disp)
           {
           static int cline3s;
           int        ii;

           ii = (int)((DWORD) i * 
                      (DWORD) (szOption->end - szOption->start) / 
                      (DWORD)bmihdr.biHeight) +
                      szOption->start;

           if (ii !=cline3s)
               {
               cline3s = ii;
               err=(*(szOption->Disp))(cline3s);
               if (err) goto cu0;
               }
           }
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
/*
   CloseRawInOutFile();
*/
   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(szOption->end);

   return err;
   }


HSI_ERROR_CODE
HSIRLECmpr(VOID)
   {
   int i,err=0;
   int nbytes;     /* number of bytes in compressed scanline */
   int n;
   long total=0;
   char *src=NULL; /* source uncompress scanline */
   char *dst=NULL; /* target compressed scanline */
   static char buf[40];
   static BYTE cS;

   src = malloc(nWidthBytes);
   dst = malloc(nWidthBytes*2);

   if (!src || !dst)
       {
       err=HSI_EC_NOMEMORY;
       goto cu0;
       }

   /*
   ** Write out header as place holder, which will be updated
   ** afterward.
   */

   err=WriteHeaderInfo();
   if (err) goto cu0;

   /*
   ** Compress one scanline at a time
   */

   for (i=0;i<bmihdr.biHeight;i++)
       {
       /*
       ** Read one uncompressed scanline 
       */

       n=fread(src,1,nWidthBytes,Infile);

       if (n<=0)
           {
           err=HSI_EC_SRCCANTREAD;
           goto cu0;
           }

       /*
       ** Compress one scanline 
       */

       if (biCompression==BI_RLE8)
           nbytes = RLE8CmprLine(src,dst,nWidthBytes);
       else
           nbytes = RLE4CmprLine(src,dst,nWidthBytes);

       /*
       ** Write out one compressed scanline
       */

       n=fwrite(dst,1,nbytes,Outfile);

       if (n<=0)
           {
           err=HSI_EC_DSTCANTWRITE;
           goto cu0;
           }

       total += nbytes;

       if (szOption && szOption->Disp)
           {
           static int cline4s;
           int        ii;

           ii = (int)((DWORD) i *
                       (DWORD)(szOption->end-szOption->start) / 
                       (DWORD) bmihdr.biHeight) +
                       szOption->start;

           if (ii !=cline4s)
               {
               cline4s = ii;
               err=(*(szOption->Disp))(cline4s);
               if (err) goto cu0;
               }
           }
       }

   /*
   ** Write out end-of-bitmap code
   */
   
   cS=0; fwrite(&cS,1,1,Outfile);
   cS=1; fwrite(&cS,1,1,Outfile);
   total += 2;

   /*
   ** Update the header info and write it out
   */

   bmihdr.biSizeImage   = total;
   bmihdr.biCompression = biCompression;

   bmfhdr.bfSize        = bmfhdr.bfOffBits +
                          bmihdr.biSizeImage;

   fseek(Outfile,0L,0);

   copybmf2buf(&bmfhdr,buf);

   fwrite(buf,                     /* write out file header */
          1,
          SIZEOFBMPFILEHDR,
          Outfile);
 
   copybmi2buf(&bmihdr,buf);
 
   fwrite(buf,                     /* write out header info  */
          1,
          SIZEOFBMPINFOHDR,
          Outfile);

   cu0:

   if (src) free(src);
   if (dst) free(dst);

   return err;
   }



/*
** Compress one scanline from src to dst.
**
** char *src   source scanline buffer
** char *dst   target compressed scanline buffer
** int n       number of bytes in source buffer
**
** Return
**
**     number of bytes in compressed buffer
*/

int RLE8CmprLine(char *src, char *dst, int n)
   {
   int i,count=1,absolute=1;
   BYTE c;
   char *t=dst,*tmp;

   c = (BYTE)*src;

   for (i=1;i<n;i++)
       {
       if ((BYTE)src[i]==c)
           {
           if (absolute > 1)
               {
               if (absolute==2)    /* optimize the special case where the */
                   {               /* absolute run is 2 */
                   t = tmp-1;
                   *t++ = absolute-1;
                   *t++ = *(t+1);
                   count=2;
                   }
               else
               if (absolute==3)    /* be careful about absolute count is 3 */
                   {               /* we cannot optimize it since the 0 2  */
                   *tmp = absolute;/* has special meaning */
                   *t++ = c;
                   *t++ = 0;
                   count=1;
                   }
               else
                   {
                   *tmp = absolute-1;

                   /* 
                   ** absolute run has to be WORD aligned 
                   */

                   if ((absolute-1)%2)
                       *t++ = 0;

                   count=2;
                   }

               absolute = 1;
               continue;
	     }


           if (count >= 0xFE)  /* make sure the repeat counter does not */
               {               /* overflow. Flush the buffer if needed  */
               *t++ = count;
               *t++ = c;
               count= 1;       /* reset repeat counter */
               }
           else
               count++;        /* increment the repeat counter */

           continue;
           }
       else
           {
           if (count > 1)      /* write out repeated run if any */
               {
               *t++ = count;
               *t++ = c;
               count= 1;       /* reset repeat counter */
               c = (BYTE)src[i];
               continue;
               }

           if (absolute >= 0xFE)
               {
               *tmp = absolute-1;

               /* 
               ** absolute run has to be WORD aligned 
               */

               if ((absolute-1)%2)
                   *t++ = 0;

               absolute = 1;
               }

           if (absolute==1)
               {
               *t++ = 0;       /* code to indicate absolute run */
               tmp  = t;       /* save the absolute counter position */
               *t++ = 2;       /* at least two run */
               }

           *t++ = c;
           c = (BYTE)src[i];

           absolute++;         /* increment absolute run counter */
           }
       }

   if (count>1)        /* write out repeated run if any */
       {
       *t++ = count;
       *t++ = c;
       }
   else
   if (absolute>1)
       {
       if (absolute==2)
           {
           t = tmp-1;
           *t++ = 1;
           *t++ = *(t+1);
           *t++ = 1;
           t++;
           }
       else
           {
           *tmp = absolute;
           *t++ = c;        /* write out the last byte */

           if (absolute%2)  /* absolute run has to be WORD aligned */
               *t++ = 0;
           }
       }
   else
       {
       *t++=1;
       *t++=c;
       }

   *t++ = 0;   /* end-of-line record */
   *t++ = 0;

   return (int)(t-dst);
   }



/*
** Compress one scanline from src to dst with 4 bbp.
**
** char *src   source scanline buffer
** char *dst   target compressed scanline buffer
** int n       number of bytes in source buffer
**
** Return
**
**     number of bytes in compressed buffer
*/

int RLE4CmprLine(char *src, char *dst, int n)
   {
   int i,count=2/*,absolute=1*/;
   BYTE c;
   char *t=dst/*,*tmp*/;

   c = (BYTE)*src;

   for (i=1;i<n;i++)
       {
       if ((BYTE)src[i]==c)
           {

           if (count >= 0xFE)  /* make sure the repeat counter does not */
               {               /* overflow. Flush the buffer if needed  */
               *t++ = count;
               *t++ = c;
               count= 2;       /* reset repeat counter */
               }
           else
               count+=2;       /* increment the repeat counter */

           continue;
           }
       else
           {
           if (count > 2)      /* write out repeated run if any */
               {
               *t++ = count;
               *t++ = c;
               count= 2;       /* reset repeat counter */
               c = (BYTE)src[i];
               continue;
               }

           *t++ = 2;
           *t++ = c;
           c = (BYTE)src[i];
           }
       }

   if (count>2)        /* write out repeated run if any */
       {
       *t++ = count;
       *t++ = c;
       }
   else
       {
       *t++=2;
       *t++=c;
       }

   *t++ = 0;   /* end-of-line record */
   *t++ = 0;

   return (int)(t-dst);
   }


#pragma Code ();

