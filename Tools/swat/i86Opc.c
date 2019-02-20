/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- opcode table for Intel *86 processors.
 * FILE:	  i86Opcodes.c
 *
 * AUTHOR:  	  Adam de Boor: Jun 22, 1988
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	I86FindOpcode	    Find the opcode description for a machine-
 *			    language opcode.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/22/88	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Opcode table for disassembling instructions from the Intel 8086
 *	family of processors.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: i86Opc.c,v 4.10 96/06/13 17:16:52 dbaumann Exp $";
#endif lint

/*
 * The following tables describe the opcodes in the 8086 family.
 * The first table is used to quickly find opcodes that are a single byte.
 * If an opcode requires the REG field of the ModRM byte to determine its
 * function, the name field is NULL, but the args field points to another
 * table indexed by the reg field of the ModRM byte.
 *
 * The interface to this table is through the I86FindOpcode function, which
 * takes a 24-bit word and a place to store the actual ModRM byte and returns
 * a pointer to the I86Opcode structure describing that opcode. The contents
 * of the structure must not be altered.
 *
 * Instructions come in three categories:
 *	single-byte	Those instructions that require only the first byte
 *			to uniquely determine the mnemonic and operands. These
 *			are decoded using the Opcode table.
 *	double-byte	Many opcodes are overloaded and the REG field of the
 *			ModRM byte must be used to determine the operation.
 *			A linear search of the extOpcode table is used to find
 *			these.
 *	triple-byte	Some of the new 286 instructions are actually two-byte
 *			opcodes with the REG field of the ModRM byte that
 *			follows the opcode determining which operation to
 *			perform. These are stored as separate opcode
 *	    	    	descriptors, but the value and mask are 0.
 *
 * For each mnemonic/argument pair, we store:
 *	- the ascii representation of the mnemonic
 *	- a mask of bits that must match and what they must contain (used
 *	  only in the searching the extOpcodes table)
 *	- the length of the opcode (the number of bytes from the start of the
 *	  opcode to the first argument, skipping over the ModRM byte)
 *	- the type of program-flow change the instruction embodies (jump,
 *	  branch, return, sequential)
 *	- a string of pairs of characters that describe the arguments the
 *	  instruction takes.
 *	- a set of bitflags indicating what sorts of operand values should be
 *	  printed when decoded arguments are requested.
 *
 * The argument string contains two characters per argument. If a pair doesn't
 * match one of the following, it is a two-character string that should be
 * printed literally in the proper position. These codes are taken from
 * the instruction description in the processor handbooks published by Intel.
 * The first character of the description gives the argument type, while
 * the second gives its size, thus:
 *
 *	First character	    Argument type
 *	    a               absolute code address -- indicates a flow change
 *	    c	  	    relative code address -- indicates a flow change
 *	    d	  	    data -- an immediate value
 *	    e	  	    effective address -- contents of register or memory
 *	    m	  	    memory
 *	    r	  	    register
 *	    x	  	    simple memory (used for short Ax MOV's)
 *	    N		    next instruction. arg size ignored
 *	    o	    	    string instruction source operand only if override
 *
 *	Second character    Argument size
 *	    b	  	    byte
 *	    w	  	    word
 *	    d	  	    double word (implies must be in mem for <386)
 *	    v		    word or dword, depending on operand size attribute
 *	    f	    	    single-precision float
 *	    p               32-bit or 48-bit pointer, depending on operand size
 *	                    attribute
 *	    q	    	    double-precision float (quadword)
 *	    t	    	    ten-byte float
 *
 *
 * The control transfer codes are as follows:
 *	    CNEXT  	    Next instruction
 *	    CJMP  	    Absolute jump
 *	    CBRAN  	    PC-relative branch
 *	    CRET  	    Intra-segment return
 *	    CLRET 	    Intra-segment return
 *	    CIRET 	    Interrupt return
 *
 */

#include <config.h>
#include "swat.h"
#include "i86Opc.h"

#define None	  ((const char *)0)

/*
 * Default instruction. The mask of 0 makes it match anything.
 * The length of 0 makes the immediate byte be the opcode that's
 * bogus.
 */
#define DEFAULT \
    "DB",	  0x0000,   0x0000, 0,	CNEXT,	0,  "db",   0,	0

static const I86Opcode	ImmedByte[8] = {
    {"ADD",  	0x38ff, 0x0080,	2,	CNEXT,	IA_DEST,
		"ebdb",	1,	1},
    {"OR",	0x38ff, 0x0880, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,	1},
    {"ADC",  	0x38ff, 0x1080, 2,	CNEXT,	IA_DEST|IA_CF,
		"ebdb",	1,	1},
    {"SBB",	0x38ff, 0x1880, 2,	CNEXT,	IA_DEST|IA_CF,
		"ebdb",	1,	1},
    {"AND",  	0x38ff, 0x2080, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,	1},
    {"SUB",	0x38ff, 0x2880, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,	1},
    {"XOR",	0x38ff, 0x3080, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1},
    {"CMP",  	0x38ff, 0x3880, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	0}
};

static const I86Opcode	ImmedWord[8] = {
    {"ADD",  	0x38ff, 0x0081, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	2},
    {"OR",	0x38ff, 0x0881, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	2},
    {"ADC",  	0x38ff,	0x1081, 2,	CNEXT,	IA_DEST|IA_CF,
		"evdv",	2,  	2},
    {"SBB",	0x38ff, 0x1881, 2,	CNEXT,	IA_DEST|IA_CF,
		"evdv",	2,  	2},
    {"AND",  	0x38ff, 0x2081, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	2},
    {"SUB",	0x38ff, 0x2881, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	2},
    {"XOR",	0x38ff, 0x3081, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	2},
    {"CMP",  	0x38ff, 0x3881, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	0}
};
static const I86Opcode    ImmedWByte[8] = {
    {"ADD",  	0x38ff, 0x0083, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"OR",	0x38ff, 0x0883, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"ADC",  	0x38ff, 0x1083, 2,	CNEXT,	IA_DEST|IA_CF,
		"evdb",	2,  	2},
    {"SBB",	0x38ff, 0x1883, 2,	CNEXT,	IA_DEST|IA_CF,
		"evdb",	2,  	2},
    {"AND",  	0x38ff, 0x2083, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"SUB",	0x38ff, 0x2883, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"XOR",	0x38ff, 0x3083, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"CMP",  	0x38ff, 0x3883, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	0}
};

static const I86Opcode    ShiftByte1[8] = {
    {"ROL",	0x38ff, 0x00d0, 2,	CNEXT,	IA_DEST,
		"eb1 ",	1,  	1},
    {"ROR",	0x38ff, 0x08d0, 2,	CNEXT,	IA_DEST,
		"eb1 ",	1,  	1},
    {"RCL",	0x38ff, 0x10d0, 2,	CNEXT,	IA_DEST|IA_CF,
		"eb1 ",	1,  	1},
    {"RCR",	0x38ff, 0x18d0, 2,	CNEXT,	IA_DEST|IA_CF,
		"eb1 ",	1,  	1},
    {"SHL",	0x38ff, 0x20d0, 2,	CNEXT,	IA_DEST,
		"eb1 ",	1,  	1},
    {"SHR",	0x38ff, 0x28d0, 2,	CNEXT,	IA_DEST,
		"eb1 ",	1,  	1},
    {"SAL",	0x38ff, 0x30d0, 2,	CNEXT,	IA_DEST,
		"eb1 ",	1,  	1},
    {"SAR",	0x38ff, 0x38d0, 2,	CNEXT,	IA_DEST,
		"eb1 ",	1,  	1}
};
    
static const I86Opcode    ShiftWord1[8] = {
    {"ROL",	0x38ff, 0x00d1, 2,	CNEXT,	IA_DEST,
		"ev1 ",	2,  	2},
    {"ROR",	0x38ff, 0x08d1, 2,	CNEXT,	IA_DEST,
		"ev1 ",	2,  	2},
    {"RCL",	0x38ff, 0x10d1, 2,	CNEXT,	IA_DEST|IA_CF,
		"ev1 ",	2,  	2},
    {"RCR",	0x38ff, 0x18d1, 2,	CNEXT,	IA_DEST|IA_CF,
		"ev1 ",	2,  	2},
    {"SHL",	0x38ff, 0x20d1, 2,	CNEXT,	IA_DEST,
		"ev1 ",	2,  	2},
    {"SHR",	0x38ff, 0x28d1, 2,	CNEXT,	IA_DEST,
		"ev1 ",	2,  	2},
    {"SAL",	0x38ff, 0x30d1, 2,	CNEXT,	IA_DEST,
		"ev1 ",	2,  	2},
    {"SAR",	0x38ff, 0x38d1, 2,	CNEXT,	IA_DEST,
		"ev1 ",	2,  	2}
};

static const I86Opcode    ShiftByteCL[8] = {
    {"ROL",	0x38ff, 0x00d2, 2,	CNEXT,	IA_DEST|IA_CL,
		"ebCL",	1,  	1},
    {"ROR",	0x38ff, 0x08d2, 2,	CNEXT,	IA_DEST|IA_CL,
		"ebCL",	1,  	1},
    {"RCL",	0x38ff, 0x10d2, 2,	CNEXT,	IA_DEST|IA_CL|IA_CF,
		"ebCL",	1,  	1},
    {"RCR",	0x38ff, 0x18d2, 2,	CNEXT,	IA_DEST|IA_CL|IA_CF,
		"ebCL",	1,  	1},
    {"SHL",	0x38ff, 0x20d2, 2,	CNEXT,	IA_DEST|IA_CL,
		"ebCL",	1,  	1},
    {"SHR",	0x38ff, 0x28d2, 2,	CNEXT,	IA_DEST|IA_CL,
		"ebCL",	1,  	1},
    {"SAL",	0x38ff, 0x30d2, 2,	CNEXT,	IA_DEST|IA_CL,
		"ebCL",	1,  	1},
    {"SAR",	0x38ff, 0x38d2, 2,	CNEXT,	IA_DEST|IA_CL,
		"ebCL",	1,  	1}
};
    
static const I86Opcode    ShiftWordCL[8] = {
    {"ROL",	0x38ff, 0x00d3, 2,	CNEXT,	IA_DEST|IA_CL,
		"evCL",	2,  	2},
    {"ROR",	0x38ff, 0x08d3, 2,	CNEXT,	IA_DEST|IA_CL,
		"evCL",	2,  	2},
    {"RCL",	0x38ff, 0x10d3, 2,	CNEXT,	IA_DEST|IA_CL|IA_CF,
		"evCL",	2,  	2},
    {"RCR",	0x38ff, 0x18d3, 2,	CNEXT,	IA_DEST|IA_CL|IA_CF,
		"evCL",	2,  	2},
    {"SHL",	0x38ff, 0x20d3, 2,	CNEXT,	IA_DEST|IA_CL,
		"evCL",	2,  	2},
    {"SHR",	0x38ff, 0x28d3, 2,	CNEXT,	IA_DEST|IA_CL,
		"evCL",	2,  	2},
    {"SAL",	0x38ff, 0x30d3, 2,	CNEXT,	IA_DEST|IA_CL,
		"evCL",	2,  	2},
    {"SAR",	0x38ff, 0x38d3, 2,	CNEXT,	IA_DEST|IA_CL,
		"evCL",	2,  	2}
};

static const I86Opcode    ShiftIByte[8] = {
    {"ROL",	0x38ff, 0x00c0, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1},
    {"ROR",	0x38ff, 0x08c0, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1},
    {"RCL",	0x38ff, 0x10c0, 2,	CNEXT,	IA_DEST|IA_CF,
		"ebdb",	1,  	1},
    {"RCR",	0x38ff, 0x18c0, 2,	CNEXT,	IA_DEST|IA_CF,
		"ebdb",	1,  	1},
    {"SHL",	0x38ff, 0x20c0, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1},
    {"SHR",	0x38ff, 0x28c0, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1},
    {"SAL",	0x38ff, 0x30c0, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1},
    {"SAR",	0x38ff, 0x38c0, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	1}
};
    
static const I86Opcode    ShiftIWord[8] = {
    {"ROL",	0x38ff, 0x00c1, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"ROR",	0x38ff, 0x08c1, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"RCL",	0x38ff, 0x10c1, 2,	CNEXT,	IA_DEST|IA_CF,
		"evdb",	2,  	2},
    {"RCR",	0x38ff, 0x18c1, 2,	CNEXT,	IA_DEST|IA_CF,
		"evdb",	2,  	2},
    {"SHL",	0x38ff, 0x20c1, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"SHR",	0x38ff, 0x28c1, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"SAL",	0x38ff, 0x30c1, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2},
    {"SAR",	0x38ff, 0x38c1, 2,	CNEXT,	IA_DEST,
		"evdb",	2,  	2}
};

static const I86Opcode    Grp1Byte[8] = {
    {"TEST",	0x38ff, 0x00f6, 2,	CNEXT,	IA_DEST,
		"ebdb",	1,  	0},
    {DEFAULT},
    {"NOT",  	0x38ff, 0x10f6, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"NEG",	0x38ff, 0x18f6, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"MUL",	0x38ff, 0x20f6, 2,	CNEXT,	IA_DEST|IA_AL,
		"eb",	1,  	0},
    {"IMUL", 	0x38ff, 0x28f6, 2,	CNEXT,	IA_DEST|IA_AL,
		"eb",	1,  	0},
    {"DIV",  	0x38ff, 0x30f6, 2,	CNEXT,	IA_DEST|IA_AX,
		"eb",	1,  	0},
    {"IDIV", 	0x38ff, 0x38f6, 2,	CNEXT,	IA_DEST|IA_AX,
		"eb",	1,  	0}
};

static const I86Opcode    Grp1Word[8] = {
    {"TEST",	0x38ff, 0x00f7, 2,	CNEXT,	IA_DEST,
		"evdv",	2,  	0},
    {DEFAULT},
    {"NOT",  	0x38ff, 0x10f7, 2,	CNEXT,	IA_DEST,
		"ev",	2,  	2},
    {"NEG",	0x38ff, 0x18f7, 2,	CNEXT,	IA_DEST,
		"ev",	2,  	2},
    {"MUL",	0x38ff, 0x20f7, 2,	CNEXT,	IA_DEST|IA_AX,
		"ev",	2,  	0},
    {"IMUL", 	0x38ff, 0x28f7, 2,	CNEXT,	IA_DEST|IA_AX,
		"ev",	2,  	0},
    {"DIV",  	0x38ff, 0x30f7, 2,	CNEXT,	IA_DEST|IA_DXAX,
		"ev",	2,  	0},
    {"IDIV", 	0x38ff, 0x38f7, 2,	CNEXT,	IA_DEST|IA_DXAX,
		"ev",	2,  	0}
};

static const I86Opcode    Grp2Byte[8] = {
    {"INC",  	0x38ff, 0x00fe, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"DEC",  	0x38ff, 0x08fe, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {DEFAULT},
    {DEFAULT},
    {DEFAULT},
    {DEFAULT},
    {DEFAULT},
    {DEFAULT}
};

static const I86Opcode    Grp2Word[8] = {
    {"INC",  	0x38ff, 0x00ff, 2,	CNEXT,	IA_DEST,
		"ev",	2,  	2},
    {"DEC",  	0x38ff, 0x08ff, 2,	CNEXT,	IA_DEST,
		"ev",	2,  	2},
    {"CALL", 	0x38ff, 0x10ff, 2,	CJMP,	IA_DEST,
		"ev",	2,  	2},
    {"CALL", 	0x38ff, 0x18ff, 2,	CJMP,	IA_DEST,
		"ed",	4,  	4},
    {"JMP",  	0x38ff, 0x20ff, 2,	CJMP,	IA_DEST,
		"ev",	2,  	0},
    {"JMP",  	0x38ff, 0x28ff, 2,	CJMP,	IA_DEST,
		"ed",	4,  	0},
    {"PUSH",	0x38ff, 0x30ff, 2,	CNEXT,	IA_DEST,
		"mv",	2,  	2},
    {DEFAULT}
};
    
static const I86Opcode    MoveFromSeg[8] = {
    {"MOV",	0x38ff, 0x008c, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"ewES",	0,  	2},
    {"MOV",	0x38ff, 0x088c, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"ewCS",	0,  	2},
    {"MOV",	0x38ff, 0x108c, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"ewSS",	0,  	2},
    {"MOV",	0x38ff, 0x188c, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"ewDS",	0,  	2},
    {"MOV",	0x38ff, 0x208c, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"ewFS",	0,  	2},
    {"MOV",	0x38ff, 0x288c, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"ewGS",	0,  	2},
    {DEFAULT},
    {DEFAULT}
};
    
static const I86Opcode    MoveToSeg[8] = {
    {"MOV",	0x38ff, 0x008e, 2,	CNEXT,	IA_SRC,
		"ESew",	2,  	0},
    {DEFAULT},
    {"MOV",	0x38ff, 0x108e, 2,	CNEXT,	IA_SRC,
		"SSew",	2,  	0},
    {"MOV",  	0x38ff, 0x188e, 2,	CNEXT,	IA_SRC,
		"DSew",	2,  	0},
    {"MOV",  	0x38ff, 0x208e, 2,	CNEXT,	IA_SRC,
		"FSew",	2,  	0},
    {"MOV",  	0x38ff, 0x288e, 2,	CNEXT,	IA_SRC,
		"GSew",	2,  	0},
    {DEFAULT},
    {DEFAULT}
};

static const I86Opcode  Opcodes[256] = {
    {"ADD",  	0x00ff, 0x0000, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	1},
    {"ADD",  	0x00ff, 0x0001, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	2},
    {"ADD",  	0x00ff, 0x0002, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"ADD",  	0x00ff, 0x0003, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"ADD",  	0x00ff, 0x0004, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"ADD",  	0x00ff, 0x0005, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {"PUSH",	0x00ff, 0x0006, 1,	CNEXT,	IA_DEST,
		"ES",	0,  	2},
    {"POP",	0x00ff, 0x0007, 1,	CNEXT,	IA_TOS,
		"ES",	2,  	0},
    {"OR",	0x00ff, 0x0008, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	1},
    {"OR",	0x00ff, 0x0009, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	2},
    {"OR",	0x00ff, 0x000a, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"OR",	0x00ff, 0x000b, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"OR",	0x00ff, 0x000c, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"OR",	0x00ff, 0x000d, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {"PUSH",	0x00ff, 0x000e, 1,	CNEXT,	IA_DEST,
		"CS",	0,  	2},
    {None,	0x0000, 0x000f, 0,	0,	0,
	        None,	0,  	0},
    {"ADC",  	0x00ff, 0x0010, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"ebrb",	1,  	1},
    {"ADC",  	0x00ff, 0x0011, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"evrv",	2,  	2},
    {"ADC",  	0x00ff, 0x0012, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"rbeb",	1,  	0},
    {"ADC",  	0x00ff, 0x0013, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"rvev",	2,  	0},
    {"ADC",  	0x00ff, 0x0014, 1,	CNEXT,	IA_AL|IA_CF,
		"ALdb",	0,  	0},
    {"ADC",  	0x00ff, 0x0015, 1,	CNEXT,	IA_AX|IA_CF,
		"AXdv",	0,  	0},
    {"PUSH",	0x00ff, 0x0016, 1,	CNEXT,	IA_DEST,
		"SS",	0,  	2},
    {"POP",	0x00ff, 0x0017, 1,	CNEXT,	IA_TOS,
		"SS",	2,  	0},
    {"SBB",	0x00ff, 0x0018, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"ebrb",	1,  	1},
    {"SBB",	0x00ff, 0x0019, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"evrv",	2,  	2},
    {"SBB",	0x00ff, 0x001a, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"rbeb",	1,  	0},
    {"SBB",	0x00ff, 0x001b, 2,	CNEXT,	IA_DEST|IA_SRC|IA_CF,
		"rvev",	2,  	0},
    {"SBB",	0x00ff, 0x001c, 1,	CNEXT,	IA_AL|IA_CF,
		"ALdb",	0,  	0},
    {"SBB",	0x00ff, 0x001d, 1,	CNEXT,	IA_AX|IA_CF,
		"AXdv",	0,  	0},
    {"PUSH",	0x00ff, 0x001e, 1,	CNEXT,	IA_DEST,
		"DS",	0,  	2},
    {"POP",  	0x00ff, 0x001f, 1,	CNEXT,	IA_TOS,
		"DS",	2,  	0},
    {"AND",  	0x00ff, 0x0020, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	1},
    {"AND",  	0x00ff, 0x0021, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	2},
    {"AND",  	0x00ff, 0x0022, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"AND",  	0x00ff, 0x0023, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"AND",  	0x00ff, 0x0024, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"AND",  	0x00ff, 0x0025, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {None,	0x0000, 0x0026, 0,	0,	0,
		None,	0,  	0},
    {"DAA",  	0x00ff, 0x0027, 1,	CNEXT,	IA_AL,
		"", 	0,  	0},
    {"SUB",  	0x00ff, 0x0028, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	1},
    {"SUB",	0x00ff, 0x0029, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	2},
    {"SUB",	0x00ff, 0x002a, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"SUB",	0x00ff, 0x002b, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"SUB",	0x00ff, 0x002c, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"SUB",	0x00ff, 0x002d, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {None,	0x0000, 0x002e, 0,	0,	0,
		None,	0,  	0},
    {"DAS",  	0x00ff, 0x002f, 1,	CNEXT,	IA_AL,
		"", 	0,  	0},
    {"XOR",	0x00ff, 0x0030, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	1},
    {"XOR",	0x00ff, 0x0031, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	2},
    {"XOR",	0x00ff, 0x0032, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"XOR",	0x00ff, 0x0033, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"XOR",	0x00ff, 0x0034, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"XOR",	0x00ff, 0x0035, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {None,	0x0000, 0x0036, 0,	0,	0,
		None,	0,  	0},
    {"AAA",  	0x00ff, 0x0037, 1,	CNEXT,	IA_AL,
		"", 	0,  	0},
    {"CMP",  	0x00ff, 0x0038, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	0},
    {"CMP",  	0x00ff, 0x0039, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	0},
    {"CMP",  	0x00ff, 0x003a, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"CMP",  	0x00ff, 0x003b, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"CMP",  	0x00ff, 0x003c, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"CMP",  	0x00ff, 0x003d, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {None,	0x0000, 0x003e, 0,	0,	0,
		None,	0,  	0},
    {"AAS",  	0x00ff, 0x003f, 1,	CNEXT,	IA_AL,
		"", 	0,  	0},
    {"INC",  	0x00ff, 0x0040, 1,	CNEXT,	IA_DEST,
		"AX",	0,  	0},
    {"INC",  	0x00ff, 0x0041, 1,	CNEXT,	IA_DEST,
		"CX",	0,  	0},
    {"INC",  	0x00ff, 0x0042, 1,	CNEXT,	IA_DEST,
		"DX",	0,  	0},
    {"INC",  	0x00ff, 0x0043, 1,	CNEXT,	IA_DEST,
		"BX",	0,  	0},
    {"INC",  	0x00ff, 0x0044, 1,	CNEXT,	IA_DEST,
		"SP",	0,  	0},
    {"INC",  	0x00ff, 0x0045, 1,	CNEXT,	IA_DEST,
		"BP",	0,  	0},
    {"INC",  	0x00ff, 0x0046, 1,	CNEXT,	IA_DEST,
		"SI",	0,  	0},
    {"INC",  	0x00ff, 0x0047, 1,	CNEXT,	IA_DEST,
		"DI",	0,  	0},
    {"DEC",  	0x00ff, 0x0048, 1,	CNEXT,	IA_DEST,
		"AX",	0,  	0},
    {"DEC",  	0x00ff, 0x0049, 1,	CNEXT,	IA_DEST,
		"CX",	0,  	0},
    {"DEC",  	0x00ff, 0x004a, 1,	CNEXT,	IA_DEST,
		"DX",	0,  	0},
    {"DEC",  	0x00ff, 0x004b, 1,	CNEXT,	IA_DEST,
		"BX",	0,  	0},
    {"DEC",  	0x00ff, 0x004c, 1,	CNEXT,	IA_DEST,
		"SP",	0,  	0},
    {"DEC",  	0x00ff, 0x004d, 1,	CNEXT,	IA_DEST,
		"BP",	0,  	0},
    {"DEC",  	0x00ff, 0x004e, 1,	CNEXT,	IA_DEST,
		"SI",	0,  	0},
    {"DEC",  	0x00ff, 0x004f, 1,	CNEXT,	IA_DEST,
		"DI",	0,  	0},
    {"PUSH",	0x00ff, 0x0050, 1,	CNEXT, 	IA_DEST,
		"AX",	0,  	2},
    {"PUSH",	0x00ff, 0x0051, 1,	CNEXT,	IA_DEST,
		"CX",	0,  	2},
    {"PUSH",	0x00ff, 0x0052, 1,	CNEXT,	IA_DEST,
		"DX",	0,  	2},
    {"PUSH",	0x00ff, 0x0053, 1,	CNEXT,	IA_DEST,
		"BX",	0,  	2},
    {"PUSH",	0x00ff, 0x0054, 1,	CNEXT,	IA_DEST,
		"SP",	0,  	2},
    {"PUSH",	0x00ff, 0x0055, 1,	CNEXT,	IA_DEST,
		"BP",	0,  	2},
    {"PUSH",	0x00ff, 0x0056, 1,	CNEXT,	IA_DEST,
		"SI",	0,  	2},
    {"PUSH",	0x00ff, 0x0057, 1,	CNEXT,	IA_DEST,
		"DI",	0,  	2},
    {"POP",	0x00ff, 0x0058, 1,	CNEXT, 	IA_TOS,
		"AX",	2,  	0},
    {"POP",	0x00ff, 0x0059, 1,	CNEXT,	IA_TOS,
		"CX",	2,  	0},
    {"POP",	0x00ff, 0x005a, 1,	CNEXT,	IA_TOS,
		"DX",	2,  	0},
    {"POP",	0x00ff, 0x005b, 1,	CNEXT,	IA_TOS,
		"BX",	2,  	0},
    {"POP",	0x00ff, 0x005c, 1,	CNEXT,	IA_TOS,
		"SP",	2,  	0},
    {"POP",	0x00ff, 0x005d, 1,	CNEXT,	IA_TOS,
		"BP",	2,  	0},
    {"POP",	0x00ff, 0x005e, 1,	CNEXT,	IA_TOS,
		"SI",	2,  	0},
    {"POP",	0x00ff, 0x005f, 1,	CNEXT,	IA_TOS,
		"DI",	2,  	0},
    {"PUSHA",	0x00ff, 0x0060, 1,	CNEXT,	IA_PUSHA,
		"", 	0,  	16},
    {"POPA",	0x00ff, 0x0061, 1,	CNEXT,	IA_TOSPOPA,
		"", 	16, 	0},
    {"BOUND",	0x00ff, 0x0062, 2,	CNEXT,	IA_DEST|IA_BOUND,
		"rvmd",	4,  	0},
    {"ARPL", 	0x00ff, 0x0063, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ewrw",	1,  	1},/* XXX: whole selector or just low byte? */
    {None,	0x0000, 0x0064, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x0065, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x0066, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x0067, 0,	0,	0,
		None,	0,  	0},
    {"PUSH",	0x00ff, 0x0068, 1,	CNEXT,	0,
		"dv",	0,  	2},
    {"IMUL", 	0x00ff, 0x0069, 2,	CNEXT,	IA_SRC,
		"rvevdv",   2,	0},
    {"PUSH",	0x00ff, 0x006a, 1,	CNEXT,	0,
		"db",	0,  	1},
    {"IMUL", 	0x00ff, 0x006b, 2,	CNEXT,	IA_SRC,
		"rvevdb",   2,	0},
    {"INSB", 	0x00ff, 0x006c, 1,	CNEXT,	IA_ESDI|IA_DX|IA_DF,
		"", 	-1,  	0},
    {"INSW", 	0x00ff, 0x006d, 1,	CNEXT,	IA_ESDI|IA_DX|IA_DF,
		"", 	-2,  	0},
    {"OUTSB",	0x00ff, 0x006e, 1,	CNEXT,	IA_SIPTR|IA_DX|IA_DF,
		"", 	0,  	-1},
    {"OUTSW",	0x00ff, 0x006f, 1,	CNEXT,	IA_SIPTR|IA_DX|IA_DF,
		"", 	0,  	-2},
    {"JO",   	0x00ff, 0x0070, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JNO",  	0x00ff, 0x0071, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JC",   	0x00ff, 0x0072, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JNC",  	0x00ff, 0x0073, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JZ",   	0x00ff, 0x0074, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JNZ",  	0x00ff, 0x0075, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JBE",   	0x00ff, 0x0076, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JA",   	0x00ff, 0x0077, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JS",   	0x00ff, 0x0078, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JNS",  	0x00ff, 0x0079, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JP",   	0x00ff, 0x007a, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JNP",  	0x00ff, 0x007b, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JL",   	0x00ff, 0x007c, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JGE",  	0x00ff, 0x007d, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JLE",  	0x00ff, 0x007e, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {"JG",   	0x00ff, 0x007f, 1,	CBRAN,	IA_BRANCH,
		"cb",	0,  	0},
    {None,	0x0000, 0x0080, 0,	0,	0,
		(char *)ImmedByte,  0,	    0},
    {None,	0x0000, 0x0081, 0,	0,	0,
		(char *)ImmedWord,  0,	    0},
    {None,	0x0000, 0x0082, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x0083, 0,	0,	0,
		(char *)ImmedWByte, 0,	    0},
    {"TEST",	0x00ff, 0x0084, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rbeb",	1,  	0},
    {"TEST",	0x00ff, 0x0085, 2,	CNEXT,	IA_DEST|IA_SRC,
		"rvev",	2,  	0},
    {"XCHG",	0x00ff, 0x0086, 2,	CNEXT,	IA_DEST|IA_SRC,
		"ebrb",	1,  	1},
    {"XCHG",	0x00ff, 0x0087, 2,	CNEXT,	IA_DEST|IA_SRC,
		"evrv",	2,  	2},
    {"MOV",  	0x00ff, 0x0088, 2,  	CNEXT,	IA_DESTADR|IA_SRC,
		"ebrb",	0,  	1},
    {"MOV",  	0x00ff, 0x0089, 2,	CNEXT,	IA_DESTADR|IA_SRC,
		"evrv",	0,  	2},
    {"MOV",	0x00ff, 0x008a, 2,	CNEXT,	IA_SRC,
		"rbeb",	1,  	0},
    {"MOV",	0x00ff, 0x008b, 2,	CNEXT,	IA_SRC,
		"rvev",	2,  	0},
    {None,	0x0000, 0x008c, 0,	0,	0,
		(char *)MoveFromSeg,	0,  0},
    {"LEA",  	0x00ff, 0x008d, 2,	CNEXT,	IA_SRCADR,
		"rvmb",	0,  	0},
    {None,	0x0000, 0x008e, 0,	0,	0,
		(char *)MoveToSeg,  0,	    0},
    {"POP",  	0x38ff, 0x008f, 2,	CNEXT,	IA_TOS|IA_DESTADR,
		"mv",	2,  	2},
    {"NOP",  	0x00ff, 0x0090, 1,	CNEXT,	0,
		"", 	0,  	0},
    {"XCHG",	0x00ff, 0x0091, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXCX",	0,  	0},
    {"XCHG",	0x00ff, 0x0092, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXDX",	0,  	0},
    {"XCHG",	0x00ff, 0x0093, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXBX",	0,  	0},
    {"XCHG",	0x00ff, 0x0094, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXSP",	0,  	0},
    {"XCHG",	0x00ff, 0x0095, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXBP",	0,  	0},
    {"XCHG",	0x00ff, 0x0096, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXSI",	0,  	0},
    {"XCHG",	0x00ff, 0x0097, 1,	CNEXT,	IA_DEST|IA_SRC,
		"AXDI",	0,  	0},
    {"CBW",  	0x00ff, 0x0098, 1,	CNEXT,	IA_AL,
		"", 	0,	0},
    {"CWD",  	0x00ff, 0x0099, 1,	CNEXT,	IA_AX,
		"", 	0,	0},
    {"CALL", 	0x00ff, 0x009a, 1,	CJMP,	0,
		"ap",	0,  	4},
    {"WAIT",	0x00ff, 0x009b, 1,	CNEXT,	0,
		"", 	0,  	0},
    {"PUSHF",	0x00ff, 0x009c, 1,	CNEXT,	IA_PUSHF,
		"", 	0,  	2},
    {"POPF",	0x00ff, 0x009d, 1,	CNEXT,	IA_TOSF,
		"", 	2,  	0},
    {"SAHF",	0x00ff, 0x009e, 1,	CNEXT,	IA_SAHF,
		"", 	0,  	0},
    {"LAHF", 	0x00ff, 0x009f, 1,	CNEXT,	IA_LAHF,
		"", 	0,  	0},
    {"MOV",	0x00ff, 0x00a0, 1,	CNEXT,	IA_SRC,
		"ALxb",	1,  	0},
    {"MOV",	0x00ff, 0x00a1, 1,	CNEXT,	IA_SRC,
		"AXxv",	2,  	0},
    {"MOV",	0x00ff, 0x00a2, 1,	CNEXT,	IA_DESTADR|IA_AL,
		"xbAL",	0,  	1},
    {"MOV",	0x00ff, 0x00a3, 1,	CNEXT,	IA_DESTADR|IA_AX,
		"xvAX",	0,  	2},
    {"MOVSB",	0x00ff, 0x00a4, 1,	CNEXT,	IA_ESDI|IA_SIPTR|IA_DF,
		"ob",	1,  	1},
    {"MOVSW",	0x00ff, 0x00a5, 1,	CNEXT,	IA_ESDI|IA_SIPTR|IA_DF,
		"ov",	2,  	2},
    {"CMPSB",	0x00ff, 0x00a6, 1,	CNEXT,	IA_DIPTR|IA_SIPTR|IA_DF,
		"ob",	2,  	0},
    {"CMPSW",	0x00ff, 0x00a7, 1,	CNEXT,	IA_DIPTR|IA_SIPTR|IA_DF,
		"ov",	4,  	0},
    {"TEST",	0x00ff, 0x00a8, 1,	CNEXT,	IA_AL,
		"ALdb",	0,  	0},
    {"TEST",	0x00ff, 0x00a9, 1,	CNEXT,	IA_AX,
		"AXdv",	0,  	0},
    {"STOSB",	0x00ff, 0x00aa, 1,	CNEXT,	IA_ESDI|IA_AL|IA_DF,
		"", 	0,  	1},
    {"STOSW",	0x00ff, 0x00ab, 1,	CNEXT,	IA_ESDI|IA_AX|IA_DF,
		"", 	0,  	2},
    {"LODSB",	0x00ff, 0x00ac, 1,	CNEXT,	IA_SIPTR|IA_DF,
		"ob",	1,  	0},
    {"LODSW",	0x00ff, 0x00ad, 1,	CNEXT,	IA_SIPTR|IA_DF,
		"ov",	2,  	0},
    {"SCASB", 	0x00ff, 0x00ae, 1,	CNEXT,	IA_DIPTR|IA_AL|IA_DF,
		"", 	1,  	0},
    {"SCASW",	0x00ff, 0x00af, 1,	CNEXT,	IA_DIPTR|IA_AX|IA_DF,
		"", 	2,  	0},
    {"MOV",	0x00ff, 0x00b0, 1,	CNEXT,	0,
		"ALdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b1, 1,	CNEXT,	0,
		"CLdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b2, 1,	CNEXT,	0,
		"DLdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b3, 1,	CNEXT,	0,
		"BLdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b4, 1,	CNEXT,	0,
		"AHdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b5, 1,	CNEXT,	0,
		"CHdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b6, 1,	CNEXT,	0,
		"DHdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b7, 1,	CNEXT,	0,
		"BHdb",	0,  	0},
    {"MOV",	0x00ff, 0x00b8, 1,	CNEXT, 	0,
		"AXdv",	0,  	0},
    {"MOV",	0x00ff, 0x00b9, 1,	CNEXT,	0,
		"CXdv",	0,  	0},
    {"MOV",	0x00ff, 0x00ba, 1,	CNEXT,	0,
		"DXdv",	0,  	0},
    {"MOV",	0x00ff, 0x00bb, 1,	CNEXT,	0,
		"BXdv",	0,  	0},
    {"MOV",	0x00ff, 0x00bc, 1,	CNEXT,	0,
		"SPdv",	0,  	0},
    {"MOV",	0x00ff, 0x00bd, 1,	CNEXT,	0,
		"BPdv",	0,  	0},
    {"MOV",	0x00ff, 0x00be, 1,	CNEXT,	0,
		"SIdv",	0,  	0},
    {"MOV",	0x00ff, 0x00bf, 1,	CNEXT,	0,
		"DIdv",	0,  	0},
    {None,	0x0000, 0x00c0, 0,	0,	0,
		(char *)ShiftIByte, 0,	0},
    {None,	0x0000, 0x00c1, 0,	0,	0,
		(char *)ShiftIWord, 0,	0},
    {"RETN",	0x00ff, 0x00c2, 1,	CRET,	IA_TOSRETN,
		"dw",	2,  	0},
    {"RETN",	0x00ff, 0x00c3, 1,	CRET,	IA_TOSRETN,
		"", 	2,  	0},
    {"LES",  	0x00ff, 0x00c4, 2,	CNEXT,	IA_SRC,
		"rved",	4,  	0},
    {"LDS",  	0x00ff, 0x00c5, 2,	CNEXT,	IA_SRC,
		"rved",	4,  	0},
    {"MOV",	0x38ff, 0x00c6, 2,	CNEXT,	IA_DESTADR,
		"ebdb",	0,  	1},
    {"MOV",	0x38ff, 0x00c7, 2,	CNEXT,	IA_DESTADR,
		"evdv",	0,  	2},
    {"ENTER",	0x00ff, 0x00c8, 1,	CNEXT,	0,
		"dwdb",	0,  	2},
    {"LEAVE",	0x00ff, 0x00c9, 1,	CNEXT,	0,
		"", 	2,  	0},
    {"RETF",  	0x00ff, 0x00ca, 1,	CLRET,	IA_TOSRETF,
		"dw",	4,  	0},
    {"RETF",  	0x00ff, 0x00cb, 1,	CLRET,	IA_TOSRETF,
		"", 	4,  	0},
    {"INT",  	0x00ff, 0x00cc, 1,	CINT,	0,
		"3 ",	4,  	6},
    {"INT",  	0x00ff, 0x00cd, 1,	CINT,	0,
		"db",	4,  	6},
    {"INTO", 	0x00ff, 0x00ce, 1,	CINT,	IA_BRANCH,
		"", 	4,  	6},
    {"IRET", 	0x00ff, 0x00cf, 1,	CIRET,	IA_TOSIRET,
		"", 	6,  	0},
    {None,	0x0000, 0x00d0, 0,	0,	0,
		(char *)ShiftByte1, 0,	0},
    {None,	0x0000, 0x00d1, 0,	0,	0,
		(char *)ShiftWord1, 0,	0},
    {None,	0x0000, 0x00d2, 0,	0,	0,
		(char *)ShiftByteCL,0,	0},
    {None,	0x0000, 0x00d3, 0,	0,	0,
		(char *)ShiftWordCL,0,	0},
    {"AAM",	0xffff, 0x0ad4, 2,	CNEXT,	IA_AL,
		"", 	0,  	0},
    {"AAM",	0xffff, 0x0ad5, 2,	CNEXT,	IA_AL,
		"", 	0,  	0},
    {None,	0x0000, 0x00d6, 0,	0,	0,
		None,	0,  	0},
    {"XLATB",	0x00ff, 0x00d7, 1,	CNEXT,	IA_AL|IA_BX,
		"ob", 	1,  	0},
    {None,	0x0000, 0x00d8, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00d9, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00da, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00db, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00dc, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00dd, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00de, 0,	0,	0,
		None,	0,  	0},
    {None,	0x0000, 0x00df, 0,	0,	0,
		None,	0,  	0},
    {"LOOPNE",	0x00ff, 0x00e0, 1,	CBRAN,	IA_ZF|IA_CX|IA_BRANCH,
		"cb",	0,  	0},
    {"LOOPE",	0x00ff, 0x00e1, 1,	CBRAN,	IA_ZF|IA_CX|IA_BRANCH,
		"cb",	0,  	0},
    {"LOOP", 	0x00ff, 0x00e2, 1,	CBRAN,	IA_CX|IA_BRANCH,
		"cb",	0,  	0},
    {"JCXZ", 	0x00ff, 0x00e3, 1,	CBRAN,	IA_CX|IA_BRANCH,
		"cb",	0,  	0},
    {"IN",   	0x00ff, 0x00e4, 1,	CNEXT,	0,
		"ALdb",	-1, 	0},
    {"IN",   	0x00ff, 0x00e5, 1,	CNEXT,	0,
		"AXdb",	-2, 	0},
    {"OUT",	0x00ff, 0x00e6, 1,	CNEXT,	IA_AL,
		"dbAL",	0,  	-1},
    {"OUT",  	0x00ff, 0x00e7, 1,	CNEXT,	IA_AX,
		"dbAX",	0,  	-2},
    {"CALL", 	0x00ff, 0x00e8, 1,	CBRAN,	0,
		"av",	0,  	2},
    {"JMP",  	0x00ff, 0x00e9, 1,	CBRAN,	0,
		"cv",	0,  	0},
    {"JMP",  	0x00ff, 0x00ea, 1,	CJMP,	0,
		"ap",	0,  	0},
    {"JMP",  	0x00ff, 0x00eb, 1,	CBRAN,	0,
		"cb",	0,  	0},
    {"IN",   	0x00ff, 0x00ec, 1,	CNEXT,	IA_DX,
		"ALDX",	-1, 	0},
    {"IN",   	0x00ff, 0x00ed, 1,	CNEXT,	IA_DX,
		"AXDX",	-2, 	0},
    {"OUT",	0x00ff, 0x00ee, 1,	CNEXT,	IA_DX|IA_AL,
		"DXAL",	0,  	-1},
    {"OUT",	0x00ff, 0x00ef, 1,	CNEXT,	IA_DX|IA_AX,
		"DXAX",	0,  	-2},
    {"LOCK", 	0x00ff, 0x00f0, 1,	CNEXT,	0,
		"N ",	0,  	0},
    {None,	0x0000, 0x00f1, 0,	0,	0,
		None,	0,  	0},
    {"REPNE",	0x00ff, 0x00f2, 1,	CNEXT,	IA_CX,
		"N ",	0,  	0},
    {None,   	0x0000, 0x00f3, 1,	CNEXT,	0,
		None,	0,  	0},
    {"HLT",  	0x00ff, 0x00f4, 1,	CNEXT,	0,
		"", 	0,  	0},
    {"CMC",  	0x00ff, 0x00f5, 1,	CNEXT,	IA_CF,
		"", 	0,  	0},
    {None,	0x0000, 0x00f6, 0,	0,	0,
		(char *)Grp1Byte,   0,	0},
    {None,	0x0000, 0x00f7, 0,	0,	0,
		(char *)Grp1Word,   0,	0},
    {"CLC",  	0x00ff, 0x00f8, 1,	CNEXT,	IA_CF,
		"", 	0,  	0},
    {"STC",	0x00ff, 0x00f9, 1,	CNEXT,	IA_CF,
		"", 	0,  	0},
    {"CLI",  	0x00ff, 0x00fa, 1,	CNEXT,	0,
		"", 	0,  	0},
    {"STI",	0x00ff, 0x00fb, 1,	CNEXT,	0,
		"", 	0,  	0},
    {"CLD",  	0x00ff, 0x00fc, 1,	CNEXT,	IA_DF,
		"", 	0,  	0},
    {"STD",	0x00ff, 0x00fd, 1,	CNEXT,	IA_DF,
		"", 	0,  	0},
    {None,	0x0000, 0x00fe, 0,	0,	0,
		(char *)Grp2Byte,   0,	    0},
    {None,   	0x0000, 0x00ff, 0,	0,	0,
		(char *)Grp2Word,   0,	    0}
};

/*
 * Static opcode structurea for extended opcodes -- those that can't be
 * decoded using two bytes. Certain extended opcodes are the only ones in
 * their class -- they are given explicitly. The ones that use /n are
 * in the i86* arrays.
 */
#define OP0f01(name,R,W) name, 0, 0, 3, CNEXT, 0, "ew",	R,  W
static const I86Opcode  i86Op0f01[8] = {
    {OP0f01("SGDT",0,8)},
    {OP0f01("SIDT",0,8)},
    {OP0f01("LGDT",8,0)},
    {OP0f01("LIDT",8,0)},
    {OP0f01("SMSW",0,2)},
    {DEFAULT},
    {OP0f01("LMSW",2,0)},
    {DEFAULT}
};

#define OP0f00(name,R,W) name, 0, 0, 3, CNEXT, 0, "ew",	R,  W
static const I86Opcode  i86Op0f00[8] = {

    {OP0f00("SLDT",0,2)},
    {OP0f00("STR",0,2)},
    {DEFAULT},
    {DEFAULT},
    {OP0f00("VERR",3,0)},	/* 2 for selector, 1 for access rights? */
    {OP0f00("VERW",3,0)},	/* 2 for selector, 1 for access rights? */
    {DEFAULT},
    {DEFAULT}
};

static const I86Opcode opLAR = { "LAR", 0, 0, 3, CNEXT, IA_SRC, "rvew", 3, 0 },
		       opLSL = { "LSL", 0, 0, 3, CNEXT, IA_SRC, "rvew", 4, 0 },
		       opCLTS= { "CLTS",0, 0, 2, CNEXT, 0, "", 0, 0 },
		       opDB  = { "DB",  0, 0, 0, CNEXT, 0, "db", 0, 0 },
		       opREPE= { "REPE",0xf6ff, 0xa6f3, 1, CNEXT, IA_CX, "N ", 0, 0},
		       opREP = { "REP", 0xf6ff, 0xa6f3, 1, CNEXT, IA_CX, "N ", 0, 0};

/*
 * Opcode structures for 80386 extended opcodes (first byte is 0fh).
 * This table defines those opcodes starting at 080h.
 */
static const I86Opcode i86Op0f[] = {
    {"JO",	0xff00, 0x8000, 2,	CBRAN,	IA_BRANCH,
     		"cv", 	0,	0},
    {"JNO",  	0xff00, 0x8100, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JC",   	0xff00, 0x8200, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JNC",  	0xff00, 0x8300, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JZ",   	0xff00, 0x8400, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JNZ",  	0xff00, 0x8500, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JBE",   	0xff00, 0x8600, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JA",   	0xff00, 0x8700, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JS",   	0xff00, 0x8800, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JNS",  	0xff00, 0x8900, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JP",   	0xff00, 0x8a00, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JNP",  	0xff00, 0x8b00, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JL",   	0xff00, 0x8c00, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JGE",  	0xff00, 0x8d00, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JLE",  	0xff00, 0x8e00, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"JG",   	0xff00, 0x8f00, 2,	CBRAN,	IA_BRANCH,
		"cv",	0,  	0},
    {"SETO",	0xff00, 0x9000,	2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNO",	0xff00, 0x9100, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETB",	0xff00, 0x9200, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNB",	0xff00, 0x9300, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETZ",	0xff00, 0x9400, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNZ",	0xff00, 0x9500, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETBE",	0xff00, 0x9600, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNBE",	0xff00, 0x9700, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETS",	0xff00, 0x9800, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNS",	0xff00, 0x9900, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETP",	0xff00, 0x9a00, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNP",	0xff00, 0x9b00, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETL",	0xff00, 0x9c00, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNL",	0xff00, 0x9d00, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETLE",	0xff00, 0x9e00, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"SETNLE",	0xff00, 0x9f00, 2,	CNEXT,	IA_DEST,
		"eb",	1,  	1},
    {"PUSH",	0xff00, 0xa000, 2,	CNEXT,	IA_DEST,
		"FS",	0,  	2},
    {"POP",	0xff00, 0xa100, 2,	CNEXT,	IA_TOS,
		"FS",	2,  	0},
    {None,	0xff00, 0xa200, 0,	0,	0,
		None,	0,  	0},
    {"BT",	0xff00, 0xa300, 2,	CNEXT,	IA_DEST,
		"evrv",	2,  	2},
    {"SHLD",	0xff00, 0xa400, 3,	CNEXT,	IA_DEST,
		"evrvdb",2,  	2},
    {"SHLD",	0xff00, 0xa500, 3,	CNEXT,	IA_DEST,
		"evrvCL",2,  	2},
    {None,	0xff00, 0xa600, 0,	0,	0,
		None,	0,  	0},
    {None,	0xff00, 0xa700, 0,	0,	0,
		None,	0,  	0},
    {"PUSH",	0xff00, 0xa800, 2,	CNEXT,	IA_DEST,
		"GS",	0,  	2},
    {"POP",	0xff00, 0xa900, 2,	CNEXT,	IA_TOS,
		"GS",	2,  	0},
    {None,	0xff00, 0xaa00, 0,	0,	0,
		None,	0,  	0},
    {"BTS",	0xff00, 0xab00, 2,	CNEXT,	IA_DEST,
		"evrv",	2,  	2},
    {"SHRD",	0xff00, 0xac00, 3,	CNEXT,	IA_DEST,
		"evrvdb",2,  	2},
    {"SHRD",	0xff00, 0xad00, 3,	CNEXT,	IA_DEST,
		"evrvCL",2,  	2},
    {None,	0xff00, 0xae00, 0,	0,	0,
		None,	0,  	0},
    {"IMUL",	0xff00, 0xaf00, 2,	CNEXT,	IA_DEST|IA_AX,
		"rvev",	2,  	0},
    {None,	0xff00, 0xb000, 0,	0,	0,
		None,	0,  	0},
    {None,	0xff00, 0xb100, 0,	0,	0,
		None,	0,  	0},
    {"LSS",  	0xff00, 0xb200, 3,	CNEXT,	IA_SRC,
		"rved",	4,  	0},
    {"BTR",	0xff00, 0xb300, 2,	CNEXT,	IA_DEST,
		"evrv",	2,  	2},
    {"LFS",  	0xff00, 0xb400, 3,	CNEXT,	IA_SRC,
		"rved",	4,  	0},
    {"LGS",  	0xff00, 0xb500, 3,	CNEXT,	IA_SRC,
		"rved",	4,  	0},
    {"MOVZX",	0xff00, 0xb600, 3,  	CNEXT,	IA_DESTADR|IA_SRC,
		"rveb",	0,  	2},
    {"MOVZX",	0xff00, 0xb700, 3,  	CNEXT,	IA_DESTADR|IA_SRC,
		"rvew",	0,  	2},
    {None,	0xff00, 0xb800, 0,	0,	0,
		None,	0,  	0},
    {None,	0xff00, 0xb900, 0,	0,	0,
		None,	0,  	0},
    {None,	0xff00, 0xba00, 0,	0,	0,
		None,	0,  	0},
    {"BTC",	0xff00, 0xbb00, 2,	CNEXT,	IA_DEST,
		"evrv",	2,  	2},
    {"BSF",	0xff00, 0xbc00, 2,	CNEXT,	IA_DEST,
		"evrv",	2,  	2},
    {"BSR",	0xff00, 0xbd00, 2,	CNEXT,	IA_DEST,
		"evrv",	2,  	2},
    {"MOVSX",	0xff00, 0xbe00, 3,  	CNEXT,	IA_DESTADR|IA_SRC,
		"rveb",	0,  	2},
    {"MOVSX",	0xff00, 0xbf00, 3,  	CNEXT,	IA_DESTADR|IA_SRC,
		"rvew",	0,  	2},
};

/*
 * Array of opcodes that have different mneumonics when used with
 * a 32-bit operand than a 16-bit operand.
 */
static const	I86ExtName Opcodes86_32[] = {
    {&Opcodes[0x60], "PUSHAD"},	/* PUSHA */
    {&Opcodes[0x61], "POPAD"},	/* POPA */
    {&Opcodes[0x6d], "INSD"},	/* INSW */
    {&Opcodes[0x6f], "OUTSD"},	/* OUTSD */
    {&Opcodes[0x98], "CWDE"},	/* CBW */
    {&Opcodes[0x99], "CDQ"},	/* CWD */
    {&Opcodes[0x9d], "POPFD"},	/* POPF */
    {&Opcodes[0x9c], "PUSHFD"},	/* PUSHF */
    {&Opcodes[0xa5], "MOVSD"},	/* MOVSW */
    {&Opcodes[0xa7], "CMPSD"},	/* CMPSW */
    {&Opcodes[0xab], "STOSD"},	/* STOSW */
    {&Opcodes[0xad], "LODSD"},	/* LODSW */
    {&Opcodes[0xaf], "SCASD"},	/* SCASW */
    {&Opcodes[0xcf], "IRETD"}	/* IRET */
};

static const	I86Opcode Opcodes87_D8[8] = {
    {"FADD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FMUL", 	0x3800, 0x0800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FCOM", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FCOMP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FSUBR", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FSUB", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FDIV", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FDIVR", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRC, "ef", 0, 0}
};

static const	I86Opcode Opcodes87_D9E[8] = {
    {"FLD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, 	    "",   0, 0},
    {"FST", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FSTP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FLDENV", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRCADDR, "eb", 0, 0},
    {"FLDCW", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FSTENV", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRCADDR, "eb", 0, 0},
    {"FSTCW", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "ew", 0, 0}
};

static const	I86Opcode Opcodes87_D9C[4] = {
    {"FLD", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FXCH", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FNOP", 	0x3800, 0x3000, 2, CNEXT, 0,	    "",   0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0,	    "",   0, 0}
};

static const	I86Opcode Opcodes87_DA[8] = {
    {"FIADD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FIMUL", 	0x3800, 0x0800, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FICOM", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FICOMP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FISUB", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FISUBR", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FIDIV", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FIDIVR", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "ed", 0, 0}
};

static const	I86Opcode Opcodes87_DB[8] = {
    {"FILD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0,        "",   0, 0},
    {"FIST", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {"FISTP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "ed", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0,        "",   0, 0},
    {"FLD", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "et", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0,        "",   0, 0},
    {"FSTP", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "et", 0, 0}
};

static const	I86Opcode Opcodes87_DC[8] = {
    {"FADD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FMUL", 	0x3800, 0x0800, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FCOM", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FCOMP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FSUBR", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FSUB", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FDIVR", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRC, "eq", 0, 0},
    {"FDIV", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "eq", 0, 0}
};

static const	I86Opcode Opcodes87_DD[8] = {
    {"FLD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, 	"eq", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, 	       	"",   0, 0},
    {"FST", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, 	"eq", 0, 0},
    {"FSTP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, 	"eq", 0, 0},
    {"FRSTOR", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRCADDR,	"eb", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, 	    	"",   0, 0},
    {"FSAVE", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRCADDR, "eb", 0, 0},
    {"FSTSW", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRCADDR, "ew", 0, 0}
};

static const	I86Opcode Opcodes87_DDC[4] = {
    {"FFREE", 	0x3800, 0x0000, 2, CNEXT, 0, 	    	"et", 0, 0},
    {"FXCH", 	0x3800, 0x0800, 2, CNEXT, IA_FPSRC, 	"et", 0, 0},
    {"FST", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, 	"et", 0, 0},
    {"FSTP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, 	"et", 0, 0}
};

static const	I86Opcode Opcodes87_DEMem[8] = {
    {"FIADD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FIMUL", 	0x3800, 0x0800, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FICOM", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FICOMP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FISUB", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FISUBR", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FIDIV", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRC, "ew", 0, 0},
    {"FIDIVR", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "ew", 0, 0}
};

static const	I86Opcode Opcodes87_DEReg[8] = {
    {"FADDP", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FMULP", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FCOMP", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FCOMPP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FSUBRP", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"FSUBP", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"DIVRP", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRC, "ef", 0, 0},
    {"DIVP", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRC, "ef", 0, 0}
};

static const	I86Opcode Opcodes87_DF[8] = {
    {"FILD", 	0x3800, 0x0000, 2, CNEXT, IA_FPSRC,     "ew", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0,            "",   0, 0},
    {"FIST", 	0x3800, 0x1000, 2, CNEXT, IA_FPSRCADDR, "ew", 0, 0},
    {"FISTP", 	0x3800, 0x1800, 2, CNEXT, IA_FPSRCADDR, "ew", 0, 0},
    {"FBLD", 	0x3800, 0x2000, 2, CNEXT, IA_FPSRC,     "ef", 0, 0},
    {"FILD", 	0x3800, 0x2800, 2, CNEXT, IA_FPSRC,     "ed", 0, 0},
    {"FBSTP", 	0x3800, 0x3000, 2, CNEXT, IA_FPSRCADDR, "et", 0, 0},
    {"FISTP", 	0x3800, 0x3800, 2, CNEXT, IA_FPSRCADDR, "ed", 0, 0}
};


static const	I86Opcode   Opcodes87_FSTSWAX[1] = {
    {"FSTSWAX", 	0x3800, 0x3800, 2, CNEXT, 0, "", 0, 0}
};

static const	I86Opcode   Opcodes87_DEFAULT[1] = {
    {DEFAULT}
};

static const I86Opcode  Opcodes87_BigD9[32] = {
    {"FCHS", 	0xffff, 0xd9e0, 2, CNEXT, 0, "", 0, 0},
    {"FABS", 	0xffff,	0xd9e1, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FTST", 	0xffff, 0xd9e4, 2, CNEXT, 0, "", 0, 0},
    {"FXAM", 	0xffff, 0xd9e5, 2, CNEXT, 0, "", 0, 0},
    {"FTSTP", 	0xffff, 0xd9e6, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FLD1", 	0xffff, 0xd9e8, 2, CNEXT, 0, "", 0, 0},
    {"FLDL2T", 	0xffff, 0xd9e9, 2, CNEXT, 0, "", 0, 0},
    {"FLDL2E", 	0xffff, 0xd9ea, 2, CNEXT, 0, "", 0, 0},
    {"FLDPI", 	0xffff, 0xd9eb, 2, CNEXT, 0, "", 0, 0},
    {"FLDLG2", 	0xffff, 0xd9ec, 2, CNEXT, 0, "", 0, 0},
    {"FLDLN2", 	0xffff, 0xd9ed, 2, CNEXT, 0, "", 0, 0},
    {"FLDZ", 	0xffff, 0xd9ee, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"F2XM1", 	0xffff,	0xd9f0, 2, CNEXT, 0, "", 0, 0},
    {"FYL2X", 	0xffff, 0xd9f1, 2, CNEXT, 0, "", 0, 0},
    {"FPTAN", 	0xffff, 0xd9f2, 2, CNEXT, 0, "", 0, 0},
    {"FPATAN", 	0xffff, 0xd9f3, 2, CNEXT, 0, "", 0, 0},
    {"FXTRACT", 0xffff, 0xd9f4, 2, CNEXT, 0, "", 0, 0},
    {"FPREM1", 	0xffff, 0xd9f5, 2, CNEXT, 0, "", 0, 0},
    {"FDESTP", 	0xffff, 0xd9f6, 2, CNEXT, 0, "", 0, 0},
    {"FINCSTP", 0xffff, 0xd9f7, 2, CNEXT, 0, "", 0, 0},
    {"FPREM", 	0xffff, 0xd9f8, 2, CNEXT, 0, "", 0, 0},
    {"FYL2XP1", 0xffff, 0xd9f9, 2, CNEXT, 0, "", 0, 0},
    {"FSQRT",   0xffff, 0xd9fa, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FRNDINT", 0xffff, 0xd9fc, 2, CNEXT, 0, "", 0, 0},
    {"FSCALE", 	0xffff, 0xd9fd, 2, CNEXT, 0, "", 0, 0},
    {"FSIN", 	0xffff, 0xd9fe, 2, CNEXT, 0, "", 0, 0},
    {"FCOS", 	0xffff,	0xd9ff, 2, CNEXT, 0, "", 0, 0}
};



static const I86Opcode  Opcodes87_RegDB[32] = {
    {"FENI", 	0xffff, 0xdbe0, 2, CNEXT, 0, "", 0, 0},
    {"FDISI", 	0xffff, 0xdbe1, 2, CNEXT, 0, "", 0, 0},
    {"FCLEX", 	0xffff, 0xdbe2, 2, CNEXT, 0, "", 0, 0},
    {"FINIT", 	0xffff, 0xdbe3, 2, CNEXT, 0, "", 0, 0},
    {"FSETPM", 	0xffff, 0xdbe4, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FSBP0", 	0xffff, 0xdbe8, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FABP2",   0xffff, 0xdbea, 2, CNEXT, 0, "", 0, 0},
    {"FSBP1", 	0xffff, 0xdbeb, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FRSTPM", 	0xffff, 0xdbf6, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {"FSINCOS", 0xffff, 0xdbfb, 2, CNEXT, 0, "", 0, 0},
    {"FRINT2", 	0xffff, 0xdbfc, 2, CNEXT, 0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
    {None,   	0x0000, 0x000f, 0, 0, 	  0, "", 0, 0},
};



/***********************************************************************
 *				I87FindOpcode
 ***********************************************************************
 * SYNOPSIS:	  Locate the description of the given coprocessor opcode.
 * CALLED BY:	  EXTERNAL
 * RETURN:	  Pointer to an I86Opcode structure for the opcode.
 * SIDE EFFECTS:  The name field of privOp may be overwritten.
 *
 * STRATEGY:	    
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/29/88		Initial Revision
 *	ardeb	10/10/88    	Adapted to table linkage.
 *
 ***********************************************************************/
const I86Opcode *
I87FindOpcode(unsigned long inst,	/* Three bytes of instruction */
	      unsigned char *modrmPtr)	/* Place to store ModRM byte */
{
    register const I86Opcode	*op = 0;
    int	index;

    /*
     * if the opcode start with a db or d9 we can just look it up in
     * a table
     */

    /*
     * if the first two bits of the second bit are on, then we are
     * using a stack register, rather than memory 
     */

    index = (inst & 0x3800) >> 11;
    *modrmPtr = (inst & 0xff00) >> 8;

    switch (inst & 0xdf)
    {
	case	0xd8:
	    op = &Opcodes87_D8[index];
	    break;
	case	0xd9:
	    switch (inst & 0xe000)
	    {
		case 0xc000:
		    index = (inst & 0x1800) >> 11;
		    op = &Opcodes87_D9C[index];
		    break;
		case 0xe000:
		    index = (inst & 0x1f00) >> 8;
		    op = &Opcodes87_BigD9[index];
		    break;
		default:
		    op = &Opcodes87_D9E[index];
		    break;
	    }
	    break;
	case	0xda:
	    if ((inst & 0xc000) == 0xc000)
	    {
		op = &Opcodes87_DEFAULT[0];
	    }
	    else
	    {
		op = &Opcodes87_DA[index];
	    }
	    break;
	case	0xdb:
	    if ((inst & 0xc000) != 0xc000)
	    {
		op = &Opcodes87_DB[index];
	    }
	    else
	    {
		index = (inst & 0x1f00) >> 8;
		op = &Opcodes87_RegDB[index];
	    }
	    break;
	case	0xdc:
	    op = &Opcodes87_DC[index];
	    break;
	case	0xdd:
	    switch (inst & 0xe000)
	    {
		case 0xe000:
		    op = &Opcodes87_DEFAULT[0];
		    break;
		case 0xc000:
		    index = (0x1800 & inst) >> 11;
		    op = &Opcodes87_DDC[index];
		    break;
		default:
		    op = &Opcodes87_DD[index];
		    break;
	    }
	    break;
	case	0xde:
	    switch (inst & 0xc000)
	    {
		case 0xc000:
		    op = &Opcodes87_DEReg[index];
		    break;
		default:
		    op = &Opcodes87_DEMem[index];
		    break;
	    }
	    break;
	case 	0xdf:
	    switch (inst & 0xf000)
	    {
		case 0xc000:
		case 0xd000:
		case 0xf000:
		    op = &Opcodes87_DEFAULT[0];
		    break;
		case 0xe000:
		    op = &Opcodes87_FSTSWAX[0];
		    break;
		default:
		    op = &Opcodes87_DF[index];
		    break;
	    }
	    break;
    }
    return (op);
}

/***********************************************************************
 *				I86FindOpcode
 ***********************************************************************
 * SYNOPSIS:	  Locate the description of the given opcode.
 * CALLED BY:	  EXTERNAL
 * RETURN:	  Pointer to an I86Opcode structure for the opcode.
 * SIDE EFFECTS:  The name field of privOp may be overwritten.
 *
 * STRATEGY:
 *	See if the opcode is a privileged, three-byte 286 instruction.
 *	If so, figure out the name, put it in privOp, set *modrmPtr
 *	properly and return.
 *
 *	If not, use byte 0 to index into Opcodes and see if we can use
 *	that. A name of None means we have to perform a more
 *	extensive search. If the args field is non-null, it points to
 *	another table of I86Opcode structures that is indexed by the
 *	REG field of the ModRM byte (the second byte).
 *
 *	If the args field is null, we perform a linear search of extOpcodes.
 *	This will always yield an I86Opcode because of the default instruction
 *	at the end
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	ardeb	6/29/88		Initial Revision
 *	ardeb	10/10/88    	Adapted to table linkage.
 *	dhunter	8/4/2000	Added support for 32-bit opcode name
 *
 ***********************************************************************/
const I86Opcode *
I86FindOpcode(unsigned long inst,	/* Three bytes of instruction */
	      unsigned char *modrmPtr,	/* Place to store ModRM byte */
	      const char **name32)	/* Place to store ptr to 32-bit name */
{
    register const I86Opcode	*op;
    int i;

    /*
     * if the first byte starts with a 0xd8 then it must be
     * a coprocessor instruction, so do the coprocessor thing 
     */

    if ((inst & 0xf8) == 0xd8) {
	return(I87FindOpcode(inst, modrmPtr));
    }

    if ((inst & 0xff) == 0x0f) {
	/*
	 * '286 extended instructions. Actual instruction determined by
	 * second byte.
	 */
	unsigned char extinst = (unsigned char)((inst & 0xff00) >> 8);
	switch(extinst) {
	case 0:
	    op = &i86Op0f00[(inst >> 19) & 7];
	    break;
	case 1:
	    op = &i86Op0f01[(inst >> 19) & 7];
	    break;
	case 2:
	    /* LAR */
	    op = &opLAR;
	    break;
	case 3:
	    /* LSL */
	    op = &opLSL;
	    break;
	case 6:
	    /* CLTS */
	    op = &opCLTS;
	    break;
	default:
	    if (extinst >= 0x80 && extinst < 0xc0)
		op = &i86Op0f[extinst - 0x80];
	    else {
		/*
		 * Use the default opcode
		 */
		op = &opDB;
	    }
	    break;
	}
    } else if ((inst & 0xff) == 0xf3) {
	/*
	 * Instruction begins with a REP prefix. This is actually REPE if the
	 * repeated instruction is a SCAS or a CMPS.
	 */
	unsigned char	nextOp;

	/*
	 * Find the first byte of the next instruction. This must skip over
	 * segment overrides and LOCK prefixes.
	 */
	switch((inst >> 8) & 0xff) {
#if REGS_32
        case 0x64:  /* FS: */
        case 0x65:  /* GS: */
        case 0x66:  /* Operand size toggle 16/32 */
        case 0x67:  /* Address size toggle 16/32 */
#endif
	case 0x26:  /* ES: */
	case 0x2e:  /* CS: */
	case 0x36:  /* SS: */
	case 0x3e:  /* DS: */
	case 0xf0:  /* LOCK */
	    /*
	     * Next byte is a prefix -- use the following byte to figure which
	     * mnemonic to use.
	     */
	    nextOp = (inst >> 16);
	    break;
	default:
	    nextOp = (inst >> 8);
	    break;
	}

	/*
	 * CMPS is 0xa6 or 0xa7 (byte or word) and SCAS is 0xae or 0xaf. Thus
	 * if we and the opcode with 0xf6 and the result is 0xa6, it is one of
	 * these two instructions (think about it :).
	 */
	if ((nextOp & 0xf6) == 0xa6) {
	    op = &opREPE;
	} else {
	    op = &opREP;
	}
    } else {
	op = &Opcodes[inst & 0xff];
    }
    if (op->name == None) {
	if (op->args == None) {
	    /*
	     * Use the default opcode
	     */
	    op = &opDB;
	} else {
	    /*
	     * Use the REG field of the ModRM byte to index into the indicated
	     * table to come up with the proper opcode.
	     */
	    op = &((const I86Opcode *)op->args)[(inst >> 11) & 0x7];
	}
    }
    if (op->length != 0) {
	/*
	 * If the opcode is non-zero length (i.e. it isn't DB), the ModRM
	 * byte is the length'th byte in inst, 1-origin.
	 */
	*modrmPtr = inst >> ((op->length - 1) * 8);
    }
    /*
     * Search Opcodes86_32 to see if this opcode has a 32-bit name.
     * If so, store a pointer to the name in name32, otherwise NULL.
     */
    *name32 = 0;
#if REGS_32
    for (i = 0; i < sizeof(Opcodes86_32) / sizeof(I86ExtName); i++)
	if (op == Opcodes86_32[i].opcode) {
	    *name32 = Opcodes86_32[i].name;
	    break;
	}
#endif

    return(op);
}

