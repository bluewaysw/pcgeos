/* selibcom.h
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

#ifndef __SELIBCOM_H
#define __SELIBCOM_H

#  ifndef NDEBUG
#    define JSE_DEBUG_FEEDBACK(val) (val)
#  endif

/* Yes, that is supposed to be a jsechar *, not a jsecharptr */
jsebool GetJsecharFromStringOrNumber(jseContext jsecontext,jseVariable var,jsechar * value);

#if defined(JSE_LANG_TOSOURCE)     \
 || defined(JSE_ARRAY_TOSOURCE)    \
 || defined(JSE_STRING_TOSOURCE)   \
 || defined(JSE_FUNCTION_TOSOURCE) \
 || defined(JSE_BOOLEAN_TOSOURCE) \
 || defined(JSE_NUMBER_TOSOURCE) \
 || defined(JSE_OBJECT_TOSOURCE)   \
 || defined(JSE_BUFFER_TOSOURCE)   \
 || defined(JSE_DATE_TOSOURCE)     \
 || defined(JSE_DSP_ANY)

#  define JSE_TOSOURCE_HELPER

#endif

#  if defined(JSE_TOSOURCE_HELPER)  \
   || defined(JSE_DSP_ANY)          \
   || defined(JSE_EXCEPTION_ANY)

      struct dynamicBuffer {
         jsecharptr buffer;
         size_t allocated;
         size_t used;
      };
#     define dynamicBufferGetString(buf)  ((buf)->buffer)
      void dynamicBufferInit( struct dynamicBuffer * buf );
      void dynamicBufferTerm( struct dynamicBuffer * buf );
      void dynamicBufferAppend( struct dynamicBuffer * buf, const jsecharptr text );
      void dynamicBufferAppendLength(struct dynamicBuffer * buf, const jsecharptr text,
                                     size_t length );

#  endif

#  if defined(JSE_TOSOURCE_HELPER)

      jseVariable jseConvertToSource(jseContext jsecontext, jseVariable var);
      struct dynamicBuffer jseEscapeString( const jsecharptr source,
                                            JSE_POINTER_UINDEX length);

#  endif

#  if defined(__JSE_UNIX__)
#     include "common/setxtlib.h"
#  elif defined(__JSE_MAC__) || defined(__JSE_GEOS__)
#     include "setxtlib.h"
#  elif defined(__JSE_390__)
#     include "SETXTLIH"
#  else
#     include "common\setxtlib.h"
#  endif

#endif
