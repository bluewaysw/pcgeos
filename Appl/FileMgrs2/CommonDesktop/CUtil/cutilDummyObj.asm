COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cutilDummyObj.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

DESCRIPTION:
	

	$Id: cutilDummyObj.asm,v 1.3 98/06/03 13:50:58 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileOpLow	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetDummyFromTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the optr of the dummy object for the passed
		object type.  In GeoManager, always returns the same
		object. 

CALLED BY: 	EXTERNAL

PASS:		si - NewDeskObjectType

RETURN:		^lbx:si - optr of dummy object

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/25/92	Initial version
        chrisb	11/2/92		changed to return BX:SI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetDummyFromTable	proc	far
GM <	LoadBXSI	DefaultDummy					>

if _NEWDESK
EC <	call	ECCheckNewDeskObjectType				>
	add	si, OFFSET_FOR_WOT_TABLES
	shl	si
 	mov	bx, cs:[NewDeskDummyObjectTable][si].handle
 	mov	si, cs:[NewDeskDummyObjectTable][si].offset
endif
	ret
UtilGetDummyFromTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetDummyFromTableWithHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the optr of the dummy object for the passed
		object type, and ensure the help context is correct.
		This means that for WOT_DRIVE, we actually determine
		what type of drive it is and then set

CALLED BY: 	EXTERNAL

PASS:		si - NewDeskObjectType
		al - drive # (if si = WOT_DRIVE)

RETURN:		^lbx:si - optr of dummy object with correct help context

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	09/25/92	Initial version
        chrisb	11/2/92		changed to return BX:SI
	Don	10/06/00	Broke out into new routine to handle
				  help context problem.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetDummyFromTableWithHelp	proc	far
GM <	LoadBXSI	DefaultDummy					>

if _NEWDESK
	push	ax, di, bp
EC <	call	ECCheckNewDeskObjectType				>
	clr	ah
	mov_tr	bp, ax			; drive number => bp
	mov	ax, si
	add	si, OFFSET_FOR_WOT_TABLES
	shl	si
 	mov	bx, cs:[NewDeskDummyObjectTable][si].handle
 	mov	si, cs:[NewDeskDummyObjectTable][si].offset

	cmp	ax, WOT_DRIVE
	jne	done
	mov	ax, MSG_ND_DRIVE_SET_HELP_CONTEXT
	mov	di, mask MF_CALL
	call	ObjMessage
done:
	pop	ax, di, bp
endif
	ret
UtilGetDummyFromTableWithHelp	endp

if _NEWDESK

if ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckNewDeskObjectType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the NewDeskObjectType is valid

CALLED BY:

PASS:		si - NewDeskObjectType

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckNewDeskObjectType	proc near
	.enter
	pushf
	cmp	si, -OFFSET_FOR_WOT_TABLES
	ERROR_L	ILLEGAL_OBJECT_TYPE
	cmp	si, NewDeskObjectType
	ERROR_G ILLEGAL_OBJECT_TYPE
	popf

	.leave
	ret
ECCheckNewDeskObjectType	endp

endif


; These are the tables of DUMMY objects.  There must be one object for
; each NewDeskObjectType.  If you add any entries to either of these
; tables, please add the appropriate .assert statements.

NewDeskDummyObjectTable	label	optr
if _NEWDESKBA
	optr	BAStudentUtilityDummy,		; WOT_STUDENT_UTILITY
		BAOfficeCommonDummy,		; WOT_OFFICE_COMMON
		BATeacherCommonDummy,		; WOT_TEACHER_COMMON
		BAOfficeHomeDummy,		; WOT_OFFICE_HOME
		BAStudentCourseDummy,		; WOT_STUDENT_COURSE
		BAStudentHomeDummy,		; WOT_STUDENT_HOME
		BAGEOSCoursewareDummy,		; WOT_GEOS_COURSEWARE
		BADOSCoursewareDummy,		; WOT_DOS_COURSEWARE
		BAOfficeAppListDummy,		; WOT_OFFICEAPP_LIST
		BASpecialUtilitiesListDummy,	; WOT_SPECIALS_LIST
		BACoursewareListDummy,		; WOT_COURSEWARE_LIST
		BAPeopleListDummy,		; WOT_PEOPLE_LIST
		BAStudentClassesDummy,		; WOT_STUDENT_CLASSES
		BAStudentHomeTViewDummy,	; WOT_STUDENT_HOME_TVIEW
		BATeacherCourseDummy,		; WOT_TEACHER_COURSE
		BARosterDummy,			; WOT_ROSTER
		BATeacherClassesDummy,		; WOT_TEACHER_CLASSES
		BATeacherHomeDummy		; WOT_TEACHER_HOME

endif		; if _NEWDESKBA

; Non-NewDesk BA dummies.  Note that the "default dummy" DOESN'T have
; to be at FOLDER_OBJECT_OFFSET, because it's not a folder.

	optr	NDFolderDummy,			; WOT_FOLDER
		NDDesktopFolderDummy,		; WOT_DESKTOP
		NDPrinterDummy,			; WOT_PRINTER
		NDWastebasketDummy,		; WOT_WASTEBASKET
		NDDriveDummy,			; WOT_DRIVE
		DocumentDummy,			; WOT_DOCUMENT
		ExecutableDummy,		; WOT_EXECUTABLE
		HelpDummy,			; WOT_HELP
		LogoutDummy,			; WOT_LOGOUT
		NDSystemFolderDummy		; WOT_SYSTEM_FOLDER


.assert (($-NewDeskDummyObjectTable) eq \
	 (NewDeskObjectType + OFFSET_FOR_WOT_TABLES)*2)

.assert (offset NDFolderDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset NDSystemFolderDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset NDDesktopFolderDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset NDPrinterDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset NDWastebasketDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset NDDriveDummy eq FOLDER_OBJECT_OFFSET)
if _NEWDESKBA
.assert	(offset BATeacherHomeDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BATeacherClassesDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BARosterDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BATeacherCourseDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentHomeTViewDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentClassesDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAPeopleListDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BACoursewareListDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BASpecialUtilitiesListDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAOfficeAppListDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAOfficeCommonDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BATeacherCommonDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAOfficeHomeDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentCourseDummy eq FOLDER_OBJECT_OFFSET)
.assert (offset BAStudentHomeDummy eq FOLDER_OBJECT_OFFSET)
endif		; if _NEWDESKBA

endif ;	_NEWDESK

FileOpLow	ends
