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
REM   RON	 6/19/95	Initial Version
REM
REM 	$Id: sp-buttn.bas,v 1.1 98/03/12 20:29:36 martin Exp $
REM
REM ********************************************

    dim buttonSpecPropBox as component
    export buttonSpecPropBox


    dim default as choice
    dim cancel as toggle
    dim destructive as choice
    dim closeDialog as toggle

    dim apply as button

    buttonSpecPropBox = MakeComponent("control","top")
    buttonSpecPropBox.proto = "buttonSpecPropBox"

    default = MakeComponent("choice", buttonSpecPropBox)
    default.caption = "default"
    default.visible = 1

    destructive = MakeComponent("choice", buttonSpecPropBox)
    destructive.caption = "destructive"
    destructive.visible = 1

    cancel = MakeComponent("toggle", buttonSpecPropBox)
    cancel.caption = "cancel"
    cancel.visible = 1

    closeDialog = MakeComponent("toggle", buttonSpecPropBox)
    closeDialog.caption = "closeDialog"
    closeDialog.visible = 1
    

rem    apply = MakeComponent("button",buttonSpecPropBox)
rem    apply.caption = "Apply"
rem    apply.default = 1
rem    apply.proto = "apply"
rem    apply.visible = 1


end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	tgglctrl.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = buttonSpecPropBox
end function

sub buttonSpecPropBox_update (current as component)

    buttonSpecPropBox.current = current

    default.status = current.default
    cancel.status = current.cancel
    destructive.status = current.destructive
    closeDialog.status = current.closeDialog

end sub


sub sp_apply ()
    dim btn as component

    btn = buttonSpecPropBox.current

    btn.cancel = cancel.status
    btn.destructive = destructive.status
    btn.closeDialog = closeDialog.status
    btn.default = default.status

    REM
    REM destructive and status need for the button to
    REM be unbuilt when they get toggled
    if btn.visible = 1 then
	btn.visible = 0
	btn.visible = 1
    end if

end sub

