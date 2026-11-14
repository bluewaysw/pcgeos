/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  wwHex.h
 *
 * AUTHOR:  	  Allen Yuen: Jul 27, 1998
 *
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	allen   	7/27/98   	Initial version
 *
 * DESCRIPTION:
 *
 *	HEX-encode and HEX-decode module, for use with URI's.
 *
 *	$Id: //depot/pcgeos/CInclude/WWW2/WW2Core/ww2Hex.h#1 $
 *
 ***********************************************************************/
#ifndef _WWHEX_H_
#define _WWHEX_H_

    //////////
    //
    // Encode encodes bufferToCode so it is safe to be combined 
    // into a URI. Note that this API must not be called on a URI
    // as that would encode reserved chars in the URI not meant to be
    // encoded. 
    //
    // For single byte encoding is done according to RFC1738 which recommends
    // encoding the following octets in their hex values preceded
    // by %. There is no double byte encoding version.
    //
    //  - No corresponding graphics US-ASCII.
    //        octets 0x80-0xFF, 00-0x1F, and 0x7F.
    //  - Unsafe.
    //        octets 0x20, "<", ">", """, "#", "%",
    //        "{", "}", "|", "\", "^", "~", "[", "]", "`".
    //  - Reserved.
    //        octets ";", "/", "?", ":", "@", "=", "&", "+".
    //
    // Parameters_
    //
    // [in]  bufferToCode  That which is to be encoded for inclusion in a URI.
    // [in]  inBufferSize
    // [out] bufferCoded   This buffer size must be equal to 
    //                      3*(inBufferSize)+1.
    //
    // Return_value_ The number of bytes in bufferCoded.
    //
    // Status_ Functional
    //
    static word WWHexEncode(const byte *bufferToCode,
                         word inBufferSize, 
                         char *bufferCoded);  

    //////////
    //
    // Decode hex encoded data to octets.
    //
    // These function decode data which was encoded as in the corresponding
    // Encode function. See RFCs 2044 (page 3) and 2070 (pages 16 & 17)
    // for details.
    //
    // Parameters_
    //
    // [in]  bufferCoded   Pointer to the string to convert.
    // [in]  inBufferSize  The number of bytes to decode from bufferCoded.
    // [out] bufferPlain   Contains decoded data. This buffer size
    //                     must be equal to (inBufferSize+1).
    // 
    // Return_value_ Number of bytes decoded in bufferPlain.
    //
    // Status_ Functional
    //
    static word WWHexDecode(const char *bufferCoded,
                         word inBufferSize,
                         byte *bufferPlain);

    //////////
    //
    // WWHexEncodePtr is equivalent to WWHex::EncodePtr
    //
#define WWHexEncodePtr(bufferToCode, inBufferSize, bufferCoded) \
    WWHexEncode(bufferToCode, inBufferSize, bufferCoded)

    //////////
    //
    // WWHexDecodePtr is equivalent to WWHex::DecodePtr
    //
#define WWHexDecodePtr(bufferCoded, inBufferSize, bufferPlain) \
    WWHexDecode(bufferCoded, inBufferSize, bufferPlain)

#endif /* _WWHEX_H_ */
