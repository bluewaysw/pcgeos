/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           codegen.h

AUTHOR:         Roy Goldman, Dec 13, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy	12/13/94	Initial version.

DESCRIPTION:
	declarations, constants, structures for code generation.

	$Id: codegen.h,v 1.1 98/10/13 21:42:32 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _CODEGEN_H_
#define _CODEGEN_H_

#include "bascoint.h"

extern Boolean CodeGenAddFunction(TaskPtr task, int funcNumber);
extern void CodeGenCheckIntegrity(TaskPtr task);
#define LabelCreateConstantRefIfNeeded(value) if((value) != (word)NullElement) LabelCreateGlobalFixup(task, (value), GRT_CONSTANT)

#endif /* _CODEGEN_H_ */
