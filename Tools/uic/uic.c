/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  UIC -- Initialization
 * FILE:	  uic.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	main
 *
 * DESCRIPTION:
 *	Main module for UIC. Symbol handling, etc.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: uic.c,v 2.10 97/06/25 19:18:46 cthomas Exp $";
#endif lint

#include    <config.h>
#include    "uic.h"
#include    "sttab.h"
#include    <stdio.h>

#include    <stdarg.h>
#include    <compat/file.h>

#include    <compat/string.h>
#include    <compat/stdlib.h>
#if defined(unix)
#include    <sys/time.h>
#include    <sys/resource.h>
#else
#include    <time.h>
#endif
#include    <localize.h>

#include    <malloc.h>
#include    <stdlib.h>
#include    "symbol.h"

FILE		  *yyin;
FILE		  *output;

char		inFile[100] = "";

char  		*outFile = "uic.out";

int		yyerrors = 0;

int		symdebug=0;
int		outdebug=0;
int		uicdebug=0;
int		outcomments=0;
int		localize=0;
int		localizationWarning = 0;    /* Warning flag for localization */
int		localizationRequired = 0;   /* lastChunk needs localized ? */
int             uniqueCount = 1;            /* for making for symbolic names */


int	    	dbcsRelease = 0;

Symbol *firstResource = NullSymbol;	/* First resource in chain */

Symbol *processResource;		/* Process resource (one and only) */

static void ParseArgs (int argc, char **argv);

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
    va_list args;

    va_start(args,fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    fprintf(stderr, "\nUsage: uic [-2cdopDIRW] <file>\n");

    exit(1);
}


/***********************************************************************
 *				Output
 ***********************************************************************
 * SYNOPSIS:	  Send output to our output file.
 * CALLED BY:	  yyparse
 * RETURN:	  Nothing
 * SIDE EFFECTS:  well...
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
Output(char *fmt, ...)
{
    va_list args;

    va_start(args,fmt);
    vfprintf(output, fmt, args);
    va_end(args);
}

void
OutputChar(char c)
{
    putc(c, output);
}


/***********************************************************************
 *				uicerror
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
/*VARARGS1*/
void
uicerror(Symbol *sym, char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

    if (sym != NullSymbol) {
	fprintf(stderr, "In object '%s': ", sym->name);
    } else {
	fprintf(stderr, "Error: ");
    }

    vfprintf(stderr, fmt, args);
    va_end(args);

    putc('\n', stderr);

    yyerrors++;
}


/***********************************************************************
 *				Abort
 ***********************************************************************
 * SYNOPSIS:	  Abort with error message
 * CALLED BY:	  all
 * RETURN:	  Nothing
 * SIDE EFFECTS:  well...
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
Abort(char *fmt, ...)
{
    va_list args;

    fprintf(stderr, "Internal error: ");

    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    fprintf(stderr, "\n");
    fflush(stderr);
    unlink(outFile);
    exit(-1);
}


/***********************************************************************
 *				FatalError
 ***********************************************************************
 * SYNOPSIS:	  Abort with error message
 * CALLED BY:	  all
 * RETURN:	  Nothing
 * SIDE EFFECTS:  well...
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
FatalError(char *fmt, ...)
{
    va_list args;

    fprintf(stderr, "Fatal error: ");

    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    fprintf(stderr, "\n");
    fflush(stderr);
    unlink(outFile);
    exit(-1);
}


/***********************************************************************
 *				UniqueName
 ***********************************************************************
 * SYNOPSIS:	  Make a unique identifier
 * CALLED BY:	  misc
 * RETURN:	  Name (entered in string table)
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/
char *
UniqueName(void)
{
    char temp[50];

    sprintf(temp, "_uic_%d", uniqueCount);
    uniqueCount++;
    return( String_Enter(temp, strlen(temp)) );
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
void
main(int argc, char **argv)
{
    /*
     * We don't pay attention to malloc errors.
     */
    malloc_noerr(1);

    ParseArgs(argc, argv);

    Symbol_Init();
    Scan_Init();			/* Uses symbol stuff */
    Parse_Init();			/* Uses symbol stuff */

    if (yyparse()) {
	printf("\n\nError reading input file\n");
	yyerrors++;
    }
    if (yyerrors) {
	printf("\n\n%d errors found\n", yyerrors);
	unlink(outFile);
        exit(yyerrors);
    }

    if (uicdebug) {
	fprintf(stderr, "Parse successful, starting semantic checks...\n");
    }

    DoSemanticChecks();

    if (yyerrors) {
	fprintf(stderr, "\n\n%d errors found\n", yyerrors);
	unlink(outFile);
        exit(yyerrors);
    }

    if (uicdebug) {
	fprintf(stderr, "Semantic checks, starting output...\n");
    }

    DoOutput();

    if (yyerrors) {
	fprintf(stderr, "\n\n%d errors found\n", yyerrors);
	unlink(outFile);
	exit(yyerrors);
    }
    if(localize){
#if defined(EXTERNAL_LOCALIZATION_FILE)
	Localize_DumpLocalizations();
#endif
    }

#if defined(unix) || defined(_WIN32) || defined(_LINUX)
    (void) pclose(yyin);
#else
    (void) fclose(yyin);
#endif

#if defined(unix)
    if (uicdebug) {
	struct rusage self, child;
	int ps;
	double i, j;

	getrusage(RUSAGE_SELF, &self);
	getrusage(RUSAGE_CHILDREN, &child);

	i = self.ru_utime.tv_sec + (double) self.ru_utime.tv_usec/1000000;
	j = child.ru_utime.tv_sec + (double) child.ru_utime.tv_usec/1000000;
	fprintf(stderr, "User time (uic): %.3f, (total) %.3f\n",i, i+j);

	i += self.ru_stime.tv_sec + (double) self.ru_stime.tv_usec/1000000;
	j += child.ru_stime.tv_sec + (double) child.ru_stime.tv_usec/1000000;
	fprintf(stderr, "Total time (uic): %.3f, (total) %.3f\n",i, i+j);

	ps = getpagesize();
	fprintf(stderr, "Max RSS (uic): %ld, (total) %ld\n", ps*self.ru_maxrss,
		ps*(self.ru_maxrss + child.ru_maxrss));
    }
#endif

    exit(0);
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
static void
ParseArgs(int argc, char **argv)
{
    int	    	ac;
    char	*argString = (char *)malloc(1);
    char    	*argStringPtr = argString;
    int	    	argStringLen = 1;
    char	command[2000];
#if defined(unix)
    char	*pp = "/lib/cpp";
#elif defined(_WIN32) || defined(_LINUX)
    char	*pp = "uicpp";
#else
    char        *pp = "uicpp";
#endif
    char	*inFile = NULL;

    *argStringPtr = '\0';

    for (ac = 1; ac < argc; ac++) {
	if (argv[ac][0] == '-') {
	    switch (argv[ac][1]) {
		case 'o':
		    if (ac + 1 == argc) {
			Usage("-o requires a filename argument");
			/*NOTREACHED*/
		    }
		    outFile = argv[ac+1];
		    ac++;
		    break;
		case 'd': {
#ifdef YYDEBUG
		    extern
#endif
			int yydebug;
#ifdef LEXDEBUG
		    extern
#endif
			int lexdebug;

		    if (argv[ac][2] == '\0') {
			lexdebug=yydebug=symdebug=outdebug=uicdebug = 1;
		    } else {
			char *ptr;

			for (ptr = &(argv[ac][2]); *ptr != '\0'; ptr++) {
			    switch (*ptr) {
				case 'y' : {
				    yydebug = 1;   break;
				}
				case 'l' : {
				    lexdebug = 1;   break;
				}
				case 's' : {
				    symdebug = 1;   break;
				}
				case 'o' : {
				    outdebug = 1;   break;
				}
				case 'u' : {
				    uicdebug = 1;   break;
				}
			    }
			}
		    }
		    break;
		}
		case 'c' :{
		    outcomments = 1;
		    break;
		}
		case 'l': {
		    localize = 1;
		    break;
		}
		case '2': {
		    dbcsRelease = 1;
		    break;
		}
		case 'p' :{
		    if (ac + 1 == argc) {
			Usage("-p requires a command name argument");
			/*NOTREACHED*/
		    }
		    pp = argv[ac+1];
		    ac++;
		    break;
		}
		case 'I' : case 'D' : case 'R' : {
		    int need = ((argStringPtr-argString) +
				strlen(argv[ac]) + 2);

		    if (need > argStringLen)
		    {
			int asl = argStringPtr-argString;

			while (argStringLen < need) {
			    argStringLen *= 2;
			}

			argString = (char *)realloc(argString, argStringLen);
			argStringPtr = argString + asl;
		    }

		    strcpy(argStringPtr, argv[ac]);
		    argStringPtr = argString + need-2;
		    *argStringPtr++ = ' ';
		    *argStringPtr = '\0';

		    break;
		}
	        case 'W': {
		    char *warningFlag = argv[ac] + 2;
		    if ( strlen(warningFlag) > 0 ){
			if ( strcmp(warningFlag, "localize") == 0 ){
			    localizationWarning = 1;
			} else {
			    Usage("-W doesn't recognize \"%s\"", warningFlag);
			}
		    }
		    break;
		}
		default:
		    Usage("Argument %c unknown", argv[ac][1]);
		    /*NOTREACHED*/
	    }
	} else {
	    if (inFile != NULL) {
		Usage("Only one input file allowed");
		/*NOTREACHED*/
	    }
	    inFile = argv[ac];
	}
    }

	/* Open input file */

    if (inFile == NULL) {
	Usage("Need a file on which to work");
	/*NOTREACHED*/
    }
    /* the following doesn't seem to work for win32, so I'll leave the
       fopen in like it uses in dos, (same at pclose) */
#if defined(unix) || defined(_WIN32) || defined(_LINUX)
    strcpy(command, pp);
    strcat(command, " ");
    strcat(command, argString);
    strcat(command, inFile);
    if (uicdebug) {
	fprintf(stderr,"Invoking pre-processor via '%s'\n", command);
    }
    yyin = popen(command, "r");
#else
    yyin = fopen(inFile, "r");
#endif
    if (yyin == NULL) {
	Usage("Cannot open pipe");
	/*NOTREACHED*/
    }

	/* Open output file */

    if (strcmp(outFile, "-") == 0) {
	if (uicdebug) {
	    fprintf(stderr,"Using stdout for output\n");
	}
	output = stdout;
    } else {
	if (uicdebug) {
	    fprintf(stderr,"Opening file '%s' for output\n", outFile);
	}
	output = fopen(outFile, "w");
	if (output == NULL) {
	    perror(outFile);
	    exit(1);
	}
    }

#if defined(EXTERNAL_LOCALIZATION_FILE)
    /*FALSE means resource names are NOT all caps*/
    Localize_Init(outFile,FALSE);
#endif
}



/***********************************************************************
 *				malloc_err
 ***********************************************************************
 * SYNOPSIS:		Write an error message w/o using malloc
 * CALLED BY:		malloc and friends
 * RETURN:		if 'fatal' is non-zero, exits 1.
 * SIDE EFFECTS:	None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
void
malloc_err(int 	fatal,
	   char	*str,
	   int 	len)
{
    write(2, str, len);
    if (fatal) {
	(void)unlink(outFile);
	exit(1);
    }
}
