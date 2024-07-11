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
REM   jmagasin	 1/17/96	Initial Version
REM
REM	$Id: sp-choic.bas,v 1.1 98/03/12 20:29:54 martin Exp $
REM
REM ********************************************

    dim choiceSpecPropBox as component
    export choiceSpecPropBox

    choiceSpecPropBox = MakeComponent("control","top")
    choiceSpecPropBox.proto = "choiceSpecPropBox"

    dim lookGroup as group
    lookGroup = MakeComponent("group", choiceSpecPropBox)
      lookGroup.name    = "lookGroup"
      lookGroup.tile = 1
      lookGroup.tileLayout = 1
      lookGroup.tileHAlign = 1
      lookGroup.visible = 1

    dim lookLabel as label
    lookLabel = MakeComponent("label", lookGroup)
      lookLabel.name    = "lookLabel"
      lookLabel.caption = "Look:"
      lookLabel.visible = 1

    dim look as list
    look = MakeComponent("list", lookGroup)
      look.name    = "look"
      look.proto   = "look"
      look.look = 0
      look.captions[0] = "Radio Button"
      look.captions[1] = "Tool Button"
      look.visible = 1

    dim statusGroup as component
    dim statusOn as component
    dim statusOff as component

    statusGroup = MakeComponent("group", choiceSpecPropBox)
      statusGroup.name = "status"
      statusGroup.caption = "Status:"
      statusGroup.look = 1
      statusGroup.tile = 1
      statusGroup.tileLayout = 1
      statusGroup.visible = 1
    
    statusOn = MakeComponent("choice", statusGroup)
      statusOn.name = "statusOn"
      statusOn.proto = "statusOn"
      statusOn.caption = "On"
      statusOn.status = 0
      statusOn.visible = 1
    statusOff = MakeComponent("choice", statusGroup)
      statusOff.caption = "Off"
      statusOff.status = 1
      statusOff.visible = 1

   dim sampleGroup as component
   dim sampleChoice as component

   sampleGroup = MakeComponent("group", choiceSpecPropBox)
      sampleGroup.look = 2
      sampleGroup.visible = 1
   sampleChoice = MakeComponent("choice", sampleGroup)
      sampleChoice.caption = "Sample"
      sampleChoice.visible = 1

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1996
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-choice.bas
REM	AUTHOR:	Jonathan Magasin, Jan 17, 1996
REM	jmagasin
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = choiceSpecPropBox
end function

sub choiceSpecPropBox_update (current as component)
    choiceSpecPropBox.current = current

    choiceSpecPropBox.current = current
    if current.status = 0 then
	statusOff.status = 1
    else
	statusOn.status = 1
    end if
    look.selectedItem = current.look
    updateLookSample(current.look)
    sampleChoice.status = statusOn.status
end sub

sub look_changed(self as list, index as integer)
    updateLookSample(self.selectedItem)
end sub

sub statusOn_changed(self as choice)
    sampleChoice.status = statusOn.status
end sub

sub updateLookSample(look as integer)
    sampleChoice.look = look
    sampleChoice.visible = 0
    sampleChoice.visible = 1
end sub

sub sp_apply()
 dim current as component
 dim tempVis as integer

  current = choiceSpecPropBox.current
  tempVis = current.visible
  current.visible = 0

  current.status = statusOn.status
  current.look = look.selectedItem

  current.visible = tempVis

end sub
