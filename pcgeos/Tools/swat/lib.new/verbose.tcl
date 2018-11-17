##############################################################################
#
# 	Copyright (c) Geoworks 1995 -- All Rights Reserved
#
# PROJECT:	PCGEOS
# MODULE:	Swat
# FILE: 	verbose.tcl
# AUTHOR: 	Paul Canavese, May 12, 1995
#
# COMMANDS:
# 	Name                           Description
#	----                           -----------
#
#       verbose                        Interface for setting and examining 
#                                      verbose breakpoints.
#       verbose-report                 Routine that breakpoints call to
#                                      actually run the verbose code.
#
#       ----------------------------------------------------------------------
#       debug-verbose                  Print out global verbose variables.
#       verbose-key-on                 Turn on a verbose key.
#       verbose-key-off                Turn off a verbose key.
#
#       add-verbose-report-point       Introduce or increment the count of a 
#                                      report point.
#       subtract-verbose-report-point  Delete or decrement the count of a report 
#                                      point.
#
#       set-verbose-breakpoint         Set a verbose breakpoint, or add it to 
#                                      the spawn waiting list.
#       unset-verbose-breakpoint       Unset a verbose breakpoint, or delete it 
#                                      from the spawn waiting list.
#       verbose-spawn-lurker           Sets waiting breakpoints when their
#                                      patient is spawned.
#
#       verbose-key-entry              Lookup entry of a verbose key.
#       verbose-key-description        Lookup description of a verbose key.
#       verbose-key-report-points      Lookup report points of a verbose key.
#
#       verbose-class-valid            Is verbose class valid?
#       verbose-key-valid              Is verbose key valid?
#       verbose-format-key-and-description
#                                      Returns nicely formatted key name and
#                                      its description.
#
#       report-point-entry             Lookup entry of a report point.
#       report-point-address           Lookup address of a report point.
#       report-point-code              Lookup code for a report point.
#
#       display-current-report-point-entry
#                                      Format and diaplay a report point entry.       
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	5/12/95   	Initial Revision
#
# DESCRIPTION:
#       Handles setting and manipulating verbose "report points".
#
#	$Id: verbose.tcl,v 1.2.6.1 97/03/29 11:27:47 canavese Exp $
#
###############################################################################

[load list.tcl]

####################################################################################
# currentVerboseKeys lists the currently set verbose keys
#
# {class1 key1 key2 key3} {class2 key4 key5 key6}...

defvar currentVerboseKeys {}


####################################################################################
# currentVerboseReportPoints lists the currently set verbose breakpoints.
#
# {geodename {reportpointname {brktoken count}} {reportpointname {brktoken count}}
# {geodename {reportpointname {brktoken count}}...}...

defvar currentVerboseReportPoints {}


####################################################################################
# spawnVerboseBreakpoints lists verbose breakpoints that will be set once the 
# given patient is spawned
#
# {geodename reportpointname reportpointname}
# {geodename reportpointname reportpointname}...

defvar spawnVerboseBreakpoints {}


####################################################################################
[defcmd verbose {args} profile
{Usage:
    verbose                    display status (currently set keys)
    verbose classes            display all valid classes
    verbose keys [<class>]     display all valid keys for class
    verbose set|on <class> [<key>...]   
                               sets the report points for keys in class
    verbose unset|off [<class>] [<key>...]   
                               unsets the report points for keys in class
    verbose points [<class>]   display all report points set for class

Examples:
    "verbose keys"             display all valid keys
    "verbose k patch"          display valid keys for class "patch"
    "verbose on patch"         sets all report points for class "patch"
    "verbose on patch h"       sets the report points for key "high" in 
                               class "patch"
    "verbose off"              unsets all report points
    "verbose off patch"        unsets all report points for class "patch"
    "verbose off patch h"      unsets report point for key "high" in 
                               class "patch"
 
Synopsis:
    Allows you to easily enable keys, which tell swat to display useful 
    information during execution.

Notes:
    * Commands can be abbreviated by their first letters.

    * A report-point is a breakpoint with code associated with it to display
      useful information.  Available report points are defined in 
      "verbkeys.tcl", in variables named {patient}ReportPoints (i.e. 
      "reseditReportPoints").  Report points are referenced by geode variable,
      and then by name.

    * A verbose key is a group of report points, grouped by function.  A
      verbose key has a name, description, and list of its report points.

    * A verbose class is a group of verbose keys, grouped by function.
      verbose classes usually refer to a major GEOS "function" or geode.

    * All verbose classes and their levels are listed in the variable
      verboseKeys in "verbkeys.tcl".  Report points can be turned on by 
      multiple keys.  It is very easy to add keys and report points to this
      file.  Very easy.  That's the idea.  Did I mention how easy it is?

    * Classes and keys can be abbreviated, as long as the abbreviation
      contains enough characters to determine it from the other classes and
      keys.

    Lower-level concerns:

    * A reference count is maintained for report points, to better support
      keys with overlapping report points.  If a report point is set twice,
      it will not be deleted until it is unset twice.

    * Report points can be set and unset regardless of whether the patient
      for the breakpoint has been spawned yet.  Verbose automagically turns
      on the report points for a patient when it is spawned.
}
{
    global currentVerboseKeys
    global currentVerboseReportPoints
    global verboseKeys

    # Make sure we can see the global keys list.

    if {[null $verboseKeys]} {
	load verbkeys.tcl
	if {[null $verboseKeys]} {
	    error {No valid keys.  What's up with that?}
	    return
	}
    }
    
    # Handle "verbose" (print out currently set keys).

    if {[null $args]} {
	if {[null $currentVerboseKeys]} {
	    echo No keys are currently set.
	} else {
	    echo Currently set keys (by class):
	    foreach classEntry $currentVerboseKeys {
		list-display-car $classEntry 1
		foreach keyEntry [cdr $classEntry] {
		    thrindent 2
		    [echo [verbose-format-key-and-description
			   [car $classEntry] [car $keyEntry]]]
		}
	    }
	}
	return
    }

    # Handle commands

    var command [cutcar args]

    # Validate the passed class, doing completion if necessary.

    var class [cutcar args]
    if {![null $class]} {
	if {![verbose-class-valid $class]} {
	    var newClass [verbose-complete-class $class]
	    if {[null $newClass]} {
		error [format {%s is not a valid class.} $class]
		return
	    } else {
		var class $newClass
	    }
	}
    }

    # Validate the passed keys, doing completion if necessary.

    var keys $args
    if {![null $keys]} {
	foreach key $keys { 
	    if {[verbose-key-valid $class $key]} {
		append newKeys $key
	    } else {
		var newKey [verbose-complete-key $class $key]
		if {[null $newKey]} {
		    error [format {%s is not a valid key for %s.} $key $class]
		    return
		} else {
		    append newKeys $newKey
		}
	    }
	}
	var keys $newKeys
    }



    [case $command in

     c* {
	 echo Valid classes:
	 list-display-keys $verboseKeys 1 1
     }

     k* {

	 # Check if we should print out everything.

	 if {[null $class]} {
	     echo Valid classes and keys:
	     foreach classEntry $verboseKeys {
		 list-display-car $classEntry 1
		 foreach keyEntry [cdr $classEntry] {
		     thrindent 2
		     [echo [verbose-format-key-and-description
			    [car $classEntry] [car $keyEntry]]]
		 }
	     }
	 } else {
	     var classEntry [hlist-get-entry $verboseKeys $class]
	     echo Valid keys for $class:
	     foreach keyEntry $classEntry {
		 thrindent 1
		 [echo [verbose-format-key-and-description
			$class [car $keyEntry]]]
	     }
	 }
     }

     p* {

	 if {[null $currentVerboseReportPoints]} {
	     echo No verbose report points are set.
	 } else {

	     # Check if we should print out everything.

	     if {[null $keys]} {
		 echo Current verbose report points:
		 foreach geodeEntry $currentVerboseReportPoints {
		     list-display-car $geodeEntry 1
		     foreach reportPoint [cdr $geodeEntry] {
			 display-current-report-point-entry $reportPoint 2
		     }
		 }
	     } else {
		 if {![hlist-entry-exists $currentVerboseReportPoints $class]} {
		     echo No verbose breakpoints are set for patient $class.
		 } else {
		     [display-current-report-point-entry 
		      [hlist-get-entry $currentVerboseReportPoints $class] 1]
		 }
	     }	
	 }
     }

     {s* on} {

	 if {[null $class]} {
	     verbose-keys-on
	 } else {
	     if {[null $keys]} {
		 verbose-keys-on $class
	     } else {
		 foreach key $keys {
		     verbose-key-on $class $key
		 }	 
	     }
	 }
     }

     {u* off} {

	 if {[null $class]} {
	     verbose-keys-off
	 } else {
	     if {[null $keys]} {
		 verbose-keys-off $class
	     } else {
		 foreach key $keys {
		     verbose-key-off $class $key
		 }
	     }
	 }	 
     }

     default {
	 echo $command is not a valid command name.
     }
    ]

}]


####################################################################################
# Ther routine that the breakpoints call

[defsubr verbose-report {geodeName reportPointName} {
    eval [report-point-code $geodeName $reportPointName]
    return 0
} ]


####################################################################################
# Code to manipulate verbose keys.

[defsubr verbose-key-on {class key} {

    global currentVerboseKeys

    if {[hlist-entry-exists $currentVerboseKeys $class $key]} {
	error [format {%s key is already set for %s.} $key $class]
	return
    }

    echo Turning on $key key for $class.
    foreach reportPoint [verbose-key-report-points $class $key] {
	add-verbose-report-point [car $reportPoint] [cdr $reportPoint] 
    }

    hlist-add-entry currentVerboseKeys $class $key
} ]


[defsubr verbose-keys-on {class} {

    global currentVerboseKeys verboseKeys

    foreach entry [hlist-get-entry $verboseKeys $class] {
	verbose-key-on $class [car $entry]
    }
} ]

[defsubr verbose-key-off {class key} {

    global currentVerboseKeys

    if {![hlist-entry-exists $currentVerboseKeys $class $key]} {
	error [format {%s key is not set for %s.} $key $class]
	return
    }

    echo Turning off $key key for $class.
    foreach reportPoint [verbose-key-report-points $class $key] {
	subtract-verbose-report-point [car $reportPoint] [cdr $reportPoint] 
    }

    hlist-delete-entry currentVerboseKeys $class $key
    
} ]

[defsubr verbose-keys-off {{class {}}} {

    global currentVerboseKeys

    if {[null $class]} {
	foreach entry $currentVerboseKeys {
	    verbose-keys-off [car $entry]
	}
    } else {
	foreach entry [hlist-get-entry $currentVerboseKeys $class] {
	    verbose-key-off $class $entry
	}
    }
} ]

####################################################################################
# Code to manipulate verbose report points.

[defsubr add-verbose-report-point {geodeName reportPointName} {

    global currentVerboseReportPoints

    # Check if report-point is already set.

    [var entry [hlist-delete-entry currentVerboseReportPoints 
		$geodeName $reportPointName] ]

    if {![null $entry]} {

	# Report point already exists.  Just increment it's count.

	var entry [car $entry]
	aset entry 1 [expr [cdr $entry]+1]

    } else {

	# Report point is new.  Set its breakpoint and make a new entry.

	var entry [list [set-verbose-breakpoint $geodeName $reportPointName] 1]
    }

    [hlist-add-entry currentVerboseReportPoints $geodeName $reportPointName $entry]

} ]


[defsubr subtract-verbose-report-point {geodeName reportPointName} {

    global currentVerboseReportPoints

    # Check if report-point is already set.

    [var entry [hlist-delete-entry currentVerboseReportPoints 
		$geodeName $reportPointName] ]

    if {[null $entry]} { return }

    var entry [car $entry]
    if {[cdr $entry] > 1} {

	# Report point count > 1.  Just decrement the count.

	aset entry 1 [expr [cdr $entry]-1]
	[hlist-add-entry currentVerboseReportPoints $geodeName $reportPointName $entry]

    } else {

	unset-verbose-breakpoint $geodeName $reportPointName [car $entry]
    }
} ]


####################################################################################
# Code to manipulate verbose breakpoints.

[defsubr set-verbose-breakpoint {geodeName reportPointName} {

    global verboseSpawnLurker
    global spawnVerboseBreakpoints

    thrindent 1
    echo Turning on $reportPointName report point for $geodeName.
    if {[null [patient find $geodeName]]} {

	# Patient has not been spawned yet.

	if {[null $verboseSpawnLurker]} {
	    
	    # The lurker has not been started yet... so start it now.
 
	    [var verboseSpawnLurker [event handle START verbose-spawn-lurker]]
	}

	[hlist-add-entry spawnVerboseBreakpoints $geodeName $reportPointName]
	return notSpawned
    }

    # Set the breakpoint.

    var currentPatient [patient data]
    switch $geodeName
    var breakToken [brk [report-point-address $geodeName $reportPointName]]
    brk cmd $breakToken [list verbose-report $geodeName $reportPointName]
    switch [index $currentPatient 0]:[index $currentPatient 2]
    return $breakToken
} ]


[defsubr unset-verbose-breakpoint {geodeName reportPointName brkToken} {

    global spawnVerboseBreakpoints

    thrindent 1
    echo Turning off $reportPointName report point for $geodeName.
    if {$brkToken == notSpawned} {

	# Breakpoint was never set, since patient was never spawned.

	[hlist-delete-entry spawnVerboseBreakpoints $geodeName $reportPointName]
	return
    }

    # Delete the breakpoint.
    # Is there any way to check if the brkToken itself is valid?

    var currentPatient [patient data]
    switch $geodeName
    if {[brk isset [report-point-address $geodeName $reportPointName]]} {
	brk delete $brkToken
    }
    switch [index $currentPatient 0]:[index $currentPatient 2]
} ]


[defsubr verbose-spawn-lurker {patient} {

    global spawnVerboseBreakpoints
    global currentVerboseReportPoints

    foreach geodeEntry $spawnVerboseBreakpoints {

	if {[string m [patient name $patient] [car $geodeEntry]*]} {

	    # We have breakpoints waiting for this patient.

	    var geodeName [car $geodeEntry]
	    [var reportPoints [hlist-delete-entry spawnVerboseBreakpoints 
			      $geodeName]]

	    # Set the breakpoints.

	    var currentPatient [patient data]
	    switch $geodeName
	    foreach reportPointName $reportPoints { 

		# Set breakpoint for this report point.

		var breakToken [brk [report-point-address $geodeName $reportPointName]]
		brk cmd $breakToken [list verbose-report $geodeName $reportPointName]

		# Record the break token.

		[var entry [hlist-delete-entry currentVerboseReportPoints 
			    $geodeName $reportPointName] ]
		[hlist-add-entry currentVerboseReportPoints $geodeName 
		 $reportPointName [list $breakToken [cdr [car $entry]]]]
	    }
	    switch [index $currentPatient 0]:[index $currentPatient 2]
	    return EVENT_HANDLED
	}
    }
    return EVENT_HANDLED
} ]


[defsubr debug-verbose {args} {
    global spawnVerboseBreakpoints currentVerboseKeys currentVerboseReportPoints
    echo currentVerboseKeys
    list-display $currentVerboseKeys 1
    echo currentVerboseReportPoints
    list-display $currentVerboseReportPoints 1
    echo spawnVerboseBreakpoints
    list-display $spawnVerboseBreakpoints 1
} ]

####################################################################################
# Code for accessing verboseKeys

[defsubr verbose-key-entry {class key} {
    global verboseKeys
    return [hlist-get-entry $verboseKeys $class $key]
} ]

[defsubr verbose-key-description {class key} {
    return [car [verbose-key-entry $class $key]]
} ]

[defsubr verbose-key-report-points {class key} {
    return [car [cdr [verbose-key-entry $class $key]]]
} ]

[defsubr verbose-class-valid {class} {
    global verboseKeys
    return [hlist-entry-exists $verboseKeys $class]
} ]

[defsubr verbose-key-valid {class key} {
    global verboseKeys
    return [hlist-entry-exists $verboseKeys $class $key]
} ]

[defsubr verbose-format-key-and-description {class key} {
    return [format {%-15s%s} $key [verbose-key-description $class $key]]
} ]

[defsubr verbose-complete-class {class} {
    global verboseKeys
    return [complete-from-list [hlist-get-keys $verboseKeys] $class]
} ]

[defsubr verbose-complete-key {class key} {
    global verboseKeys
    var keys [hlist-get-entry $verboseKeys $class]
    return [complete-from-list [hlist-get-keys $keys] $key]
} ]

[defsubr complete-from-list {list abbrev} {
    var abbrevLength [length $abbrev char]
    var bestMatch {}
    var bestMatchCount 0

    foreach entry $list {
	var matchCount [match-chars $abbrev $entry]
	if {$matchCount > $bestMatchCount} {
	    var bestMatchCount $matchCount
	    var bestMatch $entry
	} else {
	    if {$matchCount == $bestMatchCount} {
		var bestMatchCount 0
		var bestMatch {}
	    }
	}	    
    }
    return $bestMatch
} ]

[defsubr match-chars {list1 list2} {
    var matchCount 0
    var minLength [min [length $list1 char] [length $list2 char]]
    while {[index $list1 $matchCount char] == [index $list2 $matchCount char]} {
	var matchCount [expr $matchCount+1]
	if {$matchCount >= $minLength} {
	    return $matchCount
	}
    }
    return $matchCount
} ]

[defsubr min {a b} {
    if {$a > $b} { 
	return $b 
    } else {
	return $a
    }
} ]

####################################################################################
# Code for {geodeName}ReportPoints

[defsubr report-point-entry {geodeName reportPointName} {
    global ${geodeName}ReportPoints
    return [hlist-get-entry [var ${geodeName}ReportPoints] $reportPointName]]
} ]

[defsubr report-point-address {geodeName reportPointName} {
    return [car [report-point-entry $geodeName $reportPointName]]
} ]

[defsubr report-point-code {geodeName reportPointName} {
    return [car [cdr [report-point-entry $geodeName $reportPointName]]]
} ]

####################################################################################
# Code for accessing currentVerboseReportPoints

[defsubr display-current-report-point-entry {entry {indentnum 0}} {
    var brkToken [car [car [cdr $entry]]]
    var brkCount [cdr [car [cdr $entry]]]
    if {$brkCount == 1} {
	var brkCount {}
    } else {
	var brkCount ($brkCount)
    }
    thrindent $indentnum 
    echo [car $entry] $brkToken $brkCount
} ]

####################################################################################
# Code for indenting stuff.

global verboseIndent
var verboseIndent 0

[defsubr vindent {args} {
    global verboseIndent
    indent [expr $verboseIndent*3]
} ]

[defsubr inc-vindent {args} {
    global verboseIndent
    var verboseIndent [expr $verboseIndent+1]
} ]

[defsubr dec-vindent {args} {
    global verboseIndent
    var verboseIndent [expr $verboseIndent-1]
} ]


[defsubr report-carry-error {args} {
    if {[getcc carry]} {
	echo unsuccessful.
    } else {
	echo successful.
    }
} ]
