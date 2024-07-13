/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



	Copyright (c) Geoworks 1996 -- All Rights Reserved



PROJECT:	

MODULE:		

FILE:		ent.h



AUTHOR:		jimmy, Feb 29, 1996



REVISION HISTORY:

	Name	Date		Description

	----	----		-----------

	jimmy	2/29/96  	Initial version.



DESCRIPTION:

	ent stuff



	$Id: ent.h,v 1.1 97/12/05 12:16:16 gene Exp $

	$Revision: 1.1 $



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef _ENT_H_

#define _ENT_H_







#include <Legos/basrun.h>

#include <Legos/runheap.h>



/*

 * Notification block to use for controller components.

 */

typedef struct {

    optr        NCCC_component;         /* new component to use       */

} NotifyCurrentComponentChange;



typedef struct 

{

    LegosType   CD_type;

    LegosData   CD_data;

} ComponentData;





typedef ByteFlags EntState;

#define ES_INITIALIZED 0x80

#define ES_IS_VIS 0x40

#define ES_IS_GEN 0x20



typedef ByteFlags EntFlags;

#define EF_BUILT 0x4

#define EF_ALLOWS_CHILDREN 0x2

#define EF_VISIBLE 0x1



typedef struct {

    ClassStruct *ECPS_classPtr;

    TCHAR        _near *ECPS_className;

} EntClassPtrStruct;



/*

 * Components for a given interpreter need to be in their own object block

 * with the following header.  This happens automatically when a component is

 * created via the interpreter.

 */

typedef struct {

    ObjLMemBlockHeader  EOBH_lmemHeader;

    optr                EOBH_interpreter;

    MemHandle           EOBH_task;

} EntObjectBlockHeader;



/*

 * Use this macro to get the interpreter of a given EntClass object.

 */

#define EntGetInterpreter(pself)  (((EntObjectBlockHeader *) \

			((((dword) (pself)) >> 16) << 16))->EOBH_interpreter)



#define EntGetRunTask(pself)  (((EntObjectBlockHeader *) \

			((((dword) (pself)) >> 16) << 16))->EOBH_task)



/*

 * Macro to dereference the Ent part of an object.

 *

 * USAGE:       pself = ObjDerefEnt(oself);

 */

#define ObjDerefEnt(obj)  ObjDeref(obj, word_offsetof(EntBase,  Ent_offset))





/*****************************************************************

 * Property structures & related macros

 *****************************************************************/



typedef enum {

    PDT_WORD_DATA = 1,

    PDT_DWORD_DATA,

    PDT_SEND_MESSAGE,

    PDT_CALL_FPTR,

    PDT_ERROR,

    PDT_UNDEFINED_PROPERTY

} PropertyDispatchType;



typedef union {

    word        PD_message;

    dword       PD_fptr;

    dword       PD_dword;

    word        PD_word;

} PropertyDispatchData;



typedef struct {

    PropertyDispatchType PDS_dispatchType;

    PropertyDispatchData PDS_dispatchData;

} PropertyDispatchStruct;



typedef struct {

    TCHAR _near *PES_propName;

    LegosType PES_propType;

    PropertyDispatchStruct PES_get;

    PropertyDispatchStruct PES_set;

} PropEntryStruct;



#define ENT_PROPERTY_TABLE_TERMINATOR   (-1)

#define ENT_ACTION_TABLE_TERMINATOR     (-1)



#define makeMessagePropertyStruct(comp, propname, propnameString, type, getMsg, setMsg) \

TCHAR comp##propname##String[] = propnameString; \

PropEntryStruct comp##propname##Prop = \

				{(TCHAR _near *) comp##propname##String, \

				type, \

				{PDT_SEND_MESSAGE, getMsg}, \

				{PDT_SEND_MESSAGE, setMsg}};



#define makeFptrPropertyStruct(comp, propname, propnameString, type, getFptr, setFptr) \

TCHAR comp##propname##String[] = propnameString; \

PropEntryStruct comp##propname##Prop = \

				{(TCHAR _near *) comp##propname##String, \

				type, \

				{PDT_CALL_FPTR, getFptr}, \

				{PDT_CALL_FPTR, setFptr}};



#define mkPropTableEntry(comp, propname) &##comp##propname##Prop

#define endPropTable (PropEntryStruct _near *) ENT_PROPERTY_TABLE_TERMINATOR







/*****************************************************************

 * Property Definitions

 *****************************************************************/



typedef enum {

    EP_PROTO = 1,

    EP_PARENT,

    EP_VISIBLE,

    EP_ENABLED,

    EP_CLASS,

    EP_VERSION,

    EP_NAME

} EntProperty;



#define ENT_LAST_PROPERTY EP_NAME





typedef struct

{

    TCHAR *              EHES_eventName; /* name of event */

    ComponentData *     EHES_result;    /* place to store result if function */

    int                 EHES_argc;      /* number of arguments following this struct */

    ComponentData       EHES_argv[4];   /* first four arguments */

} EntHandleEventStruct;



typedef struct

{

    EntHandleEventStruct        EHESS_data;

    ComponentData               EHESS_argv[10];

} EntHandleEventSuperStruct;            /* More args if needed */



/* Structures and types for ENT_RESOLVE_*

 */

#define ENT_TYPE_BUFFER_LENGTH 30

typedef TCHAR EntTypeName[ENT_TYPE_BUFFER_LENGTH];

typedef struct

{

    TCHAR _far*	ERS_propOrAction;

    word	ERS_message;

    LegosType	ERS_type;

    word    	ERS_numParams;

    EntTypeName* ERS_typeBuf;

} EntResolveStruct;



typedef struct {

    optr *	RRS_comps;	/* array of components, null terminated */

    RTaskHan *	RRS_modules;	/* array of modules, null terminated */

} RemoveReferenceStruct;







/* ===============================================================

 *  

 *  Routines

 * 

 * ===============================================================*/



/*	No ActionEntryStruct yet

extern Boolean _pascal

EntResolveAction(ActionEntryStruct _near **actionTable,

		 EntResolveStruct* ers);

*/



/* Returns FALSE if property/action not found in table */

extern Boolean

_pascal EntResolvePropertyAccess(PropEntryStruct _near **propTable,

				 EntResolveStruct* ers);



extern PropertyDispatchType 

_pascal EntDispatchSetProperty(optr component, 

				PropEntryStruct _near **propTable,

				ComponentData *value,

				TCHAR _far *prop);



extern PropertyDispatchType

_pascal EntDispatchGetProperty(optr component,

				PropEntryStruct _near **propTable,

				ComponentData *value,

			       TCHAR _far *prop);



extern VMFileHandle

_pascal EntGetVMFile(optr component);



#endif /* _ENT_H_ */

