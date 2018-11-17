/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	pmake stub for DOS
MODULE:		pmake
FILE:		pmake.c

AUTHOR:		Joon Song, Nov 18, 1993

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/18/93   	Initial version.

DESCRIPTION:
	Source code for the brain-dead PMAKE stub.

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <io.h>
#include <dir.h>
#include <process.h>
#include <errno.h>

#define FALSE		0
#define TRUE		~FALSE
#define STDOUT		1
#define BUFFER_SIZE	4096
#define NCOM		32

#define exitError(x)	{fprintf(stderr, x); exit(-1);}

static char bmake[] = "bmake";
static char noExecuteFlag[] = "-u";
static char *dosCommands[NCOM] = {
	"break",   "call",   "cd",   "chcp", "chdir", "cls",
	"copy",    "ctty",   "date", "del",  "dir",   "echo",
	"erase",   "exit",   "for",  "md",   "mkdir", "path",
	"pause",   "prompt", "rd",   "rem",  "ren",   "rename",
	"replace", "rmdir",  "set",  "time", "type",  "ver",
	"verify",  "vol" };

/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    brain-dead pmake
 * CALLED BY:	    user
 * RETURN:	    error code
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	Joon	11/18/93   	Initial Revision
 *
 ***********************************************************************/
void main (int argc, char *argv[], char **envp)
{
    FILE *bmakefile, *argfile;
    int	 i, cmp, oldstdout, redir, buflen, bmake_status, execute = TRUE;
    char *bmakefname = "TMPXXXXXX", *argfname = "TMPXXXXXX";
    char buffer[BUFFER_SIZE], *buffer_copy, *cp, *av[255];

    /*
     * Check arguments to see if we should just print out commands instead
     * of executing them.
     */
    for (i = 1; i < argc && execute; i++)
	if (*argv[i] == '-')
	    for (cp = argv[i]; *cp != NULL && execute; cp++)
		switch (*cp) {
		    case 'U':
		    case 'u':
		        execute = FALSE;
		    case 'D':			/* -D<var>   */
		    case 'I':			/* -I<dir>   */
		    case 'd':			/* -d<flags> */
		    case 'f':			/* -f<file>  */
		    case 'p':			/* -p<num>   */
		        cp = NULL;		/* next argv */
		}

    /*
     * Spawn 'bmake' with output redirected to a temporary file.
     */
    av[0] = bmake;
    av[1] = noExecuteFlag;

    for (i = 1; i <= argc; i++) {
	av[i+1] = argv[i];
    }

    mktemp(bmakefname);
    redir = open(bmakefname, O_CREAT | O_RDWR, S_IREAD | S_IWRITE);
    if (redir == -1) {
	remove(bmakefname);
	exitError("*** Error code -1\n\nUnable to open temporary file.\n");
    }

    oldstdout = dup(STDOUT);
    dup2(redir, STDOUT);
    close(redir);

    bmake_status = spawnvpe(P_WAIT, av[0], av, envp);
    dup2(oldstdout, STDOUT);
    close(oldstdout);

    if (bmake_status == -1)
	if (errno == ENOENT) {
	    remove(bmakefname);
	    exitError("*** Error code -1\n\nUnable to spawn bmake.\n");
	}

    if ((bmakefile = fopen(bmakefname, "rb")) != NULL) {
	mktemp(argfname);

	while (fgets(buffer, BUFFER_SIZE, bmakefile) != NULL) {
	    printf("%s", buffer);
	    if (execute == FALSE || bmake_status != 0 || buffer[0] == '`')
		continue;

	    for (cp = buffer; !isspace(*cp); cp++);
	    *cp = NULL;

	    for (i = 0; i < NCOM; i++) {
		if ((cmp = stricmp(buffer, dosCommands[i])) == 0) {
		    *cp = ' ';
		    if (system(buffer)) {
			fclose(bmakefile);
			remove(bmakefname);
			exitError("*** Error code -1\n\nStop.\n");
		    }
		    break;
		} else if (cmp < 0) {
		    break;
		}
	    }

	    if (cmp != 0) {
		*cp++ = ' ';
		if ((buflen = strlen(buffer)) > 127) {
		    argfile = fopen(argfname, "w");
		    fwrite(cp, 1, strlen(cp), argfile);
		    fclose(argfile);
		    *cp++ = '@';
		    strcpy(cp, argfname);
		    buflen = strlen(buffer);
		}

		for (i = 0, cp = buffer; cp < buffer+buflen;) {
		    for (; cp < buffer+buflen; cp++)
			if (!isspace(*cp)) break;
		    av[i++] = cp;
		    for (; cp < buffer+buflen; cp++)
			if (isspace(*cp)) break;
		    *cp++ = NULL;
		}
		av[i] = NULL;

		if (spawnvpe(P_WAIT, av[0], av, envp) != 0) {
		    fclose(bmakefile);
		    remove(bmakefname);
		    remove(argfname);
		    exitError("*** Error code -1\n\nStop.\n");
		}
	    }
	}
	fclose(bmakefile);
	remove(bmakefname);
	remove(argfname);
    }

    exit (0);
}	/* End of main.	*/
