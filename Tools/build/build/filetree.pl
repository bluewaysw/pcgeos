#!/usr/public/perl -w
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) Geoworks 1996 -- All Rights Reserved
#       GEOWORKS CONFIDENTIAL
#
# PROJECT:	PCGEOS
# MODULE:	Build script
# FILE: 	filetree.pl
# AUTHOR: 	Paul Canavese, Mar 25, 1996
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#	pjc	3/25/96   	Initial Revision
#	pjc	10/24/96   	Added media type handling.
#
# DESCRIPTION:
#
#	----		-----------
#	pjc	3/25/96   	Initial Revision
#	pjc	10/24/96   	Added media type handling.
#
# DESCRIPTION:
#
#	Subroutines for parsing and sending a file tree.
#
# SUBROUTINES:
#
#       OpenAndSendFileTreeFile()
#               Find the appropriate filetree file, open it, and send it.
#	SendFileTree()
#		Parse the file tree, creating directories and sending files.
#	ParseIgnoreFrame()
#		We are in a frame that is conditionally discluded.  Keep 
#		parsing and throwing the shme away until we exit the frame.
#	BuildDestPath()
#		Return the GEOS destination path based on the media type and
#		options.
#	BuildGEOSDestPath()
#		Determine the current destination path (as seen by GEOS).
#	BuildDOSDestPath()
#		Determine the current destination path (as seen by DOS).
#	ChooseMedia()
#		Returns the media type to use for the current file.
#	CreateFileStub()
#		Turns the specified geode into a file stub.
#
#	$Id: filetree.pl,v 1.32 98/06/11 16:34:52 simon Exp $
#
###############################################################################

$subtree="";			# Current path in filetree file.

1;

@copydirlist;  # list of all files in a dir. It gets initialized by the 
               # COPYDIR command.

##############################################################################
#	OpenAndSendFileTreeFile
##############################################################################
#
# SYNOPSIS:	Find the appropriate filetree file, open it, and send it.
# PASS:		nothing
# CALLED BY:	top level
# RETURN:	1 on error, 0 on success
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/31/96   	Initial Revision
#
##############################################################################
sub OpenAndSendFileTreeFile {

    my($ProcessObj);
    my($retriesRemaining, $retiresCount);

    #
    # Launch the Resedit if necessary
    
    if (&UseResedit()) {
	
	$isSync = 1;   
	
	if ( ! ($var{debugresedit})) {
	
	 #
	 # This is to make sure that all files copy must
	 # be done successfully

          &SetReseditIni();
	  
	  #
	  # We have to delete act.ive file and the state files
	  # for the nt demo.

	  if (-e "$var{reseditpath}/geos_act.ive") {
	      print "Deleting geos_act.ive.\n";
	      unlink "$var{reseditpath}/geos_act.ive" 
	      }
	  if (-d "$var{reseditpath}/privdata/state") {
	      my(@stateFiles) = glob "$var{reseditpath}/privdata/state/*.*";
	      print "Deleting state files.\n";
	      unlink @stateFiles;
	  }
	  
	  Win32::Process::Create($ProcessObj,
			     "$var{dosreseditpath}\\geos.bat",
				 "geos",
				 0,
			     NORMAL_PRIORITY_CLASS,
			     "$var{dosreseditpath}") ||
				 die &print_error;
	    
	    # Sleep long enough to have resedit ready
	  sleep 10;
      }
    }
    
    $retriesRemaining = $var{retries};
    for (;;) {
	if ( -f "$var{filetree}" ) {
	
	    # Look for filetree file in local directory first.
	    open(FILELIST, "$var{filetree}");
	    &printbold("Sending file tree $var{filetree}.\n");
	    
	} else {
	    
	    # Otherwise, look in GEOS tree that script was run from, or 
	    # $geosPath/Tools/build
	    
	    $fullPathFile=&FindBuildFile("$var{filetree}");
	    
	    if ( -f "$fullPathFile" ) {
		open(FILELIST, "$fullPathFile");
		&printbold("Sending file tree $fullPathFile.\n\n");
	    } else {
		&Error("Filetree $var{filetree} not found.");
	    return 1;
	    }
	}
	
	&printbold("Sending to $var{desttree}\n\n");
	
	&SendFileTree();
	#
	# Check if we need to retry, quit if not.
	#
	if (($retriesRemaining == 0) ||
	    (scalar(@retryList) == 0)) {
	    last; 
	} else {
	    print "\nRetrying the following files: @retryList\n";
	    print "Retries remaining: $retriesRemaining\n\n";

	    #
	    # Write a header for the log file indicating this the nth trial 
	    # warnings/errors.

	    $retriesCount = $var{retries} - $retriesRemaining + 1;
	    open(WARNING_LOG, ">>$var{logdir}/warning.log");
	    open(ERROR_LOG, ">>$var{logdir}/error.log");
	    
	    print WARNING_LOG "\n\n\nWarnings for retry No. $retriesCount:\n";
	    print ERROR_LOG "\n\n\nErrors for retry No.$retriesCount:\n";

	    close(WARNING_LOG);
	    close(ERROR_LOG);

	    #
	    #  We need to retry, so set up includefiles 
	    #  and retryList
	    # 
	    @includelist = @retryList;
	    @retryList = ();  # emtpy retryList
	    $retriesRemaining--;
	    close(FILELIST);
	}
    }
    close (FILELIST);

    #
    # Okay now we are done with sending down the files, if we are using
    # Resedit, we can kill it at this moment.
  						
    if (&UseResedit()) {
	if ( ! ($var{debugresedit})) {

	    #
	    # Just touch the ENDFILE, resedit should quit when it sees this.
	    
	    &TruncateToZero("$var{commdir}/ENDFILE");
	    sleep 5;
#	    $ProcessObj->Wait(INFINITE); 
	    &FinishCleanUp();
	}
	    $isSync = 0;
    }
    return 0;
}

##############################################################################
#	SendFileTree
##############################################################################
#
# SYNOPSIS:	Parse the filetree file, creating directories and sending 
#               files.
# PASS:		nothing
# CALLED BY:	top level, recursively by itself
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY:	The parsing process is frame-based.  Whenever a new frame is
#		entered, SendFileTree recursively calls itself.  Whenever
#		SendFileTree reaches the end of a frame, it returns.
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	3/25/96   	Initial Revision
#       canavese 	10/24/96   	Added media-type handling.
#       kliu            3/30/98         Added everything Resedit-related
##############################################################################
sub SendFileTree {
    local($dirname, $destpath);
    my($errorLog);
    my($warningLog);
    my($reseditError);
    my($reseditWarning);

    if (&UseResedit()) {
	#
	# Set up the resedit specific locals 

	$errorLog = "$var{logdir}/error.log";
	$warningLog = "$var{logdir}/warning.log";
	$reseditError = "$var{commdir}/ERROR";
	$reseditWarning = "$var{commdir}/WARN";
    }

    # Enumerate through each line in the filetree file.

    while (&GetNextLine()) {

	# Pass each line through in debugging mode.

	chop($_);
	&DebugPrint(parsefiletree, ": $_");

	# Pre-process line to remove extra spaces and comments.

	s/^[\s]*//;
	s/\#.*//;

	# Process "{ec}" macros.

	if ( "$var{ec}" ) {
	    s/{ec}/ec/g;
	} else {
	    s/{ec}//g;
	}

	# Process "{dbcs}" macros.

	if ( "$var{dbcs}" ) {
	    s/{dbcs}/DBCS/g;
	} else {
	    s/{dbcs}//g;
	    # consume any double-slashes left over
	    s/\/\//\//g;
	}

	
	# Pre-process special directory
	s/\%LANGUAGE\%/$var{language}/;

	# 
	# Translate simple conditional macros.

	s/^AMENGLISH[\s]+{/IF \( language == "english" \) {/;
	s/^BRENGLISH[\s]+{/IF \( language == "britengl" \) {/;
	s/^DUTCH[\s]+{/IF \( language == "dutch" \) {/;
	s/^ENGLISH[\s]+{/IF \( language == "english" || language == "britengl" \) {/;
	s/^FRENCH[\s]+{/IF \( language == "french" \) {/;
	s/^GERMAN[\s]+{/IF \( language == "german" \) {/;
	s/^ITALIAN[\s]+{/IF \( language == "italian" \) {/;
	s/^SPANISH[\s]+{/IF \( language == "spanish" \) {/;
	s/^FINNISH[\s]+{/IF \( language == "finnish" \) {/;
	s/^NORSK[\s]+{/IF \( language == "norsk" \) {/;
	s/^SWEDISH[\s]+{/IF \( language == "swedish" \) {/;

        # Scandinavian languages

	s/^SCAND[\s]+{/IF \( language == "swedish" || language == "norsk" || language == "finnish" \) {/;

	# If frame ends, and else frame begins, ignore everything in it.
						  
        if ( /}[\s]*ELSE[\s]*{/i ) {

	    &ParseIgnoreFrame();
	    last;
	
	}
	    
	# Return if our frame has ended.

	last if /}/;

	# Look for a frame command.

	@line=reverse(split(" ", "$_"));
	$cmd=pop(@line);
 	if ( "$cmd" eq "DIR" ) {

	    # "cd" into the directory, send the files, then "cd" out.

	    $dirname=&GetFromParen($_);
	    push(@dirstack, "$dirname");
	    &SendFileTree();
	    pop(@dirstack);

	} elsif ( "$cmd" eq "COPYDIR" ) {
	    
	    # Do not copy directory if we send only a few files, i.e., 
	    # only if @includelist is not empty 

	    if ( ! scalar(@includelist) ) {
		&InitializeCopyDirList();
	    }
      
	} elsif ( "$cmd" eq "IF" ) {

	    # If the expression is true, send everything inside.  
	    # Otherwise, ignore it all.

	    if ( &EvaluateExpression(&GetFromParen($_)) ) {
		&SendFileTree();
	    } else {
		&ParseIgnoreFrame();
	    }

	} elsif ( "$cmd" eq "IMAGE" ) {

	    local($dosDestPath)=&MakePath(&BuildDestPath(IMAGE));
	    $sourceFile = pop(@line);
	    if (scalar(@includelist)) {
		#
		# okay there are some files which we want explicitly,
		
		my($curFile) = $sourceFile;
		$curFile =~ s|.*/([^/]*$)|$1|;
		next if (! (&Member($curFile, @includelist)));
	    }

	    if (scalar(@excludelist)) {
		#
		# okay there are some files which we want explicitly,
		
		my($curFile) = $sourceFile;
		$curFile =~ s|.*/([^/]*$)|$1|;
		next if ( (&Member($curFile, @excludelist)));
	    }

	    &SendFile($sourceFile, $dosDestPath);

	} elsif ( "$cmd" eq "FORCEDIR" ) {

	    foreach $mediaType (@line) {

		local($baseMediaType, @options)= split(/_/, $mediaType);
		$baseMediaType =~ tr/A-Z/a-z/;
		if ( "$var{$baseMediaType}" ) {
		    $destPath=&BuildDestPath($baseMediaType, @options);
		    &MakePath($destPath);
		}
	    }

	} elsif ( "$cmd" ) {

	    #
	    # Process a file to put into the build
	    #

	    local($productDir,$productDirOption,$dosDestPath, $dosName, $fullName);
	    local(@productDirOptions);

	    # If the TEMPLATE directive is used, it is followed by the file.

	    if ( "$cmd" eq "TEMPLATE" ) {
		$sourceFile=pop(@line);
	    } else {
		$sourceFile=$cmd;
	    }

	    # If user has supplied a file filter, apply it to the file
	    # and ship the file only if it matches

	    if (scalar(@includelist)) {
		#
		# okay there are some files which we want explicitly,
		
		my($curFile) = $sourceFile;
		$curFile =~ s|.*/([^/]*$)|$1|;
		next if (! (&Member($curFile, @includelist)));
	      }

	    if (scalar(@excludelist)) {
		#
		# okay there are some files which we want explicitly,
		
		my($curFile) = $sourceFile;
		$curFile =~ s|.*/([^/]*$)|$1|;
		next if ( (&Member($curFile, @excludelist)));
	      }


	    # Determine the media type for the file.

	    ($mediaType,@mediaOptions)=&ChooseMedia(@line);
	    if ( ! "$mediaType" ) {
		&Error("No valid media type for $sourceFile\n");
		next;
	    }

	    # Change the source path, if necessary.

	    @productDirOptions=grep(/^PRODUCTDIR/, @mediaOptions);
	    ($productDirOption)=@productDirOptions;
	    if ( "$productDirOption" ) {
		($productDirOption, $productDir) = split("=", $productDirOption);
		$sourceFile=&ReplaceProductDir($sourceFile, $productDir);
	    }

	    # Build the destination path.

	    if ( ! $var{"sendtemplateonly"} || ($cmd eq "TEMPLATE") ){
		$destPath=&BuildDestPath($mediaType, @mediaOptions);
		$dosDestPath=&MakePath($destPath);
	    }

	    # Send the file.

	    if ( "$cmd" eq "TEMPLATE" ) {
		&ParseTemplateFileAndSend($sourceFile, $dosDestPath);
	    } elsif ( ! $var{"sendtemplateonly"} ){

		if (&UseResedit() &&
		    ($vmFile = &GetVMFile($sourceFile))) {

		    #
		    # Now wait for ResEdit to produce the resulting file
		    #
		    $fullName = $sourceFile;
		    $fullName =~ s|.*/([^/]+)$|$1|;
		    $dosName = $fullName;               # used later in retry list.

		    if ($var{"ec"}) {
			if ($dosName =~ /ec\.geo/) {
			    $dosName =~ s/ec\.geo//;
			} else {
			    #
			    # For test apps maybe
			    $dosName =~ s/\.geo//;
			}
		    } else {
			$dosName =~ s/\.geo//;
		    }
		    $dosName = substr($dosName, 0, 8);

		    if ($var{action} =~ /create_trans_files/i) {
			
			if (! (-s "$var{transdir}/$dosName\.atf")) {
			    
			    # Only send file if translation file not aleady exists
			    
			    &SendFile($vmFile, "$var{srctrans}/", 1);
			    &SendFile($sourceFile, "$var{srctrans}/", 1);
			} else {
			    print "Translation file $dosName\.atf already exists. Skipping $dosName..\n";
			    next;
			}

		    } elsif (-s "$var{transdir}/$dosName\.atf") {

			#
			# For optimization purpose, we want to check whether the file
			# in the destination directory already exists and it is newer than 
			# the sourceFile  we are using. If yes, we can skip the sending.
			# We won't attempt this optimization if we are only creating patch,
			# since we don't have the info for the dosname of the patch file
			# at this point. We rarely use create_patch anyway.
			#
			
			if (($var{action} !~ /create_patch/i) &&
			    (-s "$dosDestPath/$dosName\.geo")) {
			    
			    # 
			    # We already get a copy of the geode down there, so check the timestamp.
			    
			    my($fileFullPath);
			    my(@sourceStats, @destStats);
			    
			    $fileFullPath = &FindInstalledFile($sourceFile);

			    @sourceStats = stat $fileFullPath;
			    @destStats = stat "$dosDestPath/$dosName\.geo";

			    #
			    # stats result contains the mtime in the 10th element

			    if ($destStats[9] > $sourceStats[9]) {

				# The dest file is up-to-date, no need to send
				print "Destination files are up to date. Skipping $dosName..\n";
				next;          # deal with next file
			    }
			}

			#
			# Also need to copy the translation file over to srctrans,
			# we need to do that first before the .geo get copied over
			# for sync purpose
			
			print "Copying gct translation file to src directory.\n";
			my($tmpDosPath) = $var{srctrans};
			$tmpDosPath =~ s|/|\\|g;
			&CopyFile("$var{transdir}/$dosName\.atf", "$tmpDosPath\\", 1);
			&SendFile($vmFile, "$var{srctrans}/", 1);
			&SendFile($sourceFile, "$var{srctrans}/", 1);
			
		    } else {
			print "Translation File doesn't exist or it has zero length. Skipping $dosName..\n\n";
			
			#
			# Send geode down anyway

			&SendFile($sourceFile, $dosDestPath);
			if ($var{"vm"}) {
			    &SendFile($vmFile, $dosDestPath);
			}

			#
			# Send geode stub (elyomed) if necessary.
			
			&SendGeodeStubIfNecessary($mediaType, $sourceFile, $dosDestPath, @mediaOptions);
			next;              # parse next line
		    }
		    
		    my(@match);
		    my($tmpFile, $timer, $cnt);
		    my(%report_array) = ();

		    if ($var{action} =~ /create_trans_files/i) {
			$tmpFile = "$var{transdir}/$dosName\.atf";
		    } else {
			#
			# Sometimes patch files have different name
			# from .geo file.
			$tmpFile = "$var{desttrans}/*.*";
		    }
		    
		    if ($var{action} =~ /create_null_and_patch/i) {
			$cnt = 2;  # we are anticipating two files
		    } else {
			$cnt = 1;
		    }
		    
		    print "Checking for $dosName..";
		    for ($timer=0;  ; (sleep 2.5), $timer++, print ".") {

			#
			# Check for error first
			if ((! ($report_array{'resedit_warning'})) && 
			    (-s $reseditWarning)) {
			    $report_array{'resedit_warning'} = 1;
			}

			if ($var{action} =~ /create_trans_files/i) {
			    last if (-s $tmpFile);
			} else {
			    @match = glob("$tmpFile");	
			    last if (scalar(@match) == $cnt);
			}

			if (-s $reseditError) {

			    $report_array{'resedit_error'} = 1;
			    last;        ## Shouldn't continue if it's a resedit error
			}
			
			#
			# Give enough time, if still can't get anything, we have to 
			# timout
			
			if ($timer >= 30) { 
			    
			    if (scalar(@match)) {
				#
				# if we have some file, we still continue the operation
				$report_array{'anticipate_more_files'} = 1;
				last;
				
			    } else {
				# If there is nothing, apparently Resedit runs into some 
				# problems. We better cleanup and quit
				
				next if ($var{debugresedit}) ;
				
				print "Resedit did not respond. Timout\n";
				
                                #
				# touch the FAIL file, this is for makespock use.
				open(TMP, ">$var{logdir}/FAIL");
				close(TMP);

				&FinishCleanUp;
				exit;
			    }
			}
		    }
		    print "done\n";
		    
		    if (scalar(%report_array)) {  # error 
			
#			push(@retryList, $fullName);
			
			print "We have a warning/error reported\n\n";
			
			#
			# Why not opening everything first.
			
			open(RES_WARN, "<$reseditWarning");
			open(WARNING_LOG, ">>$warningLog");
			open(RES_ERROR, "<$reseditError");
			open(ERROR_LOG, ">>$errorLog");
			
			if ($report_array{'resedit_error'}) {
			    push(@retryList, $fullName);

			    print ERROR_LOG "============================================================\n";
			    print ERROR_LOG "Geode \= $dosName\.geo\n";
			    print ERROR_LOG "Error \= ";
			    print ERROR_LOG while (<RES_ERROR>);
			    print ERROR_LOG "\n";
			}
			
			if ($report_array{'anticipate_more_files'}) {
			    print WARNING_LOG "============================================================\n";
			    print WARNING_LOG "Geode \= $dosName\.geo\n";
			    print WARNING_LOG "Warning \= ";
			    print WARNING_LOG "Gbuild is anticipating more file produced from Resedit\n";
			}
			
			if ($report_array{'resedit_warning'}) {
			    print WARNING_LOG "============================================================\n";
			    print WARNING_LOG "Geode \= $dosName\.geo\n";
			    print WARNING_LOG "Warning \= ";
			    print WARNING_LOG while (<RES_WARN>);
			    print WARNING_LOG "\n";
			    }
			close(RES_WARN);
			close(WARNING_LOG);
			close(RES_ERROR);
			close(ERROR_LOG);
		    
			#
			# Sigh..truncate doesn't work, use the hack version.
			
			&TruncateToZero ($reseditError);
			&TruncateToZero ($reseditWarning);
		    }
		    
		    if ((! ($var{action} =~ /create_trans_files/i)) 
			&& scalar(@match)) {
			
			my($patchPath);
			foreach $file (@match) {
			    if ($file !~ /\.geo$/i) {
				#
				# okay it's a patch file
				
				if ($var{langgfs}) {
				    #
				    # if langgfs is set, we just go ahead and put the
				    # patch files into langgfs dir.

				    $patchPath = "$var{desttree}/langgfs/privdata/language/$var{language}";
				} elsif ($mediaType !~ /XIP/) {
				    #
				    # Send to mediaType if not langgfs and not XIP.

				    $patchPath = "$var{desttree}/$mediaType/privdata/language/$var{language}";
				} else {
				    #
				    # Send to GFS if mediaType is XIP but langgfs is not set.

				    $patchPath = "$var{desttree}/gfs/privdata/language/$var{language}";
				}

				my($dosPatchPath) =&MakePath($patchPath);
				
				#
				# We want to rename the file to the standard format:

				my($newName) = $file;
				$newName =~ s|.*/([^/]*$)|$1|;
				$newName =~ s|\.P0(\d)$|.P__|i;
                                   						  
				&CopyFile($file, "$dosPatchPath$newName");
				    
			    } else {
				&CopyFile($file, $dosDestPath);
			    }
			    #
			    # should also copy to installed directory in here, okay
			}
		    }
		    #
                    # Now delete useless files from source 
		    &ClearSrcSyncFiles("$dosName");
		    if ($var{action} !~ /create_trans_files/i) {
			&ClearDestSyncFiles(scalar(@match));
		    }
		    
		    if ($var{action} =~ /create_trans_files/i) {
			next;
		    }
		    
		} elsif (&UseResedit() 
			 && ($var{action} =~ /create_trans_files/i)) {
		    #
		    # If we are creating translation files, don't bother.
		    next;

		} else {
		    &SendFile($sourceFile, $dosDestPath);
			
		    if ( $var{"vm"} ) {
			if ( $var{"ec"} ) {
			    ($vmFile = $sourceFile) =~ s/ec\.geo/\.vm/;
			}
			else {
				($vmFile = $sourceFile) =~ s/\.geo/\.vm/;
			    }
			&SendFile($vmFile, $dosDestPath);
			}
		}
	    }

	    # Send geode stub (elyomed) if necessary.

	    &SendGeodeStubIfNecessary($mediaType, $sourceFile, $dosDestPath, @mediaOptions);
       }
    }
}

##############################################################################
#	InitializeCopyDirList
##############################################################################
#
# SYNOPSIS: Initialize the array with the list of files in source dir	
# PASS:	    nothing 	
# CALLED BY: SendFileTree()	
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# STRATEGY: W	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       mjoy     	8/07/97   	Initial Revision
#	
##############################################################################
sub InitializeCopyDirList {
    local($arglist, $dirpath, $restOfLine);
    local($installedDir);
    
    $arglist=&GetFromParen($_);
    ($dirpath, $restOfLine) = split(/ /, $arglist, 2);
    #
    #Find the corresponding dir in the installed tree
    #
    $installedDir = &FindInstalledDir($dirpath);
    
    if ("$installedDir") {
	#
        #get the list of files in the dir,
	#
	if (opendir(SOURCEDIR, "$installedDir")) {
	    foreach $fileName (readdir(SOURCEDIR)) {
		#
                # ignore directories
		#
		next if -d "$installedDir/$fileName";
	
        	push(@copydirlist, "$dirpath$fileName $restOfLine\n");
	    }
	
	    closedir(SOURCEDIR);
       	}
    } else {
	&Error("Could not find $dirpath in any of the source trees.");
    }
}	

sub  FinishCleanUp {

    &RmTree($var{srctrans});
    &RmTree($var{desttrans});
    &RmTree($var{commdir});
}    
						  
##############################################################################
#	GetNextLine
##############################################################################
#
# SYNOPSIS: get next line to be parsed by SendFileTree	
# PASS:	    nothing 
# CALLED BY:	SendFileTree()
# RETURN:	True/False
# SIDE EFFECTS:	none
#
# STRATEGY:   So far we could only copy files that were explicitly listed in 
# .filetree. Added ability to copy an entire directory. If @cmd = COPYDIR, 
# initialize array @copydirlist with the contents of the specified dir. When 
# looking for the next line to parse in SendFileTree() pop an element from
# @copydirlist, if this is empty then get next line from FILELIST, when we 
# reach EOF return false
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       mjoy     	8/06/97   	Initial Revision
#	
##############################################################################
sub GetNextLine {
    return ($_ = pop(@copydirlist)) || ($_ = <FILELIST>);
}

##############################################################################
#	ParseIgnoreFrame
##############################################################################
#
# SYNOPSIS:	We are in a frame that is conditionally discluded.  Parse
#		through and throw the lines away until we reach the end of
#		the frame.
# PASS:		$ignoreif
# CALLED BY:	SendFileTree
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/14/96   	Initial Revision
#
##############################################################################
sub ParseIgnoreFrame {

    local($ignoreif)=@_;
    while (<FILELIST>) {

	s/\#.*//;		# Get rid of comments
	s/{ec}//g;		# The ec brackets confuse us, Ernay?
	s/{dbcs}//g;		# The dbcs brackets confuse us, Ernay?

	# Pass each line through in debugging mode.

	chop($_);
	&DebugPrint(parsefiletree, "; $_");

	# If a new IF frame begins, parse it.

        if ( /\s*IF\s\(.*\)\s*{/i ) {
	    &ParseIgnoreFrame("1");
	    next;
	}

	# If this frame ends, and an else frame begins, parse it.

        if ( /}[\s]*ELSE[\s]*{/i ) {
	    if ($ignoreif) {
		&ParseIgnoreFrame("1");
		last;
	    } else {
		&SendFileTree();
		last;
	    }
	}

	# Check if a new nested frame is beginning.

	if ( /{/ ) {

	    # New nested frame... ignore it, too.

	    &ParseIgnoreFrame($ignoreif);

	} else {

	    # If our frame has ended, return to caller.

	    last if /}/;
	}
    }
}	


##############################################################################
#	BuildDestPath
##############################################################################
#
# SYNOPSIS:	Return the GEOS destination path based on the media type and
#               options.
# PASS:		media type, media options (if exist)
# CALLED BY:	SendFileTree
# RETURN:	nothing
# SIDE EFFECTS:	none
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/17/96   	Initial Revision
#
##############################################################################
sub BuildDestPath {
    local($mediaType, @mediaOptions) = @_;
    local($destSubPath,$destPath);

    # Set the destination path for the file.

    $mediaType=~tr/A-Z/a-z/;
    $destSubPath="$mediaType";

    # Ramdisk is built out of the romdisk at boot time.

    if ( "$mediaType" eq "ramdisk" ) {
	$destSubPath="romdisk/ramdisk";
    }

    # Handle special cases for certain media types.

    if ( "$mediaType" eq "xip" ) {

	# If shipping a "disc dgroup" geode, it goes a level deeper.

	if ( grep(/DDGROUP/, @mediaOptions) ) {
	    $destSubPath .= "/ddgroup";
	}

	# Geodes bound for XIP don't retain their relative path.

	return "$var{desttree}/$destSubPath";

    } elsif ( ( "$mediaType" eq "romdisk" ) || 
	      ( "$mediaType" eq "ramdisk" ) ) {

	# If media type has a _GEOWORKS option on it, send it
	# to a "GEOWORKS" subdirectory.

	if ( grep(/^GEOWORKS$/, @mediaOptions) ) {
	    $destSubPath .= "/geoworks";
	}

    }

    $destPath=&BuildGEOSDestPath("$destSubPath");
    return "$destPath";
}


##############################################################################
#	BuildGEOSDestPath, BuildDOSDestPath
##############################################################################
#
# SYNOPSIS:	Determines the current destination path (as seen by GEOS/DOS)
# PASS:		media subdirectory (optional)
# CALLED BY:	various
# RETURN:	path
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       canavese 	10/14/96   	Initial Revision
#
##############################################################################
sub BuildGEOSDestPath {

    local($mediaDir)=@_;
    local($mainPath);

    $mainPath = join("/", @dirstack);
    if ( "$mainPath" ) {
	$mainPath = "/$mainPath";
    }
    if ( "$mediaDir" ) {
	$mediaDir = "/$mediaDir";
    }
    return "$var{desttree}$mediaDir$mainPath";
}

sub BuildDOSDestPath {
    return &GEOSToDOSPathName(&BuildGEOSDestPath(@_));
}


##############################################################################
#	ChooseMedia
##############################################################################
#
# SYNOPSIS:	Returns the media type to use for the current file
# PASS:		List if directives for current file.
# CALLED BY:	SendFileTree
# RETURN:	media type, 
#               media options (if exist)
#
# STRATEGY:
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#       clee 		9/17/96   	Initial Revision
#       canavese 	10/16/96   	Renamed, made big revision
#
##############################################################################
@validMediaTypes=(XIP,GFS,LANGGFS,RAMDISK,ROMDISK,LOCALPC,SERVER);
@validXIPOptions=(DDGROUP,MAKESTUB);

sub ChooseMedia {

    local(@mediaHierarchy,@options);
    local($mediaType,$baseMediaType,$baseMediaTypeLower, $mediaOptions);
    local($directive, $productDir);
    @_=reverse(@_);

    if ( "$var{mediahierarchy}" ) {
	@mediaHierarchy=split(/ /, "$var{mediahierarchy}"); 
    }

    # Use the first valid media type in the directives.  If one does not 
    # exist, continue looking in the media hierarchy list.

    &DebugPrint(mediaship, "Considering media types: @_ / @mediaHierarchy");

    foreach $directive ( @_, @mediaHierarchy ) {

	# Separate the media type from the product directory (if exists)

	($mediaType, $productDir) = split("=", $directive);

	# Separate the media type into the base and options.

	($baseMediaType, @options)= split(/_/, $mediaType);

	# Add the product directory.

	if ( "$productDir" ) {
	    push(@options, "PRODUCTDIR=$productDir");
	}

	# Check if the media type is valid

	if ( grep(/^$baseMediaType$/, @validMediaTypes) ) {

	    # If media type is not available in this build, try the next one.

	    ($baseMediaTypeLower=$baseMediaType) =~ tr/A-Z/a-z/;
	    if ( ! "$var{$baseMediaTypeLower}" ) {
		&DebugPrint(mediaship, "   $baseMediaType not available in this build.");
		next;
	    }
	
	    # Throw out EC-only or non-EC-only media types if appropriate.
	
	    if ( "$var{ec}" && grep(/^NEC$/, @options)) {
		&DebugPrint(mediaship, "   $baseMediaType not available in EC build.");
		next;
	    }    
	    if ( ! "$var{ec}" && grep(/^EC$/, @options)) {
		&DebugPrint(mediaship, "   $baseMediaType not available in NEC build.");
		next;
	    }

	    # If XIP, check return extra media options

	    if ( "$baseMediaType" eq "XIP" ) {

		foreach $validXIPOption (@validXIPOptions) {
		    @option = grep(/$validXIPOption/, @_);
		    ($option) = @option;
		    push(@options,"$option");
		}
	    }

	    # Return.

	    &DebugPrint(mediaship, "   Using $baseMediaType.\n");

	    return "$baseMediaType", @options;
	}
    }

    return 0;
}


##############################################################################
#	CreateFileStub
##############################################################################
#
# SYNOPSIS:	Turns the specified geode into a file stub. 
# PASS:		ElyomGeode(geode)
#               geode = full path of the geode
# CALLED BY:	(INTERNAL)
# RETURN:	nothing
#
# REVISION HISTORY:
#	Name	Date		Description
#	----	----		-----------
#       clee 	9/18/96   	Initial Revision
#
##############################################################################
sub CreateFileStub {
    local($geode) = @_;
    local($abbrevPath) = $geode;

    if ( $var{reportabbreviatedpaths} ){
	$abbrevPath  = &AbbrevPath($geode);
    }
    print "Stubbing $abbrevPath\n\n";

    if ( &IsWin32 ) {
	$geode =~ tr|/|\\|;	# Dosify the path
    }
    system("elyom", $geode);
}

