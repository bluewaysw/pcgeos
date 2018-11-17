/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Vector Maintenance
 * FILE:	  vector.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 12, 1991
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/12/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for vector maintenance.
 *
 *
 * 	$Id: vector.h,v 1.2 91/04/26 12:41:59 adam Exp $
 *
 ***********************************************************************/
#ifndef _VECTOR_H_
#define _VECTOR_H_

/******************************************************************************
 *
 *			  VECTOR DEFINITIONS
 *
 ******************************************************************************/
typedef void *	Vector;   	/* Basic type */
typedef void *	Address;

#define NullVector	((Vector)NULL)

typedef enum {
    ADJUST_MULTIPLY,	    	/* Expand by multiplying current max by the
				 * adjustment size */
    ADJUST_ADD,	  	    	/* Expand by adding the adjustment size to
				 * the current maximum */
}	    	  Vector_Adjust;

typedef struct {
    char *  	  	data;	    /* The actual data */
    int		  	num;	    /* Current number of elements (vector
				     * length) */
    int		  	max;	    /* Current maximum number (vector size) */
    int		  	size;	    /* Size of each element */
    Vector_Adjust 	adj;	    /* Type of adjustment needed for overflow*/
    int			adjSize;    /* Size of adjustment to make */
} VectorRec, *VectorPtr;

#define VECTOR_END  -1          /* Position to pass to Vector_Add to add an
                                 * element to the end of the vector */

extern Vector   Vector_Create (int dataSize, Vector_Adjust adjustType,
                               int adjustSize, int initialSize);
extern void     Vector_Empty (Vector vector);
extern void 	Vector_Truncate (Vector vector, int size);
extern void     Vector_Destroy (Vector vector);
extern Address  Vector_Data (Vector vector);
extern int      Vector_Size (Vector vector);
extern int      Vector_Length (Vector vector);
extern void     Vector_Add (Vector vector, int offset, Address data);
extern void     Vector_Insert (Vector vector, int offset, Address data);
extern Boolean  Vector_Get (Vector vector, int offset, Address buf);

#endif /* _VECTOR_H_ */
