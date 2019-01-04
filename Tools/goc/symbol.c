/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- Symbol methdling
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
"$Id: symbol.c,v 1.19 96/07/09 17:09:50 jimmy Exp $";
#endif lint

#include    <config.h>
#include    "goc.h"
#include    "hash.h"
#include    "stringt.h"

#include    <malloc.h>
#include    <compat/string.h>
#include    "parse.h"
#include    "localize.h"
#ifdef _WIN32
#include    <winutil.h>
#endif

Scope	*ScopeArray[MAX_SCOPES];

Scope	**scopePtr = &ScopeArray[0];

Scope *visMonikerScope;
Scope *kbdAcceleratorScope;

MsgParamPassEnum    sym_ParamTable[] =  {
    MPD_PASS_AND_RETURN, 			/* call 	*/
    MPD_PASS_ONLY_RETURN_EVENT_HANDLE, 		/* record 	*/
    MPD_PASS_AND_RETURN, 			/* callsuper    */
    MPD_PASS_VOID_RETURN_VOID,  		/* dispatch     */
    MPD_RETURN_ONLY,                            /* dispatchcall */
    MPD_PASS_ONLY_RETURN_VOID,                  /* send,(not to children) */
};



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
 *	tony	6/14/89		Cmethged for uic
 *
 ***********************************************************************/
Symbol *
Symbol_Enter(char *name, int type, int flags)
{
    return Symbol_EnterWithLineNumber(name, type, flags,yylineno);
}

Symbol *
Symbol_EnterWithLineNumber(char *name, int type, int flags,int lineNumber)

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
	if(sym->type == CHUNK_SYM ||
	   sym->type == VIS_MONIKER_CHUNK_SYM){

	    CHUNK_LOC(sym) = (LocalizeInfo *)calloc(1,sizeof(LocalizeInfo));
	}
    } else {
	if ((sym->flags & flags & SYM_DEFINED)) {
	    if (sym->flags & SYM_EXTERN) {
	        yyerror("%s: previously declared extern in line %d of '%s'\n",
			name, sym->lineNumber, sym->realFileName);
	    } else {
	        yyerror("%s: multiply defined (also in line %d of '%s')\n",
			name, sym->lineNumber, sym->realFileName);
	    }
	    sym->flags |= SYM_MULTIPLY_DEFINED;
	} else if ((sym->type != type)) {
	    yyerror("%s: definition clashes with previous usage\n", name);
	}
	sym->flags |= flags;
    }
    if ((sym->flags & SYM_DEFINED) & !(sym->flags & SYM_MULTIPLY_DEFINED)) {
	sym->fileName = String_Enter(curFile->name, strlen(curFile->name));
	sym->realFileName = String_Enter(curFile->name, strlen(curFile->name));
	sym->lineNumber = lineNumber;
    }
    return(sym);
}



/***********************************************************************
 *	    Symbol_OutputProtoMinorRelocations
 ***********************************************************************
 * SYNOPSIS:	  Loop through each of the protominor symbols and
 *                write them to the output file
 * CALLED BY:	  main
 * RETURN:	  Nothing
 * SIDE EFFECTS:  A new segment containing a bunch of relocations to
 *                protominor symbols is written to the output file
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *      jon     14 jul 1993     initial revision
 *
 ***********************************************************************/
void
Symbol_OutputProtoMinorRelocations(char *inFileName)
{
    Scope	*sptr, **sptrptr;
    Symbol      *sym;
    Hash_Entry	  *entry;
    Hash_Search	  search;
    char        truncatedInFileName[256];
    char        *cp;
    int         refnum = 0;

    /*
     * We'll use the name of the infile to generate the name of the
     * bogus routine that'll contain references to the protoMinor symbols.
     *
     * Need to deal with names like "../Foo/bar.goc" ala bug 27721
     */
    if (cp = (char *) strstr(inFileName, ".goc")) {
	strcpy(truncatedInFileName, inFileName);
	truncatedInFileName[cp - inFileName] = '\000';
    } else if (cp = (char *) strstr(inFileName, ".GOC")) {
	strcpy(truncatedInFileName, inFileName);
	truncatedInFileName[cp - inFileName] = '\000';
    } else {
	strcpy(truncatedInFileName, "generic");
    }

    /*
     *  Switch code segments so we can discard it in the linker
     */
#ifdef _WIN32
    cp = (char *) strrchr(truncatedInFileName, '/');
    {
	char* cp2 = (char*)  strrchr(truncatedInFileName, '\\');
	if( (cp == NULL) || (( cp2 != NULL) && ( cp2 < cp ))) {
		cp = cp2;
	}
    }
#else
    cp = (char *) strrchr(truncatedInFileName,
#if defined(_LINUX)
				'/');
#else
			  (compiler == COM_HIGHC) ? '/' : '\\');
#endif
#endif
    if (cp == NULL) {
	cp = truncatedInFileName;
    } else {
	cp++;
    }
    switch (compiler) {
        case COM_HIGHC :
	    /*
	     * Override above path sep shme in the Unix/MetaC case.
	     */
	    Output("pragma Code(\"_BOGUS_PROTOMINORRELOCS\");");
	    Output("\nvoid\n%s_ProtoMinorRoutine()\n{", cp);
	    break;
	case COM_WATCOM :
	case COM_MSC :
	    Output("#pragma code_seg(\"_BOGUS_PROTOMINORRELOCS\")\n");
	    OutputLineNumber(yylineno, curFile->name);
	    Output("\nvoid\n%s_ProtoMinorRoutine()\n{", cp);
	    break;
	case COM_BORL:
	    /*
	     * The first thing we'll output to our new file is a specification
	     * for the name of the code segment.
	     *
	     * We also want to disable any warnings about calling functions
	     * with no prototype.
	     */
	    Output("#pragma option -zE_BOGUS_PROTOMINORRELOCS\n");
	    break;
	}

    /*
     * Now we loop through all of the symbols looking for PROTOMINOR_SYM's
     * that have been referenced. If we find one, we add a call to it in our
     * funky routine.
     */

    for (sptrptr = scopePtr; sptrptr >= &ScopeArray[0]; sptrptr -= 1) {
	for (sptr = *sptrptr; sptr != NullScope; sptr = sptr->parent) {
	    for (entry = Hash_EnumFirst(sptr->symbols, &search);
		 entry != (Hash_Entry *)NULL;
		 entry = Hash_EnumNext(&search))
		{
		    sym = (Symbol *)Hash_GetValue(entry);
		    if ((sym->type == PROTOMINOR_SYM) &&
			(sym->data.symProtoMinor.references != 0)) {

			if (compiler == COM_BORL) {
			    Output("\nextern int %s;\nword far _%s_PROTO_REF_%d[] = {(word)(dword)&%s};", sym->name, cp, refnum++, sym->name);
			} else {
			    Output("\n%s(%d, %s);", sym->name,
			        sym->data.symProtoMinor.references,
				sym->data.symProtoMinor.msgOrVardataSym->name);
			}
		    }
		}
	}
    }

    switch (compiler) {
	case COM_HIGHC :
	    Output("\n}\n");
	    Output("pragma Code();");
	    break;
	case COM_WATCOM :
	case COM_MSC :
	    Output("\n}\n");
	    Output("\n#pragma code_seg()\n");
	    OutputLineNumber(yylineno, curFile->name);
	    break;
	  case COM_BORL:
	    Output("\n#pragma option -zE*\n");
	    break;
    }
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
 *				Symbol_ClassUses
 ***********************************************************************
 * SYNOPSIS:
 * CALLED BY:
 * RETURN:
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/21/93		Initial Revision
 *
 ***********************************************************************/
void
Symbol_ClassUses(Symbol     *class,
		 Symbol     *used)
{
    if (class->data.symClass.numUsed == 0) {
	class->data.symClass.used = (Symbol **)malloc(sizeof(Symbol *));
    } else {
	class->data.symClass.used =
	    (Symbol **)realloc((malloc_t)class->data.symClass.used,
				 ((class->data.symClass.numUsed+1) *
				  sizeof(Symbol *)));
    }
    class->data.symClass.used[class->data.symClass.numUsed] = used;
    class->data.symClass.numUsed += 1;
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
	fprintf(stderr, "Symbol_NewScope: creating new scope 0x%x",
		(unsigned) scope);
	fprintf(stderr,", parent scope = 0x%x\n", (unsigned) parent);
    }

    return(scope);
}
