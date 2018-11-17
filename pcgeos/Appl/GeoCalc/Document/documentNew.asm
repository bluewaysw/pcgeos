COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		documentNew.asm

AUTHOR:		Gene Anderson, Feb 12, 1991

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/12/91		Initial revision

DESCRIPTION:
	This file contains routines to implement creation of a new document.

	$Id: documentNew.asm,v 1.1 97/04/04 15:48:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Document	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentInitializeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize new spreadsheet document file
CALLED BY:	MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of GeoCalcDocumentClass
		ax - the method
RETURN:		carry - set if error
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentInitializeFile	method dynamic GeoCalcDocumentClass, \
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	;
	; let our superclass create the file and stuff...
	;
	mov	di, offset GeoCalcDocumentClass
	call	ObjCallSuperNoLock
	;
	; Initialize the spreadsheet file
	;   NOTE: the spreadsheet object does not yet exist
	;
	sub	sp, (size SpreadsheetInitFileData)
	mov	bp, sp				;ss:bp <- params
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, ds:[di].GDI_fileHandle	;ax <- VM file handle
	mov	ss:[bp].SIFD_file, ax
	mov	ss:[bp].SIFD_numRows, GEOCALC_NUM_ROWS
	mov	ss:[bp].SIFD_numCols, GEOCALC_NUM_COLUMNS
	mov	ss:[bp].SIFD_drawFlags, mask SDF_DRAW_GRID or \
				mask SDF_DRAW_GRAPHICS or \
		 		mask SDF_DRAW_NOTE_BUTTON or \
				mask SDF_DRAW_HEADER_FOOTER_BUTTON
	call	SpreadsheetInitFile
	add	sp, (size SpreadsheetInitFileData)
	;
	; Allocate a map block for GeoCalc, and save the
	; spreadsheet map in it
	;
	mov	cx, ax				;cx <- spreadsheet map
	call	AllocMapBlock			;allocate a map block for us
	call	SetSpreadsheetMap		;store the spreadsheet map in it
	;
	; Tell the file that it may be storing objects
	;
	mov	ax, mask VMA_OBJECT_RELOC  or \
			mask VMA_SYNC_UPDATE or mask VMA_NOTIFY_DIRTY
	call	VMSetAttributes

	;
	; create and init the grobj/chart body and attribute manager
	;
CHART<	call	GeoCalcDocumentCreateGrObjBody				>
CHART<	call	GeoCalcDocumentInitGrObjBody				>

	clc			;no error
	ret
GeoCalcDocumentInitializeFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSpreadsheetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get VM handle of spreadsheet map block
CALLED BY:	UTILITY

PASS:		*ds:si - document object
RETURN:		cx - VM handle of spreadsheet map block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSpreadsheetMap	proc	near
	uses	ax, bx, di, es
	class	GeoCalcDocumentClass
	.enter

	call	GetSpreadsheetFile		;bx <- VM file handle
	;
	; Lock the map item and get the spreadsheet map handle
	;
	call	DBLockMap			;*es:di <- map item
	mov	di, es:[di]			;es:di <- ptr to map item
	mov	cx, es:[di].CMB_spreadsheetMap
	;
	; Unlock the map item
	;
	call	DBUnlock			;unlock me jesus

	.leave
	ret
GetSpreadsheetMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetSpreadsheetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set VM handle of spreadsheet map block that we store in
		our map block
CALLED BY:	UTILITY

PASS:		*ds:si - document object
		cx - VM handle of spreadsheet map block
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetSpreadsheetMap	proc	near
	uses	di
	class	GeoCalcDocumentClass
	.enter

	call	GetSpreadsheetFile		;bx <- VM file handle
	;
	; Lock the map item and set the spreadsheet map handle
	;
	call	DBLockMap			;*es:di <- map item
	mov	di, es:[di]			;es:di <- ptr to map item
	mov	es:[di].CMB_spreadsheetMap, cx
	;
	; Dirty and unlock the map item
	;
	call	DBDirty
	call	DBUnlock			;unlock me jesus

	.leave
	ret
SetSpreadsheetMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSpreadsheetFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get handle of spreadsheet file associated with document
CALLED BY:	UTILITY

PASS:		*ds:si - document object
RETURN:		bx - VM file handle
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetSpreadsheetFile	proc	far
	uses	di
	class	GeoCalcDocumentClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset		;ds:di <- gen instance data
	mov	bx, ds:[di].GDI_fileHandle	;bx <- VM file handle

	.leave
	ret
GetSpreadsheetFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a map block for GeoCalc document file
CALLED BY:	GeoCalcDocumentInitializeFile()

PASS:		*ds:si - document object
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocMapBlock	proc	near
		uses	ax, cx, es, di
		.enter

		call	GetSpreadsheetFile	;bx <- VM file handle
		mov	ax, DB_UNGROUPED	;Allocate it ungrouped
		mov	cx, size CalcMapBlock	;cx <- size of the block
		call	DBAlloc			;Allocate a map item
		call	DBSetMap		;Make it the map item
	;
	; Zero-initialize the map block
	;
		call	DBLockMap
		mov	di, es:[di]			;es:di <- ptr to map
		push	di
		clr	ax
		mov	cx, size CalcMapBlock/2
		CheckHack <(size CalcMapBlock and 1) eq 0>
		rep	stosw
		pop	di
		mov	es:[di].CMB_pageSetup.CPSD_startPage,
					GEOCALC_DEFAULT_START_PAGE
		mov	es:[di].CMB_pageSetup.CPSD_flags,
					GEOCALC_DEFAULT_PRINT_FLAGS
		call	DBDirty
		call	DBUnlock

		.leave
		ret
AllocMapBlock	endp

Document	ends
