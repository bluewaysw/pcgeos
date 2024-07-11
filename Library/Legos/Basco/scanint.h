/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        Legos
MODULE:         Basco
FILE:           scanint.h

AUTHOR:         Roy Goldman, Dec  5, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       12/ 5/94           Initial version.

DESCRIPTION:
	Header file for the Basco scanner

	$Id: scanint.h,v 1.1 98/10/13 21:43:22 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _SCANINT_H_
#define _SCANINT_H_

#include <mystdapp.h>

/* INTERNAL SCANNING ROUTINES: */

/* Do the len bytes at cp form a keyword? */

TokenCode CheckForKeyword(TCHAR *cp, int len);

/* Null terminate the buffer and add it to the string table */

dword MyStringTableAdd(optr IdentTable, TCHAR *buffer, word len);

/* Can this TCHARacter be in the middle of an identifier? */

byte IsValidIdentChar(TCHAR c);

/* My version of string compare */

byte myequal(TCHAR *s1, TCHAR *s2, int length);


/* WE know we have a number, scan it off */

Token ScanNumber(TCHAR *expression, word *position);
#endif /* _SCANINT_H_ */








