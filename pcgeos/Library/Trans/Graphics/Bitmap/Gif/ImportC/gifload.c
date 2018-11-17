/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		gifload.c				     
*								     
*	AUTHOR:		jimmy lefkowitz				     
*								     
*	REVISION HISTORY:					     
*								     
*	Name	Date		Description			     
*	----	----		-----------			     
*	jimmy	1/29/92		Initial version			     
*								     
*	DESCRIPTION:						     
*								     
*	$Id: gifload.c,v 1.1 97/04/07 11:27:09 newdeal Exp $
*							   	     
*********************************************************************/
#pragma Comment( "@" __FILE__);

#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"    
#include "gif.h"
#include <Ansi/string.h>
#include <Ansi/stdlib.h>
#include <geoMisc.h>         /*needed for strcmpi which isnt AnsiC compatible*/
#include <localize.h>
LPSTR      InBuffer, OutBuffer;

int        colors;
BYTE       bits_per_pix;
short      err2;
WORD       theight;
WORD       plane, pixcol, pixrow;
BYTE       BitsPixel;
WORD       iImageWidth, iImageHeight, bmWidthBytes;
BOOL       fInterlace;

WORD       base_row[4] = { 0, 4, 2, 1 },    // Interlace Tables 
           row_disp[4] = { 8, 8, 4, 2 },
           interlace_pass = 0;

long       endImage= 0;
int        nrw;
int        nWrite, nRead;
int        Importn;
long       Importl;
int     bad_code_count;

#define MAX_CODES   4095

LPCNVOPTION szOption;

/*********************************************************************

   FUNCTION    LoadGIF ( szInfile, szOutfile )

   PURPOSE     Convert GIF file to DIB.

**********************************************************************/

HSI_ERROR_CODE FAR PASCAL
HSILoadGIF ( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt)
   {
   short    err =0;
   static char     /*filename[15],*/ version[8]/*, style[5]*/;
   int      /*image_left, image_top, data_byte_cnt*/;
   static BYTE     byte1,/* byte2,*/ byte3;
   int      image_cnt, bits_to_use/*, color_res*/;
   static int      /*i,*/ globl,/* end_gif_fnd,*/ unexpected/*, color_style, switch_present*/;
   static long     file_byte_cnt=0L;
/*
   WORD     width, height;
   char     str[80];
*/
   szOption = szOpt;

   Infile = (FILE *)szInfile;
   Outfile = (FILE *)szOutfile;
/***
   err = OpenInOutFile ( szInfile, szOutfile );
   if ( err ) goto cu0;
***/

   // allocate larger buffer for input file only.  No need to increase
   // output buffer size, since fseek() is used extensively.

   theight         = 0;
   pixrow          = 0;       /* used for interlaced image */
   interlace_pass  = 0;       /* used for interlaced image */
   bad_code_count  = 0;
 /*color_style = 0; */
   image_cnt   = 0;
 /*  end_gif_fnd = 0;*/
   unexpected  = 0;

   // get version from file 

   nrw = fread( version, 1, 6, Infile );

   if ( nrw <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

#ifdef DO_DBCS
   if ((version[0] != 'G') && (version[0] != 'g'))
      goto notGif;
   if ((version[1] != 'I') && (version[1] != 'i'))
      goto notGif;
   if ((version[2] != 'F') && (version[2] != 'f'))
      goto notGif;
   if (version[3] != '8')
      goto notGif;
   if ((version[4] != '7') && (version[4] != '9'))
      goto notGif;
   if ((version[5] == 'A') || (version[5] == 'a'))
      goto isGif;
   goto isGif;
 notGif:
    err = HSI_EC_NOTGIF;
    goto cu0;
 isGif:
#else
   version[6] = 0;
 // new version has GIF89A
   if ( strcmpi( version, "GIF87a" ) != 0 && 
        strcmpi( version, "GIF89a" ) != 0 )    
       {
       err = HSI_EC_NOTGIF;        
       goto cu0;                   // This is not a GIF file
       }
#endif
   file_byte_cnt += 6L;

   // determine screen width 

 /*  width      = */getbytes( Infile );
 /*  height     = */getbytes( Infile );

   // check for a Global Map 

   nrw = fread( &byte1, 1, 1, Infile );

   if ( nrw <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }
   file_byte_cnt++;

   if (  byte1 & 0x80 )
       globl = TRUE;
   else
       globl = FALSE;

   /* --------------------------
   Check for the 0 bit 
   if ( !( byte1 & 0x08 ) ) ;
       printf ("\n? -- Reserved zero bit is not zero.\n"); 
   ---------------------*/

   /* determine the color resolution */
/**
   byte2 = byte1 & 0x70;
   color_res = byte2 >> 4;
**/
   /* get the background index */
   nrw = fread ( &byte3, 1, 1, Infile ); 
   if ( nrw <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   file_byte_cnt++;

   /* determine the bits per pixel */
   bits_per_pix   = byte1 & 0x07;
   bits_per_pix++;
   bits_to_use    = bits_per_pix;
   BitsPixel      = bits_per_pix;

   /* determine # of colors in global map */
   colors = 1 << bits_per_pix;

   /* check for the 0 byte */

   nrw = fread ( &byte1, 1, 1, Infile );
   if ( nrw <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   file_byte_cnt++;

   /* ------------------
   if (byte1 != 0) ;
       printf ("\n? -- Reserved byte after Background index is not zero.\n"); 
   ------------------------- */

   // monochrome image should have 2 colors anyway

   if ( !globl )
       colors = 2;

   // if there is a global colormap, save the color map in memory 

   LoadColorMap ( colors, &file_byte_cnt );

   /* check for the zero byte count, a new image, or 
    the end marker for the gif file*/ 

   while (fread( &byte1, 1, 1, Infile ) > 0)
       {

       file_byte_cnt++;

       switch ( byte1 )
           {
           case ',' :
               image_cnt++;

               if (unexpected != 0)
                   chkunexp ( &unexpected, image_cnt);

               // decompress GIF file 

               err = LoadGIFImage( bits_to_use, 
                            /*   color_style,*/ 
                               &file_byte_cnt);

               goto cu0;
    
           case '!' :
               /* Extension data found */ 

               err = extninfo( &file_byte_cnt );

               // stop reading file, do not consider this as error return

               if ( err )
                   {
                   err = 0;
                   goto cu0;
                   }

               break;
    
           case ';' :
               /* GIF terminator located, check for any 
                unexpected data found before terminator*/ 

               if (unexpected != 0)
                   chkunexp (&unexpected, -1);

	       /**
               end_gif_fnd = 1;
	       **/
               break;
    
           default :
               unexpected++;
           }
       }

   cu0:


/***
   CloseInOutFile();
****/

   if (!err && szOption && szOption->Disp)
       (*(szOption->Disp))(100);

   return err;
   }




/* 
 * COLORMAP - reads color information in from the GIF file 
 */
int 
LoadColorMap( int times, long *file_byte_cnt)
   {
   static BYTE    red, green, blue;
   short err2;
   int     i;

   err2 = 0;
   /*b&w image */

/*****************************************************************************
   if ( times == 2 )
       {
       clrtbl[0].rgbBlue     = 0x00;
       clrtbl[0].rgbGreen    = 0x00;
       clrtbl[0].rgbRed      = 0x00;
       clrtbl[0].rgbReserved = 0x00;

       clrtbl[1].rgbBlue     = 0xFF;
       clrtbl[1].rgbGreen    = 0xFF;
       clrtbl[1].rgbRed      = 0xFF;
       clrtbl[1].rgbReserved = 0x00;
       memset ( &clrtbl[2].rgbBlue, zero, sizeof(RGBQUAD) * 254 );

       return 0;
       }
 *****************************************************************************/

   for (i = 0; i < times ; i++)
       {
       nrw = fread ( &red,   1, 1, Infile );
       if( nrw <= 0)
	   {
	       err2 = HSI_EC_SRCCANTREAD;
	       goto cu0;
	   }
       nrw = fread ( &green, 1, 1, Infile );
       if( nrw <= 0)
	   {
	       err2 = HSI_EC_SRCCANTREAD;
	       goto cu0;
	   }
       nrw = fread ( &blue,  1, 1, Infile );
       if( nrw <= 0)
	   {
	       err2 = HSI_EC_SRCCANTREAD;
	       goto cu0;
	   }
       /* save RGB pallette values */

       clrtbl[i].rgbRed    = red;
       clrtbl[i].rgbGreen  = green;
       clrtbl[i].rgbBlue   = blue;

       *file_byte_cnt += 3L;

       }

   if ( times != 256 )
      memset ( &clrtbl[i].rgbBlue, 
               zero, 
               sizeof(RGBQUAD) * (256-times) );
   cu0:
   return err2;
   }


/*
   
*/

HSI_ERROR_CODE
LoadGIFImage( int bits_to_use/*, int color_style*/ , long *file_byte_cnt )
   {
   /* int     image_left,image_top, data_byte_cnt;*/
   static BYTE    byte12, byte22/*, byte3*/;
   int     /*color_res, i,*/ local/*, unexpected*/;
/**
   DWORD   bytetot, possbytes;
**/
   /* determine the image left value */ 

   getbytes( Infile );



   /* determine the image top value */ 

/*image_top      = */  getbytes(Infile);
   iImageWidth    = getbytes(Infile);
   iImageHeight   = getbytes(Infile);

   /* check for interlaced image */

   nrw = fread ( &byte12, 1, 1, Infile );
   if( nrw <= 0)
       {
	   err2 = HSI_EC_SRCCANTREAD;
	   goto cu0;
       }
   (*file_byte_cnt)++;

   byte22 = byte12 & 0x40;

   if ( byte22 == 0x40 )
       fInterlace = TRUE;
   else
       fInterlace = FALSE;

   /* check for a local map */ 

   byte22 = byte12 & 0x80;

   if (byte22 == 0x80)
       local = TRUE;
   else
       local = FALSE;

   /* check for the 3 zero bits */ 

   byte22 = byte12 & 0x38;

   if ( local )    /* Yes, there is local colormap */
       {
       /* determine the # of color bits in local map */ 

       bits_per_pix = byte12 & 0x07;
       bits_per_pix++;
       bits_to_use = bits_per_pix;

       LoadColorMap ( 1 << bits_per_pix, file_byte_cnt );
       }


   bmfhdr.bfType       = BFT_BITMAP;
   bmfhdr.bfReserved1  = 0;
   bmfhdr.bfReserved2  = 0;

   bmihdr.biSize       = 40L;

   bmihdr.biWidth         = iImageWidth;
   bmihdr.biHeight        = iImageHeight;
   bmihdr.biPlanes        = 1;

   bmihdr.biCompression   = 0L;
   bmihdr.biXPelsPerMeter = 0L;
   bmihdr.biYPelsPerMeter = 0L;
   bmihdr.biClrUsed       = (long)colors;
   bmihdr.biClrImportant  = 0L;

   if ( BitsPixel == 1 )
       {
       bmihdr.biBitCount = 1;
       bmWidthBytes = (iImageWidth+15)/16*2;
       nColors      = 2;
       }
   else
   if ( BitsPixel <= 4 )
       {
       bmihdr.biBitCount = 4;
       bmWidthBytes = (iImageWidth+15)/16*2*4;
       nColors      = 16;
       }
   else
   if ( BitsPixel <= 8 )
       {
       bmihdr.biBitCount = 8;
       bmWidthBytes = (iImageWidth+15)/16*2*8;
       nColors      = 256;
       }
   else
       {   
       err2 = HSI_EC_UNSUPPORTED;   // does not support 24 bit
       goto cu0;
       }

   // calculate real size in byte of one scanline

   wWidthBytes = ( (bmihdr.biWidth * bmihdr.biBitCount ) + 
                   7 ) / 8 * bmihdr.biPlanes;

   // normalize scanline width to LONG boundary

   nWidthBytes = ( wWidthBytes + sizeof(LONG)-1 ) / 
                   sizeof(LONG) *
                   sizeof(LONG); 

   bmihdr.biSizeImage = (DWORD)nWidthBytes * bmihdr.biHeight;

   // calculate offset to bitmap data

   bmfhdr.bfOffBits   = sizeof(BITMAPFILEHEADER) + // notice that the colors
                        sizeof(BITMAPINFOHEADER) + // is the actual # of
                        colors * sizeof(RGBQUAD);  // colors used.

   // calculate total size of this image

   bmfhdr.bfSize      = bmihdr.biSizeImage +
                        bmfhdr.bfOffBits;

   /* write out file header */

   err2 = WriteHeaderInfo();
   if (err2) goto cu0;

   // fill the file
   // if image is interleaved 

   Importn = fseek(Outfile, (long) bmihdr.biSizeImage, 1);
   if( Importn != 0)
       {
	   err2 = HSI_EC_DSTCANTWRITE;
	   goto cu0;
       }


     endImage = ftell(Outfile);
/* ---- 

   if ( fInterlace )
       {

       long    lword=ftell ( Outfile );

       // allocate correct bytes for the output file 

       fseek ( Outfile, 
               (long) bmihdr.biSizeImage,
               1 );

       // go back to where we were

       fseek( Outfile, (long)lword, 0 );

       }

 ---- */

   // call the DecodeGIFData module 

   err2 = DecodeGIFData((WORD)bmihdr.biWidth );

   if (err2) goto cu0;

   cu0:

   return err2;
   }




/* ---------------------  DecodeGIFData module ------------------------------*/

/* 
 * DECODE.C - An LZW DecodeGIFData for GIF
 *
 * GIF and 'Graphics Interchange Format' are trademarks (tm) of
 * Compuserve, Incorporated, an H&R Block Company.
 */

/* Static variables */
static WORD curr_size;                     /* The current code size */
static WORD clear;                         /* Value for a clear code */
static WORD ending;                        /* Value for a ending code */
static WORD newcodes;                      /* First available code */
static WORD top_slot;                      /* Highest code for current size */
static WORD slot;                          /* Last read code */

// The following static variables are used
// for seperating out codes

static WORD navail_bytes = 0;              /* # bytes left in block */
static WORD nbits_left = 0;                /* # bits left in current byte */
static BYTE b1;                           /* Current byte */
static BYTE byte_buff[257];               /* Current block */
static BYTE *pbytes;                      /* Pointer to next byte in block */

static DWORD code_mask[13] = {
     0,
     0x0001, 0x0003,
     0x0007, 0x000F,
     0x001F, 0x003F,
     0x007F, 0x00FF,
     0x01FF, 0x03FF,
     0x07FF, 0x0FFF
     };


// This function initializes the decoder for reading a new image.

static WORD init_exp( WORD size )
   {
   curr_size      = size + 1;
   top_slot       = 1 << curr_size;
   clear          = 1 << size;
   ending         = clear + 1;
   slot = newcodes= ending + 1;
   navail_bytes   = 0;
   nbits_left     = 0;

   return(0);
   }

// get_next_code()
// - gets the next code from the GIF file.  Returns the code, or else
// a negative number in case of file errors...
//

static int get_next_code( FILE * Infile )
   {
   static WORD     i, x;
   DWORD     ret;

   if (nbits_left == 0)
       {
       if (navail_bytes <= 0)
       {

       /* Out of bytes in current block, so read next block */
       pbytes = byte_buff;

       if (fread(&navail_bytes, 1, 1, Infile) <= 0)    // no more data
           return -1;                                  // all done

       else if (navail_bytes)
           {
           for (i = 0; i < navail_bytes; ++i)
               {
               if (fread(&x, 1, 1, Infile )<=0)    // no more data
                   return -1;                      // all done

               byte_buff[i] = x;
               }
           }
       }

       b1 = *pbytes++;
       nbits_left = 8;
       --navail_bytes;

       }

   ret = b1 >> (8 - nbits_left);
   while (curr_size > nbits_left)
       {
       if (navail_bytes <= 0)
           {

           /* Out of bytes in current block, so read next block */
           pbytes = byte_buff;

           if ( fread ( &navail_bytes, 1, 1, Infile ) <= 0)
               return -1;

           else if (navail_bytes)
               {
               for (i = 0; i < navail_bytes; ++i)
                   {
                   if ( fread ( &x, 1, 1, Infile )  <= 0)
                       return -1;

                   byte_buff[i] = x;
                   }
               }
           }

       b1 = *pbytes++;
       ret |= b1 << nbits_left;
       nbits_left += 8;
       --navail_bytes;
       }

   nbits_left -= curr_size;
   ret &= code_mask[curr_size];

   return((WORD)(ret));
   }

/* The reason we have these seperated like this instead of using
 * a structure like the original Wilhite code did, is because this
 * stuff generally produces significantly faster code when compiled...
 * This code is full of similar speedups...  (For a good book on writing
 * C for speed or for space optomisation, see Efficient C by Tom Plum,
 * published by Plum-Hall Associates...)
 */

static BYTE stack[MAX_CODES + 1];            /* Stack for storing pixels */
static BYTE suffix[MAX_CODES + 1];           /* Suffix table */
static WORD prefix[MAX_CODES + 1];           /* Prefix linked list */


/* WORD DecodeGIFData()
 *
 * This function decodes an LZW image, according to the method used
 * in the GIF spec.  Every *linewidth* "characters" (ie. pixels) decoded
 * will generate a call to out_line(), which is a user specific function
 * to WRITE OUT line of pixels.  The function gets it's codes from
 * get_next_code() which is responsible for reading blocks of data and
 * seperating them into the proper size codes.  Finally, get_byte() is
 * the global routine to read the next byte from the GIF file.
 *
 * It is generally a good idea to have linewidth correspond to the actual
 * width of a line (as specified in the Image header) to make your own
 * code a bit simpler, but it isn't absolutely necessary.
 *
 * Returns: 0 if successful, else negative.  (See ERRS.H)
 *
 */


LPSTR  obuf;           // output buffer itself
int    obuflinecnt;    // current line number in output buffer
int    obufnoline;     // number of lines in output buffer

HSI_ERROR_CODE
DecodeGIFData( WORD linewidth )
   {
   BYTE FAR *sp;
   BYTE FAR *bufptr;
   WORD   code, fc, oc, bufcnt;
   LPSTR    buf=NULL;
   static BYTE            size;
   short    c;
   short    err;
   long     fposition;

   OutBuffer = NULL;

   // Initialize for decoding a new image...    

   if ( fread( &size, 1, 1, Infile ) <= 0 )
       {
       err = HSI_EC_SRCCANTREAD;
       goto cu0;
       }

   if (size < 2 || 9 < size)      
       {
       err =  HSI_EC_UNSUPPORTED;
       goto cu0;
       }

   init_exp( size );

   // Initialize in case they forgot to put in a clear code.
   // (This shouldn't happen, but we'll try and decode it anyway...)

   oc = fc = 0;

   /* Allocate space for the decode buffer */  

   buf = (LPSTR) malloc(linewidth + 2 );   

   if (!buf) 
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // allocate space for output buffer 

   OutBuffer = (LPSTR)malloc(nWidthBytes+1);

   if ( !OutBuffer )
       {
       err = HSI_EC_NOMEMORY;
       goto cu0;
       }

   // allocate space for large output buffer up to 32K chunk

//   obuf = allocmax(&size);
//
//   if (obuf)
//       {
//       obufnoline = size / nWidthBytes;
//       obuflinecnt= obufnoline-1;
//       }

   // Set up the stack pointer and decode buffer pointer    

   sp = stack;
   bufptr = (BYTE FAR *)buf;
   bufcnt = linewidth;

   // This is the main loop.  For each code we get we pass through the
   // linked list of prefix codes, pushing the corresponding "character" for
   // each code onto the stack.  When the list reaches a single "character"
   // we push that on the stack too, and then start unstacking each
   // character for output in the correct order.  Special handling is
   // included for the clear code, and the whole thing ends when we get
   // an ending code.
   
   while ((c = get_next_code(Infile)) != ending)
       {
       // If we had a file error, return without completing the decode 

       if ( c < 0 )
           {
           err = 0;
           goto cu0;
           }

       // If the code is a clear code, reinitialize all necessary items.
         
       if (c == clear)
           {
           curr_size = size + 1;
           slot = newcodes;
           top_slot = 1 << curr_size;

           // Continue reading codes until we get a non-clear code
           // (Another unlikely, but possible case...)
           
           while ((c=get_next_code( Infile )) == clear)
               {
               if (c<0)        /* unexpected EOF */
                   {
                   err=0;
                   goto cu0;
                   }
               }

           // If we get an ending code immediately after a clear code
           // (Yet another unlikely case), then break out of the loop.
           
           if (c == ending)
               break;

           // Finally, if the code is beyond the range of already set codes,
           // (This one had better NOT happen...  I have no idea what will
           // result from this, but I doubt it will look good...) then set it
           // to color zero.
           
           if (c >= slot)
               c = 0;

           oc = fc = c;

           // And let us not forget to put the char into the buffer... And
           // if, on the off chance, we were exactly one pixel from the end
           // of the line, we have to send the buffer to the out_line()
           // routine...
           
           *bufptr++ = c;

           if (--bufcnt == 0)
               {
/********************************************************************
  this error check was <0, but there was a file write error, and a non zero
  errror code was returned, but it is ignored because the test was for only <0
  WHY??????????????????????????
****************************************Ms 1/17/93*************************/
               if ((err = out_line( (BYTE FAR *)buf, linewidth)) != 0)
                   goto cu0;

               bufptr = (BYTE FAR *)buf;
               bufcnt = linewidth;
               }
           }
       else
           {
	   /*********************************************************
           // In this case, it's not a clear code or an ending code, so
           // it must be a code code...  So we can now decode the code into
           // a stack of character codes. (Clear as mud, right?)
           **********************************************************/
           code = c;

	   /**********************************************************
           // Here we go again with one of those off chances...  If, on the
           // off chance, the code we got is beyond the range of those already
           // set up (Another thing which had better NOT happen...) we trick 
           // the DecodeGIFData into thinking it actually got the last code read.
           // (Hmmn... I'm not sure why this works...  But it does...)
           ********************************************************/
           if (code >= slot)
               {

               if (code > slot)
                   {
                   ++bad_code_count;
                   err=HSI_EC_INVALIDFILE;
                   goto cu0;
                   }

               code = oc;
               *sp++ = fc;
               }

           // Here we scan back along the linked list of prefixes, pushing
           // helpless characters (ie. suffixes) onto the stack as we do so.
           
           while (code >= newcodes)
               {
               *sp++ = suffix[code];
               code = prefix[code];
               }

	   /***************************************************
           // Push the last character on the stack, and set up the new
           // prefix and suffix, and if the required slot number is greater
           // than that allowed by the current bit size, increase the bit
           // size.  (NOTE - If we are all full, we *don't* save the new
           // suffix and prefix...  I'm not certain if this is correct...
           // it might be more proper to overwrite the last code...
           ***************************************************/
           *sp++ = code;

           if (slot < top_slot)
               {
               suffix[slot] = fc = code;
               prefix[slot++] = oc;
               oc = c;
               }

           if (slot >= top_slot)
               if (curr_size < 12)
                   {
                   top_slot <<= 1;
                   ++curr_size;
                   } 

	   /******************************************************
           // Now that we've pushed the decoded string (in reverse order)
           // onto the stack, lets pop it off and put it into our decode
           // buffer...  And when the decode buffer is full, write another
           // line...
           ****************************************************/
           while (sp > (BYTE FAR *)stack)
               {
               *bufptr++ = *(--sp);

               if (--bufcnt == 0)
                   {
/********************************************************************
  this error check was <0, but there was a file write error, and a non zero
  errror code was returned, but it is ignored because the test was for only <0
  WHY??????????????????????????
****************************************Ms 1/17/93*************************/
                   if ((err = out_line( (BYTE FAR *)buf, linewidth)) != 0)
                      {
                      goto cu0;
                      }

                   bufptr = (BYTE FAR *)buf;
                   bufcnt = linewidth;
                   }
               }
           }


       }

   fposition = ftell(Outfile);

   if ((theight < iImageHeight) && (bufcnt < (linewidth-1)))
       err = out_line( (BYTE FAR *) buf, (linewidth - bufcnt));

   cu0:

   if (OutBuffer)
       _ffree(OutBuffer);

   if (buf)
      _ffree(buf);

// image file is corrupted if not enough scanline is read 
//   if ( theight < iImageHeight ) 
//       return 5; 

//   if (obuf)   // large output buffer exist, flush it out
//       {
//       flushimage();
//       _ffree(obuf);
//       }

   return err;
   }




/*
 EXTNINFO - routine to read the GIF file for extension data and       
            display it to the screen in an orderly fasion.  This      
            extension information may be located before, between, or  
            after any of the image data.                              
*/

int 
extninfo( long *file_byte_cnt)
   {
   static BYTE       byte13, byte23; 
   static int        i2, data_byte_cnt;
   DWORD      bytetot;
   short      err = 0;

   // retrieve the function code 

   nrw = fread ( &byte13, 1, 1, Infile );
   if( nrw <= 0)
       {
	   err = HSI_EC_SRCCANTREAD;
	   goto cu0;
       }

   (*file_byte_cnt)++;

   // tally up the total bytes and read past each data block

   bytetot = 0;

   if ( fread( &data_byte_cnt, 1, 1, Infile ) <= 0 )
       data_byte_cnt = EOF; 

   while ( data_byte_cnt > 0 )
       {                
       (*file_byte_cnt)++;

       bytetot = bytetot + data_byte_cnt;

       for (i2 = 0; i2 < data_byte_cnt ; i2++)
           {
           (*file_byte_cnt)++;

           if ( fread( &byte23, 1, 1, Infile ) <= 0 )
               {
               (*file_byte_cnt)--;
               err = HSI_EC_SRCCANTREAD;
               goto cu0;
               }
           }

       if ( fread( &data_byte_cnt, 1, 1, Infile ) <= 0 )
           data_byte_cnt = EOF; 
       }

   (*file_byte_cnt)++;

   if ( data_byte_cnt == EOF )
       {
       (*file_byte_cnt)--;
       return 2;
       }

   cu0:

   return err;
   }


/* 
   CHKUNEXP - routine to check for any unexpected nonzero data found  
              within the GIF file.  This routine will help determine    
              where the unexpected data may reside in the file.         
*/

void
chkunexp ( int *unexpected, int determiner)
   {

   /* Determine place in the GIF file */ 

   if (determiner > 0)
       {
       /*
       printf ("\n? -- %d bytes of unexpected data found before",*unexpected);
       printf ("\n     image %d.\n", determiner);
       */
       }
   else if (determiner == -1)
       {
       /*
       printf ("\n? -- %d bytes of unexpected data found before", *unexpected);
       printf ("\n     GIF file terminator.\n");
       */
       }
   else if (determiner == -2)
       {
       /*
       printf ("\n? -- %d bytes of unexpected data found after", *unexpected);
       printf ("\n     GIF file terminator.\n");
       */
       }
   else
       {
       /*
       printf ("\n? -- %d bytes of unexpected data found at",*unexpected);
       printf ("\n     or after expected GIF terminator byte.\n");
       */
       }

   /* Zero out the unexpected variable for */
   /* the next group that may be encountered */

   *unexpected = 0;

   }


/*
 * After each scanline is decompressed, the buffer has 1 byte/pixel
 * format. Translate to the appropriate bits depending upon bits-per-pixel
 * value.
 */

int 
out_line( BYTE FAR *pixels, int linelen )
   {
/**
   int     i, j;
   WORD    width;
   BYTE    c;
   char    str[ 80 ];
   long lw;
**/
   short   err=0;

   if (szOption && szOption->Disp)       
       {
       static int clinel;
       int        ii;

       ii = (int)((DWORD) theight * 100L / (DWORD)bmihdr.biHeight);

       if (ii !=clinel)
           {
           clinel = ii;
           err=(*(szOption->Disp))(clinel);
           if (err) goto cu0;
           }
       }

   ++theight;

   // rewind the file one scanline

   fseek ( Outfile, -1L * (long)nWidthBytes, 1 );

   switch ( BitsPixel )
       {
       case 5 :
       case 6 :
       case 7 :
       case 8 :
           err = SaveTo8( (LPSTR)pixels, linelen ); 
           if (err) goto cu0;
           break;

       case 2 :
       case 3 :
       case 4 :
           err = SaveTo4( (LPSTR)pixels, linelen );
           if (err) goto cu0;
           break;

       case 1 :
           // pack 8 bytes to 1 byte before writing 
           err = SaveTo1 ( (LPSTR)pixels, linelen );
           if (err) goto cu0;
           break;

       default:  /* not supported format */
           err=HSI_EC_UNSUPPORTED;
           goto cu0;
       }

   // rewind the file one scanline again

   fseek ( Outfile, -1L * (long)nWidthBytes, 1 );

   cu0:

   return err;
   }


/*
   Convert scanline from 1 byte per pixel to 1 byte per 8 pixel.
*/

int SaveTo1 (LPSTR pixels, int linelen )
   {
   register BYTE    j;
   register int     i;
   register LPSTR   p=OutBuffer;
   short err=0;

   j  = 0;
   *p = 0;

   for ( i = 0 ; i < linelen ; i++ )
       {
       if ( pixels[i] ) 
           *p |= BitPatternOr[ j ];

       if ( ++j == 8 )
           {
           j = 0;
           ++p;
           *p = 0x00;
           }
       }

   // write the line out

   Importl=lfwrite ( OutBuffer, 1, (DWORD)nWidthBytes, Outfile );
   if (Importl<=0L) {err=HSI_EC_DSTCANTWRITE;goto cu0;}

   cu0:

   return err;

   }

/* 
  Convert scanline buffer from 1 byte/pixel to 4 bits/pixel or
  2 pixel per byte depending upon the display type. And write
  the scanlines out. 
*/
int        SaveTo4(LPSTR pixels, int n )
   {
   int     i;
/***
   BYTE    c;
***/
   LPSTR   p=OutBuffer;
   short   err=0;

   // convert from 1 byte per pixel to 2 pixel per byte

   for ( i=0 ; i < n ; i += 2 )
       {

       *p  = (pixels[i] & 0x0F) << 4;
       *p |= pixels[i+1] & 0x0F;

       p++;
       }

   Importl=lfwrite( OutBuffer, 1, (DWORD)nWidthBytes, Outfile );
   if (Importl<=0L) {err=HSI_EC_DSTCANTWRITE;goto cu0;}

   if ( theight >= iImageHeight ) 
       return 0;

   // take care of interleaved image 

   if ( fInterlace )
       {
       // increment current row 

       pixrow += row_disp[interlace_pass];

       if (pixrow >= bmihdr.biHeight)
           {

           interlace_pass++;

           if ( interlace_pass >= 4 ) 
               return 0;

           pixrow = base_row[interlace_pass];
/****************************************************
temp!!*/
           nrw = fseek( Outfile, endImage, 0 );
	   if( nrw !=0) 
	       {
		   err = HSI_EC_DSTCANTSEEK;
		   goto cu0;
	       }

           nrw = fseek( Outfile, 
                  -1L * (long)pixrow * nWidthBytes,
                  1 );
	   if( nrw !=0) 
	       {
		   err = HSI_EC_DSTCANTSEEK;
		   goto cu0;
	       }

/*
           nrw = fseek( Outfile, 
                  -1L * (long)pixrow * nWidthBytes,
                  2 );
	   if( nrw !=0) 
	       {
		   err = HSI_EC_DSTCANTSEEK;
		   goto cu0;
	       }
*/
           // since we will seek backward twice, we have to force
           // it forward first (yuuk!!)

           nrw = fseek ( Outfile, 
                   (long) nWidthBytes, 
                   1 );
	   if( nrw !=0) 
	       {
		   err = HSI_EC_DSTCANTSEEK;
		   goto cu0;
	       }
           }
       else
           fseek( Outfile, 
                  -1L * (long)(row_disp[interlace_pass]-1) * nWidthBytes, 
                  1 );
       }

   cu0:

   return err;
   }




/*
   Save 1 byte per pixel to 1 byte per pixel. No conversion necessary.
*/
int 
SaveTo8( LPSTR pixels, int n )
   {
/*   int   i;*/
   short err=0;

   // write out scanline as is

   Importl=lfwrite( pixels, 1, (DWORD)n, Outfile );

   if (Importl<=0L) {err=HSI_EC_DSTCANTWRITE;goto cu0;}

   // fill the trailing blanks if any 

   if ( n < nWidthBytes )
       {

       // fill the trailing with the last color

       _fmemset ( OutBuffer, 
                  (BYTE)pixels[bmihdr.biWidth-1], 
                  nWidthBytes - n );

       Importl=lfwrite( OutBuffer, 
                  1,
                  (DWORD)(nWidthBytes - n),
                  Outfile );

       if (Importl<=0L) {err=HSI_EC_DSTCANTWRITE;goto cu0;}
       }

   if ( (theight >= iImageHeight) || !fInterlace ) 
       return 0;

   pixrow += row_disp[interlace_pass];

   if ( pixrow >= bmihdr.biHeight )
       {
       interlace_pass++;

       if ( interlace_pass >= 4 ) 
           return 0;

       pixrow = base_row[interlace_pass];
       nrw = fseek( Outfile, endImage, 0 );
       if( nrw !=0) 
	   {
		   err = HSI_EC_DSTCANTSEEK;
		   goto cu0;
	   }

       nrw = fseek ( Outfile,                     // counting from backward
               -1L * (long)pixrow * nWidthBytes,
               1 );
       if( nrw !=0)
	   {
	       err = HSI_EC_DSTCANTSEEK;
	       goto cu0;
	   }
       nrw = fseek ( Outfile, (long) nWidthBytes, 1 );
       if( nrw !=0)
	   {
	       err = HSI_EC_DSTCANTSEEK;
	       goto cu0;
	   }

       }
   else
      {
	  nrw = fseek( Outfile, 
              -1L * (long)(row_disp[interlace_pass]-1) * nWidthBytes,
              1 );
	  if( nrw !=0)
	   {
	       err = HSI_EC_DSTCANTSEEK;
	       goto cu0;
	   }

      }
   cu0:

   return err;
   }

/* read one integer value( 2 bytes ) from file and return it to caller */
WORD     getbytes( FILE * Infile )
   {
   static BYTE    cl[3];

   nrw = fread( cl, 1, 2, Infile );

   return (WORD)256*cl[1]+cl[0];
   }


/*
   Buffer the write operatoin
*/

/*
int 
imgwrite(LPSTR buf,int i, int j, FILE * fp)
   {

   _fmemcpy(obuf+(long)obuflinecnt*nWidthBytes,
            buf,
            nWidthBytes );

   obuflinecnt--;  // decrement line count

   if (obuflinecnt==0) // flush output buffer
       {
       nrw = fseek(Outfile,                      // rewind the file first
             -1L * (long)nWidthBytes * (long)bufnoline,
             1 );
       if( nrw !=0)
       {
          err = HSI_DSTCANTSEEK;
	  goto cu0;
	  }

       Importl= lfwrite( obuf,                  // write out data buffer
                    1,
                    (DOWRD)(nWidthBytes * bufnoline),
                    Outfile);
       if( Importl<= 0L)
       {
         err = HSI_EC_DSTCANTWRITE;
	 goto cu0;
	 }

       nrw =fseek(Outfile,                      // rewind the file again
             -1L * (long)nWidthBytes * (long)bufnoline,
             1 );
       if( nrw !=0)
       {
          err = HSI_DSTCANTSEEK;
	  goto cu0;
	  }
       nrw = fseek(Outfile,                      // rewind one more scanline
             -1L * (long)nWidthBytes,
             1 );
       if( nrw !=0)
       {
          err = HSI_DSTCANTSEEK;
	  goto cu0;
	  }
       obuflinecnt = obufnoline-1;         // reset line counter
       }
       cu0:
       return err;
   }

int
flushimage()
   {
   int i = bufnoline-buflinecnt;
   short err = 0;

   nrw = fseek(Outfile,                      // rewind the file first
         -1L * (long)nWidthBytes * (long)i,
         1 );
       if( nrw !=0)
       {
          err = HSI_DSTCANTSEEK;
	  goto cu0;
	  }
   Importl = lfwrite( obuf+(long)buflinecnt * nWidthBytes,
                1,
                (DWORD)(nWidthBytes * i),
                Outfile);
   if ( Importl <= 0L)
     err = HSI_EC_DSTCANTWRITE;
   return err
}

*/


