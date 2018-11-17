
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		

AUTHOR:		Cheng, 3/91

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial revision

DESCRIPTION:
		
	$Id: uiList.asm,v 1.1 97/04/04 15:48:29 newdeal Exp $

-------------------------------------------------------------------------------@

UITrans	segment resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ListGetNumberOfEntries

DESCRIPTION:	Routes the method call to the appropriate dynamic list routine.

CALLED BY:	INTERNAL (MSG_META_GEN_LIST_GET_NUMBER_OF_ENTRIES)

PASS:		cx:dx - OD of the GenList

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

ListGetNumberOfEntries	proc	far
if 0
	GetResourceHandleNS UIFmtMainListGroup, bx
	cmp	bx, cx
	jne	notFormat

	call	FormatGetNumberOfEntries
	jmp	short done

notFormat:
endif
	GetResourceHandleNS DefineNameDB, bx
	cmp	bx, cx
	jne	notName

	call	NameGetNumberOfEntries
	jmp	short done

notName:
	GetResourceHandleNS ChooseFunctionList, bx
	cmp	bx, cx
	jne	done

	cmp	dx, offset ChooseFunctionList
	jne	chooseName

	call	FunctionGetNumberOfEntries
	jmp	short done

chooseName:
	call	NameGetNumberOfEntries

done:
	ret
ListGetNumberOfEntries	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ListGetEntryMoniker

DESCRIPTION:	Routes the method call to the appropriate dynamic list routine.

CALLED BY:	INTERNAL (MSG_META_GEN_LIST_REQUEST_ENTRY_MONIKER)

PASS:		cx:dx - OD of the GenList

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

ListGetEntryMoniker	proc	far
if 0
	GetResourceHandleNS UIFmtMainListGroup, bx
	cmp	bx, cx
	jne	notFormat

	call	FormatGetEntryMoniker
	jmp	short done

notFormat:
endif
	GetResourceHandleNS DefineNameDB, bx
	cmp	bx, cx
	jne	notName

	call	NameGetEntryMoniker
	jmp	short done

notName:
	GetResourceHandleNS ChooseFunctionList, bx
	cmp	bx, cx
	jne	done

	cmp	dx, offset ChooseFunctionList
	jne	chooseName

	call	FunctionGetEntryMoniker
	jmp	short done

chooseName:
	call	NameGetEntryMoniker

done:
	ret
ListGetEntryMoniker	endp

UITrans	ends
