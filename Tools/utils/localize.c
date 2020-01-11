/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	localization
MODULE:
FILE:		localize.c

AUTHOR:		Josh Putnam, Nov 16, 1992

ROUTINES:
	Name			Description
	----			-----------
	Localize_Init(file) 	init the localization module (dumps in file)

	Localize_EnterResource	create a resource, make it the current
				just makes it current if already exists

	Localize_AddLocalization	add localization info to the
					current resource

	Localize_DumpLocalizations	dump out all localizations


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	11/16/92   	Initial version.

DESCRIPTION:


	$Id: localize.c,v 1.7 96/05/20 18:55:58 dbaumann Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <config.h>
#include <compat/string.h>
#include <compat/stdlib.h>
#include <stdio.h>
#include <hash.h>
#include <ctype.h>
#include <localize.h>
#include <assert.h>

#include "malloc.h"

static FILE			*locOut;		/* output file      */
static Hash_Table 		locHash;		/* all resources    */
static ResourceSym 		*currentResource = NULL;/* currnet resource */
static int upcaseLinkerResourceNames; /* true iff using MetaWare */
static char 	    	    	*locName = NULL;



/***** Forward Delcarations *****/


/*****  Macro Defined Constants ****/




/* macro to iterate through the hash table and run 'code' with res=resource */
#define FOR_ALL_RESOURCES(__res,code)                    \
do{ 	        					 \
    Hash_Entry	*__ent;					 \
    ResourceSym *__res;					 \
    Hash_Search 	hashSearch;                      \
	        					 \
    for(__ent = Hash_EnumFirst(&locHash,&hashSearch);	 \
	__ent;						 \
	__ent = Hash_EnumNext(&hashSearch)){		 \
	__res =(ResourceSym *)Hash_GetValue(__ent);	 \
	code    					 \
    }	        					 \
}while(0)

#define FOR_ALL_LOCINFOS_IN_RESOURCE(__res,__locinfo,__code)     \
    do{	        					         \
	LocalizeInfo	*__locinfo;			         \
	for(__locinfo = RES_INFO(__res);		         \
	    __locinfo;					         \
	    __locinfo = LOC_NEXT(__locinfo)){		         \
                __code                                           \
	}                                                        \
    }while(0)



/***********************************************************************
 *				Localize_Init
 ***********************************************************************
 * SYNOPSIS:	    Create a file into which localization info can
 *		    be placed.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    a stream is opened and must be closed via a call to
 *		    Localize_DumpLocalizations
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/18/92   	Initial Revision
 *
 ***********************************************************************/
void 
Localize_Init(char *fileName,	    	    	/* Regular output file,
						 * from which name of
						 * localization file will be
						 * generated. */
	      int upcase_resource_linker_name)	/* Non-zero if resource names
						 * will be upcased by the
						 * linker */
{
    char *tmp;

    if(locName){
	fprintf(stderr,"may only call Localize_Init once.");
	exit(2);
    }

    locName = (char *) malloc(strlen(fileName) + 6);
    strcpy(locName,fileName);      /* copy the fileName into a buffer */
    tmp = strrchr(locName,'.');    /* and get the root of the name    */
    if(tmp){
	*tmp = '\0';
    }
    strcat(locName,".rsc");        /* add our own suffix */
    
    Hash_InitTable(&locHash, -1, HASH_ONE_WORD_KEYS,-1);
    upcaseLinkerResourceNames = upcase_resource_linker_name;

}



/***********************************************************************
 *				Localize_EnterResource
 ***********************************************************************
 * SYNOPSIS:	    Take note that subsequent definitions will be for
 *		    the given resource.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    non-zero if the resource had never been seen before.
 * SIDE EFFECTS:    (internal: currentResource is set to the resource
 *		    just entered)
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/93		Initial Revision
 *
 ***********************************************************************/
int
Localize_EnterResource(Opaque key,  	/* 32-bit value that identifies the
					 * resource */
		       char *name)  	/* The ASCII name of the resource */
{
    Hash_Entry	*ent;	/* entry for this resource in the hash table */
    Boolean   	new; 	/* needed for Hash_CreateEntry */
    ResourceSym	*res;
    
    ent = Hash_CreateEntry(&locHash, (Address) key, &new);

    if(new){
	/* if the thing is new, init the values (zero for all others) */
	res = 	(ResourceSym *)calloc(1,sizeof(ResourceSym) + strlen(name) + 1);
	Hash_SetValue(ent,res);
	
	res->r_name =	 (char *)(res+1);
	strcpy(res->r_name, name);
    }
    currentResource = (ResourceSym *)Hash_GetValue(ent);
    return new;
}


/***********************************************************************
 *				Localize_AddLocalization
 ***********************************************************************
 * SYNOPSIS:	    Enter localization information for a chunk into
 *		    the current resource.
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 1/93		Initial Revision
 *
 ***********************************************************************/
void
Localize_AddLocalization(LocalizeInfo *loc)
{
    if(loc == NULL){
	return;
    }
    if(RES_INSERT_INFO(currentResource) == NULL){
	/*
	 * No info for this resource yet, so make this one the head and tail of
	 * the list.
	 */
	RES_INSERT_INFO(currentResource) =
	    RES_INFO(currentResource) =
		loc;
    }else{
	/*
	 * Append this entry to the end of the list for the current
	 * resource.
	 */
	LOC_NEXT(RES_INSERT_INFO(currentResource)) = loc;
	RES_INSERT_INFO(currentResource) = loc;
    }
    LOC_NEXT(loc) = NULL;
}

/***********************************************************************
 *				Localize_RemoveLocalization
 ***********************************************************************
 * SYNOPSIS:	    Delete a previously-entered localization record
 * CALLED BY:	    (GLOBAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    the thing is unlinked, but not destroyed
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 7/93		Initial Revision
 *
 ***********************************************************************/
void
Localize_RemoveLocalization(LocalizeInfo    *loc,
			    Opaque  	    resKey)
{
    Hash_Entry	    *resEnt;
    ResourceSym	    *res;
    LocalizeInfo    **prevPtr;
    LocalizeInfo    *prev;

    resEnt = Hash_FindEntry(&locHash, (Address) resKey);
    assert(resEnt != NULL);
    res = (ResourceSym *)Hash_GetValue(resEnt);

    for (prevPtr = &res->r_locInfo, prev = NULL;
	 *prevPtr != NULL;
	 prev = *prevPtr, prevPtr = &prev->next)
    {
	if (*prevPtr == loc) {
	    break;
	}
    }
    assert(*prevPtr != NULL);
    (*prevPtr)->next = loc->next;

    if (res->r_locIns == loc) {
	res->r_locIns = prev;
    }
}
    

/***********************************************************************
 *				DumpLocInfo
 ***********************************************************************
 * SYNOPSIS:	    Print an individual localization to the output file
 * CALLED BY:	    Localize_DumpLocalizations
 * RETURN:	    nothing
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/18/92   	Initial Revision
 *
 ***********************************************************************/
static void
DumpLocInfo(LocalizeInfo *loc)
{
    int	loc_min = 0, 
    	loc_max	= 0,
    	flags	= 0;

    if (LOC_MIN(loc) == -1 && LOC_MAX(loc) == -1) {
	flags = 1;
    } else {
	loc_min = LOC_MIN(loc);
	loc_max = LOC_MAX(loc);
    }
    
    if (strchr(LOC_INST(loc) ? LOC_INST(loc) : "", '"') != NULL) {
	const char *cp;
	
	fprintf(locOut, "%s %d %d \"", LOC_NAME(loc), LOC_NUM(loc),
		LOC_HINT(loc));
	for (cp = LOC_INST(loc); *cp != '\0'; cp++) {
	    if ((*cp == '"') || (*cp == '\n')) {
		putc('\\', locOut);
	    }
	    putc(*cp, locOut);
	}
	fprintf(locOut, "\" %d %d %d\n", loc_min, loc_max, flags);
    } else {
	fprintf(locOut,
		"%s %d %d \"%s\" %d %d %d\n",
		LOC_NAME(loc),
		LOC_NUM(loc),
		LOC_HINT(loc),
		(LOC_INST(loc)?LOC_INST(loc):""),
		loc_min,
		loc_max,
		flags);
    }

}	/* End of DumpLocInfo.	*/



/***********************************************************************
 *				Localize_DumpLocalizations
 ***********************************************************************
 * SYNOPSIS:	Print all localization instructions to the output file.
 * CALLED BY:	(GLOBAL)
 * RETURN:  	nothing
 * SIDE EFFECTS:output stream is closed
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JP	11/16/92   	Initial Revision
 *
 ***********************************************************************/
void
Localize_DumpLocalizations (void)
{
    int	    	    	needFile = 0;

    FOR_ALL_RESOURCES(res, {
	if (RES_INFO(res) != NULL) {
	    needFile = 1;
	}
    });

    if (needFile) {
	locOut = fopen(locName,"wt");   

	if(locOut == NULL){
	    fprintf(stderr,"couldn't open localization info file %s.", locName);
	    return;
	}

	/* now declare all groups and their chunks */
	FOR_ALL_RESOURCES(res,{
	    char *x;
	    if(!upcaseLinkerResourceNames){
		fprintf(locOut,"resource %s\n",RES_NAME(res));
	    }else {
		fprintf(locOut,"resource ");
		for(x = RES_NAME(res); *x; x++){
		    if (islower(*x)) {
			putc(toupper(*x),locOut);
		    } else {
			putc(*x,locOut);
		    }
		}
		putc('\n',locOut);
	    }

	    FOR_ALL_LOCINFOS_IN_RESOURCE(res,loc,{
		DumpLocInfo(loc);
	    });
	});

	(void)fclose(locOut);
    }
}	

