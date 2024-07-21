/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		table.h

AUTHOR:		Jimmy Lefkowitz, Jan  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 1/ 9/95	Initial version.

DESCRIPTION:
	table header file

	$Id: table.h,v 1.1 98/10/13 21:43:46 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _TABLE_H_
#define _TABLE_H_

#include <geos.h>
#include <Legos/legtype.h>

typedef enum
{
#define BTABLE_ENUM
#include <Legos/Bridge/btable.h>
    NUM_BUILT_IN_FUNCTIONS
} BuiltInFuncEnum;

typedef struct
{
    TCHAR	name[MAX_BUILT_IN_FUNC_NAME]; 
#define VARIABLE_NUM_ARGS	0xff
    byte	numArgs;
    LegosType	argTypes[3];
    LegosType	returnType;
} BascoBuiltInEntry;

#ifdef __BORLANDC__
extern const BascoBuiltInEntry _far BuiltInFuncs[NUM_BUILT_IN_FUNCTIONS];
#else
extern const BascoBuiltInEntry BuiltInFuncs[NUM_BUILT_IN_FUNCTIONS];
#endif
#endif /* _TABLE_H_ */
