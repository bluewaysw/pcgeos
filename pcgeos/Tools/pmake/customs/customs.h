/*-
 * customs.h --
 *	Header for the customs agent.
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
 *	"$Id: customs.h,v 1.2 93/01/30 15:38:56 adam Exp $ SPRITE (Berkeley)"
 */
#ifndef _CUSTOMS_H_
#define _CUSTOMS_H_

/*
 * First comes stuff needed by both the client and the server...
 */
#include    <sys/types.h>
#include    <sys/socket.h>
#ifndef _LINUX
#include    <sys/param.h>
#endif
#include    <netinet/in.h>

#ifndef INADDR_LOOPBACK
#define	INADDR_LOOPBACK		(u_long)0x7f000001	/* in host order */
#endif /* INADDR_LOOPBACK */

#include    "rpc.h"

#define MACHINE_NAME_SIZE   	64  	    	/* Longest machine name */
#define MAX_DATA_SIZE	    	2048	    	/* Largest RPC arg packet */
#define MAX_INFO_SIZE	    	MAX_DATA_SIZE	/* Most data returned by
						 * CUSTOMS_INFO call */
#define MAX_NUM_GROUPS		16  	    	/* Most groups a caller
						 * can be in. Don't use
						 * NGROUP as that varies from
						 * OS to OS. */

typedef enum {
/* CLIENT FUNCTIONS */
    CUSTOMS_PING, 	/* See if server is up */
    CUSTOMS_HOST, 	/* Get address of host to use */
    CUSTOMS_AVAILINTV,	/* Set interval for availability check */
    CUSTOMS_SETAVAIL,	/* Set availability criteria */
    CUSTOMS_INFO, 	/* Find who's registered */
    CUSTOMS_MASTER,	/* Find address of MCA */
    CUSTOMS_LOG,  	/* Log information of rpc socket */
/* AGENT-INTERNAL FUNCTIONS */
    CUSTOMS_AVAIL,	/* Tell master if machine available */
    CUSTOMS_HOSTINT,	/* Agent-internal HOST call */
    CUSTOMS_REG,  	/* Register local machine with master */
    CUSTOMS_ALLOC,	/* Local machine allocated by master */
    CUSTOMS_CONFLICT,	/* More than one master exists */
/* ELECTION BROADCAST FUNCTIONS */
    CUSTOMS_CAMPAIGN,	/* Attempt to become master */
    CUSTOMS_NEWMASTER,	/* Declare oneself master */
/* IMPORT/TCP FUNCTIONS */
    CUSTOMS_IMPORT,	/* Import a job */
    CUSTOMS_KILL, 	/* Kill a running job with a signal */
    CUSTOMS_EXIT, 	/* RETURN CALL: status and id # of exited process */
/* DEBUG FUNCTIONS */
    CUSTOMS_ABORT,	/* Exit */
    CUSTOMS_RESTART,	/* Reexecute with same arguments */
    CUSTOMS_DEBUG,	/* Turn on debugging. */
    CUSTOMS_ELECT,  	/* Start off a new election */
} Customs_Proc;

/*
 * Parameter to CUSTOMS_DEBUG
 */
#define DEBUG_RPC 	1   	/* Debug rpc system */
#define DEBUG_CUSTOMS	2   	/* Debug customs itself */

/*
 * ExportPermits are what the servers use to authenticate exportation of
 * jobs. They are returned to the client from a Customs_Host().
 * CUSTOMS_FAIL may be used to see if the request succeeded. If it did not,
 * CUSTOMS_FAIL(&permit.addr) will be True.
 */
#define CUSTOMS_FAIL(inaddrPtr)	((inaddrPtr)->s_addr == INADDR_ANY)

typedef struct {
    struct in_addr	addr;	    	/* Address of host */
    u_long    	  	id;	  	/* Authentication ID to give it */
} ExportPermit;


/*
 * Host_Data is what is passed to the Customs_Host() function. It contains the
 * UID under which the job will be exported (which must remain constant) and
 * a word of flags indicating criteria to use to determine which host to use.
 */
typedef struct {
    u_short   	  	uid;
    u_short		flags;
} Host_Data;
#define EXPORT_ANY	0x0001	    /* Export to any sort of machine */
#define EXPORT_SAME	0x0002	    /* Export only to same sort of machine */
#define EXPORT_USELOCAL	0x0004	    /* Use local host if available */
#define EXPORT_68020	0x0008	    /* Go only to a 68020 (TEMPORARY) */

/*
 * Avail_Data is what is passed to and returned from the Customs_SetAvail()
 * function. changeMask contains a bitwise-OR of AVAIL_IDLE, AVAIL_SWAP,
 * AVAIL_LOAD and AVAIL_IMPORTS, indicating what fields of the Avail_Data
 * structure are valid. On return, changeMask indicates what fields in the
 * request were invalid. If changeMask is 0, everything was accepted.
 * The returned structure contains the current (after the change, if nothing
 * was wrong) criteria.
 * Load averages are sent as a fixed-point number. The location of the
 * decimal point is given by LOADSHIFT. Divide by LOADSCALE to get the
 * appropriate floating-point number.
 */
typedef struct {
    long    	  changeMask;	    /* Parameters to change */
    long    	  idleTime; 	    /* Idle time (in seconds) */
    long    	  swapPct;  	    /* Percentage of free swap space */
    long    	  loadAvg;  	    /* Maximum load average */
    long    	  imports;  	    /* Greatest number of imported processes */
} Avail_Data;

#define AVAIL_IDLE	    1
#define MAX_IDLE  	    (60*60)

#define AVAIL_SWAP	    2
#define MAX_SWAP  	    40

#define LOADSHIFT   	    8
#define LOADSCALE   	    (1<<LOADSHIFT)
#define AVAIL_LOAD	    4
#define MIN_LOAD  	    ((int)(0.25*LOADSCALE))

#define AVAIL_IMPORTS	    8
#define MIN_IMPORTS	    1

/*
 * The next few constants are return values, some of them, and are not to
 * be passed to the agent.
 */
#define AVAIL_DOWN	    0x80000000	/* Machine is down -- this is *not* a
					 * parameter */
#define AVAIL_EVERYTHING    (~0)

/*
 * Strings follow the WayBill in the CUSTOMS_IMPORT call arguments as
 * follows:
 *	current-working-directory
 *	file	  	    	    # command to execute
 *	number-o'-arguments 	    # on a 32-bit boundary
 *	argument strings
 *	number-o'-envariables	    # on a 32-bit boundary
 *	environment strings
 *
 * The function Customs_MakeWayBill will create an appropriate buffer...
 */
typedef struct {
    u_long  id;	  	    	/* Identifier returned by the MCA */
    long    deadline;	    	/* Deadline for remote process to start */
    u_short port; 	    	/* UDP Port for callback when process exits */
    short   ruid;  	    	/* The current real user id */
    short   euid; 	    	/* The current effective user id */
    short   rgid;	    	/* The current real group id */
    short   egid; 	    	/* The current effective group id */
    short   pad;    	    	/* Explicit padding for all architectures */
    long    umask;	    	/* File creation mask */
    long    ngroups;	    	/* Number of groups */
    long    groups[MAX_NUM_GROUPS];	/* Array of group ids */
} WayBill;

/*
 * Kill_Data is passed to the CUSTOMS_KILL procedure.
 */
typedef struct {
    u_long  id;	    	    	/* Job ID number (from ExportPermit) */
    long    signo;	    	/* Signal number to deliver */
} Kill_Data;


/*
 * Parameters to the CUSTOMS_EXIT call
 */
typedef struct {
    u_long  	  id;	    	/* ID # of exported job */
    long    	  status;   	/* Exit status */
} Exit_Data;

/*
 * This is the time within which the daemon is "guaranteed" to respond.
 */
#define CUSTOMS_RETRY	2
#define CUSTOMS_URETRY	500000
#define CUSTOMS_NRETRY	2

#define Customs_Align(ptr, type)    (type) (((int)(ptr)+3)&~3)

#define CUSTOMS_TCP_RETRY   10
#define CUSTOMS_TCP_URETRY  0
#define CUSTOMS_TCP_NRETRY  1


/*
 * Sometimes CUSTOMS_IMPORT calls (via TCP) exceed the caller's CUSTOMS_TIMEOUT
 * while actually succeeding on the server side.  This means a remote
 * process is started without the caller knowing it.  This then leads to
 * unexpected exit codes being returned and scheduling of duplicate jobs.
 * There is no good way to completely prevent this unless you have your
 * clocks reasonably synchronized across machines (e.g., to a second
 * or so).  In that case the server can doublecheck that the import call
 * succeeded within the expected time, and abort otherwise.
 * For safety, the server checks that the import is within CUSTOMS_TIMEOUT/2 of
 * call initiation.
 */
#define DOUBLECHECK_TIMEOUT



/*
 * Default ports if yellow pages f***s us over
 */
#define DEF_CUSTOMS_UDP_PORT	8231
#define DEF_CUSTOMS_TCP_PORT	8231

/*
 * Rpc front-ends
 */

/*
 * Return codes from Customs_RawExport, for anyone interested.
 * If > -100, negation of result is Rpc_Stat code from call to local server.
 * if <= -200, -(code + 200) is Rpc_Stat for call to remote server.
 */
#define CUSTOMS_NOEXPORT    -100    	/* Couldn't export */
#define CUSTOMS_NORETURN    -101    	/* Couldn't create return socket */
#define CUSTOMS_NONAME	    -102    	/* Couldn't fetch socket name */
#define CUSTOMS_ERROR	    -104    	/* Remote export error -- message
					 * already printed */
#define CUSTOMS_NOIOSOCK    -105    	/* Couldn't create tcp I/O socket */

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

#endif _CUSTOMS_H_
