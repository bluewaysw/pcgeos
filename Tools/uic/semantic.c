/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  UIC -- output
 * FILE:	  semantic.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * DESCRIPTION:
 *	Output routines for UIC
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: semantic.c,v 2.3 92/07/14 20:06:07 brianc Exp $";
#endif lint

#include    <config.h>
#include    "uic.h"
#include    "parse.h"

#include    <ctype.h>
#include    <compat/string.h>
#include    <malloc.h>

/*
 *	Name: CreateEmptyChunks
 *	Author: Tony Requist
 *
 *	Synopsis: Create empty chunks for an object
 *
 */
void
CreateEmptyChunks(Symbol *object, Symbol *resource)
{
    Symbol *class;
    Symbol *comp;
    Symbol *sym;
    ObjectField *of;

    for (class = object->data.symObject.class; class != NullSymbol;
				class = class->data.symClass.superclass) {
	for (comp = class->data.symClass.componentPtr; comp != NullSymbol;
				comp = comp->data.symByteComp.next) {
	    if (comp->type == ACTIVE_LIST_COMP_SYM) {
		for (of = object->data.symObject.firstField;
				of != NullObjectField; of = of->next) {
		    if (of->type == comp) {
			return;
		    }
		}

			/* Create new active list data sym */

		sym = Symbol_Enter(UniqueName(), ACTIVE_LIST_SYM, SYM_DEFINED);

			/* Add the the active list sym to the resource */

		sym->data.symObject.resource = resource;
		sym->data.symObject.next =
				resource->data.symResource.firstObject;
		resource->data.symResource.firstObject = sym;
		resource->data.symResource.chunkCount++;

			/* Allocate an active list field for the object */

		of = (ObjectField *) calloc(1, sizeof(ObjectField) );
		of->data.fieldActiveList.list = sym;
		of->type = comp;

			/* Add the field to the object's fields */

		of->next = object->data.symObject.firstField;
		object->data.symObject.firstField = of;
	    }
	}
    }
}   /* CreateEmptyChunks */

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
    Symbol *cl, *comp;
    ObjectField *tempField;

    for (cl = object->data.symObject.class; cl != NullSymbol;
		    cl = cl->data.symClass.superclass) {
	for (comp = cl->data.symClass.componentPtr; comp != NullSymbol;
			    comp = comp->data.symByteComp.next) {
	    if (comp->flags & SYM_IS_KBD_PATH) {
		for (tempField = object->data.symObject.firstField;
			    tempField != NullObjectField;
			    tempField = tempField->next) {
		    if (tempField->type == comp) {
			object = tempField->data.fieldLink.parent;
			object->flags |= SYM_HAS_KBD_ACCEL;
			MarkParentKbdPath(object);
		    }
		}
	    }
	}
    }
}   /* MarkParentKbdPath */

/*
 *	Name: DoSemanticChecks
 *	Author: Tony Requist
 *
 *	Synopsis: Fill in parent and next sibling links.  While we are doing
 *		  this make sure that all data definitions are defined.
 *
 */
void
DoSemanticChecks(void)
{
    Symbol *resource;
    Symbol *sym;

	/* Go through every sym of every resource */

    if (firstResource == NullSymbol) {
	yyerror("No resources defined");
    }
    for (resource = firstResource; resource != NullSymbol;
			resource = resource->data.symResource.nextResource) {
	if ((sym = resource->data.symResource.resourceOutput) != NullSymbol) {
	    if ( !(sym->flags & SYM_DEFINED) ) {
		yyerror("Symbol %s used but not defined\n",sym->name);
	    }
	}
	for (sym = resource->data.symResource.firstObject; sym != NullSymbol;
				sym = sym->data.symObject.next) {
	    if ( (sym->type != OBJECT_SYM) &&
				(sym->type != VIS_MONIKER_SYM) &&
				(sym->type != HELP_ENTRY_SYM) &&
				(sym->type != ACTIVE_LIST_SYM) &&
				(sym->type != CHUNK_SYM) &&
				(sym->type != GCN_LIST_SYM) &&
				(sym->type != GCN_LIST_OF_LISTS_SYM) &&
				(sym->type != HINT_LIST_SYM) ) {
		Abort("DoSemanticChecks: unknown symbol type for %s, %d",
					sym->name, sym->type);
	    }
	    if ( !(sym->flags & SYM_DEFINED) ) {
		yyerror("Symbol %s used but not defined\n",sym->name);
	    } else {
		if (sym->type == OBJECT_SYM) {
		    CreateEmptyChunks(sym, resource);
		    if (sym->flags & SYM_HAS_KBD_ACCEL) {
			MarkParentKbdPath(sym);
		    }
		}
	    }
	    resource->data.symResource.chunkCount++;
	}
    }
}   /* DoSemanticChecks */
