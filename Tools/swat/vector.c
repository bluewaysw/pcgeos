/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Vector Manipulation.
 * FILE:	  vector.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Vector_Create	    Create a vector.
 *	Vector_Empty	    Remove all elements from a vector, but keep the
 *	    	    	    thing itself around.
 *	Vector_Destroy	    Free all elements and the vector itself.
 *	Vector_Data 	    Return array of all elements in the vector.
 *	Vector_Size 	    Return number of elements that can fit in the
 *	    	    	    vector.
 *	Vector_Length	    Return the number of elements currently in a vector
 *	Vector_Add  	    Add an element to a vector at a position.
 *	Vector_Insert	    Insert an element into a vector before a position.
 *	Vector_Get  	    Fetch an element of a vector into a buffer.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	The functions in this file implement a data-vector abstraction
 *	that is used in numerous places throughout swat. A data-vector
 *	is simply an array of data that is automatically extended as
 *	needed, but extended in a sensible way to avoid too much copying.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vector.c,v 4.3 96/06/13 17:24:23 dbaumann Exp $";
#endif lint

#include <config.h>
#include "swat.h"
#include "vector.h"

typedef struct {
    void  	  	*data;	    /* The actual data */
    int		  	num;	    /* Current number of elements (vector
				     * length) */
    int		  	max;	    /* Current maximum number (vector size) */
    int		  	size;	    /* Size of each element */
    Vector_Adjust 	adj;	    /* Type of adjustment needed for overflow */
    int			adjSize;    /* Size of adjustment to make */
} VectorRec, *VectorPtr;

#define DEFAULT_INITIAL_SIZE	10

/*-
 *-----------------------------------------------------------------------
 * Vector_Create --
 *	Create and initialize a vector with the appropriate values.
 *
 * Results:
 *	The newly-created vector.
 *
 * Side Effects:
 *	Memory is allocated.
 *
 *-----------------------------------------------------------------------
 */
Vector
Vector_Create(int	    dataSize,	    /* Size of each element */
	      Vector_Adjust adjustType,	    /* Way to expand when overflows */
	      int	    adjustSize,	    /* Size of adjustment to make */
	      int	    initialSize)    /* Initial size of vector */
{
    VectorPtr	  v;

    if (initialSize <= 0) {
	initialSize = DEFAULT_INITIAL_SIZE;
    }
    
    v = (VectorPtr)malloc_tagged(sizeof(VectorRec), TAG_VECTOR);
    v->data = (void *)malloc_tagged(initialSize * dataSize, TAG_VECTOR);
    v->num = 0;
    v->max = initialSize;
    v->size = dataSize;
    v->adj = adjustType;
    v->adjSize = adjustSize;

    return ((Vector)v);
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Empty --
 *	Empty out a vector.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The array of data is zero-filled and num set to 0.
 *
 *-----------------------------------------------------------------------
 */
void
Vector_Empty(Vector vector)
{
    register VectorPtr	v = (VectorPtr)vector;

    bzero(v->data, v->num * v->size);
    v->num = 0;
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Destroy --
 *	Free all the memory used by a vector.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The data are freed and the vector should never be used again.
 *
 *-----------------------------------------------------------------------
 */
void
Vector_Destroy(Vector	vector)
{
    register VectorPtr	v = (VectorPtr)vector;

    free((char *)v->data);
    free((char *)v);
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Data --
 *	Return a pointer to all the data in the vector. This pointer
 *	should be used only for short references and is not guaranteed to
 *	remain valid once the vector is changed in any way.
 *
 * Results:
 *	A pointer to the data.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
void *
Vector_Data(Vector  vector)
{
    return ((VectorPtr)vector)->data;
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Size --
 *	Return the absolute size of the vector. This is the number of
 *	bytes of data the vector can hold before it must be expanded.
 *
 * Results:
 *	The size of the vector.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Vector_Size(Vector  vector)
{
    return ((VectorPtr)vector)->max * ((VectorPtr)vector)->size;
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Length --
 *	Return the number of valid entries in the vector.
 *	Note that there may be zero-filled holes in the vector if allocation
 *	of entries is not sequential.
 *
 * Results:
 *	The number of entries in the vector.
 *
 * Side Effects:
 *	None.
 *
 *-----------------------------------------------------------------------
 */
int
Vector_Length(Vector	vector)
{
    return ((VectorPtr)vector)->num;
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Add --
 *	Add an element to a data vector at the given position. If the
 *	position is below 0, the next available slot is used.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	The element is copied into the vector.
 *
 *-----------------------------------------------------------------------
 */
void
Vector_Add(Vector   vector, /* Vector to change */
	   int	    offset, /* Place at which to store the data */
	   void     *data)   /* Pointer to data to store */
{
    register VectorPtr	v = (VectorPtr)vector;

    if (offset < 0) {
	offset = v->num;
    }
    if (offset >= v->max) {
	int oldMax = v->max;
	
	if (v->adj == ADJUST_MULTIPLY) {
	    do {
		v->max *= v->adjSize;
	    } while (offset >= v->max);
	} else {
	    do {
		v->max += v->adjSize;
	    } while (offset >= v->max);
	}
	v->data = (void *)realloc_tagged(v->data, v->max * v->size);
	if (v->data == (void *)NULL) {
	    Punt("Out of memory in Vector_Add");
	}
	bzero((genptr)v->data + (oldMax * v->size),
	      (v->max - oldMax) * v->size);
    }

    if (offset >= v->num) {
	bzero((genptr)v->data + (v->num * v->size),
	      (offset + 1 - v->num) * v->size);
	v->num = offset + 1;
    }
    bcopy(data, (genptr)v->data + offset * v->size, v->size);
}

/*-
 *-----------------------------------------------------------------------
 * Vector_Insert --
 *	Insert an element into a vector. The element takes the place
 *	of the one at 'offset'.
 *
 * Results:
 *	None.
 *
 * Side Effects:
 *	All elements at offset and above are shifted up one.
 *
 *-----------------------------------------------------------------------
 */
void
Vector_Insert(Vector	vector,
	      int	offset,
	      void 	*data)
{
    register VectorPtr	v = (VectorPtr)vector;

    if (v->num == v->max) {
	/*
	 * If we have to expand the vector to insert this element anyway,
	 * simply allocate a new data array straight out and copy the data
	 * over in two pieces, leaving room in the middle for the new element.
	 */
	void	  *newData;
	
	if (v->adj == ADJUST_MULTIPLY) {
	    v->max *= v->adjSize;
	} else {
	    v->max += v->adjSize;
	}

	newData = (void *)malloc_tagged(v->max * v->size, TAG_VECTOR);
	bcopy(v->data, newData, offset * v->size);
	bcopy((genptr)v->data + offset * v->size,
	      (genptr)v->data + (offset + 1) * v->size,
	      (v->num - offset) * v->size);
	free((char *)v->data);
	v->data = newData;
    } else {
	/*
	 * No need to expand the vector, just shift all the elements up one
	 * slot.
	 */
	bcopy((genptr)v->data + offset * v->size,
	      (genptr)v->data + (offset + 1) * v->size,
	      (v->num - offset) * v->size);
    }
    /*
     * Copy the new element in
     */
    bcopy(data, (genptr)v->data + offset * v->size, v->size);
    v->num += 1;
}
	
/*-
 *-----------------------------------------------------------------------
 * Vector_Get --
 *	Copy out an element of a data vector.
 *
 * Results:
 *	TRUE if the element exists and FALSE otherwise.
 *
 * Side Effects:
 *	If return TRUE, the element is copied into the passed buffer.
 *
 *-----------------------------------------------------------------------
 */
Boolean
Vector_Get(Vector   vector,
	   int	    offset,
	   void     *buf)
{
    register VectorPtr	v = (VectorPtr)vector;

    if ((offset >= v->num) || (offset < 0)) {
	return(FALSE);
    } else {
	bcopy((genptr)v->data + offset * v->size, buf, v->size);
	return(TRUE);
    }
}

    

