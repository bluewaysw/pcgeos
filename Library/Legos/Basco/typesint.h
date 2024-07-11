/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	L E G O S
MODULE:		Basco
FILE:		typesint.h

AUTHOR:		Roy Goldman, Apr 21, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 4/21/95	Initial version.

DESCRIPTION:
	
        Internal functions used during type checking...

	$Id: typesint.h,v 1.1 98/10/13 21:43:51 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _TYPESINT_H_
#define _TYPESINT_H_

#include <Legos/legtype.h>
#include <tree.h>
#include "bascoint.h"
#include "btoken.h"
#include "types.h"

/* Check types */
Boolean isNumber(LegosType t);
Boolean isInteger(LegosType t);
Boolean isNumericConstant(TokenCode c);
Token EvalConstantExpression(TaskPtr task, Node node, TokenCode code);

/* Give two test types t1 & t2, and a type key, return TRUE iff
   t1, t2 are some combination of the UNKNOWN type and specified key
   type.*/

Boolean SafeForUnknown(LegosType t1, LegosType t2, LegosType key);


/* Similar to above but for numbers or integers instead of the
   specific key type.
*/

Boolean SafeForUnknownAndInteger(LegosType t1, LegosType t2);
Boolean SafeForUnknownAndNumber(LegosType t1, LegosType t2);


/* Insert a parse tree node to coerce the specified child into
   finalType */

void CoerceNthChild(TaskPtr task, Node node, word childNum, LegosType finalType);

/* For arithmetic between two number types, get the result type */

LegosType ArithResultType(LegosType t1, LegosType t2);

/* - Internal routines
 */
#define Type_CHECK_NTH(_node, _childNum) \
 Type_Check(task, CurTree_GET_NTH(_node, _childNum))

ExtendedType	Type_Check(TaskPtr task, Node node);
Boolean		Type_CheckChildren(TaskPtr task, Node parent, byte initial);
ExtendedType	Type_CheckRoutineCall(TaskPtr task, Node node);
Boolean		Type_CoerceNth(TaskPtr task, Node node, word childNum,
			       LegosType finalType, LegosType origType);
Boolean		Type_IsValidStruct(TaskPtr task, word structName);
ExtendedType	Type_ResolvePropOrAction(TaskPtr task, Node node, optr comp,
					 TokenCode code, word *numParams);

#endif /* _TYPESINT_H_ */
