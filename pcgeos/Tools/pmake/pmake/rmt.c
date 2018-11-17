/*-
 * rmt.c --
 *	Functions to handle the exportation of targets using the
 *	customs daemon.
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
 * Interface:
 *	Rmt_Init  	    	Initialize things for this module
 *
 *	Rmt_AddServer	    	Add the given name as the address of
 *	    	  	    	an export server.
 *
 *	Rmt_ReExport	    	Re-export a job that has come home to roost.
 *
 *	Rmt_Begin 	    	Prepare to export another job and tell
 *	    	  	    	if it can actually be exported.
 *
 *	Rmt_Exec  	    	Execute the given shell with argument vector
 *	    	  	    	elsewhere.
 *
 *	Rmt_LastID	    	Return an unique identifier for the last
 *	    	  	    	job exported.
 *
 *	Rmt_Done  	    	Take note that a remote job has finished.
 *
 *	Rmt_Watch   	    	Pay attention to a stream.
 *
 *	Rmt_Ignore  	    	Ignore a stream
 *
 *	Rmt_Wait    	    	Wait for something to happen
 *
 *	Rmt_Signal  	    	Deliver a signal to a job.
 */
#if defined(unix) 
#ifndef lint
static char *rcsid =
"$Id: rmt.c,v 1.4 92/07/28 10:12:25 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    <sys/time.h>
#include    <sys/fcntl.h>
#include    <sys/file.h>
#include    <stdio.h>
#include    <sys/wait.h>
#include    <errno.h>
extern int  errno;

#include    "make.h"
#include    "job.h"

#include    "customs.h"

/*
 * Macro to deal with incompatible calling conventions between gcc and cc on
 * a sparc (gcc passes the address in a register, since the structure is
 * small enough, while cc still passes the address).
 */
#if defined(__GNUC__) && defined(sparc)
#define InetNtoA(addr)	inet_ntoa(&(addr))
#else
#define InetNtoA(addr)	inet_ntoa(addr)
#endif

/*
 * Private data attached to each job exported by this module. The address of
 * such a structure is returned as the remote ID for the job.
 */
typedef struct {
    ExportPermit  permit;   	/* Permit under which job was exported */
    int	    	  rmtFd;    	/* FD of stream to remote job. Needed if
				 * usePipes is FALSE */
    int	    	  cmdFd;  	/* FD of file containing commands */
    int	    	  flags;    	/* Status flags */
#define CP_WRITING  	1   	    /* If set, we're in a loop in RmtIO writing
				     * data to the remote side. The private data
				     * may not be biffed */
#define CP_GONE	    	2   	    /* If set, the job has exited */
    Exit_Data	  eData;    	/* Saved data from exit call if it came in while
				 * CP_WRITING was set */
} CustomsPriv;

static char 	  	cwd[1024];  /* The current working directory */
static Boolean	  	noAgent;    /* TRUE if agent not present */

/*
 * From customslib.c
 */
extern int  	  	customs_Socket;	/* Socket opened by Customs calls */
extern struct timeval	customs_RetryTimeOut;	/* Default retry interval */
extern struct sockaddr_in customs_AgentAddr;

/*
 * For Make-mode exportation.
 */
static int returnFD;
static int exportFD;
static ExportPermit permit;

#include    <sys/ioctl.h>
#include    <netdb.h>

/*-
 *-----------------------------------------------------------------------
 * RmtSwapExit --
 *	Byte-swap an Exit_Data structure.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The words in the Exit_Data structure are byte-swapped.
 *
 *-----------------------------------------------------------------------
 */
static void
RmtSwapExit(length, data)
    int	    	  length;
    Exit_Data	  *data;
{
    Rpc_SwapLong(sizeof(long), &data->id);
    /*
     * Exit status is not swapped since bit fields are byte-order
     * independent.
     */
}

static Boolean printEm = FALSE;	/* Set true if debugging and RmtCmpID
				 * should print out the Job structures as it
				 * checks them. */


/*-
 *-----------------------------------------------------------------------
 * RmtCmpID --
 *	See if a job is remote and has the given ID number
 *
 * Results:
 *	0 if it matches, non-zero if it doesn't
 *
 * Side Effects:
 *	None
 *-----------------------------------------------------------------------
 */
static int
RmtCmpID(job, id)
    Job	    	  *job;
    unsigned long id;
{
    if (printEm) {
	printf("\t%s: ", job->node->name);
	if (job->flags & JOB_REMOTE) {
	    printf("remote #%d\n", ((CustomsPriv *)job->rmtID)->permit.id);
	} else {
	    printf("local #%d\n", job->pid);
	}
    }
    if (job->flags & JOB_REMOTE) {
	return (id - ((CustomsPriv *)job->rmtID)->permit.id);
    } else {
	return(1);
    }
}
/*-
 *-----------------------------------------------------------------------
 * RmtExit --
 *	Handle a call on the returnFD to tell us a job has exited.
 *
 * Results:
 *	Nothing.
 *
 * Side Effects:
 *	A Job is finished out.
 *
 *-----------------------------------------------------------------------
 */
static void
RmtExit(from, msg, len, data)
    struct sockaddr_in	*from;	    /* Call from... */
    Rpc_Message	  	msg;	    /* Token for return */
    int			len;	    /* Length of passed data */
    Rpc_Opaque		data;	    /* Data passed */
{
    Exit_Data	  	*eData;	    /* Data in our format */
    register LstNode	ln; 	    /* Node of finished job */
    register Job  	*job;	    /* The job itself */
    union wait	  	status;	    /* How it died */
    CustomsPriv	    	*pdata;	    /* Our private data */

    if (msg) {
	/*
	 * Acknowledge the call
	 */
	Rpc_Return(msg, 0, (Rpc_Opaque)0);
    }

    eData = (Exit_Data *)data;
    status.w_status = eData->status;

    if (WIFSTOPPED(status)) {
	/*
	 * If the remote job has stopped, it must be because of us -- we've
	 * already continued it, therefore (or will, anyway), so there's no
	 * reason to slap the thing onto the stopped list and confuse things
	 * terribly...so we don't.
	 */
	return;
    }

    ln = Lst_Find(jobs, eData->id, RmtCmpID);
    if (ln == NILLNODE) {
	ln = Lst_Find(stoppedJobs, eData->id, RmtCmpID);
	if (ln != NILLNODE) {
	    Error("Received exit for stopped job, id %d\n", eData->id, 0, 0);
	} else {
	    Error("Received exit for unknown job id %d from %s\n", eData->id,
		  (unsigned long)InetNtoA(from->sin_addr), 0);
	    printEm = TRUE;
	    (void)Lst_Find(jobs, eData->id, RmtCmpID);
	    printEm = FALSE;
	}
	return;
    }

    job = (Job *)Lst_Datum(ln);
    pdata = (CustomsPriv *)job->rmtID;

    /*
     * If we're in a loop in RmtIO, save the data away and let RmtIO call us
     * back...
     */
    if (pdata->flags & CP_WRITING) {
	pdata->eData = *eData;
	pdata->flags |= CP_GONE;
	return;
    }

    if (!usePipes) {
	/*
	 * Flush all data from the socket into the file before calling
	 * JobFinish
	 */
	int	nb;
	char  	buf[512];

	while ((ioctl(pdata->rmtFd, FIONREAD, &nb) == 0) && (nb > 0)) {
	    if (nb > sizeof(buf)) {
		nb = sizeof(buf);
	    }
	    nb = read(pdata->rmtFd, buf, nb);
	    (void)write(job->outFd, buf, nb);
	}
	Rpc_Ignore(pdata->rmtFd);
	(void)close(pdata->rmtFd);
    }

    /*
     * Take it out of the list
     */
    (void)Lst_Remove(jobs, ln);
    nJobs -= 1;

    /*
     * Table no longer full
     */
    jobFull = FALSE;

    /*
     * Finish it out
     */
    free((char *)pdata);
    JobFinish(job, status);
}

/*-
 *-----------------------------------------------------------------------
 * RmtIO  --
 *	Handle I/O transfers between a remote job and the local machine.
 *
 * Results:
 *	Nothing.
 *
 * Side Effects:
 *	None
 *-----------------------------------------------------------------------
 */
static Boolean RmtBlockTimeout() { return (TRUE); }
/*ARGSUSED*/
static void
RmtIO(stream, job, state)
    int	    	  stream;
    Job		  *job;
    int		  state;
{
    CustomsPriv	    *pdata = (CustomsPriv *)job->rmtID;

    if (state & RPC_READABLE) {
	if (usePipes) {
	    /*
	     * If we're using pipes, we can just use JobDoOutput to transfer
	     * the data to the screen.
	     */
	    JobDoOutput(job, FALSE);
	} else {
	    /*
	     * Otherwise, we have to actually write the data to the output
	     * file. Just read a single 1K block each time through.
	     * Magic numbers R us.
	     */
	    char  	buf[1024];
	    int		nb;

	    nb = read(pdata->rmtFd, buf, sizeof(buf));
	    if (nb > 0) {
		write(job->outFd, buf, nb);
	    }
	}
    }
    if (state & RPC_WRITABLE) {
	char	  buf[512];
	int 	  nb;

	nb = read(pdata->cmdFd, buf, sizeof(buf));
	if (nb > 0) {
	    char  *cp;
	    struct timeval tv;
	    Rpc_Event ev;

	    /*
	     * Stop watching for this stream to be writable until this buffer
	     * is written out
	     */
	    Rpc_Watch(pdata->rmtFd, RPC_READABLE, RmtIO, (ClientData)job);

	    /*
	     * Write out the buffer in whatever chunks the socket can swallow
	     */
	    cp = buf;

	    /*
	     * Create a timeout event to be invoked every 200 ms that makes
	     * sure Rpc_Wait will return with reasonable speed.
	     */
	    tv.tv_sec = 0;
	    tv.tv_usec = 200000;
	    ev = Rpc_EventCreate(&tv, RmtBlockTimeout, (Rpc_Opaque)0);
	    pdata->flags |= CP_WRITING;

	    while (nb > 0) {
		int	cc = write(pdata->rmtFd, cp, nb);

		if (cc < 0) {
		    if (errno != EWOULDBLOCK) {
			break;
		    } else {
			cc = 0;
		    }
		}
		cp += cc;
		nb -= cc;
		if (nb > 0) {
		    /*
		     * Give other things a chance while we wait for the
		     * socket to drain enough.
		     */
		    Rpc_Wait();
		}
	    }
	    Rpc_EventDelete(ev);
	    Rpc_Watch(pdata->rmtFd, RPC_READABLE|RPC_WRITABLE, RmtIO,
		      (ClientData)job);

	    pdata->flags &= ~CP_WRITING;

	    if (pdata->flags & CP_GONE) {
		/*
		 * Received an exit call while we were in our loop, so finish
		 * the exit.
		 */
		RmtExit((struct sockaddr_in *)0, (Rpc_Message)0,
			sizeof(pdata->eData), (Rpc_Opaque)&pdata->eData);
	    } else if (nb > 0) {
		Exit_Data   eData;

		if (lastNode != job->node) {
		    printf(targFmt, job->node->name);
		    lastNode = job->node;
		}
		if (errno == EPIPE) {
		    printf("*** connection closed\n");
		} else {
		    perror("*** writing to remote");
		}
		eData.id = pdata->permit.id;
		eData.status = 1;
		RmtExit((struct sockaddr_in *)0, (Rpc_Message)0,
			sizeof(eData), (Rpc_Opaque)&eData);
	    }
	} else {
	    if (nb < 0) {
		perror("*** read(cmd)");
	    }
	    /*
	     * Nothing more to read, so force an EOF on the other side
	     * by doing an out-going shutdown, then only pay attention
	     * to the beast being readable.
	     */
	    shutdown(pdata->rmtFd, 1);
	    Rpc_Watch(pdata->rmtFd, RPC_READABLE, RmtIO, (Rpc_Opaque)job);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * RmtCheckChildren --
 *	Timeout handler for seeing if anyone has died. Simply calls
 *	Job_CatchChildren with block set to FALSE, then returns TRUE to
 *	force Rpc_Wait to exit. This only happens if there are any
 *	jobs running locally.
 *
 * Results:
 *	TRUE.
 *
 * Side Effects:
 *	Job_CatchChildren is called.
 *
 *-----------------------------------------------------------------------
 */
static Boolean
RmtCheckChildren()
{
    int	    oldnj = nJobs;

    if (nLocal > 0) {
	Job_CatchChildren(FALSE);
    }

    return(oldnj != nJobs);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Signal --
 *	Pass a signal to a job. The job module ensures the thing is remote
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	An Rpc is issued to the server for the job to kill the thing
 *	with the same signal.
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Signal(job, signo)
    Job	    	  *job;
    int	    	  signo;
{
    Kill_Data 	    	packet;
    struct sockaddr_in  server;
    Rpc_Stat  	    	rstat;
    CustomsPriv	    	*pdata;

    pdata = (CustomsPriv *)job->rmtID;

    bzero(&server, sizeof(server));
    server.sin_family =     AF_INET;
    server.sin_addr = 	    pdata->permit.addr;
    server.sin_port = 	    customs_AgentAddr.sin_port;

    packet.id =     	    pdata->permit.id;
    packet.signo =  	    signo;

    rstat = Rpc_Call(customs_Socket, &server, (Rpc_Proc)CUSTOMS_KILL,
		     sizeof(packet), (Rpc_Opaque)&packet,
		     0, (Rpc_Opaque)0,
		     CUSTOMS_NRETRY, &customs_RetryTimeOut);

    if (rstat != RPC_SUCCESS) {
	printf("sending signal %d to %s: %s\n", signo, job->node->name,
	       Rpc_ErrorMessage(rstat));
    }
}


/*-
 *-----------------------------------------------------------------------
 * Rmt_Init --
 *	Initialize this module...
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The current working directory is placed in cwd and noAgent set
 *	FALSE if the local customs agent could be contacted.
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Init()
{
    Rpc_Stat	  status;
    struct timeval waitTime;	/* Interval at which to wake up to check for
				 * dead children */

    if (noExport || ((status = Customs_Ping()) != RPC_SUCCESS)) {
	if (DEBUG(RMT) && !noExport) {
	    printf("Could not contact customs agent: %s\n",
		   Rpc_ErrorMessage(status));
	}
	noAgent = TRUE;
    } else {
	if (DEBUG(RMT)) {
	    Rpc_Debug(1);
	}

	noAgent = FALSE;

	Rpc_ServerCreate(customs_Socket, (Rpc_Proc)CUSTOMS_EXIT,
			 RmtExit, RmtSwapExit, Rpc_SwapNull,
			 (Rpc_Opaque)0);

	getwd(cwd);
	if (DEBUG(RMT)) {
	    printf("Customs agent present. cwd = \"%s\"\n", cwd);
	}

	signal (SIGPIPE, SIG_IGN); /* This isn't right. Should use signal
				    * to check on remote jobs, or something. */
    }

    /*
     * Set up an event to check if any children have died.
     */
    waitTime.tv_sec = SEL_SEC;
    waitTime.tv_usec = SEL_USEC;
    (void)Rpc_EventCreate(&waitTime, RmtCheckChildren, (Rpc_Opaque)0);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_AddServer --
 *	Add a server to the list of those known.
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
void
Rmt_AddServer (name)
    char    *name;
{
}
/*-
 *-----------------------------------------------------------------------
 * Rmt_Begin --
 *	Prepare to export a job -- the Make-mode interface to Customs.
 *
 * Results:
 *	TRUE if the job can be exported. FALSE if it cannot.
 *
 * Side Effects:
 *	A TCP connection is opened to an available server and the
 *	CUSTOMS_IMPORT command issued (i.e. the job is started
 *	over there). exportFD is set to the fd of the connection and
 *	returnFD to the fd of the socket to be used to return the exit
 *	status.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
Boolean
Rmt_Begin (file, argv, gn)
    char    	  *file;
    char    	  **argv;
    GNode   	  *gn;
{
    if (noAgent) {
	return (FALSE);
    } else {
	extern int errno;
	int flags;

	returnFD = -1;
	errno = 0;

	flags = ((gn->type & OP_EXPORTSAME) ? EXPORT_SAME : EXPORT_ANY)|
		((gn->type & OP_M68020) ? EXPORT_68020 : 0);
	if (DEBUG(RMT)) {
	    printf("Rmt_Begin: flags = %d\n", flags);
	}
	exportFD = Customs_RawExport(file, argv, cwd,
				     flags,
				     &returnFD,
				     &permit);
	if (exportFD < 0) {
	    if (DEBUG(RMT)) {
		perror("Customs_RawExport");
		Customs_PError(file);
	    }
	    return (FALSE);
	} else {
	    struct hostent *he;

	    if (!beSilent) {
		he = gethostbyaddr(&permit.addr,
				   sizeof(permit.addr),
				   AF_INET);
		if (he == (struct hostent *)NULL) {
		    printf("*** exported to %s (id %u)\n",
			   InetNtoA(permit.addr),
			   permit.id);
		} else {
		    printf("*** exported to %s (id %u)\n", he->h_name,
			   permit.id);
		}
	    }

	    return (TRUE);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Exec --
 *	Execute a process elsewhere. If the exportation actually succeeded
 *	(exportFD > 0), the "export" program is executed (must be on the
 *	search path) with the -id flag.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	That remains to be seen.
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Exec (file, args, traceMe)
    char    *file;
    char    **args;
    Boolean traceMe;
{
    if (exportFD > 0) {
	char	  fd1[4], fd2[4];
	char	  id[10];
	char	  *argv[6];

	sprintf (fd1, "%d", exportFD);
	sprintf (fd2, "%d", returnFD);
	sprintf (id, "%08x", permit.id);

	argv[0] = "export to";
	argv[1] = "-id";
	argv[2] = fd1;
	argv[3] = fd2;
	argv[4] = id;
	argv[5] = (char *)0;
	if (DEBUG(RMT)) {
	    printf("export -id %s %s %s\n", argv[2], argv[3], argv[4]);
	}
	(void)execvp ("export", argv);
	if (DEBUG(RMT)) {
	    perror("Couldn't exec \"export\"");
	}
    } else {
	if (DEBUG(RMT)) {
	    printf("Rmt_Exec called when exportFD == %d\n", exportFD);
	}
	(void)execvp (file, args);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Export --
 *	Prepare to export a job -- the PMake-mode interface to customs.
 *
 * Results:
 *	TRUE if the job can be exported. FALSE if it cannot.
 *
 * Side Effects:
 *	A TCP connection is opened to an available server and the
 *	CUSTOMS_IMPORT command issued (i.e. the job is started
 *	over there). job->rmtFd is set to the fd of the connection and
 *	job->permit to the permit under which the job is running. If
 *	usePipes is TRUE, the pipes that were opened in JobStart are
 *	closed again and job->inPipe is set to job->rmtFd to allow
 *	us to use JobDoOutput to handle the output.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
Boolean
Rmt_Export (file, argv, job)
    char    	  *file;    	    	/* File to exec */
    char    	  **argv;   	    	/* Arguments to it */
    Job   	  *job;	    	    	/* Job descriptor for it */
{
    if (noAgent) {
	return (FALSE);
    } else {
	extern int errno;
	struct timeval now, then;
	int flags;
	CustomsPriv *data = (CustomsPriv *)malloc(sizeof(CustomsPriv));

	errno = 0;
	flags = ((job->node->type & OP_EXPORTSAME) ? EXPORT_SAME : EXPORT_ANY)|
		((job->node->type & OP_M68020) ? EXPORT_68020 : 0);

	if (DEBUG(RMT)) {
	    printf("Rmt_Export: flags = %d\n", flags);
	    gettimeofday(&now, 0);
	}

	data->flags = 0;
	data->rmtFd = Customs_RawExport(file, argv, cwd, flags,
					&customs_Socket,
					&data->permit);
	if (DEBUG(RMT)) {
	    gettimeofday(&then, 0);
	    then.tv_usec -= now.tv_usec;
	    if (then.tv_usec < 0) {
		then.tv_usec += 1000000;
		then.tv_sec -= now.tv_sec + 1;
	    } else {
		then.tv_sec -= now.tv_sec;
	    }
	    printf("*** time spent calling: %d.%06d s\n",
		   then.tv_sec, then.tv_usec);
	}

	if (data->rmtFd < 0) {
	    if (DEBUG(RMT)) {
		perror("Customs_RawExport");
		Customs_PError(file);
	    } else {
		if (data->rmtFd > -100) {
		    if (usePipes) {
			printf (targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf("*** error calling local server: %s\n",
			   Rpc_ErrorMessage(-data->rmtFd));
		} else switch(data->rmtFd) {
		case CUSTOMS_NOEXPORT:
		    /*
		     * Just couldn't export -- no biggie.
		     */
		    break;
		case CUSTOMS_NORETURN:
		    /*
		     * Couldn't create return socket
		     */
		    if (usePipes) {
			printf (targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf("*** error exporting: couldn't create return socket\n");
		    break;
		case CUSTOMS_NONAME:
		    /*
		     * Couldn't fetch name of socket
		     */
		    if (usePipes) {
			printf (targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf("*** error exporting: couldn't find name of return socket\n");
		    break;
		case CUSTOMS_ERROR:
		    if (usePipes) {
			printf (targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf("*** error exporting\n");
		    break;
		case CUSTOMS_NOIOSOCK:
		    if (usePipes) {
			printf(targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf("*** error exporting: couldn't create I/O socket\n");
		    break;
		default:
		    if (usePipes) {
			printf (targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf("*** error calling remote server: %s\n",
			   Rpc_ErrorMessage(-(data->rmtFd + 200)));
		    break;
		}
		fflush(stdout);
	    }
	    return (FALSE);
	} else {
	    struct hostent *he;

	    if (!(job->flags & JOB_SILENT)) {
		he = gethostbyaddr(&data->permit.addr,
				   sizeof(data->permit.addr),
				   AF_INET);
		if (usePipes) {
		    printf (targFmt, job->node->name);
		    lastNode = job->node;
		}

		if (he == (struct hostent *)NULL) {
		    printf("*** exported to %s (id %u)\n",
			   InetNtoA(data->permit.addr),
			   data->permit.id);
		} else {
		    printf("*** exported to %s (id %u)\n", he->h_name,
			   data->permit.id);
		}
	    }

	    if (usePipes) {
		/*
		 * Close down the pipes that were opened for this job since
		 * we dinnae need them
		 */
		(void)close(job->outPipe);
		(void)close(job->inPipe);
		job->outPipe = job->inPipe = data->rmtFd;
		job->curPos = 0;
		if (DEBUG(RMT)) {
		    printf("rmtFd = %d\n", data->rmtFd);
		}
	    }

	    fflush(stdout);

	    fcntl(data->rmtFd, F_SETFL, FNDELAY);
	    fcntl(data->rmtFd, F_SETFD, 1);

	    /*
	     * Record command file's descriptor and rewind the thing to its
	     * start.
	     */
	    data->cmdFd = fileno(job->cmdFILE);
	    lseek(data->cmdFd, 0, L_SET);

	    /*
	     * Pay attention to the remote connection for two-way communication.
	     */
	    Rpc_Watch(data->rmtFd, RPC_READABLE|RPC_WRITABLE, RmtIO,
		      (Rpc_Opaque)job);

	    /*
	     * Record the private data in the job record.
	     */
	    job->rmtID = (char *)data;
	    job->pid = 0;

	    /*
	     * Success R Us
	     */
	    return (TRUE);
	}
    }
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_ReExport --
 *	Supposed to re-export a job that's come home, but since jobs
 *	can't come home under customs, we just return FALSE to say
 *	we couldn't do it.
 *
 * Results:
 *	FALSE.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
Boolean
Rmt_ReExport(pid)
    int	    pid;
{
    if (DEBUG(RMT)) {
	printf("Rmt_ReExport called?\n");
    }
    return(FALSE);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_LastID --
 *	Return an unique identifier for the last job exported with Rmt_Exec
 *
 * Results:
 *	Some sort of identifier. Just returns 1.
 *
 * Side Effects:
 *	returnFD and exportFD are closed if we're in Make mode.
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
int
Rmt_LastID(pid)
    int	    	  pid;	    /* PID of job last exported */
{
    if (amMake) {
	(void)close(returnFD);
	(void)close(exportFD);
	exportFD = 0;
    }
    return (1);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Done --
 *	Register the completion of a remote job.
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
void
Rmt_Done (id)
    int	    id;
{
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Watch --
 *	Watch a stream for the job module. It only requires us to
 *	notify it of the readability of the stream.
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	A call to Rpc_Watch is performed.
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Watch(stream, proc, data)
    int	    stream; 	    /* Stream to watch */
    void    (*proc)();	    /* Procedure to call */
    char    *data;  	    /* Data to pass it when stream is ready */
{
    Rpc_Watch(stream, RPC_READABLE, proc, (Rpc_Opaque)data);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Ignore --
 *	Pay no further attention to a stream
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	Rpc_Ignore is called
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Ignore(stream)
    int	    	stream;	    /* Stream to ignore */
{
    Rpc_Ignore(stream);
}

/*-
 *-----------------------------------------------------------------------
 * Rmt_Wait --
 *	Wait for something to happen and return when it does
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Those of the callback functions that are called.
 *
 *-----------------------------------------------------------------------
 */
void
Rmt_Wait()
{
    Rpc_Wait();
}
#endif /* defined(unix) */
