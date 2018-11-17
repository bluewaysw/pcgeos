COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		jsPrimary.asm

AUTHOR:		Chris Thomas

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_META_FUP_KBD_CHAR   Intercepts the jotter key to prevent
				activating the jotter app.

    MTD MSG_VIS_OPEN

    MTD MSG_JS_PRIMARY_DO_CALIBRATION 
				Put up the calibration dialog.

    MTD MSG_JS_PRIMARY_DO_THE_TIME_DATE_THING 
				Put up the time/date entry dialog.

    INT InitOwnerInfo           Get the current owner information and
				display it.

    INT GetOwnerString          Return owner info string in passed buffer.

    INT SetupDismissTrigger     Sets up the dismiss trigger for the screen

    MTD MSG_JS_PRIMARY_DONE_OWNER 
				User's done entering owner information

    INT QuitStartupCommon       Write INI file and bail.

    MTD MSG_JSP_QUERY_CITY_MONIKER 
				The CityList sends this message to the
				process in order to get the city name to
				display.

    MTD MSG_META_FUP_KBD_CHAR   Intercepted to implement scrolling to the
				entries beginning with the typed letter.

    INT JSCityListScrollSelect  This procedure causes the JSCityList to scroll to the first entry beginning with the supplied character value. This entry becomes selected.  If no such entry exists, the list will scroll/select the nearest previous entry.

    MTD MSG_JSP_CITY_APPLY      The CityList sends this message to the
				process when a change of selection has
				occured.

    MTD MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC 
				The mnemonic is intercepted so we can pass
				the focus to our linked object.

    INT VisCheckIfFullyEnabled  The mnemonic is intercepted so we can pass
				the focus to our linked object.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
        cthomas	8/26/93   	Initial version.

DESCRIPTION:
	


	$Id: jsPrimary.asm,v 1.1 97/04/04 16:53:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSAMetaFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepts the jotter key to prevent activating the
		jotter app.

CALLED BY:	MSG_META_FUP_KBD_CHAR
PASS:		*ds:si	= JSApplicationClass object
		ds:di	= JSApplicationClass instance data
		ds:bx	= JSApplicationClass object (same as *ds:si)
		es 	= segment of JSApplicationClass
		ax	= message #
		cx = character value
		dl = CharFlags
		dh = ShiftState
		bp low = ToggleState
		bp high = scan code
RETURN:		
	carry set if character was handled by someone (and should
		not be used elsewhere).
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	2/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSAMetaFupKbdChar	method dynamic JSApplicationClass, 
					MSG_META_FUP_KBD_CHAR
	;
	;  Don't allow detaching here.
	;
		cmp	cx, (CS_CONTROL shl 8 or VC_F3)
		jne	doJotter

		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jnz	done
doJotter:
	;
	; Was jotter key pressed?
	;
		cmp	cx, (CS_UI_FUNCS shl 8 or UC_JOTTER)
		jne	callSuper
done:
		mov	ax, SST_NO_INPUT
		call	UserStandardSound
		stc			; we ate the key
		ret
callSuper:
		mov	di, offset JSApplicationClass
		GOTO	ObjCallSuperNoLock
JSAMetaFupKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSAVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_VIS_OPEN
PASS:		*ds:si	= JSApplicationClass object
		ds:di	= JSApplicationClass instance data
		ds:bx	= JSApplicationClass object (same as *ds:si)
		es 	= segment of JSApplicationClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	5/ 5/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSAVisOpen	method dynamic JSPrimaryClass, 
					MSG_VIS_OPEN
	mov	di, offset @CurClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_JS_PRIMARY_DO_CALIBRATION
	mov	di, mask MF_FORCE_QUEUE
	mov	bx, ds:[LMBH_handle]
	GOTO	ObjMessage

JSAVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPrimaryDoCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the calibration dialog.

CALLED BY:	MSG_JS_PRIMARY_DO_CALIBRATION

PASS:		es	= dgroup
		*ds:si	= JSPrimaryClass object
		ds:di	= JSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JSPrimaryDoCalibration	method dynamic JSPrimaryClass, 
					MSG_JS_PRIMARY_DO_CALIBRATION
	;
	;  Create the calibration screen
	;
		mov	di, si
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	ax, mask CSF_NO_CANCEL_TRIGGER or \
			    mask CSF_INSTRUCTIONS_ON_SCREEN
		call	InitCalibrationScreen         ; bx:si <- dup screen
	;
	;  Invoke it
	;
		call	UserDoDialog
	;
	;  Destroy it
	;
		call	ShutdownCalibrationScreen
	;
	; Move on to time/date
	;
		mov	ax, MSG_JS_PRIMARY_DO_THE_TIME_DATE_THING
		mov	si, di
		GOTO	ObjCallInstanceNoLock

JSPrimaryDoCalibration	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPrimaryDoTheTimeDateThing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the time/date entry dialog.

CALLED BY:	MSG_JS_PRIMARY_DO_THE_TIME_DATE_THING

PASS:		*ds:si	= JSPrimaryClass object
		ds:di	= JSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSPrimaryDoTheTimeDateThing	method dynamic JSPrimaryClass, 
					MSG_JS_PRIMARY_DO_THE_TIME_DATE_THING
		.enter
	;
	;  Create the timedate screen
	;
		GetResourceSegmentNS dgroup, es		;es = dgroup
		push	si
		mov	cx, ds:[LMBH_handle]
		mov	dx, offset JSInfoArea
		mov	ax, mask OSF_OWNER_NAME		; we only want owner's name
		call	InitOwnerScreen	      ; bx:si <- dup screen
		call	InitOwnerInfo

		pop	di
		mov	di, ds:[di]
		add	di, ds:[di].JSPrimary_offset
		movdw	ds:[di].JSPI_screen, bxsi
	;
	; Put it up
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
	;
	; And bring up the interaction that contains it
	;
		mov	si, offset JSMainScreen
		call	ObjCallInstanceNoLock
	;
	; Setup the dismiss trigger
	;
		mov	cx, MSG_JS_PRIMARY_DONE_OWNER
		call	SetupDismissTrigger
if _CITY_LIST
	;
	; Let the local city be shown in the header for the
	; city list.
	;
		mov	ax, MSG_GEN_APPLY
                mov     bx, handle JCityList
                mov     si, offset JCityList
		clr	di
                call    ObjMessage
endif		
	.leave
	ret

JSPrimaryDoTheTimeDateThing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOwnerInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current owner information and display it.

CALLED BY:	JSPrimaryDoTheTimeDateThing

PASS:		^lbx:si = GenInteraction parent of the text object
					we're interested in.
		ds	= segment of object block of primary

RETURN:		ds	= new segment of block (may have changed)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitOwnerInfo	proc	near
		uses	ax, bx, cx, dx, si, di, bp, es
		.enter
	;
	;  Get the text object.  If not found, die.
	;
		clr	cx			; find first child
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		mov	di, mask MF_CALL
		call	ObjMessage	; ^lcx:dx <- child

NEC <		jc	bail	; => very scrod				>
EC <		ERROR_C	FIRST_CHILD_OF_OWNER_INTERACTION_NOT_FOUND	>

if ERROR_CHECK
	;
	;  Make sure it's of the right class.
	;
		push	cx, dx
		movdw	bxsi, cxdx
		mov	cx, segment GenTextClass
		mov	dx, offset GenTextClass
		mov	ax, MSG_META_IS_OBJECT_IN_CLASS
		mov	di, mask MF_CALL
		call	ObjMessage		; carry set if in class
		pop	cx, dx
		ERROR_NC FIRST_CHILD_OF_OWNER_INTERACTION_NOT_TEXT_OBJECT
endif
	;
	;  Get the owner information.  Text obj in ^lcx:dx for now.
	;  Make room on stack for string.
	;
		mov	bp, OWNER_BUFFER_SIZE	; bp <- buffer size
		sub	sp, bp			; allocate buffer
		segmov	es, ss			; es:di <- buffer
		mov	di, sp

		call	GetOwnerString
		jc	done	; => no field
	;
	;  ax will equal one (1) if no information was read, since
	;  there will be at least a null-terminator.
	;
		cmp	ax, 1			; read at least one char?
		jbe	done	; => nothing to display

	;
	;  Put the string in the text object.
	;
		movdw	bxsi, cxdx
		movdw	dxbp, esdi		; dx:bp -> string
		clr	cx			; it *is* null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
done:
	;
	;  Clean up.
	;
		add	sp, OWNER_BUFFER_SIZE		

bail:
	;
	;  Don't clean up.
	;

		.leave
		ret
InitOwnerInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOwnerString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return owner info string in passed buffer.

CALLED BY:	InitOwnerInfo

PASS:		es:di = string buffer pointer
		bp    = buffer size

RETURN:		es:di - filled up (with unleaded)
		ax = #bytes read
		carry set if data not found

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OwnerCategoryString	char	OWNER_CATEGORY_STRING
OwnerNameKeyString	char	OWNER_NAME_KEY_STRING

GetOwnerString	proc	near
		uses	bx, cx, dx, si, ds
		.enter
	;
	;  Set up key & category pointers.
	;
		mov	cx, cs				; cx:dx <- key
		mov	dx, offset OwnerNameKeyString
		mov	ds, cx				; ds:si <- category
		mov	si, offset OwnerCategoryString
	;
	;  Note:  InitFileReadData will, in this case, return a
	;  null terminator at the end of the data (it's probably
	;  the one supplied by the text object in Setup's Owner
	;  Screen).  That means if cx = 1, there's no owner info.

							; bp -> buffer size
							; es:di -> buffer
		call	InitFileReadData	; carry set on error
						; cx = size read
						; bx destroyed

		mov_tr	ax, cx				; return ax = size read

		.leave
		ret
GetOwnerString	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupDismissTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the dismiss trigger for the screen

CALLED BY:	JSPrimaryDoOwner, JSPrimaryDoTheTimeDateThing
PASS:		ds	= block containing JSPrimary
		cx	= action message to send to JSPrimary
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupDismissTrigger	proc	near
	uses	ax,cx,dx,si,bp
	.enter

	;
	; Set the action message to send to the primary
	;
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	si, offset OKTrigger
		call	ObjCallInstanceNoLock
	;
	; Make trigger usable
	;
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock

	.leave
	ret
SetupDismissTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPrimaryDoneOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User's done entering owner information

CALLED BY:	MSG_JS_PRIMARY_DONE_OWNER

PASS:		*ds:si	= JSPrimaryClass object
		ds:di	= JSPrimaryClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	7/15/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JSPrimaryDoneOwner	method dynamic JSPrimaryClass, 
					MSG_JS_PRIMARY_DONE_OWNER
		.enter
	;
	; Destroy the owner screen
	;
		movdw	bxsi, ds:[di].JSPI_screen
		call	ShutdownOwnerScreen
	;
	; Turn off the dismiss trigger
	;
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	si, offset JSMainScreen
		mov	dl, VUM_NOW
		call	ObjCallInstanceNoLock
if _CITY_LIST
	;
        ; Save what the local city is:
        ;
                mov     ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
                mov     bx, handle JCityList
                mov     si, offset JCityList
                mov     di, mask MF_CALL or mask MF_FIXUP_DS
                call    ObjMessage              ; ax <- selection
        ;
        ; Find out what the absolulte record for that selection is.
        ;
		mov_tr	cx, ax
		call    JWTDatabaseGetAbsoluteRecordNumber
						; cx <- abs value
 
        ;
        ; Save the new local city to the ini file.
        ;
                call    JWTDatabaseSetLocalCity
endif
	;
	;  Do the other stuff...
	;
		call	QuitStartupCommon

		.leave
		ret
JSPrimaryDoneOwner	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuitStartupCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write INI file and bail.

CALLED BY:	JSPrimaryDoneOwner, WelcomeStartSelect

PASS:		ds = any object block

RETURN:		nothing

DESTROYED:	all

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	11/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
systemSetupCatString		char	"system", C_NULL
systemSetupKeyString 		char 	"continueSetup",C_NULL

QuitStartupCommon	proc	far
		.enter
	;
	;  set "continueSetup = false" in the .INI file
	;
		push	ds
		mov	cx, cs
		mov	ds, cx
		mov	es, cx
		mov	si, offset systemSetupCatString
		mov	dx, offset systemSetupKeyString
		mov	ax, FALSE
		call	InitFileWriteBoolean
		call	InitFileCommit
		pop	ds
		
	;
	;  Send a MSG_META_QUIT to the app object
	;
		mov	ax, MSG_META_QUIT
		call	UserCallApplication

		.leave
		ret
QuitStartupCommon	endp

if _CITY_LIST

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
              JSPQueryCityMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:     The CityList sends this message to the process
              in order to get the city name to display.

CALLED BY:    MSG_JSP_QUERY_CITY_MONIKER
PASS:         *ds:si  = JSProcessClass object
              ds:di   = JSProcessClass instance data
              ds:bx   = JSProcessClass object (same as *ds:si)
              es      = segment of JSProcessClass
              ax      = message #
              ^lcx:dx = The dynamic list requesting the moniker
              bp      = position of the item requested
RETURN:               nothing
DESTROYED:    ax, cx, dx, bp
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
      Name    Date            Description
      ----    ----            -----------
      ACJ     1/28/95         Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSPQueryCityMoniker   method dynamic JSProcessClass, 
                                      MSG_JSP_QUERY_CITY_MONIKER
jwtdbRec      local   JWTDatabaseRecord
              .enter

		push	bp
		
		pushdw  cxdx
		mov     ax, ss:[bp]
		push    ax
		
	;
	; Find out what the real record number is.
	;
		mov	cx, ax
		call    JWTDatabaseGetAbsoluteRecordNumber ; cx <- absoulute

		segmov	es, ss
		lea     di, jwtdbRec
		call    JWTDatabaseReadRecord	; buffer filled.
		

      ;
      ; Tell our dynamic list what the moniker should be
      ;
              mov     cx, ss
              lea     dx, ss:jwtdbRec.JWTDR_cityCountry
              mov_tr  ax, bp                          ; save for locals
              pop     bp                              ; bp <-item
              popdw   bxsi                            ; ^lbx:si <- city list
              push    ax                              ; save for locals
              mov     di, mask MF_CALL
              mov     ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_TEXT
              call    ObjMessage

              pop     bp
              .leave
              ret
JSPQueryCityMoniker   endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSCLMetaKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to implement scrolling to the entries
   		beginning with the typed letter.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= JSCityListClass object
		ds:di	= JSCityListClass instance data
		ds:bx	= JSCityListClass object (same as *ds:si)
		es 	= segment of JSCityListClass
		ax	= message #

	cx - character value
		SBCS: ch = CharacterSet, cl = Chars
		DBCS: cx = Chars
	dl = CharFlags
	dh = ShiftState
	bp low = ToggleState
	bp high = scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	4/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSCLMetaKbdChar	method dynamic JSCityListClass, 
					MSG_META_FUP_KBD_CHAR
	uses	ax, cx, dx, bp
	.enter

	push	cx,dx,bp
   	mov	di, offset JSCityListClass
	call	ObjCallSuperNoLock
	pop	cx,dx,bp

   ; Ignore releases, extended characters, non-printable characters
   ; --------------------------------------------------------------
	test	dl, mask CF_RELEASE
	jnz	exit
	cmp	ch, CS_BSW
	jne	exit
	mov	ax, cx
	call	LocalIsPrintable
	jz	exit

	call	JSCityListScrollSelect

exit:	.leave
	ret
JSCLMetaKbdChar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSCityListScrollSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This procedure causes the JSCityList to scroll to the
   		first entry beginning with the supplied character value.
   		This entry becomes selected.  If no such entry exists,
   		the list will scroll/select the nearest previous entry.

CALLED BY:	JSCLMetaKbdChar
PASS:		cl  =  Character value
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	4/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSCityListScrollSelect	proc	near
	uses	ax,bx,cx,dx,si,di,bp,es
	.enter

   ; Find the 1st entry starting with the passed character (or closest match)
   ; ------------------------------------------------------------------------
	clr	dx
	push	cx		; store character on stack
	segmov	es, ss, ax
	mov	di, sp		; *es:di = null terminated single char string
	push	dx		; store null on stack
	mov	ax, mask JFF_CLOSEST_MATCH
	call	JWTDatabaseFindRecord	; cx = viewpt record number
	pop	dx
	pop	dx
	jc	exit

   ; Set the selection to the new city number and scroll the list there
   ; ------------------------------------------------------------------
	push	cx
	mov	bx, handle JCityList
	mov	si, offset JCityList
	mov	di, mask MF_CALL
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	dx, 1
	call	ObjMessage
	
	mov	cx, 1
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	call	ObjMessage
	
   	mov	ax, MSG_GEN_APPLY
	call	ObjMessage
	
	pop	cx
	mov	ax, MSG_GEN_ITEM_GROUP_MAKE_ITEM_VISIBLE
	call	ObjMessage
	
exit:	.leave
	ret
JSCityListScrollSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPCityApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The CityList sends this message to the process when
		a change of selection has occured.

CALLED BY:	MSG_JSP_CITY_APPLY
PASS:		*ds:si	= JSProcessClass object
		ds:di	= JSProcessClass instance data
		ds:bx	= JSProcessClass object (same as *ds:si)
		es 	= segment of JSProcessClass
		ax	= message #
		cx 	= current selection
		bp	= number of selections
 		dl 	= GenItemGroupStateFlags

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSPCityApply	method dynamic JSProcessClass, 
					MSG_JSP_CITY_APPLY
jwtdbRec	local 	JWTDatabaseRecord
		.enter
	;
	; Get thre requested record out of the database.
	; If it couldn't get the record, then
	; just don't update the glyph that shows the current
	; local city.
	;
		segmov	es, ss
		lea	di, ss:jwtdbRec
		call	JWTDatabaseReadRecord
		jc 	done

	;
	; Display the local city in the Glyph above the city list.
	;
		push	bp

		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		mov	bx, handle JCurrentCityGlyph
		mov	si, offset JCurrentCityGlyph
		mov	di, mask MF_CALL or mask MF_FIXUP_DS

		mov	cx, ss
		lea	dx, ss:jwtdbRec
		mov	bp, VUM_NOW

		call	ObjMessage

		pop	bp
done:
		.leave
		ret
JSPCityApply	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MIActivateObjectWithMnemonic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The mnemonic is intercepted so we can pass
		the focus to our linked object.

CALLED BY:	MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
PASS:		*ds:si	= MnemonicInteractionClass object
		ds:di	= MnemonicInteractionClass instance data
		ds:bx	= MnemonicInteractionClass object (same as *ds:si)
		es 	= segment of MnemonicInteractionClass
		ax	= message #
		cx = character value
		dl = CharFlags
		dh = ShiftState (ModBits)
		bp low = ToggleState
		bp high = scan code
		carry set if mnemonic found
		ax, cx, dx, bp - destroyed
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AC	2/28/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MIActivateObjectWithMnemonic	method dynamic	MnemonicInteractionClass, \
				MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC

	call	VisCheckIfFullyEnabled
	jnc	noActivate
	call	VisCheckMnemonic
	jnc	noActivate
	;
	; mnemonic matches, grab focus for some child object
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	tst	ds:[di].MII_mnemonicFocus.high
	jz	noActivate
	movdw	bxsi, ds:[di].MII_mnemonicFocus
	clr	di
	call	ObjMessage
if 0
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	call	MetaGrabFocusExclLow
endif
	stc				;handled, no matter what
	jmp	short exit

noActivate:
	;
	; let superclass call children, since either were are not fully
	; enabled, or our mnemonic doesn't match, superclass won't be
	; activating us, just calling our children
	;
	mov	ax, MSG_SPEC_ACTIVATE_OBJECT_WITH_MNEMONIC
	mov	di, offset MnemonicInteractionClass
	call	ObjCallSuperNoLock
exit:
	Destroy	ax, cx, dx, bp
	ret
MIActivateObjectWithMnemonic	endm

VisCheckIfFullyEnabled	proc	far
	class	VisClass
	push	di
	call	VisCheckIfSpecBuilt		;are we specifically built?
	jz	hardWay				;nope, do it the hard way

	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_FULLY_ENABLED
	clc					;assume not enabled
	jz	exit				;not enabled, branch
	stc					;else return carry set
exit:
	pop	di
	ret

hardWay	:
	push	cx
	mov	cx, -1				;optimization didn't work, so
						;take no shortcuts this time.
	call	GenCheckIfFullyEnabled		;else call generic routine
	pop	cx
	pop	di
	ret

VisCheckIfFullyEnabled	endp

endif ; _CITY_LIST

