COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Translation Libraries
FILE:		transUI.asm

AUTHOR:		Jimmy Lefkowitz, July 1991

ROUTINES:
	Name			Description
	----			-----------
GLB	TransGetImportUI	Returns OD of Import options UI
GLB	TransGetExportUI	Returns OD of Export options UI
	GetSpecificUI		Does real work of finding/returning OD

GLB	TransGetImportOptions	Dummy routine for use when there are
				no import options
GLB	TransGetExportOptions	Dummy routine for use when there are
				no export options
	
GLB	TransInitImportUI	Dummy routine for use when no initialization
				is needed for the import UI
GLB	TransInitExportUI	Dummy routine for use when no initialization
				is needed for the export UI


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/91		Initial version
	ted	10/92		Added MAP_CONTROL_EXIST

DESCRIPTION:
	Common code for all translation libraries.

	$Id: transUI.asm,v 1.1 97/04/07 11:42:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Compile-time constants for pre-defined routines:
;
; IMPORT_OPTIONS_EXIST			= TRUE or FALSE (must be set)
; EXPORT_OPTIONS_EXIST			= TRUE or FALSE (must be set)
; MAP_CONTROL_EXIST			= TRUE or FALSE (must be set)
;
; INIT_IMPORT_UI			= defined (optional dummy routine)
; INIT_EXPORT_UI			= defined (optional dummy routine)

; Note: If MAP_CONTROL_EXIST is set TRUE, you must also set
;       IMPORT_OPTIONS_EXIST = TRUE.

ifndef	IMPORT_OPTIONS_EXIST

ErrMessage	<Error - Set IMPORT_OPTIONS_EXIST to TRUE or FALSE before including this file.>

else

ifndef	EXPORT_OPTIONS_EXIST

ErrMessage	<Error - Set EXPORT_OPTIONS_EXIST to TRUE or FALSE before including this file.>

else

TransCommonCode	segment	resource

if	IMPORT_OPTIONS_EXIST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetImportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the import UI (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_IMPORT_UI)

PASS:		CX	= Format (TransFormat enumaration)

RETURN:		CX:DX	= OD of generic tree for options UI
		BX:AX	= Null (no subclass of GenControl)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetImportUI	proc	far
	;
	; Get the OD of the generic tree
	;
ifndef	MAP_CONTROL_EXIST
	mov	bp, offset IFGI_importUI
	GOTO	GetSpecificUI
else
if	MAP_CONTROL_EXIST

	; do this only if MAP_CONTROL_EXIST = TRUE
	; and if  IMPORT_OPTIONS_EXIST = TRUE

	mov	bp, offset IFGI_importUI
	GOTO	GetImportSpecificUI
else
	mov	bp, offset IFGI_importUI
	GOTO	GetSpecificUI
endif
endif	

TransGetImportUI	endp

ifdef	MAP_CONTROL_EXIST
if	MAP_CONTROL_EXIST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetImportSpecificUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the import UI (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_IMPORT_UI)

PASS:		CX	= Format (TransFormat enumaration)

RETURN:		CX:DX	= OD of generic tree for options UI
		BX:AX	= subclass of GenControl

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetImportSpecificUI	proc	far	 uses	di, ds
	.enter

	; Get offset to the proper format
	
	mov	bx, handle FormatStrings
	call	MemLock
	mov	ds, ax
	mov	ax, size ImpexFormatGeodeInfo
	mul	cx					; ax <- offset to info
	mov	di, offset TLMBH_stringHandleTable
	add	di, ax					; di <- format info
	mov	cx, ds:[di][bp].handle			; OD => CX:DX
	mov	dx, ds:[di][bp].chunk
	call	MemUnlock

	mov	bx, segment ImpexMappingControlClass
	mov	ax, offset ImpexMappingControlClass
	.leave
	ret
GetImportSpecificUI	endp

endif
endif
else


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetImportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the import UI (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_IMPORT_UI)

PASS:		CX	= Format (TransFormat enumaration)

RETURN:		CX:DX	= OD of generic tree for options UI
		BX:AX	= Null (no subclass of GenControl)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Dummy routine used when there are no import options.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetImportUI	proc	far
		clr	cx		; no import UI
		ret
TransGetImportUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetImportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the import options (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_IMPORT_OPTIONS)

PASS:		CX	= Format number (TransFormat enumeration)
		DX	= Handle of duplicated options UI (= 0 if none)

RETURN:		DX	= Handle of options block (= 0 if none)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Dummy routine used when there are no import options.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetImportOptions	proc	far
		clr	dx		; no import options
		ret
TransGetImportOptions	endp

endif

if	EXPORT_OPTIONS_EXIST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the export UI (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_EXPORT_UI)

PASS:		CX	= Format (TransFormat enumeration)

RETURN:		CX:DX	= OD of generic tree for options UI
		BX:AX	= Null (no subclass of GenControl)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetExportUI	proc	far
	;
	; Get the OD of the generic tree
	;
		mov	bp, offset IFGI_exportUI
		FALL_THRU	GetSpecificUI
TransGetExportUI	endp

else


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the export UI (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_EXPORT_UI)

PASS:		CX	= Format (TransFormat enumeration)

RETURN:		CX:DX	= OD of generic tree for options UI
			  (CX = 0 if no UI)
		BX:AX	= Null (no subclass of GenControl)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Dummy routine used when there are no export options.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetExportUI	proc	far
		clr	cx		; no export UI
		ret
TransGetExportUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the export options (if any) for the passed format

CALLED BY:	GLOBAL (TR_GET_EXPORT_OPTIONS)

PASS:		CX	= Format number (TransFormat enumeration)
		DX	= Handle of duplicated options UI (= 0 if none)

RETURN:		DX	= Handle of options block (= 0 if none)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Dummy routine used when there are no export options.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jenny	10/8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetExportOptions	proc	far
		clr	dx		; no export options
		ret
TransGetExportOptions	endp

endif

if	IMPORT_OPTIONS_EXIST or EXPORT_OPTIONS_EXIST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSpecificUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the resource handle of the UI gadgetry

CALLED BY:	TransGetImportUI, TransGetExportUI

PASS:		CX	= Format number (TransFormat enumeration)
		BP	= Offset in ImpexFormatGeodeInfo to use

RETURN:		CX:DX	= OD of root of generic tree
		BX:AX	= Null (no subclass of GenControl)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Find and return the specific UI block.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jimmy	7/91		Initial version (for export UI)
		jenny   11/91		Changed name, expanded, fixed header
		Don	11/91		No longer duplcates block here
		jenny	5/92		Fixed bug.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSpecificUI	proc	far
		uses	di, ds
		.enter
	;
	; Get offset to the proper format
	;
		mov	bx, handle FormatStrings
		call	MemLock
		mov	ds, ax
		mov	ax, size ImpexFormatGeodeInfo
		mul	cx			; ax <- offset to info
		mov	di, offset TLMBH_stringHandleTable
		add	di, ax			; di <- format info
	;
	; Get the UI.
	;
		mov	cx, ds:[di][bp].handle	; OD => CX:DX
		mov	dx, ds:[di][bp].chunk
		call	MemUnlock
		clr	ax, bx			; no sub-class

		.leave
		ret
GetSpecificUI	endp

endif

ifndef	INIT_IMPORT_UI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransInitImportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy routine for initializing the import UI

CALLED BY:	GLOBAL

PASS:		CX:DX	= OD of duplicated import UI

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransInitImportUI	proc	far
		ret
TransInitImportUI	endp

endif

ifndef	INIT_EXPORT_UI


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransInitExportUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dummy routine for initializing the export UI

CALLED BY:	GLOBAL

PASS:		CX:DX	= OD of duplicated export UI

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransInitExportUI	proc	far
		ret
TransInitExportUI	endp

endif

TransCommonCode	ends

endif
endif
