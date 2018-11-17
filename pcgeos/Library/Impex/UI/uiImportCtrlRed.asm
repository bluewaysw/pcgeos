COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Impex/UI
FILE:		uiImportCtrl.asm

AUTHOR:		Don Reeves, May 26, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT ImportSendDataClassesToFormatList Send the data classes to the
				format list

    INT SetFileMask		Set the file mask

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/26/92		Initial revision


DESCRIPTION:
	Contains the code implementing the ImportControlClass

	$Id: uiImportCtrlRed.asm,v 1.3 98/07/20 18:06:30 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImpexUICode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** External Messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSetDataClasses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the data classes to be displayed for import

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_SET_DATA_CLASSES)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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

ImportControlSetDataClasses	method dynamic	ImportControlClass,
				MSG_IMPORT_CONTROL_SET_DATA_CLASSES
		.enter

		; Store the data away, and notify our child if needed
		;
EC <		test	cx, not ImpexDataClasses			>
EC <		ERROR_NZ ILLEGAL_IMPEX_DATA_CLASSES			>
		mov	ds:[di].ICI_dataClasses, cx
		call	ImportSendDataClassesToFormatList

		.leave
		ret
ImportControlSetDataClasses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetDataClasses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the data classes displayed for import

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_GET_DATA_CLASSES)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance

RETURN:		CX	= ImpexDataClasses

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlGetDataClasses	method dynamic	ImportControlClass,
				MSG_IMPORT_CONTROL_GET_DATA_CLASSES
		.enter

		mov	cx, ds:[di].ICI_dataClasses

		.leave
		ret
ImportControlGetDataClasses	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSetAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the action (message and OD to send it to) for import

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_SET_ACTION)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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

ImportControlSetAction	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_SET_ACTION
		.enter

		movdw	ds:[di].ICI_destination, cxdx
		mov	ds:[di].ICI_message, bp

		.leave
		ret
ImportControlSetAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSetMsg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the message for import

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_SET_MSG)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
		CX	= Message to send

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlSetMsg	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_SET_MSG
		.enter

		mov	ds:[di].ICI_message, cx

		.leave
		ret
ImportControlSetMsg	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the action to be used upon import

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_GET_ACTION)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance

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

ImportControlGetAction	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_GET_ACTION
		.enter

		movdw	cxdx, ds:[di].ICI_destination
		mov	bp, ds:[di].ICI_message

		.leave
		ret
ImportControlGetAction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the attributes for an ImportControl object

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_SET_ATTRS)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
		CX	= ImportControlAttrs

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlSetAttrs	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_SET_ATTRS
		.enter
if 0
EC <		test	cx, not ImportControlAttrs			>
EC <		ERROR_NZ IMPORT_CONTROL_ILLEGAL_ATTRS			>
		mov	ds:[di].ICI_attrs, cx
endif
		.leave
		ret
ImportControlSetAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the attributes for an ImportControl object

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_GET_ATTRS)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance

RETURN:		CX	= ImportControlAttrs

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlGetAttrs	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_GET_ATTRS
		.enter
if 0
		mov	cx, ds:[di].ICI_attrs
endif
		.leave
		ret
ImportControlGetAttrs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlImportComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An application has reported that is import is complete.

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_IMPORT_COMPLETE)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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

ImportControlImportComplete	method dynamic	ImportControlClass,
				MSG_IMPORT_CONTROL_IMPORT_COMPLETE

		; Send a message of to the import thread
		;
		mov	ax, MSG_ITP_IMPORT_TO_APP_COMPLETE
		mov	bx, ss:[bp].ITP_internal.low
		mov	cx, ss:[bp].ITP_internal.high
		mov	dx, size ImpexTranslationParams
		mov	di, mask MF_STACK
		GOTO	ObjMessage		

ImportControlImportComplete	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Internal Messages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlBuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept building of visual tree

CALLED BY:	GLOBAL (MSG_SPEC_BUILD_BRANCH)

PASS:		ES	= Segment of ImportControlClass
		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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
ImportControlBuildBranch	method dynamic	ImportControlClass,
						MSG_SPEC_BUILD_BRANCH

		; Add a moniker (if needed) for import
		;
		mov	dx, handle DefaultImportMoniker
		mov	cx, offset DefaultImportMoniker
		call	ImpexCopyDefaultMoniker

		; Call our superclass to finish the work
		;
		mov	di, offset ImportControlClass
		GOTO	ObjCallSuperNoLock
ImportControlBuildBranch	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the ImportControl object

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		*DS:SI	= ImportControlControlClass object
		DS:DI	= ImportControlControlClassInstance
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

ImportControlGetInfo	method dynamic 	ImportControlClass,
					MSG_GEN_CONTROL_GET_INFO
		.enter

		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset IC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
ImportControlGetInfo	endm

IC_dupInfo	GenControlBuildInfo		<
		mask GCBF_MANUALLY_REMOVE_FROM_ACTIVE_LIST,	; GCBI_flags
		IC_initFileKey,			; GCBI_initFileKey
		0,				; GCBI_gcnList
		0,				; GCBI_gcnCount
		0,				; GCBI_notificationList
		0,				; GCBI_notificationCount
		ImportControllerName,		; GCBI_controllerName

		handle ImportControlUI,		; GCBI_dupBlock
		IC_childList,			; GCBI_childList
		length IC_childList,		; GCBI_childCount
		IC_featuresList,		; GCBI_featuresList
		length IC_featuresList,		; GCBI_featuresCount
		IMPORTC_DEFAULT_FEATURES,	; GCBI_features

		handle ImportToolboxUI,		; GCBI_toolBlock
		IC_toolList,			; GCBI_toolList
		length IC_toolList,		; GCBI_toolCount
		IC_toolFeaturesList,		; GCBI_toolFeaturesList
		length IC_toolFeaturesList,	; GCBI_toolFeaturesCount
		IMPORTC_DEFAULT_TOOLBOX_FEATURES, ; GCBI_toolFeatures
		IC_helpContext>			; GCBI_helpContext

if FULL_EXECUTE_IN_PLACE
ImpexControlInfoXIP	segment	resource
endif

IC_initFileKey	char	"importControl", 0

IC_childList		GenControlChildInfo \
			<offset ImportTop,
				mask IMPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportFileMask,
				mask IMPORTCF_FILE_MASK,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportFormatUIParent,
				mask IMPORTCF_FORMAT_OPTIONS,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportAppUIParent,
				mask IMPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportTrigger,
				mask IMPORTCF_IMPORT_TRIGGER,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportCancelTrigger,
				0, mask GCCF_ALWAYS_ADD>

IC_featuresList		GenControlFeaturesInfo \
			<offset ImportDummyGlyph, 0, 0>,
			<offset ImportTop, 0, 0>,
			<offset ImportFileMask, 0, 0>,
			<offset ImportFormatUIParent, ImportFormatOptsName, 0>,
			<offset ImportTrigger, 0, 0>

IC_toolList		GenControlChildInfo \
			<offset ImportToolTrigger, mask IMPORTCTF_DIALOG_BOX,
				mask GCCF_IS_DIRECTLY_A_FEATURE>

IC_toolFeaturesList	GenControlFeaturesInfo \
			<offset ImportToolTrigger, ImportTriggerToolName, 0>

IC_helpContext	char	"dbImport", 0

if FULL_EXECUTE_IN_PLACE
ImpexControlInfoXIP	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetFileSelectorOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ImportFileSelector if it exists

CALLED BY:	MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
PASS:		*ds:si	= ImportControlClass object
		dx	= import features mask
RETURN:		cx	= offset of ImportFileSelector
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetFileSelectorOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	cx, offset ImportFileSelector
		ret
ImportControlGetFileSelectorOffset	endm

ImportControlGetFileSelectGroupOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
		mov	cx, offset ImportFileSelectGroup
		ret
ImportControlGetFileSelectGroupOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetFormatListOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ImportFormatList if it exists

CALLED BY:	MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
PASS:		*ds:si	= ImportControlClass object
		dx	= import features mask
RETURN:		cx	= offset of ImportFormatList if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetFormatListOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	cx, offset ImportFormatList
		ret
ImportControlGetFormatListOffset	endm

ImportControlGetFormatGroupOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
		mov	cx, offset ImportFormatGroup
		ret
ImportControlGetFormatGroupOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetFormatUIParentOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ImportFormatUIParent if it exists

CALLED BY:	MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
PASS:		*ds:si	= ImportControlClass object
		dx	= import features mask
RETURN:		cx	= offset of ImportFormatUIParent if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetFormatUIParentOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET

		test	dx, mask IMPORTCF_FORMAT_OPTIONS
		jz	done
		mov	cx, offset ImportFormatUIParent
done:
		ret
ImportControlGetFormatUIParentOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetAppUIParentOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ImportAppUIParent if it exists

CALLED BY:	MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
PASS:		*ds:si	= ImportControlClass object
		dx	= import features mask
RETURN:		cx	= offset of ImportAppUIParent if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetAppUIParentOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET

		mov	cx, offset ImportAppUIParent
		ret
ImportControlGetAppUIParentOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetImportTriggerOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset of the import trigger if it exists

CALLED BY:	MSG_IMPORT_CONTROL_GET_IMPORT_TRIGGER_OFFSET
PASS:		*ds:si	= ImportControlClass object
		dx	= import features mask
RETURN:		cx	= offset of ImportTrigger if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetImportTriggerOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_IMPORT_TRIGGER_OFFSET

		test	dx, mask IMPORTCF_IMPORT_TRIGGER
		jz	done
		mov	cx, offset ImportTrigger
done:
		ret
ImportControlGetImportTriggerOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGenerateUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add application-defined UI to Import dialog box

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		ES	= Segment of ImportControlClass
		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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

ImportControlGenerateUI	method dynamic	ImportControlClass,
					MSG_GEN_CONTROL_GENERATE_UI
		.enter

		; First, call our superclass
		;
		mov	di, offset ImportControlClass
		call	ObjCallSuperNoLock

		; Update the data classes in the FormatList
		;
		mov	di, ds:[si]
		add	di, ds:[di].ImportControl_offset
		call	ImportSendDataClassesToFormatList

		; Now see if need to add any application-defined UI
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- app UI parent offset
		jc	done

		mov	ax, ATTR_IMPORT_CONTROL_APP_UI
		call	ObjVarFindData		; ds:bx <- data
		jnc	done			; if none found, we're done

		call	ImpexAddAppUI		; add the application UI
done:		
		.leave
		ret
ImportControlGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlDestroyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove application-defined (or format-defined) UI from
		the Import dialog box

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_DESTROY_UI)

PASS:		ES	= Segment of ImportControlClass
		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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

ImportControlDestroyUI	method dynamic	ImportControlClass,
					MSG_GEN_CONTROL_DESTROY_UI,
					MSG_META_DETACH

		; First destroy any format-specific UI
		;
		push	ax, cx, dx, bp		; save the passed message

		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format UI parent
						;  offset
		jc	doAppUI
		call	ImpexRemoveFormatUI
doAppUI:
		; Now destroy any application-specific UI
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- app UI parent offset
		jc	done

		mov	ax, ATTR_IMPORT_CONTROL_APP_UI
		call	ObjVarFindData		; ds:bx <- data
		jnc	done			; if none found, we're done

		call	ImpexRemoveAppUI

		; Finally, call our superclass to clean things up
done:
		pop	ax, cx, dx, bp		; restore passed message
		mov	di, offset ImportControlClass
		GOTO	ObjCallSuperNoLock
ImportControlDestroyUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSelectFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that a format has been selected for import

CALLED BY:	GLOBAL (MSG_IMPORT_EXPORT_SELECT_FORMAT)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
		CX	= Format #
		DX	= FormatInfo block
		BP	= TRUE if "No Idea" choice is present;
			  FALSE, otherwise

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version
		jenny	1/92		Cleaned up
		Don	5/27/92		Renamed, cleaned up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlSelectFormat	method dynamic	ImportControlClass,
						MSG_IMPORT_EXPORT_SELECT_FORMAT
		.enter

		; Get the offset of the format UI parent object, if
		; any, and remove any current format UI.
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format UI parent offset
		jc	noOldFormatUI
		call	ImpexRemoveFormatUI
noOldFormatUI:
		; Get the default file spec from the Library geode and
		; set it into the File Mask text edit object.
		;
		cmp	cx, GIGS_NONE
		je	done			; done if nothing selected
		tst	bp			; If "No Idea" choice is
		jz	doFormatUI		; ...not present, do format UI
		jcxz	done			; Else, done
		dec	cx			; ...or adjust element number
doFormatUI:
		; Now we need to see if there is any new format UI.
		;
		tst	di
		jz	done			; done if no format UI parent
		mov	bx, di

		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
		jc	done

		mov	dx, TR_GET_IMPORT_UI
		mov	bp, offset IFD_importUIFlag
		mov	ax, MSG_FORMAT_LIST_FETCH_FORMAT_UI
		call	ObjMessage_child_call
		jc	done			; if error, done

		mov	di, bx			; di <- format UI parent offset
		mov	ax, TR_GET_IMPORT_UI
		mov	bx, TR_INIT_IMPORT_UI
		call	ImpexAddFormatUI	; update the UI

		; Notify the UI of the translation library which file has
		; been selected for Import (since that was already selected)
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
		jc	done
		call	SendFileSelectionInfo
done:
		; Either enable or disable the Import trigger
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_IMPORT_TRIGGER_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- import trigger offset
		jc	exit

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		cmp	cx, GIGS_NONE
		je	setState
		mov	ax, MSG_GEN_SET_ENABLED
setState:
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_child_call

		; Check to make sure we have at least one translation library
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ImportControlClass
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

		mov	ax, MSG_IMPORT_CONTROL_INSERT_LIBRARY_DISK_RESPONSE
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
		.leave
		ret
ImportControlSelectFormat	endm

SDRT_okCancel label	StandardDialogResponseTriggerTable
	word	2				; SDRTT_numTriggers
	StandardDialogResponseTriggerEntry <
		SDRT_ok,			; SDRTE_moniker
		IC_YES				; SDRTE_responseValue
	>
	StandardDialogResponseTriggerEntry <
		SDRT_cancel,			; SDRTE_moniker
		IC_NO				; SDRTE_responseValue
	>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlInsertLibraryDiskResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle insert library disk dialog response

CALLED BY:	MSG_IMPORT_CONTROL_INSERT_LIBRARY_DISK_RESPONSE
PASS:		*ds:si	= ImportControlClass object
		ds:di	= ImportControlClass instance data
		ds:bx	= ImportControlClass object (same as *ds:si)
		es 	= segment of ImportControlClass
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
ImportControlInsertLibraryDiskResponse	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_INSERT_LIBRARY_DISK_RESPONSE
	cmp	cx, IC_YES
	je	rescan

	; Dismiss interaction and cancel import
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_IMPORT_CONTROL_CANCEL
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

rescan:
	; Rescan new library disk
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_IMPORT_CONTROL_NEW_LIBRARY_DISK
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

ImportControlInsertLibraryDiskResponse	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlFreeLibraryAndFormatUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the passed library and free any format UI

CALLED BY:	MSG_IMPORT_EXPORT_FREE_LIBRARY_AND_FORMAT_UI
PASS:		*ds:si	= ImportControlClass object
		ds:di	= ImportControlClass instance data
		ds:bx	= ImportControlClass object (same as *ds:si)
		es 	= segment of ImportControlClass
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
ImportControlFreeLibraryAndFormatUI	method dynamic ImportControlClass, 
			MSG_IMPORT_EXPORT_FREE_LIBRARY_AND_FORMAT_UI
	; Free library
	; 
	call	ImportExportFreeLibrary

	; Get the offset of the format UI parent object, if
	; any, and remove any current format UI.
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- format UI parent offset
	jc	done
	call	ImpexRemoveFormatUI
done:
	ret
ImportControlFreeLibraryAndFormatUI	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSelectFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to a selection of a file by the user

CALLED BY:	GLOBAL (MSG_IMPORT_EXPORT_SELECT_FILE)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
		BP	= GenFileSelectorEntryFlags

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlSelectFile	method dynamic	ImportControlClass,
					MSG_IMPORT_EXPORT_SELECT_FILE
		.enter

		; Either enable or disable the Import trigger
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_IMPORT_TRIGGER_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- trigger offset
		jc	done

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		CheckHack <GFSET_FILE eq 0>
		test	bp, mask GFSEF_TYPE
		jnz	setStatus
		mov	ax, MSG_GEN_SET_ENABLED
setStatus:
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		call	ObjMessage_child_send
				
		; Finally, see if we should start the import
		;
		test	bp, mask GFSEF_OPEN
		jz	done
		mov	ax, MSG_GEN_TRIGGER_SEND_ACTION
		call	ObjMessage_child_send
done:
		.leave
		ret
ImportControlSelectFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initiate an import

CALLED BY:	MSG_IMPORT_CONTROL_IMPORT
PASS:		*ds:si	= ImportControlClass object
		ds:di	= ImportControlClass instance data
		ds:bx	= ImportControlClass object (same as *ds:si)
		es 	= segment of ImportControlClass
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
ImportControlImport	method dynamic ImportControlClass, 
					MSG_IMPORT_CONTROL_IMPORT
	CheckHack <(mask IA_IGNORE_INPUT) eq (mask ICA_IGNORE_INPUT)>

	; Redwood, nuke clipboard file for space reasons.  1/20/94 cbh
	;
	call	ClipboardFreeItemsNotInUse

	; Check if file selector is displayed (usable)
	; If it is, then we must go to part 2, ie. to disable
	; the file selector and put up the format list
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- file selector offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>

	mov	ax, MSG_GEN_GET_USABLE
	call	ObjMessage_child_call
	LONG jnc fileSelectorNotUsable

	; Tell user to insert translation library disk
	;
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

	; Yes, file selector was usable, so...
	; set it unusable
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- file selector offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildNotUsable

	; Set format group usable
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- format list offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildUsable

	; Set format UI usable
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset		; di <- format UI parent offset
	jc	5$
	call	setChildUsable
5$:
	; Set app defined UI usable
	;
	mov	ax, ATTR_IMPORT_CONTROL_APP_UI
	call	ObjVarFindData			; ds:bx <- extra data
	jnc	10$				; if non found, we're done
	mov	ax, MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
	mov	di, offset ImportControlClass
	call	ObjMessage_child_call		; di <- app UI parent offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
        call    setChildUsable
10$:
	ret


fileSelectorNotUsable:
	;
	; mark busy
	;
	call	markAppBusy

	; Initialize the ImpexThreadInfo structure
	;
	mov	di, ds:[si]
	add	di, ds:[di].ImportControl_offset
	mov	cx, ds:[di].ICI_attrs

	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- format list offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>
	mov	bp, di

	mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- file selector offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

	push	di			; save file selector offset
	mov	dx, MSG_GEN_PATH_GET	; dx <- msg to send FileSelector
	call	InitThreadInfoBlock

	; Store away some additional data
	;
	mov	di, ds:[si]
	add	di, ds:[di].ImportControl_offset
	mov	ax, ds:[di].ICI_message
	mov	es:[ITI_appMessage], ax
	movdw	es:[ITI_appDest], ds:[di].ICI_destination, ax
	mov	es:[ITI_notifySource].handle, handle ImportNotifyUI
	mov	es:[ITI_notifySource].offset, offset ImportNotify
	pop	di			; di <- file selector offset

	; Load in the name of the source file
	;
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	cx, es
	mov	dx, offset ITI_srcDestName
	call	ObjMessage_child_call

	; Now load the translation library
	;
	push	ds
	segmov	ds, es
	mov	di, offset ITI_libraryDesc
	call	ImpexLoadLibrary	; bx <- library handle
	pop	ds
	jc	loadError
continue:
	mov	es:[ITI_libraryHandle], bx
	call	ImpexLoadAndCloseImpexLibrary

	; Mark not busy while we're asking user to insert disk.
	;
	call	markAppNotBusy

	; Tell user to insert document disk
	;
	clr	ax
	pushdw	axax		; don't care about SDOP_helpContext
	pushdw	axax		; don't care about SDOP_customTriggers
	pushdw	axax		; don't care about SDOP_stringArg2
	pushdw	axax		; don't care about SDOP_stringArg1
	mov	bx, handle InsertDocumentDiskString
	mov	ax, offset InsertDocumentDiskString
	pushdw	bxax		; save SDOP_customString
	mov	ax, IMPEX_NOTIFICATION
	push	ax		; save SDOP_customFlags
	call	UserStandardDialogOptr

	; Dismiss interaction and reset import control UI 
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	call	ImportControlResetUI

	mov	ax, MSG_ITP_IMPORT
	mov	bx, es:[ITI_handle]
	call	SpawnThread
	ret


loadError:

	; If we could not load the library, then tell the user
	; to *really* insert the disk holding the translation
	; library. Instead of providing a "Cancel" trigger
	; (which would have required more work), we give the
	; user one chance to re-insert the floppy, and then
	; we give up. -Don 6/20/95

	call	markAppNotBusy
	clr	ax
	pushdw	axax			; SDOP_helpContext
	pushdw	axax			; SDOP_customTriggers
	pushdw	axax			; SDOP_stringArg2
	pushdw	axax			; SDOP_stringArg1
	mov	bx, handle InsertImpexDiskString
	mov	ax, offset InsertImpexDiskString
	pushdw	bxax		; save SDOP_customString
	mov	ax, IMPEX_NOTIFICATION
	push	ax		; save SDOP_customFlags
	call	UserStandardDialogOptr
	call	markAppBusy

	push	ds
	segmov	ds, es
	mov	di, offset ITI_libraryDesc
	call	ImpexLoadLibrary	; bx <- library handle
	pop	ds
	jnc	continue

	; give up - tell user we couldn't load the driver

	call	markAppNotBusy
	push	es
	movdw	cxdx, esdi		; cx:dx <- ITI_libraryDesc
	mov	bp, IE_COULD_NOT_LOAD_XLIB
	call	LockImpexError		; error string => ES:DI, flags => AX
	clr	bp
	pushdw	bpbp			; don't care about SDOP_helpContext
	pushdw	bpbp			; don't care about SDOP_customTriggers
	pushdw	bpbp			; don't care about SDOP_stringArg2
	pushdw	cxdx			; don't care about SDOP_stringArg1
	pushdw	esdi			; save SDOP_customString
	push	ax			; save SDOP_customFlags
	call	UserStandardDialog
	call	MemUnlock		; unlock Strings resource
	pop	es

	mov	bx, es:[ITI_handle]
	call	MemFree

	; Cancel import
	;
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock

	mov	ax, MSG_IMPORT_CONTROL_CANCEL
	GOTO	ObjCallInstanceNoLock


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

ImportControlImport	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlCancel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel an import

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_CANCEL)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlCancel	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_CANCEL
	;
	; Get the offset of the format UI parent object, if
	; any, and remove any current format UI.
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- format UI parent offset
	jc	noFormatUI
	call	ImpexRemoveFormatUI
noFormatUI:

	call	ImportControlResetUI

	; If there is vardata telling us to send a message on cancel
	; then do so
	;
	mov	ax, ATTR_IMPORT_CONTROL_CANCEL_MESSAGE
	call	ObjVarFindData
	jnc	done
	mov	dx, ds:[bx]				;save message
	mov	ax, ATTR_IMPORT_CONTROL_CANCEL_DESTINATION
	call	ObjVarFindData
	jnc	done
	mov	si, ds:[bx].chunk
	mov	bx, ds:[bx].handle
	mov_tr	ax, dx
	clr	di
	GOTO	ObjMessage
done:
	ret
ImportControlCancel	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlResetUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset import control UI

CALLED BY:	ImportControlImport
		ImportControlCancel
PASS:		*ds:si	= ImportControlClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlResetUI	proc	near
	uses	ax,bx,cx,dx,di,bp,es
	.enter

	; Disable format list and its trigger
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_GROUP_OFFSET
	mov	di, segment ImportControlClass
	mov	es, di
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset		; di <- format group offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildNotUsable

	; Set format UI unusable
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_UI_PARENT_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset		; di <- format UI parent offset
	jc	5$
	call	setChildNotUsable
5$:
	; Set app defined UI unusable
	;
	mov	ax, ATTR_IMPORT_CONTROL_APP_UI
	call	ObjVarFindData			; ds:bx <- extra data
	jnc	10$				; if non found, we're done
	mov	ax, MSG_IMPORT_CONTROL_GET_APP_UI_PARENT_OFFSET
	mov	di, offset ImportControlClass
	call	ObjMessage_child_call		; di <- app UI parent offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
        call    setChildNotUsable
10$:
	; Enable file selector
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECT_GROUP_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- file selector offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>
	call	setChildUsable

	; Clear out format list
	;
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
	mov	di, offset ImportControlClass
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
ImportControlResetUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlNewLibraryDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rescan format list

CALLED BY:	MSG_IMPORT_CONTROL_NEW_LIBRARY_DISK
PASS:		*ds:si	= ImportControlClass object
		ds:di	= ImportControlClass instance data
		ds:bx	= ImportControlClass object (same as *ds:si)
		es 	= segment of ImportControlClass
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
ImportControlNewLibraryDisk	method dynamic ImportControlClass, 
					MSG_IMPORT_CONTROL_NEW_LIBRARY_DISK
	mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
	mov	di, offset ImportControlClass
	call	ImpexGetChildOffset	; di <- format list offset
EC <	ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING			>

	mov	ax, MSG_FORMAT_LIST_RESCAN
	call	ObjMessage_child_call
	ret
ImportControlNewLibraryDisk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utilities
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportSendDataClassesToFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the data classes to the format list

CALLED BY:	INTERNAL

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	6/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportSendDataClassesToFormatList	proc	near
		class	ImportControlClass
		.enter
	
		mov	cx, ds:[di].ICI_dataClasses

		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
		jc	exit

		mov	ax, MSG_FORMAT_LIST_SET_DATA_CLASSES
		call	ObjMessage_child_send
exit:
		.leave
		ret
ImportSendDataClassesToFormatList	endp

ImpexUICode	ends
