/*-
 * logd.c --
 *	A program to get usage info from all customs agents and
 *	log them in a file in a nice manner.
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
#ifndef lint
static char *rcsid =
"$Id: logd.c,v 1.2 92/04/17 21:52:18 dloft Exp Locker: adam $ SPRITE (Berkeley)";
#endif lint

#include    "customs.h"
#include    "log.h"
#include    <netdb.h>
#include    <stdio.h>
#include    <sys/time.h>
/*#include    "/usr/include/time.h"*/
#include    <pwd.h>
#include    <sys/wait.h>
#include    <varargs.h>
/*#include    <netinet/in.h>*/
#include    <strings.h>

#define LOG_FILE  "/usr/tmp/customs.log"
#define MAXAGENTS 200

typedef struct {
    char    	  	*name;
    long    	  	avail;
    long    	    	rating;
    long		arch;
    long    	  	numClients;
    long    	  	*clients;
    struct in_addr	addr;
} Agent;

Agent 	  agents[MAXAGENTS];
int	    	  numAgents;

typedef struct {
    char    	  **argv;
    int	    	  id;
} Job;

struct sockaddr_in	mca;
Boolean	    	  	force = TRUE;

extern int  	  	customs_Socket;
extern struct timeval	customs_RetryTimeOut;

FILE	    	  	*logFile;

/*-
 *-----------------------------------------------------------------------
 * LogPrintf --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
void
LogPrintf(fmt, va_alist)
    char    	  *fmt;
    va_dcl
{
    va_list 	  args;

    va_start(args);
    _doprnt(fmt, args, logFile);
    fflush(logFile);
}

/*-
 *-----------------------------------------------------------------------
 * LogMark --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
void
LogMark(agent)
    Agent   *agent;
{
    time_t  	  now;
    struct tm	  *curTime;

    now = time(0);
    curTime = localtime(&now);
    LogPrintf("%s %2d:%02d:%02d %d/%d -- ",
	      agent ? agent->name : "LOG", curTime->tm_hour,
	      curTime->tm_min, curTime->tm_sec, curTime->tm_mon + 1,
	      curTime->tm_mday);
}
/*-
 *-----------------------------------------------------------------------
 * FindAgent --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
Agent *
FindAgent(addr)
    struct in_addr	addr;
{
    register int i;

    for (i = 0; i < numAgents; i++) {
	if (agents[i].addr.s_addr == addr.s_addr) {
	    return (&agents[i]);
	}
    }
    return((Agent *)NULL);
}
/*-
 *-----------------------------------------------------------------------
 * Start --
 *	Note starting of a job somewhere.
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
void
Start (from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    char    	  	*data;
{
    XDR	    	  	xdr;
    ExportPermit  	permit;
    short   	  	euid, ruid;
    char    	  	**argv;
    struct passwd 	*pwd;

    xdrmem_create(&xdr, data, len, XDR_DECODE);
    argv = (char **)NULL;

    if (xdr_exportpermit(&xdr, &permit) &&
	xdr_short(&xdr, &euid) &&
	xdr_short(&xdr, &ruid) &&
	xdr_strvec(&xdr, &argv)) {
	    Agent  	*ad, *as;
	    int	  	i;

	    ad = FindAgent(from->sin_addr);
	    as = FindAgent(permit.addr);
	    LogMark(ad);
	    pwd = getpwuid(euid);
	    LogPrintf("#%u ", permit.id);
	    if (pwd != (struct passwd *)NULL) {
		LogPrintf("from %s@%s: ", pwd->pw_name, as->name);
	    } else {
		LogPrintf("from %d@%s: ", euid, as->name);
	    }
	    for (i = 0; argv[i]; i++) {
		LogPrintf("%s ", argv[i]);
	    }
	    LogPrintf("\n");
    }
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * Finish --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
void
Finish (from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    char    	  	*data;
{
    union wait 	  stat;
    ExportPermit  permit;
    XDR	    	  xdr;
    Agent   	  *a;
    
    a = FindAgent(from->sin_addr);
    
    xdrmem_create(&xdr, data, len, XDR_DECODE);
    if (xdr_exportpermit(&xdr, &permit) &&
	xdr_int(&xdr, &stat)) {
	    LogMark(a);
	    LogPrintf("#%u finished ", permit.id);
	    if (WIFSIGNALED(stat)) {
		LogPrintf ("signal %d\n", stat.w_termsig);
	    } else {
		LogPrintf ("exit %d\n", stat.w_retcode);
	    }
    } else {
	LogPrintf ("BAD PACKET from %s\n", a->name);
    }
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * Stopped --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Stopped(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    Rpc_Opaque 	  	data;
{
    ExportPermit  permit;
    XDR	    	  xdr;
    Agent   	  *a;
    
    a = FindAgent(from->sin_addr);
    
    xdrmem_create(&xdr, data, len, XDR_DECODE);
    if (xdr_exportpermit(&xdr, &permit)) {
	LogMark(a);
	LogPrintf("#%u stopped\n", permit.id);
    } else {
	LogPrintf ("BAD PACKET from %s\n", a->name);
    }
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}
/*-
 *-----------------------------------------------------------------------
 * NewAgent --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
NewAgent(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    char    	  	*data;
{
    struct sockaddr_in	addr;
    XDR	    	  	xdr;
    Agent   	  	*a;

    xdrmem_create(&xdr, data, len, XDR_DECODE);
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
    
    if (xdr_sockaddr_in(&xdr, &addr)) {
	a = FindAgent(addr.sin_addr);
	if (a == (Agent *)NULL) {
	    struct hostent *he;
	    
	    a = &agents[numAgents];
	    numAgents++;
	    a->addr = addr.sin_addr;
	    a->numClients = 0;
	    he = gethostbyaddr(&addr.sin_addr, sizeof(addr.sin_addr), AF_INET);
	    if (he != (struct hostent *)NULL) {
		a->name = (char *)malloc(strlen(he->h_name)+1);
		strcpy(a->name, he->h_name);
		if (index(a->name, '.')) {
		    *index(a->name, '.') = '\0';
		}
	    } else {
		a->name = "Unknown";
	    }
	}
	LogMark(0);
	LogPrintf("Agent %s registered\n", a->name);
	(void) Rpc_Call(customs_Socket, &addr, (Rpc_Proc)CUSTOMS_LOG,
			sizeof(force), (Rpc_Opaque)&force,
			0, (Rpc_Opaque)0,
			CUSTOMS_RETRY, &customs_RetryTimeOut);
    }
}
			
/*-
 *-----------------------------------------------------------------------
 * NewMaster --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
NewMaster(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    char    	  	*data;
{
    struct sockaddr_in	addr;
    XDR	    	  	xdr;
    Agent   	  	*a;

    xdrmem_create(&xdr, data, len, XDR_DECODE);
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
    
    a = FindAgent(from->sin_addr);
    LogMark(a);
    LogPrintf("elected master -- %s\n", InetNtoA(from->sin_addr));
    mca = *from;
}
/*-
 *-----------------------------------------------------------------------
 * Evict --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Evict(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    Rpc_Opaque 	  	data;
{
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * Access --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Access(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    char    	  	*data;
{
    struct sockaddr_in	addr;
    XDR	    	  	xdr;
    char    	  	fromname[32];

    xdrmem_create(&xdr, data, len, XDR_DECODE);
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
    
    if (xdr_sockaddr_in(&xdr, &addr)) {
	LogMark(0);
	LogPrintf("illegal access to %s attempted from %s\n",
		  strcpy(fromname, InetNtoA(from->sin_addr)),
		  InetNtoA(addr.sin_addr));
    }
}

/*-
 *-----------------------------------------------------------------------
 * Killed --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Killed(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    Rpc_Opaque 	  	data;
{
    ExportPermit  permit;
    long    	  signo;
    XDR	    	  xdr;
    Agent   	  *a;
    
    a = FindAgent(from->sin_addr);
    
    xdrmem_create(&xdr, data, len, XDR_DECODE);
    if ((xdr_exportpermit(&xdr, &permit)) &&
	(xdr_long(&xdr, &signo)))
    {
	extern char	*sys_siglist[];

	LogMark(a);
	LogPrintf("#%u from %s signaled -- %s\n",
		  permit.id,
		  InetNtoA(permit.addr),
		  sys_siglist[signo]);
    } else {
	LogPrintf ("BAD PACKET from %s\n", a->name);
    }
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * ExitFailed --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
ExitFailed(from, msg, len, data)
    struct sockaddr_in  *from;
    Rpc_Message		msg;
    int			len;
    Rpc_Opaque 	  	data;
{
    ExportPermit  permit;
    XDR	    	  xdr;
    Agent   	  *a;
    
    a = FindAgent(from->sin_addr);
    
    xdrmem_create(&xdr, data, len, XDR_DECODE);
    if (xdr_exportpermit(&xdr, &permit)) {
	LogMark(a);
	LogPrintf("#%u from %s: couldn't send EXIT\n",
		  permit.id,
		  InetNtoA(permit.addr));
    } else {
	LogPrintf ("BAD PACKET from %s\n", a->name);
    }
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * main --
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
main(argc, argv)
    int	    argc;
    char    **argv;
{
    char    	  	infoBuf[MAX_INFO_SIZE];
    int	    	  	i, j;
    char    	  	*cp;
    struct sockaddr_in	sin;
    struct hostent	*he;
    int	    	  	sock;
    extern struct sockaddr_in customs_AgentAddr;

    if (Customs_Master(&mca) != RPC_SUCCESS) {
	Customs_PError("Customs_Master");
	printf("Couldn't find master\n");
	exit(1);
    }
    
    if (Customs_Info(&mca, infoBuf) != RPC_SUCCESS) {
	Customs_PError("Customs_Info");
	printf("Couldn't read registration info\n");
    }

    /*
     * The information about all the hosts is stored in the 'info' buffer
     * in the following format:
     *	<number-of-hosts>   	integer
     *	<host1>	  	    	{
     *	    	  	    	    name (rounded to next 32-bit boundary)
     *	    	  	    	    availability
     *	    	    	    	    availability index
     *				    architecture
     *	    	  	    	    number of clients (0 if ALL)
     *	    	  	    	    indices of clients (0..numClients)
     *	    	  	    	}
     *     .
     *     .
     *     .
     *	<host-n>  	    	ditto
     *	<last-allocated>    	integer (index of host last allocated)
     *
     * Due to the variable size of the host names and client lists, this
     * is not really amenable to a one-dimensional C structure, so...
     */
    if (argc != 2) {
	logFile = fopen (LOG_FILE, "a");
    } else if (strcmp(argv[1], "-") != 0) {
	logFile = fopen (argv[1], "a");
    } else {
	logFile = stdout;
    }
    
    if (logFile == (FILE *)NULL) {
	printf ("Couldn't open log file\n");
	exit(1);
    }

    sin.sin_family = AF_INET;
    sin.sin_port = customs_AgentAddr.sin_port;

    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_START, Start,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_FINISH, Finish,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_STOPPED, Stopped,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_NEWAGENT, NewAgent,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_NEWMASTER, NewMaster,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_EVICT, Evict,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_ACCESS, Access,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_KILL, Killed,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(customs_Socket, (Rpc_Proc)LOG_EXITFAIL, ExitFailed,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    
    LogMark(0);
    cp = infoBuf;
    numAgents = *(int *)cp;
    LogPrintf("%d hosts registered:\n", numAgents);
    cp += sizeof(int);
    for (i = 0; i < numAgents; i++) {
	Rpc_Stat    status;

	agents[i].name = cp;
	cp += strlen(cp) + 1;
	if (index(agents[i].name, '.')) {
	    *index(agents[i].name, '.') = '\0';
	}
	LogPrintf("\t%s: ", agents[i].name);
	cp = Customs_Align(cp, char *);

	agents[i].avail = *(long *)cp;
	cp += sizeof(long);

	agents[i].rating = *(long *)cp;
	cp += sizeof(long);

	agents[i].arch = *(long *)cp;
	cp += sizeof(long);

	agents[i].numClients = *(long *)cp;
	cp += sizeof(long);

	agents[i].clients = (long *)cp;
	cp += agents[i].numClients * sizeof(long);

	he = gethostbyname(agents[i].name);
	bcopy(he->h_addr, &agents[i].addr, sizeof(agents[i].addr));
	sin.sin_addr = agents[i].addr;
	if (agents[i].avail & AVAIL_DOWN) {
	    LogPrintf("marked down\n");
	} else if ((status = Rpc_Call(customs_Socket, &sin,
				      (Rpc_Proc)CUSTOMS_LOG,
				      sizeof(force), (Rpc_Opaque)&force,
				      0, (Rpc_Opaque)0,
				      CUSTOMS_RETRY,
				      &customs_RetryTimeOut)) != RPC_SUCCESS)
	{
	    LogPrintf("couldn't contact: %s\n", Rpc_ErrorMessage(status));
	} else {
	    LogPrintf("registered\n");
	}
			 
    }
    Rpc_Run();
}

