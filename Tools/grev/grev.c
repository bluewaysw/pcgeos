/********************************************************************
*
*	Copyright (c) GeoWorks 1991 -- All Rights Reserved
*
* 	PROJECT:	GEOS Tools
* 	MODULE:         Compilation tools
* 	FILE:		grev.c
*
*	AUTHOR:		jimmy lefkowitz
*
*	REVISION HISTORY:
*
*	Name	Date		Description
*	----	----		-----------
*	jimmy	8/19/92		Initial version
*   jacob   9/9/96		Win32 port
*	RainerB	01/15/2023	Usage() added, command help added
 *
*	DESCRIPTION: this file contains code for the DOS version of grev
*
*	$Id: grev.c,v 1.1 92/10/27 17:34:47 jimmy Exp $
*
*********************************************************************/

/*********************************************************************
The program 'grev' manipulates the <geode>.rev file.  Its syntax is:

    grev  <command> <file> [<comment>]
	If the -u option is ommitted, the environment variable USER is used.

Commands are:

    grev  new <file> [<comment>]
	Create a new '.rev' file with protocol revision 0.0 and release
	number 0.0.0.0.

    grev info <file>
	Display information about the given revision file.

    grev getproto <file>
	Output the current protocol number to stdout.

    grev  newprotomajor <file> [<comment>]
	Add a new major protocol number for <file>.
	Adds one line to the <geode>.rev file.  Outputs the new protocol
	   number to stdout.
	'newprotomajor' may be abbreviated as 'NPM'.

    grev  newprotominor <file> [<comment>]
	Add a new minor protocol number for <file>.
	Adds one line to the <geode>.rev file.  Outputs the new protocol
	   number to stdout.
	'newprotominor' may be abbreviated as 'npm'.

    grev  neweng <file> [<comment>]
	Add a new engineering revision for <file>.
	Adds one line to the <geode>.rev file.  Outputs the new revision
	   number to stdout.
	'neweng' may be abbreviated as 'ne'.

    grev  newchange <file> [<comment>]
	Add a new running change revision for <file>.  Adds one line to the
	<geode>.rev file.  Outputs the new revision number to stdout.

    grev  newrev <file> <rev> [<comment>]
	Set the revision for <file> to <rev> where rev is of the form "1.2.3".

	grev help
	Output detailed description.

Instead of a comment a special parameter (either -P or -R) may be passed so
that the output will only be either the Protocol number or the Revision number
this is used by pmake to get at these values

The standard pmake include files call 'grev' and pass information to the
linker with the -R flag, overriding any revision number specified in the
geode parameter file. e.g.

	rev=`grev neweng $(GEODE).rev -s`
	$(LINK) -R $rev $(LINKFLAGS) $(.ALLSRC) -o $(.TARGET)

The linker places the protocol and revision number in several places:
	* the .geo file
	* the .sym file (for version checking by Swat)
	* the .lobj file, if one is created, for recording in any .geo file
	  linked with it.

***************************************************************************/

#include <config.h>
#include <stdlib.h>		/* not compat/stdlib.h (no utils) */
#include <stdio.h>
#include <compat/string.h>
#include <time.h>

#if defined _MSC_VER
#    include <io.h>             /* for mktemp() */
#include <unistd.h>
#define mktemp _mktemp
#else
//#    include <dir.h>		/* for mktemp() */
#include <unistd.h>
#endif /* defined _MSC_VER */

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

typedef	  int 	 Boolean;

#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE 1
#endif

static char *Targ_FmtTime(long time);
static void InsertIntoFileAndExit(char *buf, unsigned bufSize, FILE *fp,
				  char *revFile, char noOutput);

typedef enum {
    NULL_COMMAND,
    NEW_PROTO_MAJOR,
    NEW_PROTO_MINOR,
    NEW_ENG,
    NEW_CHANGE
} SubCommand;

#define EXIT(errstring) {fprintf(stderr, "grev: %s", errstring); \
						Usage(FALSE); \
                         exit(1);}

const char *InvalidRevisionNumber = "invalid revision number, no changes made\n";
const char *InvalidRevisionFile = "invalid revision file\n";

static void Usage(int full);
void WarnNotSaved(char *revFile, char noOutput);


/*********************************************************************
 *			main
 *********************************************************************
 * SYNOPSIS:	main file for grev
 * CALLED BY:	from OS
 * RETURN:	void
 * SIDE EFFECTS: grev file might be altered
 * STRATEGY:	hope and pray
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/19/92		Initial version
 *	RainerB	01/15/2023	Usage() added, 'help' command added
 *
 *********************************************************************/
void
main(int argc, char **argv)
{
    char    *subcmd;		/* which subcommand are we doing */
    char    *revFile;
    char    *branch = "";
    Boolean save = FALSE;	/* write changes to .rev file? */
    FILE    *fp;
    static char buf[4096];	/* buffer holds data to be written to file */
    SubCommand	sc = NULL_COMMAND;
    char    token;
    char    terseOutput = '\0'; /* used by pmake to get output in a
				   * special format */
    char    *extraArg1 = "";	/* some sub-commands use these... */
    char    *extraArg2 = "";
    char    userName[50] = "unknown";

#ifdef _WIN32
    {
	DWORD nSize = sizeof (userName);
	(void) GetUserName(userName, &nSize);
    }
#endif

/*** DEBUG - log any call to grev ****/
#if 0
{
    int	n;
	fp = fopen("D:\\gparam.txt", "at");		// <-- at == append text
	if (fp == NULL) {
	    printf("GREV Debug: GParam.txt not open");
	    exit(1);
	}
	// dump current path to file
	getcwd( buf, 256);
	strcat(buf, ":\n");
	fwrite(buf, strlen(buf), 1, fp);

	// dump parameters to file
	sprintf(buf,"   ");
	for ( n=0; n<argc; n++)
	{
		strcat(buf,argv[n]);
		strcat(buf, "   ");
	}
	strcat(buf, " *\n");
	fwrite(buf, strlen(buf), 1, fp);

	fclose(fp);
}
#endif
/*** DEBUG ENDS ****/

    /*
     * The first 2 words on the command-line must be the subcommand
     * followed by the name of the .rev file.
     */
    if (argc < 2) {
	fprintf(stderr, "grev: no command specified\n");
	Usage(FALSE);
	exit(1);
    }
    subcmd = argv[1];

	/*
	 * If the subcommand is 'help' or similar, output an detailed help.
	 * In this case no rev file is required.
	 */
	if ( strcmp(subcmd, "help") * strcmp(subcmd, "-help") * strcmp(subcmd, "?") * strcmp(subcmd, "-?") == 0 ) {
	Usage(TRUE);
	exit(0);
	}


    if (argc < 3) {
	fprintf(stderr, "grev: no .rev file specified\n");
	Usage(FALSE);
	exit(1);
    }
    revFile = argv[2];

    /*
     * Now process command-line arguments.
     */
    if (argc > 3) {
	char c;

	/*
	 * Account for the fact that we glommed off 2 arguments.
	 */
	argc -= 2;
	argv = &argv[2];

	/*
	 * Process any flags that may come between the
	 * subcommand and its other stuff (comments, new revision
	 * numbers, etc.
	 */
	while ((c = (char) getopt(argc, argv, "sPRB:")) != -1) {
	    switch (c) {
	    case 'P': case 'R':
		terseOutput = c;
		break;
	    case 'B':
		branch = optarg;
		break;
	    case 's':
		save = TRUE;
		break;
	    case '?':
	    Usage(FALSE);
		exit(1);
	    }
	}

	/*
	 * The flags are sometimes followed by more arguments.
	 */
	if (optind < argc) {
	    extraArg1 = argv[optind];
	    if (++optind < argc) {
		extraArg2 = argv[optind];
	    }
	}
    }

#ifdef TEST_ARGS
    printf("sub-command:   %s\n"
	   ".rev file:     %s\n"
	   "terseOutput: %c\n"
	   "branch:        %s\n"
	   "extra arg 1:   %s\n"
	   "extra arg 2:   %s\n",
	   subcmd,
	   revFile,
	   terseOutput,
	   branch,
	   extraArg1,
	   extraArg2);
    exit(0);
#endif /* TEST_ARGS */

    if (strcmp(subcmd, "new") == 0) {
	/*
	 * First see if the file already exists.  If so query the
	 * the user to see if they want to nuke the old one.
	 */
	fp = fopen(revFile, "r");
	if (fp != NULL) {
	    char    c;

	    fclose(fp);
	    printf("File '%s' already exists, do you want to overwrite it? ",
		   revFile);
	    c = (char) getc(stdin);
	    if (c != 'Y' && c != 'y') {
		exit(1);
	    }
	}

	fp = fopen(revFile, "wb");
	if (fp == NULL) {
	    perror(revFile);
	    exit(1);
	}
	sprintf(buf,
		"P 0.0 <%s> <%s> <%s>\n",
		userName, Targ_FmtTime((long)time(NULL)), extraArg1);
	fwrite(buf, strlen(buf), 1, fp);
	sprintf(buf,
		"R 0.0.0.0 <%s> <%s> <%s>\n",
		userName, Targ_FmtTime((long)time(NULL)), extraArg1);
	fwrite(buf, strlen(buf), 1, fp);
	printf("%s revision file created\n", revFile);
	fclose(fp);
	exit(0);
    }

    else if (strcmp(subcmd, "newrev") == 0) {
	unsigned char	*cp;
	int  		dotcount;

	/* make sure the revision number is valid */
	for (cp = (unsigned char *) extraArg1, dotcount = 0; dotcount < 3;) {
	    /* the string between cp and the next dot
	     * had better be an integer */
	   while (*cp != '.' && *cp) {
	       if (*cp < '0' || *cp > '9') {
		   EXIT(InvalidRevisionNumber);
	       }
	       cp++;
	   }
	   dotcount++;
	   if (!(*cp) && dotcount != 3) {
	       EXIT(InvalidRevisionNumber);
	   }

	   if (dotcount < 3) {
	       cp++;
	   }
	}
	if (*cp) {
	    EXIT(InvalidRevisionNumber);
	}
	printf("Updating revision number to %s.0%s%s...",
	       extraArg1,
	       (*branch == '\0') ? "" : " on branch ", branch);
	sprintf(buf,
		"R%s %s.0 <%s> <%s> <%s>\n",
		branch, extraArg1,
		userName, Targ_FmtTime((long)time(NULL)), extraArg2);

	fp = fopen(revFile, "r");
	if (fp == NULL) {
	    perror(revFile);
	    exit(1);
	}
	if (save) {
	    InsertIntoFileAndExit(buf, sizeof (buf), fp, revFile, 0);
	} else {
		WarnNotSaved(revFile, terseOutput);
	    fclose(fp);
	    exit(0);
	}
    }


    /* getproto and info just read from the file without updating it
     * and so are handled separately, here
     */
    else if (strcmp(subcmd, "info") == 0 || strcmp(subcmd, "getproto") == 0) {
	char	type[100] = "";	/* may contain branch, too */
	char	tmp[24];
	int 	protof = 0;	/* have we found the protocol number? */
	int	revf = 0;	/* revision number found? */

	/* if we are only interested in the protocol number then set the
	 * revf flag to 1 so we don't look for the revision number
	 */
	if (strcmp(subcmd, "getproto") == 0) {
	    revf = 1;
	}

	fp = fopen(revFile, "r"); /* #1 */
	if (fp == NULL) {
	    perror(revFile);
	    exit(1);
	}

	while (!protof || !revf) {
	    fscanf(fp, "%s", type);

	    /* if we find the token P and we are looking for the
	     * protocol, AND the branch matches what the user
	     * passes (possibly none...)
	     */
	    if (!protof && *type == 'P' && strcmp(type + 1, branch) == 0) {
		protof = 1;

		fscanf(fp, " %s", tmp);

		/* for pmake we have a special output mode where we just
		 * output the actual protocol number rather than nice
		 * user interface strings
		 */
		if (terseOutput == 'P') {
		    printf("%s\n", tmp);
		} else {
		    printf("Protocol = %s\n", tmp);
		}
	    } else if (*type == 'R' && !revf
		       && strcmp(type + 1, branch) == 0) {
		revf = 1;
		fscanf(fp, " %s", tmp);
		printf("Revision = %s\n", tmp);
	    }

	    /*
	     * Skip trailing stuff.
	     */
	    while (*type != '\n') {
		*type = (char) fgetc(fp);
	    }
	}
	fclose(fp);		/* #1 */
	exit(0);
    }

    if (strcmp(subcmd, "newprotomajor") == 0 || strcmp(subcmd, "NPM") == 0) {
	sc = NEW_PROTO_MAJOR;
	token = 'P';
    }

    if (strcmp(subcmd, "newprotominor") == 0 || strcmp(subcmd, "npm") == 0) {
	sc = NEW_PROTO_MINOR;
	token = 'P';
    }

    if (strcmp(subcmd, "neweng") == 0) || strcmp(subcmd, "ne") == 0) {
	sc = NEW_ENG;
	token = 'R';
    }

    if (strcmp(subcmd, "newchange") == 0) {
	sc = NEW_CHANGE;
	token = 'R';
    }

    if (sc != NULL_COMMAND) {
	char	type[100] = "";
	char	pnstring[40];	/* buffer for storing output string */
	char	*tptr, *tptr2;	/* temporary pointers, ugly I know */
	int 	pn;

	fp = fopen(revFile, "r");
	if (fp == NULL) {
		perror(revFile);
		exit(1);
	}

	while (1) {
	    fscanf(fp, "%s", type);

	    /*
	     * Only pay attention to this line if it matches
	     * the branch specified on the command (or no branch
	     * at all).
	     */
	    if (*type == token && strcmp(type + 1, branch) == 0) {
		fscanf(fp, " %s", pnstring);
		break;
	    }

	    /*
	     * Skip rest of line.
	     */
	    while (*type != '\n') {
		*type = (char) fgetc(fp);
		if (*type == EOF) {
		    EXIT(InvalidRevisionFile);
		}
	    }
	}

	/* ok, we got the first matching string (either a protocol
	 * or a revision number, now increment the number accordingly
	 * and add the new line to the beginning of the file
	 */
	switch (sc) {
	case NEW_PROTO_MAJOR:
	    /* X.Y -> X+1.Y */
	    tptr = strchr(pnstring, '.');
	    *tptr++ = '\0';
	    pn = atoi(pnstring);	/* get the old X value */
	    pn++;	    	    	/* increment it */
	    tptr2 = itoa(pn, buf, 10); /* write it to new string */
	    while(*tptr2++);
	    --tptr2;
	    *tptr2++ = '.';	/* now copy in the .Y part */
	    strcpy(tptr2, tptr);
	    strcpy(pnstring, buf);
	    break;
	case NEW_PROTO_MINOR:
	    /* X.Y -> X.Y+1 */
	    /* pnstring already has the X.Y in it, so just
	     * overwrite the Y with Y+1
	     */
	    tptr = strchr(pnstring, '.');
	    tptr++;
	    tptr2 = tptr;
	    pn = atoi(tptr);    /* get the Y value */
	    pn++;		/* increment it */
	    itoa(pn, tptr2, 10); /* write it to string */
	    break;
	case NEW_ENG:
	    /* W.X.Y.Z -> W.X.Y.Z+1 */
	    /* pnstring already has the W.X.Y.Z in it, so just
	     * overwrite the Z with Z+1
	     */
	    tptr = strrchr(pnstring, '.');
	    tptr++;
	    pn = atoi(tptr);
	    pn++;
	    itoa(pn, tptr, 10);
	    break;

	case NEW_CHANGE:

	    /* W.X.Y.Z -> W.X.Y+1.Z */

	    strcpy(buf, pnstring);
	    tptr = strrchr(pnstring, '.');
	    *tptr++ = '\0';
	    /* we have nuked the last '.', so the next strrchr will
	     * go to the next to last '.' which is what we want
	     */
	    tptr2 = strrchr(pnstring, '.');
	    tptr2++;
	    pn = atoi(tptr2);
	    pn++;
	    tptr2 = strchr(buf, '.');
	    tptr2 = strchr(tptr2+1, '.');
	    tptr2++;
	    tptr2 = itoa(pn, tptr2, 10);
	    while(*tptr2++);
	    --tptr2;
	    *tptr2++ = '.';
	    strcpy(tptr2, tptr);
	    strcpy(pnstring, buf);
	    break;
	}

	if (terseOutput == '\0') {
	    printf("Updating %s number to %s%s%s...",
		   (token == 'R') ? "revision" : "protocol", pnstring,
		   (*branch == '\0') ? "" : " on branch ", branch);
	} else {
	    printf("%s\n", pnstring);
	}
	sprintf(buf,
		"%c%s %s <%s> <%s> <%s>\n",
		token, branch, pnstring,
		userName, Targ_FmtTime((long)time(NULL)), extraArg1);

	/********************************************
	 * at this point pnstring has the new protocol number,
	 * now we must stick this line at the beginning of the
	 * rev file, what a pain! I will create a new file with
	 * the new line, and the rest of the old file, then delete
	 * the old file and rename the new one to the old name
	 ********************************************/

	if (save) {
	    InsertIntoFileAndExit(buf, sizeof (buf), fp, revFile, terseOutput);
	} else {
		WarnNotSaved(revFile, terseOutput);
		fclose(fp);
	    exit(0);
	}
    }

    fprintf(stderr, "grev: unknown command: %s\n", subcmd);
    Usage(FALSE);
    exit(1);
}


/*********************************************************************
 *			InsertIntoFileAndExit
 *********************************************************************
 * SYNOPSIS:	insert the contents in buf in the head of file fp
 * CALLED BY:	main
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	8/19/92		Initial version
 *
 *********************************************************************/
void
InsertIntoFileAndExit(char *buf, unsigned bufSize,
		      FILE *fp, char *revFile, char noOutput)
{
	  int fd;
    FILE    *tmpfp;
    char    filename[13] = "TMPXXXXXX";

    fseek(fp, 0L, SEEK_SET);

#ifdef MY_TEMP
    {
	char    *fn;

	strcpy(filename, "00000000.TMP");
	randomize();
	itoa((int)rand(), (char *)(filename), 10); /* 10 = base 10 */
        /* now get rid of null character added by itoa and
	 * replace it with a zero */
	fn = filename;
	while(*fn++);
	--fn;
	*fn = '0';
    }
#endif

#if defined(_LINUX)
    fd = mkstemp(filename);
		if (fd == -1) {
	perror(filename);
	exit(1);
    }
		tmpfp = fdopen(fd, "wb");
		if (tmpfp == NULL) {
	perror(filename);
	exit(1);
    }
#else
    mktemp(filename);
    tmpfp = fopen(filename, "wb");
    if (tmpfp == NULL) {
	perror(filename);
	exit(1);
    }
#endif
    fwrite(buf, strlen(buf), 1, tmpfp);
    while (1) {
	int rd;

	rd = fread(buf, 1, bufSize, fp);
	fwrite(buf, 1, rd, tmpfp);
	if (rd != bufSize) {
	    break;
	}
    }

    fclose(fp);
    fclose(tmpfp);
    unlink(revFile);
    rename(filename, revFile);
#ifndef _WIN32
    unlink(filename);
#endif
    if (noOutput == '\0') {
	printf("done\n");
    }
    exit(0);
}


/*-
 *-----------------------------------------------------------------------
 * Targ_FmtTime --
 *	Format a modification time in some reasonable way and return it.
 *
 * Results:
 *	The time reformatted.
 *
 * Side Effects:
 *	The time is placed in a static area, so it is overwritten
 *	with each call.
 *
 *-----------------------------------------------------------------------
 */
char *
Targ_FmtTime (long time)
{
    struct tm	  	*parts;
    static char	  	buf[40];
    static char	  	*months[] = {
	"Jan", "Feb", "Mar", "Apr", "May", "Jun",
	"Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    };
    static int          year = 1900; //grev's "year 0"

    parts = localtime(&time);

    year += parts->tm_year;

    sprintf (buf, "%d:%02d:%02d %s %d, %d",
	     parts->tm_hour, parts->tm_min, parts->tm_sec,
	     months[parts->tm_mon], parts->tm_mday, year);
    return(buf);
}

/*********************************************************************
 *			Usage
 *********************************************************************
 * SYNOPSIS:	Display how to use grev
 * CALLED BY:	main
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:	Routine was taken from VC++ version of grev.c and updated
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	??		??			Initial version
 *	RainerB	01/15/2023	Parameter full added
 *
 *********************************************************************/
static void
Usage(int full)
{
	if (!full) {
    puts( "\nUsage:  grev <command> <file> [-PRs] [-B <branch>] [<rev>] [\"comment\"]" );
    puts( "        Allowed commands: new, info, getproto, newprotomajor, newprotominor, ");
    puts( "                          neweng, newchange, newrev, help" );
    puts( "        Must give -s option to commit changes to file." );
    puts( "\nUse 'grev help' for a detailed description." );
    return;
	}

    puts( "\nAll commands take the following general form:" );
    puts( "    grev <command> <file> [-PRs] [-B <branch>] [<rev>] [\"comment\"]" );
    puts( "    -P\t\tProduce terse output of only protocol number (used by pmake)." );
    puts( "    -R\t\tProduces terse output of only release number (used by pmake)." );
    puts( "    -s\t\tSave changes to rev file.  **MUST PASS TO MODIFY .rev FILE**" );
    puts( "    -B <branch>\tUse <branch> rather then trunk." );
    puts( "  ** Note the placement of flags and arguments is unforunately important **\n" );

    puts( "\nCommands are:" );

    puts( "\ngrev new <file> [flags] [\"comment\"]" );
    puts( "    Create a new '.rev' file with protocol revision 0.0 and release\n    number 0.0.0.0." );

    puts( "\ngrev info <file> [flags]" );
    puts( "    Display information about the given revision file." );

    puts( "\ngrev getproto <file> [flags]" );
    puts( "    Output the current protocol number to stdout." );

    puts( "\ngrev newprotomajor <file> [flags] [\"comment\"]\ngrev NPM <file> [flags] [\"comment\"]" );
    puts( "    Add a new major protocol number for <file>.  Adds one line to the .rev" );
    puts( "    file (if '-s' given).  Outputs the new protocol number to stdout." );

    puts( "\ngrev newprotominor <file> [flags] [\"comment\"]\ngrev npm <file> [flags] [\"comment\"]" );
    puts( "    Add a new minor protocol number for <file>.  Adds one line to the .rev" );
    puts( "    file (if '-s' given).  Outputs the new protocol number to stdout." );

    puts( "\ngrev neweng <file> [flags] [\"comment\"]\ngrev ne <file> [flags] [\"comment\"]" );
    puts( "    Add a new engineering revision for <file>.  Adds one line to the .rev" );
    puts( "    file (if '-s' given).  Outputs the new release number to stdout." );

    puts( "\ngrev newchange <file> [flags] [\"comment\"]" );
    puts( "    Add a new running change revision for <file>.  Adds one line to the .rev" );
    puts( "    file (if '-s' given).  Outputs the new release number to stdout." );

    puts( "\ngrev newrev <file> [flags] <rev> [\"comment\"]" );
    puts( "    Set the release number for <file> to <rev> where rev is of the form \"1.2.3\"" );
    puts( "    Must give -s option to commit change to file." );

    puts( "\ngrev help" );
    puts( "    Output detailed help." );

	puts( "\nExample: grev newrev myapp.rev -s 12.7.4 \"New features added\"" );
}

/*********************************************************************
 *			WarnNotSaved
 *********************************************************************
 * SYNOPSIS:	Display a warning that change is not saved to rev file
 * CALLED BY:	main
 * RETURN:	nothing
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	RainerB	01/19/2023	Initial version
 *
 *********************************************************************/
void
WarnNotSaved(char *revFile, char noOutput)
{
	if (noOutput) return;
	printf("\nFlag -s not given. No changes made in ");
	printf(revFile);
	printf("!");
}