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

    dim numberSpecPropBox as component
    export numberSpecPropBox

    dim val as number
    dim min as number
    dim max as number
    dim inc as number

    numberSpecPropBox = MakeComponent("control","top")
    numberSpecPropBox.proto = "numberSpecPropBox"

    dim lookGroup as group
    lookGroup = MakeComponent("group", numberSpecPropBox)
    lookGroup.tile = 1
    lookGroup.tileLayout = 1
    lookGroup.tileHAlign = 1
    lookGroup.visible = 1

    dim lookLabel as label
    lookLabel = MakeComponent("label", lookGroup)
    lookLabel.caption = "Look:"
    lookLabel.visible = 1

    dim look as list
    look = MakeComponent("list", lookGroup)
    look.proto   = "look"
    look.look = 0
    look.captions[0] = "Spinner"
    look.captions[1] = "Horizontal Slider"
    look.captions[2] = "Vertical Slider"
    look.visible = 1

    dim format as list
    dim flabel as label
    dim fgroup as group

    REM make a group for the format list and label
    fgroup = MakeComponent("group",numberSpecPropBox)
    fgroup.tile = 1
    fgroup.tileLayout = 1
    fgroup.tileHAlign = 1
    fgroup.visible = 1

    REM make the format label
    flabel = MakeComponent("label",fgroup)
    flabel.name = "formatLabel"
    flabel.caption = "Format:"
    flabel.visible = 1

    REM make the format list
    format = MakeComponent("list",fgroup)
    format.proto = "format"
    format.look = 0
    format.captions[0] = "integer"
    format.captions[1] = "decimal"
    format.captions[2] = "points"
    format.captions[3] = "in"
    format.captions[4] = "cm"
    format.captions[5] = "mm"
    format.captions[6] = "picas"
    format.captions[7] = "Euro pts"
    format.captions[8] = "ciceros"
    format.captions[9] = "points or mm"
    format.captions[10] = "in or cm"
    format.visible = 1

    val = MakeComponent("number",numberSpecPropBox)
    val.caption = "value"
    val.proto = "val"
    val.minimum = -32768
    val.maximum = 32767
    val.visible = 1

    min = MakeComponent("number",numberSpecPropBox)
    min.caption = "minimum"
    min.proto = "min"
    min.minimum = -32768
    min.maximum = 32767
    min.visible = 1

    max = MakeComponent("number",numberSpecPropBox)
    max.caption = "maximum"
    max.proto = "max"
    max.minimum = -32768
    max.maximum = 32767
    max.visible = 1

    inc = MakeComponent("number",numberSpecPropBox)
    inc.caption = "increment"
    inc.proto = "inc"
    inc.minimum = 1
    inc.visible = 1

    dim sampleGroup as group
    dim sample as number
    sampleGroup = MakeComponent("group",numberSpecPropBox)
    sampleGroup.name = "sampleGroup"
    sampleGroup.proto = "sampleGroup"
    sampleGroup.caption = "sample"
    sampleGroup.look = 1
    sampleGroup.visible = 1
    sample = MakeComponent("number",sampleGroup)
    sample.name  = "sample"
    sample.proto = "sample"
    sample.visible = 1

end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	tgglctrl.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Id: sp-numbr.bas,v 1.1 98/03/12 20:30:00 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = numberSpecPropBox
end function

sub numberSpecPropBox_update (current as component)

    numberSpecPropBox.current = current

    val.value = current.value
    min.value = current.minimum
    max.value = current.maximum
    inc.value = current.increment
    format.selectedItem = current.displayFormat
    look.selectedItem = current.look
    update_sample(current.look)
    sample.displayFormat = current.displayFormat
    sample.value = current.value
    sample.minimum = current.minimum
    sample.maximum = current.maximum
    sample.increment = current.increment
end sub


sub sp_apply()
    dim tval as component

    tval = numberSpecPropBox.current
    tval.value = val.value
    tval.minimum = min.value
    tval.maximum = max.value
    tval.increment = inc.value
    tval.displayFormat = format.selectedItem
    tval.look = look.selectedItem
    tval.visible = 0
    tval.visible = 1

end sub

sub look_changed(self as list, index as integer)

    update_sample(index)

end sub

sub format_changed(self as list, index as integer)
    sample.displayFormat = index
end sub

sub val_changed(self as number, value as integer)
    sample.value = value
end sub
    
sub min_changed(self as number, value as integer)
    sample.minimum = value
    val.minimum = value
    max.minimum = value
end sub

sub max_changed(self as number, value as integer)
    sample.maximum = value
    val.maximum = value
    min.maximum = value
end sub

sub inc_changed(self as number, value as integer)
    sample.increment = value
end sub

sub update_sample(newLook as integer)
    sample.look = newLook
    sample.visible = 0
    sample.visible = 1
end sub
