#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script
# FILE: 	fileutil.pl
# AUTHOR: 	Paul Canavese, Mar 25, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	3/25/96   	Initial Revision
#
# DESCRIPTION:
#
#	File and directory utility subroutines.
#
# SUBROUTINES:
#
#	MakeDir(<directory>)
#		Create passed directory, with @DIRNAME file if necessary.
#	MakePath(<path>)
#		Check if path exists.  If not, create it.
#	SendFile(<file>, <destination>)
#		Send specified file to destination.
#	FindInstalledFile(<file>)
#		Look for file in the source directories.
#	CopyFile(<file>, <destination>)
#		Copy the file to destination.
#	Dosify(<filename>)
#		Convert a filename that may have more than eight characters
#		before the period because of added ec characters to 8.3 format.
#	GEOSToDOSFileName(<filename>)
#		Convert a potentially long GEOS file name to an approximation
#		of its DOS file name.
#	GEOSToDOSPathName(<filename>)
#		Convert potentially long GEOS directory names in a path to
#		their DOS directory names.
#	BuildDestTreePath()
#		If destination path has not been explicitly defined, set it
#		based on the build variables.  Create the path if it doesn't
#		exist.
#	AbbrevPath()
#		Abbreviate the passed path.
#	ReplaceProductDir(<path>, <product directory>)
#		Remove a product sub-directory from the passed path (if it
#               exists, then insert the passed product dir.
#
#	$Id: fileutil.pl,v 1.29 98/04/24 16:58:19 kliu Exp $
#
###############################################################################

1;


##############################################################################
#	MakeDir
##############################################################################
#
# SYNOPSIS:	Create passed directory, with @DIRNAME file if necessary.
# PASS:		<directory> = full path of directory to create
# CALLED BY:	various
# RETURN:	DOS name of created directory
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub MakeDir{

    local($longname, $dosname, $destpath, $abbrevto);

    # Determine the GEOS and DOS names of the directory to create.

    $longname="@_";
    $longname =~ s|.*/([\w \.]*)$|$1|;   # Grab the directory off the path.
    $dosname=&GEOSToDOSFileName("$longname");

    # Determine the path the directory is in, and convert it to DOS.

    $destpath="@_";
    $destpath =~ s|(.*)/[\w \.]*$|$1|;   # Grab the path.
    $destpath = &GEOSToDOSPathName("$destpath");

    # Make the directory.

    if ( -f "$destpath/$dosname" ) {
	&Error("Cannot create directory $destpath/$dosname.  A file with that name exists.\n");
    } elsif ( ! -d "$destpath/$dosname" ) {
	if ( ! "$var{syntaxtest}" ) {
	    if ( "$var{reportabbreviatedpaths}" ) {
		$abbrevto=&AbbrevPath("$destpath/$dosname");
		print " Making directory $abbrevto\n";
	    } else {
		print " Making directory $destpath/$dosname\n";
	    }
	}

	&MkDir("$destpath/$dosname");
    }
    if ( ! "$var{syntaxtest}" ) {
	print "\n";
    }

    # If the DOS name does not directly match the GEOS name, we need an
    # @DIRNAME file.

    if ( "$dosname" ne "$longname") {

	# Create the @DIRNAME file.

	if ( "$var{reportabbreviatedpaths}" ) {
	    $sourcePath=&AbbrevPath("$destpath/$dosname/\@dirname.000");
	} else {
	    $sourcePath="$destpath/$dosname/\@dirname.000";
	}
	print " Making $sourcePath\n     as ";
	if ( "$var{dbcs}" ) {
	    printf "%.16s\n\n", $longname;
	    open(DIRSRC, "$geosPath/Installed/ProductFiles/Build/Common/Template/DBCS/\dirname.000");  # Change this once we move it back a dir.
	} else {
	    printf "%.32s\n\n", $longname;
	    open(DIRSRC, "$geosPath/Installed/ProductFiles/Build/Common/Template/dirname.000");  # Change this once we move it back a dir.
	}
	open(DIRDEST, "> $destpath/$dosname/\@dirname.000");
	read(DIRSRC, $buffer, 4);
	if ( "$var{dbcs}" ) {
	    # Change string to DBCS.
	    $longname=~ s/(.)/$1\x00/g;
	}
	$longname = substr($longname, 0, 32);
	printf DIRDEST "$buffer$longname\0";
	if ( "$var{dbcs}" ) {
	    printf DIRDEST "\0";
	}
	seek(DIRSRC, tell(DIRDEST), 0);
	while(<DIRSRC>) {
	    print DIRDEST "$_";
	}
	close(DIRSRC);
	close(DIRDEST);
    }
    return "$destpath/$dosname";
}


##############################################################################
#	MakePath
##############################################################################
#
# SYNOPSIS:	Check if path exists.  If not, create it.
# PASS:		<path> = an absolute path to create, if necessary
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub MakePath {

    local($directory, $dosdirectory);
    local($path)="/";
    local($dosPath)="/";
    local($passedpath)=@_;

    if ( &IsUnix() ) {		# Unix system
	#$passedpath =~ s|^/||;	# Cut off the starting slash.

        $passedpath = substr($passedpath, length($var{desttree}));
        $path = $dosPath = $var{desttree};
    } else {			# Win32 system
	$path = $dosPath = substr($passedpath, 0, 3); # Drive & leading slash
	$passedpath = substr($passedpath, 3); # Rest of the path
    }

    print "MakePath $passedpath $var{desttree}\n";

    foreach $directory (split('/', "$passedpath")) {

	# We presume that if the DOS name of the directory matches, it is
	# a match.

	$dosdirectory = &GEOSToDOSFileName($directory);
	if ( ! -d "$path$dosdirectory" ) {
	    &MakeDir("$path$directory");
	}
	$path .= "$directory/";
	$dosPath .= "$dosdirectory/";
    }
    return "$dosPath";
}


##############################################################################
#	SendFile
##############################################################################
#
# SYNOPSIS:	Send specified file to destination.
# PASS:		<file> = path of file within an Installed tree.
#               <destination> = where to put its
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub SendFile{

    my ($file,$dest, $doNotGtouch)=@_;
    my ($filefullpath)=&FindInstalledFile("$file");

    if ("$filefullpath") {
	&CopyFile($filefullpath, $dest, $doNotGtouch);
    } else {
	&Error("Could not find file $file in any of the source trees.");
    }
}


##############################################################################
#	FindInstalledFile
##############################################################################
#
# SYNOPSIS:	Look for file in the source directories.
# PASS:		<file> = path of file within an Installed tree.
# CALLED BY:	various
# RETURN:	full path of file, if found (otherwise, null)
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub FindInstalledFile {

    local($file, $sourcedir, $filewithpath);

    $file="@_";
    @sourcedirs=split(' ', "$var{sourcedirs}");
    foreach $sourcedir (@sourcedirs) {

	$filewithpath="$sourcedir/$file";
	&DebugPrint("findinstalledfile", "Looking for $filewithpath...");
	if (-f "$filewithpath") {
	    return "$filewithpath";
	}
    }
    return "";
}


##############################################################################
#	FindInstalledDir
##############################################################################
#
# SYNOPSIS:	Look for dir in the source directories, copied from
#               FindInstalledPath.
# PASS:		<dir> = path of dir within an Installed tree.
# CALLED BY:	various
# RETURN:	full path of dir, if found (otherwise, null)
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       mjoy 	   	8/07/97         Initial Revision
#
##############################################################################
sub FindInstalledDir {

    local($file, $sourcedir, $filewithpath);

    $file="@_";
    @sourcedirs=split(' ', "$var{sourcedirs}");
    foreach $sourcedir (@sourcedirs) {

	$filewithpath="$sourcedir/$file";
	&DebugPrint("findinstalleddir", "Looking for $filewithpath...");
	if (-d "$filewithpath") {
	    return "$filewithpath";
	}
    }
    return "";
}

##############################################################################
#	CopyFile
##############################################################################
#
# SYNOPSIS:	Copy the file to destination.
# PASS:		<file> = file to copy
#               <destination> = destination path
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub CopyFile {

    my ($from,$to, $doNotGtouch)=@_;

    # Convert filename to 8.3

    #
    # if $to doesn't end with a slash, we treat that it ends with a filename
    # and we will use that.
    #
    my($filename);

    if ($to =~ /\\$/ || $to =~ /\/$/) {
	$filename = "$from";
	$filename =~ s|.*/([^/]+)$|$1|;
    } else {
	$filename = "$to";
	$filename =~ s|.*/([^/]+)$|$1|;
	$to =~ s|$filename$||;
    }

    #
    # ugly hack to deal with a few specific files that need to begine with @
    # we need to do this because perforce will not handle filenames with @
    #
    if ((uc $filename) eq (uc "dirname.000")) {
	$filename = "\@$filename";
    }
    if ((uc $filename) eq (uc "nd_dire.000")) {
	$filename = "\@$filename";
    }

    $filename = &Dosify("$filename");

    # Report to user what's goin' on.

    if ( "$var{reportabbreviatedpaths}" ) {
	$abbrevfrom=&AbbrevPath("$from");
	$abbrevto=&AbbrevPath("$to");
	&printbold("Copying $abbrevfrom\n");
	print "     to $abbrevto\n\n";
    } else {
	&printbold("Copying $from\n");
	print("     to $to$filename\n\n");
    }

    # Check if file of the same name exists in the destination path. If we
    # find one, then we change the last letter of the file name to "0" before
    # the copy operation.
    if ( -e "$to$filename" && !"var{syntaxtest}" ) {
        local($oldfilename)=$filename;

	# If the file name is 8-character or longer, replace the
	# last character with "0". Otherwise, append "0" to the
	# end of the file name.
	if ( $filename =~ /^([^\.]+)\.([^\.]+)$/ ) { # file name w/ extension
	    if ( length("$1") >= 8 ) {
		substr($filename, 7, 1) = "0";
	    } else {
		$filename="${1}0.$2";
	    }
	} else {		# file name w/o extension
	    if ( length("$filename") >= 8 ) {
		substr($filename, 7, 1) = "0";
	    } else {
		$filename="${filename}0";
	    }
	}

	&Warning("File $to$oldfilename already exists.  Changing name to $filename.");
	if ( -e "$to$filename" ) {
	    &Error("File $to$filename already exists.  Overwriting.");
	}
    }

    # Do the copy.
    &Copy($from, "$to$filename");

    # Timestamp the geode if "timestampGeodeInOrder" is set.
    #
    if (! $doNotGtouch) {
	&TimestampGeodeInOrder("$to$filename");
    }

    # Check if this was a zero-length file.

   if ( -z "$to$filename" && $filename ne "swatwait" ) {
	&Warning("File $to$filename is zero length.");
    }
}


##############################################################################
#	Dosify
##############################################################################
#
# SYNOPSIS:	Convert a filename that may have more than eight characters
#               before the period because of added ec characters to 8.3 format.
# PASS:		<filename> = filename to convert
# CALLED BY:	various
# RETURN:	filename in 8.3 format.
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub Dosify {

    local($name, $newname, $namepreflen, $ending);

    $name = "@_";
    &DebugPrint("dosify", "Dosifying filename $name");
    $name =~ y/A-Z/a-z/;
    &DebugPrint("dosify", "Lowercased: $name");
    if ($name =~ /([^\.]+).*\.([^\.]+)$/) {

	# There is at least one period in the filename...

	$namepreflen = length($1);
	$newname = substr($1,0,8).".".substr($2,0,3);
	&DebugPrint("dosify", "Cropped: $newname");

	$ending = substr($1,$namepreflen-2,$namepreflen);
	if ($namepreflen > 9 && "$ending" eq "ec") {

	    # If "ec" was chopped off, slap an 'e' right before the dot.

	    substr($newname, 7, 1) = "e";
	    &DebugPrint("dosify", "Correcting for EC: $newname");
	}
    } else {

	# If there are no '.'s in the name, we'll just take the first
	# eleven letters and make that our 8.3

	if ( length($name) > 8 ) {
	    $namepreflen = 8;
	    $newname = substr($name,0,8).".".substr($name,8,3);
	    &DebugPrint("dosify", "Cropped: $newname");
	} else {
	    $namepreflen = length($name);
	    $newname = $name;
	    &DebugPrint("dosify", "Leaving it as-is: $newname");
	}
    }
    &DebugPrint("dosify", "Dosified name: $newname");
    return $newname;
}


##############################################################################
#	GEOSToDosFileName
##############################################################################
#
# SYNOPSIS:	Convert a potentially long GEOS file name to an approximation
#               of its DOS file name.
# PASS:		<filename> = filename to convert
# CALLED BY:	various
# RETURN:	filename in 8.3 format.
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub GEOSToDOSFileName{

    local ($longname, $dosname, $beforedot, $afterdot, $afterdot2);

    $longname="@_";
    ($beforedot, $afterdot, $afterdot2) = split('\.', "$longname");
    if ("$beforedot" && !"$afterdot2" &&
	length($beforedot) <= 8 && length($afterdot) <=3 ) {

	$dosname = $longname;

    } else {

	$dosname = substr($longname, 0, 8);
	$dosname =~ s/\./_/g;   # Change periods to underscores.
    }
    $dosname =~ s/\s/_/g;   # Change spaces to underscores.
    $dosname =~ y/A-Z/a-z/; # Lowercase.
    if ( "$dosname" ne "$longname" ) {
	$dosname =~ s/\./_/g;   # Might still be periods from first case.
	if ( length($longname) > 8 ) {
	    $dosname .= ".000";
	}
    }
    return "$dosname";
}


##############################################################################
#	GEOSToDOSPathName
##############################################################################
#
# SYNOPSIS:	Convert potentially long GEOS directory names in a path to
#               their DOS directory names.
# PASS:		<path> = path to convert
# CALLED BY:	various
# RETURN:	Path with filenames in 8.3 format.
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub GEOSToDOSPathName{

    local($directory);
    local($path)="";
    local($fullpath) = @_;

    if ( &IsUnix() ) {		# Unix system

        $fullpath = substr($fullpath, length($var{desttree}));
        $path = $var{desttree};
        $fullpath =~ s|^/||;    # Cut off starting slash.

    } else {			# Win32 system
	$path = substr($fullpath, 0, 2); # Drive letter and colon
	$fullpath = substr($fullpath, 3); # Path w/o leading slash
    }

    # GEOS to DOS each directory name in the path.

    foreach $directory (split('/', "$fullpath")) {
	$path .= "/";
	$path .= &GEOSToDOSFileName("$directory");
    }
    return "$path";
}


##############################################################################
#	BuildDestTreePath
##############################################################################
#
# SYNOPSIS:	If destination path has not been explicitly defined, set it
#               based on the build variables.  Create the path if it doesn't
#               exist.
# PASS:		nothing
# CALLED BY:	various
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub BuildDestTreePath {

    local($directory, $path, $destPath);
    if ( "$var{test}" ) {
	$var{defaultdesttreetop}=$var{defaulttestdesttreetop};
    }
    if ( !"$var{desttree}" || "$var{test}" ) {
	$var{desttree} = "$var{defaultdesttreetop}/$var{productshortname}";
	if ( "$var{language}" ne "english" ) {
	    $var{desttree} .= "/$var{language}";
	}
	if ( $var{"prototype"} ) {
	    if ( length($var{hardware}) > 3 ) {
		&Warning("Build variable \"hardware\" is longer than three characters.");
	    }
	    $var{desttree} .= "/proto$var{hardware}";
	} else {
	    if ( "$var{sdk}" ) {
		$var{desttree} .= "/sdkdemo";
	    } else {
		$var{desttree} .= "/demo";
	    }
	    if ( "$var{server}" ) {
		$var{desttree} .= "/serv";
	    } else {
		$var{desttree} .= "/disk";
	    }
	    if ( "$var{xip}" && "$var{gfs}" ) {
		$var{desttree} .= "xg";
	    } elsif ( $var{xip} ) {
		$var{desttree} .= "xip";
	    } elsif ( $var{gfs} ) {
		$var{desttree} .= "gfs";
	    }
	}
	if ( "$var{ec}" ) {
	    $var{desttree} .= ".ec";
	}
    }

    $var{desttree} =~ y/A-Z/a-z/; # The destination tree must be all lowercase.
    $path="/";
    $destPath = $var{desttree};

    if ( &IsUnix() ){		# Unix system
	$destPath =~ s|^/||;	# Remove the leading slash
    } else {			# Win32 system
	$path = substr($destPath, 0, 3); # Drive and the leading slash
	$destPath = substr($destPath, 3); # Rest of the path
    }

    foreach $directory (split('/', $destPath)) {

	if ( ! -e "$path$directory" ) {
	    &MkDir("$path$directory");
	} elsif ( ! -d "$path$directory" ) {
	    &Error("$path$directory is not a directory.");
	    exit;
	}
	$path .= "$directory/";
    }
}


##############################################################################
#	AbbrevPath
##############################################################################
#
# SYNOPSIS:	Abbreviate the passed path.
# PASS:		<path>
# CALLED BY:	various
# RETURN:	abbreviated path
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub AbbrevPath {

    local($path)="@_";
    $path =~ s|staff/pcgeos|<s/p>|;
    $path =~ s/Installed/<i>/;
    $path =~ s|n/nevada/demos|<d>|;
    return $path;
}


##############################################################################
#	ReplaceProductDir
##############################################################################
#
# SYNOPSIS:	Remove a product sub-directory from the passed path (if it
#               exists, then insert the passed product dir.
# PASS:		<path>, <product directory>
# CALLED BY:	various
# RETURN:	new path
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/24/96   	Initial Revision
#
##############################################################################
sub ReplaceProductDir {

    local($pathwithoutfile, $pathwithoutfileorig, $file);
    local($path,$productdir)=@_;

    # Separate path.

    $pathwithoutfile="$path";
    $pathwithoutfile =~ s|/[^/]*$||;
    $pathwithoutfileorig=$pathwithoutfile;

    $file="$path";
    $file =~ s|.*/([^/]+)|$1|;

    # Find the Makefile so we know we are not in a product sub-directory.

    $makefile=&FindInstalledFile("$pathwithoutfile/Makefile");

    if ( ! "$makefile" ) {

	# Back up another directory.

	$pathwithoutfile =~ s|/[^/]*$||;

	# Try again.

	if ( ! &FindInstalledFile("$pathwithoutfile/Makefile") ) {

	    # No Makefile found. If the original directory +
	    # productdir has the file, that means the original
	    # directory does not contain product sub-directory because
	    # there cannot be sub-directories in a product directory.

	    if ( &FindInstalledFile("$pathwithoutfileorig/$productdir/$file") ){
		$pathwithoutfile=$pathwithoutfileorig;
	    }
	}
    }

    $pathwithoutfile .= "/$productdir/$file";

    return "$pathwithoutfile";

}



##############################################################################
#	Unix2Dos
##############################################################################
#
# SYNOPSIS:	Convert a text file to DOS format.
# PASS:		Unix2Dos(filename)
#               filename - name of the file
# CALLED BY:
# RETURN:	1 on success
#               0 on failure
# SIDE EFFECTS:
#               The file is changed to DOS format.
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/22/96   	Initial Revision
#
##############################################################################
sub Unix2Dos {
    my $inFile = $_[0];
    my $tmpFile = "/tmp/tmp.$$"; # Unix temp. file

    if ( &IsWin32() ){		# Win32 temp. file
	if ( defined($ENV{"TEMP"}) ){
	    $tmpFile = "$ENV{TEMP}/tmp.$$"; # Win32 temp. file
	} else {
	    $tmpFile = "./tmp.$$";
	}
    }

    if ( &Debug("syscalls") ){
	print "SYS: Unix2Dos($inFile)\n\n";
    }

    if ( ! $var{"syntaxtest"} ){

	# Open the input and output files.
	#
	open(UNIXFILE, "<$inFile") || goto errorExit;
	if ( !open(DOSFILE, ">$tmpFile") ){
	    close(UNIXFILE);
	    goto errorExit;
	}

	# Convert the lines to DOS format
	#
	if ( &IsWin32() ){
	    binmode(UNIXFILE);
	    binmode(DOSFILE);
	}
	while ( <UNIXFILE> ){

	    # Don't dosify a file which is already in DOS format.
	    #
	    if ( ! /\r\n/ ){
		s/\n/\r\n/;
	    }
	    if ( !(print DOSFILE) ){
		close(UNIXFILE);
		close(DOSFILE);
		unlink($tmpFile); # Remove the temp. file if "print" failed.
		goto errorExit;
	    }
	}

	close(UNIXFILE);
	close(DOSFILE);

	# Copy the dosified file and remove the temp. file.
	#
	if ( ! &Copy($tmpFile, $inFile) ){
	    unlink($tmpFile);	# Remove the temp. file here if "copy" failed.
	    goto errorExit;
	}
	unlink($tmpFile);
    }

    return 1;

errorExit:
    &Error("Cannot convert $inFile to DOS format.");
    return 0;
}


##############################################################################
#	MkDir
##############################################################################
#
# SYNOPSIS:	Create a directry just like function "mkdir".
# PASS:		MkDir(directory)
#               directory - name of the directory
# CALLED BY:	EXTERNAL
# RETURN:	1 on success
#               0 on failure
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/25/96   	Initial Revision
#
##############################################################################
sub MkDir {
    my ($ok) = 1;			# assume success

    if ( &Debug("syscalls") ){
	print "SYS: mkdir($_[0], 0777)\n\n";
    }

    if ( ! $var{"syntaxtest"} ){
	$ok = mkdir($_[0], 0777);
    }

    if ( ! $ok ){
	&Error("Cannot create directory  $_[0]:$!.\n");
    }
    return $ok;
}

##############################################################################
#	Copy
##############################################################################
#
# SYNOPSIS:	Copy the source file to the destination file
# PASS:		Copy(src, dest)
#               src - source file
#               dest - destination file
# CALLED BY:	EXTERNAL
# RETURN:	1 on success
#               0 on failure
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/25/96   	Initial Revision
#
##############################################################################
sub Copy {

    my ($ok) = 1;			# assume success

    if ( &Debug("syscalls") ){
	print "SYS: copy($_[0], $_[1])\n\n";
    }

    if ( ! $var{"syntaxtest"} ){
	if ($isSync) {

	    #
	    # In synchronization process, we don't want to fail
	    for (; (! ($ok = copy(@_))) ;
		 sleep 1) {print ".";}

	} else {
	    $ok = copy(@_);
	}
    }

    if ( ! $ok ){
	&Error("Cannot copy $_[0] to $_[1]: $!.\n");
    }
    return $ok;
}

##############################################################################
#	RmTree
##############################################################################
#
# SYNOPSIS:	Remove the directory tree.
# PASS:		RmTree(directory)
#               directory - name of the directory tree
# CALLED BY:	EXTERNAL
# RETURN:	the number of files successfully deleted
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	11/25/96   	Initial Revision
#
##############################################################################
sub RmTree {
    my ($ok);

    if ( &IsUnix() ){ # Unix system
	&System("\\rm -rf $_[0]");
    } else {          # NT system

	if ( &Debug("syscalls") ){
	    print "SYS: rmtree($_[0], 0, 0)\n\n";
	}

	if ( ! $var{"syntaxtest"} ){
	    $ok = rmtree($_[0], 0, 1);
	}
    }
    return $ok;
}

#
# The following routines are resedit specific routines.
#

##############################################################################
#	GetVMFile
##############################################################################
#
# SYNOPSIS:	Search the existence of the .vm file give the sourceFile
# PASS:		sourceFile name
# CALLED BY:	SendFileTree
# RETURN:	.vm filename corresponding to the sourceFile
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################

sub GetVMFile {
    my($sourceFile) = @_;
    my($vmfile);

    if ($sourceFile =~ /\.geo$/) {
	if ($var{"ec"}) {
	    if ($sourceFile =~ /ec\.geo/) {
		# watch out for some test apps.
		($vmFile = $sourceFile) =~ s/ec\.geo/\.vm/;
	    } else {
		($vmFile = $sourceFile) =~ s/\.geo/\.vm/;
	    }
	} else  {
	    ($vmFile = $sourceFile) =~ s/\.geo/\.vm/;
	}
	if (&FindInstalledFile($vmFile)) {
	    return $vmFile;
	}
    }
    return "";
}

##############################################################################
#	SetReseditIni
##############################################################################
#
# SYNOPSIS:	Set the .ini file for the nt demo running Resedit.
# PASS:		nothing
# CALLED BY:	OpenAndSendFileTreeFile
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub SetReseditIni {
    my ($no_of_lines);

    $no_of_lines = &ReadIniFile;
    &ScanLines($no_of_lines);
}
##############################################################################
#	ReadIniFile
##############################################################################
#
# SYNOPSIS:	Read in the geos.ini for the nt demo running resedit
# PASS:		nothing
# CALLED BY:	SetReseditIni
# RETURN:	no. of lines in the geos.ini
# SIDE EFFECTS:	data of the file is read into $lines array
#
# STRATEGY:

#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub ReadIniFile {

    my($count) = 0;
    my($file) = "$var{reseditpath}\\geos.ini";

    open(INI, "<$file") || die "can't open $file\n";

    while(<INI>) {
	$lines[$count++] = $_;
    }

    close(INI);
    return $count;
}

##############################################################################
#	ScanLines
##############################################################################
#
# SYNOPSIS:	Scan the $lines array and modify it to update its information
#               as provided by gbuild and write the data back to geos.ini
#
# PASS:		no. of lines in the geos.ini
# CALLED BY:	SetReseditIni
# RETURN:	nothing
# SIDE EFFECTS:	Updated information in $lines are written back to geos.ini
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub ScanLines {

    my($count) = @_;
    my($i, $catFound);
    my($file) = "$var{reseditpath}\\geos.ini";
    my($dir);
    my($actionCode);

    for ($i=0; $i < $count; $i++) {

	$line = $lines[$i];

	if ($line =~ /^\s*$/) {
	    # We are skipping a blank line
	} elsif ($line =~ /^\[resedit\]/) {
	    $catFound = 1;
	} elsif ($catFound && ($line =~ /^([^=]+)\s*=/)) {

	    $key = $1;
	    $key =~ s/\s*$//;
	    #
	    # we are dealing with keys and data for resedit

	  SWITCH: {
	      if ($key eq "sourceDir") {
		  $dir = $var{srctrans};
		  $dir =~ s|/|\\|g;
		  $lines[$i] = "sourceDir\= $dir\n";
		  last SWITCH;
	      }
	      if ($key eq "destinationDir") {
		  $dir = $var{desttrans};
		  $dir =~ s|/|\\|g;
		  $lines[$i] = "destinationDir\= $dir\n";
		  last SWITCH;
	      }
	      if ($key eq "transDir") {
		  $dir = $var{transdir};
		  $dir =~ s|/|\\|g;
		  $lines[$i] = "transDir\= $dir\n";
		  last SWITCH;
	      }
	      if ($key eq "communicateDir") {
		  $dir = $var{commdir};
		  $dir =~ s|/|\\|g;
		  $lines[$i] = "communicateDir\= $dir\n";
		  last SWITCH;
	      }
	      if ($key eq "action") {
		  $actionCode = &MapActionCode();
		  $lines[$i] = "action\= $actionCode\n";
		  last SWITCH;
	      }
	  }
	} elsif (($line =~ /^\[/) && $catFound) {
	    #
	    # We have reached the next category after resedit
	    last;
	}

    }
    #
    #  At this point, the @lines array should have the right data, write that back to the file

    open(INI, ">$file");

    for ($i=0; $i < $count; $i++) {
	print INI $lines[$i];
    }
    close(INI);
}

##############################################################################
#	MapActionCode
##############################################################################
#
# SYNOPSIS:	Map the action text used in gbuild with the code used
#               by resedit.
# PASS:		nothing
# CALLED BY:	ScanLines
# RETURN:	Action code
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub MapActionCode {
    #
    # We need to map the action to corresponding code
    # for resedit to process. (kinda hack)

    if ($var{action} =~ /create_trans_files/i) {
	return 0;
    } elsif ($var{action} =~ /create_executables/i) {
	return 1;
    } elsif ($var{action} =~ /create_patch/i) {
	return 2;
    } elsif ($var{action} =~ /create_null_and_patch/i) {
	return 3;
    } else {
	&printbold("Undefined action for resedit, cannot proceed\n");
	exit;
    }
}

##############################################################################
#	TruncateToZero
##############################################################################
#
# SYNOPSIS:	Utililty to truncate a file to zero length (built-in truncate
#               doesn't work, gotta write my own hack)
# PASS:		filename
# CALLED BY:	GLOBAL
# RETURN:	nothing
# SIDE EFFECTS:	File truncated to zero length
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub TruncateToZero {

    my($file) = @_;

    #
    # File should have full path
    if (! $file) {
	unlink $file;
    }
    open(TMP, ">$file");
    close(TMP);
}


##############################################################################
#	SendGeodeStubIfNecessary
##############################################################################
#
# SYNOPSIS:	Send geode stub if necessary (as named)
# PASS:		mediaType, sourceFile, dosDestPath, mediaOptions
# CALLED BY:	SendFileTree
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	4/13/98   	Initial Revision
#
##############################################################################
sub SendGeodeStubIfNecessary {

    my($mediaType, $sourceFile, $dosDestPath, @mediaOptions) = @_;
    my($stubOption, $stubDest, @stubOptions);

    if ( ! $var{"sendtemplateonly"} &&
	("$mediaType" eq "XIP") &&
	grep(/^MAKESTUB/, @mediaOptions) ) {

	@stubOptions=grep(/^MAKESTUB/, @mediaOptions);
	($stubOption)=@stubOptions;
	if ( "$stubOption" ) {

	    # We need to make a stub.
	    # If we have MAKESTUB=<mediaType>, use that media type.

	    ($stubOption, $stubDest) = split(/=/, $stubOption);
	    if ( "$stubDest" ) {

		# Put specified media type as first priority.
		@line=($stubDest, @line);
	    }

	    # Remove XIP media from the running.

	    @line=grep(!/^XIP/ && !/^MAKESTUB/, @line);

	    # Choose the media type and destination path for the stub.

	    ($mediaType,@mediaOptions)=&ChooseMedia(@line);
	    $destPath=&BuildDestPath($mediaType, @mediaOptions);
	    $dosDestPath=&MakePath($destPath);

	    # Send the geode and stubify it.

	    &SendFile($sourceFile, $dosDestPath);
	    (my $geodeName=$sourceFile)=~s|.*/([^/]*)$|$1|;
	    $geodeName = &Dosify($geodeName);
	    &CreateFileStub("$dosDestPath$geodeName");
	}
    }
}

##############################################################################
#	ClearSrcSyncFiles
##############################################################################
#
# SYNOPSIS:	Delete files in srctrans directory.
# PASS:		List of files to delete.
# CALLED BY:	SendFileTree
# RETURN:	nothing
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub  ClearSrcSyncFiles
{
    my($filename) = @_;

    # We know exactly which files to delete, make sure they
    # are really deleted, .vm first:

    while (! (unlink "$var{srctrans}//$filename\.vm")) {}
    if ($var{action} !~ /create_trans_files/i) {
	while (! (unlink "$var{srctrans}//$filename\.atf")) {}
    }
}

##############################################################################
#	ClearDestSyncFiles
##############################################################################
#
# SYNOPSIS:     Delete files from desttrans directory.
# PASS:	        No. of files to delete from the directory.
# CALLED BY:    SendFileTree
# RETURN:       nothing
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub ClearDestSyncFiles {

    my ($files_to_delete) = @_;
    my(@files_found);
    my($i);

    if (! $files_to_delete) { return }

    @files_found = glob("$var{desttrans}/*.*");

    #
    # scalar(@files) could be more than $files_to_delete, because the Resedit
    # must not have deleted the .geo. But anyhow leave that for Resedit to do
    # for synchronization reason.

    for ($i=0; $i < $files_to_delete; $i += unlink @files_found) {}
}


##############################################################################
#	Member
##############################################################################
#
# SYNOPSIS:	Utility to check whether a particular item is a member of
#               a list.
# PASS:		item
# CALLED BY:	GLOBAL
# RETURN:	1 if exists, 0 if not
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/10/98   	Initial Revision
#
##############################################################################
sub Member {

    #
    # simple memeber function to check whether
    # an elemen is a member of a list

    my($item, @list) = @_;

    foreach $curItem (@list) {
	return 1 if ($item =~ /^$curItem$/i);  # exact match
    }
    return 0;
}

##############################################################################
#	PrintReseditErrorsAndWarnings
##############################################################################
#
# SYNOPSIS:	Print out whether Resedit creates any error/warning during
#               the build process
# PASS:		none
# CALLED BY:	Main in build.pl
# RETURN:	nothing
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       kliu     	1/14/98   	Initial Revision
#
##############################################################################
sub PrintReseditErrorsAndWarnings {

    if (-s "$var{logdir}/error\.log") {
	print "\nErrors were produced while using ResEdit.\n";
	print "Check $var{logdir}/error\.log for details.\n";
    }

    if (-s "$var{logdir}/warning\.log") {
	print "\nWarnings were produced while using ResEdit.\n";
	print "Check $var{logdir}/warning\.log for details.\n";
    }
}
