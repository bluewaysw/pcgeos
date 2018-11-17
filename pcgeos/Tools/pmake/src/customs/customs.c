/*-
 * customs.c --
 *	A server to inform clients, using RPC, where they can send
 *	processes.
 *
 *	Each machine that wishes to export processes must have
 *	a server running. The first server to start is the
 *	Master Customs Agent (MCA), while everything else is a
 *	Slave Customs Agent (SCA).
 *
 *	The job of the MCA is to track the availability of machines
 *	running SCA's and allocate them to other SCA's as necessary.
 *
 *	An SCA is responsible for sampling its host's status from
 *	time to time to see if it can accept processes from other
 *	machines. This information must be provided to the MCA
 *	at regular intervals.
 *
 *	An SCA can specify which hosts it is willing to serve for
 *	(there must be at least one) and the MCA will only allocate
 *	it to one of the hosts in that list. A host will not be allocated
 *	to an SCA again until all other available hosts which serve
 *	the requesting SCA have been used.
 *
 *	Several procedures are provided to clients of the customs agents.
 *	The CUSTOMSPROC_HOST will return a structure containing the address
 *	of a machine on which the exported process may be run. It also
 *	returns an identifying number which must be passed to the serving
 *	machine before it will execute the process. The MCA does not guarantee
 *	that the serving machine is actually up, though it tries hard to
 *	ensure this. If the machine has a long interval between availability
 *	packets, all bets are off.
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
 *
 */
#ifndef lint
static char *rcsid =
"$Id: customs.c,v 1.5 93/01/30 15:37:06 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "sprite.h"
#include    "customsInt.h"

#include    <sys/file.h>
#include    <errno.h>
#include    <stdio.h>
#include    <sys/ioctl.h>
#include    <strings.h>
#include    <signal.h>
#include    <sys/resource.h>
#include    <netdb.h>

char	    	  	    localhost[MACHINE_NAME_SIZE];
Boolean	    	  	    amMaster;	/* TRUE if this process is MCA */
Boolean	    	    	    canBeMaster = FALSE;    /* TRUE if this agent may
						     * become the MCA */

Boolean	    	  	    verbose = FALSE;

unsigned long	    	    arch;   	/* Machine architecture code */
char	    	  	    *regPacket;
int	    	  	    regPacketLen;
int	    	  	    numClients;
char	    	  	    **clients;
int	    	  	    initARGC;
char    	  	    **initARGV;


struct timeval	retryTimeOut = {
    CUSTOMSINT_RETRY, CUSTOMSINT_URETRY
};

/*
 * Default ports if yellow pages f***s us over
 */
#define DEF_CUSTOMS_UDP_PORT	8231
#define DEF_CUSTOMS_TCP_PORT	8231

short	    	    	    tcpPort;
int	    	  	    tcpSocket;
short			    udpPort;
int	    	  	    udpSocket;	/* The actual socket to which clients
					 * connect */
struct sockaddr_in	    localAddr;	/* Address of local socket */

/*-
 *-----------------------------------------------------------------------
 * MakeRegistrationPacket --
 *	Mangles the local host and argument vector into a packet to
 *	be sent to the master at registration time.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	regPacket is allocated and filled and regPacketLen is altered.
 *
 *-----------------------------------------------------------------------
 */
static void
MakeRegistrationPacket(void)
{
    register int  i;
    register char **cpp;
    register char *cp;
    int localhostLen;

    localhostLen = (strlen(localhost) + 1 + 3) & ~3;
    regPacketLen = localhostLen + sizeof(long) + sizeof(arch);
    for (i = 0; i < numClients; i++) {
	regPacketLen += strlen(clients[i]) + 1;
    }
    regPacket = (char *)malloc((unsigned)regPacketLen);
    strncpy (regPacket, localhost, localhostLen);
    cp = regPacket + localhostLen;
    *((unsigned long *)cp) = arch;
    cp += sizeof(arch);
    *((long *)cp) = numClients;
    cp += sizeof(long);

    for (cpp = clients, i = numClients; i != 0; i--, cpp++) {
	strcpy(cp, *cpp);
	cp += strlen(cp) + 1;
    }
}

/*-
 *-----------------------------------------------------------------------
 * CustomsPing --
 *	Do-nothing function to handle the CUSTOMS_PING procedure.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
CustomsPing( struct sockaddr_in	       *from,
    	     Rpc_Message	  	msg,
             int	    	  	len,
             Rpc_Opaque 	  	data)
{
    Rpc_Return(msg, 0, data);
}

/*-
 *-----------------------------------------------------------------------
 * CustomsHost --
 *	Stub for handling the CUSTOMS_HOST procedure. Issues
 *	CUSTOMS_HOSTINT call to master. While the master could conceivably
 *	call MCA_HostInt, we don't do that b/c the port number for return
 *	will be wrong. If the flags in the data contain EXPORT_USELOCAL,
 *	the availability of the local machine is checked before the call
 *	is issued.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An ExportPermit is sent in reply.
 *
 *-----------------------------------------------------------------------
 */
static void
CustomsHost( struct sockaddr_in	*from,
    Rpc_Message	  	msg,
    int	    	  	len,
    Rpc_Opaque	  	data)
{
    ExportPermit    	permit;
    Host_Data	  	*host = (Host_Data *)data;
    long    	    	rating;	/* Junk variable */

    /*
     * A CustomsHost call must come from the local host to
     * keep people from requesting from a different machine, not
     * that it would work anyway, since the permit published
     * by the MCA wouldn't match...
     */
    if (!Local(from)) {
	Rpc_Error(msg, RPC_ACCESS);
    } if (len != sizeof(Host_Data)) {
	Rpc_Error(msg, RPC_BADARGS);
    } else if (Elect_InProgress() ||
	       ((host->flags & EXPORT_USELOCAL) &&
		Avail_Local (~AVAIL_IDLE, &rating) == 0))
    {
		   
	/*
	 * If we're electing, or being nice and the local machine is
	 * available, barring keyboard idle time, of course, then
	 * send a failure message to the client -- the id field is
	 * unimportant in this case...
	 */
	permit.addr.s_addr = INADDR_ANY;
	Rpc_Return(msg, sizeof(permit), (Rpc_Opaque)&permit);
    } else {
	/*
	 * Ask the master where to go.
	 */
	Rpc_Stat  	rstat;

	rstat = Rpc_Call(udpSocket, &masterAddr, (Rpc_Proc)CUSTOMS_HOSTINT,
			 len, data, sizeof(permit), (Rpc_Opaque)&permit,
			 CUSTOMSINT_NRETRY, &retryTimeOut);
	if (rstat != RPC_SUCCESS) {
	    permit.addr.s_addr = INADDR_ANY;
	    if (verbose) {
		printf ("HostInt: %s\n", Rpc_ErrorMessage(rstat));
	    }
	} else if (verbose) {
	    printf ("Host call generates %s response\n",
		    InetNtoA(permit.addr));
	}
	Rpc_Return(msg, sizeof(permit), (Rpc_Opaque)&permit);
	if (rstat == RPC_TIMEDOUT) {
	    Elect_GetMaster();
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * CustomsMaster --
 *	Stub to handle CUSTOMS_MASTER procedure. Returns the address of
 *	the current master agent.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The address of the master is sent to the client, or an RPC_TIMEDOUT
 *	error is returned if an election is going on.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
CustomsMaster( struct sockaddr_in  *from,
    Rpc_Message		msg,
    int			len,
    Rpc_Opaque 	  	data)
{
    if (Elect_InProgress()) {
	/*
	 * If the call wasn't local, it must be another lost agent looking
	 * for its master. Since we can't help it there, we don't reply at all.
	 */
	if (Local(from)) {
	    Rpc_Error(msg, RPC_TIMEDOUT);
	}
    } else if (Local(from) ||
	       ((len == sizeof(elect_Token)) && (*(long *)data == elect_Token)))
    {
	/*
	 * Call is local, or it's remote and has the same election token
	 * as we, so send our idea of the current master in return.
	 */
	Rpc_Return(msg, sizeof(masterAddr), (Rpc_Opaque)&masterAddr);
    }
}

/*-
 *-----------------------------------------------------------------------
 * CustomsAbort --
 *	Abort this daemon. Returns nothing. Just exits.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The process exits.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
CustomsAbort( struct sockaddr_in  *from,
    Rpc_Message		msg,
    int			len,
    Rpc_Opaque 	  	data)
{
    Rpc_Return(msg, 0, (Rpc_Opaque)0);
    
    printf("Received ABORT message from %d@%s...\n",
	   ntohs(from->sin_port),
	   InetNtoA(from->sin_addr));
    exit(0);
}

/*-
 *-----------------------------------------------------------------------
 * CustomsRestart --
 *	Re-execute ourselves using the original argument vector.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	We reexecute.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
CustomsRestart( struct sockaddr_in	*from,
    Rpc_Message	  	msg,
    int	    	  	len,
    Rpc_Opaque	  	data)
{
    int	    	  	i;
    int	    	  	fd = open("/dev/null", 0);

    Rpc_Return(msg, 0, (Rpc_Opaque)0);

    printf("Received RESTART from %d@%s\n", ntohs(from->sin_port),
	   InetNtoA(from->sin_addr));
    printf("\texecuting: ");
    for (i = 0; i < initARGC; i++) {
	printf ("%s ", initARGV[i]);
    }
    printf("\n");
    fflush(stdout);

    /*
     * Make sure stdout and stdin are open to something so we don't close
     * the sockets in our next life.
     */
    if (fd != 1) {
	dup2(fd, 1);
    }
    if (fd != 2) {
	dup2(fd, 2);
    }
    if (fd > 2) {
	close(fd);
    }
    execvp(initARGV[0],initARGV);
}

/*-
 *-----------------------------------------------------------------------
 * CustomsDebug --
 *	Turn on debugging for us and/or the rpc system
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	verbose may be set true, as may rpcDebug.
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
CustomsDebug( struct sockaddr_in	*from,
    Rpc_Message	  	msg,
    int	    	  	len,
    int	  	  	*data)
{
    Rpc_Debug(*data & DEBUG_RPC);
    verbose = *data & DEBUG_CUSTOMS;

    Rpc_Return(msg, 0, (Rpc_Opaque)NULL);
}

/*-
 *-----------------------------------------------------------------------
 * gettime --
 *	Get a time value from a string. It must be in the form
 *	    mm:ss
 *	where 'm' is a minute's digit and 's' is a second's degit.
 *	neither number may be greater than 60, for obvious reasons.
 *
 * Results:
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
int
gettime ( char    *str)
{
    int	    min,
	    sec;

    for (min = 0;
	 *str != '\0' && *str != ':' ;
	 min = 10 * min + *str++ - '0') {
	     continue;
    }
    if (*str == '\0') {
	sec = min;
	min = 0;
    } else {
	for (sec = 0, str++; *str != '\0'; sec = 10 * sec + *str++ - '0') {
	    continue;
	}
    }
    if (min >= 60 || sec >= 60) {
	fprintf (stderr, "malformed time (only 60 seconds in a minute and 60 minutes in an hour)\n");
	exit(1);
    }
    return (min * 60 + sec);
}

void CustomsDebugOn(void) { verbose = TRUE; Rpc_Debug(True); }
void CustomsDebugOff(void) { verbose = FALSE; Rpc_Debug(False); }
/*-
 *-----------------------------------------------------------------------
 * Usage --
 *	Print out the flags we accept and die.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The process exits.
 *
 *-----------------------------------------------------------------------
 */
void
Usage (void)
{
    printf ("Usage: customs <options> {host [host ...] | ALL }\n");
    printf ("\t-verbose	    	Print verbose log messages\n");
    printf ("\t-check <time>	Set availability check interval\n");
    printf ("\t-idle <time> 	Set minimum idle time\n");
    printf ("\t-load <load avg>	Set maximum load average\n");
    printf ("\t-swap <percent>	Set minimum free swap space\n");
    printf ("\t-jobs <num>  	Set maximum imported jobs\n");
    printf ("\t-net <netnum>	Set customs network number\n");
    printf ("\t-arch <archcode> Set customs architecture code\n");
    printf ("\t-master	    	Allow agent to become the master, if needed\n");
    exit(1);
}

/*-
 *-----------------------------------------------------------------------
 * main --
 *	Check the correctness of the arguments, look for an MCA and become
 *	it if it doesn't exist, registering ourselves in the process.
 *	Else register with the MCA and go into SCA mode.
 *
 * Results:
 *	none.
 *
 * Side Effects:
 *	Billions and Billions.
 *
 *-----------------------------------------------------------------------
 */
main (int argc, char **argv)
{
    char    	  	logName[256];
    Boolean 	  	doLog = TRUE;
    Boolean 	  	debug = FALSE;
    Avail_Data	  	criteria;
    int	    	  	checkTime;
    struct servent  	*sep;
    int			i;

    clients = (char **)malloc(sizeof(char *) * argc);
    numClients = 0;

    initARGC = argc;
    initARGV = argv;

    argc--, argv++;
    criteria.changeMask = 0;
    checkTime = 0;

    while (argc > 0) {
	if (strcmp (*argv, "-verbose") == 0) {
	    verbose = TRUE;
	} else if (strcmp (*argv, "-nolog") == 0) {
	    doLog = FALSE; debug = TRUE;
	} else if (strcmp (*argv, "-debug") == 0) {
	    debug = TRUE;
	} else if (strcmp (*argv, "-check") == 0) {
	    if (argc > 1) {
		checkTime = gettime(argv[1]);
		argc--;
		argv++;
	    } else {
		printf("-check needs a time as an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp (*argv, "-idle") == 0) {
	    if (argc > 1) {
		criteria.idleTime = gettime(argv[1]);
		argc--;
		argv++;
		criteria.changeMask |= AVAIL_IDLE;
	    } else {
		printf("-idle needs a time as an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp (*argv, "-swap") == 0) {
	    if (argc > 1) {
		criteria.swapPct = atoi(argv[1]);
		argc--;
		argv++;
		criteria.changeMask |= AVAIL_SWAP;
	    } else {
		printf("-swap needs a percentage as an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp (*argv, "-load") == 0) {
	    double	maxLoad, atof();

	    if (argc > 1) {
		maxLoad = atof(argv[1]);
		criteria.loadAvg = (int)(maxLoad * LOADSCALE);
		criteria.changeMask |= AVAIL_LOAD;
		argc--;
		argv++;
	    } else {
		printf("-load needs a load average as an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp (*argv, "-jobs") == 0) {
	    if (argc > 1) {
		criteria.imports = atoi(argv[1]);
		argc--;
		argv++;
		criteria.changeMask |= AVAIL_IMPORTS;
	    } else {
		printf("-jobs needs a number of jobs as an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp (*argv, "-net") == 0) {
	    if (argc > 1) {
		elect_Token = atoi(argv[1]);
		argc--;
		argv++;
	    } else {
		printf("-net needs a network number for an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp (*argv, "-arch") == 0) {
	    if (argc > 1) {
		arch = atoi(argv[1]);
		argc--;
		argv++;
	    } else {
		printf("-arch needs an architecture code for an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp(*argv, "-bias") == 0) {
	    if (argc > 1) {
		avail_Bias = atoi(argv[1]);
		argc--;
		argv++;
	    } else {
		printf("-bias needs a bias value for an argument\n");
		Usage();
		/*NOTREACHED*/
	    }
	} else if (strcmp(*argv, "-master") == 0) {
	    canBeMaster = TRUE;
	} else if (**argv == '-') {
	    printf ("Unknown option %s\n", *argv);
	    Usage();
	    /*NOTREACHED*/
	} else {
	    clients[numClients] = *argv;
	    numClients += 1;
	}
	argc--; argv++;
    }

    if (numClients == 0) {
	printf ("You must serve at least one host!\n");
	exit(1);
    }
	
    if (!debug) {
	int t,
	    pid;

	/*
	 * First detach from our parent, then from the tty...
	 */
	pid = fork();
	if (pid == -1) {
	    perror("fork");
	}
	if (pid != 0) {
	    exit(0);
	}

	t = open ("/dev/tty", O_RDWR, 0);
	if (t >= 0) {
	    ioctl (t, TIOCNOTTY, 0);
	    (void) close (t);
	}

	if (getuid() || geteuid()) {
	    printf ("This program must be run as root to execute properly\n");
	    exit(1);
	}

	/*
	 * Renice the main server so it can respond to calls even if four
	 * of its jobs are running...
	 */
	if (setpriority(PRIO_PROCESS, getpid(), -2) < 0) {
	    perror("setpriority");
	}
    }
    
    if (gethostname (localhost, MACHINE_NAME_SIZE)) {
	printf ("The name of this machine is too long (%d chars max)\n",
		  MACHINE_NAME_SIZE);
	exit(1);
    }

    if (doLog) {
	char *cp = index (localhost, '.');
	if (cp) {
	    *cp = '\0';
	}
	sprintf (logName, "%s.%s", LOG_BASE, localhost);
	freopen (logName, "a", stdout);
	if (cp) {
	    *cp = '.';
	}
	fcntl(1, F_SETFL, FAPPEND);
    }

    for (i = 3; i > 0; i--) {
	sep = getservbyname("customs", "udp");
	if (sep == NULL) {
	    sleep(2);
	} else {
	    break;
	}
    }
    if (sep == NULL) {
	printf("customs/udp (still) unknown\n");
	udpPort = DEF_CUSTOMS_UDP_PORT;
    } else {
	udpPort = ntohs(sep->s_port);
    }
    udpSocket = Rpc_UdpCreate(True, udpPort);
    if (udpSocket < 0) {
	perror ("Rpc_UdpCreate");
	exit(1);
    }

    for (i = 3; i > 0; i--) {
	sep = getservbyname("customs", "tcp");
	if (sep == NULL) {
	    sleep(2);
	} else {
	    break;
	}
    }
    if (sep == NULL) {
	printf("customs/tcp (still) unknown\n");
	tcpPort = DEF_CUSTOMS_TCP_PORT;
    } else {
	tcpPort = ntohs(sep->s_port);
    }
    tcpSocket = Rpc_TcpCreate(True, tcpPort);
    if (tcpSocket < 0) {
	perror("Rpc_TcpCreate");
	exit(1);
    }
    /*
     * Mark both service sockets as close on exec.
     */
    (void)fcntl (udpSocket, F_SETFD, 1);
    (void)fcntl (tcpSocket, F_SETFD, 1);

    /*
     * Register all the servers every agent must handle
     */
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_PING, CustomsPing,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_HOST, CustomsHost,
		     Swap_Host, Swap_ExportPermit, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_MASTER, CustomsMaster,
		     Rpc_SwapNull, Swap_SockAddr, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_ABORT, CustomsAbort,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(tcpSocket, (Rpc_Proc)CUSTOMS_ABORT, CustomsAbort,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_RESTART, CustomsRestart,
		     Rpc_SwapNull, Rpc_SwapNull, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_DEBUG, CustomsDebug,
		     Rpc_SwapLong, Rpc_SwapNull, (Rpc_Opaque)0);
    
    signal(30, CustomsDebugOn);
    signal(31, CustomsDebugOff);
    
    /*
     * Close stdin and stderr so the descriptors are reused by the Avail
     * module. Note that if the Avail module changes to use fewer than two
     * descriptors, you should leave one of these things open so the Import
     * module doesn't have to worry about its socket already being in the
     * right place (dup2 (0, 0) would probably not be cool...)
     */
    fclose (stdin);
    fclose (stderr);

    /*
     * XXX: There should be some way to actually share these things so
     * all the perror-type functions would play with the same things.
     * unfortunately, stderr and stdout are macros, so we can only
     * get around things by making stdout be unbuffered...
     */
    setbuf (stdout, (char *)NULL);
    *stderr = *stdout;
	
    /*
     * Find the local address. get_myaddress is actually from Sun RPC
     * functions, but...
     */
    get_myaddress(&localAddr);
    localAddr.sin_port = htons(udpPort);
    if (verbose) {
	printf ("local address: %d@%s\n",
		ntohs(localAddr.sin_port),
		InetNtoA(localAddr.sin_addr));
    }

    MakeRegistrationPacket();

    Log_Init();
    Avail_Init(&criteria, checkTime);
    Import_Init();
    Elect_Init();
    Elect_GetMaster();

    Rpc_Run();
}

perror( char *str)
{
    extern int errno;
    extern char *sys_errlist[];
    extern int sys_nerr;

    if (errno > sys_nerr) {
	printf("%s: %d\n", str, errno);
    } else {
	printf("%s: %s\n", str, sys_errlist[errno]);
    }
}
