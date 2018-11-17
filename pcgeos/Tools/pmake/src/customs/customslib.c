/*-
 * customslib.c --
 *	Front end RPC stubs for clients of the customs daemons.
 *
 * Copyright (c) 1988, 1989 by the Regents of the University of California
 * Copyright (c) 1988, 1989 by Adam de Boor
 * Copyright (c) 1989 by Berkeley Softworks
 *
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any non-commercial purpose
 * and without fee is hereby granted, provided that the above copyright
 * notice appears in all copies.  The University of California,
 * Berkeley Softworks and Adam de Boor make no representations about
 * the suitability of this software for any purpose.  It is provided
 * "as is" without express or implied warranty.
 */
#if defined(unix)
#ifndef lint
static char *csid =
"$Id: customslib.c,v 1.2 93/01/30 15:37:17 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customs.h"
#include    <sys/time.h>
#include    <stdio.h>
#include    <sys/file.h>
#include    <netdb.h>

int  	  	    	customs_Socket = -1;
struct sockaddr_in   	customs_AgentAddr;
struct timeval	    	customs_RetryTimeOut = {
    CUSTOMS_RETRY, CUSTOMS_URETRY
};
static Rpc_Stat	  	    lastStatus;
static short	    	    udpPort,
			    tcpPort;

/*-
 *-----------------------------------------------------------------------
 * CustomsInit --
 *	Initialize things so these functions may be used.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A udp socket is opened and customs_AgentAddr is initialized to be
 *	suitable for talking to the local agent.
 *
 *-----------------------------------------------------------------------
 */
static void
CustomsInit()
{
    struct servent  *sep;
    int	    	i;

    i = 3;

    do {
	sep = getservbyname("customs", "udp");
    } while (sep == NULL && i-- > 0);

    if (sep == NULL) {
#if 0
	printf("customs/udp unknown\n");
	/*XXX*/
	exit(1);
#else
	udpPort = DEF_CUSTOMS_UDP_PORT;
#endif
    } else {
	udpPort = ntohs(sep->s_port);
    }
    i = 3;
    do {
	sep = getservbyname("customs", "tcp");
    } while (sep == NULL && i-- > 0);

    if (sep == NULL) {
#if 0
	printf("customs/tcp unknown\n");
	/*XXX*/
	exit(1);
#else
	tcpPort = DEF_CUSTOMS_TCP_PORT;
#endif
    } else {
	tcpPort = ntohs(sep->s_port);
    }
    
    customs_Socket = Rpc_UdpCreate(False, 0);
    (void)fcntl(customs_Socket, F_SETFD, 1);
    bzero(&customs_AgentAddr, sizeof(customs_AgentAddr));
    customs_AgentAddr.sin_family = AF_INET;
    customs_AgentAddr.sin_port = htons(udpPort);
    customs_AgentAddr.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
}
/*-
 *-----------------------------------------------------------------------
 * Customs_Ping --
 *	See if the local agent is alive.
 *
 * Results:
 *	RPC_SUCCESS if the agent is alive and responding.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Customs_Ping()
{
    if (customs_Socket == -1) {
	CustomsInit();
    }
    lastStatus = Rpc_Call(customs_Socket, &customs_AgentAddr,
			  (Rpc_Proc)CUSTOMS_PING,
			  0, (Rpc_Opaque)0,
			  0, (Rpc_Opaque)0,
			  CUSTOMS_NRETRY, &customs_RetryTimeOut);
    return(lastStatus);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_Host --
 *	Request a host for exportation from the local agent. We send the
 *	effective user-id partly because it's in the protocol and
 *	partly because that's what determines file accesses...
 *
 * Results:
 *	The status of the call. If RPC_SUCCESS, permitPtr contains the
 *	agent's response, which may have an addr field of INADDR_ANY. This
 *	indicates that a host could not be allocated.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Customs_Host(flags, permitPtr)
    short   	  flags;
    ExportPermit  *permitPtr;
{
    Host_Data	  data;
    
    data.uid = geteuid();
    data.flags = flags;

    if (customs_Socket == -1) {
	CustomsInit();
    }
    lastStatus = Rpc_Call(customs_Socket, &customs_AgentAddr,
			  (Rpc_Proc)CUSTOMS_HOST,
			  sizeof(data), (Rpc_Opaque)&data,
			  sizeof(ExportPermit), (Rpc_Opaque)permitPtr,
			  CUSTOMS_NRETRY, &customs_RetryTimeOut);
    return(lastStatus);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_AvailInterval --
 *	Set the interval at which the local agent informs the master of
 *	its availability.
 *
 * Results:
 *	The status of the call.
 *
 * Side Effects:
 *	See above.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Customs_AvailInterval(interval)
    struct timeval	*interval;
{
    if (customs_Socket == -1) {
	CustomsInit();
    }
    lastStatus = Rpc_Call(customs_Socket, &customs_AgentAddr,
			  (Rpc_Proc)CUSTOMS_AVAILINTV,
			  sizeof(*interval), (Rpc_Opaque)interval,
			  0, (Rpc_Opaque)0,
			  CUSTOMS_NRETRY, &customs_RetryTimeOut);
    return(lastStatus);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_Master --
 *	Find the location of the current master customs agent.
 *
 * Results:
 *	The status of the call. If the call succeeds, the passed
 *	sockaddr_in is filled with address of the current master.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Customs_Master(masterAddrPtr)
    struct sockaddr_in	*masterAddrPtr;
{
    if (customs_Socket == -1) {
	CustomsInit();
    }
    lastStatus = Rpc_Call(customs_Socket, &customs_AgentAddr,
			  (Rpc_Proc)CUSTOMS_MASTER,
			  0, (Rpc_Opaque)0,
			  sizeof(struct sockaddr_in),
			  (Rpc_Opaque)masterAddrPtr,
			  CUSTOMS_NRETRY, &customs_RetryTimeOut);
    return(lastStatus);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_SetAvail --
 *	Change the availability criteria for the local machine.
 *
 * Results:
 *	The status of the call. If RPC_SUCCESS, criteria is overwritten
 *	with the current/new criteria and criteria->changeMask contains
 *	bits to indicate which, if any, values of the passed criteria
 *	were out-of-bounds.
 *
 * Side Effects:
 *	The criteria are changed if all are acceptable.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Customs_SetAvail(criteria)
    Avail_Data	  *criteria;
{
    if (customs_Socket == -1) {
	CustomsInit();
    }
    lastStatus = Rpc_Call(customs_Socket, &customs_AgentAddr,
			  (Rpc_Proc)CUSTOMS_SETAVAIL,
			  sizeof(Avail_Data), (Rpc_Opaque)criteria,
			  sizeof(Avail_Data), (Rpc_Opaque)criteria,
			  CUSTOMS_NRETRY, &customs_RetryTimeOut);
    return(lastStatus);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_Info --
 *	Acquire information about the registered hosts from the master
 *	agent at the given address.
 *
 * Results:
 *	The status of the call. If RPC_SUCCESS, the passed buffer is filled
 *	with information about the registered hosts.
 *
 * Side Effects:
 *	Not really.
 *
 *-----------------------------------------------------------------------
 */
Rpc_Stat
Customs_Info(masterAddrPtr, buf)
    struct sockaddr_in	*masterAddrPtr;
    char    	  	buf[MAX_INFO_SIZE];
{
    if (customs_Socket == -1) {
	CustomsInit();
    }
    lastStatus = Rpc_Call(customs_Socket, masterAddrPtr,
			  (Rpc_Proc)CUSTOMS_INFO,
			  0, (Rpc_Opaque)0,
			  MAX_INFO_SIZE, (Rpc_Opaque)buf,
			  CUSTOMS_NRETRY, &customs_RetryTimeOut);
    return(lastStatus);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_PError --
 *	Print error message based on last call.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *  	A message is printed.
 *
 *-----------------------------------------------------------------------
 */
void
Customs_PError(msg)
    char    	  *msg;
{
    fprintf(stderr, "%s: %s\n", msg, Rpc_ErrorMessage(lastStatus));
}

/*-
 *-----------------------------------------------------------------------
 * Customs_MakeWayBill --
 *	Create a WayBill to be passed to the CUSTOMS_IMPORT function.
 *
 * Results:
 *	Length of the buffer.
 *
 * Side Effects:
 *	The passed buffer is overwritten.
 *
 *-----------------------------------------------------------------------
 */
int
Customs_MakeWayBill(permitPtr, cwd, file, argv, environ, port, buf)
    ExportPermit  	*permitPtr; /* Permit for the job */
    char    	  	*cwd;	    /* The current working directory */
    char    	  	*file;	    /* File to execute */
    char    	  	**argv;	    /* Arguments for it */
    char    	  	**environ;  /* Environment in which it should run */
    unsigned short	port;	    /* Port of udp socket for CUSTOMS_EXIT
				     * return RPC call */
    char    	  	*buf;	    /* Place to stuff the information */
{
    register char 	*cp;
    register int  	i;
    register WayBill	*wb;

    wb = (WayBill *)buf;

    /*
     * We compute a deadline for the remote side to start its process.
     * This is to prevent bogus timeouts that could lead to duplicate
     * exports.  To be on the safe side, the dead line is half the caller
     * side RPC timeout.
     */
#ifdef DOUBLECHECK_TIMEOUT
    time(&wb->deadline);
    wb->deadline += CUSTOMS_TCP_RETRY/2;
#else
    wb->deadline = 0;
#endif

    /*
     * First the constant information:
     *	    - permit ID
     *	    - return call port
     *	    - real user id
     *	    - effective user id
     *	    - real group id
     *	    - effective group id
     *	    - array of groups process is in
     *	    - file creation mask
     */
    wb->id = permitPtr->id;
    wb->port = port;
    wb->ruid = getuid();
    wb->euid = geteuid();
    wb->rgid = getgid();
    wb->egid = getegid();
    wb->ngroups = getgroups(sizeof(wb->groups) / sizeof(int), wb->groups);
    wb->umask = umask(0);
    (void) umask(wb->umask);

    /*
     * Then the variable-length part:
     *	    - the absolute path of the current working directory
     *	    - the file to execute (needn't be absolute)
     *	    - the number of arguments (stored on a longword boundary)
     *	    - the argument strings
     *	    - the number of environment strings (stored on a 32-bit boundary)
     *	    - the environment strings themselves
     */
    cp = (char *)&wb[1];
    strcpy(cp, cwd);
    cp += strlen(cp);
    *cp++ = '\0';
    strcpy(cp, file);
    cp += strlen(file);
    *cp++ = '\0';
    cp = Customs_Align(cp, char *);

    for (i = 0; argv[i]; i++) {
	;
    }
    *(int *)cp = i;
    cp += sizeof(int);
    for (i = 0; argv[i]; i++) {
	strcpy(cp, argv[i]);
	cp += strlen(cp);
	*cp++ = '\0';
    }
    cp = Customs_Align(cp, char *);
    for (i = 0; environ[i]; i++) {
	;
    }
    *(int *)cp = i;
    cp += sizeof(int);
    for (i = 0; environ[i]; i++) {
	strcpy(cp, environ[i]);
	cp += strlen(cp);
	*cp++ = '\0';
    }
    return (cp - buf);
}

/*-
 *-----------------------------------------------------------------------
 * Customs_RawExport --
 *	Start a job running on another machine, but don't fork an
 *	"export" job to handle it -- just return the tcp socket open
 *	to the remote job, or -1 if the job could not be exported.
 *
 * Results:
 *	socket to remote job if ok. If < 0, value is:
 *	    -100    Couldn't find host
 *	    -101    Couldn't create return socket
 *	    -102    Couldn't get name of return socket
 *	    -104    Remote side refused import
 *	   <-200    -(result+200) gives the return status from the
 *		    CUSTOMS_IMPORT call.
 *	This is hokey, but was done quickly to provide debugging info in
 *	pmake.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
int
Customs_RawExport(file, argv, cwd, flags, retSockPtr, permitPtr)
    char    	  *file;    	    /* File to exec */
    char    	  **argv;   	    /* Arguments to give it */
    char    	  *cwd;	    	    /* Current directory. NULL if not
				     * determined */
    int	    	  flags; 	    /* Flags to pass to Customs_Host */
    int	    	  *retSockPtr;	    /* Socket on which return call should be
				     * made when process exits. If < 0, will
				     * return a socket for the purpose. */
    ExportPermit  *permitPtr;	    /* OUT: permit returned by agent */
{
    extern char   	**environ;  /* Current process environment */
    int	    	  	sock;	    /* TCP socket connecting to exported
				     * process */
    struct sockaddr_in 	importServer;	/* Address of server running our
					 * process */
    char    	  	msg[128];   /* Error message from import server */
    Rpc_Stat	  	rstat;	    /* Return status from RPC calls */
    char    	  	buf[MAX_DATA_SIZE]; /* Buffer for outgoing waybill */
    int	    	  	buflen;	    /* Length of buffer */
    char    	  	loccwd[MAXPATHLEN]; /* Place to stuff cwd if not
					     * given */
    struct timeval	timeout;    /* Timeout for IMPORT request (since it's
				     * TCP, there's a different timeout than
				     * normal Customs calls) */
    u_short 	  	retPort;    /* Port number of return call socket for
				     * import server to return the process'
				     * exit status */
    Boolean 	  	ourSock;    /* True if we allocated the return call
				     * socket */
    ExportPermit  	locPermit;  /* Local permit if the caller isn't
				     * interested */

    if (permitPtr == (ExportPermit *)NULL) {
	permitPtr = &locPermit;
    }
    /*
     * Find out where we may go, first.
     */
    rstat = Customs_Host(flags, permitPtr);
    if (rstat != RPC_SUCCESS) {
	return (-(int)rstat);
    } else if (CUSTOMS_FAIL(&permitPtr->addr)) {
	return(CUSTOMS_NOEXPORT);
    }
    /*
     * We have somewhere to go. Now we need to set up the return-call
     * socket so we can pass its port number to the import server. If the
     * caller already has a socket in mind, ourSock is set False.
     */
    if (*retSockPtr < 0) {
	ourSock = True;
	*retSockPtr = Rpc_UdpCreate(True, 0);
	if (*retSockPtr < 0) {
	    return(CUSTOMS_NORETURN);
	}
    } else {
	ourSock = False;
    }
    
    /*
     * Figure out the port number. If this fails, we can't export...
     */
    buflen = sizeof(importServer);
    if (getsockname(*retSockPtr, &importServer, &buflen) < 0) {
	if (ourSock) {
	    (void) close(*retSockPtr);
	}
	return (CUSTOMS_NONAME);
    }
    retPort = importServer.sin_port;
    
    /*
     * Create the TCP socket for talking to the remote process and set up
     * the address of the remote server for doing the RPC
     */
    sock = Rpc_TcpCreate(False, 0);
    if (sock < 0) {
	if (ourSock) {
	    (void) close(*retSockPtr);
	}
	return(CUSTOMS_NOIOSOCK);
    }
    importServer.sin_family = AF_INET;
    importServer.sin_port = htons(tcpPort);
    importServer.sin_addr = permitPtr->addr;

    /*
     * If they haven't already figured out the current working directory,
     * we have to do it for them.
     */
    if (cwd == (char *)NULL) {
	getwd(loccwd);
	cwd = loccwd;
    }

    /*
     * Using all this information, create a WayBill buffer to pass to
     * the server.
     */
    buflen = Customs_MakeWayBill(permitPtr, cwd, file, argv, environ,
				 retPort, buf);
    /*
     * Call the server. We only send one message, since TCP is "reliable".
     * If we don't get a response in 20 seconds, the export failed.
     */
    timeout.tv_sec = 20;
    timeout.tv_usec = 0;

#ifdef DOUBLECHECK_TIMEOUT
    /*
     * Set import deadline as 2 seconds before timeout...
     */
    time (&((WayBill *)buf)->deadline);
    ((WayBill *)buf)->deadline += 18;
#endif

    rstat = Rpc_Call(sock, &importServer, (Rpc_Proc)CUSTOMS_IMPORT,
		     buflen, (Rpc_Opaque)buf,
		     sizeof(msg), (Rpc_Opaque)msg,
		     1, &timeout);
    lastStatus = rstat;
    /*
     * There are two ways an IMPORT call may fail -- if the server is down,
     * we'll get a RPC error code. If the server denies permission to export,
     * for some reason, it'll return some message other than "Ok".
     * In both cases, we clean up and return < 0 to indicate failure.
     */
    if (rstat != RPC_SUCCESS) {
	if (ourSock) {
	    (void)close(*retSockPtr);
	}
	(void)close(sock);
	return (-200-(int)rstat);
    } else if (strcmp(msg, "Ok") == 0) {
	return (sock);
    } else {
	fprintf(stderr, "CUSTOMS_IMPORT: %s\n", msg);
	if (ourSock) {
	    (void)close(*retSockPtr);
	}
	(void) close(sock);
	return (CUSTOMS_ERROR);
    }
}
#endif /* defined(unix) */
