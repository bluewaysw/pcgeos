#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script
# FILE: 	template.pl
# AUTHOR: 	Paul Canavese, Mar 25, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	3/25/96   	Initial Revision
#
# DESCRIPTION:
#
#	Subroutines for processing template files.
#	
# SUBROUTINES:
#
#	ParseTemplateFileAndSend(<template file>, <destination file>)
#		Read in the template file, process it for this build, and 
#		write it out to the destination directory.
#	Hexify(<string>)
#		Convert a character string to hex digits.  If demo is DBCS, 
#               each character will map to two bytes.
#	EvaluateExpression(<expression>)
#		Evaluates a variable expression and returns its value.
#       IncludeExclude(<expression>, <string>)
#               Returns passed string only if passed expression is true.
#
#	$Id: template.pl,v 1.17 97/08/26 21:31:21 allen Exp $
#
###############################################################################

1;


##############################################################################
#	ParseTemplateFileAndSend
##############################################################################
#
# SYNOPSIS:	Read in the template file, process it for this build, and 
#               write it out to the destination directory.
# PASS:		<template file> = template file.
#               <destination directory> = where to put it.
# CALLED BY:	SendFileTree
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub ParseTemplateFileAndSend {

    local($template, $destpath)=@_;
    $passedtemplate=$template;
    local($destname)="$template";
    $destname =~ s|.*/([\w]*)|$1|;
    $template=&FindInstalledFile("$template");
    if ( !"$template" && ($passedtemplate =~ /ec\./) ) {

	# Look for a non-ec version.

	($template=$passedtemplate) =~ s/ec\././;
	$template=&FindInstalledFile("$template");
    }
    if ( !"$template" ) {	
	&Error("Template $passedtemplate not found.");
	return;
    }
    if ($var{"reportabbreviatedpaths"}) {
	$abbrevfrom=&AbbrevPath("$template");
	$abbrevto=&AbbrevPath("$destpath$destname");
	&printbold("Parsing $abbrevfrom\n");
	print "        to $abbrevto\n\n";
    } else {
	&printbold("Parsing $template\n");
	print "        to $destpath$destname\n\n";
    }
    open(TEMPLATE, "$template");
    if ( &Debug("syscalls") ){
       print "SYS: (Writing to $destpath$destname)\n";
    } 
    if ( !"$var{syntaxtest}" ) {
       open(DESTFILE, "> $destpath$destname");
    }
    while(<TEMPLATE>) {

	chop;
	&DebugPrint("parsetemplate", " IN: $_");

	# If this was a blank line, just write it out.

	if ( !"$_" ) {
	    if ( !"$var{syntaxtest}" ) {
		print DESTFILE "\n";
	    }
	    next;
	}
	
	# Get rid of template comments.

	s/^!.*//;

	# Replace variables.

	s/VAR\(([^)]*)\)/&EvaluateExpression($1)/ge;
	
	# Process special EC/NEC macros.

	if ( "$var{ec}" ) {

	    s/EC-ext\(([^)]*)\)/$1.ec/;

	    if ( "$var{dbcs}" ) {
		s/EC-long\(([^)]*)\)/sprintf("%.16s","EC $1")/e;
	    } else {
		s/EC-long\(([^)]*)\)/sprintf("%.32s","EC $1")/e;
	    }

	    s/NEC-only\([^)]*\)//;
	    s/EC-only\(([^)]*)\)/$1/;
	    s/EC-NEC\(([^),]*),([^)]*)\)/$1/;
	    s/EC-dos\(([^).]*)\.([^)]*)\)/\@S\@$1ec.$2\@E\@/;
	    s/\@S\@(.*)\@E\@/&Dosify("$1")/e;

	} else {

	    s/EC-ext\(([^)]*)\)/$1/;

	    if ( "$var{dbcs}" ) {
		s/EC-long\(([^)]*)\)/sprintf("%.16s","$1")/e;
	    } else {
		s/EC-long\(([^)]*)\)/sprintf("%.32s","$1")/e;
	    }

	    s/NEC-only\(([^)]*)\)/$1/;
	    s/EC-only\([^)]*\)//;
	    s/EC-NEC\(([^),]*),([^)]*)\)/$2/;
	    s/EC-dos\(([^).]*)\.([^)]*)\)/\@S\@$1.$2\@E\@/;
	    s/\@S\@(.*)\@E\@/&Dosify("$1")/e;
	}

	# Handle mono vs. color macros.
	
	if ( "$var{mono}" ) {
	    s/MONO\(([^)]*)\)/$1/g;
	} else {
	    s/MONO\([^)]*\)//g;
	}

	if ( "$var{color16}" || "$var{color256}" ) {
	    s/COLOR\(([^)]*)\)/$1/g;
	} else {
	    s/COLOR\([^)]*\)//g;
	}

	# Handle standalone vs. server macros.

	if ( "$var{server}" ) {

	    s/SERVER\(([^)]*)\)/$1/g;
	    s/STANDALONE\([^)]*\)//g;

	} else {

	    s/SERVER\([^)]*\)//g;
	    s/STANDALONE\(([^)]*)\)/$1/g;
	}


        # Handle prototype vs. PC demo macros.

	if ( "$var{prototype}" ) {
	    s/PROTO\(([^)]*)\)/$1/g;
	    s/PCDEMO\([^)]*\)//g;
	    s/NTDEMO\([^)]*\)//g;
	    s/WINDEMO\([^)]*\)//g;

	} elsif ( "$var{nt}" )  {
	    s/PROTO\([^)]*\)//g;
	    s/PCDEMO\(([^)]*)\)//g;
	    s/NTDEMO\(([^)]*)\)/$1/g;
	    s/WINDEMO\([^)]*\)//g;

	} elsif ( "$var{win}" )  {
	    s/PROTO\([^)]*\)//g;
	    s/PCDEMO\(([^)]*)\)//g;
	    s/NTDEMO\(([^)]*)\)//g;
	    s/WINDEMO\(([^)]*)\)/$1/g;

        } else {
	    s/PROTO\([^)]*\)//g;
	    s/PCDEMO\(([^)]*)\)/$1/g;
	    s/NTDEMO\(([^)]*)\)//g;
	    s/WINDEMO\([^)]*\)//g;
        }

	# Handle tools macro.

	if ( "$var{tools}" ) {
	    s/NOTOOLS\([^)]*\)//g;
	    s/TOOLS\(([^)]*)\)/$1/g;
	} else {
	    s/NOTOOLS\(([^)]*)\)/$1/g;
	    s/TOOLS\([^)]*\)//g;
	}

	# Handle language macros.

	if ( "$var{language}" eq "english" ) {

	    s/AMENGLISH\(([^)]*)\)/$1/;
	    s/FRENCH\([^)]*\)//;
	    s/GERMAN\([^)]*\)//;
	    s/SPANISH\([^)]*\)//;

	} elsif ( "$var{language}" eq "french" ) {

	    s/AMENGLISH\([^)]*\)//;
	    s/FRENCH\(([^)]*)\)/$1/;
	    s/GERMAN\([^)]*\)//;
	    s/SPANISH\([^)]*\)//;

	} elsif ( "$var{language}" eq "german" ) {

	    s/AMENGLISH\([^)]*\)//;
	    s/FRENCH\([^)]*\)//;
	    s/GERMAN\(([^)]*)\)/$1/;
	    s/SPANISH\([^)]*\)//;

	} elsif ( "$var{language}" eq "spanish" ) {

	    s/AMENGLISH\([^)]*\)//;
	    s/FRENCH\([^)]*\)//;
	    s/GERMAN\([^)]*\)//;
	    s/SPANISH\(([^)]*)\)/$1/;
	}

	# Convert string to hex.

	s/HEX\(([^\)]*)\)/&Hexify("$1")/e;

	# Single byte hexify.
        s/SHX\(([^\)]*)\)/&SHexify("$1")/e;

	# Handle "IF" commands.

	s/IF\(([^,\)]*),([^,\)]*)\)/&IncludeExclude("$1","$2")/e;

        # Handle "LANG" commands.
	s/LANG\(([^,\)]*),([^,\)]*)\)/&LangInclude("$1","$2")/e;

	# Handle [] () replacement
	s/\\\[/(/g;
	s/\\\]/)/g;

	# Write out line.

	&DebugPrint("parsetemplate", "OUT: $_");
        if ( "$_" && !"$var{syntaxtest}" ) {
	    print DESTFILE "$_\n";
        }
    }

    # Make sure file is in DOS format.

    if ( !"$var{syntaxtest}" ) {
       close(DESTFILE);
    }
    close(TEMPLATE);
    &Unix2Dos("$destpath$destname");
}


##############################################################################
#	Hexify
##############################################################################
#
# SYNOPSIS:	Convert a character string to hex digits.  If demo is DBCS, 
#               each character will map to two bytes.
# PASS:		<string> = character string to convert to hex digits.
# CALLED BY:	ParseTemplateFileAndSend
# RETURN:       hex digits
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub Hexify {

    $hexstring="";
    @chars=split(//,"@_");
    foreach (@chars) {
	$hexstring.=sprintf("%2.2x",ord($_));
	if ( "$var{dbcs}" ) {
	    $hexstring.="00";
	}
    }
    return $hexstring;
}


##############################################################################
#	SHexify
##############################################################################
#
# SYNOPSIS:	Convert a character string to hex digits.
#
# PASS:		<string> = character string to convert to hex digits.
# CALLED BY:	ParseTemplateFileAndSend
# RETURN:       hex digits
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       ptrinh 	 	04/10/97   	Initial Revision
#
##############################################################################
sub SHexify {

    $hexstring="";
    @chars=split(//,"@_");
    foreach (@chars) {
	$hexstring.=sprintf("%2.2x",ord($_));
    }
    return $hexstring;
}


##############################################################################
#	EvaluateExpression
##############################################################################
#
# SYNOPSIS:	Evaluates a variable expression and returns its value.
# PASS:		<expression>
# CALLED BY:	various
# RETURN:	value of expression
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub EvaluateExpression {
    local($expr) = " @_ ";

    if ( &Debug("parsefiletree") || &Debug("parsetemplate") ) {
	print "* Evaluating expression $expr\n";
    }

    $expr =~ s/!/! /g;
    $expr =~ s/[^"\w]([\w]+)[^"\w]/"\$var{$1}"/g;
    $expr =~ s/==/ eq /g;
    $expr =~ s/!=/ neq /g;

    if ( &Debug("parsefiletree")  || &Debug("parsetemplate") ) {
	print "* Evaluating pexpression $expr\n";
    }
 
    return (eval ($expr));
}


##############################################################################
#	IncludeExclude
##############################################################################
#
# SYNOPSIS:	Returns passed string only if passed expression is true.
# PASS:		<expression>, <string>
# CALLED BY:	various
# RETURN:	<string> if <expression> is true
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub IncludeExclude {

    local($expr,$contents)=@_;
    if ( &EvaluateExpression("$expr") ) {
	return "$contents";
    } else {
	return "";
    }
}

##############################################################################
#	LangInclude
##############################################################################
#
# SYNOPSIS:	Returns passed string only if language <lang> is active.
# PASS:		<lang>, <string>
# CALLED BY:	various
# RETURN:	<string> if <expression> is true
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub LangInclude {
    local($lang,$contents)=@_;
    if ( "$var{language}" eq $lang ) {
	return "$contents";
    } else {
	return "";
    }
}
