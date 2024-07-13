sub duplo_ui_ui_ui()
duplo_start()
end sub

sub duplo_start()
REM ========================================================================
REM
REM     Copyright (c) Geoworks 1994 
REM                    -- All Rights Reserved
REM
REM     PROJECT:        UI Builder
REM     FILE:           propctrl.bas
REM
REM     AUTHOR:         Martin Turon, December 21, 1994
REM
REM     REVISION HISTORY
REM             Name    Date            Description
REM             ----    ----            -----------
REM             martin  12/21/94        Initial Version
REM
REM     DESCRIPTION:
REM             This code implements the basic property box for 
REM             components.  Eventually, this will be split up into
REM             smaller modules that will deal with properties of each
REM             class level (Ent, Gool, GoolGeom, etc.) seperately.
REM
REM	$Id: propctrl.bas,v 1.1 97/12/02 14:57:13 gene Exp $
REM     $Revision: 1.1 $
REM
REM ======================================================================


REM *********************************************************************
REM *           Define This Module's Components
REM **********************************************************************

	dim propertyCtrl as component

	export  propertyCtrl

	dim     propertyGroup           as component
	dim     propertyBoxUI           as component

	propertyCtrl = MakeComponent("control", "top")
	  propertyCtrl.proto = "propertyCtrl"

	propertyGroup           = MakeComponent("switchframe", propertyCtrl)
	  propertyGroup.proto   = "propertyGroup"
rem       propertyGroup.caption = "Properties for:  <none>"
	  propertyGroup.orient  = 1
	  propertyGroup.justifychildren = 160
	  propertyGroup.compact = 1
	  propertyGroup.visible = 1

end sub

function duplo_top() as component
    REM Return the top level component for this module

	duplo_top = propertyCtrl

end function

sub propertyCtrl_update (current as component)
REM
REM  SYNOPSIS:  Code to update the UI of this controller
REM     
REM  CALLED BY: control component
REM  PASS:      current = component whose properties we want to reflect
REM
REM  REVISION HISTORY
REM   Name      Date            Description
REM   ----      ----            -----------
REM   martin    12/21/94        Initial Version

    dim url as string

    REM ***********************************************************
    REM *       Store current component for later use,
    REM *       update name field, and switch to the correct
    REM *       library property group for this component
    REM ***********************************************************
rem        propertyGroup.caption = "Properties for:  " + current.name
	propertyCtrl.current  = current

	if (HasProperty(current, "libPropBoxURL")) then
	    REM
	    REM actions don't support TYPE_PROPERTY_LV yet, so copy the
	    REM url into a local string and then pass it in
	    REM
	    url = current.libPropBoxURL
	    propertyGroup.switchTo(url)
	    propertyGroup.visible = 1
	else
	    propertyGroup.visible = 0
	end if

end sub
