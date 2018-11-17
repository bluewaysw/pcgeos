/* inet.h      A socket class.
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

#ifndef __INET_H
#define __INET_H

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <stdlib.h>

#if !defined(JSETOOLKIT_CORE)

#include "jsetypes.h"
#include "jselib.h"

#ifdef __cplusplus
   extern "C" {
#endif

#ifdef __sun__
#  include <sys/filio.h>
#endif

#if defined(_AIX)
#  include <strings.h>
#  include <sys/select.h>
#endif

#if defined(__JSE_WIN32__) || defined(__JSE_WIN16__) || defined(__JSE_CON32__) || \
    (defined(__JSE_MAC__) && defined(USE_MAC_WINSOCK))
#  include <winsock.h>
#endif

#if defined(__JSE_MAC__) && !defined(USE_MAC_WINSOCK)
#  include <OpenTransport.h>
#  include <OpenTptInternet.h>
#endif

#if defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
#  define BSD_SELECT

#  include <types.h>
#  include <sys\socket.h>
#  include <netinet\in.h>
#  include <netdb.h>
#  include <utils.h>
#  include <nerrno.h>
#  include <sys\ioctl.h>
#  include <sys\select.h>
#  include <sys\time.h>
#endif

#if defined(__JSE_NWNLM__)
#  include <sys\types.h>
#  include <sys\socket.h>
#  include <netdb.h>
#  include <netinet\in.h>
#  include <sys\time.h>
  /*#include <io.h>*/
#  include <sys\filio.h>
#  include <sys\ioctl.h>
#  include <arpa\inet.h>
#endif

#if defined(__JSE_UNIX__)
#  include <unistd.h>
#endif
#if defined(__JSE_UNIX__) || defined(__JSE_NWNLM__)
  typedef int SOCKET;
#  define INVALID_SOCKET -1
#  define SOCKET_ERROR -1
#  define closesocket(x) close(x)
#elif defined(__JSE_OS2TEXT__) || defined(__JSE_OS2PM__)
  typedef int SOCKET;
#  define INVALID_SOCKET -1
#  define SOCKET_ERROR -1
#  define closesocket(x) soclose(x)
#elif defined(__JSE_MAC__) && !defined(USE_MAC_WINSOCK)
  typedef TEndpoint *     SOCKET;
#  define INVALID_SOCKET  NULL
#  define SOCKET_ERROR    NULL
#endif

/* ---------------------------------------------------------------------- */

/*
 * These routines under windows must set up the appropriate
 * Asynchronous stuff.
 */

struct jseSocket {
   SOCKET sock;
   char connected_to[128];

  /* by having a buffer, we can full lines at a time if needed */
  int buf_start,buf_end;
  char recv_buffer[256];

};

/* On failure, the created structure's member 'sock' is SOCKET_ERROR */
struct jseSocket * jsesocketNewPort(int port);             /* create a new socket for listening. */
struct jseSocket * jsesocketNewHostPort(char *host,int port);  /* open a connection to a remote host. If host is
                                                                   * NULL, open to this machine.
                                                                   */
struct jseSocket * jsesocketNewSocket(struct jseSocket *s);     /* accept a connection on an existing socket.
                                                                 * on Windows, this must not block.
                                                                 */
struct jseSocket * jsesocketNewSocketAddrLen(struct jseSocket *s,char *addr,int len);

void jsesocketDelete(struct jseSocket *This);

void jsesocketHostName(char *buffer,int length);    /* our own host name */
void jsesocketHostAddr(char *buffer,int length);    /* our own host name but by numbers */
int jsesocketTranslateToNumber(char *addr);         /* return the numeric host address */

void jsesocketBlocking(struct jseSocket *This);                    /* make socket blocking. */

slong jsesocketRecv(struct jseSocket *This,ubyte _HUGE_ *buffer,slong maxchars);   /* a simple recv call */

  /* read a single line, terminated by EOL. Strip EOL. Add '\0'.
   * this must also work intersperced with recv. The result should be
   * recv-like (num chars or 0/-1 for error).
   */

int jsesocketRecvLine(struct jseSocket *This,char *buffer,int maxchars);

  /* normal send may stop before everything is sent.  This sends everything until done or until error */
slong jsesocketSendBuffer(struct jseSocket *This,const ubyte _HUGE_ *buffer,slong numchars);

  /* Sometimes the '\0' should be sent. In those cases, call the first version
   * of send() above.
   */
int jsesocketSendString(struct jseSocket *This,const char *buffer);

#define EOL UNISTR("\r\n")

#if defined(__JSE_WIN32__) || defined(__JSE_CON32__) || \
    (defined(__JSE_MAC__) && defined(USE_MAC_WINSOCK)) || \
    defined(__JSE_WIN16__)
  int  start_winsock(void);
  void stop_winsock(void);
#endif

#if defined(__JSE_WIN16__) || defined(__JSE_WIN32__) || defined(__JSE_CON32__)
#  define WM_SOCKET_READY (WM_USER + 1003)
#elif (defined(__JSE_MAC__) && defined(USE_MAC_WINSOCK))
   /* On the mac, we may assign any value we want to the messages, since they are only used by
    *   the NMMessage handlers.
    */
#  define WM_SOCKET_READY 1003
#endif

#ifdef __cplusplus
}
#endif

#endif /* !defined(JSETOOLKIT_CORE) */

#endif
