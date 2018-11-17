/*-
 * reginfo.c --
 *	Find out who's registered.
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
 */
#ifndef lint
static char *rcsid =
"$Id: reginfo.c,v 1.2 94/03/14 11:30:52 adam Exp $ SPRITE (Berkeley)";
#endif lint

#include    "customs.h"
#include    <stdio.h>
#include    <netdb.h>
#include    <sys/time.h>

typedef struct {
    char    	  *name;
    long    	  avail;
    long    	  rating;
    long    	  arch;
    long    	  numClients;
    long    	  *clients;
} Host;

SortHost(h1, h2)
    Host    **h1;
    Host    **h2;
{
    return (strcmp((*h1)->name, (*h2)->name));
}

main(argc, argv)
    int	    argc;
    char    **argv;
{
    char    	  	infoBuf[MAX_INFO_SIZE];
    Host    	  	*allHosts;
    int	    	  	i, j;
    int	    	  	numHosts;
    char    	  	*cp;
    struct sockaddr_in	sin;
    struct hostent	*he;
    Host    	    	**sortHosts;
    int	    	    	longest = 0;
    int	    	    	printArch = 0;
    int	    	    	printClients = 0;

    for (i = 1; i < argc; i++) {
	if (argv[i][0] == '-') {
	    switch(argv[i][1]) {
	    case 'a':
		printArch = 1;
		break;
	    case 'c':
		printClients = 1;
		break;
	    default:
		fprintf(stderr, "unknown flag '%s' ignored\n", argv[i]);
		break;
	    }
	} else {
	    fprintf(stderr, "unknown argument '%s' ignored\n", argv[i]);
	}
    }
    if (Customs_Master(&sin) != RPC_SUCCESS) {
	Customs_PError("Customs_Master");
	printf("Couldn't find master\n");
	exit(1);
    }
    he = gethostbyaddr(&sin.sin_addr, sizeof(sin.sin_addr), AF_INET);
    printf ("Master Agent at ");
    if (he == (struct hostent *)NULL) {
	printf("%s\n\n", InetNtoA(sin.sin_addr));
    } else {
	printf ("%s\n\n", he->h_name);
    }
    
    if (Customs_Info(&sin, infoBuf) != RPC_SUCCESS) {
	Customs_PError("Customs_Info");
	printf("Couldn't read registration info\n");
	exit(1);
    }
    cp = infoBuf;
    numHosts = *(int *)cp;
    cp += sizeof(int);
    allHosts = (Host *)malloc(numHosts * sizeof(Host));
    sortHosts = (Host **)malloc(numHosts * sizeof(Host *));
    for (i = 0; i < numHosts; i++) {
	int 	len;
	
	sortHosts[i] = &allHosts[i];
	allHosts[i].name = cp;
	len = strlen(cp);
	if (len > longest) {
	    longest = len;
	}
	cp += len + 1;
	cp = Customs_Align(cp, char *);
	allHosts[i].avail = *(long *)cp;
	cp += sizeof(long);
	allHosts[i].rating = *(long *)cp;
	cp += sizeof(long);
	allHosts[i].arch = *(long *)cp;
	cp += sizeof(long);
	allHosts[i].numClients = *(long *)cp;
	cp += sizeof(long);
	allHosts[i].clients = (long *)cp;
	cp += allHosts[i].numClients * sizeof(long);
    }

    qsort(sortHosts, numHosts, sizeof(Host *), SortHost);
    
    for (i = 0; i < numHosts; i++) {
	if (printArch) {
	    printf ("%-*s (arch = %d): ", longest, sortHosts[i]->name,
		    sortHosts[i]->arch);
	} else {
	    printf("%-*s: ", longest, sortHosts[i]->name);
	}
	if (sortHosts[i]->avail & AVAIL_DOWN) {
	    printf ("host down\n");
	} else if (sortHosts[i]->avail & AVAIL_IDLE) {
	    printf ("not idle\n");
	} else if (sortHosts[i]->avail & AVAIL_SWAP) {
	    printf ("not enough swap space\n");
	} else if (sortHosts[i]->avail & AVAIL_LOAD) {
	    printf ("load average too high\n");
	} else if (sortHosts[i]->avail & AVAIL_IMPORTS) {
	    printf ("too many imported jobs\n");
	} else {
	    printf ("available (index = %4d)\n", sortHosts[i]->rating);
	}
	if (printClients && sortHosts[i]->numClients != 0) {
	    printf ("%*sclients: ", longest+1+2+(printArch ? 10 : 0), "");
	    for (j = 0; j < sortHosts[i]->numClients; j++) {
		printf ("%s ", allHosts[sortHosts[i]->clients[j]].name);
	    }
	    putchar('\n');
	}
    }
    printf ("\nLast allocated: %s\n", allHosts[*(long *)cp].name);

    exit(0);
}
