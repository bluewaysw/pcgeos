
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
REM	$Id: sp-group.bas,v 1.1 98/03/12 20:29:21 martin Exp $
REM
REM ********************************************

    dim groupSpecPropBox as control
    export groupSpecPropBox


    groupSpecPropBox = MakeComponent("control","top")
    groupSpecPropBox.proto = "groupSpecPropBox"

    dim lookGroup as group
    lookGroup = MakeComponent("group", groupSpecPropBox)
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
      look.captions[0] = "Normal"
      look.captions[1] = "In Box"
      look.captions[2] = "No Caption"
      look.visible = 1

    dim sample as group
    sample = MakeComponent("group", groupSpecPropBox)
      sample.name = "sample"
      sample.proto = "sample"
      sample.caption = "Caption"
      sample.look = 1
      sample.visible = 1

    dim sampleLabel as label
    sampleLabel = MakeComponent("label", sample)
      sampleLabel.name = "sampleLabel"
      sampleLabel.proto = "sampleLabel"
      sampleLabel.caption = "Sample"
      sampleLabel.visible = 1


end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-group.bas
REM	AUTHOR:	RON, Aug 22, 1995
REM	RON
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = groupSpecPropBox
end function

sub groupSpecPropBox_update(current as component)

    groupSpecPropBox.current = current
    look.selectedItem = current.look
    update_sample(current.look)
end sub

sub look_changed(self as list, index as integer)

    update_sample(self.selectedItem)
    
end sub

sub sp_apply()

    groupSpecPropBox.current.look = look.selectedItem
    groupSpecPropBox.current.visible = 0
    groupSpecPropBox.current.visible = 1

end sub

sub update_sample(newLook as integer)
    sample.look = newLook
    sample.visible = 0
    sample.visible = 1
end sub
