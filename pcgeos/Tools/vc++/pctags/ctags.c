/*
 * Copyright (c) 1987 Regents of the University of California.
 * All rights reserved.  The Berkeley software License Agreement
 * specifies the terms and conditions for redistribution.
 *
 *
 * 	$Id: ctags.c,v 1.15 96/07/31 22:22:17 simon Exp $
 */

#ifndef lint
char copyright[] =
"@(#) Copyright (c) 1987 Regents of the University of California.\n\
 All rights reserved.\n";
#endif not lint

#ifndef lint
static char sccsid[] = "@(#)ctags.c	1.2 (Berkeley) 3/16/87";
#endif not lint

#include "ctags.h"
#include "compat/string.h"
#include <stdlib.h>
#undef u_int

#if defined _WIN32
#    include <direct.h> /* for getcwd */
#    include <windows.h>
#endif /* defined _WIN32 */

static void find_entries(char *);
static void init(void);
static void add_filename(void);
static void CallForAllFiles(char *topPath, char **exts);
static int doFile(char *fname);


/*
 * ctags: create a tags file
 */


NODE	*head;			/* head of the sorted binary tree */

				/* boolean "func" (see init()) */
bool	_wht[0177],_etk[0177],_itk[0177],_btk[0177],_gd[0177];

FILE	*inf,			/* ioptr for current input file */
	*outf;			/* ioptr for tags file */

long	lineftell;		/* ftell after getc( inf ) == '\n' */

int	lineno,			/* line number of current line */
	cflag,	    	    	/* -c: look inside comments */
	dflag,			/* -d: non-macro defines */
	tflag,			/* -t: create tags for typedefs */
	wflag,			/* -w: suppress warnings */
	vflag,			/* -v: vgrind style index output */
	xflag;			/* -x: cxref style output */

char	*curfile,		/* current input file name */
	searchar = '/',		/* use /.../ searches by default */
	lbuf[BUFSIZ];

int	pathflag;		// add path to filename
char	*prefix = NULL;
int	prefixLen;
char	*extensions = NULL;

void
main(int argc, char **argv)
{
	extern char	*optarg;		/* getopt arguments */
	extern int	optind;
	static char	*outfile = "tags";	/* output file */
	int	aflag,				/* -a: append to tags */
		uflag,				/* -u: update tags */
		exit_val,			/* exit value */
		step,				/* step through args */
		ch;				/* getopts char */
	char	cmd[512];			/* too ugly to explain */
	char    *listfile = NULL;
	int	nFiles = 0, i;
	FILE    *listFP;
	char	**files;
	char	*extList[64];
	char *fnm = __FILE__, *shfnm;


	pathflag = aflag = uflag = NO;
	while ((ch = getopt(argc,argv,"BFP:acdf:l:p:r:twvx")) != EOF)
	{
		switch((char)ch) {
			case 'B':
				searchar = '?';
				break;
			case 'F':
				searchar = '/';
				break;
			case 'P':
				prefix = optarg;
				prefixLen = strlen( prefix );
				break;
			case 'a':
				aflag++;
				break;
		    	case 'c':
			    	cflag++;
			    	break;
			case 'd':
				dflag++;
				break;
			case 'f':
				outfile = optarg;
				break;
			case 'l':
				listfile = optarg;
				break;
			case 'r':
				extensions = optarg;
				break;
			case 't':
				tflag++;
				break;
			case 'u':
				//uflag++;
				break;
			case 'w':
				wflag++;
				break;
			case 'v':
				vflag++;
			case 'x':
				xflag++;
				break;
			case 'p':
				pathflag++;
				/*
				 * Move 1 arg back so that argument
				 * can be reprocessed as input file
				 * name.
				 */
				--optind;
				break;
			case '?':
			default:
				goto usage;
		}
	}
	argv += optind;
	argc -= optind;
	if ((!argc && !listfile) || (listfile && argc) || (extensions && !argc) || (extensions && listfile)) {
usage:
		
		if ( (shfnm = strrchr( fnm, '\\' )) ||
		     (shfnm = strrchr( fnm, '/' )) )
		     ++shfnm;
		else
		    shfnm = fnm;

		printf( "%s compiled %s under MS Visual C++ _VER: %d\n", shfnm, __TIMESTAMP__, _MSC_VER );
#ifdef _DEBUG
		puts("\t\tDEBUG VERSION");
#endif

		puts("\nUsage: pctags [-BFadctuwvx] [-f tagsfile] [-P prefix] [-p] file ...");
		puts("    Create tags for a listed files.");
		puts("Usage: pctags [-BFadctuwvx] [-f tagsfile] [-P prefix] [-p] [-l listfile]");		
		puts("    Create tags for all files listed in <listfile>.");
		puts("Usage: pctags [-BFadctuwvx] [-f tagsfile] [-P prefix] [-p] [-r ext,ext,...]\n\t\tdir ...");		
		puts("    Create tags for all files found by recursively searching specified dirs");
		puts("    that have the specified extension(s).");
		puts("\nOptions described below.  Some are pretty bizarre and/or outdated.");
		puts("    -B\t\tUse '?' for search char in resulting tags file.");
		puts("    -F\t\tUse '/' for search char in resulting tags file (default).");
		puts("    -a\t\tAppend to tags file.");
		puts("    -d\t\tInclude non-macro defines.");
		puts("    -c\t\tLook inside comments.");
		puts("    -t\t\tCreate tags for typedefs.");
		puts("    -u\t\tUpdate tags.");
		puts("    -w\t\tSuppress warnings.");
		puts("    -v\t\tvgrind style index output.");
		puts("    -x\t\tcxref style output.");
		puts("    -f <file>\tWrite tags to <file> (can be '-' for stdout) (default: 'tags').");
		puts("    -P <pfx>\tPrepend path prefix <pfx> to all filenames in tags file.");
		puts("    -p\t\tAdd current path to all filenames in tags file.");
		exit(1);
	}

	if ( listfile )
	{
	    if ( ! (listFP = fopen( listfile, "r" )) )
	    {
		perror( listfile );
		exit( 1 );
	    }

	    while ( fgets( cmd, 512, listFP ) )
	    {
		nFiles++;
	    }

	    fseek( listFP, 0, SEEK_SET );;

	    files = (char **)malloc(sizeof(char *)*nFiles);

	    for ( step = 0; step < nFiles; ++step )
	    {
		if ( fgets( cmd, 512, listFP ) == NULL )
		{
		    nFiles = step-1;
		    break;
		}

		i = strlen( cmd );
		while ( cmd[i-1] < 32 )
		{
		    cmd[--i] = 0;  // kill lf
		}

		files[step] = (char *)malloc( sizeof( char ) * (i+1) );
		strcpy( files[step], cmd );
	    }

	    fclose( listFP );
	}

	else
	{
	    nFiles = argc;
	    files = argv;
	}

	init();

	if ( ! extensions )
	{
	    for (exit_val = step = 0;step < nFiles;++step)
	    {
		exit_val = doFile( files[step] );
	    }
	}

	else
	{
	    char **pp, *pn, *p;

	    pp = extList;
	    pn = NULL;
	    for ( p = extensions; *p; ++p )
	    {
		if ( *p == ',' )
		{
		    if ( pn )
		    {
			*pn = '\0';
			pn = NULL;
			++pp;
		    }
		}

		else
		{
		    if ( pn )
		    {
			*(pn++) = *p;
		    }

		    else
		    {
			*pp = (char*)malloc( 64 );
			pn = *pp;
			*(pn++) = *p;
		    }
		}
	    }

	    if ( pn )
		*pn = '\0';

	    ++pp;
	    *pp = NULL;

	    for ( step = 0; step < argc; ++step )
	    {
		CallForAllFiles( argv[step], extList );
	    }
	}

	if (head)
	        if (xflag)
			put_entries(head);
		else {
			if (outfile[0] == '-' && outfile[1] == '\0') {
			    outf = stdout;
			    put_entries(head);
			} else {
			    /*
			    if (uflag) {
				for (step = 0;step < argc;step++) {
					(void)sprintf(cmd,"mv %s OTAGS;fgrep -v '\t%s\t' OTAGS >%s;rm OTAGS",outfile,files[step],outfile);
					system(cmd);
				}
				++aflag;
			    }
			    */
			    if (!(outf = fopen(outfile, aflag ? "a" : "w"))) {
				perror(outfile);
				exit(exit_val);
			    }
			    put_entries(head);
			    (void)fclose(outf);
			    /*
			    if (uflag) {
				(void)sprintf(cmd,"sort %s -o %s",outfile,outfile);
				system(cmd);
			    }
			    */
			}
		}
	exit(exit_val);
}

static int
doFile(char *fname)
{
    int exit_val = 0;

    if (!(inf = fopen(fname,"r"))) 
    {
	perror(fname);
	exit_val = 1;
    }
    else 
    {
	char *p;
	for (p = fname; *p; ++p )
	{
	    if ( *p == '\\' )
		*p = '/';
	}
	if ( prefix )
	{
	    char *path;
	    path = malloc( strlen( fname ) + prefixLen + 2 );
	    strcpy( path, prefix );
	    strcat( path, "/" );
	    strcat( path, fname );
	    curfile = path;

	}
	else if (fname[0] != '/' && pathflag)
	{
	    char    *path;
	    path = malloc(256);
	    getcwd(path, 256);
	    strcat(path, "/");
	    strcat(path, fname);
	    curfile = path;
	}
	else
	{
	    curfile = fname;
	}
	find_entries(fname);
	(void)fclose(inf);

    }

    return exit_val;
}

/*
 * init --
 *	this routine sets up the boolean psuedo-functions which work by
 *	setting boolean flags dependent upon the corresponding character.
 *	Every char which is NOT in that string is false with respect to
 *	the pseudo-function.  Therefore, all of the array "_wht" is NO
 *	by default and then the elements subscripted by the chars in
 *	CWHITE are set to YES.  Thus, "_wht" of a char is YES if it is in
 *	the string CWHITE, else NO.
 */
static void
init(void)
{
	register int	i;
	register char	*sp;

	for (i = 0; i < 0177; i++) {
		_wht[i] = _etk[i] = _itk[i] = _btk[i] = NO;
		_gd[i] = YES;
	}
#define	CWHITE	" \f\t\n"
	for (sp = CWHITE; *sp; sp++)	/* white space chars */
		_wht[*sp] = YES;
#define	CTOKEN	" \t\n\"'#()[]{}=-+%*/&|^~!<>;,.:?"
	for (sp = CTOKEN; *sp; sp++)	/* token ending chars */
		_etk[*sp] = YES;
#define	CINTOK	"ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz0123456789"
	for (sp = CINTOK; *sp; sp++)	/* valid in-token chars */
		_itk[*sp] = YES;
#define	CBEGIN	"ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz"
	for (sp = CBEGIN; *sp; sp++)	/* token starting chars */
		_btk[*sp] = YES;
#define	CNOTGD	",;"
	for (sp = CNOTGD; *sp; sp++)	/* invalid after-function chars */
		_gd[*sp] = NO;
}


/***********************************************************************
 *			add_filename
 ***********************************************************************
 * SYNOPSIS:	    Add an entry for the filename
 * CALLED BY:	    find_entries
 * RETURN:	    nothing
 * SIDE EFFECTS:    filename added to tags tree
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	chrisb	12/92		Initial Revision
 *
 ***********************************************************************/
static void
add_filename(void) 
{
    char    *cp;

    /*
     * Search for the last component of the current filename
     */

    strcpy(lbuf,"1");
    cp = rindex(curfile, '/');
    if (cp != NULL) {
	cp++;
    } else {
	cp = curfile;
    }

    /*
     * add it to the tree
     */

    pfnote(cp,0);
}


/*
 * find_entries --
 *	this routine opens the specified file and calls the function
 *	which searches the file.
 */
static void
find_entries(char *file)
{
	register char	*cp;

	lineno = 0;				/* should be 1 ?? KB */
	if (cp = rindex(file, '.')) {
		if (cp[1] == 'l' && !cp[2]) {
			register int	c;

			for (;;) {
				if (GETC(==,EOF))
					return;
				if (!iswhite(c)) {
					rewind(inf);
					break;
				}
			}
#define	LISPCHR	";(["
/* lisp */		if (index(LISPCHR,(char)c)) {
				l_entries();
				return;
			}
/* lex */		else {
				/*
				 * we search all 3 parts of a lex file
				 * for C references.  This may be wrong.
				 */
				toss_yysec();
				(void)strcpy(lbuf,"%%$");
				pfnote("yylex",lineno);
				rewind(inf);
			}
		}
/* yacc */	else if (cp[1] == 'y' && !cp[2]) {
			/*
			 * we search only the 3rd part of a yacc file
			 * for C references.  This may be wrong.
			 */
			toss_yysec();
			(void)strcpy(lbuf,"%%$");
			pfnote("yyparse",lineno);
			y_entries();
		}
/* fortran */	else if (cp[1] == 'f' && !cp[2]) {
			if (PF_funcs())
				return;
			rewind(inf);
		}
		else if (strcmp(cp, ".asm") == 0 ||
			 strcmp(cp, ".def") == 0)
		{
		    add_filename();
		    asm_entries(file);
		    return;
		}
		else if (strcmp(cp, ".goc") == 0 ||
			 strcmp(cp, ".goh") == 0 ||
			 strcmp(cp, ".c") == 0   ||
			 strcmp(cp, ".h") == 0)
		{
		    add_filename();
		    c_entries(1);
		    return;
		}

		/* For these types of files, we don't actually extract
		   symbols from the file -- just its name   */
		else if (strcmp(cp, ".ui") == 0 ||
			 strcmp(cp, ".uih") == 0 ||
			 strcmp(cp, ".gp") == 0)
	        {
		    add_filename();
		}
	}
/* C */	c_entries(0);
}

static void
CallForAllFiles(char *topPath, char **exts)
{
    HANDLE context;
    WIN32_FIND_DATA data;
    char *pathWithWC = malloc( (strlen( topPath ) + 256) * sizeof( char ) );
    char **pp, *p;
    
    strcpy( pathWithWC, topPath );
    strcat( pathWithWC, "\\*.*" );

    context = FindFirstFile( pathWithWC, &data );

    while ( context != INVALID_HANDLE_VALUE )
    {
	if ( (data.dwFileAttributes & (FILE_ATTRIBUTE_HIDDEN |
	    FILE_ATTRIBUTE_SYSTEM)) == 0 )
	{
	    if ( (data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0 )
	    {
		if ( strcmp( data.cFileName, "." ) != 0 &&
		    strcmp( data.cFileName, ".." ) != 0 )
		{
		    // Recurse on this subdirectory!
		    strcpy( pathWithWC, topPath );
		    strcat( pathWithWC, "\\" );
		    strcat( pathWithWC, data.cFileName );
		    
		    CallForAllFiles( pathWithWC, exts );
		}
	    }

	    else
	    {
		if ( (p = strrchr( data.cFileName, '.' )) != NULL )
		{
		    ++p;
		    for ( pp = exts; pp && *pp; ++pp )
		    {
			if ( strcmp( p, *pp ) == 0 )
			{
			    char *permName = (char *)malloc( strlen( topPath ) + strlen( data.cFileName ) + 2 );
			    strcpy( permName, topPath );
			    strcat( permName, "\\" );
			    strcat( permName, data.cFileName );
			    doFile( permName );
			    break;
			}
		    }
		}
	    }
	    
	    if ( ! FindNextFile( context, &data ) )
		break;
	}
    }

    FindClose( context );

    free( pathWithWC );
}
