/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		runmath.h

AUTHOR:		Jimmy Lefkowitz, Dec 30, 1994

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	12/30/94	Initial version.

DESCRIPTION:
	

        $Revision: 1.1 $
 
        Liberty version control
        $Id: runmath.h,v 1.1 98/10/05 12:35:22 martin Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _RUNMATH_H_
#define _RUNMATH_H_

#ifdef LIBERTY
#include "Legos/runint.h"
#else
#include "runint.h"
#endif

void
OpNegative(RMLPtr rms, RVal op1);

void
OpNot(RMLPtr rms, RVal op1);

void
OpMultiply(RMLPtr rms, RVal op1, RVal op2);

void
OpAdd(RMLPtr rms, RVal op1, RVal op2);

void
OpBitAnd(RMLPtr rms, RVal op1, RVal op2);

void
OpBitXor(RMLPtr rms, RVal op1, RVal op2);

void
OpBitOr(RMLPtr rms, RVal op1, RVal op2);

void
OpSubtract(RMLPtr rms, RVal op1, RVal op2);

void
OpDivide(RMLPtr rms, RVal op1, RVal op2);

void
OpMod(RMLPtr rms, RVal op1, RVal op2);

void
OpOr(RMLPtr rms, RVal op1, RVal op2);

void
OpAnd(RMLPtr rms, RVal op1, RVal op2);

void
OpXor(RMLPtr rms, RVal op1, RVal op2);

void
OpLessThan(RMLPtr rms, RVal op1, RVal op2);

void
OpGreaterThan(RMLPtr rms, RVal op1, RVal op2);

void
OpLessEqual(RMLPtr rms, RVal op1, RVal op2);

void
OpLessGreater(RMLPtr rms, RVal op1, RVal op2);

void
OpGreaterEqual(RMLPtr rms, RVal op1, RVal op2);

void
OpEquals(RMLPtr rms, RVal op1, RVal op2);

long
SmartTrunc(float f);

LegosType FindResultType(LegosType type1, LegosType type2);

#endif /* _RUNMATH_H_ */
