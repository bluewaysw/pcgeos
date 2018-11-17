/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		pcxsave.c

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
	

	$Id: pcxsave.c,v 1.1 97/04/07 11:28:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
  
/*************************************************************\
 
   PCX.C
 
Description
   Contain PCX related modules
 
   Following target PCX image files are supported:
 
   monochome
 
   16 colors
 
   256 colors  769 byte at the end of file. First byte MUST be
               0x0C(12) followed by 257 RGB triplets.
 
 
History
   01/30/90    Separated from convert.c 
               Per Rober Hanes input, PC World, looking into 
               PCX color problem.
 
   01/31/90    Fixed problem with RGBI alignment. 4 plane PCX 
               file use BGRI sequence(brain dead!)
 
   04/14/90    Start to work on DIB as input file format.
 
\**************************************************************/
#pragma Comment( "@" __FILE__);

#pragma Code ("MainExportC");

#include "hsimem.h"
#include "hsierror.h"


 
#include <Ansi/stdio.h>
#include "hsidib.h"
#include <Ansi/stdlib.h>     /* for _fmemxxx calls */
#include <Ansi/string.h>

#include "pcx.h"


static LPSTR  gOutBuffer;
static int gOutIndex;
static int gOutBufSize;
 
HSI_ERROR_CODE EXPORT HSISavePCX ( FILE *,FILE *, LPCNVOPTION);
int buf_write(FILE *,LPSTR,int);
 
void   NormalizeScanLine       (LPSTR);
HSI_ERROR_CODE CmpOneScanline  (LPSTR);
HSI_ERROR_CODE Cmp4Scanline    (LPSTR);
void            encput      ( int, int );
 
/* local variables */
 
WORD             tsize[8], WidthBytes;
int                plane;
LPSTR      inBuffer, outBuffer;
int        wScanline, iScanline;
LONG       lWord;
long       ll;
struct pcx_header   header;
WORD       l,m,n,o;
WORD       bpl;               /* bits per plane */
char       szComplete[] = "Complete";
 
/**/
 
 
/*****************************************************************
 
FUNCTION    HSISavePCX    (FILE * szInfile, FILE * szOutfile)
 
PURPOSE     Save the tempory file to a PCX file.
 
COMMENT     See the return code definition above. PCX file always use 1 bit
            per pixel and multiple bit plane for color image. Its color 
            planes are separated on a byte boundary. Which is different 
            from BMP, it use full bitplane.
 
******************************************************************/
 
LPCNVOPTION szOption;

HSI_ERROR_CODE EXPORT
HSISavePCX ( FILE * szInfile, FILE * szOutfile, LPCNVOPTION szOpt)
   {
/*   DWORD   dwLength;*/
   int     i/* , j, k, result = 0, tPlane=0, bmPlane=0 */;
   short   err = 0;
   /*char    str[80];*/
   WORD    height;
   MemHandle gOutBufferHandle;

   szOption = szOpt;
   gOutBufferHandle = allocmax(&gOutBufSize);    /* allocate global output */
   gOutIndex  = 0;                         /* buffer and reset index */
 
 /*lock block and deref Block to far pointer(ms)*/
   gOutBuffer = MemLock(gOutBufferHandle);

/* open input and output files */
 /*already open(ms)
   err = OpenRawInOutFile ( szInfile, szOutfile );
   
   if ( err ) goto cu0;
*/
   /* read header information from DIB file */

   Infile = (FILE *)szInfile;
   Outfile =(FILE *)szOutfile;

   err = ReadRawHeaderInfo(Infile);
 
   if ( err ) goto cu0;
 
   if (bmihdr.biBitCount==24 ||
       bmihdr.biBitCount==0)
       {
       err=HSI_EC_NO24BIT;  /* does not support 24 bit image */
       goto cu0;
       }
 
   header.manf        =   0x0a;
   header.version     =   0x05;
   header.encoding    =   0x01;    /* compressed */
 
   header.Xmin        =   header.Ymin = 0;
   header.Ymax        =   FIXWORD(bmihdr.biHeight-1);
   header.Xmax        =   FIXWORD(bmihdr.biWidth -1);
 
   header.V_res       =   FIXWORD(bmihdr.biHeight);
   header.H_res       =   FIXWORD(bmihdr.biWidth);
 
   header.bpp         =   1;
   header.nplanes     =   1;
 
   wWidthBytes = (bmihdr.biWidth+15)/16 * 2;
 
   switch ( bmihdr.biBitCount )
       {
       case 1 :
           header.bpp      = 1;
           header.nplanes  = 1;
           bpl	            = wWidthBytes;
           break;
 
       case 4 :
           header.bpp      = 1;
           header.nplanes  = 4;
           bpl             = wWidthBytes;
           break;
 
       case 8 :
           header.bpp      = 8;
           header.nplanes  = 1;
           bpl             = (bmihdr.biWidth+1)/2*2;
           break;
 
       case 24 :
          err = HSI_EC_OUTFILEUNSUPT;
          goto cu0;
 
       default :
          err = HSI_EC_INVALIDINPUT;      /* invalid input file */
          goto cu0;
           
       }

   /* save the bpl in header.  We cannot use header.bpl, in stead, we use */
   /* bpl.  This is because the header structure is INTEL format where    */
   /* WORD and DWORD are fixed. */ 
   header.bpl      = FIXWORD(bpl);

   if ( nColors < 0 )
       {
       err = HSI_EC_INVALIDINPUT;      /* invalid input file */
       goto cu0;
       }
 
   /* PCX file does not support 24bit image yet */
 
   if ( nColors == 0 )
       {
       err = HSI_EC_OUTFILEUNSUPT;
       goto cu0;
       }
 
   /* load color map data to PCX header for now. 256 color image file */
   /* (and/or version 5 file ) will be taken care of later  */
   /* (write to end of file). */
 
   for ( i=0;i!=16;i++)
       {
       /* color map is stored B-G-R ! which is contrary to what the */
       /* doc say, but this work! 6/15/90 Don */
 
       header.colormap[i][0] = clrtbl[i].rgbRed;
       header.colormap[i][1] = clrtbl[i].rgbGreen;
       header.colormap[i][2] = clrtbl[i].rgbBlue;
       }
 
   /* write header info to PCX file  */
 
   l = buf_write( Outfile,
                  (LPSTR)&header, 
                  sizeof(struct pcx_header));
 
   if (l==0L) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
   /* allocate buffer used to store compressed data for each scanline. Remember
   * that the scanline will be stored 'backward' for PCX file, which means
   * each compressed byte is store 'backward'(starting from the end and stored
   * one before the other). At the end, buffer is flushed to output file 
   * starting from the current pointer position.
   */
 
   inBuffer  =  (LPSTR) NULL;     
   outBuffer  = (LPSTR) NULL;     
 
   inBuffer  = (LPSTR) malloc(nWidthBytes+2);
 
   if (!inBuffer) 
       {
       err         = HSI_EC_NOMEMORY;
       goto cu0;
       }
   
   /* worst case compression is twice as big */
 
   outBuffer=(LPSTR)malloc(nWidthBytes*2);
 
   if (!outBuffer) 
       {
       err         = HSI_EC_NOMEMORY;
       goto cu0;
       }
 
   /* initialize buffer to all 1's  */
 
   _fmemset( (LPSTR)outBuffer, (BYTE)ones, nWidthBytes * 2 );
 
   /* DIB is store 'backward', we will read from the end of file, */
   /* one scanline at a time */
 
   ll = _llseek(Infile, 
           (LONG)bmfhdr.bfSize,
           0 );       /* seek to end of file */
 
   if (ll==-1L) {err=HSI_EC_SRCCANTSEEK;goto cu0;}
       
   _llseek (Infile, 
            -1L * (long)nWidthBytes,
            1 );     /* seek one scanline backward */
 
   /* go through all scanlines from input file */
 
   height = bmihdr.biHeight;
 
   while ( bmihdr.biHeight-- )
       {
       /*WORD    nRead;*/ 
 
       if (szOption && szOption->Disp)       
           {
           static int cline;
           int        i;
 
           i=  (int)((long)(height-bmihdr.biHeight) * 100L / (long)height);
 
           if (i!=cline)
               {
               cline = i;
               err=(*(szOption->Disp))(cline);
               if (err) goto cu0;
               }
           }
 
       /*nRead =*/ _lread (Infile,
                       inBuffer,       /* read one scanline into  */
                       nWidthBytes);
 
       wScanline = 0;
 
       if (bmihdr.biBitCount!=4)
          err=CmpOneScanline(inBuffer);   /* compress one scanline to buffer */
       else
          err=Cmp4Scanline(inBuffer);   /* compress one scanline to buffer */

 
       if ( err ) goto cu0;
 
       l = buf_write( Outfile,
                      outBuffer,          /* write out one compressed */
                      wScanline);
 
       if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
       _llseek(Infile,                 /* seek one scanline backward, since */
               -2*(LONG)nWidthBytes,   /* CmpOneScanline() will move current */
               1 );                    /* file position forward */
                                       
                                       
       }
 
   /* write 256 color palette if necessary */
 
   if ( bmihdr.biBitCount == 8 )
       {    
       BYTE c=0x0C;    /* it has to be an 12 to indicate there are 256 */
                       /* RGB triplete at the end ! */
       LPSTR lpstr;
 
       lpstr =(LPSTR) malloc(768);
 
       l = buf_write(Outfile,
                     (LPSTR)&c, 
                     1);
 
       if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
       for ( i=0; i < 256 ; i++ )
           {
           if (!lpstr)
               {
               l = buf_write(Outfile,(LPSTR)&clrtbl[i].rgbRed,    sizeof(BYTE));
               if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
               l = buf_write(Outfile,(LPSTR)&clrtbl[i].rgbGreen,  sizeof(BYTE));
               if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
               l = buf_write(Outfile,(LPSTR)&clrtbl[i].rgbBlue,   sizeof(BYTE));
               if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
               }
           else
               {
               lpstr[i*3]   = clrtbl[i].rgbRed; 
               lpstr[i*3+1] = clrtbl[i].rgbGreen;
               lpstr[i*3+2] = clrtbl[i].rgbBlue;
               }
           }
 
       if (lpstr)
           {
 
           l = buf_write(Outfile,lpstr,768);
           if (l==0) {err=HSI_EC_OUTOFTMPDISK;goto cu0;}
 
           _ffree(lpstr);
           }
       }
 
   cu0:
 
   if (inBuffer)  _ffree(inBuffer);
   if (outBuffer) _ffree(outBuffer);
 
   if(gOutIndex)           /* flush out output buffer data to file */
       {
	 _lwrite(Outfile,gOutBuffer,gOutIndex);
/*
	 _ffree(gOutBuffer);
*/
	 MemFree(gOutBufferHandle);
         gOutBufferHandle=(MemHandle)0;
       }
 /*
   CloseRawInOutFile();
 */
   return err;
   }
 
/* #pragma Code (); */ 

/* #pragma Code ("ImportCCode1") */
 
/*
   NAME    CmpOneScanline
 
   PURPOSE Compress one scanline from input file and write it to
           an output buffer. 16 color image needs to be normalized
           first, since input file has 4 bpp and will be converted
           to 1 bpp and 4 planes.
*/
 
HSI_ERROR_CODE
CmpOneScanline( LPSTR inBuffer )
   {
   short   err=0;
   /*int     count, i;*/
   WORD    chcnt;
   BYTE    c, d;
 
   wScanline = iScanline = 0;      /* reset scanline counter */
 
   chcnt   = 1;
   d       = inBuffer[iScanline++];        /* get first byte */
   /*count   = 1;*/
 
   while ( iScanline < bpl )
       {
 
       c = inBuffer[iScanline++];        /* get next byte */
 
       if ( c == d )
           {
 
           /* note count increase */
 
           if ( ++chcnt >= 63 )    /* write the pattern */
               {
               encput( d, chcnt );
               chcnt = 0;
               }
           }
       else
           {
           encput( d, chcnt );
           d=c;
           chcnt = 1;
           }
       }
 
   encput( d, chcnt ); /* flush out rest of the scanline */
 
   cu0:
 
   return err;
   }
 
HSI_ERROR_CODE
Cmp4Scanline( LPSTR inBuffer )
   {
   short   err=0;
   int     /*count*/ i,j,k;
   WORD    chcnt;
   BYTE    c, d;
 
   /* normalize the scanline for 4 bpp (16 color) image */
 
   NormalizeScanLine( inBuffer );
 
   k = nWidthBytes/4;
 
   wScanline = 0;      /* reset scanline counter */
 
   for (j=0;j<4;j++)
   {
   iScanline = j*k;
   chcnt   = 1;
   d       = inBuffer[iScanline];        /* get first byte */
   /*count   = 1;*/
   i=1;
 
   while ( i < bpl)
       {
       c = inBuffer[iScanline+i];        /* get next byte */
       i++;
 
       if ( c == d )
           {
           if ( ++chcnt >= 63 )    /* write the pattern */
               {
               encput( d, chcnt );
               chcnt = 0;
               }
           }
       else
           {
           encput( d, chcnt );
           d=c;
           chcnt = 1;
           }
       }
 
   encput( d, chcnt ); /* flush out rest of the scanline */
   }
 
 
   cu0:
 
   return err;
   }
 
 
/*
 * Encoding of the input compressed image to output buffer
 */
void
encput( int byt, int cnt )
   {
   if ( cnt )
       {
       if ( (cnt==1) && (0xc0 != (0xc0&byt)))
 
           outBuffer[ wScanline++ ] = byt;
 
       else    /* encode as byte pair */
           {
           outBuffer[ wScanline++ ] = 0xc0 | cnt;
           outBuffer[ wScanline++ ] = byt;
           }
       }
   }
 
/* #pragma Code () */

/* #pragma Code ("ImportCCode2") */
/*
   Convert 4bpp to 4 planes. Use a DWORD mask for each row and column
   conversion. The DIB bit has IRGB alignment where the PCX has
   BGRI alignment.
*/
 
 
DWORD  mask[16] =
   {
/*
        DIB = BGRI, PCX = BGRI
*/ 
       0x00000000,     // 0000 /
       0x00000001,     // 0001 /
       0x00000100,     // 0010 /
       0x00000101,     // 0011 /
       0x00010000,     // 0100 /
       0x00010001,     // 0101 /
       0x00010100,     // 0110 /
       0x00010101,     // 0111 /
       0x01000000,     // 1000 /
       0x01000001,     // 1001 /
       0x01000100,     // 1010 /
       0x01000101,     // 1011 /
       0x01010000,     // 1100 /
       0x01010001,     // 1101 /
       0x01010100,     // 1110 /
       0x01010101      // 1111 /
   };


      /*DIB = BGRI, PCX = IRGB 
 
       0x00000000,     / 0000 /
       0x01000000,     / 0001 /
       0x00010000,     / 0010 /
       0x01010000,     / 0011 /
       0x00000100,     / 0100 /
       0x01000100,     / 0101 /
       0x00010100,     / 0110 /
       0x01010100,     / 0111 /
       0x00000001,     / 1000 /
       0x01000001,     / 1001 /
       0x00010001,     / 1010 /
       0x01010001,     / 1011 /
       0x00000101,     / 1100 /
       0x01000101,     / 1101 /
       0x00010101,     / 1110 /
       0x01010101      / 1111 /
   };*/

/*
        DIB = IRGB, PCX = RGBI 
 
       0x00000000,     // 0000 /
       0x01000000,     // 0001 /
       0x00000010,     // 0010 /
       0x01000010,     // 0011 /
       0x00000100,     // 0100 /
       0x01000100,     // 0101 /
       0x00000101,     // 0110 /
       0x01000101,     // 0111 /
       0x00010000,     // 1000 /
       0x01010000,     // 1001 /
       0x00010001,     // 1010 /
       0x01010001,     // 1011 /
       0x00010100,     // 1100 /
       0x01010100,     // 1101 /
       0x00010101,     // 1110 /
       0x01010101      // 1111 /
   };

*/
/*
        DIB = BGRI, PCX = RGBI
 
       0x00000000,     // 0000 /
       0x00000001,     // 0001 /
       0x01000000,     // 0010 /
       0x01000001,     // 0011 /
       0x00010000,     // 0100 /
       0x00010001,     // 0101 /
       0x01010000,     // 0110 /
       0x01010001,     // 0111 /
       0x00000100,     // 1000 /
       0x00000101,     // 1001 /
       0x01000100,     // 1010 /
       0x01000101,     // 1011 /
       0x00010100,     // 1100 /
       0x00010101,     // 1101 /
       0x01010100,     // 1110 /
       0x01010101      // 1111 /
   };

*/
/*
   {
        DIB = IRGB, PCX = IRGB 
 
       0x00000000,     / 0000 /
       0x00000001,     / 0001 /
       0x00000100,     / 0010 /
       0x00000101,     / 0011 /
       0x00010000,     / 0100 /
       0x00010001,     / 0101 /
       0x00010100,     / 0110 /
       0x00010101,     / 0111 /
       0x01000000,     / 1000 /
       0x01000001,     / 1001 /
       0x01000100,     / 1010 /
       0x01000101,     / 1011 /
       0x01010000,     / 1100 /
       0x01010001,     / 1101 /
       0x01010100,     / 1110 /
       0x01010101      / 1111 /
   };
*/
 
/*
   {
       // DIB = IBGR, PCX = BGRI
 
       0x00000000,     // 0000
       0x01000000,     // 0001
       0x00000001,     // 0010
       0x01000001,     // 0011
       0x00000100,     // 0100
       0x01000100,     // 0101
       0x00000101,     // 0110
       0x01000101,     // 0111
       0x00010000,     // 1000
       0x01010000,     // 1001
       0x00010001,     // 1010
       0x01010001,     // 1011
       0x00010100,     // 1100
       0x01010100,     // 1101
       0x00010101,     // 1110
       0x01010101      // 1111
   };
 
   {
       // PCX = BGRI      DIB=IGRB
 
       0x00000000,     // 0000
       0x01000000,     // 0001
       0x00000100,     // 0010
       0x01000100,     // 0011
       0x00010000,     // 0100
       0x01010000,     // 0101
       0x00010100,     // 0110
       0x01010100,     // 0111
       0x00000001,     // 1000
       0x01000001,     // 1001
       0x00000101,     // 1010
       0x01000101,     // 1011
       0x00010001,     // 1100
       0x01010001,     // 1101
       0x00010101,     // 1110
       0x01010101      // 1111
   };
 
   {
       // DIB = IRGB, PCX = BGRI
 
       0x00000000,     // 0000
       0x01000000,     // 0001
       0x00010000,     // 0010
       0x01010000,     // 0011
       0x00000100,     // 0100
       0x01000100,     // 0101
       0x00010100,     // 0110
       0x01010100,     // 0111
       0x00000001,     // 1000
       0x01000001,     // 1001
       0x00010001,     // 1010
       0x01010001,     // 1011
       0x00000101,     // 1100
       0x01000101,     // 1101
       0x00010101,     // 1110
       0x01010101      // 1111
   };
 
*/
static DWORD   dw,dw1;

 
void
NormalizeScanLine( LPSTR inBuffer )
   {
   int     i, j, in;
   BYTE    c;
   int     width=nWidthBytes/4;
   LPSTR   out=outBuffer;
 
   /* let's borrow the outbuffer for now */
 
   _fmemcpy ( out, inBuffer, nWidthBytes );
 
   for ( i=0 ; i < width ; i++ )
       {
       dw = 0L;
 
       for ( j=0; j < 4 ; j++ )
           {
           c = 0x00;
 
           c = ( *out >> 4 ) & 0x0F;
 
           in  = 7 - 2 * j;
           dw1 = (mask[c] << in);
           dw |= dw1;

           c = *out & 0x0F;        /* get 2nd nibble */
 
           in = 7 - (2*j+1);
           dw1 = mask[c] << in;
           dw |= dw1;
 
           out++;
           }
 
       /* DIB input = IBGR, PCX = BGRI */
 /*
       *(inBuffer+3*width) = (BYTE)(( dw >> 24 ) & 0xFF) ;
       *inBuffer           = (BYTE)(( dw >> 16 ) & 0xFF) ;
       *(inBuffer+width)   = (BYTE)(( dw >>  8 ) & 0xFF) ;
       *(inBuffer+2*width) = (BYTE)( dw );

 */

 /* BGRI - DIB  RGBI- PCX
       *(inBuffer+width) = (BYTE)(( dw >> 24 ) & 0xFF) ;
       *(inBuffer+2*width)   = (BYTE)(( dw >> 16 ) & 0xFF) ;
       *(inBuffer+ 3*width)   = (BYTE)(( dw >>  8 ) & 0xFF) ;
  
     *(inBuffer) = (BYTE)( dw );
*/

 /* BGRI - DIB  RGBI- PCX*/ 
       *(inBuffer+width*3) = (BYTE)(( dw >> 24 ) & 0xFF) ;
       *(inBuffer+2*width)   = (BYTE)(( dw >> 16 ) & 0xFF) ;
       *(inBuffer+ width)   = (BYTE)(( dw >>  8 ) & 0xFF) ;
       *(inBuffer) = (BYTE)( dw );

 /* IRGB - DIB  RGBI- PCX 
       *(inBuffer) = (BYTE)(( dw >> 24 ) & 0xFF) ;
       *(inBuffer+3*width)   = (BYTE)(( dw >> 16 ) & 0xFF) ;
       *(inBuffer+ 2*width)   = (BYTE)(( dw >>  8 ) & 0xFF) ;
       *(inBuffer+ width) = (BYTE)( dw );
*/
 /* BGRI - DIB  IRGB- PCX 
       *(inBuffer)           = (BYTE)(( dw >> 24 ) & 0xFF) ;
       *(inBuffer+width)   = (BYTE)(( dw >> 16 ) & 0xFF) ;
       *(inBuffer+2*width)   = (BYTE)(( dw >>  8 ) & 0xFF) ;
       *(inBuffer+3*width) = (BYTE)( dw );
*/
       inBuffer++;
       }

   }
 
 
 
 
 
/*
   Check whether the global output buffer exist. If so, write to
   the global buffer in stead.  If buffer overflow, flush it out
   to disk and reset counter.
*/
 
int buf_write(FILE * fd, LPSTR s, int n)
   {
   long l;
   int size=gOutBufSize-gOutIndex;
   int result=n;
 
   if (!gOutBuffer)            /* write it out if no global buffer exist */
       return _lwrite(fd,s,n);
 
   _fmemcpy(gOutBuffer+gOutIndex,      /* copy to output buffer  */
            s,
            min(size,n) );
 
   gOutIndex += min(size,n);
 

/*n
   if ( size <= n ) / overflow, flush buffer out /
       {
 
       l = _lwrite(fd,gOutBuffer,gOutBufSize);
 
       if ( l <= 0 )
           return 0;
 
       gOutIndex = 0;          / reset index /
 
       _fmemcpy(gOutBuffer,    / copy the reset of string to output buffer /
                s+size,
                n-size);
 
       gOutIndex += (n-size);
 
       }
*/

/* MS- 6/10/92 to account for smaller buffer size and possibility that
       the overflow is more than one buffer's worth.         */

   while ( size <= n ) /* overflow, flush buffer out */
       {
 
       l = _lwrite(fd,gOutBuffer,gOutBufSize);
 
       if ( l <= 0 )
           return 0;
 
       gOutIndex = 0;          /* reset index */
 
       s += size;              /* reset pointer into string */

       n -= size;              /* amount of string left */

       size = gOutBufSize;    /* buffer size */
 
      _fmemcpy(gOutBuffer,    /* copy the rest of string to output buffer */
                s,
                min(size,n));

                              /* reset index */
       gOutIndex += min(size,n);
 
       }
 
   return result;   	    /* return number of bytes written */
   }
 
#pragma Code ()

