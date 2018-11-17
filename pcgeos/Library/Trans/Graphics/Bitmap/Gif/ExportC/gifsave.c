/********************************************************************
*								     
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved	     
*								     
* 	PROJECT:	PC GEOS					     
* 	MODULE:							     
* 	FILE:		gifsave.c				     
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
*	$Id: gifsave.c,v 1.1 97/04/07 11:27:06 newdeal Exp $
*							   	     
*********************************************************************/




/**************************************************************************

NAME       GIFSAVE.C

PURPOSE    Save GIF(Graphics Interchange Format) file.

HISTORY

02/04/89    Created.

07/06/89    Cannot have global windows handle for status dialog box. It 
            somehow screw up only after the next SetScrollRange() call in
            the fileio.c routine. Once I pass hWnd to each function, then
            the problem goes away.

7/25/89     Add color table to BMP file when GIF file is loaded.

4/18/90    Start porting to Windows 3.0 with DIB format as metafile

11/4/90    Take care of DIB that has less color used than the bit depth
           e.g. 32 color used in 8 bit image. -Don Hsi

****************************************************************************/

/***
#include <fcntl.h>
#include <setjmp.h>
#include <sys/types.h>
**/
#include "hsimem.h"
#include "hsierror.h"

#include <Ansi/stdio.h>
#include "hsidib.h"    


#include <Ansi/string.h>
#include <Ansi/stdlib.h>
#include <resource.h>

// global variables

// used with setvbuf() call

/**
HSI_ERROR_CODE EXPORT  HSISaveGIF      ( LPSTR, LPSTR,LPCNVOPTION );
**/
short          Write_Byte(BYTE);
short       Write_Color_Map            ( int );

// global variables

BYTE        LookUpTable[ 256 ];
BOOL        fInterlace2;
int         interleave=0, BitsPixel2;
int         gcolors;

LPCNVOPTION szOption2;
WORD        plane2, pixcol2, pixrow2;

char               str[80];

LPSTR    buffer;

WORD    line_count;
DWORD    class;
char     type[5];
BYTE     *tempbuffer, **psource, **pdest;
BYTE     *filebuffer, *tempfilebuffer, *savebuffer;

// DWORD    pixel_count;
int      i, shift;
int n;
long l;

short    bytes_collected;
char     GIF_signature[] = "GIF87a";

/***
typedef  unsigned long  ID;
typedef  BYTE           Masking;
typedef  BYTE           Compression;
*****/

#define UGetByte() (*source++)
#define UPutByte(c) (*dest++ = (c))

static  short    maxhx=0;

BYTE NibblePattern[2] = { 0xF0, 0x0F };
short    err;



/* 
   Fetch the next Pixel value and return. Depending upon the BitsPixel2 value
   more than one bits are sigificant in the byte return.  Since the input
   file contain index to color palette, which is identical to the GIF
   color format, all we need to do is to return the index value.

   RETURN 
      -1    EOF, no more scanline
      other Byte value returned

*/
short Read_Pixel()
   {
   register char     pixel;
/*   register short    plane2;
   register BYTE     *buf, mask;
*/
/*
   char              str[ 20 ];
*/
   if ( pixrow2 >= bmihdr.biHeight ) 
      return -1;                     // no more input scanline

   pixel = 0;

   // retrieve the byte value in the scanline buffer */


   switch ( bmihdr.biBitCount )
      {
      case 1 :
         // obtain next bit value based upon current pixel location
         pixel = (buffer[pixcol2/8 ] & BitPatternOr[ pixcol2%8 ] ) ? 1 : 0;
         break;

      case 4 :
         // obtain next nibble based upon current pixel location
         pixel = (buffer[ pixcol2/2 ] & NibblePattern[ pixcol2%2 ])
                  >> ( pixcol2%2 ? 0 : 4 );
         break;

      case 8 :
         // return the next byte
         pixel = buffer[ pixcol2 ];
         break;

      default :
         err = HSI_EC_UNSUPPORTED;
         goto cu0;
      }

/* ---------------------

   if ( BitsPixel2 == 8 )
      pixel = buffer[ pixcol2 ];
   else
      buf = &buffer[ pixcol2 >> 3 ]; 

   mask = 1 << (7 - (pixcol2 & 7)); // mask the bit position within the byte 

   for ( plane2 = bmhdr.bmPlanes-1; plane2 >= 0 ; plane2--)
      {
      if ( *buf & mask ) pixel |= 1 << plane2;
      buf += bmhdr.bmWidthBytes;
      }
  ---------------------- */

   pixcol2++;

   if ( pixcol2 >= bmihdr.biWidth )
      {

      if (szOption2 && szOption2->Disp)       
          {
          static int cline;
          int        ii;

          ii = (int)((DWORD) line_count * 100L / (DWORD)bmihdr.biHeight);

          if (ii !=cline)
              {
              cline = ii;
              err=(*(szOption2->Disp))(cline);
              if (err) goto cu0;
              }
          }
   
      line_count++;    
      pixcol2 = 0;

       // rewind one scanline 

       n = fseek ( Infile, -1L * (long)nWidthBytes, 1 );
       if (n!= 0)
	   return -1;

       // read next scanline data. Return if no more data

       if ( lfread( buffer, 1, (DWORD)nWidthBytes, Infile ) <= 0 )   
           return -1;

       // rewind to previsou location

       fseek ( Infile, -1L * (long)nWidthBytes, 1 );

/* ----------------------------------------------
      if ( fInterlace2 )
         {
         pixrow2 += row_disp[interlace_pass];

         if (pixrow2 >= bmhdr.bmHeight)
               {
               interlace_pass++;
               pixrow2 = base_row[interlace_pass];
               }
         }
 ------------------------------------------------ */

      pixrow2++;
      }

//   pixel_count--;

   cu0:

   return pixel & 0x00FF;
   }


/*
 * ABSTRACT:
 *    The compression algorithm builds a string translation table that maps
 *    substrings from the input string into fixed-length codes.  These codes
 *    are used by the expansion algorithm to rebuild the compressor's table
 *    and reconstruct the original data stream.  In it's simplest form, the
 *    algorithm can be stated as:
 *
 *        "if <w>k is in the table, then <w> is in the table"
 *
 *    <w> is a code which represents a string in the table.  When a new
 *    character k is read in, the table is searched for <w>k.  If this
 *    combination is found, <w> is set to the code for that combination
 *    and the next character is read in.  Otherwise, this combination is
 *    added to the table, the code <w> is written to the output stream and
 *    <w> is set to k.
 *
 *    The expansion algorithm builds an identical table by parsing each
 *    received code into a prefix string and suffix character.  The suffix
 *    character is pushed onto the stack and the prefix string translated
 *    again until it is a single character.  This completes the expansion.
 *    The expanded code is then output by popping the stack and a new entry
 *    is made in the table.
 *
 *    The algorithm used here has one additional feature.  The output codes
 *    are variable length.  They start at a specified number of bits.  Once
 *    the number of codes exceeds the current code size, the number of bits
 *    in the code is incremented.  When the table is completely full, a
 *    clear code is transmitted for the expander and the table is reset.
 *    This program uses a maximum code size of 12 bits for a total of 4096
 *    codes.
 *
 *    The expander realizes that the code size is changing when it's table
 *    size reaches the maximum for the current code size.  At this point,
 *    the code size in increased.  Remember that the expander's table is
 *    identical to the compressor's table at any point in the original data
 *    stream.
 *
 *    The compressed data stream is structured as follows:
 *        first byte denoting the minimum code size
 *        one or more counted byte strings. The first byte contains the
 *        length of the string. A null string denotes "end of data"
 *
 *    This format permits a compressed data stream to be embedded within a
 *    non-compressed context.
 */
#define largest_code      4095
#define table_size        5003

struct code_entry
    {
    short prior_code;
    short code_id;
    unsigned char added_char;
    };

short code_size;
short clear_code;
short eof_code;
short min_code;
short bit_offset;
short byte_offset, bits_left;
short max_code;
short free_code;
short prefix_code;
short suffix_char;
short hx, d;
unsigned char code_buffer[256+3];
struct code_entry FAR *code_table;
short (*get_byte)();
short (*put_byte)(BYTE);
GLOBALHANDLE        hGHandle;

static void init_table( short min_code_size)
   {
   short i;

   code_size   = min_code_size + 1;
   clear_code  = 1 << min_code_size;
   eof_code    = clear_code + 1;
   free_code   = clear_code + 2;
   max_code    = 1 << code_size;

   for (i = 0; i < table_size; i++)
      code_table[i].code_id = 0;
   }

static short flush( short n)
   {
   short i, status;

   status = (*put_byte)(n);

   if (status != 0)
       return status;
      // longjmp( recover, status );

   for (i = 0; i < n; i++)
      {
      status = (*put_byte)(code_buffer[i]);

      if (status != 0)
	  return status;
         // longjmp(recover, status);
      }
   return 0;
   }

static short 
write_code( short code ) 
   {
   long temp;
   short err;
   byte_offset   = bit_offset >> 3;
   bits_left     = bit_offset & 7;

   if ( byte_offset >= 254 )
      {
      if (byte_offset >= 256)  // this is one special case where byte_count
         byte_offset = 0xFF;   // might be 256 at this point ????

      err = flush(byte_offset);
      if (err)
	  return err;
 
      code_buffer[0]     = code_buffer[byte_offset];
      bit_offset         = bits_left;
      byte_offset     = 0;
      }

   if ( bits_left > 0 )
      {
      temp = ((long) code << bits_left) | code_buffer[byte_offset];
      code_buffer[byte_offset]   = temp;
      code_buffer[byte_offset+1] = temp >> 8;
      code_buffer[byte_offset+2] = temp >> 16;
      }
   else
      {
      code_buffer[byte_offset] = code;
      code_buffer[byte_offset + 1] = code >> 8;
      }

   bit_offset += code_size;
   }

/* write a byte to output file */
short 
Write_Byte(BYTE pbyte )
   {
   static BYTE c;
   
   c=pbyte;

   if ( fwrite( &c, 1, 1, Outfile ) <= 0 )
      {
      bytes_collected = 0;
      return HSI_EC_DSTCANTWRITE;
      }

   bytes_collected++;
   return 0;
   }   

/*
 * FUNCTION Compress_Data( get_byte_routine, put_byte_routine)
 *          
 * PURPOSE    Compress a stream of data bytes using the LZW algorithm.
 *
 * Inputs:
 *    min_code_size
 *        the field size of an input value.  Should be in the range from
 *        1 to 9.
 *
 *    get_byte_routine
 *        address of the caller's "get_byte" routine:
 *
 *        status = get_byte();
 *
 *        where "status" is
 *            0 .. 255    the byte just read
 *            -1        logical end-of-file
 *            < -3        error codes
 *
 *    put_byte_routine
 *        address the the caller's "put_byte" routine:
 *
 *        status = put_byte(value)
 *
 *        where
 *            value    the byte to write
 *            status    0 = OK, else < -3 means some error code
 *
 * Returns:
 *     0    normal completion
 *    -1    (not used)
 *    9     insufficient dynamic memory
 *    5     bad "min_code_size"
 *    < -3    error status from either the get_byte or put_byte routine
 */
short Compress_Data(  get_byte_routine, put_byte_routine )
   short (*get_byte_routine)();
   short (*put_byte_routine)(BYTE);
   {
   short  min_code_size = bmihdr.biBitCount;
   short  err=0;
/***
   WORD   msize;
   DWORD  dwLength;
***/
   get_byte = get_byte_routine;
   put_byte = put_byte_routine;

   if (min_code_size < 2 || min_code_size > 9)
      {
      if (min_code_size == 1)
         min_code_size = 2;
      else
         {
         err = HSI_EC_UNSUPPORTED;    /* corrupted data */
         goto cu0;
         }
      }

   // allocate memory for the LZW compression code table

   code_table=(struct code_entry FAR *)malloc(
           (WORD)sizeof(struct code_entry)*table_size);

   if (!code_table)
      {
      err = HSI_EC_NOMEMORY;
      goto cu0;
      }

   /* set the point to jump to in case of error */
/**
   err = setjmp(recover);
**/
   err = 0;

longjmp_recover:

   if ( err )
      goto cu0;

   ProcCallFixedOrMovable_pascal(min_code_size,*put_byte);
   	    	    	    // record the minimum code size 

   bit_offset = 0;

   init_table  ( min_code_size );

   write_code  (clear_code);

   suffix_char = (short)ProcCallFixedOrMovable_pascal(*get_byte);

   if (suffix_char >= 0)
      {
      prefix_code = suffix_char;

      while ((suffix_char = (short)ProcCallFixedOrMovable_pascal(*get_byte)) >= 0)
         {
         hx = (prefix_code ^ suffix_char << 5) % table_size;
         d = 1;

         for (;;)
            {
            if (code_table[hx].code_id == 0)
               {
               write_code(prefix_code);
    
               d = free_code;
    
               if (free_code <= largest_code)
                  {
                  code_table[hx].prior_code = prefix_code;
                  code_table[hx].added_char = suffix_char;
                  code_table[hx].code_id = free_code;
                  free_code++;
                  }
    
               if (d == max_code)
                  {
                  if (code_size < 12)
                     {
                     code_size++;
                     max_code <<= 1;
                     }
                  else
                     {
                     write_code(clear_code);
                     init_table(min_code_size);
                     }
                  }

               prefix_code = suffix_char;
               break;
               }

            if (code_table[hx].prior_code == prefix_code &&
               code_table[hx].added_char == suffix_char)
               {
               prefix_code = code_table[hx].code_id;
               break;
               }

            hx += d;
            maxhx = max( hx, maxhx );
            d += 2;

            if (hx >= table_size)
               hx -= table_size;
            }
         }

      if (suffix_char != -1)
      {
	  err = suffix_char;
	  goto longjmp_recover;
/**
         longjmp(recover, suffix_char);
**/
      }

      write_code(prefix_code);
      }
   else 
   if (suffix_char != -1)
   {
	  err = suffix_char;
	  goto longjmp_recover;
       /***
      longjmp(recover, suffix_char);
      ****/
   }

   write_code(eof_code);

   // Make sure the code buffer is flushed 

   if (bit_offset > 0)                 
   {	    	    	    	    	    // This is one special case where
       err = flush(min(255,(bit_offset+7)/8)); // byte counter may exceed 255!!
       if (err) goto longjmp_recover;  // This happens only on certain file!
   }

   // put end-of-data byte to output file 

   err = flush(0);      
   if (err) goto longjmp_recover;

   cu0:

   if (code_table)
       _ffree(code_table);

   return err;
   }

/*
 * Function:
 *    Write the GIF signature, the screen description, and the optional
 *    color map.
 *
 * Inputs:
 *
 * Returns:
 *    0 = OK, else error code
 */
short Write_Screen_Desc (write_byte, cr, fill_color )
   short (*write_byte)(BYTE);   /* ptr to caller's byte writer */ 
   short cr;                // bits of color resolution (1..8) 
   short fill_color;        // pixel value used to fill the background 
   {
   short width=bmihdr.biWidth;     // width of image in pixels 
   short height=bmihdr.biHeight;   // height of image in pixels 
   short bp=cr;                    // bits per pixel
   short err=0;
   short i;

   // write out GIF signature 'GIF87a'
/**
      rc = (INT)ProcCallFixedOrMovable_pascal(tgt, icf, icf_code, buffer,
                                    0, *(p_wsseq->tran));
***/
   for (i = 0; i < 6; i++)
   {
      err = ProcCallFixedOrMovable_pascal(GIF_signature[i], *write_byte);
      if (err) return err;
  }

   err = ProcCallFixedOrMovable_pascal((width & 0xFF), *write_byte);
   if (err) return err;

   err = ProcCallFixedOrMovable_pascal((width >> 8), *write_byte);
   if (err) return err;

   err = ProcCallFixedOrMovable_pascal((height & 0xFF),*write_byte);
   if (err) return err;

   err = ProcCallFixedOrMovable_pascal((height >> 8), *write_byte);
   if (err) return err;

   //    err = (*write_byte)(((cr - 1) & 0x07) << 4); 

   err = (short)ProcCallFixedOrMovable_pascal((0x80 | ((cr - 1) << 4) | ((bp - 1) & 0x07)), *write_byte);

   if (err) return err;

   err = (short)ProcCallFixedOrMovable_pascal(fill_color, *write_byte);

   if (err) return err;

   err = (short)ProcCallFixedOrMovable_pascal(0, *write_byte);  /* reserved */

   if (err) return err;

   // write color map if it is color image 

   err = Write_Color_Map(cr);

   cu0 :

   return err;
   }

/*
 * Function:
 *    Write the image description and optional local color map.
 *
 * Inputs:
 *
 * Returns:
 *    0 = OK, else error code
 */
short Write_Image_Desc(write_byte,left_edge, top_edge,/*cr,*/interlaced)
   short (*write_byte)(BYTE);       /* ptr to caller's byte writer */
   short left_edge;            // (left_edge, top_edge) is the upper left 
   short top_edge;             // position in pixels of the image 
   /*short cr;               bits of color resolution (1..8) */ 
   short interlaced;           // 1 = interlace the image 
   {
   short width=bmihdr.biWidth;      // width of image in pixels 
   short height=bmihdr.biHeight;    // height of image in pixels 
   short err;

   err = (short)ProcCallFixedOrMovable_pascal(',', *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((left_edge & 0xFF), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((left_edge >> 8), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((top_edge & 0xFF), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((top_edge >> 8), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((width & 0xFF), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((width >> 8), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((height & 0xFF), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((height >> 8), *write_byte);
   if (err != 0) return err;

   err = (short)ProcCallFixedOrMovable_pascal((interlaced << 6), *write_byte);

   /* --------------- do not write local color map whatsoever -------

   if ( cmap == NULL)
      err = (short)ProcCallFixedOrMovable_pascal((interlaced << 6), *write_byte);
   else
      err = (short)ProcCallFixedOrMovable_pascal((0x80 | (interlaced << 6) | ((cr - 1) & 0x07)), *write_byte);

   if (err != 0) return err;

   if ( cmap != NULL)
      Write_Color_Map (cr);
   else

   -------------------------------------------------------------------  */
   return 0;
   }

/*
 * Function:
 *    Create a 1-image GIF image-set.  The size of the screen will be the
 *    same as the image.
 *
 * Inputs:
 * Returns:
 *    0 = OK, else error code
 */
short Create_GIF ( read_pixel, write_byte, cr, interlaced )
   short   (*read_pixel)();    /* ptr to caller's pixel reader */ 
   short   (*write_byte)(BYTE);    /* ptr to caller's byte writer */ 
   short   cr;                 // bits of color resolution (1..8) 
   short   interlaced;         // interlaced flag 
   {
   short err =0;        // return err 

 err = Write_Screen_Desc( write_byte, cr, 0 );

   if ( err ) return err;

   // do not handle local color map by passing  NULL over 

   err = Write_Image_Desc (write_byte, 0, 0,/* cr,*/ interlaced );

   if (err) return err;

   err = Compress_Data ( read_pixel, write_byte);

   if (err) return err;

   return (short)ProcCallFixedOrMovable_pascal( ';', *write_byte);
   }




/*
   Write the DIB color map to GIF file.
*/

static short 
Write_Color_Map ( int cr )
   {
   short i;

   cr = 1 << cr;

   for (i = 0; i < cr; i++)
      {
      Write_Byte(clrtbl[i].rgbRed );
      Write_Byte(clrtbl[i].rgbGreen );
      Write_Byte(clrtbl[i].rgbBlue );
      }
   return 0;
   }



/*********************************************************************

FUNCTION       HSISaveGIF( LPSTR, LPSTR,LPCNVOPTION )

PURPOSE        Convert DIB file to GIF file format

**********************************************************************/

HSI_ERROR_CODE EXPORT
HSISaveGIF( FILE * szInfile, FILE * szOutfile,LPCNVOPTION szOpt)
   {
   short    err = 0;
   short    cr;

   szOption2 = szOpt;
   
   buffer = NULL;

   // open input (DIB) and output (GIF) file
/***already opened in GEOS
   err = OpenInOutFile( szInfile, szOutfile );
   if ( err ) goto cu0;
***/

   Infile = szInfile;
   Outfile = szOutfile;

   // get file header 

   err = ReadHeaderInfo (Infile);

   if ( err ) goto cu0;

   // allocate memory for scanline buffer 

   buffer = (LPSTR)malloc(nWidthBytes+1);

   if ( !buffer )
      {
      err = HSI_EC_NOMEMORY;
      goto cu0;
      }

   if ( nColors < 0 )
       {
       err = HSI_EC_INVALIDINPUT;      // invalid input file
       goto cu0;
       }

   // GIF file does not support 24 bit image yet

   if ( nColors == 0 )
       {
       err = HSI_EC_OUTFILEUNSUPT;
       goto cu0;
       }

   // go to end of input file, since DIB file is stored backward

   n = fseek ( Infile,
           (LONG)bmfhdr.bfSize,
           0 );

   if( n != 0)
       {
	   err = HSI_EC_SRCCANTSEEK;
	   goto cu0;
       }
   n = fseek ( Infile, -1L * (long)nWidthBytes, 1 );

   if( n != 0)
       {
	   err = HSI_EC_SRCCANTSEEK;
	   goto cu0;
       }
   // read the first chunk of scanline 

   l = lfread( buffer, 1, (DWORD)nWidthBytes, Infile ) ;

   if ( l <=0)
       {
	   err = HSI_EC_SRCCANTREAD;
	   goto cu0;
       }

   // rewind one scanline

   n = fseek ( Infile, -1L * (long)nWidthBytes, 1 );
   if( n != 0)
       {
	   err = HSI_EC_SRCCANTSEEK;
	   goto cu0;
       }
   bytes_collected = 0;

   pixrow2 = 0;
   pixcol2 = 0;

//   pixel_count = (DWORD)bmihdr.biWidth*bmihdr.biHeight;

   line_count     = 0;
   fInterlace2     = FALSE;    // do not support interlaced output 

   switch ( bmihdr.biBitCount )
      {
      case 1 :
         cr = 1;       // should this be 0 ?
         break;
      
      case 4 :
         cr = 4;
         break;

      case 8 :
         switch (nColors)
           {
           case 32 :
               cr = 5;
               break;

           case 64 :
               cr = 6;
               break;

           case 128 :
               cr = 7;
               break;

           default :
               cr = 8;
               break;
               }
         break;

      default :
         err = HSI_EC_UNSUPPORTED;
         goto cu0;
      }

   err = Create_GIF (  Read_Pixel,  
                       Write_Byte, 
                       cr, 
                       fInterlace2 );

   cu0:

   if (buffer)
       _ffree(buffer);
/*
   CloseInOutFile();
*/
   if (!err && szOption2 && szOption2->Disp)
       (*(szOption2->Disp))(100);

   return err;
   }




/*
   Decide how many colors are there in this DIB file
*/

