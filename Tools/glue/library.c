/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Dynamic-Library Support
 * FILE:	  library.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 20, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Library_Link	    Load the symbols from a library interface
 *	    	    	    definition file.
 *	Library_ExportAs    Enter a routine in the export table but place
 *	    	    	    it under a different name in the .ldf file.
 *	Library_AddDir	    Add another directory to search for library
 *	    	    	    interface definition files.
 *	Library_Skip	    Add n empty entry slots to the export table.
 *	Library_WriteLDF    Create the .ldf file for the geode.
 * 	Library_IncMinor    Increment geode's minor protocol number, setting
 *	    	    	    it as the minor number for subsequent exports.
 *	Library_UseEntry    Note the use of a library's exported entry
 *			    point, increasing the minor number used in
 *			    the ImportedLibraryEntry as necessary.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/20/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to deal with dynamic libraries under pc/geos
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: library.c,v 3.30 96/05/21 16:36:48 adam Exp $";
#endif lint

#include    "glue.h"
#include    "output.h"
#include    "geo.h"
#include    "obj.h"
#include    "sym.h"
#include    "parse.h"
#include    "library.h"
#include    "st.h"
#include    <ctype.h>

/* extern void __stdcall DebugBreak(void); */

typedef struct {
    char              name[20];
    unsigned short    flags;

#define PE_SHIPPED    0x0002  /* This library is being shipped with the geode
				 at the specified protocol */

#define PE_EXEMPT     0x0001  /* Exempt this library from any compile time
				 protocol checking */
    int               major;
    int               minor;
} PlatformEntry;

Library	    *libs;
int	    numLibs = 0;
PlatformEntry	    *platformLibs;
int	            numPlatformLibs = 0;
int	    numImport = 0;
EntryPt	    *entryPoints;
int	    numEPs = 0;

static VMHandle	    	ldf;	    /* Handle open to .ldf file */
static VMBlockHandle	ldfStrings; /* String table for the thing */
static VMBlockHandle	ldfBlock;   /* Block containing ENTRY symbols for it */
static int  	    	ldfSize;    /* Size of ldfBlock since OS/90 rounds
				     * the thing up to a paragraph boundary
				     * each time and we don't want to waste
				     * 4 bytes per symbol (besides, we'd
				     * really screw ourselves up when the
				     * library is linked in) */
static VMBlockHandle	ldfTypes;   /* Associated type block */
static int  	    	ldfTSize;   /* Size of the beastie */

/*
 * Directories to search when looking for .ldf files with which to link.
 */
static char 	**dirs;
static int  	ndirs = 0;


static int      LibraryLookupPlatformLibrary(char    *libName);



/***********************************************************************
 *				Library_AddDir
 ***********************************************************************
 * SYNOPSIS:	    Add another directory to the library search path
 * CALLED BY:	    main
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
void
Library_AddDir(char 	*dir)
{
    if (ndirs == 0) {
	dirs = (char **)malloc(sizeof(char *));
    } else {
	dirs = (char **)realloc((void *)dirs, (ndirs+1)*sizeof(char *));
    }
    dirs[ndirs++] = dir;
}

/***********************************************************************
 *				LibraryEnsureOpen
 ***********************************************************************
 * SYNOPSIS:	    Make sure the ldf file is open and initialized.
 * CALLED BY:	    Library_ExportAs
 * RETURN:	    Nothing
 * SIDE EFFECTS:    the ldf* variables are initialized
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/89	Initial Revision
 *
 ***********************************************************************/
static int
LibraryEnsureOpen(void)
{
    static int	openattempted = 0;

    if ((ldf == NULL) && makeLDF) {
	char	    	*file;
	char	    	*cp, *cp2;
	int 	    	i;
	short	    	status;
	VMBlockHandle	map;
	ObjHeader   	*hdr;
	ObjSegment	    	*s;
	ObjSymHeader	*osh;
	ObjTypeHeader	*oth;

	if (openattempted) {
	    return(0);
	}

	openattempted = 1;

	/*
	 * initilize filename with ldfOutputDir and slash, if needed
	 */
	if (ldfOutputDir != NULL) {
	    file = malloc((strlen(ldfOutputDir))+GEODE_NAME_SIZE+5);
	    for (cp2 = file, cp = ldfOutputDir ; *cp != 0 ; cp++)
	    {
	    	*cp2++ = *cp;
	    }
	    if (cp2 != file) {
	    	*cp2++ = '/';
	    }
	} else {
	    file = malloc(GEODE_NAME_SIZE+5);
	    cp2 = file;
	}

	/*
	 * Find first space in the name and downcase everything, since
	 * that's what the makefile system we have expects.
	 */
	for (cp = GH(geodeName), i = GEODE_NAME_SIZE;
	     *cp != ' ' && i > 0;
	     i--, cp++)
	{
	    if (isupper(*cp)) {
		*cp2++ = tolower(*cp);
	    } else {
		*cp2++ = *cp;
	    }
	}
	/*
	 * Tack .ldf onto the name starting at the first space.
	 */
	strcpy(cp2, ".ldf");

	/*
	 * Make sure any old version is biffed
	 */
	(void)unlink(file);
	/*
	 * Attempt to create a new version.
	 */
	ldf = VMOpen(VMO_CREATE_ONLY|FILE_DENY_RW|FILE_ACCESS_RW,
		     70,
		     file,
		     &status);

	if (ldf == NULL) {
	    /*
	     * Notify and return error.
	     */
	    Notify(NOTIFY_ERROR, "unable to create library definition file %s",
		   file);
	    return(0);
	}

	if (geosRelease > 1) {
	    GeosFileHeader2	gfh;

	    VMGetHeader(ldf, (char *)&gfh);
	    gfh.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	    gfh.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	    bcopy(OBJ_SYMTOKEN, gfh.token.chars, sizeof(gfh.token.chars));
	    bcopy("GLUE", gfh.creator.chars, sizeof(gfh.creator.chars));
	    VMSetHeader(ldf, (char *)&gfh);
	} else {
	    GeosFileHeader	gfh;

	    VMGetHeader(ldf, (char *)&gfh);
	    gfh.core.protocol.major = swaps(OBJ_PROTOCOL_MAJOR);
	    gfh.core.protocol.minor = swaps(OBJ_PROTOCOL_MINOR);
	    bcopy(OBJ_SYMTOKEN, gfh.core.token.chars,
		  sizeof(gfh.core.token.chars));
	    bcopy("GLUE", gfh.core.creator.chars,
		  sizeof(gfh.core.creator.chars));
	    VMSetHeader(ldf, (char *)&gfh);
	}

	/*
	 * Create a string table and symbol table for our sole segment
	 */
	ldfStrings = ST_Create(ldf);

	/*
	 * Set up the map block containing a single segment whose name is
	 * the name of the geode, minus its extension and padding spaces.
	 */
	map = VMAlloc(ldf, sizeof(ObjHeader)+sizeof(ObjSegment), OID_MAP_BLOCK);
	hdr = (ObjHeader *)VMLock(ldf, map, (MemHandle *)NULL);
	/*
	 * First the various header fields.
	 */
	hdr->magic = OBJMAGIC;
	hdr->numSeg = 1;
	hdr->numGrp = 0;
	hdr->strings = ldfStrings;
	hdr->entry.frame = 0;
	if (geosRelease >= 2) {
	    bcopy(&geoHeader.v2x.execHeader.geosFileHeader.release,
		  &hdr->rev,
		  sizeof(hdr->rev));
	    bcopy(&geoHeader.v2x.execHeader.geosFileHeader.protocol,
		  &hdr->proto,
		  sizeof(hdr->proto));
	} else {
	    bcopy(&geoHeader.v1x.execHeader.geosFileHeader.core.release,
		  &hdr->rev,
		  sizeof(hdr->rev));
	    bcopy(&geoHeader.v1x.execHeader.geosFileHeader.core.protocol,
		  &hdr->proto,
		  sizeof(hdr->proto));
	}

	/*
	 * Now the segment descriptor.
	 */
	s = (ObjSegment *)(hdr+1);
	s->name = ST_Enter(ldf, ldfStrings,
			   GH(geodeName), GEODE_NAME_SIZE-i);
	s->class = NullID;
	s->align = 0;
	s->type = SEG_LIBRARY;
	s->toc = s->lines = s->addrMap = s->data = s->relHead = 0;
	s->syms = ldfBlock = VMAlloc(ldf, sizeof(ObjSymHeader), OID_SYM_BLOCK);
	ldfSize = sizeof(ObjSymHeader);
	s->flags = 0;

	ldfTSize = sizeof(ObjTypeHeader);
	ldfTypes = VMAlloc(ldf, ldfTSize, OID_TYPE_BLOCK);
	oth = (ObjTypeHeader *)VMLock(ldf, ldfTypes, (MemHandle *)NULL);
	oth->num = 0;

	/*
	 * Set up the header for the lone symbol block we use. The type
	 * block must be allocated (2 bytes for the "next" pointer) b/c
	 * various functions aren't careful about checking and it's more of
	 * a pain than it's worth to make them careful.
	 */
	osh = (ObjSymHeader *)VMLock(ldf, ldfBlock, (MemHandle *)NULL);
	osh->types = ldfTypes;
	osh->seg = sizeof(ObjHeader);
	osh->next = 0;
	osh->num = 0;

	VMUnlockDirty(ldf, ldfTypes);
	VMUnlockDirty(ldf, ldfBlock);
	VMUnlockDirty(ldf, map);

	VMSetMapBlock(ldf, map);

	free(file);
    }
    return(1);
}

/***********************************************************************
 *				LibraryDupType
 ***********************************************************************
 * SYNOPSIS:	    Duplicate the type description for a symbol being
 *	    	    copied into the ldf file.
 * CALLED BY:	    Library_ExportAs
 * RETURN:	    Nothing
 * SIDE EFFECTS:    New type token is stored in the indicated place.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/12/89	Initial Revision
 *
 ***********************************************************************/
static void
LibraryDupType(word 	    	type,   /* Description to duplicate */
	       VMBlockHandle	block,	/* Block in symbols in which type
					 * lies */
	       word 	    	*dest)	/* Place to store new token */
{
    if (type & OTYPE_SPECIAL) {
	*dest = type;
    } else {
	ObjType	    	src;   	/* Holding pen for type being duplicated while
				 * we recurse */
	void	    	*base; 	/* Base of symbol's type block */
	MemHandle   	mem;   	/* Memory handle of our type block so we can
				 * enlarge it */
	ObjType	    	*new;  	/* Place to store duplicate */
	ObjTypeHeader	*oth;	/* Header of our type block */

	/*
	 * Fetch out the source description
	 */
	base = VMLock(symbols, block, (MemHandle *)NULL);
	src = *(ObjType *)((genptr)base + type);
	VMUnlock(symbols, block);

	/*
	 * Duplicate any nested types first.
	 */
	if (!OTYPE_IS_STRUCT(src.words[0])) {
	    LibraryDupType(src.words[1], block, &src.words[1]);
	}

	/*
	 * Lock down and enlarge our type block to hold another descriptor
	 */
	VMLock(ldf, ldfTypes, &mem);
	MemReAlloc(mem, ldfTSize+sizeof(ObjType), 0);

	MemInfo(mem, (genptr *)&oth, (word *)NULL);
	oth->num += 1;

	/*
	 * Point "new" at the newly allocated slot and increase the recorded
	 * size of the type block. Set our return variable to hold the offset
	 * of the new slot.
	 */
	new = (ObjType *)((genptr)oth + ldfTSize);
	*dest = ldfTSize;
	ldfTSize += sizeof(ObjType);

	if (OTYPE_IS_STRUCT(src.words[0])) {
	    /*
	     * Copy the structure name into the ldf file and store its ID
	     * in the type descriptor.
	     */
	    ID	id = ST_Dup(symbols, OTYPE_STRUCT_ID(&src),
			    ldf, ldfStrings);

	    OTYPE_ID_TO_STRUCT(id, new);
	} else {
	    /*
	     * Copy the adjusted type descriptor into the new slot.
	     */
	    *new = src;
	}
    }
}


/***********************************************************************
 *				Library_ExportAs
 ***********************************************************************
 * SYNOPSIS:	    Export a routine to users of the library under some
 *	    	    alias.
 * CALLED BY:	    Parse_GeodeParams via yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
void
Library_ExportAs(char 	    *name,
		 char	    *alias,
		 Boolean    mustBeDefined)
{
    char    	message[132];
    EntryPt 	*ep;
    SegDesc 	*sd;
    char        yystr[50];   /*string to hold the default error message
			      *from the case statement below*/

    if (numEPs == 0) {
	entryPoints = (EntryPt *)malloc(sizeof(EntryPt));
    } else {
	entryPoints = (EntryPt *)realloc((void *)entryPoints,
					 (numEPs+1) * sizeof(EntryPt));
    }
    LibraryEnsureOpen();
    ep = &entryPoints[numEPs];

    ep->name = ST_LookupNoLen(symbols, strings, name);

    /* if the name isn't there then try the thing with or without a
     * leading underscore
     */
    if (ep->name == NullID)
    {
	if (name[0] == '_') {
	    ep->name = ST_LookupNoLen(symbols, strings, name+1);
	} else {
	    char	*name2 = (char *)malloc(1+strlen(name)+1);

	    sprintf(name2, "_%s", name);
	    ep->name = ST_LookupNoLen(symbols, strings, name2);
	    free((malloc_t)name2);
    	}
	if (ep->name == NullID)
	{
	    /* if that didn't work, try all caps, what the hell */
	    char    *cp=name;
	    char    *name2 = (char *)malloc(1+strlen(name)+1);
	    char    *cp2;

	    cp2 = name2;
	    while (*cp)
	    {
		*cp2++ = toupper(*cp++);
	    }
	    ep->name = ST_LookupNoLen(symbols, strings, name2);
	    free((malloc_t)name2);
	}
    }

    if (ep->name == NullID ||
	!Sym_FindWithSegment(symbols, ep->name, &ep->block, &ep->offset,
			     TRUE, &sd))
    {
	if (mustBeDefined) {
	    sprintf(message, "%s undefined4", name);
	    yyerror(message);
	} else {
	    /*
	     * Doesn't have to be defined, so just skip this slot in the table
	     */
	    Library_Skip(1);
	}
    } else {
	ObjSym	    	*sym;	    /* Symbol in main output file */
	ObjSym	    	*lsym;	    /* Symbol in ldf file */
	MemHandle   	mem;	    /* General memory handle for resize and
				     * determining number of symbols left */
	ObjSymHeader	*osh;	    /* Header of ldf symbol block */
	word	    	n;  	    /* Offset of new symbol in ldf file */
	int 	    	need = 1;   /* Number of symbol slots needed in ldf */
	VMBlockHandle	types;	    /* Type block for symbol in symbols */
	ID  	    	aname;	    /* ID for the alias */

	/*
	 * Make sure the routine hasn't already been exported, as that would
	 * cause multiply-defined errors in the client program, rather than
	 * now.
	 */
	aname = NullID;		/* Be quiet, GCC */
	if (makeLDF) {
	    aname = ST_EnterNoLen(ldf, ldfStrings, alias);
	    for (ep = entryPoints; ep < &entryPoints[numEPs]; ep++) {
		if (ep->alias == aname) {
		    sprintf(message, "%s is already exported", alias);
		    yyerror(message);
		    return;
		}
	    }
	}

	/*
	 * Mark the entry point as referenced.
	 */
	osh = (ObjSymHeader *)VMLock(symbols, ep->block, &mem);
	types = osh->types;
	sym = (ObjSym *)((genptr)osh+ep->offset);
	sym->flags |= OSYM_REF;

	if (makeLDF) {
	    /*
	     * Deal with the need to copy in any binding symbols for exported
	     * classes.
	     *
	     * First figure the number of symbols left in the block.
	     */
	    n = osh->num - ((ep->offset - sizeof(ObjSymHeader))/sizeof(ObjSym));

	    switch(sym->type) {
		case OSYM_CLASS:
		case OSYM_MASTER_CLASS:
		case OSYM_VARIANT_CLASS:
		{
		    ObjSym	*bsym;

		    /*
		     * Binding symbols follow immediately after the class.
		     * XXX: Make use of the 'next' field?
		     */
		    for (bsym = sym+1, n--;
			 n > 0 && bsym->type == OSYM_BINDING;
			 n--, bsym++)
		    {
			need++;
			if (bsym->u.binding.isLast) {
			    break;
			}
		    }
		    break;
		}
		case OSYM_PROC:
		case OSYM_LABEL:
		case OSYM_VAR:
		case OSYM_CHUNK:
		    /*
		     * These are ok.
		     */
		    break;
		default:
		    sprintf(yystr,"%i is not of a type that my be exported",
			    sym->name);
		    yyerror(yystr);
		    return;
	    }

	    /*
	     * Lock down the symbol block we're using
	     */
	    VMLock(ldf, ldfBlock, &mem);

	    /*
	     * Enlarge it again and fetch its new address.
	     */
	    n = ldfSize;
	    ldfSize += (need * sizeof(ObjSym));
	    MemReAlloc(mem, ldfSize, 0);
	    MemInfo(mem, (genptr *)&osh, (word *)NULL);

	    /*
	     * The new symbol goes at the previous limit of the block. Increase
	     * the record of the number of symbols in the block by the number
	     * needed.
	     */
	    lsym = (ObjSym *)((genptr)osh + n);
	    osh->num += need;

	    /*
	     * Initialize the symbol record from the real one. The address
	     * becomes the symbol's entry point number.
	     */
	    *lsym = *sym;
	    lsym->flags |= OSYM_REF|OSYM_GLOBAL|OSYM_ENTRY;
	    lsym->u.addrSym.address = numEPs++;
	    lsym->name = ep->alias = aname;
	    /*
	     * If the segment to which the symbol belongs isn't marked fixed,
	     * mark the lsym as movable. NOTE: If the user places an export
	     * command in the .gp file before the resource command that declares
	     * the segment to be fixed, this will take the conservative approach
	     * and given an error if the user attempts to jump to the routine in
	     * question. This will lead to a rapid correction of the erroneous
	     * .gp file.
	     */
	    if (!(sd->flags & RESF_FIXED)) {
		lsym->flags |= OSYM_MOVABLE;
	    }

	    /*
	     * Deal with class bindings.
	     */
	    switch(sym->type) {
		case OSYM_CLASS:
		case OSYM_MASTER_CLASS:
		case OSYM_VARIANT_CLASS:
		{
		    ObjSym	*bsym;

		    OBJ_STORE_SID(lsym->u.class.super,
				  ST_Dup(symbols,
					 OBJ_FETCH_SID(sym->u.class.super),
					 ldf, ldfStrings));

		    for (bsym = sym+1, need--; need > 0; need--, bsym++) {
			lsym++;
			/*
			 * Copy the name of the method into the ldf file
			 */
			lsym->name = ST_Dup(symbols, bsym->name, ldf,
					    ldfStrings);
			/*
			 * Copy the name of the procedure into the ldf file
			 */
			OBJ_STORE_SID(lsym->u.binding.proc,
				      ST_Dup(symbols,
					     OBJ_FETCH_SID(bsym->u.binding.proc),
					     ldf, ldfStrings));
			lsym->u.binding.callType = bsym->u.binding.callType;
			/*
			 * If the method is marked as private static, convert
			 * it to callable dynamic for users of the library.
			 */
			if (lsym->u.binding.callType == OSYM_PRIVSTATIC) {
			    lsym->u.binding.callType = OSYM_DYNAMIC_CALLABLE;
			}
			lsym->u.binding.isLast = bsym->u.binding.isLast;

			/*
			 * No special flags for a binding symbol in here...
			 */
			lsym->flags = 0;
			lsym->type = OSYM_BINDING;
		    }
		    break;
		}
		case OSYM_VAR:
		case OSYM_CHUNK:
		    /*
		     * Duplicate the thing's type descriptor as well...
		     */
		    LibraryDupType(sym->u.variable.type, types,
				   &lsym->u.variable.type);
		    break;
	    }

	    /*
	     * Mark the symbol blocks as dirty...
	     */
	    VMUnlockDirty(ldf, ldfBlock);
	} else {
	    numEPs++;
	}
	VMUnlockDirty(symbols, ep->block);
    }
}


/***********************************************************************
 *			Library_TackPrependPublishedToID
 ***********************************************************************
 * SYNOPSIS:	    Locate a symbol in the .ldf file with the passed ID
 * CALLED BY:	    Library_Publish
 * RETURN:	    block, offset of symbol (block = 0 if not found)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	-----------	----------------
 *	jon	29 jul 1993	Initial Revision
 *
 ***********************************************************************/
ID
Library_TackPrependPublishedToID(VMHandle         vmHandle,
				 VMBlockHandle    table,
				 ID               id)
{
    char    name[300];
    ID      returnID;

    strcpy(name, "_PUBLISHED_");
    strcat(name, ST_Lock(vmHandle, id));
    returnID = ST_LookupNoLen(vmHandle, table, name);
    ST_Unlock(vmHandle, id);
    return(returnID);
}


/***********************************************************************
 *			Library_ForceTackPrependPublishedToID
 ***********************************************************************
 * SYNOPSIS:	    Locate a symbol in the .ldf file with the passed ID
 * CALLED BY:	    Library_Publish
 * RETURN:	    block, offset of symbol (block = 0 if not found)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	-----------	----------------
 *	jon	29 jul 1993	Initial Revision
 *
 ***********************************************************************/
ID
Library_ForceTackPrependPublishedToID(VMHandle         vmHandle,
				      VMBlockHandle    table,
				      ID               id)
{
    char    name[300];
    ID      returnID;

    strcpy(name, "_PUBLISHED_");
    strcat(name, ST_Lock(vmHandle, id));
    returnID = ST_EnterNoLen(vmHandle, table, name);
    ST_Unlock(vmHandle, id);
    return(returnID);
}


/***********************************************************************
 *				Library_MarkPublished
 ***********************************************************************
 * SYNOPSIS:	    Copy a routine from its native code segment to the
 *                  .ldf file, along with any of its relocations
 *
 * CALLED BY:	    Parse_GeodeParams via yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon     22 jul 1993     initial revision
 *
 ***********************************************************************/
void
Library_MarkPublished(char 	*name)
{
    ID          id;
    char    	message[300];
    VMBlockHandle 	symBlock;
    word        symOff;
    SegDesc 	*sd;


    if (!makeLDF) {
	return;
    }

    LibraryEnsureOpen();

    /*
     * See if we can locate the name in the string table
     */

    id = ST_LookupNoLen(symbols, strings, name);


    if (id == NullID) {
	sprintf(message, "%s undefined, so can't be published", name);
	yyerror(message);
	return;
    } else if (!Sym_FindWithSegment(symbols, id, &symBlock, &symOff,TRUE, &sd))
    {
	sprintf(message, "Can't find symbol for %s, so can't be published", name);
	yyerror(message);
	return;
    } else {
	ObjSym	    	*sym;	    /* Symbol in main output file */
	ObjSymHeader	*osh;	    /* Header of ldf symbol block */
	MemHandle       mem;
	word            memSize;
	ObjSegment      *seg;
	VMBlockHandle   map;
	ObjHeader       *hdr;

	/*
	 * Mark the entry point as referenced.
	 */
	osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *)NULL);
	sym = (ObjSym *)((genptr)osh+symOff);
	sym->flags |= OSYM_REF;
	sym->u.proc.flags |= OSYM_PROC_PUBLISHED;
	VMUnlockDirty(symbols, symBlock);

	/*
	 * Add the published symbol into the .ldf file so we can store the
	 * offset of the code in the segment there
	 */

	map = VMGetMapBlock(ldf);
	hdr = (ObjHeader *)VMLock(ldf, map, &mem);
	MemInfo(mem, (genptr *)NULL, &memSize);
	memSize += sizeof(ObjSegment);
	MemReAlloc(mem, memSize, 0);
	MemInfo(mem, (genptr *)&hdr, (word *)NULL);
	seg = (ObjSegment *)(hdr+1);
	seg += hdr->numSeg;
	hdr->numSeg++;

	id = ST_LookupNoLen(ldf, ldfStrings, name);
	id = Library_ForceTackPrependPublishedToID(ldf, ldfStrings, id);

	seg->name = id;
	seg->class = NullID;
	seg->align = 0;
	seg->type = SEG_LIBRARY;
	seg->size = 0;
	seg->flags = 0;
	seg->toc = seg->lines = seg->addrMap = 0;
	seg->syms = VMAlloc(ldf, sizeof(ObjSymHeader) + sizeof(ObjSym), OID_SYM_BLOCK);
	osh = (ObjSymHeader *)VMLock(ldf, seg->syms, (MemHandle *)NULL);

	osh->types = ldfTypes;
	osh->seg = (int)seg - (int)hdr;
	osh->next = 0;
	osh->num = 1;

	sym = (ObjSym *)(osh+1);
	id = Library_ForceTackPrependPublishedToID(ldf, ldfStrings, id);
	sym->name = id;
	sym->type = OSYM_PROC;
	sym->flags = OSYM_GLOBAL | OSYM_MOVABLE;
	sym->flags = 0;

	VMUnlockDirty(ldf, seg->syms);
	VMUnlockDirty(ldf, map);
    }
}


/***********************************************************************
 *				LDFFind
 ***********************************************************************
 * SYNOPSIS:	    Locate a symbol in the .ldf file with the passed ID
 * CALLED BY:	    Library_Publish
 * RETURN:	    block, offset of symbol (block = 0 if not found)
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	-----------	----------------
 *	jon	29 jul 1993	Initial Revision
 *
 ***********************************************************************/
void
LDFFind(ID               id,
	VMBlockHandle    *symBlock,
	word             *symOff)
{

    ObjSym           *sym;
    VMBlockHandle    next;
    ObjSymHeader     *osh;
    int              n;

    /*
     * The idea here is simply to loop through all the symbols in
     * the .ldf file, looking for the passed ID. The first loop enumerates
     * through all the VMBlockHandles in the chain, while the second
     * loop enumerates each of the symbols in a given block.
     */

    for (*symBlock = ldfBlock; *symBlock != 0; *symBlock = next) {
	osh = (ObjSymHeader *)VMLock(ldf, *symBlock, (MemHandle *)NULL);
	n = osh->num;

	/*
	 * Loop through all the symbols in *symBlock
	 */
	for (*symOff = sizeof(ObjSymHeader); n > 0; *symOff += sizeof(ObjSym), n--) {
	    sym = (ObjSym *)((genptr)osh + *symOff);
	    if (sym->name == id) {
		break;
	    }
	}

	/*
	 * Record the next block handle before unlocking the current block
	 */
	next = osh->next;

	VMUnlock(ldf, *symBlock);

	/*
	 * If we found the symbol (n != 0), then we're done
	 */

	if (n != 0) {
	    break;
	}
    }
}


/***********************************************************************
 *				Library_Publish
 ***********************************************************************
 * SYNOPSIS:	    Copy a routine from its native code segment to the
 *                  .ldf file, along with any of its relocations
 *
 * CALLED BY:	    Parse_GeodeParams via yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon     22 jul 1993     initial revision
 *
 ***********************************************************************/
void
Library_Publish(VMHandle         fh,        /* File handle of passed blocks */
		VMBlockHandle    dataBlock, /* Block containing code */
		VMBlockHandle    relBlock,  /* Block containing relocations */
		word             procOffset,/* offset of routine within code */
		word             bytes,     /* Number of bytes to write */
		ID               symID)     /* ID in symbols of routine */
{
    char            message[300];
    ObjSym	    *targetSym;
    ID              targetID;
    ObjSegment      *seg;
    ObjSegment      *frameSeg;
    VMBlockHandle   map;
    VMBlockHandle   frameMap;
    word            memSize;
    ObjHeader       *hdr;
    byte            *destp;
    byte            *sourcep;
    ID              id;
    ID              frameID;

    ObjSymHeader    *frameHeader;
    ObjSym          *frameSym;
    MemHandle       frameMem;
    word            frameMemSize;


    MemHandle       mem;
    VMBlockHandle   cur;
    VMBlockHandle   next;	    /* Handle of next relocation block */
    MemHandle	    rmem;	 /* Mem handle for determining number of
				  * relocations in the current block */
    ObjRel          *sourceRel;
    ObjRel          *destRel;
    word            rmemSize;
    ObjRelHeader    *sourceRelHead;
    ObjRelHeader    *destRelHead;
    ObjSegment      *sourceFrame;
    int             i;           /* Index used to run through relocations */
    int             n;           /* Index used to run through relocations */

    if (!makeLDF) {
	return;
    }

    LibraryEnsureOpen();

    /*
     * Copy that many bytes out of the native code segment into the DATA
     * portion of the ldf segment.
     */

    map = VMGetMapBlock(ldf);
    hdr = (ObjHeader *)VMLock(ldf, map, &mem);

    /*
     * Find the right segment to copy into
     */

    id = ST_DupNoEnter(symbols, symID, ldf, ldfStrings);
    id = Library_TackPrependPublishedToID(ldf, ldfStrings, id);

    for (seg = (ObjSegment *)(hdr+1), n = 0 ; n < hdr->numSeg; n++, seg++) {

	if (seg->name == id) {
	    break;
	}
    }

    if (n == hdr->numSeg) {
	/*
	 * Couldn't find the segment that should've been defined in
	 * Library_MarkPublished
	 */
    }

    seg->data = VMAlloc(ldf, bytes, OID_CODE_BLOCK);
    seg->size = bytes;
    seg->relHead = VMAlloc(ldf, sizeof(ObjRelHeader), OID_REL_BLOCK);

    destp = (byte *)VMLock(ldf, seg->data, (MemHandle *)NULL);
    sourcep = (byte *)VMLock(fh, dataBlock, (MemHandle *)NULL);

    /*
     * Copy the bytes to the .ldf's DATA block
     */
    bcopy(sourcep + procOffset, destp, bytes);

    VMUnlock(fh, dataBlock);
    VMUnlockDirty(ldf, seg->data);

    /*
     * Now we'll copy any relevant relocations into the .ldf file
     */

    for (cur = relBlock; cur != 0; cur = next) {
	sourceRelHead = (ObjRelHeader *)VMLock(fh, cur, (MemHandle *)NULL);
	next = sourceRelHead->next;
	n = sourceRelHead->num;

	    for (sourceRel = (ObjRel *)(sourceRelHead+1); n > 0; n--, sourceRel++) {

		/*
		 * If the relocation lies within the bounds of the code
		 * we just copied, then we need to copy the relocation
		 * as well
		 */

		if ((sourceRel->offset >= procOffset) &&
		    (sourceRel->offset < procOffset + bytes)) {

		    /*
		     * Allocate a block for the ldf RELOCATIONS if non exists
		     */

		    VMLock(ldf, seg->relHead, &rmem);

		    /*
		     * Allocate room for a relocation in the .ldf file
		     * and copy it over.
		     */

		    MemInfo(rmem, (genptr *)NULL, &rmemSize);
		    rmemSize += sizeof(ObjRel);
		    MemReAlloc(rmem, rmemSize, 0);
		    MemInfo(rmem, (genptr *)&destRelHead, (word *)NULL);
		    destRel = (ObjRel *)(destRelHead+1);
		    destRel += destRelHead->num++;
		    bcopy(sourceRel, destRel, sizeof(ObjRel));
		    destRel->offset -= procOffset;

		    /*
		     * See whether the frame needed for the relocation
		     * has been copied into the .ldf file, and if not,
		     * make it so.
		     */

		    /*
		     * First we'll look for the original frame to see
		     * whether it's a library or not, and assume that
		     * if it's not a library, it must be a code segment in
		     * the current geode.
		     *
		     * Note that a relocation with a symBlock of 0
		     * is permissible: it means to relocate the thing by
		     * the relocation factor of the containing segment.
		     *  	    -- ardeb 11/15/93
		     */
		    frameMap = VMGetMapBlock(fh);
		    sourceFrame = (ObjSegment *)((genptr)VMLock(fh, frameMap,(MemHandle *)NULL) + sourceRel->frame);

		    if (sourceRel->symBlock != 0) {
			targetSym =
			    (ObjSym *)((genptr)VMLock(fh,
						      sourceRel->symBlock,
						      (MemHandle *)NULL) +
				       sourceRel->symOff);
			targetID = ST_Dup(fh, targetSym->name, ldf, ldfStrings);
		    } else {
			targetSym = (ObjSym *)NULL;
			targetID = NullID;
		    }

		    /*
		     * If it was a library, then we want to loop through
		     * each of our segments looking for that library (by name)
		     */
		    if (sourceFrame->type == SEG_LIBRARY) {
			frameID = ST_Dup(fh, sourceFrame->name, ldf, ldfStrings);
			for (frameSeg = (ObjSegment *)(hdr+1), i = hdr->numSeg;
			     i > 0; i--, frameSeg++) {
			    if (frameSeg->name == frameID) {
				break;
			    }
			}

			/*
			 * We couldn't find any segments by that name, so
			 * we'll create a new one.
			 */
			if (i == 0) {
			    /*
			     * Create a new segment in the .ldf file to
			     * contain the frame needed for the relocation
			     */

			    MemInfo(mem, (genptr *)NULL, &memSize);
			    memSize += sizeof(ObjSegment);
			    MemReAlloc(mem, memSize, 0);
			    MemInfo(mem, (genptr *)&hdr, (word *)NULL);
			    frameSeg = (ObjSegment *)(hdr+1);
			    frameSeg += hdr->numSeg;
			    hdr->numSeg++;

			    frameSeg->name = frameID;
			    frameSeg->class = NullID;
			    frameSeg->align = 0;
			    frameSeg->type = SEG_LIBRARY;
			    frameSeg->size = 0;
			    frameSeg->flags = 0;
			    frameSeg->toc = frameSeg->lines = frameSeg->addrMap = frameSeg->data = frameSeg->relHead = 0;
			    frameSeg->syms = VMAlloc(ldf, sizeof(ObjSymHeader), OID_SYM_BLOCK);

			    frameHeader = (ObjSymHeader *)VMLock(ldf, frameSeg->syms, (MemHandle *)NULL);
			    frameHeader->types = ldfTypes;
			    frameHeader->seg = (int)frameSeg - (int)hdr;
			    frameHeader->next = 0;
			    frameHeader->num = 0;
			    VMUnlock(ldf, frameSeg->syms);
			}

			/*
			 * At this point, frameSeg should be pointing at the
			 * ObjSegment in the .ldf file that contains the needed
			 * symbols for relocation. We'll scan the segment
			 * looking for the target symbol, and if we can't
			 * find it, we'll copy it in.
			 */

			destRel->frame = (int)frameSeg - (int)hdr;

			frameHeader = (ObjSymHeader *)VMLock(ldf, frameSeg->syms, &frameMem);
			frameSym = (ObjSym *)(frameHeader+1);

			for(i = frameHeader->num; i > 0; i--, frameSym++) {
			    if (frameSym->name == targetID) {
				break;
			    }
			}

			if (i == 0) {
			    /*
			     * We couldn't find the symbol in the frame, so
			     * let's enter it here
			     */

			    MemInfo(frameMem, (genptr *)NULL, &frameMemSize);
			    frameMemSize += sizeof(ObjSym);
			    MemReAlloc(frameMem, frameMemSize, 0);
			    MemInfo(frameMem, (genptr *)&frameHeader, (word *)NULL);
			    frameSym = (ObjSym *)(frameHeader+1);
			    frameSym += frameHeader->num;
			    frameHeader->num++;

			    *frameSym = *targetSym;
			    frameSym->name = targetID;
			}

			destRel->symBlock = frameSeg->syms;
			destRel->symOff = (int)frameSym - (int)frameHeader;

			VMUnlockDirty(ldf, frameSeg->syms);
			VMUnlockDirty(ldf, seg->relHead);
			VMUnlock(fh, sourceRel->symBlock);
		    } else {
			/*
			 * The frame isn't a SEG_LIBRARY, so we assume that
			 * the symbol is in the main .ldf segment
			 *
			 * Note that a relocation with a symBlock of 0
			 * is permissible: it means to relocate the thing by
			 * the relocation factor of the containing segment.
			 *  	    -- ardeb 11/15/93
			 */

			if (sourceRel->symBlock != 0) {
			    destRel->frame = sizeof(ObjHeader);

			    LDFFind(targetID,
				    &(destRel->symBlock),
				    &(destRel->symOff));
			    /*
			     * If we couldn't locate it, then we're calling a
			     * routine that isn't exported. Complain
			     */

			    if (destRel->symBlock == 0) {
				targetID = ST_DupNoEnter(ldf, targetID,
							 symbols, strings);
				sprintf(message,
					"Unable to publish %i due to a reference to %i, which is not an exported routine",
					symID, targetID);
				yyerror(message);
			    }
			    VMUnlock(fh, sourceRel->symBlock);
			} else {
			    word    val;

			    /*
			     * Frame for this funky relocation is the segment
			     * of the code, not the library segment for this
			     * library that's being linked.
			     */
			    destRel->frame = ObjEntryOffset(seg, hdr);

			    /*
			     * Now fixup the data to cope with the routine
			     * having been shifted down.
			     */
			    assert(destRel->size == OREL_SIZE_WORD);
			    destp = (byte *)VMLock(ldf, seg->data,
						   (MemHandle *)NULL);
			    destp += destRel->offset;
			    val = destp[0] | (destp[1] << 8);
			    val -= procOffset;
			    destp[0] = val;
			    destp[1] = val >> 8;
			    VMUnlockDirty(ldf, seg->data);

			    if (val > bytes) {
				sprintf(message,
					"Unable to publish %i due to a reference to data/code outside the routine.",
					symID);
				yyerror(message);
			    }
			}
		    }

		    VMUnlock(fh, frameMap);
		    VMUnlockDirty(ldf, seg->relHead);
		}
	    }
	    VMUnlock(fh, cur);
    }
    VMUnlockDirty(ldf, map);
}


/***********************************************************************
 *				Library_ProtoMinor
 ***********************************************************************
 * SYNOPSIS:	    Write out a protominor symbol to the ldf file
 * CALLED BY:	    Parse_GeodeParams via yyparse
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	1 jul 1993	Initial Revision
 *
 ***********************************************************************/
void
Library_ProtoMinor(char 	*name)
{
    ObjSym	    	*lsym;	    /* Symbol in ldf file */
    MemHandle   	mem;	    /* General memory handle for resize and
				     * determining number of symbols left */

    ObjSymHeader	*osh;	    /* Header of ldf symbol block */
    word	    	n;  	    /* Offset of new symbol in ldf file */
    ID  	    	aname;	    /* ID for the alias */

    if (makeLDF) {

	LibraryEnsureOpen();

	aname = ST_EnterNoLen(ldf, ldfStrings, name);

	/*
	 * Lock down the symbol block we're using
	 */

	VMLock(ldf, ldfBlock, &mem);

	/*
	 * Enlarge it again and fetch its new address.
	 */
	n = ldfSize;
	ldfSize += sizeof(ObjSym);
	MemReAlloc(mem, ldfSize, 0);
	MemInfo(mem, (genptr *)&osh, (word *)NULL);

	/*
	 * The new symbol goes at the previous limit of the block. Increase
	 * the record of the number of symbols in the block by the number
	 * needed.
	 */
	lsym = (ObjSym *)((genptr)osh + n);
	osh->num += 1;

	/*
	 * Initialize the symbol record from the real one. The address
	 * becomes the symbol's entry point number.
	 */
	lsym->type = OSYM_PROTOMINOR;
	lsym->flags = OSYM_REF|OSYM_GLOBAL;
	lsym->u.addrSym.address = 107;
	lsym->name = aname;

	/*
	 * Mark the symbol blocks as dirty...
	 */
	VMUnlockDirty(ldf, ldfBlock);
    }
}


/***********************************************************************
 *				Library_Skip
 ***********************************************************************
 * SYNOPSIS:	    Skip a given number of entries in the export table
 * CALLED BY:	    yyparse for SKIP command
 * RETURN:	    Nothing
 * SIDE EFFECTS:    entryPoints is expanded and the new entries are
 *	    	    zero-filled.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/89	Initial Revision
 *
 ***********************************************************************/
void
Library_Skip(int    	n)
{
    if (numEPs == 0) {
	entryPoints = (EntryPt *)calloc(n, sizeof(EntryPt));
    } else {
	entryPoints = (EntryPt *)realloc((void *)entryPoints,
					 (numEPs+n)*sizeof(EntryPt));
	bzero(&entryPoints[numEPs], n * sizeof(EntryPt));
    }
    numEPs += n;
}


/***********************************************************************
 *                  Library_SkipUntilNumber
 ***********************************************************************
 * SYNOPSIS:	    Skip a given number of entries in the export table
 * CALLED BY:	    yyparse for SKIP command
 * RETURN:	    Nothing
 * SIDE EFFECTS:    entryPoints is expanded and the new entries are
 *	    	    zero-filled.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/89	Initial Revision
 *
 ***********************************************************************/
void
Library_SkipUntilNumber(int n)
{
    int     i;
    char    message[100];

    if (numEPs >= n) {
	sprintf(message, "'skip until %d' follows %d other entry points", n, numEPs);
	yyerror(message);
    }

    if (numEPs == 0) {
	entryPoints = (EntryPt *)calloc(n, sizeof(EntryPt));
    } else {
	entryPoints = (EntryPt *)realloc((void *)entryPoints,
					 n*sizeof(EntryPt));
	for (i = numEPs; i < n; i++) {
	    entryPoints[i].name = NullID;
	    entryPoints[i].alias = NullID;
	    entryPoints[i].block = 0;
	    entryPoints[i].offset = 0;
	}
    }

    numEPs = n;
}


/***********************************************************************
 *		    Library_SkipUntilConstant
 ***********************************************************************
 * SYNOPSIS:	    Skip a given number of entries in the export table
 * CALLED BY:	    yyparse for SKIP command
 * RETURN:	    Nothing
 * SIDE EFFECTS:    entryPoints is expanded and the new entries are
 *	    	    zero-filled.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/89	Initial Revision
 *
 ***********************************************************************/
void
Library_SkipUntilConstant(char *name)
{
    char             message[100];
    ID               id;
    VMBlockHandle    symBlock;
    word             symOff;
    SegDesc 	     *sd;

    /*
     * Let's go find the constant...
     */
    id = ST_LookupNoLen(symbols, strings, name);

    if (id == NullID) {
	sprintf(message, "%s undefined, so can't skip until then.", name);
	yyerror(message);
	return;
    } else if (!Sym_FindWithSegment(symbols, id, &symBlock, &symOff,FALSE, &sd))
    {
	sprintf(message, "Can't find symbol for %s, so can't skip until then.", name);
	yyerror(message);
	return;
    } else {
	ObjSym	    	*sym;	    /* Symbol in main output file */
	ObjSymHeader	*osh;	    /* Header of ldf symbol block */

	/*
	 * Lock the thing down so wwe can suck on its value.
	 */
	osh = (ObjSymHeader *)VMLock(symbols, symBlock, (MemHandle *)NULL);
	sym = (ObjSym *)((genptr)osh+symOff);
	if (sym->type != OSYM_CONST) {
	    sprintf(message, "%s must be defined as a constant to skip until then.", name);
	    yyerror(message);
	} else {
	    Library_SkipUntilNumber(sym->u.constant.value);
	}

	VMUnlock(symbols, symBlock);
    }
}

/*********************************************************************
 *			LibraryNameStrCmp
 *********************************************************************
 * SYNOPSIS: compare the names of two libraries
 * CALLED BY:	Library_HasBeenLinked
 * RETURN:  0 if the names are the same
 * SIDE EFFECTS:
 * STRATEGY:	only look as far as the length of the first string
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/18/92		Initial version
 *
 *********************************************************************/
static int
LibraryNameStrCmp(char	    *name1,
		  char	    *name2)
{
    return strncmp(name1, name2, strlen(name1));
}

/*********************************************************************
 *			LibraryHasBeenLinked
 *********************************************************************
 * SYNOPSIS: 	see if a library has already been linked in
 * CALLED BY:	Library_Link
 * RETURN:  	TRUE if the library has already been linked in
 * SIDE EFFECTS:
 * STRATEGY:  	look for the name of the library in the libs array
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jimmy	6/10/92		Initial version
 *
 *********************************************************************/
static int
LibraryHasBeenLinked(char  	*name)  /* name of library to check for */
{
    int	    i;

    for (i = numLibs; i > 0; i--) {
	if (!LibraryNameStrCmp(name, libs[i-1].entry.name))
	{
	    return (TRUE);
	}
    }
    return FALSE;
}


/***********************************************************************
 *				Library_Link
 ***********************************************************************
 * SYNOPSIS:	    Load in symbols from an interface definition file,
 *	    	    optionally recording the library as something the
 *	    	    system must load before the current geode is
 *	    	    run.
 * CALLED BY:	    Parse_GeodeParams via yyparse
 * RETURN:	    zero if the library has already been linked in
 * SIDE EFFECTS:    The imported-library table may be expanded
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/89	Initial Revision
 *
 ***********************************************************************/
LibraryLinkValues
Library_Link(char   	    	*name,	    /* File name */
	     LibraryLoadTypes 	loadType,   /* How library will be loaded */
	     word   	    	attrs)	    /* Expected attributes (library vs.
					     * driver) */
{
    char    	    file[1024];	    /* Path for locating a library */
    int	    	    i;	    	    /* Index into directory list */
    VMHandle	    fh;	    	    /* Handle open to ldf file */
    short   	    status; 	    /* Status of open */
    VMBlockHandle   map;    	    /* Map block of ldf file */
    ObjHeader	    *hdr;   	    /* Header of ldf file */
    ObjFileType	    type;   	    /* Type of library (only OBJ_VM
				     * supported) */
    ObjSegment 	    *s;	    	    /* Sole segment allowed in ldf */
    VMHandle	    oidfile;	    /* Saving space for idfile */
    SegDesc 	    *sd;    	    /* Library segment */
    byte    	    *bp;
    ID	    	    sname;
    ID	    	    sclass;

    /*
     * First see if a file of the given name exists.
     */

    if (LibraryHasBeenLinked(name) == TRUE)
    {
	return	LLV_ALREADY_LINKED;
    }

    /*
     * Ridiculous hack to keep ProtoMinorSymbolSegment from attempting to load
     */
    if (!strcmp(name, "ProtoMinorSymbolSegment")) {
	return	LLV_ALREADY_LINKED;
    }

    strcpy(file, name);
    fh = Obj_Open(file, &status, &type, TRUE);
    if (fh == NULL) {
	/*
	 * Try sticking .ldf onto the end.
	 */
	sprintf(file, "%s.ldf", name);
	fh = Obj_Open(file, &status, &type, TRUE);
	if (fh == NULL) {
	    for (i = 0; i < ndirs; i++) {
		/*
		 * Stick the name onto the end of this directory and try that
		 */
		sprintf(file, "%s"QUOTED_SLASH"%s", dirs[i], name);
		fh = Obj_Open(file, &status, &type, TRUE);
		if (fh != NULL) {
		    break;
		}
		/*
		 * Nope. How about with .ldf on the end?
		 */
		strcat(file, ".ldf");
		fh = Obj_Open(file, &status, &type, TRUE);
		if (fh != NULL) {
		    break;
		}
	    }
	    if (i == ndirs) {
		sprintf(file, "cannot locate library %s", name);
		yyerror(file);
		return LLV_FAILURE;
	    }
	}
    }
    if (type != OBJ_VM) {
	sprintf(file, "cannot handle non-VM library %s (yet)", name);
	yyerror(file);
	fclose((FILE *)fh);
	return LLV_FAILURE;
    }

    map = VMGetMapBlock(fh);
    hdr = (ObjHeader *)VMLock(fh, map, (MemHandle *)NULL);

    /*
     * A Library definition file may only have a single segment -- that
     * containing the definitions for the library entry point numbers.
     *
     * This check is no longer valid now that "publish" creates segments

    if (hdr->numSeg != 1) {
	sprintf(file, "%s is an improperly formatted library definition file",
		name);
	yyerror(file);
	VMClose(fh);
	return LLV_FAILURE;
    }

     */


    /*
     * Now allocate a Library descriptor for the thing. Need to do this
     * before calling Pass1_LoadVM as that closes the VM file and we need
     * info from it...
     */
    if (numLibs == 0) {
	libs = (Library *)malloc(sizeof(Library));
    } else {
	libs = (Library *)realloc((void *)libs, (numLibs+1)*sizeof(Library));
    }

    s = (ObjSegment *)(hdr+1);
    sname = ST_Dup(fh, s->name, symbols, strings);
    sclass = ST_Dup(fh, s->class, symbols, strings);

    /* XXX: if the library is named "geos" and its major protocol number is
     * <= 622 (the level at which the 2.0 kernel came into being) then mark
     * the library as the kernel -- everything else should follow our lead */

    if (strcmp(name, "geos") == 0 && hdr->proto.major <= 622) {
	sprintf(file, "kernel protocol is too low (%d.%d) -- we don't do 1.x links anymore\n",
		hdr->proto.major, hdr->proto.minor);
	yyerror(file);
	VMClose(fh);
	return (LLV_FAILURE);
    } else if (loadType == LLT_ON_STARTUP) {
	libs[numLibs].lnum = numImport++;
    } else if (loadType == LLT_DYNAMIC) {
	libs[numLibs].lnum = NO_LOAD;
    } else {
	libs[numLibs].lnum = NO_LOAD_FIXED;
    }

    /*
     * Use the name of the only segment in the file as the name of the library,
     * since that's what we used when we built the thing.
     */
    oidfile = UtilGetIDFile();
    UtilSetIDFile(fh);
    sprintf(libs[numLibs].entry.name, "%-*.*i", GEODE_NAME_SIZE,
	    GEODE_NAME_SIZE, s->name);
    UtilSetIDFile(oidfile);
    /*
     * Fetch the protocol from the header.
     */
    bcopy(&hdr->proto, &libs[numLibs].entry.protocol, sizeof(hdr->proto));

    /*
     * Store in the expected attributes
     */
    bp = (byte *)&libs[numLibs].entry.geodeAttrs;
    *bp++ = attrs;
    *bp = attrs >> 8;

    /*
     * Up the number of libraries...
     */
    numLibs++;

    /*
     * "file" now contains the name of the file to load. Pass1VM_Load will
     * close the file for us.
     */
    VMUnlock(fh, map);
    Pass1VM_Load(file, fh);

    /*
     * Set the index into the libs array for the segment.
     */
    sd = Seg_Find(file, sname, sclass);

    assert (sd != NULL);
    sd->pdata.library = numLibs-1;
    return (LLV_SUCCESS);
}


/***********************************************************************
 *                  Library_LoadPublished
 ***********************************************************************
 * SYNOPSIS:	    Loop through all the linked libraries and run them
 *                  through a second pass to process any relocations
 *                  from published routines.
 *
 * CALLED BY:	    main
 * RETURN:	    nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon     8 sep 1993	Initial Revision
 *
 ***********************************************************************/
void
Library_LoadPublished(void)
{
    char    	    file[1024];	    /* Path for locating a library */
    char            strippedName[20]; /* lib name without space padding */
    int	    	    i;	    	    /* Index into directory list */
    VMHandle	    fh;	    	    /* Handle open to ldf file */
    short   	    status; 	    /* Status of open */
    ObjFileType	    type;   	    /* Type of library (only OBJ_VM
				     * supported) */
    int             whichLib;       /* index for cycling through libs */

    for (whichLib = 0; whichLib < numLibs; whichLib++) {
	strcpy(strippedName, libs[whichLib].entry.name);

	for (i = 0; i < 20; i++) {
	    if (strippedName[i] == ' ') {
		strippedName[i] = 0;
		break;
	    }
	}

	strcpy(file, strippedName);

	fh = Obj_Open(file, &status, &type, TRUE);
	if (fh == NULL) {
	    /*
	     * Try sticking .ldf onto the end.
	     */
	    sprintf(file, "%s.ldf", strippedName);
	    fh = Obj_Open(file, &status, &type, TRUE);
	    if (fh == NULL) {
		for (i = 0; i < ndirs; i++) {
		    /*
		     * Try sticking the name onto the end of the directory
		     */
		    sprintf(file, "%s"QUOTED_SLASH"%s", dirs[i], strippedName);
		    fh = Obj_Open(file, &status, &type, TRUE);
		    if (fh != NULL) {
			break;
		    }
		    /*
		     * Nope. How about with .ldf on the end?
		     */
		    strcat(file, ".ldf");
		    fh = Obj_Open(file, &status, &type, TRUE);
		    if (fh != NULL) {
			break;
		    }
		}
		if (i == ndirs) {
		    continue;
		}
	    }
	}
	Pass2VM_Load(strippedName, fh);
    }
}


/***********************************************************************
 *				Library_WriteLDF
 ***********************************************************************
 * SYNOPSIS:	    Finish filling in the .ldf file and close it down.
 * CALLED BY:	    Parse_GeodeParams
 * RETURN:	    Nothing
 * SIDE EFFECTS:    ldf is closed...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 2/89	Initial Revision
 *
 ***********************************************************************/
void
Library_WriteLDF(void)
{
    if (!numEPs) {
	/*
	 * Handle drivers that don't export anything but need to create
	 * a .ldf file.
	 */
	LibraryEnsureOpen();
    }

    if (ldf != NULL) {
	ST_Close(ldf, ldfStrings);
	VMClose(ldf);
    }
}

/***********************************************************************
 *			Library_CheckForMissingLibraries
 ***********************************************************************
 * SYNOPSIS:	    This routine checks platformLibs for each of the
 *                  libraries in "libs", and errors if it can't find
 *                  'em all.
 * CALLED BY:	    Parse_GeodeParams
 * RETURN:	    Nothing
 * SIDE EFFECTS:    Nothing
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon     6 jul 1993      Initial Revision
 *
 ***********************************************************************/
void
Library_CheckForMissingLibraries(void)
{
    char    message[1000];
    int     i;    /* Index for libs */

    /*
     * If no platform files were specified, then skip this check
     */

    if (numPlatformLibs) {

/*
	printf("\nThis geode is being linked to work with the following platform:\n");
	for (i = 0; i < numPlatformLibs; i++) {
	    if (platformLibs[i].flags & PE_EXEMPT) {
		printf("%s is exempted\n", platformLibs[i].name);
	    } else if (platformLibs[i].flags & PE_SHIPPED) {
		printf("%s is being shipped with proto %d.%d\n", platformLibs[i].name, platformLibs[i].major, platformLibs[i].minor);
	    } else {
		printf("%s: %d.%d\n", platformLibs[i].name, platformLibs[i].major, platformLibs[i].minor);
	    }
	}
*/

	/*
	 * Loop through each library in "libs", and try to find the
	 * name of the library in platformLibs
	 */
	for (i = 0; i < numLibs; i++) {
	    if (LibraryLookupPlatformLibrary(libs[i].entry.name) == numPlatformLibs) {
		sprintf(message, "Can't find required library %s in any of the platform files", libs[i].entry.name);
		yyerror(message);
	    }
	}
    }
}


/***********************************************************************
 *				Library_Find
 ***********************************************************************
 * SYNOPSIS:	    Locate an entry point by name, returning its number
 * CALLED BY:	    Pass2VMHandleEntryRel
 * RETURN:	    0 if couldn't be found
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	11/ 6/89	Initial Revision
 *
 ***********************************************************************/
int
Library_Find(ID	    name,
	     word   *entryNum)
{
    int	    i;

    for (i = 0; i < numEPs; i++) {
	if (entryPoints[i].name == name) {
	    *entryNum = i;
	    return(1);
	}
    }

    return(0);
}



/***********************************************************************
 *				Library_IncMinor
 ***********************************************************************
 * SYNOPSIS:	    Note that subsequent exports should use a minor
 *	    	    protocol number 1 higher than the current one.
 * CALLED BY:	    (EXTERNAL) yyparse
 * RETURN:	    nothing
 * SIDE EFFECTS:    a symbol is entered if makeLDF set.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/93		Initial Revision
 *
 ***********************************************************************/
void
Library_IncMinor(void)
{
    MemHandle	    mem;
    word    	    n;
    ObjSym  	    *os, *os2;
    ObjSymHeader    *osh;

    if (makeLDF) {

	LibraryEnsureOpen();
	/*
	 * Lock down the symbol block we're using
	 */
	VMLock(ldf, ldfBlock, &mem);

	/*
	 * Enlarge it again and fetch its new address.
	 */
	n = ldfSize;
	ldfSize += sizeof(ObjSym);
	MemReAlloc(mem, ldfSize, 0);
	MemInfo(mem, (genptr *)&osh, (word *)NULL);

	/*
	 * The new symbol goes at the previous limit of the block. Increase
	 * the record of the number of symbols in the block by the number
	 * needed.
	 */
	os = (ObjSym *)((genptr)osh + n);
	osh->num += 1;

	/*
	 * Assume this is the first increment we've seen and use the base
	 * minor number plus one.
	 */
	os->u.newMinor.number =
	    ((geosRelease >= 2) ?
	     geoHeader.v2x.execHeader.geosFileHeader.protocol.minor :
	     geoHeader.v1x.execHeader.geosFileHeader.core.protocol.minor) + 1;

	/*
	 * Now search back through the symbols looking for an earlier NEWMINOR
	 * symbol off which to base our number.
	 */
	for (os2 = os-1; os2 >= ObjFirstEntry(osh, ObjSym); os2--) {
	    if (os2->type == OSYM_NEWMINOR) {
		os->u.newMinor.number = os2->u.newMinor.number + 1;
		break;
	    }
	}

	os->name = NullID;
	os->type = OSYM_NEWMINOR;
	os->flags = 0;

	VMUnlockDirty(ldf, ldfBlock);
    }

    /*
     * Up the minor number of the geode itself, as well. The minor number
     * in the header of the LDF file remains at the base level defined when
     * we first started linking the beast, as that's the level for the
     * entry points that come before the first incminor directive.
     */
    if (geosRelease >= 2) {
	geoHeader.v2x.execHeader.geosFileHeader.protocol.minor += 1;
    } else {
	geoHeader.v1x.execHeader.geosFileHeader.core.protocol.minor += 1;
    }

}


/***********************************************************************
 *				Library_UseEntry
 ***********************************************************************
 * SYNOPSIS:	    Take note of a library entry point being used by
 *	    	    this geode and adjust the minor number of the library
 *		    needed to run the geode based on the nearest
 *	    	    NEWMINOR symbol in the ldf file.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    the imported library entry for the library may be
 *		    adjusted
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/19/93		Initial Revision
 *
 ***********************************************************************/
int
Library_UseEntry(SegDesc    	*libSeg,
		 const ObjSym  	*os,
		 int            doInc,
		 int            errorIfPlatformViolated)
{
    ObjSymHeader    *osh;
    const ObjSym    *os2;

    assert(libSeg->combine == SEG_LIBRARY);

    /*
     * Simplest just to lock the sole symbol block for the library down
     * again, rather than trying to locate it. We know, however, that
     * os falls within the block.
     */
    osh = (ObjSymHeader *)VMLock(symbols, libSeg->addrH, (MemHandle *)NULL);

    assert(os > (const ObjSym *)osh &&
	   os < ObjFirstEntry(osh, const ObjSym) + osh->num);

    for (os2 = os-1; os2 >= ObjFirstEntry(osh, const ObjSym); os2--) {
	if (os2->type == OSYM_NEWMINOR) {
	    if (libs[libSeg->pdata.library].entry.protocol.minor <
		os2->u.newMinor.number)
	    {
		int i;

		/*
		 * Need to make sure that this doesn't violate any platform
		 * restrictions
		 */
		i = LibraryLookupPlatformLibrary(libs[libSeg->pdata.library].entry.name);

		if (i != numPlatformLibs) {
		    if (!(platformLibs[i].flags & PE_EXEMPT) && (os2->u.newMinor.number > platformLibs[i].minor)) {

			/*
			 * The caller is attempting to use an entry point
			 * that is prohibited by platform specifications.
			 * Bitch if we have been so advised.
			 */
			if (errorIfPlatformViolated) {
			    char    platformViolatedMessage[1000];

			    sprintf(platformViolatedMessage,
				    "Usage of %i requires %s minor protocol %d, but platform files only allow minor protocol %d\n",
				    os->name, platformLibs[i].name,
				    os2->u.newMinor.number,
				    platformLibs[i].minor);
			    yyerror(platformViolatedMessage);
			}
			VMUnlock(symbols, libSeg->addrH);
			return(0);
		    }
		}

		if (doInc) {
		    libs[libSeg->pdata.library].entry.protocol.minor =
			os2->u.newMinor.number;
		}
		break;
	    }
	}
    }
    VMUnlock(symbols, libSeg->addrH);
    return(1);
}


/***********************************************************************
 *			Library_ReadPlatformFile
 ***********************************************************************
 * SYNOPSIS:	    Reads in a file containing the names of libraries and
 *                  their protocol numbers which should not be exceeded.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	2 jul 1993	Initial Revision
 *
 ***********************************************************************/
void
Library_ReadPlatformFile(char   *name) /* File name */
{
    char    	    file[1024];	    /* Path for locating a .plt file */
    FILE            *fh;            /* File open to .plt file */
    int             i;              /* Generic index */
    char    	    libName[20];    /* Library name */
    int             majorProto,
                    minorProto;

    sprintf(file, "%s.plt", name);
    fh = fopen(file, "r");
    if (fh == NULL) {
	/*
	 * Look through the include directories for the .plt file
	 */
	for (i = 0; i < ndirs; i++) {
	    /*
	     * Stick the name onto the end of this directory and try that
	     */
	    sprintf(file, "%s"QUOTED_SLASH"%s.plt", dirs[i], name);
	    fh = fopen(file, "r");
	    if (fh != NULL) {
		break;
	    }
	}
	if (i == ndirs) {
	    sprintf(file, "cannot locate platform file for %s", name);
	    yyerror(file);
	    return;
	}
    }

    /*
     * Each line of a .plt file is supposed to look like:
     *
     * <library> <major protocol> <minor protocol>
     *
     * So we'll read in lines, expecting that format, until we're EOF
     */
    while (fscanf(fh, "%s%d%d", libName, &majorProto, &minorProto) != EOF) {

	/*
	 * See if another platform has already specified protocol numbers
	 * for this library
	 */
	i = LibraryLookupPlatformLibrary(libName);

	if (i != numPlatformLibs) {
	    /*
	     * If this library has been exempted or shipped, skip it.
	     */
	    if (platformLibs[i].flags & (PE_EXEMPT | PE_SHIPPED)) {
		return;
	    }

	    /*
	     * Make sure the major protocol numbers are identical
	     */
	    if (majorProto != platformLibs[i].major) {
		sprintf(file, "Major protocol numbers for %s must match across platform files (found %d and %d)", libName, platformLibs[i].major, majorProto);
		yyerror(file);
		return;
	    /*
	     * If this entry specifies an earlier version of the library
	     * (ie., a smaller minor protocol) than was previously entered,
	     * then we'll want to use it.
	     */
	    } else if (minorProto < platformLibs[i].minor) {
		platformLibs[i].minor = minorProto;
	    }
	} else {
	    /*
	     * This is the first time we've seen this library. Allocate some
	     * space for it and fill it in.
	     */
	     if (numPlatformLibs == 0) {
	         platformLibs = (PlatformEntry *)malloc(sizeof(PlatformEntry));
	     } else {
	         platformLibs = (PlatformEntry *)realloc((void *)platformLibs, (numPlatformLibs+1)*sizeof(PlatformEntry));
	     }
	     strcpy(platformLibs[numPlatformLibs].name, libName);
	     platformLibs[numPlatformLibs].flags = 0;
	     platformLibs[numPlatformLibs].major = majorProto;
	     platformLibs[numPlatformLibs].minor = minorProto;
	     numPlatformLibs++;
	 }
    }
}


/***********************************************************************
 *			Library_ReadShipFile
 ***********************************************************************
 * SYNOPSIS:	    Reads in a file containing the names of libraries and
 *                  their protocol numbers which should not be exceeded.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	2 jul 1993	Initial Revision
 *
 ***********************************************************************/
void
Library_ReadShipFile(char   *name) /* File name */
{
    char    	    file[1024];	    /* Path for locating a .plt file */
    FILE            *fh;            /* File open to .plt file */
    int             i;              /* Generic index */
    char    	    libName[20];    /* Library name */
    int             majorProto,
                    minorProto;

    sprintf(file, "%s.plt", name);
    fh = fopen(file, "r");
    if (fh == NULL) {
	/*
	 * Look through the include directories for the .plt file
	 */
	for (i = 0; i < ndirs; i++) {
	    /*
	     * Stick the name onto the end of this directory and try that
	     */
	    sprintf(file, "%s"QUOTED_SLASH"%s.plt", dirs[i], name);
	    fh = fopen(file, "r");
	    if (fh != NULL) {
		break;
	    }
	}
	if (i == ndirs) {
	    sprintf(file, "cannot locate ship file for %s", name);
	    yyerror(file);
	    return;
	}
    }

    /*
     * Each line of a .plt file is supposed to look like:
     *
     * <library> <major protocol> <minor protocol>
     *
     * So we'll read in lines, expecting that format, until we're EOF
     */
    while (fscanf(fh, "%s%d%d;", libName, &majorProto, &minorProto) != EOF) {

	/*
	 * See if another platform has already specified protocol numbers
	 * for this library
	 */
	i = LibraryLookupPlatformLibrary(libName);

	if (i != numPlatformLibs) {
	    /*
	     * If this library has been exempted, skip it.
	     */
	    if (platformLibs[i].flags & PE_EXEMPT) {
		return;
	    }

	    /*
	     * If the thing has already been "shipped", let's make sure it
	     * was shipped with the same protocol
	     */
	    if (platformLibs[i].flags & PE_SHIPPED) {
		if ((majorProto != platformLibs[i].major) || (minorProto != platformLibs[i].minor)) {
		    sprintf(file, "Library %s cannot be shipped with multiple protocols (%d.%d and %d.%d)", libName, majorProto, minorProto, platformLibs[i].major, platformLibs[i].minor);
		    yyerror(file);
		    return;
		}
	    } else {
		/* We want to override the previous platform entry with the
		 * shipped protocol numbers.
		 */
		platformLibs[i].flags |= PE_SHIPPED;
		platformLibs[i].major = majorProto;
		platformLibs[i].minor = minorProto;
	    }
	} else {
	    /*
	     * This is the first time we've seen this library. Allocate some
	     * space for it and fill it in.
	     */
	     if (numPlatformLibs == 0) {
	         platformLibs = (PlatformEntry *)malloc(sizeof(PlatformEntry));
	     } else {
	         platformLibs = (PlatformEntry *)realloc((void *)platformLibs, (numPlatformLibs+1)*sizeof(PlatformEntry));
	     }
	     strcpy(platformLibs[numPlatformLibs].name, libName);
	     platformLibs[numPlatformLibs].flags = PE_SHIPPED;
	     platformLibs[numPlatformLibs].major = majorProto;
	     platformLibs[numPlatformLibs].minor = minorProto;
	     numPlatformLibs++;
	 }
    }
}


/***********************************************************************
 *			Library_ExemptLibrary
 ***********************************************************************
 * SYNOPSIS:	    Reads in a file containing the names of libraries and
 *                  their protocol numbers which should not be exceeded.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	2 jul 1993	Initial Revision
 *
 ***********************************************************************/
void
Library_ExemptLibrary(char   *name) /* Library name */
{
    int             i;              /* Generic index */

    /*
     * See if we can find this library in the platform libraries; if we
     * can, mark the thing as exempt. If not, create space for a new one.
     */
    i = LibraryLookupPlatformLibrary(name);

    if (i != numPlatformLibs) {
	platformLibs[i].flags |= PE_EXEMPT;
    } else {
	/*
	 * This is the first time we've seen this library. Allocate some
	 * space for it and fill it in.
	 */
	if (numPlatformLibs == 0) {
	    platformLibs = (PlatformEntry *)malloc(sizeof(PlatformEntry));
	} else {
	    platformLibs = (PlatformEntry *)realloc((void *)platformLibs, (numPlatformLibs+1)*sizeof(PlatformEntry));
	}
	strcpy(platformLibs[numPlatformLibs].name, name);
	platformLibs[numPlatformLibs].flags = PE_EXEMPT;
	numPlatformLibs++;
    }
}


/***********************************************************************
 *	            Library_LookupPlatformLibrary
 ***********************************************************************
 * SYNOPSIS:	    Reads in a file containing the names of libraries and
 *                  their protocol numbers which should not be exceeded.
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	jon	2 jul 1993	Initial Revision
 *
 ***********************************************************************/
static int
LibraryLookupPlatformLibrary(char    *libName)
{
    int     i;
    char    *cp;
    char    strippedName[20];

    /*
     * Strip out any trailing spaces from the passed library name. This
     * is done because the names stored in libs are space padded to 8 chars.
     */
    for (cp = libName, i = 0; (*cp != 0) && (*cp != ' '); cp++, i++) {
	strippedName[i] = *cp;
    }
    strippedName[i] = 0;

    /*
     * Check each of the platformLibs in turn for the passed name. I presume
     * that the names in libs are truncated to 8 chars, so only check the
     * first 8 chars for a match.
     */
    for (i = 0; i < numPlatformLibs; i++) {

	if (!strncmp(strippedName, platformLibs[i].name, 8)) {
	    break;
	}
    }

    return i;
}
