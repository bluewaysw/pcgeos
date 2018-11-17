/***********************************************************************
 *
 * PROJECT:	  PMake
 * MODULE:	  Prefix -- Utilities/Initialization
 * FILE:	  main.c
 *
 * AUTHOR:  	  Adam de Boor: Jul  4, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	main	    	    Entry point
 *	HandleToPrefix	    Map a fhandle_t to a Prefix
 *	NameToPrefix	    Map an absolute name to a Prefix
 *	Message	    	    Write a message to the console
 *	dprintf	    	    Write debugging info to the console
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	7/ 4/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Program to do stuff similar to Sprite's prefix table, thus
 *	simplifying the task of administering a sizeable network of
 *	workstations that require a consistent global filesystem for
 *	PMake to operate correctly.
 *
 * 	Copyright (c) Berkeley Softworks 1989
 * 	Copyright (c) Adam de Boor 1989
 *
 * 	Permission to use, copy, modify, and distribute this
 * 	software and its documentation for any non-commercial purpose
 *	and without fee is hereby granted, provided that the above copyright
 * 	notice appears in all copies.  Neither Berkeley Softworks nor
 * 	Adam de Boor makes any representations about the suitability of this
 * 	software for any purpose.  It is provided "as is" without
 * 	express or implied warranty.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: main.c,v 1.14 92/10/26 10:15:48 adam Exp $";
#endif lint

#include    "prefix.h"

#include    <varargs.h>
#include    <ctype.h>
#include    <sys/signal.h>
#include    <netdb.h>

#include    "rpc.h"

Lst	    	prefixes;   	    /* List of unmounted prefixes */
Lst	    	freePrefixes;	    /* List of freed Prefix records */

int	    	prefixSock;    	    /* Socket over which we talk to other
				     * prefix daemons */

int		debug;	    	    /* Non-zero if in debug mode */
int	    	quiet;	    	    /* Don't spew to the console */

struct sockaddr_in prefixMountAddr; /* Address of server for prefixes */

static FILE	*dbgStream;	    /* Stream into which debugging output
				     * should go */
struct sockaddr_in  searchNets[10];
unsigned    	    numSearchNets = 0;


/***********************************************************************
 *				AllocPrefix
 ***********************************************************************
 * SYNOPSIS:	    Allocate a new Prefix record
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The Prefix * with only the generation field set.
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 9/89	Initial Revision
 *
 ***********************************************************************/
Prefix *
AllocPrefix()
{
    Prefix  *pp;
    
    if (Lst_IsEmpty(freePrefixes)) {
	pp = (Prefix *)malloc(sizeof(Prefix));
	pp->generation = 0;
    } else {
	pp = (Prefix *)Lst_DeQueue(freePrefixes);
    }

    return(pp);
}

/***********************************************************************
 *				FreePrefix
 ***********************************************************************
 * SYNOPSIS:	    Free a prefix structure.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	Place the prefix on the freePrefixes list after upping its
 *	generation number. The prefix is removed from the prefixes list
 *	as well, but no other fields are altered.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 9/89	Initial Revision
 *
 ***********************************************************************/
void
FreePrefix(pp)
    Prefix  	*pp;
{
    LstNode 	ln;

    ln = Lst_Member(prefixes, (ClientData)pp);
    if (ln != NILLNODE) {
	Lst_Remove(prefixes, ln);
    }

    pp->generation += 1;
    (void)Lst_AtEnd(freePrefixes, (ClientData)pp);
}



/***********************************************************************
 *				HandleToPrefix
 ***********************************************************************
 * SYNOPSIS:	    Convert an NFS handle to a Prefix *
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The Prefix * for the FS.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 4/89		Initial Revision
 *
 ***********************************************************************/
Prefix *
HandleToPrefix(handle)
    fhandle_t	*handle;    	/* Handle to be converted. Should contain
				 * the ascii representation of the Prefix
				 * structure's address, if it's valid */
{
    PrefixHandle    *php = (PrefixHandle *)handle;

    if ((php->type != PH_REGULAR) ||
	(php->rd.generation != php->rd.pp->generation) ||
	(Lst_Member(prefixes, (ClientData)php->rd.pp) == NILLNODE))
    {
	return(PREFIX_STALE);
    } else {
	return(php->rd.pp);
    }
}


/***********************************************************************
 *				PrefixToHandle
 ***********************************************************************
 * SYNOPSIS:	    Create an NFS handle to return for a prefix.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The handle is filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/ 9/89	Initial Revision
 *
 ***********************************************************************/
void
PrefixToHandle(pp, handle)
    Prefix  	*pp;
    fhandle_t	*handle;
{
    PrefixHandle    *php;

    php = (PrefixHandle *)handle;
    
    /*
     * Make sure unused bytes are zero.
     */
    bzero(handle, sizeof(*handle));

    /*
     * Store the handle and the generation number
     */
    php->rd.type = PH_REGULAR;
    php->rd.generation = pp->generation;
    php->rd.pp = pp;
}


/***********************************************************************
 *				NameToPrefix
 ***********************************************************************
 * SYNOPSIS:	    Given an absolute name, return the Prefix for it
 * CALLED BY:	    various and sundry
 * RETURN:	    The Prefix * or NULL
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
Prefix	*
NameToPrefix(path)
    char    	*path;
{
    LstNode 	ln;
    Prefix  	*pp;

    for (ln = Lst_First(prefixes); ln != NILLNODE; ln = Lst_Succ(ln)) {
	pp = (Prefix *)Lst_Datum(ln);

	if (strcmp(pp->path, path) == 0) {
	    return(pp);
	}
    }
    
    return((Prefix *)NULL);
}
    

/***********************************************************************
 *				Message
 ***********************************************************************
 * SYNOPSIS:	    Print a message on the console
 * CALLED BY:	    Things Of Import
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 7/89		Initial Revision
 *
 ***********************************************************************/
void
Message(fmt, va_alist)
    char    	*fmt;	    /* Format string for message */
    va_dcl  	    	    /* Other args... */
{
    va_list 	args;

    /*
     * Start examining the args.
     */
    va_start(args);

    /*
     * Label the message
     */
    fprintf(stderr, "prefix: ");

    /*
     * Use vfprintf to print the message if it's around (better than _doprnt
     * since it handles some of the newer architectures...)
     * If vfprintf isn't around, we'll have to settle for _doprnt.
     */
    vfprintf(stderr, fmt, args);

    /*
     * Terminate the message with a newline and make sure the stream is
     * flushed.
     */
    putc('\r', stderr);
    putc('\n', stderr);
    fflush(stderr);

    /*
     * Finish processing the args
     */
    va_end(args);

    /*
     * Route output to debug log too, if not the console
     */
    if (debug && dbgStream != stderr) {
	va_start(args);
	fprintf(dbgStream, "prefix: ");
	vfprintf(dbgStream, fmt, args);
	putc('\n', dbgStream);
	fflush(dbgStream);
	va_end(args);
    }

}


/***********************************************************************
 *				dprintf
 ***********************************************************************
 * SYNOPSIS:	    Print if debugging enabled
 * CALLED BY:	    Lots Of Unimportant Things
 * RETURN:	    Nothing
 * SIDE EFFECTS:    No
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 7/89		Initial Revision
 *
 ***********************************************************************/
void
dprintf(fmt, va_alist)
    char    	*fmt;
    va_dcl
{
    va_list 	args;

    /*
     * Start examining the args.
     */
    va_start(args);

    if (debug) {
	vfprintf(dbgStream, fmt, args);
	fflush(dbgStream);
    }

    /*
     * Finish with the arguments
     */
    va_end(args);
}

#ifdef MEM_TRACE

/***********************************************************************
 *				MessageFlush
 ***********************************************************************
 * SYNOPSIS:	    Function required by tracing malloc to spew a string
 *	    	    to stderr.
 * CALLED BY:	    error in malloc.c
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The string is written to stream 2
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 6/89		Initial Revision
 *
 ***********************************************************************/
void
MessageFlush(str)
    char    	*str;
{
    write(2, str, strlen(str));
}


/***********************************************************************
 *				DumpMemStats
 ***********************************************************************
 * SYNOPSIS:	    Dump the memory usage to /tmp/prefix.usage
 * CALLED BY:	    SIGHUP
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/89		Initial Revision
 *
 ***********************************************************************/
void
DumpMemStats()
{
    FILE    *pu = fopen("/tmp/prefix.usage", "w");

    if (pu != NULL) {
	extern int fprintf();

	MessageFlush("Dumping memory allocation statistics to /tmp/prefix.usage...");
	malloc_printstats((void (*)())fprintf, (void *)pu);
	fclose(pu);
	MessageFlush("done\n");
    }
}

#endif /* MEM_TRACE */


/***********************************************************************
 *				DumpPrefix
 ***********************************************************************
 * SYNOPSIS:	    Return state of prefix tables to caller
 * CALLED BY:	    PREFIX_DUMP
 * RETURN:	    Wheeee.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	A buffer is filled with the following data:
 *	    For each imported prefix:
 *	    	<type><name>:<options>:<mtd>\n
 *	    <type> is one of i (imported, non-temporary), r (root), or
 *	    t (temporary). <options> is the string of mount options,
 *	    <mtd> is 1 if the prefix is mounted and 0 if it is not.
 *
 *	    For each exported prefix:
 *	    	x<dir>:<name>\n
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static void
DumpPrefix(from, msg, len, data, serverData)
    struct sockaddr_in	    *from;
    Rpc_Message		    msg;
    int			    len;
    Rpc_Opaque		    data;
    Rpc_Opaque	    	    serverData;	/* Data we gave (UNUSED) */
{
    if (len != 2) {
	Rpc_Error(msg, RPC_BADARGS);
    } else {
	char	    *buf;
	LstNode	    ln;
	Prefix	    *pp;
	char	    *cp;
	int 	    left;
	
	left = len = *(short *)data;
	left -= 1;

	/*
	 * Allocate a buffer of the proper size.
	 */
	cp = buf = (char *)malloc(len+1);
	bzero(buf, len);

	for (ln = Lst_First(prefixes); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    int	    eltlen;

	    pp = (Prefix *)Lst_Datum(ln);
	    eltlen = 1 + strlen(pp->path) + 1 + strlen(pp->options) + 1 + 1 + 1;

	    /*
	     * If the prefix is temporary, only return it if it's mounted.
	     * Permanent prefixes are governed solely by the amount of space
	     * left.
	     */
	    if ((eltlen < left) && (!(pp->flags & PREFIX_TEMP) ||
				    (pp->flags & PREFIX_MOUNTED)))
	    {
		sprintf(cp, "%c%s:%s:%c\n",
			((pp->flags & PREFIX_TEMP) ? 't' :
			 ((pp->flags & PREFIX_ROOT) ? 'r' : 'i')),
			pp->path, pp->options,
			(pp->flags & PREFIX_MOUNTED) ? '1' : '0');
		cp += eltlen;
		left -= eltlen;
	    }
	}
	
	Export_Dump(cp, &left);

	Rpc_Return(msg, len - left + 1, (Rpc_Opaque)buf);

	free(buf);
    }
}


/***********************************************************************
 *				PrintPrefix
 ***********************************************************************
 * SYNOPSIS:	    Print the state of the prefix tables
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Stuff be printed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
PrintPrefix(server)
    struct sockaddr_in	*server;
{
    char    	buf[8192];  	/* 8K for now */
    short   	len;	    	/* Place to pass length to Rpc_Call */
    Rpc_Stat	status;
    char    	*cp;
    char    	*end;
    struct timeval retry;

    retry.tv_sec = 1;
    retry.tv_usec = 0;
    
    len = sizeof(buf);
    status = Rpc_Call(prefixSock, server, PREFIX_DUMP,
		      sizeof(len), (Rpc_Opaque)&len,
		      sizeof(buf), (Rpc_Opaque)buf,
		      2, &retry);

    if (status != RPC_SUCCESS) {
	fprintf(stderr, "Unable to dump prefix tables: %s\n",
		Rpc_ErrorMessage(status));
	return False;
    }

    end = buf+sizeof(buf);
    
    printf("IMPORTED PREFIXES:\n");
    printf("Type    Name              Mounted    Options\n");
    printf("============================================\n");
    cp = buf;

    while (*cp != 'x' && *cp != '\0' && cp < end) {
	int 	namelen,
		optlen;
	char 	*cp2;
	char	*type;
	char	*name;

	type = ((*cp == 'i') ? "import" : ((*cp == 'r') ? "root" : "temp"));

	cp += 1;
	cp2 = (char *)index(cp, ':');
	name = cp;
	namelen = cp2 - name;

	cp = cp2+1;
	cp2 = (char *)index(cp, ':');
	optlen = cp2-cp;
	
	printf ("%-8s%-18.*s  %-3s      %.*s\n",
		type,
		namelen, name,
		cp2[1] == '1' ? "yes" : "no",
		optlen, cp);

	cp = cp2 + 3;
    }
    printf("\nEXPORTED PREFIXES\n");
    printf("Directory                           Exported As             Flags\n");
    printf("=================================================================\n");
	
    while (*cp == 'x' && cp < end) {
	int 	dirlen;
	char	*cp2;
	char	*dir;
	int 	flags;

	dir = cp+1;
	cp = (char *)index(dir, '|');
	dirlen = cp - dir;

	cp += 1;
	cp2 = (char *)index(cp, '|');

	flags = cp2[1] - '0';
	
	printf("%-35.*s %-23.*s %s%s\n", dirlen, dir, cp2-cp, cp,
	       (flags & 1) ? "Act " : "",
	       (flags & 2) ? "Loc " : "");

	cp = cp2 + 3;
    }
    return True;
}
	

/***********************************************************************
 *				ChangeDebug
 ***********************************************************************
 * SYNOPSIS:	    Change the state of debugging
 * CALLED BY:	    PREFIX_DEBUG
 * RETURN:	    Nothing
 * SIDE EFFECTS:    'debug' is set to the passed value
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/13/89		Initial Revision
 *
 ***********************************************************************/
static void
ChangeDebug(from, msg, len, data, serverData)
    struct sockaddr_in	    *from;
    Rpc_Message		    msg;
    int			    len;
    Rpc_Opaque		    data;
    Rpc_Opaque	    	    serverData;	/* Data we gave (UNUSED) */
{
    if (len != 4) {
	Rpc_Error(msg, RPC_BADARGS);
    } else {
	quiet = (*(long *)data & PREFIX_DEBUG_SEARCH) ? 0 : 1;
	dprintf("PREFIX LOCATION DEBUGGING %s\r\n",
		quiet ? "DISABLED" : "ENABLED");

	if (*(long *)data & PREFIX_DEBUG_SERVER) {
	    debug = 1;
	    dprintf("SERVER DEBUGGING ENABLED\r\n");
	} else {
	    dprintf("SERVER DEBUGGING DISABLED\r\n");
	    debug = 0;
	}
	Child_Call(NULL, PREFIX_DEBUG);
	Rpc_Return(msg, 0, (Rpc_Opaque)NULL);
    }
}

/***********************************************************************
 *				BeFiendish
 ***********************************************************************
 * SYNOPSIS:	    Enter daemon mode
 * CALLED BY:	    main
 * RETURN:	    Never
 * SIDE EFFECTS:    The process forks...read the code.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static void
BeFiendish()
{
    int			pid;	    	/* Child process ID in case we have
					 * a problem in the parent. */
    LstNode 		ln;		/* Current prefix node */
    LstNode		next;		/* Node of next prefix to mount */
    
    /*
     * We must be all root to function effectively...
     */
    if (getuid() != 0 || geteuid() != 0) {
	fprintf(stderr, "must be run by root to act as a daemon\n");
	exit(1);
    }
    
    /*
     * Create the socket over which we communicate with everyone but the kernel
     */
    prefixSock = Rpc_UdpCreate(True, PREFIX_PORT);
    if (prefixSock == -1) {
	perror("Rpc_UdpCreate");
	exit(1);
    }

    Rpc_ServerCreate(prefixSock, PREFIX_DUMP, DumpPrefix,
		     Rpc_SwapShort, NULL, NULL);
    Rpc_ServerCreate(prefixSock, PREFIX_DEBUG, ChangeDebug,
		     Rpc_SwapLong, NULL, NULL);
    
    /*
     * Locate exported prefixes and register servers
     */
    Export_Init();

    /*
     * Make sure the mount directory's ok
     */
    Mount_Init();
	    
    /*
     * Initialize things in the module that manages unmounted prefixes
     */
    Import_Init();

    /*
     * Create the "child" process the daemon will use for mounting and
     * unmounting. In reality, they're siblings, but life goes on.
     */
    if (!Child_Init()) {
	exit(1);
    }
    
    /*
     * Mount the existing prefixes on ourself.
     *
     * Register the MOUNT_DIR with the kernel first, only mounting
     * other prefixes if we succeed there.
     */
    if (Mount_MountRoot()) {
	for (ln = Lst_First(prefixes); ln != NILLNODE; ln = next){
	    Prefix  *pp = (Prefix *)Lst_Datum(ln);
	    char    *answer;

	    next = Lst_Succ(ln);

	    if (Export_IsExported(pp->path)) {
		
		fprintf(stderr, "ignoring %s: we're exporting it already",
			pp->path);
		Import_DeletePrefix(pp, &answer);
		fprintf(stderr, " (result: %s)\r\n", answer);
	    } else if (!Child_Call(pp, PREFIX_MOUNT_LOCAL)) {
		/*
		 * Remove the prefix.
		 */
		fprintf(stderr, "Couldn't mount %s: deleting\n",
			pp->path);
		Import_DeletePrefix(pp, &answer);
	    } else {
		pp->flags |= PREFIX_INITIALIZED;
	    }
	}
    } else {
	/*
	 * Kill both processes before exiting non-zero
	 */
	Message("Couldn't mount %s\n", MOUNT_DIR);
	Child_Kill();
	exit(1);
    }

    /*
     * Fork so we can detach from our parent.
     */
    switch (pid = fork()) {
	case 0:
	    /*
	     * Change our process group so opening the console doesn't make
	     * it our controlling terminal. Wouldn't want to be shut out by
	     * it or get a HANGUP signal should someone log out on it.
	     */
	    setpgrp(0, getpid());
	    /*
	     * Go do our thing after opening stderr to the console for
	     * logging purposes.
	     */
	    freopen("/dev/console", "w", stderr);
	    /*
	     * Close the other two standard streams so we can be started
	     * via an rsh. Otherwise, rshd won't exit...
	     */
	    close(0);
	    close(1);
#ifdef MEM_TRACE
	    (void)signal(SIGHUP, DumpMemStats);
#endif /* MEM_TRACE */
	    /*
	     * Rpc_Run never returns
	     */
	    dprintf("main prefix daemon alive and running...\n");
	    Rpc_Run();
	    fprintf(stderr, "Rpc_Run returned!\n");
	    exit(1);
	case -1:
	    perror("fork");
	    Child_Kill();
	    exit(1);
	    break;
	default:
	    exit(0);
    }
}

/***********************************************************************
 *				ReadConfigFile
 ***********************************************************************
 * SYNOPSIS:	    Read a configuration file
 * CALLED BY:	    main
 * RETURN:	    1 if successful, 0 if not
 * SIDE EFFECTS:    Things are entered on the prefixes and exports lists
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 8/89		Initial Revision
 *
 ***********************************************************************/
static int
ReadConfigFile(name)
    char    	*name;	    /* Name of file to read */
{
    FILE    	*cf;	    /* Stream open to file */
    char    	line[256];  /* Line from file. I can't see it ever getting
			     * this big, but better safe than sorry, no? */
    char    	*cp;
    int	    	num = 1;
    int	    	retval = 1;

    cf = fopen(name, "r");

    if (cf == (FILE *)NULL) {
	perror(name);
	return(0);
    }

    while (fgets(line, sizeof(line), cf) != NULL) {
	for (cp = line; isspace(*cp); cp++) {
	    ;
	}

	switch(*cp) {
	    case 'i': case 'I':
	    case 'r': case 'R':
	    {
		/*
		 * Import a prefix or prefix root. Usage:
		 *
		 * import	<prefix>	[<mount options>]
		 * root		<prefix>	[<mount options>]
		 */
		char	*prefix;
		int 	flags = (*cp == 'r' || *cp == 'R') ? PREFIX_ROOT : 0;
		
		/*
		 * Skip command
		 */
		while (!isspace(*cp) && (*cp != '\0')) {
		    cp++;
		}
		/*
		 * Skip to prefix
		 */
		while (isspace(*cp)) {
		    cp++;
		}
		
		if (*cp == '\0') {
		   fprintf(stderr,
			   "file \"%s\", line %d: %s requires prefix as argument\n",
			   name, num, flags ? "root" : "import");
		   retval = 0;
		} else {
		    Prefix  	*pp;	/* New prefix */
		    char    	save;	/* Character after prefix */
		    
		    /*
		     * Record and skip over prefix
		     */
		    prefix = cp;
		    while (!isspace(*cp) && (*cp != '\0')) {
			cp++;
		    }
		    /*
		     * Save character after prefix so we know if we hit
		     * the end of the line.
		     */
		    save = *cp;
		    *cp++ = '\0';

		    pp = Import_CreatePrefix(prefix);
		    if (pp != NULL) {
			if (save != '\0' && save != '\n') {
			    /*
			     * May be mount options here...
			     */
			    while (isspace(*cp)) {
				cp++;
			    }
			    if (*cp != '\0') {
				/*
				 * Rest of the line is options...
				 */
				int 	len;	    /* Length of options */
				
				/*
				 * Skip to the end of the line, keeping
				 * track of the start of the options.
				 */
				pp->options = cp;
				while (*cp != '\n' && *cp != '\0') {
				    cp++;
				}

				/*
				 * Copy the options into their own buffer
				 */
				*cp = '\0';
				len = cp - pp->options;

				cp = (char *)malloc(len+1);
				strcpy(cp, pp->options);
				pp->options = cp;
			    }
			}
			/*
			 * Set the PREFIX_ROOT flag if appropriate.
			 */
			pp->flags |= flags;
		    }
		}
		break;
	    }
	    case 'e': case 'E' : case 'x' : case 'X':
	    {
		/*
		 * Export a directory as a prefix. Usage:
		 *
		 * export [local] [opt=<nfsopts>] <directory> [<prefix>]
		 *
		 * If no <prefix> is given, <directory> is used.
		 */
		char	*dir;
		char	*prefix;
		Boolean	local = False;
		char	*options = NULL;
		
		/*
		 * Skip command
		 */
		while (!isspace(*cp) && (*cp != '\0')) {
		    cp++;
		}
		/*
		 * Skip to directory
		 */
		while (isspace(*cp)) {
		    cp++;
		}

		/*
		 * Handle any flags between the command and the directory.
		 */
		while (1) {
		    if (*cp == 'l') {
			char *cp2;

			/*
			 * Skip to end of word so we can see if the whole
			 * thing matches this option.
			 */
			for (cp2 = cp; !isspace(*cp2) && *cp2 != '\0'; cp2++) {
			    ;
			}

			if (strncmp(cp, "local", cp2-cp) == 0) {
			    /*
			     * It's the option we sought. Set the flag and
			     * advance cp past the whitespace that follows
			     * the option.
			     */
			    local = True;
			    cp = cp2;
			} else {
			    /*
			     * Not a known option: assume it's the directory to
			     * be exported.
			     */
			    break;
			}
		    } else if ((*cp == 'o') && !strncmp(cp, "opt=", 4)) {
			/*
			 * NFS mount options for the client to use.
			 */
			char	*cp2;
			
			cp += 4;
			for (cp2 = cp; !isspace(*cp2) && *cp2 != '\0'; cp2++) {
			    ;
			}

			options = (char *)malloc(cp2-cp+1);
			bcopy(cp, options, cp2-cp);
			options[cp2-cp] = '\0';
			cp = cp2;
		    } else {
			/*
			 * Not a known option: assume it's the directory to
			 * be exported.
			 */
			break;
		    }
		    while (isspace(*cp)) {
			cp++;
		    }
		}
		
		if (*cp == '\0') {
		   fprintf(stderr,
			   "file \"%s\", line %d: export requires directory, at least\n",
			   name, num);
		   retval = 0;
		} else {
		    /*
		     * Record start of, and skip over, directory
		     */
		    dir = cp;
		    while (!isspace(*cp) && (*cp != '\0')) {
			cp++;
		    }

		    if (*cp != '\0') {
			/*
			 * Terminate directory and skip to prefix
			 */
			*cp++ = '\0';
			while (isspace(*cp)) {
			    cp++;
			}
			if (*cp != '\0') {
			    /*
			     * Actually a prefix here -- use it
			     */
			    prefix = cp;
			    while (!isspace(*cp) && (*cp != '\0')) {
				cp++;
			    }
			    /*
			     * Terminate the prefix
			     */
			    *cp = '\0';
			} else {
			    /*
			     * Prefix is the same as the directory
			     */
			    prefix = dir;
			}
		    } else {
			/*
			 * Prefix be the same as the directory.
			 */
			prefix = dir;
		    }

		    /*
		     * Make permanent copies of the two things
		     */
		    cp = (char *)malloc(strlen(dir) + 1);
		    strcpy(cp, dir);
		    dir = cp;

		    cp = (char *)malloc(strlen(prefix) + 1);
		    strcpy(cp, prefix);
		    prefix = cp;

		    if (options == NULL) {
			options = (char *)malloc(1);
			*options = '\0';
		    }

		    /*
		     * Record the export of the thing.
		     */
		    Export_Prefix(dir, prefix, local, options);
		}
		break;
	    }
	    case '\0':
	    case '#':
		/*
		 * Comment/blank line -- ignore line
		 */
		break;
	    case 'q': case 'Q':
		/*
		 * Be quiet. Usage:
		 *
		 * quiet
		 *
		 */
		quiet = 1;
		break;
	    case 'd': case 'D':
	    {
		/*
		 * Turn on debugging. Usage:
		 *
		 * debug [<logfile> <mode>]
		 *
		 */
		char	*dbgFile;

		debug = 1;
		dbgStream = stderr;

		while (!isspace(*cp) && *cp != '\0') {
		    cp++;
		}

		while (isspace(*cp)) {
		    cp++;
		}

		if (*cp != '\0') {
		    dbgFile = cp;
		    while(!isspace(*cp) && *cp != '\0') {
			cp++;
		    }
		    if (*cp != '\0') {
			*cp++ = '\0';
			while(isspace(*cp)) {
			    cp++;
			}
		    }
		    if (*cp != 'a' && *cp != 'w') {
			*cp = 'a';
			cp[1] = '\0';
		    }
		    dbgStream = fopen(dbgFile, cp);
		    if (dbgStream == NULL) {
			fprintf(stderr, "can't open debug log \"%s\"\n",
				dbgFile);
			dbgStream = stderr;
		    } else {
			time_t	now;

			time(&now);
			fprintf(dbgStream, "prefix: Start %s", ctime(&now));
		    }
		}
		break;
	    }
	    case 'n': case 'N':
		/*
		 * Specify a network on which to search. Usage:
		 *
		 * network <in-addr>
		 */
		if (numSearchNets == sizeof(searchNets)/sizeof(searchNets[0])) {
		    fprintf(stderr,
			    "file \"%s\", line %d: too many networks specified (%d max)\n",
			    name, num,
			    sizeof(searchNets)/sizeof(searchNets[0]));
		    retval = 0;
		    break;
		}
		/*
		 * Skip command
		 */
		while (!isspace(*cp) && (*cp != '\0')) {
		    cp++;
		}
		/*
		 * Skip to network address
		 */
		while (isspace(*cp)) {
		    cp++;
		}
		if (*cp == '\0') {
		    fprintf(stderr,
			    "file \"%s\", line %d: network requires network address\n",
			    name, num);
		    retval = 0;
		} else {
		    searchNets[numSearchNets].sin_addr.S_un.S_addr =
			inet_addr(cp);
		    numSearchNets += 1;
		}
		break;
	    case '.':
		if (cp[1] == 'i' || cp[1] == 'I') {
		    /*
		     * Include file -- recurse.
		     *
		     * Skip command
		     */
		    char    *name;
		    
		    while (!isspace(*cp) && (*cp != '\0')) {
			cp++;
		    }
		    /*
		     * Skip to file
		     */
		    while (isspace(*cp)) {
			cp++;
		    }
		    name = cp;
		    while (!isspace(*cp)) {
			cp++;
		    }
		    *cp = '\0';
		    
		    retval = ReadConfigFile(name) && retval;
		    break;
		}
	    default:
		fprintf(stderr, "\"%s\" command unknown\n",
			cp);
		retval = 0;
		break;
	}
	num++;
    }
    fclose(cf);
    return(retval);
}
    

/***********************************************************************
 *				PrepSearchNets
 ***********************************************************************
 * SYNOPSIS:	    Make sure the searchNets array holds valid data.
 * CALLED BY:	    (EXTERNAL) ImportLocatePrefix, ExportDelete
 * RETURN:	    nothing
 * SIDE EFFECTS:    searchNets & numSearchNets may be changed
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/15/94		Initial Revision
 *
 ***********************************************************************/
void
PrepSearchNets()
{
    unsigned	i;
    
    if (numSearchNets == 0) {
	Rpc_GetNetworks(prefixSock, sizeof(searchNets)/sizeof(searchNets[0]),
			searchNets, &numSearchNets);
    }
    for (i = 0; i < numSearchNets; i++) {
	searchNets[i].sin_port = htons(PREFIX_PORT);
	searchNets[i].sin_family = AF_INET;
    }
}


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    Initialization
 * CALLED BY:	    UNIX
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Process forks and parent goes away.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/ 5/89		Initial Revision
 *
 ***********************************************************************/
main(argc, argv)
    int	    	argc;
    char    	**argv;
{
    Prefix	*pp;	    /* Prefix being added */
    int		i;  	    /* Index into argv */
    int	   	daemon=0;   /* Non-zero if should enter daemon mode */
    Lst		delete;	    /* List of prefixes to be deleted */
    Lst	    	noex;	    /* List of prefixes to stop exporting */
    int	    	printem=0;  /* Non-zero if should request all prefixes and
			     * print them. */
    char    	*printhost=0;	/* Host whose prefixes are desired */
    int	    	debugon=0;  /* Non-zero if should turn debugging on */
    int	    	debugoff=0; /* Non-zero if should turn debugging off */

    /*
     * Initialize the lists on which Prefixes can reside
     */
    prefixes = Lst_Init(FALSE);
    freePrefixes = Lst_Init(FALSE);
    delete = Lst_Init(FALSE);
    noex = Lst_Init(FALSE);

    dbgStream = stderr;

    for (i = 1; i < argc; i++) {
	if (argv[i][0] == '-') {
	    switch(argv[i][1]) {
		case 'D':
		    daemon = 1;
		    if (argv[i][2] == 'D') {
			debug = 1;
		    }
		    break;
		case 'd':
		    if (strcmp(argv[i], "-debug") == 0) {
			debugon=1; debugoff=0;
		    } else {
			/*
			 * Delete a prefix (not valid in daemon mode)
			 */
			if (i+1 == argc) {
			    fprintf(stderr,
				    "-d requires prefix as argument\n");
			    goto usage;
			} else {
			    (void)Lst_AtEnd(delete, (ClientData)argv[i+1]);
			}
			i += 1;
		    }
		    break;
		case 'f':
		    /*
		     * Read configuration from a file. This implies we're
		     * in daemon mode.
		     */
		    if (i+1 == argc) {
			fprintf(stderr, "-f requires filename as argument\n");
			goto usage;
		    } else if (ReadConfigFile(argv[i+1])) {
			daemon = 1;
		    }
		    i += 1;
		    break;
		case 'i':
		    /*
		     * Import a prefix
		     */
		    if (i+1 == argc) {
			fprintf(stderr, "-i requires prefix as argument\n");
			goto usage;
		    } else {
			Prefix	*pp;
			
			dprintf("-i %s\n", argv[i+1]);
			pp = Import_CreatePrefix(argv[i+1]);
			if (i+2 < argc && argv[i+2][0] != '-') {
			    /*
			     * Have mount options...
			     */
			    if (pp != NULL) {
				pp->options =
				    (char *)malloc(strlen(argv[i+2])+1);
				strcpy(pp->options, argv[i+2]);
			    }
			    /*
			     * Skip options even if prefix not created...
			     */
			    i += 1;
			}
		    }
		    i += 1;
		    break;
		case 'n':
		    if (strcmp(argv[i], "-nodebug") == 0) {
			debugoff = 1; debugon = 0;
		    } else {
			goto usage;
		    }
		    break;
		case 'p':
		    /*
		     * Print all known prefixes after processing everything
		     * else.
		     */
		    if (i+1 != argc && argv[i+1][0] != '-') {
			printhost = argv[i+1];
			i += 1;
		    }
		    printem = 1;
		    break;
		case 'q':
		    quiet = 1;
		    break;
		case 'r':
		    /*
		     * Import prefixes under a root
		     */
		    if (i+1 == argc) {
			fprintf(stderr, "-r requires prefix as argument\n");
			goto usage;
		    } else {
			dprintf("-r %s\n", argv[i+1]);
			pp = Import_CreatePrefix(argv[i+1]);

			if (pp != NULL) {
			    pp->flags = PREFIX_ROOT;
			}
		    }
		    i += 1;
		    break;
		case 'x':
		    /*
		     * Export a directory under a prefix
		     */
		    if (i+1 == argc) {
			fprintf(stderr,
				"-x requires at least a directory\n");
			goto usage;
		    } else {
			char	*fsname;
			char	*prefix;
			char	*options;

			if ((i+3 < argc) &&
			    argv[i+2][0] != '-' &&
			    argv[i+3][0] != '-')
			{
			    fsname = (char *)malloc(strlen(argv[i+1])+1);
			    strcpy(fsname, argv[i+1]);
			    prefix = (char *)malloc(strlen(argv[i+2])+1);
			    strcpy(prefix, argv[i+2]);
			    options = (char *)malloc(strlen(argv[i+3])+1);
			    strcpy(options, argv[i+3]);
			    i += 3;
			}
			else if ((i+2 < argc) &&
				 argv[i+2][0] != '-')
			{
			    fsname = (char *)malloc(strlen(argv[i+1])+1);
			    strcpy(fsname, argv[i+1]);
			    prefix = (char *)malloc(strlen(argv[i+2])+1);
			    strcpy(prefix, argv[i+2]);
			    options = (char *)malloc(1);
			    *options = '\0';
			    i += 2;
			}
			else
			{
			    fsname = (char *)malloc(strlen(argv[i+1])+1);
			    strcpy(fsname, argv[i+1]);
			    prefix = (char *)malloc(strlen(argv[i+1])+1);
			    strcpy(prefix, argv[i+1]);
			    options = (char *)malloc(1);
			    *options = '\0';
			    i += 1;
			}
			dprintf("-x %s %s %s\n", fsname, prefix, options);
			Export_Prefix(fsname, prefix, argv[i][2] == 'l',
				      options);
		    }
		    break;
		case 'X':
		    /*
		     * Stop exporting a prefix.
		     */
		    if (i+1 == argc) {
			fprintf(stderr,
				"-X requires a prefix to stop exporting");
			goto usage;
		    } else {
			(void)Lst_AtEnd(noex, argv[i+1]);
			i += 1;
		    }
		    break;
		default:
		    fprintf(stderr, "-%c unknown\n", argv[i][1]);
		usage:
		    fprintf(stderr,
			    "%s [-D[D]] [[-f] <file>] [-i <prefix>] [-x <fs> [<prefix>]] [-r <prefix>]\n",
			    argv[0]);
		    fprintf(stderr, "\t[-d <prefix>] [-debug] [-nodebug] [-X <prefix>]\n");
		    fprintf(stderr, "\t[-xl <fs> [<prefix>]]\n");
		    exit(1);
	    }
	} else if (ReadConfigFile(argv[i])) {
	    daemon = 1;
	}
    }
    
#ifdef MEM_TRACE
    /*
     * Set heap debugging based on debug flag
     */
    if (debug) {
	malloc_debug(2);
    } else {
	malloc_debug(1);
    }
#endif

    if (daemon) {
	if (!Lst_IsEmpty(delete)) {
	    fprintf(stderr, "Warning: -d ignored in daemon mode\n");
	}
	if (printem) {
	    fprintf(stderr, "Warning: -p ignored in daemon mode\n");
	}
	
	BeFiendish();
    } else {
	/*
	 * Tell daemon about new things to export/import and things to
	 * blow away.
	 */
	LstNode	    	ln;	/* For traversing prefixes list */
	struct timeval	retry;	/* Retry interval for Rpc_Call */
	Rpc_Stat	status;	/* Status of call */
	struct sockaddr_in sin;	/* Address of local server */
	int 	    	estat;	/* Status with which to exit */

	estat = 0;		/* Assume hunky-dory */

	/*
	 * Set up address to contact daemon on local machine.
	 */
	sin.sin_family = AF_INET;
	sin.sin_port = htons(PREFIX_PORT);
	sin.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	
	/*
	 * Retransmit every second...
	 */
	retry.tv_sec = 1;
	retry.tv_usec = 0;
	
	/*
	 * Create calling socket
	 */
	prefixSock = Rpc_UdpCreate(FALSE, 0);
	if (prefixSock < 0) {
	    perror("Rpc_UdpCreate");
	    exit(1);
	}

	/*
	 * Let the export module tell the local daemon what to export, since
	 * all its data are hidden.
	 */
	Export_Send(&sin);

	/*
	 * All the prefixes we recorded need to be forward to the proper
	 * procedure in the local daemon.
	 */
	for (ln = Lst_First(prefixes); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    pp = (Prefix *)Lst_Datum(ln);
	    
	    if (!Export_IsExported(pp->path)) {
		char	*buf;
		int 	pathlen = strlen(pp->path);
		int 	optlen = strlen(pp->options);

		buf = (char *)malloc(pathlen + 1 + optlen + 1);
		strcpy(buf, pp->path);
		strcpy(buf+pathlen+1, pp->options);
		
		status = Rpc_Call(prefixSock, &sin,
				  (pp->flags & PREFIX_ROOT) ?
				  PREFIX_IMPORT_ROOT : PREFIX_IMPORT,
				  pathlen+1+optlen+1, (Rpc_Opaque)buf,
				  0, (Rpc_Opaque)NULL,
				  2, &retry);

		if (status != RPC_SUCCESS) {
		    if (status == DUPLICATE_PREFIX) {
			fprintf(stderr, "already importing %s\n", pp->path);
			estat++;
		    } else {
			fprintf(stderr, "couldn't import %s: %s\n", pp->path,
				Rpc_ErrorMessage(status));
			estat++;
		    }
		}
	    } else {
		fprintf(stderr, "exporting %s, so can't import it too",
			pp->path);
		estat++;
	    }
	}

	/*
	 * Tell the local daemon to delete any prefixes we were asked to
	 * delete.
	 */
	for (ln = Lst_First(delete); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    char	*prefix = (char *)Lst_Datum(ln);
	    char	response[128];

	    status = Rpc_Call(prefixSock, &sin,
			      PREFIX_DELETE,
			      strlen(prefix) + 1, (Rpc_Opaque)prefix,
			      sizeof(response), (Rpc_Opaque)response,
			      2, &retry);
	    if (status != RPC_SUCCESS) {
		fprintf(stderr, "couldn't delete %s: %s\n", prefix,
			Rpc_ErrorMessage(status));
		estat++;
	    } else if (strcmp(response, "Ok") != 0) {
		fprintf(stderr, "couldn't delete %s: %s\n", prefix,
			response);
		estat++;
	    }
	}

	/*
	 * Tell the local daemon to stop exporting any prefixes we were asked
	 * to hide.
	 */
	for (ln = Lst_First(noex); ln != NILLNODE; ln = Lst_Succ(ln)) {
	    char    	*prefix = (char *)Lst_Datum(ln);
	    char    	response[1024];

	    status = Rpc_Call(prefixSock, &sin,
			      PREFIX_NOEXPORT,
			      strlen(prefix) + 1, (Rpc_Opaque)prefix,
			      sizeof(response), (Rpc_Opaque)response,
			      2, &retry);
	    if (status != RPC_SUCCESS) {
		fprintf(stderr, "Couldn't revoke %s: %s\n", prefix,
			Rpc_ErrorMessage(status));
		estat++;
	    } else if (strcmp(response, "Ok") != 0) {
		fprintf(stderr, "Couldn't revoke %s: %s\n",
			prefix, response);
		estat++;
	    }
	}

	/*
	 * Change the debugging state now if requested.
	 */
	if (debugon || debugoff || quiet) {
	    long    state =
		(debugon ? PREFIX_DEBUG_SERVER : 0) |
		    (quiet ? 0 : PREFIX_DEBUG_SEARCH);

	    status = Rpc_Call(prefixSock, &sin,
			      PREFIX_DEBUG,
			      sizeof(state), (Rpc_Opaque)&state,
			      0, (Rpc_Opaque)NULL,
			      2, &retry);
	    if (status != RPC_SUCCESS) {
		fprintf(stderr, "couldn't turn %s debugging: %s\n",
			debugon ? "on" : "off",
			Rpc_ErrorMessage(status));
	    }
	}
	
	/*
	 * If want to see all the prefixes, do that now.
	 */
	if (printem) {
	    if (printhost != 0) {
		struct hostent	*he;

		he = gethostbyname(printhost);
		if (he == NULL) {
		    fprintf(stderr,
			    "unknown host %s; can't print its prefix tables",
			    printhost);
		    estat++;
		} else if (he->h_addrtype != AF_INET) {
		    fprintf(stderr,
			    "cannot get internet address for host %s",
			    printhost);
		    estat++;
		} else if (he->h_addr_list[1] != 0) {
		    int n;

		    for (n = 0; he->h_addr_list[n] != 0; n++) {
			printf("Trying %s...\n",
			       InetNtoA(*(struct in_addr *)he->h_addr_list[n]));
			bcopy(he->h_addr_list[n],
			      &sin.sin_addr,
			      sizeof(sin.sin_addr));
			if (PrintPrefix(&sin)) {
			    break;
			}
		    }
		} else {
		    bcopy(he->h_addr_list[0],
			  &sin.sin_addr,
			  sizeof(sin.sin_addr));
		    PrintPrefix(&sin);
		}
	    } else {
		PrintPrefix(&sin);
	    }
	}

	exit(estat);
    }
}
