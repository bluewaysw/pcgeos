COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		pen
FILE:		fileC.asm

AUTHOR:		Allen Schoonmaker, Jun 19, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial revision


DESCRIPTION:
	This file contains C interface routines for the cell library routines	
		

	$Id: fileC.asm,v 1.1 97/04/05 01:28:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

C_Pen	segment	resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkDBInit

C DECLARATION:	extern void 
			_far _pascal InkDBInit(FileHandle fh);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKDBINIT		proc	far	
	C_GetOneWordArg	bx, cx, dx
	call	InkDBInit
	ret
INKDBINIT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkDBGetHeadFolder

C DECLARATION:	extern dword 
			_far _pascal InkDBGetHeadFolder(FileHandle fh);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKDBGETHEADFOLDER		proc	far	
	C_GetOneWordArg	bx, cx, dx
	mov	dx, di			; preserve DI
	call	InkDBGetHeadFolder
	xchg	dx, ax		; dx <- handle.high, ax <- saved di
	xchg	ax, di		; ax <- handle.low, di <- saved di
	ret
INKDBGETHEADFOLDER	endp

PenGenericData	struct
	PGDS_dword1	dword (?)
	PGDS_dword2 	dword (?)
	PGDS_word1	word (?)
PenGenericData	ends


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkDBGetDisplayInfo

C DECLARATION:	extern void 
			_far _pascal InkDBGetDisplayInfo(PenGenericData _far \
						*RetValue, FileHandle fh);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKDBGETDISPLAYINFO		proc	far	RetValue:fptr, fh:lptr
							uses ds, si, bp
	.enter

	mov	bx, fh
	call	InkDBGetDisplayInfo
	lds	si, RetValue
	mov	ds:[si].PGDS_dword1.high, ax
	mov	ds:[si].PGDS_dword1.low, di
	mov	ds:[si].PGDS_dword2.high, dx
	mov	ds:[si].PGDS_dword2.low, cx
	mov	ds:[si].PGDS_word1, bp
	.leave
	ret
INKDBGETDISPLAYINFO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkDBSetDisplayInfo

C DECLARATION:	extern void 
			_far _pascal InkDBSetDisplayInfo(FileHandle fh, 
			dword ofh, dword note, word page);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKDBSETDISPLAYINFO	proc	far	fh:lptr, ofh:fptr, note:fptr, pg:word
							uses di, bp
	.enter
	mov	bx, fh
	mov	ax, ofh.high
	mov 	di, ofh.low
	mov 	dx, note.high
	mov	cx, note.low
	mov	bp, pg
	call	InkDBSetDisplayInfo
	.leave
	ret
INKDBSETDISPLAYINFO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkSetDocPageInfo

C DECLARATION:	extern void 
			_far _pascal InkSetDocPageInfo(PageSizeReport 
			_far *psr, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKSETDOCPAGEINFO		proc	far	psr:fptr, fh:word
							uses ds, si
	.enter
	lds	si, psr
	mov	bx, fh
	call	InkSetDocPageInfo
	mov	psr.high, ds
	mov	psr.low, si
	.leave
	ret
INKSETDOCPAGEINFO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkGetDocPageInfo

C DECLARATION:	extern void 
			_far _pascal InkGetDocPageInfo(PageSizeReport _far 
			*psr, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKGETDOCPAGEINFO		proc	far	psr:fptr, fh:lptr
							uses ds, si
	.enter
	lds	si, psr
	mov	bx, fh
	call	InkGetDocPageInfo
	mov	psr.high, ds
	mov	psr.low, si
	.leave
	ret
INKGETDOCPAGEINFO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkSetDocGString

C DECLARATION:	extern void 
			_far _pascal InkSetDocGString(FileHandle dbfh, 
			word type);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKSETDOCGSTRING		proc	far	
	C_GetTwoWordArgs bx, ax, cx, dx
	call	InkSetDocGString
	ret
INKSETDOCGSTRING	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkGetDocGString

C DECLARATION:	extern word
			_far _pascal InkGetDocGString(FileHandle dbfh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKGETDOCGSTRING		proc	far	
	C_GetOneWordArg bx, cx, dx 
	call	InkGetDocGString
	ret
INKGETDOCGSTRING	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkSetDocCustomGString

C DECLARATION:	extern void 
			_far _pascal InkSetDocCustomGString(
				FileHandle dbfh, Handle gh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKSETDOCCUSTOMGSTRING		proc	far	
	C_GetTwoWordArgs bx, ax, cx, dx
	call	InkSetDocCustomGString
	ret
INKSETDOCCUSTOMGSTRING	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkGetDocCustomGString

C DECLARATION:	extern Handle 
			_far _pascal InkGetDocCustomGString(FileHandle dbfh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKGETDOCCUSTOMGSTRING		proc	far	
	C_GetOneWordArg bx, cx, dx
	call	InkGetDocCustomGString
	ret
INKGETDOCCUSTOMGSTRING	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkSendTitleToTextObject

C DECLARATION:	extern void 
			_far _pascal InkSendTitleToTextObject(dword tag, 
				FileHandle fh, optr to);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKSENDTITLETOTEXTOBJECT 	proc	far	tag:dword, fh:lptr, to:optr
							uses di
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	mov 	cx, to.high
	mov	dx, to.low
	call	InkSendTitleToTextObject
	.leave
	ret
INKSENDTITLETOTEXTOBJECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkGetTitle

C DECLARATION:	extern word
			_far _pascal InkGetTitle(dword tag, FileHandle fh, 
			char _far *dest);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKGETTITLE		proc	far	tag:dword, fh:lptr, dest:fptr
							uses ds, si
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	lds	si, dest
	call	InkGetTitle
	mov 	ax, cx
	.leave
	ret
INKGETTITLE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkGetParentFolder

C DECLARATION:	extern dword
			_far _pascal InkGetParentFolder(dword tag, 
			FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKGETPARENTFOLDER		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx
	xchg	dx, di
	call	InkGetParentFolder
	xchg	ax, dx		; dx <- dbgroup, ax <- saved di
	xchg	ax, di		; ax <- dbitem, di <- saved di
	ret
INKGETPARENTFOLDER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderSetTitleFromTextObject

C DECLARATION:	extern void 
			_far _pascal InkFolderSetTitleFromTextObject(
			dword fldr, FileHandle fh, optr text);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERSETTITLEFROMTEXTOBJECT	proc	far	fldr:dword, fh:lptr, txt:optr
							uses di
	.enter
	mov 	ax, fldr.high
	mov	di, fldr.low
	mov	bx, fh
	mov	cx, txt.high
	mov	dx, txt.low
	call	InkFolderSetTitleFromTextObject
	.leave
	ret
INKFOLDERSETTITLEFROMTEXTOBJECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderSetTitle

C DECLARATION:	extern void 
			_far _pascal InkFolderSetTitle(dword fldr, 
			FileHandle fh, char _far *name);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERSETTITLE		proc	far	note:dword, fh:word, nme:fptr
							uses di, si
	.enter
	movdw	axdi, note
	mov	bx, fh
	lds	si, nme
	call	InkFolderSetTitle
	.leave
	ret
INKFOLDERSETTITLE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSetTitleFromTextObject

C DECLARATION:	extern void 
			_far _pascal InkNoteSetTitleFromTextObject(
			dword fldr, FileHandle fh, optr text);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTESETTITLEFROMTEXTOBJECT	proc	far	note:dword, fh:lptr, txt:optr
							uses di
	.enter
	movdw 	axdi, note
	mov	bx, fh
	movdw	cxdx, txt
	call	InkNoteSetTitleFromTextObject
	.leave
	ret
INKNOTESETTITLEFROMTEXTOBJECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSetTitle

C DECLARATION:	extern void 
			_far _pascal InkNoteSetTitle(dword fldr, 
			FileHandle fh, char _far *name);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTESETTITLE		proc	far	fldr:dword, fh:word, nme:fptr
							uses di, si
	.enter
	mov	ax, fldr.high
	mov 	di, fldr.low
	mov	bx, fh
	lds	si, nme
	call	InkNoteSetTitle
	.leave
	ret
INKNOTESETTITLE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderGetContents

C DECLARATION:	extern dword 
			_far _pascal InkFolderGetContents(dword tag, 
						FileHandle fh,
						DBGroupAndItem *subFolders);
			

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version
	AMS	9/4/92		Fixed return values
------------------------------------------------------------------------------@
INKFOLDERGETCONTENTS		proc	far	tag:dword, fh:lptr, \
						subFolders:fptr.DBGroupAndItem
							uses ds, di, si
	.enter
	movdw	axdi, tag
	mov	bx, fh
	call	InkFolderGetContents
	lds	si, subFolders		
	movdw	ds:[si], axdi		; *subFolders = ax.di
	mov	ax, cx			; return dx.cx (in dx.ax)
	.leave
	ret
INKFOLDERGETCONTENTS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderGetNumChildren

C DECLARATION:	extern dword 
			_far _pascal InkFolderGetNumChildren(
				dword fldr, FileHandle fh);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERGETNUMCHILDREN		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx
	push	di
	mov	di, dx
	call	InkFolderGetNumChildren
	mov	ax, dx
	mov	dx, cx
	pop	di
	ret
INKFOLDERGETNUMCHILDREN	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderDisplayChildInList

C DECLARATION:	extern void 
			_far _pascal InkFolderDisplayChildInList(
			dword fldr, FileHandle fh, optr list, word entry);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERDISPLAYCHILDINLIST	proc	far	fldr:dword, fh:word, list:optr, \
						entry:word, displayFolders:word
							uses di, bp, si
	.enter
	mov	ax, fldr.high
	mov	di, fldr.low
	mov 	bx, fh
	mov	cx, list.high
	mov	dx, list.low
	mov 	bp, entry
	mov	si, displayFolders
	call	InkFolderDisplayChildInList
	.leave
	ret
INKFOLDERDISPLAYCHILDINLIST	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderGetChildInfo

C DECLARATION:	extern Boolean
			_far _pascal InkFolderGetChildInfo(
				dword fldr,
				FileHandle fh,
				word child,
				word *childID);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version
	AMS	9/4/92		Fixed it

------------------------------------------------------------------------------@
INKFOLDERGETCHILDINFO		proc	far	fldr:dword, fh:word, \
						child:word, childID:fptr.dword

							uses ds, di, si
	.enter
	movdw	axdi, fldr
	mov	bx, fh
	mov	cx, child	
	call	InkFolderGetChildInfo
	lds	si, childID			; Copy AX:DI to *childID
	movdw	ds:[si], axdi
	mov	ax, 0				; Set AX = carry
	jnc	done
	dec	ax
done:
	.leave
	ret
INKFOLDERGETCHILDINFO	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderGetChildNumber

C DECLARATION:	extern word
			_far _pascal InkFolderGetChildNumber(
				dword fldr, FileHandle fh, dword note);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERGETCHILDNUMBER		proc	far	fldr:dword, fh:lptr, note:dword
							uses di
	.enter
	mov	ax, fldr.high
	mov	di, fldr.low
	mov	bx, fh
	mov	dx, note.high
	mov	cx, note.low	
	call	InkFolderGetChildNumber
	.leave
	ret
INKFOLDERGETCHILDNUMBER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderCreateSubFolder

C DECLARATION:	extern dword 
			_far _pascal InkFolderCreateSubFolder(
				dword tag, FileHandle fh);
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERCREATESUBFOLDER		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx
	xchg	dx, di
	call	InkFolderCreateSubFolder
	xchg	ax, dx		; dx <- dbgroup, ax <- saved di
	xchg	ax, di		; ax <- dbitem, di <- saved di
	ret
INKFOLDERCREATESUBFOLDER	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderMove

C DECLARATION:	extern void 
			_far _pascal InkFolderMove(dword fldr, dword pfldr);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERMOVE		proc	far	fldr:dword, parent:dword
							uses di
	.enter
	mov	ax, fldr.high
	mov	di, fldr.low	
	mov	dx, parent.high
	mov	cx, parent.low
	call	InkFolderMove
	.leave
	ret
INKFOLDERMOVE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderDelete

C DECLARATION:	extern void 
			_far _pascal InkFolderDelete(dword tag, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERDELETE		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx
	xchg	dx, di
	call	InkFolderDelete
	mov	di, dx
	ret
INKFOLDERDELETE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkFolderDepthFirstTraverse

C DECLARATION:	extern void 
			_far _pascal InkFolderDepthFirstTraverse(   \
					dword rfldr, FileHandle fh, \
					Boolean (*callback)(
						dword fldr,
						VMFileHandle fh,
						word *info), 
					word *info);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKFOLDERDEPTHFIRSTTRAVERSE	proc	far	fldr:dword, fh:lptr, \
						cb:fptr.far, info:fptr
				uses es, si, di

	ForceRef cb		;Used by _INKFOLDERDEPTHFIRSTTRAVERSE_callback
	ForceRef info		;Used by _INKFOLDERDEPTHFIRSTTRAVERSE_callback
	.enter
	mov	ax, fldr.high
	mov	di, fldr.low
	mov 	bx, fh
	mov	cx, cs
	mov	dx, offset _INKFOLDERDEPTHFIRSTTRAVERSE_callback
	call	InkFolderDepthFirstTraverse
	.leave
	ret
INKFOLDERDEPTHFIRSTTRAVERSE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	_INKFOLDERDEPTHFIRSTTRAVERSE_callback

C DESCRIPTION:	

C DECLARATION:	extern void 
			_far _pascal _INKFOLDERDEPTHFIRSTTRAVERSE_callback(void);

;		Pass:		BX	= VM file handle
;				AX.DI	= folder
;				BP	= data passed in
;		Return: 	Carry	= Set to end traversal
;				BP	= data to pass on

		calls

                                        Boolean (_pascal *callback)(
                                                      dword fldr,
                                                      VMFileHandle fh,
                                                      word *info),


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	7/ 6/92		Initial version

------------------------------------------------------------------------------@
_INKFOLDERDEPTHFIRSTTRAVERSE_callback		proc	far	

	.enter inherit INKFOLDERDEPTHFIRSTTRAVERSE
	pushdw	axdi			; fldr
	push	bx			; file handle
	pushdw	ss:[info]
	movdw	bxax, ss:[cb]
	call	ProcCallFixedOrMovable
	
	tst	ax
	jz	done
	stc
done:	
	.leave
	ret
_INKFOLDERDEPTHFIRSTTRAVERSE_callback	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteCreate

C DECLARATION:	extern dword
			_far _pascal InkNoteCreate(dword tag, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTECREATE		proc	far	tag:dword, fh:lptr
						uses di
	.enter
	mov	ax, tag.high
	mov 	di, tag.low
	mov	bx, fh
	call	InkNoteCreate
	mov	dx, ax
	mov	ax, di
	.leave
	ret
INKNOTECREATE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteCopyMoniker

C DECLARATION:	extern void 
			_far _pascal InkNoteCopyMoniker(void);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/24/92		Initial version

------------------------------------------------------------------------------@
INKNOTECOPYMONIKER		proc	far	tite:dword, lust:optr, tip:word,
					try:word
							uses di, si
	.enter
	mov	di, tite.high
	mov	cx, tite.low
	mov	bx, lust.high
	mov	si, lust.low
	mov	ax, tip
	mov	dx, try
	call	InkNoteCopyMoniker
	.leave
	ret
INKNOTECOPYMONIKER	endp



COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteGetPages

C DECLARATION:	extern void 
			_far _pascal InkNoteGetPages(dword tag, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTEGETPAGES		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx
	xchg	dx, di
	call	InkNoteGetPages
	xchg	ax, dx		; dx <- dbgroup, ax <- saved di
	xchg	ax, di		; ax <- dbitem, di <- saved di
	ret
INKNOTEGETPAGES	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteGetNumPages

C DECLARATION:	extern word
			_far _pascal InkNoteGetNumPages(dword item)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTEGETNUMPAGES		proc	far	
	C_GetTwoWordArgs ax, dx, bx, cx
	xchg	dx, di
	call	InkNoteGetNumPages
	mov	di, dx
	mov_tr 	ax, cx
	ret
INKNOTEGETNUMPAGES	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteCreatePage

C DECLARATION:	extern void 
			_far _pascal InkNoteCreatePage(dword tag, 
			FileHandle fh, word page);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTECREATEPAGE	proc	far	tag:dword, fh:lptr, paige:word
							uses di
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	mov	cx, paige		
	call	InkNoteCreatePage
	mov	ax, cx
	.leave
	ret
INKNOTECREATEPAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteLoadPage

C DECLARATION:	extern void 
			_far _pascal InkNoteLoadPage(dword tag, 
			FileHandle fh, word page, optr obj, word type);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTELOADPAGE		proc	far	tag:dword, fh:lptr, paige:word, \
					obj:optr, tupe:word
							uses di,si,bp
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	mov	cx, paige
	mov	dx, obj.high
	mov	bp, obj.low
	mov	si, tupe
	call	InkNoteLoadPage
	.leave
	ret
INKNOTELOADPAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSavePage

C DECLARATION:	extern void 
			_far _pascal InkNoteSavePage(dword tag, 
			FileHandle fh, word page, optr obj, word type);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTESAVEPAGE		proc	far	tag:dword, fh:lptr, paige:word, \
					obj:optr, tup:word
							uses di, bp, si
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	mov	cx, paige
	mov	dx, obj.high
	mov	bp, obj.low
	mov	si, tup
	call	InkNoteSavePage
	.leave
	ret
INKNOTESAVEPAGE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSetKeywordsFromTextObject

C DECLARATION:	extern void 
			_far _pascal InkNoteSetKeywordsFromTextObject(
			dword tag, FileHandle fh, char *text);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTESETKEYWORDSFROMTEXTOBJECT	proc	far	tag:dword, fh:lptr, \
							txt:optr
							uses di
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	mov	cx, txt.high
	mov	dx, txt.low
	call	InkNoteSetKeywordsFromTextObject
	.leave
	ret
INKNOTESETKEYWORDSFROMTEXTOBJECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSetKeywords

C DECLARATION:	extern void 
			_far _pascal InkNoteSetKeywords(dword tag, \
			FileHandle fh, fptr text);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTESETKEYWORDS		proc	far	tag:dword, fh:lptr, txt:fptr
						uses ds, di, si
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	lds	si, txt
	call	InkNoteSetKeywords
	.leave
	ret
INKNOTESETKEYWORDS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteGetKeywords

C DECLARATION:	extern word
			_far _pascal InkNoteGetKeywords(dword tag, 
			FileHandle fh, char *text);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTEGETKEYWORDS	proc	far	tag:dword, fh:lptr, dest:fptr
							uses ds, di, si
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov 	bx, fh
	lds	si, dest
	call	InkNoteGetKeywords
	mov	ax, cx
	.leave
	ret
INKNOTEGETKEYWORDS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSendKeywordsToTextObject

C DECLARATION:	extern void 
			_far _pascal InkNoteSendKeywordsToTextObject(dword tag,
			FileHandle fh, optr text);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTESENDKEYWORDSTOTEXTOBJECT	proc	far	tag:dword, fh:lptr, txt:optr
							uses di
	.enter
	mov	ax, tag.high
	mov	di, tag.low
	mov	bx, fh
	mov	cx, txt.high
	mov	dx, txt.low
	call	InkNoteSendKeywordsToTextObject
	.leave
	ret
INKNOTESENDKEYWORDSTOTEXTOBJECT	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteDelete

C DECLARATION:	extern void 
			_far _pascal InkNoteDelete(dword tag, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/22/92		Initial version

------------------------------------------------------------------------------@
INKNOTEDELETE		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx	
	xchg	dx, di
	call	InkNoteDelete
	mov	di, dx
	ret
INKNOTEDELETE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteMove

C DECLARATION:	extern void 
			_far _pascal InkNoteMove(dword tag, dword pfldr, 
			FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTEMOVE		proc	far	note:fptr, fldr:dword, fh:lptr
							uses di
	.enter
	mov	ax, note.high
	mov	di, note.low
	mov	dx, fldr.high
	mov	cx, fldr.low			
	mov	bx, fh
	call	InkNoteMove
	.leave
	ret
INKNOTEMOVE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSetModificationDate

C DECLARATION:	extern void 
			_far _pascal InkNoteSetModificationDate(
			word tdft1, tdft2, dword note, FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTESETMODIFICATIONDATE	proc	far	tgdt1:word, tgdt2:word, \
						note:fptr, fh:lptr
							uses di
	.enter
	mov	cx, tgdt1
	mov 	dx, tgdt2
	mov	di, note.high
	mov	ax, note.low
	mov	bx, fh
	call	InkNoteSetModificationDate
	.leave
	ret
INKNOTESETMODIFICATIONDATE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteGetModificationDate

C DECLARATION:	extern dword 
			_far _pascal InkNoteGetModificationDate(dword note, 
			FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTEGETMODIFICATIONDATE		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx	; ax <- group, dx <- item,
						; bx <- file
	push	di
	mov	di, dx
	call	InkNoteGetModificationDate
	mov_tr 	ax, dx
	mov	dx, cx
	pop	di
	ret
INKNOTEGETMODIFICATIONDATE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteGetCreationDate

C DECLARATION:	extern dword 
			_far _pascal InkNoteGetCreationDate(dword note, 
			FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTEGETCREATIONDATE		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx	; ax <- group, dx <- item,
						; bx <- file
	push	di
	mov	di, dx
	call	InkNoteGetCreationDate
	mov_tr 	ax, dx
	mov	dx, cx
	pop	di
	ret
INKNOTEGETCREATIONDATE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteGetNoteType

C DECLARATION:	extern void 
			_far _pascal InkNoteGetNoteType(dword note, 
			FileHandle fh);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTEGETNOTETYPE		proc	far	
	C_GetThreeWordArgs ax, dx, bx, cx
	xchg	dx, di
	call	InkNoteGetNoteType
	clr 	ah
	mov	al, cl
	mov	di, dx
	ret
INKNOTEGETNOTETYPE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteSetNoteType

C DECLARATION:	extern void 
			_far _pascal InkNoteSetNoteType(dword note, 
			FileHandle fh, NoteType nt);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTESETNOTETYPE		proc	far	nite:fptr, fh:lptr, tip:word
							uses di
	.enter
	mov	di, nite.high
	mov	ax, nite.low
	mov	bx, fh
	mov	cx, tip
	call	InkNoteSetNoteType
	.leave
	ret
INKNOTESETNOTETYPE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteFindByTitle

C DECLARATION:	extern word
			_far _pascal InkNoteFindByTitle(char _far *string, 
			byte opt, Boolean body, FileHandle fh);


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTEFINDBYTITLE	proc	far	string:fptr, opt:byte, body:byte, \
					fh:lptr
							uses ds, si
	.enter
	lds	si, string
	clr	ah
	mov	al, opt
	mov	ah, body
	mov	bx, fh
	call	InkNoteFindByTitle
	mov	ax, dx
	.leave
	ret
INKNOTEFINDBYTITLE	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkNoteFindByKeywords

C DECLARATION:	extern word
			_far _pascal InkNoteFindByKeywords(FileHandle fh, 
			char _far *strings, word opt);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/23/92		Initial version

------------------------------------------------------------------------------@
INKNOTEFINDBYKEYWORDS		proc	far	string:fptr, opt:word, fh:lptr
							uses ds, si
	.enter
	lds	si, string
	mov	ax, opt
	mov	bx, fh
	call	InkNoteFindByKeywords
	mov	ax, dx
	.leave
	ret
INKNOTEFINDBYKEYWORDS	endp

C_Pen	ends
	
	SetDefaultConvention






