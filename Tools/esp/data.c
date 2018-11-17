/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1988-91 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Data Definition
 * FILE:	  data.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 25, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Data_Enter  	    Given a type description and an expression,
 *	    	    	    store the proper data in the current segment.
 *	Data_EncodeRecord   Set up things to encode a record initializer
 *	    	    	    as a series of AND, OR, and SHL operators
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/25/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for the definition of data.
 *
 *	Of all the functions in this file, only DataEnterSingle can be
 *	called on pass 2, and no function is called on passes 3 and 4
 *	(there being nothing to optimize or finalize as far as data go).
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: data.c,v 1.35 94/11/10 14:51:34 adam Exp $";
#endif lint

#if defined(__HIGHC__)
pragma Code("MYDATA");
#endif

#include    "esp.h"
#include    "scan.h"
#include    "parse.h"
#include    "data.h"
#include    "type.h"

#include    <ctype.h>

/*
 * State kept for complex initializations.
 */
typedef struct _DataState {
    struct _DataState	*next;	    /* Next in stack */
    TypePtr 	    	base;	    /* Base type being filled */
    Expr    	    	cur;	    /* Current piece */
    LexProc 	    	*yylex;	    /* Initial lex procedure */
    InputProc	    	*yyinput;   /* Initial input procedure */
    char    	    	*cp;	    /* Next character to return */
} DataState;

static DataState    *top;

static int DataParse(DataState *, LexProc *, InputProc *);


/***********************************************************************
 *				DataSkipInitializer
 ***********************************************************************
 * SYNOPSIS:	    Skip over a field in a structure initializer, handling
 *	    	    balancing of <>'s, ()'s and quotation marks.
 * CALLED BY:	
 * RETURN:	
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/19/90		Initial Revision
 *
 ***********************************************************************/
static char *
DataSkipInitializer(char    	**startPtr, /* Start of the field. Set to
					     * actual start of initializer
					     * (ignoring initial whitespace) */
		    ID	    	name,	    /* Name of field (for errors) */
		    ID	    	file,	    /* File from which expression
					     * springs */
		    int	    	line,	    /* Line at which expression was */
		    int	    	*blankPtr,  /* Place to store whether field
					     * is blank (may be null) */
		    char    	*savePtr)   /* Place to store field terminator
					     * that was replaced with a null
					     * byte */
{
    int	    angles; /* Unbalanced angle brackets */
    int	    parens; /* Unbalanced parens */
    char    quote;  /* Unmatched quotation mark
		     * (single/double) */
    char    save;   /* Field terminator to be replaced */
    int	    blank;  /* Non-zero if nothing but space in the field */
    char    *cp;    /* Internal ptr to initializer */
    char    *start; /* Actual start of the initializer, skipping leading
		     * whitespace */

    angles = parens = quote = save = 0;
    blank = 1;

    cp = start = *startPtr;
    
    while (*cp != '\0') {
	switch(*cp) {
	    case '<': blank=0; if (!quote) angles++; break;
	    case '>': blank=0; if (!quote) angles--; break;
	    case '(': blank=0; if (!quote) parens++; break;
	    case ')': blank=0; if (!quote) parens--; break;
	    case ',':
		if (!quote && !angles && !parens) {
		    save = ',';
		    *cp = '\0';
		    continue;
		}
		break;
	    case '\'':
	    case '"':
		blank=0;
		if (!quote) {
		    /*
		     * Enter quoted string
		     */
		    quote = *cp;
		} else if (quote == *cp) {
		    if (cp[1] == quote) {
			/*
			 * Doubled -- ignore both
			 */
			cp++;
		    } else {
			/*
			 * Done with string.
			 */
			quote=0;
		    }
		}
		break;
	    case ' ':
	    case '\t':
		/* Don't clear "blank" & advance start ptr */
		if (blank) {
		    start++;
		}
		break;
	    default:
		blank=0;
		break;
	}
	cp++;
    }
    if (angles) {
	Notify(NOTIFY_ERROR, file, line, "unbalanced < initializing field %i",
	       name);
	return ((char *)NULL);
    } else if (parens) {
	Notify(NOTIFY_ERROR, file, line, "unbalanced ( initializing field %i",
	       name);
	return ((char *)NULL);
    } else if (quote) {
	Notify(NOTIFY_ERROR, file, line,
	       "unterminated string constant initializing %i", name);
	return((char *)NULL);
    }

    if (blankPtr) {
	*blankPtr = blank;
    }
    if (savePtr) {
	*savePtr = save;
    }
    *startPtr = start;
    return(cp);
}

/******************************************************************************
 *
 *			   ARRAY CONVERSION
 *
 *****************************************************************************/
/***********************************************************************
 *				DataReturnEOF
 ***********************************************************************
 * SYNOPSIS:	    Wrapup function for defining from a string
 * CALLED BY:	    yystdlex
 * RETURN:	    1 to indicate that yystdlex should return 0 to parser
 * SIDE EFFECTS:    yywrap reset to yystdwrap
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
static int
DataReturnEOF(void)
{
    yywrap = yystdwrap;
    return(1);			/* Actually at end of file */
}

/***********************************************************************
 *				DataArrayString
 ***********************************************************************
 * SYNOPSIS:	    Return characters from a null-terminated string,
 *	    	    returning \n-EOF pair at the end
 * CALLED BY:	    yystdlex
 * RETURN:	    Next character
 * SIDE EFFECTS:    
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
static char
DataArrayString(void)
{
    inmacro = 1;		/* Don't increment yylineno */

    if (top->cp == NULL) {
	yywrap = DataReturnEOF;
	return(0);		/* Signal end-of-file */
    } else if (*top->cp == '\0') {
	top->cp = NULL;		/* Signal \n returned */
	return('\n');
    } else {
	return(*top->cp++);	/* Return next char */
    }
}


/***********************************************************************
 *				DataArrayStart
 ***********************************************************************
 * SYNOPSIS:	    Return initial token for defining an array
 * CALLED BY:	    yyparse
 * RETURN:	    PTYPE(base)
 * SIDE EFFECTS:    yylex set to yystdlex, yyinput to DataSingleString
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
static int
DataArrayStart(YYSTYPE	*yylval, ...)
{
    /*
     * Switch to reading input, using standard lexer, from the embedded string
     */
    top->cp = top->cur.elts[1].str;
    yylex = yystdlex;
    yyinput = DataArrayString;

    /*
     * Return a PTYPE of the base to start the definition off
     */
    yylval->type = top->base->tn_u.tn_array.tn_base;
    return(PTYPE);
}

/******************************************************************************
 *
 *			    	RECORD CONVERSION
 *
 *****************************************************************************/
/*
 * More complex. A record initializer is turned into an expression of the
 * following form:
 *
 *	( ((<value> SHL <offset>) FLDMASK <mask>) OR ... )
 *
 */
typedef struct {
    DataState	    	common;
    char		*fieldEnd;  /* End of initializer for current field */
    char    	    	save;	    /* Saved field delimiter */
    SymbolPtr	    	field;
    enum {
	DRS_FIRST_PAREN,	    /* Very first paren */
	DRS_FIRST_FIELD_PAREN,	    /* First paren for field */
	DRS_SECOND_FIELD_PAREN,	    /* Second paren for field */
	DRS_VALUE,  	    	    /* EXPR for empty field/value for
				     * non-empty field */
        DRS_SHL,    	    	    /* SHL token */
	DRS_OFFSET, 	    	    /* Bit offset (CONSTANT token) */
	DRS_FIRST_CLOSE_PAREN,	    /* Close paren after offset */
	DRS_FMASK,    	    	    /* FLDMASK token */
	DRS_MASK,   	    	    /* Field mask (CONSTANT token) */
	DRS_CLOSE_PAREN,    	    /* Closing paren for field */
	DRS_TWEEN,  	    	    /* Between fields -- if next sym is
				     * a bitfield, return OR, else return
				     * final closing paren */
	DRS_DONE,   	    	    /* Complete -- return \n or reset and
				     * call yylex */
	DRS_EOF,    	    	    /* defvar complete -- return EOF */
    }	    	    	state;	/* Current state */
    int	    	    	flags;	
#define DRS_DEF_VAR 	    1	/* Non-zero if defining a variable (i.e.
				 * parse caused by Data_Enter, not
				 * Data_EncodeRecord) */
#define DRS_WARNED  	    2	/* Non-zero if not defining a variable,
				 * warn_record is set, not all fields were
				 * given, and a warning has already been
				 * given */
#define DRS_NESTED  	    4	/* Non-zero if handling a nested record */
} DataRecordState;


static int DataRecordContinue(YYSTYPE  *yylval, ...);

/***********************************************************************
 *				DataRecordNotEOF
 ***********************************************************************
 * SYNOPSIS:	    Wrapup function for defining field value from a string
 * CALLED BY:	    yystdlex
 * RETURN:	    0 to indicate that yystdlex should recurse
 * SIDE EFFECTS:    yywrap reset to yystdwrap
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 1/89		Initial Revision
 *
 ***********************************************************************/
static int
DataRecordNotEOF(void)
{
    yywrap = yystdwrap;
    yylex = DataRecordContinue;
    return(0);			/* Not at end-of-file -- recurse */
}

/***********************************************************************
 *				DataRecordValue
 ***********************************************************************
 * SYNOPSIS:	    Return the next character from a bitfield initializer
 *	    	    string.
 * CALLED BY:	    yystdlex
 * RETURN:	    The next character or 0 if hit null or ,
 * SIDE EFFECTS:    yywrap will be set to DataReturnNotEOF if returning 0
 *
 * STRATEGY:	    If not at the end of the value, return the next
 *		    character
 *	    	    Else, revector yywrap to DataReturnNotEOF to have it
 *	    	    tell yystdlex to recurse and to revector yylex
 *	    	    back to DataRecordContinue, the idea being that when
 *	    	    defining a variable (DRS_DEF_VAR is true), we really
 *	    	    want to tell the parser it can quit, but when encoding a
 *	    	    record operand, we don't. DataReturnNotEOF will be called
 *	    	    only after the 0 we're returning has really been
 *	    	    processed, as opposed to being read and pushed back.
 *		    When we know this is true, we can decide whether the
 *		    parser should return or keep going.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 2/89		Initial Revision
 *
 ***********************************************************************/
static char
DataRecordValue(void)
{
    DataRecordState	*drs = (DataRecordState *)top;

    if (drs->state == DRS_VALUE) {
	if (*top->cp != '\0') {
	    return(*top->cp++);
	}
	/*
	 * Hit end of field -- switch to DRS_SHL state so we know next time
	 * to return EOF, then return closing paren for initializer.
	 * If we just returned an initializer for a nested record, return
	 * EOF now, as there was no open-paren we need to match.
	 */
	drs->state = DRS_SHL;
	if ((drs->flags & DRS_NESTED) == 0) {
	    return(')');
	}
    }
    /*
     * Done with this field -- return 0 now to signal end of parse and make
     * yystdlex recurse when it calls yywrap.
     */
    yywrap = DataRecordNotEOF;
    return(0);
}
	
    

/***********************************************************************
 *				DataRecordContinue
 ***********************************************************************
 * SYNOPSIS:	    Return the next token for a record constant
 * CALLED BY:	    yyparse
 * RETURN:	    Proper token
 * SIDE EFFECTS:    yylex will be set to yystdlex if state is DRS_VALUE
 *	    	    and top->cp doesn't point to a comma or null byte
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 2/89		Initial Revision
 *
 ***********************************************************************/
static int
DataRecordContinue(YYSTYPE  *yylval, ...)
{
    DataRecordState *drs = (DataRecordState *)top;

    switch(drs->state) {
	case DRS_FIRST_PAREN:
	    drs->state = DRS_FIRST_FIELD_PAREN;
	    return('(');
	case DRS_FIRST_FIELD_PAREN:
	    drs->state = DRS_SECOND_FIELD_PAREN;
	    return('(');
	case DRS_SECOND_FIELD_PAREN:
	    drs->state = DRS_VALUE;
	    return('(');
	case DRS_VALUE:
	{
	    int	    blank = 1;

	    /*
	     * Put back any field terminator biffed by DataSkipInitializer,
	     * causing our string pointer to advance over it.
	     */
	    if (drs->field->name != NullID) {
		if (drs->fieldEnd != NULL) {
		    if (drs->save) {
			*drs->fieldEnd = drs->save;
			drs->common.cp++;
		    } else if (warn_record &&
			       !(drs->flags & (DRS_WARNED|DRS_DEF_VAR)))
		    {
			Notify(NOTIFY_WARNING,
			       drs->common.cur.file,
			       drs->common.cur.line,
			       "incomplete record initializer");
			drs->flags |= DRS_WARNED;
		    }
		}
		
		drs->fieldEnd = DataSkipInitializer(&drs->common.cp,
						    drs->field->name,
						    drs->common.cur.file,
						    drs->common.cur.line,
						    &blank,
						    &drs->save);
		/*
		 * If error in initializer, return EOF so we bail out.
		 */
		if (drs->fieldEnd == NULL) {
		    return(0);
		}
	    }

	    if (!blank) {
		/*
		 * Field in initializer non-empty -- use yystdlex to
		 * extract fields from it. DataRecordValue returns chars
		 * until it encounters a comma or a null. We return an initial
		 * open paren so there's no conflict between operators
		 * in the initializer and the SHL operator we use...
		 *
		 * Note that DataRecordValue does the switch to SHL for us,
		 * allowing it to use the current state to figure whether to
		 * return ) or EOF when it's done with the field.
		 */
		yylex = yystdlex;
		yyinput = DataRecordValue;
		if ((drs->field->u.bitField.type != NULL) &&
		    (drs->field->u.bitField.type->tn_type == TYPE_STRUCT) &&
		    (drs->field->u.bitField.type->tn_u.tn_struct->type==
		     SYM_RECORD) &&
		    (*drs->common.cp == '<'))
		{
		    /*
		     * Field is a nested record initialized with a <> string, so
		     * we need to turn the thing into a record-initializer by
		     * returning RECORD_SYM before we return the nested
		     * initializer itself.
		     * 10/31/91: We must also set defStruct true so <> is
		     * returned as STRUCT_INIT, not STRING...
		     */
		    yylval->sym = drs->field->u.bitField.type->tn_u.tn_struct;
		    drs->flags |= DRS_NESTED;
		    defStruct = TRUE;
		    return(RECORD_SYM);
		} else {
		    drs->flags &= ~DRS_NESTED;
		    return('(');
		}
	    } else {
		/*
		 * No value given -- use default value, returned as an EXPR
		 * token, and switch to SHL state.
		 */
		yylval->expr = drs->field->u.bitField.value;
		drs->state = DRS_SHL;
		return(EXPR);
	    }
	}
	case DRS_SHL:
	    drs->state = DRS_OFFSET;
	    return(SHL);
	case DRS_OFFSET:
	    yylval->number = drs->field->u.bitField.offset;
	    drs->state = DRS_FIRST_CLOSE_PAREN;
	    return(CONSTANT);
	case DRS_FIRST_CLOSE_PAREN:
	    drs->state = DRS_FMASK;
	    return(')');
	case DRS_FMASK:
	    drs->state = DRS_MASK;
	    return(FLDMASK);
	case DRS_MASK:
	    yylval->number = ((1 << (drs->field->u.bitField.offset+
				     drs->field->u.bitField.width)) -
			      (1 << drs->field->u.bitField.offset));
	    drs->state = DRS_CLOSE_PAREN;
	    return(CONSTANT);
	case DRS_CLOSE_PAREN:
	    /*
	     * Done with field -- advance to next, skipping nameless fields.
	     */
	    do {
		drs->field = drs->field->u.eltsym.next;
	    } while (drs->field->name == NullID);
	    drs->state = DRS_TWEEN;
	    return(')');
	case DRS_TWEEN:
	    if (drs->field->type == SYM_BITFIELD) {
		/*
		 * Another field -- set to return open paren next time and
		 * return the requisite OR operator now...
		 */
		drs->state = DRS_FIRST_FIELD_PAREN;
		return(OR);
	    } else {
		/*
		 * Record complete -- return final closing paren and indicate
		 * should return EOF on next call
		 */
		drs->state = DRS_DONE;
		return(')');
	    }
	case DRS_DONE:
	    /*
	     * The initializer should point to the end of the string now.
	     * If it doesn't the user gave too many fields in the initializer,
	     * possibly because s/he gave one for a nameless field.
	     * drs->field points to the record type again, so we can use
	     * that to get the name for the warning...
	     */
	    if (*top->cp != '\0') {
		yywarning("extra fields in initializer for %i",
			  drs->field->name);
	    }
	    if (drs->flags & DRS_DEF_VAR) {
		/*
		 * Each initializer done on its own "line" -- set to EOF
		 * state and return a newline token to signal end of the
		 * road.
		 */
		drs->state = DRS_EOF;
		return('\n');
	    } else {
		/*
		 * Parse started by Data_EncodeRecord -- restore state,
		 * popping current state and freeing it, then recurse
		 * to return the next token.
		 */
		yylex = top->yylex;
		yyinput = top->yyinput;
		Scan_RestorePB();
		top = top->next;
		free((char *)drs);
		return(yylex(yylval));
	    }
	case DRS_EOF:
	    /*
	     * Tell parser to return
	     */
	    return(0);
	default:
	    assert(0);
	    return(0);
    }
}
	    

/***********************************************************************
 *				DataRecordStart
 ***********************************************************************
 * SYNOPSIS:	    Begin the definition of a record variable
 * CALLED BY:	    yyparse
 * RETURN:	    DEF(size)
 * SIDE EFFECTS:    yylex set to DataRecordContinue, top->state altered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 2/89		Initial Revision
 *
 ***********************************************************************/
static int
DataRecordStart(YYSTYPE *yylval, ...)
{
    DataRecordState *drs = (DataRecordState *)top;
    SymbolPtr	    sym;

    sym = drs->common.base->tn_u.tn_struct;
    
    drs->common.cp = drs->common.cur.elts[1].str;
    drs->field = sym->u.record.first;
    drs->fieldEnd = NULL;
    drs->state = DRS_FIRST_PAREN;

    yylex = DataRecordContinue;

    yylval->number = drs->common.base->tn_u.tn_struct->u.record.common.size;
    return(DEF);
}
/******************************************************************************
 *
 *			 STRUCTURE CONVERSION
 *
 *****************************************************************************/
/*
 * Structure variable definition. Need to keep track of the current field
 * and the end of the initializer
 */
typedef struct {
    DataState	    common;
    char    	    *end;   	/* End of the current initializer */
    SymbolPtr	    field;  	/* Field being defined */
} DataStructState;


/***********************************************************************
 *				DataFieldInput
 ***********************************************************************
 * SYNOPSIS:	    Return the next character from a field initializer
 * CALLED BY:	    yystdlex
 * RETURN:	    The next char or \n or 0
 * SIDE EFFECTS:    yywrap may be set to DataReturnEOF
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 2/89		Initial Revision
 *
 ***********************************************************************/
static char
DataFieldInput(void)
{
    DataStructState *dss = (DataStructState *)top;

    if (top->cp == NULL) {
	yywrap = DataReturnEOF;
	return(0);
    } else if (top->cp == dss->end) {
	/*
	 * Return newline to signal the end of the definition and set up
	 * to return EOF next time we're called
	 */
	inmacro = TRUE;		/* Don't up yylineno */
	top->cp = NULL;
	return('\n');
    } else {
	return(*top->cp++);
    }
}
	

/***********************************************************************
 *				DataFieldStart
 ***********************************************************************
 * SYNOPSIS:	    Begin the definition of a structure field
 * CALLED BY:	    yyparse
 * RETURN:	    PTYPE(field type)
 * SIDE EFFECTS:    yyinput set to DataFieldInput, yylex to yystdlex
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 2/89		Initial Revision
 *
 ***********************************************************************/
static int
DataFieldStart(YYSTYPE *yylval, ...)
{
    yylex = yystdlex;
    yyinput = DataFieldInput;
    
    yylval->type = top->base;
    return(PTYPE);
}
	


/***********************************************************************
 *				DataEnterStruct
 ***********************************************************************
 * SYNOPSIS:	    Enter elements that are structures
 * CALLED BY:	    Data_Enter
 * RETURN:	    TRUE if no errors
 * SIDE EFFECTS:    dot is advanced...
 *
 * STRATEGY:
 *	For each initializer
 *	    - make sure it's a string
 *	    - for each field in the structure
 *	    	- extract its initializer (all characters from current
 *		  pos to next comma, balancing <>'s, ()'s and strings in
 *	    	  single or double quotes.
 *	    	- if initializer empty, call Data_Enter for the field,
 *	    	  using the value stored in the field symbol.
 *	    	- else use the parser to set up the field by causing
 *		  it to see PTYPE(field) followed by the initializer.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 8/89		Initial Revision
 *
 ***********************************************************************/
static int
DataEnterStruct(TypePtr	    type,
		Expr	    *expr,
		int 	    maxElts)
{
    /*
     * This one's somewhat more interesting than
     * SYM_RECORD because the individual pieces have their
     * own types,
     */
    SymbolPtr	    field;
    Expr    	    cur;    /* Current structure */
    DataStructState dss;
    char    	    *cp,    /* General pointer into init */
		    *init;  /* Initializer for current field */
    int 	    retval = TRUE;
    int		    base;
    
    cur.elts = NULL;
    
    do {
	Expr_NextPart(expr, &cur, FALSE);
	if (cur.numElts == 0) {
	    /*
	     * All done...
	     */
	    return(retval);
	}
	
	if (cur.elts[0].op != EXPR_INIT) {
	    Notify(NOTIFY_ERROR, cur.file, cur.line,
		   "structure %i not initialized with <>-string",
		   type->tn_u.tn_struct->name);
	    retval = FALSE;
	} else if (type->tn_u.tn_struct->u.sType.first) {
	    int	    dest;
	    
	    cp = cur.elts[1].str;
	    base = dot;
	    dest = dot + type->tn_u.tn_struct->u.sType.common.size;

	    for (field = type->tn_u.tn_struct->u.sType.first;
		 field->type != SYM_STRUCT;
		 field = field->u.eltsym.next)
	    {
		char    save;   /* End delimiter (, or \0) */
		int	blank;
		Expr    *value;
		TypePtr	type;
		int 	offset;

		if (field->type == SYM_FIELD) {
		    value = 	field->u.field.value;
		    type =  	field->u.field.type;
		    offset = 	field->u.field.offset;
		} else {
		    value = 	field->u.instvar.value;
		    type =  	field->u.instvar.type;
		    offset = 	field->u.instvar.offset;
		}

		if (value == NULL) {
		    /*
		     * Fake field (i.e. just a label) -- do nothing.
		     */
		    continue;
		}
		
		init = cp;	/* Here to avoid gcc warning */
		if (field->name != NullID) {
		    /*
		     * Find the end of the initializer, making sure
		     * all angle brackets, parens and quotation marks
		     * balance. At the end, cp points to the nulled-out
		     * terminating comma (if save is ',') or the final
		     * null character (if save is 0). blank is set
		     * 0 if any non-space character occurs between
		     * init and cp. angles, parens and quote should
		     * all be back to zero when done.
		     */
		    cp = DataSkipInitializer(&init, field->name, cur.file,
					     cur.line, &blank, &save);
		    if (cp == (char *)NULL) {
			/*
			 * Error in the initializer -- bail out now.
			 */
			retval = FALSE;
			break;
		    }
		    /*
		     * HACK: To initialize the default window and gstates
		     * easily, we take an initializer of {} for a structure
		     * field as meaning the field should be completely ignored.
		     * This involves reducing the address we expect to reach
		     * when done with this structure and the start of the
		     * structure (so any non-skipped fields that follow will
		     * be defined immediately after the last field w/o the {}
		     * initializer), as well as getting to the end of the loop
		     * quickly.
		     */
		    if (strcmp(init, "{}") == 0) {
			int skipSize = Type_Size(type);
			
			dest -= skipSize;
			base -= skipSize;
			if (save) {
			    *cp++ = save;
			}
			continue;
		    }
		} else {
		    /*
		     * Nameless fields get their default value and cannot
		     * be otherwise initialized. To signal this, proclaim the
		     * initializer for the field to be blank and set "save"
		     * to zero so we don't advance cp (fools it into thinking
		     * we hit the end of the initializer string)
		     */
		    blank = 1; save = 0;
		}
		/*
		 * Deal with alignment directives in the structure by
		 * forcing dot to be the proper offset for the field from
		 * the base.
		 */
		dot = base + offset;

		if (blank) {
		    /*
		     * If initializer is empty, just recurse
		     * using the default value. No need to give maxElts,
		     * as it comes from the value or, if field's an array, will
		     * be checked in Data_Enter. Note: need to make sure
		     * retval stays FALSE if set FALSE for earlier field and
		     * gets set FALSE if error in this field.
		     */
		    if (type->tn_type == TYPE_ARRAY) {
			/*
			 * If the field is labeled as an array, it is because
			 * there were multiple elements given. Since the
			 * elements weren't all in a string, we can't
			 * just pass the type to Data_Enter. Rather, we
			 * need to do what we would have done had this
			 * just been a variable declaration -- give the
			 * value to Data_Enter but tell it the base type
			 * of the array, not the array itself.
			 */
			retval = !(!Data_Enter(&dot,
					       type->tn_u.tn_array.tn_base,
					       value,
					       0) || !retval);
		    } else {
			retval = !(!Data_Enter(&dot, type, value,
					       0) || !retval);
		    }
		} else {
		    /*
		     * The punt mode. Theoretically, for array fields,
		     * we ought to allow the dude to default individual
		     * elements. To do this, we'd have to scan through
		     * the initializer and the default value component
		     * by component. Not too rough, but I don't want
		     * to spend the time right now. So instead, we
		     * just use the parser to define the field using the
		     * given initializer and set any uninitialized bytes
		     * of the field to 0.
		     */
		    int startDot = dot;
		    int undefined;
			
		    /*
		     * Record start and end of initializer
		     */
		    dss.common.cp = init;
		    dss.end = cp;
		    dss.common.base = type;
			
		    if (DataParse((DataState *)&dss, DataFieldStart, yyinput)){
			/*
			 * Fill in un-initialized bytes in the field and
			 * bounds check.
			 */
			undefined = Type_Size(type) - (dot - startDot);
			
			if (undefined > 0) {
			    /*
			     * If bytes left in field, store that many blank
			     * elements.
			     */
			    Table_StoreZeroes(curSeg->u.segment.code, undefined,
					      dot);
			} else if (undefined < 0) {
			    /*
			     * If undefined < 0, the number of bytes allocated
			     * since we started is too large -- print an error
			     * message. There's no point in deleting the
			     * elements as we'll reset dot down below.
			     */
			    Notify(NOTIFY_ERROR, cur.file, cur.line,
				   "too many bytes allocated in field %i",
				   field->name);
			}
		    } else {
			Notify(NOTIFY_ERROR, cur.file, cur.line,
			       "error initializing field %i", field->name);
			retval = FALSE;
		    }
		}

		/*
		 * Adjust cp to start of next initializer, replacing the
		 * delimiter (just in case).
		 */
		if (save) {
		    *cp++ = save;
		}
	    }
	    if (cp != NULL) {
		/*
		 * Allow trailing spaces...
		 */
		while (isspace(*cp)) {
		    cp++;
		}
		if (*cp != '\0') {
		    Notify(NOTIFY_WARNING, cur.file, cur.line,
			   "extra fields in initializer for %i ignored",
			   field->name);
		}
	    }
	    dot = dest;
	} else {
	    Notify(NOTIFY_ERROR, expr->file, expr->line,
		   "cannot initialize empty structure %i",
		   type->tn_u.tn_struct->name);
	    return(FALSE);
	}
    } while (--maxElts != 0);

    Expr_NextPart(expr, &cur, FALSE);
    if (cur.numElts != 0) {
	Notify(NOTIFY_ERROR, expr->file, expr->line,
	       "too many elements in array");
	retval=FALSE;
    }
    return(retval);
}

/***********************************************************************
 *				DataEnterUnion
 ***********************************************************************
 * SYNOPSIS:	    Enter elements that are unions
 * CALLED BY:	    Data_Enter
 * RETURN:	    TRUE if no errors
 * SIDE EFFECTS:    dot is advanced...
 *
 * STRATEGY:
 *	A union initializer looks like:
 *	    <field> <initializer>
 *	inside angle-brackets, of course. We simply map the <field> to
 *	its data type and perform initialization as for a structure
 *	field, padding the segment out with zeroes to the size of
 *	the whole union. <initializer> is the sort of initializer expected
 *	by the data type.
 *
 *	If the union-initializer is blank, we just fill the whole space
 *	with zero. WE DO NOT USE ANY OF THE DEFAULT VALUES SO NICELY
 *	BOUND INTO THE FIELDS OF THE UNION. The problem of which to enter
 *	first, &c., is too cumbersome to be solved to everyone's satsifaction
 *	without somehow designating one of the fields as the primary.
 *	If someone wants a particular field initialized when the union
 *	is in a structure, he or she should specify that in the default
 *	initializer for that structure field.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 8/89		Initial Revision
 *
 ***********************************************************************/
static int
DataEnterUnion(TypePtr	    type,
	       Expr	    *expr,
	       int 	    maxElts)
{
    SymbolPtr	    field;
    Expr    	    cur;    /* Current structure */
    DataStructState dss;
    char    	    *cp,    /* General pointer into init */
		    *init;  /* Initializer for current field */
    int 	    retval = TRUE;
    int		    base;
    
    cur.elts = NULL;
    
    do {
	Expr_NextPart(expr, &cur, FALSE);
	if (cur.numElts == 0) {
	    /*
	     * All done...
	     */
	    return(retval);
	}
	
	if (cur.elts[0].op != EXPR_INIT) {
	    Notify(NOTIFY_ERROR, cur.file, cur.line,
		   "union %i not initialized with <>-string",
		   type->tn_u.tn_struct->name);
	    retval = FALSE;
	} else if (type->tn_u.tn_struct->u.sType.first) {
	    char    *fname;
	    ID	    fid;
	    char    save;   /* End delimiter (, or \0) */
	    int	    blank;
	    

	    cp = cur.elts[1].str;
	    base = dot;

	    /*
	     * Find which field of the union is being initialized by taking
	     * the first part of our initializer and seeing if there's a field
	     * in the union of that name.
	     */
	    while (isspace(*cp)) {
		cp++;
	    }
	    fname = cp;
	    while (*cp != '\0' && !isspace(*cp)) {
		cp++;
	    }

	    if (cp != fname) {
		fid = ST_Lookup(output, symStrings, fname, cp - fname);

		if (fid == NullID) {
		    Notify(NOTIFY_ERROR, cur.file, cur.line,
			   "union field %.*s not known", cp - fname, fname);
		    retval = FALSE;
		    continue;
		} else {
		    /*
		     * Search the permanent table too and see if it's there
		     * as well, using that version in preference to the
		     * temporary, as the field will be doing so too.
		     */
		    ID	pid = ST_DupNoEnter(output, fid, output, permStrings);
		    if (pid != NullID) {
			fid = pid;
		    }
		}

		for (field = type->tn_u.tn_struct->u.sType.first;
		     field->type != SYM_UNION;
		     field = field->u.eltsym.next)
		{
		    if (field->name == fid) {
			break;
		    }
		}

		if (field->name != fid) {
		    Notify(NOTIFY_ERROR, cur.file, cur.line,
			   "%i not a field in union", fid);
		    continue;
		}
		    
		/*
		 * Well, now we know what field we're initializing. Look for the
		 * end of the initializer.
		 */
		init = cp;

		cp = DataSkipInitializer(&init, field->name, cur.file,
					 cur.line, &blank, &save);
		
		if (cp == (char *)NULL) {
		    /*
		     * Error in the initializer -- skip this one
		     */
		    retval = FALSE;
		    continue;
		}

		if (blank) {
		    /*
		     * If initializer is empty, just recurse
		     * using the default value. No need to give maxElts,
		     * as it comes from the value or, if field's an array, will
		     * be checked in Data_Enter. Note: need to make sure
		     * retval stays FALSE if set FALSE for earlier field and
		     * gets set FALSE if error in this field.
		     */
		    TypePtr type = field->u.field.type;

		    if (type->tn_type == TYPE_ARRAY) {
			/*
			 * If the field is labeled as an array, it is because
			 * there were multiple elements given. Since the
			 * elements weren't all in a string, we can't
			 * just pass the type to Data_Enter. Rather, we
			 * need to do what we would have done had this
			 * just been a variable declaration -- give the
			 * value to Data_Enter but tell it the base type
			 * of the array, not the array itself.
			 */
			retval = !(!Data_Enter(&dot,
					       type->tn_u.tn_array.tn_base,
					       field->u.field.value,
					       0) || !retval);
		    } else {
			retval = !(!Data_Enter(&dot,
					       field->u.field.type,
					       field->u.field.value,
					       0) || !retval);
		    }
		} else {
		    /*
		     * The punt mode. Theoretically, for array fields,
		     * we ought to allow the dude to default individual
		     * elements. To do this, we'd have to scan through
		     * the initializer and the default value component
		     * by component. Not too rough, but I don't want
		     * to spend the time right now. So instead, we
		     * just use the parser to define the field using the
		     * given initializer and set any uninitialized bytes
		     * of the field to 0.
		     */
		    int startDot = dot;
		    int undefined;
		    
		    /*
		     * Record start and end of initializer
		     */
		    dss.common.cp = init;
		    dss.end = cp;
		    dss.common.base = field->u.field.type;
		    
		    if (DataParse((DataState *)&dss, DataFieldStart, yyinput)){
			/*
			 * Just make sure the value didn't overstep the bounds
			 * of the field -- zero-fill will be taken care of for
			 * the whole union in a moment.
			 */
			undefined = Type_Size(field->u.field.type) -
			    (dot - startDot);
			
			if (undefined < 0) {
			    /*
			     * If undefined < 0, the number of bytes allocated
			     * since we started is too large -- print an error
			     * message. There's no point in deleting the
			     * elements as we'll reset dot down below.
			     */
			    Notify(NOTIFY_ERROR, cur.file, cur.line,
				   "too many bytes allocated in union field");
			}
			/*
			 * Now zero-pad the union out to its full size.
			 */
			undefined = Type_Size(type) - (dot - startDot);
			if (undefined > 0) {
			    Table_StoreZeroes(curSeg->u.segment.code, undefined,
					      dot);
			}
		    } else {
			retval = FALSE;
		    }

		    /*
		     * Replace the delimiter (just in case).
		     */
		    if (save) {
			*cp++ = save;
		    }
		}
	    } else {
		/*
		 * If initializer is empty, we need to zero-fill the area,
		 * since we have no way to choose between the different fields.
		 */
		int	size = Type_Size(type);
		
		Table_StoreZeroes(curSeg->u.segment.code, size, dot);
	    }
	    dot = base + type->tn_u.tn_struct->u.sType.common.size;
	} else {
	    Notify(NOTIFY_ERROR, expr->file, expr->line,
		   "cannot initialize empty union %i",
		   type->tn_u.tn_struct->name);
	    return(FALSE);
	}
    } while (--maxElts != 0);

    Expr_NextPart(expr, &cur, FALSE);
    if (cur.numElts != 0) {
	Notify(NOTIFY_ERROR, expr->file, expr->line,
	       "too many elements in array");
	retval=FALSE;
    }
    return(retval);
}
	
/******************************************************************************
 *
 *		       UTILITIES FOR Data_Enter
 *
 *****************************************************************************/

/***********************************************************************
 *				DataParse
 ***********************************************************************
 * SYNOPSIS:	    Given a state block, a lexical analyzer function
 *	    	    and an input function, call the parser recursively
 *	    	    to parse an initializer
 * CALLED BY:	    Data_Enter
 * RETURN:	    TRUE if parsing successful
 * SIDE EFFECTS:    Oh, here and there.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 8/89		Initial Revision
 *
 ***********************************************************************/
static int
DataParse(DataState *state,
	  LexProc   *newyylex,
	  InputProc *newyyinput)
{
    int parseRes;	    /* Result of parse */

    /*
     * Save current lex and input procedures & hide pushback
     */
    state->yylex = yylex;
    state->yyinput = yyinput;
    Scan_SavePB();
    
    /*
     * Push to new state
     */
    state->next = top;
    top = state;
    
    /*
     * Set to proper procedures
     */
    yylex = newyylex;
    yyinput = newyyinput;
    
    /*
     * Parse the definition.
     */
    parseRes = yyparse();
    
    /*
     * Restore lex and input procs and pop state
     */
    yylex = state->yylex;
    yyinput = state->yyinput;
    top = state->next;
    Scan_RestorePB();

    return(!parseRes);
}

/*
 * Field constants for the datum that is passed to DataEnterSingle, since
 * the compiler won't let us convert a really small structure to a pointer
 * or vice-versa, and we only have one longword of data available to us.
 */
#define DESD_SIZE_MASK	    	0x00000007    	/* Size of data to enter */
#define DESD_SIZE_SHIFT	    	0
#define DESD_CHUNK_ONLY_MASK	0x00000008  	/* Only a chunk symbol or 0
						 * will do */
#define DESD_CHUNK_ONLY_SHIFT	3
#define DESD_FIX_TYPE_MASK  	0x000000f0  	/* Type of external fixup to
						 * register */
#define DESD_FIX_TYPE_SHIFT 	4
#define DESD_NO_STRING_MASK 	0x00000100
#define DESD_NO_STRING_SHIFT	8

#define DESD_SIZE(data)	    	\
    ((((unsigned int)(data)) & DESD_SIZE_MASK) >> DESD_SIZE_SHIFT)
#define DESD_CHUNK_ONLY(data)	\
    (((unsigned int)(data)) & DESD_CHUNK_ONLY_MASK)
#define DESD_FIX_TYPE(data) 	\
    ((((unsigned int)(data)) & DESD_FIX_TYPE_MASK) >> DESD_FIX_TYPE_SHIFT)
#define DESD_NO_STRING(data) 	\
    ((((unsigned int)(data)) & DESD_NO_STRING_MASK) >> DESD_NO_STRING_SHIFT)

/***********************************************************************
 *				DataEnterSingle
 ***********************************************************************
 * SYNOPSIS:	    Enter a single piece of machine data.
 * CALLED BY:	    DataEnterInt, Fixup module
 * RETURN:	    FR_DONE or FR_ERROR, *addrPtr advanced beyond data
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/30/89		Initial Revision
 *
 ***********************************************************************/
static FixResult
DataEnterSingle(int 	*addrPtr,   /* IN/OUT: Address of instruction start */
		int 	prevSize,   /* # bytes previously allocated to datum */
		int 	pass,       /* Current pass (1 or 2) */
		Expr	*expr1,     /* Value to store */
		Expr	*expr2,	    /* NULL */
		Opaque	data)	    /* Special stuff */
{
    byte    	*val;	    	/* Buffer for value, based on size of elt */
    ExprResult  result; 	/* Result of evaluating expr1 */
    byte    	status; 	/* Status of same */
    int	    	size;	    	/* Size of data to enter */
    FixResult	retcode = FR_DONE;

    size = DESD_SIZE(data);
    val = (byte *)malloc(size);
    
    /*
     * Another element to stuff. Wheee.
     */
    if (!Expr_Eval(expr1, &result,
		   ((pass>1) ? EXPR_NOUNDEF : 0) |
		   ((pass==4) ? EXPR_FINALIZE : 0) |
		   (DESD_FIX_TYPE(data) ? EXPR_DATA_ENTER : 0) |
		   EXPR_NOT_OPERAND,
		   &status))
    {
	/*
	 * Error in piece -- print error message.
	 */
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       (char *)result.type);
	retcode = FR_ERROR;
    } else if (((status & EXPR_STAT_DEFINED) == 0) ||
	       (status & EXPR_STAT_DELAY))
    {
	/*
	 * Enter fixup for undefined or final, depending on delay
	 * status of the expression, w/copy of expr. DELAY takes precedence
	 * since we couldn't actually do anything but catch errors if there's
	 * something undefined if DELAY is set, so might as well save a
	 * call and evaluation and just wait for the final pass.
	 */
	Fix_Register((status & EXPR_STAT_DELAY) ? FC_FINAL : FC_UNDEF,
		     DataEnterSingle, *addrPtr, size,
		     expr1, expr2, data);
	
	/*
	 * Store junk there for now (want to expand the table if nec'y)
	 */
	Table_Store(curSeg->u.segment.code, size,
		    val, *addrPtr);
	*addrPtr += size;
    } else if (result.type == EXPR_TYPE_STRING) {
	int len = strlen(result.data.str);
	
	if (DESD_NO_STRING(data)) {
	    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		   "variable may not be initialized with a string");
	    retcode = FR_ERROR;
	} else if (size == 1 || (size == 2 && dbcsRelease)) {
	    /*
	     * Want to store the string whole...
	     */
	    if (prevSize > 0 && len > prevSize) {
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "string too long to fit in %d byte%s remaining",
		       prevSize, prevSize == 1 ? "" : "s");
		retcode = FR_ERROR;
	    } else {
		if (size == 1) {
		    Table_Store(curSeg->u.segment.code,
				len,
				result.data.str,
				*addrPtr);
		    *addrPtr += len;
		} else {
		    int i;
		    char dbcs[2];

		    for (i = 0; i < len; i++) {
			dbcs[0] = result.data.str[i];
			dbcs[1] = '\0';
			Table_Store(curSeg->u.segment.code,
				    2,
				    &dbcs,
				    *addrPtr);
			*addrPtr += 2;
		    }
		}
	    }
	} else {
	    char    *cp;	/* Pointer to result string */
	    byte    *bp;	/* Pointer into value to store */
	    
	    if (len > size) {
		Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		       "string constant '%s' longer than data element (%d bytes) -- truncating",
		       result.data.str, size);
		len = size;
	    }
	    
	    /*
	     * Store the string in the proper order, ending up with
	     * bp pointing after all characters so we can zero the
	     * remaining bytes.
	     */
	    if (masmCompatible || reverseString) {
		/*
		 * For reasons unknown to me, MASM likes to put
		 * the *last* character of the constant first
		 * in memory...
		 */
		for (cp = result.data.str+len, bp=val;
		     cp != result.data.str;
		     *bp++ = (byte)*--cp)
		{
		    ;
		}
	    } else {
		/*
		 * Store the chars in the same order as
		 * if this were a string.
		 */
		for (cp=result.data.str, bp=val;
		     cp != result.data.str+len;
		     *bp++ = (byte)*cp++)
		{
		    ;
		}
	    }
	    /*
	     * Any unused bytes are 0
	     */
	    while (bp != val+size) {
		*bp++ = 0;
	    }
	    Table_Store(curSeg->u.segment.code,
			size,
			val,
			*addrPtr);
	    *addrPtr += size;
	}
    } else if (result.type == EXPR_TYPE_CONST) {
	long        	mask;	/* Permissible bits */
	unsigned long	v;  	/* Copy of value for extracting bytes*/
	int 	    	i;  	/* Byte counter */
	byte	    	*bp;	/* Pointer into value to store */
	
	if (DESD_CHUNK_ONLY(data) && result.data.number != 0) {
	    /*
	     * Can't be a chunk or it wouldn't be constant
	     */
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "should be initialized with 0 or a \"chunk\" symbol");
	}
	/*
	 * Figure mask of permissible bits based on size
	 */
	mask = (1 << (size*8))-1;
	
	/*
	 * Value is permissible if there are no bits set outside the mask
	 * (first clause) or the bits outside the mask are all 1 and the
	 * highest bit of the value (determined by the final clause) is
	 * 1.
	 */
	if ((size != 4) &&
	    (result.data.number & ~mask) &&
	    (((result.data.number & ~mask) != ~mask) ||
	     ((result.data.number & (mask ^ (mask >> 1))) == 0)))
	{
	    /*
	     * Bits outside mask not a sign-extension of lower
	     * part -- warn the user of this, but keep going.
	     */
	    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
		   "value (%d) too large for %d-byte variable",
		   result.data.number, size);
	}
	/*
	 * Store the value in low byte first
	 */
	for (i = size, v = result.data.number, bp=val;
	     i > 0;
	     v >>= 8, i--, bp++)
	{
	    *bp = (byte)v;
	}
	/*
	 * Store the value at the end of the segment
	 */
	Table_Store(curSeg->u.segment.code,
		    size,
		    val,
		    *addrPtr);
	/*
	 * Enter relocation if constant is relocatable...
	 * In most cases, the fixup descriptor will already have
	 * been filled in by the expression parser.
	 */
	if (result.rel.sym) {
	    if ((size == 1) && (result.rel.size == FIX_SIZE_WORD)) {
		/*
		 * If not already trimmed by LOW or HIGH
		 * operator, perform implicit LOW
		 */
		result.rel.size = FIX_SIZE_BYTE;
		result.rel.type = FIX_LOW_OFFSET;
	    } else {
		if (size > 2) {
		    /*
		     * Allow longword constants by setting the fixup size to
		     * dword
		     */
		    result.rel.size = FIX_SIZE_DWORD;
		}
		/*
		 * If caller specified a fixup type, use that instead of the
		 * one provided by the expression parser.
		 */
		if (DESD_FIX_TYPE(data)) {
		    result.rel.type = DESD_FIX_TYPE(data);

		    if (result.rel.type == FIX_BOGUS) {
			Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			       "initializer is not allowed to require relocation");
			retcode = FR_ERROR;
		    }
		}
	    }
	    
	    if ((size == 4) &&
		((DESD_FIX_TYPE(data) == FIX_HANDLE) ||
		 (DESD_FIX_TYPE(data) == FIX_SEGMENT)))
	    {
		/*
		 * If handle relocation in an optr, or segment relocation
		 * in an fptr, place the relocation in the handle/segment
		 * portion of the pointer, not the base.
		 */
		result.rel.size = FIX_SIZE_WORD;
		Fix_Enter(&result, (*addrPtr) + 2, (*addrPtr) + 2);
	    } else {
		Fix_Enter(&result, *addrPtr, *addrPtr);
	    }
	}
	/*
	 * Advance dot over the thing
	 */
	*addrPtr += size;
    } else if (result.data.ea.modrm != MR_DIRECT) {
	Notify(NOTIFY_ERROR, expr1->file, expr1->line,
	       "bogus operand (indirect or register) for variable definition");
	retcode = FR_ERROR;
    } else {
	switch(size) {
	    case 1:
	    {
		byte	b;
		
		result.rel.size = FIX_SIZE_BYTE;
		result.rel.type = FIX_LOW_OFFSET;
		
		b = (byte)result.data.ea.disp;
		Table_Store(curSeg->u.segment.code,
			    1, &b, *addrPtr);
		Fix_Enter(&result, *addrPtr, *addrPtr);
		break;
	    }
	    case 2:
	    {
		if (DESD_CHUNK_ONLY(data) &&
		    (result.rel.sym->type != SYM_CHUNK))
		{
		    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			   "should be initialized with 0 or a \"chunk\" symbol");
		} else if (DESD_FIX_TYPE(data) && !DESD_CHUNK_ONLY(data)) {
		    /*
		     * Segment/group come back as relocatable constants.
		     * If fixType non-zero, we must want a segment or a group
		     * (except in the case of an optr, of course, when we
		     * want a chunk).
		     */
		    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			   "initializer should be segment or group");
		}
		
		result.rel.size = FIX_SIZE_WORD;
		result.rel.type = DESD_FIX_TYPE(data) ? DESD_FIX_TYPE(data) :
							FIX_OFFSET;
		
		/*
		 * Store displacement in proper byte order
		 */
		val[0] = (byte)result.data.ea.disp;
		val[1] = (byte)(result.data.ea.disp >> 8);
		
		Table_Store(curSeg->u.segment.code,
			    2, val, *addrPtr);

		Fix_Enter(&result, *addrPtr, *addrPtr);
		break;
	    }
	    case 4:
	    {
		FixDesc	fix;
		
		if (DESD_CHUNK_ONLY(data) &&
		    (result.rel.sym->type != SYM_CHUNK))
		{
		    Notify(NOTIFY_WARNING, expr1->file, expr1->line,
			   "should be initialized with 0 or a \"chunk\" symbol");
		}
		
		val[0] = (byte)result.data.ea.disp;
		val[1] = (byte)(result.data.ea.disp >> 8);
		val[2] = val[3] = 0;
		
		Table_Store(curSeg->u.segment.code,
			    4, val, *addrPtr);
		
		/*
		 * First the segment relocation
		 */
		fix.size = FIX_SIZE_WORD;
		fix.type = (DESD_FIX_TYPE(data) ? DESD_FIX_TYPE(data) :
			    (DESD_CHUNK_ONLY(data) ?
			     FIX_HANDLE : FIX_SEGMENT));
		fix.pcrel = 0;
		fix.fixed = 0;
		fix.frame = result.rel.frame;
		fix.sym = result.rel.sym;

		if (fix.type == FIX_BOGUS) {
		    Notify(NOTIFY_ERROR, expr1->file, expr1->line,
			   "initializer is not allowed to require relocation");
		    retcode = FR_ERROR;
		}
		
		/*
		 * Now for the offset part. Can't re-use the 2-byte case,
		 * though I'd really like to, b/c we need to store two bytes
		 * of 0's for the segment.
		 */
		result.rel.size = FIX_SIZE_WORD;
		result.rel.type = FIX_OFFSET;

		Fix_Enter(&result, *addrPtr, *addrPtr);
		result.rel = fix;
		Fix_Enter(&result, (*addrPtr)+2, *addrPtr);
		break;
	    }
	    default:
		Notify(NOTIFY_ERROR, expr1->file, expr1->line,
		       "Unhandled size (%d) in DataEnterSingle", size);
		retcode = FR_ERROR;
		break;
	}
	*addrPtr += size;
    }
    free((void *)val);
    return(retcode);
}
    

/***********************************************************************
 *				DataEnterInt
 ***********************************************************************
 * SYNOPSIS:	    Enter an integer or integers at dot
 * CALLED BY:	    Data_Enter (TYPE_INT, TYPE_SIGNED, TYPE_CHAR,
 *	    	    TYPE_POINTER [near and far])
 * RETURN:	    TRUE if successful
 * SIDE EFFECTS:    *addrPtr is adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 8/89		Initial Revision
 *
 ***********************************************************************/
static int
DataEnterInt(int    	    *addrPtr,   /* IN/OUT: address at which to store */
	     TypePtr	    type,   	/* Base type */
	     Expr   	    *expr,  	/* Initializers */
	     int    	    maxElts,	/* Maximum # elements we may define */
	     int	    chunkOnly,	/* Only a chunk symbol or 0 will do */
	     int    	    fixType)	/* Fix type to use by default
					 * (if not FIX_TYPE_OFFSET) */
{
    Expr	cur;    	/* Next part to store */
    int 	retval = TRUE;	/* Assume success */
    int	    	size;	    	/* Size of element */
    Opaque  	data;
    int	    	initMax = maxElts;
    
    cur.elts = NULL;
    size = Type_Size(type);

    /*
     * Build the opaque longword that can be registered with a fixup and
     * governs how the data are entered. Most of the fields just come from
     * our arguments. The one exception is, if the type being entered is not
     * actually an integer (it's a record or enum), do not allow a string to
     * initialize the thing.
     */
    data = (Opaque)(((size<<DESD_SIZE_SHIFT)&DESD_SIZE_MASK) |
		    ((chunkOnly<<DESD_CHUNK_ONLY_SHIFT)&DESD_CHUNK_ONLY_MASK) |
		    ((fixType<<DESD_FIX_TYPE_SHIFT)&DESD_FIX_TYPE_MASK) |
		    (((type->tn_type != TYPE_INT) &&
		      (type->tn_type != TYPE_SIGNED)) ?
		     DESD_NO_STRING_MASK : 0));
    
    do {
	int 	startAddr;
	
	Expr_NextPart(expr, &cur, FALSE);
	if (cur.numElts == 0) {
	    return(retval);
	}
	
	startAddr = *addrPtr;
	if (DataEnterSingle(addrPtr, maxElts, 1, &cur, NULL, data) != FR_DONE){
	    retval = FALSE;
	} else {
	    /*
	     * Handle DataEnterSingle storing more than one element (as done
	     * for db "hi there", e.g.)
	     */
	    maxElts -= ((*addrPtr - startAddr) / size) - 1;
	}
    } while(--maxElts != 0);

    Expr_NextPart(expr, &cur, FALSE);
    if (cur.numElts != 0) {
	Notify(NOTIFY_ERROR, cur.file, cur.line,
	       "too many elements in array (%d max)", initMax);
	return(FALSE);
    }
    return(retval);
}

/***********************************************************************
 *				Data_Enter
 ***********************************************************************
 * SYNOPSIS:	    Enter data into the current segment
 * CALLED BY:	    DataDefineSym and others
 * RETURN:	    FALSE on error.
 * SIDE EFFECTS:    None.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/25/89		Initial Revision
 *
 ***********************************************************************/
int
Data_Enter(int	    	*addrPtr,   /* IN/OUT: address at which to store */
	   TypePtr  	type,  	    /* Type of data being defined */
	   Expr	    	*expr, 	    /* Value(s) to store. Must not have
				     * anything where the parser can nuke
				     * it. */
	   int	    	maxElts)    /* Maximum number of elements that may
				     * be in expr */
{
    int 	retval = TRUE;	    /* Assume success */

    /*
     * Make sure data aren't being entered in global or library
     * segment. Data may go in an absolute segment to define symbol offsets...
     */
    if (curSeg->u.segment.data->comb == SEG_GLOBAL ||
	curSeg->u.segment.data->comb == SEG_LIBRARY)
    {
	Notify(NOTIFY_ERROR, expr->file, expr->line,
	       "Data in global/library segment %i", curSeg->name);
	return(FALSE);
    } else if (warn_inline_data &&
	       (!curSeg->u.segment.data->checkLabel ||
		dot == curSeg->u.segment.data->lastLabel))
    {
	Notify(NOTIFY_WARNING, expr->file, expr->line,
	       "Data declared in-line without .inst directive");
    }
	
    again:			/* Return point for handling SYM_TYPE */

    switch(type->tn_type) {
    case TYPE_NEAR:
    case TYPE_FAR:
    case TYPE_VOID:
	Notify(NOTIFY_ERROR, expr->file, expr->line,
	       "Bogus type in Data_Enter");
	return(FALSE);
    case TYPE_INT:
    case TYPE_SIGNED:
	return DataEnterInt(addrPtr, type, expr, maxElts, FALSE, 0);
    case TYPE_CHAR:
	return DataEnterInt(addrPtr, Type_Int(Type_Size(type)), expr, maxElts, FALSE, 0);
    case TYPE_PTR:
	switch(type->tn_u.tn_ptr.tn_ptrtype) {
	case TYPE_PTR_NEAR:   	/* nothing special */
	    return DataEnterInt(addrPtr, type, expr, maxElts, FALSE,
				0);
	case TYPE_PTR_VIRTUAL: 	/* FIX_SEGMENT for high word if non-zero */
	case TYPE_PTR_FAR:   	/* FIX_SEGMENT for high word if non-zero */
	    return DataEnterInt(addrPtr, type, expr, maxElts, FALSE,
				FIX_SEGMENT);
	case TYPE_PTR_LMEM:	/* offset must be chunk */
	    return DataEnterInt(addrPtr, type, expr, maxElts, TRUE, 0);
	case TYPE_PTR_SEG:	/* FIX_SEGMENT if non-zero */
	    return DataEnterInt(addrPtr, type, expr, maxElts, FALSE,
				FIX_SEGMENT);
	case TYPE_PTR_HANDLE:	/* FIX_HANDLE if non-zero */
	    return DataEnterInt(addrPtr, type, expr, maxElts, FALSE,
				FIX_HANDLE);
	case TYPE_PTR_OBJ:	/* FIX_HANDLE if non-zero + offset=chunk */
	    return DataEnterInt(addrPtr, type, expr, maxElts, TRUE,
				FIX_HANDLE);
	case TYPE_PTR_VM:   	/* High word should be 0 */
	    return DataEnterInt(addrPtr, type, expr, maxElts, FALSE,
				FIX_BOGUS);
	}

	Notify(NOTIFY_ERROR, expr->file, expr->line,
	       "internal error: unsupported pointer type '%c'",
	       type->tn_u.tn_ptr.tn_ptrtype);
	return(FALSE);
    case TYPE_ARRAY:
    {
	/*
	 * Must take individual elements out of the string(s) that must be
	 * here, passing them back to the scanner as input.
	 */
	DataState	state; 	    /* Current state block */
	
	state.base = type;
	state.cur.elts = NULL;
	
	/*
	 * When dealing with default values in structure fields defined like
	 *  biff    db	3 dup(3)
	 * or
	 *  whiffle dw	1, 2, 3
	 * we get an expression like
	 *  CONST(1) COMMA CONST(2) COMMA CONST(3) COMMA
	 * THIS IS LEGAL. To deal with this, we check the first element of
	 * the expression to see if it's a string or not. If not, we
	 * check the base type to see if it's simple enough that it could
	 * be done with simple expressions, as above. If so, we recurse, then
	 * pad any extra space with 0's. Otherwise, we lose.
	 *
	 * Note this even works for
	 *  biff    db	"hi there"
	 */
	if (expr->elts[0].op != EXPR_INIT) {
	    switch(type->tn_u.tn_array.tn_base->tn_type) {
		case TYPE_INT:
		case TYPE_SIGNED:
		case TYPE_CHAR:
		case TYPE_PTR:
		    return Data_Enter(addrPtr, type->tn_u.tn_array.tn_base,
				      expr, type->tn_u.tn_array.tn_length);
	    }
	}
	
	do {
	    int	startDot;   /* dot at start of initialized */
	    int	undefined;  /* Bytes uninitialized at end */
	    
	    /*
	     * Fetch next array to define
	     */
	    Expr_NextPart(expr, &state.cur, FALSE);
	    
	    if (state.cur.numElts == 0) {
		return(retval);
	    }
	    startDot = dot; /* Record starting offset */
	    
	    if (state.cur.elts[0].op != EXPR_INIT) {
		Notify(NOTIFY_ERROR, state.cur.file, state.cur.line,
		       "array not initialized with <>-string");
		retval = FALSE;
	    } else if (DataParse(&state, DataArrayStart, yyinput)) {
		/*
		 * Fill in un-initialized slots in the array and
		 * bounds check.
		 */
		undefined = Type_Size(type) - (dot - startDot);
		
		if (undefined > 0) {
		    /*
		     * If bytes left in type, insert that many blank
		     * elements.
		     */
		    Table_StoreZeroes(curSeg->u.segment.code, undefined, dot);
		} else if (undefined < 0) {
		    /*
		     * If undefined < 0, the number of bytes allocated
		     * since we started is too large -- print an error
		     * message. There's no point in deleting the
		     * elements as we'll reset dot down below.
		     */
		    Notify(NOTIFY_ERROR, state.cur.file, state.cur.line,
			   "too many elements in array");
		    retval = FALSE;
		}
		dot += undefined;
	    } else {
		/*
		 * Signal error -- message already given...
		 */
		retval = FALSE;
	    }
	} while (--maxElts != 0);

	Expr_NextPart(expr, &state.cur, FALSE);
	if (state.cur.numElts != 0) {
	    Notify(NOTIFY_ERROR, state.cur.file, state.cur.line,
		   "too many elements in array");
	    retval = FALSE;
	}
	return(retval);
    }
    case TYPE_STRUCT:
	switch (type->tn_u.tn_struct->type) {
	case SYM_ETYPE:
	    return DataEnterInt(addrPtr, type, expr, maxElts, FALSE, 0);
	case SYM_RECORD:
	{
	    /*
	     * Must take individual elements out of the string(s)
	     * that must be here, passing them to Data_EncodeRecord
	     * back to the scanner as input.
	     */
	    DataRecordState	state; 	    /* Current state block */
	    
	    state.common.base = type;
	    state.common.cur.elts = NULL;
	    state.flags = DRS_DEF_VAR;
	    
	    if (type->tn_u.tn_struct->u.record.first == NULL) {
		Notify(NOTIFY_ERROR, expr->file, expr->line,
		       "cannot initialize record %i -- it has no fields",
		       type->tn_u.tn_struct->name);
		return(FALSE);
	    }
	    
	    do {
		/*
		 * Fetch next record to define
		 */
		Expr_NextPart(expr, &state.common.cur, FALSE);
		
		if (state.common.cur.numElts == 0) {
		    return(retval);
		}
		
		if (state.common.cur.elts[0].op != EXPR_INIT) {
		    /*
		     * Allow the user to initialize a record with either
		     * a string or with a real expression. In the case of
		     * a real expression, use DataEnterInt, which will
		     * make sure the expression isn't too big.
		     */
		    DataEnterInt(addrPtr, type, &state.common.cur, 1, FALSE,0);
		} else if (!DataParse((DataState *)&state,
				      DataRecordStart,
				      yyinput))
		{
		    retval = FALSE;
		}
	    } while (--maxElts != 0);

	    Expr_NextPart(expr, &state.common.cur, FALSE);
	    if (state.common.cur.numElts != 0) {
		Notify(NOTIFY_ERROR, expr->file, expr->line,
		       "too many elements in array");
		retval = FALSE;
	    }
	    return(retval);
	}
	case SYM_STRUCT:
	    return DataEnterStruct(type, expr, maxElts);
        case SYM_TYPE:
	    /*
	     * Switch to the type recorded in the typedef and try again...
	     * Why recurse when you don't have to?
	     */
	    type = type->tn_u.tn_struct->u.typeDef.type;
	    goto again;
	case SYM_UNION:
	    return DataEnterUnion(type, expr, maxElts);
	default:
	    assert(0);
	    return(FALSE);
	}

    default:
	assert(0);
	return(FALSE);
    }
}
		    


/***********************************************************************
 *				Data_EncodeRecord
 ***********************************************************************
 * SYNOPSIS:	    Encode a record initialization string as an
 *	    	    expression for the parser to read.
 * CALLED BY:	    yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:    parser input is revectored to a routine that will
 *	    	    feed it the appropriate things.
 *
 * STRATEGY:	    Set up a state block for transforming the initializer
 *	    	    into the proper expression for a record, then switch
 *	    	    into that state, relying on the code written for
 *	    	    defining record variables to take care of the rest.
 *
 *	    	    The rule that calls this function should follow the
 *	    	    nested action with an 'expr' non-terminal to evaluate
 *	    	    the expression this function will cause to be returned.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/25/89		Initial Revision
 *
 ***********************************************************************/
void
Data_EncodeRecord(SymbolPtr record, 	/* Record involved */
		  char	    *initStr)	/* String containing field values */
{
    DataRecordState *drs;

    drs = (DataRecordState *) malloc(sizeof(DataRecordState));

    drs->flags	    	= 0;	/* Just produce expression, no \n */
    drs->state	    	= DRS_FIRST_PAREN;
    drs->field	    	= record->u.record.first;
    drs->common.cp  	= initStr;
    drs->common.yylex 	= yylex;
    drs->common.yyinput	= yyinput;
    drs->common.next	= top;
    drs->common.cur.file= curFile->name;
    drs->common.cur.line= yylineno;
    drs->fieldEnd   	= NULL;

    /*
     * If initialization string is entirely empty, assume the user wants to
     * get all the default values for the record and don't generate a warning.
     */
    if (*initStr == '\0') {
	drs->flags |= DRS_WARNED;
    }

    /*
     * Switch over to the proper mode for generating the expression from the
     * initializer. Involves pushing to the above state, calling
     * DataRecordContinue to get tokens back, and saving the current pushback
     * away until the expression's been parsed.
     */
    top = (DataState *)drs;
    yylex = DataRecordContinue;
    Scan_SavePB();
}

/*
 * local-variables:
 * c-label-offset: -4
 * end:
 */
