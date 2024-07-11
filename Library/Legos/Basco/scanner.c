/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:        Legos	
MODULE:		basco
FILE:		scanner.c

AUTHOR:		Roy Goldman, Dec  5, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/ 5/94   	Initial version.

DESCRIPTION:
	
        Scanner for the basic compiler

	$Id: scanner.c,v 1.1 98/10/13 21:43:23 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include "scanner.h"
#include "scanint.h"
#include <library.h>
#include <math.h>
#include <Ansi/ctype.h>
#include <Ansi/string.h>
#include "stable.h"
#include "faterr.h"
#include <char.h>
#include "scope.h"

extern word setDSToDgroup(void);
extern void restoreDS(word);

#define ESCAPE_CHAR C_BACKSLASH


/*********************************************************************
 *			ScannerInitState
 *********************************************************************
 * SYNOPSIS:	initialize a scanner state for parsing
 * CALLED BY:	Parse_Function
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/ 8/96  	Initial version
 * 
 *********************************************************************/
void
ScannerInitState(ScannerState *state, TaskPtr task, dword lineElement)
{
    state->lineElement = lineElement;
    state->task = task;
    state->lineNum = 0;
    state->position= 0;
    state->numPushed = 0;
    state->line = Line_SelfToLine(task, lineElement);
}


/*********************************************************************
 *			ScannerClean
 *********************************************************************
 * SYNOPSIS:	cleanup a ScannerState
 * CALLED BY:	Parse_Function
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/ 8/96  	Initial version
 * 
 *********************************************************************/
void
ScannerClean(ScannerState *state)
{
    if (state->line != NULL) {
	Line_Unlock(state->task);
    }
}

/*********************************************************************
 *			ScannerPushToken
 *********************************************************************
 * SYNOPSIS:	allow a putback of a single token
 * CALLED BY:	GLOBAL
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	3/ 7/96  	Initial version
 * 
 *********************************************************************/
void 
ScannerPushToken(ScannerState *state, Token token)
{
    /* only handles a single pushed token at a time */
    EC_ERROR_IF(state->numPushed >= MAX_LOOKAHEAD, -1);
    state->tokenStack[state->numPushed++] = token;
}

/*********************************************************************
 *			ScannerGetToken
 *********************************************************************
 * SYNOPSIS:	Main scanning routine.
 *              This routine's job is to translate ASCII code
 *              into a stream of tokens
 *
 *              To use, supply a character buffer, and a starting
 *              offset to begin examining the buffer.  Also supply
 *              a starting line-number corresponding to where
 *              the first token to be examined will be.
 *
 *              This routine will return the next token found and
 *              adjust position and startLineNum accordingly.
 *
 *              Position will be set to NULL and the last token
 *              is automatically terminated when we hit NULL in
 *              the string. We return the NULLCODE token code.
 *
 *              When we find an EOL, we return TOKEN_EOLS since
 *              this is important to BASIC. Before we do, though,
 *              we consume all whitespace (including returns)
 *              following that EOL since those are no longer important.
 *
 *              LineNum is incremented by the routine every time
 *              a newline is encountered; 
 *
 *              With this design, it is straightforward to
 *              scan one or more lines at a time, with lineNum
 *              getting adjusted automatically...
 *              
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 5/94		Initial version			     
 * 
 *********************************************************************/

Token ScannerGetToken(ScannerState  *state,
		      optr  	    IdentTable,
		      optr  	    StringTable,
		      Boolean	    ignoreEOL)
{
    TCHAR   *cp;
    TCHAR   *start;
    TCHAR   *buffer;
    int     len;
    Token   token;
    word    *position;
    byte    loop;
    word    oldDS;

    if (state->numPushed > 0) {
	return state->tokenStack[--state->numPushed];
    }

    oldDS = setDSToDgroup();

 TOP:
    /* if we are not currently working on a line, lock down
     * the next line
     */
    if (state->line == NULL) 
    {
	state->lineElement = Line_FindNext(state->task, state->lineElement);
	state->line = Line_SelfToLine(state->task, state->lineElement);
	state->lineNum++;
    }

    token.code            = TOKEN_EOF;
    token.data.integer    = 0;
    token.lineNum = state->lineNum;

    if (state->line == NULL)
    {
	restoreDS(oldDS);
	return token;
    }

    buffer = state->line + 1;
    position = &state->position;
    
    EC_BOUNDS(buffer);

    /* The first token we find will always be on this line,
       because EOL's are important to BASIC. If we find one,
       we set the token to TOKEN_EOL and then consume all whitespace
       following that.....
     */

    loop = 1;

    while(loop) {

	cp = buffer + *position;

	switch (*cp) {
	case C_ENTER:
	    
	    /* We hit a return, now consume all following space */
	    token.code = TOKEN_EOLS;
	    state->lineNum += 1;

	    /* fall through... */

	case C_FF:
	case C_SPACE:
	case C_TAB:
	case C_LINEFEED:
	    
	    *position += 1;
	    break;
	    
	case C_BACKSLASH:
	    if (*(cp+1) == C_ENTER)
	    {
		/* we only want to see this once */
		*cp = C_SPACE;
		*(cp + 1) = C_SPACE;
		*position += 2;
		state->lineNum += 1;
	    }
	    else
	    {
		loop = 0;
	    }
	    break;

	case C_NULL:
	    /* If we are going to return EOLS, don't consume
	       the EOF yet... That will happen next time around... */

	    if (token.code != TOKEN_EOLS) {
/* I nuked this as it was causing my trouble
		*position = NULL;
*/
		goto	done;
	    }

	    default:
	    loop = 0;
	}
	
    }

    if (token.code == TOKEN_EOLS) {
	goto	done;
    }

    /* Now, in one pass identify the next token... */
	    
    cp = buffer + *position;
    start = cp;

    len = 0;

    switch (*cp)
    {

    case C_QUOTE:
    {
	Boolean	inEscape = FALSE;

	/* Try to consume the next quote */

	cp++;
	*position += 1;
	len = 0;
	start++;		/* skip the double quote */

	/* FIXME inefficient; we can deal with all escape chars here
	 * instead passing over yet again at mystringtableadd --dubois
	 */

	/* Read until the next un-escaped double-quote, or to NULL */
	while (*cp != C_NULL
	       && (*cp != C_QUOTE || inEscape))
	{
	    inEscape = inEscape ? FALSE : (*cp == ESCAPE_CHAR);
	    cp++;
	    /*
	     * Don't store linefeed as part of string, but do store
	     * CR (carriage return).
	     */
	    if (*cp != C_LINEFEED) 
	    {
		*position += 1;
		len++;
	    }

	}
	    
	if (*cp == C_QUOTE)
	{
	    /* Successful */
	    *position += 1;	/* pass over the close quote */
	    token.data.key = MyStringTableAdd(StringTable,start,len);
	    token.code = CONST_STRING;
	}
	else
	{
	    /* Hammered! */
	    token.code = ERR_NO_END_QUOTE;
	}
	break;
    }
    case C_ZERO:
    case C_ONE:
    case C_TWO:
    case C_THREE:
    case C_FOUR:
    case C_FIVE:
    case C_SIX:
    case C_SEVEN:
    case C_EIGHT:
    case C_NINE:
    case C_AMPERSAND:		/* designator for hex or octal constant */
    case C_PERIOD:

	if (*cp == C_AMPERSAND ||
	    isdigit(*cp) || (*cp == C_PERIOD && isdigit(*(cp+1)))) {
	    /* Scan in the number and update the position */
	    token = ScanNumber(cp,position);

	    /* ScanNumber doesn't fill in the line number */
	    token.lineNum = state->lineNum;
	}
	else {
	    token.code = PERIOD;
	    *position += 1;
	}

	break;

	/* Now take care of all unambiguous single TCHARacter tokens */


    case C_COLON:
	/* module variable references will look like module:varname */
	token.code = COLON;
	*position += 1;
	break;

    case C_EXCLAMATION:
	/* for now actions use the '!', so dialog!Show() will call the
	 * show action for a dialog
	 */
	token.code = EXCLAMATION;
	*position += 1;
	break;

    case C_LEFT_PAREN:

	token.code = OPEN_PAREN;
	*position += 1;
	break;

    case C_RIGHT_PAREN:

	token.code = CLOSE_PAREN;
	*position += 1;
	break;

    case C_LEFT_BRACKET:

	token.code = OPEN_BRACKET;
	*position += 1;
	break;

    case C_RIGHT_BRACKET:

	token.code = CLOSE_BRACKET;
	*position += 1;
	break;

    case C_ASTERISK:
            
	token.code = MULTIPLY;
	token.data.precedence = PREC_MULTIPLY;
	*position += 1;
	break;

    case C_PLUS:
            
	token.code = PLUS;
	token.data.precedence = PREC_PLUS;
	*position += 1;
	break;

    case C_MINUS:
            
	token.code = MINUS;
	token.data.precedence = PREC_PLUS;
	*position += 1;
	break;

    case C_SLASH:
            
	token.code = DIVIDE;
	token.data.precedence = PREC_MULTIPLY;
	*position += 1;
	break;

    case C_EQUAL:
            
	token.code = EQUALS;
	token.data.precedence = PREC_EQUALS;
	*position += 1;
	break;

    case C_LESS_THAN:
 
	if (*(cp+1) == C_GREATER_THAN) {
	    token.code = LESS_GREATER;
	    token.data.precedence = PREC_EQUALS;
	    *position += 2;
	    break;
	}

	if (*(cp+1) == C_EQUAL) {
	    token.code = LESS_EQUAL;
	    token.data.precedence = PREC_COMPARE;

	    *position += 2;
	    break;
	}

	token.code = LESS_THAN;
	token.data.precedence = PREC_COMPARE;
	*position += 1;

	break;

    case C_GREATER_THAN:

	if (*(cp+1) == C_EQUAL) {
	    token.code = GREATER_EQUAL;
	    *position += 2;
	    token.data.precedence = PREC_COMPARE;
	    break;
	}

	token.code = GREATER_THAN;
	token.data.precedence = PREC_COMPARE;
	*position += 1;

	break;

    case C_COMMA:
	token.code = COMMA;
	*position += 1;
	break;
		
    case C_ASCII_CIRCUMFLEX:
	token.code = CARET;
	*position += 1;
	break;

    case C_SNG_QUOTE:
	token.code = REM;
	*position += 1;
	break;

    default:
	if ( isalpha(*cp) || *cp==C_UNDERSCORE ) {
		
	    /* Scan this word based thing,
	       which could be a keyword, function, or variable.
	       
	       For now, we convert keywords into tokens.
	       I dont' convert RND, ABS, COS, etc. into keywords.
	       We can do this later.....
	       */
		
	    len = 0;

	    while (IsValidIdentChar(*cp)) {
		cp++;
		*position += 1;
		len++;
	    }

	    token.code = CheckForKeyword(start,len);

	    /* If we found one we're done */

	    if (token.code != NULLCODE) 
	    {
		switch (token.code) 
		{
		case NOT: token.data.precedence = PREC_NOT; break;
		case MOD: token.data.precedence = PREC_MULTIPLY; break;
		case BIT_AND: token.data.precedence = PREC_BIT_AND; break;
		case BIT_XOR: token.data.precedence = PREC_BIT_XOR; break;
		case BIT_OR: token.data.precedence = PREC_BIT_OR; break;
		case AND: token.data.precedence = PREC_AND; break;
		case XOR: token.data.precedence = PREC_XOR; break;
		case OR: token.data.precedence = PREC_OR; break;
		}
		break;
	    }

	    /* Otherwise, we have a function or variable name
	       (perhaps incorrect)... 
	       Store it in our string table and update the position*/

	    token.code = IDENTIFIER;

	    /* Add portion of buffer to string table,
	       keep a key for it */

	    token.data.key = MyStringTableAdd(IdentTable,start,len);
	    break;
	}
	else
	    token.code = ERR_BAD_CHAR;
    }

    if (token.code == REM) {
	
	while (*cp != C_ENTER && *cp != C_NULL) 
	{
	    cp++;
	    *position += 1;
	}
    }
 done:
    if (LINE_TERM(token.code))
    {
	Line_Unlock(state->task);
	state->line = NULL;
	state->position = 0;
	if (ignoreEOL)
	{
	    goto TOP;
	}
    }
    restoreDS(oldDS);
    return token;
}



/*********************************************************************
 *		    BascoIsKeyword
 *********************************************************************
 * SYNOPSIS:	external routine for checking keywords
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	5/ 6/96  	Initial version
 * 
 *********************************************************************/
Boolean BascoIsKeyword(TCHAR	*name, int len)
{
    word    oldDS;
    TokenCode  	code;

    oldDS = setDSToDgroup();

    if (!len) {
	len = strlen(name);
    }
    code = CheckForKeyword(name, len);
    restoreDS(oldDS);
    return (Boolean)(code != NULLCODE);
}
	
/*********************************************************************
 *			CheckForKeyword
 *********************************************************************
 * SYNOPSIS:	Take a TCHARacter pointer and a length
 *              and see if that data is a keyword.
 *              If so, return the correct token.
 *              Otherwise, return NULLCODE;
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 5/94		Initial version			     
 * 
 *********************************************************************/
TokenCode CheckForKeyword(TCHAR *cp, int len) 
{
    byte fc = toupper(*cp);

#define CHECK_TOKEN(_tok, _len) \
 if (myequal(cp, _TEXT(#_tok), _len)) return _tok

    switch(len) 
    {
	case 1:
	return NULLCODE;

	case 2:

	switch(fc) 
	{
	case C_CAP_I:
	    if (myequal(cp,_TEXT("IF"),2)) return IF;
	    break;
    	case C_CAP_D:
	    if (myequal(cp,_TEXT("DO"),2)) return DO;
	    break;
    	case C_CAP_A:
	    if (myequal(cp,_TEXT("AS"),2)) return AS;
	    break;
    	case C_CAP_T:
	    if (myequal(cp,_TEXT("TO"),2)) return TO;
	    break;
    	case C_CAP_O:
	    if (myequal(cp,_TEXT("OR"),2)) return OR;
	    break;
    	}	
	break;

	case 3:

	switch (fc) 
	{
	case C_CAP_A:
	    if (myequal(cp,_TEXT("AND"),3)) return AND;
	    break;
	case C_CAP_D:
	    if (myequal(cp,_TEXT("DIM"),3)) return DIM;
	    break;
	case C_CAP_E:
	    if (myequal(cp,_TEXT("END"),3)) return END;
	    break;
	case C_CAP_F:
	    if (myequal(cp,_TEXT("FOR"),3)) return FOR;
	    break;
	case C_CAP_L:
	    if (myequal(cp,_TEXT("LET"),3)) return LET;
	    break;
	case C_CAP_M:
	    if (myequal(cp,_TEXT("MOD"),3)) return MOD;
	    break;
	case C_CAP_N:
	    if (myequal(cp,_TEXT("NOT"),3)) return NOT;
	    break;
	case C_CAP_R:
	    if (myequal(cp,_TEXT("REM"),3)) return REM;
	    break;

	case C_CAP_S:
	    if (myequal(cp,_TEXT("SUB"),3)) return SUB;
	    break;

	case C_CAP_X:
	    if (myequal(cp,_TEXT("XOR"),3)) return XOR;
	    break;
	}
	break;

	case 4:

	switch (fc) 
	{
	case C_CAP_C:
	    if (myequal(cp,_TEXT("CASE"),4)) return CASE;
	    break;
	case C_CAP_E:
	    if (myequal(cp,_TEXT("ELSE"),4)) return ELSE;
	    if (myequal(cp,_TEXT("EXIT"),4)) return EXIT;
	    break;
	case C_CAP_G:
	    if (myequal(cp,_TEXT("GOTO"),4)) return TOKEN_GOTO;
	    break;
	case C_CAP_L:
	    if (myequal(cp,_TEXT("LONG"),4)) return LONG;
	    if (myequal(cp,_TEXT("LOOP"),4)) return LOOP;
	    break;
	case C_CAP_N:
	    if (myequal(cp,_TEXT("NEXT"),4)) return NEXT;
	    break;
	case C_CAP_S:
	    if (myequal(cp,_TEXT("STEP"),4)) return STEP;
	    break;
	case C_CAP_T:
	    if (myequal(cp,_TEXT("THEN"),4)) return THEN;
	    break;
	case C_CAP_W:
	    if (myequal(cp,_TEXT("WEND"),4)) return WEND;
	    break;
	}
	break;

	case 5:
	switch (fc)
	{
	case C_CAP_C:
	    if (myequal(cp, _TEXT("CONST"), 5)) return CONSTANT;
	    break;
	case C_CAP_D:
	    if (myequal(cp,_TEXT("DEBUG"),5)) return DEBUG;
	    break;
	case C_CAP_F:
	    if (myequal(cp,_TEXT("FLOAT"),5)) return FLOAT;
	    break;
	case C_CAP_R:
	    if (myequal(cp, _TEXT("REDIM"), 5)) return REDIM;
	    break;
	case C_CAP_U:
	    if (myequal(cp,_TEXT("UNTIL"),5)) return UNTIL;
	    break;
	case C_CAP_W:
	    if (myequal(cp,_TEXT("WHILE"),5)) return WHILE;
	    break;
	case C_CAP_B:
	    if (myequal(cp,_TEXT("BITOR"),5)) return BIT_OR;
	    break;
	}
	break;

	case 6:

	switch (fc)
	{
	case C_CAP_E:
	    if (myequal(cp,_TEXT("EXPORT"), 6)) return EXPORT;
	    break;
	case C_CAP_G:
	    if (myequal(cp, _TEXT("GLOBAL"), 6)) return GLOBAL;
	    break;
	case C_CAP_M:
	    if (myequal(cp,_TEXT("MODULE"), 6)) return MODULE;
	    break;
	case C_CAP_R:
	    CHECK_TOKEN(RESUME, 6);
	    break;
	case C_CAP_S:
	    if (myequal(cp,_TEXT("STRING"),6)) return STRING;
	    if (myequal(cp,_TEXT("SELECT"),6)) return SELECT;
	    if (myequal(cp, _TEXT("STRUCT"),6)) return STRUCT;
	    break;
    	case C_CAP_B:
	    if (myequal(cp,_TEXT("BIT"), 3))
	    {
		cp += 3;
		switch (*cp)
		{
		case C_CAP_A:
		    if (myequal(cp,_TEXT("AND"),3)) return BIT_AND;
		case C_CAP_X:
		    if (myequal(cp,_TEXT("XOR"),3)) return BIT_XOR;
		}
	    }
	    break;
	}
	break;

	case 7:
	switch (fc)
	{
	case C_CAP_C:
	    if (myequal(cp,_TEXT("COMPLEX"),7)) return COMPLEX;
	    break;
	case C_CAP_I:
	    if (myequal(cp,_TEXT("INTEGER"),7)) return INTEGER;
	    break;
	case C_CAP_O:
	    CHECK_TOKEN(ONERROR, 7);
	    break;
	}
	break;

	case 8:
	switch (fc)
	{
	case C_CAP_F:
	    if (myequal(cp,_TEXT("FUNCTION"),8)) return FUNCTION;
	    break;
	case C_CAP_C:
	    if (myequal(cp,_TEXT("COMPINIT"),8)) return COMP_INIT;
	    break;
	case C_CAP_P:
	    if (myequal(cp,_TEXT("PRESERVE"),8)) return PRESERVE;
	    break;
	}
	break;

	case 9:

	if (myequal(cp,_TEXT("COMPONENT"),9))
	    return COMPONENT;
    }


    return NULLCODE;
}

/*********************************************************************
 *			MyStringTableAdd
 *********************************************************************
 * SYNOPSIS:	Use a hack to null-terminate the given pointer
 *              and then add it to the actual table.
 *		Convert Escape codes to real TCHARs: \r -> C_CR.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:     
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 5/94		Initial version			     
 * 
 *********************************************************************/
dword
MyStringTableAdd(optr table, TCHAR *buffer, word len)
{
    dword	val;
    TCHAR	t;
    
    /* Do a little funny stuff to ensure that the string we add
       is null terminated...*/

    EC_BOUNDS(buffer+len);
    t = buffer[len];

    buffer[len] = 0;

    /*
     * Check for escape codes
     */
    if ( strchr(buffer, ESCAPE_CHAR) == NULL )
    {
	val = StringTableAdd(table, buffer);
    }
    else
    {
	MemHandle 	tempHan; /* holds string + trailing null */
	TCHAR*		tempPtr;
	TCHAR*		buff2;

	buff2 = buffer;
	tempHan = MemAlloc((len+1)*sizeof(TCHAR), 
			   HF_SWAPABLE | HF_SHARABLE, HAF_LOCK);
	tempPtr = MemDeref(tempHan);
	while (*buff2)
	{
	    if (*buff2 != ESCAPE_CHAR)
	    {
		*tempPtr = *buff2;
	    } 
	    else 
	    {
		switch (buff2[1]) 
		{
		case C_SMALL_R:
		    *tempPtr = C_ENTER;
		    buff2++;
		    break;
		case C_QUOTE:
		    *tempPtr = C_QUOTE;
		    buff2++;
		    break;
		case ESCAPE_CHAR:
		    *tempPtr = ESCAPE_CHAR;
		    buff2++;
		    break;
		case C_SMALL_T:
		    *tempPtr = C_TAB;
		    buff2++;
		    break;
		default:
		    *tempPtr = ESCAPE_CHAR;
		    tempPtr++;
		    buff2++;
		    *tempPtr = *buff2;
		    break;
		}
	    }
	    tempPtr++;
	    buff2++;
	}
	EC_ERROR_IF(tempPtr - MemDeref(tempHan) > len, BE_FAILED_ASSERTION);
	*tempPtr = C_NULL;

	val = StringTableAdd(table, MemDeref(tempHan));
	MemFree(tempHan);
    }

    buffer[len] = t;
    return val;
}

/*********************************************************************
 *			IsValidIdentChar
 *********************************************************************
 * SYNOPSIS:	Are we looking at a TCHARacter which can
 *              be part of an identifier?
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:         
 *                 
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 5/94		Initial version			     
 * 
 *********************************************************************/

byte IsValidIdentChar(TCHAR c) {

    return ( isalnum(c) ||  c == C_UNDERSCORE);
}
    
/*********************************************************************
 *			myequal
 *********************************************************************
 * SYNOPSIS:	Simple string comparison for a specific number
 *              of TCHARs, ignoring the case of first value,
 *              and returning as soon as one found invalid...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 5/94		Initial version			     
 * 
 *********************************************************************/

byte myequal(TCHAR *s1, TCHAR *s2, int len) {

    while (len) {
	if (toupper(*s1) != *s2)
	    return 0;

	s1++;
	s2++;
	len--;
    }

    return 1;
}


/*********************************************************************
 *			IsValidSingle
 *********************************************************************
 * SYNOPSIS:	Returns TRUE iff the given double can
 *              be safely casted down into a single with no loss
 *              of magnitude. Of course there will be a loss
 *              of precision
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 *              This depends entirely on IEEE standard
 *              for 64 bit/ 32 bit floating point represenations..
 *              
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	 5/ 3/95	Initial version
 * 
 *********************************************************************/
Boolean IsValidSingle(double x) 
{
    byte *wow;
    unsigned int highWord;
    int doubExp;

    if (x == 0) {
	return TRUE;
    }

    wow = (byte*) &x;

    /* Considering a double's bits being numberd 0-63, bits
       52 - 62 (11 bits) are used for the exponent of the number.

       First let's pare things down and only look at bits 48-63:
    */

    highWord = *(unsigned int*)(wow+6);

    /* Now, isolate the bits by and shift right 4:

       63 62 61 60 59 58 57 56 55 54 53 52 51 50 49 48
  
       ?  eA e9 e8 e7 e6 e5 e4 e3 e2 e1 e0 ?  ?  ?  ?

       goes to
       
       0  0  0  0  0  eA e9 e8 e7 e6 e5 e4 e3 e2 e1 e0

       Further, 1023 must be subtracted from the final result
       to get the actual exponent... (See the standard)
    */

    doubExp = ((highWord & 0x7ff0) >> 4) - 1023;

    /* Single exponent magnitudes must be between -127 and 127 */
    return (doubExp >= -127 && doubExp <= 127);
} 
                               
          

/*********************************************************************
 *			ScanNumber
 *********************************************************************
 * SYNOPSIS:	Scans off a number
 *              Swiped almost verbatim from Jimmy's exp_numconst
 *              function, except for the +- header...
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/ 6/94		Initial version
 *      roy     5/2/95          Tweaked to be more robust	     
 *                              when enormous numbers are entered
 * 
 *********************************************************************/

/* These seem entirely reasonable... */

#ifdef DO_DBCS
#define MAX_NUM_LEN    70
#define MAX_EXP_LEN    10
#else
#define MAX_NUM_LEN    35
#define MAX_EXP_LEN    5
#endif

Token
ScanNumber( TCHAR *expression, word *position )
{
    int     base;                /* numerical base for the constant */
    double testDouble;
    double expVal;
    float  mantissa;	    	 /* value of manitssa for floats */
    int     exponent= FALSE;     /* exponent for floating point number */
    int     man_start;           /* starting point of mantissa */
    int     build_loop;	       	 /* looping variable */
    int     need_pm;	   	 /* need plus/minus flag */
    int	    decimal= FALSE;
    long    l;
    TCHAR    *exps_string, *exp;	 /* pointers into expression */
    TCHAR    tempStore[MAX_NUM_LEN];       /* Where we build up the number
					   */
    word    oldDS;
    unsigned long ul;
    double x;

    TCHAR    *start_string;
    Token token;
    byte makeFloat =0;
    byte nextOverFlows;


    token.code = NULLCODE;
    token.data.key = 0;

    exps_string = tempStore;
    start_string = tempStore;

   /* check the first character(s) to determine numerical base
      and starting point of the mantissa */

    switch( expression[ 0 ] )
    {
    case C_PERIOD:
	decimal = TRUE;
    case C_ZERO:
    case C_ONE:
    case C_TWO:
    case C_THREE:
    case C_FOUR:
    case C_FIVE:
    case C_SIX:
    case C_SEVEN:
    case C_EIGHT:
    case C_NINE:
	base = 10;                     /* decimal constant */
	man_start = 0;                 /* starts at position 0 */
	break;
    case C_AMPERSAND:                         /* hex or octal constant */
	if ((expression[1] == C_CAP_H) || (expression[1] == C_SMALL_H))
	{
	    base = 16;                  /* hexadecimal constant */
	    man_start = 2;              /* starts at position 2 */
	    *position += 2;
	    break;
	}
	base = 8;                   /* octal constant */
	if ((expression[1] == C_CAP_O) || (expression[1] == C_SMALL_O)) {
	    man_start = 2;           /* starts at position 2 */
	} else {
	    man_start = 1;           /* starts at position 1 */
	}
	*position += man_start;
	break;
    default:
#if ERROR_CHECK
	EC_ERROR(-1);
#endif
	return token;
	
    }
    
    build_loop = TRUE;
    
    exp = expression+man_start;
    
    switch( base )
    {
	
    case 10:                          /* decimal constant */
	
	/* loop to build the string */
	
	while ( build_loop == TRUE )
	{
	    
	    if (exps_string - start_string >= MAX_NUM_LEN) {
		token.code = ERR_OVERFLOW;
		return token;
	    }
	    switch( *exp )
	    {
	    case C_PERIOD:           /* note at least single precision */
		decimal = TRUE;
	    case C_ZERO:
	    case C_ONE:
	    case C_TWO:
	    case C_THREE:
	    case C_FOUR:
	    case C_FIVE:
	    case C_SIX:
	    case C_SEVEN:
	    case C_EIGHT:
	    case C_NINE:
		*exps_string++ = *exp++;
		*position += 1;
		break;
		
	    case C_NUMBER_SIGN:  /* Microsoft-type precision indicators */
		/*     case '!': */  /* ignored but terminates 
		       we don't support doubles! */
		exp++;
		*position += 1;
		token.code = CONST_FLOAT;
		exponent = FALSE;
		build_loop = FALSE;
		break;
		
	    case C_CAP_E:     /* exponential, single precision */
	    case C_SMALL_E:
	    case C_CAP_D:     /* exponential, double precision */
	    case C_SMALL_D:
		exp++;
		*position += 1;
		token.code = CONST_FLOAT;
		exponent = TRUE;
		build_loop = FALSE;
		break;
		
	    default:                         /* anything else, terminate */
		build_loop = FALSE;
		break;
	    }
	    
	}
	*exps_string = C_NULL;
	EC_ERROR_IF(exps_string - tempStore > MAX_NUM_LEN,
		    BE_FAILED_ASSERTION);
	
	
	/* assign the value to the mantissa variable */
	
	if (decimal == TRUE || exponent == TRUE)
	{
	    FloatAsciiToFloat(FAF_PUSH_RESULT, 
			      strlen(start_string), 
			      start_string, NULL);
	    FloatGeos80ToIEEE64(&testDouble);
	    
	    if (!IsValidSingle(testDouble)) {
		/* OVERFLOW! */
		token.code = ERR_OVERFLOW;
		return token;
	    }
	    /* Cast it into single */
	    mantissa = testDouble;
	    makeFloat = 1;
	}
	else if (exps_string - start_string > 9 * sizeof(TCHAR)) {
	    /* Wow, we may be too big for even a long.
	       Convert to float if necessary.
	       This allows us to successfully
	       parse 5000000000 as a float constant*/
	    
	    FloatAsciiToFloat(FAF_PUSH_RESULT,
			      strlen(start_string),
			      start_string, NULL);
	    FloatGeos80ToIEEE64(&testDouble);
	    
	    if (!IsValidSingle(testDouble)) {
		/* OVERFLOW! */
		token.code = ERR_OVERFLOW;
		return token;
	    }
	    /* Do same check here... */
	    
	    oldDS = setDSToDgroup();
	    if (testDouble >  (double) 2147483647.0 ||
		testDouble <  (double) -2147483648.0) {
		
		makeFloat = 1;
		mantissa = testDouble;
	    }
	    restoreDS(oldDS);
	}
	    
	if (!makeFloat) {
	    /* We know that this varaible is now for sure 
	       small enough to fit either as an int or a long.
	       */
	    l = 0L;
	    exps_string = start_string;
	    
	    while(*exps_string >= C_ZERO && *exps_string <= C_NINE)
	    {
		l = 10 * l + (*exps_string++ - C_ZERO);
	    }
	    
	    if (l > 32767 || l < -32768)
	    {
		token.code = CONST_LONG;
		token.data.long_int = l;
	    }
	    else 
	    {
		token.code = CONST_INT;
		token.data.integer = (int)l;
	    }
	    break;
	}
	
	/* read the exponent if there is one */
	
	if ( exponent == TRUE )
	{
	    
	    /* allow a plus or minus once at the beginning */
	    
	    need_pm = TRUE;
	    
	    /* initialize counters */
	    
	    exps_string = start_string;
            build_loop = TRUE;
	    
            /* loop to build the string */
	    
            while ( build_loop == TRUE )
	    {
		if (exps_string - start_string >= MAX_EXP_LEN) {
		    token.code = ERR_OVERFLOW;
		    return token;
		}
		switch( *exp )
		{
		case C_MINUS:                  /* prefixed plus or minus */
		case C_PLUS:
		    if ( need_pm == TRUE ) {
			*position+=1;
			*exps_string++ = *exp++;
		    } else {
			build_loop = FALSE;
		    }
		    break;
		    
		case C_ZERO:
		case C_ONE:
		case C_TWO:
		case C_THREE:
		case C_FOUR:
		case C_FIVE:
		case C_SIX:
		case C_SEVEN:
		case C_EIGHT:
		case C_NINE:
		    *position += 1;
		    *exps_string++ = *exp++;
		    need_pm = FALSE;
		    break;
		    
		default:                  /* anything else, terminate */
		    build_loop = FALSE;
		    break;
		}
		
	    }                            /* end of build loop for exponent */
	    *exps_string = C_NULL;
	    EC_ERROR_IF(exps_string - tempStore > 4 * sizeof(TCHAR), 
			BE_FAILED_ASSERTION);
	    
            /* use the float routine just cause it's easy,
	       not case the exponent can be a float */
	    
	    
	    FloatAsciiToFloat(FAF_PUSH_RESULT, 
			      strlen( start_string), 
			      start_string, NULL);
	    
	    FloatGeos80ToIEEE64(&expVal);
	    
	    /* No way in hell we should support exponenets 
	       with magnitude > 250, since max supported in a
	       single is 38.
	       
	       We don't want to overflow the doubles, which
	       can have exponents up to 308. Hence even with
	       bizarre decimal placement, 250 + MAX_NUM_LEN should
	       never be more than 308.  If you change this 250,
	       make sure that it plus MAX_NUM_LEN is still less
	       than 308 if you're going to work with it as a double...
	       */
	    
	    if (expVal > 250 || expVal < -250) {
		token.code = ERR_OVERFLOW;
		return token;
	    }
	    

	    /* Let's raise 10 to the expVal's power, return it
	       into expVal */

	    oldDS = setDSToDgroup();
	    x = 10.0;
	    restoreDS(oldDS);
	    
	    FloatIEEE64ToGeos80(&x);
	    FloatIEEE64ToGeos80(&expVal);
	    
	    FloatExponential();
	    FloatGeos80ToIEEE64(&x);
	    
	    testDouble = mantissa * x;
	    
	    if (!IsValidSingle(testDouble)) {
		token.code = ERR_OVERFLOW;
		return token;
	    }
	    
	    token.data.num = testDouble;
	}
	else
	{
	    token.code = CONST_FLOAT;
	    token.data.num = mantissa;
	}
	
	break;
	
    case 8:                           /* octal constant */
    case 16:                          /* hexadecimal constant */
	
	/* initialize counters */
	
	/* In hex or octal, 32 bit numbers can be entered.
	   Anything else is overflow.
	*/

	ul = 0L;
	nextOverFlows = 0;

	if (base == 8)
	{

	     while(*exp >= C_ZERO && *exp <= C_SEVEN)
	     {
		 if (nextOverFlows) {
		     token.code = ERR_OVERFLOW;
		     return token;
		 }

		 ul = 8 * ul + (*exp - C_ZERO);
		 exp++;
		 *position+=1;

		 /* If any of bits 29, 30, or 31 are set
		    then an additional digit will take us
		    out of range because we multiply by 8....
		 */

		 if (ul & 0xe0000000) {
		     nextOverFlows = 1;
		 }
	     }
	     
	 }
	 else
	 {

	     while((*exp >= C_ZERO && *exp <= C_NINE) ||
		   (toupper(*exp) >= C_CAP_A && toupper(*exp) <= C_CAP_F))
	     {
		 if (nextOverFlows) {
		     token.code = ERR_OVERFLOW;
		     return token;
		 }
		 ul = ul * 16;
		 if (*exp <= C_NINE) {
		     ul += (*exp - C_ZERO);
		 } else {
		     ul += (toupper(*exp) - C_CAP_A + 10);
		 }
		 exp++;
		 *position+=1;

		 /* If any of bits 28, 29, 30, or 31 are set
		    than an additional digit will take us out
		    of range because we m ultiply by 16..
		 */

		 if (ul & 0xf0000000) {
		     nextOverFlows = 1;
		 }
	     }
	 }

	 /*
	  * Unfortunately, checking "ul & 0xFFFF8000" will cause
	  * compile-time errors (overflow) in apps that assign a
	  * constant with bit 15 set to an integer.  Since there
	  * might be many cases of this, and since Toshiba has
	  * worked around the "H00008000 -> -32768" bug (61688),
	  * it's better not to fix the code.  Note that it is
	  * difficult to check Toshiba's apps for potential overflow
	  * errors since expressions like "myInteger = C_SYS_F14"
	  * will cause the overflow.  So I'm unfixing this bug;
	  * once again, ul will be checked against 65535.
	  *					-jmagasin 11/15/96
	  *
	  *    If the low word's most significant bit is set, or
	  *    any bit in the high word is set, then use a dword
	  *    (or face the wrath of sign extension).
	  */
	/* if (ul & 0xFFFF8000) */
	 if (ul > 65535)
	 {
	     token.code = CONST_LONG;
	     token.data.long_int = ul;
	 }
	 else
	 {
	     token.code = CONST_INT;
	     token.data.integer = ul;
	 }

         break;
      }

   return token;
}


