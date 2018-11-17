COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Misc
FILE:		miscCustomSpin.asm

AUTHOR:		Don Reeves, February 7, 1990

ROUTINES:
	Name			Description
	----			-----------
	CustomSpinGetValueText		Returns text to use for a certain value
	CustomSpinSetValueFromText	Sets a value based on the text
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/7/90		Initial revision
	Chris	7/22/92		Rewritten to be subclassed from GenValueClass

DESCRIPTION:
	Implements the custom spin gadget, used to display "n" monikers
	using a GenSpinGadget.
		
	To allow the gadget to hold an easily expandable number of monikers,
	a table of pointers to monikers is utilized:
	
	CustomSpinGadget -> MonikerList --> Moniker 0
					|-> Moniker 1
					|-> Moniker 2
					...
	Notice that the system is zero-based!

	If an ActionDescriptor is provided (by setting the "action" field
	in the .UI file, then the current index value is reported in CX
	every time it is changed.  No check for duplicity is made.

	$Id: miscCustomSpin.asm,v 1.1 97/04/04 14:48:44 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
	CustomSpinClass				; my custom spin gadget
idata		ends

RepeatCode	segment	resource


COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinGetValueText -- 
		MSG_GEN_VALUE_GET_VALUE_TEXT for CustomSpinClass

DESCRIPTION:	Returns appropriate text for the value.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_VALUE_TEXT
		cx:dx	- buffer to hold text
		bp 	- GenValueChoice

RETURN:		cx:dx   - buffer, filled in
		ax, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

CustomSpinGetValueText	method dynamic	CustomSpinClass, \
				MSG_GEN_VALUE_GET_VALUE_TEXT
	tst	bp				;make sure they want current
	jz	getMonikerText			;yes, branch

	mov	di, offset CustomSpinClass
	GOTO	ObjCallSuperNoLock		;else give up, and return digits

getMonikerText:
	mov	bx, ds:[di].GVLI_value.WWF_int	;get integer value
	shl	bx, 1				; double for word array
	add	bx, ds:[di].CS_firstMoniker	; moniker handle => BX
	mov	si, ds:[bx]			; dereference chunk
	movdw	esdi, cxdx			; point to destination
copyLoop:
	LocalGetChar ax, dssi			; copy the string in
	LocalPutChar esdi, ax
	LocalIsNull ax
	jnz	copyLoop
	ret
CustomSpinGetValueText	endm


COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinSetValueFromText -- 
		MSG_GEN_VALUE_SET_VALUE_FROM_TEXT for CustomSpinClass

DESCRIPTION:	Sets the value from the text, using the one that matches.
		We'll allow for partial completion here; one may want to make
		that an option.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
		cx:dx	- text
		bp	- GenValueChoice

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
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

CustomSpinSetValueFromText	method dynamic	CustomSpinClass, \
				MSG_GEN_VALUE_SET_VALUE_FROM_TEXT

	tst	bp				;not current value, punt
	je	setValue
	mov	di, offset CustomSpinClass
	GOTO 	ObjCallSuperNoLock

setValue:
	;
	; Loop through the monikers, looking for a match, until it's time to
	; give up.
	;
	mov	bx, ds:[di].CS_firstMoniker	; moniker handle => BX
	movdw	esdi, cxdx			; text in es:di
	clr	cx				; keep value counter
	mov	bp, si				; keep chunk handle in bp

checkLoop:
	mov	si, ds:[bx]			; redef moniker, ds:si
	push	di
strCmp:
	cmp	{byte} es:[di], 0		; at end of string, match
	jz	found
	cmpsb					; else get a moniker byte
	je	strCmp				; bytes match, loop

	inc	cx				; else bump count
	inc	bx				; and bump moniker pointer
	inc	bx		
	mov	di, ds:[bp]			
	add	di, ds:[di].Gen_offset
	cmp	cx, ds:[di].GVLI_maximum.WWF_int ; past last entry?
	pop	di				 ; (restore start of dest)
	jbe	checkLoop			 ; no, loop

	mov	ax, SST_NO_INPUT		 ; else we'll signal an error
	call	UserStandardSound
	ret					 ; and give up

found:
	pop	di				; unload pointer
	mov	si, bp				; value in dx.cx
	clr	bp				; not indeterminate
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	GOTO	ObjCallInstanceNoLock

CustomSpinSetValueFromText	endm


COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinGetTextFilter -- 
		MSG_GEN_VALUE_GET_TEXT_FILTER for CustomSpinClass

DESCRIPTION:	Returns text filter to use.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_TEXT_FILTER

RETURN:		al	- VisTextFilters
		ah, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	6/ 1/92		Initial Version

------------------------------------------------------------------------------@

CustomSpinGetTextFilter	method dynamic	CustomSpinClass, \
				MSG_GEN_VALUE_GET_TEXT_FILTER

	mov	al, mask VTF_NO_TABS		;allow everything but tabs
	ret
CustomSpinGetTextFilter	endm


COMMENT @----------------------------------------------------------------------

METHOD:		CustomSpinGetMaxTextLen -- 
		MSG_GEN_VALUE_GET_MAX_TEXT_LEN for CustomSpinClass

DESCRIPTION:	Handles getting the maximum text length for the gadget.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_GEN_VALUE_GET_MAX_TEXT_LEN

RETURN:		nothing
		ax, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	7/22/92		Initial Version

------------------------------------------------------------------------------@

CustomSpinGetMaxTextLen	method dynamic	CustomSpinClass, \
				MSG_GEN_VALUE_GET_MAX_TEXT_LEN
	clr	cx
	mov	cl, ds:[di].CS_maxTextLen
	ret
CustomSpinGetMaxTextLen	endm

RepeatCode	ends
