/* seblob.h
 */

/* (c) COPYRIGHT 1993-98           NOMBAS, INC.
 *                                 64 SALEM ST.
 *                                 MEDFORD, MA 02155  USA
 *
 * ALL RIGHTS RESERVED
 *
 * This software is the property of Nombas, Inc. and is furnished under
 * license by Nombas, Inc.; this software may be used only in accordance
 * with the terms of said license.  This copyright notice may not be removed,
 * modified or obliterated without the prior written permission of Nombas, Inc.
 *
 * This software is a Trade Secret of Nombas, Inc.
 *
 * This software may not be copied, transmitted, provided to or otherwise made
 * available to any other person, company, corporation or other entity except
 * as specified in the terms of said license.
 *
 * No right, title, ownership or other interest in the software is hereby
 * granted or transferred.
 *
 * The information contained herein is subject to change without notice and
 * should not be construed as a commitment by Nombas, Inc.
 */

#ifndef __SEGNBLOB_H
#define __SEGNBLOB_H

#if defined(JSE_SELIB_BLOB_GET)    || \
    defined(JSE_SELIB_BLOB_PUT)    || \
    defined(JSE_SELIB_BLOB_SIZE)   || \
    defined(JSE_CLIB_FREAD)        || \
    defined(JSE_CLIB_FWRITE)       || \
    defined(JSE_SELIB_PEEK)        || \
    defined(JSE_SELIB_POKE)        || \
    defined(JSE_SOCKET_READ)       || \
    defined(JSE_SOCKET_WRITE)      || \
    defined(JSE_SELIB_DYNAMICLINK)

enum {
   blobUWORD8      = -1,
   blobSWORD8      = -2,
   blobUWORD16     = -3,
   blobSWORD16     = -4,
   blobUWORD24     = -5,
   blobSWORD24     = -6,
   blobUWORD32     = -7,
   blobSWORD32     = -8,
#  if defined(__JSE_MAC__)  /* These are new Mac Pascal string types */
      blobSTR255    = -9,
      blobSTR63     = -10,
      blobSTR31     = -11,
#     if (0==JSE_FLOATING_POINT)
         blobLAST_DATUM_TYPE = blobSTR31
#     else
         blobFLOAT32 = -12,
         blobFLOAT64 = -13,
         blobFLOAT80 = -14,
         blobLAST_DATUM_TYPE = blobFLOAT80
#     endif
#  else
#     if (0==JSE_FLOATING_POINT)
         blobLAST_DATUM_TYPE = blobSWORD32
#     else
         blobFLOAT32     = -9,
         blobFLOAT64     = -10,
#        if defined(_MSC_VER)
            blobLAST_DATUM_TYPE = blobFLOAT64
#        else
            blobFLOAT80     = -11,
            blobLAST_DATUM_TYPE = blobFLOAT80
#        endif
#     endif
#  endif
};

jsebool NEAR_CALL blobBigEndianMode(jseContext jsecontext);
jsebool NEAR_CALL blobGet(jseContext jsecontext,jseVariable GetVar,
                          ubyte _HUGE_ *mem,jseVariable TypeOrLenVar,
                          jsebool BigEndianState);
jsebool NEAR_CALL blobPut(jseContext jsecontext,ubyte _HUGE_ *mem,JSE_POINTER_UINDEX datalen,
                          jseVariable TypeOrLenVar,jseVariable DataVar,
                          jsebool BigEndianState);
   /* If error then jseLibErrorPrintf() and will return False; else return True */
   /* TypeOrLenVar MUST be OK and datalen correct */
jsebool NEAR_CALL blobDataTypeLen(jseContext jsecontext,jseVariable TypeOrLenVar,
                                  JSE_POINTER_UINDEX *DataLength);
   /* set DataLength to size of this data type, whether a pre-defined
    * type or a byte array buffer size.
    * Return True for success, else False and jseLibErrorPrintf() will have been called
    * This is used to get length and to verify TypeOrLenVar is valid
    */
jseVariable blobCreateBLobType(jseContext jsecontext, long value);
extern CONST_DATA(jsecharptrdatum) blobInternalDataMember[];

extern CONST_DATA(jsecharptrdatum) blobInternalDataMember[];
jsebool NEAR_CALL isBlobType( jseContext jsecontext, jseVariable var );

#endif

void InitializeLibrary_Blob(jseContext jsecontext);

#endif
