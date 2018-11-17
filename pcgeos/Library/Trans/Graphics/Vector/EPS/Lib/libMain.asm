COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		EPS Translation library	
FILE:		libMain.asm

AUTHOR:		Jim DeFrisco, Dec 30, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/30/92		Initial revision


DESCRIPTION:
	GetExportOptions code for EPS Translation lib	
		

	$Id: libMain.asm,v 1.1 97/04/07 11:25:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetExportOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the handle of the block containing export options

CALLED BY:	GLOBAL

PASS:		dx	- handle of object block holding UI gadgetry
			  (zero if default options are desired)

RETURN:		dx	- handle of block containing PSExportOpts structure
			  (or zero if no options)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		extract the options from the UI gadgetry and setup the
		structure

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		caller is expected to free the block when finished

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransGetExportOptions proc	far
		uses	ax, bx, cx, ds, es, si, di
		.enter

		; allocate a block to hold the options

		mov	ax, size PSExportBlock		; need this much
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE 
		call	MemAlloc

		; fill in defaults

		mov	es, ax				; es -> block
		clr	di				; es:di -> structure
		segmov	ds, cs
		lea	si, defaultOptions		; ds:si -> defaults
		mov	cx, size PSExportBlock
		rep	movsb				; copy it over

		; check for zero, which means default options.  

		tst	dx				; check for defaults
		jnz	getState			;  no, get state
		mov	dx, bx				; return handle
		call	MemUnlock			; unlock the block

done:
		.leave
		ret

		; don't want defaults.  For now, just return NULL.  eventually
		; we will get the state from the passed UI block.
getState:
		call	MemFree				; don't ret anything
		clr	bx
		jmp	done

TransGetExportOptions endp

defaultOptions	PSExportBlock < < < <0,0,0,0,0,0>,	; GExportFlags 
				    0,			; GSControl 
				    1,			; #pages
				    1,			; #copies
				    <"PC/GEOS">,	; appName
				    <"untitled">,	; docName
				    <"untitled.eps">, 	; fileName
				    792,		; docHeight
				    612,		; docWidth
				    0			; file handle
				    >,			;  end GExportOpts 
				  <1,0,0>,		; PSExportFlags
				  PSFL_STANDARD_13	; PSFontList
				  >,			;  end PSExportOpts
			        <0,0>,			; PSExportStatus
				1			; PSEB_curPage
			        >			;  end PSExportBlock


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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the file is a valid EPS format

CALLED BY:	Impex	- GLOBAL	
PASS:		SI	= fileHandle, open
RETURN:		AX	= TransError (0 = no error)
		CX	= format number if valid format
			  or NO_IDEA_FORMAT if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MS	6/28/92		Initial version
	jim	12/92		modified for EPS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

epsFileID	char	"%!PS-Adobe"	; in front of every EPS file


TransGetFormat	proc	far
		uses	bx,dx,ds,si,di,bp
epsHeader	local	10 dup(char)

		.enter

		mov	cx, 10
		segmov	ds, ss			; read into local header struct
		lea	dx, epsHeader
		clr	al			; flags = 0
		mov	bx, si			; file
		call	FileRead
		jc	notEPSFormat		; bad file read. no match.

		lea	si, epsHeader		; ds:si -> file content
		segmov	es, cs, di
		mov	di, offset epsFileID	; es:di -> string to match
		mov	cx, 10
		repe	cmpsb
		jcxz	done			; cx = 0 is format number
notEPSFormat:
		mov	cx, NO_IDEA_FORMAT
done:
		clr	ax			;ax <- TE_NO_ERROR
		.leave
		ret

TransGetFormat	endp


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

ExportCode	ends

