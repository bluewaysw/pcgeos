/* selib.h  Header file for selib library
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

#ifndef __SESELIB_H
#  define __SESELIB_H

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
#  if defined(__JSE_UNIX__)
#     include "common/seblob.h"
#  elif defined(__JSE_MAC__)
#     include "seblob.h"
#  elif defined(__JSE_390__)
#     include "SEBLOBH"
#  else
#     include "common\seblob.h"
#  endif
#endif

#if defined(JSE_SELIB_DIRECTORY) || \
    defined(JSE_SELIB_FULLPATH)  || \
    defined(JSE_SELIB_SPLITFILENAME)
#  if defined(__JSE_UNIX__)
#     include "selib/sedir.h"
#  elif defined(__JSE_MAC__)
#     include "sedir.h"
#  elif defined(__JSE_390__)
#     include "SEDIRH"
#  else
#     include "selib\sedir.h"
#  endif
#endif

#if defined(JSE_OS2_PMDYNAMICLINK)
#  include "os2\se2pmgat.h"
#endif

#if defined(JSE_SELIB_DYNAMICLINK)
#  if defined(__JSE_UNIX__)
#     include "common/sedyna.h"
#  elif defined(__JSE_MAC__)
#     include "sedyna.h"
#  elif defined(__JSE_390__)
#     include "SEDYNAH"
#  else
#     include "common\sedyna.h"
#  endif
#endif

#if defined(JSE_SELIB_SPAWN)
#  if defined(__JSE_UNIX__)
#     include "selib/sespawn.h"
#  elif defined(__JSE_MAC__)
#     include "sespawn.h"
#  elif defined(__JSE_390__)
#     include "SESPAWNH"
#  else
#     include "selib\sespawn.h"
#  endif
#endif

#if defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#  include "win\sent.h"
#endif

void InitializeLibrary_SElib_Blob(jseContext jsecontext);
void InitializeLibrary_SElib_Callback(jseContext jsecontext);
void InitializeLibrary_SElib_Directory(jseContext jsecontext);
void InitializeLibrary_SElib_Misc(jseContext jsecontext);

jsebool LoadLibrary_SElib(jseContext jsecontext);

jsebool checkCompiledChecksum(ubyte * buffer,uint bufferLength);
extern CONST_DATA(ubyte) magicNumber[];

#endif

