/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Glue -- Output definitions
 * FILE:	  output.h
 *
 * AUTHOR:  	  Adam de Boor: Oct 16, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	10/16/89  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for output portion of the linker.
 *
 *
 * 	$Id: output.h,v 2.9 92/12/10 22:05:32 adam Exp $
 *
 ***********************************************************************/
#ifndef _OUTPUT_H_
#define _OUTPUT_H_

#include    <objfmt.h>

/*
 * Typedefs for the various procedure vectors. Aids in forward-declaration
 * of static procedures in the individual file-output modules.
 */
/*
 * Prepare the data structures for the second pass. Returns the final
 * size of the output file.
 */
typedef int	PrepareProc(char    *outfile,	/* Output file, in case
						 * it must be opened during
						 * preparation */
			    char    *paramfile,	/* File containing link
						 * parameters */
			    char    *mapfile);	/* File in which to place
						 * address map. NULL if not
						 * necessary */
/*
 * Enter a runtime relocation. Returns non-zero if relocation actually
 * entered. It is not an error for a relocation to be ignored.
 */
typedef int 	RelMapProc(int      type,	/* Relocation type (from obj
						 * file) */
			   SegDesc  *frame,	/* Descriptor of relocation
						 * frame */
			   void     *rbuf,	/* Place to store runtime
						 * relocation */
			   SegDesc  *targ,	/* Target segment */
			   int      off,	/* Offset w/in segment of
						 * relocation */
			   word     *val);	/* Word being relocated. Store
						 * value needed at runtime in
						 * PC byte-order */
/*
 * Write the buffer out to the output file. Any header information should
 * be written at this point, too.
 */
typedef void	WriteProc(void	    *base, 	/* Base of output image.
						 * All data written at proper
						 * offsets. Header and zero
						 * padding not present. */
			  int	    len,    	/* Length returned by
						 * PrepareProc */
			  char	    *outfile); 	/* Name of output file */

/*
 * Make sure the target of a relocation is actually in fixed memory.
 */
typedef int	IsFixedProc(SegDesc *targ);

/*
 * Set the entry point for the executable.
 */
typedef void	SetEntryProc(SegDesc 	*seg,	/* Segment in which the entry
						 * point lies */
			     word   	off);	/* Offset in same of same */

typedef struct {
    char    	opt;	    /* Option character */
    enum {
	OPT_NOARG,  	    /* Takes no arg. Sets *(int *)argVal to 1 if
			     * option seen */
	OPT_INTARG, 	    /* Takes an arg that is decoded into an int
			     * and stored through argVal */
	OPT_STRARG, 	    /* Takes an arg that is left as a string and
			     * whose address is stored through argVal */
    }	    	type;
    void    	*argVal;    /* Pointer to value */
    void    	*argName;   /* Non-terminal to give as name of argument, if
			     * argument required. */
} FileOption;


typedef struct {
    /*
     * Prepare output file. Arg is name of parameter file (if any). Returns
     * size of final output file.
     */
    PrepareProc	    *prepare;
    /*
     * Function to call to map an object relocation to a runtime relocation.
     */
    int	    	    rtrelsize; 	    /* Size (bytes) of a run-time
				     * relocation. rbuf will always
				     * point to a buffer at least this big
				     */
    RelMapProc	    *maprel;
    /*
     * All other operations done. Now write executable header to the output
     * file.
     */
    WriteProc       *write;
    /*
     * Make sure the target of a relocation lies in fixed memory.
     */
    IsFixedProc	    *checkFixed;
    /*
     * Set the entry point for the executable.
     */
    SetEntryProc    *setEntry;
    /*
     * Various flags
     */
    int	    	    flags;
#define FILE_NOCALL 	    	1   	/* CALL relocations not handled at
					 * runtime */
#define FILE_NEEDPARAM	    	2   	/* Need extra parameter file */
#define FILE_NOENTRYPTS	    	4   	/* Don't allow ENTRY relocations */
#define FILE_BIGGROUPS	    	8   	/* Allow groups larger than 64K */
#define FILE_USES_GEODE_PARAMS 	16  	/* Format uses a geode parameters file,
					 * so its libraries should be loaded
					 * by Parse_GeodeParams before pass 1 */
#define FILE_AUTO_LINK_LIBS 	32  	/* If any library segment has undefined
					 * symbols, call Library_Link for it
					 * automatically */
#define FILE_PROTO_RELS	    	64  	/* Format supports libraries and
					 * therefore protominor/protomajor
					 * relocations to them */
    /*
     * Default suffix to place on output file.
     */
    char    	    *suffix;
    /*
     * Any extra command-line options Glue supports in this mode.
     */
    FileOption	    *options;
} FileOps;

extern FileOps    	*fileOps;

/*
 * File operation records for the different types of output files.
 */
extern FileOps	    	exeOps,
			comOps,
			geoOps,
			vmOps,
			kernelOps,
			fontOps,
			rawOps;

    
extern void 	    	Out_Init(long size);
extern void 	    	Out_Block(long position, void *data, int len);
extern int  	    	Out_Fetch(long position, void *data, int len);
extern void 	    	Out_Final(char *outfile);
extern void 	    	Out_DosMap(char *mapfile, long imgBase);
extern void 	    	Out_ExtraReloc(SegDesc *sd, word reloc);
extern void 	    	Out_AddLines(char *file, VMHandle fh,
				     SegDesc *sd, VMBlockHandle lineMap,
				     word reloc,
				     Boolean doSrcMap);
extern void 	    	Out_FinishLineBlock(SegDesc *sd, VMBlockHandle block);
extern int	    	Out_FindConstSym(char *name, int *valPtr);
extern void		Out_PromoteGroups(void);
extern void 	    	Out_RegisterFinalProtoRel(Boolean isMajor,
						  long position,
						  SegDesc *library);
#endif /* _OUTPUT_H_ */
