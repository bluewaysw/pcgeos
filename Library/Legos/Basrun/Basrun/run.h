/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime pcode interpreter
FILE:		run.h

AUTHOR:		Roy Goldman, Dec 27, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/27/94	Initial version.

DESCRIPTION:
	Exported runtime routines

	$Revision: 1.1 $

	Liberty version control
	$Id: run.h,v 1.1 98/10/05 12:35:20 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _RUN_H_
#define _RUN_H_

#ifdef LIBERTY
#include "Legos/fido.h"
#include "Legos/basrun.h"
#include "Legos/runtask.h"
#else
#include <Legos/fido.h>
#include <Legos/basrun.h>
#include <geos.h>

#include <Legos/Internal/runtask.h>
#endif

#ifndef SCOPE
/* to make defining local scopes easier. */
#define SCOPE
#endif

#ifndef CAST_ARR
#define CAST_ARR(type, array) *( (type *) (& (array)) )
#endif

/* RFTE_startSeg == NULL_SEGMENT implies function hasn't been loaded yet */

#define NULL_SEGMENT 0xffff

typedef struct 
{
    LegosType	VRS_opcode;	/* operation associated with variable */
    word	VRS_offset;	/* offset to variable in whatever scope */
    LegosType	VRS_oldType;	/* variable's type */
    dword	VRS_oldData;	/* variable's data */
} VariableReferenceStruct;

/* --- Prototypes --- */

/* - runrout.c */

extern void RunDestroyTask(RTaskHan);
extern Boolean RunReadPage(RunTask*, word pageNum);
extern RTaskHan RunLoadModuleLow(PTaskHan, TCHAR*, optr, ModuleToken);

extern void _far _pascal BasrunHandleSetOwner(MemHandle	memHandle);

#ifdef __HIGHC__
pragma Alias(BasrunHandleSetOwner,"BASRUNHANDLESETOWNER");
pragma Alias(VMCopyVMChain_FIX,"VMCOPYVMCHAIN_FIX");
#endif

#endif /* _RUN_H_ */
