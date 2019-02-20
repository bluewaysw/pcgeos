/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Header for users of the Var module.
 * FILE:	  var.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Constant and function definitions for the Var module.
 *
 *
* 	$Id: var.h,v 4.2 92/07/26 16:49:27 adam Exp $
 *
 ***********************************************************************/
#ifndef _VAR_H
#define _VAR_H

typedef enum {
    VAR_FETCH,	  	    /* Patient -> Swat conversion */
    VAR_STORE	  	    /* Swat -> Patient conversion */
}	    Var_SwapDirection;

extern char 	*Var_FetchString (Handle handle, Address offset);
extern dword 	Var_ExtractBits (genptr base, int offset, int length,
				 Boolean isSigned);
extern void 	Var_InsertBits (genptr base, int offset, int length,
				dword val);
extern Boolean 	Var_FetchBits (Handle handle, Address base, int offset,
			       int length, Boolean isSigned, dword *valuePtr);
extern Boolean 	Var_FetchInt (int size, Handle handle, Address offset,
			      genptr swatAddress);
extern Boolean 	Var_FetchAlloc (Type type, Handle handle, Address offset,
				genptr *swatAddressPtr);
extern Boolean 	Var_Fetch (Type type, Handle handle, Address offset,
			   genptr swatAddress);
extern Boolean	Var_StoreBits (Handle handle, Address base, int offset,
			       int length, dword value);
extern Boolean 	Var_StoreInt (int size, int word, Handle handle,
			      Address offset);
extern Boolean 	Var_Store (Type type, genptr swatAddress, Handle handle,
			   Address offset);
extern void 	Var_SwapValue (Var_SwapDirection direction,
			       Type type, int size, genptr address);
extern genptr 	Var_Cast (genptr data, Type srcType, Type dstType);

#endif /* _VAR_H */

