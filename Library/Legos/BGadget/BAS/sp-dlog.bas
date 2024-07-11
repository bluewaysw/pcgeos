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
REM   jimmy	 6/19/95	Initial Version
REM
REM	$Id: sp-dlog.bas,v 1.1 98/03/12 20:28:23 martin Exp $
REM
REM ********************************************

    dim dialogSpecPropBox as component
    export dialogSpecPropBox

    dialogSpecPropBox = MakeComponent("control","top")
    dialogSpecPropBox.proto = "dialogSpecPropBox"

    REM Make a "type" property group.
    dim typeArray[6] as choice
    dim typeGroup as group
    dim i as integer
    typeGroup = MakeComponent("group", dialogSpecPropBox)
    typeGroup.caption = "Type"
    typeGroup.visible = 1
    typeGroup.tile = 1
    typeGroup.tileHAlign = 2 REM left justify
    for i = 0 to 5
	typeArray[i] = MakeComponent("choice", typeGroup)
	typeArray[i].proto = "anyChoice"
	typeArray[i].value = i
	typeArray[i].visible = 1
    next

    typeArray[0].caption = "Non-modal"
    typeArray[1].caption = "Tool box"
    typeArray[2].caption = "Modal"
    typeArray[3].caption = "System-modal"
    typeArray[4].caption = "Always on top"
    typeArray[5].caption = "Popup"

    REM Make a "focus" property.
    dim focusGroup as group
    dim focusComp as entry
    focusGroup = MakeComponent("group", dialogSpecPropBox)
    CompInit focusGroup
	caption = "Focus"
	visible = 1
	tile = 1
	tileHAlign = 2 REM left justify
    end CompInit
    focusComp = MakeComponent("entry", focusGroup)
    CompInit focusComp
	filter = 36      REM alphanumeric chars only
	visible = 1
    end CompInit

    REM make a "helpContext" property
    dim helpGroup as group
    dim helpContextEntry as entry
    helpGroup = MakeComponent("group", dialogSpecPropBox)
    CompInit helpGroup
	caption = "helpContext"
	tile = 1
	tileHAlign = 2   REM left justify
	visible = 1
    end CompInit
    helpContextEntry = MakeComponent("entry", helpGroup)
    CompInit helpContextEntry
	name = "helpContextEntry"
	visible = 1
	filter = 36      REM alphanumeric characters onlly
    end CompInit
	

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-dlog.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = dialogSpecPropBox
end function

sub dialogSpecPropBox_update (current as component)
    dialogSpecPropBox.current = current
    typeArray[current.type].status = 1

    REM ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE **
    REM We need to map the string representing the desired .focus
    REM to a component.  This mapping is done by BGadgetDialogClass.
    REM Here, we're grabbing the string associated with the desired
    REM .focus component.
    focusComp.text = current.focusString
    helpContextEntry.text = current.helpContext
end sub


sub sp_apply()
    dialogSpecPropBox.current.type = typeArray[0].choice.value

    REM ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE **
    REM We need to map the string representing the desired .focus
    REM to a component.  This mapping is done by BGadgetDialogClass.
    REM Here, we grab the string name of the desired .focus component
    REM and assign it to the dialog's special focusString property.
    REM BGadgetDialogClass does special things when it see "focusString"
    REM being set.
    dialogSpecPropBox.current.focusString = focusComp.text

    dialogSpecPropBox.current.helpContext = helpContextEntry.text

    if dialogSpecPropBox.current.visible then
        dialogSpecPropBox.current.visible = 0
        dialogSpecPropBox.current.visible = 1
    end if 

end sub

sub anyChoice_changed(self as choice)

REM ********************************************************************
REM                       anyChoice_changed
REM ********************************************************************
REM
REM SYNOPSIS:	Handle _changed event for the all choices.
REM
REM CALLED BY:	builder UI
REM 
REM ********************************************************************

REM
REM Ensure a Selection
REM
REM This line ensures that one of the choices is always selected.  The
REM Legos API allows for all the choices in a group to unselected, which
REM is not what we want.
REM

    self.status = 1 
end sub
