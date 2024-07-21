/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		table.c

AUTHOR:		Jimmy Lefkowitz, Jan  9, 1995

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	 1/ 9/95   	Initial version.
	roy      7/9/95         Slimmed down tremendously.

DESCRIPTION:
	table of built-in functions
	
	$Id: table.c,v 1.1 98/10/13 21:43:44 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <geos.h>
#include <object.h>
#include "table.h"

#ifdef __BORLANDC__
#pragma option -zEFUNC_TABLE_TEXT -zFDATA
#define vfar _far
#else /* __HIGHC__ z!*/
#define vfar
#endif

const BascoBuiltInEntry vfar BuiltInFuncs[ NUM_BUILT_IN_FUNCTIONS ] =
{
#define BTABLE_BASCO_TABLE
#include <Legos/Bridge/btable.h>
};

#if defined(__BORLANDC__)
#pragma option -zE* -zF*
#endif

