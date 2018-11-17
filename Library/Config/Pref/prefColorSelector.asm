COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		PrefColorSelector.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

DESCRIPTION:
	

	$Id: prefColorSelector.asm,v 1.2 98/04/05 13:00:07 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set not usable on CGA

PASS:		*ds:si	- PrefColorSelectorClass object
		ds:di	- PrefColorSelectorClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorInit	method	dynamic	PrefColorSelectorClass, 
					MSG_PREF_INIT
	uses	ax,cx,dx,bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	UserCallApplication

	;
	; Set the background color list not usable if on a monochrome display,
	; because the user isn't allowed to change it.
	;

	and	ah, mask DT_DISP_CLASS		;Get display class
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS	;Branch if monochrome
	mov	ax, MSG_GEN_SET_NOT_USABLE
	je	mono
	mov	ax, MSG_GEN_SET_USABLE
mono:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock


	.leave
	mov	di, offset PrefColorSelectorClass
	GOTO	ObjCallSuperNoLock
PrefColorSelectorInit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Hacked routine to call GenClass directly, bypassing
		GenControlClass 

PASS:		*ds:si	= PrefColorSelectorClass object
		ds:di	= PrefColorSelectorClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorHack	method	dynamic	PrefColorSelectorClass, 
					MSG_META_LOAD_OPTIONS,
					MSG_META_SAVE_OPTIONS
	.enter
	segmov	es, <segment GenClass>, di
	mov	di, offset GenClass
	call	ObjCallClassNoLock
	.leave
	ret
PrefColorSelectorHack	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load options and set the color	

PASS:		*ds:si	= PrefColorSelectorClass object
		ds:di	= PrefColorSelectorClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorLoadOptions	method	dynamic	PrefColorSelectorClass, 
					MSG_GEN_LOAD_OPTIONS

	.enter

	push	ds, si
	mov	cx, ss
	mov	ds, cx
	lea	si, ss:[bp].GOP_category
	lea	dx, ss:[bp].GOP_key
	call	InitFileReadInt32	; dx:ax - integer
	pop	ds, si
	jc	done

	mov_tr	cx, ax
	clr	bp
	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock


done:

	.leave
	ret
PrefColorSelectorLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get and set the color, AFTER the UI has been generated.

PASS:		*ds:si	= PrefColorSelectorClass object
		ds:di	= PrefColorSelectorClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 6/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorSpecBuild	method	dynamic	PrefColorSelectorClass, 
					MSG_SPEC_BUILD
	.enter
	mov	di, offset PrefColorSelectorClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_COLOR_SELECTOR_GET_COLOR
	call	ObjCallInstanceNoLock

	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	call	ObjCallInstanceNoLock

	.leave
	ret
PrefColorSelectorSpecBuild	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save options and set the color	

PASS:		*ds:si	= PrefColorSelectorClass object
		ds:di	= PrefColorSelectorClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorSaveOptions	method	dynamic	PrefColorSelectorClass, 
					MSG_GEN_SAVE_OPTIONS

	.enter

	push	bp
	mov	ax, MSG_COLOR_SELECTOR_GET_COLOR
	call	ObjCallInstanceNoLock
	pop	bp

	mov_tr	ax, cx			; dx:ax - color

	push	ax
	mov	ax, TEMP_GEN_CONTROL_INSTANCE
	call	ObjVarDerefData
	pop	ax
	;
	; see if we're using RGB colors, and if not, convert to index
	;
	test	ds:[bx].TGCI_features, mask CSF_RGB
	jnz	gotColor
	mov_tr	bx, dx				;al <-R, bl <- G, bh <- B
	clr	di				;di <- default mapping
	call	GrMapColorRGB
	clr	al				;al <- no R
	clr	dx				;dx <- no GB
	xchg	al, ah				;al <- index

gotColor:
	segmov	es, ss
	segmov	ds, ss
	lea	si, ss:[bp].GOP_category
	lea	di, ss:[bp].GOP_key
	call	InitFileWriteInt32	; dx:ax - integer


	.leave
	ret
PrefColorSelectorSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileReadInt32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read a 32-bit integer

CALLED BY:	PrefColorSelectorLoadOptions

PASS:		ds:si - category
		cx:dx - key

RETURN:		CARRY SET IF ERROR
		carry clear otherwise
			dx:ax - number

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileReadInt32	proc near
	uses	ds, si, bp
	.enter

	clr	bp
	call	InitFileReadString
	jc	done

	call	MemLock
	mov	ds, ax
	clr	si
	call	UtilAsciiToHex32
	pushf
	call	MemFree
	popf
done:
	.leave
	ret
InitFileReadInt32	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitFileWriteInt32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a 32-bit int to the init file

CALLED BY:	PrefColorSelectorSaveOptions

PASS:		ds:si - category
		es:di - key
		dx:ax - value

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitFileWriteInt32	proc near
	uses	cx,dx,es,di

textNum	local	UHTA_NULL_TERM_BUFFER_SIZE dup (TCHAR)

	.enter
	push	es, di
	lea	di, ss:[textNum]
	segmov	es, ss
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii
	pop	cx, dx
	call	InitFileWriteString	


	.leave
	ret
InitFileWriteInt32	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorResolveVariant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefColorSelectorClass object
		ds:di	- PrefColorSelectorClass instance data
		es	- dgroup

RETURN:		cx:dx 	- fptr to variant superclass (ColorSelectorClass)

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorResolveVariant method dynamic PrefColorSelectorClass, 
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
		cmp	cx, Pref_offset
		jne	gotoSuper

		mov	cx, segment ColorSelectorClass
		mov	dx, offset ColorSelectorClass
		ret

gotoSuper:
		mov	di, offset PrefColorSelectorClass
		GOTO	ObjCallSuperNoLock

PrefColorSelectorResolveVariant	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefColorSelectorHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefColorSelectorClass object
		ds:di	- PrefColorSelectorClass instance data
		es	- dgroup

RETURN:		carry - set if anything changed

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        eca	3/28/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefColorSelectorHasStateChanged method dynamic PrefColorSelectorClass, 
					MSG_PREF_HAS_STATE_CHANGED

		FALL_THRU	ColorSelectorHasStateChanged
PrefColorSelectorHasStateChanged	endm

ColorSelectorHasStateChanged	proc	far
		class	ColorSelectorClass
	;
	; See if anything has changed
	;
		mov	di, ds:[si]
		add	di, ds:[di].ColorSelector_offset
		test	ds:[di].CSI_states, mask ColorModifiedStates
		jz	done				;branch if no change
		stc					;carry <- state changed
done:
		ret
ColorSelectorHasStateChanged	endp
