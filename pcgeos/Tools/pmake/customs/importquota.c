/*-
 * importquota.c --
 *	A program to set the availability of the local host.
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
"$Id: importquota.c,v 1.7 89/11/14 13:46:07 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customs.h"
#include    <sys/time.h>
#include    <stdio.h>

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
gettime (str)
    char    *str;
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
	fprintf (stderr, "malformed time\n");
	exit(1);
    }
    return (min * 60 + sec);
}

/*-
 *-----------------------------------------------------------------------
 * main --
 *	Usage:
 *	    importquota -check mm:ss -idle mm:ss -swap pct -load float
 *
 *	-check	  	interval at which to check availability
 *	-idle	  	minimum time the keyboard must be idle for the
 *	    	  	host to be available
 *	-swap	  	minimum percentage of swap space that must
 *	    	  	be free for the host to be available
 *	-load	  	a floating-point number which is the maximum
 *	    	  	load average the host can have before it becomes
 *	    	  	unavailable.
 *	-jobs	  	maximum number of imported jobs allowed at once
 *
 *	The -idle, -swap and -load have certain limits (e.g. you cannot
 *	say -idle 400:00). To turn off the checking of any criterion,
 *	give a 0 value for it (e.g. -load 0 means not to worry about the
 *	load averages on the machine).
 *
 * Results:
 *	None, really.
 *
 * Side Effects:
 *	The criteria are altered if all are within bounds.
 *
 *-----------------------------------------------------------------------
 */
main (argc, argv)
    int	    argc;
    char    **argv;
{
    Avail_Data	  	criteria,
			current;
    struct timeval	interval;
    double  	  	maxLoad,
			atof();
    Rpc_Stat   	  	rstat;
    Boolean 	  	beNice = -1;
    
    interval.tv_sec = interval.tv_usec = 0;
    criteria.changeMask = 0;

    for (argc--, argv++; argc > 1; argc -= 2, argv += 2) {
	if (strcmp (*argv, "-check") == 0) {
	    interval.tv_sec = gettime (argv[1]);
	} else if (strcmp (*argv, "-idle") == 0) {
	    criteria.idleTime = gettime (argv[1]);
	    criteria.changeMask |= AVAIL_IDLE;
	} else if (strcmp (*argv, "-swap") == 0) {
	    criteria.swapPct = atoi (argv[1]);
	    criteria.changeMask |= AVAIL_SWAP;
	} else if (strcmp (*argv, "-load") == 0) {
	    maxLoad = atof (argv[1]);
	    criteria.loadAvg = (int)(maxLoad * LOADSCALE);
	    criteria.changeMask |= AVAIL_LOAD;
	} else if (strcmp (*argv, "-jobs") == 0) {
	    criteria.imports = atoi(argv[1]);
	    criteria.changeMask |= AVAIL_IMPORTS;
	} else {
	    fprintf (stderr, "Unknown flag: %s\n", *argv);
	    exit(1);
	}
    }

    if (interval.tv_sec) {
	rstat = Customs_AvailInterval(&interval);
	if (rstat != RPC_SUCCESS) {
	    Customs_PError("Customs_AvailInterval\n");
	    fprintf(stderr, "Could not change availability interval\n");
	}
    }

    rstat = Customs_SetAvail(&criteria);

    if (rstat != RPC_SUCCESS) {
	Customs_PError("Customs_SetAvail");
	fprintf (stderr, "Could not change criteria\n");
    } else if (criteria.changeMask) {
	fprintf (stderr, "Values out of range:\n");
	if (criteria.changeMask & AVAIL_IDLE) {
	    fprintf (stderr, "\tidle time too long (%d:%02d maximum)\n",
		     MAX_IDLE / 60, MAX_IDLE % 60);
	}
	if (criteria.changeMask & AVAIL_SWAP) {
	    fprintf (stderr, "\tswap percentage too high (%d%% maximum)\n",
		     MAX_SWAP);
	}
	if (criteria.changeMask & AVAIL_LOAD) {
	    fprintf (stderr, "\tload average too low (%f minimum)\n",
		     (double) MIN_LOAD / LOADSCALE);
	}
	if (criteria.changeMask & AVAIL_IMPORTS) {
	    fprintf (stderr, "\tjob imports too low (%d minimum)\n",
		     MIN_IMPORTS);
	}
    }
    
    printf ("Current criteria:\n");
    if (criteria.idleTime) {
	printf ("\t      idle time:  %d:%02d\n", criteria.idleTime / 60,
		criteria.idleTime % 60);
    }
    if (criteria.swapPct) {
	printf ("\tswap percentage:  %d%%\n", criteria.swapPct);
    }
    if (criteria.loadAvg) {
	printf ("\t   load average:  %f\n",(double)criteria.loadAvg/LOADSCALE);
    }
    if (criteria.imports) {
	printf ("\t  imported jobs:  %d\n", criteria.imports);
    }
}
			 
