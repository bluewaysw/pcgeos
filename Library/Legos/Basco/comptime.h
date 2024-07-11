/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		comptime.h

AUTHOR:		Jimmy Lefkowitz, May  5, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 5/ 5/95	Initial version.

DESCRIPTION:
	

	$Id: comptime.h,v 1.1 98/10/13 21:42:41 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _COMPTIME_H_
#define _COMPTIME_H_

#include "mystdapp.h"
#include <Legos/legtype.h>
#include "btoken.h"
#include "bascoint.h"

/* structID is an entry in the struct string table, if lt == TYPE_STRUCT
 * Returns TRUE if successful
 */
extern Boolean
CompileResolvePropertyOrAction
    (TaskPtr task, optr comp, TokenCode code, TCHAR *prop, 
     byte* message, LegosType* lt, word* structID, word *numParams);

#endif /* _COMPTIME_H_ */
