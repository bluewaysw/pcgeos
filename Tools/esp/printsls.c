/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  printobj.c
 * FILE:	  printobj.c
 *
 * AUTHOR:  	  Adam de Boor: Aug 30, 1989
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	8/30/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Program to print out the contents of an object file.
 *
 ***********************************************************************/

#include    "config.h"

#include    <st.h>
#include    <objfmt.h>
#include    <objSwap.h>
#include    <stdio.h>
#include    <ctype.h>

int 	debug = 0;
int	obj_hash_chains;    	/* used for symfile format compatibility */

VMHandle	    output;
int	    	    geosRelease;    /* For VM functions */
int	    	    dbcsRelease = 0; /* For VM functions */
int	    	    useDecimal = 0;

const char *segtypes[] = {
    "private", "common", "stack", "library", "resource", "lmem", "public",
    "absolute", "global"
};

const char *registers[] = {
    "ax", "bx", "cx", "dx", "sp", "bp", "si", "di",
    "es", "cs", "ss", "ds", 
    "al", "bl", "cl", "dl", "ah", "bh", "ch", "dh"
    };

void
DumpSyms(VMHandle   	file,
	 VMBlockHandle	block,
	 const char*    segName,
	 int	    	segOff)
{
    ObjSymHeader    *hdr;
    ObjSym  	    *sym;
    int	    	    n;
    word    	    size;
    MemHandle	    mem;
    VMBlockHandle   next;

    while (block != NULL) {
	hdr = (ObjSymHeader *)VMLock(file, block, &mem);
	MemInfo(mem, (genptr *)NULL, &size);

	if (hdr->seg != segOff) {
	    printf("************** WARNING: hdr->seg (%d) != segOff (%d) ************\n",
		   hdr->seg, segOff);
	}

	n = hdr->num;

	if (debug) {
	    printf("Block %04xh, %d symbols, types = %04xh\n", block, n,
		   hdr->types);
	}
	for (sym = (ObjSym *)(hdr+1); n > 0; sym++, n--) {
		switch(sym->type) {
			case OSYM_CLASS:
				printf("%i %u %i\n",
					segName,
					sym->u.class.address,
					sym->name);
				break;
			case OSYM_PROC:
				printf(
				"%i %u %i\n",
				segName,
				sym->u.proc.address,
				sym->name);
				break;
		}
		next = hdr->next;
		VMUnlock(file, block);
		block = next;
	}
    }
}

volatile void
main(int argc, char **argv)
{
    short   	    status;
    VMBlockHandle   map;
    ObjSegment 	    *seg;
    ObjHeader	    *hdr;
    int	    	    i;
    extern volatile void exit(int);
    extern char	    *optarg;
    extern int	    optind;
    char    	    optchar;

    if (argc < 2) {
        fprintf(stderr, 
		"usage: printsls [-d] [-D] <symfile>\n"
		"\t-d\tprint values in decimal\n"
		"\t-D\tturn on debugging mode\n");
	exit(1);
    }

    while ((optchar = getopt(argc, argv, "Dd")) != (char)EOF) {
	switch (optchar) {
	    case 'D':
		debug = 1;
		break;
	    case 'd':
		useDecimal = 1;
		break;
	}
    }
    output = VMOpen(VMO_OPEN|FILE_DENY_W|FILE_ACCESS_R, 0,
			     argv[optind],
			     &status);

    if (output == NULL) {
	perror(argv[optind]);
	exit(1);
    }
    UtilSetIDFile(output);

    map = VMGetMapBlock(output);
    hdr = (ObjHeader *)VMLock(output, map, NULL);

    switch(hdr->magic)
    {
	case SWOBJMAGIC:
	    ObjSwap_Header(hdr);
	    VMSetReloc(output, ObjSwap_Reloc);
	    /* FALLTHRU */
	case OBJMAGIC:
	    obj_hash_chains = OBJ_HASH_CHAINS;
	    break;
	case SWOBJMAGIC_NEW_FORMAT:
	    ObjSwap_Header(hdr);
	    VMSetReloc(output, ObjSwap_Reloc_NewFormat);
	    /* FALLTHRU */
	case OBJMAGIC_NEW_FORMAT:
	    obj_hash_chains = OBJ_HASH_CHAINS_NEW_FORMAT;
	    break;
	default:
	    printf("invalid magic number (is %04x, s/b %04x)\n",
		   hdr->magic, OBJMAGIC);
	    exit(1);
    }

    printf("; protocol: %d.%d; revision: %d.%d.%d.%d\n",
	   hdr->proto.major, hdr->proto.minor,
	   hdr->rev.major, hdr->rev.minor, hdr->rev.change, hdr->rev.internal);

    if (hdr->entry.frame != NULL) {
	ID  	frame;
	ObjSym	*sym;
	
	if (hdr->entry.frame > (sizeof(ObjHeader) +
				hdr->numSeg * sizeof(ObjSegment)))
	{
	    frame = ((ObjGroup *)((genptr)hdr+hdr->entry.frame))->name;
	} else {
	    frame = ((ObjSegment *)((genptr)hdr+hdr->entry.frame))->name;
	}
	
	if (hdr->entry.symBlock == 0) {
	    //printf("no symbol");
	} else {
	    sym = (ObjSym *)((genptr)VMLock(output, hdr->entry.symBlock, NULL) +
			     hdr->entry.symOff);
	    //printf("target = %i", sym->name);
	}
	//printf (", frame = %i\n", frame);
    }
	
    for (i = hdr->numSeg, seg = (ObjSegment *)(hdr+1);
	 i > 0;
	 i--, seg++)
    {
	/*printf("%sSegment %d: name %i, class %i, type %s, alignment %#x, size %5d\n",
	       i == hdr->numSeg ? "" : "\n=================\n",
	       hdr->numSeg-i+1,
	       seg->name, seg->class, segtypes[seg->type], seg->align,
	       seg->size);
	if (seg->type == SEG_ABSOLUTE) {
	    printf("\tlocated at %04x:0\n", seg->data);
	} else {
	    printf("*** DATA:\n");
	    DumpBlock(output, seg->data);
	}*/
	//printf("*** SYMBOLS:\n");
	DumpSyms(output, seg->syms, seg->name, (genptr)seg-(genptr)hdr);
	//printf("*** RELOCATIONS:\n");
	//DumpRel(output, seg->relHead, hdr);
	//printf("*** LINES:\n");
	//DumpLines(output, seg->lines);
    }

    VMClose(output);
    exit(0);

}
