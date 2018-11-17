##############################################################################
#
# 	Copyright (c) GeoWorks 1991 -- All Rights Reserved
#
# PROJECT:	PC GEOS
# MODULE:	pkmap.tcl
# FILE: 	pkmap.tcl
# AUTHOR: 	Gene Anderson, Jun 28, 1991
#
# COMMANDS:
# 	Name			Description
#	----			-----------
#   	pkmap	    	    	print keyboard map in assembly-language form
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
# DESCRIPTION:
#	
#
#	$Id: pkmap.tcl,v 1.7.12.1 97/03/29 11:25:05 canavese Exp $
#
###############################################################################

##############################################################################
#				pkmap
##############################################################################
#
# SYNOPSIS:	Print out a keyboard map in assembly-language form
# PASS:		addr - ptr to KeyboardTable
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defcmd pkmap {addr filename} lib_app_driver.keyboard
{Usage:
    pkmap <addr> <filename>

Examples:
    "pkmap ds:si /tmp/kmap"

Synopsis:
    Prints a keyboard map in assembly-language format.

See also:
    <none>
}
{
    global  kout
    var kout [stream open $filename w]

    protect {
    	#
        # emit KbdConvHeader
        #
    	echo {header...}
        emit_header $addr
        #
        # extended scan codes and ExtendedScanDef table
        #
    	echo {extended scan codes...}
        emit_extscans $addr
        #
        # KeyDef table
        #
    	echo {key defs...}
        emit_keydefs $addr
        #
        # ExtendedDef table
        #
    	echo {extended key defs...}
        emit_extdefs $addr
        #
        # Accentables table
        #
    	echo {accentables...}
        emit_accentables $addr
        #
        # Accents
        #
    	echo {accents...}
        emit_accents $addr
    } {
    	stream close $kout
    }
}]

##############################################################################
#				secho
##############################################################################
#
# SYNOPSIS:	Echo string to stream $kout
# PASS:		-n - optional flag to supress new line
#   	    	str - string to print
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 8/91		Initial Revision
#
##############################################################################

[defsubr secho {args}
{
    global kout
    if {![null $args]} {
    	if {![string compare [index $args 0] {-n}]} {
        	var flag [index $args 0]
    		var args [cdr $args]
    	}
    }
    var preface {}
    foreach i $args {
    	stream write $preface$i $kout
    	var preface { }
    }
    if {[null $flag]} {
    	stream write [format {\n}] $kout
    }
}]

##############################################################################
#				emit_header
##############################################################################
#
# SYNOPSIS:	Emit KbdConvHeader for keyboard map
# PASS:		addr - ptr to KeyboardTable
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 2/91		Initial Revision
#
##############################################################################

[defsubr emit_header {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    #
    # KbdConvheader
    #
    secho {KeyboardMap	label	KeyboardTable}
    secho {KbdHeader KbdConvHeader <}
    global geos-release
    if {${geos-release} < 2} {
      secho [format {%s,} [emit_word_enum $s:$o.KCH_tableID KeyMapTypes]]
      secho [format {%s,} [emit_words $s:$o.KCH_tableClass 1]]
      secho [format {%s} [emit_word_enum $s:$o.KCH_keyboardType KeyboardTypes]]
    } else {
      secho [format {%s,} [emit_word_enum $s:$o.KCH_tableID KeyMapType]]
      secho [format {%s,} [emit_words $s:$o.KCH_tableClass 1]]
      secho [format {%s} [emit_word_enum $s:$o.KCH_keyboardType KeyboardType]]
    }
    secho {>}
    secho {ForceRef	KbdHeader}
}]

##############################################################################
#				emit_extscans
##############################################################################
#
# SYNOPSIS:	Emit extended scan codes and ExtendedScanDef table
# PASS:		addr - ptr to KeyboardTable
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_extscans {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    #
    # extended scan codes
    #
    secho -n {KbdExtendedScanCodes byte }
    emit_bytes $s:$o.KT_extScan.KES_extScanCodes KBD_NUM_EXTSCANCODES
    secho { }
    #
    # ExtendedScanDef table
    #
    var o [expr $o+[getvalue KT_extScan]+[getvalue KES_extScanTab]]
    var n [getvalue KBD_NUM_EXTSCANMAPS]
    secho {KbdExtendedScanTable label ExtendedScanDef }
    for {var i 0} {$i < $n} {var i [expr $i+1]} {
    	secho -n {    byte }
    	emit_bytes $s:$o [size ExtendedScanDef]
    	secho { }
    	var o [expr $o+[size ExtendedScanDef]]
    }
}]

##############################################################################
#				emit_keydefs
##############################################################################
#
# SYNOPSIS:	Emit table of KeyDef structures
# PASS:		addr - ptr to KeyboardTable
# RETURN:	mone
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_keydefs {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var o [expr $o+[getvalue KT_keyDefTab]]
    var	n [getvalue KBD_NUM_KEYDEFS]
    secho { }
    secho {KbdKeyDefTable	KeyDef	<}
    for {var i 0} {$i < $n} {var i [expr $i+1]} {
    	#
    	# KD_keyType
    	#
    	secho -n {    }
    	var flags [field [value fetch $s:$o KeyDef] KD_keyType]
    	var keyflags [value fetch $s:$o.KD_keyType]
    	var keytype [expr [value fetch $s:$o.KD_keyType byte]&0xf]
    	var kt [format {%x} $keytype]
    	#
    	# KD_keyType
    	#
    	global geos-release
    	if {${geos-release} < 2} {
    	    secho -n [type emap $keytype [sym find type KeyTypeFlags]]
    	} else {
    	    secho -n [type emap $keytype [sym find type KeyTypeFlag]]
    	}
    	if {[isbitset KDF_STATE_KEY $keyflags]} {
    	    secho -n { or KD_STATE_KEY}
    	}
    	if {[isbitset KDF_EXTENDED $keyflags]} {
    	    secho -n { or KD_EXTENDED}
    	}
    	if {[isbitset KDF_ACCENT $keyflags]} {
    	    secho -n { or KD_ACCENT}
    	}
    	if {[isbitset KDF_ACCENTABLE $keyflags]} {
    	    if {$kt == [getvalue KEY_TOGGLE]} {
    	    	secho -n { or KD_SET_LED}
    	    } elif {$kt == [getvalue KEY_XTOGGLE]} {
    	    	secho -n { or KD_SET_LED}
    	    } else {
    	    	secho -n { or KD_ACCENTABLE}
    	    }
    	}
    	secho {,}
    	#
    	# KD_char & KD_shiftChar
    	#
	[case $kt in
    	    {2 3} { emit_key $s:$o }
    	    {0 1 4 5 6 7 8 9 a b c d} { emit_ctrlkey $s:$o }
	]
    	#
    	# KD_extEntry
    	#
    	secho -n {    }
    	emit_bytes $s:$o.KD_extEntry 1
    	secho { }

    	#
    	# next...
    	#
    	emit_ends $i $n [format {;SCAN CODE 0x%x} [expr $i+2]]

    	var o [expr $o+[size KeyDef]]
    }
    secho {KBD_MAX_SCAN	equ ($-KbdKeyDefTable)/size KeyDef}
}]

##############################################################################
#				emit_extdefs
##############################################################################
#
# SYNOPSIS:	Emit table of ExtendedDef structures
# PASS:		addr - ptr to KeyboardTable
# RETURN:	mone
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_extdefs {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var o [expr $o+[getvalue KT_extDefTab]]
    var	n [getvalue KBD_NUM_EXTDEFS]
    secho { }
    secho {KbdExtendedDefTable	ExtendedDef <}
    for {var i 0} {$i < $n} {var i [expr $i+1]} {
    	var ctrl [field [value fetch $s:$o ExtendedDef] EDD_charSysFlags]
    	emit_record $s:$o+[getvalue EDD_charSysFlags] ExtVirtualBits
    	emit_record $s:$o+[getvalue EDD_charAccents] ExtVirtualBits
    	if {[isbitset EVB_CTRL $ctrl]} {
    	    emit_vchar $s:$o+[getvalue EDD_ctrlChar]
    	} else {
    	    emit_char $s:$o+[getvalue EDD_ctrlChar]
   	}
    	secho {,}
    	if {[isbitset EVB_SHIFT_CTRL $ctrl]} {
   	    emit_vchar $s:$o+[getvalue EDD_shiftCtrlChar]
    	} else {
    	    emit_char $s:$o+[getvalue EDD_shiftCtrlChar]
    	}
    	secho {,}
        emit_char $s:$o+[getvalue EDD_altChar]
    	secho {,}
        emit_char $s:$o+[getvalue EDD_shiftAltChar]
    	secho {,}
        emit_char $s:$o+[getvalue EDD_ctrlAltChar]
    	secho {,}
        emit_char $s:$o+[getvalue EDD_shiftCtrlAltChar]
    	secho { }

    	#
    	# next...
    	#
    	emit_ends $i $n [format {;EXT 0x%x} [expr $i+1]]

    	var o [expr $o+[size ExtendedDef]]
    }
}]

##############################################################################
#				emit_record
##############################################################################
#
# SYNOPSIS:	Emit a record / bit field
# PASS:		addr - ptr to record
#   	    	type - type of record
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 3/91		Initial Revision
#
##############################################################################

[defsubr emit_record {addr type}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var record [value fetch $s:$o $type]
    var foo 0
    while {![null $record]} {
	var field [index $record 0]
	var name [index $field 0]
    	if {[index [index $field 2] 0] == 1} {
    	    if {$foo != 0} {
    	    	secho { or }
    	    }
    	    secho -n [format {    mask %s} $name]
    	    var foo 1
    	}
	var record [cdr $record]
    }
    if {$foo != 0} {
        secho {, }
    } else {
    	secho {    0,}
    }
}]

##############################################################################
#				emit_char
##############################################################################
#
# SYNOPSIS:	Emit <C_BSW (mumble)>
# PASS:		addr - ptr to Chars
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 2/91		Initial Revision
#
##############################################################################

[defsubr emit_char {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    global dbcs
    if {$dbcs} {
    	if {[value fetch $s:$o byte] != 0} {
    	    secho -n {    }
            emit_byte_enum $s:$o Chars
    	} else {
    	    secho -n {    0}
    	}
    } else {
    	if {[value fetch $s:$o byte] != 0} {
    	    if {${geos-release} < 2} {
            	secho -n {    <C_BSW }
            	emit_byte_enum $s:$o Chars
            	secho -n {>}
    	    }
    	} else {
    	    secho -n {    <>}
    	}
    }
}]

##############################################################################
#				emit_vchar
##############################################################################
#
# SYNOPSIS:	Emit <C_CTRL (mumble)>
# PASS:		addr - ptr to VChar
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 2/91		Initial Revision
#
##############################################################################

[defsubr emit_vchar {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    global geos-release
    global dbcs
    if {$dbcs} {
    	emit_char $s:$o
    } else {
    	if {${geos-release} < 2} {
    	secho -n {    <C_CTRL }
            emit_byte_enum $s:$o VChars
    	} else {
            emit_byte_enum $s:$o VChar
    	}
    	secho -n {>}
    }
}]

##############################################################################
#				emit_key
##############################################################################
#
# SYNOPSIS:	Emit characters for a printable character KeyDef
# PASS:		addr - ptr to KeyDef
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_key {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    emit_char $s:$o.KD_char
    secho {,}
    emit_char $s:$o.KD_shiftChar
    secho {,}
}]

##############################################################################
#				emit_ctrlkey
##############################################################################
#
# SYNOPSIS:	Emit character for a control character KeyDef
# PASS:		addr - ptr to KeyDef
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_ctrlkey {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    global dbcs

    emit_vchar $s:$o.KD_char
    secho {,}
    if {$dbcs} {
    	secho -n {    }
    	emit_bytes $s:$o.KD_shiftChar 1
    	secho {,}
    } else {
    	secho -n {    <C_CTRL }
    	emit_bytes $s:$o.KD_shiftChar 1
    	secho {>,}
    }
}]

##############################################################################
#				emit_comma
##############################################################################
#
# SYNOPSIS:	Emit separator comma when appropriate
# PASS:		value - current value
#   	    	last - last legal value
# RETURN:	
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_comma {value last}
{
    if {$value < [expr $last-1]} {
    	secho -n {,}
    }
}]

##############################################################################
#				emit_ends
##############################################################################
#
# SYNOPSIS:	Emit structure separator when appropriate
# PASS:		value - current value
#   	    	last - last legal value
#   	    	msg - message to emit
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_ends {value last msg}
{
    if {$value < [expr $last-1]} {
    	secho [format {>,<				%s} $msg]
    } else {
    	secho {>}
    }
}]

##############################################################################
#				emit_word_enum
##############################################################################
#
# SYNOPSIS:	Emit a word-sized enum
# PASS:		addr - ptr to enum in memory
#   	    	enumtype - enumerated type
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_word_enum {addr enumtype}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var val  [value fetch $s:$o word]
    secho -n [type emap $val [sym find type $enumtype]]
}]

##############################################################################
#				emit_byte_enum
##############################################################################
#
# SYNOPSIS:	Emit a byte-sized enum
# PASS:		addr - ptr to enum in memory
#   	    	enumtype - enumerated type
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_byte_enum {addr enumtype}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var val  [value fetch $s:$o byte]
    secho -n [type emap $val [sym find type $enumtype]]
}]

##############################################################################
#				emit_words
##############################################################################
#
# SYNOPSIS:	Emit word values
# PASS:		addr - ptr to words in memory
#   	    	num - number of words
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_words {addr num}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    var n [getvalue $num]

    for {var i 0} {$i < $n} {var i [expr $i+1]} {
        var val  [value fetch $s:$o+$i word]
        secho -n [format {0x%x} $val]
    	emit_comma $i $n
    }
}]

##############################################################################
#				emit_bytes
##############################################################################
#
# SYNOPSIS:	emit bytes from memory
# PASS:		addr - ptr to bytes in memory
#   	    	num - number of bytes
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	6/28/91		Initial Revision
#
##############################################################################

[defsubr emit_bytes {addr num}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]
    var n [getvalue $num]

    for {var i 0} {$i < $n} {var i [expr $i+1]} {
        var val  [value fetch $s:$o+$i byte]
        secho -n [format {0x%x} $val]
    	emit_comma $i $n
    }
}]

##############################################################################
#				emit_accentables
##############################################################################
#
# SYNOPSIS:	Emit table of accentable characters
# PASS:		addr - address of KeyboardTable
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 3/91		Initial Revision
#
##############################################################################

[defsubr emit_accentables {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var n [getvalue KBD_NUM_ACCENTABLES]
    var o [expr $o+[getvalue KT_accentables]]
    secho {KbdAccentables label Chars}
    for {var i 0} {$i < $n} {var i [expr $i+1]} {
    	secho -n {    byte }
        emit_byte_enum $s:$o+$i Chars
    	secho { }
    }
}]

##############################################################################
#				emit_accents
##############################################################################
#
# SYNOPSIS:	Emit table of accent characters
# PASS:		addr - address of KeyboardTable
# RETURN:	none
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	gene	7/ 8/91		Initial Revision
#
##############################################################################

[defsubr emit_accents {addr}
{
    var a [addr-parse $addr]
    var s [handle segment [index $a 0]]
    var o [index $a 1]

    var n [getvalue KBD_NUM_ACCENTABLES]
    var n2 [getvalue KBD_NUM_ACCENTS]
    var o [expr $o+[getvalue KT_accentTab]]
    secho {KbdAccentTable:}
    secho {AccentDef <<}
    for {var i 0} {$i < $n} {var i [expr $i+1]} {
    	for {var j 0} {$j < $n2} {var j [expr $j+1]} {
    	    secho -n {    }
            emit_byte_enum $s:$o+$j+[expr $i*[size AccentDef]] Chars
    	    emit_comma $j $n2
    	    secho { }
    	}
    	secho -n {>>}
    	if {$i < [expr $n-1]} {
    	    secho {,<<}
    	}
    }
}]
