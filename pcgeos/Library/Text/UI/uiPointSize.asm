COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Text Library
FILE:		uiPointSizeControl.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	PointSizeControlClass	Style menu object

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/91		Initial version

DESCRIPTION:
	This file contains routines to implement PointSizeControlClass

	$Id: uiPointSize.asm,v 1.1 97/04/07 11:16:46 newdeal Exp $

-------------------------------------------------------------------------------@

;---------------------------------------------------

TextClassStructures	segment	resource

	PointSizeControlClass		;declare the class record

TextClassStructures	ends

;---------------------------------------------------

if not NO_CONTROLLERS

TextControlCommon segment resource

;---------------------------------------------------

COMMENT @----------------------------------------------------------------------

MESSAGE:	PointSizeControlGetInfo --
		MSG_GEN_CONTROL_GET_INFO for PointSizeControlClass

DESCRIPTION:	Return group

PASS:
	*ds:si - instance data
	es - segment of PointSizeControlClass

	ax - The message

	cx:dx - GenControlBuildInfo structure to fill in

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
PointSizeControlGetInfo	method dynamic	PointSizeControlClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset PSC_dupInfo
	GOTO	CopyDupInfoCommon

PointSizeControlGetInfo	endm

PSC_dupInfo	GenControlBuildInfo	<
	mask GCBF_SUSPEND_ON_APPLY,	; GCBI_flags
	PSC_IniFileKey,			; GCBI_initFileKey
	PSC_gcnList,			; GCBI_gcnList
	length PSC_gcnList,		; GCBI_gcnCount
	PSC_notifyTypeList,		; GCBI_notificationList
	length PSC_notifyTypeList,	; GCBI_notificationCount
	PSCName,			; GCBI_controllerName

	handle PointSizeControlUI,	; GCBI_dupBlock
	PSC_childList,			; GCBI_childList
	length PSC_childList,		; GCBI_childCount
	PSC_featuresList,		; GCBI_featuresList
	length PSC_featuresList,	; GCBI_featuresCount
	PSC_DEFAULT_FEATURES,		; GCBI_features

	handle PointSizeControlToolboxUI,	; GCBI_toolBlock
	PSC_toolList,			; GCBI_toolList
	length PSC_toolList,		; GCBI_toolCount
	PSC_toolFeaturesList,		; GCBI_toolFeaturesList
	length PSC_toolFeaturesList,	; GCBI_toolFeaturesCount
	PSC_DEFAULT_TOOLBOX_FEATURES>	; GCBI_toolFeatures

; Table used to build moniker string for the normal UI.  These contain the
; keyboard mnemonic and the prefix (e.g., "1. ") for the moniker.
PSC_namePrefixTable	label	lptr
	lptr SizeEntry1Moniker
	lptr SizeEntry2Moniker
	lptr SizeEntry3Moniker
	lptr SizeEntry4Moniker
	lptr SizeEntry5Moniker
	lptr SizeEntry6Moniker
	lptr SizeEntry7Moniker
	lptr SizeEntry8Moniker
	lptr SizeEntry9Moniker

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	segment	resource
endif

PSC_IniFileKey	char	"pointSize", 0

PSC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_APP_TARGET_NOTIFY_POINT_SIZE_CHANGE>

PSC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_TEXT_CHAR_ATTR_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GWNT_POINT_SIZE_CHANGE>

;---

PSC_childList	GenControlChildInfo	\
	<offset SizesList, mask PSCF_9 or mask PSCF_10 or mask PSCF_12 or \
			   mask PSCF_14 or mask PSCF_18 or mask PSCF_24 or \
			   mask PSCF_36 or mask PSCF_54 or mask PSCF_72, 0>,
	<offset SmallerTrigger, mask PSCF_SMALLER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset LargerTrigger, mask PSCF_LARGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset CustomSizeBox, mask PSCF_CUSTOM_SIZE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

PSC_featuresList	GenControlFeaturesInfo	\
	<offset CustomSizeBox, CustomSizeName, 0>,
	<offset LargerTrigger, LargerName, 0>,
	<offset SmallerTrigger, SmallerName, 0>,
	<offset Size72Entry, Size72Name, 0>,
	<offset Size54Entry, Size54Name, 0>,
	<offset Size36Entry, Size36Name, 0>,
	<offset Size24Entry, Size24Name, 0>,
	<offset Size18Entry, Size18Name, 0>,
	<offset Size14Entry, Size14Name, 0>,
	<offset Size12Entry, Size12Name, 0>,
	<offset Size10Entry, Size10Name, 0>,
	<offset Size9Entry, Size9Name, 0>

;---

PSC_toolList	GenControlChildInfo	\
	<offset SizesToolList, mask PSCTF_9 or mask PSCTF_10 or \
			       mask PSCTF_12 or mask PSCTF_14 \
			or mask PSCTF_18 or mask PSCTF_24 or mask PSCTF_36 \
			or mask PSCTF_54 or mask PSCTF_72, 0>,
	<offset LargerToolTrigger, mask PSCTF_LARGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset SmallerToolTrigger, mask PSCTF_SMALLER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

PSC_toolFeaturesList	GenControlFeaturesInfo	\
	<offset LargerToolTrigger, LargerName, 0>,
	<offset SmallerToolTrigger, SmallerName, 0>,
	<offset Size72ToolEntry, Size72Name, 0>,
	<offset Size54ToolEntry, Size54Name, 0>,
	<offset Size36ToolEntry, Size36Name, 0>,
	<offset Size24ToolEntry, Size24Name, 0>,
	<offset Size18ToolEntry, Size18Name, 0>,
	<offset Size14ToolEntry, Size14Name, 0>,
	<offset Size12ToolEntry, Size12Name, 0>,
	<offset Size10ToolEntry, Size10Name, 0>,
	<offset Size9ToolEntry, Size9Name, 0>

if FULL_EXECUTE_IN_PLACE
ControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointSizeControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the monikers for the point sizes.  Assigns the prefix
		(usually "1. ", "2. ", etc) dynamically so that no matter
		what point sizes are enabled, the item group is numbered
		sequentially (without any gaps).

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si	= PointSizeControlClass object
		ds:di	= PointSizeControlClass instance data
		ds:bx	= PointSizeControlClass object (same as *ds:si)
		es 	= segment of PointSizeControlClass
		ax	= message #
		cx	= duplicated block handle
		dx	= features mask

RETURN:		Nothing
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointSizeControlTweakDuplicatedUI	method dynamic PointSizeControlClass, 
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI

	; Check for trivial case.. no font sizes at all
	
	test	dx, mask PSCF_9  or mask PSCF_10 or mask PSCF_12 or \
		    mask PSCF_14 or mask PSCF_18 or mask PSCF_24 or \
		    mask PSCF_36 or mask PSCF_54 or mask PSCF_72
	
	jz	noTweakingNecessary
	

    	; Define locals after code above because the "push cx" local will
	; happen before the .enter and will then not be popped.
	
duplicatedBlockHandle	local	hptr			push cx
stringSegment		local	word
visMonikerChunk		local	lptr
replaceFrame		local	ReplaceVisMonikerFrame
featureListObject	local	lptr
featureListName		local	lptr			; suffix of moniker
	
; inherited by called procedure
ForceRef		duplicatedBlockHandle
ForceRef		featureListObject
ForceRef		featureListName

	.enter
	
	; Allocate an lmem block in the point size control object that
	; will be used to copy vis moniker's from.  Allocate it here for
	; some arbitrary size and it will be resized inside the loop.
	mov	al, mask OCF_IGNORE_DIRTY	; this is a temporary chunk
	mov	cx, 32
	call	LMemAlloc
	mov	ss:[visMonikerChunk], ax
	
	; Set up ReplaceVisMonikerFrame
	mov	ss:[replaceFrame].RVMF_source.offset, ax
	mov	ax, ds:[LMBH_handle]
	mov	ss:[replaceFrame].RVMF_source.handle, ax
	mov	ss:[replaceFrame].RVMF_sourceType, VMST_OPTR
	mov	ss:[replaceFrame].RVMF_dataType, VMDT_VIS_MONIKER
	clr	ss:[replaceFrame].RVMF_length
	mov	ss:[replaceFrame].RVMF_updateMode, VUM_MANUAL
	
	; Lock down string block and store segment.
	mov	bx, handle ControlStrings
	call	MemLock
	mov	ss:[stringSegment], ax
	
	; Calculate offset to last item of interest in features table.
	; Do byte multiply to not destroy dx
	mov	al, offset PSCF_9
	mov	ah, size GenControlFeaturesInfo
	mul	ah
	
	; cs:ax = ptr to current element in features list
	;  (or, in FXIP, ControlInfoXIP:ax = ptr to current element in features
	;    list)
	; cs:bx = ptr to current element in name prefix table
	; cl = amount to shift features mask to the LEFT by to check sign bit
	; ch = last feature bit to check
	
	add	ax, offset PSC_featuresList
	mov	bx, offset PSC_namePrefixTable
	mov	cx, ((((size PSCFeatures) * 8 - 1) - offset PSCF_72) shl 8) \
		      or ((size PSCFeatures) * 8 - 1) - offset PSCF_9 
	
featureLoop:
	mov	di, dx
	shl	di, cl
	jns	continueLoop
	call	PSCCreateAndReplaceMoniker

continueLoop:
    	inc	cl				; change shift amount
	sub	ax, size GenControlFeaturesInfo	; advance ax
	cmp	cl, ch				; check to see if done
	jbe	featureLoop
	
	; Unlock strings block
	mov	bx, handle ControlStrings
	call	MemUnlock
	
	; Free temporary LMem chunk
	mov	ax, ss:[visMonikerChunk]
	call	LMemFree
	
	.leave

noTweakingNecessary:
	ret
PointSizeControlTweakDuplicatedUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PSCCreateAndReplaceMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by PointSizeControlTweakDuplicatedUI.
		Actually creates the vis moniker and send a message to the
		object in the duplicated block that needs the new moniker.

CALLED BY:	PointSizeControlTweakDuplicatedUI

PASS:		*ds:si	= PointSizeControlClass object
		ax	= offset of current element in features list
		bx	= offset of current element in name prefix table
		ss:bp	= inherited local variables from
			  PointSizeControlTweakDuplicatedUI

RETURN:		*ds:si	= PointSizeControlClass object (may have been fixed)
		bx	= updated offset into name prefix table
		
DESTROYED:	es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PSCCreateAndReplaceMoniker	proc	near
	uses	si, cx
	.enter	inherit PointSizeControlTweakDuplicatedUI
	
	; We need to ReAlloc our temporary chunk used in creating the vis
	; moniker.  To do this, we need the size of the prefix moniker and
	; the size of the suffix (featureName) string.  So, for this first
	; part, we leave ds pointing to the controller object because that
	; is where the new chunk is.  After we ReAlloc, we exchange ds and
	; es so that the movsw works correctly.
	
	; load es:si with pointer to prefix moniker in string resource
	mov	es, ss:[stringSegment]
	mov	si, cs:[bx]			; get handle to prefix moniker
	mov	si, es:[si]			; es:si = source (prefx monk)
	ChunkSizePtr	es, si, cx		; cx = size of prefix moniker
	
	; ReAlloc the lmem chunk used for the new moniker to the total of
	; the prefix moniker size and the suffix string size
	push	ax, bx, cx
	
	; Get the size of the suffix string.  To get this information, we
	; need to go through the feature list table.  While were there,
	; might as well keep around the offset to the chunk of the string
	; (we'll need it later) and keep the offset to the object.

    	; In both FXIP and non-FXIP, we set es to be the segment to
	; reference for the table.  This makes the code easier to read.
	
NOFXIP< segmov	es, cs, bx						>
NOFXIP<	mov	bx, ax							>
	
FXIP<	push	ax				; offset into features list>
FXIP<	mov	bx, handle ControlInfoXIP	; lock down FXIP block	>
FXIP<	call	MemLock				;   containing the list >
FXIP<	mov	es, ax				; es=FXIP segment	>
FXIP<	pop	bx				; put offset into bx	>

	
	mov	di, es:[bx].GCFI_object
	mov	ss:[featureListObject], di
	
	; get the offset to the name of the feature (which is our suffix).
	; We know that this is in the string resource so we don't need the
	; handle.
	mov	di, es:[bx].GCFI_name.offset
	mov	ss:[featureListName], di

FXIP<	mov	bx, handle ControlInfoXIP	; unlock FXIP block	>
FXIP<	call	MemUnlock						>
	
	mov	es, ss:[stringSegment]		; es = string segment	>

	; *es:di = suffix string (feature name string)
	ChunkSizeHandle	es, di, bx		; bx = size of suffix string
	add	cx, bx				; cx = total size
	
	; ReAlloc the chunk
	mov	ax, ss:[visMonikerChunk]
	call	LMemReAlloc			; *ds:ax = the chunk
	pop	ax, bx, cx
	
	; load ds:di with pointer to our temporary chunk for creating the
	; vis moniker.
	mov	di, ss:[visMonikerChunk]
	mov	di, ds:[di]			; ds:di = new chunk
	push	di				; save beginning of new chunk
	
	; Setup the segments for copying
	segxchg	ds, es				; ds:si = source (prefix monikr)
						; es:di = new chunk
	
	; Copy the prefix moniker into our chunk.
	shr	cx, 1				; copy words
	rep	movsw
	jnc	doneWithPrefixCopy
	movsb					; copy odd byte, if any

doneWithPrefixCopy:
	pop	di				; es:di = start of new chunk
						; which is now a VisMoniker
	clr	es:[di].VM_width
	add	di, VM_data + VMT_text		; es:di = text moniker
	
	; We now need to append the suffix (featureName) string to our chunk.
	
	; Search in moniker string to find zero byte/word.
	push	ax
	clr	ax
	mov	cx, -1
SBCS <	repne	scasb				; find null byte	>
DBCS <	repne	scasw				; find null word	>
	pop	ax
	
	; scasb/w finish one byte/word past the match.. back up to overwrite
	; zero byte/word.
	dec	di
DBCS <	dec	di							>
	
	; Set ds:si to point to suffix string (which is the same as the name
	; string stored in the GenControlFeaturesInfo list).
	mov	si, ss:[featureListName]
	mov	si, ds:[si]			; dereference chunk handle
	
	; Copy the suffix string into the new vis moniker.
	push	ax
	; ds:si = suffix string
	; es:di = end of the string in our new vis moniker
	LocalCopyString
	
	segmov	ds, es, si			; ds to PointSizeControl block
						; to be fixed up by ObjMessage
	
	; Send a message to the actual item in the new object block that
	; needs the moniker we just created.  The replace frame argument for
	; this message was set up in calling function.
	push	bx, cx, dx, bp
	mov	si, ss:[featureListObject]	; GCFI_object offset
	mov	bx, ss:[duplicatedBlockHandle]
	lea	bp, ss:[replaceFrame]
	mov	dx, size ReplaceVisMonikerFrame
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, cx, dx, bp
	pop	ax
	
	inc	bx				; increment pointer to prefix
	inc	bx				; monikers by 2 (size lptr)
	
	.leave
	ret
PSCCreateAndReplaceMoniker	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	PointSizeControlSetPointSize -- MSG_PSC_SET_POINT_SIZE
						for PointSizeControlClass

DESCRIPTION:	Handle a change in the point size

PASS:
	*ds:si - instance data
	es - segment of PointSizeControlClass

	ax - The message

	MSG_PSC_SET_POINT_SIZE_FROM_LIST:
		cx - size
	MSG_PSC_SET_POINT_SIZE:
		dx.cx -- size

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@

PointSizeControlSetPointSizeFromList	method PointSizeControlClass,
					MSG_PSC_SET_POINT_SIZE_FROM_LIST

	mov	dx, cx
	clr	cx				;size in dx.cx
	FALL_THRU	PointSizeControlSetPointSize

PointSizeControlSetPointSizeFromList	endm

PointSizeControlSetPointSize	method PointSizeControlClass,
						MSG_PSC_SET_POINT_SIZE

	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	FALL_THRU	SendMeta_AX_DXCX_Common

PointSizeControlSetPointSize	endm

;---

SendMeta_AX_DXCX_Common	proc	far
	pushdw	dxcx			;point size
	clr	dx
	push	dx			;range.end.high
	push	dx			;range.end.low
	mov	bx, VIS_TEXT_RANGE_SELECTION
	push	bx			;range.start.high
	push	dx			;range.start.low
	mov	bp, sp
	mov	dx, size VisTextSetPointSizeParams
	clr	bx
	clr	di
	call	GenControlOutputActionStack
	add	sp, size VisTextSetPointSizeParams
	ret

SendMeta_AX_DXCX_Common	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	PointSizeControlSmallerPointSize -- MSG_PSC_SMALLER_POINT_SIZE
						for PointSizeControlClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of PointSizeControlClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	12/ 5/91		Initial version

------------------------------------------------------------------------------@
PointSizeControlSmallerPointSize	method dynamic	PointSizeControlClass,
					MSG_PSC_SMALLER_POINT_SIZE

	mov	ax, MSG_VIS_TEXT_SET_SMALLER_POINT_SIZE
	mov	cx, MIN_POINT_SIZE
	GOTO	SendAX_CX_Always_Common

PointSizeControlSmallerPointSize	endm

;---

PointSizeControlLargerPointSize	method dynamic	PointSizeControlClass,
					MSG_PSC_LARGER_POINT_SIZE

	mov	ax, MSG_VIS_TEXT_SET_LARGER_POINT_SIZE
	mov	cx, MAX_POINT_SIZE
	FALL_THRU	SendAX_CX_Always_Common

PointSizeControlLargerPointSize	endm

SendAX_CX_Always_Common	proc	far
	GOTO	SendMeta_AX_CX_Common
SendAX_CX_Always_Common	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	PointSizeControlUpdateUI -- MSG_GEN_CONTROL_UPDATE_UI
					for PointSizeControlClass

DESCRIPTION:	Handle notification of attributes change

PASS:
	*ds:si - instance data
	es - segment of PointSizeControlClass

	ax - The message

	ss:bp - GenControlUpdateUIParams

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/12/91		Initial version

------------------------------------------------------------------------------@
PointSizeControlUpdateUI	method dynamic PointSizeControlClass,
				MSG_GEN_CONTROL_UPDATE_UI

	; get notification data

	push	ds
	mov	bx, ss:[bp].GCUUIP_dataBlock
	call	MemLock
	mov	ds, ax
	cmp	ss:[bp].GCUUIP_changeType, GWNT_TEXT_CHAR_ATTR_CHANGE
	jz	textNotify
	movdw	cxax, ds:NPSC_pointSize
	clr	dx
	mov	dl, ds:NPSC_diffs
	jmp	common
textNotify:
	clr	al
	mov	cx, ds:VTNCAC_charAttr.VTCA_pointSize.WBF_int
	mov	ah, ds:VTNCAC_charAttr.VTCA_pointSize.WBF_frac
	mov	dx, ds:VTNCAC_charAttrDiffs.VTCAD_diffs
	and	dx, mask VTCAF_MULTIPLE_POINT_SIZES
common:
	call	MemUnlock
	pop	ds
	
	; cxax = size

	push	ax
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock
	test	ax, mask PSCF_9 or mask PSCF_10 or mask PSCF_12 or \
			mask PSCF_14 \
			or mask PSCF_18 or mask PSCF_24 or mask PSCF_36 \
			or mask PSCF_54 or mask PSCF_72
	jz	noList
	mov	si, offset SizesList
	call	SendListSetExcl
noList:

	; set custom size box

	test	ax, mask PSCF_CUSTOM_SIZE
	pop	ax				;value to pass in cx.ax
	jz	noCustom
	mov	si, offset PointSizeDistance
	call	SendRangeSetWWFixedValue
noCustom:

	; set toolbox

	test	ss:[bp].GCUUIP_toolboxFeatures, mask PSCTF_9 or \
			mask PSCTF_10 or mask PSCTF_12 or mask PSCTF_14 \
			or mask PSCTF_18 or mask PSCTF_24 or mask PSCTF_36 \
			or mask PSCTF_54 or mask PSCTF_72
	jz	noToolbox
	mov	bx, ss:[bp].GCUUIP_toolBlock
	mov	si, offset SizesToolList
	call	SendListSetExcl
noToolbox:

	ret

PointSizeControlUpdateUI	endm

TextControlCommon ends

endif		; not NO_CONTROLLERS
