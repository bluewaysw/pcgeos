/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dcpt4.c

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
	

	$Id: dcpt4.c,v 1.1 97/04/07 11:27:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/


/*
       ----- Copyright(c), 1990-91  Halcyon Software -----


    dcpt4.c

Description

    Decompression routine for CCITT according to table T4, 
    one dimensional.
*/

#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>   /* used for memset() */

#include "ccitt.h"

#include "tif.h"

#define    WHITE    0x0000
#define    BLACK    0xffff

WORD  colormsk;
T4    *srttbl;
int   ptncnt;


extern Image *image;


/*
   Get the next 2 byte WORD to process. We have to use a 4 bytes
   var to process the data, since they might be shifted to the
   right x number of bits.

   Rember that the byte order has to be correct. The INTEL byte
   flipping might be in the way!
*/

WORD    
Get16Bits( WORD bitpos, WORD *val, LPSTR buf )
   {

   union {
      DWORD   fourbytes;
      char    s[4];
      } tu;

    int     bytpos, bitoff;

    bytpos   = bitpos / 8;    // calc the byte and bit offset(divde by 8)    
    bitoff   = bitpos % 8;


/*  fourbytes = *(DWORD *)&buf[bytpos];
   fourbytes = fixlongnow(fourbytes);
*/
   if (image->compression==2)
       {
       tu.s[3] = buf[bytpos];
       tu.s[2] = buf[bytpos+1];
       tu.s[1] = buf[bytpos+2];
       tu.s[0] = buf[bytpos+3];
       *val = (WORD)(tu.fourbytes >> (16-bitoff));
       }
   else
       {
       tu.fourbytes = *((DWORD FAR *)&buf[bytpos]);
       *val = (WORD)(tu.fourbytes >> bitoff);
       }

   // get the word back


   return( bitoff );
   }



/*
   Look up the T4 code table from the WORD passed.
*/
T4 *Lookup( WORD wrd, int limit )
   {
   WORD    w=wrd;
   T4      *entry;

   entry = srttbl;
   
   while ( limit-- )
        {
        if (image->compression==2)
           w = wrd >> ( 16 - entry->bc);

        if ( (w & (entry->mk)) == entry->cd )
            return( entry );

        entry++;
        }

   return( 0 );
   }



void
SwitchColor()
   {
    if ( colormsk == WHITE ) 
        {
        colormsk = BLACK;
        if (image->compression==3)
           srttbl = blktbl;
        else
           srttbl = blk;
        ptncnt = blkcnt;
        } 
    else 
        {
        colormsk = WHITE;
        if (image->compression==3)
           srttbl = whttbl;
        else
           srttbl = wht;
        ptncnt = whtcnt;
        }
   }




/*
   Decopmress one compressed scan buffer to output buffer.
   Buffers are preallocated by the caller.

   LPSTR src           Source buffer that contain compressed scan line
   LPSTR dst           Target buffer to hold uncompressed scanline data
   WORD  width         Width of the scanline image in pixel
   WORD  nWidthBytes   Width of the output scanline in bytes

*/
int
dcpt4( LPSTR src, LPSTR dst, WORD width, WORD nWidthBytes )
   {
   static WORD   wrd;
   int    dpos, eolcnt, runlen, err;
   int    ret_spos;
   static int spos;
   T4     *tptr;

   dpos = 0; 
   eolcnt = 0;          /* init EOL count*/    
   runlen = 0;          /* init run length*/   

   colormsk = BLACK;    /* init color table - by force switch from */ 

   SwitchColor();       

   _fmemset((LPSTR)dst,               /* init to inverted color */
            (BYTE)~colormsk,          /* 1 is WHITE dot and 0*/
            nWidthBytes);             /* is BLACK dot*/
                                        

   do {
       /* Get the next code word to look for */ 

       err = Get16Bits  ( (WORD)spos,
                          (WORD *)&wrd,
                          (LPSTR)src );

       if (err < 0) 
           break;

       if (wrd==0) 
           {
           spos += 4;
           continue;
           }  

       /* get the run length by T4 table look up*/ 

       tptr = Lookup( wrd, ptncnt );

       if ( tptr != 0 )                   /* valid code found in table*/
           {
           if ( tptr->rl >= 0 )           /* run length is not zero*/
               {    
               runlen += tptr->rl;        /* update run length*/

               if ( tptr->rl < 64 )       /* check for the terminator*/
                   {
                   if ( colormsk == BLACK ) /* write white dots if BLACK run*/
                       {
                       int i;

                       /* mask all the zero(BLACK dots)*/

                       for ( i=0; i < runlen ; i++ )
                           {
                           int k=(dpos+i)/8;

                           if ( k >= nWidthBytes)
                               {
                               err=0;  // error condition
                               goto cu0;
                               }

                           dst[k] &= BitPatternAnd[(dpos+i)%8];
                           }
                       }
                 
                   dpos += runlen;   /* increment file offset*/
                   runlen = 0;       /* reset run length*/
                   SwitchColor();    /* change color*/
                   }
               } 
           else 
           if (tptr->rl < 0)     /* run length is -1 EOF*/
               eolcnt++;

           spos += tptr->bc;       /* increament bit count*/

           } 
       else 
           {
           if ( wrd & 0xfff )      /* cannot find code ?!
              ;
          printf( "wrd = %04x @ %d spos=%d\n", wrd, dpos, spos );
  */             
           spos++;    /* ERROR condition, try to resynch    */
           }

       /* modified CCITT does not rely upon the EOL */

       if (image->compression==2 && dpos >= width)
           break;

       } 
      while ( !eolcnt );

      /* end of While. Will exit when EOL is reached or image decompressed
       more than one scanline's worth - dpos < width*/


   cu0:

   if (image->compression == 3)    // Type 3 is true CCITT G3 Implementation
       {                           // we maintain the current bit position.
       ret_spos = spos / 8;
       spos %= 8;
       }
   else
       {
       ret_spos = (spos+7)/8;      // modified G3 align on byte boundary.
       spos     = 0;               // extra bits are discarded.
       }

   return( ret_spos );    // return how many bytes that we processed in
                          // this routine so that next time we can start
                          // at the appropriate location.
   }

