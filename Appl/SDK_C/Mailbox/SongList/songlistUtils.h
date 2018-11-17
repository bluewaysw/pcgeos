/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	  
 * MODULE:	  
 * FILE:	  songlistUtils.h
 *
 * AUTHOR:  	  Chung Liu: Dec  9, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	CL	12/ 9/94   	Initial version
 *
 * DESCRIPTION:
 *	
 *
 *
 * 	$Id: songlistUtils.h,v 1.1 97/04/04 16:40:20 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SONGLISTUTILS_H_
#define _SONGLISTUTILS_H_

extern word
    SLVMTreeGetNumChildren (VMFileHandle vmfh,
			    VMBlockHandle vmbh);
extern void
    SLVMTreeAddChild (VMFileHandle vmfh,
		      VMBlockHandle parentBlock,
		      VMBlockHandle newChildBlock);

extern VMBlockHandle
    SLVMTreeGetNthChild (VMFileHandle vmfh,
			 VMBlockHandle parentBlock,
			 word n);

extern void
    SLVMTreeDeleteChild (VMFileHandle vmfh,
			 VMBlockHandle parentBlock,
			 VMBlockHandle childBlock);

extern VMBlockHandle
    SLAllocAndInitDataBlock (VMFileHandle vmfh,
			     word userID,
			     char *name,
			     char *notes);

extern VMBlockHandle
    SLAllocAndInitDataBlockFromDialog (VMFileHandle vmfh,
				       word userID);

extern VMBlockHandle
    SLAllocAndInitDataBlockLikeThisOther (VMFileHandle vmfh,
					  VMBlockHandle vmbh,
					  word userID,
					  VMFileHandle newVMFile);

extern VMBlockHandle
    SLFindDataBlock(VMFileHandle vmfh,
		    char *name,
		    word userID);

extern void
    SLUpdateText (VMFileHandle vmfh,
		  VMBlockHandle artistBlock,
		  VMBlockHandle recordBlock,
		  VMBlockHandle songBlock);

typedef Boolean
    SLVMTreeEnumCallback (VMFileHandle vmfh,
			  VMBlockHandle vmbh,
			  word n,
			  VMBlockHandle otherBlock);

extern void
    SLVMTreeEnum (VMFileHandle vmfh,
		  VMBlockHandle vmbh,
		  SLVMTreeEnumCallback *callback,
		  VMBlockHandle otherBlock);

extern void
    SLAppendNotes (VMFileHandle vmfh, VMBlockHandle vmbh, char *moreNotes);

extern void
    SLReplaceNotes (VMFileHandle vmfh, VMBlockHandle vmbh, char *newNotes);


#endif /* _SONGLISTUTILS_H_ */


