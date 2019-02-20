##############################################################################
#
# 	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
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
#	$Id: makeref.tcl,v 3.2 90/08/28 12:42:13 adam Exp $
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
    	/%s/bfound
    \}
    /^COMMENT.*-----/,/^FUNCTION:/\{
    	/^COMMENT/h
    	/^FUNCTION.*%s/bfound
    \}
    /^COMMENT.*-----/,/^METHOD:/\{
    	/^COMMENT/h
    	/^METHOD.*%s/bfound
    \}
    /^COMMENT.*-----/,/^ROUTINE:/\{
    	/^COMMENT/h
    	/^ROUTINE.*%s/\{
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
    
[defcommand ref {target dir} reference
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
	var file [file [patient path $p] dirname]/$file
    } else {
    	var outputfile ${dir}/[range $file [expr [string first [file $dir tail] $file]+[length [file $dir tail] char]+1] end char]
    }
    var header [extract-header $target $file]
    if {[null $header]} {
    	echo [format {Error: "%s" not in %s as expected} $target $file]
    } else {
    	var outputdir [file $outputfile dirname]
       	if {![file $outputdir isdirectory]} {
	    exec mkdir -p $outputdir
       	}
	var str [stream open $outputfile a]
	if {[null $str]} then {error [format {Could not open %s.} $outputfile]}
	stream write $header $str
	stream close $str
    }
}]
[defcommand makeref {patient {dir /staff/pcgeos/refs}} reference
{'makeref ' calls ref on ALL functions for a geode. First argument PATIENT is
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
    if {[string match $subdir Installed/*]} {
    	var subdir [range $subdir 10 end char]
    }
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
    } elif {[file ${pdir}/${gpfile} exists]} {
    	var gpfile ${pdir}/${gpfile}
    } else {
    	var gpfile ${file-root}/${subdir}/${gpfile}
    }
    echo creating reference files from $gpfile under $dir/$subdir
    exec rm -fr $dir/$subdir
    var funcs [exec awk {/^export/ && NF == 2 {print $2} /^export/ && NF == 4 {print $4}} $gpfile]
    foreach i $funcs {
    	catch {ref $i ${dir}/${subdir}}
    }
}]
