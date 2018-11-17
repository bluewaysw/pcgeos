/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Esp -- Code Generators
 * FILE:	  code.h
 *
 * AUTHOR:  	  Adam de Boor: Jun 29, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	6/29/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Header file for callers of the code generators...
 *
 *
 * 	$Id: code.h,v 1.12 93/09/19 18:07:21 adam Exp $
 *
 ***********************************************************************/
#ifndef _CODE_H_
#define _CODE_H_

#include    "fixup.h"

/*
 * Declare all the code generators
 */
extern FixProc	Code_Arith2;
extern FixProc	Code_Arpl;
extern FixProc	Code_BitNF;
extern FixProc	Code_Bound;
extern FixProc	Code_Call;
extern FixProc	Code_CallStatic;
extern FixProc	Code_DPShiftLeft;
extern FixProc	Code_DPShiftRight;
extern FixProc	Code_EnterLeave;
extern FixProc	Code_Fbiop;
extern FixProc	Code_Fcom;
extern FixProc	Code_Ffree;
extern FixProc	Code_Fgroup0;
extern FixProc	Code_Fgroup1;
extern FixProc	Code_Fldst;
extern FixProc	Code_Fint;
extern FixProc	Code_Fzop;
extern FixProc	Code_Group1;
extern FixProc	Code_Imul;
extern FixProc	Code_IO;
extern FixProc	Code_Ins;
extern FixProc	Code_Int;
extern FixProc	Code_Jmp;
extern FixProc	Code_Jcc;
extern FixProc	Code_LDPtr;
extern FixProc	Code_Lea;
extern FixProc	Code_Lock;
extern FixProc	Code_Loop;
extern FixProc	Code_LSDt;
extern FixProc	Code_LSInfo;
extern FixProc	Code_Move;
extern FixProc	Code_NoArg;
extern FixProc	Code_NoArgPriv;
extern FixProc	Code_NoArgIO;
extern FixProc	Code_Override;
extern FixProc	Code_Outs;
extern FixProc	Code_Pop;
extern FixProc	Code_Push;
extern FixProc	Code_PWord;
extern FixProc	Code_Rep;
extern FixProc	Code_Ret;
extern FixProc	Code_Shift;
extern FixProc	Code_String;
extern FixProc	Code_Test;
extern FixProc	Code_IncDec;
extern FixProc	Code_Xchg;

extern void 	Code_ProfileBBlock(int *addrPtr);
extern void	Code_PrologueSaveFP(void);
extern void     Code_Prologue(int frameNeeded,
			      dword usesMask,
			      int localSize,
			      int fpSaved);


extern FixResult
Code_Fxch(int	    *addrPtr,	/* IN/OUT: Address of instruction start */
	  int     prevSize,  	/* # bytes previously allocated to inst */
	  int     pass,    	/* Current pass */
	  Expr    *expr1,   	/* Operand 1 */
	  Expr    *expr2,   	/* Operand 2 */
	  Opaque  data);    	/* OpCode/other data */
extern void
Code_Epilogue(int   	frameNeeded,
	      int   	usesMask,
	      int   	localSize);

#endif /* _CODE_H_ */
