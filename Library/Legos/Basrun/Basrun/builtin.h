/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		basrun
FILE:		builtin.h

AUTHOR:		Roy Goldman, Jul  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 9/95	Initial version.

DESCRIPTION:
	
        Built-in function table header info neede at runtime.
	Note that this is more lightweight than the crap
	needed at compile time...

	$Revision: 1.1 $

	Liberty version control
	$Id: builtin.h,v 1.1 98/10/05 12:34:57 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BUILTIN_H_
#define _BUILTIN_H_

typedef enum
{
#define BTABLE_ENUM
#ifdef LIBERTY
#include "Legos/btable.h"
#else
#include <Legos/Bridge/btable.h>
#endif
#undef BTABLE_ENUM
    NUM_BUILT_IN_FUNCTIONS
} BuiltInFuncEnum;

typedef void (BuiltInVector)(RMLPtr, BuiltInFuncEnum);

/* This table is defined in builtin.c
 */
#ifdef LIBERTY

const BuiltInVector *
GetBuiltInFunction(int funcNumber);

#else
typedef struct {
    BuiltInVector       *BIFE_vector;
} BuiltInFuncEntry;

#ifdef __BORLANDC__
extern BuiltInFuncEntry _far BuiltInFuncs[NUM_BUILT_IN_FUNCTIONS];
#else /* __HIGHC__ */
extern BuiltInFuncEntry BuiltInFuncs[NUM_BUILT_IN_FUNCTIONS];
#endif
#endif

#define DEFUN(_name) void _name(register RMLPtr rms, BuiltInFuncEnum id)

#define BTABLE_HEADER
#ifdef LIBERTY
#include "Legos/btable.h"
#else
#include <Legos/Bridge/btable.h>
#endif
#undef BTABLE_HEADER
#endif /* _BUILTIN_H_ */
