###################################################################
#
#  Copyright(c) GlobalPC 1999.  
#
#  Project:     System Update
#  Module:
#  File:        makeupd
#
#  Revision History:
#       Name            Date           Description
#       -----------------------------------------------
#       jonl            12/14/99       Initial Creation
#         jonl          04/28/00           1. Added code so that net.ini is always included in the update
#                                                  2. Added workarounds for DOS/GEOS name conflicts
#                                                  3. Minor changes to reflect current path conventions
#       dhunter         09/18/00       Added curVerNum to notes field
#
#         paul n                11/14/00           Added a section to allow the chgini stuff to be
#                                                       included automatically.  Also to allow creation
#									  of zipped updates (provided PKZIP.EXE is in the path)
#
#  Description:
#       Gets the name of two builds from a user (must be in
#       same directory) and then calls buildupd.pl to compare
#       the two trees.
#
#       Original impetis for creating this file was remembering
#       file argument order, options, and changing path info
#       was a pain in the posterior
#
#         This script also has routines for copying the UPD file over to
#         a machine on the intranet and updating a web page for 
#         testing.  It is currently configured for the GPC machine.
#
#  Usage:
#       perl makeupd.pl
###################################################################

$path = "d:/SysUpd/";

# Variables for calls to &traverse
my $nGeo = 0;
my $n000 = 0;
my $nfiles = 0;

# make sure the following vars are global...
$newbuild="\0";
$oldbuild="\0";
$fname="\0";
$copyupd="\0";
$updhtm="\0";
$inifile1="\0";
$inifile2="\0";
$zipped="\0";

print "***Welcome to System Update builder! ***\n";
print;

&GetInfo;
&BuildUpd;
#&CopyUpd;
#&UpdateHTML;

############################################################
#GetInfo:
#       Gets the names of the 2 builds to compare and verifies
#       the builds exist.  Also gets all other user info
#
############################################################

sub GetInfo{
	print "New build name: > ";
	$newbuild = <STDIN>;
	chop($newbuild);

	unless (opendir(NEWDIR, $newbuild)) {
		warn "\n******* Can't find $newbuild *********\n";
		closedir(NEWDIR);
		exit;
	}

	# need to append the geos2000 dirname so it doesn't get included in the ZIP

	print "Old build name: > ";
	$oldbuild = <STDIN>;
	chop($oldbuild);

	unless (opendir(OLDDIR, $oldbuild)) {
		warn "\n******* Can't find $oldbuild *********\n";
		closedir(OLDDIR);
		exit;
	}

	#  make sure the files inputted exist....

	closedir(NEWDIR);
	closedir(OLDDIR);

#       if including change to geos.ini get name of chgini file
	
	print "\nDo you wish to change geos.ini in the updated system? (y/n) >";
	$inifile1 = <STDIN>;
	chop $inifile1;
	if ($inifile1 eq "y"){
		print "\n What is the name of the text file with the changes? >";
		$inifile2 = <STDIN>;

#               It would be good to put something in to check the chgini file exists here!
		$inipath = $newbuild."\\geos2000\\".$inifile2;
		chop $inipath;

		unless (open(INI, $inipath)) {
			warn "\n******* Can't find $inipath *********\n";
			close(INI);
			exit;
		}
       
	       
		
	}

#       Adding possibility of zipped update

	print "\nDo you want the update to be compressed? (y/n) >";
	$zipped = <STDIN>;
	chop $zipped;

}




#####################################################################
#BuildUpd:
#       takes the build names obtained from GetInfo() and calls:
#               buildupd.pl
#               pack.pl
#       to create the update file.  Update file is then renamed to
#       reflect the update path.
#
#       Default value of Name in new.list is altered to reflect a new
#       unique value so as not to conflict with prior installs
#####################################################################

sub BuildUpd {

# Check that the version string will make a valid DOS 8.3 name.
# Currently we are using the version string as the name of the system root.
	
	$_ = $newbuild;
	s/^[^0-9.][^0-9.]*//g;
	$Version = "Version = ".$_;

	($major, $minor) = split /\./;
	if (!(/\./) or (length($major) == 0 or length($major) > 8)
	    or (length($minor) == 0 or length($minor) > 3)) {
	    warn "\n\"$_\" is not a valid DOS 8.3 name and cannot be used as the version.\n";
	    exit;
	}

# generate new.list file 
       system "buildupd.pl", "$newbuild/geos2000", "$oldbuild/geos2000";


# Need to modify new.list so the default Name = geos2001 isn't used.
	unless (open(LST, "new.list")) {
		warn "\nUnable to find new.list...";
		close(LST);
		exit;
	}

# Use a temp file to store intermediate changes
	unless (open(TMP, ">newlist")) {
		warn "\nUnable to create temp file...";
		close(TMP);
		exit;
	}

	$DirName = "Name = ".$newbuild;


#       &getDeltaFiles;
	$note = "note = newFiles=".$retval[0]."; curVerNum=".$oldbuild;

	$chgfile = "inifile = ".$inifile2;
	while (<LST>) {
		s/^Name = ..*$/$DirName/;
		s/^Version = ..*$/$Version/;
		s/^note = ..*$/$note/;
			if ($inifile1 eq "y"){
				s/(^..*add files here)/$chgfile$1/;
			}
		print TMP;
	}

	close(LST);
	close(TMP);

	system "erase", "new.list";
	rename("newlist", "new.list");

# take the now modified new.list file and generate the update
# -n causes pack.pl to write pathnames using GEOS longname directories
# -z causes pack.pl to compress the pack file

	if ($zipped eq "y"){
		system "pack.pl", "-p", "new.list", "-n", "-z";
	}
	else {
		system "pack.pl", "-p", "new.list", "-n";
	}


	# first build the filename to be used for the update....
	$_ = $newbuild;

# remove all but numbers... for some reason, '.' slips thru...
	s/^[^0-9][^0-9]*//g;

# remove '.'......
#       s/\.//g;

	$fname = $_;

	$_ = $oldbuild;
	s/^[^0-9][^0-9]*//g;
#       s/\.//g;
	$fname = $_."_to_".$fname.".upd";

# Need to add a "0" to account for pack.pl's PAK numbering scheme
	$DefaultUPD = $newbuild."0".".upd";

#now rename the update file to reflect the builds...
	rename("$DefaultUPD", "$fname");
}


#####################################################################
#CopyUpd:
#       Takes the new UPD file and places it on gpc.globalpc.com
#       currently this has to then be moved to the location expected by
#         the portal Java code
#####################################################################

sub CopyUpd {
	print "Copy the update to gpc.globalpc.com/systemupdate/ ? (y/n) >";
	$copyupd = <STDIN>;

	if ($copyupd = "y") {
		system "xcopy", "/z", "/R", "$fname", "\\\\gpc\\webdocs\\systemupdate\\";
	}


}



#####################################################################
#UpdateHTML:
#       This routine will probably go away eventually.  Its purpose is
#       to dynamically update a web page to sysupdate automation
#####################################################################

sub UpdateHTML {
	#Update the systemupdate.html file to incorporate the new update...
	print "Update gpc.globalpc.com/systemupdate/systemupdate.html ? (y/n) >";
	$updhtml = <STDIN>;
	chop $updhtml;

	if ($updhtml eq "y") {

	
		$localpath="\\\\gpc\\webdocs\\systemupdate\\";
		$updtotal = $localpath."systemupdate.html";
		$tmptotal = $localpath."ztempz.html";
	
		unless (open(UPD, "$updtotal")) {
			warn "\nUnable to find systemupdate.html...";
			close(UPD);
			exit;
		}
	
		unless (open(TMP, ">$tmptotal")) {
			warn "\nUnable to create temp file...";
			close(TMP);
			exit;
		}
	
		$_ = $fname;
		s/\.upd$//;
		$corefname = $_;
	
		$AddLine = "<P ALIGN=\"center\"><A HREF=\"$fname\">$corefname</A></P>";
	
		while (<UPD>) {
			s/(^..*A MARKER FOR INSERTION..*$)/$1\n$AddLine/;
			print TMP;
		}
	
		close(TMP);
		close(UPD);

		system "erase", "$updtotal";
		rename($tmptotal, $updtotal);
	}

}




####################################################################################
# Description:
#       Just a quick and dirty file to take a look at file stats.  Recursively 
#       traverses two directory structures and returns a difference in the number
#       of files.
####################################################################################

sub getDeltaFiles {

	&traverse("d:/sysupd/$oldbuild/geos2000");

	print "\n\n", "*****************  Totals:  *******************\n";
	print "Total files:    ", $retval[0], "\n";
	print "GEOS files:     ", $retval[1], "\n";
	print ".000 files:     ", $retval[2], "\n";

	$oldtotal = $retval[0];


	$nfiles = 0;
	$nGeo = 0;
	$n000 = 0;

	&traverse("d:/systemupdate/$newbuild/geos2000");

	print "Total files:    ", $retval[0], "\n";
	print "GEOS files:     ", $retval[1], "\n";
	print ".000 files:     ", $retval[2], "\n";

	print;

	my $filedelta = $retval[0] - $oldtotal;

	if ($filedelta < 0) {
		print "Change in file count = 0  (real count was negative)\n";
		$filedelta = 0;
	} else {
		print "Change in file count = ", $filedelta, "\n";
	}

	@retval = ($filedelta);
}
# ***********************************************


sub traverse {
	local($dir) = shift;
	local($path);

	unless (opendir(DIR, $dir)) {
		warn "Can't open $dir\n";
		closedir(DIR);
		return;
	}

	foreach (readdir(DIR)) {
		next if $_ eq "." || $_ eq "..";
		$path = "$dir/$_";

		if (-d $path) {
			&traverse($path);
		} elsif (-f _) {
			$nfiles += 1;
			if (length($_) > 4) {
				if (/....$/ eq /\.000/) {
					$n000 += 1;
				} elsif (/....$/ eq /\.geo/) {
					$nGeo += 1;
				}
			}
			print "$path";
			&AddSpace($path);
#                       &FileInfo($path);
		}
	}
	closedir(DIR);
	@retval = ($nfiles, $nGeo, $n000);
}





# ***********************************************

sub FileInfo {
# Commented out to avoid errors finding 'stat'
#        local($fname) = @_;
#
#      use FILE::stat;
#        require 'ctime.pl';
#        
#      $date_string = ctime((stat($fname))[9]);
#      print $date_string, "\n";
#        return;
}

# ***********************************************

my $c = 0;
sub AddSpace {
	local($string) = @_;
	$l = length($string);

	if (int($c/2) == $c/2) {
		$char = " ";
	} else {
		$char = "-";
	}

	while ($l < 80) {
		$l++;
		print $char;
	}
	$c++;
	return;
}



