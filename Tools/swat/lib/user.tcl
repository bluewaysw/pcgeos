##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	swat/lib
# FILE: 	user.tcl
# AUTHOR: 	Doug Fults, May  5, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	doug	5/ 5/89		Initial Revision
#
# DESCRIPTION:
#	Misc NEW_UI functions
#
#	$Id: user.tcl,v 3.4 90/03/26 23:15:15 andrew Exp $
#
###############################################################################


[defdsubr systemobj {} output|ui
{Prints out address of the uiSystemObj}
{
    var system ui::uiSystemObj
    var addr ^l[value fetch $system.OD_handle]:[value fetch $system.OD_chunk]
    return $addr
}]


[defdsubr flowobj {} output|ui
{Prints out address of the uiFlowObj}
{
    var flow ui::uiFlowObj
    var addr ^l[value fetch $flow.OD_handle]:[value fetch $flow.OD_chunk]
    return $addr
}]


[defdsubr impliedwin {} output|ui
{Prints out address of the current implied window}
{
    # Returns implied window handle
    return ^h[value fetch ([flowobj]).ui::FI_impliedMouseGrab.ui::G_gWin]
}]

[defdsubr impliedgrab {} output|ui
{Prints out address of the current implied grab}
{
    # Returns object holding implied mouse grab
    return ^l[value fetch ([flowobj]).ui::FI_impliedMouseGrab.ui::G_OD.OD_handle]:[value fetch ([flowobj]).ui::FI_impliedMouseGrab.ui::G_OD.OD_chunk]
}]

[defdsubr screenwin {} output|ui
{Prints out address of the current top-most screen window}
{
    # returns top-most screen window
    var addr [systemobj]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    var addr ^l[value fetch ($addr).ui::VCI_comp.CP_firstChild.OD_handle]:[value fetch ($addr).ui::VCI_comp.CP_firstChild.OD_chunk]
    var addr ($addr)+[value fetch ($addr).ui::Vis_offset]
    return ^h[value fetch ($addr).ui::VCI_gWin]
}]

[defdsubr fieldwin {} output|ui
{Prints out address of the current top-most field window}
{
    # returns top-most field window
    var addr [systemobj]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    var addr ^l[value fetch ($addr).VCI_comp.CP_firstChild.OD_handle]:[value fetch ($addr).VCI_comp.CP_firstChild.OD_chunk]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    var addr ^l[value fetch ($addr).VCI_comp.CP_firstChild.OD_handle]:[value fetch ($addr).VCI_comp.CP_firstChild.OD_chunk]
    var addr ($addr)+[value fetch ($addr).Vis_offset]
    return ^h[value fetch ($addr).VCI_gWin]
}]


[defcommand prinst {mc element {obj *ds:si}} output|ui
{ Prints out an instance data field, given the master offset, instance data, 
  and object.  For instance:
	prinst Month MI_month @65	
	prinst Gen GI_states		;uses object at *ds:si   }
{
	var ofield [format {%s%s} $mc _offset]
	print (($obj)+[value fetch ($obj).$ofield]).$element
}]


[defcommand prgen {element {obj *ds:si}} output|ui
{ Prints out generic instance data field, for example:
	prgen GI_states @65
	prgen GI_moniker		;uses object at *ds:si }
{
	print (($obj)+[value fetch ($obj).Gen_offset]).$element
}]


[defcommand prvis {element {obj *ds:si}} output|ui
{ Prints out visual instance data field, for example:
	prvis VI_bounds @65
	prvis VI_optFlags		;uses object at *ds:si }
{
	print (($obj)+[value fetch ($obj).Vis_offset]).$element
}]

[defcommand prspec {element {obj *ds:si}} output|ui
{ Prints out visual instance data field, for example:
	prspec OLSBI_docOffset @65
	prspec OLCI_optFlags		;uses object at *ds:si }
{
	print (($obj)+[value fetch ($obj).Spec_offset]).$element
}]

[defcommand prsize {{obj *ds:si}} output|ui
{ Prints out the size of an object.  }
{
    var vis ($obj)+[value fetch ($obj).Vis_offset]
    var left [value fetch ($vis).VI_bounds.R_left]
    var right [value fetch ($vis).VI_bounds.R_right]
    var top [value fetch ($vis).VI_bounds.R_top]
    var bottom [value fetch ($vis).VI_bounds.R_bottom]
    echo [format {(%d, %d)} [expr {$right-$left+1}] [expr {$bottom-$top+1}]]
}]

