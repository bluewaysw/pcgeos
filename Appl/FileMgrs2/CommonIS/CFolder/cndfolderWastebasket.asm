COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cndfolderWastebasket.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/15/92   	Initial version.

DESCRIPTION:
	

	$Id: cndfolderWastebasket.asm,v 1.2 98/06/03 13:11:46 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
idata	segment
	NDWastebasketClass
idata	ends


NDFolderCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDWastebasketCheckTransferEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	accept everything (not quite everything)

PASS:		*ds:si	= NDWastebasketClass object
		ds:di	= NDWastebasketClass instance data
		es	= dgroup
		dx:0	= FileQuickTransferHeader
		dx:bp	= FileOperationInfoEntry in in the FileQuickTransfer
		current directory is the destination directory (dest. object)
RETURN:		carry
		- set if this item has been handled specially, or rejected.
			It will be taken out of the FileQuickTransfer block
			so it will not be copied, moved or whatever the
			default operation was.
		- clear if this item is normal and should be handled normally 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/15/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESKBA

NDWastebasketCheckTransferEntry	method	dynamic	NDWastebasketClass, 
					MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY
	.enter

	;
	; If this is a list operation, abort
	;
	movdw	dssi, dxbp		; ds:si = FileOperationInfoEntry
	tstListTransfer ds
	jz	regularTransfer	

	cmp	cx, 1			; put up error box for last item only
	jne	specialHandling

	mov	ax, ERROR_FOLDER_UNSUPPORTED_TRANSFER_OPERATION
	jmp	desktopError

regularTransfer:
	; Accept:
	;	WOT_FOLDER
	;	WOT_DOCUMENT
	;	WOT_EXECUTABLE
	;	WOT_TEACHER_COURSE
	;	WOT_STUDENT_COURSE
	;	WOT_DOS_COURSEWARE
	;	WOT_GEOS_COURSEWARE
	;	WOT_STUDENT_HOME_TVIEW
	;
	; This should eventually be changed to accept everything, with
	; dummies of the aforementioned types handling
	; MSG_SHELL_OBJECT_DELETE in the proper fasion.
	;

	cmp	ds:[si].FOIE_info, WOT_FOLDER
	je	accept
	cmp	ds:[si].FOIE_info, WOT_DOCUMENT
	je	accept
	cmp	ds:[si].FOIE_info, WOT_EXECUTABLE
	je	accept
	cmp	ds:[si].FOIE_info, WOT_TEACHER_COURSE
	je	accept
	cmp	ds:[si].FOIE_info, WOT_STUDENT_COURSE
	je	accept
	cmp	ds:[si].FOIE_info, WOT_DOS_COURSEWARE
	je	accept
	cmp	ds:[si].FOIE_info, WOT_GEOS_COURSEWARE
	je	accept
	cmp	ds:[si].FOIE_info, WOT_STUDENT_UTILITY
	je	accept
	cmp	ds:[si].FOIE_info, WOT_STUDENT_HOME_TVIEW
	je	accept

	segmov	es, dgroup, di
	mov	di, offset fileOperationInfoEntryBuffer	; es:di is buff.
	mov	cx, size FileOperationInfoEntry
	rep	movsb
	mov	ax, ERROR_ND_OBJECT_NOT_ALLOWED

desktopError:
	call	DesktopOKError

specialHandling:
	stc
accept:
	.leave
	ret
NDWastebasketCheckTransferEntry	endm


endif
NDFolderCode	ends
