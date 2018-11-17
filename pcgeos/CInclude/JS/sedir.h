/* sedir.h   Directory-related library functions
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

#ifndef __XDIR_H
#define  __XDIR_H
#ifdef __cplusplus
   extern "C" {
#endif

#if defined(JSE_SELIB_DIRECTORY)

#if defined(__JSE_DOS16__) || defined(__JSE_DOS32__) \
  || defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#   if defined(_MSC_VER) && defined(__JSE_WIN32__) && !defined(__JSE_WINCE__)
#      include <dos.h>
#   endif
#   define  FATTR_RDONLY      _A_RDONLY
#   define  FATTR_HIDDEN      _A_HIDDEN
#   define  FATTR_SYSTEM      _A_SYSTEM
#   define  FATTR_SUBDIR      _A_SUBDIR
#   define  FATTR_ARCHIVE     _A_ARCH
#   define  FATTR_NORMAL      _A_NORMAL
#elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#   define  FATTR_RDONLY      FILE_READONLY
#   define  FATTR_HIDDEN      FILE_HIDDEN
#   define  FATTR_SYSTEM      FILE_SYSTEM
#   define  FATTR_SUBDIR      FILE_DIRECTORY
#   define  FATTR_ARCHIVE     FILE_ARCHIVED
#   define  FATTR_NORMAL      FILE_NORMAL

#elif defined(__JSE_NWNLM__)

#define  FATTR_RDONLY 0x01
#define  FATTR_HIDDEN 0x02
#define  FATTR_SYSTEM 0x04
#define  FATTR_SUBDIR 0x10
#define  FATTR_ARCHIVE 0x20
#define  FATTR_NORMAL 0x00

#elif defined(__JSE_UNIX__)

#   define  FATTR_RDONLY      0x80000000        /* fake so always thinks readable */
#   define  FATTR_HIDDEN      0x80000000        /* ditto */
#   define  FATTR_SYSTEM      0x80000000        /* ditto */
#   define  FATTR_SUBDIR      0x40000000
#   define  FATTR_ARCHIVE     S_IFDIR
#   define  FATTR_NORMAL      0x00

#else
#   define  FATTR_RDONLY      0x01
#   define  FATTR_HIDDEN      0x02
#   define  FATTR_SYSTEM      0x04
#   define  FATTR_SUBDIR      0x08
#   define  FATTR_ARCHIVE     0x10
   /* At least for Macintosh, if this is set to 0, then it is indistinguishable from
    * from the user passing an explicit 0 to denote no attributes set.  This is not an
    * actual attribute that is used by the user, but it gets passed if no other attributes
    * are set, so we must catch it specially.
    */
#  if defined(__JSE_MAC__)
#     define FATTR_NORMAL     0x20
#  else
#     define  FATTR_NORMAL      0x00
#  endif
#endif

#if defined(__JSE_DOS16__) || defined(__JSE_DOS32__) \
 || defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__) \
 || defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__) \
 || defined(__JSE_NWNLM__)

#   define  FATTR_MASK  (FATTR_RDONLY|FATTR_HIDDEN|FATTR_SYSTEM|FATTR_SUBDIR|FATTR_ARCHIVE|FATTR_NORMAL)
#elif defined(__JSE_UNIX__) || defined(__JSE_MAC__)
#   define FATTR_MASK 0
#else
#   error define FATTR_MASK for valid FATTR_ bits in this OS
#endif

#ifdef __JSE_MAC__
typedef struct {
   jseVariable *strVarArray;
   uint *total;
   jsecharptr searchSpec;
   jseContext jsecontext;
   uint includeAttrib;
   uint requiredAttrib;
} dirPrintStruct;

void dirFilterProc( const CInfoPBRec * const cpbPtr, Boolean *quitFlag,
                    void *yourDataPtr );
#endif  /* __JSE_MAC__ */

#endif /*# if defined(JSE_SELIB_DIRECTORY) */

#ifdef __cplusplus
}
#endif
#endif
