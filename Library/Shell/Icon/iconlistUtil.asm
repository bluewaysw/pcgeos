COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		iconlistUtil.asm

AUTHOR:		Martin Turon, Oct 18, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/18/92	Initial version


DESCRIPTION:
	
		

RCS STAMP:
	$Id: iconlistUtil.asm,v 1.1 97/04/07 10:45:29 newdeal Exp $


=============================================================================@




COMMENT @-------------------------------------------------------------------
			IconListLockTable
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	INTERNAL - IconListLookupTable
			   IconListGetListSize

PASS:		ds:di	= IconListClass instance data

RETURN:		es:di	= IconListTableHeader
		bx	= memory handle of table

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/19/92	Initial version

---------------------------------------------------------------------------@
IconListLockTable	proc	near
	class	IconListClass
	.enter
	movdw	bxdi, ds:[di].ILI_lookupTable
					 	; ^lbx:di = lookupTable
	call	ObjLockObjBlock			; lock it down
	mov	es, ax
	mov	di, es:[di]			; es:di -> lookupTable
	.leave
	ret
IconListLockTable	endp



COMMENT @-------------------------------------------------------------------
			IconListBuildTable
----------------------------------------------------------------------------

DESCRIPTION:	Builds a table of all the icons in the token database.

CALLED BY:	INTERNAL - IconListBuildListIfNeededAndGetSize

PASS:		ds:di	= IconListClass instance data

RETURN:		cx	= size of new table

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/29/92	Initial version

---------------------------------------------------------------------------@
IconListBuildTable	proc	near
		class	IconListClass

		uses	ax, bx, es
		.enter
	;
	; Build a list of all tokens in token database, and save
	; pointer to table in IconList object's instance data.
	;
		mov	ax, mask TRF_ONLY_GSTRING
		mov	bx, size IconLookupTableHeader + size word
		call	TokenListTokens
		mov	ds:[di].ILI_lookupTable.handle, bx
		clr	ds:[di].ILI_lookupTable.offset
		mov_tr	cx, ax				; cx = size of table
	;
	; Lock down block with TokenTable, and:
	; 	1) make first word in segment a pointer to the table
	; 	2) Fill in header of lookupTable
	; 
		call	MemLock
		mov	es, ax
		mov	{word}es:[0], 2			
		mov	es:[2 + ILTH_tableSize], cx
		call	MemUnlock

		.leave
		ret
IconListBuildTable	endp



COMMENT @-------------------------------------------------------------------
			IconListLookupToken
----------------------------------------------------------------------------

DESCRIPTION:	Returns the entry at the given offset of the current
		IconLookupTable. 

CALLED BY:	INTERNAL - IconListQueryItemMoniker,
			   IconListGetSelected

PASS:		ds:di		= IconListClass instance data
		bp		= table entry number

RETURN:		ax:cx:dx	= GeodeToken

DESTROYED:	si, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/18/92	Initial version

---------------------------------------------------------------------------@
IconListLookupToken	proc	near
	.enter

	call	IconListLockTable
	mov	ax, bp
	shl	ax				; double entry
	add	ax, bp				; triple entry
	shl	ax				; X6 (six byte tokens)
	add	di, ax				; es:di -> desired token
	add	di, offset ILTH_table

	mov	ax, {word}es:[di]		; tokenchars 1 & 2
	mov	cx, {word}es:[di+2]		; tokenchars 3 & 4 (cx for now)
	mov	dx, {word}es:[di+4]		; manufacturer's ID

	call	MemUnlock			; release block
	.leave
	ret
IconListLookupToken	endp



COMMENT @-------------------------------------------------------------------
			IconListFindToken
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	INTERNAL - IconListSetSelectionToToken

PASS:		ds:di		= IconListClass instance data
		bp:cx:dx	= GeodeToken

RETURN:		IF FOUND:
			carry clear
			bp	= table entry number
		ELSE:
			carry set
	
DESTROYED:	bx, cx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/30/92	Initial version

---------------------------------------------------------------------------@
IconListFindToken	proc	near
		.enter
		call	IconListLockTable	

		mov	ax, bp
		mov	bp, -1
	
		push	bx
		mov	bx, cx
		mov	cx, es:[di].ILTH_tableSize
		add	di, offset ILTH_table - size GeodeToken	; go back by one
								; token, forward
								; by header size
continue:
		jcxz	notFound
		inc	bp
		dec	cx
		add	di, size GeodeToken
		cmpdw	es:[di].GT_chars, bxax
		jne	continue
		cmp	es:[di].GT_manufID, dx
		jne	continue
		clc
done:
		pop	bx
		call	MemUnlock
		.leave
		ret
notFound:
		stc
		jmp	done

IconListFindToken	endp




COMMENT @-------------------------------------------------------------------
			IconListGetListSize
----------------------------------------------------------------------------

DESCRIPTION:	Returns the size of the current IconLookupTable

CALLED BY:	INTERNAL - IconListBuildListIfNeededAndGetSize

PASS:		ds:di	= IconListClass instance data

RETURN:		cx	= # of entries in lookup table

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/19/92	Initial version

---------------------------------------------------------------------------@
IconListGetListSize	proc	near
		uses	es
		.enter
		call	IconListLockTable
		mov	cx, es:[di].ILTH_tableSize
		call	MemUnlock
		.leave
		ret
IconListGetListSize	endp




COMMENT @-------------------------------------------------------------------
			IconListBuildListIfNeededAndGetSize
----------------------------------------------------------------------------

DESCRIPTION:	Optimization routine to speed up a commonly used
		combination of functions.  

CALLED BY:	INTERNAL - IconListInitialize,
			   IconListSetToken

PASS:		ds:di	= IconListClass instance data

RETURN:		cx	= # of entries in lookup table

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
	If zero flag is set: builds a lookup table of tokens from the
			     token db if zero flag is set, and returns
			     the size of the table.  
	If zero flag is clear: return the size of the current token table.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92	Initial version

---------------------------------------------------------------------------@
IconListBuildListIfNeededAndGetSize	proc	near
		class	IconListClass
		.enter

		tst	ds:[di].ILI_lookupTable.handle
		jnz	getSizeOnly
		call	IconListBuildTable	
		jmp	done
getSizeOnly:
		call	IconListGetListSize
done:
		.leave
		ret
IconListBuildListIfNeededAndGetSize	endp


