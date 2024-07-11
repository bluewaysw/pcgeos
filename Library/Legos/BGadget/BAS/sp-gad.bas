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
REM   jimmy	 6/19/95	Initial Version
REM
REM	$Id: sp-gad.bas,v 1.1 98/03/12 20:30:06 martin Exp $
REM
REM ********************************************

    dim gadgetSpecPropBox as component
    export gadgetSpecPropBox

    REM Set up the penInterest property.
    DIM mouseGroup as group
    DIM interest[3] as choice

    CONST NO_INTEREST 0
    CONST IN_OUT_INTEREST 1
    CONST ALL_INTEREST 2

    gadgetSpecPropBox = MakeComponent("control","top")
    gadgetSpecPropBox.proto = "gadgetSpecPropBox"

    dim mouseInterestGroup as group
    mouseInterestGroup = MakeComponent("group", gadgetSpecPropBox)
      mouseInterestGroup.name    = "mouseInterestGroup"
      mouseInterestGroup.tile = 1
      mouseInterestGroup.tileLayout = 1
      mouseInterestGroup.tileHAlign = 1
      mouseInterestGroup.visible = 1

    dim mouseInterestLabel as label
    mouseInterestLabel = MakeComponent("label", mouseInterestGroup)
      mouseInterestLabel.name    = "mouseInterestLabel"
      mouseInterestLabel.caption = "MouseInterest:"
      mouseInterestLabel.visible = 1

    dim mouseInterest as list
    mouseInterest = MakeComponent("list", mouseInterestGroup)
      mouseInterest.look = 2
      mouseInterest.name    = "mouseInterest"
      mouseInterest.proto   = "mouseInterest"
      mouseInterest.captions[0] = "None"
      mouseInterest.captions[1] = "Enter-Exit"
      mouseInterest.captions[2] = "All"
      mouseInterest.visible = 1
    

REM Set up UI for changing clipboardable API properties.

    dim clipGroup as group
    clipGroup = MakeComponent("group", gadgetSpecPropBox)
      clipGroup.name    = "clipGroup"
      clipGroup.tile = 1
      clipGroup.tileLayout = 1
      clipGroup.tileHAlign = 1
      clipGroup.left = 10
      clipGroup.visible = 1

    dim clipLabel as label
    clipLabel = MakeComponent("label", clipGroup)
      clipLabel.name    = "clipLabel"
      clipLabel.caption = "Clipboardable API:"
      clipLabel.visible = 1

CONST FOCUSABLE 0, CLIPBOARDABLE 1, DELETABLE 2, COPYABLE 3
    dim clipList as list
    clipList = MakeComponent("list", clipGroup)
      clipList.name    = "clipList"
      clipList.proto   = "clipList"
      clipList.look = 2
      clipList.behavior = 2
      clipList.captions[FOCUSABLE] = "focusable"
      clipList.captions[CLIPBOARDABLE] = "clipboardable"
      clipList.captions[DELETABLE] = "deletable"
      clipList.captions[COPYABLE] = "copyable"
      clipList.visible = 1

    
end sub

function duplo_revision()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	sp-gad.bas
REM	AUTHOR:	Ronald Braunstein, Jun 19, 1995
REM	RON
REM	$Revision: 1.1 $
REM

end function

function duplo_top() as component
    duplo_top = gadgetSpecPropBox
end function

sub gadgetSpecPropBox_update (current as component)
    gadgetSpecPropBox.current = current
    mouseInterest.selectedItem = current.mouseInterest

    rem Update the clipboardable API.
	REM Update the clipboardable API.
   dim i as integer
    for i = 0 to 3
    select case i
      case FOCUSABLE
       clipList.selections[i] = current.focusable
      case CLIPBOARDABLE
        clipList.selections[i] = current.clipboardable
      case DELETABLE
       clipList.selections[i] = current.deletable
      case COPYABLE
       clipList.selections[i] = current.copyable
    end select
    next
end sub


sub sp_apply()
    gadgetSpecPropBox.current.mouseInterest = mouseInterest.selectedItem

    rem Change the clipboardable properties.
   dim i as integer
    for i = 0 to 3
    select case i
      case FOCUSABLE
       gadgetSpecPropBox.current.focusable = clipList.selections[i]
      case CLIPBOARDABLE
	gadgetSpecPropBox.current.clipboardable = clipList.selections[i]
      case DELETABLE
        gadgetSpecPropBox.current.deletable = clipList.selections[i]
      case COPYABLE
        gadgetSpecPropBox.current.copyable = clipList.selections[i]
    end select
    next

end sub

