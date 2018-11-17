/*-
 * import.c --
 *	Functions to import processes.
 *
 * Copyright (c) 1988 by the Regents of the University of California
 * Copyright (c) 1988 by Adam de Boor
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
static char *csid =
"$Id: import.c,v 1.5 93/02/01 11:59:30 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customsInt.h"
#include    "lst.h"
#include    "log.h"
#include    <sys/types.h>
#include    <sys/signal.h>
#include    <sys/wait.h>
#include    <sys/resource.h>
#include    <sys/file.h>
#include    <stdio.h>
#include    <varargs.h>

/*
 * Permits published by the MCA are kept in ImportPermit structures on the
 * permits list until a process actually arrives for them. If one doesn't
 * arrive before the expiration timer goes off, the ImportPermit (and hence
 * the ExportPermit) is discarded.
 */
typedef struct {
    ExportPermit  permit;   	/* Actual permit from MCA */
    Rpc_Event	  expire;   	/* Expiration timer. If this goes off,
				 * the permit gets nuked */
} ImportPermit;

/*
 * A Process structure is assigned to each imported process so it can be
 * killed, its status returned, etc. The ExportPermit for the job is also
 * saved to allow the log server to match a job finish with a start.
 */
typedef struct {
    int	    	  	pid;	    	/* ID of child */
    ImportPermit  	*permit;  	/* Import permit for job */
    struct sockaddr_in 	retAddr;  	/* Address of socket on which to
					 * return the exit status */
    time_t  	    	start;	    	/* Start time */
} Process;

static Lst  	  	permits;    /* List of permits awaiting processes */
static Lst  	  	imports;    /* List of active processes */

/*
 * Once processes are running, we check them every checkInterval seconds.
 * This should probably be changed to catch SIGCHLD and set an event to be
 * taken immediately control returns to Rpc.
 */
static Rpc_Event  	checkEvent;
static struct timeval	checkInterval = {
    1, 0,
};

/*
 * This is the time for which an ImportPermit may remain active without a
 * process.
 */
static struct timeval 	expirationDate = {
    30, 0,
};

static Boolean ImportCheckAll();


/*-
 *-----------------------------------------------------------------------
 * ImportCmpPid --
 *	Callback function for ImportCheckAll to find a Process record
 *	with the given pid.
 *
 * Results:
 *	0 if it matches, non-0 if it doesn't.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
ImportCmpPid(procPtr, pid)
    Process 	  	*procPtr;   	/* Process to examine */
    int	    	  	pid;	    	/* PID desired. */
{
    return (procPtr->pid - pid);
}
	
/*-
 *-----------------------------------------------------------------------
 * ImportHandleKill --
 *	Handle the killing of an imported process.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The signal number is read from the socket and given to the child.
 *
 *-----------------------------------------------------------------------
 */
static void
ImportHandleKill (from, msg, len, data)
    struct sockaddr_in	    *from;
    Rpc_Message	  	    msg;
    int	    	  	    len;
    Rpc_Opaque 	  	    data;
{
    Kill_Data	  	    *packet = (Kill_Data *)data;
    register Process   	    *procPtr;
    LstNode 	  	    ln;
    
    /*
     * Find the Process structure corresponding to the id number
     * given, then kill the process.
     */
    if (Lst_Open(imports) == SUCCESS) {
	while ((ln = Lst_Next(imports)) != NILLNODE) {
	    procPtr = (Process *)Lst_Datum(ln);
	    if (procPtr->permit->permit.id == packet->id) {
		Lst_Close(imports);
		Rpc_Return(msg, 0, (Rpc_Opaque)0);
		if (verbose) {
		    printf("killpg(%d, %d)\n", procPtr->pid, packet->signo);
		}

		(void)killpg(procPtr->pid, packet->signo);
		Log_Send(LOG_KILL, 2,
			 xdr_exportpermit, &procPtr->permit->permit,
			 xdr_long, &packet->signo);
		return;
	    }
	}
	Lst_Close(imports);
    }
    Rpc_Error(msg, RPC_BADARGS);
}

/*-
 *-----------------------------------------------------------------------
 * ImportCheckAll --
 *	Check on all the jobs. This is kinda gross. It just does a wait3
 *	to see if anyone wants to say anything and finishes the job out
 *	if it does.
 *
 * Results:
 *	FALSE.
 *
 * Side Effects:
 *	Jobs will be removed from the imports list, if they actually
 *	finish. If there are no imported jobs left, the event that caused
 *	the invocation of this function is deleted.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ImportCheckAll()
{
    union wait	  status;   	/* Status of child */
    int	    	  pid;	    	/* ID of reporting child */
    LstNode 	  ln;
    Process 	  *procPtr;

    while ((pid=wait3(&status,WNOHANG|WUNTRACED,(struct rusage *)0)) > 0) {
	ln = Lst_Find (imports, (ClientData)pid, ImportCmpPid);
	if (ln != NILLNODE) {
	    procPtr = (Process *)Lst_Datum(ln);
	    (void)Lst_Remove(imports, ln);
	    if (Lst_IsEmpty (imports)) {
		/*
		 * Because ImportProcess may be called while waiting for
		 * a reply to the Avail_Send, we want to make sure to
		 * delete the event as soon as it is unneeded.
		 */
		Rpc_EventDelete(checkEvent);
	    }
	    Avail_Send();
	    free((char *)procPtr->permit);
	    free((char *)procPtr);
	}
    }
    return(FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * ImportExpire --
 *	Delete an expired ImportPermit.
 *
 * Results:
 *	False.
 *
 * Side Effects:
 *	The permit is removed from the permits list and the event that
 *	caused this call back is deleted. An availability packet is
 *	sent to the mca, too, since this expiration could have made the
 *	host available again.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
ImportExpire(ln)
    LstNode 	  	    ln;	    	/* Node of permit to nuke */
{
    ImportPermit  	    *permit;	/* The actual permit */

    permit = (ImportPermit *)Lst_Datum(ln);
    Rpc_EventDelete(permit->expire);
    Lst_Remove(permits, ln);
    free((char *)permit);
    Avail_Send();
}

/*-
 *-----------------------------------------------------------------------
 * ImportAllocated --
 *	Notice that we've been allocated. This call is only allowed to
 *	come from the udp customs port on the master machine (or 127.1
 * 	[localhost] if we are the master).
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
ImportAllocated(from, msg, len, permit)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    ExportPermit  	*permit;
{
    ImportPermit  	*newPermit;
    AllocReply	    	reply;

    if (len != sizeof(ExportPermit)) {
	Rpc_Error (msg, RPC_BADARGS);
    } else if ((from->sin_port == htons(udpPort)) &&
	       ((from->sin_addr.s_addr == masterAddr.sin_addr.s_addr) ||
		(amMaster && Local(from))))
    {
	if (verbose) {
	    printf ("Incoming process from %s (id %u)\n",
		    InetNtoA(permit->addr), permit->id);
	}
	
	newPermit = (ImportPermit *)malloc (sizeof (ImportPermit));
	newPermit->permit = *permit;
	Lst_AtEnd (permits, (ClientData)newPermit);
	newPermit->expire =
	    Rpc_EventCreate(&expirationDate, ImportExpire,
			    (Rpc_Opaque)Lst_Last(permits));
	reply.avail = Avail_Local(AVAIL_EVERYTHING, &reply.rating);
	Rpc_Return(msg, sizeof(reply), (Rpc_Opaque)&reply);
    } else {
	printf ("Attempted Allocation from %d@%s\n",
		ntohs(from->sin_port), InetNtoA(from->sin_addr));
	printf ("Master = %s\n", InetNtoA(masterAddr.sin_addr));
	Rpc_Error(msg, RPC_ACCESS);
	Log_Send(LOG_ACCESS, 1, xdr_sockaddr_in, from);
    }
}

/*-
 *-----------------------------------------------------------------------
 * ImportFindID --
 *	Look for a permit with the given id number. Callback procedure
 *	for ImportProcess.
 *
 * Results:
 *	0 if the current permit matches. non-zero otherwise.
 *
 * Side Effects:
 *	None
 *
 *-----------------------------------------------------------------------
 */
static int
ImportFindID (permit, id)
    ImportPermit  *permit;
    u_long  	  id;
{
    return (permit->permit.id - id);
}

/*-
 *-----------------------------------------------------------------------
 * ImportPrintPermit --
 *	Print out a permit...Used by ImportProcess in verbose mode.
 *
 * Results:
 *	Always returns 0.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static int
ImportPrintPermit (permitPtr)
    ImportPermit  *permitPtr;
{
    printf ("#%u to %s, ", permitPtr->permit.id,
	    InetNtoA(permitPtr->permit.addr));
    return (0);
}

/*-
 *-----------------------------------------------------------------------
 * ImportExtractVector --
 *	Extract an array of strings from a buffer and return a vector of
 *	char pointers. Used by ImportProcess to get the argv and envp for
 *	the new process.
 *
 * Results:
 *	A dynamically-allocated vector of char *'s.
 *
 * Side Effects:
 *	*strPtrPtr is set to point beyond the extracted strings.
 *
 *-----------------------------------------------------------------------
 */
static char **
ImportExtractVector(strPtrPtr)
    char    	  **strPtrPtr;
{
    register char *cp;
    register char **vec;
    register int  numStrings;
    char    	  **vecPtr;

    cp = *strPtrPtr;
    numStrings = *(int *)cp;
    vecPtr = (char **)malloc((unsigned)((numStrings + 1) * sizeof(char *)));
    cp += sizeof(int);
    for (vec = vecPtr; numStrings != 0; vec++, numStrings--) {
	*vec = cp;
	cp += strlen(cp) + 1;
    }
    *vec = (char *)0;
    cp = Customs_Align(cp, char *);
    *strPtrPtr = cp;
    return(vecPtr);
}

/*-
 *-----------------------------------------------------------------------
 * ImportProcess --
 *	Import a process from another machine. Requires an unique ID
 *	which is communicated by the MCA in the CustomsAlloc call.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
static void
ImportProcess (from, msg, len, wbPtr)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    WayBill 	  	*wbPtr;
{
    LstNode 	  	ln; 	    	/* Node of published permit */
    ImportPermit  	*permit;    	/* The permit itself */
    Process 	  	*proc;	    	/* Structure to track job */
    int	    	  	sock;	    	/* I/O socket for job */
    char    	  	*cp;	    	/* General char pointer */
    char    	  	*cwd;	    	/* Directory for job */
    char    	  	*file;	    	/* File to exec */
    char    	  	**argv;	    	/* Arguments for it */
    char    	  	**envp;	    	/* Environment for job */
    extern char	  	**environ;  	/* Current environment */
    int	    	  	permituid;  	/* UID in permit's ID */
    int	    	    	retries;    	/* Retries left for changing to the
					 * cwd */

#if defined(__STDC__)
#define ERROR(str) Rpc_Return(msg, sizeof(#str), (Rpc_Opaque)#str); \
                   (void)close(sock);\
                   Rpc_Ignore(sock);\
		   return;
#else
#define ERROR(str) Rpc_Return(msg, sizeof("str"), (Rpc_Opaque)"str"); \
                   (void)close(sock);\
                   Rpc_Ignore(sock);\
		   return;
#endif /* __STDC__ */

    sock = Rpc_MessageSocket(msg);
    
    ln = Lst_Find (permits, (ClientData)wbPtr->id, ImportFindID);
    if (ln == NILLNODE) {
	if (verbose) {
	    if (Lst_IsEmpty (permits)) {
		printf ("No permits issued\n");
	    } else {
		printf ("No permit for %u: ", wbPtr->id);
		Lst_ForEach (permits, ImportPrintPermit, (ClientData)0);
		putchar('\n');
	    }
	}
	ERROR(No permit issued to you);
    } else {
	permit = (ImportPermit *)Lst_Datum (ln);
	Rpc_EventDelete(permit->expire);
	(void) Lst_Remove (permits, ln);
	if (permit->permit.addr.s_addr != from->sin_addr.s_addr) {
	    ERROR(Invalid address);
	}
	if (verbose) {
	    printf ("Received IMPORT from %s\n",
		    InetNtoA(permit->permit.addr));
	}
	
#ifndef INSECURE
	/*
	 * Make sure the person's not trying to execute as root...
	 */
	if (wbPtr->ruid == 0 || wbPtr->euid == 0) {
	    printf ("Attempted execution as ROOT\n");
	    /*
	     * We don't care if this RPC times out...
	     */
	    Log_Send(LOG_ACCESS, 1, xdr_sockaddr_in, from);
	    ERROR(Root execution not allowed);
	}
#endif /* INSECURE */
	/*
	 * The effective uid of the caller is encoded in the high word of
	 * permit id. We make sure it matches the id in the WayBill
	 * to prevent one source of fraud
	 */
	permituid = (wbPtr->id >> 16) & 0xffff;
	
	if (wbPtr->euid != permituid) {
	    printf ("Mismatched uid's (permit = %d, waybill=%d)\n",
		    permituid, wbPtr->euid);
	    Log_Send(LOG_ACCESS, 1, xdr_sockaddr_in, from);
	    ERROR(Mismatched user IDs);
	}

	cp = (char *)&wbPtr[1];
	cwd = cp;
	cp += strlen(cwd) + 1;
	file = cp;
	cp += strlen(file) + 1;
	cp = Customs_Align(cp, char *);
	argv = ImportExtractVector(&cp);
	envp = ImportExtractVector(&cp);
	
	proc = (Process *) malloc (sizeof (Process));
	proc->permit = permit;
	proc->retAddr = *from;
	proc->retAddr.sin_port = wbPtr->port;

	time(&proc->start);
	

#ifdef DOUBLECHECK_TIMEOUT
	/*
	 * Check for export deadline expiration.  If we weren't able to get
	 * to this point in the time alotted, we give up.
	 */
	if (wbPtr->deadline && proc->start > wbPtr->deadline) {
	    printf ("Import from %d@%s took %ld secs too long\n",
		    ntohs(from->sin_port), InetNtoA(from->sin_addr),
		    proc->start - wbPtr->deadline);
	    ERROR("Import took too long");
	}
#endif /* DOUBLECHECK_TIMEOUT */

	Rpc_Return(msg, sizeof("Ok"), (Rpc_Opaque)"Ok");
	
	fflush(stdout);

	proc->pid = fork();
	if (proc->pid == 0) {
	    /*
	     * Child process:
	     * Set std{in,out,err} to send things to and receive things from
	     * the remote machine. Files opened for other jobs will close when
	     * we exec... Once that is done, attempt to set up the running
	     * environment:
	     *	  1) set both gids
	     *	  2) install all the groups the caller is in
	     *	  3) set both uids
	     *	  4) chdir to the working directory
	     *	  5) set the umask correctly.
	     * Then fork and execute the given command using the passed
	     * environment instead of our own. If any of these steps fails,
	     * we print an error message for pen pal to read and return a
	     * non-zero exit status.
	     */
	    union wait	status;
	    int	  	cpid;
	    int	  	oldstdout;
	    int	    	on = 1;

	    /*
	     * Reset our priority to 0 since we're just another job now
	     */
	    setpriority(PRIO_PROCESS, getpid(), 0);

	    /*
	     * Allow re-use of this address so if agent restarts, it won't
	     * die (maybe)
	     */
	    (void)setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &on, sizeof(on));

	    oldstdout = dup(1);
	    
	    if (sock != 0) {
		dup2 (sock, 0);
	    }
	    if (sock != 1) {
		dup2 (sock, 1);
	    }
	    if (sock != 2) {
		dup2 (sock, 2);
	    }
	    status.w_status = 0;
	    
	    environ = envp;
	    
	    if (setregid (wbPtr->rgid, wbPtr->egid) < 0) {
		perror("Couldn't set real/effective group ids");
		status.w_retcode = 1;
	    }
#define min(a,b) ((a)<(b)?(a):(b))
	    if (setgroups (min(wbPtr->ngroups, NGROUPS), wbPtr->groups) < 0){
		perror("Couldn't set groups");
		status.w_retcode = 2;
	    }
	    if (setreuid (wbPtr->ruid, wbPtr->euid) < 0) {
		perror("Couldn't set real/effective user ids");
		status.w_retcode = 3;
	    }
	    for (retries = 4; retries > 0; retries--) {
		if (chdir (cwd) == 0) {
		    break;
		} else {
		    sleep(1);
		}
	    }
	    if (retries == 0) {
		perror("Couldn't change to current directory");
		printf("cwd = \"%s\"\n", cwd);
		fflush(stdout);
		status.w_retcode = 4;
	    }
	    umask (wbPtr->umask);
	    signal (SIGPIPE, SIG_DFL);

	    /*
	     * Under SunOS 4.1, our parent seems to be started with these
	     * three signals ignored, making it impossible for the remote user
	     * to kill an exported job (from pmake, e.g.) by typing Ctrl+C, so
	     * ensure their handling is the default. -- ardeb 9/1/92
	     */
	    signal (SIGINT, SIG_DFL);
	    signal (SIGHUP, SIG_DFL);
	    signal (SIGQUIT, SIG_DFL);

	    /*
	     * Don't want to do anything our parent is doing, so reset
	     * the RPC system and close the service sockets.
	     */
	    Rpc_Reset();
	    (void)close(tcpSocket);
	    (void)close(udpSocket);
	    setpgrp(0, getpid());

	    if (status.w_status == 0) {
		/*
		 * If we're still ok, fork and exec the program to
		 * be run, then wait for it to finish. We do a bare
		 * wait since we will suspend when it suspends, etc.
		 * We be a dedicated process...
		 */
		cpid = vfork();
		if (cpid == 0) {
		    close(oldstdout);
		    if (sock > 2) {
			(void)close(sock);
		    }
		    execvp (file, argv);
		    perror("Couldn't exec program");
		    _exit(5);
		} else if (cpid < 0) {
		    perror("Couldn't fork");
		    status.w_retcode = 6;
		}
	    }

	    /*
	     * Block all signals we can. Anything we get, our
	     * child will get too, and we will exit when it does,
	     * so there's no point in our dying without sending
	     * a status back, is there?
	     */
	    sigblock(~0);

	    /*
	     * Substitute new socket for sending log messages and exit
	     * statuses.
	     */
	    udpSocket = Rpc_UdpCreate(FALSE, 0);

	    /*
	     * No need for us to keep the socket open. Also want to print
	     * our messages to the log file, so redup the old stdout back to
	     * stream 1.
	     */
	    if (sock != 0) {
		close(0);
	    }
	    if (sock != 1) {
		close(1);
	    }
	    if (sock != 2) {
		close(2);
	    }
	    dup2(oldstdout, 1);
	    close(oldstdout);
	    
	    while (1) {
		Rpc_Stat    rstat;
		char	    oob;
		Exit_Data   retVal;
		
		if (status.w_status == 0) {
		    /*
		     * Haven't got an exit status yet, so wait for one.
		     * We block on the wait since we've got nothing better
		     * to do.
		     */
		    int	pid;
		    do {
			pid = wait3(&status, WUNTRACED, (struct rusage *)0);
		    } while ((pid != cpid) && (pid > 0));
		}

		/*
		 * Force an EOF-equivalent on the socket on the remote side
		 */
		if (send(sock, &oob, 1, MSG_OOB) < 0) {
		    perror("sendOOB");
		}
		
		close(sock);
		
		/*
		 * Return exit status. We don't really care if the
		 * other side receives it. We're very optimistic.
		 * They'll find out either by the RPC or by the socket
		 * going away...
		 */
		if (verbose) {
		    printf("Calling %d@%s\n", ntohs(proc->retAddr.sin_port),
			   InetNtoA(proc->retAddr.sin_addr));
		}
		
		retVal.id = permit->permit.id;
		retVal.status = status.w_status;
		
		rstat = Rpc_Call(udpSocket, &proc->retAddr,
				 (Rpc_Proc)CUSTOMS_EXIT,
				 sizeof(retVal), (Rpc_Opaque)&retVal,
				 0, (Rpc_Opaque)0,
				 CUSTOMSINT_NRETRY, &retryTimeOut);
		if (rstat != RPC_SUCCESS) {
		    Log_Send(LOG_EXITFAIL, 1,
			     xdr_exportpermit, &permit->permit);
		}
		
		if (verbose) {
		    if (WIFSIGNALED(status)) {
			printf("%d: signal %d\n", cpid, status.w_termsig);
		    } else if (WIFSTOPPED(status)) {
			printf("%d: stopped(%d)\n", cpid, status.w_stopsig);
		    } else {
			printf("%d: exit(%d)\n", cpid, status.w_retcode);
		    }
		    if (rstat != RPC_SUCCESS) {
			printf("EXIT call failed: %s\n",
			       Rpc_ErrorMessage(rstat));
		    }
		}
		if (!WIFSTOPPED(status)) {
		    /*
		     * The process is actually done, so break out of this
		     * loop after telling the logger that the job is
		     * finished.
		     */
		    Log_Send(LOG_FINISH, 2,
			     xdr_exportpermit, &permit->permit,
			     xdr_int, &status);
		    break;
		} else {
		    /*
		     * Tell logger the job is just stopped and loop.
		     */
		    Log_Send(LOG_STOPPED, 1,
			     xdr_exportpermit, &permit->permit);
		    status.w_status = 0;
		}
	    }
	    exit(0);
	} else if (proc->pid == -1) {
	    /*
	     * Couldn't fork:
	     * close everything we just opened and return an error.
	     */
	    free ((Address) proc);
	    free((char *)argv);
	    free((char *)envp);
	    ERROR(Could not fork);
	} else {
	    /*
	     * Parent process:
	     * Close the socket and start up the child reaper to catch dead
	     * children if it isn't going already (it won't be if there were
	     * no jobs running before this one).
	     */

	    Rpc_Ignore(sock);
	    (void)close(sock);
	    if (Lst_IsEmpty (imports)) {
		checkEvent = Rpc_EventCreate (&checkInterval, ImportCheckAll,
					      (Rpc_Opaque)0);
	    }
	    Lst_AtEnd (imports, (ClientData)proc);

	    Log_Send(LOG_START, 4,
		       xdr_exportpermit, &permit->permit,
		       xdr_short, &wbPtr->euid,
		       xdr_short, &wbPtr->ruid,
		       xdr_strvec, &argv);
	    free((char *)argv);
	    free((char *)envp);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Import_NJobs --
 *	Return the number of imported jobs. This includes not only
 *	currently-running jobs, but potential jobs as well. This is to
 *	keep the quota from being overflowed by requesting enough hosts
 *	to cause this machine to be overallocated before it can send
 *	of an availability packet...Better to overestimate the number
 *	of jobs and have this machine unavailable than to overload this
 *	machine...
 *
 * Results:
 *	The number of jobs.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Import_NJobs()
{
    return (Lst_Length (imports) + Lst_Length(permits));
}

/*-
 *-----------------------------------------------------------------------
 * Import_Init --
 *	Initialize this module.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The imports list is initialized.
 *
 *-----------------------------------------------------------------------
 */
void
Import_Init()
{
    imports = Lst_Init (FALSE);
    permits = Lst_Init (FALSE);
    (void)signal (SIGPIPE, SIG_IGN);

    Rpc_ServerCreate(tcpSocket, (Rpc_Proc)CUSTOMS_IMPORT, ImportProcess,
		     Swap_WayBill, Rpc_SwapLong, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_ALLOC, ImportAllocated,
		     Swap_ExportPermit, Rpc_SwapLong, (Rpc_Opaque)0);
    Rpc_ServerCreate(udpSocket, (Rpc_Proc)CUSTOMS_KILL, ImportHandleKill,
		     Swap_Kill, Rpc_SwapNull, (Rpc_Opaque)0);
}
