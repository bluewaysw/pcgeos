/* source.h  Determine next code card from the input string.
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

#if !defined(_SOURCE_H) && (0!=JSE_COMPILER)
#define _SOURCE_H
#if defined(__cplusplus)
   extern "C" {
#endif

#if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
struct ConditionalCompilation_
{
   jsebool ConditionHasBeenMet; /* set true first time a conditional matches */
   jsebool ConditionTrue;       /* true while in good condition; else false
                                   to ignore lines */
   struct ConditionalCompilation_ *prev;
};
#endif

#if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
struct IncludedFile
{
   struct IncludedFile *Previous;
   jsechar RootFileName[1];
      /* structure allocated big enough for file and extension,
         but not directory */
};
#endif

struct Source
{
   struct Source *prev;   /* buffer that preceded this one, and to return to */
   jsecharptr MemoryPtr;     /* trace through source text */

#  if defined(JSE_CONDITIONAL_COMPILE) && (0!=JSE_CONDITIONAL_COMPILE)
      struct ConditionalCompilation_ * ConditionalCompilation;
#  endif

#  if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
      struct IncludedFile *RecentIncludedFile;
#  endif

   /* if reading from text */
   jsecharptr AllocMemory;     /* originally allocated address, free this;
                             will be NULL if reading from a file */
   jsecharptr MemoryEnd;       /* used on source text, not when read from file,
                           * to know when NextLine() is done
                           */

#  if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
      /* if reading from file */
      struct jseToolkitAppSource sourceDesc; /* source code description */
      jsebool FileIsOpen;
#  else
      uint lineNumber;
#  endif

   /* If this source is a #define replacement, it should not generate
    * any newlines
    */
   jsebool define;
};

#if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
#  define SOURCE_LINE_NUMBER(SOURCE)  SOURCE->sourceDesc.lineNumber
#else
#  define SOURCE_LINE_NUMBER(SOURCE)  SOURCE->lineNumber
#endif

#if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
   struct Source *sourceNewFromFile(struct Call *call,struct Source *PrevSB,
                                    jsecharptr FileSpec,jsebool *Success);
#endif

struct Source *sourceNewFromText(struct Source *PrevSB,
                                 const jsecharptr const SourceText);

void sourceDelete(struct Source *src,struct Call *call);

jsebool sourceNextLine(struct Source *src,struct Call *call,
                       jsebool withinComment,jsebool *success);
   /* get the next line in source file, return True if is one, else False;
    * if there is an error then return False AND set success false AND use
    * call to print error
    */
#if defined(JSE_INCLUDE) && (0!=JSE_INCLUDE)
   jsebool sourceInclude(struct Source **source,struct Call *call);
      /* True if OK, else printed message and return False */
#endif

#define sourceGetPtr(this) ((this)->MemoryPtr)
#define sourceSetPtr(this,ptr) ((this)->MemoryPtr = (ptr))
#define sourcePrev(this) ((this)->prev)
#if defined(JSE_TOOLKIT_APPSOURCE) && (0!=JSE_TOOLKIT_APPSOURCE)
#   define SOURCE_FILENAME(this) ((this)->sourceDesc.name)
#else
#   define SOURCE_FILENAME(this) NULL
#endif

#if defined(JSE_GETFILENAMELIST) && (0!=JSE_GETFILENAMELIST)
void callAddFileName(struct Call *This,jsecharptr name);
#endif

#if defined(__cplusplus)
   }
#endif
#endif
