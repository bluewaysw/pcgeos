/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  codeview32.h
 * FILE:	  codeview32.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 17, 1991
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/17/91	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for CodeView-format symbol and type information
 *	encoded in a microsoft/intel-format object file.
 *
 *	Types are stored in a segment named $$TYPES, while symbols are
 *	stored in one named $$SYMBOLS. HighC likes to generate two
 *	definitions for each segment, but one has zero size, so we can
 *	ignore it.
 *
 *	A symbol or type record can be broken across two or more LEDATA
 *	records, so we have to merge all the data records into a single
 *	block in codeview.c, just so you know :)
 *
 *
 *
 * 	$Id: codeview.h,v 1.3 91/04/26 12:37:45 adam Exp $
 *
 ***********************************************************************/
#ifndef _CODEVIEW32_H_
#define _CODEVIEW32_H_

#define CV_SYM_SEG_NAME	    "$$SYMBOLS"
#define CV_TYPE_SEG_NAME    "$$TYPES"

/******************************************************************************
 *
 *		     CODEVIEW SYMBOL INFORMATION
 *
 * All symbol records have a length byte and a type byte, then a variable
 * amount of data.
 ******************************************************************************/

/*
 * Start of a lexical block (scope). Followed by:
 *	- starting offset (word)
 *	- block length (word)
 *	- block name (optional, counted ascii)
 * ignore this if it's same offset & length as the procedure.
 * need to make up a symbol name for nameless blocks.
 */
#define CST_BLOCK_START	    0x00

/*
 * Start of a procedure. Followed by:
 *	- offset (word) of the procedure. An offset fixup to the containing
 * 	  segment is generated for the thing. Ignore the frame, use the target.
 *	  Also need to use the target displacement as well, to get the proper
 *	  offset for the beast.
 *	- type index (word)
 *	- procedure length (word)
 *	- end of prologue (word) as offset into procedure
 *	- start of epilogue (word) as offset into procedure
 *	- reserved (word)
 *	- CS_NEAR/CS_FAR (byte)
 *	- name (counted ascii)
 */
#define CST_PROC_START	    0x01
#define CS_NEAR	    	    	0x00
#define CS_FAR	    	    	0x04

/*
 * End of nearest CST_PROC_START, CST_WITH_START, or CST_BLOCK_START.
 * Followed by: nothing
 */
#define CST_END	    	    0x02

/*
 * Local variable/procedure argument:
 *	- signed offset off BP (word)
 *	- type index (word)
 *	- name (counted ascii)
 */
#define CST_LOCAL_VAR	    0x04

/*
 * Static variable (as opposed to automatic):
 *	- fptr to variable
 *	- type index (word)
 *	- name (counted ascii)
 */
#define CST_VARIABLE 	    0x05

/*
 * Code label:
 *	- offset (word) (fixup, too, I assume)
 *	- CS_NEAR/CS_FAR (byte)
 *	- name (counted ascii)
 */
#define CST_CODE_LABEL	    0x0b

/*
 * Start of a lexical block for the pascal "with" statement:
 *	- offset (word) [fixed up, perhaps]
 *	- length (word)
 *	- name of pointer being used (counted ascii)
 */
#define CST_WITH_START	    0x0c

/*
 * Register variable. Followed by:
 *	- type index (word)
 *	- register number (byte)
 *	-name (counted ascii)
 */
#define CST_REG_VAR  	    0x0d
#define CSR_BYTE_REG_START  	0
#define CSR_WORD_REG_START  	8
#define CSR_DWORD_REG_START 	16
#define CSR_SEG_REG_START   	24
#define CSR_DX_AX   	    	32
#define CSR_ES_BX   	    	33

/*
 * Symbolic constant:
 *	- type index (word)
 *	- value (size depends on type?)
 *	- name (counted ascii)
 */
#define CST_CONST    	    0x0e
/*
 * Fortran routine. Same as CST_PROC_START...
 */
#define CST_FORTRAN_ENTRY   0x0f

/*
 * Extra space allocated for incremental linking. Ignore it.
 */
#define CST_SKIP_ME  	    0x10

/*
 * Change default text segment for symbols:
 *	- new segment (word) with associated segment fixup
 *	- reserved (word)
 */
#define CST_CHANGE_SEG	    0x11

/*
 * Type alias:
 *	- type index (word)
 *	- name (counted ascii)
 */
#define CST_TYPEDEF  	    0x12

 /******************************************************************************
 *
 *			 CODEVIEW NEW SYMBOL TYPES
 *
 ******************************************************************************/

#define CST2_UDT		0x0004
#define CST2_END		0x0006

#define CST2_BPREL16	0x0100
#define CST2_GDATA16	0x0102
#define CST2_LPROC16	0x0104
#define CST2_GPROC16	0x0105
#define CST2_BLOCK16	0x0107


#define CSTT2_CHAR		0x0010
#define CSTT2_SHORT     0x0011
#define CSTT2_LONG     0x0012
#define CSTT2_UCHAR     0x0020
#define CSTT2_USHORT	0x0021
#define CSTT2_ULONG		0x0022
#define CSTT2_RCHAR		0x0070
#define CSTT2_INT2		0x0072


#define CCC2_PASCAL_NEAR	2
#define CCC2_PASCAL_FAR	    3



 /******************************************************************************
 *
 *			 CODEVIEW TYPE LEAVES
 *
 ******************************************************************************/
#define CTL2_MODIFIER		0x01
#define CTL2_POINTER		0x02
#define CTL2_ARRAY			0x03
#define CTL2_STRUCTURE		0x05
#define CTL2_ENUMERATION	0x07
#define CTL2_PROCEDURE		0x08
#define CTL2_ID	    	    0xffff

#define CTL2_FIELDLIST		0x0204
#define CTL2_MEMBER			0x0406
#define CTL2_ENUMERATIO		0x0403

#define CTL_BITFIELD	    0x5c
#define CTL_TYPEDEF 	    0x5d
#define CTL_HUGE    	    0x5e
#define CTL_STRING_TYPE	    0x60
#define CTL_NEAR    	    0x63
#define CTL_FAR	    	    0x64
#define CTL_PACKED  	    0x68
#define CTL_UNPACKED	    0x69
#define CTL_BOOLEAN 	    0x6c
#define CTL_CHAR    	    0x6f
#define CTL_INTEGER 	    0x70
#define CTL_CONSTANT	    0x71
#define CTL_LABEL   	    0x72
#define CTL_FAR_PTR	    0x73
#define CTL_NEAR_PTR 	    0x74
#define CTL_PROCEDURE	    0x75
#define CTL_PARAMETER	    0x76
#define CTL_ARRAY   	    0x78
#define CTL_STRUCTURE	    0x79
#define CTL_POINTER 	    0x7a
#define CTL_SCALAR  	    0x7b
#define CTL_UNSIGNED_INT    0x7c
#define CTL_SIGNED_INT	    0x7d
#define CTL_REAL    	    0x7e
#define CTL_LIST    	    0x7f
#define CTL_NIL	    	    0x80
#define CTL_VOID    	    0x81
#define CTL_STRING  	    0x82
#define CTL_INDEX   	    0x83
#define CTL_WORD    	    0x85
#define CTL_DWORD   	    0x86
#define CTL_QWORD   	    0x87
#define CTL_SBYTE   	    0x88
#define CTL_SWORD   	    0x89
#define CTL_SDWORD  	    0x8a
#define CTL_SQWORD  	    0x8b
#define CTL_BASIC_ARRAY	    0x8c
#define CTL_FORTRAN_STRING  0x8d
#define CTL_FORTRAN_ARR_IDX 0x8e
#define CTL_SKIP_ME 	    0x90
#define CTL_BASED   	    0x91
#define CTL_MEMBER_FUNCTION 0x9e
#define CTL_ID	    	    0xff    /* Special composite of ours to record
				     * when we turn a structured type into
				     * a real symbol; its ID follows in the
				     * next four bytes */

/* Calling-convention for CTL_PROCEDURE */
#define CCC_PASCAL_NEAR	    CTL_NEAR_PTR
#define CCC_PASCAL_FAR	    CTL_FAR_PTR
#define CCC_C_NEAR  	    CTL_NEAR
#define CCC_C_FAR   	    CTL_FAR
#define CCC_FAST_NEAR	    0x95
#define CCC_FAST_FAR	    0x96
#define CCC_INLINE  	    0x99

#define CST_LAST_PREDEF	0x0FFF

/* Fields of a predefined type (index < 512)  */
#define CST_SPECIAL 0x80    /* Set if index made of the following fields */
#define CST_MODE    0x60
#define CSTM_DIRECT 	0x00	/* Directly addressed */
#define CSTM_NEAR   	0x20	/* Near pointer to indicated type */
#define CSTM_FAR    	0x40	/* Far pointer to indicated type */
#define CSTM_HUGE   	0x60	/* Huge pointer to indicated type
				 * (unsupported) */
#define CST_TYPE    0x1c
#define CSTT_SIGNED 	0x00
#define CSTT_UNSIGNED	0x04
#define CSTT_REAL   	0x08
#define CSTT_COMPLEX	0x0c
#define CSTT_BOOLEAN	0x10
#define CSTT_ASCII  	0x14
#define CSTT_CURRENCY	0x18
#define CSTT_RESERVED	0x1c

#define CST_SIZE    0x03
/* Sizes for CSTT_REAL. Sizes for CSTT_COMPLEX are twice the size for CSTT_REAL,
 * there being two reals in a complex... */
#define CSTS_REAL_FLOAT	    0x00	/* 4-byte real */
#define CSTS_REAL_DOUBLE    0x01    	/* 8-byte real */
#define CSTS_REAL_TEMP	    0x02    	/* 10-byte (temporary) real */
#define CSTS_REAL_RESERVED  0x03    	/* undefined */

/* Sizes for CSTT_CURRENCY */
#define CSTS_CURR_8BYTE	    0x01    	/* all others are reserved */

/* Sizes for anything else */
#define CSTS_OTHER_BYTE	    0x00
#define CSTS_OTHER_WORD	    0x01
#define CSTS_OTHER_DWORD    0x02
#define CSTS_OTHER_RESERVED 0x03


#endif /* _CODEVIEW32_H_ */
