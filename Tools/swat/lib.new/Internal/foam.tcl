##############################################################################
#
# 	Copyright (c) GeoWorks 1994, 1995 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	Swat -- System Library
# FILE: 	foam.tcl
# AUTHOR: 	Andrew Wilson, Nov 23, 1994
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	atw	11/23/94		Initial Revision
#
# DESCRIPTION:
#	Contains routines to print out info in the foam database
#
#	$Id: foam.tcl,v 1.2 94/12/19 16:43:25 andrew Exp $
#
###############################################################################
[defcmd pfoamrec {args} {}
{Usage:
	pfoamrec <address>
}
{
	if {[null $args]} {
		var args {^hax}
	}
	var addr [addr-parse $args]
	var seg ^h[handle id [index $addr 0]]
	var off [index $addr 1]

	#
	# Print out information about this field
	#
	var id [value fetch $seg:$off.foamdb::RH_id]
	var numFields [value fetch $seg:$off.foamdb::RH_fieldCount]
	echo [format {Record #%d (%d fields)} $id $numFields]
	var off [expr $off+[size foamdb::RecordHeader]]
	
	#
	# Print out all the fields
	#
	while {$numFields != 0} {
	    var id [value fetch $seg:$off.foamdb::FH_id]
	    var token [value fetch $seg:$off.foamdb::FH_nameToken]
	    var type [value fetch $seg:$off.foamdb::FH_type]
	    var dataSize [value fetch $seg:$off.foamdb::FH_size]
	    var off [expr $off+[size foamdb::FieldHeader]]
	    var type [type emap $type [sym find type contdb::ContdbFieldType]]
	    echo -n [format {   Field #%d: nameToken = %d, } $id, $token]
	    echo -n $type {: }
	    if {$dataSize == 0} {
	    	echo <No data>
	    } else {
		var maxSize 30
	        if {$dataSize < $maxSize} {
			var maxSize $dataSize
		}
	        pstring -s -l $maxSize $seg:$off
		if {$dataSize != $maxSize} {
		    echo -n ...
		}
		echo {}
	    }
	    #
	    # Go to the next field
	    #
	    var off [expr $off+$dataSize]
	    var numFields [expr $numFields-1]
	}
}]


