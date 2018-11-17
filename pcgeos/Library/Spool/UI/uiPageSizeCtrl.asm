COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		uiPageSizeCtrl.asm

AUTHOR:		Don Reeves, Jan 23, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/23/92		Initial revision

DESCRIPTION:
	Contains the message handlers and routines to define the operation
	of the PageSizeControlClass.	

	$Id: uiPageSizeCtrl.asm,v 1.1 97/04/07 11:10:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Global routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolSetDocSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the document size for a given application

CALLED BY:	GLOBAL

PASS:		DS:SI	= PageSizeReport structure
		CX	= TRUE (document is open)
			= FALSE (document is closed)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Currently must be called from the *application* thread!

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolSetDocSize	proc	far
		push	bx, di
		call	GeodeGetProcessHandle
		mov	di, GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE
		call	SpoolSetDocSizeLow
		pop	bx, di
		ret
SpoolSetDocSize	endp

SpoolSetDocSizeLow	proc	near
		uses	ax, cx, dx, si, bp, es
		.enter
	
		; Create a PageSizeReport to send to the GCN list
		;
		push	bx, di			; process handle,GCN notify type
		clr	bx			; assume document is closed
		cmp	cx, FALSE		; is this assumption correct ??
		je	createEvent		; yes, so we're home free
		mov	ax, size PageSizeReport
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		mov	es, ax
		clr	di			; destination => ES:DI
		mov	cx, size PageSizeReport
		rep	movsb			; copy PageSizeReport structure
		call	MemUnlock
		mov	ax, 1
		call	MemInitRefCount

		; Create the classed event
createEvent:
		mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
		mov	cx, MANUFACTURER_ID_GEOWORKS
		mov	dx, GWNT_SPOOL_DOC_OR_PAPER_SIZE
		mov	bp, bx
		mov	di, mask MF_RECORD
		call	ObjMessage		; event handle => DI

		; Setup the GCNListMessageParams
		;
		pop	ax			; restore GCN notify type
		pop	cx			; process handle => CX
		mov	dx, size GCNListMessageParams
		sub	sp, dx
		mov	bp, sp			; GCNListMessageParams => SS:BP
		mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
		mov	ss:[bp].GCNLMP_ID.GCNLT_type, ax
		mov	ss:[bp].GCNLMP_block, bx
		mov	ss:[bp].GCNLMP_event, di
		mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
		mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
		mov	bx, cx			; process handle => BX
		mov	di, mask MF_STACK
		call	ObjMessage
		add	sp, dx			; clean up the stack

		.leave
		ret
SpoolSetDocSizeLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** External method handlers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the saved options for the PageSizeControl

CALLED BY:	GLOBAL (MSG_META_LOAD_OPTIONS)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlLoadOptions	method dynamic	PageSizeControlClass,
						MSG_META_LOAD_OPTIONS
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
		.enter
ForceRef	categoryBuffer

		; First do the common work
		;
		push	bp
		push	si
		call	PZCLoadSaveOptionsCommon
		push	bx
		jc	sendMessage

		; Now read in the data, and set the default
		;
		clr	bp
		call	InitFileReadData
sendMessage:
		pop	ax			; object block handle => AX
		pop	si
		xchg	ax, bx
		call	MemDerefDS		; object block => DS
		xchg	ax, bx
		jc	done
		cmp	cx, (size PageSizeReport)
		jne	done
		call	MemLock
		mov_tr	dx, ax
		clr	bp
		mov	ax, MSG_PZC_SET_PAGE_SIZE
		call	ObjCallInstanceNoLock
		call	MemFree
done:
		pop	bp

		.leave
		ret
PageSizeControlLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the options of the PageSizeControl

CALLED BY:	GLOBAL (MSG_META_SAVE_OPTIONS)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSaveOptions	method dynamic	PageSizeControlClass,
						MSG_META_SAVE_OPTIONS
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
		.enter
ForceRef	categoryBuffer

		; First do the common work
		;
		push	si
		call	PZCLoadSaveOptionsCommon
		pop	di
		jc	done
		
		; Now write the data out
		;
		push	bp
		call	MemDerefES		; object block => ES
		mov	di, es:[di]
		add	di, es:[di].PageSizeControl_offset		
		add	di, offset PZCI_width
		mov	bp, size PageSizeReport
		call	InitFileWriteData
		pop	bp
done:
		.leave
		ret
PageSizeControlSaveOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply changes made in the dialog box, and report our status
		to the output of this controller.

CALLED BY:	GLOBAL (MSG_GEN_APPLY)

PASS:		ES	= Segment of PageSizeControlClass
		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlApply	method dynamic	PageSizeControlClass, MSG_GEN_APPLY
		.enter

		; First send this on to our superclass
		;
		mov	di, offset PageSizeControlClass
		call	ObjCallSuperNoLock

		; Report our status to the outside world
		;
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		call	PZCPushPageSizeReport	; PageSizeReport => SS:BP
		test	ds:[di].PZCI_attrs, mask PZCA_ACT_LIKE_GADGET
		jz	sendToOD
		mov	dx, ss			; PageSizeReport => DX:BP
		call	PZCSendNotifyToGCNList	; send to GCN list
sendToOD:
		mov	dx, size PageSizeReport
		mov	ax, MSG_PRINT_REPORT_PAGE_SIZE
		clr	bx			; any class --
		clr	di			; this is a meta message
		call	GenControlOutputActionStack
		add	sp, size PageSizeReport

		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		test	ds:[di].PZCI_attrs, mask PZCA_LOAD_SAVE_OPTIONS
		jz	done
	;
	; hack to avoid options-changed when initially bringing up print
	; dialog (check to see if SpoolChange dialog has been opened)
	;
		push	si
		mov	ax, MSG_VIS_GET_BOUNDS
		mov	bx, segment SpoolChangeClass
		mov	si, offset SpoolChangeClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	si
		mov	cx, di
		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	ObjCallInstanceNoLock
		jcxz	done		; right bound zero, not opened

		mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
		call	UserCallApplication
done:

		.leave
		ret
PageSizeControlApply	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the page size & type to be displayed.

CALLED BY:	GLOBAL (MSG_PZC_SET_PAGE_SIZE)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX:BP	= PageSizeReport structure

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetPageSize	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_PAGE_SIZE
		.enter

		; Some set-up work
		;
		add	di, offset PZCI_width	
		call	PZCGetChildBlock	; features => AX
		segmov	es, ds			; destination => ES:DI
		mov	ds, dx
		xchg	si, bp			; source => DS:SI, chunk => BP
		call	PZCVerifyOrientation
		jc	storeValues

		; See if anything has changed
		;
		push	di, si
		mov	cx, (size PageSizeReport) - (size PSR_margins)
		test	ax, mask PSIZECF_MARGINS
		jz	doCompare
		add	cx, (size PSR_margins)		
doCompare:
		repe	cmpsb			; compare them bytes
		pop	di, si
		jz	noDataChange		; no difference, so jump

		; Store all of the values away
storeValues:
		push	si			; save start of PageSizeReport
		mov	ax, ds:[si].PSR_layout	; new PageLayout => AX
		mov	bx, es:[di].PSR_layout	; old PageLayout => BX
		mov	cx, (size PageSizeReport)
		rep	movsb			; copy the data now

		; See if the PageType has changes
		;
		segmov	ds, es
		mov	si, bp
		pop	bp			; PageSizeReport => DX:BP
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		and	ax, mask PLP_TYPE
		and	bx, mask PLP_TYPE
		cmp	ax, bx
		je	continue
		or	ds:[di].PZCI_attrs, mask PZCA_NEW_PAGE_TYPE

		; If we are acting like a gadget, we'd better put this
		; PageSizeReport struture on the GCN list for future
		; reference.
continue:
		test	ds:[di].PZCI_attrs, mask PZCA_ACT_LIKE_GADGET
		jz	tellChildren
		mov	dx, ds
		mov	bp, di
		add	bp, offset PZCI_width	; PageSizeReport => DX:BP
		call	PZCSendNotifyToGCNList	; send to GCN list

		; Now stuff the values into the objects
tellChildren:
		mov	cx, mask PSIZECF_PAGE_TYPE or \
			    mask PSIZECF_SIZE_LIST or \
			    mask PSIZECF_LAYOUT or \
			    mask PSIZECF_CUSTOM_SIZE or \
			    mask PSIZECF_MARGINS
		call	PZCUpdateUI		; update all of the UI
done:
		.leave
		ret

		; There's been no change, but see if we need to update
		; things anyway.
noDataChange:
		segmov	ds, es
		mov	si, bp
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		test	ds:[di].PZCI_attrs, mask PZCA_SIZE_LIST_INITIALIZED
		jnz	done			; if set, no need to do anything
		jmp	tellChildren		; else update children
PageSizeControlSetPageSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCVerifyOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Simple verification that the width/height matches
		the passed orientation.

CALLED BY:	PageSizeControlSetPageSize

PASS:		DS:SI	= PageSizeReport

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCVerifyOrientation	proc	near
		pushf
		uses	ax, bx, cx
		.enter
	
		; Compare the width & height
		;
		movdw	bxax, ds:[si].PSR_width
		cmpdw	ds:[si].PSR_height, bxax ; carry gets set if width is
						 ; larger than height.
		mov	bx, 0			; BX = 0 (portrait), or
		rcl	bx, 1			;      1 (landscape)
		mov	ax, ds:[si].PSR_layout
		mov	cx, ax
		and	ax, mask PLP_TYPE		
		cmp	ax, PT_PAPER
		je	checkPaper
		cmp	ax, PT_ENVELOPE
		je	checkEnvelope
done:
		.leave
		popf
		ret

		; Set the paper orientation
checkPaper:
		mov	cl, offset PLP_ORIENTATION
		jmp	storeValue
		
		; Set the envelope orientation
checkEnvelope:
		mov	ax, cx			; layout => AX
		and	ax, not (1 shl ((offset PLE_ORIENTATION) + 1))
		mov	cl, (offset PLE_ORIENTATION) + 1
storeValue:
		shl	bx, cl
		or	ax, bx
		mov	ds:[si].PSR_layout, ax
		jmp	done
PZCVerifyOrientation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlGetPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the page size & type

CALLED BY:	GLOBAL (MSG_PZC_GET_PAGE_SIZE)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX:BP	= PageSizeReport structure to fill

RETURN:		DX:BP	= PageSizeReport structure filled

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlGetPageSize	method dynamic	PageSizeControlClass,
						MSG_PZC_GET_PAGE_SIZE
		uses	ax
		.enter

		; Get all of the current values
		;
		call	PageSizeControlInit	; initialize if needed
		mov	es, dx
		movdw	es:[bp].PSR_width, ds:[di].PZCI_width, ax
		movdw	es:[bp].PSR_height, ds:[di].PZCI_height, ax
		mov	ax, ds:[di].PZCI_layout
		mov	es:[bp].PSR_layout, ax
		mov	ax, ds:[di].PZCI_margins.PCMP_top
		mov	es:[bp].PSR_margins.PCMP_top, ax
		mov	ax, ds:[di].PZCI_margins.PCMP_left
		mov	es:[bp].PSR_margins.PCMP_left, ax
		mov	ax, ds:[di].PZCI_margins.PCMP_right
		mov	es:[bp].PSR_margins.PCMP_right, ax
		mov	ax, ds:[di].PZCI_margins.PCMP_bottom
		mov	es:[bp].PSR_margins.PCMP_bottom, ax

		.leave
		ret
PageSizeControlGetPageSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Internal method handlers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the PageSize controller

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		DS:*SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		CX:DX	= GenControlBuildInfo structure to fill

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlGetInfo	method dynamic	PageSizeControlClass,
					MSG_GEN_CONTROL_GET_INFO
		.enter

		; First copy the data into the structure
		;
		mov	ax, ds
		mov	bx, di			; PageSizeCtrlInstance => AX:BX
		mov	bp, dx
		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset PZC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb

		; Now see if we like document or paper sizes
		;
		mov	ds, ax
		test	ds:[bx].PZCI_attrs, mask PZCA_PAPER_SIZE
		jz	afterPaperSize
		mov	es:[bp].GCBI_gcnList.offset, offset PZC_gcnPaperList
		mov	es:[bp].GCBI_gcnCount, length PZC_gcnPaperList
afterPaperSize:

		test	ds:[bx].PZCI_attrs, mask PZCA_ACT_LIKE_GADGET
		jz	afterGadget
		ornf	es:[bp].GCBI_flags,
			mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST
afterGadget:

		.leave
		ret
PageSizeControlGetInfo	endm

PZC_dupInfo	GenControlBuildInfo		<
		0,				; GCBI_flags
		PZC_iniKey,			; GCBI_initFileKey
		PZC_gcnDocList,			; GCBI_gcnList
		length PZC_gcnDocList,		; GCBI_gcnCount
		PZC_notifyList,			; GCBI_notificationList
		length PZC_notifyList,		; GCBI_notificationCount
		PZCName,			; GCBI_controllerName

		handle PageSizeControlUI,	; GCBI_dupBlock
		PZC_childList,			; GCBI_childList
		length PZC_childList,		; GCBI_childCount
		PZC_featuresList,		; GCBI_featuresList
		length PZC_featuresList,	; GCBI_featuresCount
		PSIZEC_DEFAULT_FEATURES,	; GCBI_features

		handle PageSizeToolboxUI,	; GCBI_toolBlock
		PZC_toolList,			; GCBI_toolList
		length PZC_toolList,		; GCBI_toolCount
		PZC_toolFeaturesList,		; GCBI_toolFeaturesList
		length PZC_toolFeaturesList,	; GCBI_toolFeaturesCount
		PSIZECT_DEFAULT_TOOLBOX_FEATURES, ; GCBI_toolFeatures
		PZC_helpContext,		; GCBI_helpContext
		0>				; GCBI_reserved

PZC_iniKey		char	"pageSizeControl", 0

PZC_gcnDocList		GCNListType \
			<MANUFACTURER_ID_GEOWORKS, \
				GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE>

PZC_gcnPaperList	GCNListType \
			<MANUFACTURER_ID_GEOWORKS, \
				GAGCNLT_APP_NOTIFY_PAPER_SIZE_CHANGE>

PZC_notifyList		NotificationType \
			<MANUFACTURER_ID_GEOWORKS, GWNT_SPOOL_DOC_OR_PAPER_SIZE>

PZC_childList		GenControlChildInfo \
			<offset PageTypeList, 
				mask PSIZECF_PAGE_TYPE, 
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset PageSizeLayout,
				mask PSIZECF_LAYOUT,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset PageSizeListParent,
				mask PSIZECF_SIZE_LIST,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset PageSizeWidth,
				mask PSIZECF_CUSTOM_SIZE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset PageSizeHeight,
				mask PSIZECF_CUSTOM_SIZE,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset PageSizeMargins,
				mask PSIZECF_MARGINS,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

PZC_featuresList	GenControlFeaturesInfo \
			<offset PageTypeList, PageTypeListName, 0>,
			<offset PageSizeList, PageSizeListName, 0>,
			<offset PageSizeLayout, PageSizeLayoutName, 0>,
			<offset PageSizeWidth, PageCustomSizeName, 0>,
			<offset PageSizeMargins, PageSizeMarginsName, 0>

%out Need to do something about PageSizeHeight...

PZC_toolList		GenControlChildInfo \
			<offset PageSizeToolTrigger, mask PSIZECTF_DIALOG_BOX,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

PZC_toolFeaturesList	GenControlFeaturesInfo \
			<offset PageSizeToolTrigger, PageSizeToolDBName, 0>

PZC_helpContext		char	"dbPageSize", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify me with the PageSizeContol become visible

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		ES	= Segment of PageSizeControlClass		
		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		AX	= Message passed

RETURN:		see MSG_GEN_CONTROL_GENERATE_UI

DESTROYED:	see MSG_GEN_CONTROL_GENERATE_UI

PSEUDO CODE/STRATEGY:
		This is a hack to ensure that a PageSizeControl object,
		working as a gadget, is properly initialized. If the
		PZCA_ACT_LIKE_GADGET flag is not set, nothing is done, ensure
		we adhere to good controller-priniciples.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlGenerateUI	method dynamic	PageSizeControlClass,
						MSG_GEN_CONTROL_GENERATE_UI

		; Initialize, and then call our superclass
		;
		push	ds:[di].PZCI_attrs
		andnf	ds:[di].PZCI_attrs, not mask PZCA_SIZE_LIST_INITIALIZED
		call	PageSizeControlInit	; initialize if needed
		mov	di, offset PageSizeControlClass
		call	ObjCallSuperNoLock
		
		; If we are appearing inside of a Print->Options
		; dialog box, then we have a bit of work to do
		;
		pop	ax
		test	ax, mask PZCA_PAPER_SIZE
		jz	updateMaxValues		; nope, so do nothing		
		; Reset some monikers
		;
		call	PZCGetChildBlock
		jc	updateMaxValues		; should never happen, but...

		; Check for simple UI
		;
		push	si
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		test	es:[uiOptions], mask SUIO_SIMPLE	; if simple...
		jnz	resetMonikers		; don't elongate string
		mov	cx, offset PageTypeListMonikerPrinter
		mov	si, offset PageTypeList
		call	PZCObjMessageSend

		; Set Printing-specific monikers
resetMonikers:
		mov	cx, offset PageSizeListMonikerPrinter
		mov	si, offset PageSizeListParent
		call	PZCObjMessageSend

		mov	cx, offset PaperPortraitMonikerListPrinter
		mov	si, offset PageSizePaperOrientationPortrait
		call	PZCObjMessageSend
		mov	cx, offset PaperLandscapeMonikerListPrinter
		mov	si, offset PageSizePaperOrientationLandscape
		call	PZCObjMessageSend

		mov	cx, offset EnvelopePortraitMonikerListPrinter
		mov	si, offset PageSizeEnvelopeOrientationPortrait
		call	PZCObjMessageSend
		mov	cx, offset EnvelopeLandscapeMonikerListPrinter
		mov	si, offset PageSizeEnvelopeOrientationLandscape
		call	PZCObjMessageSend

if _POSTCARDS
		mov	cx, offset PageSizePostcardLayoutMonikerPrinter
		mov	si, offset PageSizePostcardLayout
		call	PZCObjMessageSend
		mov	cx, offset PostcardPortraitMonikerListPrinter
		mov	si, offset PageSizePostcardOrientationPortrait
		call	PZCObjMessageSend
		mov	cx, offset PostcardLandscapeMonikerListPrinter
		mov	si, offset PageSizePostcardOrientationLandscape
		call	PZCObjMessageSend
endif
		pop	si
		
		; Then, update the maximum values
updateMaxValues:
		GOTO	PZCUpdateMaximumDimensions
PageSizeControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify me when the PageSizeControlUI is destroyed

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_DESTROY_UI)

PASS:		ES	= Segment of PageSizeControlClass
		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		AX	= Message passed

RETURN:		see MSG_GEN_CONTROL_DESTROY_UI

DESTROYED:	see MSG_GEN_CONTROL_DESTROY_UI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlDestroyUI	method dynamic	PageSizeControlClass,
						MSG_GEN_CONTROL_DESTROY_UI
		
		; Set some internal flags to ensure proper updating
		; if the UI is re-generated
		;
		andnf	ds:[di].PZCI_attrs, not mask PZCA_SIZE_LIST_INITIALIZED
		ornf	ds:[di].PZCI_attrs, mask PZCA_NEW_PAGE_TYPE
		mov	di, offset PageSizeControlClass
		GOTO	ObjCallSuperNoLock
PageSizeControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the user-interace controls that the controller displays

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_UPDATE_UI)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		SS:BP	= GenControlUpdateUIParams

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlUpdateUI	method dynamic	PageSizeControlClass,
					MSG_GEN_CONTROL_UPDATE_UI
		.enter

		; Get the notification data
		;
		mov	bx, ss:[bp].GCUUIP_dataBlock
		call	MemLock
		mov	dx, ax
		clr	bp			; PageSizeReport => DX:BP
		mov	ax, ds:[di].PZCI_attrs
		and	ax, mask PZCA_ACT_LIKE_GADGET
		and	ds:[di].PZCI_attrs, not (mask PZCA_ACT_LIKE_GADGET)
		mov_tr	di, ax
		mov	ax, MSG_PZC_SET_PAGE_SIZE
		call	ObjCallInstanceNoLock	; send ourselves a message

		; Clean up, by restoring an attribute & unlocking notify block
		;
		mov_tr	ax, di
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		or	ds:[di].PZCI_attrs, ax	; OR-in saved attribute
		call	MemUnlock

		.leave
		ret
PageSizeControlUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlRequestPageSizeMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the number of entries in the list

CALLED BY:	GLOBAL (MSG_PZC_REQUEST_PAGE_SIZE_MONIKER)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		BP	= Entry  number for moniker
		CX:DX	= GenDynamicList OD

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlRequestPageSizeMoniker	method dynamic PageSizeControlClass,\
					MSG_PZC_REQUEST_PAGE_SIZE_MONIKER
		.enter

		; First, see if this size will fit on the page
		;
		push	bp			; save paper size #
		push	cx, dx
		mov_tr	ax, bp			; paper size => AX
		mov	bp, ds:[di].PZCI_layout
		and	bp, mask PLP_TYPE	; PageType => BP
		call	SpoolGetPaperSize	; paper dimensions => CX, DX
		call	PZCHowWillPageFit	; attributes => DX
		tst	ax
		mov	dx, mask RIMF_NOT_ENABLED
		jz	copyString
		clr	dx

		; First copy the sting into a buffer
copyString:
		pop	bx, si			; GenDynamicList OD => BX:SI
		mov	bp, ds:[di].PZCI_layout
		and	bp, mask PLP_TYPE	; PageType => BP
		pop	ax			; paper size # => AX
SBCS <		sub	sp, MAX_PAPER_STRING_LENGTH			>
DBCS <		sub	sp, MAX_PAPER_STRING_LENGTH*(size wchar)	>
		mov	di, sp
		segmov	es, ss			; buffer => ES:DI
		call	SpoolGetPaperString	; fill buffer with string

		; Create a moniker to send to the GenDynamicList
		;
		sub	sp, (size ReplaceItemMonikerFrame)
		mov	bp, sp			; frame => SS:BP
		movdw	ss:[bp].RIMF_source, esdi
		mov	ss:[bp].RIMF_sourceType, VMST_FPTR
		mov	ss:[bp].RIMF_dataType, VMDT_TEXT
		mov	ss:[bp].RIMF_length, 0
		mov	ss:[bp].RIMF_width, 0
		mov	ss:[bp].RIMF_itemFlags, dx
		mov	ss:[bp].RIMF_item, ax
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
		mov	dx, (size ReplaceItemMonikerFrame)
		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
SBCS <		add	sp, (MAX_PAPER_STRING_LENGTH) + (size ReplaceItemMonikerFrame) >
DBCS <		add	sp, (MAX_PAPER_STRING_LENGTH)*(size wchar) + (size ReplaceItemMonikerFrame) >

		.leave
		ret
PageSizeControlRequestPageSizeMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetPageType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the page type to be displayed to the user.

CALLED BY:	GLOBAL (MSG_PZC_SET_PAGE_TYPE)

PASS:		DS:*SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		CX	= PageType

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		We don't take advantage of knowing what the old
		PageType was, as we cannot be guaranteed, due to the
		GenControl mechanism, that the instance data and the
		status of the layout groups match all the time.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetPageType	method dynamic 	PageSizeControlClass,
						MSG_PZC_SET_PAGE_TYPE
		.enter

		; Request that the page sizes be reloaded
		;
		mov	bp, cx			; new PageType => BP
		mov	cx, ds:[di].PZCI_layout
		and	cx, mask PLP_TYPE	; old PageType => CX
		and	ds:[di].PZCI_layout, not (mask PLP_TYPE)
		or	ds:[di].PZCI_layout, bp
		cmp	cx, bp
		je	done			; no change, so do nothing

		; A new PageType has been selected.
		;
		ornf	ds:[di].PZCI_attrs, mask PZCA_NEW_PAGE_TYPE or \
					    mask PZCA_IGNORE_UPDATE
		call	SpoolGetNumPaperSizes	; default entry => DX
		mov	cx, dx
		mov	ax, MSG_PZC_SET_PAGE_SIZE_ENTRY
		call	ObjCallInstanceNoLock	; also performs the update
		andnf	ds:[di].PZCI_attrs, not (mask PZCA_IGNORE_UPDATE)
		mov	cx, mask PSIZECF_SIZE_LIST or \
			    mask PSIZECF_LAYOUT or \
			    mask PSIZECF_CUSTOM_SIZE
		call	PZCUpdateUI

if	_LABELS
		; If labels are supported, then we need to update the
		; maximum dimensions supported by the UI, as labels come
		; with their own unique limits.
		;
		call	PZCUpdateMaximumDimensions
endif
done:
		.leave
		ret
PageSizeControlSetPageType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetPageSizeEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Internal method to change the paper size, sent when
		the user clicks on a list entry.

CALLED BY:	GLOBAL (MSG_PZC_SET_PAGE_SIZE_ENTRY)

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance
		CX	= Selected list entry number

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	5/90		Initial version
		Don	1/16/92		Documentation clean-up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetPageSizeEntry	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_PAGE_SIZE_ENTRY
		.enter

		; Get the size of the selected page
		;
		mov_tr	ax, cx			; selected paper string => AX
		mov	bp, ds:[di].PZCI_layout
		and	bp, mask PLP_TYPE	; PageType => BP
		call	SpoolGetPaperSize	; paper dimensions => CX, DX
		mov_tr	bp, ax			; default layout => BP
		mov	ax, cx
		or	ax, dx			; both dimensions zero ??
		jz	done			; if so, change nothing

		; We need to check to ensure the default layout can
		; fit given the width/height restrictions. If necessary,
		; we will re-orient the page
		;
		call	PZCHowWillPageFit	; PageSizeControlAttrs => AX
		CheckHack <(mask PLP_ORIENTATION) eq (mask PLE_ORIENTATION)>
		mov	bx, mask PZCA_LANDSCAPE_VALID
		test	bp, mask PLP_ORIENTATION
		jnz	testOrientation
		mov	bx, mask PZCA_PORTRAIT_VALID
testOrientation:
		test	ax, bx
		jnz	storeValues
		xchg	cx, dx
		xor	bp, mask PLP_ORIENTATION

		; Store the new values away, and update the UI
storeValues:
		mov	ds:[di].PZCI_width.low, cx
		mov	ds:[di].PZCI_height.low, dx
		mov	ds:[di].PZCI_layout, bp
		mov	cx, mask PSIZECF_LAYOUT or \
			    mask PSIZECF_CUSTOM_SIZE
		call	PZCUpdateUI
done:
		.leave
		ret
PageSizeControlSetPageSizeEntry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetPage[Width,Height]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the currently selected width or height

CALLED BY:	GLOBAL (MSG_PZC_SET_PAGE_WIDTH, MSG_PZC_SET_PAGE_HEIGHT)

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance
		DX.CX	= Width or height (in points)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/90		Initial version
	Don	1/16/92		Documentation clean-up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetPageWidth	method	PageSizeControlClass,
					MSG_PZC_SET_PAGE_WIDTH

		; Prepare for the real work
		;
		mov	bx, offset PZCI_width
		GOTO	PZCSetWidthHeightCommon
PageSizeControlSetPageWidth	endm

PageSizeControlSetPageHeight	method	PageSizeControlClass,
					MSG_PZC_SET_PAGE_HEIGHT

		; Prepare for the real work
		;
		mov	bx, offset PZCI_height
		FALL_THRU	PZCSetWidthHeightCommon
PageSizeControlSetPageHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetWidthHeightCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common work for when the width & height change

CALLED BY:	PageSizeControlSet[Width, Height]

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance
		CX.DX	= Actual width or height (in WWFixed points)
		BX	= Offset into PageSizeControlInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCSetWidthHeightCommon	proc	far
		class	PageSizeControlClass
		.enter
	
		; Store the value away
		;
		call	PZCStoreValue

		; See if we need to update any layout data. Essentially,
		; if width <= height, we want portrait mode, else we
		; want landscape mode selected.
		;
		mov	bp, ds:[di].PZCI_layout
		mov	cx, bp
if	_LABELS
		and	bp, mask PLP_TYPE	; PageType => BX
		cmp	bp, PT_LABEL
		je	update
endif
		CheckHack <mask PLE_ORIENTATION eq mask PLP_ORIENTATION>
		mov	dx, mask PLP_ORIENTATION
		cmpdw	ds:[di].PZCI_width, ds:[di].PZCI_height, ax
		jbe	checkOrientation	; if landscape, then set
		not	cx			; ...landscape orientation flag
checkOrientation:
		test	cx, dx			; if orientation flag is OK
		jz	update			; ...then don't muck with layout
		xor	ds:[di].PZCI_layout, dx	; ...else change the orientation

		; Now go update the UI
update:
		mov	cx, mask PSIZECF_SIZE_LIST or \
			    mask PSIZECF_LAYOUT
		call	PZCUpdateUI

		.leave
		ret
PZCSetWidthHeightCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetPaperOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the orientation for paper

CALLED BY:	GLOBAL (MSG_PZC_SET_PAPER_ORIENTATION)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		CX	= PaperOrientation

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetPaperOrientation	method dynamic	PageSizeControlClass,
					MSG_PZC_SET_PAPER_ORIENTATION
		.enter

		; Store the value away
		;
		mov	dx, not (mask PLP_ORIENTATION)
		mov	al, offset PLP_ORIENTATION
		call	PZCStoreLayoutOpts
		mov	cx, mask PSIZECF_SIZE_LIST or \
			    mask PSIZECF_CUSTOM_SIZE
		call	PZCUpdateUI

		.leave
		ret
PageSizeControlSetPaperOrientation	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetEnvelopeOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the orientation for envelopes

CALLED BY:	GLOBAL (MSG_PZC_SET_ENVELOPE_ORIENTATION)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		CX	= EnvelopeOrientation

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetEnvelopeOrientation	method dynamic	PageSizeControlClass,
					MSG_PZC_SET_ENVELOPE_ORIENTATION
		.enter

		; Store the value away
		;
		mov	dx, not (mask PLE_ORIENTATION)
		mov	al, offset PLE_ORIENTATION
		call	PZCStoreLayoutOpts
		mov	cx, mask PSIZECF_CUSTOM_SIZE
		call	PZCUpdateUI

		.leave
		ret
PageSizeControlSetEnvelopeOrientation	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetLabelColumns
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the number of labels across a page

CALLED BY:	GLOBAL (MSG_PZC_SET_LABEL_COLUMNS)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX	= # of columns

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_LABELS
PageSizeControlSetLabelColumns	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_LABEL_COLUMNS

		; Store the value away
		;
		mov	bx, not (mask PLL_COLUMNS)
		mov	al, offset PLL_COLUMNS
		GOTO	PZCStoreLayoutRange
PageSizeControlSetLabelColumns	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetLabelRows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the number of labels down a page

CALLED BY:	GLOBAL (MSG_PZC_SET_LABEL_ROWS)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX	= # of rows

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_LABELS
PageSizeControlSetLabelRows	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_LABEL_ROWS

		; Store the value away
		;
		mov	bx, not (mask PLL_ROWS)
		mov	al, offset PLL_ROWS
		GOTO	PZCStoreLayoutRange
PageSizeControlSetLabelRows	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetMaximumWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the maximum width for a page

CALLED BY:	GLOBAL (MSG_PZC_SET_MAXIMUM_WIDTH)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX:CX	= Maximum width

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetMaximumWidth	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_MAXIMUM_WIDTH
		
		; Set the maximum width
		;
		pushdw	dxcx
		call	PZCGetMaximumDimensions
		popdw	bxax
		GOTO	PZCSetMaximumDimensions
PageSizeControlSetMaximumWidth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetMaximumHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the maximum width for a page

CALLED BY:	GLOBAL (MSG_PZC_SET_MAXIMUM_HEIGHT)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX:CX	= Maximum height

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetMaximumHeight	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_MAXIMUM_HEIGHT

		; Set the maximum height
		;
		pushdw	dxcx
		call	PZCGetMaximumDimensions
		popdw	dxcx
		GOTO	PZCSetMaximumDimensions
PageSizeControlSetMaximumHeight	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlSetMargin[Left, Top, Right, Bottom]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the current margin values

CALLED BY:	GLOBAL (MSG_PZC_SET_LABEL_ROWS)

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlClassInstance
		DX.CX	= Margin value

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlSetMarginLeft	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_MARGIN_LEFT
		mov	bx, offset PZCI_margins.PCMP_left
		GOTO	PZCStoreMarginValue
PageSizeControlSetMarginLeft	endm

PageSizeControlSetMarginTop	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_MARGIN_TOP
		mov	bx, offset PZCI_margins.PCMP_top
		GOTO	PZCStoreMarginValue
PageSizeControlSetMarginTop	endm

PageSizeControlSetMarginRight	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_MARGIN_RIGHT
		mov	bx, offset PZCI_margins.PCMP_right
		GOTO	PZCStoreMarginValue
PageSizeControlSetMarginRight	endm

PageSizeControlSetMarginBottom	method dynamic	PageSizeControlClass,
						MSG_PZC_SET_MARGIN_BOTTOM
		mov	bx, offset PZCI_margins.PCMP_bottom
		FALL_THRU	PZCStoreMarginValue
PageSizeControlSetMarginBottom	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** PageSizeControl utility routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCStoreMarginValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a margin value

CALLED BY:	INTENRAL

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlInstance
		BX	= Offset to instance data in which to store value
		DX.CX	= Margin value

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCStoreMarginValue	proc	far
		call	PZCStoreValue
		clr	cx			; update no features
		call	PZCUpdateUI
		ret
PZCStoreMarginValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCLoadSaveOptionsCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common work for saving or loading options

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object
		AX	= MSG_META_SAVE/LOAD_OPTIONS

RETURN:		DS:SI	= Initfile category
		CX:DX	= Initfile key
		BX	= Handle of object blocking holding PageSizeControl
		Carry	= Clear
			- or -
		Carry	= Set (don't bother)
		
DESTROYED:	AX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The caller *must* dereference the object block after
		calling this function.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

pageSizeCtrlKey		char	"pageSizeCtrl", 0

PZCLoadSaveOptionsCommon	proc	near
		class	PageSizeControlClass
categoryBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
		.enter	inherit

		; First call our superclass
		;
		mov	di, offset PageSizeControlClass
		call	ObjCallSuperNoLock
		mov	bx, ds:[LMBH_handle]
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		test	ds:[di].PZCI_attrs, mask PZCA_LOAD_SAVE_OPTIONS
		stc
		jz	done

		; Now either load or save the options
		;
		mov	cx, ss
		lea	dx, categoryBuffer
		push	bx
		call	UserGetInitFileCategory		; get .ini category
		pop	bx
		movdw	dssi, cxdx
		mov	cx, cs
		mov	dx, offset pageSizeCtrlKey
		clc
done:
		.leave
		ret
PZCLoadSaveOptionsCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update all of the UI displayed by the PageSizeControl

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlInstance
		CX	= PageSizeControlFeatures to update

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateUI	proc	near
		class	PageSizeControlClass
		.enter

		; Update all of the UI components
		;
		test	ds:[di].PZCI_attrs, mask PZCA_IGNORE_UPDATE
		jnz	done
		call	PZCGetChildBlock	; child block handle => BX
		jc	done			; if no children, done
		and	ax, cx			; features to update => AX
		call	PZCUpdateType
		call	PZCUpdateLayout
		call	PZCUpdateSizeList
		call	PZCUpdateCustomSize
		call	PZCUpdateMargins

		; Update some flags
		;
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		andnf	ds:[di].PZCI_attrs, not (mask PZCA_NEW_PAGE_TYPE)
		ornf	ds:[di].PZCI_attrs, mask PZCA_SIZE_LIST_INITIALIZED

		; See if someone wants a general UI change notification
		;
		mov	ax, ATTR_PAGE_SIZE_CONTROL_UI_CHANGES
		call	ObjVarFindData		; PageSizeControlChanges=>DS:BX
		jnc	done			; not found, so we're done
		call	PZCPushPageSizeReport	; PageSizeReport => SS:BP
		mov	dx, size PageSizeReport	; stack frame size => DX
		mov	ax, ds:[bx].PSCC_message
		push	ds:[bx].PSCC_destination.high
		push	ds:[bx].PSCC_destination.low
		mov	di, mask MF_STACK or mask MF_FIXUP_DS
		call	GenProcessAction	; send out the information
		add	sp, dx			; clean up the stack frame
done:
		.leave
		ret
PZCUpdateUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Page Type UI

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControlClass object
		BX	= Block holding child UI
		AX	= PageSizeControlFeatures

RETURN:		Nothing

DESTROYED:	CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateType	proc	near
		class	PageSizeControlClass
		uses	ax, si
		.enter
	
		; Some set-up work first
		;
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		test	ax, mask PSIZECF_PAGE_TYPE
		jz	done
		call	PZCTestNewPageTypeOrInitialized
		jc	done

		; Update the PageTypeList object
		;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, ds:[di].PZCI_layout
		and	cx, mask PLL_TYPE	; PageType => CX
		clr	dx			; a "determinate" selection
		mov	si, offset PageSizeControlUI:PageTypeList
		call	PZCObjMessageSend
done:
		.leave
		ret
PZCUpdateType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateLayout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Page Layout UI

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControlClass object
		BX	= Block holding child UI
		AX	= PageSizeControlFeatures

RETURN:		Nothing

DESTROYED:	CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

layoutGroup	nptr		PageSizePaperLayout, \
				PageSizeEnvelopeLayout, \
				PageSizeLabelLayout, \
				PageSizePostcardLayout

layoutMkrPageSize	nptr	PageSizeLayoutPaperMkrPageSize, \
				PageSizeLayoutEnvelopeMkrPageSize, \
				PageSizeLayoutLabelMkrPageSize, \
				PageSizeLayoutPostcardMkrPageSize

layoutMkrPrinter	nptr	PageSizeLayoutPaperMkrPrinter, \
				PageSizeLayoutEnvelopeMkrPrinter, \
				PageSizeLayoutLabelMkrPrinter, \
				PageSizeLayoutPostcardMkrPrinter

layoutUpdate	nptr.near	PZCUpdateLayoutPaper, 
				PZCUpdateLayoutEnvelope,
				PZCUpdateLayoutLabel,
				PZCUpdateLayoutPostcard

CheckHack <(length layoutGroup)*2 eq PageType>
CheckHack <(length layoutUpdate)*2 eq PageType>

PZCUpdateLayout	proc	near
		class	PageSizeControlClass
		uses	ax, si
		.enter
	
		; Some set-up work first
		;
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		mov	dx, ds:[di].PZCI_layout
		mov	bp, dx
		and	bp, mask PLL_TYPE	; PageType => BP

		; Ensure the orientation matches the width/height comparison
		;
		push	ax, dx			; save features, PageLayout
		cmp	bp, PT_LABEL
		je	continue
		CheckHack <(mask PLP_ORIENTATION) eq (mask PLE_ORIENTATION)>
		mov	cx, mask PLP_ORIENTATION
		cmpdw	ds:[di].PZCI_width, ds:[di].PZCI_height, ax
		jbe	performCheck
		not	dx			; invert PageLayout mask
performCheck:
		test	dx, cx			; is orientation consistent ??
		jz	continue		; yes, so we're OK
		xchgdw	ds:[di].PZCI_width, ds:[di].PZCI_height, cx

		; Determine if the current page dimensions can only
		; fit one way or another on the page
continue:
		andnf	ds:[di].PZCI_attrs, not (mask PZCA_PORTRAIT_VALID or \
						 mask PZCA_LANDSCAPE_VALID)
		mov	cx, ds:[di].PZCI_width.low
		mov	dx, ds:[di].PZCI_height.low
		call	PZCHowWillPageFit	; perform the calculation
		or	ds:[di].PZCI_attrs, ax

		; Now change to the proper layout options, and set the
		; moniker appropriately.
		;
		pop	ax, dx			; restore features, PageLayout
		test	ax, mask PSIZECF_LAYOUT
		jz	done
		push	si
		call	PZCTestNewPageTypeOrInitialized
		jc	doUpdateNow
		mov	cx, offset layoutMkrPrinter
		test	ds:[di].PZCI_attrs, mask PZCA_PAPER_SIZE
		jnz	layoutStart
		mov	cx, offset layoutMkrPageSize
layoutStart:
		push	dx			; save PageLayout
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	di, cx			; moniker table => DI
		mov	cx, PageType		; last PageType => CX
layoutLoop:
		sub	cx, 2			; go to next PageType
		mov	si, cx
		mov	ax, MSG_GEN_SET_NOT_USABLE
		cmp	si, bp			; check assumption
		mov	si, cs:[layoutGroup][si]; layout group => BX:SI
		jne	setStatus		; if not current layout, jump
		call	SetLayoutMoniker		
		mov	ax, MSG_GEN_SET_USABLE	; we'd better set it usable
setStatus:
		push	di
		call	PZCObjMessageSend	; set USABLE or NOT_USABLE
		pop	di
		tst	cx			; go to next PageType
		jnz	layoutLoop		; loop 'til done
		pop	dx			; restore PageLayout
doUpdateNow:
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		call	cs:[layoutUpdate][bp]
done:
		.leave
		ret
PZCUpdateLayout	endp

SetLayoutMoniker	proc	near
		uses	cx, bp, si
		.enter

		mov	bp, cx
		mov	cx, cs:[di][bp]		; choose correct moniker
		mov	si, offset PageSizeLayout
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		call	PZCObjMessageSend

		.leave
		ret
SetLayoutMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateLayout[Paper, Envelope, Label]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the specific layout options

CALLED BY:	PZCUpdateLayout

PASS:		*DS:SI	= PageSizeControlClass object
		DS:DI	= PageSizeControlInstance
		DX	= PageLayout
		BX	= Block holding child UI
		AX	= PageSizeControlFeatures

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP (may destroy)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateLayoutPaper	proc	near
		class	PageSizeControlClass
	
		; Enable/Disable portrait & landscape modes
		;
		push	dx
		mov	cx, ds:[di].PZCI_attrs
		mov	dx, mask PZCA_PORTRAIT_VALID
		mov	si, offset PageSizePaperOrientationPortrait
		call	PZCEnableDisable
		mov	dx, mask PZCA_LANDSCAPE_VALID
		mov	si, offset PageSizePaperOrientationLandscape
		call	PZCEnableDisable
		pop	dx

		; Set the orientation
		;
		mov	di, mask PLP_ORIENTATION
		mov	cl, offset PLP_ORIENTATION
		mov	si, offset PageSizeControlUI:PageSizePaperOrientation
		GOTO	PZCSetLayoutList
PZCUpdateLayoutPaper	endp

PZCUpdateLayoutEnvelope	proc	near
		class	PageSizeControlClass
	
		; Enable/Disable portrait & landscape modes
		;
		push	dx
		mov	cx, ds:[di].PZCI_attrs
		mov	dx, mask PZCA_PORTRAIT_VALID
		mov	si, offset PageSizeEnvelopeOrientationPortrait
		call	PZCEnableDisable
		mov	dx, mask PZCA_LANDSCAPE_VALID
		mov	si, offset PageSizeEnvelopeOrientationLandscape
		call	PZCEnableDisable
		pop	dx

		; Set the orientation & the path
		;
		mov	di, mask PLE_ORIENTATION
		mov	cl, offset PLE_ORIENTATION
		mov	si, offset PageSizeControlUI:PageSizeEnvelopeOrientation
		GOTO	PZCSetLayoutList
PZCUpdateLayoutEnvelope	endp

PZCUpdateLayoutLabel	proc	near
	
if	_LABELS
		; Update limits first (this is key, or else our default
		; label layout will be limited by the previous setting)
		; the allowable values
		;
		clr	bp			; don't update cols & rows
		call	PZCUpdateMaximumLabelSheetDimensions

		; Set both of the GenValue objects
		;
		mov	di, mask PLL_COLUMNS
		mov	cl, offset PLL_COLUMNS
		mov	si, offset PageSizeControlUI:PageSizeLabelColumns
		call	PZCSetLayoutValue
		call	forceStatusMsg		; set new column value,
						; ...if limited

		mov	di, mask PLL_ROWS
		mov	cl, offset PLL_ROWS
		mov	si, offset PageSizeControlUI:PageSizeLabelRows
		call	PZCSetLayoutValue
		call	forceStatusMsg		; set new row value,
						; ...if limited
endif
		ret

if	_LABELS
forceStatusMsg	label	near
 		mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
 		call	PZCObjMessageSend
		retn
endif
PZCUpdateLayoutLabel	endp

PZCUpdateLayoutPostcard	proc	near
		class	PageSizeControlClass
	
if	_POSTCARDS
	
		; Enable/Disable portrait & landscape modes
		;
		push	dx
		mov	cx, ds:[di].PZCI_attrs
		mov	dx, mask PZCA_PORTRAIT_VALID
		mov	si, offset PageSizePaperOrientationPortrait
		call	PZCEnableDisable
		mov	dx, mask PZCA_LANDSCAPE_VALID
		mov	si, offset PageSizePaperOrientationLandscape
		call	PZCEnableDisable
		pop	dx

		; Set the orientation
		;
		mov	di, mask PLPC_ORIENTATION
		mov	cl, offset PLPC_ORIENTATION
		mov	si, offset PageSizeControlUI:PageSizePostcardOrientation
		GOTO	PZCSetLayoutList
else
		ret
endif
PZCUpdateLayoutPostcard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateSizeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Size List UI

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControlClass object
		BX	= Block holding child UI
		AX	= PageSizeControlFeatures

RETURN:		Nothing

DESTROYED:	CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateSizeList	proc	near
		class	PageSizeControlClass
		uses	ax, si
		.enter
	
		; Let's see if the dimensions match a page size
		;
		test	ax, mask PSIZECF_SIZE_LIST
		jz	done
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset

		; See if we need to re-initialize the dynamic list
		;
		call	PZCTestNewPageTypeOrInitialized
		jc	calcSelection		; no need to re-initiialize
		mov	bp, ds:[di].PZCI_layout
		and	bp, mask PLP_TYPE	; PageType => BP
		call	SpoolGetNumPaperSizes	; number of entries => CX
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	si, offset PageSizeControlUI:PageSizeList
		call	PZCObjMessageSend

		; Now re-calculate the selection
calcSelection:
		mov	cx, ds:[di].PZCI_width.low
		mov	dx, ds:[di].PZCI_height.low
		mov	bp, ds:[di].PZCI_layout
		and	bp, mask PLP_TYPE	; PageType => BP
		call	SpoolConvertPaperSize	; paper # => AX

		; Now tell the GenItemGroup to select this entry number
		;
		mov_tr	cx, ax
		clr	dx			; a "determinate" selection
		mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
		cmp	cx, -1			; no match ??
		je	resetSelection
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
resetSelection:
		mov	si, offset PageSizeList	; OD => BX:SI
		call	PZCObjMessageSend
done:		
		.leave
		ret
PZCUpdateSizeList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateCustomSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Custom Size UI

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControlClass object
		BX	= Block holding child UI
		AX	= PageSizeControlFeatures

RETURN:		Nothing

DESTROYED:	CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateCustomSize	proc	near
		class	PageSizeControlClass
		uses	si
		.enter
	
		; Some set-up work
		;
		test	ax, mask PSIZECF_CUSTOM_SIZE
		jz	done
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		
		; Load the value into each of the GenValue objects
		;
		mov	cx, ds:[di].PZCI_width.low
		mov	dx, ds:[di].PZCI_height.low
		mov	si, offset PageSizeWidth
		call	PZCSetValue
		mov	cx, dx
		mov	si, offset PageSizeHeight
		call	PZCSetValue
done:
		.leave
		ret
PZCUpdateCustomSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the Margin UI

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControlClass object
		BX	= Block holding child UI
		AX	= PageSizeControlFeatures

RETURN:		Nothing

DESTROYED:	CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateMargins	proc	near
		class	PageSizeControlClass
		uses	si
		.enter
	
		; Some set-up work
		;
		test	ax, mask PSIZECF_MARGINS
		jz	done
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		
		; Load the value into each of the GenValue objects
		;
		mov	cx, ds:[di].PZCI_margins.PCMP_left
		mov	si, offset PageSizeMarginLeft
if PZ_PCGEOS
		call	PZCSetMarginValue
else
		call	PZCSetValue
endif

		mov	cx, ds:[di].PZCI_margins.PCMP_top
		mov	si, offset PageSizeMarginTop
if PZ_PCGEOS
		call	PZCSetMarginValue
else
		call	PZCSetValue
endif

		mov	cx, ds:[di].PZCI_margins.PCMP_right
		mov	si, offset PageSizeMarginRight
if PZ_PCGEOS
		call	PZCSetMarginValue
else
		call	PZCSetValue
endif

		mov	cx, ds:[di].PZCI_margins.PCMP_bottom
		mov	si, offset PageSizeMarginBottom
if PZ_PCGEOS
		call	PZCSetMarginValue
else
		call	PZCSetValue
endif
done:
		.leave
		ret
PZCUpdateMargins	endp

if PZ_PCGEOS
PZCSetMarginValue	proc	near
		uses	ax, cx, dx, bp, di
		.enter
		mov	ax, MSG_GEN_APPLICATION_GET_MEASUREMENT_TYPE
		call	GenCallApplication	; al = MeasurementType
		tst	al			; US measurement, no change
		jz	notMetric
		;
		; metric - will massage value into nearby metric value
		;	cx = integral number of points
		;
		call	MassageValueForMetric	; dx.cx = WWFixed
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		clr	bp			; not indeterminate
		call	PZCObjMessageSend
		jmp	short done

notMetric:
		call	PZCSetValue
done:
		.leave
		ret
PZCSetMarginValue	endp

MassageMetricEntry	struct
	MME_real	WWFixed
	MME_integer	word
MassageMetricEntry	ends

MassageValueForMetric	proc	near
		uses	bx
		.enter
		mov	ax, cx				; ax = value
		clr	bx				; start at beginning
checkNext:
		movdw	dxcx, cs:massageMetricTable[bx].MME_real
		cmp	ax, cs:massageMetricTable[bx].MME_integer
		je	found
		add	bx, size MassageMetricEntry	; else, next entry
		cmp	bx, SIZE_MASSAGE_TABLE
		jne	checkNext
		mov	dx, ax				; use passed value
		clr	cx
found:
		.leave
		ret
MassageValueForMetric	endp

massageMetricTable	label	MassageMetricEntry
	MassageMetricEntry <<05676, 7>, 7>	;.25 cm    7.08661
	MassageMetricEntry <<11353, 14>, 14>	;.5 cm	   14.17323
	MassageMetricEntry <<22706, 28>, 28>	;1 cm	   28.34646
	MassageMetricEntry <<45411, 56>, 56>	;2 cm	   56.69291
endMassageMetricTable	label	byte
SIZE_MASSAGE_TABLE = (offset endMassageMetricTable)-(offset massageMetricTable)
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCHowWillPageFit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set how the current page dimensions could fit, given the
		current minimum & maximum values

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object
		CX	= Page width
		DX	= Page height

RETURN:		DS:DI	= PageSizeControlInstance
		AX	= PageSizeControlAttrs
				PZCA_PORTRAIT_VALID
				PZCA_LANDSCAPE_VALID

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCHowWillPageFit	proc	near
		class	PageSizeControlClass
		uses	bx, cx, dx, bp
		.enter
	
		; Now see how things will fit
		;
		push	cx, dx
		call	PZCGetMaximumDimensions
		mov	dx, cx			; maximum height => DX
		mov	cx, ax			; maximum width => CX
		clr	di
		pop	ax, bp			; width => AX, height => BP
		cmp	ax, bp
		jle	doComparisons
		xchg	ax, bp			; width in AX, length in BP
doComparisons:
		cmp	ax, cx
		jg	checkLandscape
		cmp	bp, dx
		jg	checkLandscape
		or	di, mask PZCA_PORTRAIT_VALID
checkLandscape:
		cmp	ax, dx
		jg	done
		cmp	bp, cx
		jg	done
		or	di, mask PZCA_LANDSCAPE_VALID
done:
		mov	ax, di			; PageSizeControlAttrs => DX
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset

		.leave
		ret
PZCHowWillPageFit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCGetMaximumDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the maximum dimensions

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object

RETURN:		BX:AX	= Maximum width
		DX:CX	= Maximum height

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCGetMaximumDimensions	proc	near
		class	PageSizeControlClass
		.enter
	
if	_LABELS
		; If we are dealing with labels, then we have a
		; limit of the default paper size (due to the code
		; that exists GetLabelMarginsRealLow(). So, check
		; for that case and deal with it
		;
		mov	bx, ds:[si]
		add	bx, ds:[bx].PageSizeControl_offset
		mov	ax, ds:[bx].PZCI_layout
		and	ax, mask PLP_TYPE	; PageType => AX
		cmp	ax, PT_LABEL
		je	labels
endif		
		; Grab the current maximum dimensions
		;
		mov	ax, TEMP_PAGE_SIZE_CONTROL_MAX_DIMENSIONS
		call	ObjVarFindData
		jnc	standard
		movdw	dxcx, ds:[bx].PZCMD_height
		mov	ax, ds:[bx].PZCMD_width.low
		mov	bx, ds:[bx].PZCMD_width.high
done:
		.leave
		ret

		; If none found, use the standard maximum values
standard:
		mov	ax, MAXIMUM_PAGE_WIDTH_VALUE
		mov	cx, MAXIMUM_PAGE_HEIGHT_VALUE
doneInteger::
		clr	bx, dx
		jmp	done

if	_LABELS
		; Get maximum page dimensions for labels
labels:
		push	ds, si
		sub	sp, size PageSizeReport
		segmov	ds, ss, si
		mov	si, sp				; ds:si -> scratch
		call	SpoolGetDefaultPageSizeInfo
		mov	ax, ds:[si].PSR_width.low	; ax = default width
		mov	cx, ds:[si].PSR_height.low	; cx = default height
		add	sp, size PageSizeReport
		pop	ds, si
		jmp	doneInteger		
endif
PZCGetMaximumDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetMaximumDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the maximum dimensions

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object
		BX:AX	= Maximum width
		DX:CX	= Maximum height

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCSetMaximumDimensions	proc	far
	
		; Allocate some variable instance data
		;
		pushdw	bxax
		pushdw	dxcx
		mov	ax, TEMP_PAGE_SIZE_CONTROL_MAX_DIMENSIONS or \
			    mask VDF_SAVE_TO_STATE
		mov	cx, size PageSizeControlMaxDimensions
		call	ObjVarAddData

		; Go store the data away
		;
		popdw	ds:[bx].PZCMD_height
		popdw	ds:[bx].PZCMD_width

		; Now update the values
		;
		FALL_THRU	PZCUpdateMaximumDimensions
PZCSetMaximumDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateMaximumDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the maximum dimensions

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCUpdateMaximumDimensions	proc	far
		uses	ax, bx, cx, dx, di, bp
		.enter

	
		; Now stuff the values into the range objects
		;
		call	PZCGetMaximumDimensions
		pushdw	bxax
		mov	di, offset PageSizeHeight
		call	PZCSetMaximumValue
		popdw	dxcx
		mov	di, offset PageSizeWidth
		call	PZCSetMaximumValue
if	_LABELS
		mov	bp, 1			; update maximum labels
		call	PZCUpdateMaximumLabelSheetDimensions
endif
done::
		.leave
		ret
PZCUpdateMaximumDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCUpdateMaximumLabelSheetDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the maximum columns & rows, given a size of label

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControlClass object
		BP	=  0 to not report new column & rows values
			<> 0 to report new column & rows values

RETURN:		Nothing

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_LABELS
PZCUpdateMaximumLabelSheetDimensions	proc	near
		class	PageSizeControlClass
		uses	ax, bx, dx, di
		.enter
	
		; Grab the current maximum values
		;
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
		test	ds:[di].PZCI_layout, PT_LABEL shl offset PLL_TYPE
		jz	done
		call	PZCGetMaximumDimensions
EC <		tst	bx			; verify zero		>
EC <		ERROR_NZ SPOOL_PAPER_SIZE_TOO_LARGE			>	
EC <		tst	dx			; verify zero		>
EC <		ERROR_NZ SPOOL_PAPER_SIZE_TOO_LARGE			>	

		; Calculate the maxmimum # of columns
		;
		push	ds:[di].PZCI_height.low
		mov	bx, ds:[di].PZCI_width.low
		div	bx			; maximum columns => AX
		mov	di, offset PageSizeLabelColumns
		call	PZCSetLabelMaximumValue
		
		; Calculate the maximum # of rows
		;
		pop	bx
		mov_tr	cx, ax
		clr	dx			; height => DX:AX
		div	bx
		mov	di, offset PageSizeLabelRows
		call	PZCSetLabelMaximumValue
done:
		.leave
		ret
PZCUpdateMaximumLabelSheetDimensions	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetLabelMaximumValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the maximum value for a label

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object
		DI	= Chunk handle of GenValue in duplicated UI
		AX	= Maximum # of rows or columns
		BP	=  0 to not report new column & rows values
			<> 0 to report new column & rows values

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 8/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_LABELS
.assert	(MAXIMUM_LABELS_ACROSS eq MAXIMUM_LABELS_DOWN)

PZCSetLabelMaximumValue	proc	near
		uses	bx, cx, dx, si
		.enter
	
		; We only allow a maximum number of rows & columns
		;
		cmp	ax, MAXIMUM_LABELS_ACROSS
		jbe	setMaximum
		mov	ax, MAXIMUM_LABELS_ACROSS
setMaximum:
		mov_tr	cx, ax
		clr	dx
		call	PZCSetMaximumValue
		tst	bp			; don't send status message
		jz	done			; ...if we don't want to get
						; back the current setting

		; Force the status message to be sent
		;
		call	PZCGetChildBlock
		jc	done
		mov	si, di			; GenValue's OD => BX:SI
		mov	ax, MSG_GEN_VALUE_SEND_STATUS_MSG
		call	PZCObjMessageSend
done:		
		.leave
		ret
PZCSetLabelMaximumValue	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets an integer value for a GenValue object

CALLED BY:	INTERNAL

PASS:		DS	= Segment of object block
		BX:SI	= GenValue object OD
		CX	= Size (in points)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCSetValue	proc	near
		uses	ax, cx, dx, bp, di
		.enter
	
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp			; "determinate" value
		call	PZCObjMessageSend

		.leave
		ret
PZCSetValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetMaximumValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a maximum for a GenValue

CALLED BY:	UTILITY

PASS:		*DS:SI	= PageSizeControl object
		DI	= Chunk handle of GenValue in duplicated UI
		DX:CX	= Maximum value (dword)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/22/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCSetMaximumValue	proc	near
		uses	ax, bx, cx, dx, si
		.enter
	
		; Set the maximum value
		;
EC <		tst	dx			; verify zero		>
EC <		ERROR_NZ SPOOL_PAPER_SIZE_TOO_LARGE			>	
		call	PZCGetChildBlock
		jc	done
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		mov	dx, cx			; low word of integer => DX
		clr	cx			; no fraction
		mov	si, di			; OD => BX:SI
		call	PZCObjMessageSend
done:
		.leave
		ret
PZCSetMaximumValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetLayoutList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a GenItemGroup to hold a value in a layout record

CALLED BY:	INTERNAL

PASS:		BX:SI	= GenItemGroup OD
		CL	= Offset to value in bitmask		
		DX	= Bitmask containing range value
		DI	= Bitmask to AND with
		
RETURN:		Nothing

DESTROYED:	AX, CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCSetLayoutList	proc	near
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		GOTO	PZCSetLayoutCommon
PZCSetLayoutList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSetLayoutValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a GenValue to hold a value in a layout record

CALLED BY:	INTERNAL

PASS:		DS	= Segment of objet block
 		BX:SI	= GenValue OD
		CL	= Offset to value in bitmask		
		DX	= Bitmask containing range value
		DI	= Bitmask to AND with

RETURN:		CX, BP, DI

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_LABELS
PZCSetLayoutValue	proc	near
		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
PZCSetLayoutCommon	label	near
else
PZCSetLayoutCommon	proc	near
endif
		push	dx
		and	dx, di
		shr	dx, cl
		mov	cx, dx
		clr	dx, bp			; value is "determinate"
		call	PZCObjMessageSend
		pop	dx
		ret
if	_LABELS
PZCSetLayoutValue	endp
else
PZCSetLayoutCommon	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCStoreValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a a rounded WWFixed range value

CALLED BY:	INTERNAL

PASS: 		DS:DI	= PageSizeControlInstance
		DX.CX	= Value to store (must round to integer first)
		BX	= Offset to field in PageSizeControlInstance

RETURN:		DX	= Rounded value

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCStoreValue	proc	near
		.enter
	
		shl	cx, 1			; high fraction bit => carry
		adc	dx, 0			; rounded points => CX
		mov	ds:[di][bx], dx		; store the value away

		.leave
		ret
PZCStoreValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCStoreLayoutRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a range value in one of the layout fields

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance
		DX	= Value to store
		BX	= Mask to clear
		AL	= Record offset

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_LABELS
PZCStoreLayoutRange	proc	far
	
		; Set things up for call lower-level routines
		;
		mov	cx, dx
		mov	dx, bx
		FALL_THRU	PZCStoreLayoutOpts
PZCStoreLayoutRange	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCStoreLayoutOpts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store an option (value) in one of the layout fields

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance
		CX	= Value to store
		DX	= Mask to clear
		AL	= Record offset

RETURN:		Nothing

DESTROYED:	AX, BX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCStoreLayoutOpts	proc	far
		class	PageSizeControlClass
		.enter
	
		; Store the value away, after clearing away the old value
		;
		xchg	ax, cx
		shl	ax, cl
		and	ds:[di].PZCI_layout, dx
		or	ds:[di].PZCI_layout, ax

		.leave
		ret
PZCStoreLayoutOpts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCTestNewPageTypeOrInitialized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test to see if we've been initialized, or a new PageType
		was passed

CALLED BY:	INTERNAL

PASS:		DS:DI	= PageSizeControlInstance

RETURN:		Carry	= Clear (something has changed)
			- or -
		Carry	= Set (nothing has changed)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	9/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCTestNewPageTypeOrInitialized	proc	near
		class	PageSizeControlClass
		.enter
	
		test	ds:[di].PZCI_attrs, mask PZCA_NEW_PAGE_TYPE
		jnz	done
		test	ds:[di].PZCI_attrs, mask PZCA_SIZE_LIST_INITIALIZED
		jz	done
		stc
done:
		.leave
		ret
PZCTestNewPageTypeOrInitialized	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCEnableDisable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable a generic object

CALLED BY:	UTILITY

PASS:		BX:SI	= Generic object
		CX	= Flags mask
		DX	= Bit to check		

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCEnableDisable	proc	near
		uses	ax, cx, dx, di, bp
		.enter
	
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		test	cx, dx
		jz	sendMessage
		mov	ax, MSG_GEN_SET_ENABLED
sendMessage:
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	PZCObjMessageSend

		.leave
		ret
PZCEnableDisable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCGetChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block handle for the children of PageSizeControl

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControl object

RETURN:		AX	= PageSizeControlFeatures
		BX	= Block handle
		Carry	= Clear
			  - or -
		Carry	= Set if no children

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCGetChildBlock	proc	near
		.enter
	
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData		; TempGenControlInstance=>DS:BX
		cmc				; invert the carry
		jc	done			; if not found, abort
		mov	ax, ds:[bx].TGCI_features
		mov	bx, ds:[bx].TGCI_childBlock
		tst	bx
		jnz	done
		stc				; set carry for no children
done:
		.leave
		ret
PZCGetChildBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PageSizeControlInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the PageSizeControl object, if needed

CALLED BY:	PageSizeControlGenerateUI(), PageSizeControlGetSize()

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PageSizeControlInit	proc	near
		class	PageSizeControlClass
		.enter
	
		; Now see if we need to initialize ourselves
		;
		test	ds:[di].PZCI_attrs, mask PZCA_SIZE_LIST_INITIALIZED
		jnz	exit

		; We need to initialize ourselves. Either we use our
		; instance data, or we query for a system default
		;
		push	ax, bx, cx, dx, bp, si
		test	ds:[di].PZCI_attrs, mask PZCA_INITIALIZE
		jz	updateUI
EC <		test	ds:[di].PZCI_attrs, mask PZCA_ACT_LIKE_GADGET	>
EC <		ERROR_Z	PAGE_SIZE_CONTROL_MUST_ACT_LIKE_GADGET_TO_INIT	>
		andnf	ds:[di].PZCI_attrs, not (mask PZCA_INITIALIZE)
		sub	sp, size PageSizeReport
		mov	bp, sp			; PageSizeReport => DX:BP
		push	ds, si
		segmov	ds, ss, dx
		mov	si, bp			; PageSizeReport => DS:SI
		call	SpoolGetDefaultPageSizeInfo
		mov	ax, MSG_PZC_SET_PAGE_SIZE
		pop	ds, si
		call	ObjCallInstanceNoLock	; send the message
		add	sp, size PageSizeReport
		mov	ax, MSG_GEN_APPLY
		call	ObjCallInstanceNoLock
done:
		pop	ax, bx, cx, dx, bp, si
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset
exit:
		.leave
		ret

		; Just update the current UI
updateUI:
		mov	cx, mask PSIZECF_PAGE_TYPE or \
			    mask PSIZECF_SIZE_LIST or \
			    mask PSIZECF_LAYOUT or \
			    mask PSIZECF_CUSTOM_SIZE or \
			    mask PSIZECF_MARGINS
		call	PZCUpdateUI
		jmp	done
PageSizeControlInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCSendNotifyToGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send out a notification of a size change to the GCN list

CALLED BY:	INTERNAL

PASS:		*DS:SI	= PageSizeControl object
		DS:DI	= PageSizeControlInstance
		DX:BP	= PageSizeReport structure

RETURN:		Nothing

DESTROYED:	BX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCSendNotifyToGCNList	proc	near
		class	PageSizeControlClass
		.enter
	
		; Determine to which list we should send the notification
		;
		test	ds:[di].PZCI_attrs, mask PZCA_PAPER_SIZE
		mov	di, GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE
		jz	sendNotify
		mov	di, GAGCNLT_APP_NOTIFY_PAPER_SIZE_CHANGE

		; Now send the notification
sendNotify:
		mov	bx, ds:[LMBH_handle]	; block handle => BX
		push	bx, si			; save PageSizeControl OD
		call	MemOwner		; process handle => BX
		mov	ds, dx
		mov	si, bp			; PageSizeReport => DS:SI
		mov	cx, TRUE		; the document is "open"
		call	SpoolSetDocSizeLow	; send notification to GCN list
		pop	bx, si			; restore PageSizeControl OD
		call	MemDerefDS
		mov	di, ds:[si]
		add	di, ds:[di].PageSizeControl_offset

		.leave
		ret
PZCSendNotifyToGCNList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCPushPageSizeReport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push a PageSizeReport structure onto the stack

CALLED BY:	INTERNAL

PASS:		DS:DI	= PageSizeControlInstance

RETURN:		SS:BP	= PageSizeReport

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Remember to clean up the stack after using the data!

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCPushPageSizeReport	proc	near
		class	PageSizeControlClass
	
		; Push the information onto the stack
		;
		pop	ax			; return address => AX
		push	ds:[di].PZCI_margins.PCMP_bottom
		push	ds:[di].PZCI_margins.PCMP_right
		push	ds:[di].PZCI_margins.PCMP_top
		push	ds:[di].PZCI_margins.PCMP_left
		push	ds:[di].PZCI_layout	; PSR_layout
		pushdw	ds:[di].PZCI_height	; PSR_height
		pushdw	ds:[di].PZCI_width	; PSR_width
		mov	bp, sp			; PageSizeReport => SS:BP
		push	ax			; return address => stack
		ret
PZCPushPageSizeReport	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PZCObjMessageSend, PZCObjMessageCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message via ObjMessage

CALLED BY:	INTERNAL

PASS:		DS	= Segment of object block
		BX:SI	= OD of destination
		AX	= Message to send
		CX,DX,BP = Data

RETURN:		see ObjMessage

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PZCObjMessageSend	proc	near
		push	di
		mov	di, mask MF_FIXUP_DS
		FALL_THRU	PZCObjMessage, di
PZCObjMessageSend	endp

EC <PZCObjMessage	proc	near call				>
NEC <PZCObjMessage	proc	near jmp				>
		call	ObjMessage
		FALL_THRU_POP	di
		ret
PZCObjMessage	endp

PageSizeControlCode	ends
