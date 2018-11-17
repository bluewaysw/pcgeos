##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	Irlmp
# MODULE:	
# FILE: 	irlmp.tcl
# AUTHOR: 	Andy Chiu, Apr 11, 1996
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	AC	4/11/96   	Initial Revision
#
# DESCRIPTION:
#	* pias command to look at the ias database
#       
#
#	$Id: irlmp.tcl,v 1.1.6.1 97/03/29 11:27:31 canavese Exp $
#
###############################################################################
require carray-enum chunkarr.tcl
require map-file-to-vm-handle   vm.tcl
require fmt-string rtcm.tcl

[defcommand pias {args} {top.print}
{Usage:
	pias [<flags>]

	  -a print out attribute info

Synopsis:
	Prints out contents of the IAS database.

}
{

    var attrs 0

    while {[string m [index $args 0] -*]} {
	#
	# Gave us some flags
	#
    	var arg [range [index $args 0] 1 end chars]
    	while {![null $arg]} {
	    [case [range $arg 0 0 chars] in
		a {var attrs 1}
		default {error [format {unknown option %s} $i]}
	       ]
    	    if {![null $arg]} {
    	    	var arg [range $arg 1 end chars]
    	    }
    	}
	var args [cdr $args]
    }

    #
    # Get the map block from the file.  Make sure the header is resident
    #
    sd irlmp
    var fhandle [value fetch irlmp::irdbFileHandle]
    var file [map-file-to-vm-handle $fhandle]
    ensure-vm-block-resident $file [getvalue geos::VMH_blockTable]
    var mapblock [get-map-block-from-vm-file $file]
    ensure-vm-block-resident $file $mapblock
    var objArrayHandle [value fetch ^v$file:$mapblock.irlmp::IFMB_objArrayVMBlockHandle]
    var objArrayChunk [value fetch ^v$file:$mapblock.irlmp::IFMB_objArrayChunkHandle]
    #
    # Load and get the object array into memory
    #
    ensure-vm-block-resident $file $objArrayHandle
    var addr [addr-parse *(^v$file:$objArrayHandle):$objArrayChunk]
    var seg [handle segment [index $addr 0]]
    var off [index $addr 1]
    #
    # Loop through each object in the array and print out the
    # details.
    # 
    carray-enum $seg:$off print-irdb-object [concat $fhandle $attrs]
    
}
]

##############################################################################
#	print-irdb-object
##############################################################################
#
# SYNOPSIS:	Prints information about an irdb object
# CALLED BY:	pias vai carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of style
#   	    	extra	- List containing:
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       AC 	4/ 9/96   	Initial Revision
#
##############################################################################
[defsubr    print-irdb-object {elnum addr rsize extra} {

    echo {-------------------- Object --------------------}
    echo {Object ID     :} $elnum
    echo {Object Name   :} [fmt-string -l [value fetch $addr.irlmp::IOAE_classNameSize] $addr.irlmp::IOAE_className]
    var file [index $extra 0]
    var attrs [index $extra 1]

    #
    # If you want to see the attributes, do the below
    # 
    if {$attrs} {
	#
	# list out the attributibutes associated with the object
	#
	var attrBlock [value fetch $addr.irlmp::IOAE_attrsBlockHandle]
	var attrChunk [value fetch $addr.irlmp::IOAE_attrsChunkHandle]

	if {$attrBlock} {
	    ensure-vm-block-resident $file $attrBlock
	    var attrAddr [addr-parse *(^v$file:$attrBlock):$attrChunk]
	    var seg [handle segment [index $attrAddr 0]]
	    var off [index $attrAddr 1]
	    carray-enum $seg:$off print-irdb-attributes $file
	}
    }
    return 0
}]

##############################################################################
#	print-irdb-attributes
##############################################################################
#
# SYNOPSIS:	Print the attributes array
# CALLED BY:	print-irdb-object via carray-enum
# PASS:		elnum	- Element number (region number)
#   	    	addr	- Address expression of region
#   	    	rsize	- Size of style
#   	    	extra	- List containing:
# RETURN:	0
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       AC 	4/10/96   	Initial Revision
#
##############################################################################
[defsubr    print-irdb-attributes {elnum addr rsize extra} {

    #
    # Get the lptr to the attribute name and find the size
    #
    var attrName [value fetch $addr.irlmp::IAAE_attrName]
    var attrNameSize [value fetch $addr.irlmp::IAAE_attrNameSize]

    #
    # Get the segment and offset of the attribute structure
    #
    var a [addr-parse $addr]
    var seg [handle segment [index $a 0]]
    var off [index $a 1]

    #
    # Make the attribute label prefix
    #
    var attrPrefix [concat {Attr} #$elnum]

    #
    # Print out the attribute name and type
    #
    echo $attrPrefix {Name  :} [fmt-string -l $attrNameSize *$seg:$attrName]
    var attrType [value fetch $addr.IAAE_attrType]
    echo $attrPrefix {Type  :} [penum irlmp::IrlmpIasValueType $attrType]


    #
    # Print out the details of the attribute
    #
    if {$attrType == [getvalue IIVT_INTEGER]} {
	# Integer attribute.  The value is stored in network
	# order, so we have to munge it a little bit.

	var valueaddr $addr+[expr [getvalue IAAE_attrData]+[getvalue AD_integer]]
	var firstword $valueaddr+2
	var firstword $value
	var firstword [expr [value fetch $valueaddr [type byte]]*0x100+[value fetch $valueaddr+1 [type byte]]]

	var secondword [expr [value fetch $valueaddr+2 [type byte]]*0x100+[value fetch $valueaddr+3 [type byte]]]
	echo $attrPrefix {Value :} [format {%04xh} $firstword]:[format {%04xh} $secondword]

    } elif {$attrType == [getvalue IIVT_USER_STRING]} {
	# User string attribute
	echo $attrPrefix {C-set :} [value fetch $addr.IAAE_attrData.USD_charSet]
	
	var length [value fetch $addr.IAAE_attrData.USD_size]
	var attrString [fmt-string -l $length 
			*$seg:[value fetch $addr.IAAE_attrData.USD_data]]
	echo $attrPrefix {Value :} $attrString
    } elif {$attrType == [getvalue IIVT_OCTET_SEQUENCE]} {
	# Octet sequence attribute
	var size [value fetch $addr.IAAE_attrData.OSD_size]
	echo $attrPrefix {Size  :} $size
	var octets \{
	for {var i 0} {$i < $size} {var i [expr $i+1]} {
	    if {! ($i == 0)} {
		var octets $octets,
	    }
	    var data [value fetch $seg:$off.IAAE_attrData.OSD_data]
	    var octets $octets[format {%02xh} [value fetch *$seg:$data+$i [type byte]]]
	}
	var octets $octets\}
	echo $attrPrefix {Value :} $octets
    }

    return 0
}]









