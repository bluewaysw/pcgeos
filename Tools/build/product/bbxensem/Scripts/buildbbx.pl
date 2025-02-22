#!/usr/public/perl5
##############################################################################
#
#       Copyright (c) Global PC 1998.  All rights reserved.
#
# PROJECT:      Global PC
# MODULE:       Tools
# FILE:         buildbbx.pl
# AUTHOR:       Todd Stumpf
#
# REVISION HISTORY:
#       Name    Date            Description
#       ----    ----            -----------
#       TDS	07/22/98        Initial Revision
#
# DESCRIPTION:
# 	"buildbbx" is an interactive script that allows one to create
# 	an bbxensem image easily using the build tool
# 
# USAGE:
# 	buildbbx [-h] [-debug] [-nolocal] [-noprompt] [-template] [-xip]
#                [-i <directory>] [-s <directory>] [<gbuild argument>+]
# 
# 	-h or -help:	Bring up this help message
# 	-debug:	        Debug mode. Do not really create any image.
#       -nolocal:       Do not look at .local file, the download list file
#       -noprompt:      Do not ask the user for input, use the defaults.
#       -template:      Only send templates, like *.INI files, and not 
#                       make any images
#	-xip:		Make an non-XIP image
#       -i <source directory>: 
#			Specify the directory to search for source
#			files before installed ones.
#       -s <build file directory>: 
#			Specify the top directory where the *.build
#                       and *.filetree files should be used. 
#			"Tools/build/product/bbxensem" should be omitted
#			in <build file directory>. 
#
#			For example, if you have *.build files in 
#			c:\pcgeos\todd\Tools\build\product\bbxensem\,
#			you only need to specify "-s c:\pcgeos\todd".
#
#       <gbuild argument>+:
#			The extra arguments you want to pass to gbuild. 
#
#	$Id:$
#
##############################################################################

#
# User interrupt handler
#
$SIG{INT} = sub { 
    #
    # Simply exit instead of "die" so that any child process will not 
    # continue.
    #
    print "\n[User interrupted]\n";
    exit( 1 );
};

######################################################################
#	Constants
######################################################################

$TARGET_NT = "nt";
$TARGET_NT_XIP = "ntxip";
$TARGET_PC = "pc";		# DOS PC platform
$TARGET_PC_XIP = "pcxip";	# DOS PC platform
$TARGET_PROTO = "hw";           # Prototype hardware platform
$TARGET_PROTO_XIP = "hwxip";    # Prototype hardware platform
$TARGET_DEMO = "demo";        # Prototype hardware platform for demo
$TARGET_WIN = "win";		  # Windows build
$TARGET_PROTO_TOOLS = "hwtools"; # Prototype hardware platform for tools
$TARGET_NT_TOOLS = "nttools";	# Windows NT platform for tools
$DEST_SUB_DIRECTORY = "gbuild"; # sub-directory to download files to in 
                                # defining destination directory
$CONFIG_FILE_ROOT = ".bbxxip";	# Config file root
$LOCAL_LIST_FILE = ".local";    # File that specifies the list of files 
                                # to include in download
$TARGET_LANGUAGE = $ENV{TARGET_LANG} || "english";   # start out with English 

######################################################################
#	Process command line options
######################################################################

use File::Find;
use File::Copy;
use File::Path qw(rmtree);

require "newgetopt.pl";
NGetOpt("debug", "help", "i=s", "s=s", "nolocal", "noprompt", "template", "xip");

$opt_help = $opt_help;			# To get rid of warning
if ( $opt_help ) {
    Usage();
    exit( 0 );
}

if ( $opt_s ) {
    $opt_s = FormatPath( $opt_s, 0 );
    print "[Using build files from: $opt_s]\n";
}

if ( $opt_i ) {
    $opt_i = FormatPath( $opt_i, 0 );
    print "[Including source dirs: $opt_i]\n";
}

######################################################################
#	Variables
######################################################################

#
# Set tools directories
#
#if ( IsWinNT() ) {
    $TopDir = $ENV{ROOT_DIR} || 
	die "ERROR: \%ROOT_DIR\% variable must be set.\n";
    $TopDir = FormatPath( $TopDir, 0 );

    $LocalDir = $ENV{LOCAL_ROOT} ||
	die "ERROR: \%LOCAL_ROOT\% variable must be set.\n";
    $LocalDir = FormatPath( $LocalDir, 0 );
    $SourceDir = FormatPath( "$TopDir/bbxensem/Installed $TopDir/Installed $TopDir", 0 );
#} else {
    #
    # Running under Unix
    #
#    $TopDir = "/staff/pcgeos";
#    $LocalDir = $ENV{HOME};
#    $SourceDir = FormatPath( "/staff/pcgeos/bbxensem/Installed /staff/pcgeos/Installed /staff/pcgeos", 0 );
#}

$CommonConfigFile = "$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT";
                                # Configuration file common to all platforms

#
# Default values of the settings
#
%DefaultInfo = ("target" => $TARGET_NT, 
		"ec" => "n", 
		"dbcs" => "n",
		"mapblock" => "e8000",
		"romwindows" => "c8000 128k",
		"destdir" => "$LocalDir/$DEST_SUB_DIRECTORY",
		"shipfiles" => "y",
		"vm" => "n",
		"patching" => "n",
		"patchaction" => "create_null_and_patch",
		"language" => $TARGET_LANGUAGE,
		"reseditpath" => "$LocalDir/Target/geos2xnc",
		"transpath" => "$LocalDir/trans",
		"logpath" => "$LocalDir/log");

#
# Actual value of the settings
#
%RealInfo = ( "sourceDirs" => $SourceDir );

#
# Arguments passed to gbuild
#
$GbuildArgs = "";
$GbuildResult = 0;                       # result returned by gbuild

$GbuildTargetDir = "";		         # gbuild destination tree directory
$DemoTargetDir = "";		         # Demo target directory

##############################################################################
#	Main
##############################################################################

#
# Prepend user specified path to sourceDirs to search for geodes
#
if ( $opt_i ) {
    $RealInfo{sourceDirs} = "$opt_i $RealInfo{sourceDirs}";
}

#
# Check to see if the user wants to be prompted or use his defaults
#

# Set up some gbuild arguments first
AddGbuildArg( "sourceDirs", $RealInfo{sourceDirs} );

# Always delete destination tree
AddGbuildArg( "promptOnDeleteDestTree", "false" );

# Run gbuild in debug mode if we are in debug mode
if ( $opt_debug ) {
    print "[Running in DEBUG mode]\n";
    AddGbuildArg( "syntaxtest", "true" );
}

# Send template only if "template" option is set
if ( $opt_template ) {
    print "[Sending Templates only. No image will be created.]\n";
    AddGbuildArg( "sendTemplateOnly", "true" );
    AddGbuildArg( "makeImages", "false" );
}

# See if there are extra arguments passed to gbuild
if ( $#ARGV >= 0 ) {
    print "[User-defined gbuild arguments: " . join( " ", @ARGV ) . "]\n";
}

# Read in the list of local files, if any
if ( $opt_nolocal ) {
    print "[Ignoring any .local file]\n";
} else {
    ReadLocalFileList();
}

print "\n*** Welcome to buildbbxensem! ***\n\n";

##############################################################################
#
# Get target platform
#

# Read any saved input from cached file about previous platform
ReadCommonInputFromCache();

print "Which platform? ";
print "($TARGET_PC/$TARGET_PC_XIP/$TARGET_PROTO/$TARGET_PROTO_XIP/$TARGET_DEMO/$TARGET_NT/$TARGET_WIN/$TARGET_PROTO_TOOLS/$TARGET_NT_TOOLS), \n";
print "   default = $DefaultInfo{target}: ";
$RealInfo{target} = ReadUserInput( $DefaultInfo{target} );

#
# Find out which .build file to use given the platform
#
BUILDFILE: {
    if ( $RealInfo{target} eq $TARGET_PC ) {
	 $RealInfo{targetfile} = "pcbbx.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_NT ) {
	 $RealInfo{targetfile} = "ntbbx.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_PROTO ) {
	 $RealInfo{targetfile} = "hwbbx.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_PC_XIP ) {
	 $RealInfo{targetfile} = "pcbbxxip.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_PROTO_XIP ) {
	 $RealInfo{targetfile} = "hwbbxxip.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_DEMO ) {
	 $RealInfo{targetfile} = "demobbx.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_WIN ) {
	 $RealInfo{targetfile} = "winbbx.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_PROTO_TOOLS ) {
	 $RealInfo{targetfile} = "hwbbxtools.build";
	 last BUILDFILE;
    }

    if ( $RealInfo{target} eq $TARGET_NT_TOOLS ) {
	 $RealInfo{targetfile} = "ntbbxtools.build";
	 last BUILDFILE;
    }

    die "\nERROR: Invalid platform: $RealInfo{target}\n";
}

# Save platform information to common configuration file
SaveCommonInputToCache();

##############################################################################
#
# Find out whether to use EC or non-EC version
#

# Read platform specific configuration file
ReadTargetCommonInputFromCache();
print "Make an EC image? (y/n), default = $DefaultInfo{ec}: ";
$RealInfo{ec} = ReadUserInput( $DefaultInfo{ec} );
AddGbuildArg( "ec", YesNo2TrueFalse( $RealInfo{ec} ) );

##############################################################################
#
# Find out whether to use SBCS or DBCS version
#

# Read platform specific configuration file
ReadTargetCommonInputFromCache();
print "Make an DBCS image? (y/n), default = $DefaultInfo{dbcs}: ";
$RealInfo{dbcs} = ReadUserInput( $DefaultInfo{dbcs} );
AddGbuildArg( "dbcs", YesNo2TrueFalse( $RealInfo{dbcs} ) );


##############################################################################
#
# Get map block and ROM windows for PC or Win32 demos
#
if ( $RealInfo{target} eq $TARGET_PC_XIP ||
     $RealInfo{target} eq $TARGET_NT_XIP  ) {
    #
    # Get map block location
    #
    print "Memory location of the map block ";
    print "(default = $DefaultInfo{mapblock}): ";
    $RealInfo{mapblock} = ReadUserInput( $DefaultInfo{mapblock} );

    CheckAddr( $RealInfo{mapblock} );
    AddGbuildArg( "xipMappingWinAddress", "0x" . "$RealInfo{mapblock}" );

    #
    # Get ROM Windows
    #
    print "ROM Windows location and size ";
    print "(default = $DefaultInfo{romwindows}): ";
    $RealInfo{romwindows} = 
	ReadUserInput( $DefaultInfo{romwindows} );

    #
    # Process ROM Windows into arguments
    #
    SetRomWindows();
}

##############################################################################
#
# Need to make an image with patching? It only applies to buildbbxensem running 
# in NT environment as localization tools only exist on NT, except the case
# that we are using the nightly make files. In this case, we don't need to
# launch the Resedit.
#

#print "Make an image with language patch? (y/n), ";
#print "default = $DefaultInfo{patching}: ";
$RealInfo{patching} = $DefaultInfo{patching};

#
# If the user uses language patch for prototype, use a different build file
#
#if ( $RealInfo{target} eq $TARGET_PROTO_XIP &&
#     $RealInfo{patching} eq "y" ) {
#    $RealInfo{targetfile} = "hwbbxlangxip.build";
#}

##############################################################################
# What language is desired?
#
# USS = U.S. Spanish
# BRP = Brazilian Portuguese
#
# English is the only option for the copy of buildbbx.pl on the Trunk of perforce
# as English is the current default.  If another language is desired, user needs
# to go to the localization (currently Rel13) perforce  branch and use the buildbbx.pl 
# script there.

#print "Select desired language (english, uss, brp, etc.), ";
#print "default = $DefaultInfo{language}: ";
$RealInfo{language} = $DefaultInfo{language};

# let's ask for the DBCS version
if ( $RealInfo{dbcs} eq "y" ) {
  print "Select desired language (english, chinese, etc.), ";
  print "default = $DefaultInfo{language}: ";
  $RealInfo{language} = ReadUserInput( $DefaultInfo{language} );
}

AddGbuildArg( "language", $RealInfo{language} );

##############################################################################
#
# Find out if the user wants the files to be re-downloaded
#
print "Copy geodes from Installed to target? (y/n), ";
print "default = $DefaultInfo{shipfiles}: ";
$RealInfo{shipfiles} = ReadUserInput( $DefaultInfo{shipfiles} );

AddGbuildArg( "shipFiles", YesNo2TrueFalse( $RealInfo{shipfiles} ) );

#
# Only ask users about running ResEdit info if run from NT
#
#if ( $RealInfo{patching} eq "y" && IsWinNT() ) {
#
#    if ( $RealInfo{nightlymake} eq "n" &&
#	 $RealInfo{shipfiles} eq "y" &&
#	 ! $opt_template ) {
#	#
#	# Set misc. variables. Currently, we do not allow user to select
#	# language at this point.
#	#
#	AddGbuildArg( "action", $DefaultInfo{patchaction} );
#	AddGbuildArg( "language", $DefaultInfo{language} );
#
#	# 
#	# Get ResEdit demo path
#	#
#	print "ResEdit demo diretory ";
#	print "(default = $DefaultInfo{reseditpath}): ";
#	$RealInfo{reseditpath} = 
#	    FormatPath( ReadUserInput( $DefaultInfo{reseditpath} ), 0 );
#	AddGbuildArg( "reseditpath", $RealInfo{reseditpath} );
#
#	# 
#	# Get translation file path
#	#
#	print "Translation file directory ";
#	print "(default = $DefaultInfo{transpath}): ";
#	$RealInfo{transpath} =
#	    FormatPath( ReadUserInput( $DefaultInfo{transpath} ), 0 );
#	AddGbuildArg( "transdir", $RealInfo{transpath} );
#
#	# 
#	# Get log file path
#	#
#	print "Log file directory (default = $DefaultInfo{logpath}): ";
#	$RealInfo{logpath} =
#	    FormatPath( ReadUserInput( $DefaultInfo{logpath} ), 0 );
#	AddGbuildArg( "logdir", $RealInfo{logpath} );
#
#    } else {
#	#
#	# No Resedit needs to be launched, but we still want to save
#	# the default patching info in case user wants to run patching 
#	# again. 
#	#
#	$RealInfo{reseditpath} = $DefaultInfo{reseditpath};
#	$RealInfo{transpath} = $DefaultInfo{transpath};
#	$RealInfo{logpath} = $DefaultInfo{logpath};
#    }
#
#} else {
    # 
    # non-NT version, but we still want to save the default patching info 
    # in case user wants to switch back to run it on NT.
    # 
    $RealInfo{reseditpath} = $DefaultInfo{reseditpath};
    $RealInfo{transpath} = $DefaultInfo{transpath};
    $RealInfo{logpath} = $DefaultInfo{logpath};
#}

##############################################################################
#
# Find out if the user wants to download the resource (.vm) files.
#
print "Copy resource (.vm) files from Installed to target? (y/n), ";
print "default = $DefaultInfo{vm}: ";
$RealInfo{vm} = ReadUserInput( $DefaultInfo{vm} );

AddGbuildArg( "vm", YesNo2TrueFalse( $RealInfo{vm} ) );

# Save platform specific information
SaveTargetCommonInputToCache();

##############################################################################
#
# Find out the directory in which the user wants to put intermediate files
#

# Read platform and EC/NEC specific information
ReadTargetInputFromCache();

#
# Since we are not making xip images, this is not the temporary directory, 
# it is the destination directory for the demo.
#
print "Directory to put target files in (default = $DefaultInfo{destdir}): ";
$RealInfo{destdir} = FormatPath( ReadUserInput( $DefaultInfo{destdir} ), 0 );

AddGbuildArg( "desttree", $RealInfo{destdir} );

##############################################################################
#
# Find out the target demo directory for non-prototypes
#
if ( $RealInfo{target} eq $TARGET_PC_XIP ) {	

    # Set default demo directory if undefined
    if ( ! $DefaultInfo{demodir} ) {
	$DefaultInfo{demodir} = 
	    FormatPath( "$RealInfo{destdir}/localpc", 1 );
    }

    print "Demo directory (default = $DefaultInfo{demodir}): ";
    $RealInfo{demodir} = FormatPath( ReadUserInput( $DefaultInfo{demodir} ), 
					1 ); # demodir is DOS path based
    CheckDemoDir( $RealInfo{demodir} );

    AddGbuildArg( "demodir", $RealInfo{demodir} );
}

#
# Save platform and EC/NEC specific information
#
SaveTargetInputToCache();

#
# Okay now, if we are using nightly make files, we need to copy the entire
# demo tree to our destination tree and make the image from there.
#
if ($RealInfo{nightlymake} eq "y") {
    &CopyDemoTreeToDestTree();
    ModifyGeosIni();
}

##############################################################################
#
# Finally, call gbuild command
#

#
# Add the custom gbuild arguments user wants to pass to gbuild
#
$GbuildArgs .= join(" ", @ARGV);

#
# If the user wants to use his/her own *.build files, then change
# directory to that directory.
#
if ( $opt_s ) {
    print "+ chdir $opt_s/Tools/build/product/bbxensem\n";
    chdir( "$opt_s/Tools/build/product/bbxensem" ) || 
	die "\nERROR: Cannot change directory to $opt_s/Tools/build/product/bbxensem\n";
} else {
    print "+ chdir $TopDir/Tools/build/product/bbxensem\n";
    chdir( "$TopDir/Tools/build/product/bbxensem" ) ||
	die "\nERROR: Cannot change directory to $TopDir/Tools/build/product/bbxensem\n";
}

print "+ gbuild $RealInfo{targetfile} $GbuildArgs\n";
$GbuildResult = system( "gbuild $RealInfo{targetfile} $GbuildArgs" );

if ( $GbuildResult != 0 ) {
    print "\nbuildbbx not completed because of errors.\n";
    exit( $GbuildResult );
} else {
    #
    # Copy files to target demo directory if making PC/WIN32 image
    #
    print "\nbuildbbx completed!\n";
}

print "[End of DEBUG mode]\n" if ( $opt_debug );

##############################################################################
##############################################################################
###
###			GBUILD Related Routines
###
##############################################################################
##############################################################################

##############################################################################
#       SetRomWindows
##############################################################################
#
# SYNOPSIS:     Set ROM Windows variables
# PASS:         $RealInfo{romwindow} = ROM windows string
#                   The format of the string is:
#                   (<starting address XXXXX> <window size>)+
#
#                   where starting address is heximal number
#                   For example, "d0000 64k" or "c9000 16k d0000 64k"
#
# CALLED BY:    Main
# RETURN:       ROM window arguments are set in gbuild arguments. 
# SIDE EFFECTS: Die if any ROM window arguments are invalid or missing.
#
##############################################################################
sub SetRomWindows {
    local( $addr1, $size1, $addr2, $size2 ) = 
		split( " ", $RealInfo{romwindows} );

    #
    # Verify that ROM window arguments are in pairs
    #
    CheckRomWindowArgInPairs( $addr1, $size1 );
    CheckRomWindowArgInPairs( $addr2, $size2 );

    # 
    # Verify that starting address is a heximal number
    #
    CheckAddr( $addr1 );
    CheckAddr( $addr2 );

    #
    # Verify that rom window size is valid
    #
    CheckWinSize( $size1 );
    CheckWinSize( $size2 );

    # 
    # Set ROM Window arguments in gbuild
    #
    if ( $addr1 && $size1 ) {
	$RealInfo{romwindows} = "$addr1 $size1";
	AddGbuildArg( "xipROMWindowAddress", "0x" . "$addr1" );
	AddGbuildArg( "xipROMWindowSize", $size1 );
    }

    if ( $addr2 && $size2 ) {
	$RealInfo{romwindows} .= " $addr2 $size2";
	AddGbuildArg( "xipROMWindow2Address", "0x" . "$addr2" );
	AddGbuildArg( "xipROMWindow2Size", $size2 );
    }
}

##############################################################################
#       CheckRomWindowArgInPairs
##############################################################################
#
# SYNOPSIS:     Check to see if both ROM window starting address and
#               size are supplied together  
# PASS:         arg1 = ROM window starting address
#               arg2 = ROM window size
# CALLED BY:    SetRomWindows
# RETURN:       nothing
# SIDE EFFECTS: Die if ROM window address is given but not ROM window size
#
##############################################################################
sub CheckRomWindowArgInPairs {
    local( $start, $size ) = @_;

    if ( $start && "$start" ne "" && !$size ) {
	die "\nERROR: ROM Window settings must be in form of (<addr> <size)+ pairs.\n";
    }
}

##############################################################################
#       CheckAddr
##############################################################################
#
# SYNOPSIS:     Check the ROM window address syntax
# PASS:         arg1 = ROM window address
# CALLED BY:    SetRomWindows
# RETURN:       nothing
# SIDE EFFECTS: Die if the address syntax is invalid
#
##############################################################################
sub CheckAddr
{
    local( $start ) = @_;

    if ( $start && $start !~ /^[a-fA-F0-9]{5}$/ ) {
	die "\nERROR: Illegal address: $start\n" .
	    "Address format=\"d0000\", for example.\n" . 
	    "It must be in hex and has 5 digits.\n"; 
    }
}

##############################################################################
#       CheckWinSize
##############################################################################
#
# SYNOPSIS:     Check the ROM window size syntax
# PASS:         arg1 = ROM window size
# CALLED BY:    SetRomWindows
# RETURN:       nothing
# SIDE EFFECTS: Die if ROM window size is incorrect.
#
##############################################################################
sub CheckWinSize {
    local( $size ) = @_;
    local( $numSize ) = $size;	       # ROM window size w/o 'k'
    
    if ( $size && $size !~ /[\d]{2,}k/ ) {
	die "\nERROR: Illegal \"romWindows\" window size: $size\n" .
	    "Size format = \"64k\", for example.\n";
    }

    # Check to see if size is a multiple of 16K
    if ( $size ) {
	$numSize =~ s/([\d]{2,})k/$1/; # Strip 'k' and get the number only
	if ( $numSize % 16 ) {
	    die "\nERROR: Illegal \"romWindows\" window size: $size\n" . 
		"ROM window size must be in multiples of 16k as in 32k, 64k, etc.\n";
	}
    }
}

##############################################################################
#       CheckDemoDir
##############################################################################
#
# SYNOPSIS:     Check the demo directory syntax
# PASS:         arg1 = demo directory
# CALLED BY:    Main
# RETURN:       nothing
# SIDE EFFECTS: Die if demo directory syntax is incorrect
#
##############################################################################
sub CheckDemoDir {
    local( $demodir ) = @_;

    if ( $demodir !~ /^[A-Za-z]{1}:\\/ ) {
	die "\nERROR: Demo directory must be a DOS path: $demodir\n";
    }
}

##############################################################################
#       AddGbuildArg
##############################################################################
#
# SYNOPSIS:     Add a gbuild settings argument to the argument list
# PASS:         arg1 = key
#               arg2 = value
#               For example, to add "ec=true", call AddGbuildArg("ec", "true")
# CALLED BY:    Main
# RETURN:       nothing
#
##############################################################################
sub AddGbuildArg {
    local( $key, $value ) = @_;
    $GbuildArgs .= "\"$key=$value\" ";
}

##############################################################################
##############################################################################
###
###			Utility Routines
###
##############################################################################
##############################################################################

##############################################################################
#       Usage
##############################################################################
#
# SYNOPSIS:     Print out the usage of this program
# PASS:         Nothing
# CALLED BY:    Main
# RETURN:       nothing
#
##############################################################################
sub Usage {
    print <<EOM;
Synopsis:
	"buildbbx" is an interactive script that allows one to create
	an bbxensem image easily with various customization.

Usage:
 	bbxxip [-h] [-debug] [-noprompt] [-template] [-xip] [-i <directory>]
                 [-s <directory>] [<gbuild argument>+]

  	-h or -help:	Bring up this help message
  	-debug:	        Debug mode. Do not really create any image.
        -nolocal:       Do not look at .local file, the download list file
        -noprompt:      Don't ask the user for input, use the defaults.
        -template:      Only send template files, like *.INI files, and 
                        not any images
	-xip:		Make an XIP image
        -i <source directory>: 
 			Specify the directory to search for source
 			files before installed ones.
        -s <build file directory>: 
 			Specify the top directory where the *.build
                        and *.filetree files should be used. 
 			"Tools/build/product/bbxensem" should be omitted
 			in <build file directory>. 
 
 			For example, if you have *.build files in 
 			c:\pcgeos\simon\Tools\build\product\bbxensem\,
 			you only need to specify "-s c:\pcgeos\todd".

        <gbuild argument>+:
			The extra arguments you want to pass to gbuild. 

Cache Files:
	User input is cached in cache files. These files are located in:

	Windows NT: 
	    %LOCAL_ROOT%\\$CONFIG_FILE_ROOT\\.*
	UNIX:
	    /staff/\$USER/$CONFIG_FILE_ROOT/.*

Setup requirement:
	Windows NT:
	    %LOCAL_ROOT% variable must be set. This is the directory used
	    to cache user's input from the script.
EOM
}

##############################################################################
#       IsWinNT
##############################################################################
#
# SYNOPSIS:     Check if we are running under WinNT
# PASS:         Nothing
# CALLED BY:    Main
# RETURN:       1 if running under NT
#               0 otherwise
#
##############################################################################
sub IsWinNT {
    if ( $ENV{"OS"} ) {
	return ( $ENV{"OS"} eq "Windows_NT" );
    } else {
	return 0;
    }
}

##############################################################################
#       ReadUserInput
##############################################################################
#
# SYNOPSIS:     Clean up user input
# PASS:         arg1 = default value
# CALLED BY:    Main
# RETURN:       cleaned up user input string
#
##############################################################################
sub ReadUserInput {
    local( $default ) = @_; 
    if ( $opt_noprompt ) {
	print "\n";
	return $default;
    }
    $input = <STDIN>;
    chop( $input );
    if ( ! "$input" ) {			# To get rid of warnings
	return $default;		# below if no input
    }
    $input =~ s/^[\s]+//g;
    $input =~ s/[\s]+$//g;
    if ( "$input" ) {
	return $input;
    } else {
	return $default;
    }
}

##############################################################################
#       YesNo2TrueFalse
##############################################################################
#
# SYNOPSIS:     Convert "y/n" into "true/false"
# PASS:         arg1 = 'y' or 'n'
# CALLED BY:    Main
# RETURN:       "true" or "false" according to argument
#
##############################################################################
sub YesNo2TrueFalse {
    local( $arg ) = @_;
    if ( $arg eq "y" ) {
	return "true";
    }
    print "Invalid argument to YesNo2TrueFalse: assuming \"n\"\n"
	if ( $arg ne "n" ); 
    return "false";
}

##############################################################################
#       FormatPath
##############################################################################
#
# SYNOPSIS:     Convert paths
# PASS:         arg1 = path string
#		arg2 = 0 to convert to UNIX paths OR
#		       1 to convert to DOS paths
# CALLED BY:    Main
# RETURN:       converted path
#
##############################################################################
sub FormatPath {
    local( $arg, $pathType ) = @_;
    
    #
    # Convert all backslashes to forward slashes
    #
    if ( $pathType ) {
        $arg =~ s/\//\\/g;
    } else {
        $arg =~ s/\\/\//g;
    }
    return $arg;
}

##############################################################################
#       CRLF2CR
##############################################################################
#
# SYNOPSIS:     Convert a string ending with CRLF into one ending with CR
# PASS:         arg = string to convert
# CALLED BY:    INTERNAL
# RETURN:       converted string
#
##############################################################################
sub CRLF2CR {
    local( $arg ) = @_;

    $arg =~ s/\r//;
    return $arg;
}

##############################################################################
##############################################################################
###
###		Cache File Utilities
###
##############################################################################
##############################################################################

#
# There are 3 types of cache files that store the user inputs:
# General
#    .bbxxip:	Stores common info that applies to any platform and
#		EC/NEC version
#    .bbxxip.$platform (e.g. .bbxxip.pc):
#		Stores common info that applies to a particular
#		platform, but common to both EC/NEC version
#    .bbxxip.$platform.$ec (e.g. .bbxxip.pcxip.ec):
#		Stores info for EC/NEC specific information on a
#               particular platform
#

##############################################################################
#       ReadCommonInputFromCache
##############################################################################
#
# SYNOPSIS:     Read common non-target specific information from cache 
#               files to set default values
# PASS:         nothing
# CALLED BY:    Main
# RETURN:       nothing
# NOTES:
#	The file format of the common configuration file is:
#       
#       target=
#
##############################################################################
sub ReadCommonInputFromCache {
    #
    # Read the file if it exists
    #
    if ( -f $CommonConfigFile ) {
	open( CONFIG_FILE, "< $CommonConfigFile" ) || 
	    die "\nERROR: Cannot read from configuration file: $CommonConfigFile\n";

	#
	# Parse the configuration file
	#
	while ( <CONFIG_FILE> ) {
	    
	    # Get last saved target
	    if ( /^target=(.*)/ ) {
		$DefaultInfo{target} = CRLF2CR( $1 );
	    }
	}
	close( CONFIG_FILE );
    }
}

##############################################################################
#       SaveCommonInputToCache
##############################################################################
#
# SYNOPSIS:     Save common non-target specific information to cache 
#               files
# PASS:         nothing
# CALLED BY:    Main
# RETURN:       nothing
# NOTES:
#	The file format of the common configuration file is:
#       
#       target=
#
##############################################################################
sub SaveCommonInputToCache {

    if ( ! -d "$LocalDir/$CONFIG_FILE_ROOT" ) {
	mkdir( "$LocalDir/$CONFIG_FILE_ROOT", 0777 ) || 
	    die "\nERROR: Cannot create configuration file directory: $LocalDir/$CONFIG_FILE_ROOT\n";
    }

    open( CONFIG_FILE, "> $CommonConfigFile" ) || 
	die "\nERROR: Cannot write to configuration file: $CommonConfigFile\n";

    # Write the target to configuration file
    print CONFIG_FILE "target=$RealInfo{target}\n";

    close( CONFIG_FILE );
}

##############################################################################
#       ReadTargetCommonInputFromCache
##############################################################################
#
# SYNOPSIS:     Read common target specific information from cache 
#               files to set default values
# PASS:         nothing
# CALLED BY:    Main
# RETURN:       nothing
# NOTES:
#	The file format of the target common configuration file:
#       
#       Win32 (.bbx.win32) or DOS (.bbx.pc):
#       ec=
#       mapblock=
#       romwindows=
#
##############################################################################
sub ReadTargetCommonInputFromCache {


    local( $targetConfigFile ) = 
	"$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT.$RealInfo{target}";
    
    if ( -f $targetConfigFile ) {
	open( PLATFORM_CONFIG_FILE, "< $targetConfigFile" ) ||
	    die "\nERROR: Cannot read from configuration file: $targetConfigFile\n";
        #
        # Read in the platform specific file information
        #
	while ( <PLATFORM_CONFIG_FILE> ) {
	    #
	    # Read in common configuration settings
	    #
	    COMMONCACHE: {
		if ( /^patching=(.*)/ ) {
		    $DefaultInfo{patching} = CRLF2CR( $1 );
		    last COMMONCACHE;
		} 
		if ( /^reseditpath=(.*)/ ) {
		    $DefaultInfo{reseditpath} = CRLF2CR( $1 );
		    last COMMONCACHE;
		}
		if ( /^transpath=(.*)/ ) {
		    $DefaultInfo{transpath} = CRLF2CR( $1 );
		    last COMMONCACHE;
		}
		if ( /^logpath=(.*)/ ) {
		    $DefaultInfo{logpath} = CRLF2CR( $1 );
		    last COMMONCACHE;
		}
		if ( /^shipfiles=(.*)/ ) {
		    $DefaultInfo{shipfiles} = CRLF2CR( $1 );
		}
		if ( /^vm=(.*)/ ) {
		    $DefaultInfo{vm} = CRLF2CR( $1 );
		}
	    }

	    # PC XIP info file
	      if ( $RealInfo{target} eq $TARGET_PC_XIP ||
		   $RealInfo{target} eq $TARGET_NT_XIP    ) {
		CACHE: {
		    if ( /^ec=(.*)/ ) {
			$DefaultInfo{ec} = CRLF2CR( $1 );
			last CACHE;
		    }
		    if ( /^dbcs=(.*)/ ) {
			$DefaultInfo{dbcs} = CRLF2CR( $1 );
			last CACHE;
		    }
		    if ( /^mapblock=(.*)/ ) {
			$DefaultInfo{mapblock} = CRLF2CR( $1 );
			last CACHE;
		    }
		    if ( /^romwindows=(.*)/ ) {
			$DefaultInfo{romwindows} = CRLF2CR( $1 );
			last CACHE;
		    }
		}
	    }
	      
	}
        close( PLATFORM_CONFIG_FILE );
    }
}

##############################################################################
#       SaveTargetCommonInputToCache
##############################################################################
#
# SYNOPSIS:     Save common target specific information to cache 
#               files
# PASS:         nothing
# CALLED BY:    Main
# RETURN:       nothing
# NOTES:
#	The file format of the common configuration file is:
#       
#       Win32 (.bbx.win32) or DOS (.bbx.pc):
#       ec=
#       mapblock=
#       romwindows=
#
##############################################################################
sub SaveTargetCommonInputToCache {
    local( $targetConfigFile ) = 
	"$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT.$RealInfo{target}";
    
    #
    # Do not create common target cache file for Lizzy prototypes because 
    # there is nothing in there.
    #
    open( TARGET_CONFIG_FILE, "> $targetConfigFile" ) || 
	die "\nERROR: Cannot write to configuration file: $targetConfigFile\n";

    # Common configuration for patching
    print TARGET_CONFIG_FILE "patching=$RealInfo{patching}\n";
    print TARGET_CONFIG_FILE "reseditpath=$RealInfo{reseditpath}\n";
    print TARGET_CONFIG_FILE "transpath=$RealInfo{transpath}\n";
    print TARGET_CONFIG_FILE "logpath=$RealInfo{logpath}\n";
    print TARGET_CONFIG_FILE "shipfiles=$RealInfo{shipfiles}\n";
    print TARGET_CONFIG_FILE "vm=$RealInfo{vm}\n";

    # Write nightly make info
    print TARGET_CONFIG_FILE "nightlymake=$RealInfo{nightlymake}\n";
   
    # Write the target to configuration file
    TARGETCACHE: {
	if ( $RealInfo{target} eq $TARGET_PC_XIP || 
	    $RealInfo{target} eq $TARGET_PC_XIP  ) {
	    print TARGET_CONFIG_FILE "ec=$RealInfo{ec}\n";
	    print TARGET_CONFIG_FILE "dbcs=$RealInfo{dbcs}\n";
	    print TARGET_CONFIG_FILE "mapblock=$RealInfo{mapblock}\n";
	    print TARGET_CONFIG_FILE "romwindows=$RealInfo{romwindows}\n";
	    last TARGETCACHE;
	}
    }    

    close( TARGET_CONFIG_FILE );
}

##############################################################################
#       ReadTargetInputFromCache
##############################################################################
#
# SYNOPSIS:     Read target specific information from cache 
#               files to set default values
# PASS:         nothing
# CALLED BY:    Main
# RETURN:       nothing
# NOTES:
#	The file format of the target common configuration file:
#       
#       Common:
#       destdir= 
#       shipfiles=
#
#       Win32 or PC only:
#       demodir=
#
##############################################################################
sub ReadTargetInputFromCache {
    local( $ecSuffix ) = "nec";	# extension of EC/NEC filename suffix
    if ( $RealInfo{ec} eq "y" ) {
	$ecSuffix = "ec";
    }
    local( $targetConfigFile ) = 
	"$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT.$RealInfo{target}.$ecSuffix";
    if ( $RealInfo{dbcs} eq "y" ) {
	$targetConfigFile = 
	"$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT.$RealInfo{target}.dbcs.$ecSuffix";
    }
    
    if ( -f $targetConfigFile ) {
	open( PLATFORM_CONFIG_FILE, "< $targetConfigFile" ) ||
	    die "\nERROR: Cannot read from configuration file: $targetConfigFile\n";
        #
        # Read in the platform specific file information.
	# At this point, all platform specific info is just the
        # intermediate temporary directory
        #
	while ( <PLATFORM_CONFIG_FILE> ) {
	    # Directory to hold temporary files
	    if ( /^destdir=(.*)/ ) {
		$DefaultInfo{destdir} = CRLF2CR( $1 );
	    }

	    # Read demo directory for non-prototype platforms
	    if ( $RealInfo{target} eq $TARGET_PC_XIP ||
		$RealInfo{target} eq $TARGET_NT_XIP ||
		$RealInfo{target} eq $TARGET_NT ||
		$RealInfo{target} eq $TARGET_DEMO ||
		$RealInfo{target} eq $TARGET_NT_TOOLS ||
		 $RealInfo{target} eq $TARGET_PC ) {
		if ( /^demodir=(.*)/ ) {
		    $DefaultInfo{demodir} = CRLF2CR( $1 );
		}
	    }
	}

        close( PLATFORM_CONFIG_FILE );
    }
}

##############################################################################
#       SaveTargetInputToCache
##############################################################################
#
# SYNOPSIS:     Save target specific information to cache files
# PASS:         nothing
# CALLED BY:    Main
# RETURN:       nothing
# NOTES:
#	The file format of the common configuration file is:
#       
#       destdir=
#
##############################################################################
sub SaveTargetInputToCache {
    local( $ecSuffix ) = "nec";	# extension of EC/NEC filename suffix
    if ( $RealInfo{ec} eq "y" ) {
	$ecSuffix = "ec";
    }
    local( $targetConfigFile ) = 
	"$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT.$RealInfo{target}.$ecSuffix";
    if ( $RealInfo{dbcs} eq "y" ) {
	$targetConfigFile = 
	"$LocalDir/$CONFIG_FILE_ROOT/$CONFIG_FILE_ROOT.$RealInfo{target}.dbcs.$ecSuffix";
    }
    
    open( TARGET_CONFIG_FILE, "> $targetConfigFile" ) || 
	die "\nERROR: Cannot write to configuration file: $targetConfigFile\n";

    #
    # Write the platform specific information. At this point, only
    # intermediate temporary directory is kept.
    # 
    print TARGET_CONFIG_FILE "destdir=$RealInfo{destdir}\n";

    #
    # Write demo directory for non-prototypes
    #
    if ( $RealInfo{target} eq $TARGET_PC_XIP ||
	 $RealInfo{target} eq $TARGET_PC ||
	$RealInfo{target} eq $TARGET_NT ||
	$RealInfo{target} eq $TARGET_DEMO ||
	$RealInfo{target} eq $TARGET_NT_TOOLS ||
	$RealInfo{target} eq $TARGET_NT_XIP ) {
	print TARGET_CONFIG_FILE "demodir=$RealInfo{demodir}\n";
    }

    close( TARGET_CONFIG_FILE );
}

##############################################################################
##############################################################################
###
###		Copy demo and image files to target directory
###
##############################################################################
##############################################################################

##############################################################################
#       CopyFilesToDemoDir
##############################################################################
#
# SYNOPSIS:     Copy image and demo files to target demo directory
# PASS:         $RealInfo{demodir} = target demo directory
#               $RealInfo{destdir} = gbuild dest tree 
# CALLED BY:    Main
# RETURN:       nothing
#
##############################################################################
sub CopyFilesToDemoDir {
    $DemoTargetDir = FormatPath( $RealInfo{demodir}, 0 );
    $GbuildTargetDir = $RealInfo{destdir};

    if ( ! IsWinNT() ) {
	#
	# If we are not running from Windows NT, assume we are running
	# in UNIX. We need to change target directory to UNIX  
	# path in order to copy the files there if demo directory
	# starts in F: drive. If it is not F: drive, simply do nothing.
	#
	if ( $DemoTargetDir =~ m/^f:/i ) {
	    $DemoTargetDir =~ s/^f:/\/n\/users\/$ENV{USER}/i;
	} else {
	    return;
	}
    }

    print "\nCopying files to target demo directory...\n";

    #
    # Create target demo directory if it does not exist
    #
    if ( ! -d $DemoTargetDir ) {
	print "+ mkdir $DemoTargetDir\n";
	if ( ! $opt_debug ) {
	    mkdir( $DemoTargetDir, 0777 ) ||
		die "\nERROR: Cannot create demo directory $DemoTargetDir\n";
	}
    }
    
    $DemoTargetDir =~ s/\/$//;	           # Remove prepending slashes

    #
    # Copy XIP and GFS files there
    #
    print "+ copy $GbuildTargetDir/image/xip.img $DemoTargetDir/xipimage\n";
    if ( ! $opt_debug ) {
	copy( "$GbuildTargetDir/image/xip.img", "$DemoTargetDir/xipimage" ) ||
	    die "\nERROR: Cannot copy XIP image file:\n" .
		"$GbuildTargetDir/image/xip.img -> $DemoTargetDir/xipimage"; 
    }

    print "+ copy $GbuildTargetDir/image/gfs.img $DemoTargetDir/resp.gfs\n";
    if ( ! $opt_debug ) {
	copy( "$GbuildTargetDir/image/gfs.img", "$DemoTargetDir/resp.gfs" ) ||
	    die "\nERROR: Cannot copy GFS image file:\n" .
		"$GbuildTargetDir/image/gfs.img -> $DemoTargetDir/resp.gfs";
    }

    #
    # If the demo directory is the same as the gbuild source directory
    # storing the demo files, return
    #
    if ( "$GbuildTargetDir/localpc" ne "$DemoTargetDir" ) {
	if ( -d "$GbuildTargetDir/localpc" ) {
	    find (\&CopyFileToDemoDirCallback, "$GbuildTargetDir/localpc");
	} else {
	    print "\nERROR: Cannot find demo file directory: $GbuildTargetDir/localpc\n";
	}
    }
}

##############################################################################
#       CopyFileToDemoDirCallback
##############################################################################
#
# SYNOPSIS:     Copy a demo file or make a directory to the target demo 
#               directory 
# PASS:         $File::Find::name = enumerated file or directory from gbuild 
#                                   desttree localpc directory
#               $GbuildTargetDir  = gbuild desttree directory
#               $TargetDemoDir    = target demo directory
# CALLED BY:    $File::Find::find callback
# RETURN:       nothing
#
##############################################################################
sub CopyFileToDemoDirCallback {
    local( $relativeDir ) = $File::Find::dir;
    local( $targetDir );                    # Target top directory

    #
    # Get the directory without "$demodir/localpc" part
    #
    $relativeDir =~ s/$GbuildTargetDir\/localpc//;
    $relativeDir =~ s/^\///;                # Remove prepending slashes

    #
    # Form the target directory to copy files to
    #
    if ( $relativeDir eq "" ) {
	$targetDir = "$DemoTargetDir";
    } else {
	$targetDir = "$DemoTargetDir/$relativeDir";
    }

    #
    # If a directory is found, make sure the directory exists
    #
    if ( -d "$_" ) {
	if ( ! -d "$targetDir/$_" ) {
	    print "+ mkdir $targetDir/$_\n";
	    if ( ! $opt_debug ) {
		mkdir( "$targetDir/$_", 0777 ) ||
		    die "\nERROR: Cannot create directory: $targetDir/$_\n";
	    }
	}
	return;
    }

    #
    # Always copy net{ec}.ini and loader{ec}.exe.
    # For other files, if they already exist, do not copy them.
    #
    if ( ! -f "$targetDir/$_" ||
	 ( -f "$_" &&
           ( /^net.*\.ini$/i || /^loader.*\.exe$/i ) ) ) {
        print "+ copy $File::Find::name $targetDir/$_\n";
	if ( ! $opt_debug ) {
	    copy( "$File::Find::name", "$targetDir/$_" ) ||
		die "\nERROR: Cannot copy file:\n" .
		    "$File::Find::name -> $targetDir/$_\n";
	}
    }
}

##############################################################################
##############################################################################
###
###		Miscellaneous
###
##############################################################################
##############################################################################

sub ReadLocalFileList {
    local($localfile) = "$LocalDir/$CONFIG_FILE_ROOT/$LOCAL_LIST_FILE";
    local($isEmpty) = 1;               # flag to tell if file is empty

    if ( -e "$localfile" ) {
	# Check if it is an empty file
	open( LOCALFILE, "< $localfile" ) || 
	    die "ERROR: Cannot read download file list: $localfile\n";
	while ( <LOCALFILE> ) {
	    if ( /\w/ ) {
		$isEmpty = 0;
		break;
	    }
	}

	# Only process a non-empty file
	if ( $isEmpty == 0 ) {
	    # Print the local file list 
	    print "[Download only these files:]\n\n";
	    seek( LOCALFILE, 0, 0 );
	    while ( <LOCALFILE> ) {
		print "\t" . $_ if ( /\w/ );
	    }
	    print "\n";
	    AddGbuildArg( "deleteDestTree", "false" );
	    AddGbuildArg( "includelistfile", "$localfile" );
	}
	close( LOCALFILE );
    }
}


##############################################################################
#	CopyDemoTreeToDestTree
##############################################################################
#
# SYNOPSIS:	Copy nightly make files to the destination tree 
#               so that image can be made from there
# PASS:		
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	5/05/98   	Initial Revision
#	
##############################################################################
sub   CopyDemoTreeToDestTree {
    
    my($from, $to);

    $from = &FindDemoDir();
    $to = $RealInfo{destdir};

    #
    # Clean the destination directory

    print "Cleaning temporary directory...\n";
    &RmTree($to);

    #
    # Now do the actual copy

    &CopyTree($from, $to);
}

##############################################################################
#	CopyTree
##############################################################################
#
# SYNOPSIS:	Utility to do a recursive copy
# PASS:		from and to directories
# CALLED BY:	CopyDemoTreeToDestTree
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	5/05/98   	Initial Revision
#	
##############################################################################
sub   CopyTree {
    my($from, $to) = @_;
    
    print "Copying files from $from to $to...\n";
    #
    # Not too sophisticated platform dependent copy tree.

    if ( ! $opt_debug ) {
	if ( IsWinNT() ) {
	    $from =~ s|/|\\|g;
	    $to =~ s|/|\\|g;
	    
	    system("xcopy /e /i $from $to\\");
	    
	} else {
	    system("\\cp -r $from $to");
	}
    }
}

##############################################################################
#	RmTree
##############################################################################
#
# SYNOPSIS:	File utility to remove tree.
# PASS:		Directory to remove recursively.
# CALLED BY:	CopyDemoTreeToDestTree
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	5/05/98   	Initial Revision
#	
##############################################################################
sub RmTree {

    if ( ! $opt_debug ) {
	if ( IsWinNT() ){ # NT system
	    rmtree($_[0], 0, 1);
	} else {          # Unixsystem
	    system("\\rm -rf $_[0]");
	}
    }
}

##############################################################################
#	FindDemoDir
##############################################################################
#
# SYNOPSIS:	Find out the location of the nightly make files
# PASS:		nothing
# CALLED BY:	CopyDemoTreeToDestTree
# RETURN:	Full path of the directory
# SIDE EFFECTS:	none
#
# STRATEGY:	
#     We have made the assumptions for the location of the nightly make files:
#     
#     N:\dosxip.ec
#     N:\dosxip.nec
#     N:\patch\dosxip.ec
#     N:\patch\dosxip.nec
#     N:\ntxip.ec
#     N:\ntxip.nec
#     N:\patch\ntxip.ec
#     N:\patch\ntxip.nec
#     N:\hw20
#     N:\hw21
#     N:\hw23
#     N:\patch\hw
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	5/05/98   	Initial Revision
#	
##############################################################################
sub FindDemoDir {
    
    my ($dir, $dirname);

    if (IsWinNT) {
	$dir = "n:/";
    } else {
	$dir = "/n/nevada/";
    }
    
    if ($RealInfo{patching} eq "y") {
	$dir .= "patch/";
    }
    
    #
    # Now map the directory name using the target info.
    
    MAPDIR: {
      if ($RealInfo{target} eq $TARGET_PC_XIP) {

	  $dirname = "pcxip";
	  last MAPDIR;
      } 
      
      if ($RealInfo{target} eq $TARGET_PC) {

	  $dirname = "pc";
	  last MAPDIR;
      }

      if ($RealInfo{target} eq $TARGET_NT) {

	  $dirname = "nt";
	  last MAPDIR;
      }
      if ($RealInfo{target} eq $TARGET_NT_XIP) {

	  $dirname = "ntxip";
	  last MAPDIR;
      }
      
      if ($RealInfo{target} eq $TARGET_PROTO) {
	  $dirname = "hw";	  
	  last MAPDIR;
      }

      if ($RealInfo{target} eq $TARGET_PROTO_XIP) {
	  $dirname = "hwxip";	  
	  last MAPDIR;
     } 

      if ($RealInfo{target} eq $TARGET_DEMO) {
	  $dirname = "demo";	  
	  last MAPDIR;
      }

      if ($RealInfo{target} eq $TARGET_WIN) {
	  $dirname = "win";	  
	  last MAPDIR;
      }

      if ($RealInfo{target} eq $TARGET_PROTO_TOOLS) {
	  $dirname = "hwtools";	  
	  last MAPDIR;
      }

      if ($RealInfo{target} eq $TARGET_NT_TOOLS) {
	  $dirname = "nttools";	  
	  last MAPDIR;
      }

  }
    
    #
    # Complete the dirname with the ec/nec info
    
    if (! ($dirname =~ /hw/)) {
	if ($RealInfo{ec} eq "y") {
	    $dirname .= ".ec";
	} else {
	    $dirname .= ".nec";
	} 
    }
	
    #
    # Complete the entire path

    $dir .= $dirname;
    
    return $dir;
}

##############################################################################
#	ModifyGeosIni
##############################################################################
#
# SYNOPSIS:	Make necessary changes to GEOS.INI
# PASS:		nothing
# CALLED BY:	Main
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       simon     	6/01/98   	Initial Revision
#	
##############################################################################
sub ModifyGeosIni {
    local( $tmpini ) = "$RealInfo{destdir}/localpc/tmp.ini.$$";
                                     # Temp file to convert this INI file
    local( $ininame );               # File name of the GEOS{EC}.INI

    # Make necessary adjustment for GEOS.INI.
    # Currently, only PC and NT demos need changes to "system fs" line to
    # the demo directory.
    if ( $RealInfo{target} eq $TARGET_PC_XIP ||
	$RealInfo{target} eq $TARGET_NT ||
	$RealInfo{target} eq $TARGET_DEMO ||
	$RealInfo{target} eq $TARGET_NT_TOOLS ||
	$RealInfo{target} eq $TARGET_NT_XIP ||
	 $RealInfo{target} eq $TARGET_PC ) {
	
	# GEOSEC.INI or GEOS.INI?
	if ( $RealInfo{ec} eq "y" ) {
	    $ininame = "$RealInfo{destdir}/localpc/geosec.ini";
	} else {
	    $ininame = "$RealInfo{destdir}/localpc/geos.ini";
	}

	# Do it the INI file INI has been downloaded and writable
	if ( -f "$ininame" ) {
	    if ( ! -w "$ininame" ) {
		die "\nERROR: Cannot modify $ininame.\n";
	    } else {

		# Fill in "system fs" line with "demodir"
		print "Updating $ininame...\n";
		open( FROMINI, "< $ininame" );
		open( TOINI, "> $tmpini" ) || 
		    die "\nERROR: Cannot write to temporary $tmpini.\n";

		binmode FROMINI;
		binmode TOINI;
		while ( <FROMINI> ) {
		    s/system fs.*=[\S ]*/system fs = $RealInfo{demodir}/i;
		    print TOINI $_;
		}

		close( TOINI );
		close( FROMINI );

		# Rename temp file -> INI file
		rename( $tmpini, $ininame ) ||
		    die "\nERROR: Cannot rename $tmpini to $ininame.\n";
	    }
	}
    }
}


