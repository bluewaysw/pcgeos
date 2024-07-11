/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           bascoint.h

AUTHOR:         Jimmy Lefkowitz, Dec  8, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	jimmy       12/ 8/94           Initial version.

DESCRIPTION:
	internal definitions for basco

	$Id: bascoint.h,v 1.1 98/10/13 21:42:19 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#ifndef _BASCOINT_H_
#define _BASCOINT_H_

#include "mystdapp.h"
#include <file.h>

#include <Legos/basco.h>
#include <Legos/fido.h>

#include <Ansi/stdio.h>
#include <Ansi/string.h>

#include "faterr.h"
#include "comtask.h"
#include "btoken.h"

/* The "right way" to cast an array reference.
 * Can be used as an lval (if you just need an rval, there are easier ways)
 * Ex:
 *   *( (word*) (&code[wOff]) ) = 0xffff;		becomes
 *   CAST_ARR(sbyte, code[wOff]) = ...
 */
#define CAST_ARR(type, array) *( (type *) (& (array)) )

/* NOTE: these must be a power of two as part of an optimization
 */
#define INIT_NUM_SCOPES	16
#define INC_NUM_SCOPES	16

/* note: this used to be (task->liberty), but now the standard is
 * for all legos files to be little-endian
 */
/* I'd make it (0) but that causes tons of unreachable code warnings
 */
#define BIG_ENDIAN (task->liberty == task->liberty+1)


typedef struct _Line
{
   dword    self;   	    	/* self pointer */
   TCHAR    *buffer;
} LineStruct;

typedef LineStruct *LinePtr;


#define GLOBAL_REFS_CHUNK 0x10

/* These are useful when we're working on the current tree in the task.
 * Require local vars: task
 */

#ifndef PREALLOC
#define PREALLOC USE_PREALLOCATED_NODE
#endif

#define CurTree_LOCK(_el) \
 (Token *)HugeTreeLock(task->vmHandle, task->tree, _el)

#define CurTree_APPEND(_node, _el) \
 HugeTreeAppendChild(task->vmHandle, task->tree, _node, PREALLOC, _el)

#define CurTree_GET_NTH(_node, _position) \
 HugeTreeGetNthChild(task->vmHandle, task->tree, _node, _position)

#define CurTree_SET_NTH(_node, _n, _el) \
 HugeTreeSetNthChild(task->vmHandle,task->tree, _node, _n, PREALLOC, _el)

#define CurTree_REMOVE_NTH(_node, _position) \
 HugeTreeRemoveNthChild(task->vmHandle, task->tree, _node, _position)

#define CurTree_GET_PARENT(_node) \
 HugeTreeGetParent(task->vmHandle, task->tree, _node)

#define CurTree_NUM_CHILDREN(_node) \
 HugeTreeGetNumChildren(task->vmHandle, task->tree, _node)

#define CurTree_GET_INDEX(_node) \
 HugeTreeGetNumSibling(task->vmHandle, task->tree, _node)
 
/* This should be in the tree lib
 */
#define TREE_ROOT 0

extern    int	    	SetError(TaskPtr, ErrorCode);
extern    int	    	SetIdentError(TaskPtr, TokenCode);
extern	void		swapWord(word* value);
extern	void		swapDword(dword* value);

extern    void    	sendMessage(optr dest, word msg);
extern	  void	    	SignalError(TaskPtr task);

extern	  void	    	adv_ws(TCHAR *buf, int *pos);
extern	  int	    	strncmp_nocase(TCHAR *s1, TCHAR *s2, int n);

extern word setDSToDgroup(void);
extern void restoreDS(word oldDS);
extern	void	BugGetDataFromCTask(MemHandle ctaskHan);;

#define PROP_ERROR_NC(x) return x;
#define PTR_DUMMY NULL
#define ERROR_SET (task->err_code)



#ifdef DOS
#define FIXED_CA_FIRST_ELEMENT(cah) (((MyHugeArrayHeader *)MemDeref(((ChunkArrayHeader *)cah)->CAH_curOffset))->firstElement)
#else
#define FIXED_CA_FIRST_ELEMENT(cah) ((char *)cah+cah->CAH_offset)
#endif

#endif
