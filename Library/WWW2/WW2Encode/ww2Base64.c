/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1998.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		wwbase64.c

AUTHOR:		Allen Yuen, Jul 27, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	allen   	7/27/98   	Initial version

DESCRIPTION:

	Base64-encode and Base64-decode modules.

	$Id: //depot/pcgeos/Library/WWW2/WW2Encode/ww2Base64.c#1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <geos.h>
#include <WWW2/WW2Core/ww2Base64.h>

const char wwBase64Six2pr[64] = {  /* 6 bits to 8-bit printable char table */
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
    'a','b','c','d','e','f','g','h','i','j','k','l','m',
    'n','o','p','q','r','s','t','u','v','w','x','y','z',
    '0','1','2','3','4','5','6','7','8','9','+','/'
};

/*
 * Initially pr2six table is not initialized. It will be initialized
 * when we first call Decode.
 */
unsigned char wwBase64Pr2six[256] = {0}; 
Boolean wwBase64Pr2sixNeedsInitialize = TRUE;

//--------------------------------------------------------------------------
// WWBase64Encode
//--------------------------------------------------------------------------
//
// DESCRIPTION:     Encode a single line of binary data to the base64 std 
//                  format that uses only printing ASCII characters (but 
//                  takes up 33% more bytes).
//
// SCOPE:           PUBLIC
//
// RETURN:          number of bytes successfully encoded, bufferCoded contains
//                  the coded line. The first 4 * inBufferSize / 3
//                  bytes contain printing ASCII chars representing those 
//                  binary bytes. The may include one or two '=' chars used
//                  as padding at the end. The last byte is a zero byte (as
//                  null-terminator).
//
// REVISION HISTORY:
//      Name    Date        Description
//      ----    ----        -----------
//      kkee    12/ 6/96    Initial Revision
//      jsenior 11/18/97    New Sokoto Port.
//
//--------------------------------------------------------------------------
word 
WWBase64Encode(const byte *bufToCode, word nbytes, char *bufCoded)
{
#define ENC(c) wwBase64Six2pr[c]

    char *start;
    word i;

    if (!bufToCode || !nbytes || !bufCoded) return 0;

    start = bufCoded;
    
    for (i=0; i<nbytes; i += 3) {
	*(bufCoded++) = ENC(*bufToCode >> 2);             /*c1*/
	*(bufCoded++) = ENC(((*bufToCode << 4) & 060) | 
			  ((bufToCode[1] >> 4) & 017)); /*c2*/
	*(bufCoded++) = ENC(((bufToCode[1] << 2) & 074) | 
			  ((bufToCode[2] >> 6) & 03));  /*c3*/
	*(bufCoded++) = ENC(bufToCode[2] & 077);          /*c4*/
	
	bufToCode += 3;
    }
    
    /* 
     * If nbytes was not a multiple of 3, then we have encoded too
     * many characters.  Adjust appropriately.
     */
    if(i == nbytes+1) {
	/* There were only 2 bytes in that last group */
	bufCoded[-1] = '=';
    } else if (i == nbytes+2) {
	/* There was only 1 byte in that last group */
	bufCoded[-1] = '=';
	bufCoded[-2] = '=';
    }
    *bufCoded = '\0';

    i = bufCoded - start;

    return i;
} /* End of WWBase64Encode. */

//--------------------------------------------------------------------------
// WWBase64Decode
//--------------------------------------------------------------------------
//
// DESCRIPTION:     Decode an ASCII-encoded buffer back to its original
//                  binary form.
// SCOPE:           PUBLIC
// RETURN:          The number of binary bytes decoded.        
//
// IMPLEMENTATION:  
//
// REVISION HISTORY:
//      Name    Date        Description
//      ----    ----        -----------
//      kkee    1/23/97     Initial Revision
//    jsenior   11/18/97    New Sokoto Port.
//
//--------------------------------------------------------------------------
word 
WWBase64Decode(const char *bufferCoded, word inbufsize, 
                 byte *bufferPlain, word outbufsize)
{
/* single character decode */
#define DEC(c) wwBase64Pr2six[(int)c]
#define MAXVAL 63

   word nbytesdecoded;
   sword j;
   register int nprbytes;
   register const char *bufin = bufferCoded;
   register byte *bufout = bufferPlain;

   /* 
    * If this is the first call, initialize the mapping table.
    * This code should work even on non-ASCII machines.
    */
   if(wwBase64Pr2sixNeedsInitialize) {
      wwBase64Pr2sixNeedsInitialize = FALSE;
      for(j=0; j<256; j++) wwBase64Pr2six[j] = MAXVAL+1;
      for(j=0; j<64; j++) wwBase64Pr2six[(int)wwBase64Six2pr[j]] = (unsigned char) j;
   }

   /* Figure out how many characters are in the input buffer.
    * If this would decode into more bytes than would fit into
    * the output buffer, adjust the number of input bytes downwards.
    */
   while(wwBase64Pr2six[(int)*(bufin++)] <= MAXVAL);
   nprbytes = bufin - bufferCoded - 1;
   nprbytes = (nprbytes < inbufsize) ? nprbytes : inbufsize;
   nbytesdecoded = ((nprbytes+3)/4) * 3;
   if(nbytesdecoded > outbufsize)
       nprbytes = (outbufsize*4)/3;

   bufin = bufferCoded;
   while (nprbytes > 0) {
      *(bufout++) = (unsigned char) (DEC(*bufin) << 2 | DEC(bufin[1]) >> 4);
      *(bufout++) = (unsigned char) (DEC(bufin[1]) << 4 | DEC(bufin[2]) >> 2);
      *(bufout++) = (unsigned char) (DEC(bufin[2]) << 6 | DEC(bufin[3]));
      bufin += 4;
      nprbytes -= 4;
   }
   
   if(nprbytes & 03) {
      if(wwBase64Pr2six[(int)bufin[-2]] > MAXVAL) {
         nbytesdecoded -= 2;
      } else {
         nbytesdecoded -= 1;
      }
   }

   return(nbytesdecoded);
} /* End of WWBase64Decode. */
