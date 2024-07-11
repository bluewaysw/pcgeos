/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        Legos
MODULE:         Basco
FILE:           scanner.h

AUTHOR:         Roy Goldman, Dec  5, 1994

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	roy       12/ 5/94           Initial version.

DESCRIPTION:
	Header file for the Basco scanner;
	declarations exported to rest of basco
	
	$Id: scanner.h,v 1.1 98/10/13 21:43:25 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _SCANNER_H_
#define _SCANNER_H_

#include <mystdapp.h>
#include "btoken.h"
#include "comtask.h"
#include "bascoint.h"

/* Get the next token from buffer, starting at position.

   IdentTable is the string table where non-string-constants
   will be deposited.  String constants go into StrTable.

   buffer is a NullTerminated buffer containing >=1 lines of BASIC source.

   position is the current offset to look at within that buffer.
     Initially this should be 0, and the routine will update it
     as tokens are consumed.

   lineNum is the current lineNumber associated with each token.  Again, 
     it should be initially supplied as 0, and this routine will update
     as necessary

   Returns the token found (or TOKEN_EOF or TOKEN_EOL or ERR*)
*/

#define MAX_LOOKAHEAD	3
typedef struct
{
    TaskPtr 	task;
    word    	position;
    word    	lineNum;
    dword   	lineElement;
    TCHAR   	*line;
    Token	tokenStack[MAX_LOOKAHEAD];
    byte	numPushed;
    /* hasPushedToken, lastToken */
} ScannerState;

Token ScannerGetToken(ScannerState *state, optr IdentTable, optr StrTable,
		      Boolean ignoreEOL);
void ScannerPushToken(ScannerState *state, Token token);
void ScannerInitState(ScannerState *state, TaskPtr task, dword lineElement);
void ScannerClean(ScannerState *state);

/* Debugging routine: return a string equivalent of the token */


#endif /* _SCANNER_H_ */
