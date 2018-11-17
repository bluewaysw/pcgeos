/* Proxy stuff for integration with sewse
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

/*
 * Revision History
 *
 * Apr  4, 1996   Created by Richard Robinson
 * Mar 12, 1998   Upgraded to new protocols/define flags
 * Mar 17, 1998   rewritten in C
 */

#if (defined(JSE_DEBUGGABLE) && (0!=JSE_DEBUGGABLE)) && defined(JSE_DEBUG_TCPIP)

#include "inet.h"

#ifdef __cplusplus
extern "C" {
#endif

struct debugMe;

void tcpipProxyCheckStop(jseContext jsecontext,struct debugMe **debugme,SOCKET socket);
jsebool tcpipProxyGetMsg(struct debugMe *debugme,SOCKET socket,struct DebugInfo *msg);
jsebool tcpipProxySendMsg(struct debugMe *debugme,SOCKET socket,struct DebugInfo *i);
SOCKET tcpipProxyConnect(jseContext jsecontext,char const *ip_addr);
jsebool tcpipProxyInitialize(void);
void tcpipProxyTerminate(SOCKET working);

jsebool outgoingMsg(struct debugMe *debugme,struct DebugInfo *i);
jsebool incomingMsg(struct debugMe *debugme,struct DebugInfo *i);

int start_winsock(void);
void stop_winsock(void);

#ifdef __cplusplus
}
#endif

/* We have to decide on some port number. This was the suggestion. Amazingly enough,
 * it was not my idea...
 */
#define JSE_REMOTE_DBG_PORT 0xdead

#if defined(JSE_DEBUG_PROXY)
#  define MakeFullPath _fullpath
#endif

#endif
