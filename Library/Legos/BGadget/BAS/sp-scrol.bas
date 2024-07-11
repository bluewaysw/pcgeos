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

    dim scrollbarSpecPropBox as component
    export scrollbarSpecPropBox

    dim value as number
    dim min as number
    dim max as number
    dim inc as number
    dim thumb as number
    DIM notifyDrag as toggle

    scrollbarSpecPropBox = MakeComponent("control","top")
    scrollbarSpecPropBox.proto = "scrollbarSpecPropBox"


    value = MakeComponent("number",scrollbarSpecPropBox)
    value.caption = "value"
    value.minimum = -32768
    value.maximum = 32767
    value.visible= 1

    min = MakeComponent("number",scrollbarSpecPropBox)
    min.caption = "minimum"
    min.minimum = -32768
    min.maximum = 32767
    min.visible= 1

    max = MakeComponent("number",scrollbarSpecPropBox)
    max.caption = "maximum"
    max.minimum = -32768
    max.maximum = 32767
    max.visible= 1

    inc = MakeComponent("number",scrollbarSpecPropBox)
    inc.caption = "increment"
    inc.minimum = 1
    inc.visible= 1

    thumb = MakeComponent("number",scrollbarSpecPropBox)
    thumb.caption = "thumbSize"
    thumb.visible= 1

    notifyDrag = MakeComponent("toggle", scrollbarSpecPropBox)
    notifyDrag.caption = "notifyDrag"
    notifyDrag.visible = 1

    dim lookGroup as group
    lookGroup = MakeComponent("group", scrollbarSpecPropBox)
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
      look.captions[0] = "Spin Buttons"
      look.captions[1] = "Vertical"
      look.captions[2] = "Horizontal"
      look.visible = 1


end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	tgglctrl.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Id: sp-scrol.bas,v 1.1 98/03/12 20:30:14 martin Exp $
REM

end function

function duplo_top() as component
    duplo_top = scrollbarSpecPropBox
end function

sub scrollbarSpecPropBox_update (current as component)

    scrollbarSpecPropBox.current = current

    value.value = current.value
    min.value = current.minimum
    max.value = current.maximum
    inc.value = current.increment
    thumb.value = current.thumbSize
    notifyDrag.status = current.notifyDrag

    look.selectedItem = current.look
end sub


sub sp_apply()
    dim c as component

    c = scrollbarSpecPropBox.current

    c.visible = 0
    c.value = value.value
    c.minimum = min.value
    c.maximum = max.value
    c.increment = inc.value
    c.thumbSize = thumb.value

    IF (c.look <> look.selectedItem) THEN
	REM
	REM IF orientation changed, make sure we convert width to height and
	REM or vice versa.  Also, set the sizeHControl and sizeVControl as
        REM appropriate.
	REM

	SELECT CASE (look.selectedItem)
          CASE 0
	    REM
	    REM Ugly hack!  The best way to change the look of a scrollbar
	    REM to spin button is to make the height very small...
	    REM
	    c.height = 0
	    c.width = 0
	    c.sizeHControl = 3
	    c.sizeVControl = 3
	  CASE 1
	    c.height = c.width
	    c.sizeHControl = 3
	  CASE 2
	    c.width = c.height
	    c.sizeVControl = 3
	END SELECT
    END IF
    c.look = look.selectedItem

    c.notifyDrag = notifyDrag.status
    c.visible = 1

    scrollbarSpecPropBox_update(c)

end sub

