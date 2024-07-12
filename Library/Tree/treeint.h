/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           treeint.h

AUTHOR:         Roy Goldman, Dec  4, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       12/ 4/94           Initial version.

DESCRIPTION:
	Header for internal routines used by Tree code

	$Id: treeint.h,v 1.1 97/05/30 08:20:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _TREEINT_H_
#define _TREEINT_H_

#include <tree.h>

/* INTERNAL ROUTINES                   */

/* Given a pointer to a node's header
   return the pointer of its child table
 */

Node *FindChildrenOffset(FixedNodeData *d);

/* Grab pointer of the opaque data,
   given a pointer to the node's header */

void *FindDataOffset(FixedNodeData *d);

/* Rescan children to find new count when necessary */

void RecountChildren(FixedNodeData *d);


#if ERROR_CHECK

/* Check integrity of a node (for ec) */
void CheckNode(VMFileHandle vmFile,
	       VMBlockHandle treeHandle,
	       Node node);    

#endif

/* Take parameters for all node insertion functions and
   return either the specified node or allocate and return
   a new one */

Node GiveMeThatNode(VMFileHandle vmFile,
		   VMBlockHandle treeHandle,
		   int sizeOrSPECIAL,
		   Node childSlotsorNodeToInsert);

/* Expand the number of children in a locked block,
   and return pointer to new locked node */

FixedNodeData *ResizeAndRelock(VMFileHandle vmFile,
			       VMBlockHandle treeHandle,
			       Node node,
			       FixedNodeData *d);
#endif /* _TREEINT_H_ */
