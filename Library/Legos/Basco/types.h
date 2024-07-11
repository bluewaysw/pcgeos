/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:        L E G O S
MODULE:		
FILE:		types.h

AUTHOR:		Roy Goldman, Apr 21, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 4/21/95	Initial version.

DESCRIPTION:
	
        Type checker.
	Must be called after variable analysis.  

	Returns false if there is a type incompatibility somewhere.

	Instruments the parse tree with type information
	which can be used at code generation time to generate
	fully correct and optimized instructions.

	
	$Id: types.h,v 1.1 98/10/13 21:43:49 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _TYPES_H_
#define _TYPES_H_

#include <tree.h>
#include "bascoint.h"
#include "mystdapp.h"

/* Low word is a LegosType
 * if lw is TYPE_STRUCT or TYPE_ARRAY, high word is extra type data
 * It's safe to pass this to a function wanting a LegosType.
 */
typedef dword ExtendedType;
/*#define MAKE_ET(_xtra, _type) ( ( ((dword) (_xtra)) << 16) | (_type) )*/
#define MAKE_ET(_a, _b) ConstructOptr(_a, _b)
#define ET_TYPE(_et) ( (word) (_et) )
#define ET_DATA(_et) ( (word) ((_et) >> 16) )

/* 1st: return true if _et is an array type
 * 2nd: return the type of the elements
 */
#define ET_ARRAY_TYPE(_et) (ET_TYPE(_et) & TYPE_ARRAY_FLAG)
#define ET_ARRAY_ELT_TYPE(_et) (ET_TYPE(_et) & ~TYPE_ARRAY_FLAG)

/* return true if _et is a specific component type
 */
#define SPEC_COMP_TYPE(_et) \
  (ET_TYPE(_et) == TYPE_COMPONENT && ET_DATA(_et) != (word)NullElement)

typedef enum {
    COMP_CHECK_ERROR,
    COMP_CHECK_DONE,
    COMP_CHECK_DO_SPECIFIC_CHECK
} CompCheckType;

/* - Exported routines
 */
Boolean		TypeCheckFunction(TaskPtr task, word funcNumber);
ExtendedType	TypeOfNthChild(TaskPtr task, Node node, word childNum);

#endif /* _TYPES_H_ */

