/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           tree.h

AUTHOR:         Roy Goldman, Nov 30, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       11/30/94           Initial version.

DESCRIPTION:
	
        Header file for general tree support.

	Easy and flexible....

	We use one hugearray to serve as the heap, or supplier
	of nodes.  

        Words (typedef'd to be a Node) are used
	to identify children, meaning each tree can have
	up to 65535 nodes.

        Since each node is one element,
	and all children pointers are stored with the element,
	performance will downgrade when a specific node has
	more than about 3000 children.  I suggest using some
	kind of hack to prevent cases like this.


	$Id: tree.h,v 1.1 98/07/06 19:12:43 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _TREE_H_
#define _TREE_H_

#include <geos.h>
#include <heap.h>
#include <geode.h>
#include <resource.h>
#include <ec.h>
#include <object.h>
#include <vm.h>
#include <hugearr.h>
#include <system.h>
#include <geoworks.h>


/* Each node in a heap has a unique Node identifier */

typedef word Node;


#define NullNode 65535
#define MAX_NUMBER_NODES 65535
#define USE_PREALLOCATED_NODE -1
#define HugeTreeUnlock HugeArrayUnlock
#define HugeTreeDirty HugeArrayDirty

/* To use this package, allocate one tree heap (with HugeTreeCreate)
   for each conceptual tree you wish to build.

   Different heaps can't be merged easily, and space is only recovered
   when an entire heap is destroyed.

   Nodes within a heap are identified by two-byte id's of type Node.
   These are unique to a tree heap.

   The NullNode constant identifies empty nodes.

   Children are 0-indexed. (First child described as 0th child).

   Nodes can be linked into an existing tree as they are created,
   or they can be created and linked in later.


*/


/* Each non-null node in the tree heap looks like this:

Node parent               : id of parent, or NullNode if none

int childSlots;           : Number of slots available for children
                            before additional storage (resizing) is required,
	                    provided when the node is created.

int numChildren;          : Actual number of children. This is defined
                            precisely as 1 + the index of the last non-null
			    child.  This is kept updated internally.
                       
			    Note numChildren is always <= childSlots.
			    
int dataSize              : the size of the opaque data stored in this node;
                            provided when node is created

OPAQUE DATA               : dataSize bytes

Node children[childSlots] : Array of children, can be resized...



   Advanced usage pitfalls:


   Things get tricky when you set children equal to NULL and/or
   try to delete children of a node when that node has some NULL
   children.

   numChildren's definition is very important.  Again it is
   1 + the 0-based index of the last non-null child.

   This means that if you have a node A with no children and set 
   its 7th child to be a non-null node X, then A now has 8 children,
   the first 7 of which are Null..

   If you then remove A's 7th child (or set the 7th child to Null),
   A will then have 0 children.

   Get it?! Be careful, because you could get SLAMMED when you try
   stuff like this:

   n = HugeTreeGetNumChildren
   for i = n-1 to 0 step -1
       HugeTreeRemoveNthChild(i)
   next i

   This could very easily croak, as in the case above.
   EC Code will catch the second removal, saying that such
   a child doesn't exist.

   Instead, count from 0 to n-1 OR recompute n after each removal:

      while ((n = HugeTreeGetNumChildren) != 0) {
          HugeTreeRemoveNthChild(n-1)
      }

*/

/* Header for each node */

typedef struct {
    Node parent;
    int childSlots;
    int numChildren;
    int dataSize;
} FixedNodeData;


/* EXPORTED HIGH-LEVEL ROUTINES */


/*********************************************************************
 *			HugeTreeCreate
 *********************************************************************
 * SYNOPSIS:	Initialize a tree heap.
 *              All nodes are unique and are accessible
 *              only within this heap.
 * CALLED BY:	
 * RETURN:      VMBlockHandle to tree heap
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

VMBlockHandle HugeTreeCreate(VMFileHandle vmFile);


/*********************************************************************
 *			HugeTreeDestroy
 *********************************************************************
 * SYNOPSIS:	Destroy a HugeTree heap. The only current way to recover
 *              any space used by a HugeTree heap
 * CALLED BY:	
 * RETURN:      void
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

void HugeTreeDestroy(VMFileHandle vmFile, VMBlockHandle tree);


/* The three routines which can be used to add a node as a child of a
   given node are HugeTreeAddAfterNthChild, HugeTreeAppend, and
   HugeTreeSetChild.

   All consistently let the client either add a preallocated node
   or have the routine create a new one.

   To use a preallocated node:

       The parameter SizeOrSPECIAL should be USE_PREALLOCATED_NODE
       The parameter childSlotsOrNodeToInsert should be the Node to add.

   
   To create one on the fly:

       The parameter SizeOrSpecial should be the size of data
       for the new node.

       childSlotsOrNodeToInsert is the initial number of children
       to allocate space for. The system automatically
       expands the number of available children as needed.
       No contraction, though...

 */

/*********************************************************************
 *			HugeTreeAddAfterNthChild
 *********************************************************************
 * SYNOPSIS:	Inserts a new child after the nth child
 *              of the current node, which must exist
 * CALLED BY:	
 * RETURN:      Inserted node
 * SIDE EFFECTS:
 * STRATEGY:        See comments before this declaration
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/
       
Node HugeTreeAddAfterNthChild(VMFileHandle vmFile,
				VMBlockHandle treeHandle,
				Node node, int n, int SizeOrSPECIAL,
				word childSlotsOrNodeToInsert);


/*********************************************************************
 *			HugeTreeAppendChild
 *********************************************************************
 * SYNOPSIS:	Append a child to the current node,
 *              either by linking in an already allocated node
 *              or by allocating it ourselves...
 *              
 * CALLED BY:	
 * RETURN:        The appended node
 * SIDE EFFECTS:
 * STRATEGY:      See comments before HugeTreeAddAfterNthChild
 *                for an explanation of arguments
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

Node HugeTreeAppendChild(VMFileHandle vmFile,
			VMBlockHandle treeHandle,
			Node node, int SizeOrSPECIAL, 
			word childSlotsOrNodeToInsert);

/*********************************************************************
 *			HugeTreeSetNthChild
 *********************************************************************
 * SYNOPSIS:	Similar to insertion but simply detaches
 *              the child that used to be there..
 *              Note that its storage does NOT get freed at all
 *              right now until the entire tree gets demolished.
 *
 *              Pitfall:  If you set the nth child to be NullNode,
 *              and nodes 0 thru n-1 were already NullNode,
 *              then numChildren will be set to 0 by its definition
 *              in tree.h.
 *   
 *              So be careful if you try something like
 *              n = HugeTreeGetNumchildren
 *              for i = n-1 to 0 
 *                   HugeTreeSetNthChild(i,NullNode)
 *              next i
 *      
 *              This will choke in a major way if you have a mix
 *              of NullNodes in there already.
 *
 *              Alternatives:
 *              Loop for 0 to n-1 OR recompute n after each Set.
 *
 * CALLED BY:	
 * RETURN:      ID of new node
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/


Node HugeTreeSetNthChild(VMFileHandle vmFile,
			 VMBlockHandle treeHandle,
			 Node node, int n, int SizeOrSPECIAL,
			 word childSlotsOrNodeToInsert);

						     
/* Remove nth child slot from node; child slots after n will be
 * shuffled down.  If the end slot is removed, any trailing empty
 * slots will be removed as well.
 */
void HugeTreeRemoveNthChild(VMFileHandle vmFile,
			    VMBlockHandle treeHandle,
			    Node node, int n);

		  
/*********************************************************************
 *			HugeTreeAllocNode
 *********************************************************************
 * SYNOPSIS:	Allocates a new node in a given tree heap.
 *              This node will be UNLINKED.  You must use
 *              the insertion/set/append routines to actually
 *              link this puppy in.
 *
 *              size is the size of the opaque data you wish
 *              to store in the node (i.e. use 0 for an empty node)
 *
 *              childSlots is the initial number of available children
 *              to allocate storage for. Eventually this will change
 *              on the fly as needed, but currently this must be made
 *              as large as you'll ever need
 *
 *              Returns NullNode if can't allocate...
 *
 * CALLED BY:	
 * RETURN:      Allocated Node or NullNode if no more room
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

Node HugeTreeAllocNode(VMFileHandle vmFile,
		      VMBlockHandle treeHandle,
		      int size, int childSlots);


/*********************************************************************
 *			HugeTreeGetNthChild
 *********************************************************************
 * SYNOPSIS:	Get the Nth child of a node.
 * 
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:     If this chokes, double check and make sure
 *               you aren't accessing an index > the number of 
 *               the node's children.
 *
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

Node HugeTreeGetNthChild(VMFileHandle vmFile,
			VMBlockHandle treeHandle, Node node, int n);


/*********************************************************************
 *			HugeTreeGetParent
 *********************************************************************
 * SYNOPSIS:	Get the parent of a given node if it exists
 * CALLED BY:	
 * RETURN:     Parent Node or NullNode
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

Node HugeTreeGetParent(VMFileHandle vmFile,
		      VMBlockHandle treeHandle,
		      Node node);


/*********************************************************************
 *			HugeTreeGetNumChildren
 *********************************************************************
 * SYNOPSIS:	Return the number of children of a given node
 *
 * CALLED BY:	
 * RETURN:       1 + the last 0-based Non-Null child index
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

int HugeTreeGetNumChildren(VMFileHandle vmFile,
			   VMBlockHandle treeHandle,
			   Node node);

/*********************************************************************
 *			HugeTreeGetNumSibling
 *********************************************************************
 * SYNOPSIS:	Returns the sibling number of a given node.
 *              If it's the 0th child of its parent, returns 0.
 *              second returns 1, etc....
 *              Returns NullNode if it has no parent or if it
 *              is the NullNode.
 * CALLED BY:  	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

int HugeTreeGetNumSibling(VMFileHandle vmFile,
			  VMBlockHandle treeHandle,
			  Node node);


/*********************************************************************
 *			HugeTreeGetDataSize
 *********************************************************************
 * SYNOPSIS:	Get the size of the opaque data within
 *              a node
 * CALLED BY:	
 * RETURN:      Size
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

int HugeTreeGetDataSize(VMFileHandle vmFile,
			VMBlockHandle treeHandle,
			Node node);


/*********************************************************************
 *			HugeTreeLock
 *********************************************************************
 * SYNOPSIS:	Locks and returns a pointer to a node's opaque
 *              data. Use this instead of HugeArrayLock when
 *              you want to access a node's data...
 *              Use HugeTreeDataSize to get the size of the data
 *              if you don't know it.  Returns NULL for NullNodes
 *            
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	11/30/94		Initial version			     
 * 
 *********************************************************************/

void *HugeTreeLock(VMFileHandle vmFile,
		   VMBlockHandle treeHandle,
		   Node node);


/**************************************************
 * NOTE: HugeTreeUnlock and HugeTreeDirty are also available
 *       as macros which translate directly into HugeArrayUnlock
 *       and HugeArrayDirty.  Use them exactly as you would
 *       for huge arrays, passing in the pointer of any element
 *       from that node to unlock or dirty that node
 **************************************************/

#endif /* _TREE_H_ */


