sub duplo_ui_ui_ui()
duplo_start()
end sub

sub duplo_start()

REM	Copyright (c) Geoworks 1995 
REM                    -- All Rights Reserved
REM
REM	FILE: 	p-gadget.bas
REM	AUTHOR:	David Loftesness, Jun 13, 1995
REM	DESCRIPTION:
REM		This code implements the gadget library property box
REM	$Id: p-gadget.bas,v 1.1 98/03/12 20:29:51 martin Exp $
REM	Revision:   1.28
REM

    dim gadgetPropCtrl 		as control
    dim gadgetFrame 		as component		REM switchframe
    dim applyGroup 		as group
    dim applyButton 		as button
    dim titleLabel              as component
    dim triggerFrame 		as group
    dim currentSelection 	as component
    dim generalTrigger 		as button
    dim childTrigger 		as button

    dim specificTrigger 	as button
    dim specificPropCtrl 	as control
    DIM globalMod 		as module

    export gadgetPropCtrl

    gadgetPropCtrl = MakeComponent("control", "top")
    gadgetPropCtrl.proto = "gadgetPropCtrl"

REM
REM Put up our UI, namely the triggers and controllers for each sub-group
REM
    titleLabel = MakeComponent("label", gadgetPropCtrl)
       titleLabel.caption = "Properties for:  <none>"
    triggerFrame = MakeComponent("group", gadgetPropCtrl)
    	triggerFrame.tile = 1
	triggerFrame.tileLayout = 1
	triggerFrame.tileHAlign = 2
	triggerFrame.tileVAlign = 2
    generalTrigger = MakeComponent("button", triggerFrame)
       generalTrigger.proto = "propBoxButton"
       generalTrigger.caption = "General"
       generalTrigger.visible = 1
    childTrigger = MakeComponent("button", triggerFrame)
       childTrigger.proto = "propBoxButton"
       childTrigger.caption = "Children"
       childTrigger.visible = 1
    specificTrigger = MakeComponent("button", triggerFrame)
       specificTrigger.proto = "propBoxButton"
       specificTrigger.caption = "Specific"
       specificTrigger.visible = 1
    titleLabel.visible = 1
    triggerFrame.visible = 1

    gadgetFrame = MakeComponent("switchframe", gadgetPropCtrl)
       gadgetFrame.caption = ""
rem       gadgetFrame.compact = 1
       gadgetFrame.visible = 1

    applyGroup = MakeComponent("group", gadgetPropCtrl)
       applyGroup.tile = 1
       applyGroup.visible = 1
    applyButton = MakeComponent("button", applyGroup)
       applyButton.caption = "Apply"
       applyButton.proto = "apply"
       applyButton.default = 1
       applyButton.visible = 1

    propBoxButton_pressed(generalTrigger)

end sub

function duplo_top() as component
REM
REM Return the top level component for this module
REM
	duplo_top = gadgetPropCtrl

end function

sub gadgetPropCtrl_update(current as component)
  dim specURL as string
    
    titleLabel.caption = "Properties for:  " + current.name+ " ("+current.class +")"

    gadgetPropCtrl.current = current

    if (HasProperty(current, "tile") and not (current.class = "table" or current.class = "gadget")) then
	childTrigger.enabled = 1
    else 
	childTrigger.enabled = 0
    end if

    IF (current.specPropBoxURL = "none") then
	specificTrigger.enabled = 0
    ELSE
	specificTrigger.enabled = 1
    END IF

    REM ***********************************************************
    REM *	Check if the specific or general property box is visible and 
    REM *	displaying the proper UI for the current component.
    REM ***********************************************************

    IF (currentSelection.caption = "Specific") OR \
	(currentSelection.caption = "General") then
	propBoxButton_pressed(currentSelection)
    END if
	
end sub

sub propBoxButton_pressed (self as component)
REM
REM  SYNOPSIS:	Code to load the properties controller when the
REM		the property group button is pressed on.
REM	
REM  CALLED BY:	duplo
REM  PASS:	nothing
REM  RETURN:	nothing
REM
REM  REVISION HISTORY
REM   Name	Date		Description
REM   ----	----		-----------
REM   martin	12/28/94	Initial Version

 dim URL	as string
 DIM selected	as component

  IF HasProperty(gadgetPropCtrl, "current") then
    selected = gadgetPropCtrl.current
    select CASE self.caption
     CASE "Specific"
      URL = selected.specPropBoxURL
     CASE "General"
      URL = GeneralUrl(selected.class)
     case "Children"
      URL = "DOS://~U/BASIC/LP-CHILD"
    END select
  ELSE
    REM  Not sure what this should be, but it works for now I guess
    URL = "DOS://~U/BASIC/NONESEL"
  END IF

    currentSelection = self

    doSwitch(URL)
end sub

function GeneralUrl(className as string)
  REM Return the correct general property box for different
  REM types of components

  select case className
   case "button","choice","dialog","form","group","label","list","number","popup","scrollbar","toggle"
    REM UI components
    GeneralUrl = "DOS://~U/BASIC/LP-GEN"

   case "clipper","floater","gadget","picture","spacer"

    REM Primitive UI components
    GeneralUrl = "DOS://~U/BASIC/LP-GEN"
    
   case "text","entry","table"
    REM Random other components
    GeneralUrl = "DOS://~U/BASIC/LP-GEN"

   case "alarm","clipboard","timedate","timer"
    REM currently-implemented service components
    GeneralUrl = "DOS://~U/BASIC/LP-SERV"

   case else
    REM probably an aggregate, just use the service box for now
    GeneralUrl = "DOS://~U/BASIC/LP-SERV"
  end select
end function

sub doSwitch(url as string)
    if (url = "none") then
rem	gadgetFrame!close()
	propBoxButton_pressed(generalTrigger)
    ELSE
REM
REM This is a horrible hack... because SP-TEXT has its own special apply 
REM button, we need TO turn ours off when we load it...
REM
	IF (url = "DOS://~U/BASIC/SP-TEXT") THEN
	    applyGroup.visible = 0
	ELSE
	    applyGroup.visible = 1
	END IF

	globalMod = gadgetFrame!switchTo(url)
    end if

rem    specificTrigger.caption = url

end sub

sub apply_pressed(self as button)
    REM back door TO get the at the child trigger
    REM heh heh heh, "back door"
    REM
    IF (gadgetPropCtrl.current.proto = "ftpoomm") THEN
	childTrigger.visible = 1
    ELSE
	globalMod:sp_apply()
    END IF
END sub
