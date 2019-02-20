/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Table maintenance.
 * FILE:	  table.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 15, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Table_Enter 	    Enter data into a data table
 *	Table_Delete	    Nuke an item from a data table
 *	Table_Lookup	    Look up an item in a data table
 *	Table_Destroy	    Destroy an entire table
 *	Table_Create	    Create a new table
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/15/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to maintain hash tables keyed by strings, with
 *	delete functions associated with entries.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: table.c,v 4.9 97/04/18 16:50:03 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "cmd.h"
#include "table.h"
#include <compat/stdlib.h>
#if defined(_WIN32)
# include <ctype.h>
#endif

typedef struct {
    Opaque   	  data;	    	    /* Data for the entry */
    void    	  (*destroyProc)(); /* Function to destroy it */
} EntryRec, *EntryPtr;

/*-
 *-----------------------------------------------------------------------
 * Table_Enter --
 *	Enter a piece of data under the given name into a table.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	An EntryRec is created and entered into the table.
 *
 *-----------------------------------------------------------------------
 */
void
Table_Enter(Table 	table,
	    const char	*key,
	    Opaque	value,
	    void    	(*destroyProc) (Opaque value, char *key))
{
    Boolean 	  	new;
    Hash_Entry		*entry;
    EntryPtr	  	e;

    entry = Hash_CreateEntry(table, (Address)key, &new);

    if (new) {
	e = (EntryPtr)malloc_tagged(sizeof(EntryRec), TAG_TABLE);
	Hash_SetValue(entry, e);
    } else {
	e = (EntryPtr)Hash_GetValue(entry);
	if (e->destroyProc) {
	    (* e->destroyProc)(e->data, key);
	}
    }
    e->data = value;
    e->destroyProc = destroyProc;
}

/*-
 *-----------------------------------------------------------------------
 * Table_Delete --
 *	Remove the datum of the given name from the table.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The EntryRec for the data is freed and deleted from the table.
 *
 *-----------------------------------------------------------------------
 */
void
Table_Delete(Table  table,
	     const char   *key)
{
    Hash_Entry		*entry;
    EntryPtr	  	e;

    entry = Hash_FindEntry(table, (Address)key);

    if (entry != (Hash_Entry *)NULL) {
	e = (EntryPtr)Hash_GetValue(entry);

	if (e->destroyProc != NoDestroy) {
	    (* e->destroyProc) (e->data, key);
	}
	free((char *)e);
	Hash_DeleteEntry(table, entry);
    }
}

/*-
 *-----------------------------------------------------------------------
 * Table_Lookup --
 *	Return the data stored under the given name.
 *
 * Results:
 *	The data stored or NullTEntry if none stored.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
Opaque
Table_Lookup(Table  table,
	     const char   *key)
{
    Hash_Entry		*entry;
    EntryPtr	  	e;

    entry = Hash_FindEntry(table, (Address)key);
    if (entry != (Hash_Entry *)NULL) {
	e = (EntryPtr)Hash_GetValue(entry);
	return(e->data);
    } else {
	return(NullTEntry);
    }
}


/*-
 *-----------------------------------------------------------------------
 * Table_Destroy --
 *	Free up all resources and call the destroyProc for each piece of
 *	data we know of if destroy is TRUE.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	All our data are freed.
 *
 *-----------------------------------------------------------------------
 */
void
Table_Destroy(Table	table,
	      Boolean	destroy)
{
    Hash_Entry	  	*entry;
    Hash_Search	  	search;
    EntryPtr		e;

    for (entry = Hash_EnumFirst(table, &search);
	 entry != (Hash_Entry *)NULL;
	 entry = Hash_EnumNext(&search))
    {
	e = (EntryPtr)Hash_GetValue(entry);
	if (destroy && (e->destroyProc != NoDestroy)) {
	    (* e->destroyProc) (e->data, (char *)&entry->key);
	}
	free((char *)e);
    }
    Hash_DeleteTable(table);
    free((char *)table);
}

/*-
 *-----------------------------------------------------------------------
 * Table_Create --
 *	Initialize a table.
 *
 * Results:
 *	The new Table
 *
 * Side Effects:
 *	A Hash_Table is allocated and initialized.
 *
 *-----------------------------------------------------------------------
 */
Table
Table_Create(int	initBuckets)
{
    register Table	t;

    t = (Table)malloc_tagged(sizeof(Hash_Table), TAG_TABLE);
    Hash_InitTable(t, initBuckets, HASH_STRING_KEYS, 0);

    return(t);
}


/***********************************************************************
 *				TableCmd
 ***********************************************************************
 * SYNOPSIS:	    Command to provide hash tables to TCL procedures
 * CALLED BY:	    Tcl
 * RETURN:	    TCL_OK...
 * SIDE EFFECTS:    Ja.
 *
 * STRATEGY:
 *	All data stored in the hash table are keyed on strings (as you'd
 *	expect, since that's what this module provides). The data
 *	themselves are also dynamically-allocated strings that are freed
 *	automatically when the entry is changed or deleted.
 *
 *	XXX: What about garbage-collecting this stuff if someone drops
 *	the token? Could put it in the private data, but that just
 *	makes sure we can get to it, it doesn't make sure we will...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/17/89		Initial Revision
 *
 ***********************************************************************/
#define TABLE_CREATE	((ClientData)0)
#define TABLE_DESTROY	((ClientData)1)
#define TABLE_ENTER 	((ClientData)2)
#define TABLE_LOOKUP	((ClientData)3)
#define TABLE_REMOVE	((ClientData)4)
#define TABLE_FOREACH	((ClientData)5)
static const CmdSubRec	tableCmds[] = {
    {"create",	TABLE_CREATE,	0, 1,	"[<initBuckets>]"},
    {"destroy",	TABLE_DESTROY,	1, 1,	"<table>"},
    {"enter",	TABLE_ENTER,	3, 3,	"<table> <key> <value>"},
    {"lookup",	TABLE_LOOKUP,	2, 2,	"<table> <key>"},
    {"remove",	TABLE_REMOVE,	2, 2,	"<table> <key>"},
    {"foreach", 	TABLE_FOREACH,	2, 3,	"<table> <proc> [<data>]"},
    {NULL,   	(ClientData)NULL,	    	0, 0,	NULL}
};
DEFCMD(table,Table,TCL_EXACT,tableCmds,swat_prog,
"Usage:\n\
    table create [<initBuckets>]\n\
    table destroy <table>\n\
    table enter <table> <key> <value>\n\
    table lookup <table> <key>\n\
    table remove <table> <key>\n\
    table foreach <table> <proc> [<data>]\n\
\n\
Examples:\n\
    \"table create 32\"	    	    Create a new table with 32 hash buckets\n\
				    initially.\n\
    \"table enter $t tbrk3 {1 2 3}\"  Enter the value \"1 2 3\" under the key\n\
				    \"tbrk3\" in the table whose token is\n\
				    stored in the variable t.\n\
    \"table lookup $t tbrk4\" 	    Fetch the value, if any, stored under the\n\
				    key \"tbrk4\" in the table whose token is\n\
				    stored in the variable t.\n\
    \"table remove $t tbrk3\" 	    Remove the data stored in the table, whose\n\
				    token is stored in the variable t, under\n\
				    the key \"tbrk3\"\n\
    \"table destroy $t\"	    	    Destroy the table $t and all the data\n\
				    stored in it.\n\
    \"table foreach $t print-it $s\"  Invoke procedure print-it on each element\n\
				    currently in table $t, passing it the\n\
				    element, the element's key, and $s as the\n\
				    procedure's three arguments.\n\
\n\
Synopsis:\n\
    The \"table\" command is used to create, manipulate and destroy hash tables.\n\
    The entries in the table are keyed on strings and contain strings, as\n\
    you'd expect from Tcl.\n\
\n\
Notes:\n\
    * The <initBuckets> parameter to \"table create\" is set based on the number\n\
      of keys you expect the table to have at any given time. The number of\n\
      buckets will automatically increase to maintain hashing efficiency,\n\
      should the need arise, so <initBuckets> isn't a number that need be\n\
      carefully chosen. It's best to start with the default (16) or perhaps a\n\
      slightly larger number.\n\
\n\
    * If no data are stored in the table under <key>, \"table lookup\" will\n\
      return the string \"nil\", for which you can test with the \"null\" command.\n\
\n\
    * The callback procedure for \"table foreach\" should be declared with 2 or 3\n\
      arguments, depending on whether you pass the <data> argument:\n\
      	    callback <table> <key> [<data>]\n\
      is the syntax for the callback, where <table> is the table being enumer-\n\
      ated, <key> is the key for that entry, and <data> is the same as the\n\
      <data> passed to \"table foreach\", and is absent if you passed none.\n\
      If the callback returns a non-zero or non-numeric result, enumeration\n\
      will stop; \"table foreach\" will then return whatever the callback\n\
      returned. The callback must return 0 for it to continue to the next\n\
      entry in the table. If the callback never returns anything but 0, \"table\n\
      foreach\" will return the empty string.\n\
\n\
See also:\n\
    null, cache\n\
")
{
    Table   table;

    if (clientData > TABLE_CREATE) {
	table = (Table)atoi(argv[2]);
	if (!VALIDTPTR(table,TAG_TABLE)) {
	    Tcl_RetPrintf(interp, "%s: not a valid table", argv[2]);
	    return(TCL_ERROR);
	}
    } else {
	table=NULL;
    }
    switch((int)clientData) {
	case TABLE_CREATE:
	    table = Table_Create(argc != 3 ? 0 : cvtnum(argv[2],NULL));
	    Tcl_RetPrintf(interp, "%d", table);
	    break;
	case TABLE_DESTROY:
	    Table_Destroy(table, TRUE);
	    break;
	case TABLE_ENTER:
	{
	    char    *value = (char *)malloc(strlen(argv[4])+1);

	    strcpy(value, argv[4]);
	    Table_Enter(table, argv[3], (Opaque)value,
			(Table_DestroyProc *)free);
	    break;
	}
	case TABLE_LOOKUP:
	{
	    char    *value;

	    value = (char *)Table_Lookup(table, argv[3]);
	    Tcl_Return(interp, value ? value : "nil", TCL_STATIC);
	    break;
	}
	case TABLE_REMOVE:
	    Table_Delete(table, argv[3]);
	    break;
        case TABLE_FOREACH:
	{
	    Hash_Search	search;
	    Hash_Entry	*e;
	    char    	*cbArgv[4];
	    int	    	result;

	    /*
	     * Prep the two parts of the command that never change: the
	     * callback procedure name and the table's token.
	     */
	    cbArgv[0] = argv[3];
	    cbArgv[1] = argv[2];

	    /*
	     * Now enumerate all the entries, calling the callback for each one
	     */
	    for (e = Hash_EnumFirst(table, &search);
		 e != NullHash_Entry;
		 e = Hash_EnumNext(&search))
	    {
		char	*cmd;
		
		/*
		 * Second arg is the entry's key.
		 */
		cbArgv[2] = e->key.name;

		/*
		 * Create the command to evaluate, tacking on the extra data
		 * argument only if present.
		 */
		if (argc == 4) {
		    cmd = Tcl_Merge(3, cbArgv);
		} else {
		    cbArgv[3] = argv[4];
		    cmd = Tcl_Merge(4, cbArgv);
		}
		/*
		 * Evaluate the command. It's a shame we have to go through the
		 * parsing etc. each time, but we need to have the call frame
		 * set up properly, etc.
		 */
		result = Tcl_Eval(interp, cmd, 0, 0);
		free(cmd);
		if (result != TCL_OK) {
		    return(result);
		}
		/*
		 * If callback returned non-zero (or non-numeric), return its
		 * result as our own.
		 */
		if (!isdigit(interp->result[0]) || atoi(interp->result)) {
		    break;
		} else {
		    /*
		     * Else wipe out its result...
		     */
		    Tcl_Return(interp, NULL, TCL_STATIC);
		}
	    }
	    break;
	}
    }
    return(TCL_OK);
}
