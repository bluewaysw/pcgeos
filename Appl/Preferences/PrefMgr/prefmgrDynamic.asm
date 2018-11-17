COMMENT @---------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		
FILE:		prefmgrDynamic.asm

AUTHOR:		Cheng, 1/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial revision

DESCRIPTION:
	Dynamic list routines for the preference manager.
		
	$Id: prefmgrDynamic.asm,v 1.1 97/04/04 16:27:15 newdeal Exp $

-------------------------------------------------------------------------------@

if 0

These tables are here for documentation only

DynamicListTable	optr	\
	0,
	EditDictionaryList,
	ChooseDictionaryList

SetMonikerTable	word \
	0,
	offset TextRequestAlternate,
	offset ReturnMonikerForDictionaryList



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNumEntriesChooseDictionaryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

zSYNOPSIS:

CALLED BY:

PASS:		

RETURN:		cx - # entries

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNumEntriesChooseDictionaryList	proc near
	mov	cx, es:[numDictionaries]
	ret
SetNumEntriesChooseDictionaryList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNumEntriesEditDictionaryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the # entries in the "edit user dict" list

CALLED BY:

PASS:		

RETURN:		cx - num entries

DESTROYED:	ax,bx,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNumEntriesEditDictionaryList	proc near

	.enter
	clr	cx
	push	bx
	mov	bx, ds:[userDictList]
	tst	bx
	jz	80$
	call	MemLock
	mov	es, ax
	mov	cx, es:[UDLI_numEntries]
	call	MemUnlock
80$:
	pop	bx

	.leave
	ret
SetNumEntriesEditDictionaryList	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnMonikerForDictionaryList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a moniker for the dictionary list

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	ax,bx,cx,dx,si,di,bp,es,ds
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReturnMonikerForDictionaryList	method	PrefMgrClass, MSG_TEXT_GET_DICTIONARY_LIST_MONIKER
EC <	cmp	bp, es:[numDictionaries]				>
EC <	ERROR_AE INVALID_BITMAP_NUMBER					>
	mov	bx, es:[dictionaryData]	;Lock list of dictionaries
	call	MemLock
	mov	ds, ax
	mov	ax, bp				;
	push	dx
	mov	bx, size DictionaryInfoStruct	;
	mul	bx				;
	pop	dx
	xchg	di, ax				;DS:DI <- ptr to dictionary
	call	SetTextMoniker			;
	mov	bx, es:[dictionaryData]	;Unlock list of dictionaries
	call	MemUnlock
	ret
ReturnMonikerForDictionaryList	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetTextMoniker

DESCRIPTION:	

CALLED BY:	INTERNAL (MtdHanReturnMoniker)

PASS:		cx:dx - gen list od
		bp - entry index
		es - dgroup
		ds:di - ASCIIZ string


RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

SetTextMoniker	proc	near
EC<     call    CheckESDgroup                                           >

	mov	bx, cx
	mov	si, dx

	mov	cx, ds
	mov	dx, di
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
	mov	di, mask MF_CALL		; process before block
						; is freed!
	call	ObjMessage			
	ret
SetTextMoniker	endp

