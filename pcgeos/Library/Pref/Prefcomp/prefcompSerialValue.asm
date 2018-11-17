COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		prefcompSerialValue.asm

AUTHOR:		Adam de Boor, Jan 19, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/19/93		Initial revision


DESCRIPTION:
	Implementation of PrefCompSerialValueClass, a subclass of PrefValue
	used to adjust the interrupt level of a serial port.
		

	$Id: prefcompSerialValue.asm,v 1.1 97/04/05 01:33:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefCompCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PCSVSetSpecialValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the PCSVS_SPECIAL_VALUE field to that passed

CALLED BY:	(INTERNAL)
PASS:		al	= PrefCompSerialValueSpecialValue to set
		*ds:si	= PrefCompSerialValue object
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PCSVSetSpecialValue proc	near
		class	PrefCompSerialValueClass
		uses	cx, di, dx, es
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].PrefCompSerialValue_offset
		mov	cl, offset PCSVS_SPECIAL_VALUE
		mov	ah, al
		shl	al, cl
			CheckHack <offset PCSVS_SPECIAL_VALUE eq 6 and \
				   width  PCSVS_SPECIAL_VALUE eq 2>
		andnf	ds:[di].PCSVI_state, not mask PCSVS_SPECIAL_VALUE
		ornf	ds:[di].PCSVI_state, al
		tst	ah
		jnz	notifySpui
done:
		.leave
		ret
notifySpui:
	;
	; Force a visual update, in case we're not coming up for the first time.
	; This ugly piece o' code simply sends the MSG_GEN_VALUE_SET_VALUE to
	; the specific UI, setting the thing to the current value. It's what
	; Chris suggested I use...
	; 
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		movwwf	dxcx, ds:[di].GVLI_value
		segmov	es, <segment GenValueClass>, di
		mov	di, offset GenValueClass
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjCallSuperNoLock
		jmp	done
PCSVSetSpecialValue endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the interrupt level for the port from the serial
		driver and set our state accordingly.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= PrefCompSerialValue object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	original value set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueLoadOptions method dynamic PrefCompSerialValueClass, 
			       MSG_META_LOAD_OPTIONS
		.enter
	;
	; Load the value from the .ini file, in case driver has no clue.
	; 
		mov	di, offset PrefCompSerialValueClass
		CallSuper	MSG_META_LOAD_OPTIONS
	;
	; Set the maximum interrupt level based on whether there's a second
	; interrupt controller in the machine. Must do this before getting
	; the port's interrupt level so if it's > 7, it doesn't get truncated
	; by the max being only 7...
	; 
		call	SysGetConfig
		test	al, mask SCF_2ND_IC
		mov	dx, 7
		jz	haveMax
		mov	dx, 15
haveMax:
		clr	cx		; no fraction
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	ObjCallInstanceNoLock
		
	;
	; Now see if the driver has an opinion.
	; 
		push	ds, si
		mov	bx, handle serial
		call	GeodeInfoDriver
		segmov	es, ds
		mov	bp, si
		pop	ds, si
		
		mov	di, ds:[si]
		add	di, ds:[di].PrefCompSerialValue_offset
		mov	bx, ds:[di].PCSVI_portNum
		mov	di, DR_SERIAL_STAT_PORT
		call	es:[bp].DIS_strategy
		jc	off
		
		cmp	al, -1
		je	indeterminate
	;
	; Value is known. Make sure we know it's known, then set our value
	; according to what the driver thinks, as it may be different from
	; what the user thought.
	; 
		cbw
		mov_tr	cx, ax
		mov	al, PCSVSV_KNOWN
		call	PCSVSetSpecialValue

		clr	bp		; not indeterminate
		mov	ax, MSG_PREF_VALUE_SET_ORIGINAL_VALUE
		call	ObjCallInstanceNoLock
done:		
		mov	di, ds:[si]
		add	di, ds:[di].PrefCompSerialValue_offset
		mov	al, ds:[di].PCSVI_state
		mov	ah, al
		andnf	ax, ((not mask PCSVS_ORIG_SPECIAL_VALUE) and 0xff) or \
				(mask PCSVS_SPECIAL_VALUE shl 8)
			CheckHack <offset PCSVS_SPECIAL_VALUE - \
				   offset PCSVS_ORIG_SPECIAL_VALUE eq 2>
		shr	ah
		shr	ah
		or	al, ah
		mov	ds:[di].PCSVI_state, al
		.leave
		ret
off:
	;
	; Make sure we know the thing is off. We leave the value as fetched
	; from the .ini file.
	; 
		mov	al, PCSVSV_OFF
		call	PCSVSetSpecialValue
forceUpdate:
		jmp	done

indeterminate:
	;
	; Make sure we know we don't know. We leave the value as fetched from
	; the .ini file.
	; 
		mov	al, PCSVSV_UNKNOWN
		call	PCSVSetSpecialValue
		jmp	forceUpdate
PrefCompSerialValueLoadOptions endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueGetValueText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the textual representation of a value.

CALLED BY:	MSG_GEN_VALUE_GET_VALUE_TEXT
PASS:		*ds:si	= PrefCompSerialValue object
		cx:dx	= buffer in which to place the result.
		bp	= GenValueType
RETURN:		cx:dx	= filled
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueGetValueText method dynamic PrefCompSerialValueClass,
					MSG_GEN_VALUE_GET_VALUE_TEXT
		cmp	bp, GVT_LONG
		je	returnOffString	; we assume the "Off" string is longer
					;  than anything else we can produce
		cmp	bp, GVT_VALUE
		jne	passItUp	; if not current value, just let our
					;  superclass handle it
		test	ds:[di].PCSVI_state, mask PCSVS_SPECIAL_VALUE
		jz	passItUp	; if want current value and port isn't
					;  in special state, let superclass
					;  handle it
		CheckHack <PCSVSV_UNKNOWN eq 2 and \
			offset PCSVS_SPECIAL_VALUE eq 6>
		js	isUnknown
returnOffString:
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		assume	ds:Strings
		mov	si, ds:[SerialValueOffString]
		movdw	esdi, cxdx
		ChunkSizePtr	ds, si, cx
		rep	movsb
done:
		mov	cx, es
		call	MemUnlock
		assume	ds:nothing
		ret
passItUp:
		mov	di, offset PrefCompSerialValueClass
		GOTO	ObjCallSuperNoLock

isUnknown:
	;
	; Get the normal text for the thing.
	; 
		mov	di, offset PrefCompSerialValueClass
		call	ObjCallSuperNoLock
	;
	; Now append the SerialValueUnknownString to that.
	; 
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax
		assume	ds:Strings
		mov	si, ds:[SerialValueUnknownString]
		movdw	esdi, cxdx
		clr	ax
		mov	cx, -1
		LocalFindChar		; find null byte
		LocalPrevChar	esdi	; point back to null
		ChunkSizePtr	ds, si, cx
		rep	movsb
		jmp	done
		assume	ds:nothing
PrefCompSerialValueGetValueText endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueGetTextFilter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the set of characters we allow the user to type
		into us.

CALLED BY:	MSG_GEN_VALUE_GET_TEXT_FILTER
PASS:		*ds:si	= PrefCompSerialValue object
RETURN:		al	= VisTextFilters
DESTROYED:	ah, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueGetTextFilter method dynamic PrefCompSerialValueClass, 
				 	MSG_GEN_VALUE_GET_TEXT_FILTER
		.enter
		mov	al, mask VTF_NO_SPACES or \
			    mask VTF_NO_TABS or \
			    VTFC_ALPHA_NUMERIC shl offset VTF_FILTER_CLASS
		.leave
		ret
PrefCompSerialValueGetTextFilter endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueSetValueFromText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the value for the range from the given text.

CALLED BY:	MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
PASS:		*ds:si	PrefCompSerialValue object
		cx:dx	= pointer to text
		bp	= GenValueType
RETURN:		carry set if value instance data changed.
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueSetValueFromText method dynamic PrefCompSerialValueClass, 
				    	MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
		cmp	bp, GVT_VALUE
		jne	passItUp
		
	;
	; Compare passed string with the one indicating the port is off.
	; 
		mov	bx, handle Strings
		push	ds, si, es
		call	MemLock
		mov	es, ax
		assume	es:Strings
		mov	di, es:[SerialValueOffString]	; es:di <- string2
		movdw	dssi, cxdx		; ds:si <- string1
		clr	cx			; null terminated
		call	LocalCmpStringsNoCase
		mov	cx, ds			; restore cx for possible super-
						;  class call
		pop	ds, si, es
		call	MemUnlock
		assume	es:nothing
		jne	clearOffPassItUp
	;
	; Set the PCSVS_OFF flag, mark ourselves dirty and return carry set to
	; indicate we changed the instance data.
	; 
		mov	al, PCSVSV_OFF
		call	PCSVSetSpecialValue
		call	ObjMarkDirty
doneModified:
		stc
done:
		ret

clearOffPassItUp:
		mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_TEXT
		mov	di, offset PrefCompSerialValueClass
		call	ObjCallSuperNoLock
		jnc	done
		mov	al, PCSVSV_KNOWN
		call	PCSVSetSpecialValue
		jmp	doneModified
passItUp:
		mov	di, offset PrefCompSerialValueClass
		GOTO	ObjCallSuperNoLock
PrefCompSerialValueSetValueFromText endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interception of increment message to switch the port OFF
		if appropriate.

CALLED BY:	MSG_GEN_VALUE_INCREMENT
PASS:		*ds:si	= PrefCompSerialValue object
		ds:di	= PrefCompSerialValueInstance
RETURN:		carry set if value instance data changed
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueIncrement method dynamic PrefCompSerialValueClass, 
			    			MSG_GEN_VALUE_INCREMENT
		test	ds:[di].PCSVI_state, mask PCSVS_SPECIAL_VALUE
		js	wasUnknown
		jz	checkForSwitchOff
	;
	; Port is now off. Change to minimum.
	; 
		mov	al, PCSVSV_KNOWN
		call	PCSVSetSpecialValue
		mov	di, ds:[si]
		add	di, ds:[di].GenValue_offset

		movwwf	dxcx, ds:[di].GVLI_value	; use default port
		cmp	dx, PCSV_HACK_OFF_VALUE		;  value if set
		jne	doneModified

		mov	dx, PCSV_ACTUAL_MIN
		clr	cx
doneModified:
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp
		call	ObjCallInstanceNoLock
		stc
		ret

wasUnknown:
	;
	; State was unknown, but user is changing it, so switch to known, on
	; the assumption user's not an ass (a dangerous assumption, at best)
	; 
		mov	al, PCSVSV_KNOWN
		call	PCSVSetSpecialValue

checkForSwitchOff:
	;
	; If current value is maximum, this means we should cycle back to off
	; 
		mov	di, ds:[si]
		add	di, ds:[di].GenValue_offset
		mov	ax, ds:[di].GVLI_maximum.WWF_int
		cmp	ds:[di].GVLI_value.WWF_int, ax
		je	switchToOff

		mov	ax, MSG_GEN_VALUE_INCREMENT
		mov	di, offset PrefCompSerialValueClass
		GOTO	ObjCallSuperNoLock

switchToOff:
		mov	al, PCSVSV_OFF
		call	PCSVSetSpecialValue

		mov	dx, PCSV_HACK_OFF_VALUE
		clr	cx
		jmp	doneModified
PrefCompSerialValueIncrement		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueDecrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Interception of decrement message to switch the port OFF
		if appropriate.

CALLED BY:	MSG_GEN_VALUE_DECREMENT
PASS:		*ds:si	= PrefCompSerialValue object
		ds:di	= PrefCompSerialValueInstance
RETURN:		carry set if value instance data changed
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueDecrement method dynamic PrefCompSerialValueClass, 
			    			MSG_GEN_VALUE_DECREMENT
		test	ds:[di].PCSVI_state, mask PCSVS_SPECIAL_VALUE
		js	wasUnknown
		jz	checkForSwitchOff
	;
	; Port is now off. Change to maximum.
	; 
		mov	al, PCSVSV_KNOWN
		call	PCSVSetSpecialValue
		mov	di, ds:[si]
		add	di, ds:[di].GenValue_offset
		movwwf	dxcx, ds:[di].GVLI_value
		cmp	dx, PCSV_HACK_OFF_VALUE	; use default value for port
		jne	doneModified		;  if set.

		movwwf	dxcx, ds:[di].GVLI_maximum
doneModified:
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp
		call	ObjCallInstanceNoLock
		stc
		ret

wasUnknown:
	;
	; State was unknown, but user is changing it, so switch to known, on
	; the assumption user's not an ass (a dangerous assumption, at best)
	; 
		mov	al, PCSVSV_KNOWN
		call	PCSVSetSpecialValue

checkForSwitchOff:
	;
	; If current value is minimum, this means we should cycle back to off
	; 
		mov	di, ds:[si]
		add	di, ds:[di].GenValue_offset
		cmp	ds:[di].GVLI_value.WWF_int, PCSV_ACTUAL_MIN
		je	switchToOff
passItUp:
		mov	ax, MSG_GEN_VALUE_DECREMENT
		mov	di, offset PrefCompSerialValueClass
		GOTO	ObjCallSuperNoLock

switchToOff:
		mov	al, PCSVSV_OFF
		call	PCSVSetSpecialValue
		jmp	passItUp
PrefCompSerialValueDecrement		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset value to original value stored.

CALLED BY:	MSG_GEN_RESET
PASS:		*ds:si	= PrefCompSerialValue object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueReset method dynamic PrefCompSerialValueClass, MSG_GEN_RESET
	;
	; Take care of our special state first.
	; 
		mov	cl, ds:[di].PCSVI_state
		mov	ch, cl
		andnf	cx, (mask PCSVS_ORIG_SPECIAL_VALUE shl 8) or \
				((not mask PCSVS_SPECIAL_VALUE) and 0xff)
			CheckHack <offset PCSVS_SPECIAL_VALUE - \
				   offset PCSVS_ORIG_SPECIAL_VALUE eq 2>
		shl	ch
		shl	ch
		or	cl, ch
		mov	ds:[di].PCSVI_state, cl
	;
	; Then let our superclass revert its state.
	; 
		mov	di, offset PrefCompSerialValueClass
		GOTO	ObjCallSuperNoLock
PrefCompSerialValueReset endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save our value to the .ini file and communicate it to the
		serial driver as well.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= PrefCompSerialValue object
		ds:di	= PrefCompSerialValueInstance
		ss:bp	= GenOptionsParams
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueSaveOptions method dynamic PrefCompSerialValueClass, 
				MSG_GEN_SAVE_OPTIONS
		.enter
		test	ds:[di].PCSVI_state, mask PCSVS_SPECIAL_VALUE
		jz	getValue
		mov	cx, -1		; assume shut off
		jns	haveValue

		; if unknown, don't touch it
done:
		.leave
		ret

getValue:
		add	bx, ds:[bx].GenValue_offset
		mov	cx, ds:[bx].GVLI_value.WWF_int
haveValue:
	;
	; First verify things with the serial driver.
	; 
		push	bp, ds, di, cx, si
		mov	ax, ds:[di].PCSVI_portBase
		mov	bx, handle serial
		call	GeodeInfoDriver
		mov	bx, -1		; Not PCMCIA, we assume
		mov	di, DR_SERIAL_DEFINE_PORT
		call	ds:[si].DIS_strategy
		pop	bp, ds, di, cx, si
		jc	error
	;
	; Seems ok. Write the value to the ini file.
	; 
		mov_tr	ax, cx		; save irq #
		segmov	ds, ss, cx	; ds, cx <- ss
		lea	si, ss:[bp].GOP_category
		lea	dx, ss:[bp].GOP_key
		mov_tr	bp, ax		; bp <- value to write
		call	InitFileWriteInteger
		jmp	done

error:
		sub	sp, size StandardDialogParams
		mov	bp, sp
		mov	ss:[bp].SDP_customFlags,CustomDialogBoxFlags <
			0,			; CDBF_SYSTEM_MODAL
			CDT_ERROR,		; CDBF_TYPE
			GIT_NOTIFICATION,	; CDBF_RESPONSE_TYPE
			0			; CDBF_DESTRUCTIVE_ACTION
		>
		mov	di, offset SerialNoSuchDevice
		cmp	ax, STREAM_NO_DEVICE
		je	haveErrString
		mov	di, offset SerialDeviceInUse
EC <		cmp	ax, STREAM_DEVICE_IN_USE			>
EC <		WARNING_NE	UNHANDLED_STREAM_ERROR_CODE_FROM_DEFINE_PORT>
haveErrString:
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax
		mov	ss:[bp].SDP_customString.segment, ax
		mov	di, es:[di]
		mov	ss:[bp].SDP_customString.offset, di
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	di, ds:[di].GI_visMoniker
EC <		tst	di						>
EC <		ERROR_Z	NEED_MONIKER_FOR_ERROR_MESSAGE			>
		mov	di, ds:[di]
		add	di, offset VM_data + offset VMT_text
		movdw	ss:[bp].SDP_stringArg1, dsdi
		clr	ax
		mov	ss:[bp].SDP_helpContext.segment, ax
		mov	ss:[bp].SDP_customTriggers.segment, ax
		mov	ss:[bp].SDP_stringArg2.segment, ax
		call	UserStandardDialog
		jmp	done
PrefCompSerialValueSaveOptions endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefCompSerialValueHasStateChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the state of the object has changed, from our
		perspective.

CALLED BY:	MSG_PREF_HAS_STATE_CHANGED
PASS:		*ds:si	= PrefCompSerialValue object
		ds:di	= PrefCompSerialValueInstance
RETURN:		carry set if anything changed
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefCompSerialValueHasStateChanged method dynamic PrefCompSerialValueClass, 
				MSG_PREF_HAS_STATE_CHANGED
		mov	cl, ds:[di].PCSVI_state
		mov	ch, cl
		andnf	cx, mask PCSVS_ORIG_SPECIAL_VALUE or \
			(mask PCSVS_SPECIAL_VALUE shl 8)
			CheckHack <offset PCSVS_SPECIAL_VALUE - \
				   offset PCSVS_ORIG_SPECIAL_VALUE eq 2>
		shl	cl
		shl	cl
		cmp	cl, ch
		je	passItUp
		stc
		ret
passItUp:
		mov	di, offset PrefCompSerialValueClass
		GOTO	ObjCallSuperNoLock
PrefCompSerialValueHasStateChanged endm
PrefCompCode	ends
