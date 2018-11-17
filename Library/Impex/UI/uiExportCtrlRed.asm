COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		uiExportCtrl.asm

AUTHOR:		Don Reeves, May 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/26/92		Initial revision

DESCRIPTION:
	Contains the code implementing the ExportControlClass

	$Id: uiExportCtrlRed.asm,v 1.1 97/04/04 23:19:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexUICode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** External Messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlSetDataClasses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the data classes to be displayed for export

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_SET_DATA_CLASSES)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		CX	= ImpexDataClasses

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlSetDataClasses	method dynamic	ExportControlClass,
				MSG_EXPORT_CONTROL_SET_DATA_CLASSES
		.enter

		; Store the data away, and notify our child if needed
		;
EC <		test	cx, not ImpexDataClasses			>
EC <		ERROR_NZ ILLEGAL_IMPEX_DATA_CLASSES			>
		mov	ds:[di].ECI_dataClasses, cx
		call	ExportSendDataClassesToFormatList

		.leave
		ret
ExportControlSetDataClasses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetDataClasses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the data classes displayed for export

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_GET_DATA_CLASSES)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance

RETURN:		CX	= ImpexDataClasses

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlGetDataClasses	method dynamic	ExportControlClass,
				MSG_EXPORT_CONTROL_GET_DATA_CLASSES
		.enter

		mov	cx, ds:[di].ECI_dataClasses

		.leave
		ret
ExportControlGetDataClasses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlSetAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the action (message and OD to send it to) for export

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_SET_ACTION)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		CX:DX	= OD of destination object
		BP	= Message to send

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlSetAction	method dynamic	ExportControlClass,
					MSG_EXPORT_CONTROL_SET_ACTION
		.enter

		movdw	ds:[di].ECI_destination, cxdx
		mov	ds:[di].ECI_message, bp

		.leave
		ret
ExportControlSetAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlSetMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message for export

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_SET_MSG)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		cx	= Message to send

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jon	12 oct 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlSetMsg	method dynamic	ExportControlClass,
					MSG_EXPORT_CONTROL_SET_MSG
		.enter

		mov	ds:[di].ECI_message, cx

		.leave
		ret
ExportControlSetMsg	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the action to be used upon export

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_GET_ACTION)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance

RETURN:		CX:DX	= OD of destination object
		BP	= Message to send

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlGetAction	method dynamic	ExportControlClass,
					MSG_EXPORT_CONTROL_GET_ACTION
		.enter

		movdw	cxdx, ds:[di].ECI_destination
		mov	bp, ds:[di].ECI_message

		.leave
		ret
ExportControlGetAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the attributes for an ExportControl object

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_SET_ATTRS)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		CX	= ExportControlAttrs

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlSetAttrs	method dynamic	ExportControlClass,
					MSG_EXPORT_CONTROL_SET_ATTRS
		.enter

EC <		test	cx, not ExportControlAttrs			>
EC <		ERROR_NZ EXPORT_CONTROL_ILLEGAL_ATTRS			>
		mov	ds:[di].ECI_attrs, cx

		.leave
		ret
ExportControlSetAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the attributes for an ExportControl object

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_GET_ATTRS)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance

RETURN:		CX	= ExportControlAttrs

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlGetAttrs	method dynamic	ExportControlClass,
					MSG_EXPORT_CONTROL_GET_ATTRS
		.enter

		mov	cx, ds:[di].ECI_attrs

		.leave
		ret
ExportControlGetAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlExportComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An application has reported that is export is complete.

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_EXPORT_COMPLETE)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		SS:BP	= ImpexTranslationParams

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlExportComplete	method dynamic	ExportControlClass,
				MSG_EXPORT_CONTROL_EXPORT_COMPLETE

		; Send a message of to the export thread
		;
		mov	ax, MSG_ITP_EXPORT_FROM_APP_COMPLETE
		mov	bx, ss:[bp].ITP_internal.low
		mov	cx, ss:[bp].ITP_internal.high
		mov	dx, size ImpexTranslationParams
		mov	di, mask MF_STACK
		GOTO	ObjMessage		
ExportControlExportComplete	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Internal Messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlBuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept building of visual tree

CALLED BY:	GLOBAL (MSG_SPEC_BUILD_BRANCH)

PASS:		ES	= Segment of ExportControlClass
		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		BP	= SpecBuildFlags

RETURN:		Nothing

DESTROYED:	BX, CX, DX, DI

PSEUDO CODE/STRATEGY:
		* Copy a default moniker (if needed)
		* Continue with building of branch
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	DEFAULT_MONIKER
ExportControlBuildBranch	method dynamic	ExportControlClass,
						MSG_SPEC_BUILD_BRANCH

		; Add a moniker (if needed) for export
		;
		mov	dx, handle DefaultExportMoniker
		mov	cx, offset DefaultExportMoniker
		call	ImpexCopyDefaultMoniker

		; Call our superclass to finish the work
		;
		mov	di, offset ExportControlClass
		GOTO	ObjCallSuperNoLock
ExportControlBuildBranch	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the ExportControl object

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		*DS:SI	= ExportControlControlClass object
		DS:DI	= ExportControlControlClassInstance
		CX:DX	= GenControlBuildInfo

RETURN:		Nothing

DESTROYED:	CX, DI, SI, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlGetInfo	method dynamic 	ExportControlClass,
					MSG_GEN_CONTROL_GET_INFO
		.enter

		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset EC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
ExportControlGetInfo	endm

EC_dupInfo	GenControlBuildInfo		<
		mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST,	; GCBI_flags
		EC_initFileKey,			; GCBI_initFileKey
		EC_gcnList,			; GCBI_gcnList
		length EC_gcnList,		; GCBI_gcnCount
		EC_notifyList,			; GCBI_notificationList
		length EC_notifyList,		; GCBI_notificationCount
		ExportControllerName,		; GCBI_controllerName

		handle ExportControlUI,		; GCBI_dupBlock
		EC_childList,			; GCBI_childList
		length EC_childList,		; GCBI_childCount
		EC_featuresList,		; GCBI_featuresList
		length EC_featuresList,		; GCBI_featuresCount
		EXPORTC_DEFAULT_FEATURES,	; GCBI_features

		handle ExportToolboxUI,		; GCBI_toolBlock
		EC_toolList,			; GCBI_toolList
		length EC_toolList,		; GCBI_toolCount
		EC_toolFeaturesList,		; GCBI_toolFeaturesList
		length EC_toolFeaturesList,	; GCBI_toolFeaturesCount
		EXPORTC_DEFAULT_TOOLBOX_FEATURES, ; GCBI_toolFeatures
		EC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ImpexControlInfoXIP	segment	resource
endif

EC_initFileKey	char	"exportControl", 0

EC_gcnList		GCNListType \
			<MANUFACTURER_ID_GEOWORKS, \
				GAGCNLT_APP_TARGET_NOTIFY_DOCUMENT_CHANGE>

EC_notifyList		NotificationType \
			<MANUFACTURER_ID_GEOWORKS, GWNT_DOCUMENT_CHANGE>

EC_childList		GenControlChildInfo \
			<offset ExportTop,
				mask EXPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportFormatUIParent,
				mask EXPORTCF_FORMAT_OPTIONS,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportAppUIParent,
				mask EXPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportTrigger,
				mask EXPORTCF_EXPORT_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportCancelTrigger,
				0, mask GCCF_ALWAYS_ADD>

EC_featuresList		GenControlFeaturesInfo \
			<offset ExportDummyGlyph, 0, 0>,
			<offset ExportTop, 0, 0>,
			<offset ExportFormatUIParent, ExportFormatOptsName, 0>,
			<offset ExportTrigger, 0, 0>

EC_toolList		GenControlChildInfo \
			<offset ExportToolTrigger, mask EXPORTCTF_DIALOG_BOX,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

EC_toolFeaturesList	GenControlFeaturesInfo \
			<offset ExportToolTrigger, ExportTriggerToolName, 0>

EC_helpContext	char	"dbExport", 0

if FULL_EXECUTE_IN_PLACE
ImpexControlInfoXIP	ends
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFileSelectorOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ExportFileSelector if it exists

CALLED BY:	MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
PASS:		*ds:si	= ExportControlClass object
		dx	= export features mask
RETURN:		cx	= offset of ExportFileSelector
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFileSelectorOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	cx, offset ExportFileSelector
		ret
ExportControlGetFileSelectorOffset	endm

ExportControlGetFileSelectGroupOffset	method dynamic ExportControlClass,
				MSG_EXPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
		mov	cx, offset ExportFileSelectGroup
		ret
ExportControlGetFileSelectGroupOffset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFormatListOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ExportFormatList if it exists

CALLED BY:	MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
PASS:		*ds:si	= ExportControlClass object
		dx	= export features mask
RETURN:		cx	= offset of ExportFormatList if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFormatListOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET

		mov	cx, offset ExportFormatList
		ret
ExportControlGetFormatListOffset	endm

ExportControlGetFormatGroupOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
		mov	cx, offset ExportFormatGroup
		ret
ExportControlGetFormatGroupOffset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFileNameOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ExportFileName if it exists

CALLED BY:	MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
PASS:		*ds:si	= ExportControlClass object
		dx	= export features mask
RETURN:		cx	= offset of ExportFileName if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFileNameOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET

		test	dx, mask EXPORTCF_BASIC
		jz	done
		mov	cx, offset ExportFileName
done:
		ret
ExportControlGetFileNameOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFormatUIParentOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ExportFormatUIParent if it exists

CALLED BY:	MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
PASS:		*ds:si	= ExportControlClass object
		dx	= export features mask
RETURN:		cx	= offset of ExportFormatUIParent if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFormatUIParentOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET

		test	dx, mask EXPORTCF_FORMAT_OPTIONS
		jz	done
		mov	cx, offset ExportFormatUIParent
done:
		ret
ExportControlGetFormatUIParentOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetAppUIParentOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ExportFileMask if it exists

CALLED BY:	MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
PASS:		*ds:si	= ExportControlClass object
		dx	= export features mask
RETURN:		cx	= offset of ExportAppUIParent if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetAppUIParentOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET

		test	dx, mask EXPORTCF_BASIC
		jz	done
		mov	cx, offset ExportAppUIParent
done:
		ret
ExportControlGetAppUIParentOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetExportTriggerOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset of the export trigger if it exists

CALLED BY:	MSG_EXPORT_CONTROL_GET_EXPORT_TRIGGER_OFFSET
PASS:		*ds:si	= ExportControlClass object
		dx	= export features mask
RETURN:		cx	= offset of ExportTrigger if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetExportTriggerOffset	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_EXPORT_TRIGGER_OFFSET

		test	dx, mask EXPORTCF_EXPORT_TRIGGER
		jz	done
		mov	cx, offset ExportTrigger
done:
		ret
ExportControlGetExportTriggerOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add application-defined UI to Export dialog box

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		ES	= Segment of ExportControlClass
		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		AX	= Message passed

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlGenerateUI	method dynamic	ExportControlClass,
					MSG_GEN_CONTROL_GENERATE_UI
		.enter

		; First, call our superclass
		;
		mov	di, offset ExportControlClass
		call	ObjCallSuperNoLock

		; Update the data classes in the FormatList
		;
		mov	di, ds:[si]
		add	di, ds:[di].ExportControl_offset
		call	ExportSendDataClassesToFormatList

		; Now see if need to add any application-defined UI
		;
		mov	ax, ATTR_EXPORT_CONTROL_APP_UI
		call	ObjVarFindData		; ds:bx <- data
		jnc	done			; if none found, we're done

		mov	ax, MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- app UI parent offset
		jc	done

		call	ImpexAddAppUI		; add the application UI
done:		
		.leave
		ret
ExportControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove application-defined (or format-defined) UI from
		the Export dialog box

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_DESTROY_UI)

PASS:		ES	= Segment of ExportControlClass
		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		AX	= Message

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlDestroyUI	method dynamic	ExportControlClass,
					MSG_GEN_CONTROL_DESTROY_UI,
					MSG_META_DETACH

		; First destroy any format-specific UI
		;
		push	ax, cx, dx, bp		; save the passed message

		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format UI parent offset
		jc	doAppUI
		call	ImpexRemoveFormatUI
doAppUI:
		; Now destroy any application-specific UI
		;
		mov	ax, ATTR_EXPORT_CONTROL_APP_UI
		call	ObjVarFindData		; ds:bx <- data
		jnc	done			; if none found, we're done

		mov	ax, MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- app UI parent offset
		jc	done

		call	ImpexRemoveAppUI

		; Finally, call our superclass to clean things up
done:
		pop	ax, cx, dx, bp		; restore passed message
		mov	di, offset ExportControlClass
		GOTO	ObjCallSuperNoLock
ExportControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlInteractionInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate the export control

CALLED BY:	MSG_GEN_INTERACTION_INITIATE
PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 7/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlInteractionInitiate	method dynamic ExportControlClass, 
					MSG_GEN_INTERACTION_INITIATE
	;
	; Now tell user to insert translation library disk.
	;
	push	ax
	clr	ax
	pushdw	axax		; don't care about SDOP_helpContext
	pushdw	axax		; don't care about SDOP_customTriggers
	pushdw	axax		; don't care about SDOP_stringArg2
	pushdw	axax		; don't care about SDOP_stringArg1
	mov	bx, handle InsertImpexDiskString
	mov	ax, offset InsertImpexDiskString
	pushdw	bxax		; save SDOP_customString
	mov	ax, IMPEX_NOTIFICATION
	push	ax		; save SDOP_customFlags
	call	UserStandardDialogOptr
	pop	ax

	mov	di, offset ExportControlClass
	GOTO	ObjCallSuperNoLock

ExportControlInteractionInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlSelectFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a format has been selected for export

CALLED BY:	GLOBAL (MSG_IMPORT_EXPORT_SELECT_FORMAT)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		ES 	= segment of ExportControlClass
		CX	= Format #
		DX	= FormatInfo block

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		1) Create a default filename, based upon the file mask
		   provided by each translation format

		2) Load new format UI, and destroy the old as needed
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version
		jenny	1/92		Bug fix, cleanup
		don	5/27/92		Changed routine name, fixed stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if FULL_EXECUTE_IN_PLACE
idata	segment
endif

nullString	char	0

if FULL_EXECUTE_IN_PLACE
idata	ends
endif

ExportControlSelectFormat	method dynamic	ExportControlClass,
						MSG_IMPORT_EXPORT_SELECT_FORMAT

		; Get the offset of the format UI parent object, if
		; any, and remove any current format UI.
		;
		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format UI parent
						;  offset
		jc	noOldFormatUI
		call	ImpexRemoveFormatUI
noOldFormatUI:

		; Get the default file spec from the Library geode and
		; set it into the File Spec text edit object
		;
		cmp	cx, GIGS_NONE		; no selected ??
		je	done			; if none, we're done
		push	cx			; save element to access
		mov	bx, dx			; FormatInfo block => BX
		call	GetDefaultFileMask	; file mask => CX:DX
		call	ConstructDefaultName	; construct & set default name
		call	MemUnlock		; unlock the FormatInfo

		; Now we need to see if there is any new format UI
		;
		pop	cx			; cx <- format #
		tst	di
		jz	done			; done if no format UI parent
		mov	bx, di

		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format list
		jc	done

		mov	dx, TR_GET_EXPORT_UI
		mov	bp, offset IFD_exportUIFlag
		mov	ax, MSG_FORMAT_LIST_FETCH_FORMAT_UI
		call	ObjMessage_child_call
		LONG jc	error

		mov	di, bx			; di <- format UI parent offset
		mov	ax, TR_GET_EXPORT_UI
		mov	bx, TR_INIT_EXPORT_UI
		call	ImpexAddFormatUI	; update the UI
		clr	cx			; enable trigger and filename

		; Either enable or disable the Export trigger & the
		; filename text
done:
		mov	ax, MSG_EXPORT_CONTROL_GET_EXPORT_TRIGGER_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- export trigger offset
		jc	filename

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	cx, GIGS_NONE
		je	setState
		mov	ax, MSG_GEN_SET_ENABLED
setState:
		push	cx
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_child_call
		pop	cx
filename:
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- file name offset
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	cx, GIGS_NONE
		je	setStatus		; if error occurred, jump
		mov	ax, MSG_GEN_SET_ENABLED
setStatus:
		tst	di
		jz	exit			; no file name
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_child_send

		; If we've disable the filename text object, clear all of
		; the text out of there to remove any of the users doubts
		;
		cmp	ax, MSG_GEN_SET_NOT_ENABLED
		jne	checkList
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
NOFXIP	<	mov	dx, cs					>
FXIP	<	push	ds, bx					>
FXIP	<	mov	bx, handle dgroup			>
FXIP	<	call	MemDerefDS		; ds = dgroup	>
FXIP	<	mov	dx, ds					>
FXIP	<	pop	ds, bx					>
		mov	bp, offset nullString	
		clr	cx
		call	ObjMessage_child_call
checkList:
		; Check to make sure we have at least one translation library
		;
		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
		jc	exit

		mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
		call	ObjMessage_child_call
		tst	cx
		jnz	exit

		; Tell user to insert translation library disk
		;
		mov	bx, handle NoTranslationLibraryString
		call	MemLock
		mov	es, ax
		mov	di, offset NoTranslationLibraryString
		mov	di, es:[di]	; es:di = NoTranslationLibraryString

		mov	ax, MSG_EXPORT_CONTROL_INSERT_LIBRARY_DISK_RESPONSE
		push	ax		; save GADDP_message
		mov	ax, ds:[LMBH_handle]
		pushdw	axsi		; save GADDP_finishOD
		clr	ax
		pushdw	axax		; don't care about SDOP_helpContext
		mov	ax, offset SDRT_okCancel
		pushdw	csax		; don't care about SDOP_customTriggers
		clr	ax
		pushdw	axax		; don't care about SDOP_stringArg2
		pushdw	axax		; don't care about SDOP_stringArg1
		pushdw	esdi		; save SDOP_customString
		mov	ax, (CDT_NOTIFICATION shl offset CDBF_DIALOG_TYPE) or \
		       (GIT_MULTIPLE_RESPONSE shl offset CDBF_INTERACTION_TYPE)
		push	ax		; save SDOP_customFlags
		mov	bp, sp		; ss:bp = GenAppDoDialogParams

		clr	bx
		call	GeodeGetAppObject

		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		mov	dx, size GenAppDoDialogParams
		mov	di, mask MF_STACK or mask MF_CALL
		call	ObjMessage

		add	sp, size GenAppDoDialogParams	; fixup stack

		mov	bx, handle NoTranslationLibraryString
		call	MemUnlock
exit:
		ret

		; An error has ocurred, so disable the filename text object
error:
		mov	cx, GIGS_NONE		; disable trigger and filename
		jmp	done
ExportControlSelectFormat	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlInsertLibraryDiskResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle insert library disk dialog response

CALLED BY:	MSG_EXPORT_CONTROL_INSERT_LIBRARY_DISK_RESPONSE
PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #
		cx	= InteractionCommand
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	1/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlInsertLibraryDiskResponse	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_INSERT_LIBRARY_DISK_RESPONSE
	cmp	cx, IC_YES
	je	rescan

	; Dismiss interaction and cancel import
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_EXPORT_CONTROL_CANCEL
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

rescan:
	; Rescan new library disk
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_EXPORT_CONTROL_NEW_LIBRARY_DISK
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

ExportControlInsertLibraryDiskResponse	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlFreeLibraryAndFormatUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the passed library and free any format UI

CALLED BY:	MSG_IMPORT_EXPORT_FREE_LIBRARY_AND_FORMAT_UI
PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #
		cx	= library handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	12/ 9/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlFreeLibraryAndFormatUI	method dynamic ExportControlClass, 
			MSG_IMPORT_EXPORT_FREE_LIBRARY_AND_FORMAT_UI
	; Free library
	; 
	call	ImportExportFreeLibrary

	; Get the offset of the format UI parent object, if
	; any, and remove any current format UI.
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- format UI parent offset
	jc	done
	call	ImpexRemoveFormatUI
done:
	ret
ExportControlFreeLibraryAndFormatUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlTextEmptyStatusChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the empty status for a text object has changed

CALLED BY:	GLOBAL (MSG_META_TEXT_EMPTY_STATUS_CHANGED)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		CX:DX	= Text object OD
		BP	= Non-zero if text became non-empty

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlTextEmptyStatusChanged	method dynamic	ExportControlClass,
					MSG_META_TEXT_EMPTY_STATUS_CHANGED
		.enter

		; See if this is the export file name. 
		;
		call	ImpexGetChildBlockAndFeatures	; bx <- block handle
		jc	done
		cmp	bx, cx
		jne	done

		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- file name offset
		jc	done

		cmp	dx, di
		jne	done

		; This is the export file name. Enable the export
		; trigger if the name is non-empty and disable the
		; trigger if the name is empty.
		;
		mov	ax, MSG_EXPORT_CONTROL_GET_EXPORT_TRIGGER_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- trigger offset
		jc	done

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		tst	bp			; is the name empty?
		jz	setStatus
		mov	ax, MSG_GEN_SET_ENABLED
setStatus:
		call	ObjMessage_child_send		
done:
		.leave
		ret
ExportControlTextEmptyStatusChanged	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlExport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate an export

CALLED BY:	GLOBAL (MSG_EXPORT_CONTROL_EXPORT)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		* Do common setup work
		* Get the name of the destination file
		* Spawn the thread and export
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlExport	method dynamic	ExportControlClass,
					MSG_EXPORT_CONTROL_EXPORT
	CheckHack <(mask IA_IGNORE_INPUT) eq (mask ECA_IGNORE_INPUT)>

	; Redwood, nuke clipboard file for space reasons.  1/20/94 cbh
	;
	call	ClipboardFreeItemsNotInUse

	; Check if format list is displayed (usable)
	; If it is, then we must go to part 2, i.e. to disable
	; the format list and put up the file selector
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- format group offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>

	mov	ax, MSG_GEN_GET_USABLE
	call	ObjMessage_child_call
	LONG jnc formatListNotUsable

	; Mark busy
	;
	call	markAppBusy

	; Initialize the ImpexThreadInfo structure
	;
	mov	di, ds:[si]
	add	di, ds:[di].ExportControl_offset
	mov	cx, ds:[di].ECI_attrs

	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- format list offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	mov	bp, di

	mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- file selector offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>

	mov	dx, MSG_META_DUMMY	; send off dummy message to file select
	call	InitThreadInfoBlock

	; Store away the application destination OD & message
	;
	mov	di, ds:[si]
	add	di, ds:[di].ExportControl_offset
	mov	ax, ds:[di].ECI_message
	mov	es:[ITI_appMessage], ax
	movdw	es:[ITI_appDest], ds:[di].ECI_destination, ax
	mov	es:[ITI_notifySource].handle, handle ExportNotify
	mov	es:[ITI_notifySource].offset, offset ExportNotify
	or	es:[ITI_state], ITA_EXPORT shl offset ITS_ACTION

	push	ds
	segmov	ds, es
	mov	di, offset ITI_libraryDesc
	call	ImpexLoadLibrary	; library handle => BX
	pop	ds
	jnc	loadOK

	; Display error dialog
	;
	call	markAppNotBusy

	push	ds, es
	segmov	ds, es
	mov	dx, di			; ds:dx <- ITI_libraryDesc
	mov	bp, IE_COULD_NOT_LOAD_XLIB
	call	LockImpexError		; error string => ES:DI, flags => AX
	clr	bp
	pushdw	bpbp			; don't care about SDOP_helpContext
	pushdw	bpbp			; don't care about SDOP_customTriggers
	pushdw	bpbp			; don't care about SDOP_stringArg2
	pushdw	dsdx			; don't care about SDOP_stringArg1
	pushdw	esdi			; save SDOP_customString
	push	ax			; save SDOP_customFlags
	call	UserStandardDialog
	call	MemUnlock		; unlock Strings resource
	pop	ds, es

	call	markAppBusy

	clr	bx			; indicate no translation library
loadOK:
	mov	es:[ITI_libraryHandle], bx

	; Force the export library into memory and close the library file.
	;
	tst	bx
	jz	afterClose
	call	ImpexLoadAndCloseImpexLibrary
afterClose:

	push	bx			; save library handle
	mov	bx, es:[ITI_handle]
	call	MemUnlock

	; Save ImpexThreadInfo block handle in vardata
	;
	push	bx
	mov	ax, TEMP_EXPORT_CONTROL_IMPEX_THREAD_INFO
	mov	cx, size hptr
	call	ObjVarAddData
	pop	ds:[bx]
	pop	bx			; restore library handle

	; Cancel export if we don't have a translation library
	;
	tst	bx
	jnz	gotLib

	; Dismiss interaction and reset export control UI 
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	call	ExportControlResetUI
	jmp	notBusy

gotLib:
	; Mark not busy while we're asking user to insert disk.
	;
	call	markAppNotBusy

	; Now tell user to insert document disk.
	;
	clr	ax
	pushdw	axax			; don't care about SDOP_helpContext
	pushdw	axax			; don't care about SDOP_customTriggers
	pushdw	axax			; don't care about SDOP_stringArg2
	pushdw	axax			; don't care about SDOP_stringArg1
	mov	bx, handle InsertDocumentDiskString
	mov	ax, offset InsertDocumentDiskString
	pushdw	bxax			; save SDOP_customString
	mov	ax, IMPEX_NOTIFICATION
	push	ax			; save SDOP_customFlags
	call	UserStandardDialogOptr

	; Now mark busy again
	;
	call	markAppBusy

	; Get the current selection in the destination filename. We
	; need to reset this value, as the text object gets re-built
	; when we set the group usable. Annoying, but true. -Don 5/25/95
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
	mov	di, segment ExportControlClass
	mov	es, di
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- file name offset
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_RANGE
	sub	sp, (size VisTextRange)
	mov	dx, ss
	mov	bp, sp
	call	ObjMessage_child_call
	mov	cx, ss:[bp].VTR_start.low
	mov	dx, ss:[bp].VTR_end.low
	add	sp, (size VisTextRange)
	push	cx, dx, di		; save start, end, textObj chunk handle

	; Yes, format group was usable, so set it unusable
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
	mov	di, segment ExportControlClass
	mov	es, di
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- format group offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildNotUsable

	; Set format UI unusable
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- format UI parent offset
	jc	5$
	call	setChildNotUsable
5$:
	; Set app defined UI unusable
	;
	mov	ax, ATTR_EXPORT_CONTROL_APP_UI
	call	ObjVarFindData			; ds:bx <- extra data
	jnc	10$				; if non found, we're done
	mov	ax, MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- app UI parent offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildNotUsable
10$:
	; Set file select group usable
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- fileselect group offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildUsable

	; Reset the selection in the export file's filename
	;
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	pop	cx, dx, di		; restore start, end, textObj handle
	call	ObjMessage_child_call

notBusy:
	; Mark not busy
	;
	call	markAppNotBusy
	ret


formatListNotUsable:
	;
	; Get the ImpexThreadInfo block handle
	;
	mov	ax, TEMP_EXPORT_CONTROL_IMPEX_THREAD_INFO
	call	ObjVarFindData
EC <	ERROR_NC -1				; vardata must exist	>
	mov	ax, ds:[bx]
	call	ObjVarDeleteDataAt

	mov_tr	bx, ax
	call	MemLock

	;
	; Get the path for the destination file from the ExportFileSelector.
	;
	push	ax				; save ImpexThreadInfo segment
	mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- file selector offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	pop	es				; es <- ImpexThreadInfo segment

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	mov	cx, (size ITI_pathBuffer)
	mov	dx, es
	mov	bp, offset ITI_pathBuffer	; dx:bp <- buffer
	call	ObjMessage_child_call
	mov	es:[ITI_pathDisk], cx

	; Load in the name of the destination file
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
	mov	di, segment ExportControlClass
	mov	es, di
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- file name offset

	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	bp, offset ITI_srcDestName
	call	ObjMessage_child_call

	; Dismiss interaction and reset export control UI 
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	call	ExportControlResetUI

	; Now spawn the thread
	;
	mov	ax, MSG_ITP_EXPORT
	call	SpawnThread
	ret


setChildUsable:
	mov	ax, MSG_GEN_SET_USABLE
	jmp	callChild
setChildNotUsable:
	mov	ax, MSG_GEN_SET_NOT_USABLE
callChild:
	mov	dl, VUM_NOW
	call	ObjMessage_child_call
	retn

markAppBusy:
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_COMPLETELY_BUSY
	jmp	callApp
markAppNotBusy:
	mov	ax, MSG_GEN_APPLICATION_MARK_APP_NOT_COMPLETELY_BUSY
callApp:
	call	UserCallApplication
	retn

ExportControlExport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel an Export

CALLED BY:	MSG_EXPORT_CONTROL_CANCEL
PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlCancel	method dynamic ExportControlClass, 
					MSG_EXPORT_CONTROL_CANCEL
	; Get rid of ImpexThreadInfo block
	;
	mov	ax, TEMP_EXPORT_CONTROL_IMPEX_THREAD_INFO
	call	ObjVarFindData
	jnc	removeFormatUI

	mov	ax, ds:[bx]
	call	ObjVarDeleteDataAt

	mov_tr	bx, ax				; bx <- ^hImpexThreadInfo
	call	MemLock
	push	ds
	mov	ds, ax
	mov	cx, ds:[ITI_libraryHandle]
	pop	ds
	call	MemFree
	jcxz	removeFormatUI

	mov	bx, cx
	call	GeodeFreeLibrary

removeFormatUI:
	;
	; Get the offset of the format UI parent object, if
	; any, and remove any current format UI.
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- format UI parent offset
	jc	done
	call	ImpexRemoveFormatUI
done:
	FALL_THRU	ExportControlResetUI

ExportControlCancel	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlResetUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset export control UI

CALLED BY:	ExportControlExport
		ExportControlCancel
PASS:		*ds:si	= ExportControlClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	12/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlResetUI	proc	far
	uses	bx
	.enter

	; Set file select group unusable
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
	mov	di, segment ExportControlClass
	mov	es, di
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- fileselect group offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildNotUsable

	; Set format group usable
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- format group offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildUsable

	; Set format UI usable
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- format UI parent offset
	jc	20$
	call	setChildUsable
20$:
	; Set app defined UI usable
	;
	mov	ax, ATTR_EXPORT_CONTROL_APP_UI
	call	ObjVarFindData			; ds:bx <- extra data
	jnc	30$				; if non found, we're done
	mov	ax, MSG_EXPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset		; di <- app UI parent offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildUsable
30$:

	; Clear out format list
	;
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- format list offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	clr	cx
	call	ObjMessage_child_call

	.leave
	ret


setChildUsable:
	mov	ax, MSG_GEN_SET_USABLE
	jmp	callChild
setChildNotUsable:
	mov	ax, MSG_GEN_SET_NOT_USABLE
callChild:
	mov	dl, VUM_NOW
	call	ObjMessage_child_call
	retn
ExportControlResetUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlNewLibraryDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rescan format list

CALLED BY:	MSG_EXPORT_CONTROL_NEW_LIBRARY_DISK
PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlNewLibraryDisk	method dynamic ExportControlClass, 
					MSG_EXPORT_CONTROL_NEW_LIBRARY_DISK
	mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
	mov	di, offset ExportControlClass
	call	ImpexGetChildOffset	; di <- format list offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>

	mov	ax, MSG_FORMAT_LIST_RESCAN
	call	ObjMessage_child_call
	ret
ExportControlNewLibraryDisk	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportSendDataClassesToFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the data classes to the format list

CALLED BY:	INTERNAL

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportSendDataClassesToFormatList	proc	near
		class	ExportControlClass
		.enter
	
		mov	cx, ds:[di].ECI_dataClasses

		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
		jc	exit

		mov	ax, MSG_FORMAT_LIST_SET_DATA_CLASSES
		call	ObjMessage_child_send
exit:
		.leave
		ret
ExportSendDataClassesToFormatList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConstructDefaultName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Construct a default name for the file to be exported, based
		upon the file mask for the format.

CALLED BY:	INTERNAL

PASS:		*DS:SI	= ExportControlClass object
		CX:DX	= Default format file mask

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConstructDefaultName	proc	near
		uses	bx, di, es
		.enter
	
		; Find the text object
		;
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
		mov	di, segment ExportControlClass
		mov	es, di
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- file name offset
		jc	exit

		; Determine if the text is dirty. If it is, then
		; we call EditDefaultName, to preserve the user's changes
		;
		push	cx
		mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
		call	ObjMessage_child_call
		jcxz	createDefault
		pop	cx
		call	EditDefaultName
		jmp	exit

		; First copy the "UNNAMED" string into a buffer
createDefault:
		pop	cx
		mov	bx, di
		sub	sp, PATH_BUFFER_SIZE
		segmov	es, ss
		mov	di, sp			; buffer => ES:DI
		push	bx			; save text object offset
		push	ds, si			; save ExportControl object
		push	cx
		mov	si, offset NoNameString
		call	LockString		; string => DS:SI
		ChunkSizePtr	ds, si, cx	; string length (w/NULL) => CX
		dec	cx
		mov	bp, cx			; base-name length => BP
		rep	movsb			; copy the string
		call	MemUnlock		; unlock strings resource

		; Find the extension
		;
		pop	ds
		mov	si, dx			; file mask => DS:SI
findNext:
		lodsb
		tst	al			; check for NULL
		jz	nullTerminate		; if done, boogie
		cmp	al, '.'
		jne	findNext
		mov	cx, ax			; cx <- non-zero,
						;  meaning no extension yet

		; Copy the '.' and the extension, unless it contains wildcards
nextExtChar:
		stosb
		lodsb
		tst	al			; check for NULL
		jz	stringDone		; if done, boogie
		cmp	al, '?'
		je	stringDone
		cmp	al, '*'
		je	stringDone
		clr	cx			; now copying extension
		jmp	nextExtChar
stringDone:
		jcxz	nullTerminate		; if no extension after the
		dec	di			;  '.', we'll erase the '.'

		; NULL-terminate the string, and set the text. We also
		; select the text, to make the user's life easy.
nullTerminate:
		mov	{byte} es:[di], 0
		pop	ds, si			; ExportControl => *DS:SI
		pop	di			; text object offset => DI
		mov	bx, bp			; base-name length => BX
		mov	bp, sp
		mov	dx, es			; string => DX:BP
		mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
		call	DefaultNameSetText
		add	sp, PATH_BUFFER_SIZE	; clean up the stack
exit:
		.leave
		ret
ConstructDefaultName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EditDefaultName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Edit the default name for the file to be exported, based
		upon the file mask for the format & the text the user has
		already entered.

CALLED BY:	ConstructDefaultName

PASS:		*DS:SI	= ExportControlClass object
		DI	= File mask offset
		CX:DX	= Default format file mask

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EditDefaultName	proc	near
		.enter
	
		; Get the current text
		;
		mov_tr	ax, cx
		mov	cx, PATH_BUFFER_SIZE
		sub	sp, cx
		mov	bp, sp
		push	ax, dx			; save default file mask
		mov	dx, ss
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage_child_call	; length of text => CX

		; Upcase the string (for beautification)
		;
		push	ds, si
		mov	ds, dx
		mov	si, bp
		call	LocalUpcaseString
		pop	ds, si

		; Scan for the period. If one isn't found, then stick
		; one in.
		;
		push	di			; save text object chunk
		mov	es, dx
		mov	di, bp
		mov	dx, bp			; save start of text
SBCS <		mov	al, '.'						>
SBCS <		repne	scasb						>
DBCS <		mov	ax, '.'						>
DBCS <		repne	scasw						>
		mov	bp, di			; start of extension => BP
		pop	di			; restore text object chunk
		pop	es, bx			; default file mask => ES:BX
		jz	findDefaultExt		; if match, then continue
		LocalPutChar	ssbp, ax

		; We've found the source extension. Find the extension of
		; of the default file mask. If none is found, then terminate
		; the string (removing the extension).
findDefaultExt:
		push	bp			; save extension offset
scanNextChar:
		LocalGetChar	ax, esbx
		LocalCmpChar	ax, '.'
		je	copyNextChar
		LocalIsNull	ax
		jnz	scanNextChar
		dec	bp			; nuke trailing period
DBCS <		dec	bp			; nuke rest of it	>
		jmp	terminate		; terminate the string

		; Copy the new extension onto the old. If any wildcards are
		; found in the extension, ignore them (there should generally
		; not be any).
copyNextChar:
		LocalGetChar	ax, esbx
		LocalCmpChar	ax, '?'
		je	terminate
		LocalCmpChar	ax, '*'
		je	terminate
		LocalPutChar	ssbp, ax
		LocalIsNull	ax
		jne	copyNextChar
terminate:
SBCS <		mov	{byte} ss:[bp], 0				>
DBCS <		mov	{wchar} ss:[bp], 0				>
		pop	bx
		sub	bx, dx
		dec	bx			; string length => BX

		; Replace the text, and re-select everything up until
		; the start of the extension
		;
		mov	bp, dx
		mov	dx, ss			; text => DX:BP
		mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
		call	DefaultNameSetText
		add	sp, PATH_BUFFER_SIZE	; clean up the stack

		.leave
		ret
EditDefaultName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DefaultNameSetText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text in the default name text object

CALLED BY:	ConstructDefaultName, EditDefaultName

PASS:		*DS:SI	= ExportControlClass
		DI	= Text object offset
		DX:BP	= Default text
		BX	= End of "base" of file name
		AX	= Message to send after setting text
				MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
				MSG_VIS_TEXT_SET_USER_MODIFIED

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/24/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DefaultNameSetText	proc	near
		.enter
	
		push	ax
		clr	cx			; it is NULL-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessage_child_call
		mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
		clr	cx			; start selection => CX
		mov	dx, bx			; end selection => DX
		call	ObjMessage_child_call
		pop	ax
		call	ObjMessage_child_call

		.leave
		ret
DefaultNameSetText	endp

ImpexUICode	ends
