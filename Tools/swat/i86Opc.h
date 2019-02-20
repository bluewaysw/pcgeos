/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Intel 86 family opcodes
 * FILE:	  i86Opcodes.h
 *
 * AUTHOR:  	  Adam de Boor: Jun 22, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/22/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for users of the Intel *86 opcode table.
 *
 *
* 	$Id: i86Opc.h,v 4.3 92/07/03 20:09:01 adam Exp $
 *
 ***********************************************************************/

#ifndef _I86OPCODES_H_
#define _I86OPCODES_H_

#define MAXINST	  	15  	/* Maximum number of bytes needed to decode
				 * an instruction (the 386 generates an
				 * illegal instruction exception if one
				 * is longer than this) */

typedef struct {
    const char 	  	*name;      /* Mnemonic */
    const unsigned short mask;	    /* Mask of bits that must match */
    const unsigned short value;	    /* Value they must match */
    const unsigned char	length;	    /* Length of the opcode (1, 2 or 3) */
    const char		branch;	    /* Control flow type */
    const unsigned long	flags;	    /* Argument flags (for printing) */
    const char		*args;	    /* Argument descriptions */
    const char	    	bread;	    /* Bytes read by instruction */
    const char	    	bwrite;	    /* Bytes written by instruction */
} I86Opcode;

typedef struct {
    const I86Opcode	*opcode;	/* Pointer to opcode struct */
    const char		*name;		/* 32-bit opcode name */
} I86ExtName;

extern const I86Opcode  *I86FindOpcode(unsigned long inst,
				       unsigned char *modrmPtr,
				       const char **name32);

/*
 * Branch codes
 */
#define	CNEXT	  '1'	/* No branch */
#define CJMP	  'j'	/* Absolute jump */
#define CBRAN	  'b'	/* PC-relative jump */
#define CRET	  'r'	/* Near return */
#define CLRET	  'R'	/* Far return */
#define CIRET	  'i'	/* Interrupt return */
#define CINT	  'I'	/* Interrupt instruction */

/*
 * Argument flags. The flags indicate which args are to be printed when the
 * instruction is decoded. Certain instructions print out implicit args
 * where useful. The args should be printed from bit 0 to bit 31. i.e.
 * since IA_DEST is b0 and IA_SRC is b2, the dest value should be printed
 * before the source.
 */
#define IA_DEST	    0x00000001	/* Dest value (+ addr if ea) */
#define IA_DESTADR  0x00000002	/* Dest addr (not value) */
#define IA_FPSRCADDR IA_DESTADR
#define IA_SRC	    0x00000004	/* Source value (+ addr if ea) */
#define IA_SRCADR   0x00000008	/* Address of source (LEA) */
#define IA_AL	    0x00000010	/* AL (BCD & XLAT & strings) */
#define IA_AX	    0x00000020	/* AX (CWD, OUT) */
#define IA_DF	    0x00000040	/* DF (strings) */
#define IA_ESDI     0x00000080	/* ES:DI symbolicly */
#define IA_DIPTR    0x00000100	/* DI's value and what it points at */
#define IA_SIPTR    0x00000200	/* SI's value and what it points at */
#define IA_CF	    0x00000400	/* CF (RCR, RCL, CMC) */
#define IA_CL	    0x00000800	/* CL (variable shifts) */
#define IA_CX	    0x00001000	/* CX (LOOPs, REPs, JCXZ) */
#define IA_BX	    0x00002000	/* BX (XLAT) */
#define IA_DXAX	    0x00004000	/* DX:AX as int (DIV et al) */
#define IA_TOSF	    0x00008000	/* TOS as flags word (POPF) */
#define IA_TOSRETN  0x00010000	/* TOS for near return */
#define IA_TOSRETF  0x00020000	/* TOS for far return */
#define IA_TOSIRET  0x00040000	/* TOS for IRET */
#define IA_TOS	    0x00080000	/* TOS (POP) */
#define IA_TOSPOPA  0x00100000	/* TOS (POPA) */
#define IA_ZF	    0x00200000	/* ZF (LOOPcc) */
#define IA_BRANCH   0x00400000	/* If instruction will branch (Jcc, LOOPcc) */
#define IA_SAHF	    0x00800000	/* AH as flags (SAHF) */
#define IA_LAHF     0x01000000	/* Low-order flags (LAHF) */
#define IA_PUSHF    0x02000000	/* All flags (PUSHF) */
#define IA_PUSHA    0x04000000	/* All registers (PUSHA) */
#define IA_BOUND    0x08000000	/* Index bounds (BOUND) */
#define IA_DX	    0x10000000	/* DX (INS, OUTS) */
#define IA_FLOATREG 0x20000000  /* float register from the coprocessor */
#define IA_FLOATNUM 0x40000000	/* floating point number */
#define IA_FPSRC    0x80000000 	/* Source operand for FP instruction (stored
				 * in DEST_INDEX part of value array) */

#endif /* _I86OPCODES_H_ */
