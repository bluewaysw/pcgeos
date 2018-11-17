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

	$Id: uiExportCtrl.asm,v 1.1 97/04/04 21:58:36 newdeal Exp $

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
			<offset ExportGlyphParent,
				mask EXPORTCF_GLYPH,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportAppUIParent,
				mask EXPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportFileNameAndFormatListParent,
				mask EXPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportFormatUIParent,
				mask EXPORTCF_FORMAT_OPTIONS,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportFileSelector,
				mask EXPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ExportTrigger,
				mask EXPORTCF_EXPORT_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

EC_featuresList		GenControlFeaturesInfo \
			<offset ExportGlyphParent, 0, 0>,
			<offset ExportFormatListParent, 0, 0>,
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
		test	dx, mask EXPORTCF_BASIC
		jz	done
		mov	cx, offset ExportFileSelector
done:
		ret
ExportControlGetFileSelectorOffset	endm


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

		test	dx, mask EXPORTCF_BASIC
		jz	done
		mov	cx, offset ExportFormatList
done:
		ret
ExportControlGetFormatListOffset	endm


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
		ExportControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	modify UI of Export dialog box

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		ES	= Segment of ExportControlClass
		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance
		AX	= Message passed
		cx	= block
		dx	= features

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		brianc	1/29/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlTweakDuplicatedUI	method	dynamic	ExportControlClass, MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	;
	; remove path list and file list for CUI
	;
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		jne	done
		mov	bx, cx
		mov	si, offset ExportFileSelector
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx = attrs
		andnf	cx, not (mask FSA_HAS_CHANGE_DIRECTORY_LIST or mask FSA_HAS_FILE_LIST)
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; turn off directories
	;
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FILE_CRITERIA
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx = crit
		andnf	cx, not mask FSFC_DIRS
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_FILE_CRITERIA
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
		ret
ExportControlTweakDuplicatedUI	endm


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

SYNOPSIS:	Initiate the ExportControl

CALLED BY:	GLOBAL (MSG_GEN_INTERACTION_INITIATE)

PASS:		*DS:SI	= ExportControlClass object
		DS:DI	= ExportControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/27/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportControlInteractionInitiate	method dynamic	ExportControlClass,
					MSG_GEN_INTERACTION_INITIATE

		; Ask the FormatList to send out its status, so
		; that the default file name will be correctly
		; updated in case the user has edited it. To do
		; this, the text object must think the user has not
		; mucked with it.
		;
		push	ax
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- file name offset
		jc	callSuperClass
		mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
		call	ObjMessage_child_call

		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format list
		jc	callSuperClass
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		call	ObjMessage_child_call

		; Call our superclass
callSuperClass:
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

LocalDefNLString	nullString <0>

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
		jc	error

		mov	di, bx			; di <- format UI parent offset
		mov	ax, TR_GET_EXPORT_UI
		mov	bx, TR_INIT_EXPORT_UI
		call	ImpexAddFormatUI	; update the UI
		clr	cx			; enable trigger and filename

		; Either enable or disable the Export trigger & the
		; filename text
done:
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
		jne	exit
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
exit:
		ret

		; An error has ocurred, so disable the filename text object
error:
		mov	cx, GIGS_NONE		; disable trigger and filename
		jmp	done
ExportControlSelectFormat	endm


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
		.enter


		; Initialize the ImpexThreadInfo structure
		;
		CheckHack <(mask IA_IGNORE_INPUT) eq (mask ECA_IGNORE_INPUT)>
		mov	cx, ds:[di].ECI_attrs

		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	bp, di
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	dx, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
		call	InitThreadInfoBlock
		jc	exit

		; Store away the application destination OD & message
		;
		mov	di, ds:[si]
		add	di, ds:[di].ExportControl_offset
		mov	ax, ds:[di].ECI_message
		mov	es:[ITI_appMessage], ax
		movdw	cxax, ds:[di].ECI_destination
		movdw	es:[ITI_appDest], cxax		
		mov	es:[ITI_notifySource].handle, handle ExportNotifyUI
		mov	es:[ITI_notifySource].offset, offset ExportNotify
		or	es:[ITI_state], ITA_EXPORT shl offset ITS_ACTION

		; Load in the name of the destination file
		;
		mov	dx, es
		mov	bp, offset ITI_srcDestName

		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
		mov	di, segment ExportControlClass
		mov	es, di
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di <- file name offset
		jc	exit

		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjMessage_child_call

ifdef GPC_ONLY
		; If the filename does not have an extension, tack on the
		; default extension for the selected format.
		;
		call	EnsureFileNameHasExtension
endif
	
		; Now spawn the thread
		;
		mov	ax, MSG_ITP_EXPORT
		call	SpawnThread
exit:
		.leave
		ret
ExportControlExport	endm



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
DBCS <		shr	cx, 1			; cx <- string length	>
		dec	cx
		mov	bp, cx			; base-name length => BP
		LocalCopyNString		; rep movsb/movsw
		call	MemUnlock		; unlock strings resource

		; Find the extension
		;
		pop	ds
		mov	si, dx			; file mask => DS:SI
findNext:
		LocalGetChar ax, dssi
		LocalIsNull ax			; check for NULL
		jz	nullTerminate		; if done, boogie
		LocalCmpChar ax, '.'
		jne	findNext
		mov	cx, ax			; cx <- non-zero,
						;  meaning no extension yet

		; Copy the '.' and the extension, unless it contains wildcards
nextExtChar:
		LocalPutChar esdi, ax
		LocalGetChar ax, dssi
		LocalIsNull ax			; check for NULL
		jz	stringDone		; if done, boogie
		LocalCmpChar ax, '?'
		je	stringDone
		LocalCmpChar ax, '*'
		je	stringDone
		clr	cx			; now copying extension
		jmp	nextExtChar
stringDone:
		jcxz	nullTerminate		; if no extension after the
		LocalPrevChar esdi		;  '.', we'll erase the '.'

		; NULL-terminate the string, and set the text. We also
		; select the text, to make the user's life easy.
nullTerminate:
SBCS <		mov	{byte} es:[di], 0				>
DBCS <		mov	{wchar} es:[di], 0				>
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

if	not _DOS_LONG_NAME_SUPPORT
		; Upcase the string (for beautification)
		;
		push	ds, si
		mov	ds, dx
		mov	si, bp
		call	LocalUpcaseString
		pop	ds, si
endif	; not _DOS_LONG_NAME_SUPPORT

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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFileNameField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the optr of the filename text field, if built.

CALLED BY:	MSG_EXPORT_CONTROL_GET_FILE_NAME_FIELD

PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #

RETURN:		^lcx:dx = the text object
		carry set if the child hasn't been built yet

DESTROYED:	ax, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/07/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFileNameField	method dynamic ExportControlClass, 
				MSG_EXPORT_CONTROL_GET_FILE_NAME_FIELD
		uses	ax, bp
		.enter

		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di = file selector offset

		call	ImpexGetChildBlockAndFeatures	; bx = block

		movdw	cxdx, bxdi

		.leave
		ret
ExportControlGetFileNameField	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the format list optr.

CALLED BY:	MSG_EXPORT_CONTROL_GET_FORMAT_LIST

PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #

RETURN:		^lcx:dx = optr, if built (carry set if not)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/13/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFormatList	method dynamic ExportControlClass, 
					MSG_EXPORT_CONTROL_GET_FORMAT_LIST
		uses	ax, bp
		.enter

		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di = file selector offset

		call	ImpexGetChildBlockAndFeatures	; bx = block

		movdw	cxdx, bxdi

		.leave
		ret
ExportControlGetFormatList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportControlGetFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the format list optr.

CALLED BY:	MSG_EXPORT_CONTROL_GET_FILE_SELECTOR

PASS:		*ds:si	= ExportControlClass object
		ds:di	= ExportControlClass instance data
		ds:bx	= ExportControlClass object (same as *ds:si)
		es 	= segment of ExportControlClass
		ax	= message #

RETURN:		^lcx:dx = optr, if built (carry set if not)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/13/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExportControlGetFileSelector	method dynamic ExportControlClass, 
					MSG_EXPORT_CONTROL_GET_FILE_SELECTOR
		uses	ax, bp
		.enter

		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ExportControlClass
		call	ImpexGetChildOffset	; di = file selector offset

		call	ImpexGetChildBlockAndFeatures	; bx = block
		movdw	cxdx, bxdi

		.leave
		ret
ExportControlGetFileSelector	endm

ifdef GPC_ONLY

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureFileNameHasExtension
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the filename (ITI_srcDestName) does not have an
		extension, tack on the default extension for the selected
		format.

CALLED BY:	ExportControlExport
PASS:		cx	= length of file name not counting NULL
		dx	= segment of ImpexThreadInfo
RETURN:		nothing
DESTROYED:	CX, SI, DI, ES
SIDE EFFECTS:	ITI_srcDestName possibly updated

PSEUDO CODE/STRATEGY:
		Scan filename for extension
		Exit if extension found
		Otherwise,
			Get current format's file mask
			Append extension from mask to filename

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	9/15/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnsureFileNameHasExtension	proc	near
		uses	ax,ds
		.enter

		; Scan for the period. If one is found, then exit.
		; Otherwise, stick one in and continue.
		;
		mov	es, dx
		mov	di, offset ITI_srcDestName
SBCS <		mov	al, '.'						>
SBCS <		repne	scasb						>
DBCS <		mov	ax, '.'						>
DBCS <		repne	scasw						>
		mov	bp, di			; start of extension => BP
		jz	done			; if match, then exit
		LocalPutChar esdi, ax		; store the period

		; Find the extension of the default file mask. If none is
		; found, then terminate the string (removing the period).
		;
		mov	si, offset ITI_formatDesc.IFD_defaultFileMask
		segmov	ds, es, ax		; ds:si = file mask
scanNextChar:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '.'
		je	copyNextChar
		LocalIsNull	ax
		jnz	scanNextChar
		dec	di			; nuke trailing period
DBCS <		dec	di			; nuke rest of it	>
		jmp	terminate		; terminate the string

		; Copy the new extension onto the old. If any wildcards are
		; found in the extension, ignore them (there should generally
		; not be any).
copyNextChar:
		LocalGetChar	ax, dssi
		LocalCmpChar	ax, '?'
		je	terminate
		LocalCmpChar	ax, '*'
		je	terminate
		LocalPutChar	esdi, ax
		LocalIsNull	ax
		jne	copyNextChar
terminate:
		LocalClrChar	ds:[di]

done:
		.leave
		ret
EnsureFileNameHasExtension	endp
endif

ImpexUICode	ends
