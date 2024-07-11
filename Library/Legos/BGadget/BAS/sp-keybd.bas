sub duplo_ui_ui_ui()
REM
REM	$Id: sp-keybd.bas,v 1.1 98/03/12 20:30:33 martin Exp $
REM
 duplo_start()
end sub

sub duplo_start()
    dim keyboardSpecPropBox as component
    dim focusInterestToggle as toggle

    export keyboardSpecPropBox

    keyboardSpecPropBox = MakeComponent("control","top")
    keyboardSpecPropBox.proto = "keyboardSpecPropBox"

    focusInterestToggle = MakeComponent("toggle", keyboardSpecPropBox)
    focusInterestToggle.caption = "focusInterest"
    focusInterestToggle.visible = 1

end sub

function duplo_revision()

REM
REM	Copyright (c) Geoworks 1996 -- All Rights Reserved
REM
REM	FILE: 		sp-keybd.bas
REM	AUTHOR:		jmagasin, April 5, 1996
REM	DESCRIPTION:	
REM
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = keyboardSpecPropBox
end function

sub keyboardSpecPropBox_update (current as component)
    keyboardSpecPropBox.current = current
    focusInterestToggle.status = current.focusInterest
end sub

sub sp_apply()
    dim keybd as component
    keybd = keyboardSpecPropBox.current
    keybd.focusInterest = focusInterestToggle.status
end sub
