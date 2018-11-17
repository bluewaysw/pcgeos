/*-
 * cust-cfg.h --
 *	Configuration constants for the local site.
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
 *	"$Id: cust-cfg.h,v 1.3 1996/09/28 00:18:07 tbradley Exp $ SPRITE (Berkeley)"
 */
#ifndef _CUST_CFG_H_
#define _CUST_CFG_H_

/*
 * For customs, everything's the same except we tell the job module to use
 * the extended Rmt interfaces.
 */

#if defined (unix) || defined(_LINUX)
#	include "../unix/unix-cfg.h"
#elif defined (_WIN32)
#	include "../nt/nt-cfg.h"
#endif /* unix */

/*
 * RMT_WILL_WATCH
 *	If defined, the job module will rely on the rmt module to pay attention
 *	to streams and to call Job_CatchChildren on a regular basis should any
 *	jobs be run locally. Defining this adds the following three functions
 *	to the Rmt interface requirements:
 *	    void    Rmt_Watch(stream, proc, data)
 *	    	Call proc(stream, data) whenever stream becomes READABLE.
 *	    void    Rmt_Ignore(stream)
 *	    	Stop paying attention to stream.
 *	    void    Rmt_Wait()
 *	    	Wait for something to happen, process it and return when
 *	    	done. During this time, Job_CatchChildren should be called
 *	    	regularly (if the Rmt module wishes to catch SIGCHLD, or its
 *	    	equivalent, and call Job_CatchChildren SYNCHRONOUSLY [e.g.
 *	    	by setting a flag for Rmt_Wait to watch for], that is fine).
 *	    	The Customs Rmt module does it by waking up every 200 ms
 *	    	and calling Job_CatchChildren(block = FALSE).
 *
 * RMT_WANTS_SIGNALS
 *	If defined, the job module will rely on the rmt module to transmit
 *	any signal to a remote job. If not defined, the pid in the job
 *	descriptor will be assumed to hold the id of a process that will
 *	transmit the signal. If signals cannot be sent at all, set the pid
 *	to 0 and don't define this.
 *	There are several places where a signal might be sent:
 *	    1) if pmake receives one of the four interrupt signals (SIGINT,
 *	    	SIGHUP, SIGTERM and SIGQUIT)
 *	    2) if pmake receives a terminal signal (SIGTSTP, SIGTTIN,
 *	    	SIGTTOU, SIGWINCH). Note these signals are only caught if
 *	    	RMT_WANT_SIGNALS or USE_PGRP are defined.
 *	    3) if something calls for an abort of all currently running jobs
 *	Defining this constant introduces another interface:
 *	    int	Rmt_Signal(job, signo)
 *	The function should return non-zero on success, zero if signal couldn't
 *	be delivered.
 *
 * RMT_NO_EXEC
 *	If defined, implies that a fork/exec is not required to export a
 *	job. When running in parallel mode, pmake will use the function
 *	    	int Rmt_Export(fileToExec, argv, job)
 *	in place of Rmt_Begin (Rmt_Begin, Rmt_Exec, Rmt_LastID and Rmt_Done
 *	will still be used if exporting in non-parallel mode, as the
 *	compatibility module doesn't use Job descriptors). Defining
 *	RMT_WANT_SIGNALS usually implies RMT_NO_EXEC.
 */
#if defined (unix) || defined(_LINUX)
//#    define RMT_WILL_WATCH
#    define RMT_WANTS_SIGNALS
#    define RMT_NO_EXEC
#endif /* defined (unix) */
/*
 * CAN_EXPORT
 *	If defined, indicates that an export system is installed. This
 *	activates the -X and -x flags.
 */
#if defined (unix)
#define CAN_EXPORT
#endif /* defined (unix) */

/*
 * If you're using something more reliable than NFS for your filesystem,
 * nuke this #undef line. Look at the note in ../unix/config.h for its
 * meaning.
 */
#undef RECHECK

/* For testing... */
//#define USE_PGRP

#if defined (unix)
#undef DEFSYSPATH
#define DEFSYSPATH "/staff/pcgeos/Include:/usr/public/lib/pmake"
#endif /* defined (unix) */

#endif /*_CUST_CFG_H_*/
