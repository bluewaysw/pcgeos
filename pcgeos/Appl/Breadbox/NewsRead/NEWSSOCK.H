/**********************************************************************
 * NEWSSOCK.H - News Reader Header File                               *
 * Project - News Reader                                              *
 * Started 4/28/98                                                    *
 **********************************************************************/

#ifndef __NEWSSOCK_H
#define __NEWSSOCK_H

/**********************************************************************
 * Defines                                                            *
 **********************************************************************/

#define NEWS_SERVER_PORT     119
#define MAX_RESOLVED_SIZE    30

/**********************************************************************
 * Structs                                                            *
 **********************************************************************/

typedef struct {
  TcpAccPntExtendedAddress UTA_link;
  TCHAR                    UTA_ip[MAX_IP_ADDR_STRING_LENGTH];
} UnresolvedTCPAddress;

typedef struct {
  SocketAddress            RTA_sock;
  TcpAccPntResolvedAddress RTA_addr;
} ResolvedTCPAddress;

/**********************************************************************
 * External Variables                                                 *
 **********************************************************************/

extern Socket NewsSocket;

/**********************************************************************
 * Functions                                                          *
 **********************************************************************/

char *sgets(char *lineBuf);
char *sgetfield(char *buffer, char *p_term);
void sputs(char *line);
void ClearIncoming(void);

#endif
