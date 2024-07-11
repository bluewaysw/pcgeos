sub duplo_ui_ui_ui()
duplo_start()
end sub

sub duplo_start()
REM ********************************************
REM		duplo_start
REM ********************************************
REM
REM  SYNOPSIS:
REM	
REM  CALLED BY:
REM  PASS:
REM  RETURN:
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   jmagasin	 1/17/96	Initial Version
REM
REM	$Id: sp-form.bas,v 1.1 98/03/12 20:29:08 martin Exp $
REM
REM ********************************************

    dim formSpecPropBox as component
    export formSpecPropBox

    formSpecPropBox = MakeComponent("control","top")
    formSpecPropBox.proto = "formSpecPropBox"

    dim formPropGroup as component
    formPropGroup = MakeComponent("group", formSpecPropBox)
    CompInit formPropGroup
	name = "formPropGroup"
	visible = 1
	tile = 1
	tileHAlign = 3 		REM right align
	tileSpacing = 3
    end CompInit

    REM Make a "focus" property.
    dim focusGroup as group
    dim focusComp as entry
    focusGroup = MakeComponent("group", formPropGroup)
    CompInit focusGroup
	caption = "focus"
	visible = 1
    end CompInit

    focusComp = MakeComponent("entry", focusGroup)
    CompInit focusComp
	name = "focusComp"
	filter = 36      REM alphanumeric chars only
	visible = 1
    end CompInit

    REM make a "helpContext" property
    dim helpContextGroup as group
    dim helpContextEntry as entry
    helpContextGroup = MakeComponent("group", formPropGroup)
    CompInit helpContextGroup
	caption = "helpContext"
	visible = 1
    end CompInit
    helpContextEntry = MakeComponent("entry", helpContextGroup)
    CompInit helpContextEntry
	name = "helpContextEntry"
	filter = 36      REM alphanumeric characters only
	visible = 1
    end CompInit

    dim helpFileGroup as group
    dim helpFileEntry as entry
    helpFileGroup = MakeComponent("group", formPropGroup)
    CompInit helpFileGroup
	caption = "helpFile"
	visible = 1
    end CompInit
    helpFileEntry = MakeComponent("entry", helpFileGroup)
    CompInit helpFileEntry
	name = "helpFileEntry"
	filter = 36	REM alphanumeric characters only
	visible = 1
    end CompInit

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1996
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-form.bas
REM	AUTHOR:	Jonathan Magasin, Jan 17, 1996
REM	jmagasin
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = formSpecPropBox
end function

sub formSpecPropBox_update (current as component)
    formSpecPropBox.current = current

    REM ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE **
    REM We need to map the string representing the desired .focus
    REM to a component.  This mapping is done by BGadgetFormClass.
    REM Here, we're grabbing the string associated with the desired
    REM .focus component.
    focusComp.text = current.focusString
    helpContextEntry.text = current.helpContext
    helpFileEntry.text = current.helpFile
end sub


sub sp_apply()
    REM ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE **
    REM We need to map the string representing the desired .focus
    REM to a component.  This mapping is done by BGadgetFormClass.
    REM Here, we grab the string name of the desired .focus component
    REM and assign it to the forms's special focusString property.
    REM BGadgetFormClass does special things when it see "focusString"
    REM being set.
    formSpecPropBox.current.focusString = focusComp.text
    formSpecPropBox.current.helpContext = helpContextEntry.text
    formSpecPropBox.current.helpFile = helpFileEntry.text
    if formSpecPropBox.current.visible then
        formSpecPropBox.current.visible = 0
        formSpecPropBox.current.visible = 1
    end if 
end sub
