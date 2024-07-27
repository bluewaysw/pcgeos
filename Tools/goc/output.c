/***********************************************************************
 * PROJECT:	  PCGEOS
 * MODULE:	  goc -- output
 * FILE:	  output.c
 *
 * AUTHOR:  	  Tony Requist
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * DESCRIPTION:
 *	Output routines for goc
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: output.c,v 1.70 96/07/09 17:09:04 jimmy Exp $";
#endif lint

#include     <config.h>
#include    "goc.h"
#include    "scan.h"
#include    "parse.h"
#include    "stringt.h"
#include    "map.h"
#include    "strwid.h"

#include <localize.h>
#include    <ctype.h>
#include    <compat/string.h>
#include    <assert.h>

Symbol *processClass;

/* Flags kept for each chunk in an object block */

#define OCF_VARDATA_RELOC   	0x10
#define OCF_DIRTY		0x08
#define OCF_IGNORE_DIRTY	0x04
#define OCF_IN_RESOURCE		0x02
#define OCF_IS_OBJECT		0x01

/* VisMoniker flags */

#define VMLET_GS_SIZE		0x3000
#define VMLET_STYLE		0x0f00
#define VMLET_MONIKER_LIST	0x0080
#define VMLET_GSTRING		0x0040
#define VMLET_GS_ASPECT_RATIO	0x0030
#define VMLET_GS_COLOR		0x000f

#define VMLET_GS_SIZE_OFFSET 12
#define VMLET_STYLE_OFFSET 8
#define VMLET_GS_ASPECT_RATIO_OFFSET 4
#define VMLET_GS_COLOR_OFFSET 0

#define VMT_MONIKER_LIST	0x80
#define VMT_GSTRING		0x40
#define VMT_GS_ASPECT_RATIO	0x30
#define VMT_GS_COLOR		0x0f

#define VMT_GS_ASPECT_RATIO_OFFSET 4
#define VMT_GS_COLOR_OFFSET 0

/* Class flags */

#define CLASSF_HAS_DEFAULT      0x80
#define CLASSF_MASTER_CLASS     0x40
#define CLASSF_VARIANT_CLASS    0x20
#define CLASSF_DISCARD_ON_SAVE  0x10
#define CLASSF_NEVER_SAVED      0x08
#define CLASSF_HAS_RELOC        0x04
#define CLASSF_C_HANDLERS       0x02

/* Flags for a local memory block */

#define LMF_HAS_FLAGS           0x8000
#define LMF_IN_RESOURCE         0x4000
#define LMF_DETACHABLE          0x2000
#define LMF_DUPLICATED          0x1000
#define LMF_RELOCATED           0x0800
#define LMF_AUTO_FREE           0x0400
#define LMF_IN_LMEM_ALLOC       0x0200
#define LMF_IS_VM               0x0100
#define LMF_NO_HANDLES          0x0080
#define LMF_NO_ENLARGE          0x0040
#define LMF_RETURN_ERRORS       0x0020
#define LMF_DEATH_COUNT         0x0007

/* Flags for object variable storage */

#define VDF_EXTRA_DATA		0x0002
#define VDF_SAVE_TO_STATE	0x0001

/* Flags for GCN lists */

#define GCNLTF_SAVE_TO_STATE	0x0001

/* Flags for relocations */

#define RELOC_END_OF_LIST 0
#define RELOC_RELOC_HANDLE 1
#define RELOC_RELOC_SEGMENT 2
#define RELOC_RELOC_ENTRY_POINT 3



/***********************************************************************
 *				OutputCheckIfString
 ***********************************************************************
 * SYNOPSIS:	    Checks type against both "char[]" and "TCHAR[]".
 * CALLED BY:	    (INTERNAL) OutputVariableData
 * RETURN:	    FALSE iff it's not a string
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	JAG	1/28/96   	Initial Revision
 *
 ***********************************************************************/
static inline Boolean
OutputCheckIfString (const char *ctype)
{
    return ((strcmp(ctype, "char[]") == 0) ||
	    (strcmp(ctype, "TCHAR[]") == 0));
}	/* End of OutputCheckIfString.	*/




/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FmtBytes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	format various quantites (words, bytes) into
                an array for dumping a chunk

CALLED BY:	OutputChunk

PASS:		dest array, format string, ...

RETURN:		Void.

DESTROYED:

PSEUDO CODE/STRATEGY:

CHECKS:

KNOWN BUGS/SIDE EFFECTS/IDEAS:	everything gets passed as an int.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JP	5/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#define HighWord(x)  (((x)&0xff00)>>8)
#define LowWord(x)   ((x)&0xff)

int OutputLineNumberWithCount(int lineNumber, char *fileName,Boolean print);

void
FmtBytes(char *dest,char *fmt, ...)
{
  int w;
  va_list ap;

  va_start(ap,fmt);
  for(;*fmt; fmt++){
    w = va_arg(ap,int);

    switch(*fmt){
    case 'b':
      *dest++ = (char) (w&0xff);
      break;
    case 'w':
      *dest++ = (char) LowWord(w);
      *dest++ = (char) HighWord(w);
      break;
    default:
      assert(0);
    }
  }
}




/***********************************************************************
 *
 * FUNCTION:	OutputSubst
 *
 * DESCRIPTION:	Output a string, substituting "(optr)&" for @
 *
 * CALLED BY:   misc
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
OutputSubstOptr(char *str)
{
    OutputSubst(str, "@", "(optr)&");
}

void
OutputSubst(char *str, char *find, char *repl)
{
    char *cp;
    while (*str != '\0') {
	cp = OurStrPos(str, find);
	while (cp > str) {
	    OutputChar(*str++);
	}
	if (*str != '\0') {
	    Output("%s", repl);
	    str += strlen(find);
	}
    }
}

/***********************************************************************
 *
 * FUNCTION:	CopySubst
 *
 * DESCRIPTION:	Copy a string, substituting "(optr)&" for @
 *
 * CALLED BY:   misc
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
CopySubst(char *dest, char *source, char *find, char *repl)
{
    char *cp;

    while (*source != '\0') {
	cp = OurStrPos(source, find);
	while (cp > source) {
	    *dest++ = *source++;
	}
	if (*source != '\0') {
	    strcpy(dest, repl);
	    dest += strlen(repl);
	    source += strlen(find);
	}
    }
    *dest = '\0';
}

/***********************************************************************
 *
 * FUNCTION:	FindDefault
 *
 * DESCRIPTION:	Find the default value for a field
 *
 * CALLED BY:   OutputObjectData, ...
 *
 * RETURN:	InstanceValue *
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
InstanceValue *
FindDefault(Symbol *class, char *field)
{
    InstanceValue *defVal;
    /*
     * Look for a default value for this field.  To do this we need
     * to look up the class tree.
     */
    while (class != NullSymbol) {
	for (defVal = class->data.symClass.defaultList;
	     defVal != NullInstanceValue;
	     defVal = defVal->next) {
	    if (defVal->name == field) {
		return defVal;
	    }
	}
	if (class->flags & SYM_CLASS_VARIANT) {
	    class = NullSymbol;
	} else {
    	    class = class->data.symClass.superclass;
	}
    }
    return(NullInstanceValue);
}


/***********************************************************************
 *				LocateSuperForVariant
 ***********************************************************************
 * SYNOPSIS:	Locate the superclass for a variant object
 * CALLED BY:	OutputMasterFields, OutputMasterData
 * RETURN:	TRUE if superclass found
 * SIDE EFFECTS:*superPtr is set to the Symbol * of the class found
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/92		Initial Revision
 *
 ***********************************************************************/
Boolean
LocateSuperForVariant(Symbol	    *class, 	/* Bottom-most class in master
						 * group containing variant */
		      Symbol	    *object,	/* Variant object */
		      Symbol	    **superPtr)	/* Place to store superclass,
						 * if found */
{
    InstanceValue   *value;
    char    	    *superName;
    Symbol  	    *tempClass;

    /* Go up to the class that has the default variant class */

    for (tempClass = class; !(tempClass->flags & SYM_CLASS_VARIANT);
	      	    	    tempClass = tempClass->data.symClass.superclass);
    value = FindDefault(class, tempClass->data.symClass.instanceData->name);
    if (value == NullInstanceValue) {
	superName = tempClass->data.symClass.instanceData->
	    	    	    	    data.symRegInstance.defaultValue;
    } else {
    	superName = value->value;
    }

    if (object != NullSymbol) {
	for (value = object->data.symObject.firstInstance;
	     value != NullInstanceValue;
	     value = value->next)
	{
	    if (value->name == tempClass->data.symClass.instanceData->name) {
		superName = value->value;
		break;
	    }
	}
    }

    if (superName != NULL) {
	*superPtr = Symbol_Find(superName, TRUE);

	assert(*superPtr != NullSymbol);
	return(TRUE);
    } else {
	return(FALSE);
    }
}
/***********************************************************************
 *
 * FUNCTION:	OutputBaseStructure
 *
 * DESCRIPTION:	Output a base structure for an object
 *
 * CALLED BY:   parsing code
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
OutputBaseStructure(Symbol *class,
		    Symbol *chunk,
		    char *root,
		    Symbol *bottomClass,
		    int *masterNumPtr,
		    Boolean vflag)
{
    /*
     * If this is not a master class then move up the class tree until we find a
     * master class, as that's where the master offset field is located. All
     * the rest is just _metaBase crap.
     */
    if (class->data.symClass.superclass != NullSymbol) {
	Symbol	*super;
	Boolean	newvflag;

	super = class->data.symClass.superclass;
	if (class->flags & SYM_CLASS_VARIANT) {
	    /*
	     * See if the variant's been resolved for us.
	     */
	    newvflag = (!LocateSuperForVariant(bottomClass, chunk, &super) ||
			vflag);
	} else {
	    newvflag = vflag;
	}

	/*
	 * If going to a new master level, it means we're going to a nested
	 * structure...
	 */
	if (class->flags & SYM_CLASS_MASTER) {
	    Output("{");
	}
	OutputBaseStructure(super, chunk, root,
			    ((class->flags & SYM_CLASS_MASTER) ?
			     super : bottomClass),
			    masterNumPtr,
			    newvflag);

	if (class->flags & SYM_CLASS_MASTER) {
	    /*
	     * Close the nested structure for the previous level.
	     */
	    Output("}");
	    *masterNumPtr += 1;
	    if (vflag) {
		Output(", 0");
	    } else {
		Output(", word_offsetof(struct _%s, m%d)",
		       NAME(chunk), *masterNumPtr);
	    }
	}
    } else {
	Output("(ClassStruct *)&%sClass", root);
    }
}

/***********************************************************************
 *				OutputMasterFields
 ***********************************************************************
 * SYNOPSIS:	Put out structure fields for the master levels of this
 *		object.
 * CALLED BY:	OutputChunkData, self
 * RETURN:	nothing
 * SIDE EFFECTS:*masterNumPtr is incremented if this is a master class
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/92		Initial Revision
 *
 ***********************************************************************/
static void
OutputMasterFields(Symbol *class,   	    /* Current class */
		   Symbol *object,  	    /* Object for which structure is
					     * being defined (for figuring
					     * variant build) */
		   Symbol *bottomClass,	    /* Bottom-most class in current
					     * master level */
		   Boolean variant, 	    /* Non-zero if we've hit an
					     * unresolved variant in the course
					     * of our upward traversal */
		   int *masterNumPtr)	    /* Current master level number */
{
    if (class->data.symClass.superclass != NullSymbol) {
	Symbol	*super = class->data.symClass.superclass;

	if (class->flags & SYM_CLASS_VARIANT) {
	    /*
	     * Look for value for the field in the object. If not there, look
	     * for default value in first instance variable for bottom-most
	     * class (default from higher classes within the same master
	     * level should have been carried along...).
	     * If neither applies, use the specified superclass, but make it
	     * clear that we've gone through an unresolved variant, so
	     * we shouldn't put out fields for any master classes up the
	     * tree, but we want the number to match...
	     */
	    Boolean newVariant;

	    newVariant = (!LocateSuperForVariant(bottomClass, object, &super) ||
			  variant);
	    OutputMasterFields(super, object, super, newVariant, masterNumPtr);

	} else if (class->flags & SYM_CLASS_MASTER) {
	    /*
	     * Recurse with the superclass, passing the superclass as the
	     * bottom-most class in the next master group.
	     */
	    OutputMasterFields(class->data.symClass.superclass,
			       object,
			       class->data.symClass.superclass,
			       variant,
			       masterNumPtr);
	} else {
	    /*
	     * Recurse up the class tree.
	     */
	    OutputMasterFields(class->data.symClass.superclass,
			       object,
			       bottomClass,
			       variant,
			       masterNumPtr);
	}

	/*
	 * Superclasses handled. If this is a master or variant class, up
	 * the master number.
	 */
	if (class->flags & (SYM_CLASS_MASTER|SYM_CLASS_VARIANT)) {
	    *masterNumPtr += 1;
	    if (!variant) {
		/*
		 * Instance data for this thing actually needs to be given,
		 * so put out a field for it.
		 */
		Output("%sInstance m%d;", bottomClass->data.symClass.root,
		       *masterNumPtr);
	    }
	}
    }
}

/***********************************************************************
 *
 * FUNCTION:	OutputObjectData
 *
 * DESCRIPTION:	Output object data
 *
 * CALLED BY:   parsing code
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
char OOD_temp[2000];
char OOD_buf[2000];


void
OutputObjectData(Symbol *class,
		 Symbol *object,
		 int skipFlag)	    /* TRUE if should skip first instance var */
{
    Symbol *iptr;
    InstanceValue *val;
    InstanceValue *valueToUse;
    int firstFlag = TRUE;

    if (class->data.symClass.superclass != NullSymbol &&
    	    	    !(class->flags & SYM_CLASS_VARIANT) &
	    	    !(class->flags & SYM_CLASS_MASTER)) {
	OutputObjectData(class->data.symClass.superclass, object, skipFlag);
	skipFlag = FALSE;
	firstFlag = FALSE;
    }

    /*
     * Output the fields, skipping the first one if this class
     * has no master levels (since in this case the first field
     * is the base structure)
     */
    for (iptr = class->data.symClass.instanceData; iptr != NullSymbol;
		iptr = iptr->data.symRegInstance.next) {
	InstanceValue staticInst;

	staticInst.value = OOD_buf;
	if (!skipFlag) {
	    valueToUse = FindDefault(object->data.symObject.class, iptr->name);
	    if (valueToUse != NullInstanceValue) {
	    	strcpy(OOD_buf, valueToUse->value);
	    } else {
		if (iptr->data.symRegInstance.defaultValue != NULL) {
		    strcpy(OOD_buf, iptr->data.symRegInstance.defaultValue);
		} else {
		    strcpy(OOD_buf, "0");
		}
	    }
	    if (defaultdebug) {
		fprintf(stderr,
			"%%%% Looking for field %s of class %s, returns %s\n",
			iptr->name,
			object->data.symObject.class->name,
			(valueToUse == NullInstanceValue) ?
			"NULL" : valueToUse->value);
	    }
	    /*
	     * Look for a value given for this field
	     */
	    for (val = object->data.symObject.firstInstance;
		    val != NullInstanceValue; val = val->next) {
		if (val->name == iptr->name) {


		    strcpy(OOD_temp, OOD_buf);
		    if (val->value != NULL) {
		    	CopySubst(OOD_buf, val->value, "@default", OOD_temp);
		    }
		    valueToUse = val;
		    break;
		}
	    }
	    if (!firstFlag) {
		Output(", ");
	    }
	    switch (iptr->type) {
		case VARIANT_PTR_SYM: {
		    if (valueToUse == NullInstanceValue) {
			Output("{%s}", OOD_buf);
		    } else {
			Output("{(ClassStruct *)&%s}",
			       valueToUse->value);
		    }
		    break;
		}
		case REG_INSTANCE_SYM : {
		    if (valueToUse == NullInstanceValue) {
			Output(OOD_buf);
		    } else {
			if (!strcmp(valueToUse->value, "process"))
			{
			    /*
			     * Special case: if "process" is given as the
			     * output, set the process class
			     */
			    if (processClass == NullSymbol) {
			    	gocerror(NullSymbol,
					 "No process class defined");
			    } else {
			    	Output("(optr)&%s", processClass->name);
			    }
			} else {
	    	    	    OutputSubstOptr(OOD_buf);
			}
		    }
		    break;
		}
		case COMPOSITE_SYM :
		case LINK_SYM : {
		  if (valueToUse != NullInstanceValue) {
		      if (valueToUse->data.instLink.isParentLink) {
			  /* need to set  the first bit, a GI_link flag */
                          Output("{(optr)(((char *)&%s)+1)}",
                                 valueToUse->data.instLink.link->name);
			}else{
                          Output("{(optr)&%s}",
                                 valueToUse->data.instLink.link->name);
		      }
		  } else {
                      Output("{0}");
		  }
		  break;
		}
		case OPTR_SYM : {
		    if (valueToUse != NullInstanceValue) {
			if (valueToUse->data.instReg.flags & INST_ADD_OPTR) {
			    Output("(optr)&");
			}
			if (!strcmp(valueToUse->value,
				    "process")) {
			    Output("%s", processClass->name);
			} else {
			    Output("%s", valueToUse->value);
			}
		    } else {
		    	if (iptr->data.symRegInstance.defaultValue != NULL) {
		    	    Output("%s",
				    iptr->data.symRegInstance.defaultValue);
			} else {
			    Output("0");
			}
		    }
		    break;
		}
		case CHUNK_INST_SYM : {
		    if (valueToUse != NullInstanceValue) {
			Output("(ChunkHandle)(dword)&%s",
			       	    valueToUse->value);
		    } else {
			Output("(ChunkHandle)0");
		    }
		    break;
		}
		case VIS_MONIKER_SYM : {
		    if (valueToUse != NullInstanceValue) {
			Output("(ChunkHandle)(dword)&%s",
			       	    valueToUse->value);
		    } else {
			Output("0");
		    }
		    break;
		}
		case KBD_ACCELERATOR_SYM  : {
		    char *cp;
		    int i;

		    if (valueToUse != NullInstanceValue) {
	    	    	i = CheckShortcut(
			    valueToUse->data.instKbdAccelerator.flags,
		    	    valueToUse->data.instKbdAccelerator.key >> 16,
		    	    valueToUse->data.instKbdAccelerator.key & 0xffff,
		    	    valueToUse->data.instKbdAccelerator.specificUI
					    	    	    | specificUI,
		    	    &cp);
			if (i == 0) {
			    gocerror(object, cp);
			}
                        Output("0x%04x", i);
		    } else {
			Output("0");
		    }
		    break;
		}
	    }
	}
	firstFlag = FALSE;
	skipFlag = FALSE;
    }
}


/***********************************************************************
 *				OutputMasterData
 ***********************************************************************
 * SYNOPSIS:	Output the various master groups defined for the object.
 * CALLED BY:	OutputChunkData, self
 * RETURN:	nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	7/10/92		Initial Revision
 *
 ***********************************************************************/
static void
OutputMasterData(Symbol *class,
		 Symbol *object,
		 Symbol *bottomClass,
		 Boolean oflag)	/* TRUE if should actually print data for this
				 * class. Set when the class is the bottom
				 * class of a master group... */
{
    if (class != NullSymbol) {
	Symbol	*super;

	super = class->data.symClass.superclass;
	if (class->flags & SYM_CLASS_VARIANT) {
	    if (LocateSuperForVariant(bottomClass, object, &super)) {
		OutputMasterData(super, object, super, TRUE);
	    }
	} else if (class->data.symClass.masterLevel > 1) {
	    /*
	     * Recurse, telling it to print the master group's data only if
	     * this level we're at now is a master level (=> the next level
	     * up is the bottom of a master group).
	     */
	    OutputMasterData(super,
			     object,
			     ((class->flags & SYM_CLASS_MASTER) ? super :
			      bottomClass),
			     (class->flags & SYM_CLASS_MASTER));
	}
	if (oflag) {
	    Output(",{");
	    OutputObjectData(class, object, FALSE);
	    Output("}");
	}
    }
}

/***********************************************************************
 *
 * FUNCTION:	OutputClassTable
 *
 * DESCRIPTION:	Output a class table for a class
 *
 * CALLED BY:   DoFinalOutput
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/

int relocTable[] = {
    RELOC_RELOC_ENTRY_POINT,
    RELOC_RELOC_HANDLE,
    RELOC_RELOC_HANDLE
};

void
OutputClassTable(Symbol *class)
{
    Reloc     *rel;
    int       flag;
    int       cmethEntries;
    Method    *meth;
    char      preTypeString[] = "_far ";
    char      postTypeString[] = " far";
    char      *segName;

    if (class->data.symClass.classSeg != NullSymbol) {
	segName = class->data.symClass.classSeg->name;
    } else if (classSegName) {
	segName = classSegName;
    } else {
	segName = NULL;
	    *preTypeString = '\0';
	    *postTypeString = '\0';
    }

    /*
     * For Borland, we want things to look like:
     *
     * type far name[] = {}
     *
     * While for High C we want something more like:
     *
     * _far type name[] = {}
     *
     * Of course, if there's no active class segment, both of "far" strings
     * a nullified above.
     */
    if (compiler == COM_BORL) {
	*preTypeString = '\0';
    } else {
	*postTypeString = '\0';
    }

    /*
     * For Borland, start the segment the class resides in here. High C has
     * graciously remembered which segment the thing's going into from the
     * extern.
     */

    if (segName) {
	if (compiler == COM_BORL) {
	    CompilerStartSegment("", segName);
	} else {
	    CompilerStartSegment("_CLASSSEG_", segName);
	}
    }

    /*
     * We do not want the relocation tables to lie at offset 0, so
     * prevent this:
     */
    if (class->flags & (SYM_CLASS_HAS_INST_RELOC | SYM_CLASS_HAS_VD_RELOC)) {
	Output("extern char _%s_HackByte;\nchar _%s_HackByte;\n",
	       class->data.symClass.root, class->data.symClass.root);
    }
    /*
     * If the class has an instance data relocation table then output it
     */
    if (class->flags & SYM_CLASS_HAS_INST_RELOC) {
	Output("%sObjRelocation%s _%s_Reloc[]={", preTypeString,
	       postTypeString, class->data.symClass.root);
	for (rel = class->data.symClass.relocList; rel != NullReloc;
	     	    	    	    	    	    	rel = rel->next) {
	    if (rel->tag == NullSymbol) {
		int count;
		for (count = 0; count < rel->count; count++) {
		    Output("{%d, word_offsetof(%sInstance, %s)",
				    relocTable[rel->type],
				    class->data.symClass.root, rel->text);
		    if (rel->type != RT_HPTR) {
			Output("+2");
		    }
		    if (count > 0) {
			Output("+%d*sizeof(%s)", count, rel->structName);
		    }
		    Output("}, ");
		}
	    }
	}
	Output("{0,0}};\n");
    }

    /*
     * If the class has a vardata data relocation table then output it
     */
    if (class->flags & SYM_CLASS_HAS_VD_RELOC) {
	/*
	 * The reloc table must go into the DATA segment (idata).
	 */
	Output("%sVarObjRelocation%s _%s_vdReloc[]={", preTypeString,
	       postTypeString, class->data.symClass.root);
	for (rel = class->data.symClass.relocList; rel != NullReloc;
	     	    	    	    	    	    	rel = rel->next) {
	    if (rel->tag != NullSymbol) {
		int count;
		for (count = 0; count < rel->count; count++) {
		    if (strcmp(rel->text, "0")) {
			Output("{%d|%d, word_offsetof(%s, %s)",
			       relocTable[rel->type],
			       rel->tag->data.symVardata.tag,
			       rel->tag->data.symVardata.ctype, rel->text);
		    } else {
			Output("{%d|%d, 0",
			       relocTable[rel->type],
			       rel->tag->data.symVardata.tag);
		    }
		    if (rel->type != RT_HPTR) {
			Output("+2");
		    }
		    if (count > 0) {
			Output("+%d*sizeof(%s)", count, rel->structName);
		    }
		    Output("}, ");
		}
	    }
	}
	Output("{0,0}};\n");
    }

    if (compiler == COM_BORL) {
	/*
	 * Turn on word alignment to ensure relocation handler gets placed
	 * properly.
	 */
	Output("#pragma option -a\n");
    }

    /* START CLASSSTRUCT */
    Output("%sClassStruct%s %s%s = {%s", preTypeString, postTypeString, class->name, compiler == COM_BORL ? "[]" : "", compiler == COM_BORL ? "{" : "");
    if (class->data.symClass.superclass != NullSymbol) {
	if (class->flags & SYM_CLASS_VARIANT) {
	    /*
	     * Variant classes have 1:0 for the superclass.
	     */
	    Output("(ClassStruct *)((dword)1 << 16), ");
	} else {
	    Output("(ClassStruct *)&%s, ",
		   class->data.symClass.superclass->name);
	}
    } else {
	Output("(ClassStruct *)0, ");
    }
    /*
     * Output Class_masterOffset and Class_messageCount
     */
    if (class->data.symClass.masterLevel) {
        Output("%d, ", 4+(class->data.symClass.masterLevel*2)-2);
    } else {
        Output("0, ");
    }
    /*
     * Output Class_messageCount
     */
    Output("%d, ", class->data.symClass.methodCount);
    /*
     * Output Class_instanceSize
     */
    if (class->flags & SYM_PROCESS_CLASS) {
    	Output("4, ");
    } else {
    	Output("sizeof(%sInstance), ", class->data.symClass.root);
    }
    /*
     * Output Class_vdRelocTable
     */
    if (class->flags & SYM_CLASS_HAS_VD_RELOC) {
	Output("%s &_%s_vdReloc, ",
	       compilerCastForOffset,
	       class->data.symClass.root);
    } else {
	Output("0, ");
    }
    /*
     * Output Class_relocTable
     */
    if (class->flags & SYM_CLASS_HAS_INST_RELOC) {
	Output("%s &_%s_Reloc, ",
	       compilerCastForOffset,
	       class->data.symClass.root);
    } else {
	Output("0, ");
    }
    /*
     * Output class flags (setting C_METHODS flag)
     */
    Output("%d, ", CLASSF_C_HANDLERS |
	   ((class->flags & SYM_NEVER_SAVED) ? CLASSF_NEVER_SAVED : 0)|
	   ((class->flags & SYM_CLASS_VARIANT) ? CLASSF_VARIANT_CLASS : 0)|
	   ((class->flags & SYM_CLASS_MASTER) ? CLASSF_MASTER_CLASS : 0)|
	   ((class->flags & SYM_CLASS_HAS_RELOC) ? CLASSF_HAS_RELOC : 0));

    Output("%d%s};\n", class->data.symClass.masterMessages, compiler == COM_BORL ? "}" : "");
    /* END CLASSSTRUCT */

    /*
     * Output message table
     */
    if (class->data.symClass.methodCount != 0) {
    	flag = FALSE;
	Output("%sMessage%s _Messages_%s[]={", preTypeString,
	                                       postTypeString,
	                                       class->name);
	for (meth = class->data.symClass.firstMethod; meth != NullMethod;
	     meth = meth->next)
	{
	    if (meth->message->data.symMessage.class == NULL) {
		/* relocation method that doesn't go in this table */
		continue;
	    }

	    if (flag) {
		Output(", ");
	    }
	    Output("%d", meth->message->data.symMessage.messageNumber);
	    flag = TRUE;
	}
	Output("};\n");

    	flag = FALSE;

	/*
	 * For some reason, Borland can't deal with type (MessageMethod *),
	 * but coasts through with a typedef to the same thing...???
	 */

	if (compiler == COM_BORL) {
	    Output("typedef MessageMethod *MessageMethodP;");
	    Output("%sMessageMethodP%s _Methods_%s[]={", preTypeString,
		   postTypeString, class->name);
	} else {
	    Output("%sMessageMethod%s *_Methods_%s[]={", preTypeString,
		   postTypeString, class->name);
	}

	for (meth = class->data.symClass.firstMethod; meth != NullMethod;
	     meth = meth->next)
	{
	    if (meth->message->data.symMessage.class == NULL) {
		/* relocation method that doesn't go in this table */
		continue;
	    }

	    if (flag) {
		Output(", ");
	    }
            Output("(MessageMethod *)%s", meth->name);
	    flag = TRUE;
	}
	Output("};\n");

	flag = FALSE;
	cmethEntries = 0;
	Output("%sCMethodDef%s _htypes_%s[]={", preTypeString,
	       postTypeString, class->name);
	for (meth = class->data.symClass.firstMethod; meth != NullMethod;
	     meth = meth->next)
	{
	    if (meth->message->data.symMessage.class == NULL) {
		/* relocation method that doesn't go in this table */
		continue;
	    }

	    if (flag) {
		Output(", ");
	    }
	    Output("{%s, %d}",
		   GenerateMPDString(meth->message, MPD_PASS_AND_RETURN),
		   meth->htd);
	    flag = TRUE;
	    cmethEntries += 1;
	}
	Output("};\n");
	if((compiler == COM_WATCOM) && (cmethEntries % 2)) {
	    Output("char _%s_HackByte2 = 0;\n",
					class->data.symClass.root);
	}
    }
    /*
     * Output relocation method at the end of the above tables.
     */
    if (class->flags & SYM_CLASS_HAS_RELOC) {
	for (meth = class->data.symClass.firstMethod;
	     meth != NullMethod;
	     meth = meth->next)
	{
	    if (meth->message->data.symMessage.class == NULL) {
		break;
	    }
	}
	assert(meth != NullMethod);

	if (compiler == COM_BORL) {
	    Output("typedef MessageMethod *MessageMethodP;");
	    Output("%sMessageMethodP%s _Reloc_%s[] = {(MessageMethod *)&%s};\n",
		   preTypeString, postTypeString, class->name, meth->name);
	} else {
	    Output("%sMessageMethod%s *_Reloc_%s = (MessageMethod *)&%s;\n",
		   preTypeString, postTypeString, class->name, meth->name);
	}

    }

    if (compiler == COM_BORL) {
	/*
	 * Turn *off* word alignment to ensure relocation tables get defined
	 * properly.
	 */
	Output("#pragma option -a-\n");
    }
    
    if (segName) {
	if (compiler == COM_BORL) {
	    CompilerEndSegment("", segName);
	} else {
	    CompilerEndSegment("_CLASSSEG_", segName);
	}
    }
}



/***********************************************************************
 *
 * FUNCTION:	OutputLineNumber
 *
 * DESCRIPTION:	Output line number information. compiler dependent.
 *              tries to print the least amount of info, so it remembers
 *              the filename and doesn't put out the name the next time
 *              unless it has to.
 *
 * CALLED BY:
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
OutputLineNumberForSym(Symbol *sym)
{
    OutputLineNumber(sym->lineNumber, sym->fileName);
}
/*
 * MSC doesn't like '\\' in the path name: it thinks they escape other
 * characters in the string (which really doesn't make much sense, because
 * it's unlikely that one would want to include a file with newlines and
 * tab characters in its name.
 *
 * The buffer below holds the fileName, but with '\\' changed to '/'.
 *
 */
void
OutputLineNumber(int lineNumber, char *fileName)
{
    OutputLineNumberWithCount(lineNumber,fileName,TRUE);
}

char outputLineNumberBuf[1024];

int
OutputLineNumberWithCount(int lineNumber, char *fileName,Boolean print)
{
    int	length;
    char *from;
    char *to;
    static char *prevFile = NULL;/* string table entry for previous fileName */

    switch(compiler){
      case COM_HIGHC:

	if (strcmp(fileName, inFile) == 0) {/* must transform name for HighC */
	    fileName = outFile;
	}
	sprintf(outputLineNumberBuf,"\n# %d \"%s\"\n", lineNumber, fileName);
    	break;

      case COM_WATCOM:
      case COM_MSC:
      case COM_BORL:
	if(fileName == prevFile){/* assumes fileName is in the string table */
	    sprintf(outputLineNumberBuf,"#line %d", lineNumber);
	}else{
	    sprintf(outputLineNumberBuf,"#line %d \"", lineNumber);
	    /* copy in the filename, changing '\\' to '/' for MSC */
	    for(from = fileName,
		to = &outputLineNumberBuf[strlen(outputLineNumberBuf)];
		*from;
		from++,to++){
		*to = (*from =='\\' && 
			((compiler==COM_MSC) || (compiler==COM_WATCOM)))? '/' : *from;
	    }
	    sprintf(to,"\"");
	    prevFile =  fileName;
	}
	break;
      default:
	assert(0);
    }
    if(print){
	length = Output("\n%s\n",outputLineNumberBuf);
    } else {
	/* there are two newlines added, but different OS's will print them */
	/* differently */
	length  = strlen(outputLineNumberBuf) + 2 * NEWLINE_SIZE;
    }

    return length;
}



/***********************************************************************
 *
 * FUNCTION:	OutputLineDirectiveOrNewlinesForFile
 *
 * DESCRIPTION:
 *         output a bunch of newlines or a line directive to resynch
 *         the given file with the output file.
 *
 * PASS:    difference: number of lines that must be added to the output
 *                         file to set it's line number to lineNumber.
 *          fileName:   the input file name
 *          lineNumber: the lineNumber we want the output to be set to
 *
 * RETURN:  1 if used line directive, else 0
 *
 * CALLED BY: OutputInstanceData, OutputLineDirectiveOrNewlines
 *
 *
 * REVISION HISTORY:
 *	name	date		description
 *	----	----		-----------
 *	josh	9/92
 *
 ***********************************************************************/
int OutputLineDirectiveOrNewlinesForFile(int difference,
					 char *fileName,
					 int lineNumber)
{
    /* calculate the count of chars output for a line directive*/

    int charCount = OutputLineNumberWithCount(lineNumber,fileName,FALSE);


    /* compare it with  the count of chars for a series of newlines */
    /* if difference is for some reason negative, do a directive.   */

    if(difference * NEWLINE_SIZE > charCount || difference < 0){
	OutputLineNumber(lineNumber,fileName);
	return 1;
    }
  else {
    while(difference-- > 0){
      Output("\n");
    }
    return 0;
  }
}

/***********************************************************************
 *
 * FUNCTION:	OutputVariableData
 *
 * DESCRIPTION:	Output an object's variable data storage area
 *
 * CALLED BY:   parsing code
 *
 * RETURN:	number of bytes of variable data
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	brianc	10/91		Initial Revision
 *
 ***********************************************************************/
Boolean
OutputVariableData(Symbol *class, Symbol *object, Boolean setup)
{
    if (object->data.symObject.vardata != NullVardataValue) {
	VardataValue *vd;

	/*
	 * Make a structure definition for the
	 * var data so that we can output all the hints as a
	 * single structure and avoid the word alignment of
	 * variables.  Its name is _vs_<object->name>.
	 */
	if (setup) {
	    int counter = 1;
	    Output("struct {");
	    for (vd = object->data.symObject.vardata;
		    vd != NullVardataValue;
		    vd = vd->next) {
		Output("word _%dh; ", counter);
		if (strlen(vd->value) != 0) {
		    if (OutputCheckIfString(vd->type->data.symVardata.ctype))
		    {
			/*
			 * Deal with string data. We can't put a [] into the
			 * typedef, as it's an incompletely-specified type
			 * in an inappropriate context, so use the initializer
			 * for the thing to determine the size.
			 */
			Output("word _%ds; char _%dd[sizeof(%s)]; ",
			       counter, counter, vd->value);
		    } else {
			if(vd->arraySize == NULL){
			    Output("word _%ds; %s _%dd%s; ", counter,
				   vd->type->data.symVardata.ctype, counter,
				   vd->type->data.symVardata.typeSuffix);
			} else{
			    Output("word _%ds; %s _%dd[%s]; ", counter,
				   vd->type->data.symVardata.ctype, counter,
				   vd->arraySize);
			}
		    }
		}
		counter++;
	    } /* vardata loop */
	    Output("} v;");
	} else {
	    for (vd = object->data.symObject.vardata;
		    vd != NullVardataValue;
		    vd = vd->next)
	    {
		if (strlen(vd->value) == 0) {
		    Output("%d|%d, ", vd->type->data.symVardata.tag,
			    	      VDF_SAVE_TO_STATE);
		} else {
		    Output("%d|%d|%d, ",
			   vd->type->data.symVardata.tag,
			   VDF_SAVE_TO_STATE, VDF_EXTRA_DATA);
		    if (OutputCheckIfString(vd->type->data.symVardata.ctype))
		    {
			Output("4+sizeof(%s), %s",
			       vd->value, vd->value);
		    } else if(vd->arraySize == NULL){
			Output("4+sizeof(%s), ",
			       vd->type->data.symVardata.ctype);
			OutputSubstOptr(vd->value);
		    } else {
			Output("4+sizeof(%s)*%s, ",
			       vd->type->data.symVardata.ctype,
			       vd->arraySize);
			OutputSubstOptr(vd->value);
		    }
		    Output(", ");
		}
	    } /* vardata loop */
	} /* if setup or nor */
	return(TRUE);
    } else {
	return(FALSE);
    }
}


/***********************************************************************
 *
 * FUNCTION:	OutputByteArray
 *
 * DESCRIPTION:	output N bytes with commas between them. Used for dumping
 *              gstring headers
 * CALLED BY:   OutputChunk()
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	3/91		Initial Revision
 *
 ***********************************************************************/
void OutputByteArray(char *bytes, int length)
{
  while(length-- > 0){
    Output("%d," , (unsigned char) *bytes++);
  }
}


/***********************************************************************
 *
 * FUNCTION:	OutputChunk
 *
 * DESCRIPTION:	Output a chunk
 *
 * CALLED BY:   DoFinalOutput
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
OutputChunk(Symbol *chunk)
{
    if(localize){
	Localize_AddLocalization(CHUNK_LOC(chunk));
    }

    OutputLineNumberForSym(chunk);
    switch (chunk->type) {
	case CHUNK_SYM : {
	    if (chunk->flags & SYM_IS_CHUNK_ARRAY) {
		char *hname;
		/*
		 * Its a chunk array
		 */
	    	if (strlen(chunk->data.symChunk.headerType) != 0) {
		    /*
		     * Custom header
		     */
		    hname = chunk->data.symChunk.headerType;
		} else {
		    if (chunk->flags & SYM_IS_ELEMENT_ARRAY) {
			hname = "ElementArrayHeader";
		    } else {
			hname = "ChunkArrayHeader";
		    }
		}
		/*
		 * Note that we do not output the correct number of
		 * elements.  The linker takes care of this for us, we
		 * just output the element size.
		 */
		if (chunk->flags & SYM_IS_ELEMENT_ARRAY) {
	    	    if (strlen(chunk->data.symChunk.headerType) != 0) {
			Output("%s %s _%s%s = %s{{{0, sizeof(%s), 0, "
			       "sizeof(%s)}, 0xffff}, ",
			       hname, lms, chunk->name, _ar,_op,
			       chunk->data.symChunk.ctype, hname);
		    	OutputSubstOptr(chunk->data.symChunk.headerData);
		    	Output("}%s;",_cl);
		    } else {
			Output("%s %s _%s%s = %s{{0, sizeof(%s), 0, "
			       "sizeof(%s)}, 0xffff}%s; ",
			       hname, lms, chunk->name,_ar,_op,
			       chunk->data.symChunk.ctype, hname,_cl);
		    }
		} else {
	    	    if (strlen(chunk->data.symChunk.headerType) != 0) {
			Output("%s %s _%s%s = %s{{0, sizeof(%s), 0, "
			       "sizeof(%s)}, ",
			       hname, lms, chunk->name,_ar,_op,
			       chunk->data.symChunk.ctype, hname);
		    	OutputSubstOptr(chunk->data.symChunk.headerData);
		    	Output("}%s;",_cl);
		    } else {
			Output("%s %s _%s = {0, sizeof(%s), 0, "
			       "sizeof(%s)}; ",
			       hname,lms, chunk->name,
			       chunk->data.symChunk.ctype, hname);
		    }
		}

		Output("%s %s _carray_%s[] = ",
		       chunk->data.symChunk.ctype,
		       lms,
		       chunk->name);
		OutputSubstOptr(chunk->data.symChunk.data);
		Output(";\n");
	    } else {
		/*
		 * Its a normal chunk
		 */
		if (chunk->flags & SYM_CHUNK_NEEDS_QUOTES) {
		    if (dbcsRelease && (chunk->data.symChunk.ctype[3] != 'A')) {
			Output("%s %s _%s%s = ", chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix);
			Scan_OutputMultiByteString(
						   chunk->data.symChunk.ctype[3], chunk->data.symChunk.data);
			Output(";");
		    } else {
			Output("%s %s _%s%s = \"%s\";",
			       chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix,
			       chunk->data.symChunk.data);
		    }
		} else {
		    /*
		     * Used by some of the cases below to *temporarily* nuke
		     * the " at the end of the chunk.
		     */
		    int finalChar = (strlen(chunk->data.symChunk.data) - 1);

		    /*
		     * Let's check for S" (or just " if were in sjis mode)
		     * at the beginning to see if we need to translate this
		     * sucker.
		     */

		    if ((chunk->data.symChunk.data[0] == 'S') &&
			(chunk->data.symChunk.data[1] == '"')) {

			Output("%s %s _%s%s = ", chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix);

			/*
			 * Nuke the final '"' out of the data string.
			 * Remember to put it back, otherwise
			 * duplicate strings will become gradually
			 * shorter.
			 */
			chunk->data.symChunk.data[finalChar] = '\0';
			Scan_OutputMultiByteString('S',
					   &(chunk->data.symChunk.data[2]));
			chunk->data.symChunk.data[finalChar] = '"';
			Output(";");
		    } else if ((chunk->data.symChunk.data[0] == '"') &&
			       (defStringType == sjisStringType)) {

			Output("%s %s _%s%s = ", chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix);

			/*
			 * Nuke the final '"' out of the data string.
			 * Remember to put it back, otherwise
			 * duplicate strings will become gradually
			 * shorter.
			 */
			chunk->data.symChunk.data[finalChar] = '\0';
			Scan_OutputMultiByteString('S',
					   &(chunk->data.symChunk.data[1]));
			chunk->data.symChunk.data[finalChar] = '"';
			Output(";");

		    } else if ((chunk->data.symChunk.data[0] == '"') &&
			       (defStringType == lStringType)) {
			Output("%s %s _%s%s = L%s;",
			       chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix,
			       chunk->data.symChunk.data);

		    } else if ((chunk->data.symChunk.data[0] == '1') &&
			       (chunk->data.symChunk.data[1] == '"')) {

			Output("%s %s _%s%s = %s;",
			       chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix,
			       &(chunk->data.symChunk.data[1]));

		    } else if ((chunk->data.symChunk.data[0] == 'T') &&
			       (chunk->data.symChunk.data[1] == '"')) {

			Output("%s %s _%s%s = ", chunk->data.symChunk.ctype,
			       lms, chunk->name,
			       chunk->data.symChunk.typeSuffix);

			if (defStringType == lStringType) {
			    Output("L%s;", &(chunk->data.symChunk.data[1]));
			} else if (defStringType == sjisStringType) {

			    /*
			     * Nuke the final '"' out of the data string.
			     * Remember to put it back, otherwise
			     * duplicate strings will become gradually
			     * shorter.
			     */
			    chunk->data.symChunk.data[finalChar] = '\0';
			    Scan_OutputMultiByteString('S',
				              &(chunk->data.symChunk.data[2]));
			    chunk->data.symChunk.data[finalChar] = '"';
			    Output(";");

			} else {
			    Output("%s;", &(chunk->data.symChunk.data[1]));
			}
		    } else {
			/*
			 * if it is a scalar, make it into an
			 * array for Borland
			 */
			Output("%s %s _%s%s=%s",
			       chunk->data.symChunk.ctype,
			       lms,
			       chunk->name,
			       (*chunk->data.symChunk.typeSuffix == '\0'?
				_ar:chunk->data.symChunk.typeSuffix),
			       (*chunk->data.symChunk.typeSuffix == '\0'?
				_op:""));
			OutputSubstOptr(chunk->data.symChunk.data);
			Output("%s;",
			       (*chunk->data.symChunk.typeSuffix == '\0')? _cl:"");
		    }
		}
	    }
	    break;
	}
	case OBJECT_SYM : {
	    Symbol *class;
	    Boolean hasVarData;
	    int	masterNum;

	    /*
	     * If the object has any master classes then we actually want
	     * to output a <class>InstanceBase structure (which has the
	     * base structure followed by the instance structure).
	     */
	    class = chunk->data.symObject.class;

	    /*
	     * If we have variable data for this object, we'll need to
	     * define a new structure that is the normal instance data
	     * plus the variable data, all to avoid the f**king word
	     * alignment problems.
	     * The structure is named _ovds_<chunk->name>.
	     *
	     * OutputVariableData(X,X,TRUE) will output a structure for the
	     * variable data itself with name _vs_<chunk->name>.
	     *
	     * 7/10/92: revised output format. We don't create a typedef for
	     * the variable data. Instead it becomes a nameless structure
	     * type inside the object. Nor to we use xxxInstanceBase structures
	     * any more. An object definition looks like:
	     *	struct _objName {
	     *	    xxxBase b;	    if object has master levels...
	     *	    xxxInstance m1; master group 1 data
	     *	    xxxInstance m2; master group 2 data
	     *	    struct {vardata stuff} vd;
	     *	} _objName = {initializer...};
	     *
	     * Only if the object has neither master levels nor vardata do
	     * we use the xxxInstance structure directly -- ardeb.
	     */
	    if ((chunk->data.symObject.vardata == NullVardataValue) &&
		(class->data.symClass.masterLevel == 0))
	    {
		/*
		 * Has neither vardata nor master groups, so we can just
		 * use the instance structure straight.
		 */
		Output("%sInstance %s _%s%s = %s{",
		       class->data.symClass.root,
		       lms,
		       chunk->name,_ar,_op);
		Output("{(ClassStruct *)&%sClass}", class->data.symClass.root);
		OutputObjectData(class, chunk, TRUE);
		Output("}%s;\n",_cl);
	    } else {
		/*
		 * Define structure to hold the base, master levels, and
		 * vardata.
		 */
		Output ("struct _%s {", chunk->name);
		if (class->data.symClass.masterLevel != 0) {
		    Output("%sBase b; ", class->data.symClass.root);
		    masterNum = 0;
		    OutputMasterFields(class, chunk, class, FALSE, &masterNum);
		    hasVarData = OutputVariableData(class, chunk, TRUE);
		} else {
		    Output("%sInstance i;", class->data.symClass.root);
		    hasVarData = OutputVariableData(class, chunk, TRUE);
		}
		Output("} %s _%s%s=%s{", lms, chunk->name,_ar,_op);

		if (class->data.symClass.masterLevel != 0) {
		    /*
		     * Master levels involved here. First put out the contents
		     * of the base structure.
		     */
		    masterNum = 0;
		    Output("{");
		    OutputBaseStructure(class,
					chunk,
					class->data.symClass.root,
					class,
					&masterNum,
					FALSE);
		    Output("}");
		    /*
		     * Now put out the individual master groups.
		     */
		    OutputMasterData(class, chunk, class, TRUE);
		} else {
		    /*
		     * No master levels, so put out the class pointer and follow
		     * it with the instance data.
		     */
		    Output("{{(ClassStruct *)&%sClass}",
			   class->data.symClass.root);

		    OutputObjectData(class, chunk, TRUE);
		    Output("}");
		}

		if (hasVarData) {
		    Output(",{");
		    (void)OutputVariableData(class, chunk, FALSE);
		    Output("}");
		}
		Output("}%s;\n",_cl);
	    }
	    break;
	}

	case GCN_LIST_SYM : {
	    SymbolListEntry *sle;
	    int count;

	    count = 0;
	    for (sle = chunk->data.symGCNList.firstItem;
		 sle != NullSymbolListEntry; sle = sle->next) {
		     count++;
	    }
	    Output("GCNListHeader %s _%s%s =%s{{%d, sizeof(GCNListElement),"
		   "0, sizeof(GCNListHeader)}, 0, 0, 0}%s; ",
		   lms, chunk->name,_ar,_op, count,_cl);
	    if (count != 0) {
		Output("GCNListElement %s _e_%s[] = {",lms, chunk->name);
		for (sle = chunk->data.symGCNList.firstItem;
		     sle != NullSymbolListEntry; sle = sle->next) {
			 Output("{(optr)&%s}, ", sle->entry->name);
		}
		Output("};");
	    }
	    Output("\n");
	    break;
	}
	case GCN_LIST_OF_LISTS_SYM : {
	    Symbol *sle;
	    int count;

	    count = 0;
	    for (sle = chunk->data.symGCNListOfLists.firstList;
		 sle != NullSymbol; sle = sle->data.symGCNList.nextList) {
		     count++;
	    }
	    Output("GCNListOfListsHeader %s _%s%s = %s{{%d, "
		   "sizeof(GCNListOfListsElement), 0,"
		   "sizeof(GCNListOfListsHeader)}}%s;",
		   lms,
		   chunk->name,_ar,_op, count,_cl);
	    if (count != 0) {
		Output("GCNListOfListsElement %s _e_%s[] = {",
		       lms,
		       chunk->name);
		for (sle = chunk->data.symGCNListOfLists.firstList;
		     sle != NullSymbol; sle = sle->data.symGCNList.nextList) {
			 Output("{ {%s, %s|%d}, ",
					sle->data.symGCNList.manufID,
					sle->data.symGCNList.type,
					GCNLTF_SAVE_TO_STATE);
			 Output("(ChunkHandle)(optr)&%s }, ", sle->name);
		}
		Output("};");
	    }
	    Output("\n");
	    break;
	}
	case VIS_MONIKER_CHUNK_SYM : {
	    if (chunk->flags & SYM_LIST_MONIKER) {
		/*
		 * Output list moniker
		 */
		SymbolListEntry *sle;
		/*
		 * Output list moniker
		 */
		Output("VisMonikerListEntry %s _%s[] = {",lms, chunk->name);
		for (sle = chunk->data.symVisMoniker.list;
		     sle != NullSymbolListEntry; sle = sle->next) {
			 Output("{%d, (optr)&%s}, ", VMLET_MONIKER_LIST |
			   ((sle->entry->data.symVisMoniker.vmType.gsColor<<
			    	VMLET_GS_COLOR_OFFSET) & VMLET_GS_COLOR) |
			   ((sle->entry->data.symVisMoniker.vmType.style<<
			    	VMLET_STYLE_OFFSET) & VMLET_STYLE) |
			   ((sle->entry->data.symVisMoniker.vmType.aspectRatio<<
    	    	    VMLET_GS_ASPECT_RATIO_OFFSET) & VMLET_GS_ASPECT_RATIO) |
			   ((sle->entry->flags &SYM_GSTRING_MONIKER)
			    ?(VMLET_GSTRING|
			     ((sle->entry->data.symVisMoniker.vmType.gsSize <<
			      VMLET_GS_SIZE_OFFSET) & VMLET_GS_SIZE))
			    :0),
			    sle->entry->name);
		}
		Output("};\n");
	    } else {
		if (chunk->flags & SYM_GSTRING_MONIKER) {
		    /*
		     * Output gstring moniker
		     *
		     * unfortunately, the visMonikerWithGstring is a five
		     * byte quantity, so the HighC compiler would not always
		     * allow the gstring to appear right after this thing
		     * without padding. Were it 4 bytes, like the
		     * visMonikerWithText (used below), we could dump it out,
		     * and then the string, because they are guaranteed to
		     * appear one right after the other, without any compiler
		     * generated padding.
		     *
		     * The solution is to dump out a big char array, with the
		     * first 5 bytes being the visMonikerWithGstring, and the
		     * rest being the gstring data.
		     *
		     */
		    char vmwgs[5];

		    /* fill the VM_TYPE field for this vismoniker */


		    FmtBytes(vmwgs,"bww",
			     (((chunk->data.symVisMoniker.vmType.gsColor<<
			       VMT_GS_COLOR_OFFSET) & VMT_GS_COLOR) | VMT_GSTRING |
			      ((chunk->data.symVisMoniker.vmType.aspectRatio<<
			       VMT_GS_ASPECT_RATIO_OFFSET) & VMT_GS_ASPECT_RATIO)),
			     chunk->data.symVisMoniker.vmXSize,
			     chunk->data.symVisMoniker.vmYSize);

		    Output("char %s _%s[] = {", lms,chunk->name);

		    /* output the visMonikerWithGstring */
		    OutputByteArray(vmwgs,5);
		    OutputLineNumber(chunk->data.symVisMoniker.startLine,
				     chunk->fileName);
		    Output(chunk->data.symVisMoniker.vmText);
		    Output("};\n");


		} else {
		    /*
		     * Output text moniker
		     */
		    /*
		     * Find the widths
		     */
		    if (chunk->data.symVisMoniker.vmXSize == 0) {
			chunk->data.symVisMoniker.vmXSize =
			    CalcHintedWidth(chunk->data.symVisMoniker.vmText);
		    }
		    Output("VisMonikerWithText %s _%s%s=%s{",
			   lms,chunk->name,_ar,_op);
                    Output("{%d, 0x%04x}, ",
			   ((chunk->data.symVisMoniker.vmType.gsColor<<
			        VMT_GS_COLOR_OFFSET) & VMT_GS_COLOR) |
			   ((chunk->data.symVisMoniker.vmType.aspectRatio<<
                    VMT_GS_ASPECT_RATIO_OFFSET) & VMT_GS_ASPECT_RATIO),
			   chunk->data.symVisMoniker.vmXSize);

		    switch (chunk->data.symVisMoniker.navType) {
		      /* NT_STRING and NT_CHAR are very similar:    */
		      /* get the char to search for, use its index  */
		        case NT_STRING :
			case NT_CHAR : {

			    int i;
			    char *ptr;
			    char charToSearchFor;

			    if (chunk->data.symVisMoniker.navType == NT_CHAR) {
				charToSearchFor = chunk->data.symVisMoniker.navChar;
			    } else {
				charToSearchFor = *chunk->data.symVisMoniker.vmText;
			    }
			    ptr = (char *) strchr(chunk->data.symVisMoniker.vmText, charToSearchFor);
			    if (ptr == NULL) {
				yyerror("navigation char not found (text ="
					" '%s')",
					chunk->data.symVisMoniker.vmText);
				i = 0;
			    } else {
				i = ptr - chunk->data.symVisMoniker.vmText;
			    }
			    Output("%d", i);
			    break;
			}
			case NT_CONST :
			    Output("%d", chunk->data.symVisMoniker.navConst);
			    break;
		    }
		    Output("}%s;",_cl);

		    if (dbcsRelease && (chunk->data.symVisMoniker.ctype[3] != 'A')) {
			Output("%s %s _%s_text[] = ",
			       chunk->data.symVisMoniker.ctype, lms,
			       chunk->name);
			Scan_OutputMultiByteString(chunk->data.symVisMoniker.ctype[3], chunk->data.symVisMoniker.vmText);
			Output(";\n");
		    } else {
			Output("char %s _%s_text[] = \"%s\";\n", lms,
			       chunk->name, chunk->data.symVisMoniker.vmText);
		    }
		}
	    }
	    break;
	}
    } /* switch */
    Output("\n");
}

/***********************************************************************
 *
 * FUNCTION:	OutputMethodAntiWarningCode
 *
 * DESCRIPTION:	Output some code at the start of a method to avoid
 *              compiler warnings about pself and oself.
 *
 * CALLED BY:   yylex
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	josh	7/92		Initial Revision
 *
 ***********************************************************************/
void OutputMethodAntiWarningCode(Method *meth)
{

  switch(compiler){
  case COM_HIGHC : {
    Output("pragma Off(warn); ");
    if (!(meth->class->flags &
	  SYM_PROCESS_CLASS)) {
      switch (meth->model) {
      case MM_FAR:
      case MM_NEAR:
	Output("pself; ");
	break;
      case MM_BASED:
	Output("sself; pself; ");
	break;
      }
    }
    Output("oself; message; ");
    Output("pragma On(warn); ");
  }
      break;
  case COM_BORL: {
      /* Output("\n#pragma warn -eff\n"); */
      /*     Output("\n#pragma warn .eff"); */
      /* OutputLineNumber(yylineno,curFile->name); */

  }
    break;
  case COM_WATCOM:
    Output("\n#pragma disable_message(303)\n");
    OutputLineNumber(yylineno,curFile->name);
    break;
  case COM_MSC:
    break;
  default:
    assert(0);
  }
}



/***********************************************************************
 *
 * FUNCTION:	OutputResource
 *
 * DESCRIPTION:	Output a resource table
 *
 * CALLED BY:   DoFinalOutput
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
OutputResource(Symbol *resource)
{
    Symbol *chunk;
    int i;
    int flagsChunk;
    char *headerType;
    char buf[100];
    int roundedNumChunks;
    int flags;
    int outputChunkCount = 0;

    if(localize){
	Localize_EnterResource((Opaque)resource,resource->name);
    }

    /*
     * If this resource isn't an LMem Block (eg., it contains class records),
     * then we don't want any of this stuff.
     */
    if (resource->flags & SYM_RESOURCE_NOT_LMEM) {
	return;
    }

    flagsChunk = (resource->flags & SYM_OBJECT_BLOCK) ? 1 : 0;
    roundedNumChunks =
	(resource->data.symResource.numberOfChunks+flagsChunk+1) & ~1;
    Output("\n");
    CompilerStartSegment("__DATA_", resource->name);
    Output("\n");
    /*
     * Output flags chunk (if this resource has flags)
     */
    if (flagsChunk) {
	outputChunkCount++;
	Output("byte %s __%s_Flags[]={OCF_IGNORE_DIRTY, ", lms,resource->name);
	for (chunk = resource->data.symResource.firstChunk;
	       chunk != NullSymbol; chunk = chunk->data.symChunk.nextChunk) {
	    Output("%d,", OCF_IN_RESOURCE |
		    ((chunk->flags & SYM_OBJECT_HAS_VD_RELOC) ?
		     	    	    	    OCF_VARDATA_RELOC : 0)|
		    ((chunk->flags & SYM_IGNORE_DIRTY) ? OCF_IGNORE_DIRTY : 0)|
		    ((chunk->flags & SYM_IS_OBJECT) ? OCF_IS_OBJECT : 0));
	}
	/*
	 * Pad the flags to a multiple of 4 (+ 2 to account for size word)
	 */
	if ((resource->data.symResource.numberOfChunks+1+2) % 4 != 0) {
	    for (i  = 0;
		 i < 4-((resource->data.symResource.numberOfChunks+1+2) % 4);
		 i++) {
		     Output("0, ");
	    }
	}
	Output("};\n");
    }
    /*
     * Output the chunks (with line numbers)
     */
    for (chunk = resource->data.symResource.firstChunk; chunk != NullSymbol;
	    	    	    chunk = chunk->data.symChunk.nextChunk) {
	 if (!(chunk->flags & SYM_IS_EMPTY_CHUNK)) {

	     /* get the chunk's number in the resource for localization */
	     /* if it happens to be a localizable chunk */
	     if(CHUNK_LOC(chunk)){
		 LOC_NUM(CHUNK_LOC(chunk))= outputChunkCount;
	     }
	     outputChunkCount++;
	     OutputChunk(chunk);
	 }
    }
    CompilerEndSegment("__DATA_", resource->name);
    Output("\n");

    /*
     * Output the handle table
     */
    CompilerStartSegment("__HANDLES_", resource->name);
    /*
     * If this block is an object block then output the handle for the flags
     * chunk
     */
    if(compiler == COM_WATCOM) {
	sprintf(buf, "__based(__segname(\"__HANDLES_%s\"))", resource->name);
    } 
    else {
	buf[0] = 0;
    }
    if (flagsChunk) {
    	Output("%s %s _%s_Flags%s = %s%s&__%s_Flags%s;",
	       compilerOffsetTypeName,
	       compiler == COM_WATCOM ? buf : compilerFarKeyword,
	       resource->name,
	       _ar,
	       _op,
	       compilerCastForOffset,
	       resource->name,
	       _cl);
    }
    for (chunk = resource->data.symResource.firstChunk; chunk != NullSymbol;
	    	    	    	chunk = chunk->data.symChunk.nextChunk) {
	/*
	 * Output handle for a chunk.  We want:
	 *  	word _far MyChunk = (word)(dword)&_MyChunk;
	 * or   word _far MyChunk[] ={ (word)(dword)&_MyChunk};
	 */
	Output("%s %s %s%s =%s%s",
	       compilerOffsetTypeName,
	       compiler == COM_WATCOM ? buf : compilerFarKeyword,
	       chunk->name,
	       _ar,
	       _op,
	       compilerCastForOffset);
	if (chunk->flags & SYM_IS_EMPTY_CHUNK) {
	    Output("0xffff");
	} else {
	    Output("&_%s", chunk->name);
	}
	Output("%s;",_cl);
    }
    /*
     * Output an even number of chunks
     */
    if ((resource->data.symResource.numberOfChunks+flagsChunk) & 1) {
	Output("%s %s _pad_%sHandles%s=%s0%s;",
	       compilerOffsetTypeName,
	       compiler == COM_WATCOM ? buf : compilerFarKeyword,
	       resource->name,
	       _ar,
	       _op,
	       _cl);
    }
    Output("\n");
    CompilerEndSegment("__HANDLES_", resource->name);
    Output("\n");

    /*
     * Output the header
     */
    CompilerStartSegment("__HEADER_", resource->name);
    Output("\n");
    /*
     * If a header type was given, use it
     */
    if (resource->data.symResource.header_ctype != NULL) {
    	headerType = resource->data.symResource.header_ctype;
    } else if (resource->flags & SYM_OBJECT_BLOCK) {
	headerType = "ObjLMemBlockHeader";
    } else {
    	headerType = "LMemBlockHeader";
    }
    /* START OF LMEMBLOCKHEADER */

    Output("%s %s _%sHeader%s=%s{", headerType, lms,resource->name,_ar,_op);
    if (resource->flags & SYM_OBJECT_BLOCK) {
    	Output("{");
    }
    if (resource->data.symResource.header_ctype != NULL) {
    	Output("{");
    }
    /*
     * Output LMBH_handle (dummy value, handled by the linker)
     */
    Output("0, ");
    /*
     * Output beginning of heap area
     */
    sprintf(buf, "sizeof(%s)", headerType);
    Output("(word)(sizeof(%s)+(%s%%4?(%s%%4!=3?2:0):0)), ",
	    	    	    	    	    	headerType, buf, buf);

    /*
     * 5/30/92: if LMF_IN_RESOURCE is set, FarFullObjLock thinks the block
     * is an object block, regardless of the type or the setting of
     * LMF_HAS_FLAGS. To be consistent with UIC, we initialize flags to 0
     * until we know the thing is an object block...
     */
    flags = 0;
    if (resource->flags & SYM_OBJECT_BLOCK) {
	flags |= LMF_HAS_FLAGS | LMF_IN_RESOURCE;
	if (!(resource->flags & SYM_NOT_DETACHABLE)) {
	    flags |= LMF_DETACHABLE;
	}
    }

    Output("0x%04x, ", flags);
    /*
     * Output the type of lmem block
     */
    if (resource->flags & SYM_OBJECT_BLOCK) {
	Output("LMEM_TYPE_OBJ_BLOCK, ");
    } else {
	Output("LMEM_TYPE_GENERAL, ");
    }
    Output("0, %d, 0, 0}", roundedNumChunks);
    /*
     * If this is an object block output the rest of the ObjLMemBlockHeader
     */
    if (resource->flags & SYM_OBJECT_BLOCK) {
	if (resource->data.symResource.resourceOutput != NullSymbol) {
	    Output(", 0, 0, (optr)&%s, 0}",
		   resource->data.symResource.resourceOutput->name);
	} else {
	    Output(", 0, 0, 0, 0}");
	}
    }
    /*
     * If a special header type is given then output the initializer
     * the the special part
     */
    if (resource->data.symResource.header_initializer != NULL) {
    	Output(", %s}", resource->data.symResource.header_initializer);
    }

    Output("%s;",_cl);
    CompilerEndSegment("__HEADER_", resource->name);
    Output("\n");
}

/***********************************************************************
 *
 * FUNCTION:	DoFinalOutput
 *
 * DESCRIPTION:	Output class tables
 *
 * CALLED BY:	main
 *
 * RETURN:	none
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	tony	3/91		Initial Revision
 *
 ***********************************************************************/
void
DoFinalOutput(void)
{
    Symbol *sym;

    for (sym = resourceList; sym != NullSymbol;
	    	    	sym = sym->data.symResource.nextResource) {
	OutputResource(sym);
    }

    for (sym = classDeclList; sym != NullSymbol;
	    	    	sym = sym->data.symClass.nextDeclaredClass) {
	OutputClassTable(sym);
    }

    if (declareMessageParams) {
	switch(compiler){
	  case COM_HIGHC:
	    Output("pragma Off(Warn);\n");
	    break;
	  case COM_MSC: case COM_BORL: case COM_WATCOM:
	    break;
	  default:
	    assert(0);
	}
    }
}
