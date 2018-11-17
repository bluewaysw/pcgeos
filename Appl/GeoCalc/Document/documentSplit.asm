COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		documentSplit.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/94   	Initial version.

DESCRIPTION:
	Code for implementing splitting / unsplitting of views


	$Id: documentSplit.asm,v 1.1 97/04/04 15:48:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Document segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSplitViews
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Split the views

PASS:		*ds:si	- GeoCalcDocumentClass object
		ds:di	- GeoCalcDocumentClass instance data
		es	- segment of GeoCalcDocumentClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixedSizeArgs	struct
    FSA_width	SpecWidth
    FSA_height	SpecHeight
FixedSizeArgs	ends

GeoCalcDocumentSplitViews	method	dynamic	GeoCalcDocumentClass, 
					MSG_GEOCALC_DOCUMENT_SPLIT_VIEWS

srp		local	SpreadsheetRangeParams
rangeBounds	local	RectDWord
svi		local	SplitViewInfo
viewHandle	local	hptr

ForceRef	avdp
ForceRef	fixedSizeArgs
		
		.enter
	;
	; Fetch various pieces of Vis-level instance data
	;
		mov	di, bx
		add	di, ds:[di].Vis_offset
		mov	ax, ds:[di].VCNI_view.handle
		mov	ss:[viewHandle], ax
		
		movdw	ss:[svi].SVI_docOrigin.PD_x, \
				 ds:[di].VCNI_docOrigin.PD_x, ax

		movdw	ss:[svi].SVI_docOrigin.PD_y, \
				ds:[di].VCNI_docOrigin.PD_y, ax
if 1
	;
	; Get the selection bounds from the spreadsheet
	;
		mov	ax, MSG_GEOCALC_SPREADSHEET_IS_ACTIVE_CELL_VISIBLE
		call	VisCallFirstChild
		mov	ax, offset activeCellNotVisible
		LONG	jnc	abortOperation
endif
	;
	;  Figure out whether the selection is valid for freezing titles.
	;
		push	bp
		lea	bp, ss:[srp]
		mov	ax, MSG_SPREADSHEET_GET_SELECTION
		call	VisCallFirstChild
		pop	bp

		mov	dx, ss
		lea	cx, ss:[rangeBounds]

		push	bp
		lea	bp, ss:[srp].SRP_selection
		mov	ax, MSG_SPREADSHEET_GET_RANGE_BOUNDS
		call	VisCallFirstChild
		pop	bp

		movdw	bxax, ss:[rangeBounds].RD_left
		subdw	bxax, ss:[svi].SVI_docOrigin.PD_x
		LONG	js	error

		tst	bx
		LONG	jnz	error
		mov	ss:[svi].SVI_cornerSize.P_x, ax

		movdw	bxax, ss:[rangeBounds].RD_top
		subdw	bxax, ss:[svi].SVI_docOrigin.PD_y
		js	error
		tst	bx
		jnz	error
		mov	ss:[svi].SVI_cornerSize.P_y, ax

		tstdw	ss:[svi].SVI_cornerSize

	;
	;  Active cell is in upper-left corner -- abort.
	;
		mov	ax, offset cantFreezeCellA1	; assume upper-left
		jz	abortOperation			; abort noisily

	;
	; These limits are imposed by the SpecWidth record size
	;
		
		cmp	ss:[svi].SVI_cornerSize.P_x, 1024
		jae	error

		cmp	ss:[svi].SVI_cornerSize.P_y, 1024
		jae	error

validBounds::
	;
	; Check (and set) the GCDF_SPLIT flag
	;
		
		mov	di, ds:[si]
		add	di, ds:[di].GeoCalcDocument_offset
		test	ds:[di].GCDI_flags, mask GCDF_SPLIT
		jnz 	done
		ornf	ds:[di].GCDI_flags, mask GCDF_SPLIT

		call	StoreSplitInfo
		
	;
	; Add "fixed-size" hints to all the various views
	;
		mov	bx, ss:[viewHandle]
		mov	cx, ss:[svi].SVI_cornerSize.P_x
		mov	dx, ss:[svi].SVI_cornerSize.P_y
		call	GCDocumentSetViewSizes

	;
	; Set the views usable.  
	;
		call	GCDocumentSetViewsUsable

	;
	; And set their origins
	;
		
		push	bp
		lea	bp, ss:[svi]
		call	GCDocumentSetOrigins
		pop	bp

ifdef GPC
	;
	; Update split UI
	;
		mov	cx, mask GCMF_SPLIT
		mov	ax, MSG_GEOCALC_APPLICATION_UPDATE_SPLIT_STATE
		call	UserCallApplication
endif
done:
		.leave
		ret
;--------------------------------------------------

error:
		jmp	done
if 1
abortOperation:
		clr	cx, di
		call	CallErrorDialog
		jmp	done
endif
GeoCalcDocumentSplitViews	endm


if 1
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallErrorDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the user of the error occured during the operation.

CALLED BY:	GeoCalcDocumentSplitViews
PASS:		ax	= chunk handle of the error string.
		cx:di	= string to be displayed OR cx = di = 0
RETURN:		nothing
DESTROYED:	ax, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	1/23/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallErrorDialog	proc	far
		uses	bx 
		.enter
	;
	; Create an error dialog.
	;
		clr	bx
		xchg	bx, ax				;bx = chunk handle of str
		push	ax, ax				;SDP_helpContext
		push	ax, ax				;SDP_customTriggers
		push	ax, ax				;SDP_stringArg2
		pushdw	cxdi				;SDP_stringArg1

		mov	di, bx				
		GetResourceHandleNS StringsUI, bx
		call	MemLock				;ax = str block
		mov	es, ax
		mov	di, es:[di]			;es:di = str
		pushdw	esdi				;SDP_customString
		mov	ax, CustomDialogBoxFlags<1, CDT_ERROR, GIT_NOTIFICATION,0>
		push	ax				;SDP_customFlags
		call	UserStandardDialog
		call	MemUnlock
		.leave
		ret

CallErrorDialog		endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StoreSplitInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the "split" information in the map block

CALLED BY:	GeoCalcDocumentSplitViews

PASS:		ds:di - GeoCalcDocumentInstance

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/23/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StoreSplitInfo	proc near
		class	GeoCalcDocumentClass
		
		.enter	inherit	GeoCalcDocumentSplitViews

	;
	; See if the calc map block is the right size
	;
		mov	bx, ds:[di].GDI_fileHandle
		call	DBLockMap
		mov	di, es:[di]
		ChunkSizePtr	es, di, cx
		cmp	cx, size CalcMapBlock
		je	sizeOK

	;
	; Unlock the thing and re-lock it, since it's not clear to me
	; how to re-dereference an already-locked DB item.
	;
		call	DBUnlock
		call	GeoCalcDocumentReAllocMapBlock
		call	DBLockMap
		mov	di, es:[di]
sizeOK:
		ornf	es:[di].CMB_flags, mask GCMF_SPLIT
		add	di, offset CMB_splitInfo
		push	ds, si
		segmov	ds, ss
		lea	si, ss:[svi]
		mov	cx, size SplitViewInfo/2
		rep	movsw
		pop	ds, si

		call	DBDirty
		call	DBUnlock

		.leave
		ret
		
StoreSplitInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentReAllocMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reallocate the map block, and zero-initialize the
		flags and "reserved" portions for future use.

CALLED BY:	StoreSplitInfo

PASS:		bx - file handle

RETURN:		nothing 

DESTROYED:	ax,cx,di,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/27/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentReAllocMapBlock	proc near

		.enter
		
		call	DBGetMap
		mov	cx, size CalcMapBlock
		call	DBReAlloc
		call	DBLock
		
		mov	di, es:[di]
		clr	ax
		add	di, offset CMB_reserved
		mov	cx, (size CMB_reserved + size CMB_flags)/2
		CheckHack <(size CMB_reserved and 1) eq 0>
		rep	stosw

		call	DBUnlock
		
		.leave
		ret
GeoCalcDocumentReAllocMapBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCDocumentSetOrigins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the common work of setting up a "split"

CALLED BY:	GeoCalcDocumentSplitViews
		GeoCalcDocumentSplitFromMap

PASS:		ss:bp - SplitViewInfo
		*ds:si - GeoCalcDocumentClass object
		bx- view handle

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCDocumentSetOrigins	proc near
		uses	ax,bx,cx,dx,di,si,bp
		.enter
	;
	; Set the origins of the various views
	;
		push	si			; *ds:si - document
		mov	si, offset MidLeftView
		call	setViewOrigin

		pushdw	ss:[bp].SVI_docOrigin.PD_x

		mov	ax, ss:[bp].SVI_cornerSize.P_x
		add	ss:[bp].SVI_docOrigin.PD_x.low, ax
		adc	ss:[bp].SVI_docOrigin.PD_x.high, 0

		mov	si, offset MidRightView
		call	setViewOrigin

		popdw	ss:[bp].SVI_docOrigin.PD_x
		
		mov	ax, ss:[bp].SVI_cornerSize.P_y
		add	ss:[bp].SVI_docOrigin.PD_y.low, ax
		adc	ss:[bp].SVI_docOrigin.PD_y.high, 0

		mov	si, offset BottomLeftView
		call	setViewOrigin

		mov	ax, ss:[bp].SVI_cornerSize.P_x
		add	ss:[bp].SVI_docOrigin.PD_x.low, ax
		adc	ss:[bp].SVI_docOrigin.PD_x.high, 0

		mov	si, offset BottomRightView
		call	setViewOrigin

		pop	si			; *ds:si - document
	;
	; Allow the view to scroll again.
	;
		call	TurnOnTrackScrolling
		
	;
	; Now update the spreadsheet's origin.
	;
		mov	ax, MSG_SPREADSHEET_SET_DOC_ORIGIN
		push	bp
		lea	bp, ss:[bp].SVI_docOrigin
		mov	dx, size SVI_docOrigin
		mov	di, mask MF_STACK or mask MF_FIXUP_DS
		call	SendToDocSpreadsheet
		pop	bp

		.leave
		ret
;------------------------------
setViewOrigin:
		push	bp
		mov	dx, size SVI_docOrigin
		lea	bp, ss:[bp].SVI_docOrigin	
		mov	ax, MSG_GEN_VIEW_SET_ORIGIN
		mov	di, mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
		retn
GCDocumentSetOrigins	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCDocumentSetViewSizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the widths of the various views along the left side

CALLED BY:	GeoCalcDocumentSplitViews

PASS:		bx - handle of view block
		*ds:si - document
		(cx, dx) - corner size

RETURN:		nothing 

DESTROYED:	ax,bx,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/ 1/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCDocumentSetViewSizes	proc near
		class	GeoCalcDocumentClass
		

viewHandle	local	hptr	push	bx
cornerSize	local	Point	push	dx, cx
avdp		local	AddVarDataParams
fixedSizeArgs	local	FixedSizeArgs
		
		uses	bx, cx, dx, si
		
		.enter

	;
	; The passed corner size is in document coordinates -- multiply
	; by the scale factor to get screen coordinates
	;
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset

		movdw	bxax, ds:[di].VCNI_scaleFactor.PF_y
		mov	dx, ss:[cornerSize].P_y
		call	doMul
		mov	ss:[cornerSize].P_y, dx

		movdw	bxax, ds:[di].VCNI_scaleFactor.PF_x
		mov	dx, ss:[cornerSize].P_x
		call	doMul
		mov	ss:[cornerSize].P_x, dx
		
	;
	; Set up the AddVarDataParams
	;
		
		mov	ss:[avdp].AVDP_data.segment, ss
		lea	ax, ss:[fixedSizeArgs]
		mov	ss:[avdp].AVDP_data.offset, ax
		mov	ss:[avdp].AVDP_dataSize, size FixedSizeArgs
		mov	ss:[avdp].AVDP_dataType,
			HINT_FIXED_SIZE or mask VDF_SAVE_TO_STATE

		mov	ax, ss:[cornerSize].P_x
		tst	ax
		jz	afterWidths
		
		mov	ss:[fixedSizeArgs].FSA_width,
			SpecWidth <SST_PIXELS,0>

		ornf	ss:[fixedSizeArgs].FSA_width, ax
		clr	ss:[fixedSizeArgs].FSA_height

		mov	si, offset LeftColumnView
		call	addVarData

		mov	si, offset MidLeftView
		call	addVarData

		mov	si, offset BottomLeftView
		call	addVarData

afterWidths:
		mov	ax, ss:[cornerSize].P_y
		tst	ax
		jz	done
		
		mov	ss:[fixedSizeArgs].FSA_height,
			SpecHeight <SST_PIXELS,0>
		or	ss:[fixedSizeArgs].FSA_height, ax
		
		clr	ss:[fixedSizeArgs].FSA_width
		
		mov	si, offset MidViewGroup
		call	addVarData
done:
		.leave
		ret

;--------------------
addVarData:
		mov	bx, ss:[viewHandle]
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	dx, size AddVarDataParams
		push	bp
		lea	bp, ss:[avdp]
		mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
		retn

doMul:
	;
	; Do a multiply, unless the scale factor hasn't yet been
	; initialized.
	;
		tstdw	bxax
		jz	afterMul
		clr	cx
		call	GrMulWWFixed
afterMul:
		retn
GCDocumentSetViewSizes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GCDocumentSetViewsUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the various views and things usable

CALLED BY:	GeoCalcDocumentSplitViews

PASS:		bx - handle of views
		(cx, dx) - corner size

RETURN:		nothing 

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/ 6/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GCDocumentSetViewsUsable	proc near
		uses	si

		.enter	inherit	GeoCalcDocumentSplitViews


		call	TurnOffTrackScrolling

		jcxz	afterWidths
		
		mov	si, offset LeftColumnView
		call	GCDocumentSetUsable

		mov	si, offset MidLeftView
		call	GCDocumentSetUsable

		mov	si, offset BottomLeftView
		call	GCDocumentSetUsable

afterWidths:
		tst	dx
		jz	done
	;
	; Set the origin of the MidRowView to 0,0 because if we don't
	; do it here, and we want it to be 0,0, it will keep its previous
	; y value because of the order in which views become usable and
	; their origins are set.
	;
		push	bp
		clr	ax
		pushdw	axax
		pushdw	axax
		mov	bp, sp
		mov	ax, MSG_GEN_VIEW_SET_ORIGIN
		mov	di, mask MF_STACK or mask MF_FIXUP_DS
		mov	si, offset MidRowView
		call	ObjMessage
		add	sp, 2 * (size dword)
		pop	bp
		
		mov	si, offset MidViewGroup
		call	GCDocumentSetUsable

done:
		.leave
		ret

		
GCDocumentSetViewsUsable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSplitFromMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Turn on "split views" from information in the map block

PASS:		*ds:si	- GeoCalcDocumentClass object
		ds:di	- GeoCalcDocumentClass instance data

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/21/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentSplitFromMap	method	dynamic	GeoCalcDocumentClass, 
					MSG_GEOCALC_DOCUMENT_SPLIT_FROM_MAP

svi		local	SplitViewInfo
viewHandle	local	word
		
		.enter

		add	bx, ds:[bx].Vis_offset
		mov	ax, ds:[bx].VCNI_view.handle
		mov	ss:[viewHandle], ax

		mov	bx, ds:[di].GDI_fileHandle
		call	DBLockMap
		mov	di, es:[di]

	;
	; If this document is from an older version of GeoCalc, then
	; bail immediately.
	;
		
		ChunkSizePtr	es, di, cx
		cmp	cx, size CalcMapBlock
		jne	unlockDone

		test	es:[di].CMB_flags, mask GCMF_SPLIT
		jz	unlockDone
		
		
		push	ds, es, si
		lea	si, es:[di].CMB_splitInfo
		segmov	ds, es
		segmov	es, ss
		lea	di, ss:[svi]
		mov	cx, size SplitViewInfo/2
		rep	movsw
		pop	ds, es, si

		call	DBUnlock

		mov	bx, ds:[si]
		add	bx, ds:[bx].GeoCalcDocument_offset
		ornf	ds:[bx].GCDI_flags, mask GCDF_SPLIT

	;
	; Add "fixed-size" hints to all the various views
	;
		mov	bx, ss:[viewHandle]
		mov	cx, ss:[svi].SVI_cornerSize.P_x
		mov	dx, ss:[svi].SVI_cornerSize.P_y
		call	GCDocumentSetViewSizes

	;
	; Set the views usable.  
	;
		call	GCDocumentSetViewsUsable

	;
	; Set their origins
	;
		
		push	bp
		lea	bp, ss:[svi]
		call	GCDocumentSetOrigins
		pop	bp
done:

		.leave
		ret
unlockDone:
		call	DBUnlock
		jmp	done
GeoCalcDocumentSplitFromMap	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentUnsplitViews
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Turn off "split views"

PASS:		*ds:si	- GeoCalcDocumentClass object
		ds:di	- GeoCalcDocumentClass instance data
		es	- segment of GeoCalcDocumentClass

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentUnsplitViews	method	dynamic	GeoCalcDocumentClass, 
					MSG_GEOCALC_DOCUMENT_UNSPLIT_VIEWS

docOrigin	local	PointDWord
		.enter

		test	ds:[di].GCDI_flags, mask GCDF_SPLIT
		LONG jz	done
		andnf	ds:[di].GCDI_flags, not mask GCDF_SPLIT

		
		mov	bx, ds:[di].GDI_fileHandle
		call	DBLockMap
		mov	di, es:[di]
		test	es:[di].CMB_flags, mask GCMF_SPLIT
		jnz	continue
		
	;
	; Something's wrong here -- the document object and the map
	; block don't agree, so just unlock the map and forget about it.
	;
		
		call	DBUnlock
		jmp	done
continue:

	;
	; Turn off the "split" flag, and restore the old origin
	;
		
		andnf	es:[di].CMB_flags, not mask GCMF_SPLIT
		movdw	ss:[docOrigin].PD_x, \
				es:[di].CMB_splitInfo.SVI_docOrigin.PD_x, ax
		movdw	ss:[docOrigin].PD_y, \
				es:[di].CMB_splitInfo.SVI_docOrigin.PD_y, ax
		call	DBDirty
		call	DBUnlock
		
		
		mov	di, ds:[si]
		add	di, ds:[di].Vis_offset
		mov	bx, ds:[di].VCNI_view.handle

		call	TurnOffTrackScrolling

		push	si			; document chunk
		mov	si, offset LeftColumnView
		call	GCDocumentSetNotUsable

		mov	si, offset BottomLeftView
		call	GCDocumentSetNotUsable
	;
	; Must set the MidLeftView not usable, because if the next
	; split view doesn't require that it is present (because no
	; visible columns are locked), it will become usable when the
	; MidViewGroup is set usable. 
	;
		mov	si, offset MidLeftView
		call	GCDocumentSetNotUsable

		mov	si, offset MidViewGroup
		call	GCDocumentSetNotUsable

		pop	si			; document chunk

	;
	; Clear out the spreadsheet's origin.
	;
		push	bp
		clr	ax
		push	ax
		push	ax
		push	ax
		push	ax
		CheckHack <size PointDWord eq 8>

		mov	ax, MSG_SPREADSHEET_SET_DOC_ORIGIN
		mov	bp, sp
		mov	dx, size PointDWord
		mov	di, mask MF_FIXUP_DS
		call	SendToDocSpreadsheet
		add	sp, size PointDWord
		pop	bp

		push	bp
		mov	ax, MSG_GEOCALC_SPREADSHEET_SET_OFFSET
		lea	bp, ss:[docOrigin]
		mov	dx, size PointDWord
		mov	di, mask MF_FIXUP_DS
		call	SendToDocSpreadsheet
		pop	bp
	;
	; Set the origin back to where it was originally, after turning
	; track scrolling back on so that the spreadsheet can works its
	; magic.
	;
		push	bp, si
		mov	si, offset BottomRightView
		lea	bp, ss:[docOrigin]
		mov	dx, size PointDWord
		mov	ax, MSG_GEN_VIEW_SET_ORIGIN
		mov	di, mask MF_STACK or mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp, si
		
		call	TurnOnTrackScrolling

ifdef GPC
	;
	; Update split UI
	;
		mov	cx, 0
		mov	ax, MSG_GEOCALC_APPLICATION_UPDATE_SPLIT_STATE
		call	UserCallApplication
endif

done:

		.leave
		ret
		
GeoCalcDocumentUnsplitViews	endm

; Pass: ^lbx:si - object

GCDocumentSetNotUsable	proc	near
		mov	ax, MSG_GEN_SET_NOT_USABLE
		GOTO	SetUsableStateCommon
GCDocumentSetNotUsable	endp

GCDocumentSetUsable	proc	near
		mov	ax, MSG_GEN_SET_USABLE
		FALL_THRU	SetUsableStateCommon
GCDocumentSetUsable	endp

SetUsableStateCommon	proc	near
		uses	cx, dx, bp
		.enter
if 0
	;
	;  Using VUM_DELAYED_VIA_QUEUE_QUEUE seems to fix bug #50685,
	;  but causes bug #51110, so I guess we'll try to look at these
	;  bugs for Obiwan.
	;
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
else
		mov	dl, VUM_NOW
endif		
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		.leave
		retn
SetUsableStateCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TurnOffTrackScrolling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off track scrolling in the document's view

CALLED BY:	GeoCalcDocumentSplitViews
		GeoCalcDocumentUnsplitViews

PASS:		*ds:si - document
		bx - handle of view block

RETURN:		nothing 

DESTROYED:	ax,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TurnOffTrackScrolling	proc	near
		uses	cx, dx, si
		.enter
		mov	si, offset BottomRightView
		mov	ax, MSG_GEN_VIEW_SET_ATTRS
		mov	dx, mask GVA_TRACK_SCROLLING
		clr	cx
		call	om 

	; Suspend some updates
		
		mov	ax, MSG_GEN_VIEW_SUSPEND_UPDATE
		call	om

		mov	si, offset RightColumnView
		call	om

		mov	si, offset BottomRowView
		call	om
		.leave
		ret

om:

		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		retn
		
TurnOffTrackScrolling	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TurnOnTrackScrolling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn track scrolling on

CALLED BY:	GeoCalcDocumentContinueSplit,
		GeoCalcDocumentUnsplitViews

PASS:		*ds:si - document
		bx - handle of GenView

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/19/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TurnOnTrackScrolling	proc near
		uses	si
		.enter
		mov	si, offset BottomRightView
		mov	ax, MSG_GEN_VIEW_SET_ATTRS
		mov	cx, mask GVA_TRACK_SCROLLING
		clr	dx
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_GEN_VIEW_UNSUSPEND_UPDATE
		call	omfq

		mov	si, offset RightColumnView
		call	omfq

		mov	si, offset BottomRowView
		call	omfq

		.leave
		ret
omfq:
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage
		retn
		
TurnOnTrackScrolling	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentSetView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Attach to the view.  See if we want to set up "split views"

PASS:		*ds:si	- GeoCalcDocumentClass object
		ds:di	- GeoCalcDocumentClass instance data
		es	- segment of GeoCalcDocumentClass
		^lcx:dx	- view OD

RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/23/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GeoCalcDocumentSetView	method	dynamic	GeoCalcDocumentClass, 
					MSG_META_CONTENT_SET_VIEW

		push	cx
		mov	di, offset GeoCalcDocumentClass
		call	ObjCallSuperNoLock
		pop	cx
		jcxz	done


callSplitFromMap	label	near		
		mov	ax, MSG_GEOCALC_DOCUMENT_SPLIT_FROM_MAP
		GOTO	ObjCallInstanceNoLock 
done:
		ret
GeoCalcDocumentSetView	endm

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoCalcDocumentScaleFactorChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- GeoCalcDocumentClass object
		ds:di	- GeoCalcDocumentClass instance data
		es	- segment of GeoCalcDocumentClass
		ss:bp 	- ScaleChangedParams
RETURN:		nothing 

DESTROYED:	ax, cx, dx, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/10/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoCalcDocumentScaleFactorChanged	method	dynamic	GeoCalcDocumentClass, 
				MSG_META_CONTENT_VIEW_SCALE_FACTOR_CHANGED

		mov	di, offset GeoCalcDocumentClass
		call	ObjCallSuperNoLock
		mov	ax, MSG_GEOCALC_DOCUMENT_SPLIT_FROM_MAP
		GOTO	ObjCallInstanceNoLock
		
GeoCalcDocumentScaleFactorChanged	endm



Document ends
