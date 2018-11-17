/* extlib.h  External Library Link (ScriptEase Plug-ins) code
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

#ifndef _EXTLIB_H
#define _EXTLIB_H

#if defined(JSE_LINK) && (0!=JSE_LINK)

#if !defined(__JSE_WIN16__) && !defined(__JSE_WIN32__) && !defined(__JSE_CON32__) && \
    !defined(__JSE_OS2TEXT__) && !defined(__JSE_OS2PM__) && !defined(__JSE_UNIX__) && \
    !defined(__JSE_MAC__) && !defined(__JSE_NWNLM__)
#  error Extensions are not yet supported on this platform
#endif


#if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#  define ExtensionLibHandle HINSTANCE
#elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#  define ExtensionLibHandle HMODULE
#elif defined(__hpux__)
#  include <dl.h>
#  define ExtensionLibHandle shl_t
#elif defined(__JSE_UNIX__)
#  define ExtensionLibHandle void *
#elif defined(__JSE_MAC__)
#  define ExtensionLibHandle CFragConnectionID
#elif defined(__JSE_NWNLM__)
   /* actually, we store nothing. */
#  define ExtensionLibHandle void *
#else
#  error dont know how to store the external object!
#endif

#if (JSE_COMPILER==1)
   jsebool extensionLink(struct Source **source,struct Call *call);
#endif


struct LinkedExtensionLib
{
   struct LinkedExtensionLib *Previous;
   ExtensionLibHandle hExtensionLib;
   jsechar RootLibraryName[1];
};

struct ExtensionLibrary
{
   struct ExtensionLibrary *MyParent;
   struct LinkedExtensionLib *RecentLinkedExtensionLib;
};

   struct ExtensionLibrary *
extensionNew(struct Call *call,struct ExtensionLibrary *Parent);

struct jseFuncTable_t;

   void
extensionDelete(struct Call *call,
                struct ExtensionLibrary *,
                struct jseFuncTable_t *jseFuncTable);
#if defined(JSE_TOKENSRC) && (0!=JSE_TOKENSRC)

   void
extensionTokenWrite(struct ExtensionLibrary *,struct Call *call,struct TokenSrc *tSrc);

#endif
#if defined(JSE_TOKENDST) && (0!=JSE_TOKENDST)
      void
   extensionTokenRead(struct ExtensionLibrary *,struct Call *call,struct TokenDst *tDst);
#endif

   void NEAR_CALL
extensionFreeAllLibs(struct ExtensionLibrary *);

#endif
#endif
