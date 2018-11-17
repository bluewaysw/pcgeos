COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Test Printer Driver
FILE:		testUI.asm

AUTHOR:		Don Reeves, Jul 10, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	7/10/94		Initial revision

DESCRIPTION:
	Contains code to implement the UI displayed by the test
	printer driver.

	$Id: testUI.asm,v 1.1 97/04/18 11:52:33 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment
	TestTextClass
	TestControlClass
idata		ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintEvalUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Looks in the device info for the appropriate routine to call
		to evaluate the data passed in the object tree.

CALLED BY:	EXTERNAL

PASS:		AX	= Handle of JobParameters block
		BX	= Handle of the duplicated generic tree
			  displayed in the main print dialog box.
		DX	= Handle of the duplicated generic tree
			  displayed in the options dialog box
		ES:SI	= JobParameters structure
		BP	= PState segment

RETURN:		Carry	= clear
			- or -
		Carry	= set
		CX	= handle of block holding error message

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
	        Name    Date            Description
	        ----    ----            -----------
		Don	7/10/94		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintEvalUI	proc    far
		.enter

		clc

		.leave
		ret
PrintEvalUI     endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                PrintStuffUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs the info stored in JobParameters back into the
		generic tree.

CALLED BY:	EXTERNAL

PASS:		BP	= PState segment
		CX	= Handle of the duplicated generic tree
			  displayed in the main print dialog box.
		DX	= Handle of the duplicated generic tree
			  displayed in the options dialog box
		ES:SI	= JobParameters structure
		AX	= Handle of JobParameters block

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
                none

REVISION HISTORY:
	        Name    Date            Description
	        ----    ----            -----------
		Don	7/10/94		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStuffUI	proc    far
		.enter

		clc

		.leave
		ret
PrintStuffUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the PageSize controller

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		DS:*SI	= TestControlClass object
		DS:DI	= TestControlClassInstance
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

TestControlGetInfo	method dynamic	TestControlClass,
					MSG_GEN_CONTROL_GET_INFO
		.enter

		; Copy the data into the structure
		;
		mov	ax, ds
		mov	bx, di			; PageSizeCtrlInstance => AX:BX
		mov	bp, dx
		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset TC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
TestControlGetInfo	endm

TC_dupInfo	GenControlBuildInfo		<
		mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST,
						; GCBI_flags
		TC_iniKey,			; GCBI_initFileKey
		TC_gcnList,			; GCBI_gcnList
		length TC_gcnList,		; GCBI_gcnCount
		TC_notifyList,			; GCBI_notificationList
		length TC_notifyList,		; GCBI_notificationCount
		0,				; GCBI_controllerName

		handle TestControlUI,		; GCBI_dupBlock
		TC_childList,			; GCBI_childList
		length TC_childList,		; GCBI_childCount
		TC_featuresList,		; GCBI_featuresList
		length TC_featuresList,		; GCBI_featuresCount
		TC_DEFAULT_FEATURES,		; GCBI_features

		0,				; GCBI_toolBlock
		0,				; GCBI_toolList
		0,				; GCBI_toolCount
		0,				; GCBI_toolFeaturesList
		0,				; GCBI_toolFeaturesCount
		0, 				; GCBI_toolFeatures
		TC_helpContext,			; GCBI_helpContext
		0>				; GCBI_reserved

TC_iniKey		char	"testControl", 0

TC_gcnList		GCNListType \
			<MANUFACTURER_ID_GEOWORKS, \
				GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE>

TC_notifyList		NotificationType \
			<MANUFACTURER_ID_GEOWORKS, GWNT_SPOOL_DOC_OR_PAPER_SIZE>

TC_childList		GenControlChildInfo \
			<offset PageTypeList, 
				mask TCF_PAGE_TYPE, 
				mask GCCF_IS_DIRECTLY_A_FEATURE>

TC_featuresList		GenControlFeaturesInfo \
			<offset PageTypeList, 0, 0>

TC_helpContext		char	"dbPageSize", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestControlDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detach the object

CALLED BY:	GLOBAL (MSG_META_DETACH)

PASS:		*DS:SI	= TestControlClass object
		DS:DI	= TestControlClassInstance

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	7/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TestControlDetach	method dynamic	TestControlClass, MSG_META_DETACH

		; Verify our class is valid, and then call superclass
		;
		mov	di, offset TestControlClass
EC <		call	ECCheckClass					>
		GOTO	ObjCallSuperNoLock
TestControlDetach	endm
