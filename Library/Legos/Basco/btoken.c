/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		btoken.c

AUTHOR:		Roy Goldman, Dec 24, 1994

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	12/24/94   	Initial version.

DESCRIPTION:
	Token/opcode utilities

	$Id: btoken.c,v 1.1 98/10/13 21:42:26 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/

#include <Legos/legtype.h>
#include "btoken.h"
#include "faterr.h"




/*********************************************************************
 *			TokenIsKeyword
 *********************************************************************
 * SYNOPSIS:	
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	2/26/96  	Initial version
 * 
 *********************************************************************/
Boolean
TokenIsKeyword(TokenCode    tc)
{
    switch (tc)
    {
    case NOT:
    case AND:
    case OR:
    case XOR:
    case MOD:
    case BIT_AND:
    case BIT_OR:
    case BIT_XOR:
    case IF:
    case DO:
    case AS:
    case TO:
    case DIM:
    case REM:
    case LET:
    case END:
    case FOR:
    case SUB:
    case CASE:
    case NEXT:
    case EXIT:
    case LOOP:
    case LONG:
    case STEP:
    case THEN:
    case FLOAT:
    case WHILE:
    case UNTIL:
    case RESUME:
    case STRING:
    case SELECT:
    case STRUCT:
    case ONERROR:
    case FUNCTION:
    case COMPONENT:
    case COMPLEX:
    case EXPORT:
    case DEBUG:
    case MODULE:
    case GLOBAL:
    case CONSTANT:
    case REDIM:
    case PRESERVE:
	return TRUE;
    default:
	return FALSE;
    }
}

/*********************************************************************
 *			TokenToType
 *********************************************************************
 * SYNOPSIS:	convert a token to a type
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	jimmy	 5/11/95	Initial version
 * 
 *********************************************************************/
LegosType TokenToType(TokenCode c)
{
    switch(c) {
    case CONST_INT:
    case INTEGER:
	return TYPE_INTEGER;
    case CONST_LONG:
    case LONG:
	return TYPE_LONG;
    case CONST_FLOAT:
    case FLOAT:
	return TYPE_FLOAT;
    case CONST_STRING:
    case STRING:
	return TYPE_STRING;
    case STRUCT:
	return TYPE_STRUCT;
    case MODULE:
	return TYPE_MODULE;
    case COMPONENT:
	return TYPE_COMPONENT;
    case TYPENONE:
	return TYPE_NONE;
    case COMPLEX:
	return TYPE_COMPLEX;
    default:
	/* we should always have legal opcodes here */
#if ERROR_CHECK
	EC_ERROR(BE_FAILED_ASSERTION);
#endif
	return TYPE_ILLEGAL;
    }
}

/*********************************************************************
 *			TokenToOpCode
 *********************************************************************
 * SYNOPSIS:	Convert a compile time token into a virtual machine
 *              opcode.
 * CALLED BY:	
 * RETURN:
 * SIDE EFFECTS:
 * STRATEGY:
 * REVISION HISTORY:
 *	Name	Date		Description			     
 *	----	----		-----------			     
 *	roy	12/24/94	Initial version			     
 * 
 *********************************************************************/
Opcode TokenToOpCode(TokenCode c) {
    switch (c) {

        case DEBUG:
	    return TTOC(DEBUG);

        case CONST_INT:
	    return OP_INTEGER_CONST;

        case CONST_LONG:
	    return OP_LONG_CONST;

        case CONST_FLOAT:
	    return OP_FLOAT_CONST;

        case CONST_STRING:
	    return OP_STRING_CONST;

	case DIM:
	    return TTOC(DIM);

        case PLUS:
	    return OP_ADD;

        case MINUS:
	    return OP_SUB;

        case MULTIPLY:
	    return TTOC(MULTIPLY);

        case DIVIDE:
	    return TTOC(DIVIDE);

	case MOD:
	    return TTOC(MOD);

        case LESS_THAN:
	    return TTOC(LESS_THAN);

        case GREATER_THAN:
	    return TTOC(GREATER_THAN);

        case LESS_GREATER:
	    return TTOC(LESS_GREATER);

        case LESS_EQUAL:
	    return TTOC(LESS_EQUAL);

	case GREATER_EQUAL:
	    return TTOC(GREATER_EQUAL);

        case EQUALS:
	    return TTOC(EQUALS);

        case AND:
	    return TTOC(AND);

        case OR:
	    return TTOC(OR);

	case XOR:
	    return TTOC(XOR);

	case NOT:
	    return TTOC(NOT);

        case ASSIGN:
	    return TTOC(ASSIGN);

	case NEGATIVE:
	    return TTOC(NEGATIVE);

	case POSITIVE:
	    return TTOC(POSITIVE);
	
	default:
	    /* we should always have legal opcodes here */
#if ERROR_CHECK
	    EC_ERROR(-1);
#endif
	    return OP_ILLEGAL;
    }
}
