#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script
# FILE: 	var.pl
# AUTHOR: 	Paul Canavese, Mar 23, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	3/23/96   	Initial Revision
#
# DESCRIPTION:
#
#	Subroutines dealing with build variables.
#
# SUBROUTINES:
#
#	SetVars()
#		Set all the variables, from the command line and build
#               variable files.
#	ReadVars(<file>)
#		Read variables from the passed array into %var associative
#		array.
#       SetVar(<name>, <value>)
#               Set the value of a build variable.
#	PrintVars(<file>)
#		Print out all assigned variables from %var associative array.
#       SetDebugFlags()
#               Allow the user to interactively turn on debugging flags.
#       VariableSanityCheck()
#               Check that all the right build variables are set correctly 
#               before proceeding.
#
#	$Id: var.pl,v 1.25 98/05/21 19:51:54 kliu Exp $
#
###############################################################################

1;


##############################################################################
#	SetVars
##############################################################################
#
# SYNOPSIS:	Sets all build variables, from the command line and build 
#               variable files.
# PASS:		nothing
# CALLED BY:	top level
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       canavese 	10/26/96   	Initial Revision
#
##############################################################################
sub SetVars {

    local(@commandLineArgs)=@_;
    local($file, $fullPathFile, $arg, $argtest);

    foreach $arg (@commandLineArgs) {

	if ( $arg =~ /^debug$/ ) {
	    &SetDebugFlags();
	} elsif ( $arg =~ /=/ ) {
	    push(@commandlinevars, $arg);
	} elsif ( $arg =~ /\.build/ ) {
	    push(@varfiles, $arg);
	} else {
	    push(@commandlinevars, "$arg=true");
	}    
    }

    # Read in default variables.

    print "\n";
    &ReadVars(&FindBuildFile("default.build"));

    # Read site-specific variables.

    $siteName = &GetSiteName();
    if ( &IsUnix() || $siteName ){ # NT may not have $siteName.build file.
	&ReadVars(&FindBuildFile("$siteName.build"));
    }

    # Read in variables from command line-specified build files.

    foreach $file (@varfiles) {

	if ( -f $file ) {

	    # If $file includes path or is in current directory, use it.

	    $fullPathFile=$file;

	} else {

	    # Otherwise, look in GEOS tree script was run from or 
	    # $geosPath/Tools/build

	    $fullPathFile=&FindBuildFile($file);
	}
	if ( -f "$fullPathFile" ) {
	    &ReadVars($fullPathFile);
	} else {
	    &Error("Cannot find file $file.");
	}
    }

    # Read local variables.

    if ( -e "$ENV{HOME}/.build" ) {
	&ReadVars("$ENV{HOME}/.build");
    }

    # Set variables from the command line

    print "Setting variables from the command line.\n\n";
    foreach $arg (@commandlinevars) {
	$argtest = $arg;
	if ( $argtest =~ /=/ ) {
	    ($name,$value)=split('=', $arg);
	    &SetVar($name,$value);
	} else {
	    &SetVar($name,"true");
	}
    }

    @sourcedirs=split(' ', "$var{sourcedirs}");

    # Determine where we're sending this thing, if that hasn't been 
    # explicitly defined.

    print "Building destination path.\n\n";
    &BuildDestTreePath();

    $var{reseditpath} =~ s|\\|/|g;
    $var{dosdestpath} = "$var{desttree}";
    $var{dosdestpath} =~ s|/n/nevada|N:|;
    $var{dosdestpath} =~ s|/|\\|g;
    
    $var{launchresedit} = "";    # initialize as unset

    if($var{includefiles}) {
	@includelist = split(' ', "$var{includefiles}");
    }
    
    if($var{excludefiles}) {
	@excludelist = split(' ', "$var{excludefile}");
    }

    if(-s "$var{includelistfile}") {
	open(TMP, "$var{includelistfile}");
	while (<TMP>) {
	    chomp;
	    push(@includelist, $_) if (/[\w]+/);
	}
	close(TMP);
    }

    if(-s "$var{excludelistfile}") {
	open(TMP, "$var{excludelistfile}");
	while (<TMP>) {
	    chomp;
	    push(@excludelist, $_) if (/[\w]+/);
	}
	close(TMP);
    }

    #
    # Check if no. of retries is defined, if not, set
    #
    if ($var{retries} eq "" || $var{retries} =~ /[\D]+/) {    
	    $var{retries} = 0;	    
    }

    #
    #	 Now check whether we really need to launch resedit

    if (&UseResedit()) {
	my(@tmpFiles);

	$var{transdir}    =~ s|\\|/|g;
	if (! (-d $var{transdir})) {
	    &MakePath($var{transdir});
	    $var{deletetransfiles}=0;   # There is no need to delete
	}
	#
	# Some dangling trans* files might exists
	
	my(@files);
	@files = glob("$var{reseditpath}/document/translat.*");  
	unlink @files;
	
	if (! $var{logdir}) {
	    $var{logdir} = $ENV{HOME};
	} else {
	    $var{logdir} =~ s|\\|/|g;
	}
	if (! (-d $var{logdir})) {
	    &MakePath($var{logdir});
	} else {
	    unlink "$var{logdir}/error.log" if (-s "$var{logdir}/error.log");
	    unlink "$var{logdir}/warning.log" if (-s "$var{logdir}/warning.log");
	    unlink "$var{logdir}/FAIL" if (-e "$var{logdir}/FAIL");
	}	    
	
	#
	# Make the document directory first it doesnt't exist
	if (! (-d "$var{reseditpath}/document")) {
	    &MkDir("$var{reseditpath}/document");
	}

	if (! $var{srctrans}) {
	    $var{srctrans} = "$var{reseditpath}/document/RES_SRC";
	} else {
	    $var{srctrans} =~ s|\\|/|g;
	}
	if (! (-d $var{srctrans})) {
	    &MkDir($var{srctrans});
	} else {
	    @tmpFiles = glob("$var{srctrans}/*.*");
	    unlink @tmpFiles if (scalar(@tmpFiles));
	}
	    
	if (! $var{desttrans}) {
	    $var{desttrans} = "$var{reseditpath}/document/RES_DEST";
	} else {
	    $var{desttrans} =~ s|\\|/|g;
	}
	if (! (-d $var{desttrans})) {
	    &MkDir($var{desttrans});
	} else {
	    @tmpFiles = glob("$var{desttrans}/*.*");
	    unlink @tmpFiles if (scalar(@tmpFiles));
	}
	
	if (! $var{commdir}) {
	    $var{commdir} = "$var{reseditpath}/document/COMM";
	} else {
	    $var{commdir} =~ s|\\|/|g;
	}
	if (! (-d $var{commdir})) {
	    &MkDir($var{commdir});
	} else {
	    @tmpFiles = glob("$var{commdir}/*.*");
	    unlink @tmpFiles if (scalar(@tmpFiles));
	}
	&TruncateToZero ("$var{commdir}/ERROR");
	&TruncateToZero ("$var{commdir}/WARN");

	
	$var{dosreseditpath} = $var{reseditpath};
	$var{dosreseditpath} =~ s|/|\\|g;
    }
    
    # If debug flag is on, print out variables.

    if ( &Debug(vars) ) {
	&PrintVars();
    }
    
    # Make sure variables are defined correctly.

    &VariableSanityCheck();
}


##############################################################################
#	ReadVars
##############################################################################
#
# SYNOPSIS:	Read in the variables from the passed array into %var 
#               associative array.
# PASS:		<file> = variable file.
# CALLED BY:	SetVars
# RETURN:	0 on success, 1 on error
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/26/96   	Initial Revision
#
##############################################################################
sub ReadVars {

    local($file)=@_;
    if ( ! "$file" ) {
	return 1;
    }

    print "Reading variables from\n";
    &printbold("        $file.\n\n");
    open(VARS, "$file");

    # "tell" and "seek" function will not function properly together
    # if the input file is not treated as binary file. Without setting
    # it to binary mode, UNIX input file will be given different file
    # position by "tell". Thus, "seek" will set it to the wrong place
    # and can possibly result in infinite loop reading "parent" files.

    binmode(VARS);

    while (<VARS>){

	chop($_);		# Get rid of trailing CR.
      	s/#.*//;		# Delete comments.
	s/[\s]*$//;		# Delete trailing whitespace.

	($name,$value)=split('=',$_);

	if ("$name" eq "parent") { 

	    # Remember where we are in this file.

	    local($position)=tell(VARS);

	    # Read in parent variable files.

	    if ( $file =~ m|\W.build| ) {
		print "Reading from $value\n";
	    }

	    # Make sure the file is readable
	    if ( -r "$value" ) {
		&ReadVars("$value");
	    } else {
		&Error("$file: Cannot read parent build file: $value");
	    }

	    # Restore our position in child var file.

	    open(VARS, "$file");
	    seek(VARS, $position, 0);

	} elsif ($name) {

	    # Set the variable.  Report it if we're processing a 
	    # .build file.

	    &SetVar($name, $value, ($file =~ m|\W.build|) );
	}
    }

    &DebugPrint(vardef, "");	# Just want the carriage return.
    if ($file =~ m|\W.build|) {
	print "\n";
    }
    close(VARS);
    return 0;
}


##############################################################################
#	SetVar
##############################################################################
#
# SYNOPSIS:	Set a build variable.
# PASS:		<name>, <value>, <print settings boolean>
# CALLED BY:	ReadVars
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/26/96   	Initial Revision
#
##############################################################################
sub SetVar {

    local($name, $value, $print)=@_;

    # Lowercase variable keys.

    $name =~ y/A-Z/a-z/;

    # Lowercase value to check if it is boolean.

    $testvalue=$value;
    $testvalue =~ y/A-Z/a-z/;

    # Assign appropriate value to associative array.

    if ( $testvalue eq "true" ) {
	$var{$name}="true";
    } elsif ( $testvalue eq "false" ) {
	$var{$name}="";
    } else {
	$var{$name}=$value;
    }

    if ( "$print" ) {
	print "- $name = $var{$name}\n";
    } else {
	&DebugPrint(vardef, "- $name = $var{$name}");
    }
}


##############################################################################
#	PrintVars
##############################################################################
#
# SYNOPSIS:	Prints out all assigned variables (for debugging)
# PASS:		nothing
# CALLED BY:	SetVars
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/26/96   	Initial Revision
#
##############################################################################
sub PrintVars {

    local($key, $entry);
    print "____________________ Assigned variables ____________________\n\n";
    foreach $key (sort keys(%var)) {
	$entry = $var{$key};
	if ( $entry eq "true" ) {
	    print "$key = <true>\n";
	} elsif ( !$entry ) {
	    print "$key = <false>\n";
	} else {
	    print "$key = $entry\n";
	}
    }
    print "__________________ End assigned variables __________________\n\n";
}


##############################################################################
#	VariableSanityCheck
##############################################################################
#
# SYNOPSIS:	Check that all the right build variables are set correctly 
#               before proceeding.
# PASS:		nothing
# CALLED BY:	top level
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub VariableSanityCheck {

    my $result=1;

    # Check for all variables that must be set true.

    $result &= &AssertVarTrue(filetree, "Variable fileTree must be set.",
			      "Perhaps you forgot to specify a build variables file.");

    # Check for requirements when in test mode.

    if ( "$var{test}" ) {
	$result &= &AssertVar(defaulttestdesttreetop, 
	    "The variable defaultTestDestTreeTop must be defined to run in test mode.");
	&printreversefullline("");
	&printreversefullline("Running in test mode.  Using test destination tree.");
	&printreversefullline("");
	print "\n";
    }
    if ( "$var{syntaxtest}" ) {
	&printreversefullline("");
	&printreversefullline("Running in syntax test mode.  No action will be taken.");
	&printreversefullline("");
	print "\n";
    }

    # If there were errors, report them and die.  Otherwise, return 1.

    if ( ! $result ) {
	&PrintErrorsAndWarnings();
	exit 0;
    } else {
	return 1;
    }
}


sub   UseResedit 
{
    if ($var{launchresedit} eq "") {
	#
	# First time in, let's check whether we need to
	# launch resedit or not.
	
	if (($var{action} eq "")
	    || ($var{action} =~ /no_action/i)) {
	    $var{launchresedit} = "no";
	    return 0;
	} elsif (($var{action} =~ /create_trans_files/i) ||
		 ($var{action} =~ /create_executables/i) || 
		 ($var{action} =~ /create_patch/i)       ||
		 ($var{action} =~ /create_null_and_patch/i)) {

	    $var{launchresedit} = "yes";
	    return 1;
	} else {
	    # 
	    # Action must be undefined.
	    &printbold("Cannot proceed. Action is undefined");
	    exit;
	}
    }
    elsif ($var{launchresedit} =~ /yes/i) {
	return 1;
    } elsif ($var{launchresedit} =~ /no/i) {
	return 0;
    } else {
	&printbold("Error in setting up Resedit\n");
	exit;
    }
}
	  
sub  print_error {
    print Win32::FormatMessage(Win32::GetLastError());
}

	
