/*-
 * job.h --
 *	Definitions pertaining to the running of jobs in parallel mode.
 *	Exported from job.c for the use of remote-execution modules.
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
 *	"$Id: job.h,v 1.3 96/06/24 15:05:42 tbradley Exp $ SPRITE (Berkeley)"
 */
#ifndef _JOB_H_
#define _JOB_H_

#include "pmjob.h"

/*
 * The SEL_ constants determine the maximum amount of time spent in select
 * before coming out to see if a child has finished. SEL_SEC is the number of
 * seconds and SEL_USEC is the number of micro-seconds 
 */
#define SEL_SEC		0
#define SEL_USEC	500000


/*-
 * Shell Specifications:
 * Each shell type has associated with it the following information:
 *	1) The string which must match the last character of the shell name
 *	   for the shell to be considered of this type. The longest match
 *	   wins.
 *	2) A command to issue to turn off echoing of command lines
 *	3) A command to issue to turn echoing back on again
 *	4) What the shell prints, and its length, when given the echo-off
 *	   command. This line will not be printed when received from the shell
 *	5) A boolean to tell if the shell has the ability to control
 *	   error checking for individual commands.
 *	6) The string to turn this checking on.
 *	7) The string to turn it off.
 *	8) The command-flag to give to cause the shell to start echoing
 *	   commands right away.
 *	9) The command-flag to cause the shell to Lib_Exit when an error is
 *	   detected in one of the commands.
 *
 * Some special stuff goes on if a shell doesn't have error control. In such
 * a case, errCheck becomes a printf template for echoing the command,
 * should echoing be on and ignErr becomes another printf template for
 * executing the command while ignoring the return status. If either of these
 * strings is empty when hasErrCtl is FALSE, the command will be executed
 * anyway as is and if it causes an error, so be it.
 */
typedef struct Shell {
    char	  *name;	/* the name of the shell. For Bourne and C
				 * shells, this is used only to find the
				 * shell description when used as the single
				 * source of a .SHELL target. For user-defined
				 * shells, this is the full path of the shell.
				 */
    Boolean 	  hasEchoCtl;	/* True if both echoOff and echoOn defined */
    char          *echoOff;	/* command to turn off echo */
    char          *echoOn;	/* command to turn it back on again */
    char          *noPrint;	/* command to skip when printing output from
				 * shell. This is usually the command which
				 * was executed to turn off echoing */
    int           noPLen;	/* length of noPrint command */
    Boolean	  hasErrCtl;	/* set if can control error checking for
				 * individual commands */
    char	  *errCheck;	/* string to turn error checking on */
    char	  *ignErr;	/* string to turn off error checking */
    /*
     * command-line flags 
     */
    char          *echo;	/* echo commands */
    char          *exit;	/* exit on error */
}               Shell;

#if defined(unix)
extern char 	*targFmt;   	/* Format string for banner that separates
				 * output from multiple jobs. Contains a
				 * single %s where the name of the node being
				 * made should be put. */
extern GNode	*lastNode;  	/* Last node for which a banner was printed.
				 * If Rmt module finds it necessary to print
				 * a banner, it should set this to the node
				 * for which the banner was printed */
#endif /* defined(unix) */
extern int  	nJobs;	    	/* Number of jobs running (local and remote) */
extern int  	nLocal;	    	/* Number of jobs running locally */
extern Lst  	jobs;	    	/* List of active job descriptors */
extern Lst  	stoppedJobs;	/* List of jobs that are stopped or didn't
				 * quite get started */
extern Boolean	jobFull;    	/* Non-zero if no more jobs should/will start*/

/*
 * These functions should be used only by an intelligent Rmt module, hence
 * their names do *not* include an underscore as they are not fully exported,
 * if you see what I mean.
 */
extern void 	JobDoOutput(/* job, final? */);	/* Funnel output from
			     	    	    	 * job->outPipe to the screen,
						 * filtering out echo-off
						 * strings etc. */
extern void 	JobFinish(/* job, status */);	/* Finish out a job. If
			    	    	    	 * status indicates job has
						 * just stopped, not finished,
						 * the descriptor is placed on
						 * the stoppedJobs list. */
#endif /* _JOB_H_ */
