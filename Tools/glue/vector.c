/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Vector maintenance.
 * FILE:	  vector.c
 *
 * AUTHOR:  	  Adam de Boor: Mar 18, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/18/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Vector functions. Stolen from Swat...but without the memory
 * 	tracing stuff that's there.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: vector.c,v 1.4 92/10/27 20:52:10 adam Exp $";
#endif lint

#include    "glue.h"
#include    "vector.h"

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
    
    v = (VectorPtr)malloc(sizeof(VectorRec));
    v->data = (Address)malloc(initialSize * dataSize);
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
 * Vector_Truncate --
 *	Truncate a vector to a particular size.
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
Vector_Truncate(Vector 	vector,
		int 	size)
{
    register VectorPtr	v = (VectorPtr)vector;

    /*
     * Make sure the vector is at least that long.
     */
    if (v->num < size) {
	Address 	element;

	element = (Address)calloc(1, v->size);
	Vector_Add(vector, size-1, element);
	free(element);
    } else if (v->num > size) {
	/*
	 * Zero out the elements beyond what is now the end.
	 */
	bzero(v->data + (size * v->size), (v->num - size) * v->size);
    }

    /*
     * Truncate the vector at that size.
     */
    v->num = size;
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
Address
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
	   Address  data)   /* Pointer to data to store */
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
	v->data = (Address)realloc(v->data, v->max * v->size);
	if (v->data == (Address)NULL) {
	    printf("Out of memory in Vector_Add\n");
	    exit(1);
	}
	bzero(v->data + (oldMax * v->size),
	      (v->max - oldMax) * v->size);
    }

    if (offset >= v->num) {
	bzero(v->data + (v->num * v->size),
	      (offset + 1 - v->num) * v->size);
	v->num = offset + 1;
    }
    bcopy(data, v->data + offset * v->size, v->size);
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
	      Address	data)
{
    register VectorPtr	v = (VectorPtr)vector;

    if (offset >= v->num) {
	Vector_Add(vector, offset, data);
    } else {
	if (v->num == v->max) {
	    /*
	     * If we have to expand the vector to insert this element anyway,
	     * simply allocate a new data array straight out and copy the data
	     * over in two pieces, leaving room in the middle for the new element.
	     */
	    Address	  newData;
	    
	    if (v->adj == ADJUST_MULTIPLY) {
		v->max *= v->adjSize;
	    } else {
		v->max += v->adjSize;
	    }
	    
	    newData = (Address)malloc(v->max * v->size);
	    bcopy(v->data, newData, offset * v->size);
	    bcopy(v->data + offset * v->size,
		  (char *)newData + (offset + 1) * v->size,
		  (v->num - offset) * v->size);
	    free((char *)v->data);
	    v->data = newData;
	} else {
	    /*
	     * No need to expand the vector, just shift all the elements up one
	     * slot.
	     */
	    bcopy(v->data + offset * v->size,
		  v->data + (offset + 1) * v->size,
		  (v->num - offset) * v->size);
	}
	/*
	 * Copy the new element in
	 */
	bcopy(data, v->data + offset * v->size, v->size);
	v->num += 1;
    }
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
int
Vector_Get(Vector   vector,
	   int	    offset,
	   Address  buf)
{
    register VectorPtr	v = (VectorPtr)vector;

    if ((offset >= v->num) || (offset < 0)) {
	return(0);
    } else {
	bcopy(v->data + offset * v->size, buf, v->size);
	return(1);
    }
}

