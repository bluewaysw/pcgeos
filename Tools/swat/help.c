/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Help String Maintenance
 * FILE:	  help.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 19, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Help_Store  	    Store a help string in the tree
 *	Help_Fetch  	    Fetch a help string for a command
 *	Help_Init   	    Initialize the module.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/19/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to implement the swat help facility.
 *
 * 	Help data may be accessed in one of two ways: by topic name or by a
 * 	topic path. The former is intended for fast access, e.g. by "help brk",
 * 	while the latter is for the interactive help browser.
 *
 * 	Help data are organized into two structures: The first is a hash table
 * 	keyed on topics. The entries in the table point to HelpString
 *	structures, to allow for the different name-spaces in tcl (functions
 *	and variables). The second is a tree made of HelpNodeRecs.
 *
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: help.c,v 4.12 97/04/21 18:27:15 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "file.h"
#include "hash.h"
#include <compat/stdlib.h>

#if defined(unix)
#include <sys/file.h>
#else
#include <io.h>
#include <share.h>
#endif

#include <compat/file.h>

static Hash_Table   helpTable;	/* Table mapping topics to strings. Note
				 * we can't use a Table here b/c we need
				 * to sort things and theoretically we
				 * don't *know* a Table is a hash table...
				 * Besides, we don't need deleteProcs. */
static FileType	    docFile;	/* Stream open to documentation file */

typedef struct _HelpString {
    struct _HelpString	*next;	    	/* Next string of same name */
    int	    	    	flags;	    	/* Flags for string */
#define HELP_INDOC  0x00000001	    	    /* String in doc file */
    const char	    	*string;    	/* String/offset into docFile */
} HelpString;

typedef struct _HelpNode {
    const char	    	*name;	    	/* Name of this node */
    HelpString	    	*doc;	    	/* Doc string */
    struct _HelpNode	*firstChild;	/* Pointer to first subtopic */
    struct _HelpNode	*nextSib;   	/* Pointer to next topic on same
					 * level */
} HelpNodeRec, *HelpNodePtr;

static HelpString   advHelp = {NULL, 0, "advanced level of the help tree" };
static HelpNodeRec  advLevel = {"advanced", &advHelp, NULL, NULL};

static HelpString   topHelp = {NULL, 0, "top-most level of the help tree" };
static HelpNodeRec  topLevel = {"top", &topHelp, &advLevel, NULL};

static HelpNodePtr  root = &topLevel;
static HelpNodePtr  advanced = &advLevel;

static Boolean	helpLoaded;	/* Boolean representing if help has been 
				 * loaded or not 
				 */


/***********************************************************************
 *				HelpFind
 ***********************************************************************
 * SYNOPSIS:	    Find a node in the tree given its path.
 * CALLED BY:	    HelpStore, HelpFetchCmd, HelpScanCmd
 * RETURN:	    The node in the tree or NULL if not there and create
 *		    is FALSE.
 * SIDE EFFECTS:    Nodes may be created.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
static HelpNodePtr
HelpFind(char	    *path,  	/* Path to node. Must be writable */
	 Boolean    create) 	/* TRUE if should create missing nodes */
{
    HelpNodePtr	    hnp;
    char    	    *cp;

    hnp = advanced;
    cp = index(path, '.');
    if (cp != NULL) {
	if (strncmp(path, "top", cp - path) == 0) {
	    /*
	     * Skip over "top" as the first component -- we've already
	     * got that :)
	     */
	    path = cp + 1;
	    cp = index(path, '.');
	    hnp = root;
	}
    }
    
    if (cp == NULL) {
	/*
	 * A degenerate path. Take care of the hidden nature of "top":
	 * If the string is "top", return the root node to the caller.
	 * Otherwise, point cp at the end and act like we found a dot.
	 */
	if (strcmp(path, "top") == 0) {
	    return(root);
	} else {
	    cp = path + strlen(path);
	}
    }

    do {
	HelpNodePtr hnp2;

	for (hnp2 = hnp->firstChild; hnp2; hnp2 = hnp2->nextSib) {
	    if ((strncmp(hnp2->name, path, cp - path) == 0) &&
		(hnp2->name[cp - path] == '\0'))
	    {
		/*
		 * Found the right node
		 */
		break;
	    }
	}
	if (!hnp2) {
	    if (create) {
		/*
		 * Create a new node for this level.
		 */
		hnp2 = (HelpNodePtr)malloc_tagged(sizeof(HelpNodeRec),
						  TAG_HELP);
		hnp2->name = (char *)malloc_tagged(cp - path + 1, TAG_HELP);

		/*
		 * Copy in the name, making sure it's null-terminated.
		 */
		strncpy((char *)hnp2->name, path, cp - path);
		((char *)hnp2->name)[cp - path] = '\0';
		/*
		 * Initialize the other fields
		 */
		hnp2->doc = NULL;
		hnp2->firstChild = NULL;

		/*
		 * Link this node into its level
		 */
		hnp2->nextSib = hnp->firstChild;
		hnp->firstChild = hnp2;

	    } else {
		return(NULL);
	    }
	}
	/*
	 * Descend to this level
	 */
	hnp = hnp2;

	/*
	 * Advance the path and look for the end of the next element
	 */
	path = cp + (*cp == '.' ? 1 : 0);
	cp = index(path, '.');
	if (cp == NULL && path[-1] == '.' && *path != '\0') {
	    /*
	     * Handle the final component by pointing cp to the end of the
	     * string. Note that we avoid choking on a bogus path, which ends
	     * in a ., by the *path != '\0' test. This causes <level>. and
	     * <level> to return the same thing. This can be construed as a
	     * feature.
	     */
	    cp = path + strlen(path);
	}
    } while (cp != NULL);

    return(hnp);
}
	


/***********************************************************************
 *				HelpStoreString
 ***********************************************************************
 * SYNOPSIS:	    Store a string in the hash table
 * CALLED BY:	    Help_Store, Help_Init
 * RETURN:	    The HelpString * for it.
 * SIDE EFFECTS:    A HelpString record is created and linked into the
 *		    hash table.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
static HelpString *
HelpStoreString(char	    *name,  	/* Topic name */
		const char  *string,	/* String/offset to store */
		int	    flags)  	/* Flags for it */
{
    Hash_Entry	    *entry;
    Boolean 	    new;
    HelpString	    *result;

    /*
     * Allocate a new HelpString for the thing.
     */
    result = (HelpString *)malloc_tagged(sizeof(HelpString), TAG_HELP);
    result->flags = flags;
    result->string = string;
    
    /*
     * Hash the string based on the name of the returned node.
     */
    entry = Hash_CreateEntry(&helpTable, (Address)name, &new);
    if (new) {
	/*
	 * First in chain -- init next pointer
	 */
	result->next = NULL;
    } else {
	/*
	 * Link to previous entry
	 */
	result->next = (HelpString *)Hash_GetValue(entry);
    }
    /*
     * Store the beast in the table
     */
    Hash_SetValue(entry, result);

    return(result);
}

/***********************************************************************
 *				HelpStorePath
 ***********************************************************************
 * SYNOPSIS:	    Store a help string under a given class
 * CALLED BY:	    Help_Store, Help_Init
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Nodes may be entered into the tree.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/12/89		Initial Revision
 *
 ***********************************************************************/
static void
HelpStorePath(HelpString	*doc,	    /* String to store */
	      char	    	*path)	    /* Path under which to store it */
{
    HelpNodePtr	    hnp;

    hnp = HelpFind(path, TRUE);

    hnp->doc = doc;
}


/***********************************************************************
 *				HelpStore
 ***********************************************************************
 * SYNOPSIS:	    Store a topic in the tree under all its classes
 * CALLED BY:	    Help_Init, Help_Store
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Scads
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
static void
HelpStore(char	    	*topic,	    /* Topic to store */
	  char	    	*class,	    /* Classes under which to store it */
	  HelpString	*doc)	    /* String to store */
{
    char    	path[132];
    char    	**classes;
    int	    	n;
    int	    	i;
    

    /*
     * For each class, form up a path and store the puppy.
     */
    if (Tcl_SplitList(interp, class, &n, &classes) == TCL_OK) {
	for (i = 0; i < n; i++) {
	    sprintf(path, "%s.%s", classes[i], topic);
	    HelpStorePath(doc, path);
	}
    }

    free((char *)classes);
}

/***********************************************************************
 *				HelpExtract
 ***********************************************************************
 * SYNOPSIS:	    Extract a help string from the doc file.
 * CALLED BY:	    HelpFetchCmd, HelpGetCmd
 * RETURN:	    A dynamically-allocated copy of the string.
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
static char *
HelpExtract(HelpString	*string)    	/* String to extract */
{
    char    *result;
    int	    len = 0;
    int     brk = FALSE;
    long    bytesRead = 0;
    char    c[2] = "0";

    assert(string->flags & HELP_INDOC);

    FileUtil_Seek(docFile, (long)string->string, SEEK_SET);
    do {
	FileUtil_Read(docFile, c, 1, &bytesRead);
	if (bytesRead == 0) {
	    Warning("Couldn't scan length from doc file");
	    return(NULL);
	}
	switch (c[0]) {
	case ':':
	    brk = TRUE;
	    break;
	case '0': case '1': case '2': case '3':
	case '4': case '5': case '6': case '7':
	case '8': case '9':
	    len = len * 10 + atoi(c);
	    break;
	case ' ':
	    break;
	default:
	    Warning("Couldn't scan length from doc file - "
		    "unexpected char");
	    return(NULL);
	}
    } while (brk == FALSE);

    /*
     * Allocate room for the thing
     */
    result = (char *)malloc_tagged(len + 1, TAG_HELPTS);

    /*
     * Read and null-terminate it
     */
    FileUtil_Read(docFile, result, len, &bytesRead);
    if (bytesRead < len) {
	Warning("couldn't read data from doc file");
	return(NULL);
    }

    result[len] =  '\0';

    /*
     * Return the thing.
     */
    return(result);
}


/***********************************************************************
 *				HelpInDoc
 ***********************************************************************
 * SYNOPSIS:	    See if a command is in the doc file.
 * CALLED BY:	    Help_Store
 * RETURN:	    TRUE if it is in all the classes given.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
static Boolean
HelpInDoc(char	    *topic,
	  char	    *class)
{
    char    	path[132];
    HelpNodePtr	hnp;
    char    	**classes;
    int	    	n;
    int	    	i;

    if (Tcl_SplitList(interp, class, &n, &classes) != TCL_OK) {
	return(FALSE);
    }
    
    /*
     * For each class, form up a path and find the puppy.
     */
    for (i = 0; i < n; i++) {
	sprintf(path, "%s.%s", classes[i], topic);
	hnp = HelpFind(path, FALSE);

	/*
	 * If the node doesn't exist, or has no documentation

	 * NO LONGER CARE WHERE HELP CAME FROM, STUFF BELOW REMOVED
	 *     , or that
	 *     documentation isn't in the doc file, then the thing wasn't
	 *     pre-extracted, so return FALSE
	 *               || !(hnp->doc->flags & HELP_INDOC))

	 */
	if (hnp == NULL || hnp->doc == NULL) {
	    free((char *)classes);
	    return(FALSE);
	}
    }

    free((char *)classes);
    return(TRUE);
}
	

/*
 * whether old help should be overwritten when loading
 */
#define BUF_SIZE		2048
long totalBytes=0;
/***********************************************************************
 *		HelpGetc
 ***********************************************************************
 *
 * SYNOPSIS:	get a single character from the file
 * CALLED BY:	HelpLoad
 * RETURN:	integer value of the next character read, EOF if at the end
 *	
 * STRATEGY:	read in a lot of data at once, return chars from the buffer
 *	
 * REVISION HISTORY:
 *	Name		Date		Description
 *	----		----		-----------
 *	dbaumann	4/21/97   	Initial Revision
 *	
 ***********************************************************************/
int
HelpGetc(void)
{
    static unsigned char readBuf[BUF_SIZE];  /* Buffer for reading file */
    int returnCode;
    static int bytePos = 0;
    static bytesInBuf = 0;

    if (bytePos >= bytesInBuf) { 
	bytesInBuf = 0;
	bytePos = 0;
	returnCode = FileUtil_Read(docFile, readBuf, BUF_SIZE, &bytesInBuf);
	if ((returnCode == FALSE) || (bytesInBuf == 0)) {
	    return (int)EOF;
	}
    }
    totalBytes++;
    return (int)readBuf[bytePos++];
}	/* End of HelpGetc.	*/

/***********************************************************************
 *				HelpLoad
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The helpTable is loaded
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	dbaumann	01/20/96	Initial Revision
 *
 ***********************************************************************/
void
HelpLoad(void)
{
    int	    c; 	    	    /* Current character */
    char    class[132];	    /* Buffer for class(es) */
    char    topic[132];	    /* Buffer for topic */
    char    *cp;    	    /* General pointer/Pointer 
			     * into class */
    int     dotcount = 0;   /* to display working dots */
    HelpString *doc;    	    /* Doc to pass to HelpStore */

    if (MessageFlush != NULL) {
	MessageFlush("loading help");
    }

    do {
	/*
	 * Skip to next topic-start character
	 */
	while ((c = HelpGetc()) != '\177' && (c != EOF)) {
	    ;
	}
	if (c == EOF) {
	    break;
	}

	/*
	 * Read in the topic
	 */
	cp = topic;
	while ((c = HelpGetc()) != '.') {
	    *cp++ = c;
	}
	*cp = '\0';

	/*
	 * Then the class(es)
	 */
	cp = class;
	if ((c = HelpGetc()) == '{') {
	    while ((c = HelpGetc()) != '}') {
		*cp++ = c;
	    }
	    /*
	     * Skip to the newline so we've got the real offset for the
	     * start of the string.
	     */
	    while ((c = HelpGetc()) != '\n') {
		;
	    }
	} else {
	    do {
		*cp++ = c;
	    } while ((c = HelpGetc()) != '\n');
	}
	*cp = '\0';

	/*
	 * Take care of reading things whose help was extracted into the
	 * DOC file by not doing anything if all the places under which we'd
	 * file this thing are there.
	 */
	if (HelpInDoc(topic, class) == FALSE) {
	    /*
	     * Figure the offset to the doc string and create the HelpString
	     * to use for storing the thing away.
	     */
	    doc = HelpStoreString(topic, (const char *)totalBytes, HELP_INDOC);
	    HelpStore(topic, class, doc);
	}

	/*
	 * Print out dots to keep the user happy, seeing progress
	 */
	if (((dotcount++)%30 == 0) && (dotcount < 66*30)) {
	    if (MessageFlush != NULL) {
		MessageFlush(".");
	    }
	}
    } while(c != EOF);

    if (MessageFlush != NULL) {
	MessageFlush("\r                                                                            \r");
    }

    helpLoaded = TRUE;
}


/***********************************************************************
 *				HelpGetCmd
 ***********************************************************************
 * SYNOPSIS:	    Get a list of the help strings for a topic
 * CALLED BY:	    Tcl
 * RETURN:	    The aforementioned list
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(help-get,HelpGet,TCL_EXACT,NULL,swat_prog.help,
"Usage:\n\
    help-get <topic-path>\n\
\n\
Examples:\n\
    \"help-get top.stack\"	Retrieves the strings for all nodes at the \"top.stack\"\n\
			level of the help tree.\n\
\n\
Synopsis:\n\
    Fetches a list of help strings for all nodes at the given level of the\n\
    help tree.\n\
\n\
Notes:\n\
    * This is usually only used when <topic-path> is a terminal node, but\n\
      occasionally there are two things with the same topic path (since there\n\
      isn't a central registration for such things to avoid conflicts...).\n\
\n\
    * This is different from \"help-fetch\", which can return only one string.\n\
\n\
See also:\n\
    help-fetch\n\
")
{
    Hash_Entry	*entry;
    HelpString	*string;
    char    	*result;
    int	    	len;
    char 	**strs;
    int	    	i;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: help-get <topic>");
    }

    if (helpLoaded == FALSE) {
       HelpLoad();
    }

    entry = Hash_FindEntry(&helpTable, (Address)argv[1]);
    if (entry == NULL) {
	const char  *actual;
	Tcl_CmdProc *junkProc;
	int 	    junkFlags;
	ClientData  junkClientData;
	Tcl_DelProc *junkDelProc;

	
	if (!Tcl_FetchCommand(interp, argv[1], &actual,
			     &junkProc, &junkFlags, &junkClientData,
			     &junkDelProc))
	{
	    return(TCL_ERROR);
	}

	entry = Hash_FindEntry(&helpTable, (Address)actual);
	if (entry == NULL) {
	    Tcl_RetPrintf(interp, "%s: no such help topic defined", argv[1]);
	    return(TCL_ERROR);
	}
    }
    /*
     * Figure out how many there are
     */
    for (string = (HelpString *)Hash_GetValue(entry), len = 0;
	 string;
	 string = string->next, len++)
    {
	;
    }

    /*
     * Find the strings for all the entries
     */
    strs = (char **)malloc_tagged(len * sizeof(char *), TAG_HELPTS);
    for (string = (HelpString *)Hash_GetValue(entry), i = 0;
	 string;
	 string = string->next, i++)
    {
	if (string->flags & HELP_INDOC) {
	    strs[i] = HelpExtract(string);
	} else {
	    strs[i] = (char *)string->string;
	}
    }

    /*
     * Let Tcl_Merge deal with quoting things and building up a proper list
     */
    result = Tcl_Merge(len, strs);

    /*
     * Free all the strings extracted from the doc file.
     */
    for (string = (HelpString *)Hash_GetValue(entry), i = 0;
	 string;
	 string = string->next, i++)
    {
	if (string->flags & HELP_INDOC) {
	    free((char *)strs[i]);
	}
    }
    /*
     * Free the string vector.
     */
    free((char *)strs);

    /*
     * Return things
     */
    Tcl_Return(interp, result, TCL_DYNAMIC);
    return(TCL_OK);
}


/***********************************************************************
 *				HelpFetchCmd
 ***********************************************************************
 * SYNOPSIS:	    Return a help string based on its path
 * CALLED BY:	    Tcl
 * RETURN:	    The string and TCL_OK or nil if no such string
 *	    	    defined.
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(help-fetch,HelpFetch,TCL_EXACT,NULL,swat_prog.help,
"Usage:\n\
    help-fetch <topic-path>\n\
\n\
Examples:\n\
    \"help-fetch top.patient\"	Retrieves the help string for the \"patient\"\n\
				node in the \"top\" level of the help tree.\n\
\n\
Synopsis:\n\
    Fetches the help string for a given topic path in the help tree.\n\
\n\
Notes:\n\
    * If there is more than one node with the given path in the tree, only\n\
      the string for the first node will be returned.\n\
\n\
See also:\n\
    help-get.\n\
")
{
    HelpNodePtr	hnp;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: help-fetch <path>");
    }

    if (helpLoaded == FALSE) {
       HelpLoad();
    }

    hnp = HelpFind(argv[1], FALSE);
    if (hnp == NULL) {
	Tcl_Return(interp, "nil", TCL_STATIC);
    } else if (hnp->doc == NULL) {
	Tcl_Return(interp, "not documented", TCL_STATIC);
    } else if (hnp->doc->flags & HELP_INDOC) {
	/*
	 * Load in the doc string and return that
	 */
	Tcl_Return(interp, HelpExtract(hnp->doc), TCL_DYNAMIC);
    } else {
	/*
	 * Just return the string itself.
	 */
	Tcl_Return(interp, (char *)hnp->doc->string, TCL_STATIC);
    }
    return(TCL_OK);
}

/***********************************************************************
 *				HelpFetchLevelCmd
 ***********************************************************************
 * SYNOPSIS:	    Returns the names of all topics defined at a level
 * CALLED BY:	    Tcl
 * RETURN:	    A list of names
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(help-fetch-level,HelpFetchLevel,TCL_EXACT,NULL,swat_prog.help,
"Usage:\n\
    help-fetch-level <topic-path>\n\
\n\
Examples:\n\
    \"help-fetch-level top.advanced.stack\"    Returns the topics within the\n\
					    \"top.advanced.stack\" level of the\n\
					    help tree.\n\
\n\
Synopsis:\n\
    Returns a list of the topics available at a given level in the help tree.\n\
\n\
Notes:\n\
    * The result is a list of node names, without leading path components.\n\
\n\
See also:\n\
    help-fetch.\n\
")
{
    HelpNodePtr	hnp;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: help-fetch-level <path>");
    }

    if (helpLoaded == FALSE) {
       HelpLoad();
    }

    hnp = HelpFind(argv[1], FALSE);
    if (hnp == NULL) {
	Tcl_RetPrintf(interp, "%s: no such level defined", argv[1]);
	return(TCL_ERROR);
    } else {
	HelpNodePtr hnp2;
	int 	    len;

	for (hnp2 = hnp->firstChild, len = 0; hnp2; hnp2 = hnp2->nextSib) {
	    len += strlen(hnp2->name) + 1;
	}
	if (len == 0) {
	    Tcl_Return(interp, NULL, TCL_STATIC);
	} else {
	    char    *cp, *result;

	    result = (char *)malloc(len);
	    for (cp = result, hnp2 = hnp->firstChild;
		 hnp2;
		 hnp2 = hnp2->nextSib)
	    {
		/*
		 * Copy in the name followed by a space. Faster than
		 * sprintf, I suspect. Also avoids storing an extra
		 * null byte, which would murder things on a little-endian
		 * machine....
		 */
		strcpy(cp, hnp2->name);
		cp += strlen(cp);
		*cp++ = ' ';
	    }
	    /*
	     * Overwrite final space with null byte
	     */
	    cp[-1] = '\0';
	    Tcl_Return(interp, result, TCL_DYNAMIC);
	}
	return(TCL_OK);
    }
}

/***********************************************************************
 *				HelpScanCmd
 ***********************************************************************
 * SYNOPSIS:	    Scan all known help strings for a pattern
 * CALLED BY:	    Tcl
 * RETURN:	    A list of topics that include the pattern
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(help-scan,HelpScan,TCL_EXACT,NULL,swat_prog.help,
"Usage:\n\
    help-scan <pattern>\n\
\n\
Examples:\n\
    \"help-scan break\"	    Looks for all nodes at any level of the help tree\n\
			    whose documentation matches *break*\n\
\n\
Synopsis:\n\
    Scans all nodes in the help tree for those whose documentation matches a\n\
    given pattern.\n\
\n\
Notes:\n\
    * <pattern> is expanded to *<pattern>* before the search is performed.\n\
\n\
    * The result is a list of topic-paths for those nodes whose documentation\n\
      string contains the given pattern.\n\
\n\
See also:\n\
    help-fetch.\n\
")
{
    char    	*result, *rp;
    int	    	resultSize;
    Hash_Search	search;
    Hash_Entry	*entry;
    HelpString	*string;
    char    	*pattern;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: help-scan <pattern>");
    }
    
    if (helpLoaded == FALSE) {
       HelpLoad();
    }

    /*
     * Allocate the initial return buffer
     */
    resultSize = 128;
    rp = result = (char *)malloc_tagged(resultSize, TAG_HELPTS);

    /*
     * Slap *'s on both ends of the pattern.
     */
    pattern = (char *)malloc(strlen(argv[1]) + 3);
    sprintf(pattern, "*%s*", argv[1]);

    /*
     * Work our way down the table...
     */
    for (entry = Hash_EnumFirst(&helpTable, &search);
	 entry != NULL;
	 entry = Hash_EnumNext(&search))
    {
	int 	use = 0;
	    
	for (string = (HelpString *)Hash_GetValue(entry);
	     string && !use;
	     string = string->next)
	{
	    if (string->flags & HELP_INDOC) {
		/*
		 * Fetch the string from the doc file, pattern match and
		 * free it.
		 */
		char	*str = HelpExtract(string);

		use = Tcl_StringMatch(str, pattern);
		free(str);
	    } else {
		/*
		 * Match against the in-core string
		 */
		use = Tcl_StringMatch(string->string, pattern);
	    }
	}

	if (use) {
	    /*
	     * Figure the length of the entry name and following space
	     */
	    int	    len = strlen(entry->key.name) + 1;

	    if (rp+len > result+resultSize) {
		/*
		 * Won't fit in current buffer. Figure where we are now,
		 * resize the buffer and reposition rp.
		 */
		int offset = rp-result;
		
		resultSize *= 2;
		result = (char *)realloc(result, resultSize);

		rp = result+offset;
	    }
	    /*
	     * Copy in the name, adjust rp to point past the null byte
	     * and replace the null with a space.
	     */
	    strcpy(rp, entry->key.name);
	    rp += len;
	    rp[-1] = ' ';
	}
    }
    /*
     * If any matched, replace the final space with a null.
     */
    if (rp != result) {
	rp[-1] = '\0';
	Tcl_Return(interp, result, TCL_DYNAMIC);
    } else {
	/*
	 * Return empty
	 */
	Tcl_Return(interp, NULL, TCL_STATIC);
	free(result);
    }
    free(pattern);

    return(TCL_OK);
}
    

/***********************************************************************
 *				HelpIsLeafCmd
 ***********************************************************************
 * SYNOPSIS:	    See if a path is a leaf node
 * CALLED BY:	    Tcl
 * RETURN:	    1 if it is, 0 if it isn't
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Find the node in the tree. If its firstChild pointer
 *	    	    is null, return 1.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/14/89		Initial Revision
 *
 ***********************************************************************/
DEFCMD(help-is-leaf,HelpIsLeaf,TCL_EXACT,NULL,swat_prog.help,
"Usage:\n\
    help-is-leaf <topic-path>\n\
\n\
Examples:\n\
    \"help-is-leaf top.running\" See if top.running is a leaf node in the \n\
				help tree (i.e. it has no children).\n\
\n\
Synopsis:\n\
    Determines if a given topic path refers to a help topic or a help\n\
    category.\n\
\n\
Notes:\n\
    * Returns 1 if the given path refers to a leaf node, 0 if it is not.\n\
\n\
See also:\n\
    help-fetch, help-fetch-level.\n\
")
{
    HelpNodePtr	hnp;

    if (argc != 2) {
	Tcl_Error(interp, "Usage: help-is-leaf <path>");
    }

    if (helpLoaded == FALSE) {
       HelpLoad();
    }

    hnp = HelpFind(argv[1], FALSE);
    if (hnp == NULL) {
	Tcl_RetPrintf(interp, "%s: no such help node defined", argv[1]);
	return(TCL_ERROR);
    }
    Tcl_Return(interp, hnp->firstChild ? "0" : "1", TCL_STATIC);
    return(TCL_OK);
}


/***********************************************************************
 *				Help_Fetch
 ***********************************************************************
 * SYNOPSIS:	    Similar to help-fetch, but for internal use, and
 *		    always creates a copy of the string.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    The string.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
char *
Help_Fetch(char	*name,	    /* Name (from CmdRec) */
	   char	*class)	    /* Class(es) -- just uses the first */
{
    HelpNodePtr	hnp;
    char    	path[132];
    char    	**classes;
    int	    	n;

    if (helpLoaded == FALSE) {
       HelpLoad();
    }

    if (Tcl_SplitList(interp, class, &n, &classes) != TCL_OK) {
	return((char *)NULL);
    }
    sprintf(path, "%s.%s", classes[0], name);
    free((char *)classes);

    hnp = HelpFind(path, FALSE);
    if (hnp == NULL) {
	return(NULL);
    } else {
	if (hnp->doc->flags & HELP_INDOC) {
	    return(HelpExtract(hnp->doc));
	} else {
	    char    	*cp;
	    
	    cp = (char *)malloc_tagged(strlen(hnp->doc->string) + 1,
				       TAG_HELPTS);

	    strcpy(cp, hnp->doc->string);

	    return(cp);
	}
    }
}


/***********************************************************************
 *				Help_Store
 ***********************************************************************
 * SYNOPSIS:	    Store a help string
 * CALLED BY:	    DefcommandCmd, DefdsubrCmd, DefvarCmd
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The string is copied and entered for all its classes.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/13/89		Initial Revision
 *
 ***********************************************************************/
void
Help_Store(char *topic,
	   char	*class,
	   char	*string)
{
    HelpString	*doc;
    char	*str;

    /*
     * Take care of reading things whose help was extracted into the
     * DOC file by not doing anything if all the places under which we'd
     * file this thing are there.
     */
    if (HelpInDoc(topic, class)) {
	return;
    }
    /*
     * Duplicate the thing
     */
    str = (char *)malloc_tagged(strlen(string) + 1, TAG_HELPSTR);
    strcpy(str, string);
    
    /*
     * Enter it into the table
     */
    doc = HelpStoreString(topic, str, 0);

    /*
     * Store it
     */
    HelpStore(topic, class, doc);
}


#if defined(_MSDOS) || defined(_WIN32)
# define NULL_FILE_NAME	"NUL"
# define NULL_FILE_ATTR O_RDONLY|O_BINARY
#elif defined(unix)
# define NULL_FILE_NAME	"/dev/null"
# define NULL_FILE_ATTR O_RDONLY
#endif	

/***********************************************************************
 *				Help_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize this module.
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The helpTable is initialized
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/10/88	Initial Revision
 *
 ***********************************************************************/
void
Help_Init(void)
{
    char    docPath[512];
    int     returnCode;
    
    /*
     * We up the average chain length to 5 as searching here isn't as
     * crucial -- we're more interested in the table for its organizational
     * abilities, not its speed.
     */
    Hash_InitTable(&helpTable, 0, HASH_STRING_KEYS, 5);

    helpLoaded = FALSE;
    docFile = 0;
    
    /*
     * DOS NOTE: We open the thing in binary mode, as the HighC
     * implementation of ftell improperly looks only for newlines to
     * and subtracts an extra one for each one in the buffer when in
     * text mode. I don't know the purpose of this, as it would seem
     * to make fseeking in a text file a chancy business at best. As
     * it happens, the DOC file is always made on UNIX and has only
     * newlines for its end-of-line characters, so we can safely open
     * the thing in binary mode.
     */
    returnCode = FALSE;
#if !defined(_MSDOS) && !defined(_WIN32)
    if (fileDevel && (fileSysLib[0] != '/')) {
	sprintf(docPath, "%s/%s/DOC.new", fileDevel, fileSysLib);
	returnCode = FileUtil_Open(&docFile, docPath, O_RDONLY|O_BINARY, 
				  SH_DENYWR, 0);
    }
#endif

    /* XXX: WHAT ABOUT SHARING OVER THE NET? */
    if (returnCode == FALSE) {
	sprintf(docPath, "%s/DOC", fileAbsSysLib);
	returnCode = FileUtil_Open(&docFile, docPath, O_RDONLY|O_BINARY, 
				  SH_DENYWR, 0);
    }

    if (returnCode == FALSE) {
	/*
	 * Can't really give an error message (nor should it be a fatal error
	 * for the help file to not be around), so just point the thing
	 * at /dev/null, which is harmless.
	 */
	if (MessageFlush != FALSE) {
	    MessageFlush("Couldn't find the main help file\n");
	}
	returnCode = FileUtil_Open(&docFile, NULL_FILE_NAME, NULL_FILE_ATTR,
				   SH_DENYNONE, 0);
	if (returnCode == FALSE) {
	    assert(0);
	}
    }

    Cmd_Create(&HelpGetCmdRec);
    Cmd_Create(&HelpFetchLevelCmdRec);
    Cmd_Create(&HelpFetchCmdRec);
    Cmd_Create(&HelpScanCmdRec);
    Cmd_Create(&HelpIsLeafCmdRec);
}
