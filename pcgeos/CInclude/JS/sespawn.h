/* sespawn.h    Spawn child process
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

#if !defined(__SPAWN_H)
#  define __SPAWN_H
#  ifdef __cplusplus
extern "C" {
#  endif

   jseLibFunc(CEnviSpawn);

#  if defined(__JSE_DOS16__)
#    define BUILD_SWAP_PATH_BUFSIZE  400
   void BuildSwapPath(jsechar SwapPath[BUILD_SWAP_PATH_BUFSIZE]);
#  endif

#  if defined(__JSE_DOS16__) && defined(_MSC_VER)
#    define SPAWN_WAIT      P_WAIT
#    define SPAWN_NOWAIT    P_NOWAITO
#    define SPAWN_OVERLAY   P_OVERLAY
#  elif defined(__JSE_WIN16__) && defined(_MSC_VER)
#    define SPAWN_WAIT      P_WAIT
#    define SPAWN_NOWAIT    P_NOWAITO
#  elif defined(__JSE_DOS32__)
#    define SPAWN_WAIT      P_WAIT
#  elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#    if defined(__WATCOMC__)
#      define SPAWN_WAIT      P_WAIT
#      define SPAWN_NOWAIT    P_NOWAITO
#    elif defined(__IBMCPP__)
#      define SPAWN_WAIT      P_WAIT
#      define SPAWN_NOWAIT    P_NOWAIT
#    endif
#  elif defined(__JSE_DOS16__) && defined(__CENVI__)
#    define SPAWN_WAIT      P_WAIT
#    define SPAWN_SWAP      ((P_WAIT + P_OVERLAY) * 2)
#    define SPAWN_OVERLAY   P_OVERLAY
#  elif defined(__JSE_DOS16__)
#    define SPAWN_WAIT      P_WAIT
#    define SPAWN_OVERLAY   P_OVERLAY
#  elif defined(__JSE_WIN16__) \
     || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#    define SPAWN_WAIT      0
#    define SPAWN_NOWAIT    1
#  elif defined(__JSE_NWNLM__)
#    define SPAWN_WAIT      P_WAIT
#    define SPAWN_NOWAIT    P_NOWAIT
#  elif defined(__JSE_UNIX__) || defined(__JSE_MAC__)
#    define SPAWN_WAIT      1
#    define SPAWN_NOWAIT    2
#    define SPAWN_OVERLAY   3
#  else
#    error SPAWNS not yet defined for this OS
#  endif

#  ifdef __cplusplus
}
#  endif
#endif
