##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat System Library -- Geode Launching
# FILE: 	gload.tcl
# AUTHOR: 	Adam de Boor, Mar 21, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	loadgeode   	    	load a non-process geode
#   	loadapp	    	    	load an application
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/90		Initial Revision
#
# DESCRIPTION:
#	Function to load a geode from swat. Maybe it'll work...
#
#	$Id: gload.tcl,v 1.2 90/03/21 23:56:14 adam Exp $
#
###############################################################################

##############################################################################
#				loadgeode
##############################################################################
#
# SYNOPSIS:	Load some geode besides an application.
# PASS:		file	= name of file to load relative to the top-level
#			  system directory, using / instead of \ as path
#			  separators
#   	    	arg1	= (optional) value to pass in cx to loaded geode
#   	    	arg2	= (optional) value to pass in dx to loaded geode
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	?
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/90		Initial Revision
#
##############################################################################
[defdsubr loadgeode {file {arg1 0} {arg2 0}} obscure
{Load a geode from Swat. Mandatory first argument is the name of the file to
load (with path from top-level PC/GEOS directory, using / instead of \ as the
path separator).

Second and third arguments are the data words to pass to the geode. The second
argument is passed to the geode in cx, while the third argument is passed in dx.

Both the second and third arguments are optional and default to 0. They likely
are unnecessary.

NOTE: THIS MAY NOT BE USED TO LAUNCH AN APPLICATION. USE loadapp FOR THAT}
{
    save-state
    protect {
    	#
	# Figure length of top-level path
	#
    	[for {var i 0}
	     {[value fetch topLevelPath+$i byte] != 0}
	     {var i [expr $i+1]}
	     {}]
	#
	# Create array type for fetching/storing topLevelPath
	#
	var pt [type make array $i [type byte]]
	#
	# Figure length of combined strings
	#
	var len [expr $i+1+[length $file chars]+1]
	#
	# Make that much room on the stack
	#
	assign sp sp-$len
	#
	# Copy the topLevelPath onto the stack, terminating it with the needed
	# backslash.
	#
	value store ss:sp $pt [value fetch topLevelPath $pt]
	value store ss:sp+$i [type char] \\
	
    	#
	# Now copy the desired file onto the stack, mapping /'s to \'s when
	# needed
	#
	var j [expr $i+1]
	foreach c [explode $file] {
	    if {[string c $c /] == 0} {
	    	value store ss:sp+$j [type char] \\
	    } else {
	    	value store ss:sp+$j [type char] $c
    	    }
	    var j [expr $j+1]
    	}
	#
	# Null-terminate the string
	#
    	value store ss:sp+$j [type byte] 0
	
    	#
	# Call GeodeLoad to load the thing, making sure it's *not* a process
	#
    	[if {[call-patient GeodeLoad
	    	    	   ax PRIORITY_STANDARD
			   bx 0
			   cx 0
			   dx [fieldmask GA_PROCESS]
			   di $arg1
			   bp $arg2
			   ds ss
			   si sp]}
    	{
    	    if {[read-reg cc] & 1} {
    	    	#
		# Carry set on return -- map error code and print error message
		#
	    	var err [type emap [read-reg ax]
		    	    	[sym find type GeodeLoadErrors]]
		echo [format {couldn't load %s: %s} $file $err]
    	    } else {
    	    	echo $file loaded
    	    }
    	} else {
    	    echo [format {couldn't load %s for some reason} $file]
    	}
    } {
    	restore-state
    }
}]

##############################################################################
#				loadapp
##############################################################################
#
# SYNOPSIS:	Load an application from Swat
# PASS:		file	= name of application to load, relative to system
#			  appl directory, using / instead of \ as a path
#			  separator, if needed.
# CALLED BY:	user
# RETURN:	nothing
# SIDE EFFECTS:	the application is loaded, if possible
#
# STRATEGY
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	3/21/90		Initial Revision
#
##############################################################################
[defdsubr loadapp {file} obscure
{Load an application from Swat. Single argument is the file name of the
application to launch (application must reside in the appl subdirectory of
the PC/GEOS tree).

The application is opened in normal application mode. Some day this may allow
opening in engine mode...

Note that the application will not be loaded until you continue the machine, as
the loading is accomplished by sending a method to the UI}
{
    save-state
    protect {
    	#
	# Make room for the file name on the stack
	#
	var len [expr [length $file chars]+1]
	assign sp sp-$len
	
    	#
	# Store the file name, null-terminated, in the space allocated for it
	# on the stack. Map any / to \ on the way (can't just have the user use
    	# \ b/c explode doesn't handle it correctly)
	#
	var j 0
	foreach c [explode $file] {
	    if {[string c $c /] == 0} {
	    	value store ss:sp+$j [type char] \\
	    } else {
	    	value store ss:sp+$j [type char] $c
    	    }
	    var j [expr $j+1]
    	}
    	value store ss:sp+$j [type byte] 0
	
    	#
	# Call UserLoadApplication, telling it to send the launch request via
	# the ui.
	#
    	if {[call-patient ui::UserLoadApplication
	    	ah [fieldmask ui::ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE]
		al 0
		cx ui::METHOD_UI_OPEN_APPLICATION
		dx 0
	    	ds ss
		si sp]} {
    	    echo $file loaded
    	} else {
    	    echo [format {couldn't load %s for some reason} $file]
    	}
    } {
    	restore-state
    }
}]
	
	
