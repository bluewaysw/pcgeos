/* srccore/sestring.h
 *
 * Defines for JavaScript string and buffer internal types.
 */

/* (c) COPYRIGHT 2000              NOMBAS, INC.
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

#ifndef _SRCCORE_SESTRING_H
#define _SRCCORE_SESTRING_H

#if defined(__cplusplus)
   extern "C" {
#endif


/* These are the possible flag values in the seString flag field */

#define STR_CONSTANT    0x01
   /* if it is a constant, it needs to be copied
    * when trying to write to it (to support legacy
    * ScriptEase behavior.) Basically it is a
    * 'copy on write' flag. This is needed to allow
    * ScriptEase cfunction string modification, such as
    * str[0] = 'a';
    */
#define STR_MARKED      0x02
   /* for garbage collection */


/* Store the actual data for a string (or buffer) */
struct seString
{
   struct seString *prev;     /* Linked list of all strings on the system */

#  if JSE_MEMEXT_STRINGS==0
      void * stringdata;   /* data, either string or buffer */
#  else
      jsememextHandle stringdata;   /* data, either string or buffer */
#  endif
   JSE_POINTER_UINDEX length;       /* length in chars (so for unicode strings, length in
                               * bytes is 2x this value
                               */
   JSE_POINTER_UINDEX zoffset;      /* where the 'true' 0 of the string is, needed because
                               * strings can be expanded 'to the left', and we do not
                               * have access immediately to all variables referring to
                               * it to go update all of their offsets. Sigh.
                               */

#  if defined(JSE_MBCS) && (JSE_MBCS!=0)
   JSE_POINTER_UINDEX bytelength;   /* physical version of the same for MBCS optimizations */
#  endif

   uword8 flags;
};
typedef struct seString *seString;


#if JSE_MEMEXT_STRINGS==0

   /* Get a readable version of the string's data, cannot write to
    * this. All writes are done by freeing the old one and putting
    * a new one back. Some are #ifdefed so that we do write it
    * if JSE_MEMEXT_STRINGS==0, but not if ==1
    */
#  define SESTRING_GET_DATA(s) ((s)->stringdata)
   /* Put the given data into the seString. The data is allocated, so
    * if you don't use it (copy it say), you'll need to free the
    * input.
    */
#  define SESTRING_UNGET_DATA(s,d)
#  define SESTRING_PUT_DATA(s,d,l) ((s)->stringdata = (d))
   /* Free the given seString's data */
#  define SESTRING_FREE_DATA(s) jseMustFree((s)->stringdata)

#else

#  define SESTRING_GET_DATA(s) jsememextLockRead((s)->stringdata,jseMemExtStringType)
#  define SESTRING_UNGET_DATA(s,d) jsememextUnlockRead((s)->stringdata,(d),jseMemExtStringType)
   /* The store moves the memory elsewhere, so we must free the original pointer */
#  define SESTRING_PUT_DATA(s,d,l) ((s)->stringdata = jsememextStore((d),(l),jseMemExtStringType),jseMustFree((void *)d))
#  define SESTRING_FREE_DATA(s) jsememextFree((s)->stringdata,jseMemExtStringType)

#endif


/* Create a new seString structure with the given memory already ready for it */
#if defined(JSE_MBCS) && (JSE_MBCS!=0)
   struct seString * NEAR_CALL sestrCreateAllocated(struct Call *call,const void *mem,JSE_POINTER_UINDEX len,
                                           JSE_POINTER_UINDEX bytelen,jsebool buffer);
   struct seString * NEAR_CALL sestrCreate(struct Call *call,const void *mem,JSE_POINTER_UINDEX len,
                                  JSE_POINTER_UINDEX bytelen);
   /* Buffers are byte oriented, so len==bytelen */
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      struct seString * NEAR_CALL sestrCreateBuffer(struct Call *call,const void *mem,JSE_POINTER_UINDEX len);
#  endif
#else
   struct seString * NEAR_CALL sestrCreateAllocated(struct Call *call,const void *mem,JSE_POINTER_UINDEX len,
                                           jsebool buffer);
   seString NEAR_CALL sestrCreate(struct Call *call,const void *mem,JSE_POINTER_UINDEX len);
#  if defined(JSE_TYPE_BUFFER) && (0!=JSE_TYPE_BUFFER)
      seString NEAR_CALL sestrCreateBuffer(struct Call *call,const void *mem,JSE_POINTER_UINDEX len);
#  endif
#endif


/* Make the given string a constant */
#define SESTR_MAKE_CONSTANT(s) ((s)->flags |= STR_CONSTANT)
#define SESTR_IS_CONSTANT(s) (((s)->flags & STR_CONSTANT)!=0)
#define SESTR_MARK(s) ((s)->flags |= STR_MARKED)
#define SESTR_UNMARK(s) ((s)->flags &= ~STR_MARKED)
#define SESTR_MARKED(s) (((s)->flags & STR_MARKED)!=0)

#if defined(__cplusplus)
   }
#endif

#endif
