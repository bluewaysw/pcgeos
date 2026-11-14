/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1998.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	
MODULE:		
FILE:		wwHex.c

AUTHOR:		Allen Yuen, Jul 27, 1998

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	allen   	7/27/98   	Initial version

DESCRIPTION:

	Encoding for Uniform Resource Identifiers'.

	$Id: //depot/pcgeos/Library/WWW2/WW2Encode/ww2Hex.c#1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <geos.h>
#include <ec.h>
#include <WWW2/ww2mem.h>
#include <WWW2/WW2Core/ww2Hex.h>
#include <WWW2/wwMacro.h>

const char wwHexEncodeTable[17] = "0123456789ABCDEF";

//--------------------------------------------------------------------------
// WWHexEncode
//--------------------------------------------------------------------------
//
// DESCRIPTION:     Encode data so it is safe to be combined into a URI. Note
//                  that this API must not be called on a URI as that would
//                  encode reserved chars in the URI not meant to be encoded.
//
// SCOPE:           PUBLIC
//
// RETURN:          Length of buffer returned in bytes.
//
// IMPLEMENTATION:  Encoding is done according to RFC1738 which recommends
//                  encoding the following octets in their hex values preceded
//                  by %. 
//                  - No corresponding graphics US-ASCII.
//                     octets 0x80-0xFF, 00-0x1F, and 0x7F.
//                  - Unsafe.
//                     octets 0x20, "<", ">", """, "#", "%",
//                     "{", "}", "|", "\", "^", "~", "[", "]", "`".
//                  - Reserved.
//                     octets ";", "/", "?", ":", "@", "=", "&", "+".
//
// REVISION HISTORY:
//      Name        Date        Description
//      ----        ----        -----------
//      kkee        5/ 2/97     Initial Revision
//      jsenior     11/Nov/97   New Sokoto Port.
//
//--------------------------------------------------------------------------
word 
WWHexEncode(const byte *data, word inBufferSize, 
              char *encodedBuffer)
{
    if (!data || !inBufferSize) {
        return 0;
    }

    char *p=encodedBuffer;
    word len=0;
    
    for (; inBufferSize>0; inBufferSize--) {

	if ((*data >= 0x7F)  || 
	    (*data <= 0x20)  ||
	    (*data == '<')   || (*data == '>')  ||
	    (*data == '\"')  || (*data == '#')  ||
	    (*data == '%')   || (*data == '{')  ||
	    (*data == '}')   || (*data == '|')  ||
	    (*data == '\\')  || (*data == '^')  ||
	    (*data == '~')   || (*data == '[')  ||
	    (*data == ']')   || (*data == '`')  ||
	    (*data == ';')   || (*data == '/')  ||
	    (*data == '?')   || (*data == ':')  ||
	    (*data == '@')   || (*data == '=')  ||
	    (*data == '&')   || (*data == '+')  ||
	    (*data == 0x0D)  || (*data == 0x0A)) {
	    *p++ = '%';
	    *p++ = wwHexEncodeTable[(byte)((*data & 0xF0) >> 4)];
	    *p++ = wwHexEncodeTable[(byte)(*data & 0x0F)];
	    len += 3;

	} else {
	    *p++ = *data;
	    len++;
	}

	data++;
    }

    *p = 0;  /* Null-terminate encoded data */

    return len;
} /* End of WWHexEncode */

//--------------------------------------------------------------------------
// WWHexDecode
//--------------------------------------------------------------------------
//
// DESCRIPTION:     Decode hex encoded data to octet.
//
// SCOPE:           PUBLIC
//
// RETURN:          Number of bytes in the plain buffer sucessfully decoded.  
//                  
// IMPLEMENTATION:  See double byte version. It destorys the data
//                  in the input buffer. This is considerably changed from
//                  Geos.
//
// REVISION HISTORY:
//      Name        Date        Description
//      ----        ----        -----------
//      kkee        5/ 2/97     Initial Revision
//      jsenior     11/12/97    New Sokoto Port.
//--------------------------------------------------------------------------
word
WWHexDecode(const char *bufferCoded, word inBufferSize, 
              byte *bufferPlain)
{
    if (!bufferCoded || !*bufferCoded || !inBufferSize) return 0;

    PARAM_ASSERT(bufferPlain);

    char b;
    const char *p = bufferCoded;  /* p points to data to decode */
    byte *q = bufferPlain;        /* q points to decoded data */

    for (; inBufferSize>0; inBufferSize--) {
	if (*p == '%') {
	    if (*(p+1) && *(p+2)) {
		b = TOUPPER(*(p+1));
		if (b>='A' && b<='F')
		    *q = ((b-'A')+10)*16;
		else if (b>='0' && b<='9')
		    *q = (b-'0')*16;
		else break; /* Error */

		b = TOUPPER(*(p+2));
		if (b>='A' && b<='F')
		    *q += (b-'A')+10;
		else if (b>='0' && b<='9')
		    *q += (b-'0');
		else break; /* Error */
		q++; *q=0;       /* Null-terminate the result */
		p += 3;

	    } else {
		*q = *p;
		if (*(p+1)) {
		    *(q+1) = *(p+1);
		    *(q+2) = 0;  /* *(p+2) must be 0, see if condition */
		} else {
		    *(q+1) = 0;
		}
		break;
	    }
		
	} else {
	    *q++ = *p++;
	    if (q != (byte *) p) *q=0;
	}
    }

    return (q-bufferPlain);
} /* End of WWHexDecode */
