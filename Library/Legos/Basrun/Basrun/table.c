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

#if defined(__BORLANDC__)
#pragma option -zEFUNC_TABLE_TEXT -zFDATA
#define vfar _far
#elif defined(__WATCOMC__)
#define vfar 
#endif

/* The compiler has already mapped built-in calls into one of the following
   entries. the Enum field for each is also supplied to the called routine...
   
   There is one entry for _every_ built-in basic function.

   Make sure the order here matches the order in the enum declaration
   (in Bridge/btable.h) EXACTLY!
*/

#ifdef LIBERTY
const BuiltInVector * const BuiltInFuncs[ NUM_BUILT_IN_FUNCTIONS ] =
#else
#ifdef __BORLANDC__
const BuiltInFuncEntry vfar BuiltInFuncs[ NUM_BUILT_IN_FUNCTIONS ] =
#elif defined(__WATCOMC__)
const BuiltInFuncEntry vfar BuiltInFuncs[ NUM_BUILT_IN_FUNCTIONS ] =
#else /* __HIGHC__ */
const BuiltInFuncEntry BuiltInFuncs[ NUM_BUILT_IN_FUNCTIONS ] =
#endif
#endif
{
#define BTABLE_BASRUN_TABLE
#ifdef LIBERTY
#include "Legos/btable.h"
#else
#include <Legos/Bridge/btable.h>
#endif
};

#if defined(__BORLANDC__)
#pragma option -zE* -zF*
#endif
