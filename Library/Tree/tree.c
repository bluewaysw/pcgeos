/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           tree.c

AUTHOR:         Roy Goldman, Nov 30, 1994

ROUTINES:
	Name                    Description
	----                    -----------

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy     11/30/94        Initial version.

DESCRIPTION:
	Code for HugeTrees

	$Id: tree.c,v 1.2 98/05/28 16:00:39 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <tree.h>
#include "treeint.h"
#include <library.h>
#include <Ansi/string.h>
#include "errors.h"

#define FAILED_ASSERT -1

/*********************************************************************
 *                      HugeTreeCreate
 *********************************************************************
 * SYNOPSIS:    Initialize a tree heap.
 *              All nodes are unique and are accessible
 *              only within this heap.
 * CALLED BY:   
 * RETURN:      VMBlockHandle to tree heap
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/

VMBlockHandle HugeTreeCreate(VMFileHandle vmFile) {
    return HugeArrayCreate(vmFile, 0, 0);
}


/*********************************************************************
 *                      HugeTreeAllocNode
 *********************************************************************
 * SYNOPSIS:    Allocates a new node in a given tree heap.
 *              This node will be UNLINKED.  You must use
 *              the insertion/set/append routines to actually
 *              link this puppy in.
 *
 *              Returns NullNode if can't allocate...
 *
 * CALLED BY:   
 * RETURN:      Allocated Node or NullNode if no more room
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/

Node HugeTreeAllocNode(VMFileHandle vmFile,
		      VMBlockHandle treeHandle,
		      int size, int childSlots) { 
    
    word count, dummy;
    FixedNodeData *d;

    int i;
    Node *childPtr;

#if ERROR_CHECK
    if (size < 0 || childSlots < 0)
	EC_ERROR(ILLEGAL_PARAMETERS);
#endif

    count = HugeArrayGetCount(vmFile, treeHandle);


    if (count == MAX_NUMBER_NODES)
	return NullNode;

    HugeArrayAppend(vmFile, treeHandle, 
		    sizeof(FixedNodeData) + size + 
		    (childSlots * sizeof(int)), NULL);

    HugeArrayLock(vmFile, treeHandle, count, (void**)&d, &dummy);

    d->parent      = NullNode;
    d->childSlots  = childSlots;
    d->numChildren = 0;
    d->dataSize    = size;

    childPtr = FindChildrenOffset(d);

    /* Clear all child pointers to make data structure integrity
       checking more useful */

    for (i = 0; i < childSlots; i++) {
	*childPtr = NullNode;
	childPtr++;
    }
    
    EC_ERROR_IF((byte *)childPtr - (byte *)d > sizeof(FixedNodeData)+size+childSlots * sizeof(int), FAILED_ASSERT);

    HugeArrayDirty(d);
    HugeArrayUnlock(d);

    return count;

}
/* The three routines which can be used to add a node as a child of
   a given node
   are HugeTreeAddAfterNthChild, HugeTreeAppend, and HugeTreeSetChild.

   All consistently let the client either add a preallocated node
   or have the routine create a new one.

   To use a preallocated node:

       The parameter SizeOrSPECIAL should be USE_PREALLOCATED_NODE
       The parameter childSlotsOrNodeToInsert should be the Node to add.

   
   To create one on the fly:

       The parameter SizeOrSpecial should be the size of data
       for the new node.

       childSlotsOrNodeToInsert is the initial number of children
       to allocate space for.
*/


/*********************************************************************
 *                      HugeTreeAppendChild
 *********************************************************************
 * SYNOPSIS:    Append a child to the current node,
 *              either by linking in an already allocated node
 *              or by allocating it ourselves...
 *              
 * CALLED BY:   
 * RETURN:        The appended node
 * SIDE EFFECTS:
 * STRATEGY:      See comments before HugeTreeAppendChild
 *                for an explanation of arguments
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
Node HugeTreeAppendChild(VMFileHandle vmFile,
			VMBlockHandle treeHandle,
			Node node, int sizeOrSPECIAL,
			word childSlotsOrNodeToInsert) {

    FixedNodeData *d;
    Node newNode;
    Node *childPtr;
    Node *p;
    word    size;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (node == NullNode)
	EC_ERROR(NULL_NODE);
#endif

    newNode = GiveMeThatNode(vmFile, treeHandle,
			     sizeOrSPECIAL, childSlotsOrNodeToInsert);


    /* If we are trying to add a NullNode, just ignore it */

    if (newNode == NullNode)
	return NullNode;

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &size);
    
    if (d->numChildren >= d->childSlots) {
	d = ResizeAndRelock(vmFile, treeHandle, node, d);
    }

    childPtr = FindChildrenOffset(d);
    EC_ERROR_IF((byte *)(childPtr + d->numChildren) - (byte *)d > size, FAILED_ASSERT); 
    childPtr[d->numChildren] = newNode;
    d->numChildren++;

    HugeArrayDirty(d);
    HugeArrayUnlock(d);

    HugeArrayLock(vmFile, treeHandle, newNode, (void**)&d, &size);
    d->parent = node;

    HugeArrayDirty(d);
    HugeArrayUnlock(d);

    
#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    CheckNode(vmFile, treeHandle, newNode);
#endif

    return newNode;

}

/*********************************************************************
 *                      HugeTreeAddAfterNthChild
 *********************************************************************
 * SYNOPSIS:    Inserts a new child after the nth child
 *              of the current node, which must exist
 * CALLED BY:   
 * RETURN:      Inserted node
 * SIDE EFFECTS:
 * STRATEGY:        See comments before HugeTreeAppendChild
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
Node HugeTreeAddAfterNthChild(VMFileHandle vmFile,
			     VMBlockHandle treeHandle,
			     Node node, int n, int sizeOrSPECIAL,
			     word childSlotsOrNodeToInsert) {


    FixedNodeData *d;
    Node newNode;
    Node *childPtr;
    int i;
    word size;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (node == NullNode)
	EC_ERROR(NULL_NODE);
#endif

    newNode = GiveMeThatNode(vmFile,treeHandle,
			     sizeOrSPECIAL,
			     childSlotsOrNodeToInsert);

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &size);

#if ERROR_CHECK

    if (d->numChildren == 0 || n < 0 || n >= d->numChildren )
	EC_ERROR(BAD_CHILD_SPECIFIER);
#endif

	
    if (d->numChildren >= d->childSlots) {
	d = ResizeAndRelock(vmFile, treeHandle, node, d);
    }


    /* Don't bother appending NullNode, and it doesn't
       affect numChildren */

    if (n == d->numChildren - 1 && newNode == NullNode) {
	return NullNode;
    }

    /* Now shift everything over one and make room 
       Note that this is a narley performance hit
       when inserting near the beginning of a node
       with many children */
    
    childPtr = FindChildrenOffset(d);
    
    for (i = d->numChildren-1; i > n; i--) 
    {
	childPtr[i+1] = childPtr[i];
    }

    childPtr[n+1] = newNode;
    EC_ERROR_IF((byte *)(childPtr + n + 1) - (byte *)d > size, FAILED_ASSERT); 
    d->numChildren++;
    HugeArrayDirty(d);
    HugeArrayUnlock(d);

    if (newNode != NullNode) {
	HugeArrayLock(vmFile, treeHandle, newNode, (void**)&d, &size);
	d->parent = node;
	HugeArrayDirty(d);
	HugeArrayUnlock(d);
    }

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    CheckNode(vmFile, treeHandle, newNode);
#endif

    return newNode;

}
    
/*********************************************************************
 *                      HugeTreeSetNthChild
 *********************************************************************
 * SYNOPSIS:    Similar to insertion but simply detaches
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
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/

Node HugeTreeSetNthChild(VMFileHandle vmFile,
			    VMBlockHandle treeHandle,
			    Node node, int n, int sizeOrSPECIAL,
			    word childSlotsOrNodeToInsert) 
{
    FixedNodeData *d;
    Node newNode;
    Node *childPtr;
    word    size;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (node == NullNode || n < 0)
	EC_ERROR(NULL_NODE);
#endif

    newNode = GiveMeThatNode(vmFile,treeHandle,
			     sizeOrSPECIAL,
			     childSlotsOrNodeToInsert);


    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &size);

    while (n >= d->childSlots) {
	d = ResizeAndRelock(vmFile, treeHandle, node, d);
    }
    
#if ERROR_CHECK
    if (n >= d->childSlots) {
	EC_ERROR(CHILDREN_MESSED_UP);
    }
#endif

    
    childPtr = FindChildrenOffset(d);

    EC_ERROR_IF((byte *)(childPtr + n) - (byte *)d > size, FAILED_ASSERT);
    childPtr[n] = newNode;

    /* If we're setting the last child to be Null, we no longer
       know how many children we have.... Rescan to find out...
     */

    if (newNode == NullNode && n+1 >= d->numChildren) {
	RecountChildren(d);
    } else if (n+1 > d->numChildren) {
	d->numChildren = n + 1;
    }

    HugeArrayDirty(d);
    HugeArrayUnlock(d);

    if (newNode != NullNode) {
	HugeArrayLock(vmFile, treeHandle, newNode, (void**)&d, &size);
	d->parent = node;

	HugeArrayDirty(d);
	HugeArrayUnlock(d);
    }

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    CheckNode(vmFile, treeHandle, newNode);
#endif

    return newNode;

}
						     
/*********************************************************************
 *                      HugeTreeRemoveNthChild
 *********************************************************************
 * SYNOPSIS:    Remove the nth child from the tree
 *              It can then be linked in somewhere else
 *              if needed.
 * 
 *              It currently can NOT be freed entirely
 *              until you free the entire tree.
 * 
 *              Same warning here as in HugeTreeSetNthChild
 *              when removing the last element..
 * CALLED BY:   
 * RETURN:      void
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
void HugeTreeRemoveNthChild(VMFileHandle vmFile,
			    VMBlockHandle treeHandle,
			    Node node, int n) {

    FixedNodeData *d;
    Node *childPtr;
    int i;
    word    size;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (node == NullNode)
	EC_ERROR(NULL_NODE);
#endif

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &size);

#if ERROR_CHECK
    if (d->numChildren == 0 || n < 0 || n >= d->numChildren)
	EC_ERROR(BAD_CHILD_SPECIFIER);
#endif

    /* Just contract the array and elmininate the specified one */
    
    childPtr = FindChildrenOffset(d);
    
    if (d->numChildren == 1) {
	childPtr[0] = NullNode;
	d->numChildren = 0;
    }
    else {
		
	EC_ERROR_IF((byte *)(childPtr + d->numChildren) - (byte *)d > size, FAILED_ASSERT);
	for (i = n; i < d->numChildren - 1; i++) {
	    
	    childPtr[i] = childPtr[i+1];
	    
	}
	childPtr[d->numChildren - 1] = NullNode;

	if (n == d->numChildren - 1)
	    RecountChildren(d);
	else {
	    d->numChildren--;
	}
    }
    
    HugeArrayDirty(d);
    HugeArrayUnlock(d);

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
#endif

}



/*********************************************************************
 *                      HugeTreeDestroy
 *********************************************************************
 * SYNOPSIS:    Destroy a HugeTree heap
 * CALLED BY:   
 * RETURN:      void
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
void HugeTreeDestroy(VMFileHandle vmFile, VMBlockHandle treeHandle) {
    HugeArrayDestroy(vmFile, treeHandle);
}


/*********************************************************************
 *                      HugeTreeGetParent
 *********************************************************************
 * SYNOPSIS:    Get the parent of a given node if it exists
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/

Node HugeTreeGetParent(VMFileHandle vmFile,
		      VMBlockHandle treeHandle,
		      Node node) {

    FixedNodeData *d;
    Node parent;
    word    dummy;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
#endif

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &dummy);
    parent = d->parent;

    HugeArrayUnlock(d);

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, parent);
#endif

    return parent;
}

/*********************************************************************
 *                      HugeTreeGetNumChildren
 *********************************************************************
 * SYNOPSIS:    Return the number of children of a given node
 *
 * CALLED BY:   
 * RETURN:       1 + the last 0-based Non-Null child index
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/

int HugeTreeGetNumChildren(VMFileHandle vmFile,
			   VMBlockHandle treeHandle,
			   Node node) {
    
    FixedNodeData *d;
    int count;
    word    dummy;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (node == NullNode)
	EC_ERROR(NULL_NODE);
#endif

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &dummy);
    count = d->numChildren;
    HugeArrayUnlock(d);

    return count;
}
	
/*********************************************************************
 *                      HugeTreeGetNthChild
 *********************************************************************
 * SYNOPSIS:    Get the Nth child of a node.
 * 
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:     If this chokes, double check and make sure
 *               you aren't accessing an index > the number of 
 *               the node's children.
 *
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
Node HugeTreeGetNthChild(VMFileHandle vmFile,
			VMBlockHandle treeHandle,
			Node node,
			int n) {

    FixedNodeData *d;
    Node *childPtr;
    Node value;
    word    size;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (node == NullNode)
	EC_ERROR(NULL_NODE);
#endif

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &size);

    /* Find where the children are */
    
    childPtr = FindChildrenOffset(d);

#if ERROR_CHECK
    if (d->numChildren == 0 || n >= d->numChildren || n < 0) {
	HugeArrayUnlock(d);
	EC_ERROR(BAD_CHILD_SPECIFIER);
    }
#endif
    EC_ERROR_IF((byte *)(childPtr + n) -(byte *)d  > size, FAILED_ASSERT);

    value = childPtr[n];

    HugeArrayUnlock(d);

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, value);
#endif
    return value;
}


/*********************************************************************
 *                      HugeTreeGetNumSibling
 *********************************************************************
 * SYNOPSIS:    Returns the sibling number of a given node.
 *              If it's the 0th child of its parent, returns 0.
 *              second returns 1, etc....
 *              Returns NullNode if it has no parent or if it
 *              is the NullNode.
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
int HugeTreeGetNumSibling(VMFileHandle vmFile,
			  VMBlockHandle treeHandle,
			  Node node) {
    
    FixedNodeData *d;
    Node *childPtr;
    Node parent;
    int count = 0;
    byte found = 0;
    int i;
    word    dummy;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
#endif

    if (node == NullNode)
	return node;

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &dummy);
    parent = d->parent;
    HugeArrayUnlock(d);

    if (parent == NullNode )
	return parent;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, parent);
#endif

    HugeArrayLock(vmFile, treeHandle, parent, (void**)&d, &dummy);

#if ERROR_CHECK
    if (d->numChildren == 0)
	EC_ERROR(CHILDREN_MESSED_UP);
#endif

    childPtr = FindChildrenOffset(d);

    for ( i = 0; i < d->numChildren; i++) {
	if (*childPtr == node) {
	    found = 1;
	    break;
	}

#if ERROR_CHECK
	CheckNode(vmFile, treeHandle, *childPtr);
#endif
	count++;
	childPtr++;
    }

#if ERROR_CHECK
    /* This is a major problem! */
    
    if (!found)
	EC_ERROR(CHILDREN_MESSED_UP);
#endif

    HugeArrayUnlock(d);

    return count;
}

/*********************************************************************
 *                      HugeTreeGetDataSize
 *********************************************************************
 * SYNOPSIS:    Get the size of the opaque data within
 *              a node
 * CALLED BY:   
 * RETURN:      Size
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
int HugeTreeGetDataSize(VMFileHandle vmFile,
			VMBlockHandle treeHandle,
			Node node) {
    FixedNodeData *d;
    int size;
    word    dummy;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
#endif

    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &dummy);

    size = d->dataSize;

    HugeArrayUnlock(d);

    return size;
}


/*********************************************************************
 *                      HugeTreeLock
 *********************************************************************
 * SYNOPSIS:    Locks and returns a pointer to a node's opaque
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
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
void *HugeTreeLock(VMFileHandle vmFile,
		   VMBlockHandle treeHandle,
		   Node node) {

    FixedNodeData *d;
    word        dummy;

    if (node == NullNode)
	return NULL;

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, node);
    if (!HugeArrayLock(vmFile, treeHandle, node, &(void*)d, &dummy))
    {
	EC_ERROR(FAILED_ASSERT);
    }
#else
    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &dummy);
#endif


    return FindDataOffset(d);
}


/******************************************************************
 * INTERNAL FUNCTIONS!
 ******************************************************************/

#if ERROR_CHECK
/*********************************************************************
 *                      CheckNode
 *********************************************************************
 * SYNOPSIS:    Internal EC: Pound on the integrity of a node and Barf
 *                  semi-digested Hong Fu Spicy chicken if there's
 *                  a problem.
 * CALLED BY:   All functions.
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
void CheckNode(VMFileHandle vmFile,
	       VMBlockHandle treeHandle,
	       Node node) {

    FixedNodeData *d;
    int i;
    Node *childPtr;
    word c, dummy;
    ErrorCheckingFlags  ecflags;

    /* NullNode is ok */

    ecflags = SysGetECLevel(&dummy);
    if (! (ecflags & ECF_NORMAL)) {
	return;
    }

    if (node == NullNode)
	return;

    /* First check that the node number isn't bigger than the number
       of nodes */

    c = HugeArrayGetCount(vmFile,treeHandle);

    if (node >= c)
	EC_ERROR(ILLEGAL_INDEX);

    HugeArrayLock(vmFile, treeHandle, node, &(void*)d, &dummy);

    /* Having more children than we possibly could
       have gets my stomach rumbling */

    if (d->numChildren > d->childSlots)
	EC_ERROR(CHILDREN_MESSED_UP);

    /* If we are our parent, die! */

    if (d->parent == node)
	EC_ERROR(CIRCULAR_DEPENDENCY);

    if (d->numChildren < 0 || d->dataSize < 0 || d->childSlots < 0)
	EC_ERROR(CIRCULAR_DEPENDENCY);

    /* Now examine the children structure:
       For safety all code makes sure that childSlots
       are initialized to NullNode.  

    */

    /* only check for children related problems if the node has child slots */
    if (d->childSlots > 0) 
    {
	childPtr = FindChildrenOffset(d);


	for (i = 0; i < d->numChildren; i++) {
	
	    if (*childPtr == node || 
		(*childPtr >= c && *childPtr != NullNode) )
	    {
		EC_ERROR(CHILDREN_MESSED_UP);
	    }
	
	    childPtr++;
	}

	/* Make sure last child (if one exists) isn't NullNode
	 */
	if (d->numChildren && (*(childPtr-1) == NullNode))
	{
	    EC_ERROR(CHILDREN_MESSED_UP);
	}

	/* Now examine the dead space between the last child
	   and the last possible child; should be all NullNodes */

	for (i = d->numChildren; i < d->childSlots; i++) {
	    if (*childPtr != NullNode) {
		EC_ERROR(CHILDREN_MESSED_UP);
	    }

	    childPtr++;
	}
    }

    /* Other potential checks for later on........
       Child points to self?
       Repeats in children?
     */

    HugeArrayUnlock(d);
}
#endif

/*********************************************************************
 *                      RecountChildren
 *********************************************************************
 * SYNOPSIS:    After someone deletes or sets-to-Null the last child
 *              our definition of number of children is in limbo.
 *     
 *              We must start over and count to see how many kids we have.
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     12/ 3/94                Initial version                      
 * 
 *********************************************************************/

void RecountChildren(FixedNodeData *d) {
    int i;
    Node *childPtr;

    childPtr = FindChildrenOffset(d);
 
    /* Start at the end and hunt for a non-null node. Add 1
       to get our number of children
       */

    if (d->numChildren == 0)
	return;

    for (i = d->numChildren - 1; i >= 0; i--) {
	if (childPtr[i] != NullNode) {
	    d->numChildren = i+1;
	    return;
	}
    }

    d->numChildren = 0;
}

    

/*********************************************************************
 *                      FindChildrenOffset
 *********************************************************************
 * SYNOPSIS:    INTERNAL!: Takes a pointer to FixedNodeData and returns
 *              a pointer to the first child.
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:    Be careful, because we assume that certain
 *              data exists after the FixedNodeData info...
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
Node *FindChildrenOffset(FixedNodeData *d) {

    byte *t;

    t = ((byte*)d) + sizeof(FixedNodeData) + d->dataSize;
    return (word*) t;

}

/*********************************************************************
 *                      FindDataOffset
 *********************************************************************
 * SYNOPSIS:    Internal!  Returns the offset to the node's data
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
void *FindDataOffset(FixedNodeData *d) {
    byte *t;
    t = ((byte*) d) + sizeof(FixedNodeData);
    return (void*) t;
}

			
/*********************************************************************
 *                      GiveMeThatNode
 *********************************************************************
 * SYNOPSIS:    Internal! Take tree insertion/append/replace parameters
 *              and either return the specified node or allocate
 *              a new one and return that.
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
Node GiveMeThatNode(VMFileHandle vmFile,
		   VMBlockHandle treeHandle,
		   int sizeOrSPECIAL,
		   word childSlotsOrNodeToInsert) {
    
    Node newNode;
    int size;
    int childSlots;

    if (sizeOrSPECIAL != USE_PREALLOCATED_NODE) {
	size = sizeOrSPECIAL;
	childSlots = (int) childSlotsOrNodeToInsert;
	
	newNode =  
	    HugeTreeAllocNode(vmFile,treeHandle,size,childSlots);

    }
    else {
	newNode = (Node) childSlotsOrNodeToInsert;
    }

#if ERROR_CHECK
    CheckNode(vmFile, treeHandle, newNode);
#endif

    return newNode;
}

/*********************************************************************
 *                      ResizeAndRelock
 *********************************************************************
 * SYNOPSIS:    Take a node and a locked reference to it,
 *              expand the number of children available,
 *              re-insert it into the huge array, relock it,
 *              and return a pointer.
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     12/ 9/94                Initial version                      
 * 
 *********************************************************************/
FixedNodeData *ResizeAndRelock(VMFileHandle vmFile,
			       VMBlockHandle treeHandle,
			       Node node,
			       FixedNodeData *d) {

    MemHandle tempHandle;
    FixedNodeData *tempPtr;
    Node *p;

    word    dummy;
    int oldsize, newsize;

#if ERROR_CHECK
    if (d->childSlots == 28000)
	EC_ERROR(TOO_MANY_CHILD_SLOTS);

    if ( (unsigned) ((2 * d->childSlots) + d->dataSize) > 3000)
	EC_WARNING(WARN_NODE_LARGER_THAN_6K);
#endif

    oldsize = sizeof(FixedNodeData) + d->dataSize +
	(d->childSlots * sizeof(int));

    if (d->childSlots == 0) {
	d->childSlots = 1;
    } else {
	d->childSlots = 2 * d->childSlots;
    }
    
    if ((unsigned) d->childSlots > 28000)
    {
	d->childSlots = 28000;
    }

    newsize = sizeof(FixedNodeData) + d->dataSize +
	      (d->childSlots * sizeof(int));

    tempHandle = MemAlloc(newsize, HF_SWAPABLE, HAF_LOCK);
    
    tempPtr = MemLock(tempHandle);

    EC_ERROR_IF(newsize < oldsize, FAILED_ASSERT);
    memcpy(tempPtr, d, oldsize);

    HugeArrayUnlock(d);

    for (p = (Node*)( ((byte*) tempPtr) + oldsize);
	 p < (Node*)( ((byte*) tempPtr) + newsize);
	 p++)
    {
	*p = NullNode;
    }
    
    HugeArrayReplace(vmFile, treeHandle, newsize, node, tempPtr);

    MemFree(tempHandle);

#if ERROR_CHECK
    CheckNode(vmFile,treeHandle, node);
    if (!HugeArrayLock(vmFile, treeHandle, node, &(void*)d, &dummy))
    {
	EC_ERROR(FAILED_ASSERT);
    }
#else
    HugeArrayLock(vmFile, treeHandle, node, (void**)&d, &dummy);
#endif
    
    return d;
}

/*********************************************************************
 *                      TreeLibraryEntry
 *********************************************************************
 * SYNOPSIS:    Entry. Do nothing
 * CALLED BY:   
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *      Name    Date            Description                          
 *      ----    ----            -----------                          
 *      roy     11/30/94                Initial version                      
 * 
 *********************************************************************/
#pragma argsused
extern _pascal Boolean TreeLibraryEntry(LibraryCallType type,
					GeodeHandle client) {

    /* Just crap to get these into the symbol file */
    FatalErrors shme;
    Warnings gribble;

    shme = NULL_NODE;
    gribble = WARN_NODE_LARGER_THAN_6K;
    return 0;
}

