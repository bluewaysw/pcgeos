COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefintlCustomSpin.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/22/93   	Initial version.

DESCRIPTION:
	

	$Id: prefintlCustomSpin.asm,v 1.1 97/04/05 01:39:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinSetValue -- 
		MSG_CUSTOM_SPIN_SET_VALUE for CustomSpinClass

DESCRIPTION:	Set value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_CUSTOM_SPIN_SET_VALUE
		cx	- custom value

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/28/93         Initial Version

------------------------------------------------------------------------------@

CustomSpinSetValue	method dynamic	CustomSpinClass, \
				MSG_CUSTOM_SPIN_SET_VALUE
	clr	dx				;not indeterminate
	sub	cx, ds:[di].CS_minValue
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	GOTO	ObjCallInstanceNoLock

CustomSpinSetValue	endm




COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinGetValue -- 
		MSG_CUSTOM_SPIN_GET_VALUE for CustomSpinClass

DESCRIPTION:	Gets a value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_CUSTOM_SPIN_GET_VALUE

RETURN:		cx  	- value
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/28/93         	Initial Version

------------------------------------------------------------------------------@

CustomSpinGetValue	method dynamic	CustomSpinClass, \
				MSG_CUSTOM_SPIN_GET_VALUE

	push	di
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].GIGI_selection
	pop	di
	add	cx, ds:[di].CS_minValue
	ret
CustomSpinGetValue	endm



COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinSetMinValue -- 
		MSG_CUSTOM_SPIN_SET_MIN_VALUE for CustomSpinClass

DESCRIPTION:	Sets minimum value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_CUSTOM_SPIN_SET_MIN_VALUE
		cx 	- minimum value

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/28/93         	Initial Version

------------------------------------------------------------------------------@

CustomSpinSetMinValue	method dynamic	CustomSpinClass, \
				MSG_CUSTOM_SPIN_SET_MIN_VALUE
	mov	ds:[di].CS_minValue, cx
	ret
CustomSpinSetMinValue	endm

CustomSpinSetMaxValue	method dynamic	CustomSpinClass, \
				MSG_CUSTOM_SPIN_SET_MAX_VALUE
	mov	ds:[di].CS_maxValue, cx
	sub	cx, ds:[di].CS_minValue
	inc	cx
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	GOTO	ObjCallInstanceNoLock

CustomSpinSetMaxValue	endm




COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinQueryItemMoniker -- 
		MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER for CustomSpinClass

DESCRIPTION:	Returns current moniker to use.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER
		bp 	- item to use

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	1/28/93         	Initial Version

------------------------------------------------------------------------------@

CustomSpinQueryItemMoniker	method dynamic	CustomSpinClass, \
				MSG_GEN_DYNAMIC_LIST_QUERY_ITEM_MONIKER

	mov	bx, bp				; index in bx
	add	bx, ds:[di].CS_minValue		; add minimum value
	shl	bx, 1				; double for word array
	add	bx, ds:[di].CS_firstMoniker	; moniker handle => BX
	mov	cx, ds:[LMBH_handle]

	mov	ax, bp				; al = VisUpdateMode
	sub	sp, size ReplaceItemMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RIMF_item, ax
	mov	ss:[bp].RIMF_itemFlags, 0
	mov	ss:[bp].RIMF_source.handle, cx
	mov	ss:[bp].RIMF_source.chunk, bx
	mov	ss:[bp].RIMF_sourceType, VMST_OPTR
	mov	ss:[bp].RIMF_dataType, VMDT_TEXT
	mov	dx, ReplaceItemMonikerFrame
	mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
	call	ObjCallInstanceNoLock
	add	sp, size ReplaceItemMonikerFrame
	ret

CustomSpinQueryItemMoniker	endm


if PZ_PCGEOS	;Koji
COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinGetMinMax -- 
		MSG_CUSTOM_SPIN_GET_MIN_MAX for CustomSpinClass

DESCRIPTION:	Gets a min, max value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_CUSTOM_SPIN_GET_MIN_MAX

RETURN:		al	- minimum
		ah	- maximum

DESTROYED:	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	koji	9/15/93         	Initial Version

------------------------------------------------------------------------------@

CustomSpinGetMinMax	method dynamic	CustomSpinClass, \
				MSG_CUSTOM_SPIN_GET_MIN_MAX
	mov	ax, ds:[di].CS_minValue
	mov	bx, ds:[di].CS_maxValue
	mov_tr	ah, bl
	ret
CustomSpinGetMinMax	endm

endif
