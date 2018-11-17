##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#
# PROJECT:	IP address resolver
# MODULE:	Resolver
# FILE: 	resolver.tcl
# AUTHOR: 	Steve Jang, Jul 29, 1996
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#	p-rescache		print resolver cache
#	p-resreq		print resolver request tree
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	SJ	7/29/96   	Initial Revision Based on clee's code
#
# DESCRIPTION:
#	Tcl code to print out resources used in resolver.
#
#
#	$Id: resolver.tcl,v 1.5 96/09/12 15:29:50 jang Exp $
#
###############################################################################

##############################################################################
#	p-rescache
##############################################################################
#
# SYNOPSIS:	Prints out information on resolver's cache
# PASS:		optional arguments( see help file )
# CALLED BY:	COMMAND
# RETURN:	nothing
# SIDE EFFECTS:	patient switched to resolver
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	7/30/96   	Initial Revision
#
##############################################################################
[defhelp resolver top.socket 
{commands to display resolver information}]
[defcommand p-rescache {args} top.socket.resolver
{Usage:
    p-rescache <options>+
Examples:
    p-rescache
    p-rescache addr
    p-rescache rr
    p-rescache addr rr
Synopsis:
    Print out contents of resolver cache in tree representation.
Notes:
    Options:
	addr	print out optrs for each node as resource records
	rr	print out resource records
}
{
	#
	# find resolver cache handle and display it
	#
	sw resolver
	var blockHandle [value fetch ResolverCacheBlock [type word]]
	var blockHandle [format {0x%x} $blockHandle]
	echo
	echo cache block: $blockHandle
	echo

	#
	# alias
	#
	var address {^l$blockHandle:$cur}

	#
	# get root
	#
	var cur [value fetch ^h$blockHandle:CBH_root [type word]]
	var depth 0
	print_rr_node $blockHandle $cur $depth $args
	var treeFlag [value fetch $address.RRN_tree.NC_flags NodeFlags]
	if {[field $treeFlag NF_HAS_CHILD]==0} {
	   echo nothing in the cache
	   return
	}
	var cur [value fetch $address.RRN_tree.NC_child [type word]]
	var cur [format {0x%x} $cur]
	echo ROOT
	if {[member addr $args]} {echo ($blockHandle:$cur)}

	#
	# traverse all nodes
	#
	var direction down
	for {var depth 1} {$depth != 0} {} {

	   #
	   # print stuff if this is the first visit of the node
	   #
	   if {$direction == down} {
	      print_rr_node $blockHandle $cur $depth $args}
	   #
	   # if there is a child, go down
	   #
	   var treeFlag [value fetch $address.RRN_tree.NC_flags NodeFlags]
	   if {[field $treeFlag NF_HAS_CHILD]==1 && $direction==down} {
	      var depth [expr {$depth + 1}]
	      var direction down
	      var cur [value fetch $address.RRN_tree.NC_child [type word]]
	      var cur [format {0x%x} $cur]
	      continue}

	   #
	   # if there is a sibling, go side ways
	   #
	   var cur [value fetch $address.RRN_tree.NC_next [type word]]
	   var cur [format {0x%x} $cur]
	   [if {[field $treeFlag NF_LAST] == 0} then {
	       var direction down}
	    else {
	       var direction up
	       var depth [expr {$depth - 1}]
	    }]}
}]

##############################################################################
#	print_rr_node
##############################################################################
#
# SYNOPSIS:	print out a resource record node
# PASS:		block = cache block handle
#		chunk = current node chunk handle
#		depth = tree depth of the node
#		arglist = arguments passed in by the caller
# CALLED BY:	p-rescache
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	7/31/96   	Initial Revision
#
##############################################################################
[defsubr    print_rr_node {block chunk depth arglist} {
	#
 	# get label length
 	#
 	addr-preprocess ^l$block:$chunk segaddr offset
 	[var len [value fetch $segaddr:$offset.RRN_name [type byte]]]

	#
	# print the node label
	#
 	var offset [expr $offset+1]
	var spacing [make_spacing $depth]
	echo -n $spacing
	pstring -l $len $segaddr:$offset.RRN_name

	#
	# print address if addr arg is given
	#
	if {[member addr $arglist]} {echo $spacing ($block:$chunk)}

	#
	# print resource records if rr arg is given
	#
	if {[member rr $arglist]} {
	    print_rr_list $block $chunk $depth $arglist}
}]

##############################################################################
#	print_rr_list
##############################################################################
#
# SYNOPSIS:	print a list of resource records
# PASS:		block = cache block handle
#		chunk = current node chunk handle
#		depth = tree depth of the node
#		arglist = arguments passed in by the caller
# CALLED BY:	nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	7/31/96   	Initial Revision
#
##############################################################################
[defsubr    print_rr_list {block chunk depth arglist} {
	#
	# aliases, spacing, etc
	#
	var address {$segaddr:$offset}
	var spacing [make_spacing $depth]
	#
	# get the first element
	#
 	var rrblock [value fetch ^l$block:$chunk.RRN_resource.high [type word]]
 	var rrchunk [value fetch ^l$block:$chunk.RRN_resource.low [type word]]
	#
	# traverse the linked list
	#
	for {} {[expr $rrblock!=0]} {} {
	   #
	   # get resource record type
	   #
	   addr-preprocess ^l$rrblock:$rrchunk segaddr offset
	   var rrtype [value fetch $address.RR_common.RRC_type [type word]]
	   var rrtype [type emap $rrtype [sym find type ResourceRecordType]]
	   #
	   # print rr data
	   #
	   echo -n $spacing {      }
	   if ([member addr $arglist]==1) {
	      var $rrblock [format 0x%x $rrblock]
	      var $rrchunk [format 0x%x $rrchunk]
	      echo -n (^l$rrblock:$rrchunk) { }}
	   print_rr_data $rrtype $rrblock $rrchunk
	   #
	   # go to next RR
	   #
	   var rrblock [value fetch $address.RR_next.high [type word]]
	   var rrchunk [value fetch $address.RR_next.low [type word]]
	   }
}]

##############################################################################
#	print_rr_data
##############################################################################
#
# SYNOPSIS:	Prints a resource record entry
# PASS:		spacing	= indentation
#		rrtype  = ResourceRecordType
#		address = address
# CALLED BY:	print_rr_list
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	8/ 1/96   	Initial Revision
#
##############################################################################
[defsubr    print_rr_data {rrtype rrblock rrchunk} {
	addr-preprocess ^l$rrblock:$rrchunk segaddr offset
	echo -n $rrtype {: }
	[case $rrtype in
	 RRT_A	   {
		     echo -n [format {%d.}
				[value fetch 
				   $segaddr:$offset.RR_data [type byte]]]
		     var offset [expr $offset+1]
		     echo -n [format {%d.} 
				[value fetch
				   $segaddr:$offset.RR_data [type byte]]]
		     var offset [expr $offset+1]
		     echo -n [format {%d.}
				[value fetch 
				   $segaddr:$offset.RR_data [type byte]]]
		     var offset [expr $offset+1]
		     echo    [format %d 
				[value fetch 
				   $segaddr:$offset.RR_data [type byte]]]
		    }
	 RRT_NS	   { 
		     var offset [expr $offset+1]
		     pstring $segaddr:$offset.RR_data
		    }
	 RRT_CNAME {
		     var offset [expr $offset+1]
		     pstring $segaddr:$offset.RR_data
		    }
	 default   { echo }]
}]

##############################################################################
#	display-request
##############################################################################
#
# SYNOPSIS:	display request hierarchy in resolver
# PASS:		nothing
# CALLED BY:	COMMAND
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	8/ 5/96   	Initial Revision
#
##############################################################################
[defcmd    display-request {args} top.socket.resolver
{
Usage:
    display-request <options>+
Examples:
    display-request
    display_request addr
Synopsis:
    displays the request hierarchy in ResolverRequestBlock
Options:
    addr displays addresses of the nodes
}
{
	#
	# find resolver cache handle and display it
	#
	sw resolver
	var blockHandle [value fetch ResolverRequestBlock [type word]]
	var blockHandle [format {0x%x} $blockHandle]
	echo
	echo request block: $blockHandle
	echo

	#
	# alias
	#
	var address {^l$blockHandle:$cur}

	#
	# get root
	#
	var cur [value fetch ^h$blockHandle:RBH_root [type word]]
	var treeFlag [value fetch $address.RN_tree.NC_flags NodeFlags]
	if {[field $treeFlag NF_HAS_CHILD]==0} {
	   echo no request found
	   return
	}
	var cur [value fetch $address.RN_tree.NC_child [type word]]
	var cur [format {0x%x} $cur]
	echo ROOT
	if {[member addr $args]} {echo ($blockHandle:$cur)}

	#
	# traverse all nodes
	#
	var direction down
	for {var depth 1} {$depth != 0} {} {

	   #
	   # print stuff if this is the first visit of the node
	   #
	   if {$direction == down} {
	      p_request $blockHandle $cur $depth $args
	   }
	   #
	   # if there is a child, go down
	   #
	   var treeFlag [value fetch $address.RN_tree.NC_flags NodeFlags]
	   if {[field $treeFlag NF_HAS_CHILD]==1 && $direction==down} {
	      var depth [expr {$depth + 1}]
	      var direction down
	      var cur [value fetch $address.RN_tree.NC_child [type word]]
	      var cur [format {0x%x} $cur]
	      continue}

	   #
	   # if there is a sibling, go side ways
	   #
	   var cur [value fetch $address.RN_tree.NC_next [type word]]
	   var cur [format {0x%x} $cur]
	   [if {[field $treeFlag NF_LAST] == 0} then {
	       var direction down}
	    else {
	       var direction up
	       var depth [expr {$depth - 1}]
	    }]}
}]

##############################################################################
#	p_request
##############################################################################
#
# SYNOPSIS:	print out a request node
# PASS:		block handle, chunk handle, tree depth, arguments
# CALLED BY:	nothing
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	8/ 5/96   	Initial Revision
#
##############################################################################
[defsubr    p_request {blockHandle chunk depth arglist } {
	#
	# print address if argument specifies so.
	#
	var blockHandle [format 0x%x $blockHandle]
	var chunk [format 0x%x $chunk]
	if {[member addr $arglist]} {
		echo (^l$blockHandle:$chunk)
	}
	#
	# print out basic information
	#
	addr-preprocess ^l$blockHandle:$chunk segaddr offset
	var id [value fetch $segaddr:$offset.RN_id [type word]]
	var qtype [value fetch $segaddr:$offset.RN_stype [type word]]
	var qtype [type emap $qtype [sym find type ResourceRecordType]]
	echo -n ID: $id QTYPE: $qtype Question:
	pstring $segaddr:$offset.RN_name
	var slist [value fetch $segaddr:$offset.RN_slist [type word]]
	pcarray -tSlistElement ^l$blockHandle:$slist
	echo ---------------------------------------------------------
}]


###############################################################################
#
# Temporary Debugging feature
#
###############################################################################

##############################################################################
#	replace-packet
##############################################################################
#
# SYNOPSIS:	Replaces a packet 
# CALLED BY:	COMMAND
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       SJ 	8/ 2/96   	Initial Revision
#
##############################################################################
[defcommand replace-packet {rtype segreg offsetreg} {top.socket.resolver}
{Usage:
    replace-packet <rtype> <segreg> <offsetreg>
Examples:
    replace-packet delegation es di
    replace-packet cname es di
    replace-packet error es di
Synopsys:
    Overrides the response from DNS with a predefined packet.
Note:
  RTypes:
    delegation - this response contains other name servers to query rather than
                 the answer
}
{
#
# SK means to leave the contents of the reply packet
#    all the digits are in hex
#

#
# the following packet delegates any query for xxxx.cs.washington.edu
# to ns.unet.umn.edu or trout.cs.washington.edu
#
	var delegation_packet {
	    SK SK SK SK
	    00 00 00 00
	    02 00 00 00
	    02 63 73 0a 57 41 53 48 49 4e 47 54 4f 4e 03 65 64 75 00
	    02 00 01 00 43 1d 00 01 19 00
	    05 74 72 6f 75 74 02 63 73
	    0a 77 61 73 68 69 6e 67 74 6f 6e 03 65 64 75 00
	    02 63 73 0a 57 41 53 48 49 4e 47 54 4f 4e 03 65 64 75 00
	    02 00 01 00 43 1d 00 01 11 00
	    02 6e 73 04 75 6e 65 74 03 75 6d 6e 03 65 64 75 00
	}   
	#
	# set up
	#
	var segaddr [read-reg $segreg]
	var offset [read-reg $offsetreg]
	var new_packet { SK SK }
	echo [format 0x%x $segaddr]:[format 0x%x $offset]
	echo {rtype:  } $rtype
	[case $rtype in
	  delegation {var new_packet $delegation_packet}
	  cname      {var new_packet $cname_packet}
	  default    {var new_packet { SK SK }}]
	#
	# go through the memory replacing each byte
	#
	var len [length $new_packet]
	echo {length: } $len
	for {var i 0} {$i < $len} {var i [expr $i+1]
				   var offset [expr $offset+1]} {
	var cur [index $new_packet $i]
	[if { $cur==SK } {continue} else {
	 #
	 # copy the byte into current memory location
	 #
	 value store $segaddr:$offset 0x$cur [type byte]
	 }]}}]

#
# Useful swat patches( well, write routines for these later... )
#
# print out NS queried:
#
# QueryNameServerCallback+15
# > echo -n {querying name server: }
# > var segaddr [read-reg ds]
# > var offset [read-reg di]
# > var offset [value fetch $segaddr:$offset.SE_serverName [type word]]
# > var offset [value fetch $segaddr:$offset.SE_serverName [type word]]
# > var offset [value fetch $segaddr:$offset [type word]]
# > pstring $segaddr:$offset
#


###############################################################################
# 
# Utility functions
#
###############################################################################
[proc null_func args {}]

[proc make_spacing depth {
 var spacing {}
 for {var i 0} {$i < $depth} {var i [expr $i+1]} {
     var spacing [concat $spacing {   }]}
 return $spacing}]

[proc member {element group} {
    [foreach elt $group {
	if [expr {$elt == $element}] {return 1}}]
    return 0}]






