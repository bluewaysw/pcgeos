/* FindFile.h   Routines for finding file
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

#ifndef _FINDFILE_H
#define _FINDFILE_H
#ifdef __cplusplus
   extern "C" {
#endif

jsecharptr FindFile(const jsecharptr FileSpec,
                    const jsecharptr SearchPaths,
                    uint ExtensionCount,const jsecharptr Extension[]);
   /* Return an allocated full path specification for file matching filespec,
    * which calling function must free.  If not found or error then return
    * NULL.  FileSpec is all or partial filename.  If contains any wildcards
    * then return NULL.  If contains any directory specification then only
    * search the specified directory, else search in the SearchPaths
    * directories.  If no extension then search for the Extensions in
    * the order specified.  If it does contain an extension and some extensions
    * are supplied then it must be one of those in the list.  If !ExtensionCount
    * then accept the given extension.
    */

#if defined(__JSE_MAC__)
#   define PATH_SEPARATOR '\n'
#   define PATH_SEPARATOR_STR UNISTR("\n")
#   define DIR_SEPARATOR ':'
#elif defined(__JSE_UNIX__)
#   define PATH_SEPARATOR ':'
#   define PATH_SEPARATOR_STR UNISTR(":")
#   define DIR_SEPARATOR '/'
#elif defined(__JSE_NWNLM__)
#   define PATH_SEPARATOR ';'
#   define PATH_SEPARATOR_STR UNISTR(";")
#   define DIR_SEPARATOR '/'
#elif defined(__JSE_390__)
#   define PATH_SEPARATOR ';'
#   define PATH_SEPARATOR_STR UNISTR(";")
#   define DIR_SEPARATOR '.'
#else
#   define PATH_SEPARATOR ';'
#   define PATH_SEPARATOR_STR UNISTR(";")
#   define DIR_SEPARATOR '\\'
#endif

jsebool fileExists( const jsecharptr SearchSpec );

#ifndef __JSE_UNIX__
/* Mac supports MakeFullPath - not multithread safe, though */
jsebool MakeFullPath(jsecharptr ResultBuf,const jsecharptr PartialPath,uint ResultBufSize);
      /* fill ResultBuf, up to size, with PartialPath converted to full path
       * return True if success, else error in path
       */
#endif

/* Mac now supports the "." directory - it depends on a jsecontext though */
#if defined(__JSE_MAC__)
#  define CURRENT_DIRECTORY MakeCompletePath(jsecontext,UNISTR("."))
#elif defined(__JSE_WINCE__)
#  define CURRENT_DIRECTORY MakeCompletePath(jsecontext,UNISTR("."))
#else
#  define CURRENT_DIRECTORY  UNISTR(".")
#endif

#ifdef __cplusplus
}
#endif
#endif /* _FINDFILE_H */
