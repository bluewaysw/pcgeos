/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		codeint.h

AUTHOR:		Roy Goldman, Dec 19, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/19/94		Initial version.

DESCRIPTION:
	Headers for internal code-generation routines

	$Id: codeint.h,v 1.1 98/10/13 21:42:34 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _CODEINT_H_
#define _CODEINT_H_

#include "btoken.h"
#include "mystdapp.h"
#include "label.h"
#include "bascoint.h"
#include <tree.h>

#define CG_MAXSEGSIZE 4096

#define CG_MAXSEGSPERFUNC 16
#define CHECK(x) if (!(x)) return FALSE


/* Generate the code for a function */
extern Boolean CodeGenRoutine(TaskPtr task);
extern void CodeGenEndRoutine(TaskPtr task, word vtab, word firstLocal,
			      word numParams);

/* Generate code for a block of code
   IF,FOR,DO,CASE,ASSIGNMENT,PROC CALL, etc. */

extern Boolean CodeGenBlockOfCode(TaskPtr task, Node node, 
				  Label forExitLabel,
				  Label doExitLabel);

/* The following are all called by the above CodeGenBlockOfCode */

/* Code generate the IF/THEN/ELSE parse subtree */
extern Boolean CodeGenIf(TaskPtr task, Node node, 
			 Label forExitLabel,
			 Label doExitLabel);

extern Boolean CodeGenCompInit(TaskPtr task, Node node,int lineNum);

/* Spit out code for all DO loops: code in here can't
   exit back more than one level, so don't pass DoexitLabel */

extern Boolean CodeGenDo(TaskPtr task, Node node, Label forExitLabel);

/* For loops: Like with DO, don't need exitLabel here*/
extern Boolean CodeGenFor(TaskPtr task, Node node, Label doExitLabel);
extern Boolean CodeGenExpr(TaskPtr task, Node node);
extern Boolean CodeGenExit(TaskPtr task, Node node,
			   Label forExitLabel, Label doExitLabel);
extern Boolean CodeGenSelect(TaskPtr task, Node node,
			   Label forExitLabel, Label doExitLabel);

extern Boolean CodeGenGoto(TaskPtr task, Node curNode);
extern Boolean CodeGenResume(TaskPtr task, Node curNode);

/* Go up the tree, looking for a node of type code */
/* Used for checking context of EXIT commands      */
/* Returns TRUE if it can find one, else false     */

extern Boolean CodeGenCheckContext(TaskPtr task, Node start,
				   TokenCode code);
extern Boolean CodeGenExit(TaskPtr task, Node node, 
			   Label ForExitLabel,
			   Label DoExirLabel);
extern Boolean CodeGenLineBegin(TaskPtr task, sword ln);
extern Boolean CodeGenLineBeginNext(TaskPtr task, Label* l);

/*********************************************************************
 *			CodeGenNewSegment
 *********************************************************************
 * SYNOPSIS:	Set up a new code segment and set up task to be ready 
 *              to emit code to it.
 *              Assumes old segment (if it exists) has already
 *              been taken care of.
 *
 * CALLED BY:	Three places:
 *               CodeGenAllFunctions: once for each function for
 *                                    initial storage
 *               CodeGenEmit{Byte,Word,Dword,Var}: if necessary
 *                                     to break up function across segs.
 *
 *               CodeGenCheckFreeSpace: For certain optimizations,
 *                                      use this call to see in advance
 *                                      if the current segment has
 *                                      enough free space. If not,
 *                                      it will call here to create a new
 *                                      segment.
 *
 * 
 * 
 * RETURN:      New segment number in task->curseg.
 *              Reset instruction pointer for current segment to 0.
 *              Lock down the new segment so you can access it directly
 *              with segPtr.
 *
 *              Remember a segment has a max size of 4096 bytes.
 *
 *              Adds one two the function table's notion of how
 *              many segments are used for the current function.
 *
 * SIDE EFFECTS:  Modifies some task slots.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern void CodeGenNewSegment(TaskPtr task);


/*********************************************************************
 *			CodeGenFinishSegment
 *********************************************************************
 * SYNOPSIS:	Given a task, assume we are finished
 *              writing code to the task's current segment
 *              of the current function.
 *              Set the segment to its correct size, and update
 *              the function table.
 * CALLED BY:	Exact three places mentioned above in CodeGenNewSegment,
 *              called right before creating a new segment or for finishing
 *              off the last segment.
 * RETURN:
 * SIDE EFFECTS: Modifies some task slots.
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern void CodeGenFinishSegment(TaskPtr task);


/*********************************************************************
 *			CodeGenEmitByte
 *********************************************************************
 * SYNOPSIS:	Emit one byte of code for current function
 *              , adjusting all instruction
 *              pointers, counters, segments, etc.
 * CALLED BY:	
 * RETURN:      False if there is no more room for this function
 *              (Hit 64K barrier!)
 *
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern Boolean CodeGenEmitByte(TaskPtr task, byte data);
extern Boolean CodeGenEmitWord(TaskPtr task, word data);
extern Boolean CodeGenEmitDword(TaskPtr task, dword data);
extern Boolean CodeGenEmitLabel(TaskPtr, Label);
extern void CodeGenEmitByteNoCheck(TaskPtr task, byte data);
extern void CodeGenEmitWordNoCheck(TaskPtr task, word data);
extern void CodeGenEmitDwordNoCheck(TaskPtr task, dword data);
extern void CodeGenEmitLabelNoCheck(TaskPtr, Label);

/*********************************************************************
 *			CodeGenEmitVar
 *********************************************************************
 * SYNOPSIS:	Same as above, but takes a pointer and emits
 *              a variable length of code.
 *
 *              NOTE: This variable length should still be relatively
 *              "small," since each node should emit a small
 *              amount of data..
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern Boolean CodeGenEmitVar(TaskPtr task, byte *adr, word len);


/*********************************************************************
 *			CodeGenCheckFreeSpace
 *********************************************************************
 * SYNOPSIS:	Check the current segment, seeing if there is still
 *              enough free space in the current segment.
 *              If not, and we haven't used up all available segments
 *              for this function (16), then set up the task
 *              for the next one and return true.
 *
 *              If we are Full Full, return False. 
 *
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern Boolean CodeGenCheckFreeSpace(TaskPtr task, word len);

/*********************************************************************
 *			CodeGenEnoughRoom
 *********************************************************************
 * SYNOPSIS:	Simple macro returns true iff there is enough
 *              space in current segment for specified amount of code
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
#define CodeGenEnoughRoom(task, size) \
((task)->segIp+(size) <= CG_MAXSEGSIZE-3)


/*********************************************************************
 *			CodeGenEnable
 *********************************************************************
 * SYNOPSIS:	Turn code generation on. This should be the
 *              default behavior, and need only be called after
 *              code generation is turned off.
 *
 *              Turn code generation off when you want to do a
 *              code-generating traversal only to find out the SIZE
 *              of the code to be generated, not to actually emit any.
 *
 *              This is here in anticipation of optimizing segment breaks,
 *              such as if checking the amount of code in a looping
 *              construct and then deciding whether or not to push
 *              it to the next segment.
 *
 *              To do this:
 *                 Turn code generation off with CodeGenDisable
 *                 Call code generation code for desired tree
 *                        (These calls will now increment task->codeSize
 *                        instead of emitting code)
 *                 Check task->codeSize for size of the block of code.
 *                 Turn code generation back on with CodeGenEnable
 *
 *
 *
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:  
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94		Initial version			     
 * 
 *********************************************************************/
extern void CodeGenEnable(TaskPtr task); 


/*********************************************************************
 *			CodeGenDisable
 *********************************************************************
 * SYNOPSIS:	See above, CodeGenEnable
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    Sets task's codeSize counter to 0.
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/14/94		Initial version			     
 * 
 *********************************************************************/
extern void CodeGenDisable(TaskPtr task);



/* Code Segment Abstraction functions */

/*********************************************************************
 *			CodeSegAlloc
 *********************************************************************
 * SYNOPSIS:	Allocate a new segment for the current function.
 *              Will ALWAYS succeed--so client has to check
 *              to make sure no max seg/function limit has been passed.
 * CALLED BY:	
 * RETURN:      word index to new block
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern word CodeSegAlloc(VMFileHandle vmfile, VMBlockHandle block);


/*********************************************************************
 *			CodeSegLock
 *********************************************************************
 * SYNOPSIS:	Return a pointer to the given code segment, and
 *              if size param is non-NULL, return size of block there.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern byte *CodeSegLock(VMFileHandle vmfile, VMBlockHandle block,
		  word seg, word *size);


#define CodeSegUnlock HugeArrayUnlock
#define CodeSegDirty HugeArrayDirty



/*********************************************************************
 *			CodeSegContract
 *********************************************************************
 * SYNOPSIS:	Cut down a segment to its new size...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/13/94		Initial version			     
 * 
 *********************************************************************/
extern void CodeSegContract(VMFileHandle vmfile,
		     VMBlockHandle block,
		     word seg,
		     word newSize);


extern Boolean CodeGenEmitNoOp(TaskPtr task, Node node, Boolean force);
extern Boolean CG_EmitCleanup(TaskPtr task, Node start,
			      Node* finalNode, TokenCode code);
extern Boolean CG_CheckTarget(TaskPtr task, Node startNode, Node stopNode);

Boolean CG_EmitWordOrByteVar(TaskPtr task, Opcode opcode, dword key);


#endif /* _CODEINT_H_ */

