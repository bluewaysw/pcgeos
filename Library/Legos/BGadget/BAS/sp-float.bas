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
REM	$Id: sp-float.bas,v 1.1 98/03/12 20:28:52 martin Exp $
REM
REM ********************************************

    dim floaterSpecPropBox as component
    export floaterSpecPropBox

    floaterSpecPropBox = MakeComponent("control","top")
    floaterSpecPropBox.proto = "floaterSpecPropBox"

    REM Make a "type" property group.
    dim typeGroup as group
    dim typeArray[6] as choice
    typeGroup = MakeComponent("group", floaterSpecPropBox)
    typeGroup.caption = "Type"
    typeGroup.visible = 1	
    typeGroup.tile = 1
    typeGroup.tileHAlign = 2 REM left justify
    
    dim i as integer
    for i = 0 to 5
	typeArray[i] = MakeComponent("choice", typeGroup)
	typeArray[i].value = i
	typeArray[i].visible = 1
    next

    typeArray[0].caption = "Non-modal 0"
    typeArray[1].caption = "Tool box 1"
    typeArray[2].caption = "Modal 2"
    typeArray[3].caption = "System-modal 3"
    typeArray[4].caption = "Always on top 4"
    typeArray[5].caption = "Popup 5"

    REM Make a "focus" property.
    dim focusGroup as group
    dim focusComp as entry
    focusGroup = MakeComponent("group", floaterSpecPropBox)
    focusGroup.caption = "Focus"
    focusGroup.visible = 1
    focusGroup.tile = 1
    focusGroup.tileHAlign = 2 REM left justify
    focusComp = MakeComponent("entry", focusGroup)
    focusComp.filter = 36      REM alphanumeric chars only
    focusComp.visible = 1

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-float.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = floaterSpecPropBox
end function

sub floaterSpecPropBox_update (current as component)
    floaterSpecPropBox.current = current
    typeArray[current.type].status = 1

    REM ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE **
    REM We need to map the string representing the desired .focus
    REM to a component.  This mapping is done by BGadgetFloaterClass.
    REM (Actually, the BGadgetDialogClass superclass takes care of it.)
    REM Here, we're grabbing the string associated with the desired
    REM .focus component.
    focusComp.text = current.focusString
end sub


sub sp_apply()
    floaterSpecPropBox.current.type = typeArray[0].choice.value

    REM ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE ** NOTE **
    REM We need to map the string representing the desired .focus
    REM to a component.  This mapping is done by BGadgetDialogClass,
    REM the superclas of BGadgetFloaterClass.  Here, we grab the string
    REM name of the desired .focus component and assign it to the dialog's
    REM special focusString property.  BGadgetDialogClass does special 
    REM things when it see "focusString" being set.
    floaterSpecPropBox.current.focusString = focusComp.text

    if floaterSpecPropBox.current.visible then
        floaterSpecPropBox.current.visible = 0
        floaterSpecPropBox.current.visible = 1
    end if 
end sub
