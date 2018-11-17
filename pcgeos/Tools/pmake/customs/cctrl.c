/*-
 * cctrl.c --
 *	Program to perform various utility functions on a customs network
 *	or a single customs agent. The agent/network can be aborted,
 *	restarted, pinged, have its debugging parameters set or have
 *	an election forced on it.
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
"$Id: cctrl.c,v 1.1 91/06/09 15:55:20 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customs.h"
#include    <sys/time.h>
/*#include    <netinet/in.h>*/
#include    <netdb.h>
#include    <strings.h>

Boolean
Response(from, len, data)
    struct sockaddr_in	*from;
    int	    	  	len;
    Rpc_Opaque	  	data;
{
    printf ("%d bytes of data from %s\n", len, InetNtoA(from->sin_addr));
    return (False);
}

main(argc, argv)
    int	    argc;
    char    **argv;
{
    int	    	  	sock = Rpc_UdpCreate(False, 0);
    struct timeval	timeout;
    struct sockaddr_in	sin;
    Rpc_Proc	  	proc;
    char    	  	*cp;
    int	    	  	debug;
    struct servent  	*sep;

    sep = getservbyname ("customs", "udp");

    timeout.tv_sec = 2;
    timeout.tv_usec = 0;
    sin.sin_family = AF_INET;
    sin.sin_port = sep ? sep->s_port : htons(DEF_CUSTOMS_UDP_PORT);
    sin.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    
    cp = index(argv[0], '/');
    if (cp == (char *)NULL) {
	cp = argv[0];
    } else {
	cp += 1;
    }
    if (strcmp (cp, "restart") == 0) {
	proc = (Rpc_Proc)CUSTOMS_RESTART;
    } else if (strcmp (cp, "abort") == 0) {
	proc = (Rpc_Proc)CUSTOMS_ABORT;
    } else {
	proc = (Rpc_Proc)CUSTOMS_PING;
    }

    while (--argc > 0) {
	argv++;
	if (strcmp(*argv, "-restart") == 0) {
	    proc = (Rpc_Proc)CUSTOMS_RESTART;
	} else if (strcmp (*argv, "-abort") == 0) {
	    proc = (Rpc_Proc)CUSTOMS_ABORT;
	} else if (strcmp(*argv, "-ping") == 0) {
	    proc = (Rpc_Proc)CUSTOMS_PING;
	} else if (strcmp(*argv, "-all") == 0) {
	    sin.sin_addr.s_addr = htonl(INADDR_ANY);
	} else if (strcmp(*argv, "-elect") == 0) {
	    proc = (Rpc_Proc)CUSTOMS_ELECT;
	} else if (strcmp(*argv, "-debug") == 0) {
	    proc = CUSTOMS_DEBUG;
	    
	    if (argc == 1) {
		debug = DEBUG_RPC | DEBUG_CUSTOMS;
	    } else {
		argc--, argv++;
		debug = 0;
		while (**argv != '\0') {
		    if (**argv == 'r') {
			debug |= DEBUG_RPC;
		    } else if (**argv == 'c') {
			debug |= DEBUG_CUSTOMS;
		    } else if (**argv == 'n') {
			debug = 0;
		    }
		    (*argv)++;
		}
	    }
	} else if (**argv == '-') {
	    printf("Unknown switch: %s\n", *argv);
	    printf("Usage: %s [-r] [-all] [host]\n", cp);
	    exit(1);
	} else {
	    struct hostent *he;

	    he = gethostbyname(*argv);
	    if (he == (struct hostent *)NULL) {
		sin.sin_addr.s_addr = inet_addr(*argv);
	    } else {
		bcopy (he->h_addr, &sin.sin_addr, he->h_length);
	    }
	}
    }
    
    switch ((Customs_Proc)proc) {
	case CUSTOMS_PING:
	    printf ("Pinging %s\n", InetNtoA(sin.sin_addr));
	    break;
	case CUSTOMS_ELECT:
	    printf ("Forcing election on %s\n", InetNtoA(sin.sin_addr));
	    break;
	case CUSTOMS_ABORT:
	    printf ("Abort %s? [ny](n) ", InetNtoA(sin.sin_addr));
	    if (getchar() != 'y') {
		exit(0);
	    }
	    break;
	case CUSTOMS_RESTART:
	    printf ("Restart %s? [yn](y) ", InetNtoA(sin.sin_addr));
	    if (getchar() == 'n') {
		exit(0);
	    }
	    break;
	case CUSTOMS_DEBUG:
	    printf("Setting debug for %s to ", InetNtoA(sin.sin_addr));
	    if (debug == (DEBUG_CUSTOMS|DEBUG_RPC)) {
		printf("rpc & customs\n");
	    } else if (debug == DEBUG_CUSTOMS) {
		printf("customs only\n");
	    } else if (debug == DEBUG_RPC) {
		printf("rpc only\n");
	    } else {
		printf("nothing\n");
	    }
	    (void) Rpc_Broadcast(sock, &sin, proc, sizeof(debug),
				 (Rpc_Opaque)&debug, 0, (Rpc_Opaque)0,
				 2, &timeout, Response);
	    exit(0);
	    break;
    }
    (void) Rpc_Broadcast (sock, &sin, proc, 0, (Rpc_Opaque)0,
			  0, (Rpc_Opaque)0,
			  2, &timeout, Response);
}
