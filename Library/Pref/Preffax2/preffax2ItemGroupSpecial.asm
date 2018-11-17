COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Tiramisu
MODULE:		Preferences
FILE:		preffax2ItemGroupSpecial.asm

AUTHOR:		Peter Trinh, Mar 15, 1995

ROUTINES:
	Name			Description
	----			-----------

PrefItemGroupSpecialSaveOptions	Will save options to two seperate ini keys.
PIGSCopyToGOP			Copies a string to GenOptionsParams.
PIGSWriteClassInfo		Write class info of chosen fax class.
PIGSWriteT30Response		Write T30Response struct to faxin and faxout.
PIGSWriteFaxDriverName		Writes driver name to both faxin and faxout.
PrefItemGroupSpecialCheckPort	Checks com port for viable faxmodem.
PIGSCheckIfViableInputModem	Checks for viable input-faxmodem.
PIGSCheckIfViableOutputModem	Checks for viable output-faxmodem.
PIGSLoadInputDriver		Loads input fax driver.
PIGSLoadOutputDriver		Loads output fax driver.
PIGSInstantiateWarningDB	Instantiates a warning DB.
PIGSPopUpRetryDialogBox		Displays a "retry" dialog box

ECPIGSVerifyCategories		Verifies categories str matches fax class


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95   	Initial revision


DESCRIPTION:
	Contains methods for the PrefItemGroupSpecial class.
		

	$Id: preffax2ItemGroupSpecial.asm,v 1.1 97/04/05 01:43:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefFaxCode	segment resource;

;
; Constants
;

if ERROR_CHECK

class1InputDriverName	char "EC Class 1 Fax Input Driver",0
class2InputDriverName	char "EC Class 2 Fax Input Driver",0
class1OutputDriverName	char "EC Class 1 Fax Output Driver",0
class2OutputDriverName	char "EC Class 2 Fax Output Driver",0

else

class1InputDriverName	char "Class 1 Fax Input Driver",0
class2InputDriverName	char "Class 2 Fax Input Driver",0
class1OutputDriverName	char "Class 1 Fax Output Driver",0
class2OutputDriverName	char "Class 2 Fax Output Driver",0

endif

;
; For now, class 1 and class 2 are identical.
;

class1Capabilities	T30Response <
				FVR_NORMAL,
				FBPS_14400,
				FPW_215,
				FPL_297,
				FDCF_2D_MODIFIED_READ,
				FEC_DISABLE_ECM,
				FBFT_DISABLE_XFER,
				FSTPL_ZERO
			>
.assert	size(class1Capabilities) eq size(T30Response)

class2Capabilities	T30Response <
				FVR_NORMAL,
				FBPS_14400,
				FPW_215,
				FPL_297,
				FDCF_2D_MODIFIED_READ,
				FEC_DISABLE_ECM,
				FBFT_DISABLE_XFER,
				FSTPL_ZERO
			>
.assert	size(class1Capabilities) eq size(T30Response)
				
faxinCapabilitiesStr	char FAX_INI_FAXIN_CAPABILITIES_KEY, 0
faxoutCapabilitiesStr	char FAX_INI_FAXOUT_CAPABILITIES_KEY, 0
faxinDriverNameStr	char FAX_INI_FAXIN_DRIVER_KEY, 0
faxoutDriverNameStr	char FAX_INI_FAXOUT_DRIVER_KEY, 0

if ERROR_CHECK

EC_faxinStr	char FAX_INI_FAXIN_CATEGORY,0
EC_faxoutStr 	char FAX_INI_FAXOUT_CATEGORY,0

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSpecialSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save options to both ini keys.

CALLED BY:	MSG_GEN_SAVE_OPTIONS
PASS:		*ds:si	= PrefItemGroupSpecialClass object
		ds:di	= PrefItemGroupSpecialClass instance data
		ds:bx	= PrefItemGroupSpecialClass object (same as *ds:si)
		es 	= segment of PrefItemGroupSpecialClass
		ax	= message #

		ss:bp	= GenOptionsParams

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupSpecialSaveOptions	method dynamic PrefItemGroupSpecialClass, 
					MSG_GEN_SAVE_OPTIONS
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	push	bp				; ss:bp - GenOptionsParams
	call	ObjCallInstanceNoLock
	pop	bp				; ss:bp - GenOptionsParams
	jc	done

	DerefInstanceDataDSDI	PrefItemGroupSpecial_offset
	mov	ax, ds:[di].PIGSI_categoryOne
	call	PIGSCopyToGOP
	mov	di, offset PrefItemGroupSpecialClass
	mov	ax, MSG_GEN_SAVE_OPTIONS
	call	ObjCallSuperNoLock

	DerefInstanceDataDSDI	PrefItemGroupSpecial_offset
	mov	ax, ds:[di].PIGSI_categoryTwo
	call	PIGSCopyToGOP
	mov	di, offset PrefItemGroupSpecialClass
	mov	ax, MSG_GEN_SAVE_OPTIONS
	call	ObjCallSuperNoLock

	DerefInstanceDataDSDI	PrefItemGroupSpecial_offset
	test	ds:[di].PIGSI_itemGroupSpecialflags, mask PIGSF_FAX_CLASS
	jz	done

	call	PIGSWriteClassInfo
done:
	.leave
	ret
PrefItemGroupSpecialSaveOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSCopyToGOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the lptr to the src string, will copy it to the
		GenOptionsParams category buffer.

CALLED BY:	PrefItemGroupSpecialSaveOptions

PASS:		*ds:ax	- src string
		ss:bp	- GenOptionsParams

RETURN:		copied strings
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSCopyToGOP	proc	near
	uses	ax,si,di,es
	.enter

	Assert	chunk	ax, ds

	mov	si, ax				; lptr to src str
	mov	si, ds:[si]			; ds:si - ptr to src str
	segmov	es, ss, di
	lea	di, ss:[bp].GOP_category	; es:di - ptr to dst buf
	LocalCopyString	

	.leave
	ret
PIGSCopyToGOP	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSWriteClassInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a hardcoded class information to the
		designated key and category.

CALLED BY:	PrefItemGroupSpecialSaveOptions

PASS:		*ds:si	- PrefItemGroupSpecialClass object
		ss:bp	- GenOptionsParams

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

	Driver name and capabilities written out to the ini file.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSWriteClassInfo	proc	near
	class	PrefItemGroupSpecialClass
	uses	ax,cx,dx,di,bp,es
	.enter

	Assert	objectPtr	dssi, PrefItemGroupSpecialClass

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	push	bp					; GenOptionsParams
	call	ObjCallInstanceNoLock			; ax - item selected
	pop	bp					; GenOptionsParams
	jc	done					; none selected

EC <	call	ECPIGSVerifyCategories		>

	cmp	ax, FAX_CLASS_1
	jne	writeClass2Info

	;
	; Write out class 1 capabilities
	;
	segmov	es, cs, di
	mov	di, offset class1Capabilities
	call	PIGSWriteT30Response
	;
	; Write out driver name
	;
	mov	di, offset class1InputDriverName
	mov	bp, offset class1OutputDriverName
	call	PIGSWriteFaxDriverName
done:
	.leave
	ret

writeClass2Info:
	;
	; Write out class 2 capabilities
	;
	segmov	es, cs, di
	mov	di, offset class2Capabilities
	call	PIGSWriteT30Response
	;
	; Write out driver name
	;
	mov	di, offset class2InputDriverName
	mov	bp, offset class2OutputDriverName
	call	PIGSWriteFaxDriverName
	jmp	done

PIGSWriteClassInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSWriteT30Response
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will write out the given capabilities to the
		capabilities key of both faxin and faxout.

CALLED BY:	PIGSWriteClassInfo

PASS:		*ds:si	- PrefItemGroupSpecialClass object
		es:di	- offset of T30Response structure

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSWriteT30Response	proc	near
	class	PrefItemGroupSpecialClass
	uses	cx,dx,bx,si
	.enter

	Assert	objectPtr	dssi, PrefItemGroupSpecialClass
	Assert	fptr		esdi

	push	si					; self lptr
	DerefInstanceDataDSBX	PrefItemGroupSpecial_offset
	mov	si, ds:[bx].PIGSI_categoryOne
	mov	si, ds:[si]				; ds:si - category str
	segmov	cx, cs, dx
	mov	dx, offset faxinCapabilitiesStr		; cx:dx - key str
	call	FaxInitFileWriteT30

	pop	si					; self lptr
	DerefInstanceDataDSBX	PrefItemGroupSpecial_offset
	mov	si, ds:[bx].PIGSI_categoryTwo
	mov	si, ds:[si]				; ds:si - category str
	mov	dx, offset faxoutCapabilitiesStr	; cx:dx - key str
	call	FaxInitFileWriteT30
	
	.leave
	ret
PIGSWriteT30Response	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSWriteFaxDriverName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will write out the given capabilities to the
		capabilities key of both faxin and faxout.

CALLED BY:	PIGSWriteClassInfo

PASS:		*ds:si	- PrefItemGroupSpecialClass
		es:di	- input driver name
		es:bp	- output driver name
	
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSWriteFaxDriverName	proc	near
	class	PrefItemGroupSpecialClass
	uses	cx,dx,bx,si,di,ds
	.enter

	Assert	objectPtr	dssi, PrefItemGroupSpecialClass
	Assert	nullTerminatedAscii	esdi
	Assert	nullTerminatedAscii	esbp

	;
	; Write the input driver name
	;
	push	si					; self lptr
	DerefInstanceDataDSBX	PrefItemGroupSpecial_offset
	mov	si, ds:[bx].PIGSI_categoryOne
	mov	si, ds:[si]				; ds:si - category str
	segmov	cx, cs, dx
	mov	dx, offset faxinDriverNameStr		; cx:dx - key str
	call	InitFileWriteString

	;
	; Write the output driver name
	;
	pop	si					; self lptr
	DerefInstanceDataDSBX	PrefItemGroupSpecial_offset
	mov	si, ds:[bx].PIGSI_categoryTwo
	mov	si, ds:[si]				; ds:si - category str
	mov	dx, offset faxoutDriverNameStr		; cx:dx - key str
	mov	di, bp
	call	InitFileWriteString

	.leave
	ret
PIGSWriteFaxDriverName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefItemGroupSpecialCheckPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks the selected port to see if a viable faxmodem
		is connected.  If not, then display a warning dialog
		box.

CALLED BY:	MSG_PREF_ITEM_GROUP_SPECIAL_CHECK_PORT
PASS:		*ds:si	= PrefItemGroupSpecialClass object
		ds:di	= PrefItemGroupSpecialClass instance data
		ds:bx	= PrefItemGroupSpecialClass object (same as *ds:si)
		es 	= segment of PrefItemGroupSpecialClass
		ax	= message #

		cx 	= current selection, or first selection in item group,
  			  if more than one selection, or GIGS_NONE if
			  no selection
		bp 	= number of selections
		dl	= GenItemGroupStateFlags
			  GIGSF_MODIFIED will be set if a user
			  activation has just changed the status of
			  the group.  Will be clear if a redundant
			  user activation has occurred, such as the
			  re-selection of the singly selected
			  exclusive item.  If message is a result of
			  MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG being
			  sent, then this bit will hold the value
			  passed in that message. 

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/24/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefItemGroupSpecialCheckPort	method dynamic PrefItemGroupSpecialClass, 
					MSG_PREF_ITEM_GROUP_SPECIAL_CHECK_PORT
	uses	ax, cx, dx, bp
	.enter

	cmp	cx, GIGS_NONE
	je	done
	tst	bp
	jz	done
	test	dl, mask GIGSF_MODIFIED
	jz	done					; user didn't modify

	;
	; Determine which fax driver was chosen.
	;
	push	si, cx					; self lptr,
							; selected comport 
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	si, offset PrefFaxDriversSelector
	call	ObjCallInstanceNoLock			; ax - driver
	pop	si, cx					; self lptr
							; selected comport
	jc	done

	;
	; Now call the driver with the selected port number and see if
	; a viable modem is attached.
	;
retry:
	call	PIGSCheckIfViableInputModem
	cmp	ax, IC_YES
	je	retry
	call	PIGSCheckIfViableOutputModem
	cmp	ax, IC_YES
	je	retry

done:
	.leave
	ret
PrefItemGroupSpecialCheckPort	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSCheckIfViableInputModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if there's a viable input faxmodem of
		the given class, connected to the given port.

CALLED BY:	PrefItemGroupSpecialCheckPort

PASS:		ax	- FAX_CLASS_#
		cx	- FAX_COMPORT_#

RETURN:		CF	- SET if NO viable input faxmodem
		ax	- IC_YES for RETRY
			- IC_NO for CANCEL

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSCheckIfViableInputModem	proc	near
	uses	bx,cx,di,si,ds
	.enter

	call	PIGSLoadInputDriver
	jc	warning

	call	GeodeInfoDriver				; dssi -
							; DriverInfoStruct

        push    ax                                      ; driver class
        mov     ss:[TPD_dataAX], cx                     ; port num
        movdw   bxax, ds:[si].DIS_strategy
        mov     di, DR_FAXIN_CHECK_FOR_MODEM
        call    ProcCallFixedOrMovable
        pop     ax                                      ; driver class
	jc	warning

	mov	ax, IC_NO				; found valid modem
done:
	.leave
	ret

warning:
	;
	; Put up a warning/retry dialog box
	;
	mov	cx, FAX_INPUT_DRIVER
	call	PIGSInstantiateWarningDB
	stc
	jmp	done

PIGSCheckIfViableInputModem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSCheckIfViableOutputModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if there's a viable output faxmodem of
		the given class, connected to the given port.

CALLED BY:	PrefItemGroupSpecialCheckPort

PASS:		ax	- FAX_CLASS_#
		cx	- FAX_COMPORT_#

RETURN:		CF	- SET if NO viable output faxmodem
		ax	- IC_YES for RETRY
			- IC_NO for CANCEL

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSCheckIfViableOutputModem	proc	near
	uses	bx,cx,di,si,ds
	.enter

	call	PIGSLoadOutputDriver			; bx - driver handle 
	jc	warning

	call	GeodeInfoDriver				; dssi - 
							; DriverInfoStruct

        push    ax                                      ; driver class
        mov     ss:[TPD_dataAX], cx                     ; port num
        movdw   bxax, ds:[si].DIS_strategy
        mov     di, DR_FAXOUT_CHECK_FOR_MODEM
        call    ProcCallFixedOrMovable
        pop     ax                                      ; driver class
	jc	warning

	mov	ax, IC_NO				; found valid modem
done:
	.leave
	ret

warning:
	;
	; Put up a warning/retry dialog box
	;
	mov	cx, FAX_OUTPUT_DRIVER
	call	PIGSInstantiateWarningDB
	stc
	jmp	done

PIGSCheckIfViableOutputModem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSLoadInputDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads up the appropriate input fax driver.

CALLED BY:	PIGSCheckIfViableInputModem
PASS:		ax	- FAX_CLASS_#

RETURN:		CF 	- SET on error
				else
		bx 	- driver handle

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSLoadInputDriver	proc	near

driverName	local	FileLongName

	uses	ax,si,di,ds,es
	.enter

	;
	; Move to the fax driver directory.
	;
	call	FilePushDir
	call	PutThreadInFaxDriverDir
	jc	error				; jump if no dir

	;
	; Copy the driver's name to the stack for XIP purposes
	;
	segmov	ds, cs, si
	mov	si, offset class1InputDriverName
	cmp	ax, FAX_CLASS_1
	je	copyName
	mov	si, offset class2InputDriverName
copyName:
	segmov	es, ss, di
	lea	di, ss:[driverName]
	LocalCopyString

	;
	; Load the driver.
	;
	segmov	ds, es, si
	lea 	si, ss:[driverName]		; ds:si - filename
	mov	ax, FAXIN_PROTO_MAJOR
	mov	bx, FAXIN_PROTO_MINOR
	call	GeodeUseDriver			; carry set on error
						; ax = GeodeLoadError
						; bx = driver handle
error:
	call	FilePopDir			; (preserves flags)

	.leave
	ret
PIGSLoadInputDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSLoadOutputDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads up the appropriate output fax driver.

CALLED BY:	PIGSCheckIfViableOutputModem

PASS:		ax	- FAX_CLASS_#

RETURN:		CF 	- SET on error
				else
		bx 	- driver handle

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSLoadOutputDriver	proc	near

driverName	local	FileLongName

	uses	ax,si,di,ds,es
	.enter

	;
	; Move to the fax driver directory.
	;
	call	FilePushDir
	call	PutThreadInFaxDriverDir
	jc	error				; jump if no dir

	;
	; Copy the driver's name to the stack for XIP purposes
	;
	segmov	ds, cs, si
	mov	si, offset class1OutputDriverName
	cmp	ax, FAX_CLASS_1
	je	copyName
	mov	si, offset class2OutputDriverName
copyName:
	segmov	es, ss, di
	lea	di, ss:[driverName]
	LocalCopyString

	;
	; Load the driver.
	;
	segmov	ds, es, si
	lea 	si, ss:[driverName]		; ds:si - filename
	mov	ax, FAXOUT_PROTO_MAJOR
	mov	bx, FAXOUT_PROTO_MINOR
	call	GeodeUseDriver			; carry set on error
						; ax = GeodeLoadError
						; bx = driver handle
error:
	call	FilePopDir			; (preserves flags)

	.leave
	ret
PIGSLoadOutputDriver	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSInstantiateWarningDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will load in the DB strings from the Strings resource,
		and call PIGSPopUpRetryDialogBox to dynamically create
		a standard dialog box.

CALLED BY:	PIGSCheckIfViableInputModem,
		PIGSCheckIfViableOutputModem

PASS:		ax	- FAX_CLASS_#
		cx	- FAX_INPUT_DRIVER or FAX_OUTPUT_DRIVER
		
RETURN:		ax	- IC_YES for RETRY 
			- IC_NO for CANCEL

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PIGSInstantiateWarningDB	proc	near
	uses	bx,cx,dx,si,di,bp,es
	.enter

	push	ax					; driver class
	mov	bx, handle Strings
	call	MemLock
	mov_tr	es, ax					; Strings segment
	pop	ax					; driver class

	mov	di, offset noViableModemChunk
	mov	si, offset oneChunk
	cmp	ax, FAX_CLASS_1
	je	getIOString
	mov	si, offset twoChunk
getIOString:
	mov	bx, offset inputChunk
	cmp	cx, FAX_INPUT_DRIVER
	je	popUpDB
	mov	bx, offset outputChunk
popUpDB:
	call	PIGSPopUpRetryDialogBox
	mov	bx, handle Strings
	call	MemUnlock

	.leave
	ret
PIGSInstantiateWarningDB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PIGSPopUpRetryDialogBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts up a dialog box with the RETRY and CANCEL
		triggers.

CALLED BY:	PIGSInstantiateWarningDB

PASS:		*es:di	- message string
		*es:si	- string arg1
		*es:bx	- string arg3

RETURN:		ax	- IC_YES for RETRY
			- IC_NO for CANCEL

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/24/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

responseTriggers	StandardDialogResponseTriggerTable <2>
retryTrigger 		StandardDialogResponseTriggerEntry <retryChunk, IC_YES>
cancelTrigger 		StandardDialogResponseTriggerEntry <cancelChunk, IC_NO>

ForceRef	retryTrigger
ForceRef	cancelTrigger

PIGSPopUpRetryDialogBox	proc	near
	uses	bx,bp,di,si,es
	.enter
	
	; Allocate parameters buffer
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, CustomDialogBoxFlags <0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE, 0>
	mov	di, es:[di]				; es:di - msg str
	movdw	ss:[bp].SDP_customString, esdi
	mov	si, es:[si]				; es:si - arg1 str
	movdw	ss:[bp].SDP_stringArg1, essi
	mov	bx, es:[bx]				; es:bx - arg2 str
	movdw	ss:[bp].SDP_stringArg2, esbx
	clr	ss:[bp].SDP_helpContext.segment
	mov	ss:[bp].SDP_customTriggers.segment, cs
	mov	ss:[bp].SDP_customTriggers.offset, offset responseTriggers
	call	UserStandardDialog

	; No need to deAllocate parameters because UserStandardDialog
	; does it for us.

	.leave
	ret
PIGSPopUpRetryDialogBox	endp


if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECPIGSVerifyCategories
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verifies that the categories are correct for writing
		out the class information. Ie.

			categoryOne = FAX_INI_FAXIN_CATEGORY
			categoryTwo = FAX_INI_FAXOUT_CATEGORY


CALLED BY:	PIGSWriteClassInfo

PASS:		*ds:si	- PrefItemGroupSpecialClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	3/15/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECPIGSVerifyCategories	proc	near
	class	PrefItemGroupSpecialClass
	uses	es,di,si,cx
	.enter

	Assert	objectPtr	dssi, PrefItemGroupSpecialClass

	pushf

	push	si					; self lptr,
	DerefInstanceDataDSDI	PrefItemGroupSpecial_offset
	mov	si, ds:[di].PIGSI_categoryOne
	mov	si, ds:[si]				; str offset
	segmov	es, cs, di
	mov	di, offset EC_faxinStr
	clr	cx					; 0-terminated
	;
	; ds:si - category string, es:di - EC string
	;
	call	LocalCmpStrings			
	ERROR_NE< PREF_ITEM_GROUP_SPECIAL_CATEGORY_ERROR >

	pop	si					; self lptr,
	DerefInstanceDataDSDI	PrefItemGroupSpecial_offset
	mov	si, ds:[di].PIGSI_categoryTwo
	mov	si, ds:[si]				; str offset
	mov	di, offset EC_faxoutStr
	;
	; ds:si - category string, es:di - EC string
	;
	call	LocalCmpStrings
	ERROR_NE< PREF_ITEM_GROUP_SPECIAL_CATEGORY_ERROR >


	popf
	.leave
	ret
ECPIGSVerifyCategories	endp
endif

PrefFaxCode	ends
