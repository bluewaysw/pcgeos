/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		localize.h

AUTHOR:		Josh Putname, Nov 16, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JHP	11/16/92   	Initial version.

DESCRIPTION: Library that uic/goc/esp use to produce localization info.

		Typical usage:

		when switching resources:

		Localize_EnterResource(SymbolPtr *<sym>,char *sym->name)
		
		when 
		Localize_EnterChunk(chunk->)

	$Id: localize.h,v 1.4 93/05/14 20:05:18 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef __LOCALIZATION_H
#define	__LOCALIZATION_H

/* 
 * These are the types of chunks. 
 * We set the high bit when the chunk is not localizable (e.g. a string 
 * should stay the same from country to country).
 */

typedef enum { 
    CDT_unknown,       /* 0 */
    CDT_visMoniker,    /* 1 */
    CDT_GString,       /* 2 */
    CDT_text,          /* 3 */
}  ChunkDataType;


#define LOC_NEXT(l)  	((l)->next)
#define LOC_NUM(l)	((l)->chunkNumber)
#define LOC_NAME(l)	((l)->chunkName)
#define LOC_INST(l)	((l)->instructions)
#define LOC_HINT(l)	((l)->dataTypeHint)
#define LOC_MIN(l)	((l)->min)
#define LOC_MAX(l)	((l)->max)
typedef struct _locinfo{
    char 		*chunkName;    /* may be a goc/uic generated name  */
    int 		chunkNumber;   /* chunk's number in resource       */
    ChunkDataType	dataTypeHint;  /* some idea of what the data it is */
    char		*instructions; /* instructions for human           */


    int    		min;
    int			max;

    struct _locinfo	*next;
} LocalizeInfo;


#define RES_NAME(r) 		((r)->r_name)
#define RES_INFO(r) 		((r)->r_locInfo)
#define RES_INSERT_INFO(r) 	((r)->r_locIns)


typedef struct 	{
    char		*r_name;

    LocalizeInfo 	*r_locInfo;
    LocalizeInfo 	*r_locIns;
}ResourceSym;


/* initialize the localiztion module. Output file is 'fileName'   */
/* resource_names_are_all_caps should be not zero if linker names */
/* for resources are upcased.                                     */
extern void Localize_Init(char *fileName,int resource_names_are_all_caps);



/*
 * Store localization info for output later.
 * The info will include the chunk number and other information.
 * The resource is the current one as set by Localize_EnterResource().
 */

extern void Localize_AddLocalization(LocalizeInfo *loc);

extern void Localize_RemoveLocalization(LocalizeInfo *loc, Opaque resKey);

/* produce and asm file with all the Localization DB structures */
extern void Localize_DumpLocalizations(void);


/* Create a resource that one may refer to by 'key'. 	*/
/* This becomes the implicit resource for chunks.	*/ 	
/* If the resource exists already, the resource becomes */
/* the current resource. 				*/
/* Returns true iff the resource is new.		*/
extern int Localize_EnterResource(Opaque key,char *name);


#endif
