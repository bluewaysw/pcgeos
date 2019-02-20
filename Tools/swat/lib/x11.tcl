##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- X11 startup
# FILE: 	x11.tcl
# AUTHOR: 	Adam de Boor, Jul 17, 1989
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	7/17/89		Initial Revision
#
# DESCRIPTION:
#	Definitions to start up the X11 interface.
#
#	$Id: x11.tcl,v 3.0 90/02/04 23:48:44 adam Exp $
#
###############################################################################


#
# Create the default buttons
#

#
# Control flow buttons, for both istep and command-line
#
button create continue {provide-input cont c}
button create next {provide-input next n}
button create step {provide-input step s}
button create finish {provide-input finish f}
button create {force next} {provide-input next N}
button create {to method} {provide-input {error {say what?}} m}
#
# Buttons to set a breakpoint at the current selection
#
button create {brk aset} {brk aset [x11-get-def-selection]}
button create {brk} {brk [x11-get-def-selection]}

#
# Print the current selection
#
button create {print} {print [x11-get-def-selection]}
#
# Stop the machine -- doesn't provide input, just sets the UI_IRQ bit
#
button create stop {irq 1}
#
# Miscellaneous
#
button create quit {provide-input quit q}
button create attach attach
button create detach detach
button create spawn {spawn [x11-get-def-selection]}
[defdsubr x11-get-def-selection {} prog.window
{Returns the PRIMARY or CUT_BUFFER0 selection as a string}
{
    return [x11-get-selection {PRIMARY CUT_BUFFER0} STRING]
}]
