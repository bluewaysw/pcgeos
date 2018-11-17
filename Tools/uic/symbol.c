/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  uic -- Symbol handling
 * FILE:	  symbol.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * DESCRIPTION:
 *	Symbol module for uic
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: symbol.c,v 1.7 92/05/14 12:12:31 adam Exp $";
#endif lint

#include <config.h>
#include    "uic.h"
#include    "parse.h"

#include    <compat/string.h>
#include    <malloc.h>

Scope	*ScopeArray[MAX_SCOPES];

Scope	**scopePtr = &ScopeArray[0];


/***********************************************************************
 *				Symbol_Enter
 ***********************************************************************
 * SYNOPSIS:	  Add a symbol to the symbol table
 * CALLED BY:	  yyparse
 * RETURN:	  Nothing
 * SIDE EFFECTS:  A Symbol is entered
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *	tony	6/14/89		Changed for uic
 *
 ***********************************************************************/
Symbol *
Symbol_Enter(char *name, int type, int flags)
{
    Symbol	*sym;
    Hash_Entry	*entry;

    sym = Symbol_Find(name, LOCAL_SCOPE);
    if (sym == (Symbol *) NULL) {
	if (symdebug) {
	    fprintf(stderr, "Entering new symbol %s, type = %d, flags = %d",
					name, type, flags);
	    fprintf(stderr, ", scope = 0x%x\n", (unsigned) *scopePtr);
	}
	sym = (Symbol *) calloc(1, sizeof(Symbol));
	sym->type = type;
	sym->name = name;
	sym->flags = flags;
	entry = Hash_CreateEntry((**scopePtr).symbols, name, NULL);
	Hash_SetValue(entry, sym);
    } else {
	if ((sym->flags & flags & SYM_DEFINED)) {
	    yyerror("%s: multiply defined\n", name);
	} else if ((sym->type != sym->type)) {
	    yyerror("%s: definition clashes with previous usage\n", name);
	}
    }
    return(sym);
}



/***********************************************************************
 *				Symbol_Find
 ***********************************************************************
 * SYNOPSIS:	  Find a symbol by name.  Searches all current scopes.
 * CALLED BY:	  yyparse
 * RETURN:	  Symbol * for the name
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
Symbol *
Symbol_Find(char *name, int allScopes)
{
    Scope	*sptr, **sptrptr;
    Hash_Entry	  *entry;
    int	    	    restrict = FALSE;

    if (symdebug) {
	fprintf(stderr, "Looking for symbol <%s> in ",name);
    }
    for (sptrptr = scopePtr; sptrptr >= &ScopeArray[0]; sptrptr -= 1) {
	for (sptr = *sptrptr; sptr != NullScope; sptr = sptr->parent) {
	    if (symdebug) {
		fprintf(stderr, "0x%x ", (unsigned) sptr);
	    }
	    entry = Hash_FindEntry(sptr->symbols, name);
	    if (entry != (Hash_Entry *)NULL) {
		if (symdebug) {
		    fprintf(stderr, "found\n");
		}
		return ((Symbol *)Hash_GetValue(entry));
	    }
	    if (!allScopes) {
		if (symdebug) {
		    fprintf(stderr, "not found\n");
		}
		return (NullSymbol);
	    }
	    restrict = restrict || sptr->restrict;
	}
	if (restrict) {
	    if (symdebug) {
		fprintf(stderr, "restricted => not found\n");
	    }
	    return(NullSymbol);
	}
    }
    if (symdebug) {
	fprintf(stderr, "not found\n");
    }
    return (NullSymbol);
}


/***********************************************************************
 *				Symbol_Init
 ***********************************************************************
 * SYNOPSIS:	  Init the symbol table
 * CALLED BY:	  yyparse
 * RETURN:	  Symbol * for the name
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	8/29/88		Initial Revision
 *
 ***********************************************************************/
void
Symbol_Init(void)
{
    ScopeArray[0] = Symbol_NewScope(NullScope, FALSE);
}


/***********************************************************************
 *				Symbol_PushScope
 ***********************************************************************
 * SYNOPSIS:	  Push a scope on the scope list
 * CALLED BY:	  yyparse
 * RETURN:	  none
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	6/14/89		Initial Revision
 *
 ***********************************************************************/
void
Symbol_PushScope(Scope *scope)
{
    if (symdebug) {
	fprintf(stderr, "Symbol_PushScope: pushing scope #%d, 0x%x\n",
			( (scopePtr-&ScopeArray[0]) )+1, (unsigned) scope );
    }

    scopePtr++;
    if (scopePtr == &ScopeArray[MAX_SCOPES]) {
	perror("Symbol_PushScope: too many nested scopes");
	scopePtr--;
    }
    *scopePtr = scope;
}


/***********************************************************************
 *				Symbol_PopScope
 ***********************************************************************
 * SYNOPSIS:	  Pop a scope off the scope list
 * CALLED BY:	  yyparse
 * RETURN:	  none
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	6/14/89		Initial Revision
 *
 ***********************************************************************/
Scope *
Symbol_PopScope(void)
{
    if (symdebug) {
	fprintf(stderr, "Symbol_PopScope: popping scope #%d\n",
			(scopePtr-&ScopeArray[0]) );
    }

    if (scopePtr == &ScopeArray[0]) {
	perror("Symbol_PopScope: scope stack empty");
    }
    return( *(scopePtr--) );
}


/***********************************************************************
 *				Symbol_PopScopeTo
 ***********************************************************************
 * SYNOPSIS:	  Pop scopes off the scope list until the given one is
 *	    	  popped.
 * CALLED BY:	  yyparse
 * RETURN:	  none
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	6/14/89		Initial Revision
 *
 ***********************************************************************/
void
Symbol_PopScopeTo(Scope *scope)
{

    while (*scopePtr != scope) {
	if (symdebug) {
	    fprintf(stderr, "Symbol_PopScopeTo: popping scope #%d\n",
		    (scopePtr-&ScopeArray[0]) );
	}

	if (scopePtr == &ScopeArray[0]) {
	    perror("Symbol_PopScope: scope stack empty");
	    return;
	}
	scopePtr -= 1;
    }
    scopePtr -= 1;
}

/***********************************************************************
 *				Symbol_ReplaceScope
 ***********************************************************************
 * SYNOPSIS:	    Replace one scope in the scope list with another.
 * CALLED BY:	    VARIANT_PTR_SYM rule to override default value
 *	    	    for a variant superclass pointer
 * RETURN:	    non-zero if scope actually replaced.
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/12/92		Initial Revision
 *
 ***********************************************************************/
int
Symbol_ReplaceScope(Scope   *old,
		    Scope   *new)
{
    Scope   **sptrptr;

    for (sptrptr = scopePtr; sptrptr > &ScopeArray[0]; sptrptr--) {
	if (*sptrptr == old) {
	    if (symdebug) {
		fprintf(stderr, "Symbol_ReplaceScope: replace scope #%d\n",
			sptrptr-&ScopeArray[0]);
	    }
	    *sptrptr = new;
	    return(1);
	}
    }
    return(0);
}


/***********************************************************************
 *				Symbol_NewScope
 ***********************************************************************
 * SYNOPSIS:	  Make a new scope (symbol table) that is a subscope of the
 *		  currentScope.
 * CALLED BY:	  yyparse
 * RETURN:	  none
 * SIDE EFFECTS:  None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	6/14/89		Initial Revision
 *
 ***********************************************************************/
Scope *
Symbol_NewScope(Scope *parent,
		int    restrict)
{
    Scope *scope;

    scope = (Scope *) malloc(sizeof(Scope));
    scope->parent = parent;
    scope->restrict = restrict;
    scope->symbols = (Hash_Table *) malloc(sizeof(Hash_Table));
    Hash_InitTable(scope->symbols, 0, HASH_ONE_WORD_KEYS, 3);

    if (symdebug) {
	fprintf(stderr,"Symbol_NewScope: creating new scope 0x%x",
		(unsigned) scope);
	fprintf(stderr,", parent scope = 0x%x\n", (unsigned) parent);
    }

    return(scope);
}
