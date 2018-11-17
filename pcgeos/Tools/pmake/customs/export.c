/*-
 * export.c --
 *	Program to handle the interaction with the customs agent over
 *	an exported process. This should, perhaps, be generalized so
 *	other programs can use it, but...maybe a library...
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
static char *csid =
"$Id: export.c,v 1.1 91/06/09 15:55:23 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    <sys/time.h>
#include    <signal.h>
#include    <stdio.h>
#include    <sys/wait.h>
#include    <sys/ioctl.h>
#include    <errno.h>
extern int errno;
#include    <netdb.h>
#include    <sys/file.h>

#include    "customs.h"

int	    	  	rmt;  	/* Socket to remote process */
int	    	  	ret;   	/* Socket server will call us back on with
				 * exit status */
u_long	    	  	id;    	/* Permit id under which the process is
				 * running */
struct sockaddr_in	server;	/* Address of server running the process */
extern int  	  	customs_Socket;
extern struct timeval	customs_RetryTimeOut;

union wait  	  	status;
int			exitSeen = 0;
void	    	  	DoExit();

/*-
 *-----------------------------------------------------------------------
 * PassSig --
 *	Catch a signal and pass it along. We only kill ourselves with the
 *	signal when we receive the exit status of the remote process.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An RPC call is made to the import server to deliver the signal.
 *
 *-----------------------------------------------------------------------
 */
PassSig(signo)
    int	    signo;	/* The signal number we've received */
{
    Kill_Data	  packet;
    Rpc_Stat	  status;
    
    packet.id = id;
    packet.signo = signo;

    status = Rpc_Call (ret, &server, (Rpc_Proc)CUSTOMS_KILL,
		       sizeof(packet), (Rpc_Opaque)&packet,
		       0, (Rpc_Opaque)0,
		       CUSTOMS_NRETRY, &customs_RetryTimeOut);
    if (status != RPC_SUCCESS) {
	printf("Customs_Kill(%d): %s\n", signo, Rpc_ErrorMessage(status));
	exit(1);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Drain --
 *	Wait for the remote socket to become writable again, handling
 *	any output from the remote side in the mean time.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	If 'what' is RPC_WRITABLE, Transfer is reinstalled as the stream
 *	server for stdin...
 *
 *-----------------------------------------------------------------------
 */
/*ARGSUSED*/
void
Drain(stream, arg, what)
    int	    	  stream;
    Rpc_Opaque 	  arg;
    int	    	  what;
{
    extern void	  Transfer();
    
    if (what & RPC_READABLE) {
	/*
	 * Transfer any data from remote side
	 */
	Transfer(rmt, 1);
    }
    if (what & RPC_WRITABLE) {
	/*
	 * Socket has drained enough, reinstall the regular handlers
	 * for both streams
	 */
	Rpc_Watch(rmt, RPC_READABLE, Transfer, (Rpc_Opaque)1);
	Rpc_Watch(0, RPC_READABLE, Transfer, (Rpc_Opaque)rmt);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Transfer --
 *	Transfer data from one source to another.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Data are read from source and written to dest.
 *
 *-----------------------------------------------------------------------
 */
void
Transfer (source, dest)
    int	    source;
    int	    dest;
{
    char    buf[BUFSIZ];
    int	    cc;

    cc = read(source, buf, sizeof(buf));
    if (cc < 0) {
	perror ("read");
	printf("source = %d, dest = %d\n", source, dest);
	return;
    } else if (cc == 0) {
	if (source == 0) {
	    /*
	     * When we reach the end-of-file for our input, we want the remote
	     * process to reach that state, too, so we half-shutdown our socket
	     * to it.
	     */
	    if (shutdown(rmt, 1) < 0) {
		perror("shutdown");
		exit(3);
	    }
	} else if (exitSeen) {
	    /*
	     * We've gotten an EOF on the socket and customs has already sent
	     * us an exit signal, so perform the exit now.
	     */
	    DoExit();
	}
	Rpc_Ignore(source);
    } else if (write (dest, buf, cc) != cc) {
	if (errno != EWOULDBLOCK) {
	    if (errno == EPIPE) {
		if (dest == rmt) {
		    /*
		     * Connection to remote side was lost. This means that
		     * both the process and the server died, so there's
		     * no point in waiting for the exit status...
		     */
		    printf ("*** connection closed.\n");
		    if (exitSeen) {
			DoExit();
		    }
		}
	    }
	    exit(2);
	} else {
	    /*
	     * If we can't write because it'd block, we must be transfering
	     * from local to remote. In such a case, we ignore further input
	     * from stdin, and wait for the output socket to become writable.
	     * Drain() will reset the handler for 0.
	     */
	    Rpc_Ignore(0);
	    Rpc_Watch(rmt, RPC_READABLE|RPC_WRITABLE, Drain, (Rpc_Opaque)0);
	}
    }
}
void
SwapExit(length, data)
    int	    	  length;
    Exit_Data	  *data;
{
    Rpc_SwapLong(sizeof(long), &data->id);
    Rpc_SwapLong(sizeof(long), &data->status);
}


/*-
 *-----------------------------------------------------------------------
 * Exit --
 *	Handle CUSTOMS_EXIT call from import server. This process doesn't
 *	actually exit until we get an end-of-file on the socket to the
 *	remote side. This allows any error message from the customs agent
 *	to be printed before we exit.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	exitSeen is set true and status is set to the returned status.
 *
 *-----------------------------------------------------------------------
 */
void
Exit(from, msg, len, data)
    struct sockaddr_in	*from;
    Rpc_Message	  	msg;
    int	    	  	len;
    Rpc_Opaque 	  	data;
{
    int	    	  	nb;
    Exit_Data	  	*eVal = (Exit_Data *)data;
    
    status.w_status = eVal->status;
    exitSeen = 1;
    Rpc_Return(msg, 0, (Rpc_Opaque)0);

    while ((ioctl(rmt, FIONREAD, &nb) == 0) && (nb > 0)) {
#ifdef notdef
	printf("Exit: %d bytes remaining\n", nb);
	fflush(stdout);
#endif /* notdef */
	Transfer(rmt, 1);
    }
    DoExit();
}


/*-
 *-----------------------------------------------------------------------
 * DoExit --
 *	Exit in the same way the remote process did.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The process will change state, either stopping, dying horribly
 *	or just exiting cleanly.
 *
 *-----------------------------------------------------------------------
 */
void
DoExit()
{
    if (WIFSTOPPED(status)) {
	int oldmask;
	
	signal (status.w_stopsig, SIG_DFL);
	oldmask = sigsetmask(0);
	kill (getpid(), status.w_stopsig);
	(void)sigsetmask(oldmask);
	signal (status.w_stopsig, PassSig);
    } else if (WIFSIGNALED(status)) {
	if (status.w_coredump) {
	    /*
	     * We don't want our core dump messing up the other one,
	     * so we change to a (we hope) non-writable directory before
	     * commiting suicide.
	     */
	    chdir ("/");
	}
	signal (status.w_termsig, SIG_DFL);
	kill (getpid(), status.w_termsig);
    } else {
	exit (status.w_retcode);
    }
}

    
/*-
 *-----------------------------------------------------------------------
 * main --
 *	Usage:
 *	    export -id connection-fd return-fd id
 *	    export <command>
 *
 *	In the first form, the idea is the exporting program will have
 *	contacted the customs agent already and told it what to do. This
 *	program then simply shuffles I/O and passes signals and the exit
 *	status along...
 *
 *	In the second form, this will
 *
 * Results:
 *	The exit status of the remote process.
 *
 * Side Effects:
 *	Well...
 *
 *-----------------------------------------------------------------------
 */
main (argc, argv)
    int	    argc; 	/* Number of arguments */
    char    **argv;	/* The arguments themselves */
{
    ExportPermit  	permit;
    int	    	  	raLen;
    struct servent  	*sep;

    if (argc < 2) {
	printf ("Usage:\n\t%s -id <connection-fd> <return-fd> <id>\nor",
		argv[0]);
	printf ("\t%s <command>\n", argv[0]);
	exit(1);
    }

    if (strcmp (argv[1], "-id") == 0) {
	if (argc < 5) {
	    printf ("Usage:\n\t%s -id <connection-fd> <return-fd> <id>\n",
		    argv[0]);
	    exit(1);
	}
	rmt = atoi (argv[2]);
	ret = atoi(argv[3]);
	(void)sscanf(argv[4], "%x", &id);
	fflush(stdout);
	permit.id = 0;
    } else {
	rmt = Customs_RawExport(argv[1], &argv[1], (char *)NULL, 0,
				&customs_Socket, &permit);
	if (rmt < 0) {
	    printf ("%s: could not export command\n", argv[0]);
	    fflush(stdout);
	    execvp(argv[1], &argv[1]);
	    printf ("%s: not found\n", argv[1]);
	    fflush(stdout);
	    exit(3);
	} else {
	    ret = customs_Socket;
	    id = permit.id;
	}
    }

    /*
     * Install RPC server for the remote server to return the exit status
     * of the process.
     */
    Rpc_ServerCreate(ret, (Rpc_Proc)CUSTOMS_EXIT, Exit,
		     SwapExit, Rpc_SwapNull, (Rpc_Opaque)0);
    
    if (permit.id != 0) {
	/*
	 * Only do this if we did the exportation ourselves
	 */
	raLen = sizeof(server);
	if (getpeername (rmt, &server, &raLen) < 0) {
	    perror ("getpeername");
	    exit(2);
	} else {
	    struct hostent *he;
	    
	    he = gethostbyaddr (&server.sin_addr, sizeof(server.sin_addr),
				AF_INET);
	    if (he == (struct hostent *)NULL) {
		printf ("Connected to unknown host?\n");
	    } else {
		printf ("*** exported to %s\n", he->h_name);
		fflush (stdout);
		strcpy (argv[1], he->h_name);
	    }
	}
    }

    sep = getservbyname("customs", "udp");

    server.sin_port = sep ? sep->s_port : htons(DEF_CUSTOMS_UDP_PORT);

    signal (SIGHUP, PassSig);
    signal (SIGINT, PassSig);
    signal (SIGQUIT, PassSig);
    signal (SIGTERM, PassSig);
    signal (SIGTSTP, PassSig);
    signal (SIGCONT, PassSig);
    signal (SIGTTOU, PassSig);
    signal (SIGTTIN, PassSig);
    signal (SIGWINCH, PassSig);

    signal (SIGPIPE, SIG_IGN);

    /*
     * We want to avoid I/O deadlock, so place the remote socket into
     * non-blocking mode, allowing us to delay transfering our own input until
     * the remote side can handle it while still accepting its output.
     */
    fcntl(rmt, F_SETFL, FNDELAY);

    /*
     * Install Drain as the initial stream server for rmt to make
     * sure it's writable before bothering to read anything from 0...
     */
    Rpc_Watch(rmt, RPC_READABLE|RPC_WRITABLE, Drain, (Rpc_Opaque)0);
    Rpc_Run();
}
