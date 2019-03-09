##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat system library
# FILE: 	makefref.tcl
# AUTHOR: 	Adam de Boor, April  2, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	makefref    	    	Creates a formatted reference file for a geode
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/ 3/90		Initial Revision
#
# DESCRIPTION:
#   	The functions in this file create a single file containing a very
#   	basic formatted reference for the functions exported by a geode. The
#   	reference contains only the SYNOPSIS/DESCRIPTION, PASS, and RETURN
#   	fields of the header. The resulting file should be formatted with:
#
#   	    ditroff -Plw -ms <file>
#
#   	These must be run from within Swat. You will need to reload "gloss" to
#   	get the old ref command back.
#	
#
#	$Id: makefref.tcl,v 1.1 90/04/02 17:20:31 adam Exp $
#
###############################################################################
[defsubr extract-header {target file}
{
    #
    # Now for the fun part: look through the file with SED, dealing with the
    # two different types of procedure headers in the system. The result will
    # be the procedure header with the following things deleted:
    #	- blank lines
    #	- revision history
    #	- callers/function type (CALLED BY field)
    #	- pseudo code
    #
    var header [exec sed -n -e [format {
/^COMMENT/,/^[-%%][-%%]*[@\}]$/\{
    /^COMMENT.*%%%%/,/^[^ 	]/\{
    	/%s/bploop
    \}
    /^COMMENT.*-----/,/^FUNCTION:/\{
    	/^FUNCTION.*%s/bploop
    \}
    /^COMMENT.*-----/,/^METHOD:/\{
    	/^METHOD.*%s/bploop
    \}
    /^COMMENT.*-----/,/^ROUTINE:/\{
    	/^ROUTINE.*%s/\{
	    s/ROUTINE/FUNCTION/
	    bploop
	\}
    \}
    d
    :bloop
    n
    /^[ \t]*$/bbloop
    /^%%*%%$/bbloop
    bline
    :ploop
    n
    :line
    /^CALLED BY/,/^[A-Z]/\{
	/^CALLED/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^PSEUDO/,/^[A-Z]/\{
	/^PSEUDO/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^REVISION/,/^[-A-Z%%]/\{
	/^REVISION/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^KNOWN/,/^[-A-Z%%]/\{
	/^KNOWN/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^DESTROYED/,/^[-A-Z%%]/\{
	/^DESTROYED/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^REGISTER/,/^[-A-Z%%]/\{
	/^REGISTER/bploop
	/^[ 	]/bploop
	/^$/bploop
    \}
    /^[A-Z][A-Z]*:/\{
    	s/SYNOPSIS/DESCRIPTION/
    	i\\
.SH
    	/^[^ \t]*:[ \t]*$/!bbrk
    	/^[^ \t]*:[ \t]*$/\{
	    a\\
.nr q 1\\
.ps 10\\
.ft C
	    s/^\\([^:]*\\):.*$/\\1/
    	    p
	    bploop
    	\}
:brk
    	h
	s/^\\([^:]*\\):.*$/\\1/
	p
	i\\
.nr q 1\\
.ps 10\\
.ft C
    	g
    	:iloop
	/^[ \t]*[^ \t:][^:]*:/\{
	    s/^\\([ \t]*\\)[^ \t:]\\([^:]*\\):/\\1 \\2:/
	    biloop
    	\}
	s/^\\([^:]*\\):\\([ \t]*[^ \t]\\)/\\1 \\2/
	p
	bploop
    \}
    /^[-%%][-%%]*[@\}%%]$/!\{
	p
	bploop
    \}
    /^[-%%][-%%]*[@\}]$/\{
    	i\\
.nr q 0\\
.KE
	q
    \}
    bploop
\}} $target $target $target $target] $file]
    if {[null $header]} {
    	return nil
    } else {
    	var header [exec expand < $header]
    	return [exec sed -e {
    /^         /,/^[^ ]/{
    	:loop
    	s/^        //
	n
	/^ /bloop
    }
    /^        [^ ]/,/^[^ ]/{
        :ploop
	n
	/^ /bploop
    }
} -e {/^[ 	]*$/d} < $header]
    }
}]
    
[defcommand fref {target dir out} reference
{'ref routineName' prints out the routine header for a function. If no function
is given, the function active in the current stack frame is used. This command
locates the function using a tags file, so that tags file should be kept
up-to-date}
{
    if {[length $target] > 1} {
    	var lookfor [index $target 0] name [index $target 1]
    } else {
    	var lookfor $target name $target
    }
    #
    # Default to current function if none given
    #
    var tsym [sym find func $lookfor]
    if {[null $tsym]} {
	echo [format {"%s" not a defined function} $lookfor]
    }
    
    echo -n $lookfor...
    flush-output
    var p [symbol patient $tsym]
#XXX
    var file [index [src line $lookfor] 0]

    var header [extract-header $lookfor $file]
    if {[null $header]} {
    	echo [format {Error: "%s" not in %s as expected} $target $file]
    } else {
    	stream write [format {.Fs %s\n%s} $name $header] $out
    }
}]

[defcommand makefref {patient {outfile /staff/pcgeos/frefs}} reference
{'makefref ' calls ref on ALL functions for a geode. First argument PATIENT is
the patient for which to generate the reference tree. Second optional argument
DIR is the reference directory below which to create the reference tree and
defaults to /staff/pcgeos/refs. E.g. "makeref kernel" would cause files to be
created in the tree /staff/pcgeos/refs/Kernel. All functions exported by the
patient have their headers extracted in the proper form in right shadow file}
{
    global file-root
    
    var p [patient find $patient]
    if {[null $p]} {
    	error [format {patient %s not known} $patient]
    }
    var pdir [file [patient path $p] dirname]
    var subdir [range $pdir [expr [length ${file-root} char]+1] end char]
    var fn [index [range [patient fullname $p] 0 7 char] 0]
    if {[null $fn]} {
    	var fn geos
    }
    var gpfile $fn.gp
    if {![string match $subdir {[A-Z]*}]} {
    	var subdir [range $subdir [expr [string first / $subdir]+1] end char]
    	if {[file ${pdir}/${gpfile} exists]} {
	    var gpfile ${pdir}/${gpfile}
	} else {
	    var gpfile ${file-root}/${subdir}/${gpfile}
	}
    } else {
    	var gpfile ${pdir}/${gpfile}
    }
    echo creating formatted reference file $outfile from $gpfile
    var out [stream open $outfile w]
    [stream write
{.ds LF "\fB\s+2Berkeley Softworks Company Confidential
.ds RF \*(DY
.LP
.de Fs
.KS
\l'6.5i-'
.br
.LG
.B
.tl '\\$1 ''\\$1 '
.R
.NL
.br
\v'-0.5'\l'6.5i-'\v'0.5'
..
.nr q 0
} $out]
    var funcs [exec awk {/^export/ && NF == 2 {print $2} /^export/ && NF == 4 {printf "{%s %s}\n", $2, $4}} $gpfile]
    protect {
        foreach i $funcs {
            catch {fref $i ${dir}/${subdir} $out}
        }
    } {
    	echo done
    	stream close $out
    }
}]
