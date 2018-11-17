COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DosFile (Sample PC GEOS application)
FILE:		dosfile.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the DosFile application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: dosfile.asm,v 1.1 97/04/04 16:33:24 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def

include object.def
include graphics.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

DFProcessClass	class	GenProcessClass
;
;	Handle a change in the GenValue for the X value (sent by GenValue)
;
; Pass:
;	cx - value
; Return:
;	none

DFProcessClass	endc

idata	segment
	DFProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; DFDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument

DFDocumentClass	class	GenDocumentClass

MSG_DF_DOCUMENT_X_CHANGE	message
MSG_DF_DOCUMENT_Y_CHANGE	message

    DFDI_position	Point

DFDocumentClass endc

idata	segment
	DFDocumentClass
idata	ends

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

DOCUMENT_WIDTH		=	20*72
DOCUMENT_HEIGHT		=	20*72

INITIAL_X_POS		= 20
INITIAL_Y_POS		= 20

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		dosfile.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for DFDocumentClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DFDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for DFDocumentClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	*ds:si - instance data
	es - segment of DFDocumentClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
DFDocumentInitializeDocumentFile	method dynamic	DFDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	; Initialize the position

	mov	ds:[di].DFDI_position.P_x, INITIAL_X_POS
	mov	ds:[di].DFDI_position.P_y, INITIAL_Y_POS

	clc			;no error
	ret

DFDocumentInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DFDocumentPhysicalSave -- MSG_GEN_DOCUMENT_PHYSICAL_SAVE
							for DFDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of DFDocumentClass

	ax - The message

RETURN:
	carry - set if error
	ax - error code (if any)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/30/92		Initial version

------------------------------------------------------------------------------@
DFDocumentPhysicalSave	method dynamic	DFDocumentClass,
					MSG_GEN_DOCUMENT_PHYSICAL_SAVE,
					MSG_GEN_DOCUMENT_PHYSICAL_UPDATE

	; Save the data in the file

	mov	bx, ds:[di].GDI_fileHandle		;save file handle

	call	WriteDataToFile

	ret

DFDocumentPhysicalSave	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DFDocumentPhysicalSaveAsFileHandle --
		MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE
						for DFDocumentClass

DESCRIPTION:	Write the document data to a new file handle

PASS:
	*ds:si - instance data (GDI_fileHandle is *old* file handle)
	es - segment of DFDocumentClass

	ax - The message

	cx - new file handle

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/25/92		Initial version

------------------------------------------------------------------------------@
DFDocumentPhysicalSaveAsFileHandle	method dynamic	DFDocumentClass,
				MSG_GEN_DOCUMENT_PHYSICAL_SAVE_AS_FILE_HANDLE

	mov	bx, cx
	call	WriteDataToFile
	ret

DFDocumentPhysicalSaveAsFileHandle	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	WriteDataToFile

DESCRIPTION:	Write the data to the document file

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	bx - file handle

RETURN:
	carry - set if error
	ax - error code

DESTROYED:
	cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/25/92		Initial version

------------------------------------------------------------------------------@
WriteDataToFile	proc	near

	clrdw	cxdx
	mov	al, FILE_POS_START
	call	FilePos

	mov	cx, size DFDI_position
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	lea	dx, ds:[di].DFDI_position
	mov	al, FILE_NO_ERRORS
	call	FileWrite

	ret

WriteDataToFile	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	DFDocumentCreateUIForDocument --
		MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT for DFDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of DFDocumentClass

	ax - The message

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
	Tony	7/30/92		Initial version

------------------------------------------------------------------------------@
DFDocumentCreateUIForDocument	method dynamic	DFDocumentClass,
				MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT

	mov	bx, ds:[di].GDI_fileHandle		;save file handle

	; Read in the data from the document

	clrdw	cxdx
	mov	al, FILE_POS_START
	call	FilePos

	mov	cx, size DFDI_position
	lea	dx, ds:[di].DFDI_position
	call	FileRead

	ret

DFDocumentCreateUIForDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DFDocumentAttachUIToDocument --
		MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for DFDocumentClass

DESCRIPTION:	Update the UI

PASS:
	*ds:si - instance data
	es - segment of DFDocumentClass

	ax - The message

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
	Tony	7/30/91		Initial version

------------------------------------------------------------------------------@
DFDocumentAttachUIToDocument	method dynamic	DFDocumentClass,
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	push	ds:[di].DFDI_position.P_y
	mov	cx, ds:[di].DFDI_position.P_x

	; set the X value

	GetResourceHandleNS	DFValueX, bx
	mov	si, offset DFValueX
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	clr	di
	call	ObjMessage

	; set the Y value

	pop	cx
	GetResourceHandleNS	DFValueY, bx
	mov	si, offset DFValueY
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	clr	di
	call	ObjMessage

	ret

DFDocumentAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DFDocumentChange -- MSG_DF_DOCUMENT_X_CHANGE and
				MSG_DF_DOCUMENT_Y_CHANGE for DFDocumentClass

DESCRIPTION:	Handle change in the X or the Y value

PASS:
	*ds:si - instance data
	es - segment of DFDocumentClass

	ax - The message

	dx - new value

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
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
DFDocumentChange	method dynamic	DFDocumentClass,
					MSG_DF_DOCUMENT_X_CHANGE,
					MSG_DF_DOCUMENT_Y_CHANGE

	cmp	ax, MSG_DF_DOCUMENT_Y_CHANGE
	jz	yChange
	mov	ds:[di].DFDI_position.P_x, dx
	jmp	common
yChange:
	mov	ds:[di].DFDI_position.P_y, dx
common:

	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	call	ObjCallInstanceNoLock

	ret

DFDocumentChange	endm

CommonCode	ends		;end of CommonCode resource
