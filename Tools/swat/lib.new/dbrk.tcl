##############################################################################
#
# 	Copyright (c) Geoworks 1994 -- All Rights Reserved
#
# PROJECT:	GEOS
# MODULE:	Swat -- System Library
# FILE: 	dbrk.tcl
# AUTHOR: 	Paul DuBois, Jul 27, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	dbrk			Delayed breakpoint
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	dubois	7/27/94   	Initial Revision
#
# DESCRIPTION:
#	User-friendly interface to `brk cmd' to implement a breakpoint
#	which is only taken after it has been hit a specified number of
#	times.  dbrks may be given commands with `dbrk cmd', since if one
#	uses `brk cmd' then the counting functionality is lost.
#
#	$Id: dbrk.tcl,v 1.3.12.1 97/03/29 11:27:12 canavese Exp $
#
###############################################################################

# Stores breakpoints that have been used with dbrk.
# This is an association list with entries of the form:
# {brkN S} where N is an integer and S is either e (enabled) or d (disabled)
defvar dbrkList {}

##############################################################################
#	dbrk
##############################################################################
#
# SYNOPSIS:	See help string
# CALLED BY:	user
# STRATEGY:
#	Use global variables based on the breakpoint token to keep around
#	state.  These variables are: brkNcur (current count), brkNmax
#	(max count), brkNcmd (command to eval when cur>=max).
#	
#	brk delcmd is used to clear out these variables when the breakpoint
#	is deleted.
# TODO:
#	Command should be "none" if there's no command to print      
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       dubois 	7/27/94   	Initial Revision
#
##############################################################################
[defcommand dbrk {args} top.breakpoint
{Usage:
    dbrk <addr> <num> [<command>|default]
    dbrk set <break> <num> [<command>|default]
    dbrk list [<break>]
    dbrk {clear,delete} <break>
    dbrk cur <break> <num>
    dbrk max <break> <num>
    dbrk cmd <break> [<command>]
    dbrk reset <break>
    dbrk enable <break>
    dbrk disable <break>

Examples:
    "dbrk ObjMessage 30"		Break at the 30th call to ObjMessage
    "dbrk set 5 30"			Break after hitting brk5 30 times.
    "dbrk set brk3 10 default"		Break after hitting brk3 10 times;
					Each time brk3 is hit, perform the
					default command.
    "dbrk cmd brk2 {echo foo}"		Echo a string whenever brk2 is hit.
    "dbrk cmd brk2 default"		Use the default command for brk2.
    "dbrk disable 2"			Stop counting brk2; it will now always
					be taken.

Synopsis:
    Front-end command to "brk cmd".  Delay taking a breakpoint until it has
    been hit a specified number of times.

Notes:
    * <break> may be a number, or a full breakpoint token (brk<n>)
      <num> is a number; and <command> is a string that will be evaluated.
      If <command> may also be the string "default", in which case a default
      command will be used.  The first argument to dbrk may be abbreviated;
      only the first 3 chars are significant.

    * Deleting a breakpoint with "brk del" removes the dbrk also.

    * With the exception of brk, all the commands that take <break> must be
      given a breakpoint that has been delayed.  The "dbrk list" command
      will show these.

    * "dbrk list" will show how many times a breakpoint has been hit,
      the maximum number of times to skip the breakpoint, and the command to
      evaluate whenever the breakpoint is hit.  If no breakpoint is passed,
      the status of all dbrks will be shown.

    * "dbrk clear" and "dbrk delete" are synonyms.  These commands will
      cause the delayed breakpoint to become normal again, and clear out
      the global variables used to store the dbrk's state:
          brkNcur, brkNmax, brkNcmd
      where N is a number.

    * "dbrk cur", "dbrk max", and "dbrk cmd" set the current count, the
      maximum count, and the command of the specified breakpoint
      repsectively.

    * "dbrk reset <break>" is a quick way of saying "dbrk cur <break> 0"

    * "dbrk enable" and "dbrk disable" are used to enable and disable a
      dbrk.  Disabled dbrks will always be taken, and their counter will
      not be incremented.

    * Since this command is just a front-end to brk cmd, you can use
      dbrk and brk cond to create more complex breakpoints; for instance,
      you can "mwatch MSG_VIS_DRAW", then "dbrk set <brk> 30 print-method"
      to break after MSG_VIS_DRAW has been received 30 times.

See also:
    brk, cbrk.
} {
    [global dbrkList]

    [var caseCmd [index $args 0]
	 bpt [index $args 1]]

    # This check (for number-ness) is really crude.  Oh well.
    if {[string m $bpt {[0-9]*}]} { var bpt brk${bpt} }
    [var bcur ${bpt}cur
         bmax ${bpt}max
	 bcmd ${bpt}cmd]
    [global $bcur $bmax $bcmd]

    [case $caseCmd in
     {set} {
	 # notify if it existed previously; add to dbrkList
	 if {![null [assoc $dbrkList $bpt]]} {
	     [echo Deleting old dbrk for $bpt...]
	     [dbrk-del $bpt]
	 }
	 [var dbrkList [cons [list $bpt e] $dbrkList]]

	 # set up variables
	 [var max [index $args 2]
	      cmd [index $args 3]]
	 if {[null $max]} {var max 10}
	 if {[string m $cmd def*]} {
	     [var cmd [format {[echo $breakpoint: ${%s}/${%s}]} $bcur $bmax]]
	 }
	 
	 # keep this here so on undefined brkpoint error we don't
	 # set the global vars
	 [brk cmd $bpt {dbrk-do}]
	 [brk delcmd $bpt {dbrk-del}]

	 # initialize global vars
	 [var $bcur 0 $bmax $max $bcmd $cmd]
     }
     {lis*} {
	 # we go through some contortions so the output is sorted.
	 # hey, processor time is cheap on the host machine.
	 echo {Num S Hits/Max		Command}
	 [if {[null [index $args 1]]}
	  {[var blist [sort [map i $dbrkList {index $i 0}]]]}
	  {[dbrk-ensure-valid $bpt] [var blist $bpt]}]
	 [foreach b $blist {
	     [var b [assoc $dbrkList $b]]
	     [var brk [index $b 0]]
	     [global ${brk}cur ${brk}max ${brk}cmd]
	     [case [index $b 1] in
	      {e} {[var stat E]}
	      {d} {[var stat D]}]
	     [echo [format {%3s %s %4s/%4s\t\t%s}
	       [range [index $b 0] 3 end char]
	       $stat [var ${brk}cur] [var ${brk}max] [var ${brk}cmd]]]
	 }]
     }
     {res*} {
	 [dbrk-ensure-valid $bpt]
	 [var $bcur 0]
     }
     {cur max} {
	 [dbrk-ensure-valid $bpt]
	 [var ${bpt}${caseCmd} [index $args 2]]
     }
     {cmd} {
	 [dbrk-ensure-valid $bpt]
	 [var cmd [index $args 2]]
	 if {[string m $cmd def*]} {
	     [var cmd [format {[echo $breakpoint: ${%s}/${%s}]} $bcur $bmax]]
	 }
	 [var ${bpt}cmd $cmd]
     }
     {dis* ena*} {
	 [dbrk-ensure-valid $bpt]
	 # Change entry in dbrkList to reflect enabled/disabled status
	 [var dbrkList [delassoc $dbrkList $bpt]]
	 [if {[string m $caseCmd d*]} then {
	     [brk cmd $bpt]
	     [var dbrkList [cons [list $bpt d] $dbrkList]]
	 } else {
	     [brk cmd $bpt dbrk-do]
	     [var dbrkList [cons [list $bpt e] $dbrkList]]
	 }]
     }
     {cle* del*} {
	 [dbrk-del $bpt]
     }
     {default} {
	 [var bpt [brk $caseCmd]
	      num [index $args 1]
	      cmd [index $args 2]]
	 [dbrk set $bpt $num $cmd]
	 [return $bpt]
     }]
}]

# dbrk-ensure-valid --
#    simple routine to error if $bpt isn't in $dbrkList
[defsubr dbrk-ensure-valid {bpt} {
    [global dbrkList]
    [if {[null [assoc $dbrkList $bpt]]} {
	error [format {%s isn't a dbrk} $bpt]
    }]
}]

# dbrk-do --
#    This is what's put as the breakpoints brk cmd.  It relies upon the fact
#    that the global variable "breakpoint" is set when a breakpoint is hit;
#    this is how it finds the proper state (it cobbles together variable names
#    on the fly -- isn't tcl great?)
#    
[defsubr dbrk-do {} {
    [global breakpoint]
    # for convenience... argh
    [var bcur ${breakpoint}cur bmax ${breakpoint}max bcmd ${breakpoint}cmd]
    [global $bcur $bmax $bcmd]
    [if {[null [var $bcur]]} {
	[error [format {ERROR_%s_ISNT_A_DBRK_SO_WHY_IS_IT_RUNNING_DBRK_DO_BUB} $breakpoint]]
    } else {
	[var $bcur [expr [var $bcur]+1]]
	[eval [var $bcmd]]
	[if {[catch {[expr {[var $bcur] >= [var $bmax]}]} result] == 0} {
	    return $result
	} else {
	    echo Warning: \$$bcur or \$$bmax possibly nil
	    return 1
	}]
    }]
}]

# dbrk-del --
#    delete all the global state associated with the current breakpoint.
#    This function is used as a brk delcmd and as the implementation of dbrk
#    {clear,delete}.  Because of the latter case, we should make sure to
#    clear out the brk cmd and brk delcmd.
#
[defsubr dbrk-del {{bpt {}}} {
    [global breakpoint dbrkList]

    if {[null $bpt]} {[var bpt $breakpoint]}
    [dbrk-ensure-valid $bpt]
#   echo DEBUG: deleting dbrk for $bpt
    [var dbrkList [delassoc $dbrkList $bpt]]
    [var bcur ${bpt}cur bmax ${bpt}max bcmd ${bpt}cmd]
    [global $bcur $bmax $bcmd]
    [var $bcur {} $bmax {} $bcmd {}]
    [brk cmd $bpt {}]
    [brk delcmd $bpt {}]
}]
