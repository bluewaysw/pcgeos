/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 *			GEOWORKS CONFIDENTIAL
 *
 * PROJECT:	  Sockets
 * MODULE:	  TCP/IP driver
 * FILE:	  tcpip.h
 *
 * AUTHOR:  	  Jennifer Wu: Jul 12, 1994
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/12/94	  jwu	    Initial version
 *
 * DESCRIPTION:
 *	
 *	Names of ASM routines called from C code.
 *
 * 	$Id: tcpip.h,v 1.1 97/04/18 11:57:07 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _TCPIP_H_
#define _TCPIP_H_

#include <timer.h>

#define InsertQueue(e, q) \
    (e)->prev = (q); \
    (e)->next = (q)->next; \
    (q)->next->prev = (e); \
    (q)->next = (e);

#define RemoveQueue(e) \
    (e)->next->prev = (e)->prev; \
    (e)->prev->next = (e)->next;


/***/
extern optr
    _pascal TcpipAllocDataBuffer(word bufferSize, word link);

/***/
#ifdef MERGE_TCP_SEGMENTS
extern optr
    _pascal TcpipDupDataBuffer(MbufHeader *buffer, word extraSize);
#endif

/***/
extern void
    _pascal TcpipFreeDataBuffer(optr buffer);

/***/
extern void
    _pascal TcpipLock(MemHandle mh);

/***/
extern void
    _pascal TcpipUnlock(MemHandle mh);

/***/
extern optr
    _pascal TSocketToTCB(word connection);

/***/
extern	void
    _pascal TSocketWakeWaiter(dword tcpSocket, word code);

/***/
extern void
    _pascal TSocketDoError(word code, dword sndr);

/***/
extern void
    _pascal TSocketIsConnected(word connection);

/***/
extern void
    _pascal TSocketIsDisconnected(word connection, word error, 
				 SocketCloseType closeType, Boolean destroyOK);

/***/
extern word
    _pascal TSocketIsDead(word socket);

/***/
extern void
    _pascal TSocketGetInfo(word connection, byte *src, 
			  byte *dst, word *lport, 
			  word *rport);

/***/
extern void
    _pascal TSocketTimeoutHandler(void);

/***/
extern dword
    _pascal TSocketRecvInput(optr dataBuffer, word connection);

/***/
extern word
    _pascal TSocketFindConnection(dword remoteAddr, 
				 dword localAddr, 
				 word lport,
				 word rport);
/***/
extern word
    _pascal TSocketProcessConnectRequest(dword remoteAddr,
					word rport,
					word lport,
					word link);
/***/
extern word
    _pascal TSocketDropAckedData(word connection, word numBytes, word *finAcked);


/***/
extern void
    _pascal TSocketHasUrgentData(word connection, byte *urgData);

/***/
extern word
    _pascal TSocketGetOutputSize(word connection);

/***/
extern void
    _pascal TSocketGetOutputData(byte *buffer, word off, 
				word len, word connection);

/***/
extern word
    _pascal TSocketGetLink(word connection);

/***/
extern dword
    _pascal TSocketGetRecvWin(word connection);

/***/
extern word
    _pascal TSocketRecvUdpInput(optr dataBuffer);

/***/
extern void
    _pascal TSocketRecvRawInput(optr dataBuffer);

/***/
extern void
    _pascal TSocketNotifyError(word code, word lport);

/***/
extern word
    _pascal Checksum(word *buffer, word nbytess);

/***/
extern word
    _pascal NetworkToHostWord(word value);

/***/
extern word
    _pascal HostToNetworkWord(word value);

#define HostToNetworkWord(value) NetworkToHostWord(value)

/***/
extern dword
    _pascal NetworkToHostDWord(dword value);

/***/
extern dword 
    _pascal HostToNetworkDWord(dword value);

#define HostToNetworkDWord(value) NetworkToHostDWord(value)

/***/
extern void
    _pascal TcpipReceivePacket(optr dataBuffer);

/***/
extern	word
    _pascal LinkGetMTU(word link);

/***/
extern	dword
    _pascal LinkGetLocalAddr(word link);

/***/
extern	word
    _pascal LinkCheckLocalAddr(word link, dword addr);

/***/
extern	word
    _pascal LinkSendData(optr dataBuffer, word link);

/***/
extern	void
    _pascal LinkTableDeleteEntry(word link);

/***/
extern 	word
    _pascal TcpipDetachAllowed (void);

/***/
extern dword
    _pascal IPParseDecimalAddr (char *addr, word addrLen);

/*
 * Get a packet from the input queue.
 */
extern optr
    _pascal TcpipDequeuePacket (void);


/*-------------------------------------------------------------------------
 * 
 *  Routines for logging information.
 *
 -------------------------------------------------------------------------*/
#ifdef WRITE_LOG_FILE

/***/
extern FileHandle
    _pascal LogGetLogFile(void);

#endif

/*-------------------------------------------------------------------------
 * 
 *  Routines for DHCP
 *
 -------------------------------------------------------------------------*/

extern void
    _pascal TcpipDhcpStartRenew(void);

extern void
    _pascal TcpipDhcpTimerHandler(void);

extern void
	_pascal TcpipReceiveStart(word link);

extern void
_pascal TcpipReceiveStop(word link);


#ifdef	__HIGHC__
pragma Alias(TcpipAllocDataBuffer, "TCPIPALLOCDATABUFFER");
#ifdef MERGE_TCP_SEGMENTS
pragma Alias(TcpipDupDataBuffer, "TCPIPDUPDATABUFFER");
#endif
pragma Alias(TcpipFreeDataBuffer, "TCPIPFREEDATABUFFER");
pragma Alias(TcpipLock, "TCPIPLOCK");
pragma Alias(TcpipUnlock, "TCPIPUNLOCK");
pragma Alias(TSocketToTCB, "TSOCKETTOTCB");
pragma Alias(TSocketWakeWaiter, "TSOCKETWAKEWAITER");
pragma Alias(TSocketDoError, "TSOCKETDOERROR");
pragma Alias(TSocketIsConnected, "TSOCKETISCONNECTED");
pragma Alias(TSocketIsDisconnected, "TSOCKETISDISCONNECTED");
pragma Alias(TSocketIsDead, "TSOCKETISDEAD");
pragma Alias(TSocketGetInfo, "TSOCKETGETINFO");
pragma Alias(TSocketTimeoutHandler, "TSOCKETTIMEOUTHANDLER");
pragma Alias(TSocketRecvInput, "TSOCKETRECVINPUT");
pragma Alias(TSocketFindConnection, "TSOCKETFINDCONNECTION");
pragma Alias(TSocketProcessConnectRequest, "TSOCKETPROCESSCONNECTREQUEST");
pragma Alias(TSocketDropAckedData, "TSOCKETDROPACKEDDATA");
pragma Alias(TSocketHasUrgentData, "TSOCKETHASURGENTDATA");
pragma Alias(TSocketGetOutputSize, "TSOCKETGETOUTPUTSIZE");
pragma Alias(TSocketGetOutputData, "TSOCKETGETOUTPUTDATA");
pragma Alias(TSocketGetLink, "TSOCKETGETLINK");
pragma Alias(TSocketGetRecvWin, "TSOCKETGETRECVWIN");
pragma Alias(TSocketRecvUdpInput, "TSOCKETRECVUDPINPUT");
pragma Alias(TSocketRecvRawInput, "TSOCKETRECVRAWINPUT");
pragma Alias(TSocketNotifyError, "TSOCKETNOTIFYERROR");
pragma Alias(Checksum, "CHECKSUM");
pragma Alias(NetworkToHostWord, "NETWORKTOHOSTWORD");
pragma Alias(NetworkToHostDWord, "NETWORKTOHOSTDWORD");
pragma Alias(HostToNetworkWord, "HOSTTONETWORKWORD");
pragma Alias(HostToNetworkDWord, "HOSTTONETWORKDWORD");
pragma Alias(TcpipReceivePacket, "TCPIPRECEIVEPACKET");
pragma Alias(LinkGetLocalAddr, "LINKGETLOCALADDR");
pragma Alias(LinkGetMTU, "LINKGETMTU");
pragma Alias(LinkCheckLocalAddr, "LINKCHECKLOCALADDR");
pragma Alias(LinkSendData, "LINKSENDDATA");
pragma Alias(LinkTableDeleteEntry, "LINKTABLEDELETEENTRY");
pragma Alias(TcpipDetachAllowed, "TCPIPDETACHALLOWED");
pragma Alias(IPParseDecimalAddr, "IPPARSEDECIMALADDR");
pragma Alias(TcpipDequeuePacket, "TCPIPDEQUEUEPACKET");
pragma Alias(TcpipDhcpHandleRenew, "TCPIPDHCPHANDLERENEW");
pragma Alias(TcpipDhcpLeaseExpired, "TCPIPDHCPLEASEEXPIRED");
pragma Alias(TcpipDhcpCheckIfRebind, "TCPIPDHCPCHECKIFREBIND");

#ifdef WRITE_LOG_FILE
pragma Alias(LogGetLogFile, "LOGGETLOGFILE");
#endif /* WRITE_LOG_FILE */

#endif /* __HIGHC__ */

#endif /* _TCPIP_H_ */
