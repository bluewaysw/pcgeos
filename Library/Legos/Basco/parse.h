/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           parse.h

AUTHOR:         Jimmy Lefkowitz, Dec  8, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	jimmy       12/ 8/94           Initial version.

DESCRIPTION:
 	    header file for parse functions

	$Id: parse.h,v 1.1 98/10/13 21:43:16 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _PARSE_H_
#define _PARSE_H_

#include "btoken.h"
#include "bascoint.h"


/* Free up the function table, part of the compile time task*/
extern void FuncTableDestroy(MemHandle task_han);
extern void FuncTableClean(MemHandle task_han);
extern MemHandle FuncTableCreate(void);

#endif /* _PARSE_H_ */
