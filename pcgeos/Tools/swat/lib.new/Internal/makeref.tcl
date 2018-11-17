##############################################################################
#
# 	Copyright (c) GeoWorks 1990 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat system library
# FILE: 	makeref.tcl
# AUTHOR: 	Andrew Wilson, Jan  3, 1990
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	makeref	    	    	Creates a reference tree for a geode
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	ardeb	1/ 3/90		Initial Revision
#
# DESCRIPTION:
#   	The functions in this file create a shadow source tree containing only
#   	the procedure headers, minus pseudo code and other precious/worthless
#   	information. The intent is to provide third parties the ability to
#   	use the ref command in Swat without providing them full source code.
#
#   	These must be run from within Swat. You will need to reload "gloss" to
#   	get the old ref command back.
#	
#
#	$Id: makeref.tcl,v 3.11.11.1 97/03/29 11:25:03 canavese Exp $
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
    	/^COMMENT/h
	s/$/ /
    	/%s[ \t,]/bfound
    \}
    /^COMMENT.*-----/,/^FUNCTION:/\{
    	/^COMMENT/h
	s/$/ /
    	/^FUNCTION.*%s[ \t,]/bfound
    \}
    /^COMMENT.*-----/,/^METHOD:/\{
    	/^COMMENT/h
	s/$/ /
    	/^METHOD.*%s[ \t,]/bfound
    \}
    /^COMMENT.*-----/,/^ROUTINE:/\{
    	/^COMMENT/h
	s/$/ /
    	/^ROUTINE.*%s[ \t,]/\{
	    s/ROUTINE/FUNCTION/
	    bfound
	\}
    \}
    d
    :found
    x
    p
    x
    p
    :ploop
    n
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
    /^[-%%][-%%]*[@\}]$/!\{
	p
	bploop
    \}
    /^[-%%][-%%]*[@\}]$/\{
	p
	q
    \}
\}} $target $target $target $target] $file]
    if {[null $header]} {
    	return nil
    } else {
    	return $header
    }
}]
    
[defcmd ref {target dir} support.reference
{'ref routineName' prints out the routine header for a function. If no function
is given, the function active in the current stack frame is used. This command
locates the function using a tags file, so that tags file should be kept
up-to-date}
{
    #
    # Default to current function if none given
    #
    var tsym [sym find func $target]
    if {[null $tsym]} {
	echo [format {"%s" not a defined function} $target]
    }
    
    echo -n $target...
    flush-output
    var p [symbol patient $tsym]
#XXX
    var file [index [src line $target] 0]
    if {![string match $file /*]} {
	#
	# File not absolute -- tack on the path to the patient's executable
	#
    	var outputfile ${dir}/${file}
	var file [file dirname [patient path $p]]/$file
    } else {
    	var outputfile ${dir}/[range $file [expr [string first [file tail $dir] $file]+[length [file tail $dir] char]+1] end char]
    }
    var header [extract-header $target $file]
    if {[null $header]} {
	error [format {Error: "%s" not in %s as expected} $target $file]
    } else {
    	var outputdir [file dirname $outputfile]
       	if {![file isdirectory $outputdir]} {
	    exec mkdir -p $outputdir
       	}
	var str [stream open $outputfile a]
	if {[null $str]} then {error [format {Could not open %s.} $outputfile]}
	stream write $header $str
	stream write [format {%s proc far\n%s endp\n} $target $target] $str
	stream close $str
    }
}]
[defcmd makeref {patient {dir /staff/pcgeos/refs}} support.reference
{'makeref ' calls ref on ALL functions for a geode. First argument PATIENT is
the patient for which to generate the reference tree. Second optional argument
DIR is the reference directory below which to create the reference tree and
defaults to /staff/pcgeos/refs. E.g. "makeref kernel" would cause files to be
created in the tree /staff/pcgeos/refs/Kernel. All functions exported by the
patient have their headers extracted in the proper form in right shadow file}
{
    global file-root-dir file-default-dir
    
    var p [patient find $patient]
    if {[null $p]} {
    	error [format {patient %s not known} $patient]
    }
    var pdir [file dirname [patient path $p]]
    if {[string first ${file-default-dir} $pdir] == 0} {
	#
	# Patient is in Installed tree. Strip out the Installed to get
	# the source directory.
	#
	var ipos [string first Installed $pdir]
	var subdir [range [range $pdir 0 [expr $ipos-1] char] [expr [length ${file-root-dir} char]+1] end char][range $pdir [expr $ipos+10] end char]
    } else {
	var subdir [range $pdir [expr [length ${file-root-dir} char]+1] end char]
	if {[string match $subdir Installed/*]} {
	    var subdir [range $subdir 10 end char]
	}
    }
    var fn [index [range [patient fullname $p] 0 7 char] 0]
    if {[null $fn]} {
	# kernel's .gp file is geos.gp in 1.0, kernel.gp in 1.2
	if {[null [info global geos-release]]} {
	    var fn geos
	} else {
	    var fn kernel
	}
    }
    var gpfile $fn.gp
    if {![string match $subdir {[A-Z]*}]} {
    	var subdir [range $subdir [expr [string first / $subdir]+1] end char]
    	if {[file exists ${pdir}/${gpfile}]} {
	    var gpfile ${pdir}/${gpfile}
	} else {
	    var gpfile ${file-root-dir}/${subdir}/${gpfile}
	}
    } elif {[file exists ${pdir}/${gpfile}]} {
    	var gpfile ${pdir}/${gpfile}
    } else {
    	var gpfile ${file-root-dir}/${subdir}/${gpfile}
    }
    echo creating reference files from $gpfile under $dir/$subdir
    exec rm -fr $dir/$subdir
    var funcs [exec awk {/^export/ && (NF == 2 || $3 != "as") {print $2} /^export/ && NF == 4 && $3 == "as" {print $4}} $gpfile]
    var missing {}
    sym-default $patient
    foreach i $funcs {
	if {[string match $i *Far]} {
	    var i [range $i 0 [expr [string last Far $i]-1] char]
	}
    	if {[catch {ref $i ${dir}/${subdir}}] != 0} {
	    var missing [concat $missing $i]
	}
    }
    echo
    if {![null $missing]} {
	echo missing functions: $missing
    }
}]
