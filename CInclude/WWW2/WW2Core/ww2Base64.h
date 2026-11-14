/***********************************************************************
 *
 *	Copyright (c) Geoworks 1998.  All rights reserved.
 *	GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  wwbase64.h
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
 *	Base64-encode and Base64-decode module.
 *
 *	$Id: //depot/pcgeos/CInclude/WWW2/WW2Core/ww2Base64.h#1 $
 *
 ***********************************************************************/
#ifndef _WWBASE64_H_
#define _WWBASE64_H_

    //////////
    //
    // Encode a single line of binary data to the base64 std 
    // format that uses only printing ASCII characters (but 
    // takes up 33% more bytes).
    //
    // Parameters_
    //
    // [in]  bufferToCode  Data to encode
    // [in]  inBufferSize  Size of buffer or ammount of bufferToCode to encode.
    // [out] bufferCoded   bufCoded contains the coded line. 
    //                     The first 4*nbytes/3 bytes contain printing
    //                     ASCII chars representing those binary
    //                     bytes. These may include one or two '=' chars used
    //                     as padding at the end. The last byte is a
    //                     zero byte (as null-terminator). Hence the
    //                     buffer size must be at least
    //                     4*inBufferSize/3+1.
    //
    //
    // Return_value_ The number of ASCII chars in bufferCoded
    //               successfully encoded.
    //
    // Status_ Funnctional
    //
    static word WWBase64Encode(const byte *bufferToCode,
                         word inBufferSize,
                         char *bufferCoded);

    //////////
    //
    // Decodes an ASCII-encoded buffer back to its original binary form.
    // 
    // Parameters_
    //
    // [in]  bufferCoded    Points to a base64 encoded string. It is 
    //                      terminated by any character not in pritable range.
    // [in]  inBufferSize   Number of bytes in bufferCode to decode. For 
    //                      proper decoding, must be multiple of 4.
    // [out] bufferPlain    Points to the output buffer; must be big 
    //                      enough to hold the decoded (generally shorter
    //                      than the encoded string) plus as many as two
    //                      extra bytes used during the decoding
    //                      process.
    // [in] outBufferSize   The bufferPlain size. To completedly
    //                      decode inBufferSize, outBufferSize must be
    //                      the same as inBufferSize.
    //
    // Return_value_ The number of binary bytes decoded.
    //
    // Status_ Functional
    //
    static word WWBase64Decode(const char *bufferCoded,
                         word inBufferSize,
                         byte *bufferPlain,
                         word outBufferSize);

    //////////
    //
    // WWBase64EncodePtr is equivalent to WWBase64::EncodePtr
    //
#define WWBase64EncodePtr(bufferToCode, inBufferSize, bufferCoded) \
    WWBase64Encode(bufferToCode, inBufferSize, bufferCoded)

    //////////
    //
    // WWBase64DecodePtr is equivalent to WWBase64::DecodePtr
    //
#define WWBase64DecodePtr(bufferCoded, inBufferSize, bufferPlain, outBufferSize) \
    WWBase64Decode(bufferCoded, inBufferSize, bufferPlain, outBufferSize)

#endif /* _WWBASE64_H_ */
