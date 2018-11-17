##############################################################################
#
# 	Copyright (c) GeoWorks 1992 -- All Rights Reserved
#
# PROJECT:	PC/GEOS
# MODULE:	Tools
# FILE: 	makedisk.tcl
# AUTHOR: 	Eric E. Del Sesto, 11/6/92
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	mdwatch			Set breakpoints to monitor MakeDisk's progress
#					(or lack thereof)
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	eds	11/6/92		Initial Revision
#
# DESCRIPTION:
#	
#	$Id: makedisk.tcl,v 1.4.12.1 97/03/29 11:25:46 canavese Exp $
#
###############################################################################

[defcommand mdwatch {} support.makedisk
{Usage:
    mdwatch

Examples:
    "mdwatch"	   	

Synopsis:
	Print messages at various points in execution.

Notes:

See also:
}

{
	#
	# These weird indents are intentional, to show the nesting of
	# the corresponding MakeDisk code.
	#

	# MakeDiskSetVerifyFile
	#	VerifyLoadFile
	#	MakeDiskFinishInitialization
	#		TreeBuild
	#			TreeBuildTreeLow
	#			TreeBuildTreeLow::fileLoop
	#		MakeDiskAllocSet
	#		VerifyProcessFile
	#			VerifyProcessPath
	#			VerifyProcessPath::findFileNameEnd2
	#		VerifyDisplayErrors
	#	MakeDiskFinishInitialization::addTOCFileNode::
	#	MakeDiskFinishInitialization::sortNodeArray::
	#

	[brk makedisk::VerifyLoadFile
	  {print-vlf}]

	[brk makedisk::TreeBuild
	  {print-tb}]


#	[brk makedisk::TreeBuildTreeLow::fileLoop
#	  {print-tbtl-file-loop}]

#	[brk makedisk::VerifyProcessFile
#	  {print-vpf}]

		[brk makedisk::VerifyProcessPath::findFileNameEnd2
		  {print-vpp-filename}]

	[brk makedisk::MakeDiskFinishInitialization::addTOCFileNode
	  {print-mdfi-add-toc-file-node}]

	[brk makedisk::MakeDiskFinishInitialization::sortNodeArray
	  {print-mdfi-sort-node-array}]

	#[brk makedisk::MakeDiskFinishInitialization::done
	#  {print-mdfi-done}]

	#
	# Making a disk set...
	#

	[brk makedisk::MakeDiskSet
	  {print-makediskset-start}]

	[brk makedisk::TreeBuildArray
	  {print-tba-make-disk-show-raw-size}]

		[brk makedisk::TreeBuildArrayForThisDiskUsingNodeArray::debug
		  {print-tbaftduna-make-disk-show-eff-size}]

			[brk makedisk::BuildArray_Callback::debug
			  {print-tbaftduna-callback}]

	[brk makedisk::MakeDiskSet::diskLoopDone
	  {print-makediskset-ask-user}]

	[brk makedisk::MakeDiskSet::createVMFile
	  {print-makediskset-create-vm-file}]

		[brk makedisk::MDMakeDisk
		  {print-mdmakedisk-start}]
		
	[brk makedisk::MakeDiskSet::convertVMFile
	  {print-makediskset-convert-vm-file}]

	[brk makedisk::MakeDiskSet::deleteVMFile
	  {print-makediskset-delete-vm-file}]

	[brk makedisk::MakeDiskSet::notifyDone
	  {print-makediskset-notify-done}]

	[brk makedisk::MakeDiskSet::done
	  {print-makediskset-done}]


		[brk makedisk::MDCopyFile::aboutToCopy
		  {print-mdcopyfile-about-to-copy}]

#		[brk makedisk::MDCopyFile::checkError
#		  {print-mdcopyfile-check-copy-errors}]

}]


[defsubr print-vlf {} {
	echo {Loading .CFG file...}
	return 0
}]


[defsubr print-tb {} {
	echo {Building Tree...}
	return 0
}]


[defsubr print-tbtl-file-loop {} {
	echo -n {  file: }
	pstring ds:si.TERS_longName
	return 0
}]


[defsubr print-vpf {} {
	echo {Verifying .CFG file...}
	return 0
}]


[defsubr print-vpp-filename {} {
	echo -n {  file: }
	pstringtocr ds:si-1
	return 0
}]


[defsubr print-mdfi-add-toc-file-node {} {
	echo {Adding .TOC file node to tree...}
	return 0
}]


[defsubr print-mdfi-sort-node-array {} {
	echo {Sorting Node Array...}
	return 0
}]


[defsubr print-makediskset-start {} {
	echo ##################################################################
	echo Calculating Disk set Geometry...
	return 0
}]


[defsubr print-tba-make-disk-show-raw-size {} {
	echo
	echo [format {  Analyzing Disk #%d:}
		[value fetch ds:MDLMBH_diskNumber word]
		[read-reg bx]
	     ]
	echo [format {    Total size of disk:     %d}
		[expr [expr [read-reg cx]*65536]+[read-reg dx]]
	     ]
	return 0
}]


[defsubr print-tbaftduna-make-disk-show-eff-size {} {
	echo [format {    Effective size of disk: %d  (total size - reserved space on this disk)}
		[expr [expr [read-reg cx]*65536]+[read-reg dx]]
	     ]
	return 0
}]


[defsubr print-tbaftduna-callback {} {
	echo -n {      }
	pstring2 ds:di.TN_geosName
	echo [format {	(size=%d, remaining=%d)}
		[value fetch ds:di.TN_size dword]
		[expr [expr [read-reg cx]*65536]+[read-reg dx]]
	     ]
	return 0
}]


[defsubr print-makediskset-ask-user {} {
	echo Asking you if we should continue (look at your PC, stupid :)
	return 0
}]


[defsubr print-makediskset-create-vm-file {} {
	echo Creating VM file...
	return 0
}]


[defsubr print-mdmakedisk-start {} {
	echo [format {  Making Disk #%d:}
		[value fetch ds:MDLMBH_diskNumber word]
	     ]
	return 0
}]


[defsubr print-mdcopyfile-about-to-copy {} {
	echo -n {    Copying: }
	pstring ds:si
	#echo -n {      Before copy: cwd = }
	#dirs
	return 0
}]


#[defsubr print-mdcopyfile-check-copy-errors {} {
#	echo -n {      After copy:  cwd = }
#	dirs
#	echo
#	return 0
#}]


[defsubr print-makediskset-convert-vm-file {} {
	echo Converting VM file...
	return 0
}]

[defsubr print-makediskset-delete-vm-file {} {
	echo Closing and deleting VM file...
	return 0
}]

[defsubr print-makediskset-notify-done {} {
	echo Telling you that I'm done..
	return 0
}]

[defsubr print-makediskset-done {} {
	echo Disk set complete.
	echo ##################################################################
	return 0
}]





[defsubr pstring2 addr {
    addr-preprocess $addr s o

    [for {var c [value fetch $s:$o [type byte]]}
	 {$c != 0}
	 {var c [value fetch $s:$o [type byte]]}
    {
        echo -n [format %c $c]
        var o [expr $o+1]
    }]
}]

[defsubr pstringtocr addr {
    addr-preprocess $addr s o

    [for {var c [value fetch $s:$o [type byte]]}
	 {$c != 13}
	 {var c [value fetch $s:$o [type byte]]}
    {
        echo -n [format %c $c]
        var o [expr $o+1]
    }]
    echo {}
}]

