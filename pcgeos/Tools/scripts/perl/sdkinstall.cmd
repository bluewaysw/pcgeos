@rem = '-*- Perl -*-';
@rem = '
@echo off
@echo GEOS SDK Installer (v1.0) [Requires Perl 5.003 or later]
if not exist sdkinstall.cmd goto usepath:
perl sdkinstall.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:usepath
perl -S %0.cmd %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
';
# $Id: sdkinstall.cmd,v 1.16 97/08/27 14:43:59 mjoy Exp $

require "NT.ph";

use File::Basename;
use File::Path;
use File::Copy;

undef $errorOccurred;

print <<EOM;

You are about to install the local portion of the NT GEOS SDK.

EOM

$rootDir = GetDir("Please type in the directory where the \"network\" SDK is\ninstalled (from CD-ROM).\n", $ENV{'ROOT_DIR'});

$borlandDir = GetDir("Please type in the name of the directory where Borland C++ is installed.\n", $ENV{'GOC_COMPILER_DIR'} || "c:\\bc5");

$defaultLocal = $ENV{'USERNAME'};
$defaultLocal = "$rootDir\\$defaultLocal" if (defined $defaultLocal);
while (1) {
    print("Type in the directory where you will do GEOS development.\n",
	  $defaultLocal ? "(default = $defaultLocal)" : "", " > ");
    chomp($localRoot = <STDIN>);
    if ($localRoot eq "") { 
	$localRoot = $defaultLocal;
    }

    #
    # Canonicalize directory names, otherwise the perl funcs get
    # unhappy.
    #
    $localRoot =~ y,A-Z\\,a-z/,;
    $rootDir =~ y,A-Z\\,a-z/,;

    $baseRoot = basename($rootDir);
    last if ($baseRoot eq (basename(dirname($localRoot))));

    print("The directory name you enter must be of the form:\n",
	  "  <drive letter>:<anything>\\$baseRoot\\<subdirectory name>\n",
	  "Some examples include:\n",
	  "\t$defaultLocal\n",
	  "\tc:\\$baseRoot\\geosdev\n");
}

#
# Now create the standard subdirectories
#
foreach $subdir ("Include", "CInclude", "Appl", "Library", "Driver") {
    my($fullPath) = "$localRoot/$subdir";
    if (! -d $fullPath) {
	mkpath($fullPath) || Warning("Cannot create directory '$fullPath': $!\n");
    }
}

#
# Find the branch file.  
#
if (!opendir(D, $rootDir)) {
    Warning("Cannot read directory '$rootDir': $!\n");
} else {
    @subdirs = readdir(D);
    undef $branchFound;
    foreach $dir (@subdirs) {
	$dir = $rootDir . "/" . $dir;
	$branchFile = $dir . "/" . "BRANCH";
	if (-d $dir && -e $branchFile) {
	    #
	    # Found a BRANCH file.  Only accept it if it contains
	    # its own directory name, so that we don't pick up
	    # some random user's BRANCH file.
	    #
	    $branch = GetBranchFromFile($branchFile);
	    if ($dir =~ m,/$branch$,i) {
		$branchFound = 1;
		last;
	    } else {
		undef $branch;
	    }
	}
    }
    if (!$branchFound) {
	print("Could not find BRANCH file\n");
    } else {
	print("Copying '$branchFile' to '$localRoot/BRANCH'...");
	if (copy($branchFile, "$localRoot/BRANCH")) {
	    print(" done\n");
	} else {
	    Warning("Cannot copy '$branchFile' to $localRoot: $!\n");
	}
    }
    closedir(D);
}


#
# Now add files=80, and setver line to config.nt.
#
$CONFIG_NT = "$ENV{SystemRoot}/system32/config.nt";
$CONFIG_BAK = "$ENV{SystemRoot}/system32/config.bak";
if (!copy($CONFIG_NT, $CONFIG_BAK)) {
    Warning("Cannot copy '$CONFIG_NT' to '$CONFIG_BAK': $!\n");
} else {
    if (!open(CONFIG, "+<$CONFIG_NT")) {
	Warning("Cannot open '$CONFIG_NT': $!\n");
    } else {
	my($numFiles) = 100;	# the minimum
	my($setverFound);
	while (<CONFIG>) {
	    #
	    # Jus' keep track of the maximum number files was set to
	    # (the user could have 2 or more files lines, the 2nd 
	    # overriding the first).
	    #
	    if (/^\s*files\s*=\s*(\d+)\s*/i) { 
		if ($numFiles < $1) {
		    $numFiles = $1;
		}
		next;	# we'll always print files= line at the end
	    }

	    $setverFound = 1 if /^\s*device\s*=\s*.*setver\.exe/i;
	    push(@lines, $_);
	}

	#
	# Now write back the lines of config.nt that we read in.
	#
	if (!seek(CONFIG, 0, 0)) {
	    Warning("Can't seek to beginning of '$CONFIG_NT': $!\n");
	} else {
	    for (@lines) {
		if (!print(CONFIG)) {
		    Warning("Cannot write to '$CONFIG_NT': $!\n");
		    last;
		}
	    }
	}

	#
	# Add the files line at the end.  Add setver if it's not
	# there already.
	#
	print("Adding files setting to 'config.nt'...");
	print(CONFIG "\n");	# in case final line didn't have a CR\LF at end
	if (!print(CONFIG "files=$numFiles\n")) {
	    Warning("Cannot write to '$CONFIG_NT': $!\n");
	} else {
	    print(" done\n");
	    unless($setverFound) {
		print("Adding setver to 'config.nt'... ");
		if (!print(CONFIG 
			   'device=%SystemRoot%\system32\setver.exe', "\n")) {
		    Warning("Cannot write to '$CONFIG_NT': $!\n");
		} else {
		    print(" done\n");
		}
	    }
	}

	close CONFIG;
    }
}

`setver loader.exe 9.0`;
`setver loaderec.exe 9.0`;

#
# Copy over the demos.
# XXX: different for each SDK.
#
$safeRootDir = $rootDir;
$safeRootDir =~ s,/,\\,g;
$safeLocalRoot = $localRoot;
$safeLocalRoot =~ s,/,\\,g;
#
# /q	- silent
# /s	- copy all files recursively
# /i	- assume target is directory
# /c	- continue after error
print "Copying GEOS targets...";
`xcopy /q /s /i /c $safeRootDir\\Target $safeLocalRoot\\Target`;
print " done\n";

#
# Set a bunch of stuff in the user's environment.
#
print "Modifying Registry...";
if (!Win32::RegOpenKeyEx(&HKEY_CURRENT_USER, 'Environment', &NULL, 
			 &KEY_ALL_ACCESS, $hkey)) {
    Warning("Cannot access Environment variables: $!\n");
} else {
    #
    # Set PATH in local environment.
    #
    # If there's already a PATH in here, then we need to add to it. 
    # If there isn't, we need to create it, then add in our stuff.
    #
    if (!Win32::RegQueryValueEx($hkey, 'Path', &NULL, $pathType, 
				$pathstring)) {
	$pathType = &REG_EXPAND_SZ;
    }
    #
    # Switch back to \\'s for NT's sake.
    #
    $bindir = "$rootDir/bin";
    $bindir =~ y,/,\\,;
    $bindirMatch = quotemeta $bindir;	# so \'s don't mess up grep
    $pathstring = "$bindir;" . join (';', grep(!/($bindirMatch|\.)/i, split(/;/, $pathstring)));
    $pathstring .= ";" if ($pathstring !~ /;$/);

    #print "path: $pathstring\n";
    Win32::RegSetValueEx($hkey, 'Path', &NULL, $pathType, $pathstring)
	|| Warning("Cannot update PATH: $!\n");

    Win32::RegSetValueEx($hkey, 'GOC_COMPILER_DIR', &NULL, &REG_SZ, 
			 $borlandDir)
	|| Warning("Cannot set GOC_COMPILER_DIR in Environment: $!\n");
    
    Win32::RegSetValueEx($hkey, 'ROOT_DIR', &NULL, &REG_SZ, $safeRootDir)
	|| Warning("Cannot set ROOT_DIR in Environment: $!\n");
    
    Win32::RegSetValueEx($hkey, 'CCOM', &NULL, &REG_SZ, "\@dosfront bcc")
	|| Warning("Cannot set CCOM in Environment: $!\n");

    Win32::RegCloseKey($hkey);
}

if (!Win32::RegCreateKey
    (&HKEY_CURRENT_USER, 'Software\Geoworks', $hkey)) {
    Warning("Cannot add Registry setting 'Software\Geoworks': $!\n");
} else {
  Win32::RegSetValueEx($hkey, 'USE_ALTERNATE_SDK', &NULL, &REG_SZ, "ntsdk30");

  Win32::RegCloseKey($hkey);
}

if (!Win32::RegCreateKey
    (&HKEY_CURRENT_USER, 'Software\Geoworks\GeosDLL', $hkey)) {
    Warning("Cannot add Registry setting 'Software\Geoworks\GeosDLL': $!\n");
} else {
  Win32::RegSetValueEx($hkey, 'FastVideo', &NULL, &REG_SZ, "fast");

  Win32::RegCloseKey($hkey);
}

if (!Win32::RegCreateKey
    (&HKEY_CURRENT_USER, 'Software\Geoworks\ntsdk30', $hkey)) {
    Warning("Cannot add Registry setting for 'Software\Geoworks\ntsdk30':$!\n");
} else {
  Win32::RegSetValueEx($hkey, 'BRANCH', &NULL, &REG_SZ, $branch);
  Win32::RegSetValueEx($hkey, 'LOCAL_ROOT', &NULL, &REG_SZ, $localRoot);
  Win32::RegSetValueEx($hkey, 'ROOT_DIR', &NULL, &REG_SZ, $safeRootDir);
  Win32::RegSetValueEx($hkey, 'SERIAL_BAUD_RATE', &NULL, &REG_DWORD, 0x2580);
  Win32::RegSetValueEx($hkey, 'SERIAL_COM_PORT', &NULL, &REG_DWORD, 0x1);
    
  Win32::RegCloseKey($hkey);
}

if (!Win32::RegCreateKey
    (&HKEY_CURRENT_USER, 'Software\Geoworks\ntsdk30\Swat', $hkey)) {
    Warning("Cannot add Registry setting 'Software\Geoworks\ntsdk30\Swat': $!\n");
} else {
  Win32::RegSetValueEx($hkey, 'COMM_MODE', &NULL, &REG_SZ, 'Named Pipe');
  Win32::RegSetValueEx($hkey, 'CUSTOM_TCL_LOCATION', &NULL, &REG_SZ, "");
  Win32::RegSetValueEx($hkey, 'GEODE_SUBDIR', &NULL, &REG_SZ, 'Installed');
  Win32::RegSetValueEx($hkey, 'GEODE_TYPE_1', &NULL, &REG_SZ, 'Appl');
  Win32::RegSetValueEx($hkey, 'GEODE_TYPE_2', &NULL, &REG_SZ, 'Library');
  Win32::RegSetValueEx($hkey, 'GEODE_TYPE_3', &NULL, &REG_SZ, 'Driver');
  Win32::RegSetValueEx($hkey, 'GEODE_TYPE_4', &NULL, &REG_SZ, 'Loader');
  Win32::RegSetValueEx($hkey, 'GEODE_TYPE_KERNEL', &NULL, &REG_SZ, 'Kernel');
  Win32::RegSetValueEx($hkey, 'NAMED_PIPE', &NULL, &REG_SZ, '\\\\.\pipe\swatpipe');
  Win32::RegSetValueEx($hkey, 'NUM_GEODE_TYPES', &NULL, &REG_DWORD, 0x5);
  Win32::RegSetValueEx($hkey, 'SYSLIB_SUBDIR', &NULL, &REG_SZ, 'Tools/swat/lib.new');
  Win32::RegSetValueEx($hkey, 'SYSLIB_OVERRIDE_PATH', &NULL, &REG_SZ, '');
  Win32::RegSetValueEx($hkey, 'TERM', &NULL, &REG_SZ, 'smart');
  Win32::RegSetValueEx($hkey, 'TIMEOUT_MULTIPLIER', &NULL, &REG_DWORD, 0x1);
    
  Win32::RegCloseKey($hkey);
}
print " done\n";

if (!$errorOccurred) {
    print "Local SDK sucessfully installed.  Please log out and log back in for\n",
    "the changes to take effect.\n";
} else {
    print "Errors occurred during Local SDK installation.  Please refer to\n",
    "the documentation to find out how to complete the installation\n",
    "manually.\n";
}

#
# So they'll have time to read output of script if running from icon.
#
#print "\n\nHit RETURN to finish.";
#<STDIN>;

exit 0;

##############################################################################
#	Warning
##############################################################################
#
# SYNOPSIS:	Do a warn, plus set flag that error occurred.
# PASS:		message to print
# CALLED BY:	(UTILITY)
# RETURN:	nothing
# SIDE EFFECTS:	
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       jacob    	2/26/97   	Initial Revision
#	
##############################################################################
sub Warning {
    my($msg) = @_;
    
    warn $msg;
    $errorOccurred = 1;
}

##############################################################################
#	GetBranchFromFile
##############################################################################
#
# SYNOPSIS:	Get branch from BRANCH file
# PASS:		filename
# CALLED BY:	(UTILITY)
# RETURN:	branch
# SIDE EFFECTS:	none
#
# STRATEGY:	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       jacob    	2/27/97   	Initial Revision
#	
##############################################################################
sub GetBranchFromFile {
    my($branchFile) = @_;

    #
    # Open the BRANCH file to get the branch name, so we can set
    # it in the registry.
    #
    my($branch);
    if (!open(BRANCHFILE, "<$branchFile")) {
	Warning("Cannot read branch name from '$branchFile': $!\n");
    } else {
	$line = <BRANCHFILE>;
	if ($line =~ /^([^\s]+)/) {
	    $branch = $1;
	}
	close BRANCHFILE;
    }
    return $branch;
}



##############################################################################
#	GetDir
##############################################################################
#
# SYNOPSIS:	Prompt user until they enter a valid directory name
# PASS:		$message - to prompt with
#		$default - default directory name
# CALLED BY:	
# RETURN:	directory name
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       jacob 	1/22/97   	Initial Revision
#
##############################################################################
sub GetDir {
    my($message, $default) = @_;
    my($dir);
    while (1) {
	print($message,
	      $default ? "(default = $default)" : "", " > ");
	chop($dir = <STDIN>);
	$dir = $default if ($dir eq "");
	last if -d $dir;
	print("'$dir' is not a directory; please try again.\n");
    }

    return $dir;
}
__END__
:endofperl
pause
