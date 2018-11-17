/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  UIC -- output
 * FILE:	  output.c
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
"$Id: output.c,v 2.52 97/06/25 19:17:10 cthomas Exp $";
#endif lint

#include    <config.h>
#include    "uic.h"
#include    "parse.h"
#include    "map.h"
#include    "strwid.h"

#include    <ctype.h>
#include    <compat/string.h>
#include    <localize.h>
#include    <malloc.h>

#define COMMENT(args) if(outcomments){ Output args; }
#define COMMENT_CR(args) if(outcomments){ Output args; } Output("\n");

extern Symbol *curResource;		/* Current resource, declared in parse */

	/* Forward definitions */

void PrintStructureComp(ObjectField *field, Symbol *class, Symbol *comp);
void PrintStructureComp2(ObjectField *field, Symbol *stype, char *name);

/*
 *	Name: FindDefault
 *	Author: Tony Requist
 *
 *	Find the default for a given component of a given class
 *
 */
ObjectField *
FindDefault(Symbol *class, Symbol *comp)
{
    ObjectField *of;
    Symbol *sym;

    for (sym = class; sym != NullSymbol; sym = sym->data.symClass.superclass) {
	for (of = sym->data.symClass.firstDefault; of != NullObjectField;
					of = of->next) {
	    if (of->type == comp) {
		return(of);
	    }
	}
    }
    return(comp->data.symByteComp.defaultValue);
}   /* FindDefault */



/***********************************************************************
 *				FindVariantSuperclass
 ***********************************************************************
 * SYNOPSIS:	    See if a superclass was specified for a variant class
 *	    	    and return it if so.
 * CALLED BY:	    PrintClassData
 * RETURN:	    Symbol  * for superclass to use
 * SIDE EFFECTS:    none
 *
 * STRATEGY:	    If no VARIANT_PTR_SYM field is specified for the
 *	    	    object, just return default superclass bound to the
 *	    	    variant. Else return the target of that field.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	5/ 9/92		Initial Revision
 *
 ***********************************************************************/
static Symbol *
FindVariantSuperclass(Symbol	*class,	    /* The variant class */
		      Symbol	*object)    /* The object to search */
{
    ObjectField	    *field;
    Symbol	    *variantPtr;

    /*
     * The variant-superclass pointer is always the first component of the
     * instance structure...
     */
    variantPtr = class->data.symClass.componentPtr;

    for (field = object->data.symObject.firstField;
	 field != NullObjectField;
	 field = field->next)
    {
	if (field->type == variantPtr) {
	    return (field->data.fieldVariantPtr.target);
	}
    }

    /*
     * See if there's a default superclass specified for the object's class.
     */
    field = FindDefault(object->data.symObject.class, variantPtr);
    if (field != (ObjectField *)class) {
	return (field->data.fieldVariantPtr.target);
    }
    
    return(class->data.symClass.superclass);
}

/*
 *	Name: FindBitFieldValue
 *	Author: Tony Requist
 *
 *	Find the default of a bit field for a given class and component
 *
 */
int
FindBitFieldValue(ObjectField *field, Symbol *class, Symbol *comp)
{
    ObjectField *of;
    Symbol *sym;
    int i = 0;
    int done;

    if (field->data.fieldBitField.modifiesDefault == TRUE) {
	for (done = FALSE, sym = class; !done && sym != NullSymbol;
					sym = sym->data.symClass.superclass) {
	    for (of = sym->data.symClass.firstDefault;
			    !done && of != NullObjectField; of = of->next) {
		if (of->type == comp) {
		    done = TRUE;
		    i = FindBitFieldValue(of, sym->data.symClass.superclass,
									comp);
		}
	    }
	}
	if (!done) {
	    i = comp->data.symByteComp.defaultValue->data.fieldBitField.value;
	}
	i &= ~field->data.fieldBitField.maskOut;
	i |= field->data.fieldBitField.value;
	return(i);
    } else {
	return ( field->data.fieldBitField.value ) ;
    }
}   /* FindBitFieldValue */

/*
 *	Name: PrintMasterOffsets
 *	Author: Tony Requist
 *
 *	Synopsis: Print master offsets for a class level
 *
 */
void
PrintMasterOffsets(Symbol *class, Symbol *object, int masterHasData)
{
    if (class->data.symClass.superclass != NullSymbol) {
        if (class->flags & SYM_CLASS_MASTER) {
	    /*
	     * We are ourselves a master class, so print stuff for our
	     * superclass, saying the master group has no data we know of
	     * so far.
	     */
	    if (class->flags & SYM_CLASS_VARIANT) {
		PrintMasterOffsets(FindVariantSuperclass(class, object),
					 object, FALSE);
	    } else {
		PrintMasterOffsets(class->data.symClass.superclass,
					 object, FALSE);
	    }
	} else {
	    if (class->data.symClass.componentPtr == NullSymbol) {
		/*
		 * This class doesn't have any data itself, so print the
		 * superclass passing on the masterHasData we got.
		 */
	        PrintMasterOffsets(class->data.symClass.superclass, object,
							masterHasData);
	    } else {
		/*
		 * Print the superclass, asserting the master group does
		 * indeed have data to print.
		 */
	        PrintMasterOffsets(class->data.symClass.superclass, object,
							TRUE);
	    }
	}
    }
    if (class->flags & SYM_CLASS_MASTER) {
	if (!masterHasData &&
	    (class->data.symClass.componentPtr == NullSymbol) &&
	    !(class->flags & SYM_CLASS_VARIANT))
	{
	    Output("\tword\t0");
	} else {
	    Output("\tword\t%s_%s_part-start_%s", object->name, class->name,
						object->name);
	}
	COMMENT_CR(("\t;Master offset for %sPart",class->name))
    }
}   /* PrintMasterOffsets */

/*
 *	UTILITY
 */

void
PrintBitSize(int size)
{
    switch (size) {
	case 8 : { Output("\tbyte\t");   break; }
	case 16 : { Output("\tword\t");   break; }
	case 32 : { Output("\tdword\t");   break; }
	default : {
	    Abort("PrintBitSize: bad bit size %d\n",size);
	}
    }
}

void
PrintOptr(Symbol *sym)
{
    if (sym == NullSymbol) {
	Output("\tI_OPTR\t0");
    } else {
	if (sym->flags & (SYM_DEFINED|SYM_EXTERNAL)) {
	    if (version20 && (curResource-> flags & SYM_DATA_RESOURCE)) {
		Output("\toptr");
	    } else {
		if (sym->data.symObject.resource == curResource) {
		    Output("\tI_OPTR");
		} else {
		    Output("\tUN_OPTR");
		}
	    }
	    Output("\t%s",sym->name);
	} else {
	    uicerror(sym,"used but not defined");
	}
    }
}

void
PrintHptr(Symbol *sym)
{
    if (sym == NullSymbol) {
	Output("\tI_HPTR\t0");
    } else {
	if (sym == processResource) {
	    Output("\tUN_HPTR\tprocess");
	} else {
	    if (sym->data.symObject.resource == curResource) {
		Output("\tI_HPTR");
	    } else {
		Output("\tUN_HPTR");
	    }
	    Output("\t%s",sym->name);
	}
    }
}

void
PrintNptr(Symbol *sym)
{
    if (sym == NullSymbol) {
	Output("\tlptr\t0");
    } else {
	if (sym->data.symObject.resource == curResource) {
	    Output("\tlptr\t%s", sym->name);
	} else {
	    uicerror(sym,"nptr to chunk in a different resource <%s>",
								sym->name);
	}
    }
}

void
PrintOD(ObjectField *field)
{
    switch (field->data.fieldOptr.type) {
	case OPTR_NULL :
	    {
		Output("\tdword\t0");
		break;
	    }
	case OPTR_PROCESS :
	    {
		Output("\tUN_OPTR\tprocess, ");
		if (field->data.fieldOptr.data.proc.extra == NULL) {
		    Output("0");
		} else {
		    Output("%s",field->data.fieldOptr.data.proc.extra);
		}
		break;
	    }
	case OPTR_OBJECT :
	    {
		PrintOptr(field->data.fieldOptr.data.obj.dest);
		break;
	    }
	case OPTR_STRING :
	    {
		Output("\tdword\t%s\n",
		       field->data.fieldOptr.data.proc.extra);
		break;
	    }
	case OPTR_STRING_OPTR :
	    {
		Output("\tUN_OPTR\t%s\n",
		       field->data.fieldOptr.data.proc.extra);
		break;
	    }
    }
}

/*
 *	Name: PrintXXXXComp
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for component types
 *
 */
void
PrintByteComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    if (field->data.fieldByte.type != NULL) {
	Output("\t%s\t< %s >",field->data.fieldByte.type,
					field->data.fieldByte.value);
    } else {
	Output("\tbyte\t%s",field->data.fieldByte.value);
    }
    COMMENT_CR(("\t;%s.%s (byteComp)", class->name, comp->name))
}   /* PrintByteComp */

void
PrintWordComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    if (field->data.fieldWord.type != NULL) {
	Output("\t%s\t< %s >",field->data.fieldWord.type,
					field->data.fieldWord.value);
    } else {
	Output("\tword\t%s",field->data.fieldWord.value);
    }
    COMMENT_CR(("\t;%s.%s (wordComp)", class->name, comp->name))
}   /* PrintWordComp */

void
PrintDWordComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    if (field->data.fieldDWord.type != NULL) {
	Output("\t%s\t< %s >",field->data.fieldDWord.type,
					field->data.fieldDWord.value);
    } else {
	Output("\tdword\t%s",field->data.fieldDWord.value);
    }
    COMMENT_CR(("\t;%s.%s (dwordComp)", class->name, comp->name))
}   /* PrintDWordComp */

void
PrintFptrComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    Output("\tUN_DD\t%s",field->data.fieldDWord.value);
    COMMENT_CR(("\t;%s.%s (fptrComp)", class->name, comp->name))
}   /* PrintFptrComp */

void
PrintTypeComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    Output("\t%s\t<%s>",comp->data.symTypeComp.typeName,
					field->data.fieldType.value);
    COMMENT_CR(("\t;%s.%s (typeComp)", class->name, comp->name))
}   /* PrintByteComp */

void
PrintBitFieldComp(ObjectField *field, Symbol *class, Symbol *comp,
		  Symbol *object)
{
    int i;

    PrintBitSize(comp->data.symBitFieldComp.bitSize);
    if (object == NullSymbol) {
	i = field->data.fieldBitField.value;
    } else {
	i = FindBitFieldValue(field, object->data.symObject.class, comp);
    }
    if ((object != NullSymbol) && (object->flags & SYM_HAS_KBD_ACCEL)) {
	i |= comp->data.symBitFieldComp.kbdPathMask;
    }
    Output("0%xh",i);
    COMMENT_CR(("\t;%s.%s (bitFieldComp)", class->name, comp->name))
}   /* PrintBitFieldComp */

void
PrintEnumComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    PrintBitSize(comp->data.symEnumComp.bitSize);
    Output("%d",field->data.fieldEnum.value);
    COMMENT_CR(("\t;%s.%s (enumComp)", class->name, comp->name))
}   /* PrintEnumComp */

void
PrintCompositeComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    if (field == NullObjectField) {
	PrintOptr(NullSymbol);
    } else {
	PrintOptr(field->data.fieldComposite.firstChild);
    }
    COMMENT_CR(("\t;%s.%s (CompPart)", class->name, comp->name))
}   /* PrintCompositeComp */

void
PrintLinkComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    if (field == NullObjectField) {
	PrintOptr(NullSymbol);
    } else {
	PrintOptr(field->data.fieldLink.link);
	if (field->data.fieldLink.isParentLink) {
	    Output(", parent");
	}
    }
    COMMENT_CR(("\t;%s.%s (LinkPart)", class->name, comp->name))
}   /* PrintLinkComp */

void
PrintVisMonikerComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    Symbol *sym;

    if ((field == NullObjectField) ||
		((sym = field->data.fieldVisMoniker.moniker) == NullSymbol)) {
	PrintNptr(NullSymbol);
    } else {
	if (sym->flags & (SYM_DEFINED|SYM_EXTERNAL)) {
	    PrintNptr(sym);
	} else {
	    uicerror(sym, "visual moniker not defined");
	}
    }
    COMMENT_CR(("\t;%s.%s (visMonikerComp)", class->name, comp->name))
}   /* PrintVisMonikerComp */

void
PrintKbdAcceleratorComp(ObjectField *field, Symbol *class, Symbol *comp,
			Symbol *object)
{
    int i;
    char *cp;

    if ((field == NullObjectField) ) {
	Output("\tword\t0");
    } else {
	i = CheckShortcut(field->data.fieldKbdAccelerator.flags,
		    field->data.fieldKbdAccelerator.key >> 16,
		    field->data.fieldKbdAccelerator.key & 0xffff,
		    field->data.fieldKbdAccelerator.specificUI | specificUI,
		    &cp);
	if (i == 0) {
	    uicerror(object, cp);
	}
	Output("\tword\t0x%04x", i);
    }
    COMMENT_CR(("\t;%s.%s (kbdMonikerComp)", class->name, comp->name))
}   /* PrintKbdAcceleratorComp */

void
PrintHintComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    Symbol *sym;

    if ((field == NullObjectField) ||
		((sym = field->data.fieldHint.hintList) == NullSymbol)) {
	PrintNptr(NullSymbol);
    } else {
	if (sym->flags & (SYM_DEFINED|SYM_EXTERNAL)) {
	    PrintNptr(sym);
	} else {
	    uicerror(sym, "hint list not defined");
	}
    }
    COMMENT_CR(("\t;%s.%s (hintComp)", class->name, comp->name))
}   /* PrintHintComp */

void
PrintHelpComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    Symbol *sym;

    if ((field == NullObjectField) ||
		((sym = field->data.fieldHelp.helpEntry) == NullSymbol)) {
	PrintOptr(NullSymbol);
    } else {
	if (sym->flags & (SYM_DEFINED|SYM_EXTERNAL)) {
	    PrintOptr(sym);
	} else {
	    uicerror(sym, "help entry not defined");
	}
    }
    COMMENT_CR(("\t;%s.%s (helpComp)", class->name, comp->name))
}   /* PrintHelpComp */

void
PrintActiveListComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    Symbol *sym;

    if ((field == NullObjectField) ||
		((sym = field->data.fieldActiveList.list) == NullSymbol)) {
	PrintNptr(NullSymbol);
    } else {
	if (sym->flags & (SYM_DEFINED|SYM_EXTERNAL)) {
	    PrintNptr(sym);
	} else {
	    uicerror(sym, "active list not defined");
	}
    }
    COMMENT_CR(("\t;%s.%s (activeListComp)", class->name, comp->name))
}   /* PrintActiveListComp */

void
PrintOptrComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    PrintOD(field);
    COMMENT_CR(("\t;%s.%s (optrComp)", class->name, comp->name))
}   /* PrintOptrComp */

void
PrintActionComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    PrintOD(field);
    COMMENT_CR(("\t;%s.%s (actionComp)", class->name, comp->name))
    Output("\tword\t");
    if (field->data.fieldAction.method == NullSymbol) {
	Output("0");
    } else {
	Output("%s", field->data.fieldAction.method->name);
    }
    COMMENT_CR(("\t;\tMethod for actionComp"))
}   /* PrintActionComp */

void
PrintNptrComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    if (field->data.fieldNptr.target == NullSymbol) {
	PrintNptr(NullSymbol);
    } else if (field->data.fieldNptr.target->flags & (SYM_DEFINED|SYM_EXTERNAL)) {
	PrintNptr(field->data.fieldNptr.target);
    } else {
	uicerror(field->data.fieldNptr.target, "object not defined");
    }
    COMMENT_CR(("\t;%s.%s (nptrComp)", class->name, comp->name))
}   /* PrintNptrComp */

void
PrintHptrComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    PrintHptr(field->data.fieldHptr.target);
    COMMENT_CR(("\t;%s.%s (hptrComp)", class->name, comp->name))
}   /* PrintHptrComp */

/*
 *	To add a component, add a "PrintBiffComp" routine here
 */

/*
 *	Name: PrintFieldData
 *	Author: Tony Requist
 *
 *	Synopsis: Print data for a field
 *
 */
void
PrintFieldData(ObjectField *field, Symbol *class,
	       Symbol *comp, Symbol *object)
{
    switch (comp->type) {
	case STRUCTURE_COMP_SYM :
	    { PrintStructureComp(field, class, comp); break; }
	case BYTE_COMP_SYM :
	    { PrintByteComp(field, class, comp); break; }
	case TYPE_COMP_SYM :
	    { PrintTypeComp(field, class, comp); break; }
	case WORD_COMP_SYM :
	    { PrintWordComp(field, class, comp); break; }
	case DWORD_COMP_SYM :
	    { PrintDWordComp(field, class, comp); break; }
	case FPTR_COMP_SYM :
	    { PrintFptrComp(field, class, comp); break; }
	case BIT_FIELD_COMP_SYM :
	    { PrintBitFieldComp(field, class, comp, object); break; }
	case ENUM_COMP_SYM :
	    { PrintEnumComp(field, class, comp); break; }
	case COMPOSITE_COMP_SYM :
	    { PrintCompositeComp(field, class, comp); break; }
	case LINK_COMP_SYM :
	    { PrintLinkComp(field, class, comp); break; }
	case VIS_MONIKER_COMP_SYM :
	    { PrintVisMonikerComp(field, class, comp); break; }
	case KBD_ACCELERATOR_COMP_SYM :
	    { PrintKbdAcceleratorComp(field, class, comp, object); break; }
	case HINT_COMP_SYM :
	    { PrintHintComp(field, class, comp); break; }
	case HELP_COMP_SYM :
	    { PrintHelpComp(field, class, comp); break; }
	case OPTR_COMP_SYM :
	    { PrintOptrComp(field, class, comp); break; }
	case ACTION_COMP_SYM :
	    { PrintActionComp(field, class, comp); break; }
	case ACTIVE_LIST_COMP_SYM :
	    { PrintActiveListComp(field, class, comp); break; }
	case NPTR_COMP_SYM :
	    { PrintNptrComp(field, class, comp); break; }
	case HPTR_COMP_SYM :
	    { PrintHptrComp(field, class, comp); break; }
	case VARIANT_PTR_SYM:
	    if (field != (ObjectField *)class) {
		Output("\tUN_DD\t%sClass",
		       field->data.fieldVariantPtr.target->name);
	    } else {
		Output("\tdword\t0");
	    }
	    COMMENT_CR(("\t;%s variant superclass", class->name));
	    break;

	/*
	 *	To add a component, add a "PrintBiffComp" routine here
	 */

	default : {
	    Abort("PrintFieldData: unknown comp type for <%s>, %d\n",
					comp->name, comp->type);
	}
    }
}   /* PrintFieldData */

    
/*
 *	Name: PrintClassData
 *	Author: Tony Requist
 *
 *	Synopsis: Print instance data for a class level
 *
 */
Symbol *PrintClassData(Symbol *class,  	/* Class whose data for the object
					 * wants printing */
		    Symbol *object, 	/* Object being printed */
		    int masterHasData)	/* Non-zero if a subclass in the
					 * same master group has data, so a
					 * master part needs to be output even
					 * if the master class itself has no
					 * data */
{
    Symbol *comp;
    ObjectField *field;
    ObjectField *tempField;
    Symbol  *master;

    /*
     * Print the data for all our superclasses first.
     */
    if (class->data.symClass.superclass != NullSymbol) {
        if (class->flags & SYM_CLASS_MASTER) {
	    /*
	     * We are ourselves a master class, so print stuff for our
	     * superclass, saying the master group has no data we know of
	     * so far.
	     */
	    if (class->flags & SYM_CLASS_VARIANT) {
		(void)PrintClassData(FindVariantSuperclass(class, object),
				     object, FALSE);
	    } else {
		(void)PrintClassData(class->data.symClass.superclass, object,
				     FALSE);
	    }
	    master = class;
	} else {
	    if (class->data.symClass.componentPtr == NullSymbol) {
		/*
		 * This class doesn't have any data itself, so print the
		 * superclass passing on the masterHasData we got.
		 */
		master = PrintClassData(class->data.symClass.superclass, object,
							masterHasData);
	    } else {
		/*
		 * Print the superclass, asserting the master group does
		 * indeed have data to print.
		 */
		master = PrintClassData(class->data.symClass.superclass, object,
							TRUE);
	    }
	}
    } else {
	master = NullSymbol;
    }

    /*
     * If this is the master, put out the label for the start of the part.
     */
    if (class->flags & SYM_CLASS_MASTER) {
	if (masterHasData ||
	    (class->data.symClass.componentPtr != NullSymbol) ||
	    (class->flags & SYM_CLASS_VARIANT))
	{
	    Output("%s_%s_part\tlabel\tword\n",
				object->name, class->name, object->name);
	}
    }
    if (class->data.symClass.componentPtr != NullSymbol) {
	if (outdebug) {
	    fprintf(stderr, "PrintClassData: object = '%s' (0x%x)",
		    object->name, (unsigned) object);
	    fprintf(stderr, ", class = '%s' (0x%x)\n", class->name,
		    (unsigned) class);
	}

		/* For each component, print it */

	for (comp = class->data.symClass.componentPtr; comp != NullSymbol;
					comp = comp->data.symByteComp.next) {
	    if (outdebug) {
		fprintf(stderr, " component = '%s' (0x%x)", comp->name,
			(unsigned) comp);
	    }

		/* Find the field to use */
	    field = NullObjectField;
	    if ( !(comp->flags & SYM_STATIC) ) {
		for (tempField = object->data.symObject.firstField;
			    tempField != NullObjectField;
			    tempField = tempField->next) {
		    if (tempField->type == comp) {
			if (field == NullObjectField) {
			    field = tempField;
			} else {
			    uicerror(object,
					"Multiple fields for component <%s>",
					comp->name);
			}
		    }
		}
	    }
	    if (field == NullObjectField) {

			/* No field here, use default (search class first) */

		field = FindDefault(object->data.symObject.class, comp);
	    }

		/* Print it */

	    if (outdebug) {
		fprintf(stderr, ", field = 0x%x", (unsigned) field);
		if (field == NullObjectField) {
		    fprintf(stderr, "\n");
		} else {
		    fprintf(stderr, ", field->type = 0x%x\n",
			    (unsigned) (field->type));
		}
	    }
	    PrintFieldData(field, class, comp, object);
	}
    }

    /*
     * Put out debugging code to make sure the data we just output is the
     * correct instance size for the class.
     */
    if (master != NullSymbol) {
	if ((class->data.symClass.componentPtr != NullSymbol) ||
	    (class->flags & SYM_CLASS_VARIANT))
	{
	    Output("\t.assert ($-%s_%s_part) eq size %sInstance\n",
		   object->name, master->name, class->name);
	} else if ((class != master) &&
		   (class->data.symClass.superclass != NullSymbol))
	{
	    Output("\t.assert size %sInstance eq size %sInstance\n",
		   class->name,
		   class->data.symClass.superclass->name);
	} else if (class == master) {
	    Output("\t.assert size %sInstance eq 0\n", class->name);
	}
    }

    return (master);
}   /* PrintClassData */


/*
 *	Name: PrintVariableData
 *	Author: brianc
 *
 *	Synopsis: Print variable data for a class level
 *
 */
void
PrintVariableData(Symbol *class, Symbol *object)
{
    Symbol *hSym;
    ObjectField *hint;
    char *ptr;

    if ((hSym = object->data.symObject.varData) != NullSymbol) {
	for (hint = hSym->data.symHintList.firstHint;
		hint != NullObjectField;
		hint = hint->next) {
	    if (hint->data.fieldHintEntry.data != NULL) {
		/* hint has data, output the hint word with save-to-state
		   and has-data flags and output the data */
		ptr = UniqueName();
		Output("%s\tlabel\tword\n", ptr);
		Output("\tword\t%s or mask VDF_SAVE_TO_STATE or mask VDF_EXTRA_DATA\n",
			hint->data.fieldHintEntry.name->name);
		Output("\tword\t%s_end-%s\n", ptr, ptr);
		Output("%s\n", hint->data.fieldHintEntry.data);
		Output("%s_end\tlabel\tword\n", ptr);
	    } else {
		/* hint has no data, output just the hint word with
		   save-to-state flag */
		Output("\tword\t%s or mask VDF_SAVE_TO_STATE\n",
			hint->data.fieldHintEntry.name->name);
	    }
	} /* hint entry loop */
    } /* if object has variable data */

    /* print out GCN List data for this object */
    if (object->data.symObject.gcnListOfLists != NullSymbol) {
        Output("\tword\tTEMP_META_GCN or mask VDF_SAVE_TO_STATE or mask VDF_EXTRA_DATA\n");
	Output("\tword\t7\n");
	Output("\tword\toffset %s\n", object->data.symObject.gcnListOfLists->name);
	Output("\tbyte\t0\n");
    }

}   /* PrintVariableData */

/*
 *	Name: OutputStructure
 *	Author: Tony Requist
 *
 *	Synopsis: Print a structure
 *
 */
void
PrintStructureComp(ObjectField *field, Symbol *class, Symbol *comp)
{
    PrintStructureComp2(field, comp->data.symStructureComp.structureType,
			comp->name);
}

void
PrintStructureComp2(ObjectField *field, Symbol *stype, char *name)
{
    Symbol *sfield;
    ObjectField *of;
    ObjectField *tempField;

    if (name != NULL) {
	COMMENT(("\t\t\t; Structure %s\n", name))
    }

		/* For each component, print it */

    for (sfield = stype->data.symStructure.firstField; sfield != NullSymbol;
				    sfield = sfield->data.symByteComp.next) {
	if (outdebug) {
	    fprintf(stderr, " structure component = '%s' (0x%x)",
		    sfield->name, (unsigned) sfield);
	}

	    /* Find the field to use */
	of = NullObjectField;
	if ( !(sfield->flags & SYM_STATIC) ) {
	    for (tempField = field->data.fieldStructure.firstValue;
			tempField != NullObjectField;
			tempField = tempField->next) {
		if (tempField->type == sfield) {
		    if (of == NullObjectField) {
			of = tempField;
		    } else {
			uicerror(sfield,
				"Multiple fields for structure component <%s>",
				 sfield->name);
		    }
		}
	    }
	}
	if (of == NullObjectField) {
	    of = sfield->data.symByteComp.defaultValue;
	}

	    /* Print it */

	if (outdebug) {
	    fprintf(stderr, ", of = 0x%x", (unsigned) of);
	    if (of == NullObjectField) {
		fprintf(stderr, "\n");
	    } else {
		fprintf(stderr, ", of->type = 0x%x\n", (unsigned) of->type);
	    }
	}
	PrintFieldData(of, stype, sfield, NullSymbol);
    }
}   /* PrintStructureComp */

/*
 *	Name: OutputObject
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputObject(Symbol *sym)
{
    Symbol *class;
    Symbol *temp;

    class = sym->data.symObject.class;

    COMMENT((";\n;\tObject '%s' (class = '%s')\n;\n",sym->name, class->name))
    /*
     * For now, don't try to output he type of the chunk
     */
    /* Output("%s\tchunk\t%sBase\n", sym->name, class->name); */
    Output("%s\tchunk\n", sym->name);
    /*
     * Create a label for the start of the chunk (to calculate offsets)
     */
    for (temp = class; temp != NullSymbol;
				temp = temp->data.symClass.superclass) {
	if (temp->flags & SYM_CLASS_MASTER) {
	    Output("start_%s\tlabel\tbyte\n",sym->name);
	    break;
	}
    }
    /*
     * Output class pointer
     */
    Output("\tUN_DD\t%sClass", class->name);
    COMMENT_CR(("\t;MB_class"))

    /*
     * Output superclass and master offsets
     */
    PrintMasterOffsets(class, sym, FALSE);

    /*
     * Output data for class and superclasses
     */
    (void)PrintClassData(class, sym, FALSE);

    /*
     * Output variable data for this object
     */
    if (version20) {
        PrintVariableData(class, sym);
    }

    Output("%s\tendc\n", sym->name);

}   /* OutputObject */

/*
 *	Name: OutputVisMoniker
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputVisMoniker(Symbol *sym)
{
    ObjectField *field;
    Symbol *sp;
    int i = 0;
    char *ptr;

    COMMENT((";\n;\tVis Moniker '%s'\n;\n",sym->name))

    if (version20) {
      Output("%s\tchunk\tVisMoniker\n", sym->name);
    } else {
      Output("%s\tchunk\tVisualMoniker\n", sym->name);
    }

    if (sym->flags & SYM_LIST_MONIKER) {
	for (field = sym->data.symVisMoniker.data.list.firstField;
		field != NullObjectField; field = field->next) {
	    sp = field->data.fieldVMElement.element;
	    Output("\tword\t0%xh", sp->data.symVisMoniker.data.nonList.flags
							| VMT_MONIKER_LIST);
	    COMMENT_CR(("\t;VMLE_type"))
	    PrintOptr(sp);
	    COMMENT_CR(("\t;VMLE_moniker"))
	}
    } else {
	Output("\tbyte\t0%xh", sym->data.symVisMoniker.data.nonList.flags
								& 0xff);
	COMMENT_CR(("\t;VM_type"))

        if (version20) {
	  /*
	   * We are outputting the width for a text moniker.  We need to
	   * calculate and output hint information here to tell the
	   * specific UI what the string width is for 2 common font/size
	   * combinations.
	   */
	  if (!(sym->flags & SYM_GRAPHIC_MONIKER) &&
	      !(sym->flags & SYM_DATA_MONIKER)) {
	      /*
	       * It is a text moniker, find the widths
	       */
	      if (sym->data.symVisMoniker.data.nonList.xSize == 0) {
	      	sym->data.symVisMoniker.data.nonList.xSize =
		  CalcHintedWidth(sym->data.symVisMoniker.data.nonList.data);
	      }
	  }
	  Output("\tword\t%d", sym->data.symVisMoniker.data.nonList.xSize);
	  COMMENT_CR(("\t;VM_width"))
	} else {
 	  Output("\tword\t%d, %d", sym->data.symVisMoniker.data.nonList.xSize,
 				sym->data.symVisMoniker.data.nonList.ySize);
 	  COMMENT_CR(("\t;VM_size.XYS_{width,height}"))
	}

	if (sym->flags & SYM_GRAPHIC_MONIKER) {
	    if (version20) {
	      Output("\tword\t%d",sym->data.symVisMoniker.data.nonList.ySize);
	      COMMENT_CR(("\t;VM_height"))
	    }
	    Output("%s", sym->data.symVisMoniker.data.nonList.data);
	    COMMENT_CR(("\t;Graphic moniker "))
	} else if (sym->flags & SYM_DATA_MONIKER) {
	    Output("%s", sym->data.symVisMoniker.data.nonList.data);
	    COMMENT_CR(("\t;Text moniker as data"))
	} else {
	    if (sym->flags & SYM_CONST_NAV_MONIKER) {
		i = sym->data.symVisMoniker.data.nonList.nav.navChar;
		if (i >= strlen(sym->data.symVisMoniker.data.
						    nonList.data)) {
		    uicerror(sym,
			"navigation value out of range (text = '%s')",
			sym->data.symVisMoniker.data.nonList.data);
		    i = 0;
		}
		Output("\tbyte\t%d", i);
	    } else if (sym->flags & SYM_STRING_NAV_MONIKER) {
		Output("\tbyte\t%s", sym->data.symVisMoniker.data.
						nonList.nav.navString);
	    } else {
		i = sym->data.symVisMoniker.data.nonList.nav.navChar;
		if (i == -1) {
		    Output("\tbyte\t-1");
		} else {
		    if (version20) {
			int j = 0;
			for (ptr = sym->data.symVisMoniker.data.nonList.data;
						(*ptr != i) && (*ptr != '\0');
						ptr++, j++) {
			    if (*ptr == '\\') {
				/* count escaped char as only one char, as
				 * that's what Esp will assemble the thing as */
				if (*(ptr+1) == 'x') {
				    /* hex escape -- 4 chars, so reduce j by 3
				     */
				    j -= 3;
				} else if (isdigit(ptr[1]) &&
					   ptr[1] != '8' &&
					   ptr[1] != '9')
				{
				    /* octal. reduce j by the number of
				     * digits - 1 */
				    int	k;

				    for (k = 1;
					 k < 4 && ptr[k] != '\0' &&
					 isdigit(ptr[k]) && ptr[k] != '8' &&
					 ptr[k] != '9';
					 k++)
				    {
					;
				    }
				    j -= k-1;
				} else {
				    /* standard escape, so reduce
				     * j by 1 to account for the 2 that make
				     * up the escape */
				    j -= 1;
				}
			    }
			}
			if (*ptr == '\0') {
			    j = -2;
			}
			Output("\tbyte\t%d", j);
			i = j;
		    } else {
			ptr = (char *) strchr(sym->data.symVisMoniker.\
							data.nonList.data, i);
		        if (ptr == NULL) {
			    uicerror(sym,
				"navigation char not found (text = '%s')",
				sym->data.symVisMoniker.data.nonList.data);
			    i = 0;
			} else {
			    i = ptr - sym->data.symVisMoniker.data.nonList.data;
			}
			Output("\tbyte\t%d", i);
		    }
		}
	    }
	    COMMENT_CR(("\t;Moniker navigation character"))
	    if (dbcsRelease) {
	    	if ( *(sym->data.symVisMoniker.data.nonList.data) == '\0') {
		    Output("\twchar\t0");
	    	} else {
		    Output("\twchar\t\"%s\",0",
			    sym->data.symVisMoniker.data.nonList.data);
	    	}
	    } else {
	    	if ( *(sym->data.symVisMoniker.data.nonList.data) == '\0') {
		    Output("\tchar\t0");
	    	} else {
		    Output("\tchar\t\"%s\",0",
			    sym->data.symVisMoniker.data.nonList.data);
	    	}
	    }
	    if ((i == -2) && (version20)) {
	        Output(",\"%c\"",
		       sym->data.symVisMoniker.data.nonList.nav.navChar);

	    }
	    COMMENT_CR(("\t;Text moniker "))
	}
    }

    Output("%s\tendc\n", sym->name);
}   /* OutputVisMoniker */

/*
 *	Name: OutputHelpEntry
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputHelpEntry(Symbol *sym)
{
    COMMENT((";\n;\tHelp Entry '%s'\n;\n",sym->name))
    Output("%s\tchunk\tchar\n", sym->name);
    Output("\tchar\t\"%s\",0\n", sym->data.symHelpEntry.text);
    Output("%s\tendc\n", sym->name);
}   /* OutputHelpEntry */

/*
 *	Name: OutputHintList
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputHintList(Symbol *sym)
{
    ObjectField *field;
    char *ptr;

    COMMENT((";\n;\tHint List '%s'\n;\n",sym->name))
    Output("%s\tchunk\tHintEntry\n", sym->name);
    for (field = sym->data.symHintList.firstHint; field != NullObjectField;
				field = field->next) {
	ptr = UniqueName();
	Output("%s\tlabel\tword\n", ptr);
	Output("\tword\t%s", field->data.fieldHintEntry.name->name);
	COMMENT_CR(("\t;Hint constant"))
	Output("\tword\t%s_end-%s\n",ptr,ptr);
	if (field->data.fieldHintEntry.data != NULL) {
	    Output("%s",field->data.fieldHintEntry.data);
	    COMMENT_CR(("\t;Hint data"))
	}
	Output("%s_end\tlabel\tword\n", ptr);
    }
    Output("%s\tendc\n", sym->name);
}   /* OutputHintList */

/*
 *	Name: OutputActiveList
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputActiveList(Symbol *sym)
{
    ObjectField *field;
    int count;

    COMMENT((";\n;\tActive List '%s'\n;\n",sym->name))
    Output("%s\tchunk\toptr\n", sym->name);

    /* output ChunkArrayHeader if Version 2.0 */
    if (version20) {
        count = 0;
        for (field = sym->data.symActiveList.firstActive;
			    field != NullObjectField;
			    field = field->next) {
	    count++;
        }
        Output("\tword\t%d\n",count);	/* CAH_count */
        Output("\tword\t8\n");		/* CAH_elementSize (ActiveListEntry) */
        Output("\tword\t0\n");		/* CAH_curOffset */
        Output("\tword\tsize ChunkArrayHeader\n");	/* CAH_offset */
    }

    for (field = sym->data.symActiveList.firstActive;
			    field != NullObjectField;
			    field = field->next) {
	PrintOptr(field->data.fieldActive.element);
	COMMENT_CR(("\t;object on the active list"))
	Output("\tword\t0\n"); /* extra chunk of data */
	Output("\tword\t0\n"); /* flags byte */
    }
    Output("%s\tendc\n", sym->name);
}   /* OutputActiveList */

/*
 *	Name: OutputGCNList
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputGCNList(Symbol *sym)
{
    ObjectField *field;
    int count;

    if (version20) {

        COMMENT((";\n;\tGCN List '%s'\n;\n",sym->name))
        Output("%s\tchunk\toptr\n", sym->name);

        count = 0;
        for (field = sym->data.symGCNList.firstItem;
			    field != NullObjectField;
			    field = field->next) {
	    count++;
        }
        Output("\tword\t%d\n",count);	/* CAH_count */
        Output("\tword\tsize GCNListElement\n");	/* CAH_elementSize */
        Output("\tword\t0\n");		/* CAH_curOffset */
        Output("\tword\tsize GCNListHeader\n");	/* CAH_offset */
        Output("\tword\t0\n");	/* statusEvent */
        Output("\tword\t0\n");	/* statusData */
        Output("\tword\t0\n");	/* statusCount */

        for (field = sym->data.symGCNList.firstItem;
			    field != NullObjectField;
			    field = field->next) {
	    PrintOptr(field->data.fieldActive.element);
	    COMMENT_CR(("\t;object on gcn list"))
        }
        Output("%s\tendc\n", sym->name);

    } /* if version20 */

}   /* OutputGCNList */

/*
 *	Name: OutputGCNListOfLists
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputGCNListOfLists(Symbol *sym)
{
    Symbol *field;
    int count;

    if (version20) {

        COMMENT((";\n;\tGCN List Of Lists'%s'\n;\n",sym->name))
        Output("%s\tchunk\toptr\n", sym->name);

        count = 0;
        for (field = sym->data.symGCNListOfLists.firstList;
			    field != NullSymbol;
			    field = field->data.symGCNList.nextList) {
	    count++;
        }
        Output("\tword\t%d\n",count);	/* CAH_count */
        Output("\tword\tsize GCNListOfListsElement\n");	/* CAH_elementSize */
        Output("\tword\t0\n");		/* CAH_curOffset */
        Output("\tword\tsize GCNListOfListsHeader\n");	/* CAH_offset */

	/* output GCNListOfListsElements */
        for (field = sym->data.symGCNListOfLists.firstList;
			    field != NullSymbol;
			    field = field->data.symGCNList.nextList) {
	    Output("\tword\t%s\n", field->data.symGCNList.manufID);
	    Output("\tword\t%s or mask GCNLTF_SAVE_TO_STATE\n", field->data.symGCNList.type);
	    Output("\tword\toffset %s\n",
				field->name);
	    COMMENT_CR(("\t;gcn list in gcn list of lists"))
        }
        Output("%s\tendc\n", sym->name);

    } /* if version20 */

}   /* OutputGCNList */

/*
 *	Name: OutputChunk
 *	Author: Tony Requist
 *
 *	Synopsis: Output data for an object
 *
 */
void
OutputChunk(Symbol *sym)
{
    char *cp;
    int i;

    COMMENT((";\n;\tChunk '%s'\n;\n",sym->name))

    if (sym->flags & SYM_CHUNK_IS_EMPTY) {
	Output("%s\tchunk\tbyte\n", sym->name);
    } else {
	if (sym->flags & SYM_CHUNK_IS_STRUCTURE) {
	    Output("%s\tchunk\t%s\n", sym->name,
		    sym->data.symChunk.data.chunkStructure.strucType->name);
	    PrintStructureComp2(sym->data.symChunk.data.chunkStructure
								.strucData,
		       sym->data.symChunk.data.chunkStructure.strucType, NULL);
	} else {
	    cp = sym->data.symChunk.data.chunkText;
	    if (sym->flags & SYM_CHUNK_IS_TEXT) {
		if (dbcsRelease) {
		    Output("%s\tchunk\twchar\n", sym->name);
		} else {
		    Output("%s\tchunk\tchar\n", sym->name);
		}
		if (*cp == 0) {
		    if (dbcsRelease) {
		    	Output("\twchar\t0\n");
		    } else {
		    	Output("\tchar\t0\n");
		    }
		} else {
		    int lastStringFlag;
		    while ((i = strlen(cp)) > 0) {
			if (i > 50) {
			    i = 50;
			    lastStringFlag = FALSE;
			} else {
			    lastStringFlag = TRUE;
			}
			if (dbcsRelease) {
			    Output("\twchar\t\"");
			} else {
			    Output("\tchar\t\"");
			}
			/*
			 * If this isn't the final string, make sure we're not
			 * breaking up a great partnership (a backslash and
			 * its following value)
			 */
			if (!lastStringFlag && (cp[i-1] == '\\')) {
			    if (!isdigit(cp[i]) && cp[i] != 'x') {
				/*
				 * Neither hex nor octal, so skip just
				 * one char
				 */
				i++;
			    } else if (cp[i] == 'x') {
				/*
				 * Hex escape -- always skip at least two,
				 * and maybe a third if it's hex as well.
				 */
				i += 2;
				if (isxdigit(cp[i])) {
				    i++;
				}
			    } else {
				/*
				 * Skip octal digits.
				 */
				if (isdigit(cp[i+1])) {
				    if (isdigit(cp[i+2])) {
					/* 3-digit octal escape */
					i += 3;
				    } else {
					/* 2-digit octal escape */
					i += 2;
				    }
				} else {
				    /* single-digit octal escape */
				    i++;
				}
			    }
			}
			while (i--) {
			    OutputChar(*cp++);
			}
			if (*cp == 0) {
			    Output("\",0\n");
			} else {
			    Output("\"\n");
			}
		    }
		}
	    } else {
		Output("%s\tchunk\tbyte\n", sym->name);
		Output("%s\n",cp);
	    }
	}
    }
    Output("%s\tendc\n", sym->name);
}   /* OutputChunk */

static void
OutputForceLocalization(Symbol *sym,
			ChunkDataType type)
{
    if (version20 && !(sym->flags & SYM_LOC)) {
	sym->data.symChunk.loc = (LocalizeInfo *)malloc(sizeof(LocalizeInfo));
	sym->data.symChunk.loc->instructions = "";
	sym->data.symChunk.loc->min = 0;
	sym->data.symChunk.loc->max = 0;
	sym->data.symChunk.loc->dataTypeHint = type;
	sym->flags |= SYM_LOC;
    }
}

#if !defined(EXTERNAL_LOCALIZATION_FILE)

/*
 *	Name: OutputLocalization
 *	Author: Chris Thomas
 *
 *	Synopsis: Dump an ESP localization directive to the
 *		output ESP file, rather than a separate .rsc file.
 *
 *		This feature was added because there are subtle
 *		problems caused when UIC generates its own .rsc file:
 *
 *		- if the .ui file has the same name as an ESP module,
 *		  the .rsc filename collision causes loc information
 *		  to be lost.
 *		- ESP generates its own localization info for chunks,
 *		  so the uic-defined chunks are entered in the output
 *		  file twice.
 */
static void
OutputLocalization(LocalizeInfo *loc) {
    Output("localize\t");
    if (LOC_MIN(loc) < 0) {
	Output("not");
    } else {
	/*
	 *  Spit out the double-quoted instruction string,
	 *  Anything that isn't printable ascii or otherwise needs to be
	 *  escaped, spit out the octal representation.
	 */
	const unsigned char *cp;
	OutputChar('\"');
	for (cp = (unsigned char *)LOC_INST(loc); cp && *cp != '\0'; cp++) {
	    if ((*cp == '"') || (*cp == '\\') ||
		(*cp < 0x20) || (*cp > 0x7f)) {

		int shift;

		OutputChar('\\');
		for (shift = 6; shift >= 0; shift -= 3) {
		    OutputChar( '0'+((*cp>>shift)&7) );
		}
	    } else {
		OutputChar(*cp);
	    }
	}
	Output("\", %d, %d, %d", LOC_MIN(loc), LOC_MAX(loc), LOC_HINT(loc));
    }
    OutputChar('\n');
}
#endif /* !EXTERNAL_LOCALIZATION_FILE */

/*
 *	Name: OutputResource
 *	Author: Tony Requist
 *
 *	Synopsis: Ouptut data for a resource
 *
 */
void
OutputResource(Symbol *resource)
{
    Symbol 	*sym;
    int		chunkNumber;
#if defined(EXTERNAL_LOCALIZATION_FILE)
    Localize_EnterResource(resource,resource->name);
#endif
    curResource = resource;
    for (sym = resource->data.symResource.firstObject,
	 chunkNumber = (resource->flags & SYM_DATA_RESOURCE) ? 0 : 1;
	 sym != NullSymbol;
	 sym = sym->data.symObject.next,chunkNumber++) {
	switch (sym->type) {
	    case OBJECT_SYM : {
		OutputObject(sym);
		break;
	    }
	    case VIS_MONIKER_SYM : {
		if (!(sym->flags & SYM_LOC)) {
		    OutputForceLocalization(sym, CDT_visMoniker);
		}
		OutputVisMoniker(sym);
		break;
	    }
	    case HELP_ENTRY_SYM : {
		OutputHelpEntry(sym);
		break;
	    }
	    case HINT_LIST_SYM : {
		OutputHintList(sym);
		break;
	    }
	    case ACTIVE_LIST_SYM : {
		OutputActiveList(sym);
		break;
	    }
	    case GCN_LIST_SYM : {
		OutputGCNList(sym);
		break;
	    }
	    case GCN_LIST_OF_LISTS_SYM : {
		OutputGCNListOfLists(sym);
		break;
	    }
	    case CHUNK_SYM : {
		if (sym->flags & SYM_CHUNK_IS_TEXT) {
		    OutputForceLocalization(sym, CDT_text);
		} else {
		    /* to deal with bitmaps and things of that ilk, at least
		     * give resedit a name; it will examine the chunk to figure
		     * out what manner of beast it is */
		    OutputForceLocalization(sym, CDT_unknown);
		}
		OutputChunk(sym);
		break;
	    }
	}
	if(sym->flags & SYM_LOC){
	    LOC_NUM(CHUNK_LOC(sym))	= chunkNumber;
	    LOC_NAME(CHUNK_LOC(sym))	= sym->name;

#if defined(EXTERNAL_LOCALIZATION_FILE)
	    Localize_AddLocalization(CHUNK_LOC(sym)); 
#else
	    OutputLocalization(CHUNK_LOC(sym));
#endif
	}
    }
}   /* OutputResource */


/*
 *	Name: OutputResourceFlags
 *	Author: Tony Requist
 *
 *	Synopsis: Ouptut flags for an object resource
 *
 */
void
OutputResourceFlags(Symbol *resource)
{
    Symbol *sym;
    int	nchunks;

    curResource = resource;
    /*
     * Open flags chunk
     */
    COMMENT((";\n;\tFlags for resource '%s'\n;\n",resource->name))
    Output("%s_flags\tchunk\tbyte\n", resource->name);

    /*
     * Flags for the flags chunk
     */
    Output("\tbyte\tmask OCF_IGNORE_DIRTY");
    COMMENT_CR(("\t\t;flags for flags chunk"))

    for (nchunks = 1, sym = resource->data.symResource.firstObject;
	 sym != NullSymbol;
	 nchunks++, sym = sym->data.symObject.next) {
	Output("\tbyte\t");
	if (sym->flags & SYM_IGNORE_DIRTY) {
	    Output("mask OCF_IGNORE_DIRTY or ");
	}
	if (sym->flags & SYM_VARDATA_RELOC) {
	    Output("mask OCF_VARDATA_RELOC or ");
	}
	switch (sym->type) {
	    case OBJECT_SYM : {
		Output("mask OCF_IN_RESOURCE or mask OCF_IS_OBJECT");
		break;
	    }
	    case VIS_MONIKER_SYM :
	    case HELP_ENTRY_SYM :
	    case HINT_LIST_SYM :
	    case GCN_LIST_SYM :
	    case GCN_LIST_OF_LISTS_SYM :
	    case ACTIVE_LIST_SYM :
	    case CHUNK_SYM :
	    {
		Output("mask OCF_IN_RESOURCE");
		break;
	    }
	}
	COMMENT_CR(("\t;'%s'",sym->name))
    }

    if (nchunks & 1) {
	/*
	 * Odd number of chunks, but Esp will make it even, so put out an
	 * extra flag byte to avoid later death.
	 */
	Output("\tbyte\t0");
	COMMENT_CR(("\t;rounding"));
    }
    
    /*
     * Close flags chunk
     */
    Output("%s_flags\tendc\n", resource->name);
    Output("ForceRef\t%s_flags\n", resource->name);

}   /* OutputResourceFlags */


/*
 *	Name: DoOutput
 *	Author: Tony Requist
 *
 *	Synopsis: Output the data.
 *
 */
void DoOutput(void)
{
    Symbol *resource;

	/*
	 * For each resource
	 */
    for (resource = firstResource; resource != NullSymbol;
			resource = resource->data.symResource.nextResource) {
	COMMENT((";\n;\tData for resource '%s'\n;\n", resource->name))
	if (resource->flags & SYM_DATA_RESOURCE) {
	    Output("%s\tsegment\tlmem LMEM_TYPE_GENERAL\n\n", resource->name);
	} else {
	    Output("%s\tsegment\tlmem LMEM_TYPE_OBJ_BLOCK", resource->name);
	    Output(", mask LMF_HAS_FLAGS or mask LMF_IN_RESOURCE");
	    if (! (resource->flags & SYM_NOT_DETACHABLE) ) {
		Output(" or mask LMF_DETACHABLE");
	    }
	    Output("\n\n");

	    if (!version20) {
	        Output("\tword\t0");
	        COMMENT_CR(("\t\t;TLMBH_tempList"))
	    }
	    Output("\tword\t0");
	    COMMENT_CR(("\t\t;OLMBH_inUseCount"))
	    if (version20) {
		Output("\tword\t0");
		COMMENT_CR(("\t\t;OLMBH_interactibleCount"))
		if (resource->data.symResource.resourceOutput != NullSymbol) {
		    Output("\toptr\t$s",
			   resource->data.symResource.resourceOutput->name);
		} else {
		    Output("\toptr\t0");
		}
	        COMMENT_CR(("\t\t;OLMBH_output"))
	    }
	    Output("\tword\tsize %s", resource->name);
	    COMMENT_CR(("\t;OLMBH_resourceSize"))

	    OutputResourceFlags(resource);
	}
	OutputResource(resource);
	Output("\n%s\tends\n\n",resource->name);
    }
}   /* DoOutput */
