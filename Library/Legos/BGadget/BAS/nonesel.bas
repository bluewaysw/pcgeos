sub duplo_ui_ui_ui()
duplo_start()
end sub

sub duplo_start()
  dim dummyPropControl as control
    dummyPropControl = MakeComponent("control", "top")

  dim noLabel as label
    noLabel = MakeComponent("label", "dummyPropControl")
    noLabel.caption = "No selected component"
end sub

sub sp_apply()
end sub

function duplo_revision()

REM
REM	Copyright (c) Geoworks 1996 -- All Rights Reserved
REM
REM	FILE: 		nonesel.bas
REM	AUTHOR:		RON, Mar 29, 1996
REM	DESCRIPTION:	Empty property box to indicate no selection.
REM
REM	$Id: nonesel.bas,v 1.1 98/03/12 20:30:31 martin Exp $
REM

end function

function duplo_top() as component
REM
REM Return the top level component for this module
REM
	duplo_top = dummyPropControl

end function
