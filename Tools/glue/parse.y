%{
/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Geode Parameter File Parsing
 * FILE:	  parse.y
 *
 * AUTHOR:  	  Adam de Boor: Sep 26, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	yyparse	    	    Parse the file
 *	Parse_Params	    Set up for and parse a parameter file.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/26/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Grammar to parse a geode-parameter file to specify the important
 *	attributes of a geode.
 *
 *	The geode-parameter file should be run through this grammar
 *	at the end of pass 1.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: parse.y,v 2.59 96/07/08 17:29:34 tbradley Exp $";
#endif lint

#include    "glue.h"
#include    "library.h"
#include    "sym.h"
#include    "parse.h"

#include    <ctype.h>
#include    <objfmt.h>

#include	  "geo.h"

#if defined(unix)
#define FILE_AND_LINE "file \"%s\", line %d: "
#else
#define FILE_AND_LINE "%s %d: "
#endif

#define GA_SINGLE_LAUNCH 0x10000    /* Fake attribute to handle restriction
				     * to single launch, since applications
				     * by default will allow multiple
				     * launches, but geos only has the
				     * GA_MULTI_LAUNCHABLE flag */
/*
 * Global var for use by the resFlags rule.
 */
static unsigned short	    resFlags;

static char 	*paramFile; 	/* Name of file being read */
static int  	yylineno=1; 	/* Line number in parameter file */
static int  	yylex();    	/* Can't use full prototype b/c YYSTYPE not
				 * defined yet... */
static int  	nameseen=0;
static int  	errorgiven=0;

static int	loadingLibs = 0;

static SegAlias	curAlias;
static Boolean	doingAlias = FALSE;

Boolean		  noSort = FALSE;   /* Set TRUE if user has indicated, via
				     * "nosort" command, that resources are
				     * not to be sorted */

/*
 * Stack of nested if's. iflevel == -1 => no nested ifs in progress. The
 * stack is necessary to handle elseifs properly. The way these things work
 * is to process things normally if a conditional is true, but when it is
 * false, to call ScanToEndif, which reads the file until the end of the
 * conditional is reached. The terminating token, be it an ELSE, ELSEIF or
 * ENDIF, is pushed back into the input stream, preceded by a newline,
 * to be read next.
 */
#define MAX_TOKEN_LENGTH    256
#define MAX_IF_LEVEL	    30
int 		ifStack[MAX_IF_LEVEL];
int		iflevel=-1;

static void HandleIFDEF(int, char *);
void ScanToEndif(int orElse);

/*
 * Provide our own handler for the parser-stack overflow so the default one
 * that uses "alloca" isn't used, since alloca is forbidden to us owing to
 * the annoying hidden non-support of said function by our dearly beloved
 * HighC from MetaWare, A.M.D.G.
 */
#define yyoverflow(m,s,S,v,V,d) ParseStackOverflow(m,s,S,(void **)v,V,d)
static void ParseStackOverflow(char *,
			       short **, size_t,
			       void **, size_t,
			       int *);

%}

/* In case we need another parser for another output type... */
%pure_parser

%union {
    long    number;
    char    *string;
    Boolean bool;
    LibraryLoadTypes loadType;
}

%token	<string>    IDENT
%token	<number>    KNUMBER NUMBER ALIGNMENT COMBINE
%token	<string>    STRING
%type	<number>    typeArg typeArgs
%type	<loadType>  noload
%type	<bool>	    resource

%token	    	NAME
%token		LONGNAME
%token		TOKENCHARS
%token		TOKENID
%token	    	TYPE PROCESS DRIVER LIBRARY SINGLE APPL USES_COPROC NEEDS_COPROC 
	    	SYSTEM HAS_GCM C_API PLATFORM SHIP EXEMPT DISCARDABLE_DGROUP
%token	    	REV
%token	    	APPOBJ
%token	    	NOLOAD EXPORT AS SKIP UNTIL
%token	    	CLASS
%token	    	STACK
%token	    	HEAPSPACE
%token	    	RESOURCE READONLY DISCARDONLY PRELOAD FIXED CONFORMING
		SHARED CODE DATA LMEM UIOBJECT OBJECT SWAPONLY DISCARDABLE
		SWAPABLE NOSWAP NODISCARD
%token	    	ENTRY
%token	    	USERNOTES
%token		LOAD
%token	    	NOSORT
%token	    	INCMINOR
%token	    	PUBLISH
%token	    	IFDEF ELSE ENDIF IFNDEF

%%
file		: /* empty -- always reduced at very start */
		{
		    yylineno = 1;
		}
		| file line
		;
line		: '\n'   /* Do nothing */
		| NAME IDENT '.' IDENT '\n'
		{
		    int	    lName = strlen($2);
		    int	    lExt = strlen($4);
		    char    *cp;
		    char    *cp2;
		    int	    i;

		    nameseen = 1;
		    
		    /*
		     * Adjust name and extension to be within bounds
		     */
		    if (lName > GEODE_NAME_SIZE) {
			lName = GEODE_NAME_SIZE;
		    }
		    if (lExt > GEODE_NAME_EXT_SIZE) {
			lExt = GEODE_NAME_EXT_SIZE;
		    }
		    /*
		     * Copy the name into the geodeName field, space-padding
		     * it on the right as necessary to fill up the field.
		     */
		    cp = $2, cp2 = GH(geodeName);
		    for (i = 0; i < lName; i++) {
			*cp2++ = *cp++;
		    }
		    while (i < GEODE_NAME_SIZE) {
			*cp2++ = ' ';
			i++;
		    }
		    /*
		     * The extension is a little trickier, as we have to
		     * place an E at the front of the extension if the
		     * geode is an error-checking version. This reduces the
		     * size of the extension the user may give, but only
		     * if s/he gave the full four characters.
		     */
		    cp = $4, cp2 = GH(geodeNameExt);
		    i = 0;
		    if (isEC) {
			*cp2++ = 'E';
			if (lExt < GEODE_NAME_EXT_SIZE) {
			    /*
			     * It'll all fit anyway -- up the length of
			     * the extension to account for the E
			     */
			    lExt++;
			}
			i++;
		    }
		    while (i < lExt) {
			*cp2++ = *cp++;
			i++;
		    }
		    /*
		     * Space-pad the extension too
		     */
		    while (i < GEODE_NAME_EXT_SIZE) {
			*cp2++ = ' ';
			i++;
		    }
		    free($2);
		    free($4);
		}
		| TOKENCHARS STRING
		{
		    int	    numChars = strlen($2);
		    char    *cp;
		    char    *cp2;
		    int	    i;
		    
		    /*
		     * All four token chars must be specified
		     */
		    if (numChars != TOKEN_CHARS_SIZE) {
			Notify(NOTIFY_ERROR,
			       FILE_AND_LINE "token too %s",
			       paramFile, yylineno,
			       (numChars < TOKEN_CHARS_SIZE)? "short" : "long");
			break;
		    }
		    /*
		     * Copy the token chars into the geodeToken fields.
		     */
		    cp = $2;
		    cp2 = GH(geodeToken.chars);
		    for (i = 0; i < TOKEN_CHARS_SIZE; i++) {
			*cp2++ = *cp++;
		    }
		    cp = $2;
		    if (geosRelease >= 2) {
			cp2 = geoHeader.v2x.execHeader.geosFileHeader.token.chars;
		    } else {
			cp2 = geoHeader.v1x.execHeader.geosFileHeader.core.token.chars;
		    }
		    for (i = 0; i < TOKEN_CHARS_SIZE; i++) {
			*cp2++ = *cp++;
		    }
		}
		| TOKENID NUMBER '\n'
		{
		    /*
		     * manufacturer's id must be a word
		     */
		    if (($2 < 0) || ($2 > 65535)) {
			yyerror("manufacturer's id must be in range 0 - 65535");
			break;
		    }
		    /*
		     * Copy the manuf. id of the token into the
		     * geodeToken field.
		     */
		    GH_ASSIGN(geodeToken.manufID, $2);
		    if (geosRelease >= 2) {
			geoHeader.v2x.execHeader.geosFileHeader.token.manufID = $2;
		    } else {
			geoHeader.v1x.execHeader.geosFileHeader.core.token.manufID = $2;
		    }
		}
		| LONGNAME STRING
		{
		    char    *cp;
		    char    *cp2;
		    int	    lName = strlen($2);
		    int	    i;

		    /*
		     * Copy the longname into geodeHeader.
		     */
		    cp = $2;
		    if (geosRelease >= 2) {
			cp2 = geoHeader.v2x.execHeader.geosFileHeader.longName;
		    } else {
			cp2 = geoHeader.v1x.execHeader.geosFileHeader.core.longName;
		    }
		    if (lName > GFH_LONGNAME_SIZE) {
			yyerror("longname TOO long (32 chars max)");
			break;
		    }
		    if (isEC && (lName+3 > GFH_LONGNAME_SIZE)) {
		        Notify(NOTIFY_WARNING, 
			       FILE_AND_LINE "EC longname TOO long, losing end character(s)",
			       paramFile, yylineno);
		    }
		    /*
		     * if error-checking version, tack on "EC " at the front
		     */
		    if (!dbcsRelease) {
		    	if (isEC) {
			    *cp2++ = 'E';
			    *cp2++ = 'C';
			    *cp2++ = ' ';
			    i = 3;
		    	} else {
			    i = 0;
		    	}
		    	while (i < GFH_LONGNAME_SIZE) {
			    if (*cp) {
			    	*cp2++ = *cp++;
			    } else {
			    	*cp2++ = 0;
			    }
			    i++;
		    	}
		    	*cp2++ = 0;
		    } else {
			if (isEC) {
			    i = VMCopyToDBCSString(cp2, "EC ", 6);
			} else {
			    i = 0;
			}
			VMCopyToDBCSString(cp2+i, cp, GFH_LONGNAME_SIZE-i);
		    }

		}
		| USERNOTES STRING
		{
		    char    *cp;
		    char    *cp2;
		    int	    lNotes = strlen($2);
		    int	    i;

		    /*
		     * Copy the user notes into geodeHeader.
		     */
		    cp = $2;
		    cp2 = GH(execHeader.geosFileHeader.userNotes);
		    if (lNotes > GFH_USER_NOTES_SIZE) {
			yyerror("user notes too long");
		    	break;
		    }
		    i = 0;
		    while (i < lNotes) {
			*cp2++ = *cp++;
			i++;
		    }
		}
		| TYPE typeArgs '\n'
		{
		    if (!($2 & GA_SINGLE_LAUNCH)) {
			$2 |= GA_MULTI_LAUNCHABLE;
		    }
		    GH_ASSIGN(geodeAttr, $2);
   		    GH_ASSIGN(execHeader.attributes, $2); 
		}
		;
typeArgs	: typeArg
		| typeArgs typeArg	{ $$ = $1 | $2; }
		| typeArgs ',' typeArg	{ $$ = $1 | $3; }
		;
typeArg		: PROCESS   	    { $$ = GA_PROCESS; }
		| DRIVER    	    { $$ = GA_DRIVER; }
		| LIBRARY   	    { $$ = GA_LIBRARY; }
		| SINGLE    	    { $$ = GA_SINGLE_LAUNCH; }
		| APPL	    	    { $$ = GA_APPLICATION; }
		| USES_COPROC	    { $$ = GA_USES_COPROC; }
		| NEEDS_COPROC	    { $$ = GA_REQUIRES_COPROC; }
		| SYSTEM    	    { $$ = GA_SYSTEM; }
		| HAS_GCM    	    { $$ = GA_HAS_GENERAL_CONSUMER_MODE; }
		| C_API    	    { $$ = GA_ENTRY_POINTS_IN_C; }
		| DISCARDABLE_DGROUP { discardableDgroup = 1; $$ = 0;}
		;
line		: APPOBJ IDENT '\n'
		{
		    if (!loadingLibs) {
			Parse_FindSym($2, OSYM_CHUNK, "chunk",
				      GHA(execHeader.appObjResource),
				      GHA(execHeader.appObjChunkHandle));
		    }
		    free($2);
		}
		| DRIVER IDENT '\n'
		{
		    if (loadingLibs) {
			Library_Link($2, LLT_ON_STARTUP, GA_DRIVER);
		    }
		    free($2);
		}
		| PLATFORM platformList '\n'
		{
		}
		| SHIP shipList '\n'
		{
		}
		| EXEMPT exemptList '\n'
		{
		}
		| IFDEF IDENT
		{
		    HandleIFDEF(TRUE, $2);
		}
		| IFNDEF IDENT
		{
		    HandleIFDEF(FALSE, $2);
		}
		| ELSE
		{
		    if (iflevel == -1) {
			yyerror("IF-less ELSE");
			yynerrs++;
		    } else if (ifStack[iflevel] == -1) {
			yyerror("Already had an ELSE for this level");
			yynerrs++;
		    } else if (ifStack[iflevel]) {
			/*
			 * Remember ELSE and go to the endif
			 */
			ifStack[iflevel] = -1;
			ScanToEndif(FALSE);
		    } else {
			/*
			 * IF was false, so continue parsing, but remember
			 * we had an ELSE already.
			 */
			ifStack[iflevel] = -1;
		    }
		}
		| ENDIF
		{
		    if (iflevel == -1) {
			yyerror("IF-less ENDIF");
			yynerrs++;
		    } else {
			iflevel -= 1;
		    }
		}
		| LIBRARY IDENT noload '\n'
		{
		    if (loadingLibs) 
		    {
		        switch (Library_Link($2, $3, GA_LIBRARY))
 		        {		
		            case LLV_SUCCESS: break;
		            case LLV_FAILURE: 
 		                  Notify(NOTIFY_WARNING, 
			                 "library %s: missing ldf file.", $2);
		                  break;
		            case LLV_ALREADY_LINKED: 
 		                  Notify(NOTIFY_WARNING, 
			                 "library %s: tried to link twice, perhaps the library's ldf file is out of date.", $2);
		                  break;

		        }
		    }
		    free($2);
		}
		;
platformList	: platformFile
		| platformList ',' platformFile
		;
platformFile    : IDENT
		{
		    if (loadingLibs) {
			Library_ReadPlatformFile($1);
		    }
		    free($1);
		}
		;
shipList	: shipFile
		| shipList ',' shipFile
		;
shipFile    : IDENT
		{
		    if (loadingLibs) {
			Library_ReadShipFile($1);
		    }
		    free($1);
		}
		;
exemptList	: exemptLib
		| exemptList ',' exemptLib
		;
exemptLib       : IDENT
		{
		    if (loadingLibs) {
			Library_ExemptLibrary($1);
		    }
		    free($1);
		}
		;
noload		: /* empty */ { $$ = LLT_ON_STARTUP; }
		| NOLOAD { $$ = LLT_DYNAMIC; }
		| NOLOAD FIXED { $$ = LLT_DYNAMIC_FIXED; }
		;
line		: SKIP NUMBER '\n'
		{
		    if (!loadingLibs) {
			Library_Skip($2);
		    }
		}
                | SKIP UNTIL NUMBER '\n'
                {
		    if (!loadingLibs) {
			Library_SkipUntilNumber($3);
		    }
		}
                | SKIP UNTIL IDENT '\n'
                {
		    if (!loadingLibs) {
			Library_SkipUntilConstant($3);
		    }
		}
		| EXPORT 
		{
		    if (!nameseen && !errorgiven) {
			yyerror("NAME must be given before export");
			errorgiven=1;
		    }
		}
		  idList '\n'
		;
exportid    	: IDENT
		{
		    if (nameseen && !loadingLibs) {
			Library_ExportAs($1, $1, TRUE);
		    }
		}
		| IDENT AS IDENT
		{
		    /*
		     * Similar, but the symbol placed in the interface
		     * definition file has the name $3.
		     */
		    if (nameseen && !loadingLibs) {
			Library_ExportAs($1, $3, TRUE);
		    }
		}
		| IDENT IFDEF
		{
		    if (nameseen && !loadingLibs) {
			Library_ExportAs($1, $1, FALSE);
		    }
		}
		;
idList		: exportid
		| idList ',' exportid
		;
line		: CLASS IDENT '\n'
		{
		    if (!loadingLibs) {
			Parse_FindSym($2, OSYM_CLASS, "class",
				      GHA(execHeader.classResource),
				      GHA(execHeader.classOffset));
		    }
		    free($2);
		}
		| STACK NUMBER '\n'
		{
		    stackSize = $2;
		    stackSpecified = TRUE;
		}
		| HEAPSPACE NUMBER '\n'
		{
		    if (geosRelease >= 2) {
			geoHeader.v2x.execHeader.heapSpace = $2;
		    } 
		}
                | HEAPSPACE KNUMBER '\n'
                {
                    if (geosRelease >= 2) {
			geoHeader.v2x.execHeader.heapSpace = ($2/16);
			}
		}
		;
resource	: RESOURCE { $$ = TRUE; }
		| RESOURCE IFDEF { $$ = FALSE; }
		;
line		: resource IDENT
		{
		    resFlags = RESF_STANDARD & ~RESF_DISCARDABLE;
		}
		  resArgs '\n'
		{
		    ID	    id;

		    if (!loadingLibs) {
			id = ST_LookupNoLen(symbols, strings, $2);
		        if (id == NullID)
		        {
		            char *cp, *cp2;
			    char c='\0';
		            /* since goc puts out _E and _G and _ECONST_DATA
		             * and _GCONST_DATA, I want to accept either of
                             * these (also works for file names with
			     * other underscores in them)
 		             */
                            cp = (char *)strrchr($2, '_');
			    if ((cp != NULL) && !strcmp(cp, "_DATA"))
			    {
				/* get to next to last '_' if we have 
				 * _DATA at the end
				 */
				cp[0] = 'A';
				cp2 = (char *)strrchr($2, '_');
				cp[0] = '_';
				cp = cp2;
			    }
			    if ((cp != NULL) && !strncmp(cp, "_G", 2))
			    {
				c = 'E';
			    }
			    if ((cp != NULL) && !strncmp(cp, "_E", 2))
			    {
				c = 'G';
			    }
			    if (c)
			    {
				/* ok we were on fact looking for one of these
				 * ick code segments from C so try the other
				 * one
				 */
				cp[1] = c;
				id = ST_LookupNoLen(symbols, strings, $2);
			    }
			}
				
			if (id == NullID) {
			    if ($1) {
				Notify(NOTIFY_ERROR,
				       FILE_AND_LINE "resource %s not defined",
				       paramFile, yylineno, $2);
			    }
			} else {
			    /*
			     * Can't use Seg_Find here b/c C segments have
			     * non-NULL class names...
			     */
			    SegDesc *seg = NULL;
			    int	    i, j;

			    for (i = 0; i < seg_NumSegs; i++) 
                            {
				if (seg_Segments[i]->name == id) 
		                {
				    seg = seg_Segments[i];
		                    
                                    for (j = 2; j < seg_NumSegs; j++)
		                    {
		                        if (seg_Info[j].segID == NullID)
                                        {
                                            break;
                                        }
                                    }
		                    seg_Info[j].segID = id;
				    break;
				}
			    }
			    for (i = 0; seg == NULL && i < seg_NumSubSegs; i++)
			    {
				if (seg_SubSegs[i]->name == id) {
				    seg = seg_SubSegs[i];
				    break;
				}
			    }
			    
			    if (seg == NULL) {
				if ($1) {
				    Notify(NOTIFY_ERROR,
					   FILE_AND_LINE "resource %s not defined",
					   paramFile, yylineno, $2);
				}
			    } else {
				if (seg->hasProfileMark) {
				    seg->flags = resFlags & ~RESF_DISCARDABLE;
				} else {
				    seg->flags = resFlags;
				}
			    }
			}
		    }
		    free($2);
		}
		| NOSORT '\n'
		{
		    noSort = TRUE;
		}
		| error '\n'
		{
		    doingAlias = FALSE;
		}
		;
/*
 * Rules to figure the resource allocation flags for a block. resFlags
 * starts with the default flags for a specified block (which are different
 * from those for an unspecified block -- see paramFile.doc). These
 * flags are progressively modified by the various keywords coming in.
 * In the case of conflicting keywords, the last-specified one wins.
 * Note we can't just accumulate flags as there are some that are defaults
 * and some rules have to delete flags...
 */
resArgs		: /* empty */
		| resArgList
		;
resArgList	: resArg
		| resArgList resArg
		| resArgList ',' resArg
		;
resArg		: READONLY
		{
		    resFlags|= RESF_READ_ONLY;
		    /*
		     * If the resource is fixed, do not make it discardable...
		     */
		    if ( !(resFlags & RESF_FIXED) ) {
			resFlags|= RESF_DISCARDABLE;
		    }
		}
		| DISCARDABLE
		{
		    if (!(resFlags & RESF_FIXED)) {
			resFlags |= RESF_DISCARDABLE;
		    }
		}
		| DISCARDONLY
		{
		    resFlags &= ~RESF_SWAPABLE;
		    resFlags |= RESF_DISCARDABLE;
		}
		| SWAPONLY
		{
		    resFlags &= ~RESF_DISCARDABLE;
		    resFlags |= RESF_SWAPABLE;
		}
		| SWAPABLE
		{
		    resFlags |= RESF_SWAPABLE;
		}
		| NOSWAP
		{
		    resFlags &= ~RESF_SWAPABLE;
		}
		| NODISCARD
		{
		    resFlags &= ~RESF_DISCARDABLE;
		}
		| PRELOAD   	    { resFlags &= ~RESF_DISCARDED; }
		| FIXED
		{
		    resFlags |= RESF_FIXED;
		    resFlags &= ~(RESF_SWAPABLE|RESF_DISCARDABLE|
				  RESF_DISCARDED|RESF_LMEM);
		}
		| CONFORMING
		{
		    resFlags |= RESF_CONFORMING;
		}
		| SHARED    	    { resFlags |= RESF_SHARED; }
		| CODE	    	    { resFlags |= RESF_CODE; }
		| DATA	
		{
		    resFlags &= ~(RESF_CODE|RESF_DISCARDABLE);
		    if ((resFlags&(RESF_READ_ONLY|RESF_FIXED))==RESF_READ_ONLY){
			/*
			 * Read-only data can actually still be discarded.
			 */
			resFlags |= RESF_DISCARDABLE;
		    }
		}
		| LMEM
		{
		    resFlags |= RESF_LMEM;
		    resFlags &= ~RESF_CODE;
		}
		| UIOBJECT
		{
		    resFlags |= RESF_OBJECT|RESF_UI|RESF_LMEM|RESF_SHARED;
		    resFlags &= ~(RESF_CODE|RESF_DISCARDABLE);
		    if ((resFlags&(RESF_READ_ONLY|RESF_FIXED))==RESF_READ_ONLY){
			/*
			 * Read-only data can actually still be discarded.
			 */
			resFlags |= RESF_DISCARDABLE;
		    }
		}
		| OBJECT
		{
		    resFlags |= RESF_OBJECT|RESF_LMEM;
		    resFlags &= ~(RESF_CODE|RESF_UI|RESF_DISCARDABLE);
		    if ((resFlags&(RESF_READ_ONLY|RESF_FIXED))==RESF_READ_ONLY){
			/*
			 * Read-only data can actually still be discarded.
			 */
			resFlags |= RESF_DISCARDABLE;
		    }
		}
		;
line		: ENTRY IDENT
		{
		    if (!loadingLibs) {
			Parse_FindSym($2, OSYM_PROC, "procedure",
				      GHA(libEntryResource),
				      GHA(libEntryOff));
		    }
		    free($2);
		}
		| LOAD nameAndClass AS loadArgs '\n'
		{
		    if (loadingLibs) {
			Seg_AddAlias(&curAlias);
		    }
		}
		;
/*
 * Segment Aliasing stuff
 */
nameAndClass	: IDENT
		{
		    if (loadingLibs) {
			curAlias.name = ST_EnterNoLen(symbols, strings, $1);
			curAlias.class = NullID;
			curAlias.aliasMask = 0;
		    }
		    free($1);
		    doingAlias = TRUE;
		}
		| IDENT STRING
		{
		    if (loadingLibs) {
			curAlias.name = ST_EnterNoLen(symbols, strings, $1);
			curAlias.class = ST_EnterNoLen(symbols, strings, $2);
			curAlias.aliasMask = 0;
		    }
		    free($1);
		    free($2);
		    doingAlias = TRUE;
		}
		;
/*
 * Segment attribute defintions
 */
loadArgs	: IDENT segAttrs
		{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWNAME;
			curAlias.newName = ST_EnterNoLen(symbols, strings, $1);
		    }
		    free($1);
		}
		| segAttrs
		;
segAttrs	: /* empty */
		{
		    /* Do nothing */
		}
		| ALIGNMENT
		{
		    curAlias.newAlign = $1;
		    curAlias.aliasMask |= SA_NEWALIGN;
		}
		| COMBINE
		{
		    curAlias.newCombine = $1;
		    curAlias.aliasMask |= SA_NEWCOMBINE;
		}
		| STRING
		{
		    if (loadingLibs) {
			curAlias.newClass = ST_EnterNoLen(symbols, strings, $1);
			curAlias.aliasMask |= SA_NEWCLASS;
		    }
		    free($1);
		}
		| ALIGNMENT COMBINE
		{
		    curAlias.aliasMask |= SA_NEWALIGN|SA_NEWCOMBINE;
		    curAlias.newAlign = $1;
		    curAlias.newCombine = $2;
		}
		| ALIGNMENT STRING
		{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWALIGN|SA_NEWCLASS;
			curAlias.newAlign = $1;
			curAlias.newClass = ST_EnterNoLen(symbols, strings, $2);
		    }
		    free($2);
		}
		| COMBINE STRING
		{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWCOMBINE|SA_NEWCLASS;
			curAlias.newCombine = $1;
			curAlias.newClass = ST_EnterNoLen(symbols, strings, $2);
		    }
		    free($2);
		}
		| ALIGNMENT COMBINE STRING
		{
		    if (loadingLibs) {
			curAlias.aliasMask |= SA_NEWALIGN|SA_NEWCOMBINE|SA_NEWCLASS;
			curAlias.newAlign = $1;
			curAlias.newCombine = $2;
			curAlias.newClass = ST_EnterNoLen(symbols, strings, $3);
		    }
		    free($3);
		}
		;

line		: PUBLISH IDENT
		{
		    if (!nameseen) {
			if (!errorgiven) {
			    yyerror("NAME must be given before publish");
			    errorgiven=1;
			}
		    } else if (!loadingLibs) {
			Library_ExportAs($2, $2, TRUE);
			Library_MarkPublished($2);
		    }
		}
		;

line		: INCMINOR
		{
		    if (!loadingLibs) {
			Library_IncMinor();
		    }
		}
		| INCMINOR protoMinorList
		{
		}
		;

protoMinorList	: protominorid
		| protoMinorList ',' protominorid
		;

protominorid   	: IDENT
		{
		    if (!nameseen) {
			if (!errorgiven) {
			    yyerror("NAME must be given before export");
			    errorgiven=1;
			}
		    } else if (!loadingLibs) {

			/*
			 * I can't figure out how to get the Library_IncMinor
			 * to happen before all the Library_ProtoMinor's, so
			 * I'm simply doing an incminor for each protominor
			 * token found. It'd be "nicer" to have a single
			 * Library_IncMinor above in the line that reads:
			 * "| INCMINOR protominorList". Whatever.
			 */
			Library_IncMinor();
			Library_ProtoMinor($1);
		    }
		}
		;

%%


/***********************************************************************
 *				ParseStackOverflow
 ***********************************************************************
 * SYNOPSIS:	  Enlarge the parser's internal stacks.
 * CALLED BY:	  yyparse()
 * RETURN:	  Nothing. *maxDepth left unaltered if we don't want to
 *		  allow the increase. yyerror is called with msg if so.
 * SIDE EFFECTS:  
 *
 * STRATEGY:	  This implementation relies on the "errcheck" rule
 *		  freeing stacks up, if necessary. Sadly, there's no
 *		  opportunity to do this, so it be a core leak...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/31/88		Initial Revision
 *
 ***********************************************************************/
static void
ParseStackOverflow(char		*msg,	    /* Message if we decide not to */
		   short	**state,    /* Current state stack */
		   size_t	stateSize,  /* Current state stack size */
		   void	    	**vals,	    /* Current value stack */
		   size_t	valsSize,   /* Current value stack size */
		   int		*maxDepth)  /* Current maximum stack depth of
					     * all stacks */
{
    *maxDepth *= 2;

    if (malloc_size((malloc_t)*state) != 0) {
	/*
	 * we've been called before. Just use realloc()
	 */
	*state = (short *)realloc((char *)*state, stateSize * 2);
	*vals = (YYSTYPE *)realloc((char *)*vals, valsSize * 2);
    } else {
	short	*newstate;
	YYSTYPE	*newvals;

	newstate = (short *)malloc(stateSize * 2);
	newvals = (YYSTYPE *)malloc(valsSize * 2);

	bcopy(*state, newstate, stateSize);
	bcopy(*vals, newvals, valsSize);

	*state = newstate;
	*vals = newvals;
    }
}

void
yyerror(char *s)
{
    Notify(NOTIFY_ERROR, FILE_AND_LINE "%s", paramFile, yylineno, s);
}

/******************************************************************************
 *
 *			   LEXICAL ANALYZER
 *
 *****************************************************************************/
#include    "tokens.h"
typedef struct _Token	Token;

#undef MIN_WORD_LENGTH
#undef MAX_WORD_LENGTH
#undef MIN_HASH_VALUE
#undef MAX_HASH_VALUE

#include    "segattrs.h"
typedef struct _SegAttr	SegAttr;

#define F   1	/* firstid */
#define O   2	/* otherid */
#define B   3	/* both */
#define N   0	/* none */
static const unsigned char  cbits[] = {
    N,	    	    	    	    	/* EOF */
    N,	N,  N,	N,  N,	N,  N,	N,  	/*  0 -  7 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/*  8 - 15 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 16 - 23 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 24 - 31 */
    N,	N,  N, 	N,  B,	N,  N,	N,  	/* sp ! " # $ % & ' */
    N,	N,  N,	N,  N,	O,  N,	N,  	/* (  ) * + , - . / */
    O,	O,  O,	O,  O,	O,  O,	O,  	/* 0  1 2 3 4 5 6 7 */
    O,	O,  N,	N,  N,	N,  N,	B,  	/* 8  9 : ; < = > ? */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* @  A B C D E F G */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* H  I J K L M N O */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* P  Q R S T U V W */
    B,	B,  B,	N,  N, 	N,  N,	B,  	/* X  Y Z [ \ ] ^ _ */
    N,	B,  B,	B,  B,	B,  B,	B,  	/* `  a b c d e f g */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* h  i j k l m n o */
    B,	B,  B,	B,  B,	B,  B,	B,  	/* p  q r s t u v w */
    B,	B,  B,	N,  N, 	N,  N,	N,  	/* x  y z { | } ~ del */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 128 - 135 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 136 - 143 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 144 - 151 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 152 - 159 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 160 - 167 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 168 - 175 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 176 - 183 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 184 - 191 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 192 - 199 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 200 - 207 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 208 - 215 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 216 - 223 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 224 - 231 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 232 - 239 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 240 - 247 */
    N,	N,  N,	N,  N,	N,  N,	N,  	/* 248 - 255 */
};

#define isfirstid(c)	((cbits+1)[c]&F)
#define isotherid(c)	((cbits+1)[c]&O)

static FILE *yyin;

#ifdef YYDEBUG
#define DBPRINTF(args)	if (yydebug) fprintf args
#else
#define DBPRINTF(args)
#endif



/*
 * some stuff for longname support
 */

#define input() getc(yyin)
#define unput(c) ungetc(c, yyin)


/***********************************************************************
 *				yyreadstring
 ***********************************************************************
 * SYNOPSIS:	    Read a string literal
 * CALLED BY:	    yylex (<, {, ' and " cases)
 * RETURN:	    Token to return
 * SIDE EFFECTS:    yylval->string is set to the string read, dynamically
 *	    	    allocated. findOpcode removed from the list of procedures
 *	    	    tried.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/31/89		Initial Revision
 *
 ***********************************************************************/
static int
yyreadstring(char   open,   	/* If matched, ignore next close */
	     char   close,  	/* Character to close the string */
	     char   duplicate, 	/* If matched and follows, place one
				 * in string and continue */
	     YYSTYPE *yylval,	/* Place to store result */
	     char   *yytext,
	     int    yytextSize)
{
    int  	c;
    char	*base = yytext;
    int 	size = yytextSize;
    char    	*cp;
    int	    	level = 0;
    
    DBPRINTF((stderr,"reading %c%c string literal...", open ? open : close,
		close));
    cp = base;
    while(1) {
	c = input();
	if (c == 0) {
	    if (close != '\n') {
		yyerror("end-of-file in string constant");
		return(0);
	    } else {
		/*
		 * Snarfing to the end of the line. We don't complain here.
		 * Just return what we've got after pushing a newline
		 * back into the input stream -- the EOF will be handled
		 * gracefully elsewhere.
		 */
		unput('\n');
		break;
	    }
	} else if (c == duplicate) {
	    int	c2 = input();

	    if (c2 != duplicate) {
		unput(c2);
		if (c == close) {
		    break;
		}
	    }
	} else if (c == open) {
	    /*
	     * Open character -- up the nesting level
	     */
	    level++;
	} else if (c == '\n') {
	    /*
	     * Allow a newline to terminate the string, but don't
	     * swallow the thing. Since MASM accepts things like
	     *	MACEXEC <.....\n
	     * we don't give a warning should this happen in a <> string,
	     * but otherwise we do....just to be safe :)
	     */
	    if (close != '>' && close != '\n') {
		Notify(NOTIFY_WARNING,
		       FILE_AND_LINE "%c-terminated string constant terminated by newline",
		       paramFile, yylineno, close);
	    }
	    unput(c);
	    break;
	} else if (c == close && --level < 0) {
	    /*
	     * Close on bottom level -- get out of here.
	     */
	    break;
	} else if (c == '\\') {
	    /*
	     * Handle C-style escape sequences.
	     */
	    switch(c = input()) {
	    case 'n': c = '\n'; break;
	    case 'b': c = '\b'; break;
	    case 'f': c = '\f'; break;
	    case 'r': c = '\r'; break;
	    case 't': c = '\t'; break;
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
	    {
		/*
		 * Convert from octal.
		 */
		int	val;
		
		for (val = c - '0';
		     isdigit(c=input()) && c < '8';
		     val += c - '0')
		{
		    val <<= 3;
		}
		/*
		 * Put back the non-digit char
		 */
		unput(c);
		/*
		 * Convert to a character
		 */
		c = val & 0xff;
		break;
	    }
	    case 'x':
	    {
		/*
		 * Convert following 2 digits from hex
		 */
		int val;

		/*
		 * First character MUST be hex...
		 */
		c = input();
		if (isxdigit(c)) {
		    if (c <= '9') {
			val = c - '0';
		    } else if (c <= 'F') {
			val = c - 'A' + 10;
		    } else {
			val = c - 'a' + 10;
		    }
		} else {
		    yyerror("\\x not followed by hex digit");
		    break;
		}
		/*
		 * Second character is optional
		 */
		c = input();
		if (isxdigit(c)) {
		    val <<= 4;
		    if (c <= '9') {
			val += c - '0';
		    } else if (c <= 'F') {
			val += c - 'A' + 10;
		    } else {
			val += c - 'a' + 10;
		    }
		} else {
		    /*
		     * Ok for there only to be one hex digit. Just put
		     * the character we got, back.
		     */
		    unput(c);
		}
		c = val;
		break;
	    }
	    case '\n':
		/*
		 * Swallow both the \ and the newline when newline is escaped
		 * like this.
		 */
		yylineno++;
		continue;
	    } /* switch */
	} /* if */
	
	*cp++ = c;
	
	if (cp == base+size) {
	    /*
	     * Extend buffer as needed.
	     */
	    if (base == yytext) {
		base = (char *)malloc(size*2);
		bcopy(yytext, base, yytextSize);
	    } else {
		base = (char *)realloc(base, size*2);
	    }
	    cp = base + size;
	    size *= 2;
	}
    }
    DBPRINTF((stderr,"done\n"));
    
    *cp++ = '\0';
    
    if (base == yytext) {
	/*
	 * Copy to non-volatile storage now we know how big it is.
	 */
	base = (char *)malloc(cp - yytext);
	bcopy(yytext, base, cp-yytext);
    }
    
    yylval->string = base;
    
    DBPRINTF((stderr,"returning string %s\n", yylval->string));
    return(STRING);
}

/***********************************************************************
 *				yylex
 ***********************************************************************
 * SYNOPSIS:	    Lexical analyzer for parsing a geode parameters file
 * CALLED BY:	    yyparse
 * RETURN:	    A token, dude. And either nothing (reserved word),
 *	    	    a dynamically allocated string (IDENT) or a number
 *	    	    (NUMBER)
 * SIDE EFFECTS:    Characters are consumed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
static int
yylex(yylval)
    YYSTYPE	*yylval;
{
    int	    	c;
    static int	bumpline = 0;	/* Last token returned was a newline, but
				 * we don't up yylineno until we're called
				 * again, at which point we know the newline
				 * has been used and no errors will be reported
				 * for the line, so we can up yylineno */
    static int	needNL = 0; 	/* Returned something since the last newline
				 * so we need to return a newline if we get
				 * an EOF */
    char    	yytext[256];
    char    	*cp;

    /*
     * If last token returned was a newline, up the line counter now we
     * know it's actually been used.
     */
    if (bumpline) {
	DBPRINTF((stderr, "starting line %d\n", yylineno));
	yylineno += 1;
	bumpline = 0;
    }
    
    while (1) {
	/*
	 * Whitespace is meaningless
	 */
	while ((c = getc(yyin)) == ' ' || c == '\t') {
	    ;
	}
	
	switch(c) {
	    case '"':
		return yyreadstring (0, '"', '"', yylval,
				     yytext, sizeof(yytext));
	    case '\n':
		bumpline = 1;
		needNL = 0;
		doingAlias = FALSE;
		DBPRINTF((stderr, "returning '\\n'\n"));
		return(c);
	    case '.':
	    case ',':
		/*
		 * Return operator characters as-is
		 */
		DBPRINTF((stderr, "returning '%c'\n", c));
		needNL = 1;
		return(c);
	    case '0': case '1': case '2': case '3': case '4':
	    case '5': case '6': case '7': case '8': case '9':
	    {
		/*
		 * Figure the base of the number and convert it.
		 */
		int 	base;
		int     knumb=0;
		long 	n,
			d;
		
		/*
		 * Scan all digits into the buffer. We check for it being a
		 * valid hexadecimal as that's the least-restrictive (and
		 * highest) base we support.
		 */
		cp = yytext;
		*cp++ = c;
		while(isxdigit(c = getc(yyin))) {
		    *cp++ = c;
		}
		
		/*
		 * Determine the radix, using trailing
		 * radix characters 
		 */
		if ((c == 'Q') || (c == 'q') || (c == 'O') || (c == 'o')) {
		    base = 8;
		} else if ((c == 'H') || (c == 'h')) {
		    base = 16;
		} else if ((c == 'K') || (c == 'k')) {
		    base = 10;
		    knumb=1;
		} else {
		    ungetc(c, yyin);
		    cp--;
		    if ((*cp == 'B') || (*cp == 'b')) {
			base = 2;
		    } else if ((*cp == 'D') || (*cp == 'd')) {
			base = 10;
		    } else {
			/*
			 * Current radix -- we default to 10 for now.
			 */
			base = 10;
			cp++;
		    }
		}
		
		*cp++ = '\0';
		/*
		 * Convert the number, now we know what base it's in.
		 */
		cp = yytext;
		n = 0;
		while (*cp != '\0') {
		    n *= base;
		    
		    if (*cp <= '9') {
			d = *cp++ - '0';
		    } else if (*cp <= 'F') {
			d = *cp++ - 'A' + 10;
		    } else {
			d = *cp++ - 'a' + 10;
		    }
		    if (d < base) {
			n += d;
		    } else {
			Notify(NOTIFY_ERROR,
			       FILE_AND_LINE "digit %c out of range for base %d number",
			       paramFile, yylineno, cp[-1], base);
			break;
		    }
		}
		/*
		 * Return the value.
		 */
		needNL = 1;
		if(knumb) {
		    DBPRINTF((stderr, "returning KNUMBER(%ld)\n", n));
		    yylval->number = n * 1024;
		    return(KNUMBER);
		}
		else {
		    DBPRINTF((stderr, "returning NUMBER(%ld)\n", n));
		    yylval->number = n;
		    return(NUMBER);
		}
	    }
	    case EOF:
		if (needNL) {
		    /*
		     * Hit EOF without getting a newline (naughty person),
		     * so return one now to avoid annoying, non-obvious
		     * parse errors.
		     */
		    needNL = 0;
		    DBPRINTF((stderr, "returning \\n after EOF\n"));
		    return('\n');
		} else {
		    DBPRINTF((stderr, "end-of-file\n"));
		    return(0);
		}
	    case '#':
		/*
		 * Skip comments.
		 */
		DBPRINTF((stderr, "skipping comment..."));
		while (((c = getc(yyin)) != '\n') && (c != EOF)) {
		    ;
		}
		if (c == '\n') {
		    if (needNL) {
			/*
			 * Not first thing in the line, so return a newline
			 * to finish the line off, setting bumpline so we
			 * up the line count next time. Need to reset
			 * needNL as well, since we don't :)
			 */
			DBPRINTF((stderr, "returning '\\n'\n"));
			bumpline = 1;
			needNL = 0;
			return('\n');
		    } else {
			/*
			 * No point in returning a newline by itself; we might
			 * as well keep going until we have something real to
			 * say.
			 */
			yylineno++;
			DBPRINTF((stderr, "going back in -- line = %d\n",
				yylineno));
			/*
			 * Break out of switch and loop to fetch next token
			 */
			break;
		    }
		} else {
		    DBPRINTF((stderr, "eof..."));
		    if (needNL) {
			/*
			 * Let reading of EOF next time return the end-of-file
			 * marker.
			 */
			DBPRINTF((stderr, "returning \\n\n"));
			needNL = 0;
			bumpline = 1;
			return('\n');
		    } else {
			return(0);
		    }
		}
	    default:
	    {
		const Token *token;
		
		if (!isfirstid(c)) {
		    Notify(NOTIFY_WARNING,
			   FILE_AND_LINE "Extraneous character 0x%02.2x discarded",
			   paramFile, yylineno, c);
		    break;
		}
		cp = yytext;

		do {
		    *cp++ = c;
		    c = getc(yyin);
		} while (isotherid(c));

		ungetc(c, yyin);
		*cp = '\0';

		if (doingAlias) {
		    const SegAttr *segattr;

		    segattr = findSegAttr(yytext, cp-yytext);
		    if (segattr != NULL) {
			DBPRINTF((stderr, "returning segattr %s\n", segattr->name));
			needNL = 1;
			yylval->number = segattr->value;
			return(segattr->token);
		    }
		}
		
		token = in_word_set(yytext, cp-yytext);

		if (token != NULL) {
		    DBPRINTF((stderr, "returning token %s\n", token->name));
		    needNL = 1;
		    return(token->token);
		} else {
		    yylval->string = (char *)malloc((cp-yytext)+1);
		    strcpy(yylval->string, yytext);
		    DBPRINTF((stderr, "returning IDENT %s\n", yylval->string));
		    needNL = 1;
		    return(IDENT);
		}
	    }
	}
    }
}


/***********************************************************************
 *				Parse_GeodeParams
 ***********************************************************************
 * SYNOPSIS:	    Parse a geode parameters file.
 * CALLED BY:	    InterPass
 * RETURN:	    0 on error
 * SIDE EFFECTS:    geodeHeader is filled in.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/10/89	Initial Revision
 *
 ***********************************************************************/
int
Parse_GeodeParams(char	*file,
		  char	*deflongname,
		  int	libsOnly)
{
    int	    ret;

    loadingLibs = libsOnly;

    yyin = fopen(file, "rt");

    if (yyin == NULL) {
	Notify(NOTIFY_ERROR, "Couldn't open parameters (gp) file \"%s\"\n",
	       file);
	return(0);
    }

    /*
     * Set longname fields for the file to match our output file name as a
     * default.
     */
    if (!libsOnly) {
	strncpy((geosRelease >= 2 ?
		 geoHeader.v2x.execHeader.geosFileHeader.longName :
		 geoHeader.v1x.execHeader.geosFileHeader.core.longName),
		deflongname,
		GFH_LONGNAME_BUFFER_SIZE);

    }
    
    paramFile = file;

    ret = !yyparse();

    fclose(yyin);

    Library_CheckForMissingLibraries();

    if (!libsOnly)
    {
	/* if we are making an application then make sure the App object and
	 * Process class were specified in the gp file
	 */
        if (GH(geodeAttr) & GA_APPLICATION)
        {
            if (GH(execHeader.appObjChunkHandle) == 0)
            {
	        Notify(NOTIFY_ERROR, "Application object not specified in gp file.");
	        ret = 0;
            }
            if (GH(execHeader.classResource) == 0)
            {
	        Notify(NOTIFY_ERROR, "Process class not specified in gp file.");
	        ret = 0;
            }
        }
    }
    /*
     * If any entrypoints exported, write out the LDF file.

     Not yet! We may need to publish some routines, so keep it open!

    if (!libsOnly && (numEPs != 0 || makeLDF)) {
	Library_WriteLDF();
    }

     */
    
    return(ret);
}


/***********************************************************************
 *				Parse_FindSym
 ***********************************************************************
 * SYNOPSIS:	    Figure out a symbol's address
 * CALLED BY:	
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
void
Parse_FindSym(char  	*name,	    /* Name of symbol */
	      int   	type,	    /* Expected type of symbol */
	      char  	*typeName,  /* Name of expected type */
	      word  	*resid,	    /* Place to store resource ID */
	      word  	*offset)    /* Place to store offset */
{
    ID	    	    id;	    	/* ID for which to search */
    ID		    id2;    	/* same, but with (or without, as the case may
				 * be) leading underscore */
    VMBlockHandle   block;  	/* Block in which symbol resides */
    word    	    off;    	/* Offset of symbol in block */
    SegDesc 	    *sd;    	/* Segment being searched */
    int	    	    i;	    	/* Index into seg_Segments */
    int	    	    wrongtype;	/* Set if found a symbol but it's the wrong
				 * type */

    
    id = ST_LookupNoLen(symbols, strings, name);
    if (name[0] == '_') {
	id2 = ST_LookupNoLen(symbols, strings, name+1);
    } else {
	char	*name2 = (char *)malloc(1+strlen(name)+1);

	sprintf(name2, "_%s", name);
	id2 = ST_LookupNoLen(symbols, strings, name2);
	free((malloc_t)name2);
    }

    wrongtype = 0;

    if ((id != NullID) || (id2 != NullID)) {
	for (i = 0; i < seg_NumSegs; i++) {
	    sd = seg_Segments[i];
	    
	    if ((id != NullID &&
		 Sym_Find(symbols, sd->syms, id, &block, &off, TRUE)) ||
		(id2 != NullID &&
		 Sym_Find(symbols, sd->syms, id2, &block, &off, TRUE)))
	    {
		ObjSym  	*sym;
		
		sym = (ObjSym *)((genptr)VMLock(symbols,
						block,
						(MemHandle *)NULL)+
				 off);
		/*
		 * XXX: ALLOW VAR SYMS IN PLACE OF CLASS SYMS UNTIL PC/GEOS IS
		 * CONVERTED TO THE ESP OBJECT STYLE.
		 */
		if ((sym->type != type) &&
		    ((sym->type != OSYM_VAR) || (type != OSYM_CLASS)) &&
		    ((sym->type != OSYM_VAR) || (type != OSYM_CHUNK)))
		{
		    wrongtype = 1;
		    VMUnlock(symbols, block);
		} else {
		    /*
		     * If it's global, it's hip.
		     */
		    *resid = sd->pdata.resid;
		    *offset = sym->u.addrSym.address;
		    sym->flags |= OSYM_REF;
		    VMUnlockDirty(symbols, block);
		    return;
		}
	    }
	}
    }
    if (wrongtype) {
	Notify(NOTIFY_ERROR, FILE_AND_LINE "%s isn't a %s",
	       paramFile, yylineno, name, typeName);
    } else {
	Notify(NOTIFY_ERROR, FILE_AND_LINE "%s not defined",
	       paramFile, yylineno, name);
    }
}


/***********************************************************************
 *				HandleIFDEF
 ***********************************************************************
 * SYNOPSIS:	    Deal with the start of a conditional. curExpr contains
 *	    	    an expression to be evaluated if necessary to
 *	    	    decide if the conditional code is to be assembled.
 *	    	    If the result is a non-zero constant, the conditional
 *	    	    is taken.
 * CALLED BY:	    parser for all IF and ELSEIF tokens
 * RETURN:	    Nothing
 * SIDE EFFECTS:    iflevel is altered. ScanToEndif may be called.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
static void
HandleIFDEF(int     wantDef,  	    /* Non-zero if want symbol to be defined */
	    char    *identifier)    /* String to check for definition */
{

    if (iflevel == MAX_IF_LEVEL) {
	yyerror("Too many nested IF's");
    } else {
	ID  id = ST_LookupNoLen(symbols, strings, identifier);
	if ((wantDef && id != NullID) || (!wantDef && id == NullID)) {
	    ifStack[++iflevel] = 1;
	} else {
	    /*
	     * Record a false IF and go to an ELSE or ENDIF
	     */
	    ifStack[++iflevel] = 0;
	    ScanToEndif(TRUE);
	}
    }
}


/***********************************************************************
 *				ScanToEndif
 ***********************************************************************
 * SYNOPSIS:	    Skip to the ENDIF (or ELSE if orElse is TRUE) 
 *		    corresponding to this IF.
 * CALLED BY:	    HandleIF on failed conditional
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Characters are discarded. The terminating token is
 *	    	    pushed back into the input stream.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/89		Initial Revision
 *
 ***********************************************************************/
void
ScanToEndif(int orElse)
{
    int	    	    nesting=0;	/* Level of IF nesting */
    int	    	    c;	    	/* Current character */
    int             opp;   	/* Conditional opcode, if any */
    char    	    word[MAX_TOKEN_LENGTH]; /* Buffer for scanning of token */
    char    	    *cp2;   	/* Address in same */

    cp2 = word;			/* Be quiet, GCC (this does actually get
				 * set to something in word whenever opp
				 * is set to 1, and that's when it's used) */

    while (1) {
	/*
	 * Skip to the next identifier by looking for a character that
	 * can begin one. 
	 */
	while(!isfirstid(c = input()) && (c != EOF)) {
	    if (c == '#') {
		/*
		 * Skip over a comment.
		 */
		do {
		    c = input();
		} while (c != '\n' && c != EOF);
		
		/*
		 * Fall through to handle the newline, but break out if
		 * hit the end of the file.
		 */
		if (c == EOF) {
		    yyerror("end-of-file in false conditional");
		    opp = 0;
		    break;
		}
	    }
	    
	    if (c == '\n') {
		yylineno++;
	    }
	}
	
	/*
	 * Got an ID character or an end-of-file...
	 */
	if (isfirstid(c)) {
	    /*
	     * Hit the start of an identifier. Scan it off into word,
	     * downcasing it as we go, as that's what we need to do for
	     * the keywords for which we search.
	     */
	    
	    cp2 = word;

	    do {
		if (isupper(c)) {
		    *cp2++ = tolower(c);
		} else {
		    *cp2++ = c;
		}
		c = input();
	    } while (isotherid(c));

	    *cp2 = '\0';	/* null terminate */
	    
	    /*
	     * Restore extra character to the input
	     */
	    unput(c);
	    
	    if (!strncmp(word, "endif", cp2-word)) {
		opp = 1;
		if (nesting-- == 0) {
		    /*
		     * If no more nesting, we're done.
		     */
		    break;
		}
	    } else if (!nesting
		       && (!strncmp(word, "else", cp2-word))
		       && orElse) {
		opp = 1;
		/*
		 * Hit an ELSE at the highest level and we're allowed to
		 * stop on an else, so get out.
		 */
		break;
	    } else if (!strncmp(word, "ifdef", cp2-word) ||
		       !strncmp(word, "ifndef", cp2-word))
	    {
		opp = 1;
		/*
		 * Another nested IF (yech). Up the nesting level and
		 * keep going.
		 */
		nesting++;
	    } else {
		/*
		 * If not at the start of the line (barring whitespace),
		 * this line can't contain the end or anything nested -- skip
		 * to the end to avoid running into ghosts (e.g. in comments
		 * or %out's)
		 */
		while ((c = input()) != '\n' && (c != EOF)) {
		    ;
		}
		if (c == EOF) {
		    /*
		     * yrg. EOF -- bitch and get out
		     */
		    yyerror("end-of-file in false conditional");
		    opp = 0;
		    break;
		} else {
		    opp = 1;
		    yylineno++;
		}
	    }
	} else if (c == EOF) {
	    /*
	     * yrg. EOF -- bitch and get out
	     */
	    yyerror("end-of-file in false conditional");
	    opp = 0;
	    break;
	}
    }

    if (opp) {
	/*
	 * Broke out properly -- push the token back into the input stream
	 */
	while (--cp2 >= word) {
	    unput(*cp2);
	}
	unput('\n');
	yylineno -= 1;
    }
}
