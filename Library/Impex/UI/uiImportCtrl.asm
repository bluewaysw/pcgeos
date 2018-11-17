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

    INT SelectFormatImportNoIdea Do special case for NoIdea

    INT SetFileMask		Set the file mask

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/26/92		Initial revision


DESCRIPTION:
	Contains the code implementing the ImportControlClass

	$Id: uiImportCtrl.asm,v 1.3 98/07/20 18:06:24 joon Exp $

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

EC <		test	cx, not ImportControlAttrs			>
EC <		ERROR_NZ IMPORT_CONTROL_ILLEGAL_ATTRS			>
		mov	ds:[di].ICI_attrs, cx

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

		mov	cx, ds:[di].ICI_attrs

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




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlCallField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the field object.

CALLED BY:	ImportControlImportComplete, others

PASS:		ax -- message to send, any args in cx, dx, bp

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/ 6/94       	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0	;not used until we can handle fail cases

ImportControlCallField	proc	near	uses	ax, bx, cx, dx, bp, di
		.enter
		push	si
		mov	bx, segment GenFieldClass
		mov	si, offset GenFieldClass
		mov	di, mask MF_RECORD
		call	ObjMessage
		pop	si
		mov	cx, di

		mov	ax, MSG_GEN_GUP_CALL_OBJECT_OF_CLASS
		call	GenCallParent

		.leave
		ret
ImportControlCallField	endp

endif


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
			<offset ImportGlyphParent,
				mask IMPORTCF_GLYPH,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportFileSelector,
				mask IMPORTCF_BASIC,
				mask GCCF_IS_DIRECTLY_A_FEATURE>,
			<offset ImportFormatListParent,
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
			<offset ImportGlyph, 0, 0>,
			<offset ImportFormatListParent, 0, 0>,
			<offset ImportFileMask, ImportFileMaskName, 0>,
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
		test	dx, mask IMPORTCF_BASIC
		jz	done
		mov	cx, offset ImportFileSelector
done:
		ret
ImportControlGetFileSelectorOffset	endm


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

		test	dx, mask IMPORTCF_BASIC
		jz	done
		mov	cx, offset ImportFormatList
done:
		ret
ImportControlGetFormatListOffset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetFileMaskOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get offset of ImportFileMask if it exists

CALLED BY:	MSG_IMPORT_CONTROL_GET_FILE_MASK_OFFSET
PASS:		*ds:si	= ImportControlClass object
		dx	= import features mask
RETURN:		cx	= offset of ImportFileMask if it exists
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	11/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetFileMaskOffset	method dynamic ImportControlClass, 
				MSG_IMPORT_CONTROL_GET_FILE_MASK_OFFSET

		test	dx, mask IMPORTCF_FILE_MASK
		jz	done
		mov	cx, offset ImportFileMask
done:
		ret
ImportControlGetFileMaskOffset	endm


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

		test	dx, mask IMPORTCF_BASIC
		jz	done
		mov	cx, offset ImportAppUIParent
done:
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
		ImportControlTweakDuplicatedUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	modify UI of Import dialog box

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GENERATE_UI)

PASS:		ES	= Segment of ExportControlClass
		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
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

ImportControlTweakDuplicatedUI	method	dynamic	ImportControlClass, MSG_GEN_CONTROL_TWEAK_DUPLICATED_UI
	;
	; remove path list for CUI
	;
		call	UserGetDefaultUILevel
		cmp	ax, UIIL_INTRODUCTORY
		jne	done
		mov	bx, cx
		mov	si, offset ImportFileSelector
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx = attrs
		andnf	cx, not mask FSA_HAS_CHANGE_DIRECTORY_LIST
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
ImportControlTweakDuplicatedUI	endm


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
		cmp	cx, GIGS_NONE
		je	done			; done if nothing selected
		tst	bp			; If "No Idea" choice is
		jz	setFileMask		; ...not present, set mask
		jcxz	noIdeaFormat		; Else, handle "No Idea"
		dec	cx			; ...or adjust element number

		; Get the default file spec from the Library geode and
		; set it into the File Mask text edit object.
setFileMask:
		push	cx
		mov	bx, dx			; bx <- FormatInfo block
		call	GetDefaultFileMask	; cx:dx <- file mask
		call	SetFileMask
		call	MemUnlock		; unlock the FormatInfo
		pop	cx			; cx <- format #

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
done:
		.leave
		ret

		; Deal with the "No Idea" format.
noIdeaFormat:
		call	SelectFormatImportNoIdea
		jmp	done			; we're done
ImportControlSelectFormat	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlSetFileMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the file spec of the file selector

CALLED BY:	GLOBAL

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Grab the user-edited file mask, set the mask for the
		file selector, and reset the selection
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ImportControlSetFileMask	method dynamic	ImportControlClass,
				MSG_IMPORT_CONTROL_SET_FILE_MASK
		.enter

		; Get the text from the text display object
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_MASK_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file mask offset
		jc	exit

		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		sub	sp, PATH_BUFFER_SIZE
		mov	dx, ss
		mov	bp, sp
		call	ObjMessage_child_call	; fill buffer with text
		mov	cx, dx
		mov	dx, bp
		call	SetFileMask		; set the mask
		add	sp, PATH_BUFFER_SIZE	; clean up stack
exit:
		.leave
		ret
ImportControlSetFileMask	endm


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

		; Pass this information on to a superclass
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
		jc	doTrigger
		call	SendFileSelectionInfo
doTrigger:
		; Either enable or disable the Import trigger
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_IMPORT_TRIGGER_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- trigger offset
		jc	done

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		test	bp, mask GFSEF_NO_ENTRIES
		jnz	setStatus		; if zip, can't import
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

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_IMPORT)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
		ES:DI	= ImportControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		* Do the common work
		* Get the name of the source file
		* Spawn the thread and import		
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not VOLATILE_SYSTEM_STATE

ImportControlImport	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_IMPORT
		.enter

		; Initialize the ImpexThreadInfo structure
		;
		CheckHack <(mask IA_IGNORE_INPUT) eq (mask ICA_IGNORE_INPUT)>
		mov	cx, ds:[di].ICI_attrs

		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	bp, di
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	dx, MSG_GEN_PATH_GET	; dx <- msg to send FileSelector
		call	InitThreadInfoBlock	; bx <- block handle
		jc	exit
		push	di			; save file selector offset

		; Store away some additional data
		;
		mov	di, ds:[si]
		add	di, ds:[di].ImportControl_offset
		mov	ax, ds:[di].ICI_message
		mov	es:[ITI_appMessage], ax
		movdw	cxax, ds:[di].ICI_destination
		movdw	es:[ITI_appDest], cxax		
		mov	es:[ITI_notifySource].handle, handle ImportNotifyUI
		mov	es:[ITI_notifySource].offset, offset ImportNotify

		; Load in the name of the source file
		;
		pop	di			; di <- file selector offset
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		mov	cx, es
		mov	dx, offset ITI_srcDestName
		call	ObjMessage_child_call

		; Now spawn the thread
		;
		mov	ax, MSG_ITP_IMPORT
		call	SpawnThread
exit:
		.leave
		ret

ImportControlImport	endm

else   ;VOLATILE_SYSTEM_STATE

ImportControlImport	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_IMPORT
	.enter

	test	ds:[di].ICI_attrs, mask ICA_NON_DOCUMENT_IMPORT
	jz	continueImportAfterFileSaves

	;
	; A non-document import, continue import now!
	;
	mov	ax, MSG_IMPORT_CONTROL_CONTINUE_IMPORT
	GOTO	ObjCallInstanceNoLock

continueImportAfterFileSaves:
	;
	; Delay continuing the import until after all the app's files have
	; been saved or closed.  We'll pass our continue message in
	; MSG_META_QUERY_SAVE_DOCUMENTS, which in turn will be passed to
	; app with the full screen exclusive, just to ensure that it gets
	; to the right place, though it's probably overkill...
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_IMPORT_CONTROL_CONTINUE_IMPORT
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;pass in cx to MSG_META_QUERY_DOCUMENTS

	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	clr	bp
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL
	mov	cx, di
	clr	dx
	call	GCNListSend
	.leave
	ret
ImportControlImport	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlContinueImport
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue an import, after files have been saved/closed.

CALLED BY:	GLOBAL (MSG_IMPORT_CONTROL_IMPORT)

PASS:		*DS:SI	= ImportControlClass object
		DS:DI	= ImportControlClassInstance
		ES:DI	= ImportControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		chris	3/15/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if VOLATILE_SYSTEM_STATE

ImportControlContinueImport	method dynamic	ImportControlClass,
					MSG_IMPORT_CONTROL_CONTINUE_IMPORT
		.enter

if LIMITED_UNTITLED_DOC_DISK_SPACE
		;
		; Nuke clipboard file for space reasons.  1/20/94 cbh
		;
		call	ClipboardFreeItemsNotInUse
endif

		; Initialize the ImpexThreadInfo structure
		;
		CheckHack <(mask IA_IGNORE_INPUT) eq (mask ICA_IGNORE_INPUT)>
		mov	cx, ds:[di].ICI_attrs

		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	bp, di
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	dx, MSG_GEN_PATH_GET	; dx <- msg to send FileSelector
		call	InitThreadInfoBlock	; bx <- block handle
		jc	exit
		push	di			; save file selector offset

		; Store away some additional data
		;
		mov	di, ds:[si]
		add	di, ds:[di].ImportControl_offset
		mov	ax, ds:[di].ICI_message
		mov	es:[ITI_appMessage], ax
		movdw	cxax, ds:[di].ICI_destination
		movdw	es:[ITI_appDest], cxax		
		mov	es:[ITI_notifySource].handle, handle ImportNotifyUI
		mov	es:[ITI_notifySource].offset, offset ImportNotify

		; Load in the name of the source file
		;
		pop	di			; di <- file selector offset
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
		mov	cx, es
		mov	dx, offset ITI_srcDestName
		call	ObjMessage_child_call

		; Now spawn the thread
		;
		mov	ax, MSG_ITP_IMPORT
		call	SpawnThread
exit:
		.leave
		ret

ImportControlContinueImport	endm

endif


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
		.enter

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
		call	ObjMessage
done:
		.leave
		ret
ImportControlCancel	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlGetFileSelector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the optr of the file selector, if built.

CALLED BY:	MSG_IMPORT_CONTROL_GET_FILE_SELECTOR

PASS:		*ds:si	= ImportControlClass object
		ds:di	= ImportControlClass instance data
		ds:bx	= ImportControlClass object (same as *ds:si)
		es 	= segment of ImportControlClass
		ax	= message #

RETURN:		^lcx:dx = the GenFileSelector
		carry set if the child hasn't been built yet

DESTROYED:	ax, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/07/98   	Initial version
	dhunter	10/12/00	Clear cxdx if carry set for C callers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlGetFileSelector	method dynamic ImportControlClass, 
					MSG_IMPORT_CONTROL_GET_FILE_SELECTOR
		uses	ax, bp
		.enter

		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di = file selector offset

		call	ImpexGetChildBlockAndFeatures	; bx = block

		movdw	cxdx, bxdi
		jc	clearIt
done:
		.leave
		ret
clearIt:
		clrdw	cxdx			; clear cxdx if carry set
		jmp	done
ImportControlGetFileSelector	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportControlAutoDetectFileFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tries to auto-detect the format of the file currently
		selected for import.

CALLED BY:	MSG_IMPORT_CONTROL_AUTO_DETECT_FILE_FORMAT

PASS:		*ds:si	= ImportControlClass object
		ds:di	= ImportControlClass instance data
		ds:bx	= ImportControlClass object (same as *ds:si)
		es 	= segment of ImportControlClass
		ax	= message #
RETURN:		carry set if unable to auto-detect format, otherwise clear.
DESTROYED:	ax
SIDE EFFECTS:	Sets format selector to "No idea"

PSEUDO CODE/STRATEGY:
		Select "No idea" format
		Call InitThreadInfoBlock to do the auto-detect

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dhunter	10/12/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ImportControlAutoDetectFileFormat	method dynamic ImportControlClass, 
					MSG_IMPORT_CONTROL_AUTO_DETECT_FILE_FORMAT
		uses	cx, dx, bp
		.enter
	;
	; Get the format list and set it to the first selection, which is
	; always "No idea".
	;
		mov	ax, MSG_IMPORT_CONTROL_GET_FORMAT_LIST_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- format list offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		clr	cx			; cx <- item ID = 0
		clr	dx			; dx <- not indeterminate
		call	ObjMessage_child_call
;;		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
;;		call	ObjMessage_child_call
	;
	; Initialize the ImpexThreadInfo structure to do the auto-detect
	;
		mov	bp, di
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
EC <		ERROR_C	IMPEX_NECESSARY_CONTROL_FEATURE_MISSING		>

		mov	dx, MSG_GEN_PATH_GET	; dx <- msg to send FileSelector
		call	InitThreadInfoBlock	; bx <- block handle, carry
		jc	skipFree		;  indicates error
		call	MemFree			; Else, free returned block
		clc				; Format was auto-detected
skipFree:
		.leave
		ret
ImportControlAutoDetectFileFormat	endm

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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectFormatImportNoIdea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do special case for NoIdea

CALLED BY:	SelectFormatImport

PASS:		*DS:SI	= ImportControlClass object

RETURNED:	Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:	
		* Set the filemask to "*.*"

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SelectFormatImportNoIdea	proc	near
		.enter
	
		; Set the file mask
		;
		push	ds, si			; save ImportControl object
		mov	si, offset WildCardString
		call	LockString		; string => DS:SI
		mov	cx, ds
		mov	dx, si
		pop	ds, si			; ImportControl object => *DS:SI
		call	SetFileMask
		call	MemUnlock		; unlock strings resource
		.leave
		ret
SelectFormatImportNoIdea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFileMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the file mask

CALLED BY:	INTERNAL

PASS:		*DS:SI	= ImportControlClass object
		CX:DX	= File mask string

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		* Set the file selector mask
		* Reset the file selector selection
		* Set the file mask text, and select it

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If the user cannot edit the file mask, then
		we do nothing

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/27/92		Initial version
		Don	11/4/99		changed so that masks can be
					set even if user cannot edit
					the mask.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetFileMask	proc	near
		uses	ax, bx, cx, dx, di, bp
		.enter

		; Get the child for the mask text object & the
		; file selector. If the file selector is not present,
		; then do nothing.
		;
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_MASK_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file mask offset
		mov	bp, di
		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR_OFFSET
		mov	di, offset ImportControlClass
		call	ImpexGetChildOffset	; di <- file selector offset
		jc	exit
		push	bp			; save file mask offset

		; Now set the file mask, and reset the selection
		;
		call	UpcaseString		; upcase string in CX:DX
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_MASK
		push	cx, dx, cx, dx		; save mask buffer
		call	ObjMessage_child_call	; set the file mask
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
		pop	cx, dx
		call	ObjMessage_child_call	; attempt to set selection

		; Set the mask text, and reset the selection
		;
		pop	dx, bp			; text => DX:BP		
		clr	cx			; text is NULL-terminated
		pop	di			; file mask offset => DI
		tst	di
		jz	exit
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjMessage_child_call
		mov	ax, MSG_VIS_TEXT_SELECT_ALL
		call	ObjMessage_child_call
exit:
		.leave
		ret
SetFileMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaskTextKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept keyboard characters for the mask text class

CALLED BY:	GLOBAL (MSG_META_KBD_CHAR)

PASS:		*DS:SI	= MaskTextClass object
		DS:DI	= MaskTextClassInstance
		CX	= Character value
		DL	= CharFlags
		DH	= ShiftState
		BP	= shme

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/28/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MaskTextKbdChar	method dynamic	MaskTextClass, MSG_META_KBD_CHAR

		; We're either going to swallow CR characters, and
		; send MSG_GEN_ACTIVATE direectly, or we will pass
		; on everything to our superclass
		;
		test	dl, mask CF_RELEASE
		jnz	callsuper
		cmp	cl, C_ENTER
		jne	callsuper
		mov	ax, MSG_GEN_ACTIVATE
callsuper:
		mov	di, offset MaskTextClass
		GOTO	ObjCallSuperNoLock
MaskTextKbdChar	endm


ImpexUICode	ends
