/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        
MODULE:         
FILE:           stable.h

AUTHOR:         Roy Goldman, Dec  8, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       12/ 8/94           Initial version.

DESCRIPTION:
	Header info specific to the string table/associative array

	$Id: stable.h,v 1.1 98/10/13 21:43:38 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _STABLE_H_
#define _STABLE_H_

#include <mystdapp.h>

/* The returned optr is actually a hash table set up to be used
 * with the string table callbacks.
 */
optr StringTableCreate(VMFileHandle vmFile);
void StringTableDestroy(optr table);

/* Add null-terminated string to table, returning its key.
 * If Ansi/string.has already been added, it will not be added again.
 * StringTableAddWithData will append the passed word after the
 * stored string's null.
 */
dword StringTableAddWithData(optr table, TCHAR *string, word size, void *data);
dword StringTableAdd(optr table, TCHAR *string);

/* Check if the given string is in the table; return
 * NullElement if not.  ...LookupWithData will additionally
 * extract the stored data (locking/unlocking the string).
 */
dword StringTableLookupString(optr table, TCHAR *string);
dword StringTableLookupWithData(optr table, TCHAR *string, word size, void *data);

word StringTableGetData(optr table, dword key);
void StringTableGetDataPtr(optr table, dword key, word size, void *dataPtr);
void StringTableSetDataPtr(optr table, dword key, word size, void *dataPtr);

/* Lock down the string for a given key in the string table */

TCHAR *StringTableLock(optr table, dword key);
Boolean StringTableLockNew(optr table, dword key, TCHAR** cpp, word* size);

/* Get the number of strings in the string table */

dword StringTableGetCount(optr table);

/* the only way to delete an element is to create a new table with all
 * elements but the one to be deleted added to it
 */
optr StableCopyTableDeleteElement(optr table, word index);

#define StringTableUnlock HugeArrayUnlock
#define NullElement ((dword) -1)


#endif /* _STABLE_H_ */
