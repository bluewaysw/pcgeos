/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PC/GEOS
 * FILE:	  net.h
 * AUTHOR:  	  Chung Liu: Sep 22, 1992
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	CL	9/22/92	  Initial version
 *
 * DESCRIPTION:
 *	C version of net.def
 *
 *
 * 	$Id: net.h,v 1.1 97/04/04 15:59:00 newdeal Exp $
 *
 ***********************************************************************/
#ifndef __NET_H_
#define __NET_H_

#define NW_BINDERY_OBJECT_NAME_LEN	47
#define NW_BINDERY_OBJECT_PASSWORD_LEN 	127
#define NW_USER_NAME_LENGTH 		(NW_BINDERY_OBJECT_NAME_LEN + 1)

#define NET_LOGIN_NAME_SIZE             NW_BINDERY_OBJECT_NAME_LEN
#define NET_LOGIN_NAME_SIZE_ZT          NW_BINDERY_OBJECT_NAME_LEN + 1

#define NET_PASSWORD_SIZE               NW_BINDERY_OBJECT_PASSWORD_LEN
#define NET_PASSWORD_SIZE_ZT            NW_BINDERY_OBJECT_PASSWORD_LEN + 1

#define NET_SERVER_NAME_SIZE            NW_BINDERY_OBJECT_NAME_LEN
#define NET_SERVER_NAME_SIZE_ZT         NW_BINDERY_OBJECT_NAME_LEN + 1

typedef char NetLoginName[NET_LOGIN_NAME_SIZE_ZT];
typedef char NetPassword[NET_PASSWORD_SIZE_ZT];
typedef char NetServerName[NET_SERVER_NAME_SIZE_ZT];

/*
 * Because of the transient nature of the net library/netware driver
 * api, the lines between library and driver are a bit unclear.
 * In placing type NetWareReturnCode in this library file, we cross the 
 * line (for the sake of getting things moving).  Later, some sort
 * of "NetReturnCode" should be defined and used here.
 */
typedef ByteEnum NetWareReturnCode;
#define NRC_GENERAL_SUCCESSFUL 0x00
#define NRC_SERVER_OUT_OF_MEMORY 0x96
#define NRC_LOGIN_DENIED 0xD9      /* probably concurrent login attempted */
#define NRC_PASSWORD_EXPIRED_NO_GRACE 0xDE /* login failed */
#define NRC_PASSWORD_EXPIRED 0xDF  /* login successful on grace login */
#define NRC_WILDCARD_NOT_ALLOWED 0xF0
#define NRC_NO_SUCH_PROPERTY 0xFB
#define NRC_NO_SUCH_OBJECT 0xFC
#define NRC_SERVER_BINDERY_LOCKED 0xFE
#define NRC_BINDERY_FAILURE 0xFF   /* bad password */

typedef dword NetWareBinderyObjectID;
typedef byte NetWareConnectionID;

typedef struct {
  byte	NNA_address[4];
} NovellNetworkAddress ;     /* 4 bytes */

typedef struct {
  byte 	NNOA_address[6];
} NovellNodeAddress;

typedef word NovellSocketAddress;

struct NovellNodeSocketAddrStruct {
  NovellNetworkAddress 		NNSAS_network;
  NovellNodeAddress 		NNSAS_node;
  NovellSocketAddress		NNSAS_socket;
};

typedef struct NovellNodeSocketAddrStruct NovellNodeSocketAddr;

typedef byte NetWareConnectionNumber;

typedef struct {
  byte 				NCITI_slotInUse;
  byte 				NCITI_serverOrderNumber;
  NovellNodeSocketAddr 	        NCITI_serverAddress;
  word 				NCITI_receiveTimeOut;
  NovellNodeAddress 		NCITI_routersPhysicalNodeAddress;
  byte 				NCITI_packetSequenceNumber;
  NetWareConnectionNumber	NCITI_connectionNumber;
  byte				NCITI_connectionStatus;
  word				NCITI_maximumTimeOut;
  byte				NCITI_filler[5]; /* ?? */  
} NetWareConnectionIDTableItem;

typedef struct {
    word portNum;
    word baudRate;
} PortInfoStruct;

typedef void NetSocketCallback (char *data, word dataSize, word extraData, word callbackData);
#define	SOCKET_DESTROYED 0
#define	SOCKET_HEARTBEAT -1

typedef word NetEnumBufferType;
#define NEBT_MEM			0
#define NEBT_CHUNK_ARRAY		2
#define NEBT_CHUNK_ARRAY_VAR_SIZED	4

/* returns the chunk of the chunk array created in mh. */
extern ChunkHandle
    _pascal NetEnumUsers(NetEnumBufferType bt,
			 MemHandle mh);        /* handle of block to create
						* the chunk array */
/* returns the chunk of the chunk array created in mh. */
extern ChunkHandle
    _pascal NetEnumConnectedUsers(NetEnumBufferType bt,
			 MemHandle mh);        /* handle of block to create
						* the chunk array */
extern void
    _pascal NetUserGetLoginName(char *buffer);

extern word
    _pascal NetUserCheckIfInGroup(char *userName, char *groupName);

extern NetWareConnectionID _pascal NetGetDefaultConnectionID();

extern char *_pascal NetGetServerNameTable();

extern NetWareConnectionIDTableItem *_pascal NetGetConnectionIDTable();

extern NetWareReturnCode
    _pascal NetVerifyUserPassword(char *, char *, byte, byte);

extern NetWareReturnCode
    _pascal NetScanForServer(NetWareBinderyObjectID,
			     char *,
			     NetWareBinderyObjectID *);

extern word _pascal NetServerAttach(char *);

extern word _pascal 
    NetServerChangeUserPassword(char *server,
				char *userName,
				char *oldPassword,
				char *newPassword);
extern word _pascal 
    NetServerVerifyUserPassword(char *server, char *login, char *passwd);

extern word _pascal 
    NetServerLogin(char *server,
		   char *login,
		   char *passwd,
		   Boolean reopenFiles);

extern word _pascal NetServerLogout(char *);
extern word _pascal
    NetServerGetNetAddr(char *server, NovellNodeSocketAddr *np);
extern word _pascal
    NetServerGetWSNetAddr(char *server, NovellNodeSocketAddr *np);
extern word _pascal NetMapDrive(char, char *, char *);
extern word _pascal NetUnmapDrive(char);
extern NetWareConnectionNumber _pascal NetGetConnectionNumber();
extern word _pascal NetMsgOpenPort(PortInfoStruct *);
extern word _pascal NetMsgClosePort(word);

typedef enum {
	SID_TALK,
	SID_RFSD,
	SID_CLIPBOARD_SEND,
	SID_CLIPBOARD_RECEIVE,
	SID_AIRWRITER_SEND,
	SID_AIRWRITER_RECEIVE,
	SID_NOTE_MAGIC

} SocketID;

extern word _pascal NetMsgCreateSocket(word portToken, SocketID socketID, SocketID destID, NetSocketCallback *callback,
				       word callbackData);
extern word _pascal NetMsgDestroySocket(word, word);
extern word _pascal NetMsgSendBuffer(word portToken, word socketToken,
				     word extraData, word dataSize,
				     char *data);
extern word _pascal NetMsgSetTimeOut(word, word, word);

extern MemHandle _pascal
    NetOpenSem(char *semName, int initValue, word pollIntervalTicks);
extern Boolean _pascal 
    NetPSem(MemHandle semHandle, word timeoutTicks);
extern void _pascal 
    NetVSem(MemHandle semHandle);
extern void _pascal
    NetCloseSem(MemHandle semHandle);

extern void _pascal
    NetPrintSetBannerStatus(int status);

extern void _pascal
    NetPrintSetTimeout(int timeout);

#ifdef __HIGHC__
pragma Alias (NetEnumUsers, "NETENUMUSERS");
pragma Alias (NetEnumConnectedUsers, "NETENUMCONNECTEDUSERS");
pragma Alias (NetUserGetLoginName, "NETUSERGETLOGINNAME");
pragma Alias (NetUserCheckIfInGroup, "NETUSERCHECKIFINGROUP");
pragma Alias (NetGetDefaultConnectionID, "NETGETDEFAULTCONNECTIONID");
pragma Alias (NetVerifyUserPassword, "NETVERIFYUSERPASSWORD");
pragma Alias (NetGetServerNameTable, "NETGETSERVERNAMETABLE");
pragma Alias (NetGetConnectionIDTable, "NETGETCONNECTIONIDTABLE");
pragma Alias (NetScanForServer, "NETSCANFORSERVER");
pragma Alias (NetServerAttach, "NETSERVERATTACH");
pragma Alias (NetServerChangeUserPassword, "NETSERVERCHANGEUSERPASSWORD");
pragma Alias (NetServerVerifyUserPassword, "NETSERVERVERIFYUSERPASSWORD");
pragma Alias (NetServerLogin, "NETSERVERLOGIN");
pragma Alias (NetServerLogout, "NETSERVERLOGOUT");
pragma Alias (NetServerGetNetAddr, "NETSERVERGETNETADDR");
pragma Alias (NetServerGetWSNetAddr, "NETSERVERGETWSNETADDR");
pragma Alias (NetMapDrive, "NETMAPDRIVE");
pragma Alias (NetUnmapDrive, "NETUNMAPDRIVE");
pragma Alias (NetGetConnectionNumber, "NETGETCONNECTIONNUMBER");
pragma Alias (NetMsgOpenPort, "NETMSGOPENPORT");
pragma Alias (NetMsgClosePort, "NETMSGCLOSEPORT");
pragma Alias (NetMsgCreateSocket, "NETMSGCREATESOCKET");
pragma Alias (NetMsgDestroySocket, "NETMSGDESTROYSOCKET");
pragma Alias (NetMsgSendBuffer, "NETMSGSENDBUFFER");
pragma Alias (NetMsgSetTimeOut, "NETMSGSETTIMEOUT");
pragma Alias (NetOpenSem, "NETOPENSEM");
pragma Alias (NetPSem, "NETPSEM");
pragma Alias (NetVSem, "NETVSEM");
pragma Alias (NetCloseSem, "NETCLOSESEM");
pragma Alias (NetPrintSetBannerStatus, "NETPRINTSETBANNERSTATUS");
pragma Alias (NetPrintSetTimeout, "NETPRINTSETTIMEOUT");
#endif

#endif /* _NET_H_ */


