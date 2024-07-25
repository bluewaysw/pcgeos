/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Output file/buffer manipulation
 * FILE:	  output.c
 *
 * AUTHOR:  	  Adam de Boor: Oct 19, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	Out_Init    	    Initialize the output buffer
 *	Out_Block   	    Transfer a block to the output buffer at
 *	    	    	    an offset.
 *	Out_Fetch   	    Transfer a block back from the output file to
 *	    	    	    the passed buffer.
 *	Out_Final   	    Flush all output to the file.
 *	Out_DosMap  	    Print the symbols to a DOS-style map file.
 *	Out_ExtraReloc	    Apply extra relocation to a segment
 *	Out_PromoteGroups   Promote groups to be segments, demoting their
 *	    	    	    component segments to the rank of subsegment.
 *	Out_FindConstSym    Locate a constant symbol in the output file.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/19/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Functions for manipulating the output file.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: output.c,v 3.14 95/11/08 17:23:51 adam Exp $";
#endif lint

#include    "glue.h"
#include    "geo.h" 	    /* for protocol relocations (alas) */
#include    "output.h"
#include    "sym.h"

static genptr	outbuf;
static long 	outsize;
extern Boolean 	oldSymfileFormat;

typedef struct {
    Boolean 	isMajor;
    long    	position;
    SegDesc 	*library;
} OutProtoRel;

static OutProtoRel  *protoRels = NULL;
static int  	    numProtoRels = 0;
typedef int (*CmpCallback)(const void *, const void*);


/***********************************************************************
 *				Out_Init
 ***********************************************************************
 * SYNOPSIS:	    Initialize the output buffer
 * CALLED BY:	    InterPass
 * RETURN:	    Nothing
 * SIDE EFFECTS:    outbuf is allocated.
 *
 * STRATEGY:	    None
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
void
Out_Init(long	    size)   	/* Size of output file */
{
    outbuf = (void *)malloc(size);
    outsize = size;
    /*
     * Yuck. Zero the whole mess, as HighC relies on this...
     */
    bzero(outbuf, size);
}


/***********************************************************************
 *				Out_Block
 ***********************************************************************
 * SYNOPSIS:	    Output a block at a given position in the output file.
 * CALLED BY:	    Pass2LoadVM, Pass2LoadMS
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The data are copied to the output buffer
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
void
Out_Block(long	    position,
	  void	    *data,
	  int	    len)
{
    assert(position >= 0 && position+len <= outsize);
    
    bcopy(data, outbuf+position, len);
}


/***********************************************************************
 *				Out_Fetch
 ***********************************************************************
 * SYNOPSIS:	    Fetch a block from a given position in the output file.
 * CALLED BY:	    Pass2MS_Load
 * RETURN:	    The number of bytes returned
 * SIDE EFFECTS:    The data are copied to the passed buffer
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
int
Out_Fetch(long	    position,
	  void	    *data,
	  int	    len)
{
    assert(position < outsize && position >= 0);

    if (position + len > outsize) {
	len = outsize - position;
    }
    
    bcopy(outbuf+position, data, len);
    return(len);
}


/***********************************************************************
 *				Out_Final
 ***********************************************************************
 * SYNOPSIS:	    Final output process. Sends the output to the file
 * CALLED BY:	    Final
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:	    Calls (*fileOps->write)...
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/19/89	Initial Revision
 *
 ***********************************************************************/
void
Out_Final(char	*outfile)   	/* Name of output file */
{
    int	    	i;

    /*
     * Perform the pending protocol relocations.
     */
    if (fileOps->flags & FILE_PROTO_RELS) {
	for (i = 0; i < numProtoRels; i++) {
	    char    *name;

	    /*
	     * Make sure the thing is linked in (in a no-load fashion) before
	     * we try and determine the protocol number to use.
	     */
	    name = ST_Lock(symbols, protoRels[i].library->name);
	    if (Library_Link(name, LLT_ON_STARTUP, GA_LIBRARY) != LLV_FAILURE) {
		word    val;
		byte    *bp;
		ProtocolNumber	*pn;

		pn = &libs[protoRels[i].library->pdata.library].entry.protocol;
		val = protoRels[i].isMajor ? pn->major : pn->minor;

		bp = outbuf+protoRels[i].position;

		*bp++ = val;
		*bp = val>>8;
	    }
	    ST_Unlock(symbols, protoRels[i].library->name);
	}
    }
    
    printf("out final 2 in\n");
    (*fileOps->write)(outbuf, outsize, outfile);
}

typedef struct {
    ID    	name;
    word    	frame;
    word    	offset;
} AddrSym;


/***********************************************************************
 *				OutCmpSym
 ***********************************************************************
 * SYNOPSIS:	    Compare two address symbols by name.
 * CALLED BY:	    OutPrintByName via qsort
 * RETURN:	    <, =, > 0 as sym1->name <, =, > sym2->name
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/89	Initial Revision
 *
 ***********************************************************************/
static int
OutCmpSym(AddrSym   *sym1,
	  AddrSym   *sym2)
{
    char    *name1, *name2;
    int	    res;

    name1 = ST_Lock(symbols, sym1->name);
    name2 = ST_Lock(symbols, sym2->name);

    res = strcmp(name1, name2);

    ST_Unlock(symbols, sym1->name);
    ST_Unlock(symbols, sym2->name);

    return(res);
}

/***********************************************************************
 *				OutPrintByName
 ***********************************************************************
 * SYNOPSIS:	    Print out all public address symbols in the output
 *	    	    file sorted by name. This is a pain in the ass,
 *	    	    so I'm going to put it off for a bit.
 * CALLED BY:	    OutPrepare
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *	THIS IS A KLUDGE AND WILL NOT WORK ON THE PC.
 *	We take advantage of the linear address space and the nopness
 *	of ST_Unlock to just place all the names and offsets into a
 *	big array and call qsort on the thing.
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/17/89	Initial Revision
 *
 ***********************************************************************/
static void
OutPrintByName(FILE *mf)    	/* Stream open to map file */
{
    int	    	    i;
    int	    	    j;
    AddrSym 	    *syms;
    
    fprintf(mf, "  Address         Publics by Name\n\n");
    
    syms = (AddrSym *)malloc(numAddrSyms * sizeof(AddrSym));
    
    j = 0;
    
    for (i = 0; i < seg_NumSegs; i++) {
	VMBlockHandle   cur;
	VMBlockHandle   next;
	SegDesc	    	*sd = seg_Segments[i];

	for (cur = sd->addrH; cur != 0; cur = next) {
	    ObjSym  	    *os;
	    ObjSymHeader    *osh;
	    word    	    n;

	    osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	    n = osh->num;

	    for (os = (ObjSym *)(osh+1); n > 0; os++, n--) {
		switch(os->type) {
		    case OSYM_VAR:
		    case OSYM_CHUNK:
		    case OSYM_PROC:
		    case OSYM_LABEL:
		    case OSYM_LOCLABEL:
		    case OSYM_CLASS:
		    case OSYM_MASTER_CLASS:
		    case OSYM_VARIANT_CLASS:
		    case OSYM_ENTRY:
			syms[j].name = os->name;
			syms[j].frame = sd->pdata.frame;
			syms[j].offset = os->u.addrSym.address;
			j++;
			break;
		}
	    }
	    
	    next = osh->next;
	    VMUnlock(symbols, cur);
	    if (cur == sd->addrT) {
		next = 0;
	    }
	}
    }

    qsort(syms, numAddrSyms, sizeof(AddrSym), (CmpCallback) OutCmpSym);

    for (i = 0; i < j; i++) {
	fprintf(mf, " %04X:%04X       %i\n",
		syms[i].frame, syms[i].offset, syms[i].name);
    }

    free((void *)syms);

    fprintf(mf, "\n");
}

/***********************************************************************
 *				OutPrintByAddr
 ***********************************************************************
 * SYNOPSIS:	    Print out all public address symbols in the output
 *	    	    file sorted by address. This is less of a pain in
 *	    	    the ass, but I'm still going to put it off for a bit.
 * CALLED BY:	    OutPrepare
 * RETURN:	    Nothing
 * SIDE EFFECTS:    None
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/17/89	Initial Revision
 *
 ***********************************************************************/
static void
OutPrintByAddr(FILE *mf)    	/* Stream open to map file */
{
    int	    	    i;
    
    fprintf(mf, "  Address         Publics by Value\n\n");
    
    for (i = 0; i < seg_NumSegs; i++) {
	VMBlockHandle   cur;
	VMBlockHandle   next;
	SegDesc	    	*sd = seg_Segments[i];

	for (cur = sd->addrH; cur != 0; cur = next) {
	    ObjSym  	    *os;
	    ObjSymHeader    *osh;
	    MemHandle	    mem;
	    word    	    n;

	    osh = (ObjSymHeader *)VMLock(symbols, cur, &mem);
	    MemInfo(mem, (genptr *)NULL, &n);

	    n -= sizeof(ObjSymHeader);
	    n /= sizeof(ObjSym);
	    for (os = (ObjSym *)(osh+1); n > 0; os++, n--) {
		switch(os->type) {
		    case OSYM_VAR:
		    case OSYM_CHUNK:
		    case OSYM_PROC:
		    case OSYM_LABEL:
		    case OSYM_LOCLABEL:
		    case OSYM_CLASS:
		    case OSYM_MASTER_CLASS:
		    case OSYM_VARIANT_CLASS:
			fprintf(mf, " %04X:%04X       %i\n",
				sd->pdata.frame, os->u.addrSym.address,
				os->name);
			break;
		}
	    }
	    next = osh->next;
	    VMUnlock(symbols, cur);
	    if (cur == sd->addrT) {
		next = 0;
	    }
	}
    }
}


/***********************************************************************
 *				Out_DosMap
 ***********************************************************************
 * SYNOPSIS:	    Output a map file in standard DOS format
 * CALLED BY:	    ExePrepare, ComPrepare
 * RETURN:	    Nothing
 * SIDE EFFECTS:    The map file is created...
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/23/89	Initial Revision
 *
 ***********************************************************************/
void
Out_DosMap(char	    *mapfile,
	   long	    imgBase)
{
    FILE	*mf = fopen(mapfile, "w");
    int	    	i;
    SegDesc 	*sd;
    
    if (mf == NULL) {
	Notify(NOTIFY_WARNING, "Couldn't open map file %s", mapfile);
    } else {
	fprintf(mf, "\n");
	fprintf(mf, " Start  Stop   Length Name                   Class\n");
	for (i = 1; i < seg_NumSegs; i++) {
	    sd = seg_Segments[i];
	    
	    if (sd->combine != SEG_GLOBAL && sd->combine != SEG_ABSOLUTE &&
		sd->combine != SEG_LIBRARY)
	    {
		fprintf(mf, " %05lXH %05lXH %05XH %-22li %i\n",
			sd->foff-imgBase,
			sd->size == 0 ? 0 : (sd->foff+sd->size-imgBase)-1,
			sd->size, sd->name, sd->class);
	    }
	}
	fprintf(mf, "\n");
	if (seg_NumGroups) {
	    fprintf(mf, " Origin   Group\n");
	    for (i = 0; i < seg_NumGroups; i++) {
		GroupDesc   *gd = seg_Groups[i];
		
		fprintf(mf, " %04X:0   %i\n", gd->pdata.frame, gd->name);
	    }
	    fprintf(mf, "\n");
	}
	
	OutPrintByName(mf);
	OutPrintByAddr(mf);
	
	fclose(mf);
    }
}


/***********************************************************************
 *				Out_ExtraReloc
 ***********************************************************************
 * SYNOPSIS:	    Apply extra relocation to the symbols and lines
 *	    	    of a segment
 * CALLED BY:	    ExePrepare, VMPrepare
 * RETURN:	    Nothing
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/25/89	Initial Revision
 *
 ***********************************************************************/
void
Out_ExtraReloc(SegDesc	*sd,	    /* Segment needing adjustment */
	       word 	reloc)	    /* Extra relocation to apply to all
				     * address symbols and line numbers */
{
    VMBlockHandle   cur;
    VMBlockHandle   next;
	    
    for (cur = sd->addrH; cur != 0; cur = next) {
	ObjSym	    	*os;
	ObjSymHeader    *osh;
	word    	n;
	
	osh = (ObjSymHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	n = osh->num;
	
	for (os = (ObjSym *)(osh+1); n > 0; os++, n--) {
	    switch(os->type) {
		case OSYM_VAR:
		case OSYM_CHUNK:
		case OSYM_PROC:
		case OSYM_LABEL:
		case OSYM_LOCLABEL:
		case OSYM_CLASS:
		case OSYM_VARIANT_CLASS:
		case OSYM_MASTER_CLASS:
		case OSYM_ONSTACK:
		    os->u.addrSym.address += reloc;
		    break;
	    }
	}
	next = osh->next;
	VMUnlockDirty(symbols, cur);
	if (cur == sd->addrT) {
	    next = 0;
	}
    }

    /*
     * Now do the same for all the line number records.
     */
    for (cur = sd->lineH; cur != 0; cur = next) {
	ObjLine	    	*ol;
	ObjLineHeader	*olh;
	word	    	n;
	
	olh = (ObjLineHeader *)VMLock(symbols, cur, (MemHandle *)NULL);
	n = olh->num;
	
	for (ol = (ObjLine *)(olh+1)+1, n--; n > 0; ol++, n--){
	    if (ol->line != 0) {
		/*
		 * Real record -- adjust offset
		 */
		ol->offset += reloc;
	    } else {
		/*
		 * Skip file name
		 */
		ol++, n--;
	    }
	}
	next = olh->next;
	VMUnlockDirty(symbols, cur);
    }

    /*
     * And for the line number map
     */
    if (sd->lineMap) {
	ObjAddrMapHeader    *oamh;
	ObjAddrMapEntry	    *oame;
	word	    	    n;

	oamh = (ObjAddrMapHeader *)VMLock(symbols, sd->lineMap,
					  (MemHandle *)NULL);
	n = oamh->numEntries;
	oame = (ObjAddrMapEntry *)(oamh+1);

	while(n > 0) {
	    oame->last += reloc;
	    oame++, n--;
	}

	VMUnlockDirty(symbols, sd->lineMap);
    }
}


/***********************************************************************
 *				Out_FinishLineBlock
 ***********************************************************************
 * SYNOPSIS:	    Close off a line-number block for a segment.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    nothing
 * SIDE EFFECTS:    another entry is added to the segment's lineMap.
 *		    the lineMap is allocated if it existed not.
 *	    	    the line block is shrunk to hold as many entries as
 *		        it does.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/20/92	Initial Revision
 *
 ***********************************************************************/
void
Out_FinishLineBlock(SegDesc 	    *sd,
		    VMBlockHandle   block)
{
    ObjLineHeader   	*olh;
    ObjAddrMapHeader	*oamh;
    ObjAddrMapEntry 	*oame;
    MemHandle	    	mem;

    if (sd->lineMap == 0) {
	sd->lineMap = VMAlloc(symbols,
			      sizeof(ObjAddrMapHeader)+sizeof(ObjAddrMapEntry),
			      OID_ADDR_MAP);
	oamh = (ObjAddrMapHeader *)VMLock(symbols, sd->lineMap, 
					    (MemHandle *)NULL);
	oamh->numEntries = 1;
	oame = (ObjAddrMapEntry *)(oamh+1);
    } else {
	oamh = (ObjAddrMapHeader *)VMLock(symbols, sd->lineMap, &mem);
	oame = ObjFirstEntry(oamh, ObjAddrMapEntry) + oamh->numEntries-1;
	if (oame->block != block) {
	    oamh->numEntries += 1;
	    MemReAlloc(mem,
		       (sizeof(ObjAddrMapHeader)+
			oamh->numEntries*sizeof(ObjAddrMapEntry)),
		       0);
	    MemInfo(mem, (genptr *)&oamh, (word *)NULL);
	    oame = (ObjAddrMapEntry *)(oamh+1)+oamh->numEntries-1;
	}
    }
    olh = (ObjLineHeader *)VMLock(symbols, block, &mem);

    oame->block = block;
    oame->last = ((ObjLine *)(olh+1)+olh->num-1)->offset;

    VMUnlock(symbols, block);
    VMUnlockDirty(symbols, sd->lineMap);
}

/***********************************************************************
 *				Out_AddLines
 ***********************************************************************
 * SYNOPSIS:	    Add line numbers to an output segment, relocating them
 *	    	    all as necessary.
 * CALLED BY:	    Pass1VMRelLines, Out_PromoteGroups
 * RETURN:	    Nothing
 * SIDE EFFECTS:    WHat's a side-effect?
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	3/20/90		Initial Revision
 *
 ***********************************************************************/
void
Out_AddLines(char   	    *file,  	/* Name of file containing line map to
					 * be added */
	     VMHandle	    fh,     	/* Handle containing lines. May be
					 * "symbols" */
	     SegDesc	    *sd,    	/* Segment in symbols to which to
					 * append the lines */
	     VMBlockHandle  lineMap,	/* Block mapping lines to append */
	     word   	    reloc,  	/* Relocation factor for the line
					 * numbers */
	     Boolean	    doSrcMap)	/* TRUE if no entries in the src map
					 * for these line numbers. */
{
    ObjLineHeader   *olh;   	/* Header of current block */
    ObjLineHeader   *olhn;
    ObjLine 	    *ol;    	/* Line to relocate */
    ObjLine 	    *oln;
    VMBlockHandle   prev;   	/* Handle of block before this one */
    VMBlockHandle   next;   	/* Handle of next block to copy */
    word    	    n;	    	/* Block size/number of lines left
				 * to relocate */
    ObjAddrMapHeader *oamh; 	/* Header for line map */
    ObjAddrMapEntry *oame;  	/* Entry being relocated */


    if (noLMemLineNumbers && sd->combine == SEG_LMEM) {
	/*
	 * If line numbers were allocated in the symbol file already, biff them
	 */
	if (fh == symbols) {
	    oamh = (ObjAddrMapHeader *)VMLock(fh, lineMap, (MemHandle *)NULL);
	    n = oamh->numEntries;
	    
	    oame = (ObjAddrMapEntry *)(oamh+1);
	    while (n > 0) {
		VMFree(symbols, oame->block);
		n--, oame++;
	    }
	}
	    
	return;
    }

    oamh = (ObjAddrMapHeader *)VMLock(fh, lineMap, (MemHandle *)NULL);
    n = oamh->numEntries;
    
    oame = (ObjAddrMapEntry *)(oamh+1);

    prev = sd->lineT;
    
    while (n > 0) {
	int 	i;
	ID  	fileName;   	    /* Current filename */
	int 	allocNew;   	    /* Non-zero if need to allocate a new
				     * line number block */
	int 	isFileName; 	    /* Non-zero if next ObjLine holds a file
				     * name, not a line number */
	int 	prevStart = -1;	    /* Start of the current range. If -1, we
				     * don't know it yet. When we change to
				     * a different file, if this isn't -1, it
				     * means we need to enter a range into the
				     * source map for the previous file */

	olh = (ObjLineHeader *)VMLock(fh, oame->block, (MemHandle *)NULL);
	/*
	 * See if there's enough room in the current line block for all these
	 * line numbers.
	 */
	if (prev != 0) {
	    MemHandle	mem;
	    
	    olhn = (ObjLineHeader *)VMLock(symbols, prev, &mem);
	    if (olhn->num + olh->num + 1 > OBJ_INIT_LINES/sizeof(ObjLine)) {
		allocNew = 1;
	    } else {
		MemReAlloc(mem,
			   (sizeof(ObjLineHeader) +
			    (olhn->num+olh->num+1) * sizeof(ObjLine)),
			   0);
		MemInfo(mem, (genptr *)&olhn, (word *)NULL);
		allocNew = 0;
	    }
	} else {
	    allocNew = 1;
	}

	/*
	 * If we need to allocate a new block, do so now.
	 */
	if (allocNew) {
	    next = VMAlloc(symbols,
			   (olh->num * sizeof(ObjLine) +
			    sizeof(ObjLineHeader)),
			   OID_LINE_BLOCK);
	    
	    if (prev) {
		/*
		 * Add lineMap entry for the thing, and shrink to size used.
		 */
		Out_FinishLineBlock(sd, prev);
		olhn->next = next;
		VMUnlockDirty(symbols, prev);
	    } else {
		/*
		 * First block for the thing -- store as head, too.
		 */
		sd->lineH = next;
	    }
	    sd->lineT = next;

	    olhn = (ObjLineHeader *)VMLock(symbols, next, (MemHandle *)NULL);
	    olhn->num = 0;
	    olhn->next = 0;
	    prev = next;
	}
	

	ol = ObjFirstEntry(olh, ObjLine);
	oln = (ObjLine *)(olhn+1) + olhn->num;
	
	/*
	 * Now copy all the entries from the source block to the dest
	 * block, duplicating filename IDs, adding source-map info, and
	 * relocating offsets as we go.
	 */
	isFileName = TRUE;

	if (!allocNew) {
	    /*
	     * If sticking things into the middle of a block, we need a bogus
	     * record w/line 0 to signal the filename we're about to enter.
	     */
	    oln->line = 0;
	    oln++;
	}

	fileName = NullID;	/* Be quiet, GCC (prevStart starts at -1,
				 * while isFileName starts TRUE, this means
				 * fileName will be initialized the first time
				 * through the loop without being used; it
				 * won't be used after the loop unless the
				 * loop has been gone through once [to set
				 * prevStart to -1]) */

	for (i = olh->num; i > 0; i--, ol++, oln++) {
	    if (isFileName) {
		if (prevStart != -1) {
		    /*
		     * Actually had some line numbers there, so enter a range
		     * for that preceding file, remembering to skip ol back
		     * 2, to skip over the bogus entry that signalled this one
		     * as being a filename.
		     */
		    if (doSrcMap) {
			AddSrcMapEntry(fileName, sd, prevStart, ol[-2].line);
		    }
		    prevStart = -1;
		}

		if (fh != symbols) {
		    fileName = ST_Dup(fh, *(ID *)ol, symbols, strings);
		} else {
		    fileName = *(ID *)ol;
		}
		
		*(ID *)oln = fileName;
		isFileName = FALSE;
	    } else if (ol->line == 0) {
		isFileName = TRUE;
		oln->line = 0;
	    } else {
		oln->line = ol->line;
		oln->offset = ol->offset + reloc;
		if (prevStart == -1) {
		    prevStart = oln->line;
		}
	    }
	}

	if (prevStart != -1) {
	    /*
	     * Actually had some line numbers there, so enter a range
	     * for the final file in the block.
	     */
	    assert(!isFileName);
	    if (doSrcMap) {
		AddSrcMapEntry(fileName, sd, prevStart, ol[-1].line);
	    }
	}

	olhn->num += olh->num + (allocNew ? 0 : 1);
	
	VMUnlockDirty(symbols, prev);
	
	if (fh == symbols) {
	    /*
	     * If block lies in symbol file, free it now, as we need it
	     * no longer.
	     */
	    VMFree(fh, oame->block);
	}
	
	/*
	 * Advance to the next map entry
	 */
	oame++, n--;
    }
}


/***********************************************************************
 *				Out_PromoteGroups
 ***********************************************************************
 * SYNOPSIS:	    Promote all groups to be segments.
 * CALLED BY:	    VmPrepare, GeoPrepare
 * RETURN:	    Nothing
 * SIDE EFFECTS:    All groups are allocated SegDesc's, seg_NumGroups
 *	    	    is set to 0, all segments in groups are shifted
 *	    	    to seg_SubSegs with attendant state variable
 *	    	    modification.
 *	    	    The symbol and line tables for the segments
 *	    	    are merged into a single table for the group.
 *
 *	    	    NOTE: seg_NumGroups is left non-zero. The caller must
 *	    	    zero it out when it's done with the group descriptors
 *
 *	    	    NOTE: the grpOff fields of the subsumed groups are set
 *	    	    to their offsets w/in the group in case the caller
 *	    	    requires this information. These offsets should be
 *	    	    reset to zero before pass 2 if you expect the
 *	    	    linker to function properly.
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	10/25/89	Initial Revision
 *
 ***********************************************************************/
void
Out_PromoteGroups(void)
{
    int	    	i;
    int	    	obj_hash_chains;

    /*
     * Figure the number of segments that are to be subsumed into their
     * groups.
     */
    if (oldSymfileFormat == TRUE) {
	obj_hash_chains = OBJ_HASH_CHAINS;
    } else {
	obj_hash_chains = OBJ_HASH_CHAINS_NEW_FORMAT;
    }
    for (i = 0; i < seg_NumGroups; i++) {
	seg_NumSubSegs += seg_Groups[i]->numSegs;
    }

    if (seg_NumSubSegs != 0) {
	int 	    j,	    /* Index into new seg_Segments array */
		    gs;	    /* Index into seg_SubSegs array */
	SegDesc	    **newSegs;	/* New seg_Segments array */
	
	seg_SubSegs = (SegDesc **)malloc(seg_NumSubSegs * sizeof(SegDesc *));
	gs = 0;
	
	/*
	 * First create new seg_Segments array containing segments that
	 * aren't in groups and new segment descriptors for the groups.
	 */
	newSegs =
	    (SegDesc **)malloc((seg_NumSegs+seg_NumGroups-seg_NumSubSegs)*
			       sizeof(SegDesc *));

	for (j = i = 0; i < seg_NumSegs; i++) {
	    if (seg_Segments[i]->group == NULL) {
		newSegs[j++] = seg_Segments[i];
	    }
	}

	for (i = 0; i < seg_NumGroups; i++, j++) {
	    GroupDesc 	    *gd = seg_Groups[i];
	    SegDesc 	    *sd;    /* Metamorphosis of gd */
	    int	    	    s;	    /* Group segment number */
	    ObjHashHeader   *table; /* Combined hash table */
	    int	    	    combine;
	    int	    	    roff;   /* Relocation offset for next
				     * group-segment */
	    int	    	    hasProfMark = FALSE;

	    /*
	     * KLUDGE: If any of the segments in the group is a stack
	     * segment, shift it to be the last and mark the promoted
	     * group as a stack segment
	     */
	    combine = SEG_PUBLIC;
	    for (s = 0; s < gd->numSegs; s++) {
		hasProfMark = hasProfMark || gd->segs[s]->hasProfileMark;
		if (gd->segs[s]->combine == SEG_STACK) {
		    sd = gd->segs[s];
		    gd->segs[s] = gd->segs[gd->numSegs-1];
		    gd->segs[gd->numSegs-1] = sd;
		    combine = SEG_STACK;
		    break;
		} else if (gd->segs[s]->combine == SEG_LMEM) {
		    combine = SEG_LMEM;
		    break;
		} else if (gd->segs[s]->combine == SEG_RESOURCE) {
		    combine = SEG_RESOURCE;
		    break;
		}
	    }
	    
	    sd = newSegs[j] = (SegDesc *)calloc(1, sizeof(SegDesc));

	    /*
	     * Take most of our attributes from the first segment in the
	     * group.
	     */
	    *sd = *gd->segs[0];
	    seg_SubSegs[gs++] = gd->segs[0];

	    /*
	     * Replace a few select ones however.
	     */
	    sd->name = gd->name;
	    sd->class = NullID;
	    sd->combine = combine;
	    sd->alignment = 0xf;
	    sd->hasProfileMark = hasProfMark;
	    
	    table = (ObjHashHeader *)VMLock(symbols, sd->syms,
					    (MemHandle *)NULL);

	    roff = sd->nrel * fileOps->rtrelsize;
	    
	    gd->segs[0]->type = S_SUBSEGMENT;
	    gd->segs[0]->grpOff = 0;
	    gd->segs[0]->roff = 0;
	    
	    /*
	     * Now merge the data from the other segments into this one.
	     * XXX: Deal with duplicate symbols!
	     */
	    for (s = 1; s < gd->numSegs; s++) {
		SegDesc	    	*ns = gd->segs[s];
		int 	    	chain;
		ObjHashHeader	*ohh;

		seg_SubSegs[gs++] = ns;
		ns->type = S_SUBSEGMENT;
		
		/*
		 * We set the group offset to the relocation applied so
		 * the caller knows the layout of the thing. We rely on
		 * the caller resetting the group offset back to zero,
		 * since all the symbols have already been relocated....
		 */
		sd->size = (sd->size + ns->alignment) & ~ns->alignment;
		ns->grpOff = sd->size;

		ns->roff = roff;
		roff += ns->nrel * fileOps->rtrelsize;
		    
		/*
		 * Adjust all address symbols and lines for the nested
		 * segment before linking them in (easier this way).
		 */
		Out_ExtraReloc(ns, sd->size);
		
		if (ns->lineMap) {
		    /*
		     * Tack the lines onto the end, passing a relocation of 0
		     * since we relocated all the lines already anyway.
		     */
		    Out_AddLines("output", symbols, sd, ns->lineMap, 0, FALSE);

		    /*
		     * No need for the subsegment's line map...usually
		     */
		    if (sd->lineMap != ns->lineMap) {
			VMFree(symbols, ns->lineMap);
		    }
		}

		if (ns->addrH) {
		    ObjSymHeader    *osh;

		    /*
		     * If no address symbols for the group so far, use those
		     * for this segment, else link the chain for this
		     * segment to the end of the chain for the group as
		     * a whole.
		     *
		     * This works even if ns has no address symbols.
		     */
		    if (sd->addrH == 0) {
			sd->addrH = ns->addrH;
			sd->addrT = ns->addrT;
		    } else {
			osh = (ObjSymHeader *)VMLock(symbols, sd->addrT,
						     (MemHandle *)NULL);
			osh->next = ns->addrH;
			VMUnlockDirty(symbols, sd->addrT);
			if (ns->addrT != 0) {
			    sd->addrT = ns->addrT;
			}
		    }
		}

		if (ns->symH) {
		    ObjSymHeader    *osh;

		    /*
		     * If no type symbols for the group so far, use those
		     * for this segment, else link the chain for this
		     * segment to the end of the chain for the group as
		     * a whole.
		     *
		     * This works even if ns has no type symbols.
		     */
		    if (sd->symH == 0) {
			sd->symH = ns->symH;
			sd->symT = ns->symT;
		    } else {
			osh = (ObjSymHeader *)VMLock(symbols, sd->symT,
						      (MemHandle *)NULL);
			osh->next = ns->symH;
			VMUnlockDirty(symbols, sd->symT);
			if (ns->symT != 0) {
			    sd->symT = ns->symT;
			}
		    }
		}

		/*
		 * Wheee. Now link in the various hash block chains.
		 */
		ohh = (ObjHashHeader *)VMLock(symbols, ns->syms,
					      (MemHandle *)NULL);

		
		for (chain = 0; chain < obj_hash_chains; chain++) {
		    if (ohh->chains[chain]) {
			if (table->chains[chain]) {
			    /*
			     * Already a block in this chain. Shrink the head
			     * block for the current table, find the end
			     * of the chain in ns's table and link the current
			     * chain to it, then install ns's chain at the
			     * head. We do it this way to avoid having to
			     * work down an ever-longer chain as more blocks
			     * are added to this chain with each new segment.
			     */
			    ObjHashBlock    *hb;
			    MemHandle	    mem;
			    VMBlockHandle   c;
			    
			    hb = (ObjHashBlock *)VMLock(symbols,
							table->chains[chain],
							&mem);
			    
			    (void)MemReAlloc(mem,
					     (genptr)&hb->entries[hb->nextEnt]-(genptr)hb,
					     0);
			    
			    VMUnlockDirty(symbols, table->chains[chain]);
			    c = ohh->chains[chain];
			    while (1) {
				VMBlockHandle	n;  /* Next block */
				
				hb = (ObjHashBlock *)VMLock(symbols, c,
							    (MemHandle *)NULL);
				if (hb->next == 0) {
				    /*
				     * hb is last block in the chain -- leave
				     * now while we still can :)
				     */
				    break;
				}
				n = hb->next;
				VMUnlock(symbols, c);
				c = n;
			    }

			    /*
			     * Link current chain at the end and make the
			     * merged chain the actual one.
			     */
			    hb->next = table->chains[chain];
			    table->chains[chain] = ohh->chains[chain];
			    VMUnlockDirty(symbols, c);
			} else {
			    /*
			     * Nothing to merge -- just make ns's chain the
			     * actual one in the table.
			     */
			    table->chains[chain] = ohh->chains[chain];
			}
		    }
		}

		/*
		 * No need for the header block from ns's hash table, so
		 * biff it and replace the variable with the table for the
		 * entire segment.
		 */
		VMFree(symbols, ns->syms);
		ns->syms = sd->syms;

		/*
		 * Up the size of the combined group and the number of
		 * relocations in it.
		 */
		sd->nrel += ns->nrel;
		sd->size += ns->size;
		if (sd->size > 65535) {
		    Notify(NOTIFY_ERROR,
			   "segment %i greater than 64K (now %d bytes)",
			   sd->name, sd->size);
		}
	    }

	    /*
	     * Chances are good the table changed, so mark it dirty.
	     */
	    VMUnlockDirty(symbols, sd->syms);

	    /*
	     * Finish off final line block, entering it into the map for
	     * the segment.
	     */
	    if (sd->lineT) {
		Out_FinishLineBlock(sd, sd->lineT);
	    }
	}
	/*
	 * Set seg_NumSegs to the cumulative total
	 */
	seg_NumSegs = j;
	/*
	 * Set the new array of segments in place, freeing the old one.
	 */
	free((char *)seg_Segments);
	seg_Segments = newSegs;
    }
}


/***********************************************************************
 *				Out_FindConstSym
 ***********************************************************************
 * SYNOPSIS:	    Find a constant symbol in the output file and return
 *	    	    its value if found.
 * CALLED BY:	    EXTERNAL
 * RETURN:	    TRUE & value if symbol found.
 * SIDE EFFECTS:
 *
 * STRATEGY:
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/18/91		Initial Revision
 *
 ***********************************************************************/
int
Out_FindConstSym(char	*name,	    /* Symbol to find */
		 int	*valPtr)    /* Place to store value if found,
				     * undisturbed if symbol not found */
{
    ID      id = ST_LookupNoLen(symbols, strings, name);
    int	    i;

    if (id != NullID) {
	/*
	 * ID defined, so we assume the symbol's somewhere...
	 */
	for(i = 0; i < seg_NumSegs; i++) {
	    SegDesc	    	*sd = seg_Segments[i];
	    VMBlockHandle	block;
	    word	    	off;

	    if (Sym_Find(symbols, sd->syms, id, &block, &off, TRUE)) {
		ObjSym  	*sym;

		sym = (ObjSym *)((genptr)VMLock(symbols, block,
					(MemHandle *)NULL)+off);
		if (sym->type == OSYM_CONST) {
		    *valPtr = sym->u.constant.value;
		    VMUnlock(symbols, block);
		    return(TRUE);
		}
		VMUnlock(symbols, block);
	    }
	}
    }
    return(FALSE);
}

/***********************************************************************
 *				Out_RegisterFinalProtoRel
 ***********************************************************************
 * SYNOPSIS:	    Record a relocation for the major or minor number of
 *	    	    a library or driver. These relocations must be handled
 *	    	    at the end of everything, so all symbols that might
 *		    require a higher minor number will have been processed
 * CALLED BY:	    (EXTERNAL)
 * RETURN:	    nothing
 * SIDE EFFECTS:    protoRels is extended
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	2/ 8/95		Initial Revision
 *
 ***********************************************************************/
void
Out_RegisterFinalProtoRel(Boolean   isMajor,
			  long	    position,
			  SegDesc   *library)
{
    OutProtoRel	*rel;
    
    numProtoRels += 1;
    
    if (numProtoRels > 1) {
	protoRels = (OutProtoRel *)realloc((malloc_t)protoRels,
					   numProtoRels * sizeof(OutProtoRel));
    } else {
	protoRels = (OutProtoRel *)malloc(sizeof(OutProtoRel));
    }
    rel = &protoRels[numProtoRels-1];

    rel->isMajor = isMajor;
    rel->position = position;
    rel->library = library;
    assert(library->combine == SEG_LIBRARY);
}
