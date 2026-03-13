/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  GFS (GEOS file system)
 * FILE:	  gfs.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	main
 *
 * DESCRIPTION:
 *	Main module for gfs.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: gfs.c,v 1.10 98/05/14 12:48:13 cthomas Exp $";

#endif lint

#include    "gfs.h"

#define OPEN_PERMISSION_FLAGS (S_IREAD | S_IWRITE | S_IRUSR | S_IWUSR | S_IRGRP | S_IWGRP | S_IROTH | S_IWOTH)

#if defined(_MSDOS) 
char	originalDir[100];
#endif

int	alignSize = 0;

/*
 * Base at which to store the directories, and following which will come
 * localizable files.
 */
long	dirBase = sizeof(GFSFileHeader) + DIR_ENTRY_REAL_SIZE + sizeof(GFSExtAttrs); 
/*
 * Base at which to write non-localizable files. If 0, then there is no
 * distinction between localizable and non-localizable files.
 */
long	fileBase = 0;

/*
 * Debugging variables
 */
Boolean debug = FALSE;

/*
 * Description
 */

char *description = "";

/*
 * checksum type
 */
int dataOnlyChecksum = 0;

/*
 * DBCS flag
 */
Boolean doDbcs = FALSE;

/*
 * Tree of files to be marked hidden.
 */
static Special	rootEnt = { ".", 0, 0 };
Special	    	*root = &rootEnt;

static dword	limit = 0;

#define DEFAULT_ALIGNMENT 16384

/***********************************************************************
 *
 * FUNCTION:	gfschdir
 *
 * DESCRIPTION:	...
 *
 * CALLED BY:	INTERNAL
 *
 * STRATEGY:
 *
 * KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	4/19/93		Initial Revision
 *
 ***********************************************************************/
#if !defined(_MSDOS)
#define gfschdir chdir
#else
int
gfschdir(const char *path)
{
  /*    char *cp;*/

    /*
     * Look for "Z:..." (always at least two bytes, a non-null and a null,
     * even in the shortest thing we'll get)
     */
    if (path[1] == ':') {
	unsigned    ndrives;	/* junk */
	unsigned    drive;

	if (islower(path[0])) {
	    drive = path[0]-'a'+1;
	} else {
	    drive = path[0]-'A'+1;
	}
	_dos_setdrive(drive, &ndrives);
	_dos_getdrive(&ndrives);
	if (drive != ndrives) {
	    gfserror("Error setting drive %c\n", path[0]);
	}
	return(chdir(path+2));
    } else {
	return(chdir(path));
    }
}
#endif

/***********************************************************************
 *				gfserror
 ***********************************************************************
 * SYNOPSIS:	  Print an error message with the current line #
 * CALLED BY:	  yyparse() and others
 * RETURN:	  Nothing
 * SIDE EFFECTS:  A message be printed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
void gfserror(char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

    fprintf(stderr, "Error: ");

    vfprintf(stderr,fmt,args);
    putc('\n', stderr);

    va_end(args);

#if defined(_MSDOS)
    (void) gfschdir(originalDir);
#endif

    exit(1);
}
/***********************************************************************
 *				Usage
 ***********************************************************************
 * SYNOPSIS:	  Print out an error and usage message and exit
 * CALLED BY:	  main
 * RETURN:	  No
 * SIDE EFFECTS:  Process exits.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
void
Usage(char *fmt, ...)
{
    va_list 	  args;

    va_start(args, fmt);

    vfprintf(stderr,fmt,args);

    fprintf(stderr, 
     "\nUsage:\n"
     "    gfs create [-x] [-2] [-a#] [-dDESCRIPTION] [-vNAME] (-hFILE)* -lSIZE destFile sourceTree\n"
     "\n"
     "\tThe \"create\" subcommand is used to create a GFS file system\n"
     "\tgiven a directory tree and a destination file.  Possible flags\n"
     "\tare:\n"
     "\n"
     "\t\t-a#\tThe destination file system is intended for\n"
     "\t\t\tuse in a paged environment (ROM) where some\n"
     "\t\t\tdata structures need to be aligned.  # is the\n"
     "\t\t\talignment size.  \"-a\" with no argument uses\n"
     "\t\t\tthe default alignment size of 16384.\n"
     "\n"
     "\t\t-bBASE\tSpecify the start of the directory structure\n"
     "\t\t\t(Combined with the -l option, allows creation of\n"
     "\t\t\tGFS images which share many files, but have a few\n"
     "\t\t\tdifferences localized to one part of the image)\n"
     "\n"
     "\t\t-dDESC\tEmbed the string DESC in the destination file\n"
     "\t\t\tsystem as a description.  The maximum\n"
     "\t\t\tdescription size is 100 characters.\n"
     "\n"
     "\t\t-vNAME\tMake the name of the volume NAME\n"
     "\n"
     "\t\t-hFILE\tMark the named file (it's a path under\n"
     "\t\t\tsourceTree) hidden. You may give this argument\n"
     "\t\t\tmultiple times.\n"
     "\n"
     "\t\t-lFILE\tMark the named file or directory (it's a path\n"
     "\t\t\tunder sourceTree) localizable, so that it will be added\n"
     "\t\t\tto the GFS after the directory structure. You may give\n"
     "\t\t\tthis argument multiple times.\n"
     "\n"
     "\t\t-sSIZE\tSpecifies the maximum size (as a hex\n"
     "\t\t\tnumber) for the filesystem.\n"
     "\n"
     "\t\t-x\tSpecifies that the checksum should be based on only the\n"
     "\t\t\tnumber) data in the files (not on such things as date stamps).\n"
     "\n"
     "\t\t-2\tSpecifies that a DBCS image should be made.\n"
     "\n"
     "    [[not implemented]] gfs explode sourceFile destTree\n"
     "\n"
     "\tThe \"explode\" subcommand is used to take an existing GFS file\n"
     "\tsystem and break it up into a tree of files.\n"
     "\n"
     "    gfs list sourceFile\n"
     "\n"
     "\tThe \"list\" subcommand is used to list the files in an\n"
     "\texisting GFS file system.\n"
	    );

#if defined(_MSDOS)
    (void) gfschdir(originalDir);
#endif

    exit(1);
    va_end(args);
}


/***********************************************************************
 *				MarkFile
 ***********************************************************************
 * SYNOPSIS:	    Create a Special record for the passed file, setting
 *	    	    the passed flag within the record for later processing
 *	    	    when creating the filesystem.
 * CALLED BY:	    (INTERNAL) ParseArgs
 * RETURN:	    nothing
 * SIDE EFFECTS:    various "Special" records will be
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/11/93		Initial Revision
 *
 ***********************************************************************/
static void
MarkFile(const char *file, int flag)
{
    const char    *cp;
    Special  *cur, **prevPtr;
    const char    *startNext;
    
    if (debug) {
	printf("MARK: %s\n", file);
    }

    cur = root;
    
    for (cp = file; *cp != '\0'; cp = startNext) {
	const char *start;
	int 	len;
	
	/*
	 * Find the end of this component.
	 */
	for (start = cp;
	     *cp != '\\' && *cp != '/' && *cp != '\0';
	     cp++)
	{
	    ;
	}
	/*
	 * Figure the start of the next component (cp if hit
	 * end of the string, or cp+1 if just hit a separator)
	 */
	if (*cp == '\0') {
	    startNext = cp;
	} else {
	    startNext = cp+1;
	}
	
	/*
	 * Now look within the current directory for an entry
	 * whose name matches the component.
	 */
	len = cp-start;
	for (prevPtr = &cur->firstChild;
	     *prevPtr != 0;
	     prevPtr = &cur->nextSib)
	{
	    cur = *prevPtr;
	    if ((strncmp(start, cur->name, len) == 0) &&
		(cur->name[len] == '\0'))
	    {
		break;
	    }
	}
	
	if (*prevPtr == 0) {
	    /*
	     * Didn't find one, so allocate an entry for this
	     * beast + its name & link it in.
	     */
	    Special *parent;

	    parent = cur;
	    *prevPtr = cur = (Special *)malloc(sizeof(Special) + len + 1);
	    cur->nextSib = 0;
	    cur->firstChild = 0;
	    cur->flags = parent->flags & SF_LOCAL;
	    /*
	     * Point to the space allocated after the record for
	     * the name and copy in the current component.
	     */
	    cur->name = (char *)(cur+1);
	    strncpy(cur->name, start, len);
	    cur->name[len] = '\0';
	}
    }
    cur->flags |= flag;
}

static void
PrintSpecialTree(Special *root, int level)
{
    Special *child;
    
    printf("%*s%s%s  %s%s\n", level, "", root->name,
	   root->firstChild ? "/" : "",
	   root->flags & SF_HIDDEN ? "H" : "",
	   root->flags & SF_LOCAL ? "L" : "");

    for (child = root->firstChild; child != 0; child = child->nextSib) {
	PrintSpecialTree(child, level+2);
    }
}

/***********************************************************************
 *				ParseArgs
 ***********************************************************************
 * SYNOPSIS:	  Parse command line arguments
 * CALLED BY:	  main
 * RETURN:	  No
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/
int
ParseArgs(
	  int	*argc,
	  char	***argv,
	  char	**command,
	  char	*description,
	  char	**volumeName)
{
    int	    	ac;

    *command = NULL;

    for (ac = 1; ac < *argc; ac++) {
	if ((*argv)[ac][0] == '-') {
	    switch ((*argv)[ac][1]) {
	        case 'a':
		    if (strlen((*argv)[ac]) == 2) {
			alignSize = DEFAULT_ALIGNMENT;
		    } else {
		    	alignSize = atoi(&((*argv)[ac][2]));
		    }
		    break;

		case 'd': {
		    char *cp;

		    strcpy(description, &(*argv)[ac][2]);
		    for (cp = description; *cp != '\0'; cp++);
		    *cp = '\032';
		    break;
		}
		case 'v':
		    *volumeName = &(*argv)[ac][2];
		    break;

		case 'D':
		    printf("Debugging turned on.\n");
		    debug = TRUE;
		    break;
		case 'x':
		    dataOnlyChecksum = TRUE;
		    break;
	        case 's':
		    sscanf(&(*argv)[ac][2], "%lx", &limit);
		    break;
	        case 'h':
		    MarkFile(&(*argv)[ac][2], SF_HIDDEN);
		    break;
	        case 'l':
		    MarkFile(&(*argv)[ac][2], SF_LOCAL);
		    break;
	        case 'b':
		    fileBase = dirBase;
		    sscanf(&(*argv)[ac][2], "%lx", &dirBase);
		    break;
		case '2':
		    doDbcs = TRUE;
		    break;
		default:
		    Usage("Argument %c unknown\n", (*argv)[ac][1]);
		    /*NOTREACHED*/
		}
	} else {
	    if (*command == NULL) {
		*command = (*argv)[ac];
	    } else {
		/*
		 * Return the number of the first parameter
		 */
		if (debug) {
		    printf("TREE OF SPECIAL FILES:\n");
		    PrintSpecialTree(root, 0);
		}
		return(ac);
	    }
	}
    }
    if (debug) {
	printf("TREE OF SPECIAL FILES:\n");
	PrintSpecialTree(root, 0);
    }

    return(ac);
}

/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	  Guess what?
 * CALLED BY:	  UNIX
 * RETURN:	  No
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/
void main(
	  int	argc,
	  char	**argv)
{
    int argIndex;
    char *command;
    char *volumeName = "GFS";
    GFSFileHeader fileHeader = {
	"GFS:",
	"",
	"\015\012\015\012",
	"\032",
	SwapWord(GFS_PROTO_MAJOR), SwapWord(GFS_PROTO_MINOR),
    };

#if defined(_MSDOS)
    /*
     * Get the current directory so that we can reset it (DOS is dumb)
     */
    (void) getcwd(originalDir, sizeof(originalDir));
#endif

#if defined(_MSDOS)
    /*
     * if not UNIX, we can't redirect stdout, so send stderr there.
     */
    *stderr = *stdout;
#endif

    argIndex = ParseArgs(&argc, &argv, &command,
			 fileHeader.description, &volumeName);

    if (command == NULL) {
	Usage("");
    }
    if (!strcmp(command, "create")) {
	int destFile;

	if (argc - argIndex != 2) {
	    Usage("Wrong number of arguments\n");
	}

	/*
	 * Create the destination file
	 */
	if ((destFile = open(argv[argIndex],
			     O_BINARY | O_RDWR | O_CREAT | O_TRUNC,
			     OPEN_PERMISSION_FLAGS))
	    == -1) {
	    gfserror("Cannot open output file: %s\n", argv[argIndex]);
	}

	/*
	 * Change to the directory
	 */
	if (gfschdir(argv[argIndex+1])) {
	    gfserror("Cannot change to directory: %s\n", argv[argIndex+1]);
	}

	/*
	 * Let's create us a filesystem
	 */
	CreateGFS(destFile, &fileHeader, volumeName, limit);

	if (close(destFile)) {
	    Usage("Cannot close destination file\n");
	}

	close(destFile);

    } else if (!strcmp(command, "list")) {
	int sourceFile;

	if (argc - argIndex != 1) {
	    Usage("Wrong number of arguments\n");
	}

	/*
	 * Open the source file
	 */
	if ((sourceFile = open(argv[argIndex], O_RDONLY | O_BINARY)) == -1) {
	    gfserror("Cannot open file %s\n", argv[argIndex]);
	}

	ListGFS(sourceFile);

	close(sourceFile);

    } else {
	Usage("Unrecognized command: %s\n", command);
    }

#if defined(_MSDOS)
    (void) gfschdir(originalDir);
#endif

    exit(0);
}
