/***********************************************************************
 *
 * PROJECT:	  GEOS Tools
 * MODULE:	  GOC -- Initialization
 * FILE:	  goc.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	main
 *
 * DESCRIPTION:
 *	Main module for goc.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: goc.c,v 1.38 96/07/09 17:08:54 jimmy Exp $";

#endif lint

/* MetaBlam is ridulously picky about signed/unsigned chars. e.g., unsigned */
/* chars can never equal EOF. */
#if defined(__HIGHC__)
#pragma Off(Char_default_unsigned)
#pragma On(Char_is_rep)
#pragma Off(Behaved)
#endif


#include    <config.h>

#include    "goc.h"
#include    "parse.h"
#include    "stringt.h"
#include    "symbol.h"
#include    <errno.h>
#include    <compat/string.h>
#include    <compat/stdlib.h>
#include    "malloc.h"
#include    "scan.h"		/* for depends.h (sigh) */
#include    "depends.h"		/* for directoryOverride */

#if defined(unix)
#include    <sys/time.h>
#include    <sys/resource.h>
#endif

#include    <fileargs.h>

#include <localize.h>

#if defined(__HIGHC__) && PROFILE
#include "profile.h"
#endif


/* in the arglist @file means we read our args from "file" */
#define FILE_PREFIX "@"
#define FILE_PREFIX_LEN 1


char		inFile[256] = "";

char	    	libraryName[100] = "";
DeflibNode    	*deflibPtr;

char  		*outFile = "goc.out";

char            *asciiStringType = "/* ASCII */char ";
char            *lStringType = "/* L */wchar_t ";
char            *sjisStringType = "/* SJIS */wchar_t ";
char            *defStringType;

int             makeDepend = 0;    /* don't normally ouput dependency info */

int		yyerrors = 0;

int             outputProtoMinorReferences = TRUE;

int	    	dbcsRelease = 0;

/*
 * There's no known way to keep Borland C from complaining that the
 * "oself" and "message" parameters, et. al., to a method aren't used therein,
 * so we kindly issue a "#pragma argsused" before each method, unless
 * explicitly asked not to by setting issueArgsUsedPragma to be FALSE
 */
int             issueArgsUsedPragma = TRUE;

int		symdebug=0;
int		outdebug=0;
int		gocdebug=0;
int	    	mpddebug=0;
int	    	linedebug=0;
int	    	defaultdebug=0;
int		optimizedebug = 0;
int		protodebug = 0;
Boolean         allowCurrentDirSearch = TRUE;

int	    	realLineNumbers = TRUE;
char	    	*replaceSuffix = NULL;
char            *classSegName = NULL;
int	    	declareMessageParams = FALSE;

int 		localize = FALSE;
Boolean		localizationWarning = FALSE;

int	hackFlags = 0;

#if defined(_MSDOS)
/* Non-DOS does not want optimized header files unless -p is passed,
   but in DOS for any compiler, it is fine */
int 		allowOptimize = TRUE;
#else
int 		allowOptimize = FALSE;
#endif

Compilers compiler = COM_HIGHC; 	    	/* type of compiler */

FILE		  *yyin;

Boolean		optimizeThisFile = 	FALSE;
FILE 		*foutput;
FILE		*fdepend =	 	NULL;


char       *dirs[MAX_DIRS];
int            numDirs = 0;

/*
 * This is the compiler's  magic word for putting things in far segments
 * it is set for the default compiler's (HighC) in ParseArgs().
 */

char               *compilerFarKeyword;

/*
 * lmem-string: this is set to "far" for borland, and __far for MSC.
 * It is printed before everything in an lmem block. It is set
 * to blank for the default compiler, HighC, in ParseArgs(), because
 * HighC doesn't need to put lmem chunks in far segments (it just
 * renames the initialized data segment).
 */
char               *lms;

/*
 * compilerFarKeyword (above) will be set to one of these compiler
 * dependent strings.
 */
char *highCFarString = "_far";
char *borlandFarString = "far";
char *microSoftFarString = "__far";

/*
 * This variable contains the compiler dependent type-string  for
 * chunk-things. For example, when we output an object (a chunk),
 * we declare the thing to be "word" for Borland & MetaWare.
 * For microsoft, this thing is a "void __based(void) *".
 *
 * All it really has to be is a thing the same size as a near pointer
 * that we can initialize with the offset of a variable.
 */
char *compilerOffsetTypeName;
char *microsoftOffsetTypeName 	= "ChunkHandle";
char *borlandOffsetTypeName 	= "word";
char *highCOffsetTypeName 	= "word";

/*
 * When a structure needs to have an offset of another object, it
 * casts the address of the object to this type to get the offset.
 */
char *compilerCastForOffset;
char *microsoftCastForOffset 	= "(ChunkHandle)";
char *borlandCastForOffset 	= "(word)(dword)";
char *highCCastForOffset 	= "(word)(dword)";

#ifndef BORLAND_HAS_GOT_THEIR_SHIT_TOGETHER
/*
 *  Borland 3.{0,1}   (the fuckers)
 *  requires that things be arrays if they're to go in far resources,
 *  so we have to scalars into arrays of one element. These strings get
 *  printed after everything that goes into lmem blocks.
 *
 *  Anything that goes into an lmem block should have these things printed
 *  after them too.
 */

char *_ar = "";
char *_op = "";
char *_cl = "";
#endif


/* forward declarations */
extern void DoFinalOutput(void);
void DoProtoMinorChecks(void);
void ParseArgs(int argc, char **argv);




/***********************************************************************
 *				zmalloc
 ***********************************************************************
 * SYNOPSIS:	  allocate memory, exiting on failure
 * CALLED BY:	  main, LexArgs, LoadFileIntoMemory
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
#if 0
char *
zmalloc(unsigned int msize)
{
    char *buf;

    buf = (char *) malloc(msize);
    if (buf == NULL) {
	FatalError("virtual memory exhausted");
    }
    memset(buf,'\0' ,msize);
    return(buf);
}
#endif


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
static void
Usage(char *fmt, ...)
{
    va_list 	  args;

    va_start(args, fmt);

    vfprintf(stderr, fmt, args);

    fprintf(stderr,
	    "\n"
	    "Usage: goc @argfile | goc [args] <file>\n"
	    "Valid arguments:\n"
	    "\t-c[mbh]\t\toutput Microsoft or Borland or HighC output\n"
	    "\t-C<segment>\tput class structures in <segment>\n"
	    "\t-d[ylsoumLOd]\toutput debugging information\n"
	    "\t-D<name>=<val>\tdefine the goc macro <name> to be <val>\n"
	    "\t-D<name>\tdefine the goc macro <name>\n"
	    "\t-I<dir>\t\tspecify include directory\n"
            "\t-I-\t\tturn off relative includes\n"
	    "\t-l\t\tgenerate localization files\n"
	    "\t-L <name>\tspecify library name for class structures\n"
	    "\t-M\t\toutput makedepend information\n"
	    "\t-o <filename>\tspecify output filename\n"
	    "\t-O\t\tUNIX-only, optimize for space with @optimize\n"
	    "\t-p<path>\tdirectory to put/get @optimized files\n"
	    "\t-w\t\tUNIX-only\n"
	    "\t-W<warning>\tenable warning in the specified area\n"
	    "\t-X\t\tdo protominor checking\n"
	    "\t\t\tOR ignore @optimize, PC only\n"
	    "\t-2\t\tuse double-byte characters\n"
	    "\t-2sjis\t\tuse double-byte characters, assume strings are SJIS\n"
	    );

    exit(1);
    va_end(args);
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
 * WARNING:   This is not the only routine that writes directly to the
 *            output file: ScanNoContext does too.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
int
Output(char *fmt, ...)
{
    int len = 0;
    va_list args;

    if (foutput){
	va_start(args, fmt);
	len = vfprintf(foutput,fmt,args);
	va_end(args);
    }
    return len;
}

void
OutputChar(char c)
{
    if(foutput){
	putc(c, foutput);
    }
}


/***********************************************************************
 *				gocerror
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
void
gocerror(Symbol *sym, char *fmt, ...)
{
    va_list	args;

    va_start(args, fmt);

    if (sym != NullSymbol) {
	fprintf(stderr, "In object '%s': ", sym->name);
    } else {
	fprintf(stderr, "Error: ");
    }

    vfprintf(stderr,fmt,args);
    putc('\n', stderr);

    yyerrors++;

    va_end(args);
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

    va_start(args, fmt);
    fprintf(stderr, "Fatal error: ");
    vfprintf(stderr,fmt,args);
    fprintf(stderr, "\n");
    fflush(stderr);
    unlink(outFile);
    exit(-1);
    va_end(args);
}


/***********************************************************************
 *				UniqueName
 ***********************************************************************
 * SYNOPSIS:	  Make a unique identifier, guaranteed to not end
 *                with a letter.
 * CALLED BY:	  misc
 * RETURN:	  Name (entered in string table)
 * SIDE EFFECTS:  Lots
 * NOTES:         Because it doesn't end in a letter, one can generate
 *                other uniquenames from it by adding a letter.
 * STRATEGY:
 *
 ***********************************************************************/

static int uniqueCount = 1;

char *
UniqueName(void)
{
    char temp[50];

    sprintf(temp, "_g%d", uniqueCount);
    uniqueCount++;
    return(String_EnterNoLen(temp));
}


/***********************************************************************
 *				CompilerStartSegment
 ***********************************************************************
 * SYNOPSIS:	  Start a new data segment  (compiler dependent)
 * CALLED BY:	  misc.
 * RETURN:	  void
 * SIDE EFFECTS:  changes the default segment for "objects" to the given
 *                <prefix,name> pair.
 *
 *                This is necessary because chunks get output in three
 *                different segments (for glue's sake). If we didn't change
 *                the segment, they'd all get jammed into one segment
 *                and glue couldn't figure out what started where.
 *
 * STRATEGY:  For the Borland compiler, we can't control the name of the
 *            data segment, only the far segment. That means we have to
 *            declare all of our object pieces as "far" data so they'll
 *            get jammed in the right place.
 *
 *            Also, for with Borland, we can't switch back to the default
 *            segment, because the pragma's busted. Therefore, we might
 *            already be in the given segment, and we don't have to do
 *            anything. If this ever changes, CompilerEndSegment will have
 *            to be updated too.
 *
 *            Also, for Borland and MS, we must initialize the data, or it
 *            will not go into the specified segment; instead it will go
 *            into the udata segment.
 *
 ***********************************************************************/
static char *currentBorlandPrefix = "";
static char *currentBorlandName = "";
void
CompilerStartSegment(char *prefix, char *name)
{
  switch (compiler) {
  case COM_HIGHC :
    Output("pragma Data(Common, \"%s%s\");", prefix, name);
    break;
  case COM_MSC :
     Output("#pragma data_seg(\"%s%s\")\n",prefix,name);
    OutputLineNumber(yylineno, curFile->name);
    break;
  case COM_BORL:
    /*
     * Record the segment  because we never change the far segment to default, and
     * thereby avoid changing it to the same segment (in a row) more than once.
     */
    if(strcmp(currentBorlandPrefix,prefix)||strcmp(currentBorlandName,name)){
      Output("#pragma option -zE%s%s\n",prefix,name);
      OutputLineNumber(yylineno, curFile->name);
      currentBorlandPrefix = String_Enter(prefix,strlen(prefix));
      currentBorlandName = String_Enter(name,strlen(name));
    }
    break;
  }
}


/***********************************************************************
 *				CompilerEndSegment
 ***********************************************************************
 * SYNOPSIS:	  "End" a new data segment.     (compiler dependent)
 * CALLED BY:	  misc.
 * RETURN:	  void
 * SIDE EFFECTS:  attempts to change the default segment for "objects"
 *                back to the default.
 *
 *
 * STRATEGY:   For the Borland compiler, we don't leave the segment.
 *             see explanation in CompilerStartSegment.
 ***********************************************************************/
void
CompilerEndSegment(char *prefix, char *name)
{
    switch (compiler) {
	case COM_HIGHC :
	    Output("pragma Data();");
	    break;
	case COM_MSC :
	         Output("\n#pragma data_seg()\n");
	         OutputLineNumber(yylineno, curFile->name);
	    break;
	  case COM_BORL:
	    /*
	     * This doesn't work with Borland, so do nothing. Because
	     * we never turn 'leave' the segment, we've optimized
	     * CompilerStartSegment to check the name and do nothing if
	     * already in the desired segment
	     *
	     * Output("\n#pragma option -zE*",prefix,name);
	     */

	    break;
    }
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

#if defined(__HIGHC__) && PROFILE
    _profile_setup(argc,argv);
#endif


/* if MSDOS, we can't redirect stdout, so send stderr there. */

#if defined(_MSDOS)
  *stderr = *stdout;
#endif

  /* WARNING: ParseArgs may fetch the args from a file, so argc and argv */
  /*   may not match the internal flags/values that get set.             */
  /*   if it is necessary to use argv and argc after parsing them, maybe */
  /*   it would be best to use global variables.                         */

    Scan_MacroInit();
    ParseArgs(argc, argv);
    Symbol_Init();
    Scan_Init();			/* Uses symbol stuff */

    if (makeDepend){
	printf("%s : %s\n",outFile,inFile);
	fflush(stdout);
    }
    if (yyparse()) {
	printf("\n\nError reading input file\n");
	yyerrors++;
    }

    if (yyerrors && !makeDepend) {
	printf("\n\n%d errors found\n", yyerrors);
	unlink(outFile);
        exit(yyerrors);
    }

    if (gocdebug) {
	fprintf(stderr, "Parse successful, starting semantic checks...\n");
    }

    if (outputProtoMinorReferences) {
	DoProtoMinorChecks();
    } else if (protodebug && !makeDepend) {
	printf("\nProtominor referencing disabled\n");
    }

    DoSemanticChecks();

    if (yyerrors && !makeDepend) {
	fprintf(stderr, "\n\n%d errors found\n", yyerrors);
	unlink(outFile);
        exit(yyerrors);
    }

    if (gocdebug) {
	fprintf(stderr, "Semantic checks, starting output...\n");
    }

    DoFinalOutput();

    if (outputProtoMinorReferences) {
	Symbol_OutputProtoMinorRelocations(inFile);
    }

    if (yyerrors && !makeDepend) {
	fprintf(stderr, "\n\n%d errors found\n", yyerrors);
	unlink(outFile);
	exit(yyerrors);
    }
    if (localize) {
	Localize_DumpLocalizations();
    }

#if defined(unix)
    (void) pclose(yyin);
#else
    fclose(yyin);
#endif

#if defined(unix)
    if (gocdebug) {
	struct rusage self, child;
	int ps;
	double i, j;

	getrusage(RUSAGE_SELF, &self);
	getrusage(RUSAGE_CHILDREN, &child);

	i = self.ru_utime.tv_sec + (double) self.ru_utime.tv_usec/1000000;
	j = child.ru_utime.tv_sec + (double) child.ru_utime.tv_usec/1000000;
	fprintf(stderr, "User time (goc): %.3f, (total) %.3f\n",i, i+j);

	i += self.ru_stime.tv_sec + (double) self.ru_stime.tv_usec/1000000;
	j += child.ru_stime.tv_sec + (double) child.ru_stime.tv_usec/1000000;
	fprintf(stderr, "Total time (goc): %.3f, (total) %.3f\n",i, i+j);

	ps = getpagesize();
	fprintf(stderr, "Max RSS (goc): %ld, (total) %ld\n", ps*self.ru_maxrss,
				ps*(self.ru_maxrss + child.ru_maxrss));
    }
#endif

    exit(0);
}

/***********************************************************************
 *
 * function:	CheckStringForProtoMinorReferences
 *
 * description:	Search the symbol table for the passed string, and if
 *              we find something, see if the use of that symbol requires
 *              use to generate a protoMinor reference.
 *
 * called by:	ScanIdentifierThing
 *
 * pass:        symName
 *
 * return:	nothing
 *
 * revision history:
 *	name	date		description
 *	----	----		-----------
 *      jon     7/93            initial version
 *
 ***********************************************************************/
static void
CheckStringForProtoMinorReferences(char *symName)
{
    Symbol    *sym;
    ID        id;

    /*
     * See if we can find the passed string in the symbol table
     */

    if (protodebug) {
	printf("\nChecking %s for protominor references", symName);
    }

    id = String_LookupNoLen(symName);

    if ((sym = Symbol_Find(id, TRUE)) != NullSymbol) {
	switch (sym->type) {
	case MSG_SYM:
	    if (sym->data.symMessage.protoMinor != NullSymbol) {
		sym->data.symMessage.protoMinor->data.symProtoMinor.msgOrVardataSym = sym;
		sym->data.symMessage.protoMinor->data.symProtoMinor.references++;
	    }
	    break;
	case VARDATA_SYM:
	    if (sym->data.symVardata.protoMinor != NullSymbol) {
		sym->data.symVardata.protoMinor->data.symProtoMinor.msgOrVardataSym = sym;
		sym->data.symVardata.protoMinor->data.symProtoMinor.references++;
	    }
	    break;
	default:
	    break;
	}
    }
}


/***********************************************************************
 *			 DoProtoMinorChecks
 ***********************************************************************
 * SYNOPSIS:	  Parse command line arguments
 * CALLED BY:	  main
 * RETURN:	  No
 * SIDE EFFECTS:  Lots
 *
 * STRATEGY:
 *
 ***********************************************************************/
void
DoProtoMinorChecks(void)
{
	FILE *fp;
	char c;
	char *cp;
	char symName[300];

	if (protodebug) {
	    printf("\nAttempting to file %s for protominor checks", inFile);
	}

	fp = fopen(inFile, "rb");

	if (fp == NULL) {
	    Usage("Cannot open %s for protominor checks",inFile);
	}

	if (protodebug) {
	    printf("\nSuccessfully opened file %s for protominor checks", inFile);
	}

	for (c = getc(fp); c != EOF;) {
	    switch (c) {
	    case '/':
		/*
		 * See if we're entering a comment
		 */

		c = getc(fp);
		if (c == '*') {
		    /*
		     * We begin the search for the end of the comment
		     * with the next character
		     */
		    c = getc(fp);

		    for(;;) {
			/*
			 * Find the next '*'
			 */
			for ( ; (c != '*') && (c != EOF); c= getc(fp)) {
			}

			if (c == EOF) {
			    break;
			}

			/*
			 * We just read in a '*' while parsing a comment.
			 * Could this be the end?
			 */

			c = getc(fp);

			if ((c == '/') || (c == EOF)) {
			    /*
			     * Advance to the next character and
			     * be done with it
			     */
			    c = getc(fp);
			    break;
			}
		    }
		}
		break;
	    case 'M':
		/*
		 * Start checking for MSG_
		 */
		c = getc(fp);
		if (c != 'S') {
		    break;
		}
		c = getc(fp);
		if (c != 'G') {
		    break;
		}
		c = getc(fp);
		if (c != '_') {
		    break;
		}
		/*
		 * It looks like a message!
		 */
		strcpy(symName, "MSG_");
		cp = symName + 4;
		for (c = getc(fp); (c >= 'A' && c <= 'Z') ||
		     (c >= '0' && c <= '9') ||
		     c == '_'; c = getc(fp)) {

		    *cp++ = c;
		}

		*cp = 0;
		CheckStringForProtoMinorReferences(symName);
		break;
	    case 'A':
		/*
		 * Start checking for ATTR_
		 */
		c = getc(fp);
		if (c != 'T') {
		    break;
		}
		c = getc(fp);
		if (c != 'T') {
		    break;
		}
		c = getc(fp);
		if (c != 'R') {
		    break;
		}
		c = getc(fp);
		if (c != '_') {
		    break;
		}
		/*
		 * It looks like a message!
		 */
		strcpy(symName, "ATTR_");
		cp = symName + 5;
		for (c = getc(fp); (c >= 'A' && c <= 'Z') ||
		     (c >= '0' && c <= '9') ||
		     c == '_'; c = getc(fp)) {

		    *cp++ = c;
		}

		*cp = 0;
		CheckStringForProtoMinorReferences(symName);
		break;
	    default:
		c = getc(fp);
		break;
	    }
	}

	if (protodebug) {
	    printf("\nDone checking %s for protominor references", inFile);
	}

	fclose(fp);
}



/***********************************************************************
 *				OpenOutputFile
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JL	7/ 9/96   	Initial Revision
 *
 ***********************************************************************/
Boolean
OpenOutputFile(char *outFile)
{
    if (strcmp(outFile, "-") == 0) {
	if (gocdebug) {
	    fprintf(stderr,"Using stdout for output\n");
	}
	foutput = stdout;
    } else {
	if (gocdebug) {
	    fprintf(stderr,"Opening file '%s' for output\n", outFile);
	}
	OPEN_AND_ASSIGN_OUTPUT_FILE(foutput,outFile);
	if (localize){

	    Localize_Init(outFile,TRUE); /*TRUE. resource names are all caps */
	}

	if (foutput == NULL) {
	    return FALSE;
	}
    }
    return TRUE;
}	/* End of OpenOutputFile.	*/



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
void
ParseArgs(int argc, char **argv)
{
    int	    	ac;


    /* Check to see if we have to fetch our args from a file.      */
    /* If we do, read them and reset argc and argv.                */
    /* Then do the normal arg stuff.                               */

    if(argc == 2 && HAS_ARGS_FILE(argv)){
      GetFileArgs(ARGS_FILE(argv),&argc,&argv);
    }

    /* Make our default compiler assumption. We assume HighC. */

    lms = "";               /* don't need to put 'far' before lmem blocks */
    compilerFarKeyword 		= highCFarString;
    compilerOffsetTypeName 	= highCOffsetTypeName;
    compilerCastForOffset	= highCCastForOffset;
    defStringType = asciiStringType;

    for (ac = 1; ac < argc; ac++) {
	if (argv[ac][0] == '-') {
	    switch (argv[ac][1]) {
		case 'a': {
		    issueArgsUsedPragma = FALSE;
		    break;
		}
		case 'H':
		    if (argv[ac][2] != '\0')
		    {
			char *ptr;

			for (ptr = &(argv[ac][2]); *ptr != '\0'; ptr++)
			{
			    switch (*ptr) {
				case 'a' : {
				    hackFlags |= HF_APP_BASE;
				    break;
				}
			    }
			}
		    }
		    break;
		case 'c':
		    switch (argv[ac][2]){
		    case 'm':
		      /* lms = */
		      compilerFarKeyword = microSoftFarString;
		      compilerOffsetTypeName = microsoftOffsetTypeName;
		      compilerCastForOffset = microsoftCastForOffset;
		      compiler = COM_MSC;
		      break;
		    case 'b':
		      _ar="[]";
		      _op="{";
		      _cl="}";
		      lms = compilerFarKeyword = borlandFarString;
		      compilerOffsetTypeName = borlandOffsetTypeName;
		      compilerCastForOffset  = borlandCastForOffset;
		      compiler = COM_BORL;
		      break;
		    case 'h':
		      /* lms and compilerFarKeyword are already set */
		      compiler = COM_HIGHC;
		      break;
		    default:  case '\0':
		      Usage("-c requires the name of a compiler, where\n"
			    "\tb=borland\n\th=HighC\n\tm=MicroSoft\n");
		    }
		    break;

		case 'C': {
		    if (argv[ac][2] == '\0') {
			Usage("-C requires a segment name");
			/*NOTREACHED*/
		    }
		    classSegName = (char *) malloc(strlen(argv[ac]));
		    strcpy(classSegName, &argv[ac][2]);
		    break;
		}
		case '2': {
		    dbcsRelease = 1;
		    defStringType = lStringType;
		    if (argv[ac][2] == 's' || argv[ac][2] == 'S') {
			defStringType = sjisStringType;
		    }
		    break;
		}

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
			lexdebug=yydebug=symdebug=outdebug=gocdebug = 1;
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
				gocdebug = 1;   break;
			    }
			    case 'm' : {
				mpddebug = 1;   break;
			    }
			    case 'p' : {
				protodebug = 1;   break;
			    }
			    case 'L' : {
				linedebug = 1;   break;
			    }
			    case 'O':{
				optimizedebug = 1; break;
			    }
			    case 'd' : {
				defaultdebug = 1;   break;
			    }
			    }
			}
		    }
		    break;
		}

		case 'D' :
		  if (argv[ac][2] == '\0')
		    Usage("-D arg requires a macro name and optional value");
		  else {
		    char *name, *value;
		    name = argv[ac]+2;
		    value = strchr(name,'=');
		    if(value == NULL){
		      value = "";
		    }else{
		      *value++='\0';
		    }
		    Scan_DefineMacro(name,value);
		  }
		  break;

		case 'F': {
	            fprintf(stderr,"-F  argument is now ignored\n");
		    if (ac + 1 == argc) {
			Usage("-F requires an argument");
			/*NOTREACHED*/
		    }
		    replaceSuffix = (char *) malloc(strlen(argv[ac+1])+1);
		    strcpy(replaceSuffix, argv[ac+1]);
		    ac++;
		    break;
		}

		case 'I' :
		    if(argv[ac][2] == '\0'){
			Usage("-I requires an argument");
		    }else if(argv[ac][2] == '-' && argv[ac][3] == '\0'){
			/*
			 * this is not a dir specification -- they are turning
			 * off relative @includes.
			 */
			allowCurrentDirSearch = FALSE;
		    }

		    else{
			/* remove (if exists) trailing path terminator */
			char *cp = strrchr(argv[ac],PATHNAME_SLASH);
			if((cp != NULL) && (cp[1] == '\0'))
			    *cp = '\0';
		    }

		    dirs[numDirs++] = argv[ac]+2;
		    if(numDirs > MAX_DIRS)
			Usage("can't supply more than %d include directories",
			      MAX_DIRS);

		    break;

	        case 'l':
		    localize = TRUE;
		    break;

		case 'L': {
		    if (ac + 1 == argc) {
			Usage("-L requires an argument");
			/*NOTREACHED*/
		    }
		    strcpy(libraryName, argv[ac+1]);
		    ac++;
		    break;
		}

		case 'M':
		    makeDepend = 1;
		    break;

		case 'o': {
		    if (ac + 1 == argc) {
			Usage("-o requires a filename argument");
			/*NOTREACHED*/
		    }
		    outFile = argv[ac+1];
		    ac++;
		    break;
		}

		case 'O':
#if !defined(unix)
		    allowOptimize = FALSE;
#else
		    /*allowOptimize = TRUE;*/
#endif
		    break;

		case 'p':
		    if(argv[ac][2] == '\0'){
			Usage("-p requires an argument");
		    }else{
			int len;
#if defined(unix) || defined(_WIN32) || defined(_LINUX)
			/*
			 * Under NT and Unix, only do optimize shme
			 * if -p is passed.
			 */
			allowOptimize = TRUE; /* -p implies optimization */
#endif

			directoryOverride = argv[ac] + 2;
			len = strlen(directoryOverride);
			if(IS_PATHSEP(directoryOverride[len-1])){
			    directoryOverride[len-1] = '\0';
			}
		    }
		    break;

		case 'P': {
	            fprintf(stderr,"-P  argument is now ignored\n");
		    realLineNumbers = FALSE;
		    break;
		}

		case 'R' : {
		    break;
		}

		case 'w': {
		    declareMessageParams = TRUE;
		    break;
		}

	        case 'W': {
		    char *warningFlag = argv[ac] + 2;
		    if ( strlen(warningFlag) ){
			if ( !strcmp(warningFlag, "localize") ){
			    localizationWarning = TRUE;
			} else {
			    Usage("-W doesn't recognize \"%s\"", warningFlag);
			}
		    }
		    break;
		}

		case 'X': {
		    outputProtoMinorReferences = TRUE;
		    break;
		}

		default:
		    Usage("Argument %c unknown", argv[ac][1]);
		    /*NOTREACHED*/
	 }
	} else {
	    if (inFile[0] != '\0') {
	        fprintf(stderr, "your input file is %s.\n", inFile);
		Usage("Only one input file allowed");
		/*NOTREACHED*/
	    }
	    strcpy(inFile, argv[ac]);
	}
    }

    /* Open input file */
    if (inFile[0] == 0) {
	Usage("Need a file on which to work");
	/*NOTREACHED*/
    }
    yyin = fopen(inFile, "rb");
    if (yyin == NULL) {
        Usage("%s: %s", inFile, strerror(errno));
    }

    /*
     * Allocate and initialize initial curFile record.
     */
    curFile = (File *)malloc(sizeof(File));
    curFile->next = (File *)0;
    curFile->line = 1;
    curFile->name = String_Enter(inFile,strlen(inFile));

    /* Open output file */
    if (OpenOutputFile(outFile) == FALSE) {
	perror(outFile);
	exit(1);
    }
}
