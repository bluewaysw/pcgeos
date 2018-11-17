#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996.  All rights reserved.
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	GEOS Tool
# MODULE:	Build Tool
# FILE: 	imageutil.pl
# AUTHOR: 	Chris Lee, Sep  5, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	clee	9/ 5/96   	Initial Revision
#
# DESCRIPTION:
#
# This file contains image-making routines.
#
#
#	$Id: imageutil.pl,v 1.17 98/04/06 19:20:27 simon Exp $
#
###############################################################################

1;

##############################################################################
#	CreateAndMergeImages
##############################################################################
#
# SYNOPSIS:	Create images and merge them together
# PASS:		CreateAndMergeImages(imgInfo)
#               imgInfo = associative array containing information for
#                         making images.
# CALLED BY:	(EXTERNAL)
# RETURN:	non-zero on success
#               0 on failure
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/ 6/96   	Initial Revision
#
##############################################################################
sub CreateAndMergeImages {
    
    # Copy the image making information.
    #
    %imgInfo = @_;		# global variable used by the routines here.
    local($doMerge) = 1;

    # Create the XIP image.
    #
    if ( $imgInfo{"xip"} && (! &CreateXIP()) ){
	$doMerge = 0;
    }

    # Create the GFS image.
    #
    if ( $imgInfo{"gfs"} && (! &CreateGFS()) ){
	$doMerge = 0;
    }

    # Create the language patch GFS image.
    #
    if ( $imgInfo{"langgfs"} && (! &CreateLangGFS()) ){
	$doMerge = 0;
    }

    # Create the Rom-disk image.
    #
    if ( $imgInfo{"romdisk"} && (! &CreateROMDISK()) ){
	    $doMerge = 0;
    }

    # Merge all the images.
    #
    if (($imgInfo{"xip"} || $imgInfo{"gfs"} || $imgInfo{"romdisk"}) && 
	$doMerge){
	if ( $imgInfo{"mergeimages"} ){
	    local($mergeImageResult) = &MergeImages();

	    # Patch the merged image, if necessary
	    #
	    if ( $mergeImageResult && $imgInfo{"patchmergedimage"} ){
		$mergeImageResult = &PatchMergedImage();
	    }
	    return $mergeImageResult;
	}
	return 1;
    }

    return 0;
}


##############################################################################
#	CreateXIP
##############################################################################
#
# SYNOPSIS:	Create the XIP image.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	1 = success (xip image created)
#               0 = failed (NO xip image created)
# SIDE EFFECTS:	
#               xip image is created if the process is successfull.
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/ 5/96   	Initial Revision
#
##############################################################################
sub CreateXIP {
    local($geodes, $ddgroup, $args);
    local(@geodeList);

    if ( ! $var{"syntaxtest"} ) {

	# Construct the list of geodes that don't have discardable dgroup.
	#
	if ( ! -d "$imgInfo{'desttree'}/xip" ) {
	    &Error("$imgInfo{'desttree'}/xip not found. XIP image not made.\n");
	    return 0;
	}
	$geodes = &ListFiles("$imgInfo{'desttree'}/xip");
    
	# Add geodes with the discardable dgroup to the geode list.
	#
	$ddgroup = &ListFiles("$imgInfo{'desttree'}/xip/ddgroup");
	if ( $ddgroup ) {
        
	    $ddgroup =~ s/ / -D/g;	# add -D in front of each geode
	    $geodes .= " -D" . $ddgroup;
	}

	if ( &IsWin32() ){		# Dosify the paths for Win32.
	    $geodes =~ tr|/|\\|;
	}

	#
	# Extract all the geodes from the list.
	#
	@geodeList = grep(/\.geo$/, split(" ", $geodes));
	#print "\nList of XIP geodes:\n\n" . join(" ", @geodeList) . "\n";
    }

    # Construct the fullxip arguments
    #
    $args = &ConstructXIPArgs();
    if ( &IsWin32() ){		# Dosify the path strings for Win32, if any.
	$args =~ tr|/|\\|;
    }
    &DebugPrint(images, "\nXIP arguments:\n\t$args\n");

    if ( ! $args ){
	&Error("XIP: Invalid argument(s); XIP image not made.\n");
	return 0;
    }

    # Now, create the xip image.
    #
    local($xipTool) = "fullxip";	# assume using "fullxip".
    if ( $imgInfo{"xipprofile"} ){
	$xipTool = "xipoffset";	# using "xipoffset" instead.
    }

    print "Creating XIP image...\n";
    my $result;
    $result = &System("$xipTool $args " . join(" ", @geodeList));

    if ( $result == 0 ) {
	print "XIP image created.\n";
	return 1;
    }

    &Error("Cannot create XIP image.\n");
    return 0;

}

##############################################################################
#	CreateGFS
##############################################################################
#
# SYNOPSIS:	Create GFS image.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	1 = success (gfs image created)
#               0 = failed  (NO gfs image created)
# SIDE EFFECTS:	
#               GFS image is created if the process is successful.
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/ 5/96   	Initial Revision
#
##############################################################################
sub CreateGFS {
    local($args);

    # Make sure the directory is there.
    #
    if ( !$var{"syntaxtest"} &&  (! -d "$imgInfo{'desttree'}/gfs") ) {
	&Error("$imgInfo{'desttree'}/gfs not found. GFS image not made.\n");
	return 0;
    }

    # Construct the gfs argument.
    #
    $args = &ConstructGFSArgs();
    if ( &IsWin32() ){		# Dosify the path strings for Win32, if any.
	$args =~ tr|/|\\|;
    }
    &DebugPrint(images, "\nGFS arguments:\n\t$args\n");

    if ( ! $args ){
        &Error("GFS: Invlid argument(s); image not made.\n");
	return 0;
    }

    # Call gfs to do its job.
    #
    print "Creating GFS image...\n";
    if ( ! &System("gfs $args") ){
	print "GFS image created.\n";
	
	# Compress the GFS image.
	#
	if ( $imgInfo{'gfscompress'} ){
	    $args = &ConstructCGFSArgs();
	    if ( &IsWin32() ){	# Dosify the path strings for Win32, if any.
		$args =~ tr|/|\\|;
	    }
	    &DebugPrint(images, "\nCompressed GFS arguments:\n\t$args\n");

	    print "Compressing the GFS image...\n";
	    &System("$imgInfo{'gfscompress'} $args");
	}
	    
	return 1;
    }
    
    &Error("Could not create GFS image.\n");
    return 0;
}

##############################################################################
#	CreateLangGFS
##############################################################################
#
# SYNOPSIS:	Create Language Patch GFS image.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	1 = success (gfs image created)
#               0 = failed  (NO gfs image created)
# SIDE EFFECTS:	
#               GFS image is created if the process is successful.
#
# STRATEGY:
#       We do not share the code with CreateGFS because lang GFS
#       has different arguments from regular GFS.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon   12/23/97        Borrowed from CreateGFS
#
##############################################################################
sub CreateLangGFS {
    local($args);

    # Make sure the directory is there.
    #
    if ( !$var{"syntaxtest"} &&  (! -d "$imgInfo{'desttree'}/langgfs") ) {
	&Error("$imgInfo{'desttree'}/langgfs not found. Language Patch GFS image not made.\n");
	return 0;
    }

    # Construct the gfs argument.
    #
    $args = &ConstructLangGFSArgs();
    if ( &IsWin32() ){		# Dosify the path strings for Win32, if any.
	$args =~ tr|/|\\|;
    }
    &DebugPrint(images, "\nLanguage Patch GFS arguments:\n\t$args\n");

    if ( ! $args ){
        &Error("Language Patch GFS: Invlid argument(s); image not made.\n");
	return 0;
    }

    # Call gfs to do its job.
    #
    print "Creating Language Patch GFS image...\n";
    if ( ! &System("gfs $args") ){
	print "Language Patch GFS image created.\n";
	
	# Compress the Language Patch GFS image.
	#
	if ( $imgInfo{'gfscompress'} ){
	    $args = &ConstructLangCGFSArgs();
	    if ( &IsWin32() ){	# Dosify the path strings for Win32, if any.
		$args =~ tr|/|\\|;
	    }
	    &DebugPrint(images, "\nCompressed Language Patch GFS arguments:\n\t$args\n");

	    print "Compressing the Language Patch GFS image...\n";
	    &System("$imgInfo{'gfscompress'} $args");
	}
	    
	return 1;
    }
    
    &Error("Could not create Language Patch GFS image.\n");
    return 0;
}

##############################################################################
#	CreateROMDISK
##############################################################################
#
# SYNOPSIS:	Create ROMDISK image.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	1 = success (romdisk image created)
#               0 = failed  (NO romdisk image created)
# SIDE EFFECTS:	
#               ROMDISK image is created if the process is successful.
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	10/ 3/96   	Initial Revision
#
##############################################################################
sub CreateROMDISK {
    local($args);

    # Make sure the directory is there.
    #
    if ( !$var{"syntaxtest"} && (! -d "$imgInfo{'desttree'}/romdisk") ) {
	&Error("$imgInfo{'desttree'}/romdisk not found. ROMDISK image not made.\n");
	return 0;
    }

    # Construct the romdisk argument.
    #
    $args = &ConstructROMDISKArgs();
    if ( &IsWin32() ){		# Dosify the path strings for Win32, if any.
	$args =~ tr|/|\\|;
    }
    &DebugPrint(images, "\nROMDISK arguments:\n\t$args\n");

    # Call gfs to do its job.
    #
    print "Creating ROMDISK image...\n";
    if ( ! &System("romdisk $args") ){
	print "ROMDISK image created.\n";
	return 1;
    }
    
    &Error("Could not create ROMDISK image.\n");
    return 0;
}


##############################################################################
#	MergeImages
##############################################################################
#
# SYNOPSIS:	Merge all the images into one.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	1 = success: image created
#               0 = failed : NO image created
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/ 5/96   	Initial Revision
#
##############################################################################
sub MergeImages {
    local($args);

    $args = &ConstructMergeArgs();
    if ( &IsWin32() ){		# Dosify the path strings for Win32, if any.
	$args =~ tr|/|\\|;
    }
    &DebugPrint(images, "\nMerge arguments:\n\t$args\n");

    if ( ! $args ){
	&Error("Invalid argument(s); images not merged.\n");
	return 0;
    }

    print "Merging images...\n";
    if ( ! &System("merge $args") ){
	print "Images merged.\n";
	return 1;
    }
    
     &Error("Could not merge the images.\n");
    return 0;
}

##############################################################################
#	PatchMergedImage
##############################################################################
#
# SYNOPSIS:	Patch the merged image
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	1 = success: image patched successfully
#               0 = failed : error patching image
# SIDE EFFECTS:	none
#
# STRATEGY:
#     At this point, we do not support any argument to the patching
#     program. The patching program must be in form of:
#     
#     <patch-program> <merged-final-image> <output-image>
#
#     where 
#       <patch-program>      = patchMergedImage
#       <merged-final-image> = semi.img
#       <output-image>       = finalImageName
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	11/22/97   	Initial Revision
#
##############################################################################
sub PatchMergedImage {
    local($patchProgram) = $imgInfo{"patchmergedimage"};
    local($args);

    $args = &ConstructPatchMergedImageArgs();
    if ( &IsWin32() ){		# Dosify the path strings for Win32, if any.
	$args =~ tr|/|\\|;
    }
    &DebugPrint(images, "\nPatching merged image arguments:\n\t$args\n");

    if ( ! $args ){
	&Error("Invalid argument(s); final image not patched.\n");
	return 0;
    }

    print "Patching merged image...\n";
    if ( ! &System("$patchProgram $args") ){
	print "Final image patched.\n";
	return 1;
    }

    &Error("Could not patch final image.\n");
    return 0;
}

##############################################################################
#	ConstructXIPArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "fullxip"
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	success: a string of argments
#               failed : null
#                  
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/24/96   	Initial Revision
#
##############################################################################
sub ConstructXIPArgs {
    local($args, $arg, $dest);
    local(@argList);

    # Name of the xip image.
    #
    $args = "-o" . $imgInfo{"desttree"} . "/image/xip.img";

    if ( $imgInfo{"heapaddress"} ){
	$args .= " -t" . $imgInfo{"heapaddress"};
    } else {
	&Error("The build variable \"heapAddress\" is not set.\n");
	return "";
    }
  SWITCH: {
      if ( $imgInfo{"xipresourcegrouping"} eq "normal" ){
	  $args .= " -u"; last SWITCH;
      }
      if ( $imgInfo{"xipresourcegrouping"} eq "optimized" ){
	  last SWITCH;
      }
      if ( $imgInfo{"xipresourcegrouping"} eq "randomized" ){
	  $args .= " -R"; last SWITCH;
      }
      $args .= " -u";		# default case
  }
    if ( $imgInfo{"xipoutputhandleinfo"} ){
	$args .= " -H";
    }
    if ( $imgInfo{"xipmakeextrafixedresourceswritable"} ){
	$args .= " -w";
    }
    if ( $imgInfo{"xipcompressed"} ){
	$args .= " -c";
    }
    if ( $imgInfo{"xipmappingwinaddress"} ){
	$args .= " -m" . $imgInfo{"xipmappingwinaddress"};
    } else {
	&Error("The build variable \"xipMappingWinAddress\" is not set.\n");
	return "";
    }
    if ( $imgInfo{"xipmappingwinsize"} ){
	$args .= " " . $imgInfo{"xipmappingwinsize"};
    } else {
	&Error( "The build variable \"xipMappingWinSize\" is not set.\n");
	return "";
    }
    if ( $imgInfo{"gfsromaddress"} ){
	$args .= " -f" . $imgInfo{"gfsromaddress"};
    }
    if ( $imgInfo{"xipemswingranularity"} ){
	$args .= " -e" . $imgInfo{"xipemswingranularity"};
    }
    if ( $imgInfo{"xipromaddress"} ){
	$args .= " -b" . $imgInfo{"xipromaddress"};
    }
    if ( $imgInfo{"xipnonfixedromaddress"} ){

	# Set the name of the xip images with non-fixed resources
	# 
	$args .= " -O" . $imgInfo{"desttree"} . "/image/xip.nf";

	local($nonfixedArgs) = &ConstructAddrAndSizePair("xipnonfixed", 
							"romaddress", "size",
							"-n");
	if ( $nonfixedArgs ){
	    $args .= " " . $nonfixedArgs;
	} else {
	    return "";
	}
    }
    if ( $imgInfo{"xipromwindowaddress"} ){

	local($romWinFlag) = "-r";
	if ( $imgInfo{"xipnonfixedimageoffset"}){ # Well, more than 1 image
	    $romWinFlag .= "f";
	}

	local($romWinArgs) = &ConstructAddrAndSizePair("xipromwindow", 
						       "address",
						       "size",
						       $romWinFlag);
	if ( $romWinArgs ){
	    $args.= " " . $romWinArgs;
	} else {
	    return "";
	}
    } else {
	&Error("The build variable \"xipROMWindowaddress\" is not set.\n");
	return "";
    }
    if ( $imgInfo{"xiphandles"} ){
	$args .= " -h" . $imgInfo{"xiphandles"};
    }
    if ( $imgInfo{"xipdebugflags"} ){
	$args .= " -d";

	@argList = split(/\s+/, $imgInfo{"xipdebugflags"});
	foreach (@argList) {
	  SWITCH: {
	      if ( $_ eq "stats" ) { $args .= "s"; last SWITCH }
	      if ( $_ eq "params" ) { $args .= "p"; last SWITCH }
	      if ( $_ eq "geode" ) { $args .= "g"; last SWITCH }
	      if ( $_ eq "resource" ) { $args .= "r"; last SWITCH }
	      if ( $_ eq "coreblock" ) { $args .= "c"; last SWITCH }
	      if ( $_ eq "layout" ) { $args .= "l"; last SWITCH }
	      if ( $_ eq "heap" ) { $args .= "h"; last SWITCH }
	      if ( $_ eq "output" ) { $args .= "o"; last SWITCH }
	      if ( $_ eq "relocations" ) { $args .= "R"; last SWITCH }
	      if ( $_ eq "free_list" ) { $args .= "f"; last SWITCH }
	      if ( $_ eq "resource_offsets" ) { $args .= "O"; last SWITCH }
	      if ( $_ eq "resource_handle_map" ) { $args .= "P"; last SWITCH }
	      if ( $_ eq "all" ) { $args .= "a"; last SWITCH }
	  }
	}
    }
    if ( $imgInfo{"xipgrouping"} ){
	@argList = split(/\s+/, $imgInfo{"xipgrouping"});
	
	while (@argList ){
	    $arg = shift(@argList); # 1st geode
	    $args .= " -g" . $arg;
	    $arg = shift(@argList); # resid of the 1st geode
	    $args .= " " . $arg;
	    $arg = shift(@argList); # 2nd geode
	    $args .= " " . $arg;
	    $arg = shift(@argList); # resid of the 2nd geode
	    $args .= " " . $arg;
	}
    }
    if ( $imgInfo{"xipmaximagesize"} ){
	$args .= " -M" . $imgInfo{"xipmaximgsize"};
    }
    if ( $imgInfo{"xipvademformat"}){
	$args .= " -v";
    }
    if ( $imgInfo{"xipvademromsize"}){
	$args .= " -S" . $imgInfo{"xipvademromsize"};
    }

    return $args;
}

##############################################################################
#	ConstructGFSArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "gfs".
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	success: a string of arguments
#               failed : null string
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/24/96   	Initial Revision
#
##############################################################################
sub ConstructGFSArgs {
    local($args) = "create -a";

    if ( $imgInfo{"gfsalignsize"} ne "" ){
	$args .= $imgInfo{"gfsalignsize"};
    }
    if ( $imgInfo{"gfsusedatachecksum"} ){
	$args .= " -x";
    }
    if ( $imgInfo{"gfsdescription"} ){
	$args .= " -d" . $imgInfo{"gfsdescription"};
    }
    if ( $imgInfo{"gfsvolumename"} ){
	$args .= " -v" . $imgInfo{"gfsvolumename"};
    }
    if ( $imgInfo{"gfsmaximagesize"} ){
	$args .= " -s" . $imgInfo{"gfsmaximagesize"};
    }

    # Set the output file name and the source tree.
    #
    $args .= " " . $imgInfo{"desttree"} . "/image/gfs.img";
    $args .= " " . $imgInfo{"desttree"} . "/gfs";

    return $args;
}

##############################################################################
#	ConstructLangGFSArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "gfs" to make language
#               patch GFS.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	success: a string of arguments
#               failed : null string
# SIDE EFFECTS:	none
#
# STRATEGY:
#       We do not share the code with ConstructGFSArgs because
#       there may be different arguments different for different GFS's.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon   12/23/97        Borrowed from ConstructGFSArgs
#
##############################################################################
sub ConstructLangGFSArgs {
    local($args) = "create -a";

    if ( $imgInfo{"gfsalignsize"} ne "" ){
	$args .= $imgInfo{"gfsalignsize"};
    }
    if ( $imgInfo{"gfsusedatachecksum"} ){
	$args .= " -x";
    }
    if ( $imgInfo{"langgfsdescription"} ){
	$args .= " -d" . $imgInfo{"langgfsdescription"};
    }
    if ( $imgInfo{"gfsvolumename"} ){
	$args .= " -v" . $imgInfo{"gfsvolumename"};
    }
    if ( $imgInfo{"gfsmaximagesize"} ){
	$args .= " -s" . $imgInfo{"gfsmaximagesize"};
    }

    # Set the output file name and the source tree.
    #
    $args .= " " . $imgInfo{"desttree"} . "/image/langgfs.img";
    $args .= " " . $imgInfo{"desttree"} . "/langgfs";

    return $args;
}

##############################################################################
#	ConstructCGFSArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "cgfs".
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	a string of arguments
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/24/96   	Initial Revision
#
##############################################################################
sub ConstructCGFSArgs {
    local($args);
    
    # Set input and output file names.
    #
    $args = $imgInfo{"desttree"} . "/image/gfs.img";
    $args .= " " . $imgInfo{"desttree"} . "/image/cgfs.img";

    if ( $imgInfo{"gfscompressedblocksize"} ){
	$args .= " " . $imgInfo{"gfscompressedblocksize"};
    }
    if ( $imgInfo{"gfscompressedalignments"} ){
	$args .= " " . $imgInfo{"gfscompressedalignments"};
    }

    return $args;
}

##############################################################################
#	ConstructLangCGFSArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "cgfs" to compress
#               language patch GFS.
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	a string of arguments
# SIDE EFFECTS:	none
#
# STRATEGY:
#       We do not share code with ConstructCGFSArgs because the
#       arguments to compress language patch GFS may be different.
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon   12/23/97        Borrowed from ConstructCGFSArgs
#
##############################################################################
sub ConstructLangCGFSArgs {
    local($args);
    
    # Set input and output file names.
    #
    $args = $imgInfo{"desttree"} . "/image/langgfs.img";
    $args .= " " . $imgInfo{"desttree"} . "/image/langcgfs.img";

    if ( $imgInfo{"gfscompressedblocksize"} ){
	$args .= " " . $imgInfo{"gfscompressedblocksize"};
    }
    if ( $imgInfo{"gfscompressedalignments"} ){
	$args .= " " . $imgInfo{"gfscompressedalignments"};
    }

    return $args;
}

##############################################################################
#	ConstructROMDISKArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "romdisk".
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	a string of argument.
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	10/ 3/96   	Initial Revision
#
##############################################################################
sub ConstructROMDISKArgs {
    local($args);

    # Source directory and output file name
    #
    $args = $imgInfo{"desttree"} . "/romdisk";
    $args .= " " . $imgInfo{"desttree"} . "/image/romdisk.img";

    # Setting the rest of the optional arguments
    #
    if ( $imgInfo{"romdiskfillbyte"} ){
	$args .= " -f" . $imgInfo{"romdiskfillbyte"};
    }
    if ( $imgInfo{"romdiskrecurseintosubdirs"} ){
	$args .= " -s";
    }
    if ( $imgInfo{"romdiskvolumename"} ){
	$args .= " -v" . $imgInfo{"romdiskvolumename"};
    }
    if ( $imgInfo{"romdisksectorsize"} ){
	$args .= " -z" . $imgInfo{"romdisksectorsize"};
    }

    return $args;
}


##############################################################################
#	ConstructMergeArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to "merge".
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	success: a string of arguments
#               failed : null string
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/24/96   	Initial Revision
#
##############################################################################
sub ConstructMergeArgs {
    local($args) = "-n";
    local($imgPath) = $imgInfo{"desttree"} . "/image";
    local($mergedFile) = "final.img";   # This name has to be
					# consistent with that in
					# ConstructPatchMergedImageArgs

    # Build the argument list.
    #
    if ( $imgInfo{"patchmergedimage"} ){

	# This name must be consistent with that in
	# ConstructPatchMergedImageArgs 
	#
	$mergedFile = "semi.img";
    } elsif ( $imgInfo{"finalimagename"} ){
	$mergedFile = $imgInfo{"finalimagename"};
    } 

    $args .=  " " . $imgPath . "/" . $mergedFile;

    # Handling jmp.img
    # 
    if ( $imgInfo{"jmp"} ){
	if ( !$var{"syntaxtest"} && (! -f "$imgPath/jmp.img") ){
	    &Error("Couldn't find $imgPath/jmp.img\n");
	    return "";
	}
	if ( ! $imgInfo{"jmpimageoffset"} ){
	    &Error("The build variable \"jmpImageOffset\" is not set.\n");
	    return "";
	}

	$args .= " " . &MakeMergeArgument("$imgPath/jmp.img",
					  $imgInfo{"jmpimageoffset"});
    }

    # Handling bios.img
    #
    if ( $imgInfo{"bios"} ){
	if ( !$var{"syntaxtest"} && (! -f "$imgPath/bios.img") ){
	    &Error("Couldn't find $imgPath/bios.img\n");
	    return "";
	}
	if ( ! $imgInfo{"biosimageoffset"} ){
	    &Error("The build variable \"biosImageOffset\" is not set.\n");
	    return "";
	}
	
	$args .= " " . &MakeMergeArgument("$imgPath/bios.img",
					  $imgInfo{"biosimageoffset"});
    }

    # Handling romdos.img
    #
    if ( $imgInfo{"romdos"} ){
	if ( !$var{"syntaxtest"} && (! -f "$imgPath/romdos.img") ){
	    &Error("Couldn't find $imgPath/romdos.img\n");
	    return "";
	}
	if ( ! $imgInfo{"romdosimageoffset"} ){
	    &Error("The build variable \"romdosImageOffset\" is not set.\n");
	    return "";
	}
	
	$args .= " " . &MakeMergeArgument("$imgPath/romdos.img",
					  $imgInfo{"romdosimageoffset"});
    }

    # Handling XIP images
    #
    if ( $imgInfo{"xip"} ){
	$args .= " " . &MakeMergeArgument("$imgPath/xip.img", 
					  $imgInfo{"xipimageoffset"});
	if ( $imgInfo{"xipnonfixedimageoffset"} ){
	    if ( $imgInfo{"xipnonfixed2imageoffset"} ){

		# More than one non-fixed resource image.
		#
		local($i) = 1;
		$args .= " " . &MakeMergeArgument("$imgPath/xip.nf$i",
						  $imgInfo{"xipnonfixedimageoffset"});
		$i++;
		while ( $imgInfo{"xipnonfixed${i}imageoffset"} ){
		    $args .= " " . &MakeMergeArgument("$imgPath/xip.nf$i",
						      $imgInfo{"xipnonfixed${i}imageoffset"});
		    $i++;
		}
	    } else { # Only one non-fixed resource image
		$args .= " " . &MakeMergeArgument("$imgPath/xip.nf",
						  $imgInfo{"xipnonfixedimageoffset"});
	    }
	}
    }

    # Handling GFS image
    # 
    if ( $imgInfo{"gfs"} ){
	local($gfsImg) = "gfs.img"; # assume using gfs.img.
	if ( $imgInfo{"gfscompress"} ){
	    $gfsImg = "cgfs.img"; # use cgfs.img instead
	}
    
	if ( $imgInfo{"gfsimageoffset"} ){
	    $args .= " " . &MakeMergeArgument("$imgPath/$gfsImg",
					      $imgInfo{"gfsimageoffset"});
	} else {
	    &Error("The build variable \"gfsImageOffset\" is not set.\n");
	    return "";
	}
    }

    # Handling Language Patch GFS image
    # 
    if ( $imgInfo{"langgfs"} ){
	local($langgfsImg) = "langgfs.img"; # assume using langgfs.img.
	if ( $imgInfo{"gfscompress"} ){
	    $langgfsImg = "langcgfs.img"; # use cgfs.img instead
	}
    
	if ( $imgInfo{"langgfsimageoffset"} ){
	    $args .= " " . &MakeMergeArgument("$imgPath/$langgfsImg",
					      $imgInfo{"langgfsimageoffset"});
	} else {
	    &Error("The build variable \"langgfsImageOffset\" is not set.\n");
	    return "";
	}
    }

    # Handling ROMDISK image
    # 
    if ( $imgInfo{"romdisk"} ){
	if ( $imgInfo{"romdiskimageoffset"} ){
	    $args .= " " . &MakeMergeArgument("$imgPath/romdisk.img",
					      $imgInfo{"romdiskimageoffset"});
	} else {
	    &Error("The build variable \"romdiskImageOffset\" is not set.\n");
	    return "";
	}
    }

    # Handling extra images
    # 
    $args = ConstructMergeExtraImageArgs($args); 

    return $args;

}

##############################################################################
#	ConstructMergeExtraImageArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments for extra images for merging
# PASS:		args = string of arguments to append to
# CALLED BY:	(INTERNAL)
# RETURN:	string of arguments
# SIDE EFFECTS:	none
#
# STRATEGY:
#       In order to allow user to merge N number of extra images, we
#       allow users to specify variables "extraImage<num>",
#       "extraImage<num>Name" and "extraImage<num>Offset", where <num>
#       is the Nth image to merge. (The first one should have no
#       number; the second one should start with 2)
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	03/11/98   	Initial Revision
#
##############################################################################
sub ConstructMergeExtraImageArgs {
    local($args) = @_;                  # argument list to append to
    local($imgCount) = 1;               # counter of current image
    local($imgPrefix) = "extraimage";   # prefix of extra image 
    local($imgNameSuffix) = "name";     # suffix of extra image name variable
    local($imgOffsetSuffix) = "offset"; # suffix of extra image offset variable
    local($img) = $imgPrefix;           # current image
    local($imgName);                    # current image name variable
    local($imgOffset);                  # current image offset variable
    local($realExtraImg);               # real extra image name

    #
    # We stop when "extraimage<num>" is not defined.
    #
    while ( $imgInfo{"$img"} ) {
	$imgName = $img . $imgNameSuffix;
	$imgOffset = $img . $imgOffsetSuffix;

	if ( $imgInfo{"$imgName"} ){
	    $realExtraImg = $imgInfo{"$imgName"};
	    if ( $imgInfo{"$imgOffset"} ) {
		$args .= " " . 
		    &MakeMergeArgument("$imgPath/$realExtraImg",
				       $imgInfo{"$imgOffset"});
	    } else {
		&Error("The build variable \"$imgOffset\" is not set.\n");
	    }
	} else {
	    &Error("The build variable \"$imgName\" is not set.\n");
	}

        $imgCount++;
        $img = $imgPrefix . $imgCount;
    }

    return $args;
}

##############################################################################
#	ConstructPatchMergedImageArgs
##############################################################################
#
# SYNOPSIS:	Construct the arguments to pass to user-defined patch
#               program to the final image
# PASS:		nothing
# CALLED BY:	(INTERNAL)
# RETURN:	success: a string of arguments
#               failed : null string
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       simon 	11/22/97   	Initial Revision
#
##############################################################################
sub ConstructPatchMergedImageArgs {
    local($imgPath) = $imgInfo{"desttree"} . "/image";
    local($targetFile) = "final.img";    # This name has to be
					 # consistent with that in
					 # ConstructMergeArgs 
    local($args);

    # Form path to the source file
    #
    if ( $imgInfo{"patchmergedimage"} ){

	# This name must be consistent with that in ConstructMergeArgs
	#
	$args .= " " . $imgPath . "/" . "semi.img";

    } else {
	&Error("The build variable \"patchMergedImage\" is not set.\n");
    }
    
    if ( $imgInfo{"finalimagename"} ){
	$targetFile = $imgInfo{"finalimagename"};
    }

    # Append the target file name
    #
    $args .= " " . $imgPath . "/" . $targetFile;
    return $args;
}

##############################################################################
#	ConstructAddrAndSizePair
##############################################################################
#
# SYNOPSIS:	Construct the address and size pair arguments with unlimited
#               length.
# PASS:		ConstructAddrAndSizePair(root, addrSuffix, sizeSuffix
#                                        [, prefix] )
#               root       - leading part of the argument (eg. "xipNonFixed")
#               addrSuffix - trailing of the argument for address 
#                            (eg. "ImageOffset")
#               sizeSuffix - trailing of the argument for size (eg. "Size")
#               prefix     - optional argument for adding to the 
#                            returned argument.
# CALLED BY:	ConstructXIPArgs()
# RETURN:	success = a string of pairs of address and size arguments
#               failed  = NULL
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	10/18/96   	Initial Revision
#
##############################################################################
sub ConstructAddrAndSizePair {
    local($root, $addrSuffix, $sizeSuffix, $prefix) = @_;
    local($args);

    if ( $imgInfo{"$root$addrSuffix"} ){ # set the address
	$args = $prefix . $imgInfo{"$root$addrSuffix"};
	if ( $imgInfo{"$root$sizeSuffix"} ){ # set the size
	    $args .= " " . $imgInfo{"$root$sizeSuffix"};
	} else {
	    &Error("The build variable \"$root$addrSuffix\" is set, but \"$root$sizeSuffix\" is not.\n");
	    return "";
	}

	local($i) = 2;
	while ( $imgInfo{"$root$i$addrSuffix"} ){ # set the address
	    $args .= " " . $prefix . $imgInfo{"$root$i$addrSuffix"};
	    if ( $imgInfo{"$root$i$sizeSuffix"} ){ # set the size
		$args.= " " . $imgInfo{"$root$i$sizeSuffix"};
	    } else {
		&Error("The build variable \"$root$i$addrSuffix\" is set, but \"$root$i$sizeSuffix\" is not. \n");
		return "";
	    }
	    $i++;
	}
    }

    return $args;
}

##############################################################################
#	MakeMergeArgument
##############################################################################
#
# SYNOPSIS:	Make the "merge" argument.
# PASS:		MakeMergeArgument(filename, mergePos)
#               filename - file/image to be merged
#               mergePos - the merge position
# CALLED BY:	
# RETURN:	"<filename>:<position in hex w/o leading '0x' >"
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	10/21/96   	Initial Revision
#
##############################################################################
sub MakeMergeArgument {
    local($filename, $mergePos) = @_;

    $mergePos = sprintf("%lx", eval($mergePos));
    return "$filename:$mergePos";

}


##############################################################################
#	ListFiles
##############################################################################
#
# SYNOPSIS:	List all the files in the passed directory.
# PASS:		ListFiles(dirPath)
#               dirPath - path of the directory
# CALLED BY:	(INTERNAL)
# RETURN:	a string of files in the passed directory
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/ 5/96   	Initial Revision
#
##############################################################################
sub ListFiles {
    local($dirPath) = @_;	# dir path
    local(@dirList);		# a list of entries in the given directory
    local($fileList);

    # Get the directory info.
    #
    opendir(DIR, $dirPath);
    @dirList = readdir(DIR);
    closedir(DIR);

    # Get rid of ".", "..", and directory entries.
    #
    foreach $entry (@dirList) {
	if ( ! -d "$dirPath/$entry" ) {
	    if ( &IsWin32() ){	# convert the filename to lowercase.
		$entry = lc($entry);
	    }
	    $fileList .= "$dirPath/$entry ";
	}
    }

    chop($fileList);		# Remove the space char at the end

    return $fileList;
}



##############################################################################
#	MakeFloppyImages
##############################################################################
#
# SYNOPSIS:	Create images for a floppy disk installation
# PASS:		nothing
# CALLED BY:	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub MakeFloppyImages {
   
   # Create the image directory.
 
   $dosDestPath=&MakePath(&BuildDestPath(IMAGE));

   # Create one big zip file.

   &printbold("Creating compressed image file for floppy installation.\n\n");
   $localPCPath=&BuildDestPath(LOCALPC);
   &System("cd $localPCPath;zip -r -k -q ../image/image.zip *");

   # Make the first disk image

   &printbold("Creating disk 1 image.\n\n");
   &MakePath("${dosDestPath}disk1");
   &SendFile("Tools/build/product/Common/Tools/pkunzip.exe",
	     "${dosDestPath}disk1/");
   &SendFile("Tools/build/product/Common/Tools/merge.exe",
	     "${dosDestPath}disk1/");
   &SendFile("Tools/build/product/Common/Tools/install.bat",
	     "${dosDestPath}disk1/");
   &printbold("Creating image.000\n");
   print("      in ${dosDestPath}disk1/\n\n");
   open(IMAGE, "${dosDestPath}image.zip");
   read(IMAGE, $buffer, 1380000);
   open(SPLITFILE,"> ${dosDestPath}disk1/image.000");
   print SPLITFILE $buffer;
   close(SPLITFILE);

   # Create the batch file.

   open(BATCH, "> ${dosDestPath}disk1/doinst.bat");
   print BATCH "ECHO About to install $var{productlongname} demo.\nECHO .\n";
   my $destdir="$var{productshortname}";
   if ( "$var{ec}" ) {
       $destdir.=".ec";
   }
   print BATCH "ECHO It will be installed to C:\\$destdir\nPAUSE\n";
   print BATCH "C:\nCD \\\nIF EXIST C:\\$destdir\\NUL GOTO ERROREXIST\n";
   print BATCH "MKDIR $destdir\nCD $destdir\n";
   print BATCH "COPY A:\\IMAGE.000 .\n";
   print BATCH "COPY A:\\MERGE.EXE .\nCOPY A:\\PKUNZIP.EXE .\n";

   # Make all subsequent images.

   $imagenum=1;
   while (read(IMAGE, $buffer, 1455000)) {

       $disknum=$imagenum+1;
       &printbold("Creating disk $disknum image.\n\n");

       # Create a disk subdirectory.

       &MakePath("${dosDestPath}disk$disknum");

       # Write out this segment of the zip file.

       &printbold("Creating image.00$imagenum\n");
       print("      in ${dosDestPath}disk$disknum/\n\n");
       open(SPLITFILE,"> ${dosDestPath}disk$disknum/image.00$imagenum");
       print SPLITFILE $buffer;
       close(SPLITFILE);

       # Write out the batch file lines to copy this part to the hard disk.

       print BATCH ":DISK$disknum\nECHO Please insert disk $disknum\n";
       print BATCH "PAUSE\n";
       print BATCH "IF NOT EXIST A:\\IMAGE.00$imagenum GOTO DISK$disknum\n";
       print BATCH "COPY A:\\IMAGE.00$imagenum .\n";

       $imagenum++;
   }
   close(IMAGE);

   # Finish up the batch file.

   print BATCH "ECHO Merging zip file...\nMERGE IMAGE $var{productshortname}.ZIP\n";
   print BATCH "DEL IMAGE.*\n";
   print BATCH "ECHO Unzipping files...\nPKUNZIP -D $var{productshortname}.ZIP\n";
   print BATCH "GOTO DONE\n";
   print BATCH ":ERROREXIST\nECHO ERROR: That directory already exists\n";
   print BATCH ":DONE\nECHO Cleaning up...\nDEL $var{productshortname}.ZIP\nDEL MERGE.EXE\n";
   print BATCH "DEL PKUNZIP.EXE\nDEL C:\\DOINST.BAT\n";
   close BATCH;
   &System("/usr/public/unix2dos ${dosDestPath}disk1/doinst.bat");

}


