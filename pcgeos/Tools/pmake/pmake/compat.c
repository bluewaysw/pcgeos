/*-
 * compat.c --
 *	The routines in this file implement the full-compatibility
 *	mode of PMake. Most of the special functionality of PMake
 *	is available in this mode. Things not supported:
 *	    - different shells.
 *	    - friendly variable substitution.
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
 *	Compat_Run	    Initialize things for this module and recreate
 *	    	  	    thems as need creatin'
 */
#include <config.h>
#ifndef lint
static char *rcsid = "$Id: compat.c,v 1.11 96/06/24 15:04:59 tbradley Exp $ SPRITE (Berkeley)";
#endif lint

#include    <stdio.h>
#include    <sys/types.h>
#include    <compat/file.h>

#if defined __BORLANDC__
#	include    <signal.h>
#	include    <errno.h>
#	include	   <process.h>
#	include	   <time.h>
#	include	   <compat/string.h>
#       include    <stdlib.h>
extern int errno;
#elif defined(__WATCOMC__)

#if defined(_LINUX)
#	include    <sys/wait.h>
#endif

#	include    <signal.h>
#	include    <errno.h>
#	include	   <process.h>
#	include	   <time.h>
#	include	   <compat/string.h>
#       include    <stdlib.h>
extern int errno;
#elif defined(__HIGHC__)
#	include    <signal.h>
#	include    <errno.h>
#	include	   <process.h>
#	include	   <time.h>
#	include <dos.h>
#	define malloc hc_malloc
#	define calloc hc_calloc
#	define free hc_free
#	define realloc hc_realloc
#	undef malloc
#	undef calloc
#	undef free
#	undef realloc
#	include	   <compat/string.h>
#	include	   "t:\src\spawn\spawno.h"
#	include	   <malloc.h>
extern volatile int errno;
#elif defined(unix)
#	include    <sys/signal.h>
#	include    <sys/wait.h>
#	include    <sys/errno.h>
extern int errno;
#endif
#include    <ctype.h>
#include    "make.h"

#if defined (unix)
#      include    "rmt.h"
#endif /* unix */

#include    "pmjob.h"
#include    <compat/stdlib.h>
/*
 * The following array is used to make a fast determination of which
 * characters are interpreted specially by the shell.  If a command
 * contains any of these characters, it is executed by the shell, not
 * directly by us.
 */

#if !defined(unix)
char	__spawn_xms, __spawn_ems;
# if defined(_WIN32)
static char argfile[MAX_PATH];
# else
static char argfile[13] = "TMXXXXXXX";
# endif
#endif

static char         meta[256];

static GNode	    *curTarg = NILGNODE;
static GNode	    *ENDNode;
static int  	    CompatRunCommand(char *cmd, GNode *gn);

/*-
 *-----------------------------------------------------------------------
 * CompatInterrupt --
 *	Interrupt the creation of the current target and remove it if
 *	it ain't precious.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The target is removed and the process exits. If .INTERRUPT exists,
 *	its commands are run first WITH INTERRUPTS IGNORED..
 *
 *-----------------------------------------------------------------------
 */
static void
CompatInterrupt (int signo)
{
    GNode   *gn;

    if (DEBUG(MAKE)) {
      printf ("CompatInterrupt called.\n");
    }

    /* remove temp argument files necessary to pass more than 128
     * chars on DOS command line
     */
#if !defined (unix)
    if (curTarg != NILGNODE) {
	if (unlink(argfile) != 0)
	{
	    perror ("unlink (argfile)");
	}
    }
#endif /* !defined (unix) */

    if ((curTarg != NILGNODE) && !Targ_Precious (curTarg)) {
	char 	  *file = Var_Value (TARGET, curTarg);

	if (unlink (file) == SUCCESS) {
	    printf ("*** %s removed\n", file);
	}
    }

    /*
     * Run .INTERRUPT only if hit with interrupt signal
     */
    if (signo == SIGINT) {
	gn = Targ_FindNode(".INTERRUPT", TARG_NOCREATE);
	if (gn != NILGNODE) {
	    Lst_ForEach(gn->commands, CompatRunCommand, (ClientData)gn);
	}
    }
    exit (0);
}

#if !defined(unix) && !defined(_LINUX)
/*********************************************************************
 *			CompatMakeFileArgs
 *********************************************************************
 * SYNOPSIS: put a string of space separated arguments into an argument file
 * CALLED BY:	CompatRunCommand
 * RETURN:  pointer to filename
 * SIDE EFFECTS: creates a temp file on the disk contaings the arguments
 *	    	 the string passed in is changed, so that the string of
 *	    	 arguments is replaced by @filename where filename is the
 *	    	 name of a file containing the arguments
 *
 *	    	 since different PC tools have different formats for the
 *	    	 response files, I will do some special cases here for the
 *	    	 ones that I know about, I will default to the PC/GEOS
 *	    	 format if the command is an unknown one.
 *
 * STRATEGY: break up the string at the spaces
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	7/15/92		Initial version
 *
 *********************************************************************/

static void
CompatMakeFileArgs(char *args, char *filename)
{
    FILE    *fp;
#if defined(_WIN32)
    TCHAR   temppath[MAX_PATH];
#endif

    /*
     * first, we must create a temporary file on the disk
     * use the name TMP##### where ##### is a random number
     */

    while(!isspace(*args++));
#if defined(_WIN32)
    /* use windows-supplied temp file support */
    GetTempPath(MAX_PATH, temppath);
    GetTempFileName(temppath, "TMP", 0, filename);
#else
# if defined(__HIGHC__)
    strcpy(filename,"TMXXXXXX");
# endif
    mktemp(filename);
# if defined(__HIGHC__)
    /* add an extension so that programs that assume one won't put on there
     * own
     */
    strcpy(filename+8, ".000");
# endif
#endif
    fp = fopen(filename, "w"); /* overwrite, if it happens to exist */
    fwrite(args, 1, strlen(args), fp);
    fclose(fp);
	/*
	 * now stick in a @filename over the old list of args
	 */
    *args++ = '@';
    strcpy(args, filename);
}
#endif

/*-
 *-----------------------------------------------------------------------
 * CompatRunCommand --
 *	Execute the next command for a target. If the command returns an
 *	error, the node's made field is set to ERROR and creation stops.
 *
 *      cmd is the command to execute.  gn is the node from which the
 *      command came.
 *
 * Results:
 *	0 if the command succeeded, 1 if an error occurred.
 *
 * Side Effects:
 *	The node's 'made' field may be set to ERROR.
 *
 *-----------------------------------------------------------------------
 */
static int
CompatRunCommand (char *cmd, GNode *gn)
{
    char    *cmdStart;          /* Start of expanded command */
    register char    *cp;
    volatile Boolean silent;    /* Don't print command */
    volatile Boolean errCheck; 	/* Check errors */
#if defined(unix) || defined(_LINUX)
    int 	  reason;   	/* Reason for child's death */
				/* locally */
    ReturnStatus     stat;	/* Status of fork */
    int	    	     numWritten;/* Number of bytes written for error message */
    volatile Boolean local;    	/* TRUE if command should be executed */
    int	    	     cpid;    	/* Child actually found */
#else
    char 	  set_cmd[] = "pmake_set";
    extern char   **environ;
#endif
    int	    	  mystatus;   	/* Description of child's death */
    LstNode 	  cmdNode;  	/* Node where current command is located */
    char **av;	             	/* Argument vector for thing to exec */
    int	    	  argc;	    	/* Number of arguments in av or 0 if not
				 * dynamically allocated */

    silent = ((gn->type & OP_SILENT) != 0);
    errCheck = !(gn->type & OP_IGNORE);

    cmdNode = Lst_Member (gn->commands, (ClientData)cmd);
    cmdStart = Var_Subst (cmd, gn, FALSE);

    /*
     * Str_BreakString will return an argv with a NULL in av[1], thus causing
     * execvp to choke and die horribly. Besides, how can we execute a null
     * command? In any case, we warn the user that the command expanded to
     * nothing (is this the right thing to do?).
     */
		 
    if (*cmdStart == '\0') {
	if (!noWarnings) {
	    Error("%s expands to empty string", (unsigned long)cmd, 0, 0);
	}
	return(0);
    } else {
	cmd = cmdStart;
    }
    Lst_Replace (cmdNode, (ClientData)cmdStart);

    if ((gn->type & OP_SAVE_CMDS) && (gn != ENDNode)) {
	(void)Lst_AtEnd(ENDNode->commands, (ClientData)cmdStart);
	return(0);
    } else if (strcmp(cmdStart, "...") == 0) {
	gn->type |= OP_SAVE_CMDS;
	return(0);
    }

    while ((*cmd == '@') || (*cmd == '-'))
    {
	if (*cmd == '@')
	{
	    silent = TRUE;
	}
	else
	{
	    errCheck = FALSE;
	}
	cmd++;
    }

    /*
     * Print the command before echoing if we're not supposed to be quiet for
     * this one. We also print the command if -n given.
     */

    if (!silent || noExecute)
    {
	printf ("%s\n", cmd[0]=='`' ? cmd + 1 : cmd);
	fflush(stdout);
    }

    /*
     * If we're not supposed to execute any commands, this is as far as
     * we go...
     */
    if (noExecute)
    {
	return (0);
    }

#if defined(unix) || defined(_LINUX)
    /*
     * Search for meta characters in the command. If there are no meta
     * characters, there's no need to execute a shell to execute the
     * command.
     */
    for (cp = cmd; !meta[(int)(*cp)]; cp++)
    {
	continue;
    }

    if (*cp != '\0')
    {
	/*
	 * If *cp isn't the null character, we hit a "meta" character and
	 * need to pass the command off to the shell. We give the shell the
	 * -e flag as well as -c if it's supposed to exit when it hits an
	 * error.
	 */
	static char	*shargv[4] = { "/bin/sh" };

	shargv[1] = (errCheck ? "-ec" : "-c");
	shargv[2] = cmd;
	shargv[3] = (char *)NULL;
	av = (char**) shargv;
	argc = 0;
    }
    else
    {
	/*
	 * No meta-characters, so no need to exec a shell. Break the command
	 * into words to form an argument vector we can execute.
	 * Str_BreakString sticks our name in av[0], so we have to
	 * skip over it...
	 */
	av = (char**) Str_BreakString(cmd, " \t", "\n", TRUE, &argc);
	av += 1;
    }

    /*
     * If the job has not been marked unexportable, tell the Rmt module we've
     * got something for it...local is set TRUE if the job should be run
     * locally.
     */
    /*if (!(gn->type & OP_NOEXPORT)) {
      printf("Rmt_Begin\n");
			//local = !Rmt_Begin(av[0], av, gn);
		} else*/    {
			local = TRUE;
    }


    /*
     * Fork and execute the single command. If the fork fails, we abort.
     */
    cpid = vfork();
    if (cpid < 0) {
	Fatal("Could not fork", 0, 0);
    }
    if (cpid == 0) {
	if (local) {
	    int result = execvp(av[0], av);
	    numWritten = write (2, av[0], strlen (av[0]));
	    numWritten = write (2, ": not found\n", sizeof(": not found"));
	} else {
	    //Rmt_Exec(av[0], av, FALSE);
	}
	exit(1);
    } else if (argc != 0) {
	/*
	 * If there's a vector that needs freeing (the command was executed
	 * directly), do so now, being sure to back up the argument vector
	 * to where it started...
	 */
	av -= 1;
	Str_FreeVec (argc, av);
    }

    /*
     * The child is off and running. Now all we can do is wait...
     */
    while (1) {
	int 	  id = 0;  /*I initialize to 0 to do away with */
	                   /*uninitialization warnings         */

	if (!local) {
	    //id = Rmt_LastID(cpid);
	}

	while ((stat = wait(&reason)) != cpid) {
	    if (stat == -1 && errno != EINTR) {
		break;
	    }
	}

	if (!local) {
      //Rmt_Done(id);
	}


	if (stat > -1) {
	    if (WIFSTOPPED(reason)) {
		mystatus = WSTOPSIG(reason);		/* stopped */
	    } else if (WIFEXITED(reason)) {
		mystatus = WEXITSTATUS(reason);		/* exited */
		if (mystatus != 0) {
		    printf ("*** Error code %d", mystatus);
		}
	    } else {
		mystatus = WTERMSIG(reason);		/* signaled */
		printf ("*** Signal %d", mystatus);
	    }


	    if (!WIFEXITED(reason) || (mystatus != 0)) {
		if (errCheck) {
		    gn->made = ERROR;
		    if (keepgoing) {
			/*
			 * Abort the current target, but let others
			 * continue.
			 */
			printf (" (continuing)\n");
		    }
		} else {
		    /*
		     * Continue executing commands for this target.
		     * If we return 0, this will happen...
		     */
		    printf (" (ignored)\n");
		    mystatus = 0;
		}
	    }
	    break;
	} else {
	    Fatal ("error in wait: %d", stat, 0);
	    /*NOTREACHED*/
	}
    }
#endif

#if !defined(unix) && !defined(_LINUX)
    /*
     * first take the arguments and put them into a temp file (1 per line)
     * we must do this as DOS limits us to 128 characters on the command
     * line
     */

    if (signal(SIGINT, SIG_IGN) != SIG_IGN) {
        signal(SIGINT, CompatInterrupt);
    }

       /* pmake_set is a special flag used because microf*ck 6.0 does not
	* take argument files, but wants things in an environment variable
	*/

    if (!strncmp(cmd, set_cmd, sizeof(set_cmd)-1) &&
	isspace(cmd[sizeof(set_cmd)-1]))
    {
	char *newenv;

	/*
	 * Locate the start of the env = string by skipping whitespace
	 * following the set_cmd.
	 */
	for (cp = cmd + sizeof(set_cmd); isspace(*cp); cp++) {
	    ;
	}
	/*
	 * Allocate a copy of the string, since putenv requires the memory
	 * it's given to remain valid forever.
	 */
	MallocCheck(newenv, strlen(cp)+1);

	strcpy(newenv, cp);
	/*
	 * Set the thing into the environment.
	 */
	putenv(newenv);
	mystatus = 0;		/* "Command" executed ok */
    }
    else
    {
	if (strlen(cmd) > 127)
	{
	    strcpy(argfile, "TMXXXXXX");
	    CompatMakeFileArgs(cmd, argfile);
	}

    /* set up variables for the spawn library
     * turn off the use of xms and ems to save it for
     * whatever we are running
     */
	__spawn_xms = __spawn_ems = 0;

       	if (cmd[0] == '`')
	{
	    /* this charater tells us that we must goes through the
	     * command interpreter, so use the system call and hope it works
	     */

	    mystatus = system(cmd+1);
	}
	else
	{
	    av = Str_BreakString(cmd, " \t", "\n", FALSE, &argc);
	    av += 1;
	    mystatus = spawnvpe(P_WAIT, av[0], av, environ);
	}
	unlink(argfile);
	/*
	 * Free the argument vector, being sure to back it up to where it
	 * actually started.
	 */
	if (cmd[0] != '`')
	{
	    av -= 1;
	    Str_FreeVec (argc, av);
	}

	if (mystatus != 0)
	{
	    printf("*** Error code %d", mystatus);

	    if (errCheck) {
		gn->made = ERROR;
		if (keepgoing) {
		/*
		 * Abort the current target, but let others
		 * continue.
		 */
		printf (" (continuing)\n");
		}
	    } else {
		/*
		 * Continue executing commands for this target.
		 * If we return 0, this will happen...
		 */
		printf (" (ignored)\n");
		mystatus = 0;
	    }
	}
    }

    signal(SIGINT, SIG_DFL);
#endif

    return (mystatus);


}

/*-
 *-----------------------------------------------------------------------
 * CompatMake --
 *	Make a target.
 *
 * Results:
 *	0
 *
 * Arguments:
 *      GNode *gn  : The node to make
 *      GNode *pgn : Parent to abort if necessary
 *
 * Side Effects:
 *	If an error is detected and not being ignored, the process exits.
 *
 *-----------------------------------------------------------------------
 */

int
CompatMake (GNode *gn, GNode *pgn)
{
    if (gn->type & OP_USE) {
	Make_HandleUse(gn, pgn);
    } else if (gn->made == UNMADE) {
	/*
	 * First mark ourselves to be made, then apply whatever transformations
	 * the suffix module thinks are necessary. Once that's done, we can
	 * descend and make all our children. If any of them has an error
	 * but the -k flag was given, our 'make' field will be set FALSE again.
	 * This is our signal to not attempt to do anything but abort our
	 * parent as well.
	 */
	gn->make = TRUE;
	gn->made = BEINGMADE;
	Suff_FindDeps (gn);
	Lst_ForEach (gn->children, CompatMake, (ClientData)gn);
	if (!gn->make) {
	    gn->made = ABORTED;
	    pgn->make = FALSE;
	    return (0);
	}

	if (Lst_Member (gn->iParents, (ClientData)pgn) != (LstNode)NILLNODE) {
	    Var_Set (IMPSRC, Var_Value(TARGET, gn), pgn);
	}

	/*
	 * All the children were made ok. Now cmtime contains the modification
	 * time of the newest child, we need to find out if we exist and when
	 * we were modified last. The criteria for datedness are defined by the
	 * Make_OODate function.
	 */
	if (DEBUG(MAKE)) {
	    printf("examining %s...", gn->name);
	}
	if (! Make_OODate(gn)) {
	    gn->made = UPTODATE;
	    if (DEBUG(MAKE)) {
		printf("up-to-date.\n");
	    }
	    return (0);
	} else if (DEBUG(MAKE)) {
	    printf("out-of-date.\n");
	}

	/*
	 * If the user is just seeing if something is out-of-date, exit now
	 * to tell him/her "yes".
	 */
	if (queryFlag) {
	    exit (-1);
	}

	/*
	 * We need to be re-made. We also have to make sure we've got a $?
	 * variable. To be nice, we also define the $> variable using
	 * Make_DoAllVar().
	 */
	Make_DoAllVar(gn);

	/*
	 * Alter our type to tell if errors should be ignored or things
	 * should not be printed so CompatRunCommand knows what to do.
	 */
	if (Targ_Ignore (gn)) {
	    gn->type |= OP_IGNORE;
	}
	if (Targ_Silent (gn)) {
	    gn->type |= OP_SILENT;
	}

	if (Job_CheckCommands (gn, Fatal)) {
	    /*
	     * Our commands are ok, but we still have to worry about the -t
	     * flag...
	     */
	    if (!touchFlag) {
		curTarg = gn;
		Lst_ForEach (gn->commands, CompatRunCommand, (ClientData)gn);
		curTarg = NILGNODE;
	    } else {
		Job_Touch (gn, (gn->type & OP_SILENT) != 0);
	    }
	} else {
	    gn->made = ERROR;
	}

	if (gn->made != ERROR) {
	    /*
	     * If the node was made successfully, mark it so, update
	     * its modification time and timestamp all its parents. Note
	     * that for .ZEROTIME targets, the timestamping isn't done.
	     * This is to keep its state from affecting that of its parent.
	     */
	    gn->made = MADE;
#ifndef RECHECK
	    /*
	     * We can't re-stat the thing, but we can at least take care of
	     * rules where a target depends on a source that actually creates
	     * the target, but only if it has changed, e.g.
	     *
	     * parse.h : parse.o
	     *
	     * parse.o : parse.y
	     *  	yacc -d parse.y
	     *  	cc -c y.tab.c
	     *  	mv y.tab.o parse.o
	     *  	cmp -s y.tab.h parse.h || mv y.tab.h parse.h
	     *
	     * In this case, if the definitions produced by yacc haven't
	     * changed from before, parse.h won't have been updated and
	     * gn->mtime will reflect the current modification time for
	     * parse.h. This is something of a kludge, I admit, but it's a
	     * useful one..
	     *
	     * XXX: People like to use a rule like
	     *
	     * FRC:
	     *
	     * To force things that depend on FRC to be made, so we have to
	     * check for gn->children being empty as well...
	     */
	    if (!Lst_IsEmpty(gn->commands) || Lst_IsEmpty(gn->children)) {
		gn->mtime = now;
	    }
#else
	    /*
	     * This is what Make does and it's actually a good thing, as it
	     * allows rules like
	     *
	     *	cmp -s y.tab.h parse.h || cp y.tab.h parse.h
	     *
	     * to function as intended. Unfortunately, thanks to the stateless
	     * nature of NFS (and the speed of this program), there are times
	     * when the modification time of a file created on a remote
	     * machine will not be modified before the stat() implied by
	     * the Dir_MTime occurs, thus leading us to believe that the file
	     * is unchanged, wreaking havoc with files that depend on this one.
	     *
	     * I have decided it is better to make too much than to make too
	     * little, so this stuff is commented out unless you're sure it's
	     * ok.
	     * -- ardeb 1/12/88
	     */
	    if (noExecute || Dir_MTime(gn) == 0) {
		gn->mtime = now;
	    }
	    if (DEBUG(MAKE)) {
		printf("update time: %s\n", Targ_FmtTime(gn->mtime));
	    }
#endif
	    if (!(gn->type & OP_EXEC)) {
		pgn->childMade = TRUE;
		Make_TimeStamp(pgn, gn);
	    }
	} else if (keepgoing) {
	    pgn->make = FALSE;
	} else {
	    printf ("\n\nStop.\n");
	    exit (1);
	}
    } else if (gn->made == ERROR) {
	/*
	 * Already had an error when making this beastie. Tell the parent
	 * to abort.
	 */
	pgn->make = FALSE;
    } else {
	if (Lst_Member (gn->iParents, (ClientData)pgn) != (LstNode)NILLNODE) {
	    Var_Set (IMPSRC, Var_Value(TARGET, gn), pgn);
	}
	switch(gn->made) {
	    case BEINGMADE:
		Error((char *)"Graph cycles through %s\n", (unsigned long)gn->name, 0, 0);
		gn->made = ERROR;
		pgn->make = FALSE;
		break;
	    case MADE:
		if ((gn->type & OP_EXEC) == 0) {
		    pgn->childMade = TRUE;
		    Make_TimeStamp(pgn, gn);
		}
		break;
	    case UPTODATE:
		if ((gn->type & OP_EXEC) == 0) {
		    Make_TimeStamp(pgn, gn);
		}
		break;

	    default:
		break;
	}
    }

    return (0);
}

/*-
 *-----------------------------------------------------------------------
 * Compat_Run --
 *	Initialize this mode and start making.
 *
 *      targs is the list of target nodes to re-create
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	Guess what?
 *
 *-----------------------------------------------------------------------
 */
void
Compat_Run(Lst targs)
{
    char    	  *cp = NULL;	    /* Pointer to string of shell meta-characters */
    GNode   	  *gn = NULL;	    /* Current root target */
    int	    	  errors;           /* Number of targets not remade due to errors */

    if (signal(SIGINT, SIG_IGN) != SIG_IGN) {
	signal(SIGINT, (void (*)(int))CompatInterrupt);
    }
    if (signal(SIGTERM, SIG_IGN) != SIG_IGN) {
	signal(SIGTERM, (void (*)(int))CompatInterrupt);
    }
#if defined(unix) || defined(_LINUX)
    for (cp = "#=|^(){};&<>*?[]:$`\\\n"; *cp != '\0'; cp++) {
        meta[(int) (*cp)] = 1;
    }
#endif
#if defined(unix)
    if (signal(SIGHUP, SIG_IGN) != SIG_IGN) {
	signal(SIGHUP, (void (*)(void))CompatInterrupt);
    }
    if (signal(SIGQUIT, SIG_IGN) != SIG_IGN) {
	signal(SIGQUIT, (void (*)(void))CompatInterrupt);
    }

#else
	/* in DOS there are less meta characters to worry about */
    for (cp = ">`"; *cp != '\0'; cp++) {
	meta[*cp] = 1;
    }
#endif
    /*
     * The null character serves as a sentinel in the string.
     */
    meta[0] = 1;

    ENDNode = Targ_FindNode(".END", TARG_CREATE);
    /*
     * If the user has defined a .BEGIN target, execute the commands attached
     * to it.
     */
    if (!queryFlag) {
	gn = Targ_FindNode(".BEGIN", TARG_NOCREATE);
	if (gn != NILGNODE) {
	    Lst_ForEach(gn->commands, CompatRunCommand, (ClientData)gn);
	}
    }

    /*
     * For each entry in the list of targets to create, call CompatMake on
     * it to create the thing. CompatMake will leave the 'made' field of gn
     * in one of several states:
     *	    UPTODATE	    gn was already up-to-date
     *	    MADE  	    gn was recreated successfully
     *	    ERROR 	    An error occurred while gn was being created
     *	    ABORTED	    gn was not remade because one of its inferiors
     *	    	  	    could not be made due to errors.
     */
    errors = 0;
    while (!Lst_IsEmpty (targs)) {
	gn = (GNode *) Lst_DeQueue (targs);
	CompatMake (gn, gn);

	if (gn->made == UPTODATE) {
	    printf ("`%s' is up to date.\n", gn->name);
	} else if (gn->made == ABORTED) {
	    printf ("`%s' not remade because of errors.\n", gn->name);
	    errors += 1;
	}
    }

    /*
     * If the user has defined a .END target, run its commands.
     */
    if (errors == 0) {
	Lst_ForEach(ENDNode->commands, CompatRunCommand, (ClientData)gn);
    }
}
