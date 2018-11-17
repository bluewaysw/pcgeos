COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		icon editor
FILE:		documentUI.asm

AUTHOR:		Steve Yegge, Feb 24, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/24/93		Initial revision

DESCRIPTION:

	Routines for updating the Add-icon dialog.

	$Id: documentUI.asm,v 1.1 97/04/04 16:06:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DocumentUI	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerUpdateAddDialogFormatList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the list of format sizes & colors for the 
		selected icon type, in the add-icon dialog.

CALLED BY:	MSG_DB_VIEWER_UPDATE_ADD_DIALOG_FORMAT_LIST

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance
		cx = identifier of person who called (CreateNewIconType)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	We set-not-usable all the text, then set-usable the ones we
	want to show up (based on value in cx.)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 4/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerUpdateAddDialogFormatList	method dynamic DBViewerClass,
			MSG_DB_VIEWER_UPDATE_ADD_DIALOG_FORMAT_LIST
		.enter
	;
	;  First set everything unusable.
	;
		call	SetAllGroupsUnusable
	;
	;  Now set-usable the one we want.
	;
EC <		cmp	cx, CreateNewIconType				>
EC <		ERROR_AE INVALID_CREATE_NEW_ICON_TYPE			>
		mov	bx, cx			; find out which one to do
		mov	bx, cs:[typeTable][bx]
		call	bx
	;
	;  Force the geometry to be recalculated.
	;
		mov	bx, ds:[di].GDI_display
		mov	si, offset AddDlgInfoGroup
		mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		call	ObjMessage
		
		.leave
		ret
		
typeTable	word	\
		offset	DoFileIcon,
		offset	DoToolIcon,
		offset	DoPtrImage,
		offset	DoCustomIcon

DBViewerUpdateAddDialogFormatList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAllGroupsUnusable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes through AddDlgInfoGroup and sets all children unusable

CALLED BY:	DBViewerUpdateAddDialogFormatList

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetAllGroupsUnusable	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset	FileColorGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	FileSizeGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	FileNameGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	ToolColorGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	ToolSizeGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	ToolNameGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	PtrColorGroup
		mov	di, mask MF_FORCE_QUEUE	
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	PtrSizeGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	PtrNameGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		mov	si, offset	CustomGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_NOT_USABLE
		call	ObjMessage
		
		.leave
		ret
SetAllGroupsUnusable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFileIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets-usable the glyphs for the file icon in the add dialog box

CALLED BY:	DBViewerUpdateAddDialogFormatList

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoFileIcon	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset	FileNameGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		mov	si, offset	FileSizeGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		mov	si, offset	FileColorGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage	
		
		.leave
		ret
DoFileIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoToolIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets-usable the glyphs for the tool icon info (add dialog)

CALLED BY:	DBViewerUpdateAddDialogFormatList

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoToolIcon	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset	ToolNameGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		mov	si, offset	ToolSizeGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		mov	si, offset	ToolColorGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage	
		
		.leave
		ret
DoToolIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPtrImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets-usable the glyphs for the cursor image info (add dialog)

CALLED BY:	DBViewerUpdateAddDialogFormatList

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewerInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoPtrImage	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset	PtrNameGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		mov	si, offset	PtrSizeGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		mov	si, offset	PtrColorGroup
		mov	di, mask MF_FORCE_QUEUE
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage	
		
		.leave
		ret
DoPtrImage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCustomIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets-usable the custom-icon group (add dialog)

CALLED BY:	DBViewerUpdateAddDialogFormatList

PASS:		*ds:si	= DBViewer object
		ds:di	= DBViewer instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	
	set the custom group usable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoCustomIcon	proc	near
		class	DBViewerClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset CustomGroup
		mov	di, mask MF_CALL
		mov	dl, VUM_DELAYED_VIA_UI_QUEUE
		mov	ax, MSG_GEN_SET_USABLE
		call	ObjMessage
		
		.leave
		ret
DoCustomIcon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBViewerAddDialogTextModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enables or disables the OK trigger in the add dialog.

CALLED BY:	MSG_DB_VIEWER_ADD_DIALOG_TEXT_MODIFIED

PASS:		*ds:si	= DBViewerClass object
		ds:di	= DBViewerClass instance data
		bp = zero if text is becoming empty, nonzero otherwise

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	2/24/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBViewerAddDialogTextModified	method dynamic DBViewerClass, 
		MSG_DB_VIEWER_ADD_DIALOG_TEXT_MODIFIED
		uses	ax, cx, dx, bp
		.enter
		
		mov	bx, ds:[di].GDI_display
		mov	si, offset AddDlgOKTrigger
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
	;
	;  If text is becoming empty, we disable the apply trigger.
	;		
		mov	ax, MSG_GEN_SET_ENABLED		; assume enable
		tst	bp				; see if text is empty
		jnz	doIt

		mov	ax, MSG_GEN_SET_NOT_ENABLED
doIt:
		call	ObjMessage			; enable/disable trigger
		
		.leave
		ret
DBViewerAddDialogTextModified	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableExportTokenDBTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable "Export to Token Database" trigger in File menu.

CALLED BY:	DBViewerStartSelect

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableExportTokenDBTrigger	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
		
		GetResourceHandleNS	ExportTokenDialog, bx
		mov	si, offset	ExportTokenDialog
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_ENABLED
		call	ObjMessage
		
		.leave
		ret
EnableExportTokenDBTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableExportTokenDBTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable "Export To Token Database..." dialog.

CALLED BY:	DBViewerStartSelect

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	6/14/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableExportTokenDBTrigger	proc	far
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Set the thing disabled.
	;
		GetResourceHandleNS	ExportTokenDialog, bx
		mov	si, offset	ExportTokenDialog
		mov	di, mask MF_CALL
		mov	dl, VUM_NOW
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		call	ObjMessage
		
		.leave
		ret
DisableExportTokenDBTrigger	endp

DocumentUI	ends
