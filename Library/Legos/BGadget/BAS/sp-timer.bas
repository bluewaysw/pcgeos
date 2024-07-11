sub duplo_ui_ui_ui()
 duplo_start()
end sub

sub duplo_start()
    DIM timerSpecPropBox as component
    dim interval as number

    export timerSpecPropBox

    timerSpecPropBox = MakeComponent("control","top")
    timerSpecPropBox.proto = "timerSpecPropBox"

    interval = MakeComponent("number", timerSpecPropBox)
    interval.caption = "interval"
    interval.minimum = 1
    interval.visible = 1

end sub

function duplo_revision()

REM
REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
REM
REM	FILE: 		sp-timer.bas
REM	AUTHOR:		dubois, Sep 22, 1995
REM	DESCRIPTION:	
REM
REM	$Id: sp-timer.bas,v 1.1 98/03/12 20:30:25 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = timerSpecPropBox
end function

sub timerSpecPropBox_update (current as component)
    timerSpecPropBox.current = current
    interval.value = current.interval
end sub

sub sp_apply()
    dim timer as component
    timer = timerSpecPropBox.current
    timer.interval = interval.value
    timerSpecPropBox_update(timer)
end sub
