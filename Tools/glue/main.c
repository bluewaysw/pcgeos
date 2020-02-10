/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Tools/glue -- Driver Function
 * FILE:	  main.c
 *
 * AUTHOR:  	  Adam de Boor: Sep 29, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	main	    	    Entry point and driving force
 *	Notify	    	    Notify user of something
 *	NotifyInt   	    Ditto, but takes a va_list rather than a
 *	    	    	    variable number of args.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	9/29/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Main driver function for glue. Also, any utility functions that
 *	won't fit anywhere else.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: main.c,v 3.49 96/07/08 17:28:12 tbradley Exp $";
#endif lint

#include    <config.h>
#include    "glue.h"
#include    "obj.h"
#include    "output.h"
#include    "sym.h"
#include    "geo.h"
#include    "library.h"

#define Boolean SpriteBoolean
#define Address SpriteAddress
#include    <hash.h>
#undef Boolean
#undef Address

#include    <fileargs.h>
#include    <compat/string.h>
#include    <vector.h>
#include    <errno.h>
#if defined(unix)
# include    <sys/signal.h>
#endif
#include    <ctype.h>
#include    <compat/stdlib.h>
#include    <string.h>

#if defined _WIN32
unsigned long __stdcall GetTickCount(void);
#endif /* defined _WIN32 */

/*
 *The malloc functions are using fprintf as a callback and since
 *the Sun headers suck here's the prototype
 */
#if defined(unix)
extern int fprintf(FILE *stream, char *format, ...);
#endif /*defined(unix)*/

word	    	serialNumber;
FileOps	    	*fileOps;

int	    	mustBeGeode=0;	/* Assume not */
SegDesc	    	*entrySeg;  	/* Segment in which entry point lies */
word	    	entryOff;   	/* Offset in segment at which entry point
				 * lies */
SegDesc	    	*globalSeg; 	/* Nameless global segment */
int	    	numAddrSyms;	/* Number of defined address-bearing symbols */
int	    	errors;	    	/* Number of errors so far */
int	    	debug;	    	/* Set if debugging output enabled */
int	    	entryGiven=FALSE;   /* Set if entry point encountered */


VMHandle    	symbols;    	/* VM file to hold final symbol info */
VMBlockHandle	strings;    	/* Block handle of string table in symbols */

char	    	copyright[COPYRIGHT_SIZE] = DEFCOPYRIGHT;

int	    	discardableDgroup = FALSE;  	/* Flag to give an error if
						 * a segment relocation to
						 * dgroup is encountered */
int	    	mapSharableRelocations = FALSE;	/* Flag to map relocations
						 * from shared to non-shared
						 * resources to be mapped
						 * to resource IDs */
int  	    	noLMemLineNumbers = FALSE;  	/* Flag to not output line
						 * numbers for lmem segments,
						 * thus reducing the number of
						 * blocks required for a
						 * symbol file */
int	    	geosRelease = 2;    /* Assume linking for 2.0... */

int	    	dbcsRelease = 0;    /* Assume linking for SBCS */

Boolean	    	oldSymfileFormat = TRUE;

/*
 * These are global for cleanup purposes
 */
static char    	*outfile;	/* Name of output file */
static char    	*symfile;	/* Name of .sym file */
char 	    	*ldfOutputDir;	/* Directory to output .ldf file, if any */

/*
 * Variables for the temporary source map, the one that holds the line-number
 * ranges for each source file.
 */
static Hash_Table   	tsrcMap;

typedef struct {
    SegDesc *sd;
    int	    start;
    int	    end;
} TSrcMapEntry;


/*
 * The type of file to produce is specified via a -O<c> flag, where <c> is
 * a single character that discriminates among the various choices. If the
 * FileOps record specifies the file type requires an additional parameter
 * file, the file should follow the -O flag. The first entry in the table
 * below is the default file type, should no -O flag be given.
 */
static const struct {
    char    spec;   	/* Character to match following -O */
    FileOps *ops;   	/* File operation record for file type */
}	outTypes[] = {
    {'e',    	&exeOps},    /* MS-DOS segmented executable */
    {'c',    	&comOps},    /* MS-DOS simple executable */
    {'g',    	&geoOps},    /* PC/GEOS executable */
    {'v',    	&vmOps},    /* PC/GEOS VM file */
    {'k',    	&kernelOps}, /* PC/GEOS kernel (.exe but special massaging
			     * of segments required) */
    {'f',    	&fontOps},   /* PC/GEOS font file */
    {'d',    	&rawOps}    /* Raw data (gstrings, logos, etc.) */
};

/*
 * Object file loading definitions. objProcs is indexed by ObjFileType
 * returned by Obj_Open.
 */
static const struct {
    ObjLoadProc	*pass1;
    ObjLoadProc	*pass2;
} objProcs[] = {
    { Pass1VM_Load, Pass2VM_Load, },
    { Pass1MS_Load, Pass2MS_Load, },
    { Pass1MSL_Load, Pass2MSL_Load, },
};


/***********************************************************************
 *                              ustrcmp
 ***********************************************************************
 * SYNOPSIS:      Perform an unsigned (case-insensitive) string comparison
 * CALLED BY:     MapFilename
 * RETURN:        <0 if s1 is less than s2, 0 if they're equal and >0 if
 *                s1 is greater than s2. Upper- and lower-case letters are
 *                equivalent in the comparison.
 *
 * SIDE EFFECTS:  None.
 *
 * STRATEGY:
 *      Subtract each character in s1 from its corresponding character
 *      in s2 in turn. Save that difference in case the strings are unequal.
 *
 *      If the characters are different, and the one that might be upper case
 *      actually is a letter, map that upper-case letter to lower case and
 *      subtract again (if the difference is < 0, *s1 must come before *s2 in
 *      the character set and vice versa if the difference is > 0).
 *
 *      If the characters are still different, return the original difference.
 *
 * REVISION HISTORY:
 *      Name    Date            Description
 *      ----    ----            -----------
 *      ardeb   8/27/88         Initial Revision
 *
 ***********************************************************************/
int
ustrncmp(const char *s1, const char *s2, unsigned n)
{
    int     diff;
    int     c1, c2;

    while ((c1 = *s1) != '\0' && (c2 = *s2) != '\0' && (n > 0)) {
        diff = c1 - c2;
        if (diff < 0) {
            if (!isalpha(c1) || (tolower(c1) - c2)) {
                return(diff);
            }
        } else if (diff > 0) {
            if (!isalpha(c2) || (c1 - tolower(c2))) {
                return(diff);
            }
        }
        s1++, s2++;
	n--;
    }

    return(n != 0);
}

/***********************************************************************
 *				RenameFileSrcMapEntryy
 ***********************************************************************
 * SYNOPSIS:	   Changes the key (source file name) in the sources
 *                 hash map. We assume that the old name entry is
 *		   actually there before the call, otherwise assert.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
void
RenameFileSrcMapEntry(ID oldName, ID newName)
{
    Hash_Entry	    *he, *he2;
    Boolean 	    new;
    Vector	    v;
    
    he = Hash_FindEntry(&tsrcMap, (SpriteAddress)oldName);		
    if(he) {
	v = Hash_GetValue(he);
	Hash_SetValue(he, NULL);
	he2 = Hash_CreateEntry(&tsrcMap, (SpriteAddress)newName, &new);
	assert(new);
	Hash_SetValue(he2, v);
	Hash_DeleteEntry(&tsrcMap, he);
    }
    else {
    	assert(FALSE);
    }
}

/***********************************************************************
 *				AddSrcMapEntry
 ***********************************************************************
 * SYNOPSIS:	    Record another SrcMap entry needed for the passed
 *	    	    source file.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/17/91		Initial Revision
 *
 ***********************************************************************/
void
AddSrcMapEntry(ID   fileName, SegDesc *sd, int start, int end)
{
    Hash_Entry	    *he;
    Vector  	    v;
    Boolean 	    new;
    int	    	    i;
    TSrcMapEntry    *tsme;
    TSrcMapEntry    newtsme;


    /*
     * Find or create the entry for this file in the range map we're building.
     */
    he = Hash_CreateEntry(&tsrcMap, (SpriteAddress)fileName, &new);
    if (new) {
	/*
	 * Not there before, so create a vector to hold the TSrcMapEntry
	 * structures we need for the beast.
	 */
	v = Vector_Create(sizeof(TSrcMapEntry), ADJUST_ADD, 10, 10);
	Hash_SetValue(he, v);
    } else {
	v = (Vector)Hash_GetValue(he);
    }

    for (tsme = (TSrcMapEntry *)Vector_Data(v), i = 0;
	 i < Vector_Length(v);
	 i++, tsme++)
    {
	if (start <= tsme->start && end >= tsme->end) {
	    /*
	     * New range encompasses this one. Take the existing range out
	     * of the new one and recurse on the two remaining pieces of the
	     * new range.
	     */
	    int	    endprime, startprime;

	    endprime = tsme->start-1;
	    startprime = tsme->end+1;

	    if (start <= endprime) {
		AddSrcMapEntry(fileName, sd, start, endprime);
	    }
	    if (startprime <= end) {
		AddSrcMapEntry(fileName, sd, startprime, end);
	    }
	    return;
	} else if (tsme->start <= start && tsme->end >= end) {
	    /*
	     * New range is inside existing range. Split existing range into
	     * two and insert new range in the middle.
	     */
	    if (start == tsme->start) {
		if (end == tsme->end) {
		    /*
		     * Cope with weird things like vidmem that assemble the
		     * same file more than once.
		     */
		    return;
		}
		/*
		 * Take over the first part of the range, as the existing range
		 * just has it from having had another range punched out of
		 * it.
		 */
		tsme->start = end+1;
		newtsme.sd = sd;
		newtsme.start = start;
		newtsme.end = end;
		Vector_Insert(v, i, (Address)&newtsme);
	    } else if (end == tsme->end) {
		/*
		 * Take over the last part of the range, as the existing range
		 * just has it from having had another range punched out of it.
		 */
		tsme->end = start-1;
		newtsme.sd = sd;
		newtsme.start = start;
		newtsme.end = end;
		Vector_Insert(v, i+1, (Address)&newtsme);
	    } else {
		/*
		 * Proper subset -- fracture existing range into two, inserting
		 * the low half before the top half.
		 */
		newtsme.sd = tsme->sd;
		newtsme.start = tsme->start;
		newtsme.end = start-1;
		tsme->start = end+1;
		Vector_Insert(v, i, (Address)&newtsme);

		/*
		 * Insert new range between the two.
		 */
		newtsme.sd = sd;
		newtsme.start = start;
		newtsme.end = end;
		Vector_Insert(v, i+1, (Address)&newtsme);
	    }
	    return;
	} else if (end < tsme->start) {
	    /*
	     * Hit where an overlap might be, and there's none, so just insert
	     * the thing here and have done.
	     */
	    newtsme.sd = sd;
	    newtsme.start = start;
	    newtsme.end = end;
	    Vector_Insert(v, i, (Address)&newtsme);
	    return;
	}
    }

    /*
     * Outside all ranges.
     */
    newtsme.sd = sd;
    newtsme.start = start;
    newtsme.end = end;
    Vector_Add(v, VECTOR_END, (Address)&newtsme);
}


/***********************************************************************
 *				CleanUp
 ***********************************************************************
 * SYNOPSIS:	    Clean up on receiving an evil signal
 * CALLED BY:	    SIGTERM, SIGINT, SIGHUP
 * RETURN:	    Never
 * SIDE EFFECTS:    output file(s) is(are) removed and the process exits
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 8/89	Initial Revision
 *
 ***********************************************************************/
static void
CleanUp(void)
{
    (void)unlink(outfile);
    (void)unlink(symfile);

    exit(1);
}

/***********************************************************************
 *				NotifyInt
 ***********************************************************************
 * SYNOPSIS:	    Notify the user of a momentous occasion, but take
 *	    	    a varargs list instead of ...
 * CALLED BY:	    Notify and others
 * RETURN:	    Nothing
 * SIDE EFFECTS:    errors is incremented if why is NOTIFY_ERROR
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
NotifyInt(NotifyType	why,	/* What are you telling me? */
	  char	    	*fmt,	/* Format for message */
	  va_list   	args)	/* Args for format */
{
    /*
     * First do the type-specific things...
     */
    if (why == NOTIFY_ERROR) {
	/*
	 * Record another error as having happened
	 */
#if defined (unix)
	fprintf(stderr, "error: ");
#else
	fprintf(stderr, "Error ");
#endif
	errors++;
    } else if (why == NOTIFY_WARNING) {
	/*
	 * Tell the user this is only a warning.
	 */
#if defined(unix)
	fprintf(stderr, "warning: ");
#else
	fprintf(stderr, "Warning ");
#endif
    } else if (why == NOTIFY_DEBUG && !debug) {
	/*
	 * Debugging not enabled -- just return.
	 */
	return;
    }

    /*
     * Send the message to stderr
     */
    vfprintf(stderr, fmt, args);

    /*
     * If not a debug message, spew a newline out too.
     */
    if (why != NOTIFY_DEBUG && why != NOTIFY_PREFACE) {
	putc('\n', stderr);
    }
}



/***********************************************************************
 *				Notify
 ***********************************************************************
 * SYNOPSIS:	    Notify the user of a momentous occasion
 * CALLED BY:	    Everyone
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None (but q.v. NotifyInt)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/28/89		Initial Revision
 *
 ***********************************************************************/
void
Notify(NotifyType   why,
       char 	    *fmt,
       ...)
{
    va_list args;

    va_start(args, fmt);

    NotifyInt(why, fmt, args);

    va_end(args);
}

/***********************************************************************
 *				Pass2GetFileLine
 ***********************************************************************
 * SYNOPSIS:	    Map a segment and offset to the proper file and line
 *	    	    number
 * CALLED BY:	    Pass2_RelocError, Pass2_RelocWarning
 * RETURN:	    *filePtr and *linePtr filled in.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/17/89	Initial Revision
 *
 ***********************************************************************/
static void
Pass2GetFileLine(SegDesc    *sd,    	    /* Segment to search */
		 word	    offset,    	    /* Actual offset in segment */
		 ID 	    *filePtr,	    /* Place to store file name */
		 int	    *linePtr)	    /* Place to store line number */
{
    ObjLineHeader   	*olh;	    /* Header for current line block */
    ObjLine 	    	*ol;	    /* Current line to check */
    VMBlockHandle   	cur;	    /* Handle of current line block */
    ID	    	    	file;	    /* Actual filename */
    ID	    	    	cfile;	    /* Current file name */
    int	    	    	line;	    /* Most promising/actual line number */
    ObjAddrMapHeader	*oamh;
    ObjAddrMapEntry 	*oame;

    file = NullID;
    line = 0;

    /*
     * If the thing is a subsegment, find the real segment created from the
     * group in which the subsegment lies. The line map has been moved over
     * there...
     */
    if (sd->type == S_SUBSEGMENT) {
	sd = Seg_FindPromotedGroup(sd);
    }

    if (sd->lineMap != 0) {
	int 	i;

	oamh = (ObjAddrMapHeader *)VMLock(symbols, sd->lineMap,
					  (MemHandle *)NULL);
	oame = (ObjAddrMapEntry *)(oamh+1);
	i = oamh->numEntries;

	while (i > 0 && oame->last < offset) {
	    i--, oame++;
	}
	while (i > 0) {
	    word	n;

	    cur = oame->block;

	    olh = (ObjLineHeader *)VMLock(symbols, cur,
					  (MemHandle *)NULL);

	    n = olh->num;

	    ol = (ObjLine *)(olh+1);
	    cfile = *(ID *)ol;

	    ol++,n--;
	    while (n > 0) {
		if (ol->line == 0) {
		    /*
		     * File change -- record the new file only in 'cfile'.
		     * If the next line number record is still below
		     * the offset, it will be transfered to 'file' then.
		     */
		    ol++;
		    cfile = *(ID *)ol++;
		    n -= 2;
		} else if (ol->offset > offset) {
		    /*
		     * Passed the offset. file and line already set up
		     * properly, so break out now.
		     */
		    VMUnlock(symbols, cur);
		    goto got_it;
		} else {
		    file = cfile;
		    line = ol->line;
		    ol++, n--;
		}
	    }
	    /*
	     * Keep looping until we're certain we're past the thing. If
	     * last is equal to offset, the next block could contain entries
	     * that are equal to offset as well.
	     */
	    VMUnlock(symbols, cur);
	    if (oame->last > offset) {
		break;
	    }
	    oame++, i--;
	}
	VMUnlock(symbols, sd->lineMap);
    }

got_it:

    *filePtr = file;
    *linePtr = line;
}


/***********************************************************************
 *				Pass2_RelocError
 ***********************************************************************
 * SYNOPSIS:	    Give an error message for a relocation, providing,
 *	    	    by means of our wonderful line number maps, the
 *	    	    file and line number at which the error occurred.
 * CALLED BY:	    Pass2RelOff
 * RETURN:	    Nothing
 * SIDE EFFECTS:    errors is incremented by NotifyInt
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
Pass2_RelocError(SegDesc    *sd,    	/* Segment in which relocation was
					 * occurring */
		 int 	    offset, 	/* Offset at which... */
		 char	    *fmt,   	/* Format string */
		 ...)	    	    	/* Other args */
{
    va_list 	    args;	    /* Arg list for NotifyInt */
    ID	    	    file;   	    /* File in which error occurred */
    int	    	    line;   	    /* Line at which it occurred */

    /*
     * Adjust for base of current segment piece.
     */
    offset += sd->nextOff - sd->foff + sd->grpOff;

    Pass2GetFileLine(sd, offset, &file, &line);

    /*
     * Preface the error message with the file and line number in a format
     * emacs can understand (always important :)
     */
#if defined(unix)
    Notify(NOTIFY_PREFACE, "file \"%i\", line %d: ", file, line);
#else
    Notify(NOTIFY_PREFACE, "Error %i %d: ", file, line);
#endif

    /*
     * Produce the error message our caller wants to give.
     */
    va_start(args, fmt);

    NotifyInt(NOTIFY_ERROR, fmt, args);

    va_end(args);
}

/***********************************************************************
 *				Pass2_RelocWarning
 ***********************************************************************
 * SYNOPSIS:	    Give a warning message for a relocation, providing,
 *	    	    by means of our wonderful line number maps, the
 *	    	    file and line number at which the error occurred.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/19/89	Initial Revision
 *
 ***********************************************************************/
void
Pass2_RelocWarning(SegDesc    *sd,    	/* Segment in which relocation was
					 * occurring */
		   int 	    offset, 	/* Offset at which... */
		   char	    *fmt,   	/* Format string */
		   ...)	    	    	/* Other args */
{
    va_list 	    args;	    /* Arg list for NotifyInt */
    ID	    	    file;   	    /* File in which error occurred */
    int	    	    line;   	    /* Line at which it occurred */

    /*
     * Adjust for base of current segment piece.
     */
    offset += sd->nextOff - sd->foff + sd->grpOff;

    Pass2GetFileLine(sd, offset, &file, &line);

    /*
     * Preface the error message with the file and line number in a format
     * emacs can understand (always important :)
     */
#if defined(UNIX)
    Notify(NOTIFY_PREFACE, "file \"%i\", line %d: ", file, line);
#else
    Notify(NOTIFY_PREFACE, "Warning %i %d: ", file, line);
#endif

    /*
     * Produce the error message our caller wants to give.
     */
    va_start(args, fmt);

    NotifyInt(NOTIFY_WARNING, fmt, args);

    va_end(args);
}


/***********************************************************************
 *				usage
 ***********************************************************************
 * SYNOPSIS:	    Tell the user what s/he can give us as args, then die.
 * CALLED BY:	    main
 * RETURN:	    never
 * SIDE EFFECTS:    program exits (a big side effect, if you ask me)
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/29/89		Initial Revision
 *
 ***********************************************************************/
volatile void
usage(char  *cmd, char *msg)
{
#if defined(__GNUC__)
    extern volatile void exit(int);
#endif
    int	    i;
    static struct {
	char	*flag;
	char	*msg;
    } others[] = {
	{"-o <outFile>", "specify the name of the output file"},
	{"-m", "create some sort of map of the output file's contents"},
	{"-L<dir>", "specify a directory in which to find libraries"},
	{"-Wunref", "warn of any global, unreferenced symbols"},
	{"-N <notice>", "specify 32-character copyright notice for file"},
	{"-r","map segment relocations to non-shared resources to resource IDs"},
	{"-G <major>", "specify the major release number of the PC/GEOS system"},
	{"-z", "output resouce number info and longname into rsc.rsc"},
	{"-f", "create old format symbol file"},
	{"-F<dir>", "specify product directory for .ldf and rsc.rsc file"}
    };

    /*
     * Print explanatory message, if any.
     */
    if (msg != NULL) {
	fprintf(stderr, "%s: %s\n", cmd, msg);
    }

    /*
     * Provide usage summary
     */
    fprintf(stderr, "usage: %s <flags> <objFile>+ [-l<objFile>]*\n",
	    	cmd);
    fprintf(stderr, "Those obj files passed in with a -l flag are only linked \n");
    fprintf(stderr, "in if they actually contain referenced symbols\n");
    fprintf(stderr, "Flags for all types of output files:\n");
    for (i = 0; i < sizeof(others)/sizeof(others[0]); i++) {
	fprintf(stderr, "\t%-15s%s\n", others[i].flag, others[i].msg);
    }
    fprintf(stderr, "\n");
    fprintf(stderr, "File Type   Output Flag     Other Flags\n");
    fprintf(stderr, "---------------------------------------\n");
    for (i = 0; i < sizeof(outTypes)/sizeof(outTypes[0]); i++) {
	FileOps	*ops = outTypes[i].ops;
	int 	j;

	fprintf(stderr, ".%-11s-O%c %-12s", ops->suffix,
		outTypes[i].spec,
		(ops->flags & FILE_NEEDPARAM) ? "<paramFile>" : "");

	if (ops->options) {
	    for (j = 0; ops->options[j].opt != '\0'; j++) {
		switch(ops->options[j].type) {
		    case OPT_NOARG:
			fprintf(stderr, " -%c", ops->options[j].opt);
			break;
		    case OPT_INTARG:
			fprintf(stderr, " -%c <%s>", ops->options[j].opt,
				(char *) (ops->options[j].argName ?
				 ops->options[j].argName : "n"));
			break;
		    case OPT_STRARG:
			fprintf(stderr, " -%c <%s>", ops->options[j].opt,
				(char *) (ops->options[j].argName ?
				 ops->options[j].argName : "str"));
			break;
		}
	    }
	}
	fprintf(stderr, "\n");
    }

    /*
     * Die horribly
     */
    exit(1);
}

/***********************************************************************
 *				InterPass
 ***********************************************************************
 * SYNOPSIS:	    Driving function for figuring out the layout of the
 *	    	    executable, opening up the streams necessary to write
 *	    	    the thing, etc.
 *
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/11/89	Initial Revision
 *
 ***********************************************************************/
static void
InterPass(char	    *outfile,	    /* Name of output file */
	  char	    *paramfile,	    /* Parameters file, if any */
	  char	    *mapfile)	    /* Map file, if map is to be made */
{
    int	    	    size;   	    /* Total size of output file */
    VMBlockHandle   map;    	    /* Handle of map block */
    ObjHeader	    *hdr;   	    /* Header to fill in */
    ObjSegment 	    *s;	    	    /* External segment descriptor */
    ObjGroup   	    *g;	    	    /* External group descriptor */
    int	    	    mapSize;	    /* Size of map block */
    int	    	    i;	    	    /* General index */
    int	    	    numMods;	    /* Number of module symbols to create */
    VMBlockHandle   curSMBlock;	    /* Handle of current SrcMap block */
    unsigned   	    nextSMOffset;   /* Offset of next available byte in same */
    SymUndef	    *sup;   	    /* pointer for going down */

    /*
     * If our two common segments have been created, allocate room for
     * any beasties that remain undefined in them...
     */
    if (seg_FarCommon != (SegDesc *)0) {
	Sym_AllocCommon(seg_FarCommon);
    }
    if (seg_NearCommon != (SegDesc *)0) {
	Sym_AllocCommon(seg_NearCommon);
    }

    /*
     * make a run through the segments seeing if any of the library segments
     * have undefined symbols, if so then link in the library needed
     */


    if (fileOps->flags & FILE_AUTO_LINK_LIBS) {
	for (i = 0; i < seg_NumSegs; i++)
	{
	    SegDesc	    	*sd;

	    sd = seg_Segments[i];
	    if (sd->combine == SEG_LIBRARY)
	    {
		Boolean	doLink = FALSE;
		Boolean	noload = TRUE;

		/*
		 * Any undefined symbol in this segment causes us to link
		 * the thing in, but we only force the library to be loaded
		 * at run-time if the symbol is something other than a
		 * PROTOMINOR symbol.
		 */
		for (sup = symUndefHead; sup != NULL; sup = sup->next) {
		    if (sd->syms == sup->table)
		    {
			doLink = TRUE;
			if (sup->sym.type != OSYM_PROTOMINOR) {
			    noload = FALSE;
			    /*
			     * We don't need to search farther once we've seen
			     * a non-protominor symbol undefined, as we're not
			     * going to alter our decision on how to link the
			     * library in after this.
			     */
			    break;
			}
		    }
		}
		if (doLink) {
		    if (Library_Link(ST_Lock(symbols, sd->name),
				     noload ? LLT_DYNAMIC : LLT_ON_STARTUP,
				     GA_LIBRARY) == LLV_FAILURE)
		    {
			/*
			 * Let the user know we were unable to find any of the
			 * undefined symbols in the segment.
			 */
			for (sup = symUndefHead; sup != NULL; sup = sup->next) {
			    if (sd->syms == sup->table) {
				Notify(NOTIFY_WARNING,
				       "In library %i: %i undefined",
				       sd->name, sup->sym.name);
			    }
			}
		    }
		    ST_Unlock(symbols, sd->name);
		}
	    }
	}
    }

    /*
     * Shrink the final symbol and type blocks for each segment now so
     * output types that merge group-segments together needn't worry about it.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	MemHandle   	mem;
	SegDesc	    	*sd;
	ObjSymHeader	*osh;

	sd = seg_Segments[i];

	if (sd->symTNext) {
	    (void)VMLock(symbols, sd->symT, &mem);
	    (void)MemReAlloc(mem, sd->symTNext, 0);
	    MemInfo(mem, (genptr *)&osh, 0);
	    osh->num = (sd->symTNext-sizeof(ObjSymHeader))/sizeof(ObjSym);
	    VMUnlockDirty(symbols, sd->symT);
	}
	if (sd->typeNext >= 0) {
	    ObjSymHeader    *osh;
	    ObjTypeHeader   *oth;

	    /*
	     * If the block is unused, we still can't biff it, as someone
	     * could (justifiably) just lock down the type block for a symbol
	     * even if there are no ObjType records in it, so instead we
	     * set typeNext to 1 to cause the block to be resized to 1 byte,
	     * instead of none.
	     */
	    if (sd->typeNext == 0) {
		sd->typeNext = sizeof(ObjTypeHeader);
	    }
	    osh = (ObjSymHeader *)VMLock(symbols, sd->symT, (MemHandle *)NULL);
	    (void)VMLock(symbols, osh->types, &mem);
	    (void)MemReAlloc(mem, sd->typeNext, 0);
	    MemInfo(mem, (genptr *)&oth, 0);
	    oth->num = (sd->typeNext-sizeof(ObjTypeHeader))/sizeof(ObjType);
	    VMUnlockDirty(symbols, osh->types);
	    VMUnlock(symbols, sd->symT);
	}
	if (sd->lineT != 0) {
	    Out_FinishLineBlock(sd, sd->lineT);
	}
    }

    /*
     * Call the output-specific function to prepare things.
     */
    size = (*fileOps->prepare)(outfile, paramfile, mapfile);

    /*
     * Zero size indicates error
     */
    if (size == 0) {
	return;
    }

    /*
     * Initialize output buffer.
     */
    Out_Init(size);

    /*
     * Now layout the symbol file's map block properly. Any segment/group
     * arrangement should have been performed by now.
     */
    mapSize = sizeof(ObjHeader) + seg_NumSegs * sizeof(ObjSegment);
    for (i = 0; i < seg_NumGroups; i++) {
	mapSize += OBJ_GROUP_SIZE(seg_Groups[i]->numSegs);
    }

    map = VMAlloc(symbols, mapSize, OID_MAP_BLOCK);

    /*
     * Record the map block for Swat
     */
    VMSetMapBlock(symbols, map);

    /*
     * Initialize the header fields
     */
    hdr = (ObjHeader *)VMLock(symbols, map, (MemHandle *)NULL);

    if (oldSymfileFormat == TRUE) {
	hdr->magic =    OBJMAGIC;
    } else {
	hdr->magic =    OBJMAGIC_NEW_FORMAT;
    }
    hdr->numSeg =   seg_NumSegs;
    hdr->numGrp =   seg_NumGroups;
    hdr->strings =  strings;

    hdr->srcMap =   Sym_Create(symbols);

    hdr->entry.frame = 0; /* Don't care about entry point */

    s = (ObjSegment *)(hdr+1);

    for (i = 0; i < seg_NumSegs; i++) {
	SegDesc	    *sd = seg_Segments[i];

	sd->offset = ((genptr)s - (genptr)hdr);

	s->name =   sd->name;
	s->class =  sd->class;
	s->align =  sd->alignment;
	s->type =   sd->combine;
	s->size =   sd->size;
	s->data = s->relHead = 0;

	if (sd->combine == SEG_ABSOLUTE) {
	    /*
	     * Absolute segments store their segment in the data field.
	     */
	    s->data = sd->pdata.frame;
	}

	if (sd->addrH) {
	    s->syms = sd->addrH;
	} else {
	    s->syms = sd->symH;
	}
	s->toc =    sd->syms;
	s->lines =  sd->lineMap;
	s->flags =  0;		/* IN_GROUP & IN_DGROUP flags? */
	s++;
    }

    g = (ObjGroup *)s;
    for (i = 0; i < seg_NumGroups; i++) {
	GroupDesc   *gd = seg_Groups[i];
	int 	    j;

	g->name =   	gd->name;
	g->numSegs = 	gd->numSegs;

	for (j = 0; j < gd->numSegs; j++) {
	    g->segs[j] = gd->segs[j]->offset;
	    gd->segs[j]->grpOff = gd->segs[j]->foff - gd->foff;
	}

	g = OBJ_NEXT_GROUP(g);
    }

    /*
     * Now need to modify the ObjSymHeader's for all the segments to contain
     * the segment descriptor offset so the segment of a symbol can be
     * determined. Also need to create OSYM_MODULE symbols in the
     * global segment for all but the global segment, create address maps
     * for all the segments and link the "other" symbols to the end of the
     * address-bearing symbol chain for all segments.
     */

    numMods = 0;
    curSMBlock = 0;
    nextSMOffset = 0;

    for (i = 0; i < seg_NumSegs; i++) {
	VMBlockHandle	cur;	    /* Current symbol block */
	VMBlockHandle	next;	    /* Next symbol block to examine */
	ObjSymHeader	*osh;	    /* Header of current block */
	SegDesc	    	*sd;	    /* Current segment descriptor */
	int 	    	addrBlocks; /* Number of blocks containing address
				     * symbols so we can allocate the
				     * address map for the segment */
	ObjSegment	*s; 	    /* Descriptor in output file */

	sd = seg_Segments[i];

	/*
	 * Any non-library segment gets a MODULE symbol.
	 */
	if (sd->combine != SEG_LIBRARY) {
	    numMods++;
	}

	for (addrBlocks=0, cur=sd->addrH; cur!=0; cur=next, addrBlocks++) {
	    osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	    osh->seg = sd->offset;
	    next = osh->next;
	    if (next == 0) {
		/*
		 * Hit the end of the list. Point the last one to the first
		 * block in "other" symbol list.
		 */
		osh->next = sd->symH;
	    }
	    VMUnlockDirty(symbols, cur);
	}

	for (cur = sd->symH; cur != 0; cur = next) {
	    osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	    osh->seg = sd->offset;
	    next = osh->next;
	    VMUnlockDirty(symbols, cur);
	}

	/*
	 * Form the address map for the segment.
	 */
	s = (ObjSegment *)((genptr)hdr + sd->offset);

	if (addrBlocks) {
	    ObjAddrMapHeader *amh;  	/* Header for the block */
	    ObjAddrMapEntry *ame;   	/* Current map entry */
	    ObjSym  	    *sym;   	/* Symbol for finding the last
					 * address-bearing symbol in the
					 * current block */
	    word    	    n;	    	/* Size of current symbol block */
	    MemHandle	    mem;    	/* Handle for locating same */

	    /*
	     * Allocate a map block based on the number of address-symbol
	     * blocks in the segment.
	     */
	    sd->addrMap =
		s->addrMap = VMAlloc(symbols,
				     sizeof(ObjAddrMapHeader) +
				     (addrBlocks * sizeof(ObjAddrMapEntry)),
				     OID_ADDR_MAP);

	    /*
	     * Lock down and initialize the header.
	     */
	    amh = (ObjAddrMapHeader *)VMLock(symbols, s->addrMap,
					     (MemHandle *)NULL);
	    amh->numEntries = addrBlocks;
	    /*
	     * Point ame at the first entry.
	     */
	    ame = (ObjAddrMapEntry *)(amh+1);

	    for (cur = sd->addrH; cur != sd->symH; cur = next, ame++) {
		/*
		 * Initialize the entry, giving last as -1 so we know when
		 * we encounter the first address-bearing symbol, WHICH WE
		 * WILL ALWAYS DO.
		 */
		ame->block = cur;
		ame->last = 0xffff;

		/*
		 * Lock down the symbol block and point sym past the end
		 * of the block.
		 */
		osh = (ObjSymHeader *)VMLock(symbols, cur, &mem);
		n = osh->num;
		sym = &((ObjSym *)(osh+1))[n];


		for (sym--; ame->last == 0xffff; sym--) {
		    switch(sym->type) {
			case OSYM_VAR:
			case OSYM_CHUNK:
			case OSYM_PROC:
			case OSYM_LABEL:
			case OSYM_LOCLABEL:
			case OSYM_ONSTACK:
			case OSYM_BLOCKSTART:
			case OSYM_BLOCKEND:
			case OSYM_CLASS:
			case OSYM_MASTER_CLASS:
			case OSYM_VARIANT_CLASS:
			    /*
			     * Last address-bearing symbol in the block --
			     * record the address in the block. This will
			     * get us out of the loop as well.
			     */
			    ame->last = sym->u.addrSym.address;
			    break;
		    }
		}
		next = osh->next;
		VMUnlock(symbols, cur);
	    }

	    /*
	     * Release the address map now it's filled in.
	     */
	    VMUnlockDirty(symbols, s->addrMap);
	} else {
	    /*
	     * Initialize the addrMap field to zero since this segment
	     * has no address-bearing symbols.
	     */
	    s->addrMap = 0;
	}

	/*
	 * Add this segment's line mapping to the global source mapping for
	 * the file.
	 */
	if (s->lines != 0) {
	    ObjAddrMapHeader	*oamh;
	    ObjAddrMapEntry 	*oame;
	    int	    	    	n;

	    oamh = (ObjAddrMapHeader *)VMLock(symbols, s->lines,
					      (MemHandle *)NULL);
	    oame = ObjFirstEntry(oamh, ObjAddrMapEntry);
	    n = oamh->numEntries;

	    while (n-- > 0) {
		ObjLineHeader	*olh;
		ObjLine	    	*ol;
		ID  	    	fileName;
		int 	    	nlines;
		int 	    	isFileName = TRUE;
		Vector	    	v;
		VMBlockHandle	block=0;/* Block holding map for this
					 * file */
		word	    	offset;	/* Starting offset of map */
		ObjSrcMapHeader	*osmh;	/* Header for map */
		TSrcMapEntry	*tsmeBase;
		TSrcMapEntry	*tsme = 0;

		olh = (ObjLineHeader *)VMLock(symbols, oame->block,
					      (MemHandle *)NULL);
		ol = ObjFirstEntry(olh, ObjLine);
		nlines = olh->num;

		tsmeBase = 0; osmh = 0;	/* Be quiet GCC (isFileName is always
					 * TRUE the first time through the loop,
					 * so osmh will always be set the
					 * second time through) */
		while (nlines-- > 0) {
		    if (isFileName) {
			/*
			 * Current "line" is actually a file name. Add another
			 * ObjSrcMap entry for the first line/offset in this
			 * group.
			 */
			Hash_Entry  	*he;
			void        	*smBase;/* Base of 'block' */

			fileName = *(ID *)ol++;

			/*
			 * Unlock the map for the previous file, if there is one
			 */
			if (block != 0) {
			    VMUnlockDirty(symbols, block);
			}

			he = Hash_FindEntry(&tsrcMap, (SpriteAddress)fileName);
			assert(he != 0);
			v = (Vector)Hash_GetValue(he);
			tsmeBase = (TSrcMapEntry *)Vector_Data(v);
			tsme = 0;
			/*
			 * See if we've already allocated the map for this
			 * file.
			 */
			if (!Sym_Find(symbols, hdr->srcMap, fileName,
				      &block, &offset, FALSE))
			{
			    /*
			     * Nope. First figure the number of entries we
			     * need to allocate for this source file's map
			     * by consulting the tsrcMap.
			     */
			    int	    	mapSize;
			    unsigned	numEntries;

			    numEntries = Vector_Length(v);

			    mapSize = sizeof(ObjSrcMapHeader) +
				numEntries * sizeof(ObjSrcMap);

			    if (mapSize > OBJ_INIT_SRC_MAP) {
				/*
				 * Map is bigger than a normal-sized SRC_MAP
				 * block is allowed to be -- give it its own
				 * VM block. The map begins at offset 0, and
				 * we don't do anything with the curSMBlock
				 * variables.
				 */
				block = VMAlloc(symbols, mapSize,
						OID_SRC_BLOCK);
				offset = 0;
				smBase = VMLock(symbols, block,
						(MemHandle *)NULL);
			    }
			    else if (nextSMOffset + mapSize < OBJ_MAX_SRC_MAP)
			    {
				/*
				 * There's enough room in the current block to
				 * tack the new map onto its end.
				 */
				if (curSMBlock == 0) {
				    /*
				     * That's because we have no current block.
				     * Allocate a new one and lock it down.
				     */
				    assert(nextSMOffset == 0);
				    block =
					curSMBlock = VMAlloc(symbols, mapSize,
							     OID_SRC_BLOCK);
				    smBase = VMLock(symbols, block,
						    (MemHandle *)NULL);
				} else {
				    /*
				     * The current block is nextSMOffset bytes
				     * long, at the moment, so enlarge it to
				     * hold the new map, too.
				     */
				    MemHandle	mem;

				    block = curSMBlock;
				    smBase = VMLock(symbols, block, &mem);
				    MemReAlloc(mem, nextSMOffset + mapSize, 0);
				    MemInfo(mem, (genptr *)&smBase, (word *)NULL);
				}

				/*
				 * The starting offset is the previous size of
				 * the block. Advance the nextSMOffset pointer
				 * to compensate for the new map.
				 */
				offset = nextSMOffset;
				nextSMOffset += mapSize;
			    } else {
				/*
				 * The new map won't fit in the current block,
				 * while keeping same a reasonable size.
				 * Allocate a new "current" block the size of
				 * the new map. The start of the new map is
				 * offset 0, of course, but here we adjust
				 * nextSMOffset as well.
				 */
				block =
				    curSMBlock = VMAlloc(symbols, mapSize,
							 OID_SRC_BLOCK);
				smBase = VMLock(symbols, block,
						(MemHandle *)NULL);
				offset = 0;
				nextSMOffset = mapSize;
			    }
			    /*
			     * Zero the new map. This sets the map's
			     * numEntries to 0, of course...
			     */
			    osmh = (ObjSrcMapHeader *)((genptr)smBase+offset);
			    bzero((genptr)smBase + offset, mapSize);
			    osmh->numEntries = numEntries;

			    Sym_Enter(symbols, hdr->srcMap, fileName,
				      block, offset);
			} else {
			    /*
			     * Just lock down the existing map.
			     */
			    smBase = VMLock(symbols, block, (MemHandle *)NULL);
			    osmh = (ObjSrcMapHeader *)((genptr)smBase+offset);
			}
			isFileName = FALSE;
		    } else {
			if (ol->line == 0) {
			    /*
			     * Next record is a file name.
			     */
			    isFileName = TRUE;
			} else if (!tsme || ol->line < tsme->start ||
				   ol->line > tsme->end)
			{
			    /*
			     * This one goes outside the preceding range.
			     * Find the range in which it lies.
			     */
			    int	    i;

			    for (i = 0; i < osmh->numEntries; i++) {
				if (tsmeBase[i].end >= ol->line) {
				    ObjSrcMap	*osm;

				    if (tsmeBase[i].start > ol->line) {
					/*
					 * Damn vidmem...
					 */
					break;
				    }

				    /*
				     * Initialize the ObjSrcMap entry for this
				     * range, if not initialized already.
				     * XXX: can it ever have already been
				     * initialized? Not likely...
				     */
				    osm = ObjFirstEntry(osmh, ObjSrcMap)+i;

				    if (osm->line == 0) {
					osm->line = ol->line;
					osm->offset = ol->offset;
					osm->segment = sd->offset;
				    }
				    tsme = &tsmeBase[i];
				    break;
				}
			    }
			}
			ol++;
		    }
		}

		VMUnlockDirty(symbols, block);

		/*
		 * Done with this block of line numbers -- advance to the
		 * next via the address map.
		 */
		VMUnlock(symbols, oame->block);
		oame++;
	    }

	    VMUnlock(symbols, s->lines);
	}
    }

    /*
     * Now destroy the temporary source map in which we accumulated the
     * number of entries needed for each source file.
     */
    Sym_Close(symbols, hdr->srcMap);
    Hash_DeleteTable(&tsrcMap);

    /*
     * Create the OSYM_MODULE symbols in the global table for all known segments
     */
    {
	VMBlockHandle	block;	    /* Block for OSYM_MODULE symbols */
	ObjSymHeader	*osh;	    /* Header of same */
	ObjSym	    	*os;	    /* Current module symbol */
	ObjSymHeader	*nsh;	    /* Header of first block in global's chain*/
	VMBlockHandle	next;	    /* Handle of same */

	block = VMAlloc(symbols,
			sizeof(ObjSymHeader) + (numMods*sizeof(ObjSym)),
			OID_SYM_BLOCK);

	osh = (ObjSymHeader *)VMLock(symbols, block, (MemHandle *)NULL);
	osh->num = numMods;
	osh->seg = sizeof(ObjHeader);

	s = (ObjSegment *)(hdr+1);
	next = s->syms;
	if (next) {
	    /*
	     * Link the new block into the list at the head, using the former
	     * head block's type-description block for its own. We won't be
	     * adding any type descriptions, so life is good.
	     */
	    nsh = (ObjSymHeader *)VMLock(symbols, next, (MemHandle *)NULL);
	    osh->types = nsh->types;
	    assert(osh->seg == nsh->seg);
	    VMUnlock(symbols, next);
	} else {
	    /*
	     * Else we need to allocate an empty type-description block for
	     * this thing (yuck).
	     */
	    ObjTypeHeader   *oth;

	    osh->types = VMAlloc(symbols, sizeof(ObjTypeHeader),
				 OID_TYPE_BLOCK);
	    oth = (ObjTypeHeader *)VMLock(symbols, osh->types,
					  (MemHandle *)NULL);
	    oth->num = 0;	/* We need no type descriptions -- just a
				 * block */
	    VMUnlockDirty(symbols, osh->types);
	}
	osh->next = next;
	s->syms = block;

	os = (ObjSym *)(osh+1);
	s = (ObjSegment *)(hdr+1);
	for (i = 0; i < seg_NumSegs; i++) {
	    if (s->type != SEG_LIBRARY) {
		os->name = s->name;
		os->type = OSYM_MODULE;
		os->flags = OSYM_GLOBAL|OSYM_REF;
		os->u.module.table = s->toc;
		os->u.module.offset = (genptr)s - (genptr)hdr;
		os->u.module.syms = s->syms;
		if (os->name != NullID) {
		    Sym_Enter(symbols, globalSeg->syms, os->name, block,
			      (genptr)os-(genptr)osh);
		}
		os++;
	    }
	    s++;
	}

	VMUnlockDirty(symbols, block);
    }

    VMUnlockDirty(symbols, map);
}


/***********************************************************************
 *				Final
 ***********************************************************************
 * SYNOPSIS:	    Perform final processing, writing out the
 *	    	    executable, closing the symbol file, etc.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    symbols is closed, output buffer flushed....
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
static void
Final(char  *outfile,
      int   warn_unref)
{
    int	    	i;

    /*
     * Write out the executable first.
     */
    Out_Final(outfile);
    if (errors) {
	return;
    }

    /*
     * Shut down the symbol tables for all the remaining segments before
     * closing the symbol file.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	if (warn_unref) {
	    /*
	     * Wants to know of any unreferenced global symbols. Run through
	     * the list of address symbols for the segment and search for
	     * such evil beasties.
	     */
	    VMBlockHandle   cur;
	    VMBlockHandle   next;
	    ObjSymHeader    *osh;
	    ObjSym  	    *os;
	    MemHandle	    mem;
	    word    	    n;
	    int	    	    nameGiven = 0;

	    for (cur = seg_Segments[i]->addrH; cur != 0; cur = next) {
		osh = (ObjSymHeader *)VMLock(symbols, cur, &mem);
		n = osh->num;

		for (os = (ObjSym *)(osh+1); n > 0; n--, os++) {
		    if ((os->flags & (OSYM_GLOBAL|OSYM_REF)) == OSYM_GLOBAL) {
			if (!nameGiven) {
			    Notify(NOTIFY_WARNING,
				   "In segment %i:", seg_Segments[i]->name);
			    nameGiven = 1;
			}
			Notify(NOTIFY_WARNING,
			       "%i defined but never referenced", os->name);
		    }
		}
		next = osh->next;
		VMUnlock(symbols, cur);
		if (cur == seg_Segments[i]->addrT) {
		    break;
		}
	    }
	}

	if (seg_Segments[i]->combine == SEG_LIBRARY) {
	    VMBlockHandle   map = VMGetMapBlock(symbols);
	    ObjHeader	    *hdr;
	    ObjSegment	    *seg;
	    VMBlockHandle   cur, next;

	    hdr = (ObjHeader *)VMLock(symbols, map, (MemHandle *)NULL);
	    seg = (ObjSegment *)((genptr)hdr+seg_Segments[i]->offset);

	    /*
	     * Biff the hash table for the segment first.
	     */
	    seg->toc = 0;
	    Sym_Destroy(symbols, seg_Segments[i]->syms);

	    /*
	     * Now nuke all the symbols for it as well -- Swat doesn't use them
	     */
	    for (cur = seg->syms; cur != 0; cur = next) {
		ObjSymHeader	*osh;

		osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
		next = osh->next;

		VMFree(symbols, cur);
	    }
	    seg->syms = 0;

	    /* No line numbers to free, right? */

	    VMUnlockDirty(symbols, map);
	} else {
	    Sym_Close(symbols, seg_Segments[i]->syms);
	}
    }

    /*
     * Release extra string table space too.
     */
    ST_Close(symbols, strings);

    /*
     * Now close the symbol file, thus writing it to disk.
     */
    VMClose(symbols);
}

/***********************************************************************
 *				Pass1Load
 ***********************************************************************
 * SYNOPSIS:	    Perform first-pass actions for an object file.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    Yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/89		Initial Revision
 *
 ***********************************************************************/
static void
Pass1Load(char	*file)
{
    void    	    *handle;
    ObjFileType	    type;
    int	    	    i;

    handle = Obj_Open(file, NULL, &type, FALSE);

    if (handle == NULL) {
	/*
	 * Obj_Open has already given the error message.
	 */
	return;
    }

    (* objProcs[type].pass1) (file, handle);

    /*
     * Adjust the nextOff field for all concatenatable segments to match their
     * current sizes. This field is used by the Pass1 functions to determine
     * the relocation value for the symbols in the segment in the object file
     * being loaded.
     */
    for (i = 0; i < seg_NumSegs; i++) {
	SegDesc	*sd = seg_Segments[i];

	if ((sd->combine != SEG_ABSOLUTE) && (sd->combine != SEG_COMMON) &&
	    (sd->combine != SEG_GLOBAL) && (sd->combine != SEG_PRIVATE))
	{
	    sd->nextOff = sd->size;
	}
    }
}

/*********************************************************************
 *			LoadMathIfNeeded
 *********************************************************************
 * SYNOPSIS:  if any routines in the file passed in are needed by
 *	      by the App, then link in the file
 * CALLED BY: main
 * RETURN:    if not needed, otherwise return file handle passed in
 * SIDE EFFECTS: file's symbols added to appropriate tables
 * STRATEGY: look for each of the file's strings in the existsing
 *	     table, if any are found than link in the file
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	5/29/92		Initial version
 *
 *********************************************************************/
static Boolean
LoadFileIfNeeded(char	*myfile)
{
    void    	    *handle;
    ObjFileType	    type;

    handle = Obj_Open(myfile, NULL, &type, FALSE);

    if (handle == NULL) {
	/*
	 * Obj_Open has already given the error message.
	 */
	return FALSE;
    }

    if (!Pass1VM_FileIsNeeded(myfile, handle)) {
	return FALSE;
    }

    Pass1Load(myfile);
    return TRUE;
}


/***********************************************************************
 *				Pass2Load
 ***********************************************************************
 * SYNOPSIS:	    Perform second-pass actions for an object file.
 * CALLED BY:	    main
 * RETURN:	    nothing
 * SIDE EFFECTS:    Yeah.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/30/89		Initial Revision
 *
 ***********************************************************************/
static void
Pass2Load(char	*file)
{
    void    	    *handle;
    ObjFileType	    type;

    handle = Obj_Open(file, NULL, &type, FALSE);

    if (handle == NULL) {
	/*
	 * Obj_Open has already given the error message.
	 */
	return;
    }

    (* objProcs[type].pass2) (file, handle);
}

/*********************************************************************
 *			ConvertHexDigit
 *********************************************************************
 * SYNOPSIS: 	convert an ascii hex digit to a numeral value
 * CALLED BY:	main
 * RETURN:
 * SIDE EFFECTS: Program calls usage (if there's an error) and hence exits
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/14/93		Initial version
 *      TB      6/20/96         Added usage invocation on error
 *
 *********************************************************************/
byte
ConvertHexDigit(char num)
{
    byte    result = -1;

    num = toupper(num);
    if (num >= '0' && num <= '9')
    {
	result = (num - '0');
    }
    else if (num >= 'A' && num <= 'F')
    {
	result = (num - 'A') + 10;
    }
    else /*the digit wasn't legal*/
    {
	usage("glue", "Bad escape sequence in -N string.");
    }
    return result;
}


/***********************************************************************
 *				main
 ***********************************************************************
 * SYNOPSIS:	    Entry point and driver for linker
 * CALLED BY:	    UNIX
 * RETURN:	    0 if successful or non-zero if error
 * SIDE EFFECTS:    The program runs :)
 *
 * STRATEGY:
 *	The linking process is divided into two main passes with an
 *	interpass between them to calculate various parameters required
 *	for the second pass using the info gathered by the first pass.
 *
 *	The first pass scans all the object files and libraries, finding
 *	the sizes of the various segments, relocating symbols, resolving
 *	undefined symbols, counting the relocations that will need to
 *	go into the executable.
 *
 *	The interpass reads geode parameters and sets up the geode header,
 *	if creating a geode. It re-orders segments into the same order
 *	microsoft link would place them. It calculates the file offsets
 *	in the executable for all the pieces (segment data, relocations,
 *	etc.).
 *
 *	The second pass scans all the object files again, reading the
 *	data for each segment, relocating it according to the data
 *	in the object file, writing the data and any run-time relocations
 *	out to the executable file.
 *
 *	Finally the map block for the symbol file is written out (the
 *	symbols, strings and line numbers migrated there during pass 1).
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	9/29/89		Initial Revision
 *
 ***********************************************************************/
void
main(argc, argv)
    int	    argc;
    char    **argv;
{
    char    	*paramfile; 	/* Name of file containing geode
				 * parameters */
    char    	*mapfile;   	/* Name of .map file */
    char	*cp;	    	/* General-purpose char pointer */
    short   	status;	    	/* Status of VMOpen of symbol file */
    int	    	i;  	    	/* Index of current object file */
    int	    	mapwanted;  	/* Non-zero if address map desired */
    int	    	firstobj;   	/* Index of first object file */
    int	    	firstlobj;   	/* Index of first conditional obj file */
#if defined(__GNUC__)
    extern volatile void exit(int);
#endif
    int	    	warn_unref; 	/* Warn of unreferenced global syms */
    int	    	dumpmem;    	/* Dump memory-allocation statistics */
    char    	*dumpfile;  	/* Name of file to which to dump stats */
    char    	*dumpsuff;
    int	    	leaveSymOnErr;	/* Debugging flag telling us to leave
				 * the .sym file even on error */
    SegAlias	sa;
    int	    	doDefs=0;   /* Set if -D flag encountered */

#if defined(_MSDOS)
    *stderr = *stdout;
#endif

    if ((argc == 2) && HAS_ARGS_FILE(argv))
    {
	GetFileArgs(ARGS_FILE(argv), &argc, &argv);
    }

    leaveSymOnErr = FALSE;

    /*
     * We don't want to know about failed malloc's as we won't do anything
     * about them except dereference the NULL they return and die horribly.
     */
    malloc_noerr(1);

#if defined(unix)
    /*
     * Catch all nasty signals now.
     */
    if (signal(SIGINT, SIG_IGN) != SIG_IGN) {
	signal(SIGINT, CleanUp);
    }
    if (signal(SIGTERM, SIG_IGN) != SIG_IGN) {
	signal(SIGTERM, CleanUp);
    }
    if (signal(SIGHUP, SIG_IGN) != SIG_IGN) {
	signal(SIGHUP, CleanUp);
    }
#endif /* unix */

    mapfile = outfile = symfile = paramfile = ldfOutputDir = (char *)NULL;
    dumpmem = mapwanted = 0;
    fileOps = NULL;
    warn_unref = 0;

    /*
     * Process our arguments. All flags must come before the list of
     * object files.
     */
#define ARG_MISSING ((i+1 == argc) || argv[i+1][0] == '-')

    for (i = 1; i < argc; i++) {
	if (argv[i][0] != '-') {
	    break;
	}
	switch(argv[i][1]) {
	    case 'L':
		if (argv[i][2]) {
		    Library_AddDir(&argv[i][2]);
		} else if (ARG_MISSING) {
		    usage(argv[0], "-L requires directory argument");
		} else {
		    Library_AddDir(argv[i+1]);
		    i++;
		}
		break;
	    case 'F':
		if (argv[i][2]) {
		    ldfOutputDir = argv[i]+2;
		} else {
		    usage(argv[0], "-F requires directory argument");
		}
		break;
	    case 'o':
		if (ARG_MISSING) {
		    usage(argv[0], "-o requires output file argument");
		} else {
		    outfile = argv[i+1];
		    i++;
		}
		break;
	    case 's':
		if (ARG_MISSING) {
		    usage(argv[0], "-s requires symbol file argument");
		} else {
		    symfile = argv[i+1];
		    i++;
		}
		break;
	    case 'O':
	    {
		int 	j;
		char   	msg[80];

		if (fileOps != NULL) {
		    sprintf(msg, "%s file already specified", fileOps->suffix);
		    usage(argv[0], msg);
		}

		for (j = 0; j < sizeof(outTypes)/sizeof(outTypes[0]); j++) {
		    if (argv[i][2] == outTypes[j].spec) {
			fileOps = outTypes[j].ops;
			break;
		    }
		}
		if (fileOps == NULL) {
		    sprintf(msg, "%s: output type unknown", argv[i]);
		    usage(argv[0], msg);
		}
		if (fileOps->flags & FILE_NEEDPARAM) {
		    if (ARG_MISSING) {
			Notify(NOTIFY_ERROR,
			       	"Missing glue parameter file (.gp file)\n",
			       	0,0);
			exit(1);
		    } else {
			paramfile = argv[i+1];
			i++;
		    }
		}
		break;
	    }
	    case 'm':
		mapwanted = 1;
		break;
            case 'f':
		/* support both formats */
		oldSymfileFormat = FALSE;
		break;
	    case 'z':
		localizationWanted = TRUE;
		break;

	    case 'd':
		dumpmem = 1;
		break;
	    case 'r':
		/*
		 * "-r" causes relocations from shared resources to non-shared
		 * resources to be mapped to resource IDs
		 */
		mapSharableRelocations = 1;
		break;
	    case 'N':
		if (ARG_MISSING) {
		    usage(argv[0], "-N requires copyright notice argument");
		} else {
		    char    *src, *dest;

		    if (strnlen_s((char*)argv[i+1], COPYRIGHT_SIZE) == COPYRIGHT_SIZE) {
			    Notify(NOTIFY_ERROR, "copyright notice is too long!");
			    exit(1);
		    }
		    dest = copyright;
		    src = argv[i+1];
/*		    strncpy(copyright, argv[i+1], sizeof(copyright));
*/
		    while (1)
		    {
			if (*src == '\\')
			{
			    byte    char1, char2;

			    src++;
			    char1 = ConvertHexDigit(*src++);
			    char2 = ConvertHexDigit(*src);
			    *dest =  char1 * 16 + char2;
			}
			else
			{
			    *dest = *src;
			}
			if (*src == '\0')
			{
			    break;
			}
			dest++;
			src++;

		    }
		    i++;
		}
		break;
	    case 'q':
		leaveSymOnErr = TRUE;
		break;
	    case 'G':
		if (ARG_MISSING) {
		    usage(argv[0], "-G requires major number argument");
		} else {
		    geosRelease = atoi(argv[i+1]);
		    i++;
		}
		break;
	    case '2':
		dbcsRelease = TRUE;
		break;
	    case 'D':
		/*
		 * Define a string equate. Dealt with after symbol table
		 * is initialized.
		 */
		if (argv[i][2] == '\0') {
		    usage(argv[0], "-D argument requires symbol name");
		    /*NOTREACHED*/
		}
		doDefs = 1;
		break;
	    case 'n':
		if ((argv[i][2] == 'l') && (argv[i][3] == 'l')) {
		    noLMemLineNumbers = TRUE;
		    break;
		}
		goto default_option;
	    case 'W':
		if (strcmp(&argv[i][2], "unref") == 0) {
		    warn_unref = 1;
		    break;
		} else if (strcmp(&argv[i][2], "all") == 0) {
		    /* Be nice and allow -Wall */
		    warn_unref = 1;
		    break;
		}
		/*FALLTHRU*/
	    default:
	    {
		char	msg[80];
		FileOption	    *opt;

	    default_option:

		for (opt = fileOps ? fileOps->options : NULL;
		     opt && opt->opt != 0;
		     opt++)
		{
		    if (argv[i][1] == opt->opt) {
			switch(opt->type) {
			    case OPT_NOARG: *(int *)opt->argVal = 1; break;
			    case OPT_INTARG:
				if (ARG_MISSING) {
				    sprintf(msg, "%s missing argument",
					    argv[i]);
				    usage(argv[0], msg);
				} else {
				    *(int *)opt->argVal = atoi(argv[i+1]);
				    i++;
				}
				break;
			    case OPT_STRARG:
				if (ARG_MISSING) {
				    sprintf(msg, "%s missing argument",
					    argv[i]);
				    usage(argv[0], msg);
				} else {
				    *(char **)opt->argVal = argv[i+1];
				    i++;
				}
				break;
			}
			break;
		    }
		}
		if (!opt || opt->opt == 0) {
		    sprintf(msg, "%s: option unknown", argv[i]);
		    usage(argv[0], msg);
		}
		break;
	    }
	}
    }

    if (i == argc) {
	usage(argv[0], "No object files specified");
    }

    firstobj = i;

    /*
     * If no output type specified, use the default one recorded in the
     * first element of the outTypes table.
     */
    if (fileOps == NULL) {
	fileOps = outTypes[0].ops;
    }

#if defined _WIN32
    serialNumber = (word) (GetTickCount() / 100);
#else
    serialNumber = time(0);
#endif /* defined _WIN32 */

    /*
     * Figure the name of the output file.
     */
    if (outfile == NULL) {
	/*
	 * No output file given; form it by taking the first object file's
	 * name and replacing its suffix with that of the output file type.
	 */
	outfile = (char *)malloc(strlen(argv[firstobj]) + 1 +
				 strlen(fileOps->suffix)+1);

	strcpy(outfile, argv[i]);

	cp = (char *)rindex(outfile, '.');

	if (cp++ == NULL) {
	    /*
	     * Tack suffix onto the end if none on the object file.
	     */
	    cp = outfile + strlen(outfile);
	    *cp++ = '.';
	}
	strcpy(cp, fileOps->suffix);
    }

#if defined(_MSDOS)
    if (strlen(outfile) > 12)
    {
	char	realname[12];
	char	*rnp;

	if ((rnp=strchr(outfile, '.')) == NULL)
	{
	    strncpy(realname, outfile, 12);
	}
	else
	{
	    int	dif = (rnp-outfile) > 8 ? 8 : rnp-outfile;

	    strncpy(realname, outfile, dif);
	    strncpy(realname+dif, rnp, 4);
	}
	realname[7] = 'E';
	realname[12] = '\0';
	Notify(NOTIFY_WARNING, "Output file name %s too long, using %s\n", outfile, realname);
	strcpy(outfile, realname);
    }
#endif

    /*
     * Figure the name of the symbol file.
     */
    if (symfile == NULL) {
	/*
	 * No symbol file given; form it by taking the output file's
	 * name and replacing its suffix with "sym".
	 */
	symfile = (char *)malloc(strlen(outfile) + 1 + 3 +1);

	strcpy(symfile, outfile);

	cp = (char *)rindex(symfile, '.');

	if (cp++ == NULL) {
	    /*
	     * Tack suffix onto the end if none on the output file.
	     */
	    cp = symfile + strlen(symfile);
	    *cp++ = '.';
	}
	strcpy(cp, "sym");
    }

    /*
     * If a map is desired, figure the name of the map file. We
     * don't open the thing, of course. There are some output types
     * that don't create map files -- they just write the map to stdout.
     */
    if (mapwanted) {
	/*
	 * Form the name by taking the output file's name and replacing its
	 * suffix with "map".
	 */
	mapfile = (char *)malloc(strlen(outfile) + 1 + 3 +1);

	strcpy(mapfile, outfile);

	cp = (char *)rindex(mapfile, '.');

	if (cp++ == NULL) {
	    /*
	     * Tack suffix onto the end if none on the output file.
	     */
	    cp = mapfile + strlen(mapfile);
	    *cp++ = '.';
	}
	strcpy(cp, "map");
    }

    /*
     * If a memory dump is desired, figure the name of the dump file. We
     * don't open the thing until later, though.
     */
    if (dumpmem) {
	/*
	 * Form the name by taking the output file's name and replacing its
	 * suffix with "mem".
	 */
	dumpfile = (char *)malloc(strlen(outfile) + 1 + 6 +1);

	strcpy(dumpfile, outfile);

	cp = (char *)rindex(dumpfile, '.');

	if (cp++ == NULL) {
	    /*
	     * Tack suffix onto the end if none on the output file.
	     */
	    cp = dumpfile + strlen(dumpfile);
	    *cp++ = '.';
	}
	strcpy(cp, "mem");
	dumpsuff = cp+3;
    } else {
	dumpfile = dumpsuff = 0; /* Be quiet GCC (these are only used if
				  * dumpmem is true, and dumpmem doesn't
				  * change from here on out) */
    }

    /*
     * Create the symbol file. The output file will be created during
     * the interpass.
     */
    (void)unlink(symfile);
    symbols = VMOpen(VMO_CREATE_ONLY|FILE_DENY_W|FILE_ACCESS_RW,
		     0, symfile, &status);

    if (symbols == NULL) {
	extern int  sys_nerr;
	//extern char *sys_errlist[];

	fprintf(stderr, "Couldn't open symbol file %s: ", symfile);
	if (status <= sys_nerr) {
	    //fprintf(stderr, "%s\n", sys_errlist[status]);
	} else {
	    fprintf(stderr, "status = %d\n", status);
	}
	exit(1);
    }

    /*
     * Set file for printf %i
     */
    UtilSetIDFile(symbols);

    /*
     * Create the string table for the symbol file.
     */
    strings = ST_Create(symbols);

    numAddrSyms = 0;

    /*
     * Gross hack to deal with the occasional upcased versions of these
     * segments we encounter in MetaWare libraries.
     */

    sa.newName = ST_EnterNoLen(symbols, strings, "cgroup");
    sa.name = ST_EnterNoLen(symbols, strings, "CGROUP");
    sa.aliasMask = SA_NEWNAME;
    Seg_AddAlias(&sa);

    sa.newName = ST_EnterNoLen(symbols, strings, "dgroup");
    sa.name = ST_EnterNoLen(symbols, strings, "DGROUP");
    Seg_AddAlias(&sa);

    /*
     * Initialize the map that holds source-line breakups for the final
     * source map
     */
    Hash_InitTable(&tsrcMap, 0, HASH_ONE_WORD_KEYS, 16);

    if (doDefs) {
	for (i = 1; i < argc; i++) {
	    if (argv[i][0] == '-') {
		switch (argv[i][1]) {
		    case 'o':
			/* Skip following arg */
			i++;
			break;
		    case 'D':
		    {
			ST_EnterNoLen(symbols, strings, &argv[i][2]);
			break;
		    }
		}
	    }
	}
    }

    /*
     * If the output format has a .gp file, load in all the library symbols
     * first so we can determine if an external symbol is in a library for
     * Certain Deficient Object File Formats That Shall Remain Nameless.
     */
    if (fileOps->flags & FILE_USES_GEODE_PARAMS) {
	Parse_GeodeParams(paramfile, outfile, TRUE);
    }
#if 0
    if (geosRelease > 1) {
	GeosFileHeader2	gfh;

	VMGetHeader(symbols, (char *)&gfh);
	gfh.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	gfh.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	bcopy(OBJ_SYMTOKEN, gfh.token.chars, sizeof(gfh.token.chars));
	bcopy("GLUE", gfh.creator.chars, sizeof(gfh.creator.chars));
	bcopy(GH(geodeName), gfh.userNotes, 12);
	VMSetHeader(symbols, (char *)&gfh);
    } else {
	GeosFileHeader	gfh;

	VMGetHeader(symbols, (char *)&gfh);
	gfh.core.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	gfh.core.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	bcopy(OBJ_SYMTOKEN, gfh.core.token.chars, sizeof(gfh.core.token.chars));
	bcopy("GLUE", gfh.core.creator.chars, sizeof(gfh.core.creator.chars));
	VMSetHeader(symbols, (char *)&gfh);
    }
#endif
    /*
     * Create the global segment now. Makes life easier for some object
     * file handlers.
     */
    globalSeg = Seg_AddSegment(0, NullID, NullID, SEG_GLOBAL, 0, 0);

    /*
     * Now load all the given object files for the first pass.
     */
    for (i = firstobj; i < argc && argv[i][0] != '-'; i++) {
	Pass1Load(argv[i]);
    }

    if ((i != argc) && (argv[i][1] != 'l')){
	usage(argv[0], "invalid last argument");
    }

    firstlobj = i;

    /* at the end of the argument list we allow the specifying of an unlimited
     * number of files that will only be linked in if any references to them
     * are being made, this is done using the -l flag and these files must
     * be the last things in the argument list directly following the
     * other obj files.  This code tests each file to see if it's needed,
     * if it's not needed then the first byte of the argv argument is zeroed
     * out (this will always be a '-' to start out with), so that the
     * second pass knows not to bother with them
     */

    while (i < argc && argv[i][0] == '-')
    {
	/* only legal remaining arguments must have -l */
	if (argv[i][1] != 'l')
	{
	    usage(argv[0], "invalid last argument");
    	}
	/* there might not be a space between the -l and the filename */
	if (argv[i][2])
	{
	    if (LoadFileIfNeeded(&argv[i][2]) ==  FALSE)
	    {
		argv[i][0] = 0;	    	/* zero out first byte to signal that*/
	    }	    	    	    	/* the file is not needed */
	}
	else
	{
	    if (ARG_MISSING)
	    {
	    	usage(argv[0], "-l requires file argument");
	    }
	    else
	    {
	    	if (LoadFileIfNeeded(argv[i+1]) == FALSE)
		{
		    argv[i][0] = 0; 	/* zero out first byte to signal that*/
		}   	    	    	/* that the file is not needed */
		i++;
	    }
	}
	i++;
    }

    if (errors) {
	goto err_exit;
    }

    if (dumpmem) {
	FILE	    *df;

	strcpy(dumpsuff, ".p1");
	df = fopen(dumpfile, "w");

	if (df != NULL) {
	    malloc_printstats((malloc_printstats_callback *)fprintf, df);
	    fclose(df);
	    fprintf(stderr, "pass1 memory stats dumped to %s\n", dumpfile);
	}
    }
    InterPass(outfile, paramfile, mapfile);

    if (errors) {
	goto err_exit;
    }

    if (dumpmem) {
	FILE	    *df;

	strcpy(dumpsuff, ".ip");
	df = fopen(dumpfile, "w");

	if (df != NULL) {
	    malloc_printstats((malloc_printstats_callback *)fprintf, df);
	    fclose(df);
	    fprintf(stderr, "interpass memory stats dumped to %s\n", dumpfile);
	}
    }

    for (i = firstobj; i < firstlobj; i++) {
	Pass2Load(argv[i]);
    }

   /*
    * go through and do the second pass on the optional library files that
    * are actually needed
    */
    for (; i < argc; i++)
    {
	/* must start with a '-' */
	if (argv[i][0] == '-')
	{
	    if (argv[i][2])
	    {
		Pass2Load(&argv[i][2]);
	    }
	    else
	    {
		Pass2Load(argv[i+1]);
		i++;
	    }
	}
    }

    /*
     * Call Library_LoadPublished to execute a Pass2 type run over any
     * published routines contained therein.
     */
    Library_LoadPublished();

    /*
     * Now we're ready to write the .ldf file out
     */

    Library_WriteLDF();

    if (errors) {
	goto err_exit;
    }

    if (dumpmem) {
	FILE	    *df;

	strcpy(dumpsuff, ".p2");
	df = fopen(dumpfile, "w");

	if (df != NULL) {
	    malloc_printstats((malloc_printstats_callback *)fprintf, df);
	    fclose(df);
	    fprintf(stderr, "pass2 memory stats dumped to %s\n", dumpfile);
	}
    }

    if (geosRelease > 1) {
	GeosFileHeader2	gfh;

	VMGetHeader(symbols, (char *)&gfh);
	gfh.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	gfh.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	bcopy(OBJ_SYMTOKEN, gfh.token.chars, sizeof(gfh.token.chars));
	bcopy("GLUE", gfh.creator.chars, sizeof(gfh.creator.chars));
	sprintf((char *)&(gfh.userNotes), "%8s:%04d:%04d", GH(geodeName),
		    	serialNumber, GH(resCount));
	VMSetHeader(symbols, (char *)&gfh);
    } else {
	GeosFileHeader	gfh;

	VMGetHeader(symbols, (char *)&gfh);
	gfh.core.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	gfh.core.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	bcopy(OBJ_SYMTOKEN, gfh.core.token.chars, sizeof(gfh.core.token.chars));
	bcopy("GLUE", gfh.core.creator.chars, sizeof(gfh.core.creator.chars));
	VMSetHeader(symbols, (char *)&gfh);
    }

    Final(outfile, warn_unref);
    if (errors) {
	goto err_exit;
    }


    if (dumpmem) {
	FILE	    *df;

	strcpy(dumpsuff, ".fn");
	df = fopen(dumpfile, "w");

	if (df != NULL) {
	    malloc_printstats((malloc_printstats_callback *)fprintf, df);
	    fclose(df);
	    fprintf(stderr, "final memory stats dumped to %s\n", dumpfile);
	}
    }

    exit(0);

err_exit:

    /*
     * Remove the symbol file on error, not bothering to close and
     * update it, then exit non-zero (the number of errors, but make sure
     * it's actually non-zero when trimmed to a byte, as the OS will do).
     * on the PC, it seems to complain often, if you don't close the thing
     * before unlinking it, so I just have it always close the thing - jimmy
     */
    VMClose(symbols);
    if (!leaveSymOnErr) {
	(void)unlink(symfile);
    }

    exit(errors & 0xff ? errors : errors+1);

}
