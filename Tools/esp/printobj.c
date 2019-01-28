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

#include    <config.h>

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
DumpBlock(VMHandle  	file,
	  VMBlockHandle	block)
{
    byte    	*base, *bp, *start;
    word    	size;
    MemHandle	mem;
    int	    	i;

    if (block == NULL) {
	printf("\tNONE\n");
	return;
    }
    
    base = (byte *)VMLock(file, block, &mem);
    MemInfo(mem, (genptr *)NULL, &size);

    for (start = base; size != 0; start += 16) {
	int 	n;
	
	printf("%04xh  ", start-base);

	n = 16;
	if (n > size) {
	    n = size;
	}
	for (i = n, bp = start; i > 0; bp++, i--) {
	    printf("%02x ", *bp);
	}
	printf("%*s\"", (16-n)*3 + 2, "");
	for (i = n, bp = start; i > 0; bp++, i--) {
	    if (isprint(*bp)) {
		putchar(*bp);
	    } else {
		putchar('.');
	    }
	}
	printf("\"\n");
	size -= n;
    }
    VMUnlock(file, block);
}
	
void
PrintType(VMHandle  	file,
	  VMBlockHandle	types,
	  word	    	type)
{
    if (type & OTYPE_SPECIAL) {
	switch(type & OTYPE_TYPE) {
	    case OTYPE_INT: printf("int(%d)", (type & OTYPE_DATA) >> 1); break;
	    case OTYPE_SIGNED: printf("signed(%d)", (type & OTYPE_DATA) >> 1); break;
	    case OTYPE_NEAR: printf("near"); break;
	    case OTYPE_FAR: printf("far"); break;
	    case OTYPE_CHAR:
		printf("char(%d)", ((type & OTYPE_DATA)>>1)+1);
		break;
	    case OTYPE_VOID: printf("void"); break;
	    case OTYPE_PTR: printf("%cptr", (type & OTYPE_DATA)>>1); break;
	    case OTYPE_BITFIELD:
		if (type & OTYPE_BF_WIDTH) {
		    printf("%ssigned bitfield@%d, %d bit%s",
			   (type & OTYPE_BF_SIGNED) ? "" : "un",
			   (type & OTYPE_BF_OFFSET) >> OTYPE_BF_OFFSET_SHIFT,
			   (type & OTYPE_BF_WIDTH) >> OTYPE_BF_WIDTH_SHIFT,
			   ((type & OTYPE_BF_WIDTH)==(1<<OTYPE_BF_WIDTH_SHIFT)?
			    "" : "s"));
		} else {
		    printf("bitfield");
		}
		break;
	}
    } else {
	ObjType	*t = (ObjType *)((genptr)VMLock(file, types, NULL)+type);

	if (OTYPE_IS_STRUCT(t->words[0])) {
	    printf("struct(%i)", OTYPE_STRUCT_ID(t));
	} else if (OTYPE_IS_PTR(t->words[0])) {
	    printf("%cptr(", OTYPE_PTR_TYPE(t->words[0]));
	    PrintType(file, types, t->words[1]);
	    printf(")");
	} else {
	    printf("%d array(", OTYPE_ARRAY_LEN(t->words[0]));
	    PrintType(file, types, t->words[1]);
	    printf(")");
	}
	VMUnlock(file, types);
    }
}

void
DumpSyms(VMHandle   	file,
	 VMBlockHandle	block,
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
	    if (debug) {
		printf("%04x\t%-20i: %s%s%s%s", (genptr)sym - (genptr)hdr,
		       sym->name,
		       sym->flags & OSYM_MOVABLE ? "movable " : "",
		       sym->flags & OSYM_GLOBAL ? "global " : "",
		       sym->flags & OSYM_UNDEF ? "undefined " : "",
		       sym->flags & OSYM_ENTRY ? "entry " : "");
	    } else {
		printf("\t%-20i: %s%s%s%s", sym->name,
		       sym->flags & OSYM_MOVABLE ? "movable " : "",
		       sym->flags & OSYM_GLOBAL ? "global " : "",
		       sym->flags & OSYM_UNDEF ? "undefined " : "",
		       sym->flags & OSYM_ENTRY ? "entry " : "");
	    }
	    switch(sym->type) {
		case OSYM_TYPEDEF:
		    printf("typedef to ");
		    PrintType(file, hdr->types, sym->u.typeDef.type);
		    printf("\n");
		    break;
		case OSYM_STRUCT:
		    printf("%d-byte structure:\n", sym->u.sType.size);
		    break;
		case OSYM_UNION:
		    printf("%d-byte union:\n", sym->u.sType.size);
		    break;
		case OSYM_RECORD:
		    printf("%d-byte record:\n", sym->u.sType.size);
		    break;
		case OSYM_ETYPE:
		    printf("%d-byte enumerated type:\n", sym->u.sType.size);
		    break;
		case OSYM_FIELD:
		    printf("field at %d: ", sym->u.sField.offset);
		    PrintType(file, hdr->types, sym->u.sField.type);
		    if (debug) {
			printf(" (next = %04x)\n", sym->u.sField.next);
		    } else {
			printf("\n");
		    }
		    break;
		case OSYM_BITFIELD:
		    printf("bitfield %d:%d ", sym->u.bField.offset,
			   sym->u.bField.width);
		    PrintType(file, hdr->types, sym->u.bField.type);
		    if (debug) {
			printf(" (next = %04x)\n", sym->u.bField.next);
		    } else {
			printf("\n");
		    }
		    break;
		case OSYM_ENUM:
		    printf("enum, value %d", sym->u.eField.value);
		    if (debug) {
			printf(" (next = %04x)\n", sym->u.eField.next);
		    } else {
			printf("\n");
		    }
		    break;
		case OSYM_VARDATA:
		    printf("vardata, value %d, data = ", sym->u.varData.value);
		    PrintType(file, hdr->types, sym->u.varData.type);
		    if (debug) {
			printf(" (next = %04x)\n", sym->u.varData.next);
		    } else {
			printf("\n");
		    }
		    break;
		case OSYM_METHOD:
		    printf("method number %d%s%s",
			   sym->u.method.value,
			   sym->flags&OSYM_REF?" referenced":" UNREF",
			   sym->u.method.flags&OSYM_METH_PUBLIC?" public":"");
		    if (sym->u.method.flags & OSYM_METH_RANGE) {
			printf(" %d-message exported range",
			       (sym->u.method.flags & OSYM_METH_RANGE_LENGTH) >>
			       OSYM_METH_RANGE_LENGTH_OFFSET);
		    }
		    if (debug) {
			printf(" (next = %04x)\n", sym->u.method.next);
		    } else {
			printf("\n");
		    }
		    break;
		case OSYM_CONST:
		    printf("constant value %d (%04xh)\n",
			   sym->u.constant.value, sym->u.constant.value);
		    break;
		case OSYM_PROTOMINOR:
		    printf("protominor token %s\n",
			   sym->flags&OSYM_REF?" referenced":" UNREF");
		    break;
		case OSYM_VAR:
		    printf("variable at %04x, type ", sym->u.variable.address);
		    PrintType(file, hdr->types, sym->u.variable.type);
		    printf("\n");
		    break;
		case OSYM_CHUNK:
		    printf("chunk at %04x, type ", sym->u.chunk.handle);
		    PrintType(file, hdr->types, sym->u.chunk.type);
		    printf("\n");
		    break;
		case OSYM_PROC:
		    if (debug) {
			printf(useDecimal ?
			       "%s%s%s%s%s%s procedure at %d (local = %04x)\n" :
			       "%s%s%s%s%s%s procedure at %04x (local = %04x)\n",
			       (sym->u.proc.flags & OSYM_WEIRD) ? "weird " : "",
			       (sym->u.proc.flags & OSYM_NO_JMP)?"no-jump ":"",
			       (sym->u.proc.flags & OSYM_NO_CALL)?"no-call ":"",
			       (sym->u.proc.flags & OSYM_PROC_PUBLISHED)?"published " : "",
			       (sym->u.proc.flags & OSYM_PROC_PASCAL)?"pascal " : "",
			       (sym->u.proc.flags & OSYM_NEAR)?"near":"far",
			       sym->u.proc.address, sym->u.proc.local);
		    } else {
			printf(useDecimal ?
			       "%s%s%s%s%s%s procedure at %d\n" :
			       "%s%s%s%s%s%s procedure at %04x\n",
			       (sym->u.proc.flags & OSYM_WEIRD) ? "weird " : "",
			       (sym->u.proc.flags & OSYM_NO_JMP)?"no-jump ":"",
			       (sym->u.proc.flags & OSYM_NO_CALL)?"no-call ":"",
			       (sym->u.proc.flags & OSYM_PROC_PUBLISHED)?"published " : "",
			       (sym->u.proc.flags & OSYM_PROC_PASCAL)?"pascal " : "",
			       (sym->u.proc.flags & OSYM_NEAR)?"near":"far",
			       sym->u.proc.address);
		    }
		    break;
		case OSYM_LABEL:
		    printf(useDecimal ?
			   "%s label at %d\n" :
			   "%s label at %04x\n",
			   sym->u.label.near ? "near" : "far",
			   sym->u.label.address);
		    break;
		case OSYM_LOCLABEL:
		    if (!debug) {
			printf(useDecimal ? "local label at %d\n" :
			       "local label at %04x\n",
			       sym->u.label.address);
		    } else {
			printf (useDecimal ?
				"local label at %d (next = %04x)\n" :
				"local label at %04x (next = %04x)\n",
				sym->u.label.address, sym->u.procLocal.next);
		    }
		    break;
		case OSYM_LOCVAR:
		    printf("local variable at %d[bp], type ",
			   sym->u.localVar.offset);
		    PrintType(file, hdr->types, sym->u.localVar.type);
		    printf("\n");
		    break;
		case OSYM_REGVAR:
		    printf("local register variable in %s\n", 
			    	    registers[sym->u.localVar.offset]);
		    break;
		case OSYM_ONSTACK:
		    printf(useDecimal ? "stack descriptor at %d: %i\n" :
			   "stack descriptor at %04x: %i\n",
			   sym->u.onStack.address,
			   OBJ_FETCH_SID(sym->u.onStack.desc));
		    break;
		case OSYM_BLOCKSTART:
		    if (debug) 
		    {
		    	printf(useDecimal ? "block locals at %d: " :
			       "block locals at %04x: ",
			       sym->u.blockStart.local);
		    }
		    printf(useDecimal ? "block start at %d\n" :
			   "block start at %04x\n",
			   sym->u.blockStart.address);
		    break;
		case OSYM_BLOCKEND:
		    printf(useDecimal ? "block end at %d\n" :
			   "block end at %04x\n",
			   sym->u.blockEnd.address);
		    break;
		case OSYM_EXTTYPE:
		    printf("external type (%s)\n",
			   (sym->u.extType.stype==OSYM_STRUCT ? "structure" :
			    (sym->u.extType.stype==OSYM_ETYPE?"etype":
			     (sym->u.extType.stype==OSYM_RECORD?"record":
			      (sym->u.extType.stype==OSYM_UNION?"union":"?")))));
		    break;
		case OSYM_CLASS:
		    printf(useDecimal ? "class at %d, super = %i\n" :
			   "class at %04x, super = %i\n",
			   sym->u.class.address,
			   OBJ_FETCH_SID(sym->u.class.super));
		    break;
		case OSYM_MASTER_CLASS:
		    printf(useDecimal ? "master class at %d, super = %i\n" :
			   "master class at %04x, super = %i\n",
			   sym->u.class.address,
			   OBJ_FETCH_SID(sym->u.class.super));
		    break;
		case OSYM_VARIANT_CLASS:
		    printf(useDecimal ? "variant class at %d, super = %i\n" :
			   "variant class at %04x, super = %i\n",
			   sym->u.class.address,
			   OBJ_FETCH_SID(sym->u.class.super));
		    break;
		case OSYM_BINDING:
		    printf("bound to %i (%s)\n",
			    OBJ_FETCH_SID(sym->u.binding.proc),
			   (sym->u.binding.callType==OSYM_DYNAMIC ? "dynamic" :
			    (sym->u.binding.callType==OSYM_DYNAMIC_CALLABLE?
			     "callable dynamic" :
			     (sym->u.binding.callType==OSYM_STATIC?"static":
			      (sym->u.binding.callType!=OSYM_PRIVSTATIC?"???":
			       "private static")))));
		    break;
		case OSYM_MODULE:
		    printf("module: table = %04x, offset = %d\n",
			   sym->u.module.table, sym->u.module.offset);
		    break;
		case OSYM_RETURN_TYPE:
		    printf("procedure return type = ");
		    PrintType(file, hdr->types, sym->u.localVar.type);
		    printf("\n");
		    break;
		case OSYM_LOCAL_STATIC:
		{
		    ObjSym  *vsym;
		    ObjSymHeader  *vsymHdr;
		    
		    vsymHdr =
			(ObjSymHeader *)VMLock(file,
					       sym->u.localStatic.symBlock,
					       (MemHandle *)NULL);
		    vsym = (ObjSym *)((genptr)vsymHdr +
				      sym->u.localStatic.symOff);
		    
		    printf(useDecimal ? "local static at %04x, type " :
			   "local static at %d, type ",
			   vsym->u.variable.address);
		    PrintType(file, vsymHdr->types, vsym->u.variable.type);
		    printf("\n");
		    VMUnlock(file, sym->u.localStatic.symBlock);
		    break;
		}
	        case OSYM_NEWMINOR:
		    printf("new minor protocol #%d\n", sym->u.newMinor.number);
		    break;
	        case OSYM_PROFILE_MARK:
		{
		    static const char *markTypes[] = {
			"0", "basic block", "routine count"
		    };
		    if (sym->u.profMark.markType < sizeof(markTypes)/sizeof(markTypes[0]))
		    {
			printf("%s profile mark at %04x\n",
			       markTypes[sym->u.profMark.markType],
			       sym->u.profMark.address);
		    } else {
			printf("%d-type profile mark at %04x\n",
			       sym->u.profMark.markType,
			       sym->u.profMark.address);
		    }
		    break;
		}
	        default:
		    printf("???\n");
		    break;
	    }
	}
	next = hdr->next;
	VMUnlock(file, block);
	block = next;
    }
}
		
void
DumpRel(VMHandle    	file,
	VMBlockHandle	block,
	ObjHeader   	*hdr)
{
    ObjRel  	    *rel;
    ObjRelHeader    *orh;
    VMBlockHandle   next;
    MemHandle	    mem;
    int	    	    n;

    while (block != NULL) {
	orh = (ObjRelHeader *)VMLock(file, block, &mem);

	for (rel = (ObjRel *)(orh+1), n = orh->num; n > 0; n--, rel++) {
	    static char	*sizes[] = {"byte", "word", "dword"};
	    static char	*types[] = {
		"low-offset", "high-offset", "offset",
		"segment", "handle", "resid", "call", "entry",
		"methhcall", "supercall", "protominor"
	    };
	    ID   	frame;
	    ObjSym  *sym;

	    printf(useDecimal ? "\t%s%s%s-sized %s relocation at %d:" :
		   "\t%s%s%s-sized %s relocation at %04x:",
		   rel->fixed ? "fixed, " : "",
		   rel->pcrel ? "pc-relative, " : "",
		   sizes[rel->size],
		   ((rel->symBlock == 0) ?
		    ((rel->type == OREL_LOW) ? "minor-of" : "major-of") :
		    types[rel->type]),
		   rel->offset);
	    if (rel->frame == 0) {
		/*
		 * Presumably this is a relocation in a .ldf file
		 */
		ID    id;

		id = (ID) (rel->symBlock << (sizeof(unsigned short) * 8)) +
		          (rel->symOff);

		printf("target = %i (published)\n", id);
		continue;
	    } else if (rel->frame > (sizeof(ObjHeader) +
				     hdr->numSeg * sizeof(ObjSegment)))
	    {
		frame = ((ObjGroup *)((genptr)hdr+rel->frame))->name;
	    } else {
		frame = ((ObjSegment *)((genptr)hdr+rel->frame))->name;
	    }

	    if (rel->symBlock == 0) {
		printf("no symbol");
	    } else {
		sym = (ObjSym *)((genptr)VMLock(file, rel->symBlock, NULL) +
				 rel->symOff);
		printf("target = %i", sym->name);
	    }
	    printf (", frame = %i\n", frame);
	}
	if (debug) {
	    printf("\nsymOff = %d\nsymBlock = %d\noffset = %d\nframe = %d\ntype = %d\n", rel->symOff, rel->symBlock, rel->offset, rel->frame, rel->type);
	}
	next = orh->next;
	VMUnlock(file, block);
	block = next;
    }
}
			   
void
DumpLines(VMHandle  	file,
	  VMBlockHandle	block)
{
    ObjLineHeader   *hdr;
    ObjLine 	    *line;
    int	    	    n;
    ObjAddrMapHeader *oamh;
    ObjAddrMapEntry *oame;
    int	    	    i;

    if (block != 0) {
	oamh = (ObjAddrMapHeader *)VMLock(file, block, (MemHandle *)NULL);
	oame = (ObjAddrMapEntry *)(oamh+1);
	i = oamh->numEntries;
	
	while (i > 0) {
	    hdr = (ObjLineHeader *)VMLock(file, oame->block, (MemHandle *)NULL);
	    
	    printf(useDecimal ? "last offset = %d\n" : "last offset = %04x\n",
		   oame->last);
	    n = hdr->num;
	    
	    line = (ObjLine *)(hdr+1);
	    printf("\tFile %i:\n", *(ID *)line);
	    line++, n--;
	    
	    while (n > 0) {
		if (line->line == 0) {
		    line++;
		    printf("\tFile %i:\n", *(ID *)line);
		    line++;
		    n -= 2;
		}
		printf(useDecimal ? "\t\tline %4d at %d\n" :
		       "\t\tline %4d at %04x\n",
		       line->line, line->offset);
		n--, line++;
	    }
	    VMUnlock(file, oame->block);
	    oame++, i--;
	}
	VMUnlock(file, block);
    }
}

void
DumpSourceMap(VMHandle	    file,
	      VMBlockHandle header,
	      ObjHeader	    *hdr)
{
    ObjHashHeader   *ohh;
    int	    	    chain;
    VMBlockHandle   cur;

    ohh = (ObjHashHeader *)VMLock(file, header, (MemHandle *)NULL);
    
    for (chain = 0; chain < obj_hash_chains; chain++) {
	cur = ohh->chains[chain];

	while (cur != 0) {
	    VMBlockHandle   next;
	    ObjHashBlock    *ohb;
	    ObjHashEntry    *ohe;
	    int	    	    n;

	    ohb = (ObjHashBlock *)VMLock(file, cur, (MemHandle *)NULL);

	    for (ohe = ohb->entries, n = ohb->nextEnt; n > 0; ohe++, n--) {
		ObjSrcMapHeader *osmh;
		ObjSrcMap   	*osm;
		int 	    	i;
		
		printf("\t%i: (^v%04x:%04x)\n", ohe->name, ohe->block,
		       ohe->offset);
		osmh = (ObjSrcMapHeader *)((genptr)VMLock(file,ohe->block,NULL)+
					   ohe->offset);
		osm = (ObjSrcMap *)((genptr)osmh + sizeof(*osmh));
		for (i = osmh->numEntries; i > 0; i--) {
		    if (osm->line != 0) {
			printf(useDecimal ? "\t\tline %4d is in %i, offset %d\n" :
			       "\t\tline %4d is in %i, offset %04x\n",
			       osm->line,
			       ((ObjSegment *)((genptr)hdr+osm->segment))->name,
			       osm->offset);
		    }
		    osm++;
		}
		VMUnlock(file, ohe->block);
	    }
	    next  = ohb->next;
	    VMUnlock(file, cur);
	    cur = next;
	}
    }
    VMUnlock(file, header);
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
		"usage: printobj [-d] [-D] <symfile>\n"
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

    printf("protocol: %d.%d; revision: %d.%d.%d.%d\n",
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
	    printf("no symbol");
	} else {
	    sym = (ObjSym *)((genptr)VMLock(output, hdr->entry.symBlock, NULL) +
			     hdr->entry.symOff);
	    printf("target = %i", sym->name);
	}
	printf (", frame = %i\n", frame);
    }
	
    for (i = hdr->numSeg, seg = (ObjSegment *)(hdr+1);
	 i > 0;
	 i--, seg++)
    {
	printf("%sSegment %d: name %i, class %i, type %s, alignment %#x, size %5d\n",
	       i == hdr->numSeg ? "" : "\n=================\n",
	       hdr->numSeg-i+1,
	       seg->name, seg->class, segtypes[seg->type], seg->align,
	       seg->size);
	if (seg->type == SEG_ABSOLUTE) {
	    printf("\tlocated at %04x:0\n", seg->data);
	} else {
	    printf("*** DATA:\n");
	    DumpBlock(output, seg->data);
	}
	printf("*** SYMBOLS:\n");
	DumpSyms(output, seg->syms, (genptr)seg-(genptr)hdr);
	printf("*** RELOCATIONS:\n");
	DumpRel(output, seg->relHead, hdr);
	printf("*** LINES:\n");
	DumpLines(output, seg->lines);
    }
    /*
     * Do groups
     */

    /*
     * Do source map, if there.
     */
    if (hdr->srcMap != 0) {
	printf("*** SOURCE FILE MAPPING:\n");
	DumpSourceMap(output, hdr->srcMap, hdr);
    }
    VMClose(output);
    exit(0);

}
