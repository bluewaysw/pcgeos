/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Interpreter
FILE:		unload.h

AUTHOR:		Paul L. Du Bois, May  6, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	5/ 6/96  	Initial version.

DESCRIPTION:
	Internal defns for unload.c

	$Revision: 1.1 $

	Liberty version control
	$Id: unload.h,v 1.1 98/10/05 12:35:31 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _UNLOAD_H_
#define _UNLOAD_H_

#ifdef LIBERTY
void* ChunkArrayAppendNoFail(Array* array, int flag); // unload.c
#define ChunkArrayGetCount(array) ((array)->GetCount())
#define ChunkArrayAppend(array, flag) ((array)->Append())
#define ChunkArrayLock(array) ((array)->LockElement(0))
#define ChunkArrayUnlock(array) ((array)->UnlockElement(0))
#define ChunkArrayGetElt(array, type, index) \
    *(type*)((array)->LockElement(index))
#else

/* Man -- chunkarrays are annoying
 * don't shoot me for inventing new api --dubois
 */
#define ChunkArrayAppendNoFail(array, flag) ChunkArrayAppend(array, flag)
#define ChunkArrayGetElt(_arr, _type, _idx)			\
 *(_type *)ChunkArrayElementToPtr(_arr, _idx, NULL)

#define ChunkArrayLock(_ca)					\
 (MemLock(OptrToHandle(_ca)), ChunkArrayElementToPtr(_ca,0,NULL))
 
#define ChunkArrayUnlock(_ca)					\
 MemUnlock(OptrToHandle(_ca))
#endif

typedef struct
{
#ifdef LIBERTY
    Component* headComponent;
    RunTask*   headRunTask;
#else
    optr*	compArray;
    word	numComps;
    RTaskHan*	moduleArray;
    word	numModules;
#endif
} UnloadData;

void UM_CheckComponent(optr* comp, UnloadData* ud);

#ifdef IN_UNLOAD_C

#ifdef LIBERTY

static RunTask*
UM_FindDeadModules(RTaskHan rtaskHan, RunTask** tail);

static void
UM_CallModuleExits(RMLPtr rms, RunTask* head);

static void
UM_NullReferences(RMLPtr rms, 
		  RunTask* head,
		  ArrayOfComponentsHeader* comps, 
		  MemHandle progTask);

static void
UM_RemoveChildRefs(RTaskHan srcMod, RunTask* head);

static void
UM_DestroyComps(RMLPtr rms, 
		RunTask* taskList,
		ArrayOfComponentsHeader* comps, 
		MemHandle progTask,
		word notifyMessage);

static void
UM_DestroyModules(RMLPtr rms, RunTask* taskList, MemHandle progTask);

#else /* GEOS only case follows */

static void
UM_FindDeadModules(RTaskHan rtaskHan, ChunkArray moduleArray);

static void
UM_CallModuleExits(RMLPtr rms, ChunkArray moduleArray);

static void
UM_NullReferences(RMLPtr rms, ChunkArray moduleArray,
		  ArrayOfComponentsHeader* comps, MemHandle  progTask);

static void
UM_RemoveChildRefs(RTaskHan srcMod, RTaskHan* removeMods, word numModules);

static void
UM_DestroyComps(RMLPtr rms, ChunkArray moduleArray,
		ArrayOfComponentsHeader* comps, MemHandle progTask,
		word notifyMessage);

static void
UM_DestroyModules(RMLPtr rms, ChunkArray moduleArray, MemHandle progTask);

#endif /* ifdef LIBERTY (GEOS only case ends) */

static void CheckStruct(byte* vars, word num_vars, UnloadData* ud);
static void CheckScope(byte* varTypes, dword* varData,
		       word num_vars, UnloadData* ud);

static void CheckModule(RTaskHan* module, UnloadData* ud);
static void CheckArray(MemHandle array, UnloadData* ud);

#endif


#endif /* _UNLOAD_H_ */
