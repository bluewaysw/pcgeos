##############################################################################
#
# 	Copyright (c) GeoWorks 1993 -- All Rights Reserved
#
# PROJECT:	
# MODULE:	
# FILE: 	doc.tcl
# AUTHOR: 	Joon Song, Jun 28, 1993
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#       doc
#       doc-next
#       doc-previous
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	JS	6/28/93   	Initial Revision
#
# DESCRIPTION:
#	Functions to tag the tech docs.
#
#	$Id: doc.tcl,v 1.16 97/06/26 14:12:39 ron Exp $
#
###############################################################################

##############################################################################
#	doc
##############################################################################
#
# SYNOPSIS:	Find technical documentation
# PASS:		keyword
# CALLED BY:	swat command line
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JS 	7/29/93   	Initial Revision
#
##############################################################################
[defcmd doc {keyword} top.support
{Usage:
    doc [<keyword>]

Examples:
    "doc MSG_VIS_OPEN"	- brings up technical documentation for MSG_VIS_OPEN

Synopsis:
    Find technical documentation for <keyword>.

See also:
    doc-next, doc-previous
}
{
    global file-os repeatCommand tagNumber tagList file-syslib-dir file-root-dir

    if {[string c ${file-os} unix] == 0} {
        catch {bingrep $keyword /staff/pcgeos/Tools/swat/lib.new/doctags 101} tagList
    } elif {[string c ${file-os} dos] == 0} {
	catch {bingrep $keyword ${file-syslib-dir}/DOCTAGS 102} tagList
    } else {
	#
	# The doctag file is going away.
	# If it is gone, tell the user to look at the html docs
	if [file exists ${file-root-dir}/Tools/swat/lib.new/doctags] {
	    catch {bingrep $keyword ${file-root-dir}/Tools/swat/lib.new/doctags 101} tagList
	    if {[string c $tagList RECORD_SIZE_PROBLEM] == 0} {
		# try dos style doctags file now, because unix style had a problem
		catch {bingrep $keyword ${file-root-dir}/Tools/swat/lib.new/doctags 102} tagList
	    }
	} else {
	    echo The docs have been converted to HTML and are viewable through a browser.
	    return
	}
    }
    if {[string c $tagList RECORD_SIZE_PROBLEM] == 0} {
	echo doctags file size is not a multiple of record size
	return
    } elif {$tagList == {} } {
	echo No documentation has been found for '$keyword'.
	return
    }

    var tagNumber 0
    
    echo [expr $tagNumber+1] of [length $tagList]
    docDisplay [index $tagList $tagNumber]
    if {[length $tagList] > 1} {
	var repeatCommand doc-next
    }
}]


[defcmd doc-next { } top.support
{Usage:
    doc-next

Examples:
    "doc MSG_VIS_OPEN"	- brings up technical documentation for MSG_VIS_OPEN
    "doc-next"		- brings up more info on MSG_VIS_DRAW if available

Synopsis:
    Bring up next instance of documentation for the current keyword.

See also:
    doc, doc-previous
}
{
    global repeatCommand tagNumber tagList
    if {$tagList=={}} {
	echo You must use the command 'doc' first.
	return
    }
    if {[expr $tagNumber+1]==[length $tagList]} {
	echo No more information.
    } else {
	var tagNumber [expr $tagNumber+1]
	echo [expr $tagNumber+1] of [length $tagList]
	docDisplay [index $tagList $tagNumber]
	var repeatCommand doc-next
    }
}]


[defcmd doc-previous { } top.support
{Usage:
    doc-previous

Examples:
    "doc MSG_VIS_OPEN"	- brings up technical documentation for MSG_VIS_OPEN
    "doc-next"		- brings up more info on MSG_VIS_DRAW if available
    "doc-previous"	- brings up previous info on MSG_VIS_OPEN

Synopsis:
    Bring up previous instance of documentation for the current keyword.

See also:
    doc, doc-next
}
{
    global repeatCommand tagNumber tagList
    if {$tagList=={}} {
	echo You must use the command 'doc' first.
	return
    }
    if {$tagNumber==0} {
	echo No more information.
    } else {
	var tagNumber [expr $tagNumber-1]
	echo [expr $tagNumber+1] of [length $tagList]
	docDisplay [index $tagList $tagNumber]
	var repeatCommand doc-previous
    } 
}]


proc docDisplay { tagLine } {
    global file-os doc_linenum file-syslib-dir file-root-dir

    scan $tagLine {%[^:]:%[^:]:%d} junk filename doc_linenum
    
    if {[string c ${file-os} unix] == 0} {
	view /staff/pcgeos/TechDoc/Ascii/$filename $doc_linenum 0
    } elif {[string c ${file-os} win32] == 0} {
	var res {}
	catch {view ${file-root-dir}/Techdocs/Ascii/$filename $doc_linenum 0} res
	if {[string match $res File*] == 1} {
	    view s:/pcgeos/TechDoc/Ascii/$filename $doc_linenum 0
	} else {
	    if {![null $res]} {
		error $res
	    }
	} 
    } else {
	# msdos case
	view ${file-syslib-dir}/../techdocs/ascii/$filename $doc_linenum 0
    }
}


##############################################################################
#	bingrep
##############################################################################
#
# SYNOPSIS:	Do a binary search through a sorted file.
# PASS:		<keyword> - keyword to search for
#		<filename> - filename to search in
#		<recordsize> - length of each record
# CALLED BY:	doc
# RETURN:	tag lines
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       JS 	7/29/93   	Initial Revision
#
##############################################################################
[defsubr bingrep {keyword filename recordsize} {
    var filestream [stream open $filename r]

    if {$filestream == nil} {
	echo $filename could not be opened.
	return {}
    }

    var filesize [stream seek end $filestream]
    var numrecords [expr $filesize/$recordsize]
    var linenum [expr $numrecords/2]

    if {[expr $numrecords*$recordsize] != $filesize} {
	return RECORD_SIZE_PROBLEM
    } else {
	var linenum [binsearch $filestream $linenum 0 $numrecords $recordsize $keyword]
	if {$linenum >= 0} {
	    var linenum [expr $linenum-1]
	    while {$linenum >= 0} {
		stream seek [expr $linenum*$recordsize] $filestream
		var tagline [stream read line $filestream]
		scan $tagline {%[^:]} tag
		if {$tag == $keyword} then {
		    var linenum [expr $linenum-1]
		} else {
		    break
		}
	    }

	    var linenum [expr $linenum+1]
	    stream seek [expr $linenum*$recordsize] $filestream

	    while {1} {
		var tagline [stream read line $filestream]
		scan $tagline {%[^:]} tag
		if {$tag == $keyword} then {
		    scan $tagline {%s} tagline
		    var matchlines [concat $matchlines $tagline]
		} else {
		    break
		}
	    }
	}
    }

    stream close $filestream
    return $matchlines
}]

[defsubr binsearch {filestream current first last recordsize keyword} {
    if {$first > $last} {
	return -1
    }

    stream seek [expr $current*$recordsize] $filestream
    var tagline [stream read line $filestream]
    scan $tagline {%[^:]} tag
    var comparison [string compare $tag $keyword]

    if {$comparison == 0} then {
	return $current
    } elif {$comparison > 0} then {
	return [binsearch $filestream [expr ($first+$current)/2]
			  $first [expr $current-1] $recordsize $keyword]
    } else {
	return [binsearch $filestream [expr ($last+$current+1)/2]
			  [expr $current+1] $last $recordsize $keyword]
    }
}]
