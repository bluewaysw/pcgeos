/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		stack.h

AUTHOR:		Paul L. Du Bois, Jun  5, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	6/ 5/96  	Initial version.

DESCRIPTION:
	Stack-manipulation macros

	Some macros need the macro RMS defined.  If the variable
	rms is a pointer

#define RMS (*rms)

	otherwise

#define RMS rms
	

	$Revision: 1.1 $
        $Id: stack.h,v 1.1 98/10/05 12:35:26 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _STACK_H_
#define _STACK_H_

/* These count elements, not bytes.  For purposes of memory allocation,
 * one element is 5 bytes.  INITIAL and INCREMENT should be multiples of 4.
 */
#define INITIAL_STACK_LENGTH	256
#define STACK_LENGTH_INCREMENT INITIAL_STACK_LENGTH
#ifdef LIBERTY
#define MAX_STACK_LENGTH	2560
#else
#define MAX_STACK_LENGTH	1536
#endif

/* Realloc when there is only room for 32 more elements on the stack */
#define STACK_REALLOC_THRESHOLD	(32 * 4)

#define STACK_SIZE() (RMS.ptask->PT_stackLength * 5)

/*- New macros */
/* Push/pop/top/nth macros for type and data stacks
 * Commonly-used macros that modify both stacks
 * Macros for > 4-byte data on the data stack
 *
 * Top of stack is index 1
 */
#define PushType(_t)	*(RMS.spType++) = (_t)
#define PopType()	*(--RMS.spType)
#define PopTypeV()	((void)RMS.spType--)
#define TopType()	NthType(1)
#define NthType(_n)	RMS.spType[-(_n)]

#define PushData(_d)	*(RMS.spData++) = (dword)(_d)
#define PopData()	(*(--RMS.spData))
#define PopDataV()	((void)RMS.spData--)
#define TopData()	NthData(1)
#define NthData(_n)	(RMS.spData[-(_n)])

#define PushTypeData(_t, _d) PushType(_t), PushData(_d)
#define PopVal(_rv)	(void) ((_rv).type=PopType(), (_rv).value=PopData())
#define PopValVoid()	(void) (RMS.spData--, RMS.spType--)

#define PushBigData(_dptr, _type)				\
 *(_type *)(RMS.spData) = *(_dptr);				\
 RMS.spData = (dword*)((byte*)RMS.spData + sizeof(_type));	\
 ASSERT_ALIGNED(RMS.spData)

#define PushBigDataVoid(_type)					\
 RMS.spData = (dword*)((byte*)RMS.spData + sizeof(_type));	\
 ASSERT_ALIGNED(RMS.spData)

#define PopBigData(_dptr, _type)					\
 (void)(RMS.spData = (dword*)((byte*)RMS.spData - sizeof(_type)));	\
 *(_dptr) = *(_type *)(RMS.spData);					\
 ASSERT_ALIGNED(RMS.spData)

#define TopBigData(_type)					\
 ((_type*)((byte*)RMS.spData - sizeof(_type)))

#define PopBigDataVoid(_type)						\
 (void) (RMS.spData = (dword*)((byte*)RMS.spData - sizeof(_type)));	\
 ASSERT_ALIGNED(RMS.spData)

#endif /* _STACK_H_ */
