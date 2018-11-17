/* seall.h - Includes all the necessary header files for an application
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

#ifndef __SEALL_H
#define __SEALL_H

#if defined(__sun) && !defined(__sun__)
#  define __sun__
#endif

/* SRCMISC OS DEPENDENCIES */
#include "jsedef.h"     /* get default settings from compiler */
#include "sesyshdr.h"   /* System headers */
/* INCJSE */
#include "jsetypes.h"
#include "jselib.h"
#include "selibdef.h"   /* Lib name definitions - Requires jselib.h first! */
#include "selink.h"
/* SRCMISC */
#include "cmdline.h"
#include "dbgprntf.h"
#include "dirparts.h"
#include "findfile.h"
#include "globldat.h"
#include "utilhuge.h"
#include "jsemem.h"
#if defined(__JSE_WINCE__)
#  include "winceutl.h"
#endif
#if defined(__JSE_MAC__)
#  include "macfunc.h"
#endif
#if !defined(__JSE_NUCLEUS__)
#  include "seappsrv.h"
#endif
#if defined(__JSE_MAC__)
#  include "semacthd.h"
#endif
#if defined(__JSE_UNIX__)
#  include "unixfunc.h"
#endif
#include "utilstr.h"
#include "varcall.h"
/* SRCDBG */
#if defined(JSE_DEBUGGABLE) && (0!=JSE_DEBUGGABLE)
#  include "dbgshare.h"
#  if defined(JSE_DEBUG_TCPIP)
#     include "proxy.h"
#  endif
#  include "debugme.h"
#endif

/* SRCAPP */

/* We only want things in srcapp if we are an application  */
/*
 * The user may or may not use these functions, but it can't hurt to include
 * the headers so that he or she has the prototypes available.
 */
#if defined(JSETOOLKIT_APP) && !defined(__JSE_PALMOS__)
#  include "fsearch.h"
#  include "getsourc.h"
#  include "printerr.h"
#  if defined(JSE_SECUREJSE) && (0!=JSE_SECUREJSE)
   /* get the security initialization helper function */
#     include "sesecure.h"
#  endif
#  if defined(JSE_WINDOW) || defined(JSE_WIN_SUBCLASSWINDOW)
#     include "sewincon.h"
#  endif
#endif


/* SRCLIB */
/* Only include anything in srclib if the user has defined anything */
#if defined(JSE_CLIB_ANY)     || \
    defined(JSE_SELIB_ANY)    || \
    defined(JSE_LANG_ANY)     || \
    defined(JSE_MAC_ANY)      || \
    defined(JSE_DOS_ANY)      || \
    defined(JSE_WIN_ANY)      || \
    defined(JSE_NLM_ANY)      || \
    defined(JSE_UNIX_ANY)     || \
    defined(JSE_OS2_ANY)      || \
    defined(JSE_ARRAY_ANY)    || \
    defined(JSE_BOOLEAN_ANY)  || \
    defined(JSE_FUNCTION_ANY) || \
    defined(JSE_NUMBER_ANY)   || \
    defined(JSE_OBJECT_ANY)   || \
    defined(JSE_ECMAMISC_ANY) || \
    defined(JSE_STRING_ANY)   || \
    defined(JSE_REGEXP_ANY)   || \
    defined(JSE_GD_ANY)       || \
    defined(JSE_LANG_ANY)     || \
    defined(JSE_TEST_ANY)     || \
    defined(JSE_MD5_ANY)      || \
    defined(JSE_COMOBJ_ANY)   || \
    defined(JSE_UUCODE_ANY)   || \
    defined(JSE_SOCKET_ANY)   || \
    defined(JSE_DSP_ANY)      || \
    defined(JSE_SEDBC_ANY)    || \
    defined(JSETOOLKIT_LINK)
#  include "seliball.h"
#endif

#include "seobjfun.h"

#endif /* !__SEALL_H */
