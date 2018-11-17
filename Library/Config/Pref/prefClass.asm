COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefClass.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/12/92   	Initial version.

DESCRIPTION:
	

	$Id: prefClass.asm,v 1.1 97/04/04 17:50:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	PrefSetInitFileCategory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the .INI category for this object

PASS:		*ds:si - PrefClass object
		cx:dx - init file category (DBCS if DBCS)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefSetInitFileCategory	method	PrefClass, 
				MSG_PREF_SET_INIT_FILE_CATEGORY

DBCS <sbcsString	local	4*MAX_INITFILE_CATEGORY_LENGTH dup (char) >
	uses	ax, cx, dx
	.enter
		
if DBCS_PCGEOS
		call	PrinterNameToIniCat
	;
	; es:dx = string, cx = string SIZE w/null
	;
else
	;
	; Calculate the string size
	;
		mov	es, cx
		mov	di, dx
		call	LocalStringSize		; cx = size w/o null
		inc	cx			; cx = size w/ null
endif

EC <		cmp	cx, MAX_INITFILE_CATEGORY_LENGTH		>
EC <		ERROR_A INITFILE_CATEGORY_TOO_LONG			>

	;		
	; Now set the vardata
	;
		push	bp
		sub	sp, size AddVarDataParams
		mov	bp, sp
		mov	ss:[bp].AVDP_data.segment, es
		mov	ss:[bp].AVDP_data.offset, dx
		mov	ss:[bp].AVDP_dataSize, cx
		mov	ss:[bp].AVDP_dataType, ATTR_GEN_INIT_FILE_CATEGORY
		mov	dx, size AddVarDataParams
		mov	ax, MSG_META_ADD_VAR_DATA
		call	ObjCallInstanceNoLock
		add	sp, size AddVarDataParams
		pop	bp

		.leave
		ret
PrefSetInitFileCategory	endp

if DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrinterNameToIniCat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate a printer name (DBCS) to a .INI category name (SBCS)

CALLED BY:	PrefSetInitFileCategory()
PASS:		cx:dx	= Printer name
		ss:bp	= buffer for .INI category
		
RETURN:		es:dx	= ptr to .INI category
		cx	= size of .INI category string
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	If you change this, see also PrinterNameToIniCat() in:
		Library/Spool/Lib/libPrinter.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/8/94		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrinterNameToIniCat	proc	near
		uses	ax, di, ds, si
		.enter	inherit PrefSetInitFileCategory

		mov	ds, cx
		mov	si, dx			;ds:si <- ptr to DBCS string
		segmov	es, ss
		lea	di, ss:sbcsString	;es:di <- ptr to buffer
		mov	dx, di
		clr	cx			;cx <- # of bytes
	;
	; Convert the string into SBCS
	;
charLoop:
		LocalGetChar ax, dssi		;ax <- character
		LocalCmpChar ax, 0x80		;ASCII?
		jbe	gotChar			;branch if so
	;
	; For non-ASCII, stick in a couple of hex digits.  The digits aren't
	; in the correct order, but it doesn't matter too much as long as
	; they are consistent.
	;
		call	toHexDigits
DBCS <		mov	al, ah			;al <- high byte	>
DBCS <		call	toHexDigits					>
		jmp	charLoop

gotChar:
		stosb				;store SBCS character
		inc	cx			;cx <- one more byte
		tst	al
		jnz	charLoop

		.leave
		ret

toHexDigits:
		push	ax
	;
	; Second hex digit
	;
		push	ax
		andnf	al, 0x0f		;al <- low nibble
		call	convHexDigit
		pop	ax
	;
	; First hex digit
	;
		shr	al, 1
		shr	al, 1
		shr	al, 1
		shr	al, 1			;al <- high nibble
		call	convHexDigit

		pop	ax
		retn

convHexDigit:
		add	al, '0'
		cmp	al, '9'
		jbe	gotDig
		add	al, 'A'-'9'-1
gotDig:
		stosb
		inc	cx			;cx <- one more byte
		retn
PrinterNameToIniCat	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pref...ResolveVariant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= PrefClass object
		ds:di	= PrefClass instance data
		es	= Segment of PrefClass.

		cx 	= either Pref_offset of something we can't
			handle. 

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefInteractionResolveVariant	method	dynamic PrefInteractionClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment GenInteractionClass
	mov	dx, offset GenInteractionClass
	ret
PrefInteractionResolveVariant	endm

PrefItemGroupResolveVariant	method	dynamic PrefItemGroupClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment GenItemGroupClass
	mov	dx, offset GenItemGroupClass
	ret
PrefItemGroupResolveVariant	endm

PrefValueResolveVariant	method	dynamic PrefValueClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment GenValueClass
	mov	dx, offset GenValueClass
	ret
PrefValueResolveVariant	endm

PrefDynamicListResolveVariant	method	dynamic PrefDynamicListClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment GenDynamicListClass
	mov	dx, offset GenDynamicListClass
	ret
PrefDynamicListResolveVariant	endm

PrefPortItemResolveVariant	method	dynamic PrefPortItemClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment PrefStringItemClass
	mov	dx, offset PrefStringItemClass
	ret
PrefPortItemResolveVariant	endm

PrefTextResolveVariant	method	dynamic PrefTextClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment GenTextClass
	mov	dx, offset GenTextClass
	ret
PrefTextResolveVariant	endm

PrefBooleanGroupResolveVariant	method	dynamic PrefBooleanGroupClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS

	cmp	cx, Pref_offset
	jne	resolveCallSuper

	mov	cx, segment GenBooleanGroupClass
	mov	dx, offset GenBooleanGroupClass
	ret
resolveCallSuper	label	near

	; HACK HACK HACK!  Assume all the "Pref" classes described
	; above can call the superclass of PrefClass in this case.

	mov	di, offset PrefClass
	GOTO	ObjCallSuperNoLock

PrefBooleanGroupResolveVariant	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGetRebootString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return the optr of the "reboot" string for this object

PASS:		*ds:si	= PrefClass object
		ds:di	= PrefClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefGetRebootString	method	dynamic	PrefClass, 
					MSG_PREF_GET_REBOOT_STRING
	uses	bp
	.enter

	mov	ax, ATTR_PREF_REBOOT_STRING
	call	ObjVarFindData
	jnc	notFound
	movdw	cxdx, ds:[bx]
done:
	.leave
	ret

notFound:

if ERROR_CHECK
	mov	cx, segment PrefClass
	mov	dx, offset PrefClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	GenCallParent
	ERROR_NC	REBOOT_STRING_NOT_AVAILABLE
endif

	mov	ax, MSG_PREF_GET_REBOOT_STRING
	call	GenCallParent
	jmp	done
PrefGetRebootString	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGetRebootInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Return whether system needs rebooting or not

PASS:		*ds:si	= PrefClass object
		ds:di	= PrefClass instance data
		es	= dgroup

RETURN:		IF CHANGED, and REBOOT_IF_CHANGED flag set
			^lcx:dx - string to put up
		ELSE
			cx - 0

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/26/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefGetRebootInfo	method	dynamic	PrefClass, 
					MSG_PREF_GET_REBOOT_INFO

		uses	ax,bp
		.enter

		test	ds:[di].PI_attrs, mask PA_REBOOT_IF_CHANGED
		jz	noReboot

	;
	; If the object isn't usable, and the PA_SAVE_IF_USABLE flag
	; is set, then always return CX = 0
	;
		test	ds:[di].PI_attrs, mask PA_SAVE_IF_USABLE
		jz	afterUsableCheck

		clr	cx	; use optimized form, if possible (?)
		mov	ax, MSG_GEN_CHECK_IF_FULLY_USABLE
		call	ObjCallInstanceNoLock
		jnc	noReboot
		
afterUsableCheck:
		mov	ax, MSG_PREF_HAS_STATE_CHANGED
		call	ObjCallInstanceNoLock
		jnc	noReboot

		mov	ax, MSG_PREF_GET_REBOOT_STRING
		call	ObjCallInstanceNoLock
done:	
		.leave
		ret

noReboot:
		xor	cx, cx		; clear the carry
		jmp	done
		
PrefGetRebootInfo	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	determine whether to make this object usable or not,
		and whether to send MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= PrefClass object
		ds:di	= PrefClass instance data
		es	= dgroup
		cx	- PrefMgrFeatures
		dx	- UIInterfaceLevel

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefInit	method	dynamic	PrefClass, 
					MSG_PREF_INIT
	.enter

	;
	; First see if this object is USABLE based on the variable
	; data.  -- vardata min level must be <= passed level
	;

	mov	ax, ATTR_PREF_MIN_LEVEL
	call	ObjVarFindData
	jnc	afterMin
	mov	ax, ds:[bx]
	cmp	ax, dx
	jg	notUsable

	;
	; Vardata MAX level must be >= passed level
	;

afterMin:
	mov	ax, ATTR_PREF_MAX_LEVEL
	call	ObjVarFindData
	jnc	afterMax
	mov	ax, ds:[bx]
	cmp	ax, dx
	jl	notUsable

afterMax:
	;
	; all REQUIRED features must be ON (passed features, when
	; anded with REQIRED, must equal REQUIRED) 
	;

	mov	ax, ATTR_PREF_REQUIRED_FEATURES
	call	ObjVarFindData
	jnc	afterRequired
	mov	ax, ds:[bx]
	mov	bx, cx
	and	bx, ax
	cmp	bx, ax
	jne	notUsable

afterRequired:

	;
	; No PROHIBITED features should be on
	;
	mov	ax, ATTR_PREF_PROHIBITED_FEATURES
	call	ObjVarFindData
	jnc	done
	mov	ax, ds:[bx]
	test	ax, cx
	jnz	notUsable

	;
	; XXX: Maybe we should set the object USABLE here.  (probably
	; not -- too slow).
	;

done:
	.leave
	ret

notUsable:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
	jmp	done

PrefInit	endm

