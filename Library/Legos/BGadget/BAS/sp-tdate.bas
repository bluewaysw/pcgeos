sub duplo_ui_ui_ui()
duplo_start()
end sub

sub duplo_start()
  DIM timedateSpecPropBox as component
  DIM timeInterest as number

    export timedateSpecPropBox

    timedateSpecPropBox = MakeComponent("control","top")
    timedateSpecPropBox.proto = "timedateSpecPropBox"

    timeInterest = MakeComponent("number", timedateSpecPropBox)
    timeInterest.caption = "Time interest"
    timeInterest.minimum = 0
    timeInterest.maximum = 60
    timeInterest.visible = 1

end sub

function duplo_revision()

REM
REM	Copyright (c) Geoworks 1995 -- All Rights Reserved
REM
REM	FILE:		sp-tdate.bas
REM	AUTHOR:		Paul Du Bois, Sep 21, 1995
REM	DESCRIPTION:	Specific prop box for timedate compo
REM
REM $Id: sp-tdate.bas,v 1.1 98/03/12 20:30:35 martin Exp $

end function

function duplo_top() as component
    duplo_top = timedateSpecPropBox
end function

sub timedateSpecPropBox_update (current as component)

    timedateSpecPropBox.current = current
    timeInterest.value = current.timeInterest

end sub

sub sp_apply()
    dim current as component
    current = timedateSpecPropBox.current
    current.timeInterest = timeInterest.value
    timedateSpecPropBox_update(current)
end sub

