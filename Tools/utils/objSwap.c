/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  objSwap.c
 * FILE:	  objSwap.c
 *
 * AUTHOR:  	  Adam de Boor: Apr 17, 1991
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/17/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions to byte-swap the different types of blocks found in a
 *	PC/GEOS object file.
 *
 ***********************************************************************/
#include <config.h>
#include <os90.h>
#include "objSwap.h"

/*
 * Swap a word or longword in-place. May be used with post-increment.
 */
#define swapsp(p) { unsigned char *_cp = (unsigned char *)(p), _c; \
		     _c = *_cp++; _cp[-1] = *_cp; *_cp = _c; }
#define swaplp(p) { unsigned char *_cp = (unsigned char *)(p), _c; \
		     _c = _cp[3]; _cp[3] = _cp[0]; _cp[0] = _c; \
		     _c = _cp[2]; _cp[2] = _cp[1]; _cp[1] = _c; }

/*
 * Swap a word or longword as a value, returning the value swapped.
 */
#define swaps(s)    ((((s) << 8) | (((unsigned short)(s)) >> 8)) & 0xffff)
#define swapl(l)    (((l) << 24) | \
		     (((l) & 0xff00) << 8) | \
		     (((l) >> 8) & 0xff00) | \
		     (((unsigned long)(l)) >> 24))

/***********************************************************************
 *				ObjSwapObjRel
 ***********************************************************************
 * SYNOPSIS:	    Byte-swap a single Esp relocation.
 * CALLED BY:	    ObjSwap_Header, ObjSwapRelBlock
 * RETURN:	    nothing
 * SIDE EFFECTS:    ...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static inline void
ObjSwapObjRel(word  **wPtr)
{
    byte b;
    int	one = 1;

    swapsp((*wPtr)++); 	/* symOff */
    swapsp((*wPtr)++); 	/* symBlock */
    swapsp((*wPtr)++); 	/* offset */
    swapsp((*wPtr)++); 	/* frame */
    b = *(byte *)*wPtr;
    if (*(byte *)&one) {
	/* Swap from big- to little-endian */
	*(byte *)(*wPtr) = ((b & 0xf0) >> 4) | ((b & 0x0c) << 2) |
			   ((b & 0x02) << 5) | ((b & 0x01) << 7);
    } else {
	/* Swap from little- to big-endian */
	*(byte *)(*wPtr) = ((b & 0x0f) << 4) | ((b & 0x30) >> 2) |
			   ((b & 0x40) >> 5) | ((b & 0x80) >> 7);
    }
    (*wPtr)++; 	    	/* type, size, pcrel, fixed, unused */
}


/***********************************************************************
 *				ObjSwap_Header
 ***********************************************************************
 * SYNOPSIS:	    Byte-swap an ObjHeader structure.
 * CALLED BY:	    GLOBAL
 * RETURN:	    Nothing
 * SIDE EFFECTS:    all the relevant fields are byte-swapped
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
void
ObjSwap_Header(ObjHeader    *hdr)
{
    word    	*w = (word *)&hdr->numSeg;
    unsigned	i;
    ObjSegment	*seg;
    ObjGroup	*group;

    swapsp(w++);    	/* numSeg */
    swapsp(w++);    	/* numGrp */
    swapsp(w++);    	/* strings */
    swapsp(w++);    	/* srcMap */
    ObjSwapObjRel(&w);	/* entry */
    swapsp(w++);    	/* rev.major */
    swapsp(w++);    	/* rev.minor */
    swapsp(w++);    	/* rev.change */
    swapsp(w++);    	/* rev.eng */
    swapsp(w++);    	/* proto.major */
    swapsp(w++);    	/* proto.minor */
    w++;		/* pad low */
    w++;		/* pad high */

    for (seg = (ObjSegment *)w, i = hdr->numSeg; i > 0; i--, seg++) {
	unsigned tmp;

	w = (word *)seg;
	swaplp((*(long **)&w)++);   /* name */
	swaplp((*(long **)&w)++);	    /* class */
	tmp = seg->type; seg->type = seg->flags; seg->flags = tmp;
	w++;	    	    	    /* align, type, flags */
	swapsp(w++);	    	    /* data */
	swapsp(w++);	    	    /* size */
	swapsp(w++);	    	    /* relHead */
	swapsp(w++);	    	    /* syms */
	swapsp(w++);		    /* toc */
	swapsp(w++);	    	    /* addrMap */
	swapsp(w++);	    	    /* lines */
    }

    for (group = (ObjGroup *)seg, i = hdr->numGrp; i > 0; i--) {
	unsigned j;

	w = (word *)group;
	swaplp((*(long **)&w)++);	    /* name */
	swapsp(w++);	    	    /* numSegs */
	w++;	    	    	    /* pad */
	for (j = group->numSegs; j > 0; j--) {
	    swapsp(w++);
	}
	group = (ObjGroup *)w;
    }
}

/***********************************************************************
 *				ObjSwapMapBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the contents of a map block (ObjHeader)
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    think about it...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/18/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapMapBlock(VMHandle	vmHandle,/* File from whence it comes */
	      VMBlockHandle 	vmBlock,/* The block's VM handle */
	      VMID  	    	vmID, 	/* Its vm ID */
	      MemHandle  	handle, /* Its memory handle */
	      genptr  	    	block) /* The base of the locked block */
{
    ObjSwap_Header((ObjHeader *)block);
}

/***********************************************************************
 *				ObjSwapSrcMap
 ***********************************************************************
 * SYNOPSIS:	    Swap the contents of a source map
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    think about it...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapSrcMap(VMHandle	    	vmHandle,/* File from whence it comes */
	      VMBlockHandle 	vmBlock,/* The block's VM handle */
	      VMID  	    	vmID, 	/* Its vm ID */
	      MemHandle  	handle, /* Its memory handle */
	      genptr block) /* The base of the locked block */
{
    /* ObjSrcMapHeader	*osmh = (ObjSrcMapHeader *) block; */
    word    	    	*w;
    word    	    	*end;
    unsigned	    	i;
    word    	    	curSize;

    MemInfo(handle, (genptr *)NULL, &curSize);
    end = (word *)((char *)block + curSize);
    w = (word *) block;

    while (w < end) {
	/*
	 * Swap the number of entries in this map piece.
	 */
	swapsp(w++);
	if ((char *)w + (w[-1] * sizeof(ObjSrcMap)) <= (char *)end) {
	    /*
	     * Looks like a for-real source map (i.e. the number of entries
	     * in the map does not exceed the number of possible entries left
	     * in the block...)
	     */
	    for (i = w[-1]; i > 0; i--) {
		swapsp(w++);	/* line */
		swapsp(w++);	/* offset */
		swapsp(w++);	/* segment */
	    }
	} else {
	    /*
	     * Can't be a real source map, so bail now.
	     */
	    break;
	}
    }
}

/***********************************************************************
 *				ObjSwapAddrMap
 ***********************************************************************
 * SYNOPSIS:	    Swap the contents of an address map
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    think about it...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapAddrMap(VMHandle	    	vmHandle,/* File from whence it comes */
	       VMBlockHandle 	vmBlock,/* The block's VM handle */
	       VMID  	    	vmID, 	/* Its vm ID */
	       MemHandle  	handle, /* Its memory handle */
	       genptr block) /* The base of the locked block */
{
    ObjAddrMapHeader	*oamh = (ObjAddrMapHeader *)block;
    word    	    	*w;
    unsigned	    	i;

    w = (word *)block;
    swapsp(w++);		/* numEntries */

    for (i = oamh->numEntries; i > 0; i--) {
	swapsp(w++);		/* block */
	swapsp(w++);		/* last */
    }
}

/***********************************************************************
 *				ObjSwapLineBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the contents of a line-number block
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    think about it...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapLineBlock(VMHandle	vmHandle,/* File from whence it comes */
		 VMBlockHandle 	vmBlock,/* The block's VM handle */
		 VMID  	    	vmID, 	/* Its vm ID */
		 MemHandle  	handle, /* Its memory handle */
		 genptr block) /* The base of the locked block */
{
    ObjLineHeader   *olh = (ObjLineHeader *)block;
    word    	    *w;
    unsigned	    i;
    int	    	    isFileName;

    w = (word *)block;
    swapsp(w++);		/* next */
    swapsp(w++);		/* num */

    isFileName = 1;		/* First entry is always a filename */

    for (i = olh->num; i > 0; i--) {
	if (isFileName) {
	    swaplp((*(long **)&w)++);
	    isFileName = 0;
	} else {
	    if (*w == 0) {
		/*
		 * Line number is 0 (in any byte-order) so next entry is
		 * file name.
		 */
		isFileName = 1;
	    }
	    swapsp(w++);
	    swapsp(w++);
	}
    }
}

/***********************************************************************
 *				ObjSwapTypeBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the contents of a type-descriptor block
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    think about it...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapTypeBlock(VMHandle	vmHandle,/* File from whence it comes */
		 VMBlockHandle 	vmBlock,/* The block's VM handle */
		 VMID  	    	vmID, 	/* Its vm ID */
		 MemHandle  	handle, /* Its memory handle */
		 genptr block) /* The base of the locked block */
{
    ObjTypeHeader   *hdr = (ObjTypeHeader *)block;
    word    	    *w;
    unsigned	    i;

    w = (word *)block;
    swapsp(w++);		/* num */
    w++;			/* pad */

    for (i = hdr->num; i > 0; i--) {
	swapsp(w++);		/* words[0] */
	swapsp(w++);		/* words[1] */
    }
}

/***********************************************************************
 *				ObjSwapCodeBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the contents of a code block
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    none -- code is already in the right byte-order
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapCodeBlock(VMHandle	vmHandle,/* File from whence it comes */
		 VMBlockHandle 	vmBlock,/* The block's VM handle */
		 VMID  	    	vmID, 	/* Its vm ID */
		 MemHandle  	handle, /* Its memory handle */
		 genptr block) /* The base of the locked block */
{
}

/***********************************************************************
 *				ObjSwapHashHeadBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the entries in a hash table header block.
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapHashHeadBlock(VMHandle	vmHandle,/* File from whence it comes */
		 VMBlockHandle 	vmBlock,/* The block's VM handle */
		 VMID  	    	vmID, 	/* Its vm ID */
		 MemHandle  	handle, /* Its memory handle */
		 genptr block) /* The base of the locked block */
{
    word    	    *w;
    unsigned	    i;

    w = (word *)block;
    for (i = OBJ_HASH_CHAINS; i > 0; i--) {
	swapsp(w++);
    }
}
/***********************************************************************
 *				ObjSwapHashHeadBlock_NewFormat
 ***********************************************************************
 * SYNOPSIS:	    Swap the entries in a hash table header block.
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapHashHeadBlock_NewFormat(
		 VMHandle	vmHandle,/* File from whence it comes */
		 VMBlockHandle 	vmBlock,/* The block's VM handle */
		 VMID  	    	vmID, 	/* Its vm ID */
		 MemHandle  	handle, /* Its memory handle */
		 genptr block) /* The base of the locked block */
{
    word    	    *w;
    unsigned	    i;

    w = (word *)block;
    for (i = OBJ_HASH_CHAINS_NEW_FORMAT; i > 0; i--) {
	swapsp(w++);
    }
}


/***********************************************************************
 *				ObjSwapHashBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the entries in a hash table chain block.
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    guess
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapHashBlock(VMHandle	vmHandle,/* File from whence it comes */
		 VMBlockHandle 	vmBlock,/* The block's VM handle */
		 VMID  	    	vmID, 	/* Its vm ID */
		 MemHandle  	handle, /* Its memory handle */
		 genptr block) /* The base of the locked block */
{
    ObjHashBlock    *hdr = (ObjHashBlock *)block;
    word    	    *w;
    word    	    *end;

    w = (word *)block;
    swapsp(w++);    	/* next */
    swapsp(w++);    	/* nextEnt */

    end = (word *)&hdr->entries[hdr->nextEnt];
    while (w < end) {
	swaplp((*(long **)&w)++);	/* name */
	swapsp(w++);		/* offset */
	swapsp(w++);		/* block */
    }
}



/***********************************************************************
 *				ObjSwapSymBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the entire contents of a symbol block.
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    duh
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapSymBlock(VMHandle	vmHandle,/* File from whence it comes */
		VMBlockHandle	vmBlock,/* The block's VM handle */
		VMID  	    	vmID, 	/* Its vm ID */
		MemHandle	handle, /* Its memory handle */
		genptr block)	/* The base of the locked block */
{
    ObjSymHeader    *hdr;
    unsigned	    i;
    word    	    *w;

    hdr = (ObjSymHeader *)block;
    w = (word *)block;
    swapsp(w++);    	/* next */
    swapsp(w++);    	/* types */
    swapsp(w++);    	/* seg */
    swapsp(w++);    	/* num */

    for (i = hdr->num; i > 0; i--) {
	ObjSym	    *os = (ObjSym *)w;
	
	swaplp((*(long **)&w)++);	    /* name */
	switch(os->type) {
	    case OSYM_TYPEDEF:
		swapsp(w++);	/* typeDef.type */
		w += 2;		/* no extra data */
		break;
	    case OSYM_STRUCT:
	    case OSYM_RECORD:
	    case OSYM_ETYPE:
	    case OSYM_UNION:
		swapsp(w++);	/* sType.size */
		swapsp(w++);	/* sType.first */
		swapsp(w++);	/* sType.last */
		break;
	    case OSYM_FIELD:
		swapsp(w++);	/* sField.next */
		swapsp(w++);	/* sField.offset */
		swapsp(w++);	/* sField.type */
		break;
	    case OSYM_BITFIELD:
		swapsp(w++);	/* bField.next */
		w++;		/* bField.offset, bField.width */
		swapsp(w++);	/* bField.type */
		break;
	    case OSYM_ENUM:
		swapsp(w++);	/* eField.next */
		swapsp(w++);	/* eField.value */
		w++;		/* no third word */
		break;
	    case OSYM_METHOD:
		swapsp(w++);	/* method.next */
		swapsp(w++);	/* method.value */
		swapsp(w++);	/* method.flags */
		break;
	    case OSYM_CONST:
		swapsp(w++);	/* constant.value */
		w += 2;		/* no extra data */
		break;
	    case OSYM_VAR:
		swapsp(w++);	/* variable.type */
		w++;		/* variable.pad */
		swapsp(w++);	/* variable.address */
		break;
	    case OSYM_CHUNK:
		swapsp(w++);	/* chunk.type */
		w++;		/* chunk.pad */
		swapsp(w++);	/* chunk.handle */
		break;
	    case OSYM_PROC:
		swapsp(w++);	/* proc.flags */
		swapsp(w++);	/* proc.local */
		swapsp(w++);	/* proc.address */
		break;
	    case OSYM_LABEL:
		w++;		/* label.pad */
		swapsp(w++);	/* label.near */
		swapsp(w++);	/* label.address */
		break;
	    case OSYM_LOCLABEL:
		swapsp(w++);	/* procLocal.next */
		swapsp(w++);	/* label.near */
		swapsp(w++);	/* label.address */
		break;
	    case OSYM_REGVAR:
	    case OSYM_LOCVAR:
	    case OSYM_RETURN_TYPE:
		swapsp(w++);	/* localVar.next */
		swapsp(w++);	/* localVar.type */
		swapsp(w++);	/* localVar.offset */
		break;
	    case OSYM_ONSTACK:
		swaplp((*(long **)&w)++); /* onStack.desc */
		swapsp(w++);	/* onStack.address */
		break;
	    case OSYM_BLOCKSTART:
		swapsp(w++);	/* blockStart.next */
		swapsp(w++);	/* blockStart.local */
		swapsp(w++);	/* blockStart.address */
		break;
	    case OSYM_BLOCKEND:
		swapsp(w++);	/* blockEnd.next */
		w++;	    	/* blockEnd.pad */
		swapsp(w++);	/* blockEnd.address */
		break;
	    case OSYM_EXTTYPE:
		swapsp(w++);	/* extType.offset */
		swapsp(w++);	/* extType.block */
		w++;		/* extType.stype */
		break;
	    case OSYM_CLASS:
	    case OSYM_MASTER_CLASS:
	    case OSYM_VARIANT_CLASS:
		swaplp((*(long **)&w)++);	/* class.super */
		swapsp(w++);	/* class.address */
		break;
	    case OSYM_BINDING:
		swaplp((*(long **)&w)++); /* binding.proc */
		w++;		/* binding.callType, binding.isLast */
		break;
	    case OSYM_MODULE:
		swapsp(w++);	/* module.table */
		swapsp(w++);	/* module.offset */
		swapsp(w++);	/* module.syms */
		break;
	    case OSYM_PROFILE_MARK:
	        swapsp(w++);	/* profMark.markType */
		w += 1;		/* profMark.pad */
		swapsp(w++);	/* profMark.address */
		break;
	    case OSYM_NEWMINOR:
		swapsp(w++);	/* number */
		w += 2;		/* no extra data */
		break;
	    case OSYM_LOCAL_STATIC:
		swapsp(w++);	/* localStatic.next */
		swapsp(w++);	/* localStatic.symBlock */
		swapsp(w++);	/* localStatic.symOff */
		break;
	    case OSYM_VARDATA:
		swapsp(w++);	/* varData.next */
		swapsp(w++);	/* varData.value */
		swapsp(w++);	/* varData.type */
		break;
	    default:
		w += 3;
		break;
	}
	w += 1;			/* skip type and flags */
    }
}


/***********************************************************************
 *				ObjSwapRelBlock
 ***********************************************************************
 * SYNOPSIS:	    Swap the entire contents of a relocation block.
 * CALLED BY:	    ObjSwap_Reloc
 * RETURN:	    nothing
 * SIDE EFFECTS:    duh
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
static void
ObjSwapRelBlock(VMHandle	vmHandle,/* File from whence it comes */
		VMBlockHandle	vmBlock,/* The block's VM handle */
		VMID  	    	vmID, 	/* Its vm ID */
		MemHandle	handle, /* Its memory handle */
		genptr block)	/* The base of the locked block */
{
    ObjRelHeader    *hdr;
    unsigned	    i;
    word    	    *w;

    hdr = (ObjRelHeader *)block;
    w = (word *)block;
    swapsp(w++);    	/* next */
    swapsp(w++);    	/* num */

    for (i = hdr->num; i > 0; i--) {
	ObjSwapObjRel(&w);
    }
}
    


/***********************************************************************
 *				ObjSwap_Reloc
 ***********************************************************************
 * SYNOPSIS:	    VM relocation routine for byte-swapping object file
 *	    	    blocks.
 * CALLED BY:	    VM code.
 * RETURN:	    nothing
 * SIDE EFFECTS:    The contents of the block are byte-swapped.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
void
ObjSwap_Reloc(VMHandle	    vmHandle,	/* File from whence it comes */
	      VMBlockHandle vmBlock,	/* The block's VM handle */
	      VMID  	    vmID,   	/* Its vm ID */
	      MemHandle	    handle, 	/* Its memory handle */
	      genptr block) 	/* The base of the locked block */
{
    static const VMRelocRoutine  *relocRoutines[] = {
	ST_Reloc,   	      /* OID_STRING_HEAD */
	ST_Reloc,   	      /* OID_STRING_CHAIN */
	ObjSwapRelBlock,      /* OID_REL_BLOCK */
	ObjSwapSymBlock,      /* OID_SYM_BLOCK */
	ObjSwapHashBlock,     /* OID_HASH_BLOCK */
	ObjSwapHashHeadBlock, /* OID_HASH_HEAD_BLOCK */
	ObjSwapMapBlock,      /* OID_MAP_BLOCK */
	ObjSwapCodeBlock,     /* OID_CODE_BLOCK */
	ObjSwapTypeBlock,     /* OID_TYPE_BLOCK */
	ObjSwapLineBlock,     /* OID_LINE_BLOCK */
	ObjSwapAddrMap,	      /* OID_ADDR_MAP */
	ObjSwapSrcMap         /* OID_SRC_BLOCK */
    };
	
    if (vmID >= OID_STRING_HEAD && vmID <= OID_SRC_BLOCK) {
	(*relocRoutines[vmID - OID_STRING_HEAD])(vmHandle,
						 vmBlock,
						 vmID,
						 handle,
						 block);
    }
}


/***********************************************************************
 *				ObjSwap_Reloc_NewFormat
 ***********************************************************************
 * SYNOPSIS:	    VM relocation routine for byte-swapping object file
 *	    	    blocks.
 * CALLED BY:	    VM code.
 * RETURN:	    nothing
 * SIDE EFFECTS:    The contents of the block are byte-swapped.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	4/17/91		Initial Revision
 *
 ***********************************************************************/
void
ObjSwap_Reloc_NewFormat(
	      VMHandle	    vmHandle,	/* File from whence it comes */
	      VMBlockHandle vmBlock,	/* The block's VM handle */
	      VMID  	    vmID,   	/* Its vm ID */
	      MemHandle	    handle, 	/* Its memory handle */
	      genptr block) 	/* The base of the locked block */
{
    static const VMRelocRoutine  *relocRoutines_NewFormat[] = {
	ST_Reloc, 	  /* OID_STRING_HEAD */
	ST_Reloc,    	  /* OID_STRING_CHAIN */
	ObjSwapRelBlock,  /* OID_REL_BLOCK */
	ObjSwapSymBlock,  /* OID_SYM_BLOCK */
	ObjSwapHashBlock, /* OID_HASH_BLOCK */
	ObjSwapHashHeadBlock_NewFormat,
	                                          /* OID_HASH_HEAD_BLOCK */
	ObjSwapMapBlock,  /* OID_MAP_BLOCK */
	ObjSwapCodeBlock, /* OID_CODE_BLOCK */
	ObjSwapTypeBlock, /* OID_TYPE_BLOCK */
	ObjSwapLineBlock, /* OID_LINE_BLOCK */
	ObjSwapAddrMap,	  /* OID_ADDR_MAP */
	ObjSwapSrcMap     /* OID_SRC_BLOCK */
    };
    
    if (vmID >= OID_STRING_HEAD && vmID <= OID_SRC_BLOCK) {
	(*relocRoutines_NewFormat[vmID - OID_STRING_HEAD])(vmHandle,
							   vmBlock,
							   vmID,
							   handle,
							   block);
    }
}
