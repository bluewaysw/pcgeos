/* DirParts.c   Find parts of a directory specification
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

#include "jseopt.h"
#if defined(__JSE_GEOS__)
#  include <Ansi/assert.h>
#  include <Ansi/stdlib.h>
#  include <Ansi/string.h>
#else
#  if !defined(__JSE_WINCE__) && !defined(__JSE_IOS__)
#    include <assert.h>
#  endif
#  include <stdlib.h>
#  include <string.h>
#endif

#include "jseopt.h"
#if !defined(__JSE_UNIX__) && !defined(__JSE_MAC__) \
 && !defined(__IBMCPP__) && !defined(__JSE_WINCE__) \
 && !defined(__JSE_390__) && !defined(__JSE_NWNLM__) \
 && !defined(__JSE_GEOS__)
   #include <io.h>
#endif
#include "dirparts.h"


   void
FileNameParts( const jsecharptr const FileName,
               jsecharptr *dir, uint *dirlen,
               jsecharptr *name, uint *namelen,
               jsecharptr *ext, uint *extlen )
{
#if defined(__JSE_390__)

   /* 390 pseudo-directory rules are these; everything after the last dot
    * is the "Extension", if there is only one dot then everything prior to
    * the last dot is the name, but if more then one dot everything before teh
    * next-to-last dot is directory.  For example:
    *   "a.b.test.jse"  dir = "a.b.", name = "test", ext = ".jse"
    */
   jsecharptr dot;

   assert( NULL != FileName );

   *dir = (jsecharptr )FileName;  /* default */
   *dirlen = 0;
   *name = (jsecharptr )FileName; /* default */

   dot = strrchr_jsechar(FileName,'.');
   if ( NULL == dot )
   {
      *namelen = strlen_jsechar(FileName);
      *ext = (jsecharptr )FileName + *namelen;
      *extlen = 0;
   }
   else
   {
      jsecharptr nm;
      *extlen = strlen_jsechar(*ext = dot);
      *namelen = dot - FileName; /* default if no earlier dot found */
      /* back up until we find another dot (if there is one) which will be the end
       * of the directory
       */
      for ( nm = dot - 1; FileName < nm; nm-- )
      {
         if ( '.' == *nm )
         {
            /* this is the end of the directory part */
            *name = nm + 1;
            *namelen = dot - *name;
            *dirlen = *name - FileName;
            break;
         }
      }
   }

#else

   /* Figure out char_to_find here */
   jsechar dir_tail;
   jsecharptr cptr;
   jsechar c;
   jsebool foundExt;

   assert( NULL != FileName );

#if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
 || defined(__JSE_DOS16__) || defined(__JSE_DOS32__) \
 || defined(__JSE_WIN16__) || defined(__JSE_GEOS__) \
 || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
   dir_tail = '\\';
#elif defined(__JSE_NWNLM__)
   /* Netware accepts DOS specifications, but it also has it's own stuff.
    * If it contains a '/', it is a netware filespec, something like:
    * OUTLAND/SYS:/NOWHERE/WHATEVER.JOE
    * Otherwise, everything up to a final : or a \ is part of the dir.
    */
   if( strchr( FileName, '/' ) != NULL )
      dir_tail = '/';
   else
      dir_tail = '\\';
#elif defined(__JSE_UNIX__)
   dir_tail = '/';
#elif defined(__JSE_MAC__)
   /* This duplicates the comparison with ':' below, but it keeps the code simpler. */
   dir_tail = ':';
#else
   #error No trailing character for directory name for this platform defined.
#endif

   *dir = (jsecharptr ) FileName;

   /* Compute position of start of name
    * Everything up to and including a final dir_tail or ':' is part of the dir.
    * By default, *name points at first char in FileName.
    */
   cptr = *name = *dir;
   *dirlen = 0;
   while ( 0 != (c=JSECHARPTR_GETC(cptr)) )
   {
      JSECHARPTR_INC(cptr);
      if ( dir_tail == c  ||  ':' == c )
      {
         *name = cptr;
      }
      (*dirlen)++;
   }

   /* Compute position of start of extension
    * Anything after and including the last '.' in name is the extension.
    * By default, *ext points at the terminating null.
    */
   cptr = *ext = *name;
   *namelen = 0;
   foundExt = False;
   while ( 0 != (c=JSECHARPTR_GETC(cptr)) )
   {
      if ( '.' == c )
      {
         *ext = cptr;
         foundExt = True;
      }
      JSECHARPTR_INC(cptr);
      (*namelen)++;
   }
   if ( foundExt )
   {
      /* found extension, reduce namelen */
      *extlen = strlen_jsechar(*ext);
      *namelen -= *extlen;
   }
   else
   {
      /* no extension, so ext is at end of string */
      *ext = cptr;
      *extlen = 0;
   }

   /* dirlen was calculated as entire length, but should
    * not include namelen or extlen
    */
   *dirlen -= (*namelen + *extlen);

#endif /* !defined(__JSE_390__) */
   return;
}

