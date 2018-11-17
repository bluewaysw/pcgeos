/*-
 * host.c --
 *	Program to test the host request function of customs.
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
static char rcsid[] =
"$Id: host.c,v 1.5 89/11/14 13:46:04 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include "customs.h"
#include <sys/time.h>

main(argc, argv)
    int argc;
    char **argv;
{
    ExportPermit  permit;
    struct timeval start,
		   end;
    int i;
    int max;
    
    max = atoi(argv[1]);
    (void)gettimeofday(&start, (struct timezone *)0);
    for (i = 0; i < max; i++) {
	if (Customs_Host(&permit) != RPC_SUCCESS) {
	    Customs_PError("HOST");
	} else {
	    printf ("response: id %d, host %x\n", permit.id,
		    permit.addr.s_addr);
	}
    }
    gettimeofday(&end, (struct timezone *)0);
    end.tv_usec -= start.tv_usec;
    if (end.tv_usec < 0) {
	end.tv_usec += 1000000;
	end.tv_sec -= 1;
    }
    end.tv_sec -= start.tv_sec;
    printf ("elapsed time: %d.%06d\n%.6f seconds per rpc\n",
	    end.tv_sec, end.tv_usec,
	    ((end.tv_sec+end.tv_usec/1e6)/max));
	    
}
	    
