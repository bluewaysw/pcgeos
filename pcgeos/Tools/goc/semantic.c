/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- semantic checks
 * FILE:	  semantic.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * DESCRIPTION:
 *     Semantic check routines for goc
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: semantic.c,v 1.7 96/07/08 17:38:19 tbradley Exp $";
#endif lint

#include    <config.h>
#include    "goc.h"
#include    "parse.h"

#include    <ctype.h>
#include    <compat/string.h>


/*
 *	Name: MarkParentKbdPath
 *	Author: Tony Requist
 *
 *	Synopsis: Mark this object's parent
 *
 */
void
MarkParentKbdPath(Symbol *object)
{
    if (object->flags & SYM_HAS_KBD_ACCEL) {
	while (object != NullSymbol) {
	    object->flags |= SYM_HAS_KBD_ACCEL;
	    object = object->data.symObject.kbdPathParent;
	}
    }
}   /* MarkParentKbdPath */

/*
 *	Name: DoSemanticChecks
 *	Author: Tony Requist
 *
 *	Synopsis: Make sure that all data definitions are defined.
 *
 */
void
DoSemanticChecks(void)
{
    Symbol *resource;
    Symbol *sym;

	/* Go through every sym of every resource */

    for (resource = resourceList; resource != NullSymbol;
			resource = resource->data.symResource.nextResource) {
	for (sym = resource->data.symResource.firstChunk; sym != NullSymbol;
				sym = sym->data.symChunk.nextChunk) {
	    if ( (sym->type != OBJECT_SYM) &&
				(sym->type != CHUNK_SYM) &&
				(sym->type != VIS_MONIKER_CHUNK_SYM) &&
				(sym->type != GCN_LIST_SYM) &&
				(sym->type != GCN_LIST_OF_LISTS_SYM)) {
		FatalError("DoSemanticChecks: unknown symbol type for %s, %d",
					sym->name, sym->type);
	    }
	    if ( !(sym->flags & SYM_DEFINED) ) {
		yyerror("Symbol %s used but not defined\n",sym->name);
	    } else {
		if ((sym->type == OBJECT_SYM) &&
		    	    (sym->flags & SYM_HAS_KBD_ACCEL)) {
		    MarkParentKbdPath(sym);
		}
	    }
	}
    }
    for (sym = undefinedList; sym != NullSymbol;
	    	    	sym = sym->data.symChunk.nextChunk) {
	if (sym->flags & SYM_DEFINED) {
	    FatalError("DoSemanticChecks: Defined symbol %s on undefined list",
		       sym->name);
	}
	if ( !(sym->flags & SYM_EXTERN) ) {
	    yyerror("Symbol %s used but not defined\n",sym->name);
	} else if (sym->flags & SYM_CANNOT_BE_EXTERN) {
	    yyerror("Symbol %s must be defined locally\n",sym->name);
	}
    }
}   /* DoSemanticChecks */
