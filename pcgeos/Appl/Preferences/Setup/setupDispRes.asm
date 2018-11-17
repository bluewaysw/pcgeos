COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphical Setup -- Display-resolution support
FILE:		setupDispRes.asm

AUTHOR:		Adam de Boor, Oct  9, 1990

ROUTINES:
	Name			Description
	----			-----------
	SetupDeviceListClass	Subclass of PrefDeviceListClass
	SetupTextDisplayClass	Subclass of GenTextDisplayClass

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/9/90		Initial revision


DESCRIPTION:
	Object classes to alter appearance based on the display resolution.
		

	$Id: setupDispRes.asm,v 1.1 97/04/04 16:27:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGetDisplayType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the DisplayType variable for the default video driver.

CALLED BY:	SDLSpecBuild, STDSpecBuild
PASS:		es	= dgroup
RETURN:		ah	= DisplayType
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGetDisplayType proc	near	uses ds, si
		.enter
		lds	si, es:[defaultVideo]
		mov	ah, ds:[si].VDI_displayType
		.leave
		ret
SetupGetDisplayType endp

;==============================================================================
;
;				SetupDeviceList
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SDLSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we're running on a low-res display, reduce the number of
		kids displayed at once.

CALLED BY:	MSG_SPEC_BUILD

PASS:		*ds:si	= list
		ds:bx	= SetupDeviceListBase

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SDLSpecBuild	method	SetupDeviceListClass, MSG_SPEC_BUILD

		uses	ax,cx,dx,bp

		.enter

		push	si

		call	SetupGetDisplayType
		mov	al, ah
		andnf	ah, mask DT_DISP_ASPECT_RATIO
		cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
		jne	checkHuge
		mov	cx, SDL_NUM_LOWRES_KIDS


	;
	; Fetch the fixed size hint.  It sure would be nice if there
	; were a data structure describing this hint!!!!
	;

setSize:

		mov	ax, HINT_FIXED_SIZE
		call	ObjVarFindData
		jnc	passItOn

	;
	; Make sure there's 6 bytes of vardata to work with here...
	;

EC <		VarDataSizePtr	ds, bx, ax	>
EC <		cmp	ax, 6			>
EC <		ERROR_B	-1			>

CheckHack <offset SH_DATA eq 0>

		and	{word} ds:[bx][2], not mask SH_DATA
		or	{word} ds:[bx][2], cx
		mov	{word} ds:[bx][4], cx
		jmp	passItOn


checkHuge:
		mov	cx, SDL_NUM_HIGHRES_KIDS
		andnf	al, mask DT_DISP_SIZE
		cmp	al, DS_HUGE shl offset DT_DISP_SIZE
		je	setSize

passItOn:

	;
	; Send ourselves a MSG_PREF_INIT (this will read the array of
	; drivers, etc)
	;

		pop	si
		mov	ax, MSG_PREF_INIT
		call	ObjCallInstanceNoLock

	;
	; Send ourselves a MSG_META_LOAD_OPTIONS
	;
		mov	ax, MSG_META_LOAD_OPTIONS
		call	ObjCallInstanceNoLock

		.leave

		mov	di, offset SetupDeviceListClass
		GOTO	ObjCallSuperNoLock
SDLSpecBuild	endp

;==============================================================================
;
;			SetupTextDisplayClass
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Fetch the text and replace the specified parameter.

PASS:		*ds:si	- SetupTextDisplayClass object
		ds:di	- SetupTextDisplayClass instance data
		es	- dgroup
		ss:bp	- GenOptionsParams

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

STDLoadOptions	method	dynamic	SetupTextDisplayClass, 
					MSG_GEN_LOAD_OPTIONS

		push	ds, si
		segmov	ds, ss
		lea	si, ss:[bp].GOP_category
		mov	cx, ss
		lea	dx, ss:[bp].GOP_key
		mov	bp, INITFILE_INTACT_CHARS
		call	InitFileReadString		;bx = buffer
		pop	ds, si
		jc	checkDefault

		call	MemLock
		mov	cx, ax

		clr	dx
		mov	ax, MSG_STD_REPLACE_PARAM
		call	ObjCallInstanceNoLock

		call	MemFree
done:
		ret

checkDefault:
		mov	ax, ATTR_SETUP_TEXT_DEFAULT_PARAM
		call	ObjVarFindData
		jnc	done

		mov	di, ds:[bx].chunk
		mov	bx, ds:[bx].handle
		call	MemLock
		mov	es, ax
		mov	cx, ax
		mov	dx, es:[di]
		mov	ax, MSG_STD_REPLACE_PARAM
		call	ObjCallInstanceNoLock
		call	MemUnlock
		jmp	done
		
STDLoadOptions	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to the above, but change the default style of
		the object to use Berkeley 9 point text instead.

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= SetupTextDisplay object
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDSpecBuild	method	SetupTextDisplayClass, MSG_SPEC_BUILD

		uses	ax, cx, dx, bp
		.enter
		mov	ax, MSG_META_LOAD_OPTIONS
		call	ObjCallInstanceNoLock
		
		call	SetupGetDisplayType
		mov	al, ah
		andnf	ah, mask DT_DISP_ASPECT_RATIO
		
		cmp	ah, DAR_VERY_SQUISHED shl offset DT_DISP_ASPECT_RATIO
NPZ <		jne	checkHuge					>
PZ <		jne	passItOn					>

		;
		; Switch to 9-point Berkeley instead.
		; 
		mov	dx, SETUP_LOW_RES_POINT_SIZE
sendMethod:
		;
		; Use the stack for the param struct
		;
		sub	sp, size VisTextSetPointSizeParams
		mov	bp, sp
		clrdw	ss:[bp].VTSPSP_range.VTR_start, 0
		movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
		mov	ss:[bp].VTSPSP_pointSize.WWF_int, dx
		mov	ss:[bp].VTSPSP_pointSize.WWF_frac, 0
		mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
		mov	dx, size VisTextSetPointSizeParams
		call	ObjCallInstanceNoLock
		;
		; restore the stack
		;
		add	sp, size VisTextSetPointSizeParams

if not PZ_PCGEOS
		jmp	passItOn
checkHuge:
		mov	dx, SETUP_HIGH_RES_POINT_SIZE
		andnf	al, mask DT_DISP_SIZE
		cmp	al, DS_LARGE shl offset DT_DISP_SIZE
		je	sendMethod
endif
passItOn:
		.leave
		mov	di, offset SetupTextDisplayClass
		GOTO	ObjCallSuperNoLock 
STDSpecBuild	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDReplaceParam
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the FIRST instance of \x01 in the text object with the
		passed null-terminated string.

CALLED BY:	MSG_STD_REPLACE_PARAM
PASS:		*ds:si	= SetupTextDisplay object
		cx:dx	= fptr to null-terminated string

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/90	Initial version
	chrisb	1/93		modified for 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDReplaceParam	method	SetupTextDisplayClass, MSG_STD_REPLACE_PARAM

		.enter

	push	ds, si			; object
	push	cx, dx			; string

	mov	es, cx
	mov	di, dx
	call	LocalStringLength
	mov	bp, cx
	inc	bp

	;
	; Allocate a block big enough to hold the replacement string,
	; the SearchReplaceStruct, and the (2 byte) search string.
	;

	mov	ax, bp
DBCS <	shl	ax, 1			; # chars -> # bytes		>
SBCS <	add	ax, size SearchReplaceStruct+2				>
DBCS <	add	ax, size SearchReplaceStruct+2*(size wchar)		>
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax
	
	;
	; Fill in the SearchReplaceStruct
	;


	mov	es:[SRS_searchSize], 2
	mov	es:[SRS_replaceSize], bp
	clr	es:[SRS_params]
	clrdw	es:[SRS_replyObject]
	clr	es:[SRS_replyMsg]

	;
	; Store the search string
	;

	mov	di, offset SRS_searchString
	mov	ax, 1
	stosw
DBCS <	mov	ax, 0							>
DBCS <	stosw								>

	;
	; Store the replace string
	;

	mov	cx, bp
	pop	ds, si			; string
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>

	pop	ds, si			; instance data


	;
	; Make the text editable, so that the REPLACE message will
	; actually do something
	;

	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	cx, mask VTS_EDITABLE
	call	ObjCallInstanceNoLock

	mov	dx, bx			; handle of block.  Will be
					; freed by VisTextClass.
	clr	cx
	mov	ax, MSG_REPLACE_ALL_OCCURRENCES
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	cx, (mask VTS_EDITABLE shl 8)
	call	ObjCallInstanceNoLock

	.leave
	ret
STDReplaceParam	endp


