sub duplo_ui_ui_ui()
 duplo_start()
end sub

sub duplo_start()
    dim powerSpecPropBox as component
    dim disableAutoSleepToggle as toggle
    dim interceptShutdownToggle as toggle

    export powerSpecPropBox

    powerSpecPropBox = MakeComponent("control","top")
    powerSpecPropBox.proto = "powerSpecPropBox"

    disableAutoSleepToggle = MakeComponent("toggle", powerSpecPropBox)
    disableAutoSleepToggle.caption = "disableAutoSleep"
    disableAutoSleepToggle.visible = 1

    interceptShutdownToggle = MakeComponent("toggle", powerSpecPropBox)
    interceptShutdownToggle.caption = "interceptShutdown"
    interceptShutdownToggle.visible = 1

end sub

function duplo_revision()

REM
REM	Copyright (c) Geoworks 1996 -- All Rights Reserved
REM
REM	FILE: 		sp-power.bas
REM	AUTHOR:		jmagasin, Mar 27, 1996
REM	DESCRIPTION:	
REM
REM	$Id: sp-power.bas,v 1.1 98/03/12 20:30:29 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = powerSpecPropBox
end function

sub powerSpecPropBox_update (current as component)
    powerSpecPropBox.current = current
    disableAutoSleepToggle.status = current.disableAutoSleep
    interceptShutdownToggle.status = current.interceptShutdown
end sub

sub sp_apply()
    dim power as component
    power = powerSpecPropBox.current
    power.disableAutoSleep = disableAutoSleepToggle.status
    power.interceptShutdown = interceptShutdownToggle.status
end sub
