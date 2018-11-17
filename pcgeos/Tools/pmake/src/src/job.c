/*-
 * job.c --
 *	handle the creation etc. of our child processes.
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
 *	Job_Make  	    	Start the creation of the given target.
 *
 *	Job_CatchChildren   	Check for and handle the termination of any
 *	    	  	    	children. This must be called reasonably
 *	    	  	    	frequently to keep the whole make going at
 *	    	  	    	a decent clip, since job table entries aren't
 *	    	  	    	removed until their process is caught this way.
 *	    	  	    	Its single argument is TRUE if the function
 *	    	  	    	should block waiting for a child to terminate.
 *
 *	Job_CatchOutput	    	Print any output our children have produced.
 *	    	  	    	Should also be called fairly frequently to
 *	    	  	    	keep the user informed of what's going on.
 *	    	  	    	If no output is waiting, it will block for
 *	    	  	    	a time given by the SEL_* constants, below,
 *	    	  	    	or until output is ready.
 *
 *	Job_Init  	    	Called to intialize this module. in addition,
 *	    	  	    	any commands attached to the .BEGIN target
 *	    	  	    	are executed before this function returns.
 *	    	  	    	Hence, the makefile must have been parsed
 *	    	  	    	before this function is called.
 *
 *	Job_Full  	    	Return TRUE if the job table is filled.
 *
 *	Job_Empty 	    	Return TRUE if the job table is completely
 *	    	  	    	empty.
 *
 *	Job_ParseShell	    	Given the line following a .SHELL target, parse
 *	    	  	    	the line as a shell specification. Returns
 *	    	  	    	FAILURE if the spec was incorrect.
 *
 *	Job_End	  	    	Perform any final processing which needs doing.
 *	    	  	    	This includes the execution of any commands
 *	    	  	    	which have been/were attached to the .END
 *	    	  	    	target. It should only be called when the
 *	    	  	    	job table is empty.
 *
 *	Job_AbortAll	    	Abort all currently running jobs. It doesn't
 *	    	  	    	handle output or do anything for the jobs,
 *	    	  	    	just kills them. It should only be called in
 *	    	  	    	an emergency, as it were.
 *
 *	Job_CheckCommands   	Verify that the commands for a target are
 *	    	  	    	ok. Provide them if necessary and possible.
 *
 *	Job_Touch 	    	Update a target without really updating it.
 *
 *	Job_Wait  	    	Wait for all currently-running jobs to finish.
 */
#include <config.h>

#ifndef lint
static char     *rcsid = "$Id: job.c,v 1.9 96/06/24 15:05:32 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

extern void  setenv (char *name, char *value);
extern char *getenv (const char *name);

#if defined(unix)
#    include    <utime.h>   /* for utime() in Job_Touch */
#endif /* defined(unix) */

#include    <stdio.h>
#include    <compat/string.h>
#include    <sys/types.h>

#if defined (__BORLANDC__) && !defined(_WIN32)
#      include <dos.h>
#endif /* defined (__BORLANDC__) && !defined(_WIN32) */

#if !defined(unix) && !defined(_WIN32)
#	include    <signal.h>
#	include	   <time.h>
#	include	   <malloc.h>
#elif defined(unix)
#	include    <sys/signal.h>
#	include	   <sys/unistd.h>
#	include    <sys/time.h>
#	include    <sys/wait.h>
#endif /* !defined(unix) && !defined(_WIN32) */

#include    <sys/stat.h>
#include    <compat/file.h>
#include    <ctype.h>
#include    <errno.h>
#include    <stdlib.h>

#if defined(__HIGHC__)
extern volatile int  errno;
#else
extern int  errno;
#endif /* __HIGHC__ */

#include    "make.h"
#include    "job.h"

#if defined (unix)
#      include    "rmt.h"
#      include    "arch.h"
#elif defined(_WIN32)
#      include    <windows.h>
#endif /* defined (unix) */

#include    "pmjob.h"
#include    "prototyp.h"

#if defined(_WIN32)
static int  JobCmpHandle   (Job *job, HANDLE handle);
BOOL WINAPI JobNTInterrupt (DWORD);
#endif /* defined(_WIN32) */

void JobDoOutput (Job *job, Boolean finish);
/*
 * Under unix we use wait3, select, exec and fork to handle children.  Under
 * NT we use HANDLEs, CreateProcess, WaitForMultipleObjects, and 
 * GetExitCodeProcess to handle children.  This next section defines some stuff
 * needed by wait3 and select for unix or some stuff needed by the NT paradigm.
 */
#if defined(unix)

/*
 * Some systems define the fd_set we use, but not the macros to deal with it
 * (SunOS 3.5, e.g.)
 */
#    ifndef FD_SET

#        ifdef NEED_FD_SET
/*
 * Then there are the systems that don't even define fd_set...
 */
#        ifndef	FD_SETSIZE
#             define	FD_SETSIZE	256
#        endif /* ndef FD_SETSIZE */

#        ifndef NBBY
#             define NBBY 8
#        endif /* ndef NBBY */

typedef long	fd_mask;
#        define NFDBITS	(sizeof(fd_mask) * NBBY)	/* bits per mask */
#        ifndef howmany
#              define	howmany(x, y)	((unsigned int)(((x)+((y)-1)))/(unsigned int)(y))
#        endif /* ndef howmany */

typedef	struct fd_set {
	fd_mask	fds_bits[howmany(FD_SETSIZE, NFDBITS)];
} fd_set;

#        endif /* NEED_FD_SET */

#define	FD_SET(n, p)	((p)->fds_bits[(n)/NFDBITS] |= (1 << ((n) % NFDBITS)))
#define	FD_CLR(n, p)	((p)->fds_bits[(n)/NFDBITS] &= ~(1 << ((n) % NFDBITS)))
#define	FD_ISSET(n, p)	((p)->fds_bits[(n)/NFDBITS] & (1 << ((n) % NFDBITS)))
#define FD_ZERO(p)	bzero((char *)(p), sizeof(*(p)))
#    endif /* FD_SET */

#elif defined(_WIN32)

/*
 * Since in NT children aren't connected to their parents like under unix,
 * there's no equivalent of the unix wait syscall.  Therefore we keep an array
 * of the processes we've spawned around.  The total number of children we can
 * have is DEFMAXJOBS (defined in nt-cfg.h).  It is passed to
 * WaitForMultipleObjects().
 */

/*
 * Total handles in the list is one more than the total number of jobs that
 * can be run.  This is because since even though a job might be finished,
 * it may still have output to do but another job could have been started
 * before we collect that output, so we need an extra handle for the output
 * of a finished job but an uncollected one.
 */
#define HANDLE_LIST_MAX (DEFMAXJOBS + 1)

typedef struct {
    HANDLE hArray[HANDLE_LIST_MAX];
    int    numFilled;
} HandleList;

static HandleList *children;

static Boolean JobAddHandle    (HANDLE, HandleList*);
static Boolean JobRemoveHandle (HANDLE, HandleList*);
#if 0
static Boolean JobIsSetHandle  (HANDLE, HandleList*);
#endif /* 0 */

/*
 * These constants define the name and length of the name of the temp file
 * used as the stdin of our child shell
 */

#define  SHELL_FILENAME         "%s\\pmake%x%x"
#define  SHELL_FILENAME_LENGTH  (strlen(SHELL_FILENAME) + 35 + strlen(temp))

/*
 * This is the maximum length the command line passed to CreateProcess
 * can be
 */

#define  MAX_COMMAND_LINE_LENGTH 1024

#endif /* defined (unix) */

/*
 * error handling variables 
 */
int     errors        = 0;	    /* number of errors reported */
int  	aborting      = 0;	    /* why is the make aborting? */
#define ABORT_ERROR	1   	    /* Because of an error */
#define ABORT_INTERRUPT	2   	    /* Because it was interrupted */
#define ABORT_WAIT	3   	    /* Waiting for jobs to finish */

/*
 * JobFinish will take a union wait as its second parameter if under unix
 * but an integer if under NT.  JobMakeArgv takes a char ** under unix and
 * a char * under NT.
 */
#if defined(unix)
#    define WAIT_TYPE union wait
#    define ARGV_TYPE char **
#elif defined(_WIN32)
#    define WAIT_TYPE unsigned long
#    define ARGV_TYPE char *
#endif /* defined(unix) */

void JobFinish (Job *job, WAIT_TYPE status);

/*
 * post-make command processing. The node postCommands is really just the
 * .END target but we keep it around to avoid having to search for it
 * all the time.
 */
static GNode   	  *postCommands;    /* node containing commands to execute when
				     * everything else is done */
static int     	  numCommands; 	    /* The number of commands actually printed
				     * for a target. Should this number be
				     * 0, no shell will be executed. */

/*
 * Return values from JobStart.
 */
#define JOB_RUNNING	0   	/* Job is running */
#define JOB_ERROR 	1   	/* Error in starting the job */
#define JOB_FINISHED	2   	/* The job is already finished */
#define JOB_STOPPED	3   	/* The job is stopped */

#if defined(unix)
/*
 * tfile is the name of a file into which all shell commands are put. It is
 * used over by removing it before the child shell is executed. The XXXXX in
 * the string are replaced by the pid of the make process in a 5-character
 * field with leading zeroes. 
 */
static char     tfile[] = TMPPAT;
#endif /* defined(unix) */

/*
 * Descriptions for various shells.
 */
static Shell    shells[] = {
#if defined (unix)
    /*
     * CSH description. The csh can do echo control by playing
     * with the setting of the 'echo' shell variable. Sadly,
     * however, it is unable to do error control nicely.
     */
{
    "csh",
    TRUE, "unset verbose", "set verbose", "unset verbose", 13,
    FALSE, "echo \"%s\"\n", "csh -c \"%s || exit 0\"",
    "v", "e",
},
    /*
     * SH description. Echo control is also possible and, under
     * sun UNIX anyway, one can even control error checking.
     */
{
    "sh",
    TRUE, "set -", "set -v", "set -", 5,
#if (defined(sun) && !defined(Sprite)) || defined(SYSV)
    TRUE, "set -e", "set +e",
#else
    FALSE, "echo \"%s\"\n", "sh -c '%s || exit 0'\n",
#endif
    "v", "e",
},

#elif defined (_WIN32)
    /* This is the shell description for WINNT.
     * Echo control isn't possible, no error control or exit codes, either
     */
{
    "cmd /Q /k echo off",
    FALSE, "", "", "", 0,
    FALSE, "echo %s\r\n", "%s & if errorlevel 1 (set errorlevel=1 & exit)\r\n",
    "", "",
},

#endif /* defined (unix) */

    /*
     * UNKNOWN.
     */
{
    NULL,
    FALSE, NULL, NULL, NULL, 0,
    FALSE, NULL, NULL,
    NULL, NULL,
}
};
Shell       	*commandShell = &shells[DEFSHELL]; /* this is the shell to
						   * which we pass all
						   * commands in the Makefile.
						   * It is set by the
						   * Job_ParseShell function */
char        	*shellPath = (char *) NULL,	  /* full pathname of
						   * executable image */
               	*shellName;	      	      	  /* last component of shell */


static int  	maxJobs;    	/* The most children we can run at once */
static int  	maxLocal;    	/* The most local ones we can have */
int  	    	nJobs;	    	/* The number of children currently running */
int  	    	nLocal;    	/* The number of local children */
Lst  	    	jobs;		/* The structures that describe them */
Boolean	    	jobFull;    	/* Flag to tell when the job table is full. It
				 * is set TRUE when (1) the total number of
				 * running jobs equals the maximum allowed or
				 * (2) a job can only be run locally, but
				 * nLocal equals maxLocal */
#if defined (unix)
#    ifndef RMT_WILL_WATCH
static fd_set  	outputs;    	/* Set of descriptors of pipes connected to
				 * the output channels of children */
#    endif /* ndef RMT_WILL_WATCH */

GNode 	    	*lastNode;	/* The node for which output was most recently
				 * produced. */
#endif /* defined(unix) */
char 	    	*targFmt;   	/* Format string to use to head output from a
				 * job when it's not the most-recent job heard
				 * from */
#define TARG_FMT_PROTO  "--- %s%s%%s ---\n" /* Default format */

static char 	*bannerPrefix;	/* Prefix we received from our parent make */

/*
 * When JobStart attempts to run a job remotely but can't, and isn't allowed
 * to run the job locally, or when Job_CatchChildren detects a job that has
 * been migrated home, the job is placed on the stoppedJobs queue to be run
 * when the next job finishes. 
 */
Lst  	    stoppedJobs;	/* Lst of Job structures describing
				 * jobs that were stopped due to concurrency
				 * limits or migration home */


#if defined(USE_PGRP) && defined(SYSV)
#    define KILL(pid,sig)	killpg(-(pid),(sig))
#else
#    ifdef USE_PGRP
#        define KILL(pid,sig)	killpg((pid),(sig))
#    else
#        define KILL(pid,sig)	kill((pid),(sig))
#    endif
#endif /* defined (USE_PGRP) && defined(SYSV) */

#if defined(unix)
static void JobRestart(Job *job);
#endif /* defined(unix) */

static int  JobStart(GNode *gn, short flags, Job *previous);

#if defined(unix)
static void JobInterrupt(int runINTERRUPT);
#endif /* defined(unix) */

/*-
 *-----------------------------------------------------------------------
 * JobSetChildsPrefix --
 *	change the PMAKE_BANNER_PREFIX in our own environment to account
 *	for the child process about to be spawned.
 *
 * Results:
 *	none
 *
 * Side Effects:
 *	The PMAKE_BANNER_PREFIX environment variable is altered.
 *
 *-----------------------------------------------------------------------
 */
static void
JobSetChildsPrefix(GNode *gn)
{
    static char	*buffer = NULL;
    static int	prevLen = 0;
    int	    preflen = strlen(bannerPrefix);
    int	    nodelen = strlen(gn->name);
    
    if (preflen != 0) {
	/*
	 * Make room for the separator
	 */
	preflen += 1;
    }
    if (preflen + nodelen > prevLen) {
	if (buffer == NULL) {
	    buffer = (char *)malloc(preflen + nodelen + 1);
	} else {
	    buffer = (char *)realloc(buffer, preflen + nodelen + 1);
	}
	prevLen = preflen + nodelen;
    }
    sprintf(buffer, "%s%s%s", bannerPrefix, preflen == 0 ? "" : ":",
	    gn->name);

    setenv("PMAKE_BANNER_PREFIX", buffer);
}

#if defined (unix)

/*-
 *-----------------------------------------------------------------------
 * JobCondPassSig --
 *	Pass a signal to a job if the job is remote or if USE_PGRP
 *	is defined.
 *
 * Results:
 *	=== 0
 *
 * Arguments:
 *      Job *job   : Job to biff
 *      int  signo : Signal to send it
 *
 * Side Effects:
 *	None, except the job may bite it.
 *
 *-----------------------------------------------------------------------
 */
static int
JobCondPassSig(Job *job, int signo)
{
#ifdef RMT_WANTS_SIGNALS
    if (job->flags & JOB_REMOTE) {
	(void)Rmt_Signal(job, signo);
    } else {
	KILL(job->pid, signo);
    }
#else
    /*
     * Assume that sending the signal to job->pid will signal any remote
     * job as well.
     */
    KILL(job->pid, signo);
#endif /* RMT_WANTS_SIGNALS */
    return(0);
}

/*-
 *-----------------------------------------------------------------------
 * JobPassSig --
 *	Pass a signal on to all remote jobs and to all local jobs if
 *	USE_PGRP is defined, then die ourselves.
 *
 * Results:
 *	None.
 *
 * Arguments:
 *      int signo : The signal number we've received
 *
 * Side Effects:
 *	We die by the same signal.
 *	
 *-----------------------------------------------------------------------
 */
static void
JobPassSig(int signo)
{
    int	    mask;
    
    Lst_ForEach(jobs, JobCondPassSig, (ClientData)signo);

    /*
     * Deal with proper cleanup based on the signal received. We only run
     * the .INTERRUPT target if the signal was in fact an interrupt. The other
     * three termination signals are more of a "get out *now*" command.
     */
    if (signo == SIGINT) {
	JobInterrupt(TRUE);
    } else if ((signo == SIGHUP) || (signo == SIGTERM) || (signo == SIGQUIT)) {
	JobInterrupt(FALSE);
    }
    
    /*
     * Leave gracefully if SIGQUIT, rather than core dumping.
     */
    if (signo == SIGQUIT) {
	Finish(0);  /*I guess 0 is the right number to pass here (TB)*/
    }
    
    /*
     * Send ourselves the signal now we've given the message to everyone else.
     * Note we block everything else possible while we're getting the signal.
     * This ensures that all our jobs get continued when we wake up before
     * we take any other signal.
     */
    mask = sigblock(0);
    (void) sigsetmask(~0 & ~(1 << (signo-1)));
    signal(signo, SIG_DFL);

    kill(getpid(), signo);

    Lst_ForEach(jobs, JobCondPassSig, (ClientData)SIGCONT);

    sigsetmask(mask);
    signal(signo, JobPassSig);

}
#endif /* defined (unix) */

/*-
 *-----------------------------------------------------------------------
 * JobCmpPid  --
 *	Compare the pid of the job with the given pid and return 0 if they
 *	are equal. This function is called from Job_CatchChildren via
 *	Lst_Find to find the job descriptor of the finished job.
 *
 * Results:
 *	0 if the pid's match
 *
 * Arguments:
 *      int  pid : process id desired
 *      job *job : job to examine
 *
 * Side Effects:
 *	None
 *-----------------------------------------------------------------------
 */
#if defined(unix)
static int
JobCmpPid (Job *job, int pid)
{
    return (pid - job->pid);
}
#endif /* defined(unix) */

/*-
 *-----------------------------------------------------------------------
 * JobPrintCommand  --
 *	Put out another command for the given job. If the command starts
 *	with an @ or a - we process it specially. In the former case,
 *	so long as the -s and -n flags weren't given to make, we stick
 *	a shell-specific echoOff command in the script. In the latter,
 *	we ignore errors for the entire job, unless the shell has error
 *	control.
 *	If the command is just "..." we take all future commands for this
 *	job to be commands to be executed once the entire graph has been
 *	made and return non-zero to signal that the end of the commands
 *	was reached. These commands are later attached to the postCommands
 *	node and executed by Job_End when all things are done.
 *	This function is called from JobStart via Lst_ForEach.
 *
 * Results:
 *	Always 0, unless the command was "..."
 *
 * Arguments:
 *      char *cmd : command string to print
 *      Job  *job : job for which to print it
 *
 * Side Effects:
 *	If the command begins with a '-' and the shell has no error control,
 *	the JOB_IGNERR flag is set in the job descriptor.
 *	If the command is "..." and we're not ignoring such things,
 *	tailCmds is set to the successor node of the cmd.
 *	numCommands is incremented if the command is actually printed.
 *-----------------------------------------------------------------------
 */
static int
JobPrintCommand (char *cmd, Job *job)
{
    Boolean	  noSpecials;	    /* true if we shouldn't worry about
				     * inserting special commands into
				     * the input stream. */
    Boolean       shutUp = FALSE;   /* true if we put a no echo command
				     * into the command file */
    Boolean	  errOff = FALSE;   /* true if we turned error checking
				     * off before printing the command
				     * and need to turn it back on */
#if defined(unix)
    char       	  *cmdTemplate;	    /* Template to use when printing the
				     * command */
#endif /* defined(unix) */

    char    	  *cmdStart;	    /* Start of expanded command */
    LstNode 	   cmdNode;  	    /* Node for replacing the command */

    noSpecials = (noExecute && ! (job->node->type & OP_MAKE));

    if (strcmp (cmd, "...") == 0) {
	if ((job->flags & JOB_IGNDOTS) == 0) {
	    job->tailCmds = Lst_Succ (Lst_Member (job->node->commands,
						  (ClientData)cmd));
	    return (1);
	}
	return (0);
    }

#if defined(unix)
#    define DBPRINTF(fmt, arg) \
         if (DEBUG(JOB)) printf (fmt, arg); \
	 fprintf (job->cmdFILE, fmt, arg)

#else /* _WIN32 */
#    define DBPRINTF(fmt, arg1, arg2) \
    { \
        char *dbbuf; \
        DWORD dbwritten, bufsize = strlen(arg1) + strlen(arg2) + \
			           strlen(fmt) + 1; \
      \
	dbbuf = (char *) malloc(bufsize); \
	sprintf(dbbuf, fmt, arg1, arg2); \
        if (DEBUG(JOB)) {printf (dbbuf);} \
	if (!WriteFile (job->cmdOUT, dbbuf, strlen(dbbuf), &dbwritten, NULL)){\
	    ErrorMessage("pmake: Write to shell's input stream failed"); \
	} \
	free(dbbuf); \
    }
#endif /* defined(unix) */

    numCommands += 1;

    /*
     * For debugging, we replace each command with the result of expanding
     * the variables in the command.
     */
    cmdNode = Lst_Member (job->node->commands, (ClientData)cmd);
    cmdStart = cmd = Var_Subst (cmd, job->node, FALSE);
    Lst_Replace (cmdNode, (ClientData)cmdStart);

#if defined(unix)
    cmdTemplate = "%s\n";
#endif /* defined(unix) */

    /*
     * Check for leading @'s and -'s to control echoing and error checking.
     */
    while (*cmd == '@' || *cmd == '-') {
	if (*cmd == '@') {
	    shutUp = TRUE;
	} else {
	    errOff = TRUE;
	}
	cmd++;
    }

#if defined(_WIN32)
    while (Parse_DoBackTick(&cmd)) {
	;
    }
#endif /* defined(_WIN32) */

/*
 * for unix the default is to echo commands, under NT since the shell we spawn
 * is cmd /Q ..., all echoing is off regardless of any "echo on" or "echo off",
 * so if the command is to be echoed, we must explicitly do it.
 */
#if defined(unix)
    if (shutUp) {
	if (! (job->flags & JOB_SILENT) && !noSpecials &&
	    commandShell->hasEchoCtl) {
		DBPRINTF ("%s\n", commandShell->echoOff);
	} else {
	    shutUp = FALSE;
	}
    }
    if (errOff) {
	if ( ! (job->flags & JOB_IGNERR) && !noSpecials) {
	    if (commandShell->hasErrCtl) {
		/*
		 * we don't want the error-control commands showing
		 * up either, so we turn off echoing while executing
		 * them. We could put another field in the shell
		 * structure to tell JobDoOutput to look for this
		 * string too, but why make it any more complex than
		 * it already is?
		 */
		if (! (job->flags & JOB_SILENT) && !shutUp &&
		    commandShell->hasEchoCtl) {
			DBPRINTF ("%s\n", commandShell->echoOff);
			DBPRINTF ("%s\n", commandShell->ignErr);
			DBPRINTF ("%s\n", commandShell->echoOn);
		} else {
		    DBPRINTF ("%s\n", commandShell->ignErr);
		}
	    } else if (commandShell->ignErr &&
		       (*commandShell->ignErr != '\0')) {
		/*
		 * The shell has no error control, so we need to be
		 * weird to get it to ignore any errors from the command.
		 * If echoing is turned on, we turn it off and use the
		 * errCheck template to echo the command. Leave echoing
		 * off so the user doesn't see the weirdness we go through
		 * to ignore errors. Set cmdTemplate to use the weirdness
		 * instead of the simple "%s\n" template.
		 */
		if (! (job->flags & JOB_SILENT) && !shutUp &&
		    commandShell->hasEchoCtl) {
			DBPRINTF ("%s\n", commandShell->echoOff);
			DBPRINTF (commandShell->errCheck, cmd);
			shutUp = TRUE;
		}
		cmdTemplate = commandShell->ignErr;
		/*
		 * The error ignoration (hee hee) is already taken care
		 * of by the ignErr template, so pretend error checking
		 * is still on.
		 */
		errOff = FALSE;
	    } else {
		errOff = FALSE;
	    }
	} else {
	    errOff = FALSE;
	}
    }
    DBPRINTF (cmdTemplate, cmd);
    
    if (errOff) {
	/*
	 * If echoing is already off, there's no point in issuing the
	 * echoOff command. Otherwise we issue it and pretend it was on
	 * for the whole command...
	 */
	if (!shutUp && !(job->flags & JOB_SILENT) && commandShell->hasEchoCtl){
	    DBPRINTF ("%s\n", commandShell->echoOff);
	    shutUp = TRUE;
	}
	DBPRINTF ("%s\n", commandShell->errCheck);
    }
    if (shutUp) {
	DBPRINTF ("%s\n", commandShell->echoOn);
    }

#elif defined(_WIN32)
    if (!shutUp && !(job->flags & JOB_SILENT) && !noSpecials) {
	DBPRINTF (commandShell->errCheck, cmd, "");
    }

    if (noSpecials || errOff || (job->flags & JOB_IGNERR)) {
	DBPRINTF ("%s\r\n", cmd, "");
    } else {
/*	DBPRINTF (commandShell->ignErr, cmd, eventName); */
	DBPRINTF (commandShell->ignErr, cmd, "");
    }
#endif /* defined(unix) */

    return (0);
}

/*-
 *-----------------------------------------------------------------------
 * JobSaveCommand --
 *	Save a command to be executed when everything else is done.
 *	Callback function for JobFinish...
 *
 * Results:
 *	Always returns 0
 *
 * Side Effects:
 *	The command is tacked onto the end of postCommands's commands list.
 *
 *-----------------------------------------------------------------------
 */
static int
JobSaveCommand (char *cmd, GNode *gn)
{
    cmd = Var_Subst (cmd, gn, FALSE);
    (void)Lst_AtEnd (postCommands->commands, (ClientData)cmd);
    return (0);
}
#if defined(unix)

/*-
 *-----------------------------------------------------------------------
 * JobFinish  --
 *	Do final processing for the given job including updating
 *	parents and starting new jobs as available/necessary. Note
 *	that we pay no attention to the JOB_IGNERR flag here.
 *	This is because when we're called because of a noexecute flag
 *	or something, jstat.w_status is 0 and when called from
 *	Job_CatchChildren, the status is zeroed if it s/b ignored.
 *
 * Results:
 *	None
 *
 * Arguments:
 *      Job        *job    : job to finish
 *      union wait  status : sub-why job went away
 *
 * Side Effects:
 *	Some nodes may be put on the toBeMade queue.
 *	Final commands for the job are placed on postCommands.
 *
 *	If we got an error and are aborting (aborting == ABORT_ERROR) and
 *	the job list is now empty, we are done for the day.
 *	If we recognized an error (errors !=0), we set the aborting flag
 *	to ABORT_ERROR so no more jobs will be started.
 *-----------------------------------------------------------------------
 */
void
JobFinish (Job *job, WAIT_TYPE status)
{
    Boolean 	  done;

    if ((WIFEXITED(status) &&
	  (((status.w_retcode != 0) && !(job->flags & JOB_IGNERR)) ||
	   !backwards)) ||
	(WIFSIGNALED(status) && (status.w_termsig != SIGCONT) &&
	 (!(job->flags & JOB_IGNERR) || !backwards)))
    {
	/*
	 * If it exited non-zero and either we're doing things our
	 * way or we're not ignoring errors, the job is finished.
	 * Similarly, if the shell died because of a signal (the
	 * conditional on SIGCONT is to handle the mapping of Sprite
	 * signal semantics whereby wait will return a signal
	 * termination with SIGCONT being the signal to indicate that the
	 * child has resumed), the job is also finished. In these
	 * cases, finish out the job's output before printing the exit
	 * status...
	 */
	if (usePipes) {
#ifdef RMT_WILL_WATCH
	    Rmt_Ignore(job->inPipe);
#else
	    FD_CLR(job->inPipe, &outputs);
#endif /* RMT_WILL_WATCH */
	    if (job->outPipe != job->inPipe) {
		(void)close (job->outPipe);
	    }
	    JobDoOutput (job, TRUE);
	    (void)close (job->inPipe);
	} else {
	    (void)close (job->outFd);
	    JobDoOutput (job, TRUE);
	}

	if (job->cmdFILE != NULL && job->cmdFILE != stdout) {
	    fclose(job->cmdFILE);
	}
	done = TRUE;
    } else if (backwards &&
	       ((WIFSIGNALED(status) && (status.w_termsig != SIGCONT)) ||
		(WIFEXITED(status) && (status.w_retcode != 0))))
    {
	/*
	 * Deal with ignored errors in -B mode. We need to print a message
	 * telling of the ignored error as well as setting status.w_status
	 * to 0 so the next command gets run. To do this, we set done to be
	 * TRUE if in -B mode and the job exited non-zero. Note we don't
	 * want to close down any of the streams until we know we're at the
	 * end.
	 */
	done = TRUE;
    } else {
	/*
	 * No need to close things down or anything.
	 */
	done = FALSE;
    }
    
    if (done ||
	WIFSTOPPED(status) ||
	(WIFSIGNALED(status) && (status.w_termsig == SIGCONT)) ||
	DEBUG(JOB))
    {
	FILE	  *out;
	
	if (backwards && !usePipes && (job->flags & JOB_IGNERR)) {
	    /*
	     * If output is going to a file and this job is ignoring
	     * errors, arrange to have the exit status sent to the
	     * output file as well.
	     */
	    out = fdopen (job->outFd, "w");
	} else {
	    out = stdout;
	}

	if (WIFEXITED(status)) {
	    if (status.w_retcode != 0) {
		if (usePipes && job->node != lastNode) {
		    fprintf (out, targFmt, job->node->name);
		    lastNode = job->node;
		}
		fprintf (out, "*** Error code %d%s\n", status.w_retcode,
			 (job->flags & JOB_IGNERR) ? " (ignored)" : "");

		if (job->flags & JOB_IGNERR) {
		    status.w_status = 0;
		}
	    } else if (DEBUG(JOB)) {
		if (usePipes && job->node != lastNode) {
		    fprintf (out, targFmt, job->node->name);
		    lastNode = job->node;
		}
		fprintf (out, "*** Completed successfully\n");
	    }
	} else if (WIFSTOPPED(status)) {
	    if (usePipes && job->node != lastNode) {
		fprintf (out, targFmt, job->node->name);
		lastNode = job->node;
	    }
	    if (! (job->flags & JOB_REMIGRATE)) {
		fprintf (out, "*** Stopped -- signal %d\n", status.w_stopsig);
	    }
	    job->flags |= JOB_RESUME;
	    (void)Lst_AtEnd(stoppedJobs, (ClientData)job);
	    fflush(out);
	    return;
	} else if (status.w_termsig == SIGCONT) {
	    /*
	     * If the beastie has continued, shift the Job from the stopped
	     * list to the running one (or re-stop it if concurrency is
	     * exceeded) and go and get another child.
	     */
	    if (job->flags & (JOB_RESUME|JOB_REMIGRATE|JOB_RESTART)) {
		if (usePipes && job->node != lastNode) {
		    fprintf (out, targFmt, job->node->name);
		    lastNode = job->node;
		}
		fprintf (out, "*** Continued\n");
	    }
	    if (! (job->flags & JOB_CONTINUING)) {
		JobRestart(job);
	    } else {
		Lst_AtEnd(jobs, (ClientData)job);
		nJobs += 1;
		if (! (job->flags & JOB_REMOTE)) {
		    nLocal += 1;
		}
		if (nJobs == maxJobs) {
		    jobFull = TRUE;
		    if (DEBUG(JOB)) {
			printf("Job queue is full.\n");
		    }
		}
	    }
	    fflush(out);
	    return;
	} else {
	    if (usePipes && job->node != lastNode) {
		fprintf (out, targFmt, job->node->name);
		lastNode = job->node;
	    }
	    fprintf (out, "*** Signal %d%s\n", status.w_termsig,
		     (job->flags & JOB_IGNERR) ? " (ignored)" : "");

	    if (job->flags & JOB_IGNERR) {
		status.w_termsig = 0;
	    }
	}

	fflush (out);
    }

    /*
     * Now handle the -B-mode stuff. If the beast still isn't finished,
     * try and restart the job on the next command. If JobStart says it's
     * ok, it's ok. If there's an error, this puppy is done.
     */
    if (backwards && (status.w_status == 0) &&
	!Lst_IsAtEnd (job->node->commands))
    {
	switch (JobStart (job->node,
			  job->flags & JOB_IGNDOTS,
			  job))
	{
	    case JOB_RUNNING:
		done = FALSE;
		break;
	    case JOB_ERROR:
		done = TRUE;
		status.w_retcode = 1;
		break;
	    case JOB_FINISHED:
		/*
		 * If we got back a JOB_FINISHED code, JobStart has already
		 * called Make_Update and freed the job descriptor. We set
		 * done to false here to avoid fake cycles and double frees.
		 * JobStart needs to do the update so we can proceed up the
		 * graph when given the -n flag..
		 */
		done = FALSE;
		break;
	}
    } else {
	done = TRUE;
    }
		

    if (done &&
	(aborting != ABORT_ERROR) &&
	(aborting != ABORT_INTERRUPT) &&
	(status.w_status == 0))
    {
	/*
	 * As long as we aren't aborting and the job didn't return a non-zero
	 * status that we shouldn't ignore, we call Make_Update to update
	 * the parents. In addition, any saved commands for the node are placed
	 * on the .END target.
	 */
	if (job->tailCmds != NILLNODE) {
	    Lst_ForEachFrom (job->node->commands, job->tailCmds,
			     JobSaveCommand,
			     (ClientData)job->node);
	}
	job->node->made = MADE;
	Make_Update (job->node);
	free((Address)job);
    } else if (status.w_status) {
	errors += 1;
	free((Address)job);
    }

    while (!errors && !jobFull && !Lst_IsEmpty(stoppedJobs)) {
	JobRestart((Job *)Lst_DeQueue(stoppedJobs));
    }

    /*
     * Set aborting if any error.
     */
    if (errors && !keepgoing && (aborting != ABORT_INTERRUPT)) {
	/*
	 * If we found any errors in this batch of children and the -k flag
	 * wasn't given, we set the aborting flag so no more jobs get
	 * started.
	 */
	aborting = ABORT_ERROR;
    }
    
    if ((aborting == ABORT_ERROR) && Job_Empty()) {
	/*
	 * If we are aborting and the job table is now empty, we finish.
	 */
	(void) unlink (tfile);
	Finish (errors);
    }
}
#else /* _WIN32 */

/***********************************************************************
 *				JobNTFinish
 ***********************************************************************
 * SYNOPSIS:	    NT version of JobFinish.  Does final processing
 *                  for a job.  Decides if an error occurred and if one
 *                  did, exits pmake.
 * CALLED BY:	    
 * RETURN:	    nothing
 * SIDE EFFECTS:    pmake may exit if an error occurred.  Job process
 *                  HANDLE is closed.  Some jobs may be put on tobemade
 *                  queue.
 *
 * STRATEGY:	    Simply check flags and error status to see what
 *                  needs to be done.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tb	8/08/96   	Initial Revision
 *
 ***********************************************************************/
void
JobNTFinish (Job *job, WAIT_TYPE status)
{
    nLocal -= 1;

    (void) CloseHandle(job->pid.hProcess);
    (void) CloseHandle(job->pid.hThread);

    job->pid.hProcess = INVALID_HANDLE_VALUE;
    job->pid.hThread  = INVALID_HANDLE_VALUE;

    if (status == 0 && DEBUG(JOB)) {
	HANDLE        out = GetStdHandle(STD_OUTPUT_HANDLE);
	unsigned long numWrit;
	
	if (out == INVALID_HANDLE_VALUE) {
	    ErrorMessage("pmake");
	    ExitProcess(1);
	}

	if(!WriteFile(out, "*** Completed sucessfully\r\n",
		      strlen("*** Completed sucessfully\r\n"), &numWrit,
		      NULL) || numWrit == 0) {
	    ErrorMessage("pmake");
	}
    }

    if ((aborting != ABORT_ERROR) && (aborting != ABORT_INTERRUPT) &&
	(status   == 0)) {
	if (job->tailCmds != NILLNODE) {
	    Lst_ForEachFrom (job->node->commands, job->tailCmds,
			     JobSaveCommand, (ClientData) job->node);
	}
	job->node->made = MADE;
	Make_Update (job->node);
    } else if (status != 0) {
	errors += 1;
    }

    free(job);

    /*
     * Set aborting if any error.
     */
    if (errors && !keepgoing && (aborting != ABORT_INTERRUPT)) {
	/*
	 * If we found any errors in this batch of children and the -k flag
	 * wasn't given, we set the aborting flag so no more jobs get
	 * started.
	 */
	aborting = ABORT_ERROR;
    }
    
    if ((aborting == ABORT_ERROR) && Job_Empty()) {
	/*
	 * If we are aborting and the job table is now empty, we finish.
	 */
#if 0
	Finish (errors);
#endif
	printf("*** error code %d\n\nStop.", status);
	ExitProcess(1);
    }
}	/* End of JobNTFinish.	*/
#endif /* defined(unix) */

/*-
 *-----------------------------------------------------------------------
 * Job_Touch --
 *	Touch the given target. Called by JobStart when the -t flag was
 *	given
 *
 * Results:
 *	None
 *
 * Arguments:
 *      GNode   *gn     : the node of the file to touch
 *      Boolean  silent : TRUE if should not print message
 *
 * Side Effects:
 *	The data modification of the file is changed. In addition, if the
 *	file did not exist, it is created.
 *-----------------------------------------------------------------------
 */
void
Job_Touch (GNode *gn, Boolean silent)
{
#if defined(unix)
    int		  streamID;   	/* ID of stream opened to do the touch */
#endif /* defined(unix) */

    if (gn->type & (OP_JOIN|OP_USE|OP_EXEC|OP_DONTCARE)) {
	/*
	 * .JOIN, .USE, .ZEROTIME and .DONTCARE targets are "virtual" targets
	 * and, as such, shouldn't really be created.
	 */
	return;
    }
    
    if (!silent) {
	printf ("touch %s\n", gn->name);
    }

    if (noExecute) {
	return;
    }

#ifdef unix
    if (gn->type & OP_ARCHV) {
	Arch_Touch (gn);
    } else if (gn->type & OP_LIB) {
	Arch_TouchLib (gn);
    } else 
#endif /* unix */
#if defined(unix)
    {
	char	*file = gn->path ? gn->path : gn->name;

	if (utime(file, NULL) < 0){
	    streamID = open (file, O_RDWR | O_CREAT, 0666);

	    if (streamID >= 0) {
		char	c;

		/*
		 * Read and write a byte to the file to change the
		 * modification time, then close the file.
		 */
		if (read(streamID, &c, 1) == 1) {
		    lseek(streamID, 0L, SEEK_SET);
		    write(streamID, &c, 1);
		}
		
		(void)close (streamID);
	    } else {
		extern char *sys_errlist[];

		printf("*** couldn't touch %s: %s", file, sys_errlist[errno]);
	    }
	}
    }
#endif /* defined(unix) */
}

/*-
 *-----------------------------------------------------------------------
 * Job_CheckCommands --
 *	Make sure the given node has all the commands it needs. 
 *
 * Results:
 *	TRUE if the commands list is/was ok.
 *
 * Arguments:
 *      GNode    *gn       : The target whose commands need verifying
 *      AbortMsg abortProc : Function to abort with message
 *
 * Side Effects:
 *	The node will have commands from the .DEFAULT rule added to it
 *	if it needs them.
 *-----------------------------------------------------------------------
 */
Boolean
Job_CheckCommands (GNode *gn, AbortMsg abortProc)
{
    if (OP_NOP(gn->type) && Lst_IsEmpty (gn->commands) &&
	(gn->type & OP_LIB) == 0) {
	/*
	 * No commands. Look for .DEFAULT rule from which we might infer
	 * commands 
	 */
	if ((DEFAULT != NILGNODE) && !Lst_IsEmpty(DEFAULT->commands)) {
	    /*
	     * Make only looks for a .DEFAULT if the node was never the
	     * target of an operator, so that's what we do too. If
	     * a .DEFAULT was given, we substitute its commands for gn's
	     * commands and set the IMPSRC variable to be the target's name
	     * The DEFAULT node acts like a transformation rule, in that
	     * gn also inherits any attributes or sources attached to
	     * .DEFAULT itself.
	     */
	    Make_HandleUse(DEFAULT, gn);
	    Var_Set (IMPSRC, Var_Value (TARGET, gn), gn);
	} else if (Dir_MTime (gn) == 0) {
	    /*
	     * The node wasn't the target of an operator we have no .DEFAULT
	     * rule to go on and the target doesn't already exist. There's
	     * nothing more we can do for this branch. If the -k flag wasn't
	     * given, we stop in our tracks, otherwise we just don't update
	     * this node's parents so they never get examined. 
	     */
	    if (gn->type & OP_DONTCARE) {
		printf ("Can't figure out how to make %s (ignored)\n",
			gn->name);
	    } else if (keepgoing) {
		printf ("Can't figure out how to make %s (continuing)\n",
			gn->name);
		return (FALSE);
	    } else {
		(*abortProc) ("Can't figure out how to make %s. Stop",
			     gn->name);
		return(FALSE);
	    }
	}
    }
    return (TRUE);
}

#if defined(unix)
 
#ifdef RMT_WILL_WATCH
/*-
 *-----------------------------------------------------------------------
 * JobLocalInput --
 *	Handle a pipe becoming readable. Callback function for Rmt_Watch
 *
 * Results:
 *	None
 *
 * Arguments:
 *      int  stream : Stream that's ready (ignored)
 *      Job *job    : Job to which the stream belongs
 *
 * Side Effects:
 *	JobDoOutput is called.
 *	
 *-----------------------------------------------------------------------
 */
static void
JobLocalInput(int stream, Job *job)
{
    JobDoOutput(job, FALSE);
}
#endif /* RMT_WILL_WATCH */
#endif /* defined(unix) */

/*-
 *-----------------------------------------------------------------------
 * JobExec --
 *	Execute the shell for the given job. Called from JobStart and
 *	JobRestart.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	A shell is executed, outputs is altered and the Job structure added
 *	to the job table.
 *
 *-----------------------------------------------------------------------
 */
static void
JobExec(Job *job, ARGV_TYPE argv)
{
#if defined(unix)
    int	    	      cpid;	    	    /* ID of new child */
#else /* _WIN32 */
    STARTUPINFO       st_info = {0};        /* initialization params for child
					     */
#endif /* defined(unix) */
    volatile unsigned jobflags = job->flags;/* temp unsigned to contain
					     * job->flags this should fix the
					     * memory error obtained by reading
					     * too many bytes from job->flags*/
    

    if (DEBUG(JOB)) {

#if defined(unix)
	int 	  i;
#endif /* defined(unix) */

	printf("Running %s %sly\n", job->node->name,
	       (jobflags & JOB_REMOTE)?"remote":"local");
	printf("\tCommand: ");

#if defined(unix)
	for (i = 0; argv[i] != (char *)NULL; i++) {
	    printf("%s ", argv[i]);
	}
	printf("\n");
#elif defined(_WIN32)
	printf("%s\n", argv);
#endif /* defined(unix) */

    }
    
    /*
     * Some jobs produce no output and it's disconcerting to have
     * no feedback of their running (since they produce no output, the
     * banner with their name in it never appears). This is an attempt to
     * provide that feedback, even if nothing follows it.
     */
#if defined(unix)
    if (    (lastNode != job->node)
	&&  (jobflags & JOB_FIRST)
	&& !(jobflags & JOB_SILENT) )
    {
	printf(targFmt, job->node->name);
	lastNode = job->node;
    }
#endif /* defined(unix) */

#if defined (unix)

#    ifdef RMT_NO_EXEC
    if (jobflags & JOB_REMOTE) {
	goto jobExecFinish;
    }
#    endif /* RMT_NO_EXEC */

    if ((cpid =  vfork()) == -1) {
	Punt ("Cannot fork");
    } else if (cpid == 0) {
	/* 
	 * Must duplicate the input stream down to the child's input and
	 * reset it to the beginning (again). Since the stream was marked
	 * close-on-exec, we must clear that bit in the new input.
	 */
	(void) dup2(fileno(job->cmdFILE), 0);
	fcntl(0, F_SETFD, 0);
	lseek(0, 0L, SEEK_SET);

	if (usePipes) {
	    /*
	     * Set up the child's output to be routed through the pipe
	     * we've created for it.
	     */
	    (void) dup2 (job->outPipe, 1);
	} else {
	    /*
	     * We're capturing output in a file, so we duplicate the
	     * descriptor to the temporary file into the standard
	     * output.
	     */
	    (void) dup2 (job->outFd, 1);
	}
	/*
	 * The output channels are marked close on exec. This bit was
	 * duplicated by the dup2 (on some systems), so we have to clear
	 * it before routing the shell's error output to the same place as
	 * its standard output.
	 */
	fcntl(1, F_SETFD, 0);
	(void) dup2 (1, 2);

#    ifdef USE_PGRP
	/*
	 * We want to switch the child into a different process family so
	 * we can kill it and all its descendants in one fell swoop,
	 * by killing its process family, but not commit suicide.
	 */
	
#        ifdef SYSV
	(void) setpgrp();
#        else
	(void) setpgrp(0, getpid());
#        endif /* SYSV */

#    endif /* USE_PGRP */

	if (jobflags & JOB_REMOTE) {
	    Rmt_Exec (shellPath, argv, FALSE);
	} else {
	    (void) execv (shellPath, argv);
	}

	(void) write (2, "Could not execute shell\n",
		 sizeof ("Could not execute shell"));
	_exit (1);

    } else {
	job->pid = cpid;

#elif defined(_WIN32)
	/* Now set up the STARTUPINFO structure and spawn the shell. */

     /*
      * Must set the file pointer to the beginning of the file so that
      * when cmd inherits the HANDLE it has something to read
      */
     SetFilePointer(job->cmdOUT, 0, NULL, FILE_BEGIN);

     st_info.cb          = sizeof(STARTUPINFO);
     st_info.lpReserved  = NULL;
     st_info.lpReserved2 = NULL;
     st_info.cbReserved2 = 0;
     st_info.lpDesktop   = NULL;
     st_info.lpTitle     = NULL;
     st_info.dwFlags     = STARTF_USESTDHANDLES;
     st_info.hStdInput   = job->cmdOUT;
     st_info.hStdOutput  = GetStdHandle(STD_OUTPUT_HANDLE);
     st_info.hStdError   = GetStdHandle(STD_ERROR_HANDLE);

     if (!CreateProcess(NULL, argv, NULL, NULL, TRUE,
			NORMAL_PRIORITY_CLASS,
			NULL, NULL, &st_info, &job->pid)) {
         unsigned long numWritten;

         (void) WriteFile(GetStdHandle(STD_OUTPUT_HANDLE),
			  "Could not execute shell\r\n",
			  sizeof("Could not execute shell\r\n"),
			  &numWritten, NULL);
	 ExitProcess(1); 
     } else {
         JobAddHandle(job->pid.hProcess, children);
     }
     (void) CloseHandle(job->cmdOUT);
#endif /* defined(unix) */
#if defined(unix)
	if (usePipes && (jobflags & JOB_FIRST) ) {
	    /*
	     * The first time a job is run for a node, we set the current
	     * position in the buffer to the beginning and mark another
	     * stream to watch in the outputs mask
	     */
	    job->curPos = 0;

#    ifdef RMT_WILL_WATCH
	    Rmt_Watch(job->inPipe, JobLocalInput, (char *) job);
#    else
	    FD_SET(job->inPipe, &outputs);
#    endif /* RMT_WILL_WATCH */

	}
	jobflags = job->flags;
	if (jobflags & JOB_REMOTE) {
	    job->rmtID = (char *)Rmt_LastID(job->pid);
	} else {
	    nLocal += 1;
	    /*
	     * XXX: Used to not happen if CUSTOMS. Why?
	     */
	    if (job->cmdFILE != stdout) {
		fclose(job->cmdFILE);
		job->cmdFILE = NULL;
	    }
	}
    }
#elif defined(_WIN32)
    nLocal += 1;
#endif /* defined(unix) */

#if defined(RMT_NO_EXEC)
jobExecFinish:
#endif /* defined(RMT_NO_EXEC) */
    /*
     * Now the job is actually running, add it to the table.
     */
    nJobs += 1;
    (void)Lst_AtEnd (jobs, (ClientData)job);
    if (nJobs == maxJobs) {
	jobFull = TRUE;
    }
}
#if defined(_WIN32)

/***********************************************************************
 *				JobAddHandle
 ***********************************************************************
 * SYNOPSIS:	    Adds a handle to an array of handles
 * CALLED BY:	    JobExec
 * RETURN:	    TRUE on successful addition, FALSE on failure
 * SIDE EFFECTS:    Changes the second parameter
 *
 * STRATEGY:	    Emulates unix FD_SET.  Just add a handle to the end
 *                  of the array.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/07/96   	Initial Revision
 *
 ***********************************************************************/
static Boolean
JobAddHandle (HANDLE handle, HandleList *hList)
{
    if (hList->numFilled < HANDLE_LIST_MAX) {
	hList->hArray[hList->numFilled++] = handle;
	return TRUE;
    }

    if (DEBUG(JOB)) {
	Error("Couldn't add handle.\n");
    }

    return FALSE;
}	/* End of JobAddHandle.	*/
#if 0  /* don't need this function because we aren't doing any parallel work */

/***********************************************************************
 *				JobIsSetHandle
 ***********************************************************************
 * SYNOPSIS:	    Predicate to see if a handle is present in a 
 *                  HandleList
 * CALLED BY:	    
 * RETURN:	    TRUE if handle is in hList, FALSE otherwise
 * SIDE EFFECTS:    NONE
 *
 * STRATEGY:	    Does a linear search to see if handle is in hList
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/07/96   	Initial Revision
 *
 ***********************************************************************/
static Boolean
JobIsSetHandle (HANDLE handle, HandleList *hList)
{
    int i;

    for (i = 0; i < hList->numFilled; i++) {
        if (hList->hArray[i] == handle) {
	    return TRUE;
	}
    }

    return FALSE;
}	/* End of JobIsSetHandle.	*/
#endif /* 0 */

/***********************************************************************
 *				JobRemoveHandle
 ***********************************************************************
 * SYNOPSIS:	    Removes a handle from a HandleList
 * CALLED BY:	    JobFinish, JobStart
 * RETURN:	    TRUE if a handle was removed, FALSE if not
 * SIDE EFFECTS:    The HandleList is altered on success
 *
 * STRATEGY:	    Find the handle in the array.  Copy the last valid
 *                  handle to the slot of the doomed handle.
 *                  Set the value of the slot where the last valid
 *                  handle lies to be INVALID_HANDLE_VALUE, and
 *                  decrement the count of valid handles
 *                  the slot where it was equal to INVALID_HANDLE_VALUE.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/07/96   	Initial Revision
 *
 ***********************************************************************/
static Boolean
JobRemoveHandle (HANDLE handle, HandleList *hList)
{
    int i;

    for (i = 0; i < hList->numFilled; i++) {
        if (hList->hArray[i] == handle) {
	    /*
	     * the position of the last valid handle is just the
	     * number of slots filled - 1
	     */
	    hList->hArray[i] = hList->hArray[--(hList->numFilled)];
	    hList->hArray[hList->numFilled] = INVALID_HANDLE_VALUE;

	    return TRUE;
	}
    }

    return FALSE;
}	/* End of JobRemoveHandle.	*/

#endif /* defined (_WIN32) */


/*-
 *-----------------------------------------------------------------------
 * JobMakeArgv --
 *      UNIX --
 *	Create the argv needed to execute the shell for a given job.
 *
 *      WINNT --
 *      Create a command line string to pass to CreateProcess
 *
 * Results:
 *      None
 *
 * Side Effects:
 *
 *-----------------------------------------------------------------------
 */
static void
JobMakeArgv(Job *job, ARGV_TYPE argv)
{
#if defined(unix)
    int	    	  argc;
    static char	  args[10]; 	/* For merged arguments */
    
    argv[0] = shellName;
    argc = 1;

    if ((commandShell->exit && (*commandShell->exit != '-')) ||
	(commandShell->echo && (*commandShell->echo != '-')))
    {
	/*
	 * At least one of the flags doesn't have a minus before it, so
	 * merge them together. Have to do this because the *(&(@*#*&#$#
	 * Bourne shell thinks its second argument is a file to source.
	 * Grrrr. Note the ten-character limitation on the combined arguments.
	 */
	(void)sprintf(args, "-%s%s",
		      ((job->flags & JOB_IGNERR) ? "" :
		       (commandShell->exit ? commandShell->exit : "")),
		      ((job->flags & JOB_SILENT) ? "" :
		       (commandShell->echo ? commandShell->echo : "")));

	if (args[1]) {
	    argv[argc] = args;
	    argc++;
	}
    } else {
	if (!(job->flags & JOB_IGNERR) && commandShell->exit) {
	    argv[argc] = commandShell->exit;
	    argc++;
	}
	if (!(job->flags & JOB_SILENT) && commandShell->echo) {
	    argv[argc] = commandShell->echo;
	    argc++;
	}
    }
    argv[argc] = (char *)NULL;

#elif defined (_WIN32)
    sprintf (argv, "%s", shellName);
    if (!(job->flags & JOB_IGNERR) && commandShell->exit) {
        strcat(argv, commandShell->exit);
    }
    if (!(job->flags & JOB_SILENT) && commandShell->echo) {
        strcat(argv, commandShell->echo);
    }
#endif /* defined(unix) */
    
    JobSetChildsPrefix(job->node);
}

#if defined(unix)
/*-
 *-----------------------------------------------------------------------
 * JobInitOutput  --
 *	Create whatever streams are necessary to catch the output of
 *	this job.
 *
 * Results:
 *	FALSE if couldn't create the output.
 *	TRUE if job is set up for output.
 *
 * Side Effects:
 *	job->inPipe/job->outPipe or job->outFd is set if TRUE.
 *	Any stream opened is set to close-on-exec.
 *-----------------------------------------------------------------------
 */
static Boolean
JobInitOutput(Job *job)
{
    static int          jobno  = 0; 
                              /* job number of catching output in a file */
    if (!backwards || !(job->flags & JOB_OUTPUT_SET)) {
	if (usePipes) {
	    int fd[2];
	    
	    if (pipe(fd) < 0) {
		return(FALSE);
	    }
	    
	    job->inPipe = fd[0];
	    job->outPipe = fd[1];
	    (void)fcntl (job->inPipe, F_SETFD, 1);
	    (void)fcntl (job->outPipe, F_SETFD, 1);
	} else {
	    sprintf (job->outFile, "%s%02d", tfile, jobno);
	    jobno = (jobno + 1) % 100;
	    job->outFd = open(job->outFile,O_WRONLY|O_CREAT|O_APPEND,0600);
	    if (job->outFd < 0) {
		return(FALSE);
	    }
	    (void)fcntl (job->outFd, F_SETFD, 1);
	    printf ("Remaking `%s'\n", job->node->name);
	    fflush (stdout);
	}
	job->flags |= JOB_OUTPUT_SET;
    }
    return(TRUE);
}

/*-
 *-----------------------------------------------------------------------
 * JobRestart --
 *	Restart a job that stopped for some reason. If the job stopped
 *	because it migrated home again, we tell the Rmt module to
 *	find a new home for it and make it runnable if Rmt_ReExport
 *	succeeded (if it didn't and the job may be run locally, we
 *	simply resume it). If the job didn't run and can now, we run it.
 *
 * Results:
 *	None.
 *
 * Arguments:
 *      Job *job : Job to restart
 *
 * Side Effects:
 *	jobFull will be set if the job couldn't be run.
 *
 *-----------------------------------------------------------------------
 */
static void
JobRestart(Job *job)
{
    if (job->flags & JOB_REMIGRATE) {
	if (DEBUG(JOB)) {
	    printf("Remigrating %x\n", job->pid);
	}
	if (!Rmt_ReExport(job->pid)) {
	    if (DEBUG(JOB)) {
		printf("Couldn't migrate...");
	    }
	    if (nLocal != maxLocal) {
		/*
		 * Job cannot be remigrated, but there's room on the local
		 * machine, so resume the job and note that another
		 * local job has started.
		 */
		if (DEBUG(JOB)) {
		    printf("resuming on local machine\n");
	        }
		KILL(job->pid, SIGCONT);
		nLocal +=1;
		job->flags &= ~(JOB_REMIGRATE|JOB_RESUME);
	    } else {
		/*
		 * Job cannot be restarted. Mark the table as full and
		 * place the job back on the list of stopped jobs.
		 */
		if (DEBUG(JOB)) {
		    printf("holding\n");
		}
		(void)Lst_AtFront(stoppedJobs, (ClientData)job);
		jobFull = TRUE;
		if (DEBUG(JOB)) {
		    printf("Job queue is full.\n");
		}
		return;
	    }
	} else {
	    /*
	     * Clear out the remigrate and resume flags. If MIGRATE was set,
	     * leave that around for JobFinish to see so it doesn't print out
	     * that the job was continued.
	     */
	    job->flags &= ~(JOB_REMIGRATE|JOB_RESUME);
	}
	
	(void)Lst_AtEnd(jobs, (ClientData)job);
	nJobs += 1;
	if (nJobs == maxJobs) {
	    jobFull = TRUE;
	    if (DEBUG(JOB)) {
		printf("Job queue is full.\n");
	    }
	}
    } else
      if (job->flags & JOB_RESTART) {
	/*
	 * Set up the control arguments to the shell. This is based on the
	 * flags set earlier for this job. If the JOB_IGNERR flag is clear,
	 * the 'exit' flag of the commandShell is used to cause it to exit
	 * upon receiving an error. If the JOB_SILENT flag is clear, the
	 * 'echo' flag of the commandShell is used to get it to start echoing
	 * as soon as it starts processing commands. 
	 */
	char	  *argv[4];

	JobMakeArgv(job, argv);
	
	if (DEBUG(JOB)) {
	    printf("Restarting %s...", job->node->name);
	}
	/*
	 * JOB_FIRST flag indicates output still not set up for the job, so
	 * try and set it up.
	 */
	if (!(job->flags & JOB_OUTPUT_SET) && !JobInitOutput(job)) {
	    if (DEBUG(JOB)) {
		printf("holding (no avail streams)\n");
	    }
	    (void)Lst_AtFront(stoppedJobs, (ClientData)job);
	    jobFull = TRUE;
	    if (DEBUG(JOB)) {
		printf("Job queue is full.\n");
	    }
	    return;
	}

	if ((job->node->type&OP_NOEXPORT) ||
#ifdef RMT_NO_EXEC
	    !Rmt_Export(shellPath, argv, job)
#else
	    !Rmt_Begin(shellPath, argv, job->node)
#endif
	    )
	{
	    if (
#ifdef sparc	    	    /* KLUDGE */
		(job->node->type & OP_M68020) ||
#endif
		((nLocal >= maxLocal) && ! (job->flags & JOB_SPECIAL)))
	    {
		/*
		 * Can't be exported and not allowed to run locally -- put it
		 * back on the hold queue and mark the table full
		 */
		if (DEBUG(JOB)) {
		    printf("holding\n");
		}
		(void)Lst_AtFront(stoppedJobs, (ClientData)job);
		jobFull = TRUE;
		if (DEBUG(JOB)) {
		    printf("Job queue is full.\n");
		}
		return;
	    } else {
		/*
		 * Job may be run locally.
		 */
		if (DEBUG(JOB)) {
		    printf("running locally\n");
		}
		job->flags &= ~JOB_REMOTE;
	    }
	} else {
	    /*
	     * Can be exported. Hooray!
	     */
	    if (DEBUG(JOB)) {
		printf("exporting\n");
	    }
	    job->flags |= JOB_REMOTE;
	}
	JobExec(job, argv);
    } else {
	/*
	 * The job has stopped and needs to be restarted. Why it stopped,
	 * we don't know...
	 */
	if (DEBUG(JOB)) {
	    printf("Resuming %s...", job->node->name);
	}
	if (((job->flags & JOB_REMOTE) ||
	     (nLocal < maxLocal) ||
	     (((job->flags & JOB_SPECIAL) ||
	       (job->node->type & OP_NOEXPORT)) &&
	      (maxLocal == 0))) &&
	    (nJobs != maxJobs))
	{
	    /*
	     * If the job is remote, it's ok to resume it as long as the
	     * maximum concurrency won't be exceeded. If it's local and
	     * we haven't reached the local concurrency limit already (or the
	     * job must be run locally and maxLocal is 0), it's also ok to
	     * resume it.
	     */
	    Boolean error;
	    extern int errno;
	    extern char *sys_errlist[];
	    WAIT_TYPE status;
	    
#if defined(RMT_WANTS_SIGNALS)
	    if (job->flags & JOB_REMOTE) {
		error = !Rmt_Signal(job, SIGCONT);
	    } else
#endif	/* defined(RMT_WANTS_SIGNALS) */
		error = (KILL(job->pid, SIGCONT) != 0);

	    if (!error) {
		/*
		 * Make sure the user knows we've continued the beast and
		 * actually put the thing in the job table.
		 */
		job->flags |= JOB_CONTINUING;
		status.w_termsig = SIGCONT;
		JobFinish(job, status);
		
		job->flags &= ~(JOB_RESUME|JOB_CONTINUING);
		if (DEBUG(JOB)) {
		    printf("done\n");
		}
	    } else {
		Error("couldn't resume %s: %s", job->node->name,
		      sys_errlist[errno]);
		status.w_status = 0;
		status.w_retcode = 1;
		JobFinish(job, status);
	    }
	} else {
	    /*
	     * Job cannot be restarted. Mark the table as full and
	     * place the job back on the list of stopped jobs.
	     */
	    if (DEBUG(JOB)) {
		printf("table full\n");
	    }
	    (void)Lst_AtFront(stoppedJobs, (ClientData)job);
	    jobFull = TRUE;
	    if (DEBUG(JOB)) {
		printf("Job queue is full.\n");
	    }
	}
    }
}
#endif /* defined(unix) */

/*-
 *-----------------------------------------------------------------------
 * JobStart  --
 *	Start a target-creation process going for the target described
 *	by the graph node gn. 
 *
 * Results:
 *	JOB_ERROR if there was an error in the commands, JOB_FINISHED
 *	if there isn't actually anything left to do for the job and
 *	JOB_RUNNING if the job has been started.
 *
 * Arguments:
 *      GNode *gn       : target to create
 *      short  flags    : flags for the job to override normal ones.
 *                        eg JOB_SPECIAL or JOB_IGNDOTS
 *      Job   *previous : The previous Job structure for this node if any.
 *
 * Side Effects:
 *	A new Job node is created and added to the list of running
 *	jobs. PMake is forked and a child shell created.
 *-----------------------------------------------------------------------
 */
static int
JobStart (GNode *gn, short flags, Job *previous)
{
    register Job *job;       /* new job descriptor */

#if defined(unix)
    char	 *argv[4];   /* Argument vector to shell */
#elif defined (_WIN32)
    ARGV_TYPE     argv;      /* command line to pass to CreateProcess */
#endif /* defined(unix) */

    Boolean	  cmdsOK;     /* true if the nodes commands were all right */
    Boolean 	  local;      /* Set true if the job was run locally */
    Boolean 	  noExec;     /* Set true if we decide not to run the job */

    if (previous != (Job *)NULL) {
	previous->flags &= ~ (JOB_FIRST|JOB_IGNERR|JOB_SILENT|JOB_REMOTE);
	job = previous;
    } else {
	job = (Job *) malloc (sizeof (Job));
	if (job == (Job *)NULL) {
	    Punt("JobStart out of memory");
	}
	flags |= JOB_FIRST;
    }

    job->node = gn;
    job->tailCmds = NILLNODE;

    /*
     * Set the initial value of the flags for this job based on the global
     * ones and the node's attributes... Any flags supplied by the caller
     * are also added to the field.
     */
    job->flags = 0;
    if (Targ_Ignore (gn)) {
	job->flags |= JOB_IGNERR;
    }
    if (Targ_Silent (gn)) {
	job->flags |= JOB_SILENT;
    }
    job->flags |= flags;

    /*
     * Check the commands now so any attributes from .DEFAULT have a chance
     * to migrate to the node
     */
    if (!backwards || (job->flags & JOB_FIRST)) {
	cmdsOK = Job_CheckCommands(gn, Error);
    } else {
	cmdsOK = TRUE;
    }
    
    /*
     * If the -n flag wasn't given, we open up OUR (not the child's)
     * temporary file to stuff commands in it. The thing is rd/wr so we don't
     * need to reopen it to feed it to the shell. If the -n flag *was* given,
     * we just set the file to be stdout. Cute, huh?
     */
    if (!cmdsOK) {
	/*
	 * If commands weren't ok and -k wasn't passed, bail now.
	 */
	if (!keepgoing) {
	    DieHorribly();
	}

#if defined(unix)
	job->cmdFILE = stdout;
#elif defined(_WIN32)
	job->cmdOUT = GetStdHandle(STD_OUTPUT_HANDLE);
#endif /* defined(unix) */

	noExec = TRUE;
    } else if ((gn->type & OP_MAKE) || (!noExecute && !touchFlag)) {
#if defined(unix)
	job->cmdFILE = fopen (tfile, "w+");
	if (job->cmdFILE == NULL) {
	    Punt ("Could not open %s", tfile);
	}
	fcntl(fileno(job->cmdFILE), F_SETFD, 1);
#elif defined(_WIN32)
	char               *temp;
	static int          fileCount = 0;
	char               *filename;
	SECURITY_ATTRIBUTES sAttrs = {sizeof(SECURITY_ATTRIBUTES), NULL, TRUE};

	temp = getenv("TEMP");
	if (temp == NULL) {
	    temp = ".";
	}

	filename = (char *) malloc(SHELL_FILENAME_LENGTH);

	sprintf(filename, SHELL_FILENAME, temp, GetCurrentProcessId(),
		fileCount++);
	if ((job->cmdOUT = CreateFile(filename, GENERIC_READ | GENERIC_WRITE,
				      FILE_SHARE_READ, &sAttrs, CREATE_ALWAYS,
				      FILE_FLAG_DELETE_ON_CLOSE |
				      FILE_ATTRIBUTE_TEMPORARY, NULL))
	     == INVALID_HANDLE_VALUE) {
	    Punt("Couldn't open %s\n", filename);

	} else {
	    DWORD numWritten;
	    char *str = (char *) malloc(strlen("echo --- %s ---\r\n") +
					strlen(job->node->name));
	    /* tell the command shell to echo the name of the node it's
	     * making */
	    sprintf(str, "echo --- %s ---\r\n", job->node->name);
	    WriteFile(job->cmdOUT, str, strlen(str), &numWritten, NULL);
	    free(str);
	}
	
	free(filename);
#endif /* defined(unix) */
	/*
	 * Send the commands to the command file, flush all its buffers then
	 * rewind and remove the thing.
	 */
	noExec = FALSE;

	if (backwards) {
	    /*
	     * Be compatible: If this is the first time for this node,
	     * verify its commands are ok and open the commands list for
	     * sequential access by later invocations of JobStart.
	     * Once that is done, we take the next command off the list
	     * and print it to the command file. If the command was an
	     * ellipsis, note that there's nothing more to execute.
	     */
	    if ((job->flags&JOB_FIRST) && (Lst_Open(gn->commands) != SUCCESS)){
		cmdsOK = FALSE;
	    } else {
		LstNode	ln = Lst_Next (gn->commands);
		    
		if ((ln == NILLNODE) ||
		    JobPrintCommand ((char *)Lst_Datum (ln), job))
		{
		    noExec = TRUE;
		    Lst_Close (gn->commands);
		}
#if defined(unix)
		if (noExec && !(job->flags & JOB_FIRST)) {
		    /*
		     * If we're not going to execute anything, the job
		     * is done and we need to close down the various
		     * file descriptors we've opened for output, then
		     * call JobDoOutput to catch the final characters or
		     * send the file to the screen... Note that the i/o streams
		     * are only open if this isn't the first job.
		     * Note also that this could not be done in
		     * Job_CatchChildren b/c it wasn't clear if there were
		     * more commands to execute or not...
		     */
		    if (usePipes) {
#    ifdef RMT_WILL_WATCH
			Rmt_Ignore(job->inPipe);
#    else
			FD_CLR(job->inPipe, &outputs);
#    endif /* RMT_WILL_WATCH */
			if (job->outPipe != job->inPipe) {
			    (void)close (job->outPipe);
			}
			JobDoOutput (job, TRUE);
			(void)close (job->inPipe);
		    } else {
			(void)close (job->outFd);
			JobDoOutput (job, TRUE);
		    }
		}
#endif /* defined(unix) */
	    }
	} else {
	    /*
	     * We can do all the commands at once. hooray for sanity
	     */
	    numCommands = 0;
	    
	    Lst_ForEach (gn->commands, JobPrintCommand, (ClientData)job);
	    
	    /*
	     * If we didn't print out any commands to the shell script,
	     * there's not much point in executing the shell, is there?
	     */
	    if (numCommands == 0) {
		noExec = TRUE;
	    }
	}
    } else if (noExecute) {
	/*
	 * Not executing anything -- just print all the commands to stdout
	 * in one fell swoop. This will still set up job->tailCmds correctly.
	 */
#if defined(unix)
	if (lastNode != gn)
	{
	    printf (targFmt, gn->name);
	    lastNode = gn;
	}
#elif defined(_WIN32)
	printf(targFmt, gn->name);
#endif /* defined(unix) */

#if defined(unix)
	job->cmdFILE = stdout;
#elif defined(_WIN32)
	job->cmdOUT = GetStdHandle (STD_OUTPUT_HANDLE);
#endif /* defined (unix) */

	/*
	 * Only print the commands if they're ok, but don't die if they're
	 * not -- just let the user know they're bad and keep going. It
	 * doesn't do any harm in this case and may do some good.
	 */
	if (cmdsOK) {
	    Lst_ForEach(gn->commands, JobPrintCommand, (ClientData)job);
	}
	/*
	 * Don't execute the shell, thank you.
	 */
	noExec = TRUE;
    } else {
	/*
	 * Just touch the target and note that no shell should be executed.
	 * Set cmdFILE to stdout to make life easier. Check the commands, too,
	 * but don't die if they're no good -- it does no harm to keep working
	 * up the graph.
	 */
#if defined(unix)
	job->cmdFILE = stdout;
#elif defined(_WIN32)
	job->cmdOUT = GetStdHandle(STD_OUTPUT_HANDLE);
#endif /* defined(unix) */

    	Job_Touch (gn, job->flags&JOB_SILENT);
	noExec = TRUE;
    }

    /*
     * If we're not supposed to execute a shell, don't. 
     */
    if (noExec) {
	/*
	 * Unlink and close the command file if we opened one
	 */
#if defined(unix)
	if (job->cmdFILE != stdout) {
	    (void) unlink (tfile);
	    fclose(job->cmdFILE);
	} else {
	    fflush (stdout);
	}
#endif /* defined(unix) */

	/*
	 * We only want to work our way up the graph if we aren't here because
	 * the commands for the job were no good.
	 */
	if (cmdsOK) {
	    if (aborting == 0) {
		if (job->tailCmds != NILLNODE) {
		    Lst_ForEachFrom(job->node->commands, job->tailCmds,
				    JobSaveCommand,
				    (ClientData)job->node);
		}
		job->node->made = MADE;
		Make_Update(job->node);
	    }
	    free((Address)job);
	    return(JOB_FINISHED);
	} else {
	    free((Address)job);
	    return(JOB_ERROR);
	}
    } else {
#if defined (unix)
	fflush (job->cmdFILE);
	(void) unlink (tfile);
#endif /* defined(unix) */
    }

    /*
     * Set up the control arguments to the shell. This is based on the flags
     * set earlier for this job.
     */
#if defined(_WIN32)
    /*
     * CreateProcess doesn't take a normal argument vector but a simple
     * null-terminated string as the command line, so we allocate a maximum
     * of a 1k command line
     */
    argv = (char *) malloc(MAX_COMMAND_LINE_LENGTH) ;
#endif /* defined(_WIN32 */
    JobMakeArgv(job, argv);

#if defined(unix)
    /*
     * If we're using pipes to catch output, create the pipe by which we'll
     * get the shell's output. If we're using files, print out that we're
     * starting a job and then set up its temporary-file name. This is just
     * tfile with two extra digits tacked on -- jobno.
     */
    if (!JobInitOutput(job)) {
	/*
	 * If can't create the pipe, assume the system is just low
	 * on resources, or we're using too many descriptors, or
	 * what have you (i.e. it's a temporary condition), mark the
	 * job table as full and leave the job suspended. It'll
	 * get restarted when something else exits.
	 */
	jobFull = TRUE;
	if (DEBUG(JOB)) {
	    printf("Can't create pipe/output (%d), so suspending job until it can be created\n",
		   errno);
	}
	job->flags |= JOB_RESTART;
	(void)Lst_AtEnd(stoppedJobs, (ClientData)job);
	return(JOB_RUNNING);
    }
    if (!(gn->type & OP_NOEXPORT)) {
#    ifdef RMT_NO_EXEC
	local = !Rmt_Export(shellPath, argv, job);
#    else
	local = !Rmt_Begin (shellPath, argv, gn);
#    endif /* RMT_NO_EXEC */
	if (!local) {
	    job->flags |= JOB_REMOTE;
	}
    } else {
	local = TRUE;
    }
#elif defined(_WIN32)
    local = TRUE;
#endif /* defined(unix) */

    if (local && (
#ifdef sparc	/* KLUDGE */
	(gn->type & OP_M68020) ||
#endif /* sparc */

	((nLocal >= maxLocal) &&
	 !(job->flags & JOB_SPECIAL) &&
	 (!(gn->type & OP_NOEXPORT) || (maxLocal != 0)))))
    {
	/*
	 * The job can only be run locally, but we've hit the limit of
	 * local concurrency, so put the job on hold until some other job
	 * finishes. Note that the special jobs (.BEGIN, .INTERRUPT and .END)
	 * may be run locally even when the local limit has been reached
	 * (e.g. when maxLocal == 0), though they will be exported if at
	 * all possible. In addition, any target marked with .NOEXPORT will
	 * be run locally if maxLocal is 0.
	 */
	jobFull = TRUE;
	
	if (DEBUG(JOB)) {
	    printf("Can only run job locally.\n");
	}
	job->flags |= JOB_RESTART;
	(void)Lst_AtEnd(stoppedJobs, (ClientData)job);
    } else {
	if ((nLocal >= maxLocal) && local) {
	    /*
	     * If we're running this job locally as a special case (see above),
	     * at least say the table is full.
	     */
	    jobFull = TRUE;
	    if (DEBUG(JOB)) {
		printf("Local job queue is full.\n");
	    }
	}
	JobExec(job, argv);
	free(argv);
    }
    return(JOB_RUNNING);
}

#if defined(unix)
/*-
 *-----------------------------------------------------------------------
 * JobDoOutput  --
 *	This function is called at different times depending on
 *	whether the user has specified that output is to be collected
 *	via pipes or temporary files. In the former case, we are called
 *	whenever there is something to read on the pipe. We collect more
 *	output from the given job and store it in the job's outBuf. If
 *	this makes up a line, we print it tagged by the job's identifier,
 *	as necessary.
 *	If output has been collected in a temporary file, we open the
 *	file and read it line by line, transfering it to our own
 *	output channel until the file is empty. At which point we
 *	remove the temporary file.
 *	In both cases, however, we keep our figurative eye out for the
 *	'noPrint' line for the shell from which the output came. If
 *	we recognize a line, we don't print it. If the command is not
 *	alone on the line (the character after it is not \0 or \n), we
 *	do print whatever follows it.
 *
 * Results:
 *	None
 *
 * Arguments:
 *      register Job *job    : the job whose output needs printing
 *      Boolean       finish : TRUE if this is the last time we'll be called
 *                             for this job
 *
 * Side Effects:
 *	curPos may be shifted as may the contents of outBuf.
 *-----------------------------------------------------------------------
 */
void
JobDoOutput (register Job *job, Boolean finish)
{
    Boolean       gotNL = FALSE;  /* true if got a newline */
    register int  nr;	      	  /* number of bytes read */
    register int  i;	      	  /* auxiliary index into outBuf */
    register int  max;	      	  /* limit for i (end of current data) */

    FILE      	  *oFILE;         /* Stream pointer to shell's output file */
    int            nRead;         /* (Temporary) number of bytes read */
    char          inLine[132];

    
    if (usePipes) {
	/*
	 * Read as many bytes as will fit in the buffer.
	 */
end_loop:
	nRead = read (job->inPipe, &job->outBuf[job->curPos],
			 JOB_BUFSIZE - job->curPos);
	if (nRead < 0) {
	    if (DEBUG(JOB)) {
		perror("JobDoOutput(piperead)");
	    }
	    nr = 0;
	} else {
	    nr = nRead;
	}

	/*
	 * If we hit the end-of-file (the job is dead), we must flush its
	 * remaining output, so pretend we read a newline if there's any
	 * output remaining in the buffer.
	 * Also clear the 'finish' flag so we stop looping.
	 */
	if ((nr == 0) && (job->curPos != 0)) {
	    job->outBuf[job->curPos] = '\n';
	    nr = 1;
	    finish = FALSE;
	} else if (nr == 0) {
	    finish = FALSE;
	}
	
	/*
	 * Look for the last newline in the bytes we just got. If there is
	 * one, break out of the loop with 'i' as its index and gotNL set
	 * TRUE. 
	 */
	max = job->curPos + nr;
	for (i = job->curPos + nr - 1; i >= job->curPos; i--) {
	    if (job->outBuf[i] == '\n') {
		gotNL = TRUE;
		break;
	    } else if (job->outBuf[i] == '\0') {
		/*
		 * Why?
		 */
		job->outBuf[i] = ' ';
	    }
	}
	
	if (!gotNL) {
	    job->curPos += nr;
	    if (job->curPos == JOB_BUFSIZE) {
		/*
		 * If we've run out of buffer space, we have no choice
		 * but to print the stuff. sigh. 
		 */
		gotNL = TRUE;
		i = job->curPos;
	    }
	}
	if (gotNL) {
	    /*
	     * Need to send the output to the screen. Null terminate it
	     * first, overwriting the newline character if there was one.
	     * So long as the line isn't one we should filter (according
	     * to the shell description), we print the line, preceeded
	     * by a target banner if this target isn't the same as the
	     * one for which we last printed something.
	     * The rest of the data in the buffer are then shifted down
	     * to the start of the buffer and curPos is set accordingly. 
	     */
	    job->outBuf[i] = '\0';
	    if (i >= job->curPos) {
		register char	*cp, *ecp;

		cp = job->outBuf;
		if (commandShell->noPrint) {
		    ecp = Str_FindSubstring(job->outBuf,
					    commandShell->noPrint);
		    while (ecp != NULL) {
			if (cp != ecp) {
			    *ecp = '\0';
			    if (job->node != lastNode) {
				printf (targFmt, job->node->name);
				lastNode = job->node;
			    }
			    /*
			     * The only way there wouldn't be a newline after
			     * this line is if it were the last in the buffer.
			     * however, since the non-printable comes after it,
			     * there must be a newline, so we don't print one.
			     */
			    printf ("%s", cp);
			}
			cp = ecp + commandShell->noPLen;
			if (cp != &job->outBuf[i]) {
			    /*
			     * Still more to print, look again after skipping
			     * the whitespace following the non-printable
			     * command....
			     */
			    cp++;
			    while (*cp == ' ' || *cp == '\t' || *cp == '\n') {
				cp++;
			    }
			    ecp = Str_FindSubstring (cp,
						     commandShell->noPrint);
			} else {
			    break;
			}
		    }
		}

		/*
		 * There's still more in that thar buffer. This time, though,
		 * we know there's no newline at the end, so we add one of
		 * our own free will.
		 */
		if (*cp != '\0') {
		    if (job->node != lastNode) {
			printf (targFmt, job->node->name);
			lastNode = job->node;
		    }
		    printf ("%s\n", cp);
		}

		fflush (stdout);
	    }
	    if (i < max - 1) {
		bcopy (&job->outBuf[i + 1], /* shift the remaining */
		       job->outBuf,        /* characters down */
		       max - (i + 1));
		job->curPos = max - (i + 1);
		
	    } else {
		/*
		 * We have written everything out, so we just start over
		 * from the start of the buffer. No copying. No nothing.
		 */
		job->curPos = 0;
	    }
	}
	if (finish) {
	    /*
	     * If the finish flag is true, we must loop until we hit
	     * end-of-file on the pipe. This is guaranteed to happen eventually
	     * since the other end of the pipe is now closed (we closed it
	     * explicitly and the child has exited). When we do get an EOF,
	     * finish will be set FALSE and we'll fall through and out.
	     */
	    goto end_loop;
	}
    } else {
	/*
	 * We've been called to retrieve the output of the job from the
	 * temporary file where it's been squirreled away. This consists of
	 * opening the file, reading the output line by line, being sure not
	 * to print the noPrint line for the shell we used, then close and
	 * remove the temporary file. Very simple.
	 *
	 * Change to read in blocks and do FindSubString type things as for
	 * pipes? That would allow for "@echo -n..."
	 */
	oFILE = fopen (job->outFile, "r");
	if (oFILE != (FILE *) NULL) {
	    printf ("Results of making %s:\n", job->node->name);
	    while (fgets (inLine, sizeof(inLine), oFILE) != NULL) {
		register char	*cp, *ecp, *endp;

		cp = inLine;
		endp = inLine + strlen(inLine);
		if (endp[-1] == '\n') {
		    *--endp = '\0';
		}
		if (commandShell->noPrint) {
		    ecp = Str_FindSubstring(cp, commandShell->noPrint);
		    while (ecp != (char *)NULL) {
			if (cp != ecp) {
			    *ecp = '\0';
			    /*
			     * The only way there wouldn't be a newline after
			     * this line is if it were the last in the buffer.
			     * however, since the non-printable comes after it,
			     * there must be a newline, so we don't print one.
			     */
			    printf ("%s", cp);
			}
			cp = ecp + commandShell->noPLen;
			if (cp != endp) {
			    /*
			     * Still more to print, look again after skipping
			     * the whitespace following the non-printable
			     * command....
			     */
			    cp++;
			    while (*cp == ' ' || *cp == '\t' || *cp == '\n') {
				cp++;
			    }
			    ecp = Str_FindSubstring(cp, commandShell->noPrint);
			} else {
			    break;
			}
		    }
		}

		/*
		 * There's still more in that thar buffer. This time, though,
		 * we know there's no newline at the end, so we add one of
		 * our own free will.
		 */
		if (*cp != '\0') {
		    printf ("%s\n", cp);
		}
	    }
	    fclose (oFILE);
	    (void) unlink (job->outFile);
	}
    }
    fflush(stdout);
}

/*-
 *-----------------------------------------------------------------------
 * Job_CatchChildren --
 *	Handle the exit of a child. Called from Make_Make.
 *
 * Results:
 *	none.
 *
 * Arguments:
 *      Boolean block : TRUE if should block on the wait.
 *
 * Side Effects:
 *	The job descriptor is removed from the list of children.
 *
 * Notes:
 *	We do waits, blocking or not, according to the wisdom of our
 *	caller, until there are no more children to report. For each
 *	job, call JobFinish to finish things off. This will take care of
 *	putting jobs on the stoppedJobs queue.
 *
 *-----------------------------------------------------------------------
 */
void
Job_CatchChildren (Boolean block)
{
    int    	  pid;	    	/* pid of dead child */
    register Job *job;	    	/* job descriptor for dead child */
    LstNode       jnode;    	/* list element for finding job */
    WAIT_TYPE     status;   	/* Exit/termination status */

    /*
     * Don't even bother if we know there's no one around.
     */
    if (nLocal == 0) {
	return;
    }

    while ((pid = wait3(&status, (block ? 0 : WNOHANG)|WUNTRACED, NULL)) > 0)
    {
	if (DEBUG(JOB)) {
#ifdef Sprite
	    printf("Process %x exited or stopped.\n", pid);
#else
	    printf("Process %d exited or stopped.\n", pid);
#endif /* Sprite */
	}
	    

	jnode = Lst_Find (jobs, (ClientData)pid, JobCmpPid);

	if (jnode == NILLNODE) {
	    if (WIFSIGNALED(status) && (status.w_termsig == SIGCONT)) {
		jnode = Lst_Find(stoppedJobs, (ClientData)pid, JobCmpPid);
		if (jnode == NILLNODE) {
#ifdef Sprite
		    Error("Resumed child (%x) not in table", pid);
#else
		    Error("Resumed child (%d) not in table", pid);
#endif /* Sprite */
		    continue;
		}
		job = (Job *)Lst_Datum(jnode);
		(void)Lst_Remove(stoppedJobs, jnode);
	    } else {
#ifdef Sprite
		Error ("Child (%x) not in table?", pid);
#else
		Error ("Child (%d) not in table?", pid);
#endif /* Sprite */
		continue;
	    }
	} else {
	    job = (Job *) Lst_Datum (jnode);
	    (void)Lst_Remove (jobs, jnode);
	    nJobs -= 1;
	    if (jobFull && DEBUG(JOB)) {
		printf("Job queue is no longer full.\n");
	    }
	    jobFull = FALSE;
	
	    if (job->flags & JOB_REMOTE) {
		Rmt_Done ((int) job->rmtID);
	    } else {
		nLocal -= 1;
	    }
	}

	JobFinish (job, status);
    }
}
#elif defined(_WIN32)

/***********************************************************************
 *				JobWaitProcess
 ***********************************************************************
 * SYNOPSIS:	    Waits for one of the processes passed to it.
 * CALLED BY:	    Job_NTCatchChildren
 * RETURN:	    1 if a process finished (in which case retStat
 *                  contains the return status of the process), 0 if
 *                  no process finished but more may be waiting, and
 *                  -1 if no process finished and no more are waiting.
 * SIDE EFFECTS:    Changes the HandleList passed in as argument 2.
 *
 * STRATEGY:	    Call WaitForMultipleObjects to see if any HANDLE in
 *                  procs is done.  If one is, set its position in
 *                  procs->hArray to INVALID_HANDLE_VALUE and return the value
 *                  in finishedProc.  If no processes are done, return 0 
 *                  (if not blocking) else if all HANDLEs in the array
 *                  are INVALID_HANDLE_VALUEs, then return -1.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/13/96   	Initial Revision
 *
 ***********************************************************************/
static int
JobWaitProcess (WAIT_TYPE     *retStatus,
		HandleList    *procs,
		HANDLE        *finishedProc,
		unsigned long  block)
{
    unsigned long waitStat;

    if (procs->numFilled > 0) {
	waitStat  = WaitForMultipleObjects(procs->numFilled,
					   procs->hArray,
					   FALSE, block);
    } else {
	return -1;
    }

    switch (waitStat) {
        case WAIT_TIMEOUT:
	    return 0;

        case WAIT_FAILED:
	    return -1;

        default:            /* WAIT_OBJECT_0 */
	    *finishedProc = procs->hArray[waitStat - WAIT_OBJECT_0];
	    if (GetExitCodeProcess(*finishedProc, retStatus)) {
		if (*retStatus != STILL_ACTIVE) {
		    JobRemoveHandle(*finishedProc, procs);
		    return (1);
		} else {
		    return (0);
		}
	    } else { /* failure */
		ErrorMessage("pmake");
		ExitProcess(2);
	    }
	    break;
    }

    return -1;
}	/* End of JobWaitProcess.	*/


/***********************************************************************
 *				Job_NTCatchChildren
 ***********************************************************************
 * SYNOPSIS:	    Job_CatchChildren for NT
 * CALLED BY:	    Make_Make
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The Job descriptor is removed from the list of children
 *
 * STRATEGY:
 *              We do waits, blocking or not, according to the wisdom of
 *      our caller, until there are no more children to report. For each
 *	job, call JobNTFinish to finish things off. This will take care of
 *	putting jobs on the stoppedJobs queue.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/08/96   	Initial Revision
 *
 ***********************************************************************/
void
Job_NTCatchChildren (unsigned long block)
{
    HANDLE    	  child;    	/* handle of dead child */
    WAIT_TYPE     status;   	/* Exit/termination status */
    
    /*
     * Don't even bother if we know there's no one around.
     */
    if ((nLocal == 0) || (children->numFilled == 0)) {
	return;
    }
    /*
     * As long as there are more 'children' waiting.
     */
    while (JobWaitProcess(&status, children, &child, block) > 0) {
	LstNode jnode = Lst_Find(jobs, (ClientData) child, JobCmpHandle);
	register Job *job;
	
	/* jnode not in Jobs Lst? */
	if (jnode == NILLNODE) {
	    jnode = Lst_Find(stoppedJobs, (ClientData) child,
			     JobCmpHandle);
	    
	    /* jnode not in stoppedJobs Lst either? */
	    if (jnode == NILLNODE) {
		Error ("Child (%x) not in table\n", (unsigned) child);
		ExitProcess(2);
	    } else {
		job = (Job *) Lst_Datum(jnode);
		Lst_Remove(stoppedJobs, jnode);
	    }
	    
	} else {
	    job = (Job *) Lst_Datum(jnode);
	    Lst_Remove (jobs, jnode);
	    nJobs  -= 1;
	    if (jobFull && DEBUG(JOB)) {
		printf("Job queue is no longer full.\n");
	    }
	    jobFull = FALSE;
	}
	
	JobNTFinish(job, status);
    }
}	/* End of Job_NTCatchChildren.	*/

/***********************************************************************
 *				JobCmpHandle
 ***********************************************************************
 * SYNOPSIS:	    Compares Two handles
 * CALLED BY:	    Lst_Find
 * RETURN:	    0 if the handles are equal
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Simply subtract one from the other
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/08/96   	Initial Revision
 *
 ***********************************************************************/
static int
JobCmpHandle (Job *job, HANDLE handle)
{
    return (!(job->pid.hProcess == handle));
}	/* End of JobCmpHandle.	*/
#endif /* defined(unix) */

#if defined(unix)

/*-
 *-----------------------------------------------------------------------
 * Job_CatchOutput --
 *	Catch the output from our children, if we're using
 *	pipes do so. Otherwise just block time until we get a
 *	signal (most likely a SIGCHLD) since there's no point in
 *	just spinning when there's nothing to do and the reaping
 *	of a child can wait for a while. 
 *
 * Results:
 *	None 
 *
 * Side Effects:
 *	Output is read from pipes if we're piping.
 * -----------------------------------------------------------------------
 */
void
Job_CatchOutput (void)
{
    int	    	  	  pnJobs;   	/* Previous nJobs */

    fflush(stdout);
#if defined(RMT_WILL_WATCH)
    pnJobs = nJobs;

    /*
     * It is possible for us to be called with nJobs equal to 0. This happens
     * if all the jobs finish and a job that is stopped cannot be run
     * locally (eg if maxLocal is 0) and cannot be exported. The job will
     * be placed back on the stoppedJobs queue, Job_Empty() will return false,
     * Make_Run will call us again when there's nothing for which to wait.
     * nJobs never changes, so we loop forever. Hence the check. It could
     * be argued that we should sleep for a bit so as not to swamp the
     * exportation system with requests. Perhaps we should.
     *
     * NOTE: IT IS THE RESPONSIBILITY OF Rmt_Wait TO CALL Job_CatchChildren
     * IN A TIMELY FASHION TO CATCH ANY LOCALLY RUNNING JOBS THAT EXIT.
     * It may use the variable nLocal to determine if it needs to call
     * Job_CatchChildren (if nLocal is 0, there's nothing for which to
     * wait...)
     */
    while (nJobs != 0 && pnJobs == nJobs) {
	Rmt_Wait();
    }
#else
    if (usePipes) {
	readfds = outputs;
	timeout.tv_sec = SEL_SEC;
	timeout.tv_usec = SEL_USEC;

	if ((nfds = select (FD_SETSIZE, &readfds, NULL, NULL, &timeout)) < 0)
	{
	    return;
	} else {
	    if (Lst_Open (jobs) == FAILURE) {
		Punt ("Cannot open job table");
	    }
	    while (nfds && (ln = Lst_Next (jobs)) != NILLNODE) {
		job = (Job *) Lst_Datum (ln);

		if (FD_ISSET(job->inPipe, &readfds)) {
		    JobDoOutput (job, FALSE);
		    nfds -= 1;
		}
	    }
	    Lst_Close (jobs);
	}
    }
#endif /* defined(RMT_WILL_WATCH) */
}
#elif defined(_WIN32)

/***********************************************************************
 *				Job_NTCatchOutput
 ***********************************************************************
 * SYNOPSIS:	    Catch the output of job under NT
 * CALLED BY:	    
 * RETURN:	    nothing
 * SIDE EFFECTS:    Output is read from pipes if we're piping.
 *
 * STRATEGY:	    outputs.hArray is an array of HANDLEs.  We are currently
 *                  only supporting one job and since this handle should always
 *                  be put in the first slot of the array, we'll just always
 *                  check the first slot with a PeekNamedPipe (even though
 *                  we're using an anonymous pipe here, PeekNamedPipe is the
 *                  proper function -- blame WIN32).
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/09/96   	Initial Revision
 *
 ***********************************************************************/
void
Job_NTCatchOutput (void)
{
    /*
     * since we aren't using pipes to catch the output of jobs anymore
     * we can't do any filtering or anything on them.
     */
#if 0
    if (Lst_Open(jobs) != FAILURE) {
	Job           *job;
	LstNode        ln = Lst_Next(jobs);
	unsigned long  num_avail;

	while(ln != NILLNODE) {
	    job = (Job *) Lst_Datum(ln);

	    /* just see if there's anything to read, don't actually
	     * read from it */
	    if ((job != (Job *) NIL) &&
		PeekNamedPipe(job->inPipe, NULL, 0, NULL, &num_avail, NULL)) {
		if (num_avail != 0) {
		    JobDoOutput (job, FALSE);
		}
	    } else if (DEBUG(JOB)) {
		Error("Nothing to read from %x 's pipe\n",
		      job->pid.dwProcessId);
	    }

	    if (Lst_IsAtEnd(jobs)) {
		break;
	    }

	    ln = Lst_Next(jobs);
	}

	Lst_Close(jobs);
    } else {
	Error ("Couldn't open job table\n");
    }
#endif
}	/* End of Job_NTCatchOutput.	*/
#endif /* defined(unix) */

/*-
 *-----------------------------------------------------------------------
 * Job_Make --
 *	Start the creation of a target. Basically a front-end for
 *	JobStart used by the Make module.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Another job is started.
 *
 *-----------------------------------------------------------------------
 */
void
Job_Make (GNode *gn)
{
    (void)JobStart (gn, 0, (Job *)NULL);
}

/*-
 *-----------------------------------------------------------------------
 * Job_Init --
 *	Initialize the process module
 *
 * Results:
 *	none
 *
 * Arguments:
 *      int maxproc  : The greatest number of jobs which may be running at
 *                     one time.
 *      int maxlocal : The greatest number of local jobs which may be
 *                     running at once.
 *
 * Side Effects:
 *	lists and counters are initialized
 *-----------------------------------------------------------------------
 */
void
Job_Init (int maxproc, int maxlocal)
{
    GNode         *begin;     /* node for commands to do at the very start */
    char 	  *separator = ":";

#if defined(unix)
#    ifdef Sprite
    sprintf (tfile, "/tmp/make%05x", getpid());
#    else
    sprintf (tfile, "/tmp/make%05d", getpid());
#    endif /* Sprite */
#endif /* defined(unix) */

#if defined(_WIN32)
    {
	/*
	 * initialize the Data structure that keeps track of process handles to
	 * be passed to JobWaitProcess
	 */
	int i;

	children    = (HandleList *) malloc(sizeof(HandleList));
	for (i = 0; i < HANDLE_LIST_MAX; i++) {
	    children->hArray[i] = INVALID_HANDLE_VALUE;
	}
	children -> numFilled = 0;
    }
#endif /* defined(_WIN32) */

    jobs        = Lst_Init(FALSE);
    stoppedJobs = Lst_Init(FALSE);
    maxJobs     = maxproc;
    maxLocal    = maxlocal;
    nJobs       = 0;
    nLocal      = 0;
    jobFull     = FALSE;

    aborting    = 0;
    errors      = 0;

#if defined(unix)
    lastNode    = NILGNODE;
#endif /* defined(unix) */

    bannerPrefix = getenv("PMAKE_BANNER_PREFIX");

    if (bannerPrefix == NULL) {
	separator = bannerPrefix = "";
    } else {
	bannerPrefix = Str_New(bannerPrefix);
    }
    
    if (maxJobs == 1) {
	/*
	 * If only one job can run at a time, there's no need for a banner,
	 * now is there?
	 */
	targFmt = "";
    } else {
	targFmt = (char *)malloc(strlen(TARG_FMT_PROTO) +
				 strlen(bannerPrefix));
	sprintf(targFmt, TARG_FMT_PROTO, bannerPrefix, separator);
    }
    
    if (shellPath == (char *) NULL) {
	/*
	 * The user didn't specify a shell to use, so we are using the
	 * default one... Both the absolute path and the last component
	 * must be set. The last component is taken from the 'name' field
	 * of the default shell description pointed-to by commandShell.
	 * All default shells are located in DEFSHELLDIR.
	 */
	shellName = commandShell->name;
	shellPath = Str_Concat (DEFSHELLDIR, shellName, STR_ADDSLASH);
    }

    if (commandShell->exit == NULL) {
	commandShell->exit = "";
    }
    if (commandShell->echo == NULL) {
	commandShell->echo = "";
    }

    /*
     * Catch the four signals that POSIX specifies if they aren't ignored.
     * JobPassSig will take care of calling JobInterrupt if appropriate.
     */
#if defined(unix)
    if (signal (SIGINT, SIG_IGN) != SIG_IGN) {
	signal (SIGINT, JobPassSig);
    }
    if (signal (SIGHUP, SIG_IGN) != SIG_IGN) {
	signal (SIGHUP, JobPassSig);
    }
    if (signal (SIGQUIT, SIG_IGN) != SIG_IGN) {
	signal (SIGQUIT, JobPassSig);
    }
    if (signal (SIGTERM, SIG_IGN) != SIG_IGN) {
	signal (SIGTERM, JobPassSig);
    }
    /*
     * There are additional signals that need to be caught and passed if
     * either the export system wants to be told directly of signals or if
     * we're giving each job its own process group (since then it won't get
     * signals from the terminal driver as we own the terminal)
     */
#    if defined(RMT_WANTS_SIGNALS) || defined(USE_PGRP)
    if (signal (SIGTSTP, SIG_IGN) != SIG_IGN) {
	signal (SIGTSTP, JobPassSig);
    }
    if (signal (SIGTTOU, SIG_IGN) != SIG_IGN) {
	signal (SIGTTOU, JobPassSig);
    }
    if (signal (SIGTTIN, SIG_IGN) != SIG_IGN) {
	signal (SIGTTIN, JobPassSig);
    }
    if (signal (SIGWINCH, SIG_IGN) != SIG_IGN) {
	signal (SIGWINCH, JobPassSig);
    }
#    endif /* defined(RMT_WANTS_SIGNALS) || defined(USE_PGRP) */
#elif defined(_WIN32)
    SetConsoleCtrlHandler(JobNTInterrupt, TRUE);
#endif /* defined(unix) */  
  
    begin = Targ_FindNode (".BEGIN", TARG_NOCREATE);

    if (begin != NILGNODE) {
	JobStart (begin, JOB_SPECIAL, NULL);
	while (nJobs) {

#if defined(unix)
	    Job_CatchOutput();
#    if !(defined (RMT_WILL_WATCH))
	    Job_CatchChildren (!usePipes);
#    endif /* !(defined (RMT_WILL_WATCH)) */
#elif defined(_WIN32)
	    Job_NTCatchOutput();
	    Job_NTCatchChildren (JOB_WAIT_TIMEOUT);
#endif /* defined(unix) */

	}
    }
    postCommands = Targ_FindNode (".END", TARG_CREATE);
}

/*-
 *-----------------------------------------------------------------------
 * Job_Full --
 *	See if the job table is full. It is considered full if it is OR
 *	if we are in the process of aborting OR if we have
 *	reached/exceeded our local quota. This prevents any more jobs
 *	from starting up.
 *
 * Results:
 *	TRUE if the job table is full, FALSE otherwise
 * Side Effects:
 *	None.
 *-----------------------------------------------------------------------
 */
Boolean
Job_Full (void)
{
    return (aborting || jobFull);
}

/*-
 *-----------------------------------------------------------------------
 * Job_Empty --
 *	See if the job table is empty.  Because the local concurrency may
 *	be set to 0, it is possible for the job table to become empty,
 *	while the list of stoppedJobs remains non-empty. In such a case,
 *	we want to restart as many jobs as we can.
 *
 * Results:
 *	TRUE if it is. FALSE if it ain't.
 *
 * Side Effects:
 *	None.
 *
 * -----------------------------------------------------------------------
 */
Boolean
Job_Empty (void)
{
    if (nJobs == 0) {
	if (!Lst_IsEmpty(stoppedJobs) && !aborting) {
	    /*
	     * The job table is obviously not full if it has no jobs in
	     * it...Try and restart the stopped jobs.
	     */
	    jobFull = FALSE;
#if defined(unix)
	    while (!jobFull && !Lst_IsEmpty(stoppedJobs)) {
		JobRestart((Job *)Lst_DeQueue(stoppedJobs));
	    }
#endif defined(unix)
	    return(FALSE);
	} else {
	    return(TRUE);
	}
    } else {
	return(FALSE);
    }
}

/*-
 *-----------------------------------------------------------------------
 * JobMatchShell --
 *	Find a matching shell in 'shells' given its final component.
 *
 * Results:
 *	A pointer to the Shell structure.
 *
 * Arguments:
 *      char *name : Final component of shell path
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
static Shell *
JobMatchShell (char *name)
{
    register Shell *sh;	      /* Pointer into shells table */
    Shell	   *match;    /* Longest-matching shell */
    register char *cp1,
		  *cp2;
    char	  *eoname;

    eoname = name + strlen (name);

    match = (Shell *) NULL;

    for (sh = shells; sh->name != NULL; sh++) {
	for (cp1 = eoname - strlen (sh->name), cp2 = sh->name;
	     *cp1 != '\0' && *cp1 == *cp2;
	     cp1++, cp2++) {
		 continue;
	}
	if (*cp1 != *cp2) {
	    continue;
	} else if (match == (Shell *) NULL ||
		   strlen (match->name) < strlen (sh->name)) {
		       match = sh;
	}
    }
    return (match == (Shell *) NULL ? sh : match);
}

/*-
 *-----------------------------------------------------------------------
 * Job_ParseShell --
 *	Parse a shell specification and set up commandShell, shellPath
 *	and shellName appropriately.
 *
 * Results:
 *	FAILURE if the specification was incorrect.
 *
 * Side Effects:
 *	commandShell points to a Shell structure (either predefined or
 *	created from the shell spec), shellPath is the full path of the
 *	shell described by commandShell, while shellName is just the
 *	final component of shellPath.
 *
 * Arguments:
 *      char *line : The shell spec
 *
 * Notes:
 *	A shell specification consists of a .SHELL target, with dependency
 *	operator, followed by a series of blank-separated words. Double
 *	quotes can be used to use blanks in words. A backslash escapes
 *	anything (most notably a double-quote and a space) and
 *	provides the functionality it does in C. Each word consists of
 *	keyword and value separated by an equal sign. There should be no
 *	unnecessary spaces in the word. The keywords are as follows:
 *	    name  	    Name of shell.
 *	    path  	    Location of shell. Overrides "name" if given
 *	    quiet 	    Command to turn off echoing.
 *	    echo  	    Command to turn echoing on
 *	    filter	    Result of turning off echoing that shouldn't be
 *	    	  	    printed.
 *	    echoFlag	    Flag to turn echoing on at the start
 *	    errFlag	    Flag to turn error checking on at the start
 *	    hasErrCtl	    True if shell has error checking control
 *	    check 	    Command to turn on error checking if hasErrCtl
 *	    	  	    is TRUE or template of command to echo a command
 *	    	  	    for which error checking is off if hasErrCtl is
 *	    	  	    FALSE.
 *	    ignore	    Command to turn off error checking if hasErrCtl
 *	    	  	    is TRUE or template of command to execute a
 *	    	  	    command so as to ignore any errors it returns if
 *	    	  	    hasErrCtl is FALSE.
 *
 *-----------------------------------------------------------------------
 */
ReturnStatus
Job_ParseShell (char *line)
{
    char    	  **words;
    int	    	  wordCount;
    register char **argv;
    register int  argc;
    char    	  *path;
    Shell   	  newShell;
    Boolean 	  fullSpec = FALSE;

    while (isspace (*line)) {
	line++;
    }
    words = Str_BreakString (line, " \t", "\n", TRUE, &wordCount);

    bzero ((Address)&newShell, sizeof(newShell));
    
    /*
     * Parse the specification by keyword
     */
    for (path = (char *)NULL, argc = wordCount - 1, argv = words + 1;
	 argc != 0;
	 argc--, argv++) {
	     if (strncmp (*argv, "path=", 5) == 0) {
		 path = &argv[0][5];
	     } else if (strncmp (*argv, "name=", 5) == 0) {
		 newShell.name = &argv[0][5];
	     } else {
		 if (strncmp (*argv, "quiet=", 6) == 0) {
		     newShell.echoOff = &argv[0][6];
		 } else if (strncmp (*argv, "echo=", 5) == 0) {
		     newShell.echoOn = &argv[0][5];
		 } else if (strncmp (*argv, "filter=", 7) == 0) {
		     newShell.noPrint = &argv[0][7];
		     newShell.noPLen = strlen(newShell.noPrint);
		 } else if (strncmp (*argv, "echoFlag=", 9) == 0) {
		     newShell.echo = &argv[0][9];
		 } else if (strncmp (*argv, "errFlag=", 8) == 0) {
		     newShell.exit = &argv[0][8];
		 } else if (strncmp (*argv, "hasErrCtl=", 10) == 0) {
		     char c = argv[0][10];
		     newShell.hasErrCtl = !((c != 'Y') && (c != 'y') &&
					    (c != 'T') && (c != 't'));
		 } else if (strncmp (*argv, "check=", 6) == 0) {
		     newShell.errCheck = &argv[0][6];
		 } else if (strncmp (*argv, "ignore=", 7) == 0) {
		     newShell.ignErr = &argv[0][7];
		 } else {
		     Parse_Error (PARSE_FATAL, "Unknown keyword \"%s\"",
				  *argv);
		     Str_FreeVec (wordCount, words);
		     return (FAILURE);
		 }
		 fullSpec = TRUE;
	     }
    }

    if (path == (char *)NULL) {
	/*
	 * If no path was given, the user wants one of the pre-defined shells,
	 * yes? So we find the one s/he wants with the help of JobMatchShell
	 * and set things up the right way. shellPath will be set up by
	 * Job_Init.
	 */
	if (newShell.name == (char *)NULL) {
	    Parse_Error (PARSE_FATAL, "Neither path nor name specified");
	    Str_FreeVec (wordCount, words);
	    return (FAILURE);
	} else {
	    commandShell = JobMatchShell (newShell.name);
	    shellName = newShell.name;
	}
    } else {
	/*
	 * The user provided a path. If s/he gave nothing else (fullSpec is
	 * FALSE), try and find a matching shell in the ones we know of.
	 * Else we just take the specification at its word and copy it
	 * to a new location. In either case, we need to record the
	 * path the user gave for the shell.
	 */
	shellPath = path;
	path = (char*) rindex (path, '/');
	if (path == (char *)NULL) {
	    path = shellPath;
	} else {
	    path += 1;
	}
	if (newShell.name != (char *)NULL) {
	    shellName = newShell.name;
	} else {
	    shellName = path;
	}
	if (!fullSpec) {
	    commandShell = JobMatchShell (shellName);
	} else {
	    commandShell = (Shell *) malloc(sizeof(Shell));
	    *commandShell = newShell;
	}
    }

    if (commandShell->echoOn && commandShell->echoOff) {
	commandShell->hasEchoCtl = TRUE;
    }
    
    if (!commandShell->hasErrCtl) {
	if (commandShell->errCheck == (char *)NULL) {
	    commandShell->errCheck = "";
	}
	if (commandShell->ignErr == (char *)NULL) {
	    commandShell->ignErr = "%s\n";
	}
    }
    
    /*
     * Do not free up the words themselves, since they might be in use by the
     * shell specification...
     */
    free (words);
    return SUCCESS;
}

#if defined(unix)
/*-
 *-----------------------------------------------------------------------
 * JobInterrupt --
 *	Handle the receipt of an interrupt.
 *
 * Results:
 *	None
 *
 * Arguments:
 *      int runINTERRUPT : Non-zero if commands for the .INTERRUPT target
 *                         should be executed
 *
 * Side Effects:
 *	All children are killed. Another job will be started if the
 *	.INTERRUPT target was given.
 *-----------------------------------------------------------------------
 */
static void
JobInterrupt (int runINTERRUPT)
{
    LstNode 	  ln;		/* element in job table */
    Job           *job;	    	/* job descriptor in that element */
    GNode         *interrupt;	/* the node describing the .INTERRUPT target */
    
    aborting = ABORT_INTERRUPT;

    (void)Lst_Open (jobs);
    while ((ln = Lst_Next (jobs)) != NILLNODE) {
	job = (Job *) Lst_Datum (ln);

	if (!Targ_Precious (job->node)) {
	    char  	*file = ((job->node->path == NULL) ?
				 job->node->name :
				 job->node->path);
	    if (unlink (file) == 0) {
		Error ("*** %s removed", file);
	    }
	}
#if defined(RMT_WANTS_SIGNALS)
	if (job->flags & JOB_REMOTE) {
	    /*
	     * If job is remote, let the Rmt module do the killing.
	     */
	    if (!Rmt_Signal(job, SIGINT)) {
		/*
		 * If couldn't kill the thing, finish it out now with an
		 * error code, since no exit report will come in likely.
		 */
		union wait status;

		status.w_status = 0;
		status.w_retcode = 1;
		JobFinish(job, status);
	    }
	} else if (job->pid) {
	    KILL(job->pid, SIGINT);
	}
#else
	if (job->pid) {
	    KILL(job->pid, SIGINT);
	}
#endif /* defined(RMT_WANTS_SIGNALS) */
    }
    Lst_Close (jobs);

    if (runINTERRUPT && !touchFlag) {
	interrupt = Targ_FindNode (".INTERRUPT", TARG_NOCREATE);
	if (interrupt != NILGNODE) {
	    ignoreErrors = FALSE;

	    JobStart (interrupt, JOB_IGNDOTS, NULL);
	    while (nJobs) {
		Job_CatchOutput();
#ifndef RMT_WILL_WATCH
		Job_CatchChildren (!usePipes);
#endif /* RMT_WILL_WATCH */
	    }
	}
    }

    (void) unlink (tfile);
    exit (0);
}
#elif defined(_WIN32)

/***********************************************************************
 *				JobNTTermJob
 ***********************************************************************
 * SYNOPSIS:	    Calls GenerateConsoleCtrlEvent on each job in a lst
 * CALLED BY:	    JobNTInterrupt
 * RETURN:	    0 so Lst_ForEach will continue
 * SIDE EFFECTS:    Kills a bunch of processes
 *
 * STRATEGY:	    Simply call GenerateConsoleCtrlEvent with the signo
 *                  and using the job's pid.hProcessid as the group
 *                  number.  Since CreateProcess was called with the
 *                  CREATE_NEW_PROCESS_GROUP flag, each job started
 *                  gets its own group.
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *		8/15/96   	Initial Revision
 *
 ***********************************************************************/
static int
JobNTTermJob (Job *job, ClientData signo)
{
    (void) TerminateProcess(job->pid.hProcess, (DWORD) signo + 1);
    if (DEBUG(JOB)) {
	printf("Terminating job id %x.\n", job->pid.dwProcessId);
    }

    if (!Targ_Precious (job->node)) {
	char *file = ((job->node->path == NULL) ? job->node->name :
		                                  job->node->path);
	if (DeleteFile(file)) {
	    fprintf(stderr, "*** %s removed\n", file);
	} else {
	    ErrorMessage("pmake: %s", file);
	}
    }

    (void) CloseHandle(job->pid.hProcess);
    (void) CloseHandle(job->pid.hThread);

    return 0;
}	/* End of JobNTTermJob.	*/


/***********************************************************************
 *				JobNTInterrupt
 ***********************************************************************
 * SYNOPSIS:	    SIGINT Handler for Windows NT
 * CALLED BY:	    Whenever ^C is pressed.
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Stops all jobs spawned by pmake, removes all temp
 *                  files (unimplemented), and exits with error status.
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	8/15/96   	Initial Revision
 *
 ***********************************************************************/
static BOOL WINAPI
JobNTInterrupt (DWORD signo)
{
    if (DEBUG(JOB)) {
	printf("JobNTInterrupt called.\n");
    }

    if(!GenerateConsoleCtrlEvent(CTRL_C_EVENT, 0) &&
       !GenerateConsoleCtrlEvent(CTRL_BREAK_EVENT, 0)) {
	ErrorMessage("pmake");
    }

    Lst_ForEach(jobs, JobNTTermJob, (ClientData) CTRL_C_EVENT);
    ExitProcess(signo + 1); /* Return signal value as error status (What
			     * the hell).  Add 1 to make sure that we're
			     * always returning an error.*/

    return FALSE;
}	/* End of JobNTInterrupt.	*/
#endif /* defined(unix) */

/*
 *-----------------------------------------------------------------------
 * Job_End --
 *	Do final processing such as the running of the commands
 *	attached to the .END target. 
 *
 * Results:
 *	Number of errors reported.
 *
 * Side Effects:
 *	The process' temporary file (tfile) is removed if it still
 *	existed.
 *-----------------------------------------------------------------------
 */
int
Job_End (void)
{
    if (postCommands != NILGNODE && !Lst_IsEmpty (postCommands->commands)) {
	if (errors) {
	    Error ("Errors reported so .END ignored");
	} else {
	    JobStart (postCommands, JOB_SPECIAL | JOB_IGNDOTS, NULL);

	    while (nJobs) {
#if defined(unix)
		Job_CatchOutput();
#    ifndef RMT_WILL_WATCH
		Job_CatchChildren (!usePipes);
#    endif /* RMT_WILL_WATCH */
#elif defined(_WIN32)
		Job_NTCatchOutput();
		Job_NTCatchChildren (JOB_WAIT_TIMEOUT);
#endif /* defined(unix) */
	    }
	}
    }
#if defined(unix)
    (void) unlink (tfile);
#endif /* defined(unix) */

    return(errors);
}

/*-
 *-----------------------------------------------------------------------
 * Job_Wait --
 *	Waits for all running jobs to finish and returns. Sets 'aborting'
 *	to ABORT_WAIT to prevent other jobs from starting.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Currently running jobs finish.
 *
 *-----------------------------------------------------------------------
 */
void
Job_Wait(void)
{
    aborting = ABORT_WAIT;
    while (nJobs != 0) {

#if defined(unix)
	Job_CatchOutput();
#    ifndef RMT_WILL_WATCH
	Job_CatchChildren(!usePipes);
#    endif /* RMT_WILL_WATCH */
#elif defined(_WIN32)
	Job_NTCatchOutput();
	Job_NTCatchChildren(JOB_WAIT_TIMEOUT);
#endif /* defined(unix) */

    }
    aborting = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Job_AbortAll --
 *	Abort all currently running jobs without handling output or anything.
 *	This function is to be called only in the event of a major
 *	error. Most definitely NOT to be called from JobInterrupt.
 *
 * Results:
 *	None
 *
 * Side Effects:
 *	All children are killed, not just the firstborn
 *-----------------------------------------------------------------------
 */
void
Job_AbortAll (void)
{
    LstNode           	ln;		/* element in job table */
    Job            	*job;	/* the job descriptor in that element */
#if defined(unix)
    int     	  	foo;
#endif /* defined(unix) */
    aborting = ABORT_ERROR;
    
    if (nJobs) {

	(void)Lst_Open (jobs);
	while ((ln = Lst_Next (jobs)) != NILLNODE) {
	    job = (Job *) Lst_Datum (ln);

	    /*
	     * kill the child process with increasingly drastic signals to make
	     * darn sure it's dead. 
	     */
#if defined(unix)
#    ifdef RMT_WANTS_SIGNALS
	    if (job->flags & JOB_REMOTE) {
		Rmt_Signal(job, SIGINT);
		Rmt_Signal(job, SIGKILL);
	    } else {
		KILL(job->pid, SIGINT);
		KILL(job->pid, SIGKILL);
	    }
#    else
	    KILL(job->pid, SIGINT);
	    KILL(job->pid, SIGKILL);
#    endif /* RMT_WANTS_SIGNALS */
#elif defined(_WIN32)
	    (void) TerminateProcess(job->pid.hProcess, 0);
	    (void) CloseHandle(job->pid.hProcess);
	    (void) CloseHandle(job->pid.hThread);

	    if (!GenerateConsoleCtrlEvent(CTRL_C_EVENT, 0)) {
		printf("Warning: couldn't generate ^C event\n.");
	    }
#endif /* defined(unix) */
	}
    }
#if defined(unix)
    /*
     * Catch as many children as want to report in at first, then give up
     */
    while (wait3(&foo, WNOHANG, NULL) > 0) {
	;
    }
    (void) unlink (tfile);
#endif /* defined(unix) */
}
