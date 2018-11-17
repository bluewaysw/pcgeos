COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		helpControl.asm

AUTHOR:		Gene Anderson, Oct 22, 1992

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	10/22/92	Initial revision


DESCRIPTION:
	Code for basic "Help" controller

	$Id: helpControl.asm,v 1.1 97/04/07 11:47:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;---------------------------------------------------

UserClassStructures	segment resource

	HelpControlClass		;declare the class record

UserClassStructures	ends

;---------------------------------------------------

HelpControlCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get GenControl info for the HelpControlClass
CALLED BY:	MSG_GEN_CONTROL_GET_INFO

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		cx:dx - GenControlBuildInfo structure to fill in

RETURN:		cx:dx - filled in
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HelpGetInfo	method dynamic HelpControlClass, \
						MSG_GEN_CONTROL_GET_INFO
	mov	si, offset HC_dupInfo
	mov	es, cx
	mov	di, dx				;es:di = dest
	segmov	ds, cs
	mov	cx, (size GenControlBuildInfo)/(size word)
	rep movsw
CheckHack <((size GenControlBuildInfo) and 1) eq 0>

	ret
HelpGetInfo	endm


	;
	; NOTE: GCBF_ALWAYS_UPDATE is so that duplicate notifications
	; come through.  If the user clicks on Help, navigates somewhere,
	; then clicks on Help again, this allows help to be brought up
	; again.
	; NOTE: GCBF_ALWAYS_ON_GCN_LIST is so HelpControl objects are
	; never disabled to keep users less confused.
	;
HC_dupInfo	GenControlBuildInfo	<
	mask GCBF_ALWAYS_UPDATE or \
	mask GCBF_ALWAYS_ON_GCN_LIST or \
	mask GCBF_IS_ON_ACTIVE_LIST or \
	mask GCBF_ALWAYS_INTERACTABLE or \
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,
					; GCBI_flags
	HC_IniFileKey,			; GCBI_initFileKey
	HC_gcnList,			; GCBI_gcnList
	length HC_gcnList,		; GCBI_gcnCount
	HC_notifyTypeList,		; GCBI_notificationList
	length HC_notifyTypeList,	; GCBI_notificationCount
	HelpName,			; GCBI_controllerName

	handle HelpControlUI,		; GCBI_dupBlock
	HC_childList,			; GCBI_childList
	length HC_childList,		; GCBI_childCount
	HC_featuresList,		; GCBI_featuresList
	length HC_featuresList,		; GCBI_featuresCount
; NOTE: no features by default is important since the features are
; NOTE: added based on the help type
	0,				; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	segment	resource
endif
HC_IniFileKey	char	"help", 0

HC_gcnList	GCNListType \
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_NOTIFY_HELP_CONTEXT_CHANGE>,
	<MANUFACTURER_ID_GEOWORKS, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS>

HC_notifyTypeList	NotificationType	\
	<MANUFACTURER_ID_GEOWORKS, GWNT_HELP_CONTEXT_CHANGE>

;---


HC_childList	GenControlChildInfo	\
	<offset HelpTopGroup, mask HPCF_FIRST_AID or \
				mask HPCF_CONTENTS or \
				mask HPCF_GO_BACK or \
				mask HPCF_HISTORY, 0>,
	<offset HelpInstructions, mask HPCF_INSTRUCTIONS,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
	<offset HelpTextDisplay, mask HPCF_TEXT, 0>,
	<offset HelpBottomGroup, mask HPCF_FIRST_AID_GO_BACK or \
				mask HPCF_CLOSE, 0>,
	<offset HelpOnHelpTrigger, mask HPCF_HELP,
				mask GCCF_IS_DIRECTLY_A_FEATURE>


; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

HC_featuresList GenControlFeaturesInfo \
	<offset HelpFirstAid, HCFirstAidName, 0>,
	<offset HelpFirstAidGoBack, HCFirstAidGoBackName, 0>,
	<offset HelpInstructions, HCInstructionsName, 0>,
	<offset HelpCloseTrigger, HCCloseName, 0>,
	<offset HelpGoBackTrigger, HCGoBackName, 0>,
	<offset HelpHistoryList, HCHistoryName, 0>,
	<offset HelpContentsTrigger, HCContentsName, 0>,
	<offset HelpTextDisplay, HCTextName, 0>,
	<offset HelpOnHelpTrigger, HCHelpOnHelpName, 0>
if FULL_EXECUTE_IN_PLACE
UIControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlUpdateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI for HelpControlClass
CALLED BY:	MSG_GEN_CONTROL_UPDATE_UI

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		ss:bp - GenControlUpdateUIParams
			GCUUIP_manufacturer
			GCUUIP_changeType
			GCUUIP_dataBlock
			GCUUIP_features
			GCUUIP_childBlock

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlUpdateUI	method dynamic HelpControlClass, 
						MSG_GEN_CONTROL_UPDATE_UI
	;
	; See if we've already received a detach
	;
	mov	ax, TEMP_HELP_DETACH_RECEIVED
	call	ObjVarFindData
	LONG jc quit
	;
	; Get the notification block and see if this is the right help type
	;
	mov	dx, ss:[bp].GCUUIP_dataBlock	;dx <- handle of notification
	mov	bx, dx
	call	MemLock
	mov	es, ax				;es <- seg addr of notification
	mov	al, es:NHCC_type
	cmp	al, ds:[di].HCI_helpType	;right help type?
	LONG jne	skipUpdate		;branch if wrong type
	;
	; Unless told otherwise, bring the Help DB on screen
	;
	push	bx
	mov	ax, ATTR_HELP_SUPPRESS_INITIATE
	call	ObjVarFindData
	pop	bx
	jc	noInitiate			;branch if attr exists
	;
	; Check and see if we can use HTML help
	;
	call	HelpControlUseHTMLHelp
	LONG jc	skipUpdate			;skip update if HTML help
	;
	; Bring up help control dialog
	;
	push	bp, dx
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjCallInstanceNoLock
	pop	bp, dx
	;
	; Get the features and child block directly, because the
	; act of bringing the controller up will have created the
	; child UI.  The stuff in GenControlUpdateUIParams will be zero.
	;
	call	HUGetChildBlockAndFeatures
	jmp	startUpdate

noInitiate:
	mov	ax, ss:[bp].GCUUIP_features
	mov	bx, ss:[bp].GCUUIP_childBlock

startUpdate:

HELP_LOCALS

	.enter

	mov	ss:features, ax
	mov	ss:childBlock, bx

	push	dx
	push	ds, si
	;
	; Get the data from the notification block
	;
	segmov	ds, es, dx
	mov	si, offset NHCC_context		;ds:si <- ptr to context name
	mov	cx, ((size NHCC_context)+(size NHCC_filename))/(size word)
	segmov	es, ss
	lea	di, ss:context			;es:di <- ptr to buffers
CheckHack <(offset NHCC_filename) eq (offset NHCC_context)+(size NHCC_context)>
	rep	movsw				;copy me jesus
	;
	; Save the TOC filename
	;
	mov	es, dx
	mov	di, offset NHCC_filenameTOC	;es:di <- ptr to TOC filename
	call	LocalStringSize			;cx <- size of string w/o NULL
	LocalNextChar escx			;cx <- size w/NULL
	pop	ds, si				;*ds:si <- controller


	mov	ax, TEMP_HELP_TOC_FILENAME
	call	ObjVarAddData			;ds:bx <- ptr to data
	push	ds, si
	mov	si, di
	mov	di, bx
	segmov	es, ds				;es:di <- ptr to dest
	mov	ds, dx				;ds:si <- ptr to source
	rep	movsb				;copy me jesus
	pop	ds, si

doneNotif::
	;
	; Done with the notification data block
	;
	pop	bx				;bx <- handle of data block
	call	MemUnlock
	;
	; Display the text...
	;
	call	HLDisplayText
	pushf
	;
	; Free any stored history & reset the history list
	;
	call	HHFreeHistoryArray
	clr	cx				;cx <- # of items
	call	HHInitList
	popf
	jc	openError			;branch if error
	;
	; Record the file & context for history
	;
	call	HHRecordHistory
doUpdates:
	;
	; Update UI for First Aid
	;
	test	ss:features, mask HPCF_FIRST_AID or mask HPCF_FIRST_AID_GO_BACK
	jz	noFirstAid
	call	HFAUpdateForMode
noFirstAid:
	;
	; Disable the "Go Back" button
	;
	test	ss:features, mask HPCF_GO_BACK
	jz	noGoBack
	mov	bx, ss:childBlock		;bx <- handle of child block
	mov	di, offset HelpGoBackTrigger
	call	HUDisableFeature
noGoBack:

afterUpdates:

	.leave
quit:
	ret

	;
	; Unlock the notification block and exit
	;
skipUpdate:
	call	MemUnlock
	jmp	quit

	;
	; An error occurred -- clean up after ourselves.  Normally
	; this won't do anything, but in the event that help is
	; already up on screen, and the user clicks on help again,
	; we need to clean up the help that is already up even if
	; an error occurs.
	;
openError:
	call	CloseHelpCommon
	;
	; If we are a dialog, make ourselves go away on an error
	;
	mov	di, ds:[si]
	add	di, ds:[di].HelpControl_offset
	cmp	ds:[di].GII_visibility, GIV_DIALOG
	jne	doUpdates
	push	bp
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock
	pop	bp
	jmp	afterUpdates

HelpControlUpdateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear TEMP_HELP_DETACH_RECEIVED, to deal with GenAppLazarus

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		see MSG_META_ATTACH

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlAttach		method dynamic HelpControlClass,
						MSG_META_ATTACH
	push	ax
	mov	ax, TEMP_HELP_DETACH_RECEIVED
	call	ObjVarFindData
	jnc	continue
	;
	; can do this even if not GIV_DIALOG
	;
	call	ObjVarDeleteDataAt
	mov	ax, HINT_INITIATED
	call	ObjVarDeleteData	; remove hint
	push	cx, dx, bp, si
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, ax
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	bx, 0
	call	GeodeGetAppObject	; ^lbx:si = app object
	tst	bx
	jz	continuePop
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage		; remove from GAGCNLT_WINDOWS list
continuePop:
	add	sp, size GCNListParams
	pop	cx, dx, bp, si
continue:
	pop	ax
	mov	di, offset HelpControlClass
	GOTO	ObjCallSuperNoLock
HelpControlAttach		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle closing down the help controller

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		see MSG_META_DETACH

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlDetach		method dynamic HelpControlClass,
						MSG_META_DETACH
	push	ax, cx
	mov	ax, TEMP_HELP_DETACH_RECEIVED
	clr	cx				;cx <- no extra data
	call	ObjVarAddData
	pop	ax, cx
	FALL_THRU	HelpControlDestroyUI
HelpControlDetach		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle closing down the help controller

CALLED BY:	MSG_GEN_CONTROL_DESTROY_UI
PASS:		*ds:si - instance data
		es - seg addr of HelpControlClass
		ax - the message

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/25/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlDestroyUI	method HelpControlClass,
					MSG_GEN_CONTROL_DESTROY_UI
	call	CloseHelpCommon
	mov	di, offset HelpControlClass
	GOTO	ObjCallSuperNoLock
HelpControlDestroyUI		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseHelpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code for closing down the help object

CALLED BY:	HelpControlDestroyUI(), HelpControlGupInteractionCommand()
PASS:		*ds:si - HelpControl object
RETURN:		none
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 6/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseHelpCommon		proc	near
	uses	ax
	.enter

	;
	; Set the file to none and close the old file, if any
	;
	clr	bx				;bx <- no new file
	call	HFSetFileCloseOld
	;
	; Free the history array
	;
	call	HHFreeHistoryArray
	;
	; Delete any temp vardata we added (HT_STATUS_HELP only, but
	; it's smaller to just try to delete it anyway)
	;
	mov	ax, TEMP_HELP_ERROR_FILENAME
	call	ObjVarDeleteData

	.leave
	ret
CloseHelpCommon		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGupInteractionCommand
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle InteractionCommand, looking for IC_DISMISS

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message

		cx - InteractionCommand

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/ 6/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGupInteractionCommand		method dynamic HelpControlClass,
						MSG_GEN_GUP_INTERACTION_COMMAND
	cmp	cx, IC_DISMISS			;closing window?
	jne	notClose			;branch if not closing window
	call	CloseHelpCommon
notClose:
	mov	di, offset HelpControlClass
	GOTO	ObjCallSuperNoLock
HelpControlGupInteractionCommand		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlUseHTMLHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use HTML help if possible

CALLED BY:	HelpControlUpdateUI
PASS:		*ds:si	= HelpControlClass object
		es:0	= NotifyHelpContextChange
RETURN:		carry set if HTML help used
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/22/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

htmlHelpToken	GeodeToken <"HTHP", MANUFACTURER_ID_GEOWORKS>

HelpControlUseHTMLHelp	proc	near
htmlFile	local	PathName
	uses	ax,bx,cx,dx,si,di,bp,ds,es
	.enter

	; convert the NotifyHelpContextChange filename (NHCC_filename) into
	; an HTML filename (append .htm)

	segmov	ds, es
	mov	si, offset NHCC_filename
	segmov	es, ss
	lea	di, ss:[htmlFile]
	mov	cx, DOS_FILE_NAME_CORE_LENGTH

filenameLoop:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_NULL
	je	appendHTM
	LocalCmpChar	ax, C_SPACE
	je	appendHTM
	LocalPutChar	esdi, ax
	loop	filenameLoop

appendHTM:
	mov	ax, C_PERIOD
	LocalPutChar	esdi, ax
SBCS <	mov	ax, C_SMALL_H						>
DBCS <	mov	ax, C_LATIN_SMALL_LETTER_H				>
	LocalPutChar	esdi, ax
SBCS <	mov	ax, C_SMALL_T						>
DBCS <	mov	ax, C_LATIN_SMALL_LETTER_T				>
	LocalPutChar	esdi, ax
SBCS <	mov	ax, C_SMALL_M						>
DBCS <	mov	ax, C_LATIN_SMALL_LETTER_M				>
	LocalPutChar	esdi, ax
	mov	ax, C_NULL
	LocalPutChar	esdi, ax

	; check SP_HELP_FILES to see if HTML file exists

	push	ds, di
	call	FilePushDir
	mov	ax, SP_HELP_FILES
	call	FileSetStandardPath
	segmov	ds, ss
	lea	dx, ss:[htmlFile]
	call	FileGetAttributes		; cx = FileAttrs
	call	FilePopDir
	pop	ds, di
	jc	noHtmlHelp			; exit on error

	test	ax, mask FA_SUBDIR or mask FA_VOLUME
	jnz	noHtmlHelp			; very unlikely, but...

	; now tack on "#<context>" to the filename

	LocalPrevChar	esdi
	mov	ax, C_NUMBER_SIGN
	LocalPutChar	esdi, ax

	mov	si, offset NHCC_context
	mov	cx, length NHCC_context

contextLoop:
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, C_NULL
	je	appendNull
	LocalPutChar	esdi, ax
	loop	contextLoop

appendNull:
	mov	ax, C_NULL
	LocalPutChar	esdi, ax

	; ok, we have an html file.  use iacp and launch html viewer.

	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	jc	noHtmlHelp

	; fill in AppLaunchBlock with HTML filename

	mov	bx, dx
	call	MemLock
	mov	es, ax
	mov	di, offset ALB_dataFile
	segmov	ds, ss
	lea	si, ss:[htmlFile]
	mov	cx, size htmlFile
	rep	movsb
	mov	es:[ALB_diskHandle], SP_HELP_FILES
	call	MemUnlock

	; since we may be (probably) running on the ui thread, we need to
	; spawn another thread to do the IACPConnect for us.

	push	bx, bp
	mov	al, PRIORITY_STANDARD
	mov	cx, vseg HelpControlIACPConnect
	mov	dx, offset HelpControlIACPConnect
	mov	di, INTERFACE_THREAD_MINIMUM_STACK_SIZE
	mov	bp, handle 0			; have ui own it
	call	ThreadCreate
	pop	bx, bp
	jc	freeALB				; free AppLaunchBlock if error
	stc					; must assume html help success
	jmp	done

freeALB:
	call	MemFree				; free AppLaunchBlock

noHtmlHelp:
	clc					; no html help
done:
	.leave
	ret
HelpControlUseHTMLHelp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlIACPConnect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	IACPConnect for html help

CALLED BY:	HelpControlUseHTMLHelp
PASS:		^hcx	= AppLaunchBlock
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	11/22/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlIACPConnect	proc	far

	segmov	es, cs
	mov	di, offset htmlHelpToken
	mov	ax, mask IACPCF_FIRST_ONLY
	mov	bx, cx				; ^hbx = AppLaunchBlock
	call	IACPConnect			; bp = IACPConnection
	jc	done

	clr	cx
	call	IACPShutdown
done:
	clr	cx, dx, si, bp			; exit code for ThreadDestroy
	ret
HelpControlIACPConnect	endp

HelpControlCode	ends

HelpControlInitCode segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle generation of normal UI

CALLED BY:	MSG_GEN_CONTROL_GENERATE_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlGenerateUI		method dynamic HelpControlClass,
						MSG_GEN_CONTROL_GENERATE_UI
	;
	; call our superclass
	;
	mov	di, offset HelpControlClass
	call	ObjCallSuperNoLock
	;
	; Scan for any interesting hints
	;
	call	HHScanForHints
	;
	; Add a minimum size to the text object so it doesn't get
	; too small on small screens
	;
	call	HHSetTextHints
	ret
HelpControlGenerateUI		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tweak the duplicated UI for debugging purposes

CALLED BY:	MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of HelpControlClass
		ax - the message
		cx - duplicated block handle
		dx - HCPFeatures which are active
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/16/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlTweakDuplicatedUI		method dynamic HelpControlClass,
					MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	.enter
		
	; Don't perform any "tweaking" unless our UI is available
	;
	test	dx, mask HPCF_FIRST_AID or mask HPCF_CONTENTS or \
		    mask HPCF_GO_BACK or mask HPCF_HISTORY
	jz	done

	; See if we're in debug mode. If so, set some UI usable
	;
	mov	bx, cx				; object block handle => BX
	segmov	ds, cs, cx
	mov	si, offset helpDebugCat
	mov	dx, offset helpDebugKey
	mov	ax, FALSE
	call	InitFileReadBoolean
	tst	ax
	jz	done

	; OK, we are in debug mode, so set two triggers usable
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_MANUAL
	mov	si, offset HelpVersionTrigger
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	mov	si, offset HelpInfoTrigger
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
HelpControlTweakDuplicatedUI		endm

helpDebugCat	char	"help", 0
helpDebugKey	char	"debug", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlResolveVariantSuperclass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is subclassed to add hints before we are built

CALLED BY:	MSG_META_RESOLVE_VARIANT_SUPERCLASS
PASS:		*ds:si - controller
		ds:di - controller
		see MSG_META_RESOLVE_VARIANT_SUPERCLASS
RETURN:		see MSG_META_RESOLVE_VARIANT_SUPERCLASS
DESTROYED:	see MSG_META_RESOLVE_VARIANT_SUPERCLASS

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	11/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlResolveVariantSuperclass		method dynamic HelpControlClass,
					MSG_META_RESOLVE_VARIANT_SUPERCLASS
	;
	; Add hints for the mode we're in
	;
	push	ax, cx, dx, bp
	call	HHAddHintsForMode
	pop	ax, cx, dx, bp
	;
	; call our superclass
	;
	mov	di, offset HelpControlClass
	GOTO	ObjCallSuperNoLock
HelpControlResolveVariantSuperclass		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HelpControlSetHelpType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set help type

CALLED BY:	MSG_HELP_CONTROL_SET_HELP_TYPE
PASS:		*ds:si	= HelpControlClass object
		ds:di	= HelpControlClass instance data
		ds:bx	= HelpControlClass object (same as *ds:si)
		es 	= segment of HelpControlClass
		ax	= message #
		cl	= HelpType
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/ 4/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HelpControlSetHelpType	method dynamic HelpControlClass, 
					MSG_HELP_CONTROL_SET_HELP_TYPE
	.enter
	mov	ds:[di].HCI_helpType, cl
	.leave
	ret
HelpControlSetHelpType	endm

HelpControlInitCode ends
