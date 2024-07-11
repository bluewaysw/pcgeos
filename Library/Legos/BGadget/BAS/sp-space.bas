
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

    dim spacerSpecPropBox as control
    export spacerSpecPropBox

    spacerSpecPropBox = MakeComponent("control","top")
    spacerSpecPropBox.proto = "spacerSpecPropBox"


    dim lookGroup as group
    lookGroup = MakeComponent("group", spacerSpecPropBox)
    CompInit lookGroup
      name    = "lookGroup"
      tile = 1
      tileLayout = 1
      tileHAlign = 1
      visible = 1
    end CompInit

    dim lookLabel as label
    lookLabel = MakeComponent("label", lookGroup)
    CompInit lookLabel
      name    = "lookLabel"
      caption = "Look:"
      visible = 1
    end CompInit

    dim lookList as list
    lookList = MakeComponent("list", lookGroup)
      lookList.name    = "lookList"
      lookList.proto   = "lookList"
      lookList.captions[0] = "Blank"
      lookList.captions[1] = "Black"
      lookList.captions[2] = "White"
      lookList.captions[3] = "Dotted Line"
      lookList.captions[4] = "3D In"
      lookList.captions[5] = "3D Out"
      lookList.look = 2
      lookList.visible = 1

    dim sampleGroup as group
    sampleGroup = MakeComponent("group", spacerSpecPropBox)
    CompInit sampleGroup
      name = "sampleGroup"
      tile = 1
      visible = 1
    end CompInit

    dim sampleLabel as label
    sampleLabel = MakeComponent("label", sampleGroup)
    CompInit sampleLabel
      name = "sampleLabel"
      caption = "Sample"
      visible = 1
    end CompInit

   dim sampleSpacer as spacer
   sampleSpacer = MakeComponent("spacer", sampleGroup)
   CompInit sampleSpacer
       name = "sampleSpacer"
       proto = "sampleSpacer"
       sizeHControl = 3
       visible = 1
   end CompInit

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-group.bas
REM	AUTHOR:	RON, Aug 22, 1995
REM	RON
REM	$Id: sp-space.bas,v 1.1 98/03/12 20:30:04 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = spacerSpecPropBox
end function

sub spacerSpecPropBox_update(current as component)

    spacerSpecPropBox.current = current
    lookList.selectedItem = current.look
    update_sample(current.look)

end sub

sub lookList_changed(self as list, index as integer)
    update_sample(self.selectedItem)
end sub

sub update_sample(newLook as integer)
    sampleSpacer.visible = 0
    sampleSpacer.look = newLook
    sampleSpacer.visible = 1
end sub

sub sp_apply()
  spacerSpecPropBox.current.visible = 0
  spacerSpecPropBox.current.look = lookList.selectedItem
  spacerSpecPropBox.current.visible = 1
REM
REM This is needed because of the common apply trigger in p-gadget...
REM
END sub
