COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Iclas -- IconList
FILE:		iconlistMain.asm

AUTHOR:		Martin Turon, October 16, 1992

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/16/92        Initial version

DESCRIPTION:
	Externally callable routines for this module.
	No routines outside this file should be called from outside this
	module.

	$Id: iconlistMain.asm,v 1.1 97/04/07 10:45:25 newdeal Exp $

=============================================================================@

COMMENT @-------------------------------------------------------------------
	Work to be done:
		1) make sure IconListClass frees the memory allocated
		   by IconListBuildList whenever:
			* IconList object is destroyed
			* IconList object switchs lookup tables
		2) add selectivity to IconListBuildList:
			* only add tokens of certain manufacturer id
			* only add 'ba**' tokens, etc.
		3) fixup IconListClass, so that it can handle *any*
		   video mode (not hardcoded for VGA). 

----------------------------------------------------------------------------@


COMMENT @-------------------------------------------------------------------
		IconListSpecBuild
----------------------------------------------------------------------------

DESCRIPTION:	Sets the IconList object to the correct size.

CALLED BY:	GLOBAL

PASS:		*ds:si	= IconListClass object
		ds:di	= IconListClass instance data
		bp	= SpecBuildFlags

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/16/92   	Initial version

----------------------------------------------------------------------------@
IconListSpecBuild	method dynamic IconListClass, 
					MSG_SPEC_BUILD
		uses	ax, bp		
		.enter
	;
	; Get size from first moniker in list
	;
;		call	VisGetSize
	;
	; Set size depending on DisplayType by append to object:
	;	HINT_FIXED_SIZE {
	;		SpecWidth <>
	;		SpecHeight <>
	;		word	5
	;	}
	;
		mov	ax, HINT_FIXED_SIZE
		mov	cx, size SpecWidth + size SpecHeight + size word
		call	ObjVarAddData
		mov	ds:[bx].SSA_width,  SpecWidth  <SST_PIXELS, (55*5)>
		mov	ds:[bx].SSA_height, SpecHeight <SST_PIXELS, 32>
		mov	ds:[bx].SSA_count, 5

		mov	di, ds:[si]
		add	di, ds:[di].IconList_offset
		movdw	dxcx, ds:[di].ILI_lookupTable
		mov	ax, MSG_ICON_LIST_SET_TOKEN_LIST
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE or \
			    mask MF_FIXUP_DS or mask MF_FIXUP_ES
		call	ObjMessage
		
		.leave
		mov	di, offset IconListClass
		GOTO	ObjCallSuperNoLock

IconListSpecBuild	endm




COMMENT @-------------------------------------------------------------------
		IconListQueryItemMoniker
----------------------------------------------------------------------------

SYNOPSIS:	This is called when the dynamic GenList needs to show a 
		moniker on the screen. It sends us the number of the list
		item whose moniker it needs. We get it by looking in our
		local table of tokens and grabbing the moniker from
		the token.db 

CALLED BY:	GenDynamicListClass

PASS:		*ds:si	= IconListClass object
		ds:di	= IconListClass instance data
		^lcx:dx = the dynamic list requesting the moniker
		bp	= entry # it needs the moniker for

RETURN:		nothing

DESTROYED:	lots of stuff (but it doesn't matter)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/16/92   	Initial version

----------------------------------------------------------------------------@
IconListQueryItemMoniker	method dynamic IconListClass, 
				MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
	.enter
	call	IconListLookupToken		; ax:cx:dx = GeodeToken
	call	ShellLoadMoniker		; ^cx:dx   = Moniker
	push	cx
	jc	error
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER_OPTR
	call	ObjCallInstanceNoLock
error:
	pop	bx
	call	MemFree				; free moniker
	.leave
	ret
IconListQueryItemMoniker	endm



COMMENT @-------------------------------------------------------------------
		IconListGetSelected
----------------------------------------------------------------------------

DESCRIPTION:	Returns the token currently selected in an
		IconListClass object.  If nothing is selected, returns
		the first token in the list.

CALLED BY:	GLOBAL

PASS:		*ds:si		= IconListClass object

RETURN:		ax:cx:dx	= GeodeToken
		CF		= set if no token selected
				  clear otherwise

DESTROYED:	bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/18/92   	Initial version

----------------------------------------------------------------------------@
IconListGetSelected	method dynamic IconListClass, 
					MSG_ICON_LIST_GET_SELECTED
		.enter
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		pushf				; save carry flag
		jnc	useSelected
		clr	ax			; return first token in list
useSelected:
		mov	bp, ax
		mov	di, ds:[si]
		add	di, ds:[di].IconList_offset
		call	IconListLookupToken
		popf				; restore carry flag
		.leave
		ret
IconListGetSelected	endm


COMMENT @-------------------------------------------------------------------
		IconListSetTokenOfFile
----------------------------------------------------------------------------

DESCRIPTION:	Sets the token of the given file to that of the
		current selection.  

		WARNING: Be careful when sending this message across
			 threads, as the current directorys may be
			 different!  (Use full path names)

CALLED BY:	GLOBAL

PASS:		*ds:si	= IconListClass object
		cx:dx	= file to set token of

RETURN:		IF ERROR:
			carry set
			ax	= FileError
		ELSE:
			carry clear

DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/18/92   	Initial version

----------------------------------------------------------------------------@
IconListSetTokenOfFile	method dynamic IconListClass, 
					MSG_ICON_LIST_SET_TOKEN_OF_FILE
	.enter

if ERROR_CHECK
	;
	; Validate that the filename is not in a movable code segment
	;
FXIP<	push	bx, si						>
FXIP<	mov	bx, cx						>
FXIP<	mov	si, dx						>
FXIP<	call	ECAssertValidFarPointerXIP			>
FXIP<	pop	bx, si						>
endif

	push	cx, dx
	mov	ax, MSG_ICON_LIST_GET_SELECTED
	call	ObjCallInstanceNoLock
	mov	di, dx
	pop	ds, dx
;	call	IclasSetToken
	.leave
	ret
IconListSetTokenOfFile	endm


COMMENT @-------------------------------------------------------------------
		IconListSetSelectionToToken
----------------------------------------------------------------------------

DESCRIPTION:	

CALLED BY:	

PASS:		*ds:si		= IconListClass object
		bp:cx:dx	= GeodeToken
		
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/30/92   	Initial version

----------------------------------------------------------------------------@
IconListSetSelectionToToken	method dynamic IconListClass, 
					MSG_ICON_LIST_SET_SELECTION_TO_TOKEN

		.enter
		call	IconListFindToken
		jc	done
		mov	cx, bp
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	ObjCallInstanceNoLock
done:
		.leave
		ret

IconListSetSelectionToToken	endm



COMMENT @-------------------------------------------------------------------
		IconListSetTokenList
----------------------------------------------------------------------------

DESCRIPTION:	Sets the token list, and forces a redraw if necessary.

CALLED BY:	GLOBAL

PASS:		*ds:si	= IconListClass object
		ds:di	= IconListClass instance data
		^ldx:cx	= new token list
			  if dx=0, list will be built to contain all
				   tokens in token db.
	
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/18/92   	Initial version

----------------------------------------------------------------------------@
IconListSetTokenList	method dynamic IconListClass, 
					MSG_ICON_LIST_SET_TOKEN_LIST
	;
	; Store token list in instance data.
	;
		movdw	ds:[di].ILI_lookupTable, dxcx
		FALL_THRU	IconListInitialize

IconListSetTokenList	endm




COMMENT @-------------------------------------------------------------------
		IconListInitialize
----------------------------------------------------------------------------

DESCRIPTION:	Builds a table of all the tokens in the token DB if a
		table has not already been specified.  The icon list
		is then notified to display a new list of items.
		If the list is already usable, invalidates all the
		current items and re-requests all the monikers.   All
		items will be deselected.

CALLED BY:	GLOBAL
PASS:		*ds:si	= IconListClass object
		ds:di	= IconListClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/5/92   	Initial version

----------------------------------------------------------------------------@
IconListInitialize	method	static	IconListClass, 
					MSG_ICON_LIST_INITIALIZE
	;
	; If no list is specified, build one with every entry of the
	; token database.
	;	
		call	IconListBuildListIfNeededAndGetSize
	;
	; Initialize list
	;	
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		GOTO	ObjCallInstanceNoLock

IconListInitialize	endm





