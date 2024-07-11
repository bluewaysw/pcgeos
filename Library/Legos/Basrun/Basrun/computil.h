/* -*- c -*- */
/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		computil.h

AUTHOR:		Paul L. Du Bois, Apr  5, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	4/5/96  	Initial version.

DESCRIPTION:
	Exported routines from computil.goc

        Liberty version control
	$Id: computil.h,v 1.1 98/10/05 12:35:06 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _COMPUTIL_H_
#define _COMPUTIL_H_

typedef enum
{
    GACF_NONE,			/* return all components for the passed
				   rtasks */
    GACF_TOP_LEVEL,		/* return all components who are not
				   a descendant of someone else already in
				   the array.  Each component needs to belong
				   to one of the passed rtasks. */
    GACF_ANY_DESCENDANT		/* return all components that have an ancestor
				   in one of the given rtasks. */
} GACFilter;


typedef struct
{
#if defined(LIBERTY)
    /* The Liberty way is the new awesome way that does not need memory to
       be allocated for the list of components being deleted */
    Component *head;
    Component *last;
    Component *lastTopLevel;	/* Last one with "app" parent */
#else
    /* The GEOS way is the old way that requires memory to be
       allocated for the list of components being deleted */

    MemHandle	arrayBlock;	/* array of optrs */
    word	numElements;	/* number of optrs in array */
    word 	numTopLevelComps; /* Returns the number of top level components
				     when passed to Run_GetComponentsToDestroy.
				     */

    /*- For internal use during recursion */
    optr	appObject;	/* GeodeGetAppObject(0) */
    optr*	comps;		/* Pointer to array in memory, or NULL */
    word	arrayCount;	/* number of optrs that can fit in array
				   before it needs resizing */
#endif
} ArrayOfComponentsHeader;

#define MEM_ERROR -1

#ifdef LIBERTY
int
Run_GetComponentsToDestroy(optr comp, 
			   RunTask* head,
			   ArrayOfComponentsHeader *header);

void
Run_CallRemoveReferences(Component* comps, RunTask* runTasks);

int
Run_GetSizeOfComponents(RTaskHan *rtasks);

void
Run_SendDestroyComponents(ModuleToken firstFidoToken, Component* comps);

#else	/* GEOS version below */

int
Run_GetComponentsToDestroy(optr comp, RTaskHan *rtasks,
			   ArrayOfComponentsHeader *header);

void
Run_SendDestroyComponents(optr o, optr compArray, optr uiBlockArray,
			  optr fidoModuleArray, word notifyMessage);
void
Run_CallRemoveReferences(optr* compArray, RTaskHan* moduleArray);
#endif

#endif /* _COMPUTIL_H_ */
