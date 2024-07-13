/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Basic Runtime (basrun)
FILE:		basrun.h

AUTHOR:		Paul L. DuBois, Jan 19, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	 1/19/95	Initial version.

DESCRIPTION:
	Funcs & structs defined in basrun lib which are exported
	to all.

	$Id: basrun.H,v 1.1 1999/02/18 22:49:02 (c)turon Exp martin $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BASRUN_H_
#define _BASRUN_H_

#ifdef LIBERTY
#include <Legos/opcode.h>
#include <Legos/legtype.h>
#include <Legos/runheap.h>
#else
#include <geoworks.h>
#include <geos.h>
#include <vm.h>
#include <math.h>
#include <Legos/opcode.h>
#include <Legos/legtype.h>
#include <Legos/runheap.h>
#endif

/* from clipbrd.goh */
typedef dword ClipboardItemFormatID;

typedef enum 
{
    BPT_APP,
    BPT_TOP
} BasrunParentType;

typedef MemHandle RTaskHan;
typedef MemHandle PTaskHan;

typedef struct
{
    VMFileHandle	LC_vmfh;
    VMChain		LC_chain;
    ClipboardItemFormatID LC_format;
} LegosComplex;

/* NOTE: because VMCopyVMChainTree seems to be different for different
 * platforms, and DBCS and SBCS disagree on the word ordering, I have
 * changed the macros to just take the value which ever word its in, as long
 * as its non-zero, and the DBITEM macro checks to make sure both words are
 * not non-zero - this is non-optimal, but it should work in all cases
 */
#undef VMCHAIN_GET_VM_BLOCK
#undef VMCHAIN_IS_DBITEM
#define VMCHAIN_GET_VM_BLOCK(chain) ((VMBlockHandle)(chain) ? (VMBlockHandle)(chain) : (VMBlockHandle)(((unsigned long)chain >> 16)))
#define VMCHAIN_IS_DBITEM(chain) ((word)chain && (word)((chain >> 16)))

extern VMFileHandle
ProgGetVMFile(PTaskHan);

extern PTaskHan
ProgAllocTask(optr interpreter, VMFileHandle vmfile);

extern RTaskHan
RunLoadModule(PTaskHan, TCHAR* url, optr uiParent);

extern void
RunUnloadModule(void		*rms,	
		RTaskHan	removeMod,
		Boolean		destroy,
		word		notifyMessage);

#ifdef LIBERTY

/* "switch to" the module by calling system:SwitchTo() */
extern void SystemModuleSwitchTo(TCHAR *moduleLocatorString);
extern void SystemModuleUnload(MemHandle rtaskHan);

extern PTaskHan theProgTaskHandle;

#endif

extern void
ProgDestroyTask(PTaskHan);

extern VMFileHandle
RunTaskGetVMFile(MemHandle rtaskHan);

extern void
ProgSetMainTask(PTaskHan ptask, RTaskHan rtask);

extern RTaskHan
ProgGetMainTask(PTaskHan ptask);

#ifndef LIBERTY
extern void
ProgTurboChargeFido(PTaskHan ptaskHan);
#endif

extern dword
RunFindFunction(MemHandle rtaskHan, TCHAR* name);

Boolean
RunCallFunction(MemHandle rtaskHan, TCHAR *name, byte *params,
		LegosType *returnType, dword *returnVal);

Boolean
RunCallFunctionWithKey(MemHandle rtaskHan, dword functionName, 
		       byte *params, LegosType *returnType, 
		       dword *returnVal);

extern void
RunNullRTaskCode(RTaskHan rtaskHan);

extern void
RunSetBuildTime(RTaskHan rtaskhan, Boolean flag);

extern void 
RunTopLevel(RTaskHan rtaskHan);

extern RTaskHan 
RunAllocTask(PTaskHan, optr uiParent);

extern void
RunSetURL(RTaskHan, TCHAR* url);

#ifdef LIBERTY
extern RTaskHan
RunAllocTaskXIP(PTaskHan, optr uiParent, MemHandle header, ModuleToken mod);
#endif

extern RunHeapToken
RunAllocComplex(PTaskHan);

extern RunHeapToken
RunCreateComplex(PTaskHan, ClipboardItemFormatID, VMFileHandle, VMChain);

extern void 
ProgAddRunTask(PTaskHan, RTaskHan);

extern void
ProgAddDebuggedRunTask(PTaskHan ptask, RTaskHan rtask);

extern MemHandle
RunGetFidoTask(RTaskHan);

extern void
ProgCleanHeap(PTaskHan);

extern VMChain _far _pascal VMCopyVMChain_FIX
  (VMFileHandle sourceFile, VMChain sourceChain, VMFileHandle destFile);

void
ProgResetTask(PTaskHan ptaskHan);

extern Boolean
RunGetAggPropertyExt(PTaskHan ptaskHan, RunHeapToken aggComp,
		     TCHAR* propName, LegosType* lType, dword* lData);

extern Boolean
RunSetAggPropertyExt(PTaskHan ptaskHan, RunHeapToken aggComp,
		     TCHAR* propName, LegosType lType, dword lData);


/*
#define RTASK(x) ProgGetMainTask(x)
*/

/* CompPropertyError -- used as a return value for TYPE_ERROR
 * from MSG_ENT_GET_PROPERTY and MSG_ENT_SET_PROPERTY.  Order must match 
 * that in basrun.def and in runerr.h.
 */
typedef enum
{
    CPE_INVALID_ACTION,
    CPE_READONLY_PROPERTY,	  /* this property cannot be set */
    CPE_UNKNOWN_PROPERTY,	  /* the property does not apply to the 
				     component */
    CPE_PROPERTY_TYPE_MISMATCH,   /* the property is the wrong type */
    CPE_PROPERTY_SIZE_MISMATCH,   /* the property is the wrong size */
    CPE_PROPERTY_NOT_SET,	  /* ?? */
    CAE_WRONG_NUMBER_ARGS,
    CAE_WRONG_TYPE,
    CPE_SPECIFIC_PROPERTY
} CompPropertyError;

typedef union 
{
    sword	   LD_integer;	/* TYPE_INTEGER */
    sdword	   LD_long;	/* TYPE_LONG */
    dword          LD_float;	/* TYPE_FLOAT - was float */

    MemHandle	   LD_array;	/* TYPE_ARRAY */
    MemHandle	   LD_module;	/* TYPE_MODULE */

    optr		LD_comp;   /* TYPE_COMPONENT */
    RunHeapToken	LD_struct; /* TYPE_STRUCT */
    RunHeapToken	LD_string; /* TYPE_STRING */
    RunHeapToken    	LD_complex; /* TYPE_COMPLEX */

    word    	    	LD_gen_word;	/* generic values -- word, dword */
    dword   	    	LD_gen_dword;

    CompPropertyError	LD_error;	/* TYPE_ERROR */
    TCHAR *		LD_fptr;
} LegosData;


typedef struct
{
    LegosType	AH_type;
    word	AH_numDims;
    word	AH_dims[MAX_DIMS];
    word    	AH_maxElt;		/* total number of elements */
} ArrayHeader;


/* Liberty uses the token, Geos uses the string */
typedef union
{
#ifdef LIBERTY
    RunHeapToken nameToken;
#else
    TCHAR*	nameString;
#endif
    byte	nameMessage;
} PropertyName;

/* Enumerates the first few fields of an aggregate component.
 * This is exported because it's needed in both the compiler and the
 * basrun.
 */
typedef enum {
    AF_LIB_MODULE,
    AF_LOAD_MODULE,
    AF_CLASS,
    AF_PROTO,
    AF_NUM_FIELDS
} AggregateField;

#define AGG_FIELD_TYPES {TYPE_MODULE, TYPE_MODULE, TYPE_STRING, TYPE_STRING}

/* RunVTabs are used for storing structure info,
 * used when creating structures
 */
typedef struct
{
    word	RVT_numFields;
    word	RVT_size;
/*  label	RVT_data;*/
} RunVTab;

/* FIXME: these are kinda big
 * Is it worth having a table with variable-sized entries?
 * Most of the time RVTE_dims won't be needed.
 */
typedef struct
{
    LegosType	RVTE_type;	/* Types might have TYPE_ARRAY_FLAG bit set */
    byte	RVTE_structType; /* struct identifier, if TYPE_STRUCT */
    word	RVTE_dims[MAX_DIMS];
/*    word	RVTE_offset; */
} RunVTabEntry;
    
#endif /* _BASRUN_H_ */
