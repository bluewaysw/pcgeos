sub duplo_ui_ui_ui()

    dim listSpecPropBox as component

    listSpecPropBox = MakeComponent("control","top")
      listSpecPropBox.proto = "listSpecPropBox"

    dim labelGroup as group
    labelGroup = MakeComponent("group", listSpecPropBox)
      labelGroup.visible = 1

    dim niLabel as label
    niLabel = MakeComponent("label", labelGroup)
      niLabel.caption = "Number of Visible Items:"
      niLabel.visible = 1

    dim numItems as number
    numItems = MakeComponent("number", labelGroup)
      numItems.visible = 1
      numItems.proto = "numItems"

    dim behaviorGroup as group
    behaviorGroup = MakeComponent("group", listSpecPropBox)
      behaviorGroup.visible = 1

    dim bLabel as label
    bLabel = MakeComponent("label", behaviorGroup)
      bLabel.caption = "Behavior:"
      bLabel.visible = 1

    dim behavior as number
    behavior = MakeComponent("number", behaviorGroup)
      behavior.visible = 1
      behavior.proto = "behavior"

duplo_start()

end sub

sub duplo_start()
REM ********************************************
REM		duplo_start
REM ********************************************
REM
REM  SYNOPSIS:	Explicitly write any necessary code 
REM		that the builder won't spit out
REM		automatically.
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

    export listSpecPropBox

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-slist.bas
REM	AUTHOR:	RON, Aug 14, 1995
REM	RON
REM	$Id: sp-slist.bas,v 1.1 98/03/12 20:30:27 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = listSpecPropBox
end function

sub listSpecPropBox_update (current as list)

    listSpecPropBox.current = current
    behavior.value = current.behavior
    numItems.value = current.numVisibleItems

end sub

sub numItems_changed(self as number, number as integer)
REM ********************************************
REM		numItems_changed
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
REM   RON	8/14/95	Initial Version
REM
REM ********************************************
    

    listSpecPropBox.current.numVisibleItems = number

end sub

sub behavior_changed(self as number, number as integer)
REM ********************************************
REM		behavior_changed
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
REM   RON	8/14/95	Initial Version
REM
REM ********************************************

    listSpecPropBox.current.behavior = number

end sub

