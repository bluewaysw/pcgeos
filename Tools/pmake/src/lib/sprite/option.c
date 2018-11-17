/*
 * option.c --
 *
 *	Routines to do command line option processing.
 *
 * Copyright 1986 Regents of the University of California
 * Permission to use, copy, modify, and distribute this
 * software and its documentation for any purpose and without
 * fee is hereby granted, provided that the above copyright
 * notice appear in all copies.  The University of California
 * makes no representations about the suitability of this
 * software for any purpose.  It is provided "as is" without
 * express or implied warranty.
 */
#include <config.h>

#ifndef lint
static char rcsid[] = "$Id: option.c,v 1.3 96/06/24 15:04:09 tbradley Exp $ SPRITE (Berkeley)";
#endif not lint

#include <option.h>
#include <stdio.h>
#include <stdlib.h>

#include <compat/string.h>

#define OptNoArg(progName, opt) fprintf(stderr, \
		      "Warning: %s option \"-%s\" needs an argument\n", \
		      (progName), (opt))

/*
 *----------------------------------------------------------------------
 *
 * Opt_Parse --
 *
 *	Process a command line according to a template of accepted
 *	options.  See the manual page and header file for more details.
 *
 * Results:
 *	The number of options that weren't processed by this procedure
 *	is returned, and argv points to an array of unprocessed
 *	options.  (This is all of the options that didn't start with
 *	"-", except for those used as arguments to the options
 *	processed here; it's also anything after an OPT_REST option.)
 *
 * Side effects:
 *	The variables referenced from the option array get modified
 *	if their option was present on the command line.
 *
 *----------------------------------------------------------------------
 */

int
Opt_Parse(register int    argc, 	    /* Number of arguments in argv. */
	  char    	**argv,   	    /* Array of arguments */
	  Option  	  optionArray[],    /* Array of option descriptions */
	  int	    	  numOptions,	    /* Size of optionArray */
	  int		  flags) 	    /* Or'ed combination of various
					     * flag bits: only
					     * OPT_ALLOW_CLUSTERING is
					     * currently defined. */
{
    register Option 	*optionPtr; /* pointer to the current option in the
				     * array of option specifications */
    register char 	*curOpt;    /* Current flag argument */
    register char 	**curArg;   /* Current argument */
    register int  	argIndex;   /* Index into argv to which next unused
				     * argument should be copied */
    int 	  	stop=0;	    /* Set non-zero to stop processing
				     * arguments when an OPT_REST flag is
				     * encountered */
    int			length = 0; /* Number of characters in current
				     * option. */

    argIndex = 1;
    argc -= 1;
    curArg = &argv[1];

    while (argc && !stop) {
	if (**curArg == '-') {
	    curOpt = &curArg[0][1];
	    curArg += 1;
	    argc -= 1;

	    /*
	     * Check for the special options "?" and "help".  If found,
	     * print documentation and exit.
	     */

	    if ((strcmp(curOpt, "?") == 0) || (strcmp(curOpt, "help") == 0)) {
		Opt_PrintUsage (argv[0], optionArray, numOptions);
		exit(0);
	    }

	    /*
	     * Loop over all the options specified in a single argument
	     * (must be 1 unless OPT_ALLOW_CLUSTERING was specified).
	     */

	    while (1) {
		/*
		 * Loop over the array of options searching for one with the
		 * matching key string.  If found, it is left pointed to by
		 * optionPtr.
		 */
		for (optionPtr = &optionArray[numOptions - 1];
			optionPtr >= optionArray;
			optionPtr -= 1) {
		     if (optionPtr->key == NULL) {
			 continue;
		     }
		     if (*optionPtr->key == *curOpt) {
			 if (flags & OPT_ALLOW_CLUSTERING) {
			     length = strlen(optionPtr->key);
			     if (strncmp(optionPtr->key, curOpt, length) == 0) {
				 break;
			     }
			 } else {
			     if (strcmp(optionPtr->key, curOpt) == 0) {
				 break;
			     }
			 }
		     }
		}

		if (optionPtr < optionArray) {
		    /*
		     * No match.  Print error message and skip option.
		     */

		    fprintf(stderr, "Unknown option \"-%s\";", curOpt);
		    fprintf(stderr, "  type \"%s -help\" for information\n",
			    argv[0]);
		    break;
		}

		/*
		 * Take the appropriate action based on the option type
		 */

		if (optionPtr->type >= 0) {
		    *((int *) optionPtr->address) = optionPtr->type;
		} else {
		    switch (optionPtr->type) {
			case OPT_REST:
			    stop = 1;
			    *((int *) optionPtr->address) = argIndex;
			    break;
			case OPT_STRING:
			    if (argc == 0) {
				OptNoArg(argv[0], optionPtr->key);
			    } else {
				*((char **)optionPtr->address) = *curArg;
				curArg++;
				argc--;
			    }
			    break;
			case OPT_INT:
			    if (argc == 0) {
				OptNoArg(argv[0], optionPtr->key);
			    } else {
				char *endPtr;

				*((int *) optionPtr->address) =
					strtol(*curArg, &endPtr, 0);
				if (endPtr == *curArg) {
				    fprintf(stderr,
      "Warning: option \"-%s\" got a non-numeric argument \"%s\".  Setting to 0.\n",
					    optionPtr->key, *curArg);
				}
				curArg++;
				argc--;
			    }
			    break;
			case OPT_FLOAT:
			    if (argc == 0) {
				OptNoArg(argv[0], optionPtr->key);
			    } else {
				char *endPtr;

				*((double *) optionPtr->address) =
					strtod(*curArg, &endPtr);
				if (endPtr == *curArg) {
				    fprintf(stderr,
      "Warning: option \"-%s\" got non-floating-point argument \"%s\".  Setting to 0.\n",
					    optionPtr->key, *curArg);
				}
				curArg++;
				argc--;
			    }
			    break;
			case OPT_GENFUNC: {
			    int	    (*handlerProc)();

			    handlerProc = (int (*)())optionPtr->address;

			    argc = (* handlerProc) (optionPtr->key, argc,
				    curArg);
			    break;
			}
			case OPT_FUNC: {
			    int (*handlerProc)();

			    handlerProc = (int (*)())optionPtr->address;
			    
			    if ((* handlerProc) (optionPtr->key, *curArg)) {
				curArg += 1;
				argc -= 1;
			    }
			    break;
			}
			case OPT_DOC:
			    Opt_PrintUsage (argv[0], optionArray, numOptions);
			    exit(0);
			    /*NOTREACHED*/
		    }
		}
		/*
		 * Advance to next option
		 */

		if (flags & OPT_ALLOW_CLUSTERING) {
		    curOpt += length;
		    if (*curOpt == 0) {
			break;
		    }
		} else {
		    break;
		}
	    }
	} else {
	    /*
	     * *curArg is an argument for which we have no use, so copy it
	     * down.
	     */
	    argv[argIndex] = *curArg;
	    argIndex += 1;
	    curArg += 1;
	    argc -= 1;
	}
    }

    /*
     * If we broke out of the loop because of an OPT_REST argument, we want
     * to copy the rest of the arguments down, so we do.
     */
    while (argc) {
	argv[argIndex] = *curArg;
	argIndex += 1;
	curArg += 1;
	argc -= 1;
    }
    argv[argIndex] = (char *)NULL;
    return argIndex;
}

/*
 *----------------------------------------------------------------------
 *
 * Opt_PrintUsage --
 *
 *	Print out a usage message for a command.  This prints out the
 *	documentation strings associated with each option.
 *
 * Results:
 *	none.
 *
 * Side effects:
 *	Messages printed onto the console.
 *
 *----------------------------------------------------------------------
 */

void
Opt_PrintUsage(
	       char *commandName,
	       Option optionArray[],
	       int numOptions)
{
    register int i;
    int width;

    /*
     * First, compute the width of the widest option key, so that we
     * can make everything line up.
     */

    width = 4;
    for (i=0; i<numOptions; i++) {
	int length;
	if (optionArray[i].key == NULL) {
	    continue;
	}
	length = strlen(optionArray[i].key);
	if (length > width) {
	    width = length;
	}
    }

    fprintf(stderr, "Usage of command \"%s\"\n", commandName);
    for (i=0; i<numOptions; i++) {
	if (optionArray[i].type != OPT_DOC) {
	    fprintf(stderr, " -%s%-*s %s\n", optionArray[i].key,
		    width+1-strlen(optionArray[i].key), ":",
		    optionArray[i].docMsg);
	    switch (optionArray[i].type) {
		case OPT_INT: {
		    fprintf(stderr, "\t\tDefault value: %d\n",
			    *((int *) optionArray[i].address));
		    break;
		}
		case OPT_FLOAT: {
		    fprintf(stderr, "\t\tDefault value: %g\n",
			    *((double *) optionArray[i].address));
		    break;
		}
		case OPT_STRING: {
		    if (*(char **)optionArray[i].address != (char *) NULL) {
			    fprintf(stderr, "\t\tDefault value: \"%s\"\n",
				    *(char **) optionArray[i].address);
			    break;
		    }
		}
		default: {
		    break;
		}
	    }
	} else {
	    fprintf(stderr, " %s\n", optionArray[i].docMsg);
	}
    }
    fprintf(stderr, " -help%-*s Print this message\n", width-3, ":");
}
