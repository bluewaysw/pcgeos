/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Header file for users of data vectors.
 * FILE:	  vector.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Contains definitions of types, constants and functions used by
 *	the Vector module.
 *
* 	$Id: vector.h,v 4.1 92/07/26 16:49:48 adam Exp $
 *
 ***********************************************************************/
#ifndef _VECTOR_H
#define _VECTOR_H

typedef Opaque	  Vector;   	/* Basic type */

#define NullVector	((Vector)NULL)

typedef enum {
    ADJUST_MULTIPLY,	    	/* Expand by multiplying current max by the
				 * adjustment size */
    ADJUST_ADD,	  	    	/* Expand by adding the adjustment size to
				 * the current maximum */
}	    	  Vector_Adjust;

#define VECTOR_END  -1	    	/* Position to pass to Vector_Add to add an
				 * element to the end of the vector */

extern Vector 	Vector_Create (int dataSize, Vector_Adjust adjustType,
			       int adjustSize, int initialSize);
extern void 	Vector_Empty (Vector vector);
extern void 	Vector_Destroy (Vector vector);
extern void 	*Vector_Data (Vector vector);
extern int  	Vector_Size (Vector vector);
extern int  	Vector_Length (Vector vector);
extern void 	Vector_Add (Vector vector, int offset, void *data);
extern void 	Vector_Insert (Vector vector, int offset, void *data);
extern Boolean 	Vector_Get (Vector vector, int offset, void *buf);

#endif /* _VECTOR_H */
				
