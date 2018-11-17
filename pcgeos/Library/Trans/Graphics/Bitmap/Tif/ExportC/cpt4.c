/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cpt4.c

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
	

	$Id: cpt4.c,v 1.1 97/04/07 11:27:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
/*
       ----- Copyright(c), 1990-91  Halcyon Software -----


    cpt4.c

Description

    Compression algorithm according to CCITT group 3 table T4

*/
#include "hsimem.h"
#include "hsierror.h"


#include <Ansi/stdio.h>
#include "hsidib.h"

#include <Ansi/string.h>

#define    BLACK    1
#define    WHITE    0;

#define    FLUSH    1
#define    NOFLUSH    0

#include "ccitt.h"

/* function prototypes */

int FAR _NextBlack      (LPSTR, int, int);
int FAR _NextWhite      (LPSTR, int, int);
int cPutBits           (LPSTR dst, int pos, T4 FAR *codeptr);
int cEncodeT4          (LPSTR dst, int bitpos, int bitcnt, T4 FAR *table);



/*
   Put the byte value in the buffer according to bit offset
   and number of bits.
*/

WORD WORDPatternAND[]= 
   {
   0x8000, 0x4000, 0x2000, 0x1000, 
   0x0800, 0x0400, 0x0200, 0x0100,
   0x0080, 0x0040, 0x0020, 0x0010,
   0x0008, 0x0004, 0x0002, 0x0001
   };

int cPutBits( LPSTR dst, int pos, T4 FAR *codeptr )
   {
   int i;
   int j;

   j = 16 - codeptr->bc;

   for ( i=0; i < codeptr->bc ; i++ )
      {
      if ( codeptr->cd & (WORD)WORDPatternAND[ j + i ] )
          dst[(pos+i)/8] |= BitPatternOr[(pos+i)%8];
      }
    
   return (pos+codeptr->bc);
   }


int 
cEncodeT4( LPSTR dst, int bitpos, int bitcnt, T4 FAR *table)
   {
    T4  FAR  *ptr;
    int   terminator, makeup;

    // Encoding the scan line    

    terminator = bitcnt & 0x3f;
    makeup = 0;

    if ( bitcnt >= 64 ) 
       makeup = bitcnt/64 + 63;

    // encode the makeup code first if any    

    if ( makeup ) 
       {
       ptr = table + makeup;
       bitpos = cPutBits( dst, bitpos, ptr );
       }
    
    // then the terminator code which is a must    

    ptr = table + terminator;
    bitpos = cPutBits( dst, bitpos, ptr );
    return( bitpos );
   }



/*
   Compress one scanline data to CCITT G3 format. Make sure the dst
   is zapped before coming to this routine, since it might contain
   left over from previous run.
*/

int 
cpt4 ( 
   LPSTR dst,        // output buffer
   LPSTR src,        // input buffer
   WORD  maxbits )   // image width in pixel
   {

   int    crnsrc, nxtsrc/*, last*/;
   int    nxtdst=0, i;
   /*BYTE    zero=0x00;*/

   crnsrc = nxtsrc = 0;

   for (i=0; i < (maxbits+7)/8;i++)    // invert the input string, since
       src[i] = ~src[i];               // ccitt treat 1 as black, 0 as
                                       // white
   while ( 1 ) 
      {
      if ( nxtsrc < maxbits ) 
          {
          // get the WHITE run
          nxtsrc = _NextBlack( src, crnsrc, maxbits );

          // write out the WHITE run code word
          nxtdst = cEncodeT4( dst, nxtdst, nxtsrc-crnsrc,(T4 FAR*)wht );

          crnsrc = nxtsrc;
          } 
      else 
          {
          // no more bit to process
          /*last = WHITE;*/
          break;
          }

      if ( nxtsrc < maxbits ) 
          {
          // do the BLACK run
          nxtsrc = _NextWhite( src, crnsrc, maxbits );

          // write out the BLACK run code word
          nxtdst = cEncodeT4( dst, nxtdst, nxtsrc-crnsrc,(T4 FAR *)blk );

          crnsrc = nxtsrc;
          } 
      else 
          {
          /*last = BLACK;*/
          break;
          }
      }

/*  donot append EOL if maxbits has reached
   if ( nxtsrc != maxbits )
      nxtdst = cPutBits( dst, nxtdst, (wht+whtcnt-1) );
*/

   return( nxtdst );

   }
