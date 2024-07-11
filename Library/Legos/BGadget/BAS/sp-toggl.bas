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
REM ********************************************

    dim toggleSpecPropBox as component
    export toggleSpecPropBox

    dim statusOn as component
    dim statusOff as component
    dim statusGroup as component

    toggleSpecPropBox = MakeComponent("control","top")
    toggleSpecPropBox.proto = "toggleSpecPropBox"
    
    statusGroup = MakeComponent("group", toggleSpecPropBox)
    statusGroup.caption = "Status:"
    statusGroup.look = 1
    statusGroup.tile = 1
    statusGroup.tileLayout = 1
    statusGroup.visible = 1

    statusOn = MakeComponent("choice", statusGroup)
    statusOn.caption = "On"
    statusOn.status = 0
    statusOn.visible = 1
    statusOff = MakeComponent("choice", statusGroup)
    statusOff.caption = "Off"
    statusOff.status = 1
    statusOff.visible = 1

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	tgglctrl.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Id: sp-toggl.bas,v 1.1 98/03/12 20:30:20 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = toggleSpecPropBox
end function

sub toggleSpecPropBox_update (current as component)

    toggleSpecPropBox.current = current
    if current.status = 0 then
        statusOff.status = 1
    else
        statusOn.status = 1
    end if

end sub


sub sp_apply()
    toggleSpecPropBox.current.status = statusOn.status
end sub
