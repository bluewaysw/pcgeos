
sub duplo_ui_ui_ui()
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
REM   bkurtin    8/96           Bug fixes and reorganization.
REM
REM	$Id: sp-ink.bas,v 1.1 98/03/12 20:29:56 martin Exp $
REM
REM ********************************************

    dim inkSpecPropBox as control


    dim cmgroup as group
    dim canvasModeChoice as choice
    dim analysisModeChoice as choice
    dim eraseModeChoice as choice

    dim sbgroup as group
    dim untilTimeOutChoice as choice
    dim untilTimeOutOrTappedOutsideChoice as choice

    inkSpecPropBox = MakeComponent("control","top")
    inkSpecPropBox.proto = "inkSpecPropBox"

    cmgroup = MakeComponent("group", inkSpecPropBox)
    cmgroup.caption = "Collection Mode"
    cmgroup.look = 1
    cmgroup.visible = 1
    cmgroup.proto = "cmgroup"
    cmgroup.tile = 1
    cmgroup.tileHAlign = 2 REM left justify
    cmgroup.sizeHControl = 2 REM As big as possible.

    sbgroup = MakeComponent("group", inkSpecPropBox)
    sbgroup.caption = "Stroke Behavior"
    sbgroup.look = 1
    sbgroup.visible = 1
    sbgroup.proto = "sbgroup"
    sbgroup.tile = 1
    sbgroup.tileHAlign = 2 REM left justify

    canvasModeChoice = MakeComponent("choice", cmgroup)
    canvasModeChoice.caption = "Canvas"
    canvasModeChoice.status = 0
    canvasModeChoice.visible = 1
    canvasModeChoice.proto = "cmchoice"

    analysisModeChoice = MakeComponent("choice", cmgroup)
    analysisModeChoice.caption = "Analysis"
    analysisModeChoice.status = 0
    analysisModeChoice.visible = 1
    analysisModeChoice.proto = "cmchoice"

    eraseModeChoice = MakeComponent("choice", cmgroup)
    eraseModeChoice.caption = "Erase"
    eraseModeChoice.status = 0
    eraseModeChoice.visible = 1
    eraseModeChoice.proto = "cmchoice"

    untilTimeOutChoice = MakeComponent("choice", sbgroup)
    untilTimeOutChoice.caption = "Until Time-Out"
    untilTimeOutChoice.status = 0
    untilTimeOutChoice.visible = 1
    untilTimeOutChoice.proto = "sbchoice"

    untilTimeOutOrTappedOutsideChoice = MakeComponent("choice", sbgroup)
    untilTimeOutOrTappedOutsideChoice.caption = "Until Time-Out or Tapped Outside"
    untilTimeOutOrTappedOutsideChoice.status = 0
    untilTimeOutOrTappedOutsideChoice.visible = 1
    untilTimeOutOrTappedOutsideChoice.proto = "sbchoice"
duplo_start()
end sub

sub duplo_start()
    export inkSpecPropBox

  dim curCollectionMode as integer
  dim curStrokeBehavior as integer

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
    duplo_top = inkSpecPropBox
end function

sub inkSpecPropBox_update(current as component)
    inkSpecPropBox.current = current

    curCollectionMode = current.collectionMode
    curStrokeBehavior = current.strokeBehavior

    select case curCollectionMode
      case 0
	canvasModeChoice.status = 1
      case 1
	analysisModeChoice.status = 1
      case 2
	eraseModeChoice.status = 1
    end select

    select case curStrokeBehavior
      case 1
	untilTimeOutChoice.status = 1
      case 2
	untilTimeOutOrTappedOutsideChoice.status = 1
    end select
end sub

sub cmchoice_changed(self as choice)
    self.status = 1

    select case self
      case canvasModeChoice
	curCollectionMode = 0
      case analysisModeChoice
	curCollectionMode = 1
      case eraseModeChoice
	curCollectionMode = 2
    end select
end sub

sub sbchoice_changed(self as choice)
    self.status = 1

    select case self
      case untilTimeOutChoice
	curStrokeBehavior = 1
      case untilTimeOutOrTappedOutsideChoice
	curStrokeBehavior = 2
    end select
end sub

sub sp_apply()
    inkSpecPropBox.current.collectionMode = curCollectionMode
    inkSpecPropBox.current.strokeBehavior = curStrokeBehavior
end sub



