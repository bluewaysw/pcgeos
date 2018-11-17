COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genFieldClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenFieldClass	Class that implements a field window

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenField class.

	$Id: genField.asm,v 1.2 98/05/04 05:45:22 joon Exp $

------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

			GenFieldClass

Synopsis
--------

GenFieldClass Implements a field window

Additional documentation
------------------------

	Fields will be used to represent a "Room" or "Work group".  We wish
to have separate mechanisms for:

Active Field
------------
	This will be an exclusive stored in the System object.  This field
will be given the focus, & the system object will respond to the query for
a new application's parent with the active field.  Here are the rules
governing the active field:

	1) It is an illegal condition for the Active Field to have DETACHED
	applications.  Hence, the methods used to set this field as the active
	app must FIRST re-attach any applications, before the field may be
	made the active field.  Since a field must be realized before
	applications may be (re-)launched within it, the sequence of events
	to bring up a field is:
	
	optional	MSG_GEN_FIELD_SET_VIS_PARENT
	optional	MSG_GEN_FIELD_SET_UI_LEVEL

		MSG_META_ATTACH		- to put in generic tree
		MSG_GEN_SET_USABLE	- make usable, will realize the field,
					  but NOT give it the active focus,
					  instead bringing it up in back
		MSG_GEN_BRING_TO_TOP ->
		    MSG_GEN_SYSTEM_GRAB_FIELD_EXCL	- sent to system,
							  to make active field
			-> Calls MSG_GEN_FIELD_RESTORE_APPS to restart
			   any detached apps, to prevent illegal state.

			  MSG_GEN_FIELD_SHUTDOWN_APPS will do nothing if
			  the field currently has the focus, to prevent
			  illegal situation.  It is a lower level mechanism
			  than the field focus, & will not force the loss
			  of focus.

		    MSG_GEN_SYSTEM_RELEASE_FIELD_EXCL - sent to system,
							  to cause field to lose
							  focus & be pushed to
							  the back, if it
							  doesn't have focus.

	2) The active field will have the field focus & will be on top, in
	order to be visible.

Detached Apps
-------------
	While the field group does NOT have the focus, some or all applications
within it may be detached.  Any apps which are detached will be stored
in reference form in the instance data of the field, so that they may be
brought back to life.  The following methods may be used:


	MSG_GEN_FIELD_SHUTDOWN_APPS		- forcibly shuts down ALL apps
						  (system being shut down)
	MSG_GEN_FIELD_REQUEST_SHUTDOWN_OF_APPS (Not yet implemented)
						- will shutdown any apps which
						  can easily shutdown & restore.
						  This will be called
						  automatically
	MSG_GEN_FIELD_RESTORE_APPS		- restarts all apps


Workspace menu		NOT YET IMPLEMENTED:
--------------
	This is the menu which is associated with the field.  The standard
menu varies somewhat between specific UI's, but for the most part is the
same stuff, allowing launching of apps, exiting, etc.  We will be extending
the Primary windows of specific UI's to provide a button in the title area
which will cause this menu to be brought up at that location, as if the
menu were part of the application.  Specific UI's which have pop-up menus
will in addition cause this menu to come up when pressing FEATURES in the
background of the field itself.

	Implementation:

	The specific UI should send MSG_GEN_FIELD_CREATE_WORKSPACE_MENU 
	to create the workspace menu.  It should provide a default menu in
	response.  Alternatively, an environment app which subclasses GenField
	may intercept this method, and provide their own workspace menu.
	They should send MSG_GEN_FIELD_CREATE_SPECIFIC_WORKSPACE_SUBGROUP
	to the GenField, which the specific UI should process, returning
	a group containing ONLY the items specific to the UI.  Specific
	Primary windows may then cause this menu to come up by sending
	MSG_GEN_FIELD_POPUP_WORKSPACE_MENU to the field.

AppWindows  menu	NOT YET IMPLEMENTED:
----------------
	This is the menu which contains the list of applications currently
running in the field.  The contents of this list will be the same across all
specific UI's, & will contain the list of all application objects which
are set USABLE in the field.  Selecting an application from this menu will
bring that app to the top.

	Implementation:

	The specific UI should provide this menu & manage the contents, based
on MSG_GEN_FIELD_ADD_APP_TO_RUNNING_LIST & MSG_GEN_FIELD_REMOVE_APP_FROM_RUNNING_LIST, which will be sent to the field by the default process class for
the applications.  MSG_GEN_FIELD_POPUP_APP_WINDOWS_MENU may be used by
primary windows to cause this menu to come up in a certain place.


------------------------------------------------------------------------------@

UserClassStructures	segment resource

; Declare the class record

	GenFieldClass

UserClassStructures	ends

;-----------------------

Init segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldInitialize

DESCRIPTION:	Initialize object

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass
	ax - MSG_META_INITIALIZE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	NOTE:  THIS ROUTINE ASSUME THAT THE OBJECT HAS JUST BEEN CREATED
	AND HAS INSTANCE DATA OF ALL 0'S FOR THE VIS PORTION

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	10/91		Initial version

------------------------------------------------------------------------------@

GenFieldInitialize	method static	GenFieldClass, MSG_META_INITIALIZE

	or	ds:[di].GI_attrs, mask GA_TARGETABLE

	; force options to be loaded

	push	ax
	mov	ax, ATTR_GEN_INIT_FILE_KEY or mask VDF_SAVE_TO_STATE
	clr	cx
	call	ObjVarAddData
	pop	ax

	mov	di, offset GenFieldClass
	GOTO	ObjCallSuperNoLock

GenFieldInitialize	endm

Init ends

BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenFieldClass

DESCRIPTION:	Build an object

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenFieldBuild	method	GenFieldClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	call	GenSpecGrowParents	; Make sure all generic parents are
					; built out before this object is

					; determine UI to use
	mov	cx, GUQT_UI_FOR_FIELD
	mov	ax, MSG_SPEC_GUP_QUERY
	call	UserCallSystem		; ask system object what UI should be

	mov	bx, ax			; bx = handle of specific UI to use

	mov	ax, SPIR_BUILD_FIELD
	mov	di,MSG_META_RESOLVE_VARIANT_SUPERCLASS
	call	ProcGetLibraryEntry
	GOTO	ProcCallFixedOrMovable

GenFieldBuild	endm


BuildUncommon ends

;---------------------------------------------------

Init segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldEnableBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the bit in the instance data that allows the field to
		draw the BG bitmap.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldEnableBitmap	method	dynamic GenFieldClass, 
						MSG_GEN_FIELD_ENABLE_BITMAP
	ornf	ds:[di].GFI_flags, mask GFF_LOAD_BITMAP
	ret
GenFieldEnableBitmap	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldAttach -- MSG_META_ATTACH for GenFieldClass

DESCRIPTION:	Adds field onto system object only.  Must be set usable
		AFTER this call.

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_META_ATTACH

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version
	chrisb	10/92		added load options call
------------------------------------------------------------------------------@

GenFieldAttach	method	GenFieldClass, MSG_META_ATTACH

	uses	ax
	.enter
	;
	; FIRST, load options.  This must be done before calling the
	; superclass, as in the case of Motif, the superclass makes
	; use of variables that we set here (see OLFieldAttach).
	;

	mov	ax, MSG_META_LOAD_OPTIONS
	call	ObjCallInstanceNoLock

	;
	; Add ourselves to the GenSystem
	;

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_FIND_CHILD		; are we a child yet?
	call	UserCallSystem
	jnc	alreadyThere			; yes, don't add again

	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_FIRST			; Add as first so welcome field
						; will *always* be the last one
						; (this avoids aborted detach
						; problems).
	call	UserCallSystem
alreadyThere:

	;
	; save away info about default launcher
	;
	call	SaveDefaultLauncherInfo
	;
	; enable help windows
	;
	push	ax, bx, cx, dx, bp, si
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	bx, handle SysHelpObject
	mov	si, offset SysHelpObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	mov	bx, handle SysModalHelpObject
	mov	si, offset SysModalHelpObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, cx, dx, bp, si

	.leave
	mov	di, offset GenFieldClass
	GOTO	ObjCallSuperNoLock

GenFieldAttach	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveDefaultLauncherInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find and save GeodeToken for defaultLauncher

CALLED BY:	GenFieldAttach

PASS:		*ds:si = field

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveDefaultLauncherInfo	proc	near
	uses	ax, bx, cx, dx, si, di, es
fieldSegment	local	word	push	ds
fieldChunk	local	word	push	si
catBuf		local	INI_CATEGORY_BUFFER_SIZE dup (char)
geodeToken	local	GeodeToken
	.enter
	mov	ax, TEMP_GEN_FIELD_DEFAULT_LAUNCHER_ID
	call	ObjVarFindData
	LONG jc	done				; already saved
	mov	cx, ss
	lea	dx, catBuf
	mov	ax, MSG_META_GET_INI_CATEGORY
	push	bp
	call	ObjCallInstanceNoLock
	pop	bp
	mov	ds, cx
	mov	si, dx
	mov	cx, segment defaultLauncherKey
	mov	dx, offset defaultLauncherKey
	push	bp
	clr	bp			; give us a buffer
	call	InitFileReadString	; bx = mem handle
	pop	bp
	jc	done			; if no default launcher, leave
	call	MemLock
	mov	ds, ax			; ds:dx = name
	clr	dx
	call	FilePushDir
	mov	ax, SP_APPLICATION
	call	FileSetStandardPath
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	segmov	es, ss
	lea	di, geodeToken
	call	FileGetPathExtAttributes
	jnc	noError
	cmp	ax, ERROR_FILE_NOT_FOUND
	jne	freeDone
	mov	ax, SP_SYS_APPLICATION
	call	FileSetStandardPath
	mov	ax, FEA_TOKEN
	call	FileGetPathExtAttributes
	jc	freeDone
noError:
	push	bx			; save filename block
	mov	ds, fieldSegment
	mov	si, fieldChunk
	mov	ax, TEMP_GEN_FIELD_DEFAULT_LAUNCHER_ID
	mov	cx, size GeodeToken
	call	ObjVarAddData		; ds:bx = GeodeToken
	mov	fieldSegment, ds	; (ds updated)
	segmov	es, ds
	mov	di, bx
	segmov	ds, ss
	lea	si, geodeToken
	mov	cx, size GeodeToken/2
	rep movsw
	pop	bx			; restore filename block
freeDone:
	call	MemFree
done:
	mov	ds, fieldSegment
	.leave
	ret
SaveDefaultLauncherInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load the interface level settings for this field and
		store them in the UI's global dgroup variables.

PASS:		*ds:si	= GenFieldClass object
		es	= segment of GenFieldClass

		ss:bp	- GenOptionsParams

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	This routine should be called as early as possible when the
field is coming up -- definitely before apps start coming up, that
might use these variables.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
	In theory, apps could change .INI flags and then GUP this
	message up to the GenField to change the values on the fly.
	This would not affect already-running apps, however.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 3/92   	Moved here from InitInterfaceLevel

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldLoadOptions	method	dynamic	GenFieldClass, 
					MSG_GEN_LOAD_OPTIONS

	push	ax, si, ds
	segmov	es, dgroup, si		; es <- dgroup

	;
	; Read the interface level.  If not found, assume advanced.
	;

	segmov	ds, ss
	lea	si, ss:[bp].GOP_category

	mov	cx, cs

	; get interface level

	mov	dx, offset interfaceLevelStr
	mov	ax, UIIL_ADVANCED	; set default in case not found
	call	InitFileReadInteger
	mov	es:[uiInterfaceLevel], ax

	; get default launch level

	mov	dx, offset launchLevelStr
	mov	ax, UIIL_ADVANCED	; set default in case not found
	call	InitFileReadInteger
	mov	es:[uiDefaultLaunchLevel], ax

	; get default launch model

	mov	dx, offset launchModelStr
	mov	ax, UILM_MULTIPLE_INSTANCES	; set default in case not found
	call	InitFileReadInteger
	mov	es:[uiLaunchModel], ax

	; get launch options

	mov	ax, mask UILO_DESK_ACCESSORIES
	mov	dx, offset launchOptionsStr
	call	InitFileReadInteger
	mov	es:[uiLaunchOptions], ax

	; get interface options

	mov	ax, mask UIIO_OPTIONS_MENU
	mov	dx, offset interfaceOptionsStr
	call	InitFileReadInteger
	mov	es:[uiInterfaceOptions], ax

	;
	; Call superclass in case subclasses are expecting normal
	; GenClass behavior.
	;
	mov	ax, segment GenFieldClass
	mov	es, ax				; es <- seg of GenFieldClass
	pop	ax, si, ds
	mov	di, offset GenFieldClass
	GOTO	ObjCallSuperNoLock

GenFieldLoadOptions	endm

interfaceLevelStr	char	"interfaceLevel", 0

launchLevelStr		char	"launchLevel", 0

launchModelStr		char	"launchModel", 0

launchOptionsStr	char	"launchOptions", 0

interfaceOptionsStr	char	"interfaceOptions", 0

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenFieldGetIniCategory -- MSG_META_GET_INI_CATEGORY
						for GenFieldClass

DESCRIPTION:	If no ini category is present then use the default

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - The message

	cx:dx - buffer for category

RETURN:
	cx:dx - buffer (preserved)

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/ 6/92		Initial version

------------------------------------------------------------------------------@
GenFieldGetIniCategory	method dynamic	GenFieldClass, 
					MSG_META_GET_INI_CATEGORY

	pushdw	cxdx				; save for return
	pushdw	cxdx
	mov	di, offset GenFieldClass
	call	ObjCallSuperNoLock
	popdw	esdi

	tst	<{byte} es:[di]>
	jnz	gotCategory

	segmov	ds, cs
	mov	si, offset uiFeaturesCategoryString
	mov	cx, length uiFeaturesCategoryString
	rep	movsb
gotCategory:
	popdw	cxdx

	ret

GenFieldGetIniCategory	endm

uiFeaturesCategoryString	char	"uiFeatures", 0


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldSetVisParent
		-- MSG_GEN_FIELD_SET_VIS_PARENT for GenFieldClass

DESCRIPTION:	Sets visual parent for a field object.  Allows setting the
		visible parent to be something other than the default screen
		returned from the system object when queried for the spec build.
		(Should only be called before being set USABLE)

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_SET_VIS_PARENT

	cx:dx	- visible object to use as parent

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/89		Initial version

------------------------------------------------------------------------------@


GenFieldSetVisParent	method	GenFieldClass, MSG_GEN_FIELD_SET_VIS_PARENT
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GFI_visParent.handle, cx
	mov	ds:[di].GFI_visParent.chunk, dx
	ret

GenFieldSetVisParent	endm

Init ends

;--------------------------

Common segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldAppStartupNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
		es - dgroup
RETURN:		cx 	- 0 if it is OK to start up the application
		          non-0 if it is not OK (field is detaching or is not
		     	  attached)
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldAppStartupNotify	method	dynamic GenFieldClass, 
					MSG_GEN_FIELD_APP_STARTUP_NOTIFY

	segmov	es, dgroup, cx				; SH
	mov	cx, -1		;Assume it is not OK to start an app
	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jne	exit
	test	es:[uiFlags], mask UIF_DETACHING_SYSTEM
	jnz	exit
	cmp	ds:[di].GFI_numAttachingApps, 255	;No more than 255 apps
	jz	exit

	inc	ds:[di].GFI_numAttachingApps		; start up and inc #

	push	dx
	mov	ax, MSG_GEN_SYSTEM_MARK_BUSY		; Indicate busy during
	call	UserCallSystem				; startup
	pop	dx

	clr	cx					; Allow app to be
							; allowed to start up
exit:
	ret
GenFieldAppStartupNotify	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldAppStartupDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrements the "current # of attaching apps" count and
		detaches the field if it's marked as needing detaching.

CALLED BY:	GLOBAL
PASS:		*ds:si = GenField
		es = segment of class (dgroup)
RETURN:		nothing
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldAppStartupDone	method dynamic GenFieldClass,
					MSG_GEN_FIELD_APP_STARTUP_DONE
EC <	tst	ds:[di].GFI_numAttachingApps				>
EC <	ERROR_Z	UI_STARTUP_DONE_MSG_RECEIVED_BEFORE_STARTUP_NOTIFY	>

	dec	ds:[di].GFI_numAttachingApps

	test	ds:[di].GFI_flags, mask GFF_DETACHING	;If not detaching, exit
	jz	done

	clr	cx				; no ID
	mov	ax, MSG_META_DETACH
	call	HandleFieldDetachLow		; and handle the detach...
						; (this will check the
						; GFI_numAttachingApps variable
						; anyway, so no need for us to
						; do so...)
done:
	mov	ax, MSG_GEN_SYSTEM_MARK_NOT_BUSY
	call	UserCallSystem
	ret
GenFieldAppStartupDone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldActivateInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
		es - dgroup
		dx	- AppLaunchBlock  (This is NOT considered a reference)
RETURN:		nothing
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/3/93		Split out from STARTUP_REQUEST

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenFieldActivateInitiate	method	dynamic GenFieldClass, 
					MSG_GEN_FIELD_ACTIVATE_INITIATE
EC <	xchg	bx, dx						>
EC <	call	ECCheckMemHandle				>
EC <	xchg	bx, dx						>

	; If in transparent launch model, put up "Activating" dialog
	; while loading in apps -- Doug 4/14/93
	;
	segmov	es, dgroup, bx
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	afterActivationDialog

	tst	es:[uiNoActivationDialog]
	jnz	afterActivationDialog

	mov	bx, dx
	call	MemLock
	push	ds
	mov	ds, ax
	mov	ax, ds:[ALB_appMode]
	pop	ds
	call	MemUnlock

	tst	ax			
	jz	activationDialog	; if NULL, default is to activate
	cmp	ax, MSG_GEN_PROCESS_OPEN_APPLICATION
	jne	afterActivationDialog
activationDialog:
					; No dialog during UI startup (skip
					; SPOOL.GEO, thank you)
	test	es:[uiFlags], mask UIF_INIT
	jnz	afterActivationDialog
	call	NewActivationDialog
afterActivationDialog:
	ret
GenFieldActivateInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldActivateUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
		es - dgroup
		cx	- geode
		dx	- AppLaunchBlock (This is NOT considered a reference)
RETURN:		nothing
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenFieldActivateUpdate	method	dynamic GenFieldClass, 
					MSG_GEN_FIELD_ACTIVATE_UPDATE

EC <	xchg	bx, cx						>
EC <	call	ECCheckGeodeHandle				>
EC <	xchg	bx, cx						>
EC <	xchg	bx, dx						>
EC <	call	ECCheckMemHandle				>
EC <	xchg	bx, dx						>

	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
	jnc	done

	cmp	dx, ds:[bx].AD_appLaunchBlock	; correct block?
	jne	done

	call	UpdateActivationDialog

done:
	ret
GenFieldActivateUpdate	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldActivateDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal robustly w/notification that a geode is "on screen".
		Specifically, get rid of any "Activating" dialog that is
		up for it.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
		es - dgroup
		cx	- geode, if known
		dx	- AppLaunchBlock, if geode not known
RETURN:		nothing
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldActivateDimiss	method	static GenFieldClass, 
					MSG_GEN_FIELD_ACTIVATE_DISMISS

EC <	tst	cx						>
EC <	jz	noGeode						>
EC <	xchg	bx, cx						>
EC <	call	ECCheckGeodeHandle				>
EC <	xchg	bx, cx						>
EC <	jmp	short afterEC					>
EC <noGeode:							>
EC <	xchg	bx, dx						>
EC <	call	ECCheckMemHandle				>
EC <	xchg	bx, dx						>
EC <afterEC:							>

	; Otherwise, see if we need to nuke activation dialog
	;
	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
	jnc	afterDialog

	tst	cx			; Geode known?
	jz	tryAppLaunchBlock	; if not, try app launch block

	cmp	cx, ds:[bx].AD_geode	; matching geode?
	je	nukeIt

tryAppLaunchBlock:
	cmp	dx, ds:[bx].AD_appLaunchBlock	; correct block?
	jne	afterDialog

nukeIt:
	push	cx
	call	NukeActivationDialog		; Yup. Bring'er down.
	pop	cx

afterDialog:
	ret
GenFieldActivateDimiss	endp


Activation	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NewActivationDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get activation dialog up on screen, if not there, start
		"activating" sequence based on app name in AppLaunchBlock

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenField
		dx	- AppLaunchBlock
RETURN:
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/14/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


NewActivationDialog	proc far	uses	si
	.enter

	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
	LONG	jnc	newDialog

; oldDialog:
	push	dx, si	; save AppLaunchBlock, Field

	mov	di, bx				; ds:di = ActivationData
	mov	bx, ds:[bx].AD_dialog.handle	; Get dialog block for ensuing
						; messages ...
	; Update old structure w/new data
	;
	clr	ds:[di].AD_geode

	; See if already showing blank icon....
	;
	mov	cx, ds:[di].AD_savedBlankMoniker
	tst	cx
	jz	afterIconCleared

	; If not, CLEAR ICON HERE  -- first obliterate current icon in use,

	push	cx				; save saved blank moniker
	clr	ds:[di].AD_savedBlankMoniker	; clear stored reference

	mov	si, offset ActivatingGlyph

;	Nuke the old moniker...

	mov	dx, size ReplaceVisMonikerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	ss:[bp].RVMF_updateMode, VUM_MANUAL
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_dataType, VMDT_NULL
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx

	pop	cx				; get saved blank moniker

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

afterIconCleared:

	; Clear out old name text

if	0
	mov	si, offset ActivatingText	; ^lbx:si is text object
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_START_OF_LINE		; go to start
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_FORWARD_WORD		; move past "Activate "
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	cx, VTKF_FORWARD_CHAR		; & space after it...
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_DO_KEY_FUNCTION
	mov	cx, VTKF_SELECT_ADJUST_TO_END	; select to end of line
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_VIS_TEXT_DELETE_SELECTION	; Delete selection
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
else
	mov	si, offset ApplText		; ^lbx:si is ApplText Glyph
	sub	sp, size ReplaceVisMonikerFrame
	mov	bp, sp
	mov	ss:[bp].RVMF_updateMode, VUM_NOW
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_dataType, VMDT_NULL
	mov	dx, ReplaceVisMonikerFrame
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, size ReplaceVisMonikerFrame
endif

	pop	dx, si		; retrieve AppLaunchBlock, Field
	jmp	short setName


newDialog:
	; Create new dialog, new ActivationData temp data structure to hold
	; info about it.
	;
	push	si			; save GenField obj offset
	mov	bx, handle ActivatingUI
	mov	si, offset ActivatingBox
	push	ds:[LMBH_handle]
	call	UserCreateDialog
	mov_tr	di, bx			; keep handle of dialog block in di
	pop	bx
	call	MemDerefDS		; fixup DS
	pop	si			; *ds:si = GenField obj offset

	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	mov	cx, size ActivationData
	call	ObjVarAddData
	mov	ds:[bx].AD_dialog.handle, di
	mov	ax, offset ActivatingBox
	mov	ds:[bx].AD_dialog.chunk, ax

setName:
	; dx 		- AppLaunchBlock
	;
	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
EC <	ERROR_NC	UI_TEMP_GEN_FIELD_ACTIVATION_DIALOG_NOT_PRESENT	>

	mov	ds:[bx].AD_appLaunchBlock, dx

	mov	bx, ds:[bx].AD_dialog.handle

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	si, offset ActivatingBox
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	push	ds:[LMBH_handle]
	xchg	bx, dx
	call	MemLock
	mov	ds, ax

	mov	si, offset ALB_appRef.AIR_fileName
	mov	bp, si		; init to start
charloop:
	LocalGetChar	ax, dssi
	LocalIsNull	ax
	jz	found
	LocalCmpChar	ax, C_BACKSLASH
	jne	charloop
	mov	bp, si		; save ptr to data after backslash
	jmp	short charloop
found:
	xchg	bx, dx
	push	dx		; save handle of AppLaunchBlock
	mov	dx, ds		; dx:bp is text string

if	0
	clr	cx				; test is null terminated
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	si, offset ActivatingText	; ^lbx:si is text object
else
	mov	cx, dx
	mov	dx, bp		; cx:dx is text string
	mov	bp, VUM_NOW	; VisUpdateMode
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	si, offset ApplText
endif
	mov	di, mask MF_CALL
	call	ObjMessage

	pop	bx
	call	MemUnlock
	pop	bx
	call	MemDerefDS
	.leave
	call	DrawActivationDialog	; Force the expose to happen right now
	ret

NewActivationDialog	endp


;EllipsesText	char	"...", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			NukeActivationDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take activation dialog off screen & destroy it. (MUST EXIST)

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenField
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/14/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NukeActivationDialog	proc	far
	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
EC <	ERROR_NC	UI_TEMP_GEN_FIELD_ACTIVATION_DIALOG_NOT_PRESENT	>
	push	si
	mov	si, ds:[bx].AD_dialog.chunk
	mov	bx, ds:[bx].AD_dialog.handle
	push	ds:[LMBH_handle]
	call	UserDestroyDialog
	pop	bx
	call	MemDerefDS
	pop	si
	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarDeleteData
	ret

NukeActivationDialog	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateActivationDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the activation icon in the dialog

CALLED BY:	INTERNAL
PASS:		*ds:si	- GenField
		cx	- geode
RETURN:
DESTROYED:	ax, bx, cx, dx, di, bp, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/14/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateActivationDialog	proc	far	uses	si
	.enter

	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
EC <	ERROR_NC	UI_TEMP_GEN_FIELD_ACTIVATION_DIALOG_NOT_PRESENT	>
	mov	ds:[bx].AD_appLaunchBlock, 0	; no longer using this..
	mov	ds:[bx].AD_geode, cx		; we'll now refer to it by
						; geode, instead.

if	(0)
	push	ds:[bx].AD_dialog.handle	; save block of dialog

	call	UserGetDisplayType
	mov	dl, ah

	mov	ax, ss
	mov	es, ax
	sub	sp, size GeodeToken
	mov	di, sp			; get 6 byte buffer in es:di 
	mov	bx, cx
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo
	mov	ax, {word} es:[di].GT_chars+0
	mov	bx, {word} es:[di].GT_chars+2
	mov	si, es:[di].GT_manuf
	add	sp, size GeodeToken	; fix up stack

	pop	cx				; get block of dialog in cx
	clr	di
	call	TokenLoadMoniker		; di = chunk handle in block
	mov	bx, cx
	mov	si, offset ActivatingGlyph
	mov	ax, MSG_GEN_SET_MONIKER
endif

	mov	bx, ds:[bx].AD_dialog.handle

	push	cx	; save geode handle


	; Get old blank moniker, save away for later use.

	push	si
	mov	si, offset ActivatingGlyph
	mov	ax, MSG_GEN_GET_VIS_MONIKER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	push	bx
	push	ax			; blank moniker on stack for a moment
	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
EC <	ERROR_NC	UI_TEMP_GEN_FIELD_ACTIVATION_DIALOG_NOT_PRESENT	>
	pop	ds:[bx].AD_savedBlankMoniker	; then saved away.
	pop	bx

	mov	si, offset ActivatingGlyph

	; Then, switch to using no moniker, so the blank one is left intact
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	clr	cx
	mov	dl, VUM_MANUAL
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx			; get geode handle again

	; Then, copy in a real moniker from the token database
	;
	mov	ax, ss
	mov	es, ax
	sub	sp, size GeodeToken
	mov	di, sp			; get token buffer in es:di 
	xchg	bx, cx			; get geode in bx
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo
	xchg	bx, cx			; get dialog handle back in bx

	mov	dx, size ReplaceVisMonikerFrame
	sub	sp, dx
	mov	bp, sp
	mov	ax, es
	mov	ss:[bp].RVMF_source.segment, ax
	mov	ss:[bp].RVMF_source.offset, di
	mov	ss:[bp].RVMF_sourceType, VMST_FPTR
	mov	ss:[bp].RVMF_dataType, VMDT_TOKEN
	mov	ss:[bp].RVMF_updateMode, VUM_NOW
	mov	si, offset ActivatingGlyph
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size ReplaceVisMonikerFrame

	add	sp, size GeodeToken
	.leave

	call	DrawActivationDialog	; Force the expose to happen right now
	ret
UpdateActivationDialog	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawActivationDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force immediate visual update of the "Activating" dialog

CALLED BY:	INTERNAL
PASS:
RETURN:
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	4/14/93		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawActivationDialog	proc	far
	mov	ax, TEMP_GEN_FIELD_ACTIVATION_DIALOG
	call	ObjVarFindData
	jnc	done
	push	si
	mov	si, ds:[bx].AD_dialog.chunk
	mov	bx, ds:[bx].AD_dialog.handle

	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_META_EXPOSED
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	si
done:
	ret
DrawActivationDialog	endp

Activation	ends


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldNotifyNoFocusWithinNode

DESCRIPTION:	Notification that no app within field could be found to give the
		focus to.

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	if lower-to-bottom behavior should really be defined by spui, just
	move that portion to a OLFieldClass MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
	handler and have this handler send message on to spui

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/92		Initial version
	brianc	10/22/92	Moved from spui to gen to allow use of
				common code and access to shutdown flag

------------------------------------------------------------------------------@


GenFieldNotifyNoFocusWithinNode	method	GenFieldClass,
				MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE
	; If there's an app currently being attached, then don't give up
	; on this field just yet.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GFI_numAttachingApps
	LONG jnz	done

	; Look through the array of apps we know about to see if any of them
	; is focussable. First one found wins. We need to do this if an app
	; exits during startup before any other app can open a window.
	; 
	mov	di, ds:[di].GFI_genApplications
	tst	di
	jz	noFocusableAppWithoutAWindow

	ChunkSizeHandle	ds, di, cx
	shr	cx
	shr	cx
	jz	noFocusableAppWithoutAWindow
	
	mov	di, ds:[di]
findFocusableAppLoop:
	mov	bx, ds:[di].handle
	call	MemOwner
	call	WinGeodeGetFlags
	test	ax, mask GWF_FOCUSABLE or mask GWF_TARGETABLE
	jnz	done			; don't try and give it the focus or
					;  target, as it's likely not ready
					;  for it. Just assume it will open a
					;  window eventually which will grab
					;  the focus or target

	add	di, size optr
	loop	findFocusableAppLoop

noFocusableAppWithoutAWindow:

	; There's no focusable app.  If we're in UILM_TRANSPARENT mode,
	; we'd like to get the default launcher back on screen, rather than
	; detaching, or just hanging out without an app.
	;
	push	es
	segmov	es, dgroup, ax		; SH
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	pop	es
	jne	notTransparent

	mov	di, ds:[si]
	add	di, ds:[di].GenField_offset
	test	ds:[di].GFI_flags, 
			mask GFF_LOAD_DEFAULT_LAUNCHER_WHEN_NEXT_PROCESS_EXITS
	jnz	done

	clr	cx			; report errors
	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	GOTO	ObjCallInstanceNoLock

notTransparent:

	; If we were waiting for this field's apps to exit because it is in
	; 'quitOnClose' mode and the user requested "Exit to DOS", shutdown
	; now.  Use forced clean as we already queried the shutdown control
	; list.  Stuff adding themselves to the list in the meantime are
	; hosed.
	;
	mov	ax, TEMP_GEN_FIELD_EXIT_TO_DOS_PENDING
	call	ObjVarFindData
	jnc	notExiting			; weren't waiting for apps
						; else, shutdown
	mov	ax, SST_CLEAN_FORCED
	call	SysShutdown

	mov	bp, -1				; indicate shutdown
	mov	ax, MSG_META_FIELD_NOTIFY_NO_FOCUS
	call	NotifyWithBP
	jmp	short done

notExiting:
	; Notify output about lack of focus node after setting bit telling
	; ourselves we must load the default launcher. We only set the
	; need-launcher bit if we didn't end up without a focus owing to the
	; natural course of detaching...

	mov	di, ds:[si]
	add	di, ds:[di].GenField_offset
	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jnz	notifyOutput

	ornf	ds:[di].GFI_flags, mask GFF_NEED_DEFAULT_LAUNCHER

notifyOutput:
	mov	ax, MSG_META_FIELD_NOTIFY_NO_FOCUS
	call	NotifyWithShutdownFlag
	jnc	done				; notification sent

	;
	; No one to notify, toss it to the bottom of the heap, presuming that
	; it's no longer useful.  The system will try to find a new field to
	; give the focus, & failing that, will shut down the system.
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_FORCE_QUEUE		; stick in queue to allow
						;	any dialogs to finish
	call	ObjMessage
done:
	ret

GenFieldNotifyNoFocusWithinNode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyWithShutdownFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set shutdown flag and notify output

CALLED BY:	INTERNAL
PASS:		*ds:si - GenField
		es - segment of GenFieldClass (not dgroup)
		ax - notification message
RETURN:		carry clear if notification sent
		carry set if no notification destination
DESTROYED:	bx, cx, dx, bp, di, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyWithShutdownFlag	proc	far
	class	GenFieldClass

	push	es
	segmov	es, dgroup, bp		; SH
	mov	bp, -1			; non-zero if UIF_DETACHING_SYSTEM
	test	es:[uiFlags], mask UIF_DETACHING_SYSTEM
	pop	es
	jnz	haveShutdownFlag
	clr	bp			; else, not shutting down
haveShutdownFlag:
	FALL_THRU	NotifyWithBP

NotifyWithShutdownFlag	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyWithBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify output with BP

CALLED BY:	INTERNAL
PASS:		*ds:si - GenField
		es - segment of GenFieldClass (not dgroup)
		ax - notification message
		bp - data to send
RETURN:		carry clear if notification sent
		carry set if no notification destination
DESTROYED:	bx, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/22/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyWithBP	proc	far
	class	GenFieldClass

	mov	cx, ds:[LMBH_handle]		; ^lcx:dx = this field
	mov	dx, si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GFI_notificationDestination.handle
	tst	bx			; (clears carry)
	jz	done			; no notification destination
	mov	si, ds:[di].GFI_notificationDestination.chunk
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	si, dx			; *ds:si <- field, again (dx
					;  preserved b/c not MF_CALL)
	stc				; indicate notification sent
done:
	cmc				; reverse for consistency
	ret
NotifyWithBP	endp

Common ends

;-----------------------

Exit segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldExitToDos -- MSG_GEN_FIELD_EXIT_TO_DOS for GenFieldClass

DESCRIPTION:	Verifies that user wishes to exit to dos, then does so.

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_EXIT_TO_DOS

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/14/92	Initial version

------------------------------------------------------------------------------@

GenFieldExitToDOS	method	dynamic	GenFieldClass, MSG_GEN_FIELD_EXIT_TO_DOS
	;
	; let's first call the superclass to check if the specific UI wants
	; to handle EXIT_TO_DOS specially.
	;
	mov	di, offset GenFieldClass
	call	ObjCallSuperNoLock
	LONG jc	exit
	
	;
	; check if user is allowed to exit to DOS
	;
	call	GenFieldCheckIfExitPermitted
	LONG	jnc	exit

	;
	; allow .ini file override of normal verification dialog
	;
	push	ds, si
	mov	cx, cs				; cx:dx = key
	mov	dx, offset confirmShutdownKey
	mov	ds, cx				; ds:si = category
	mov	si, offset confirmShutdownCategory
	call	InitFileReadBoolean
	jc	checkConfirm			; not found, show confirm
	tst	ax				; AX=0 means no confirm
						; (clears carry)
	jz	checkConfirm
	stc					; else, indicate confirm
checkConfirm:
	; carry set to confirm, carry clear to skip confirm
	pop	ds, si
	jc	showConfirm
	;
	; no confirm, begin exiting
	;
	mov	ax, MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
	mov	cx, IC_YES
	GOTO	ObjCallInstanceNoLock

showConfirm:
	;
	; show verification dialog
	;
	;
	; get product name for .ini file
	;
	push	ds, si
	mov	cx, cs				; cx:dx = key
	mov	dx, offset productNameKey
	mov	ds, cx				; ds:si = category
	mov	si, offset productNameCategory
						; return buffer
	mov	bp, IFCC_INTACT shl offset IFRF_CHAR_CONVERT or \
					0 shl offset IFRF_SIZE
	call	InitFileReadString		; carry clear if found
	pop	ds, si
	jnc	haveProductName
	clr	bx				; else, no buffer
haveProductName:
	push	bx				; save product name buffer
	mov	cx, bx				; cx = product name buffer
	;
	; fill in dialog params and put it up
	;
	mov	dx, ds:[LMBH_handle]		; dx = GenField handle
	mov	bx, handle Strings
	call	MemLock
	mov	ds, ax
	sub	sp, size GenAppDoDialogParams
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customString.segment, ax
	mov	ax, ds:[shutdownConfirmMessage] ; ax = string offset
	mov	ss:[bp].GADDP_dialog.SDP_customString.offset, ax
						; assume no product name,
						;	no space padding
	mov	ax, ds:[nullString]
	movdw	ss:[bp].GADDP_dialog.SDP_stringArg2, dsax
	movdw	ss:[bp].GADDP_dialog.SDP_stringArg1, dsax
	jcxz	useNullProductName		; no product name buffer
	mov	bx, cx				; else, use product name...
	call	MemLock
	mov	ss:[bp].GADDP_dialog.SDP_stringArg2.segment, ax
	mov	ss:[bp].GADDP_dialog.SDP_stringArg2.offset, 0
						; ...and space padding
	mov	ax, ds:[spaceString]
	mov	ss:[bp].GADDP_dialog.SDP_stringArg1.offset, ax
useNullProductName:
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, \
			mask CDBF_SYSTEM_MODAL or \
			CDT_QUESTION shl offset CDBF_DIALOG_TYPE or \
			GIT_AFFIRMATION shl offset CDBF_INTERACTION_TYPE
	mov	ss:[bp].GADDP_finishOD.handle, dx
	mov	ss:[bp].GADDP_finishOD.chunk, si
	mov	ss:[bp].GADDP_message,
				MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	dx, size GenAppDoDialogParams
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	GenCallApplication
	add	sp, size GenAppDoDialogParams
						; ax = IC_YES, IC_NO, IC_NULL
	pop	bx				; product name buffer
	tst	bx
	jz	noProductName
	call	MemFree				; else, free it
noProductName:
	mov	bx, handle Strings		; unlock string buffer
	call	MemUnlock

	;
	; don't do any more here as we're waiting for the user to respond
	; to the "are your sure you want to exit?" dialog.  Stuff should be
	; done in the GenFieldExitToDosConfirmationResponse handler.
	;
exit:
	ret
GenFieldExitToDOS	endm

confirmShutdownKey	char	"confirmShutdown",0
confirmShutdownCategory	label	char
productNameCategory	char	"ui",0
productNameKey		char	"productName",0


COMMENT @-------------------------------------------------------------------
			GenFieldCheckIfExitPermitted
----------------------------------------------------------------------------

DESCRIPTION:	Checks if the system is able/allowed to 
		safely exit to DOS.

CALLED BY:	INTERNAL - GenFieldExitToDOS

PASS:		*ds:si	= GenFieldClass object

RETURN:		CF	= set if exit to DOS allowed
			  clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	7/22/93		Initial version

---------------------------------------------------------------------------@
GenFieldCheckIfExitPermitted	proc	near
		uses	ax, bx, dx, bp, ds, es
		.enter
	;
	; Does the system have a keyboard?
	;   This is important for hand-held 
	;   computers with detachable keyboards.
	;
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver
		tst	ax
		jz	haveKeyboard		; assume keyboard exists
		push	ds, si
		mov_tr	bx, ax
		call	GeodeInfoDriver		; ds:si = DriverInfoStruct
		mov	di, DR_POWER_DEVICE_ON_OFF
		mov	ax, PDT_KEYBOARD
		call	ds:[si].DIS_strategy
		pop	ds, si
		jnc	haveKeyboard

	;
	; If not, inform the user they can't exit
	;
		mov	bx, handle Strings
		call	MemLock
		mov	es, ax

		sub	sp, size GenAppDoDialogParams
		mov	bp, sp

		mov	ax, CustomDialogBoxFlags <1, CDT_NOTIFICATION, 
						  GIT_NOTIFICATION, 0>
    		mov	ss:[bp].GADDP_dialog.SDP_customFlags, ax

		mov	bx, offset noKeyboardMessage
		mov	ax, es:[bx] 		; ax = string offset
	    	movdw	ss:[bp].GADDP_dialog.SDP_customString, esax

		clr	ax
    		movdw	ss:[bp].GADDP_dialog.SDP_stringArg1, axax
	   	movdw	ss:[bp].GADDP_dialog.SDP_stringArg2, axax
    		movdw	ss:[bp].GADDP_dialog.SDP_customTriggers, axax
    		movdw	ss:[bp].GADDP_dialog.SDP_helpContext, axax

		mov	ax, ds:[LMBH_handle]		; ax = GenField handle
		movdw	ss:[bp].GADDP_finishOD, axsi
		mov	ss:[bp].GADDP_message, MSG_META_DUMMY

		mov	dx, size GenAppDoDialogParams
		mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
		call	GenCallApplication
		add	sp, size GenAppDoDialogParams

		mov	bx, handle Strings		; unlock string buffer
		call	MemUnlock

	;
	; Make sure the carry flag is set correctly!
	;
		clc
exit:
		.leave
		ret

haveKeyboard:
		stc
		jmp	exit

GenFieldCheckIfExitPermitted	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldExitToDosConfirmationResponse --
		MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE for
		GenFieldClass

DESCRIPTION:	If user wishes to exit to dos, then does so.

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE

	cx - InteractionCommand

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/14/92	Initial version

------------------------------------------------------------------------------@

GenFieldExitToDosConfirmationResponse	method	dynamic	GenFieldClass,
				MSG_GEN_FIELD_EXIT_TO_DOS_CONFIRMATION_RESPONSE
	cmp	cx, IC_YES			; yes?
	jne	exit				; no, don't exit
	;
	; If this field is in 'quitOnClose' mode, make sure we quit all apps
	; before exiting.
	;
	mov	ax, MSG_GEN_FIELD_ABOUT_TO_CLOSE
	call	ObjCallInstanceNoLock
	jnc	exitNow
	;
	; indicate that we'll be waiting for all apps to quit (don't save to
	; state).  We check this in MSG_META_NOTIFY_NO_FOCUS_WITHIN_NODE.
	;
	mov	ax, TEMP_GEN_FIELD_EXIT_TO_DOS_PENDING
	clr	cx
	call	ObjVarAddData
	jmp	short exit			; 'quitOnClose', wait till all
						;	apps exit

exitNow:
	;
	; user confirmed exit, do so now
	;
	mov	ax, SST_CLEAN
	clr	cx				; notify UI when all done
	call	SysShutdown
exit:
	ret
GenFieldExitToDosConfirmationResponse	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldDetach -- MSG_META_DETACH for GenFieldClass

DESCRIPTION:	Detaches the field completely.
		Ensures that field is not active, shuts down all
		applications, removes field from tree,
		to make safe for shutdown

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_META_DETACH

	cx - caller's ID (value to be returned in MSG_META_DETACH_COMPLETE to
			 this object, & in MSG_META_ACK to caller)
	dx:bp	- OD to send MSG_META_ACK to when all done.

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenFieldDetach	method	GenFieldClass, MSG_META_DETACH
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>
EC <	call	ECCheckOD						>
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>

	;
	; make sure we clear this before quitting
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].GFI_flags, \
			not (mask GFF_RESTORING_APPS or mask GFF_QUIT_ON_CLOSE)

	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jne	AlreadyDetached

; See if in generic tree (THIS MAY NOT BE NEEDED)

	cmp	ds:[di].GI_link.LP_next.handle, 0
	jne	90$
AlreadyDetached:
				; If already detached, just send ACK, to
				; prevent any oddities from happening
	mov	bx, dx
	mov	si, bp
	mov	ax, MSG_META_ACK
	clr	di
	GOTO	ObjMessage
90$:

	;
	; if detaching system, put up exiting status box
	;
	push	es
	segmov	es, dgroup, di
	test	es:[uiFlags], mask UIF_DETACHING_SYSTEM
	pop	es
	jz	notSysDetach
	push	si, cx, dx, bp
	mov	bx, handle UIApp
	mov	si, offset UIApp
	mov	cx, handle ShutdownStatusBox
	mov	dx, offset ShutdownStatusBox
	mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle ShutdownStatusBox
	mov	si, offset ShutdownStatusBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si, cx, dx, bp
notSysDetach:

	mov	ax, MSG_META_DETACH		; detach message

	; Set flag indicating we're detaching.
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	or	ds:[di].GFI_flags, mask GFF_DETACHING
	andnf	ds:[di].GFI_flags, not mask GFF_LOAD_DEFAULT_LAUNCHER_WHEN_NEXT_PROCESS_EXITS
	call	ObjInitDetach
	
	FALL_THRU	HandleFieldDetachLow
GenFieldDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleFieldDetachLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles the detach method correctly (checks for attaching apps,
		etc).

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to GenField object
		cx - caller's ID (value to be returned in
			MSG_META_DETACH_COMPLETE to this object, & in
			MSG_META_ACK to caller)
		dx:bp	- OD to send MSG_META_ACK to when all done.
		ax - message provoking call MSG_META_DETACH
RETURN:		nothing
ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/ 5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleFieldDetachLow	proc	far
	class	GenFieldClass
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GFI_numAttachingApps	;If waiting for apps to come 
	jnz	exit				; up, branch; we'll shutdown
						; once the final attaching
						; app is done attaching.	

	; let our superclass have a crack at it first, so spui can do what
	; it does best.

	mov	di, offset GenFieldClass
	call	ObjCallSuperNoLock

	call	ShutdownField			;Just shutdown the field
exit:
	ret
HandleFieldDetachLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldDetachAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Aborts the current detach.

CALLED BY:	GLOBAL
PASS:		*ds:si - this object
		ds:di - gen field instance data
		es - segment of GenFieldClass
RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldDetachAbort	method	GenFieldClass, MSG_META_DETACH_ABORT
	andnf	ds:[di].GFI_flags, not mask GFF_DETACHING
	mov	di, offset GenFieldClass	;ES:DI <- ptr to this object
	GOTO	ObjCallSuperNoLock
GenFieldDetachAbort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShutdownField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does miscellaneous shutdown for the field

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShutdownField	proc	near
	class	GenFieldClass
EC <	call	ECCheckObject						>
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GFI_processes

;	IF THERE ARE PROCESSES AROUND, THEN WE WANT TO WAIT UNTIL THEY HAVE
;	ALL EXITED BEFORE WE FINISH DETACHING. DO AN ObjIncDetach() HERE, AND
;	DO ObjAckDetach() in GenFieldProcessExit() AFTER ALL PROCESSES HAVE
;	EXITED.

	tst	bx
	jz	10$
	ChunkSizeHandle ds, bx, cx
	jcxz	10$
	call	ObjIncDetach
10$:

	mov	cx, ds:[LMBH_handle]		;First, release field exclusive
	mov	dx, si
	mov	bp, mask MAEF_FOCUS or mask MAEF_TARGET or mask MAEF_MODEL
	mov	ax, MSG_META_MUP_ALTER_FTVMC_EXCL
	call	UserCallSystem

	;
	; disable help windows
	;
	push	si
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	bx, handle SysHelpObject
	mov	si, offset SysHelpObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	bx, handle SysModalHelpObject
	mov	si, offset SysModalHelpObject
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_FIELD_SHUTDOWN_APPS
	call	ObjCallInstanceNoLock		;Shutdown the apps
	ret
ShutdownField	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldDetachComplete

DESCRIPTION:	Handler for notification that all children have completed
		detaching.  This is subclassed from the default MetaClass
		behavior which sends a MSG_META_ACK to the caller passed
		in ObjInitDetach.

PASS:
	*ds:si - instance data (for object in GenField class)
	es - segment of GenFieldClass

	ax - MSG_META_DETACH_COMPLETE

	cx - caller's ID (value to be returned in MSG_META_DETACH_COMPLETE to
			 this object, & in MSG_META_ACK to caller)
	dx:bp	- OD to send MSG_META_ACK to when all done.


RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenFieldDetachComplete	method	GenFieldClass, MSG_META_DETACH_COMPLETE
	push	ax
	push	cx
	push	dx
	push	bp

EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>
EC <	call	ECCheckOD						>
EC <	xchg	bx, dx							>
EC <	xchg	si, bp							>


				; See if detaching or not
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jz	AfterDetaching	; if not, SKIP detach stuff.

	; let spui do some stuff

	mov	ax, MSG_GEN_FIELD_ABOUT_TO_DETACH_COMPLETE
	mov	di, offset GenFieldClass
	call	ObjCallSuperNoLock

				; First, make field object NOT USABLE
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	ObjCallInstanceNoLock

				; & remove from generic tree.
					; Get Field object in cx:dx
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	ax, MSG_GEN_REMOVE_CHILD
	clr	bp
	call	GenCallParent

				; Clean up instance data so we're OK
				; for detaching.
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GFI_visParent.handle, 0
	mov	ds:[di].GFI_visParent.chunk, 0
	andnf	ds:[di].GFI_flags, not mask GFF_DETACHING

AfterDetaching:
				; Then, call superclass to pass on 
				; acknowledge to the caller of the
				; MSG_META_DETACH
	pop	bp
	pop	dx
	pop	cx
	pop	ax
	mov	di, offset UserClassStructures:GenFieldClass
	call	ObjCallSuperNoLock

	;
	; finally, notify notification optr
	;
	mov	ax, MSG_META_FIELD_NOTIFY_DETACH
	call	NotifyWithShutdownFlag		; don't care if not sent
	ret

GenFieldDetachComplete	endm



COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldShutdownApps

DESCRIPTION:	Shutdown all applications running in field

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_SHUTDOWN_APPS

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenFieldShutdownApps	method	dynamic GenFieldClass,
					MSG_GEN_FIELD_SHUTDOWN_APPS

	; Re-order list of applications to be in order of the app's windows
	; on-screen
	;
	mov	ax, MSG_GEN_FIELD_ORDER_GEN_APPLICATION_LIST
	call	ObjCallInstanceNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
;
; do not clear number of apps here as in Wizard guided mode (quitOnClose)
; WShell has done a MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE_HOLDER and
; detached itself to get itself saved to state.  If we were to clear the
; number of apps, we'd lose the WShell entry.  (Clearing is bad anyways,
; as the GFI_app chunk array isn't cleared).  Associated fix is to ensure
; that MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE_HOLDER can handle adding
; a reference for the same app twice. - brianc 4/1/93
;
;	clr	ds:[di].GFI_numDetachedApps	; clr # of detached apps
	;
	; add ApplicationInstanceReference block for each GenApp
	;
	mov	di, ds:[di].GFI_genApplications
	tst	di				; any apps?
	jz	done				; nope
	mov	bx, di				; bx = list chunk
	mov	di, ds:[di]			; ds:di = list
	inc	di
	jz	done				; no apps
	dec	di
	jz	done				; no apps
	ChunkSizePtr	ds, di, cx		; cx = size of list
	shr	cx
	shr	cx				; cx = number of genApps
	push	cx				; save it
	mov	di, bx				; di = list chunk
	clr	bx				; bx = list offset
addRefLoop:
	push	cx
	push	di				; save list chunk
	mov	di, ds:[di]			; deref. list
	mov	bp, ds:[di][bx]+2		; bp = handle of GenApp
	mov	ax, MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE_HOLDER
	call	ObjCallInstanceNoLock
	pop	di				; restore list chunk
	add	bx, size optr			; bump list offset
	pop	cx
	loop	addRefLoop
	pop	cx				; retrieve # apps
	;
	; then, detach all applications
	;	*ds:si = GenField
	;	cx = number of GenApps
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GFI_genApplications
	mov	di, ds:[di]		; ds:di = GenApp list
detachLoop:
	call	ObjIncDetach		; One more acknowledge that we need to
					; receive.
	push	cx
	clr	cx			; No ID being used
	mov	dx, ds:[LMBH_handle]	; Send MSG_META_ACK for apps back to
	mov	bp, si			; their parent (GenField)
	push	si			; save GenField chunk
					; Send MSG_META_DETACH to app objects
	mov	bx, ds:[di]+2		; GenApp handle
if	(0)		; New idea - doug 6/2/92
	mov	si, ds:[di]+0		; GenApp chunk
else
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo		; Get thread that runs that app object
	mov	bx, ax
	call	MemOwner		; Get owning process - that's what we
	clr	si			; actually want to DETACH.
endif
	push	di			; save GenApp list offset
	mov	ax, MSG_META_DETACH
					; force-queue -> doesn't move lmem block
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	di			; retrieve GenApp list offset
	add	di, size optr
	pop	si			; *ds:si = GenField
	pop	cx
	loop	detachLoop

done:
	call	ObjEnableDetach		; Allow detaching any time...
	ret

GenFieldShutdownApps	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldAddAppInstanceReferenceHolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an entry for the passed application that will be filled
		in after the state file gets created.

CALLED BY:	GLOBAL
PASS:		bp - handle of associated app object
RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldAddAppInstanceReferenceHolder	method	GenFieldClass,
			MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE_HOLDER
	call	ObjMarkDirty	; Make sure this object is marked as dirty

	; Init chunk for application list

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	tst	ds:[di].GFI_apps	; if we already have one, done
	jnz	HaveAppChunk

	mov	al, mask OCF_DIRTY
	clr	bx			; variable-sized elements
	clr	cx			; no extra space in header
	push	si
	clr	si			; alloc new handle
	call	ChunkArrayCreate 	; create a new chunk
					; & store it away.
	mov_tr	ax, si
	pop	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].GFI_apps, ax
HaveAppChunk:
	
	;
	; first, check if we already have one for this app
	;	*ds:si = GenField
	;	bp = app handle
	;
	push	si
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	si, ds:[di].GFI_apps
	mov	bx, cs
	mov	di, offset AppAppInstanceReferenceHolderCB
	call	ChunkArrayEnum
	pop	si
	jc	done				;already there

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	inc	ds:[di].GFI_numDetachedApps	;inc # apps listed in chunk

if DBCS_PCGEOS
	;
	; If the field is exited when exiting all apps, there is a situation
	; where an AppInstanceReference will be allocated and stored in the
	; field but which never gets filled in because the app has been exited.
	; In this case, when the field restores from state, it finds an empty
	; AppInstanceReference.  In DBCS, the empty AppInstanceRefernce
	; includes one zero byte for AIR_savedDiskData.  This is fine for
	; SBCS since it'll be recognized as not being a FSSavedStdPath.  For
	; DBCS, FSSSP_signature is a word, so a random byte after the AIR
	; is checked.  If non-zero, the AIR_savedDiskData will be interpreted
	; as a FSSavedStdPath and bad things will happen.  To avoid this, we'll
	; just allocate an extra zero byte here. - brianc 12/8/93
	;
	mov	ax, size AppInstanceReference+1	; make it the minimum size...
else
	mov	ax, size AppInstanceReference	; make it the minimum size...
endif
	mov	si, ds:[di].GFI_apps
	call	ChunkArrayAppend

	;
	;	DS:DI <- ptr to new slot for AppInstanceReference
	;
	mov	ds:[di].AIR_diskHandle, bp	;Save handle of app
	mov	ds:[di].AIR_stateFile[0], 0	;Init to having no state file,
						; so if the application doesn't
						; give us a state file (e.g. it
						; couldn't create one), we 
						; don't try to restart it.
done:
	ret
GenFieldAddAppInstanceReferenceHolder	endp

;
; pass:
;	*ds:si = chunk array
;	ds:di = AppInstanceReference
;	bp = app handle
; return:
;	carry clear to continue
;	carry set to stop
;
AppAppInstanceReferenceHolderCB	proc	far
	cmp	bp, ds:[di].AIR_diskHandle
	stc					; assume found, stop
	je	done
	clc					; otherwise, continue
done:
	ret
AppAppInstanceReferenceHolderCB	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldAddAppRef

DESCRIPTION:	Add another application reference

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE

	dx - block handle holding structure AppInstanceReference
	bp - handle of application whose AIR we are adding

RETURN: nothing
	Block freed

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	ax, bx, cx, dx, si 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenFieldAddAppRef	method	dynamic GenFieldClass, MSG_GEN_FIELD_ADD_APP_INSTANCE_REFERENCE
	mov	si, ds:[di].GFI_apps	; *ds:si <- AIR array

	tst	si			; make sure the thing exists...
EC <					;Must already have chunk here	>
EC <	ERROR_Z	GEN_FIELD_DOESNT_HAVE_APP_REF_CHUNK			>
NEC <	jz	exit							>

	mov	bx, cs
	mov	di, offset GFAAR_callback
	clr	cx			; first element is # 0
	call	ChunkArrayEnum
EC <	ERROR_NC	CANNOT_FIND_APP_IN_LIST				>
NEC <	jnc	exit							>

	tst	dx
	jz	deleteRef

	mov	bx, dx
	mov	ax, MGIT_SIZE
	call	MemGetInfo		; ax <- size of AppInstanceRef + disk
					;  data

	xchg	ax, cx			; ax <- element #, cx <- new size
	call	ChunkArrayElementResize
	call	ChunkArrayElementToPtr	; ds:di <- element
	segmov	es, ds			; es:di <- element
	call	MemLock
	mov	ds, ax
	clr	si
EC <	tst	ds:[si].AIR_diskHandle					>
EC <	ERROR_Z	NO_DISK_HANDLE_IN_APP_INSTANCE_REFERENCE		>

	rep	movsb
NEC <exit:								>
NEC <	mov	bx, dx			; in case jumped here from above>
NEC <					;  error conditions		>
	call	MemFree		; free up the passed AppInstanceReference block
done:
	ret

deleteRef:
	;
	; If handle is 0, it means the app was a server and shouldn't be
	; restored from state, so we delete its AppInstanceReference entry
	; from the array.
	; 
	mov	ax, cx
	call	ChunkArrayElementToPtr	; ds:di <- element to nuke
	call	ChunkArrayDelete	; nukez le.
	jmp	done
GenFieldAddAppRef	endm

GFAAR_callback	proc	far
	cmp	ds:[di].AIR_diskHandle, bp	; geode handle matches saved?
	stc				; assume yes => element found
	je	done			; yes
	inc	cx			; no -- up returned element number since
					;  current item isn't the one we're
					;  after
	clc
done:
	ret
GFAAR_callback	endp

Exit ends

;----------------------

Init segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldRestoreApps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine starts restoring all the apps, by setting up
		the pass params for MSG_GEN_FIELD_RESTORE_NEXT_APP so it
		will restore the first application.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
		es - dgroup
RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	ax, bx, cx, dx, si 
 
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldRestoreApps	method	dynamic GenFieldClass,
					MSG_GEN_FIELD_RESTORE_APPS

;	IF DETACHING, EXIT

	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jne	exit
	push	es
	segmov	es, dgroup, bx
	test	es:[uiFlags], mask UIF_DETACHING_SYSTEM
	pop	es
	jnz	exit

;	IF ALREADY RESTORING APPLICATIONS, EXIT

	test	ds:[di].GFI_flags, mask GFF_RESTORING_APPS
	jne	exit

;	IF NO APPS TO RESTORE AND NO APPS RUNNING, START DEFAULT_LAUNCHER

	tst	ds:[di].GFI_numDetachedApps	;If apps to restore, do it
	jnz	restoreApps

	mov	bx, ds:[di].GFI_genApplications
	tst	bx				; any apps?
	jz	noApps				; nope
	mov	bx, ds:[bx]			; ds:bx = list
	inc	bx
	jz	noApps				; no apps
	dec	bx
	jz	noApps				; no apps
	ChunkSizePtr	ds, bx, ax		; ax = size of list
	tst	ax
	jnz	exit				; apps are running, just exit
noApps:

	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	mov	cx, 0				;handle error
	mov	bx, ds:[LMBH_handle]
	;
	; do this via the queue as this can cause ft changes which we want to
	; avoid here because we may be initially called because of an ft change
	; (OLFieldGainedFocusExcl, OLFieldGainedTargetExcl)
	;
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	short exit

restoreApps:
	ornf	ds:[di].GFI_flags, mask GFF_RESTORING_APPS
	clr	ds:[di].GFI_numRestartedApps

	mov	ax, TEMP_GEN_FIELD_OPEN_APP_ON_TOP
	clr	cx
	call	ObjVarAddData
						; cx = 0
	mov	ax, MSG_GEN_FIELD_RESTORE_NEXT_APP
	call	ObjCallInstanceNoLock
exit:
	ret
GenFieldRestoreApps	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldRestoreNextApp

DESCRIPTION:	Restore applications running in field

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_RESTORE_NEXT_APP

	cx - # of app being restarted

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

GenFieldDiskRestoreArgs	struct
    GFDRA_appArray	word		; chunk handle of chunkarray holding
					;  AppInstanceReference structs
    GFDRA_elementNum	word		; # of app being restored.
GenFieldDiskRestoreArgs	ends

GenFieldRestoreNextApp	method	dynamic GenFieldClass,
					MSG_GEN_FIELD_RESTORE_NEXT_APP

;	IF DETACHING, EXIT

	test	ds:[di].GFI_flags, mask GFF_DETACHING
	LONG jne	NoApps
	push	es
	segmov	es, dgroup, bx
	test	es:[uiFlags], mask UIF_DETACHING_SYSTEM
	pop	es
	LONG jnz	NoApps

	tst	ds:[di].GFI_numDetachedApps	;If no apps, just exit
	LONG jz	NoApps
	cmp	cl, ds:[di].GFI_numDetachedApps
	jae NoMoreAppsJMP
	inc	ds:[di].GFI_numRestartedApps
	push	cx			; save app #
	push	si			; save chunk handle of field on stack

	mov	si, ds:[di].GFI_apps	; fetch chunk

	clr	ax
	call	ChunkArrayElementToPtr	; ds:di <- AppInstanceRef
	jnc	haveAIR
	;
	; no more apps in AIR array
	;
	pop	si			; restore GenField chunk
	pop	cx			; restore app #
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = gen instance
					; undo 'inc' above
	dec	ds:[di].GFI_numRestartedApps
NoMoreAppsJMP:
	jmp	NoMoreApps
	
haveAIR:
	push	ax, si			; save array handle & element #
	mov	bx, sp			; pass ss:bx pointing to element #
					;  and array handle
	lea	si, ds:[di].AIR_savedDiskData
	mov	cx, SEGMENT_CS
	mov	dx, offset RestoreAppDiskRestoreCallback
	call	DiskRestore
	pop	bx, si
	jc	diskRestoreFailed
	
	xchg	ax, bx			; ax <- elt #, bx <- disk handle
	call	ChunkArrayElementToPtr
	mov	ds:[di].AIR_diskHandle, bx
	mov	si, di 			; ds:si = AppReferenceInstance to
					; restore
	pop	bp			; pass chunk handle of GenField in bp


	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or \
			mask HF_SHARABLE or ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc	;
	mov	es, ax		; es:di = AppInstanceReference section
	mov	di, offset ALB_appRef
				; Copy over AppRef to use
	mov	cx, size AppInstanceReference
	push	si		; save AIR for deletion
	rep	movsb		; Copy into block
	pop	di		; ds:di <- AppInstanceRef again

	; delete the element from the GFI_apps chunkarray, now we've used it

	mov	si, ds:[bp]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].GFI_apps
	call	ChunkArrayDelete

	; fill in the rest of the AppLaunchBlock fields.

				; Store this GenField as vis parent to use
	mov	ax, ds:[LMBH_handle]
	mov	es:[ALB_genParent].handle, ax
	mov	es:[ALB_genParent].chunk, bp
	mov	es:[ALB_userLoadAckAD].AD_OD.handle, ax
	mov	es:[ALB_userLoadAckAD].AD_OD.chunk, bp
	mov	es:[ALB_userLoadAckAD].AD_message, MSG_GEN_FIELD_RESTORE_APP_ACK
EC <	mov	es:[ALB_userLoadAckID],1234				>
	call	MemUnlock	;
	mov	dx, bx		; Put block handle in dx
	mov	si, bp		;Restore chunk handle of GenField object
	pop	cx		; cx <- app #
	mov	ax, MSG_GEN_FIELD_RESTORE_APP
	GOTO	ObjCallInstanceNoLock

diskRestoreFailed:
	;
	; alert the user to the error if it's not something s/he caused
	; 
	call	GenPathDiskRestoreError
	;
	; If couldn't restore app's disk handle, we can't run the thing, so
	; just nuke it from the array and restore the next app.
	; 
	pop	bp
	pop	cx		; recover app #, but don't upp it, as we've
				;  not actually restored this one...whatever
				;  app we are able to restore first we want
				;  to come up on top...

	mov	si, ds:[bp]
	add	si, ds:[si].Gen_offset
	mov	si, ds:[si].GFI_apps
	call	ChunkArrayDelete
	mov	si, bp
	mov	ax, MSG_GEN_FIELD_RESTORE_NEXT_APP
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage

	;
	; force queue this after MSG_GEN_FIELD_RESTORE_NEXT_APP
	;
EC <	mov	bp, 1234						>
	mov	ax, MSG_GEN_FIELD_RESTORE_APP_ACK
	mov	dx, -1
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage		;Let the field know we didn't restart

NoApps:
	andnf	ds:[di].GFI_flags, not mask GFF_RESTORING_APPS
NoMoreApps:
	clr	ds:[di].GFI_numDetachedApps	;Must clear this here, because
						; field may get multiple
						; MSG_GEN_FIELD_RESTORE_APPS
	mov	ax, ds:[di].GFI_apps		;
	tst	ax				; if didn't exist before, done
	jz	checkLauncher			;
						; else we've altered the array
	call	ObjMarkDirty			;  thus, we're dirty.

checkLauncher:
	test	ds:[di].GFI_flags, mask GFF_NEED_DEFAULT_LAUNCHER
	jz	Done

	clr	cx				; Handle errors
	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	call	ObjCallInstanceNoLock

Done:
	ret

GenFieldRestoreNextApp	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestoreAppDiskRestoreCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for GenFieldRestoreNextApp's DiskRestore

CALLED BY:	DiskRestore

PASS:		ds:dx	= drive name (null-terminated, with
			  trailing ':')
		ds:di	= disk name (null-terminated)
		ds:si	= buffer to which the disk handle was saved
		ax	= DiskRestoreError that would be returned if
			  callback weren't being called.
		bx, bp	= as passed to DiskRestore

		ss:bx	= GenFieldDiskRestoreArgs

RETURN:		carry clear if disk should be in the drive;
			ds:si	= new position of buffer, if it moved
		carry set if user canceled the restore:
			ax	= error code to return (usually
				  DRE_USER_CANCELED_RESTORE)

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We should really use a standard dialog here, but that
		would be pretty messy given that we can't do a blocking
		dialog from the UI thread.  So we punt and use SysNotify.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RestoreAppDiskRestoreCallback	proc	far
	.enter
	;
	; Perform standard callback to prompt the user for the disk. Doesn't
	; fixup DS...
	; 
	push	bx
	push	ds:[LMBH_handle]
	call	UserDiskRestoreCallback
	pop	bx
	call	MemDerefDS
	pop	bx		; ss:bx <- GenFieldDiskRestoreArgs

	pushf			; save error flag
	push	ax		; ... and code
	;
	; Deref the array element again so we can return it to DiskRestore
	; 
	mov	si, ss:[bx].GFDRA_appArray
	mov	ax, ss:[bx].GFDRA_elementNum
	call	ChunkArrayElementToPtr
	lea	si, ds:[di].AIR_savedDiskData
	;
	; Recover the error code and flag and return.
	; 
	pop	ax
	popf
	.leave
	ret
RestoreAppDiskRestoreCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldRestoreApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts up an app, given the passed AppLaunchBlock.
CALLED BY:	GLOBAL
PASS: 		cx - # of app being restarted (0-origin)
		dx - AppLaunchBlock for app to load up
RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldRestoreApp	method	GenFieldClass, MSG_GEN_FIELD_RESTORE_APP
	push	si
	push	cx
	mov	bx, dx
	call	MemLock			;Lock AppLaunchBlock
	push	ds
	mov	ds, ax
	tst	ds:[AIR_stateFile][0]	;Is there a state file?
	jnz	5$			;Branch if so...

;	IF NO STATE FILE, DON'T BOTHER RESTARTING THE APPLICATION

	mov	dx, ds:[ALB_userLoadAckAD].AD_OD.handle
	mov	si, ds:[ALB_userLoadAckAD].AD_OD.chunk
	mov	ax, ds:[ALB_userLoadAckAD].AD_message
EC <	mov	bp, ds:[ALB_userLoadAckID]				>
	call	MemFree			;Free AppLaunchBlock
	mov	bx, dx			; bx = AD_OD.handle
	pop	ds
	mov	dx, -1			;
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		;Let the field know we didn't restart
					; this application
	jmp	startNextApp
5$:
	pop	ds
	call	MemUnlock

				; Open each application in turn behind
				; the previous one (Their order in the
				; saved list is the order
				; which we'd like them to come up.)
	mov	ax, TEMP_GEN_FIELD_OPEN_APP_ON_TOP
	call	ObjVarFindData	; Test to see if FIRST application being
				;  restarted

	mov	ah, mask ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE or \
			mask ALF_OPEN_IN_BACK or mask ALF_DO_NOT_OPEN_ON_TOP

	jnc	afterAppLaunchFlags

	call	ObjVarDeleteDataAt
				; If first app to be launched, make it the
				; focus application & open on top.
	mov	ah, mask ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE or \
			mask ALF_OPEN_IN_BACK
afterAppLaunchFlags:
				; Launch the application, requesting
				; that it be restarted from the state file
				; passed
	mov	cx, MSG_GEN_PROCESS_RESTORE_FROM_STATE
	mov	si, -1		; USE filename stored in AppLaunchBlock

	clr	al
	push	ds:[LMBH_handle]
	call	UserLoadApplication
	pop	bx
	call	MemDerefDS
startNextApp:
	pop	cx
	pop	si
	inc	cx
	mov	ax, MSG_GEN_FIELD_RESTORE_NEXT_APP
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	GOTO	ObjMessage
GenFieldRestoreApp	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldRestoreAppAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notification method handler for when a process has/has not 
		been restarted from a state file.

CALLED BY:	GLOBAL
PASS:		cx - geode handle
		dx - error (0 if none)
		bp - ID passed in ALB_userLoadAckID

RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldRestoreAppAck	method	GenFieldClass, MSG_GEN_FIELD_RESTORE_APP_ACK
EC <	cmp	bp, 1234						>
EC <	ERROR_NZ UI_BAD_APP_ACK_ID					>
	tst	dx				;If no error, branch to exit
	jz	exit
	dec	ds:[di].GFI_numRestartedApps	;Decrement # apps running
EC <	ERROR_S	GEN_FIELD_BAD_NUM_RESTARTED_APPS			>
	jne	exit				;If apps running, branch
						;Else, handle error
	mov	ax, MSG_GEN_FIELD_NO_APPS_RESTORED	;
	call	ObjCallInstanceNoLock		
exit:
	ret
GenFieldRestoreAppAck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldNoAppsRestored
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle no applications being successfully restored

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
RETURN:		nothing
ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldNoAppsRestored	method	GenFieldClass,
					MSG_GEN_FIELD_NO_APPS_RESTORED
	mov	ax, TEMP_GEN_FIELD_OPEN_APP_ON_TOP
	call	ObjVarDeleteData

	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	mov	cx, 0				; handle error
	GOTO	ObjCallInstanceNoLock
GenFieldNoAppsRestored	endp

Init ends


Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldLoadDefaultLauncher
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Try to start default launcher for this field, if any.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenField
		es - segment of GenFieldClass (dgroup)

		cx - 0 to handle error
		     -1 to ignore error
		     (error handling depends on launchModel, etc.)

RETURN:		nothing
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version
	chris	9/ 3/93		Changed to pass ourselves as the generic
				parent, rather than relying on the default.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TICKS_TO_WAIT_BEFORE_TRYING_TO_START_DEFAULT_LAUNCHER_AGAIN	equ	5*60
;If the system is too busy to load the default launcher, wait this amount of
; time and start again.

NUM_DEFAULT_LAUNCHER_LOADING_RETRIES	equ	3
;If we can't restart the system

;
; This is in Resident module, to launch from safe memory situation
;
GenFieldLoadDefaultLauncher	method	dynamic GenFieldClass,
					MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER

	test	ds:[di].GFI_flags, mask GFF_HAS_DEFAULT_LAUNCHER
	LONG jz	noDefaultLauncher
	
	push	es
	segmov	es, dgroup, bx
	test	es:[uiFlags], mask UIF_DETACHING_SYSTEM
	pop	es
	LONG jnz noDefaultLauncher

	test	ds:[di].GFI_flags, mask GFF_DETACHING
	LONG jnz noDefaultLauncher

	andnf	ds:[di].GFI_flags, not mask GFF_NEED_DEFAULT_LAUNCHER

	mov	ax, TEMP_GEN_FIELD_LOADING_DEFAULT_LAUNCHER
	call	ObjVarFindData		; carry set if found
	LONG jc	noDefaultLauncher	; if already there, don't need another

	push	cx
	mov	cx, size hptr
	call	ObjVarAddData		; Set flag to indicate we're trying
	pop	cx

	clr	di			;Save all the stack, as this can use
					; alot of stack space...
	call	ThreadBorrowStackSpace
	push	di

	mov	bx, cx			; bx = error handling flag
	mov	cx, INI_CATEGORY_BUFFER_SIZE
	sub	sp, cx
	mov	dx, sp			; cx:dx = category buffer
	mov	cx, ss
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock

	mov	ax, bx			;ax = error handling flag

	push	ds:[LMBH_handle]
	push	si
	mov	ds, cx
	mov	si, dx
	mov	cx, cs
	mov	dx, offset defaultLauncherKey
	clr	bp			; give us a buffer
	call	InitFileReadString	; bx = mem handle
	mov	bp, ax			; bp = error handling flag
	mov	ax, bx			; ax = mem handle
	pop	si
	pop	bx
	call	MemDerefDS
	jc	done			; if no default launcher, leave
					;	empty field


	mov	bx, ax			; bx = mem handle
	call	MemLock
	push	bx

	push	si
	push	ds:[LMBH_handle]
	push	bp			; save error handling flag
	mov	di, ds:[LMBH_handle]	; pass field as ^ldi:bp
	mov	bp, si

	mov	ds, ax			; ds:si = app name
	clr	si
	mov	ah, mask ALF_NO_ACTIVATION_DIALOG
	clr	cx			; default app mode
	clr	dx			; default launch info
	clr	bx			; search system dirs

					
	call	PrepAppLaunchBlock	; get completed AppLaunchBlock in DX
					;  using field in ^ldi:bp!  9/3/93 cbh
	call	UserLoadApplication

	pop	cx			; cx = error handling flag
	mov	bp, bx			; bp = New geode handle
	segmov	es, ds			; es:bx is app name
	pop	bx			; *ds:si = GenField
	call	MemDerefDS
	mov	bx, si
	pop	si
	jc	error

	push	bp			; New geode handle
	mov	ax, TEMP_GEN_FIELD_LOADING_DEFAULT_LAUNCHER
	call	ObjVarFindData		; Find data created earlier
	pop	ds:[bx]			; Save geode handle of new launcher

afterError:
					; *ds:si = GenField
	pop	bx
	call	MemFree

done:
	add	sp, INI_CATEGORY_BUFFER_SIZE

	pop	di
	call	ThreadReturnStackSpace

noDefaultLauncher:
	ret

;
;---------
;

error:
	tst	cx
	jnz	errorEnd

;	Currently, if you exit the last application, the system immediately
;	tries to restart the default launcher. This is OK, but sometimes
;	there won't be enough heap space available until after the app
;	exits, or until the system generally settles down some. 
;	If the error we are getting is "GLE_INSUFFICIENT_HEAP_SPACE", retry
;	a few times...

	cmp	ax, GLE_INSUFFICIENT_HEAP_SPACE
	je	retryLater

;	Also, if the default launcher is already running, just wait till it
;	exits and restart it.

	cmp	ax, GLE_NOT_MULTI_LAUNCHABLE
	jne	reportError
retryLater:

	

;	The system was too busy, so set a flag telling the system to try
;	re-running the default launcher after an app exits.
;
; 	NOTE: If you are running on a system with limited heap space, but
;	you are not in transparent detach mode, trying to load the default
;	launcher when other apps are filling up the heap space will not
;	yield any error - it will transparently just delay the launch until
;	one of the apps has exited.


	mov	di, ds:[si]
	add	di, ds:[di].GenField_offset
	ornf	ds:[di].GFI_flags, mask GFF_LOAD_DEFAULT_LAUNCHER_WHEN_NEXT_PROCESS_EXITS
	jmp	errorEnd
reportError:
	; Report error
	;
	push	cx			; save error handling flag

	push	si
	push	ds:[LMBH_handle]	; save optr to GenField
	segmov	ds, es			; ds:si = app name
	mov	si, bx
	mov	di, offset LauncherErrorTextOne
	call	ReportLoadAppError
	pop	bx			; *ds:si = GenField
	call	MemDerefDS
	pop	si

	pop	cx			; cx = error handling flag


	; Notify notification optr
	;
	mov	ax, MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR
	call	NotifyWithBP		; don't care about BP
	jnc	errorEnd		; notification sent, done

	; If in TRANSPARENT launch mode, then don't detach the field -- just
	; try again.
	;
	mov	ax, segment GenFieldClass
	mov	es, ax
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	je	errorEnd

	;
	; if we have no one to notify about the launcher error, then just
	; detach the field
	;
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_GEN_LOWER_TO_BOTTOM
	mov	di, mask MF_FORCE_QUEUE		; stick in queue to allow
						;	any dialogs to finish
	call	ObjMessage
	clr	cx
	clr	dx
	clr	bp
	mov	ax, MSG_META_DETACH
	mov	di, mask MF_FORCE_QUEUE		; stick in queue to allow
						;	any dialogs to finish
	call	ObjMessage

errorEnd:
					; OK, allow another try now
	mov	ax, TEMP_GEN_FIELD_LOADING_DEFAULT_LAUNCHER
	call	ObjVarDeleteData
	jmp	afterError

GenFieldLoadDefaultLauncher	endp

;
; this must be in Resident, as it is used in other resources
;
defaultLauncherKey	char	"defaultLauncher", 0


Resident ends

;--------

Common segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Intercept to clean up TEMP_GEN_FIELD_LOADING_DEFAULT_LAUNCHER

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_MUP_ALTER_FTVMC_EXCL

		^lcx:dx - object requesting grab/release
		bp	- MetaAlterFTVMCExclFlags

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldAlterFTVMCExcl	method	dynamic GenFieldClass, 
					MSG_META_MUP_ALTER_FTVMC_EXCL
	mov	di, offset GenFieldClass
	call	ObjCallSuperNoLock

	; If we've been trying to load the default launcher, & it has
	; just been given the focus, then consider our task complete --
	; nuke the vardata we've been keeping around, keeping us from
	; repeatedly trying to load the launcher, now that it has arrived.
	;
	mov	ax, TEMP_GEN_FIELD_LOADING_DEFAULT_LAUNCHER
	call	ObjVarFindData
	jnc	done
	mov	di, ds:[bx]		; Fetch geode being launched

	mov	ax, MSG_META_GET_FOCUS_EXCL
	call	ObjCallInstanceNoLock
	jcxz	done
	mov	bx, cx
	call	MemOwner		; get owning geode of new focus
	cmp	bx, di
	jne	done

	mov	ax, TEMP_GEN_FIELD_LOADING_DEFAULT_LAUNCHER
	call	ObjVarDeleteData	; Delete vardata for new launcher
done:
	reT
GenFieldAlterFTVMCExcl	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldAddGenApplication

DESCRIPTION:	Handle addition of an application from the field.  Add
		the process handle to our list and make the process "owned"
		by the UI.

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_ADD_GEN_APPLICATION

	cx:dx	- optr of GenApplication to add
	bp	- CompChildFlags

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

GenFieldAddGenApplication	method	dynamic GenFieldClass, 
					MSG_GEN_FIELD_ADD_GEN_APPLICATION

	push	cx, dx			; save GenApplication optr
	push	bp			; save CompChildFlags

	; change process to be "owned" by the UI

	mov	bx, cx
	call	MemOwner		; bx = handle of process
	mov	ax, handle 0
	call	HandleModifyOwner

	; add process handle to our list

	mov	bp, 0			; adding process handle
	mov	cx, bx			; cx = process handle
	mov	bx, offset GFI_processes
	mov	ax, CCO_LAST		; add at end
	call	AddChunkOrOptrToList

	; add GenApplication optr to our list

	mov	bp, -1			; adding optr
	pop	ax			; CompChildFlags
	pop	cx, dx			; cx:dx = GenApplication optr
	mov	bx, offset GFI_genApplications

	push	cx			; save handle of app
	call	AddChunkOrOptrToList
	pop	bx			; get handle of app
	call	MemOwner		; get owning geode of app
	mov	cx, bx			; Pass in cx
	clr	dx			; Don't need (or know) AppLaunchBlock
	mov	ax, MSG_GEN_FIELD_APP_STARTUP_DONE
	call	ObjCallInstanceNoLock
EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFieldAddGenApplication	endm

;
; pass:
;	*ds:si - object
;	bp - 0 if adding process handle
;		cx - process handle to add
;	bp <> 0 if adding optr
;		cx:dx - optr to add
;	bx - offset of instance data field holding list chunk handle
;	ax - CompChildFlags
; return:
;	nothing
; destroys:
;	ax, bx, cx, dx, di
;
AddChunkOrOptrToList	proc	near
	uses	si
	.enter
	push	cx			; save process or optr.handle
	tst	bp
	jz	chunk0
	push	dx			; save optr.chunk
chunk0:
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di][bx]		; di = chunk handle
	tst	di			; does the chunk exist ?
	jz	noChunk			; no, need to allocate
	mov	cx, ds:[di]		; di = chunk address
	inc	cx
	jz	exists			; was 0xffff (empty chunk), reallocate
	dec	cx
	jnz	exists			; non-empty chunk, resize and store
					; else, was 0, allocate new chunk
noChunk:
	mov	cx, 2
	tst	bp
	jz	chunk1
	mov	cx, 4
chunk1:
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc		; ax = chunk
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di][bx], ax
	mov	di, ax
	mov	di, ds:[di]
	add	di, cx
	tst	bp
	jz	chunk25
	pop	ds:[di-4]		; optr.chunk
chunk25:
	pop	ds:[di-2]		; optr.handle or process handle
	jmp	short done

exists:
	;
	; insert new item in correct place
	;	*ds:di = list chunk
	;	ax = CompChildFlags
	;
	ChunkSizeHandle	ds, di, bx	; bx = size (end of list offset)
	andnf	ax, mask CCF_REFERENCE	; extract reference field
	cmp	ax, CCO_LAST		; desired to be in last position?
	je	havePosition		; yes, insert at end (bx)
	shl	ax			; ax = offset for new 2-byte entries
	tst	bp
	jz	chunk3
	shl	ax			; ax = offset for new 4-byte entries
chunk3:
	cmp	ax, bx			; is desired position beyond end?
	ja	havePosition		; yes, just use last position
	mov	bx, ax			; bx = offset for new entry
havePosition:
	mov	ax, di			; ax = chunk
	mov	cx, 2
	tst	bp
	jz	haveSize
	mov	cx, 4
haveSize:
	call	LMemInsertAt		; insert space for new entry
	mov	di, ax			; *ds:di = list chunk
	mov	di, ds:[di]		; ds:di = list
	tst	bp
	jz	chunk4
	pop	ds:[di][bx]		; optr.chunk
	pop	ds:[di][bx+2]		; optr.handle
	jmp	short done
chunk4:
	pop	ds:[di][bx]		; process handle
done:
	.leave
	ret
AddChunkOrOptrToList	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldRemoveGenApplication

DESCRIPTION:	Handle removal of an application from the field. 

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_REMOVE_GEN_APPLICATION

	cx:dx	- child to remove

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

GenFieldRemoveGenApplication	method	GenFieldClass,
					MSG_GEN_FIELD_REMOVE_GEN_APPLICATION

	;
	; remove GenApplication optr from our GenApplication optr list
	;
	call	RemoveOptrFromAppList

EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFieldRemoveGenApplication	endm

;
; pass:
;	cx:dx = optr to remove
;	*ds:si = GenField
;	ds:di = GenInstance
;
RemoveOptrFromAppList	proc	near
	class	GenFieldClass
	mov	ax, cx				;ax:dx = GenApplication optr

	mov	di, ds:[di].GFI_genApplications

	mov	bx, di				;bx saves chunk
	mov	di, ds:[di]			;ds:di = list
	inc	di
	jz	notFound
	dec	di
	jz	notFound

	ChunkSizePtr	ds, di, cx		;cx = size
	shr	cx
	shr	cx				;cx = number of optrs
	segmov	es, ds				;es:di = list
searchLoop:
	cmp	es:[di]+2, ax			; handle is at +2
	jne	searchNext
	cmp	es:[di]+0, dx			; chunk is at +0
	je	found
searchNext:
	add	di, size optr
	loop	searchLoop
notFound:
EC <	ERROR_C	UI_GEN_FIELD_GEN_APPLICATION_LIST_CORRUPT		>
found:
	; found -- remove it

	sub	di, ds:[bx]
	mov	ax, bx				;ax = chunk
	mov	bx, di				;bx = offset to delete at
	mov	cx, 4				;# bytes to delete
	call	LMemDeleteAt
	ret
RemoveOptrFromAppList	endp


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldMoveGenApplication

DESCRIPTION:	Handle moving of an application to the end of the field's
		application list.

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_MOVE_GEN_APPLICATION

	cx:dx	- application to move to end of list
	bp	- CompChildFlags

RETURN:	nothing

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

GenFieldMoveGenApplication	method	GenFieldClass,
					MSG_GEN_FIELD_MOVE_GEN_APPLICATION

	;
	; remove GenApplication optr from our GenApplication optr list
	;
	push	cx, dx				; save GenApplication
	push	bp				; save CompChildFlags
	call	RemoveOptrFromAppList

	;
	; add it back in at the end of the application list
	;
	mov	bp, -1			; adding optr
	pop	ax			; CompChildFlags
	pop	cx, dx			; cx:dx = GenApplication optr
	mov	bx, offset GFI_genApplications
	call	AddChunkOrOptrToList

EC <	Destroy	ax, cx, dx, bp						>
	ret

GenFieldMoveGenApplication	endm


COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldProcessExit

DESCRIPTION:	Notification that a process has exited.  See if it is a process
		on this field.

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_PROCESS_EXIT

	cx - handle of child process

RETURN: carry - set if process found

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

GenFieldProcessExit	method	GenFieldClass,
				MSG_GEN_FIELD_PROCESS_EXIT

	mov	ax, cx				;ax = process

	mov	di, ds:[di].GFI_processes

	tst	di				;array allocated?
	jz	notFound			;no -- can't know the thing.

	mov	bx, di				;bx saves chunk
	mov	di, ds:[di]			;ds:di = list
	inc	di
	jz	notFound
	dec	di
	jz	notFound

	ChunkSizePtr	ds, di, cx		;cx = size
	mov	dx, cx				;dx = size
	shr	cx
	segmov	es, ds				;es:di = list
	jz	notFound			; => cx is 0, so not found

	repne	scasw				;search
	jnz	notFound

	; found -- remove it

	sub	di, ds:[bx]
	sub	di, 2
	mov	ax, bx				;ax = chunk
	mov	bx, di				;bx = offset to delete at
	mov	cx, 2				;# bytes to delete
	call	LMemDeleteAt

	; if this was the last one and we are detaching then finish

	cmp	dx, 2
	jnz	done
	mov	di, ds:[si]
	add	di, ds:[di].GenField_offset
	test	ds:[di].GFI_flags, mask GFF_DETACHING
	jz	done
	call	ObjAckDetach
done:

;
;	We are waiting until this app exits before loading the default
;	launcher - go for it now.
;
	mov	di, ds:[si]
	add	di, ds:[di].GenField_offset
	test	ds:[di].GFI_flags, mask GFF_LOAD_DEFAULT_LAUNCHER_WHEN_NEXT_PROCESS_EXITS
	pushf
	andnf	ds:[di].GFI_flags, not mask GFF_LOAD_DEFAULT_LAUNCHER_WHEN_NEXT_PROCESS_EXITS
	popf
	jz	noLoadDefaultLauncher

	clr	cx			; report errors
	mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
	call	ObjCallInstanceNoLock

noLoadDefaultLauncher:
	stc					;return success
	ret

notFound:
	clc
	ret

GenFieldProcessExit	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReportLoadAppError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	report error from loading application

CALLED BY:	INTERNAL
PASS:		ax - GeodeLoadError
		ds:si - application name
		(ds:si *cannot* be pointing into the movable XIP code resource.)
		di - chunk of main error string (in Strings resource)
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, es, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReportLoadAppError	proc	far
		
if	FULL_EXECUTE_IN_PLACE
	;
	; Make sure the fptr passed in is valid
	;
EC <		push	bx						>
EC <		mov	bx, ds						>
EC <		call	ECAssertValidFarPointerXIP			>
EC <		pop	bx						>
endif
	;
	; this assumes GeodeLoadError starts at 0 and increments by 1
	;
EC <	cmp	ax, GeodeLoadError					>
EC <	ERROR_AE	BAD_GEODE_LOAD_ERROR				>
	mov_tr	bp, ax			; bx = error code
	shl	bp, 1			; convert to word table index
	;
	; PDA hacks - brianc 7/14/93
	;
	call	UserCheckIfPDA
	jnc	notPDA
	mov	ax, cs:[GeodeLoadErrorStringsPDA][bp]
	tst	ax
	jz	notPDA
	mov	bp, ax
	jmp	short haveErrStr
notPDA:
	mov	bp, cs:[GeodeLoadErrorStrings][bp]
haveErrStr:
	cmp	bp, offset GeodeLoadHeapSpaceError
	jne	notTransparentHeapSpaceError
	mov	ax, segment uiLaunchModel
	mov	es, ax
	cmp	es:[uiLaunchModel], UILM_TRANSPARENT
	jne	notTransparentHeapSpaceError
	mov	bp, offset GeodeLoadHeapSpaceErrorTransparent
notTransparentHeapSpaceError:
	mov	bx, handle Strings
	call	MemLock
	mov	es, ax			; es = Strings resource
	mov	di, es:[di]		; es:di = main error string
	mov	bx, es:[bp]		; es:bp = secondary error string
	mov	dx, size GenAppDoDialogParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GADDP_dialog.SDP_customFlags, \
			mask CDBF_SYSTEM_MODAL or \
			CDT_ERROR shl offset CDBF_DIALOG_TYPE or \
			GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE
					; main error string
	movdw	ss:[bp].GADDP_dialog.SDP_customString, esdi
					; arg 1 = filename
	movdw	ss:[bp].GADDP_dialog.SDP_stringArg1, dssi
					; arg 2 = secondary error string
	movdw	ss:[bp].GADDP_dialog.SDP_stringArg2, esbx
	movdw	ss:[bp].GADDP_finishOD, 0	; going nowhere...
	clr	ss:[bp].GADDP_dialog.SDP_helpContext.segment
	mov	bx, handle UIApp
	mov	si, offset UIApp
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	mov	di, mask MF_STACK or mask MF_CALL
	call	ObjMessage
	add	sp, size GenAppDoDialogParams
	mov	bx, handle Strings
	call	MemUnlock
;exit:
	ret
ReportLoadAppError	endp

GeodeLoadErrorStrings	label	lptr
	lptr	offset 	GeodeLoadProtocolError		;IMPORTER_TOO_RECENT
	lptr	offset	GeodeLoadProtocolError		;IMPORTER_TOO_OLD
	lptr	offset	GeodeLoadFileNotFoundError	;FILE_NOT_FOUND
	lptr	offset	GeodeLoadLibraryNotFoundError	;LIBRARY_NOT_FOUND
	lptr	offset	GeodeLoadMiscFileError		;FILE_READ_ERROR
	lptr	offset	GeodeLoadMiscFileError		;NOT_GEOS_FILE
	lptr	offset	GeodeLoadMiscFileError		;NOT_GEOS_EXECUTABLE
	lptr	offset	GeodeLoadMiscFileError		;ATTRIBUTE_MISMATCH
	lptr	offset	GeodeLoadNoMemError		;MEMORY_ALLOCATION
	lptr	offset	GeodeLoadMultiLaunchError	;MULTI_LAUNCHABLE
	lptr	offset	GeodeLoadProtocolError		;PROTOCOL_ERROR
	lptr	offset	GeodeLoadMiscFileError		;LOAD_ERROR
	lptr	offset	GeodeLoadMiscFileError		;DRIVER_INIT_ERROR
	lptr	offset	GeodeLoadMiscFileError		;LIBRARY_INIT_ERROR
	lptr	offset	GeodeLoadDiskFullError		;DISK_TOO_FULL
	lptr	offset	GeodeLoadFieldDetachingError	;FIELD_DETACHING
	lptr	offset	GeodeLoadHeapSpaceError		;INSUFFICIENT_HEAP_SPACE

if (GeodeLoadError ne ($-GeodeLoadErrorStrings)/2)
	ErrMessage <ERROR: Too few GeodeLoadErrorStrings>
endif

GeodeLoadErrorStringsPDA	label	lptr
	lptr	0					;IMPORTER_TOO_RECENT
	lptr	0					;IMPORTER_TOO_OLD
	lptr	offset	GeodeLoadFileNotFoundErrorPDA	;FILE_NOT_FOUND
	lptr	offset	GeodeLoadLibraryNotFoundErrorPDA ;LIBRARY_NOT_FOUND
	lptr	offset	GeodeLoadMiscFileErrorPDA	;FILE_READ_ERROR
	lptr	offset	GeodeLoadMiscFileErrorPDA	;NOT_GEOS_FILE
	lptr	offset	GeodeLoadMiscFileErrorPDA	;NOT_GEOS_EXECUTABLE
	lptr	offset	GeodeLoadMiscFileErrorPDA	;ATTRIBUTE_MISMATCH
	lptr	0					;MEMORY_ALLOCATION
	lptr	0					;MULTI_LAUNCHABLE
	lptr	0					;PROTOCOL_ERROR
	lptr	offset	GeodeLoadMiscFileErrorPDA	;LOAD_ERROR
	lptr	offset	GeodeLoadMiscFileErrorPDA	;DRIVER_INIT_ERROR
	lptr	offset	GeodeLoadMiscFileErrorPDA	;LIBRARY_INIT_ERROR
	lptr	0					;DISK_TOO_FULL
	lptr	0					;FIELD_DETACHING
	lptr	0					;INSUFFICIENT_HEAP_SPACE

if (GeodeLoadError ne ($-GeodeLoadErrorStringsPDA)/2)
	ErrMessage <ERROR: Too few GeodeLoadErrorStringsPDA>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldReadInitFileBoolean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GenFieldReadInitFileBoolean

CALLED BY:	INTERNAL
PASS:		*ds:si - GenField
		cx:dx - key
RETURN:		carry clear if found
			ax = TRUE or FALSE
		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldReadInitFileBoolean	proc	near
	uses	ds, si
catBuffer	local	INI_CATEGORY_BUFFER_SIZE dup (char)
	.enter

	pushdw	cxdx			; save key
	mov	cx, ss			; cx:dx = category buffer
	lea	dx, catBuffer
	mov	ax, MSG_META_GET_INI_CATEGORY
	call	ObjCallInstanceNoLock
	mov	ds, cx			; ds:si = category
	mov	si, dx
	popdw	cxdx			; cx:dx = key
	call	InitFileReadBoolean	; carry/ax = results
	.leave
	ret
GenFieldReadInitFileBoolean	endp



COMMENT @----------------------------------------------------------------------

METHOD:		GenFieldAboutToClose

DESCRIPTION:	If in 'quitOnClose' mode, quit all applications running in
		field, else do nothing.

PASS:
	*ds:si - instance data
	es - segment of GenFieldClass

	ax - MSG_GEN_FIELD_ABOUT_TO_CLOSE

RETURN:	carry clear if GenField doesn't have 'quitOnClose' set and can
		be closed immediately
	carry set if 'quitOnClose' is set and field should not be
		closed until all apps are exited (whence
		MSG_META_FIELD_NOTIFY_NO_FOCUS will be sent)

ALLOWED_TO_DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	As each app exits, we'll get MSG_GEN_FIELD_PROCESS_EXIT

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/26/92	Initial version

------------------------------------------------------------------------------@

GenFieldAboutToClose	method	dynamic GenFieldClass,
						MSG_GEN_FIELD_ABOUT_TO_CLOSE

	mov	cx, cs
	mov	dx, offset quitOnCloseKey
	call	GenFieldReadInitFileBoolean	;carry clear if found
						;	(ax = TRUE or FALSE)
	cmc					;set if found, clr if not
	jnc	done				;not found, done return C clr
	tst	ax				;(clear carry)
	jz	done				;FALSE, done

	;
	; Indicate that we are doing 'quitOnClose'.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	ornf	ds:[di].GFI_flags, mask GFF_QUIT_ON_CLOSE

	;
	; query shutdown control list, sending ack to ourselves.  When we
	; receive ack, we quit all apps or do nothing depending on whether
	; shutdown control objects aborted detach.
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bp, MSG_GEN_FIELD_SHUTDOWN_CONTROL_RESPONSE
	mov	ax, SST_CLEAN
	call	SysShutdown
	stc				; wait for
					;	MSG_META_FIELD_NOTIFY_NO_FOCUS
done:

	ret

GenFieldAboutToClose	endm

quitOnCloseKey	char	"quitOnClose", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldShutdownControlResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle our quitOnClose shutdown-control query

CALLED BY:	MSG_GEN_FIELD_SHUTDOWN_CONTROL_RESPONSE

PASS:		*ds:si	= class object
		ds:di	= class instance data
		es 	= segment of class
		ax	= MSG_GEN_FIELD_SHUTDOWN_CONTROL_RESPONSE

		cx	= 0 if shutdown denied
			  non-zero if shutdown allowed

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/29/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenFieldShutdownControlResponse	method	dynamic	GenFieldClass,
					MSG_GEN_FIELD_SHUTDOWN_CONTROL_RESPONSE

	jcxz	done				; shutdown denied
	;
	; quit all apps in this field
	;
	mov	di, ds:[di].GFI_genApplications
	tst	di				; any apps?
	jz	noApps				; nope
	mov	di, ds:[di]			; ds:di = list
	inc	di
	jz	noApps				; no apps
	dec	di
	jz	noApps				; no apps
	ChunkSizePtr	ds, di, cx		; cx = size of list
	shr	cx
	shr	cx				; cx = number of apps

	;
	; quit all applications
	;	*ds:si = GenField
	;	cx = number of GenApps
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, ds:[di].GFI_genApplications
	mov	di, ds:[di]		; ds:di = GenApp list
quitLoop:
	push	cx			; save GenApp counter
	push	si			; save GenField chunk
	;
	; send MSG_META_QUIT to GenApp object
	;
	mov	bx, ds:[di]+2		; GenApp handle
	mov	si, ds:[di]+0		; GenApp chunk
	push	di			; save GenApp list offset
	mov	ax, MSG_META_QUIT
					; force-queue -> doesn't move lmem block
	mov	di, mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	di			; retrieve GenApp list offset
	add	di, size optr
	pop	si			; *ds:si = GenField
	pop	cx			; cx = GenApp counter
	loop	quitLoop
	jmp	short done

noApps:
	mov	ax, MSG_META_FIELD_NOTIFY_NO_FOCUS
	call	NotifyWithShutdownFlag	; don't care if not sent (ie. no dest)
done:
	ret
GenFieldShutdownControlResponse	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenFieldGetLaunchModel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get launch model in use

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_FIELD_GET_LAUNCH_MODEL

RETURN:		ax	- UILaunchModel

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenFieldGetLaunchModel	method	dynamic	GenFieldClass,
					MSG_GEN_FIELD_GET_LAUNCH_MODEL
	segmov	es, dgroup, ax		; SH
	mov	ax, es:[uiLaunchModel]
	ret
GenFieldGetLaunchModel	endm

Common ends
