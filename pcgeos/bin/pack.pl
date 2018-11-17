#!/usr/public/perl
# -*- perl -*-
##############################################################################
#
# 	Copyright (c) GlobalPC.  All rights reserved.
#
# PROJECT:	
# MODULE:	
# FILE: 	
# AUTHOR: 	
#
# REVISION HISTORY:
#	Name		Date		Description
#	----		----		-----------
#	mzhu	        12/21/98   	Initial Revision
#
# DESCRIPTION:
#
###############################################################################

# parse the command line
# 

while ($_ = shift) {
    if (/^[-\/].$/) {
      SWITCH: {
	  /p/ && do {
	      $pack = 1;
	      !$view or die "Choose either -p or -v\n";
	      $file = shift @ARGV;
	      last SWITCH;
	  };
	  /v/ && do {
	      $view = 1;
	      !$pack or die "Choose either -p or -v\n";
	      $file = shift @ARGV;
	      last SWITCH;
	  };
	  /s/ && do {
	      $size = shift @ARGV;
	      !$zip or die "-s cannot be used with -z\n";
		  die "Wrong size number!\n" unless $size =~ /^[0-9]*$/;
	      last SWITCH;
	  };
	  /n/ && do {
	      $LONGNAME = 1;
	      last SWITCH;
	  };
	  /z/ && do {
	      $zip = 1;
	      !$size or die "-s cannot be used with -z\n";
	      last SWITCH;
	  };
	  &printusage() and die "\nUnknown option $_\n";
      }
    } else {
	&printusage() and die "\nInvalid argument\n";
    }
}

# define number of bytes for later use
&definebytes();

if ($pack) {
    &pack($file, $size);
} elsif ($view) {
    &list($file);
} else {
    &printusage();
}

sub printusage {
    # print the usage
    my $name = $0;
    $name =~ /^.*[\\|\/]([^\\|\/]*)$/;
    print "Usage: $1 [-p listfile [-s size] [-n] [-z]] [-v package]\n";
    print "  -p : Use the given file as the file list to pack.\n";
    print "  -s : The output package file size, for packing use only.\n";
    print "       This might generate multiple files and each of them \n";
    print "       will be equal to or smaller than the give size (kbytes).\n";
    print "  -v : View the infomation on the following package file.\n";
    print "       If there are more than one files, just use the first file name.\n";
    print "  -n : Specify GEOS longnames for the paths in all files.\n";
    print "       (Typically only used for creating an update pack.)\n";
    print "  -z : Compress the package file.  Cannot be used with -s, or client\n";
    print "       software version 1.3 or less.\n";
    return 1;
}


sub definebytes {
    # find out how many bytes for short & long. I am not sure we need it or not.
    local($out) = pack "c16", 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1;
    local($short) = unpack "v", $out;
    local($long) = unpack "V", $out;
    if( 0x0101 == $short ) {
	$SHORT = 2;
    } elsif (0x01010101 == $short) {
	$SHORT = 4;
    } else {
	die "Cannot figure out how many bytes per short!\n";
    }

    if( 0x01010101 == $long ) {
	$LONG = 4;
    } else {
	die "Cannot figure out how many bytes per long!\n";
    }

    $NAME = 256;
    $NOTES = 256;
    $AUTHOR = 128;
    $PATH = 256;
    $PT_GEOS_APPL = 1;
    $PT_DOS_APPL = 2;
    $PT_SYSTEM_UPDATE = 3;
    $PT_MULTI_PAK = 4;
    $PT_GEOS_DATA_FILES = 5;
    $PT_GEOS_FONT = 6;
    $PT_GEOS_PRINT_DRIVER = 7;

    # for signature use
    $SIGNATURE_STR = "GlobalPC";
    $H_V_MAJOR = 1; # hardware version major 
    $H_V_MINOR = 0; # hardware version minor
    if ($zip) {
	# Zipped packages are identified by a software version of 1.3.
	$S_V_MAJOR = 1; # software version major 
	$S_V_MINOR = 3; # software version minor
    } else {
	$S_V_MAJOR = 1; # software version major 
	$S_V_MINOR = 0; # software version minor
    }
}


sub pack {
   
    local($listfile, $disksize) = @_;

    #first we need to search files.list file under current directory
    open LISTFILE, "<$listfile" or die "Cannot find $listfile!";

    $totalsize = 0;

    while(<LISTFILE>) {
	# looking for package name, version, date, and author, etc.

	next if /\#/ || !/\S/; #comment and empty lines

	chop;

#	if(/name\s*=\s*([a-z|0-9]*)/i) {
	if(/name\s*=\s*(.*)/i) {
	    # save the package name
	    $name = $1;
	    print STDOUT "name = $name\n";
	} 
	elsif(/version\s*=\s*(.*)/i) {
	    $_ = $1;
	    print STDOUT "version = $_\n";
	    /([^\.]+)\.([^\.]+)/;
	    $ver_major = $1;
	    $ver_minor = $2;
	}
	elsif(/author\s*=\s*(.*)/i) {
	    $author = $1;
	    print STDOUT "author = $1\n";
	}
	elsif(/system\s*=\s*(.*)/i) {
	    $_ = $1;
	    print STDOUT "system = $_\n";
	    /([^\.]+)\.([^\.]+)/;
	    $sys_major = $1;
	    $sys_minor = $2;
	}
	elsif(/note\s*=\s*(.*)/i) {
	    $note = $1;
	    print STDOUT "note = $1\n";
	}
	elsif(/type\s*=\s*(.*)/i) {
	    $_ = $1;
	    $type = $PT_GEOS_APPL if /GEOS/i;
	    $type = $PT_DOS_APPL if /dos/i;
	    $type = $PT_SYSTEM_UPDATE if /system/i;
	    $type = $PT_MULTI_PAK if /multi[\s-_]*pak/i;
	    $type = $PT_GEOS_DATA_FILES if /geos[\s-_]*data/i;
	    $type = $PT_GEOS_FONT if /font/i;
	    $type = $PT_GEOS_PRINT_DRIVER if /print([\s-_]*driver)?/i;
	    print STDOUT "type = $type\n";
	}
	elsif(/rootdir\s*=\s*(.*)/i) {
	    $rootdir = $1;
	    print STDOUT "rootdir = $1\n";
	}
	elsif(/mainprog\s*=\s*(.*)/i) {
	    $mainprog = $1;
	    print STDOUT "mainprog = $1\n";
	}
	elsif(/readme\s*=\s*(.*)/i) {
	    $readme = $1;
	    print STDOUT "readme = $1\n";
	}
	elsif(/installpath\s*=\s*(.*)/i) {
	    $installpath = $1;
	    print STDOUT "installpath = $1\n";
	}
	elsif(/linkpath\s*=\s*(.*)/i) {
	    $linkpath = $1;
	    print STDOUT "linkpath = $1\n";
	}
	elsif(/inifile\s*=\s*(.*)/i) {
	    $inifile = $1;
	    print STDOUT "inifile = $1\n";
	}
	elsif(/setupGeos\s*=\s*(.*)/i) {
	    $setupgeos = $1;
	    print STDOUT "setupGeos = $1\n";
	} 
	else {

	    # check if the type and name set
	    die "Error! You need to have a name for the package.\n"
		unless defined $name;

#	    die "The wrong type!" unless ($type == $PT_GEOS_APPL ||
#					  $type == $PT_DOS_APPL ||
#					  $type == $PT_SYSTEM_UPDATE);
	    
#	    die "Error! You need to have a main program for the package.\n"
#		unless $type == $PT_SYSTEM_UPDATE || defined $mainprog;
#		unless $type == $PT_SYSTEM_UPDATE;

	    if($type == $PT_GEOS_APPL || $type == $PT_DOS_APPL) {
		die "No main program!" unless defined $mainprog;
	    } elsif ($type == $PT_MULTI_PAK ||
		     $type == $PT_GEOS_PRINT_DRIVER) {
	    } elsif ($type != $PT_SYSTEM_UPDATE) {
		die "No install path" unless defined $installpath;
	    }

	    # change '\' to '/' if there
	    tr/\\/\//;
	    if(/^(.*\/)([^\/]*)$/) {

		$dir = $1;

		# if no file name given, assume it "*.*"
		if(defined $2) {
		    $filepattern = $2; 
		} else { 
		    $filepattern = "\*\.\*"; 
		}

		# check if the path has wildcard
		if($dir =~ /\*/ || $dir =~ /\?/) {
		    $pathpattern = $dir;
		    if($pathpattern =~ /^.*\/.*\/$/) {
			die "Wrong path pattern!\n";
		    }
		    $pathpattern =~ s/^(.*)\/$/$1/;
		    $pathpattern =~ s/\./\\\./s;  # '.' -> "\."
		    $pathpattern =~ s/\*/\.\*/s;  # '*' -> ".*"
		    $pathpattern =~ s/\?/\./s;    # '?' -> '.'
		    $dir = ".";
		} else {
		    $dir =~ s/^\///;
		}

	    } else {
		$dir = ".";
		$filepattern = $_;
	    }

	    # check file name
	    # if it has wild card (* or ?), expand it to all the files
	    $filepattern =~ s/\./\\\./s;  # '.' -> "\."
	    $filepattern =~ s/\*/\.\*/s;  # '*' -> ".*"
	    $filepattern =~ s/\?/\./s;    # '?' -> '.'


	    # all the files go here
	    if(!defined $rootdir) {
		$rootdir = "./";
	    } elsif($rootdir !~ /[\\|\/]$/) {
		$rootdir .= "/";
	    }
	    
	    &find($dir);
	}

    }

    # count all the files
    $totalfiles = $#allfiles + 1;
    print "\n+++ total $totalfiles files $totalsize bytes will be added to the package.\n";
    
    use integer;

    # default we will create one file
    $disknum = 1; 
    if($disksize){
	# but if the command line gives the size, we need to create more than
	# one file.
	$disknum = $totalsize / ($disksize*1024) + 1;
	print "There will be $disknum files generated.\n";
    }
    # the current file we are making
    $cur_dis = 0;

    # now we start to generate the package
    # the file name will be the package name plus ".pak" or ".upd"
    # we use an array to store the output file names
    if ($type == $PT_SYSTEM_UPDATE) {
	$ext = ".upd";
    } else {
	$ext = ".pak";
    }
    for($i=0; $i<$disknum; $i++) {
	$name =~ /^(.{1,6}).*/;
	push @outfiles, "$1$i"."$ext";
    }
    
    print "\nGenerating output file: ", @outfiles[$cur_dis], "\n";

    open OUT, "+>".@outfiles[$cur_dis]
	or die "Cannot create ".@outfiles[$cur_dis]."\n";
    binmode OUT;

    if (!$zip) {
	# file signature
	print OUT $SIGNATURE_STR;
	$out = pack "v4", $H_V_MAJOR, $H_V_MINOR, $S_V_MAJOR, $S_V_MINOR;
	print OUT $out;
    }

    #
    # the disk header first
    #
    $checksum = 0;

    $out = pack "a$NAME", $name;
    print OUT $out;
    $checksum += unpack "%16C*", $out;
    $out = pack "v2", $disknum, $cur_dis;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # put the next file name here, so when we unpack it, it will be easy.
    $out = pack "a$PATH", @outfiles[$cur_dis+1];
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # print the checksum
    $checksum %= 65536;
    $out = pack "v", $checksum;
    print OUT $out;

    print "DH checksum = ", $checksum, "\n";

    $cur_size = $NAME + $PATH + $SHORT * 3;

    # get the date
    ($t, $t, $t, $day, $mon, $year, $t, $t, $t ,$t ) = localtime(time);

    #
    # the package header
    #
    $checksum = 0;

    # name
    $out = pack "a$NAME", $name;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # notes
    $out = pack "a$NOTES", $note;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # author
    $out = pack "a$AUTHOR", $author;
    print OUT $out;
    $checksum += unpack "%16C*", $out;
    
    # main program
    $out = pack "a$PATH", $mainprog;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # readme file
    $out = pack "a$PATH", $readme;
    print OUT $out;
    $checksum += unpack "%16C*", $out;
    
    # install path
    $out = pack "a$PATH", $installpath;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # link path
    $out = pack "a$PATH", $linkpath;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # ini file
    $out = pack "a$PATH", $inifile;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # setupgeos file
    $out = pack "a$PATH", $setupgeos;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    $out = pack "v9", $ver_major, $ver_minor, 
                      $sys_major, $sys_minor,
                      $totalfiles, $type, 
                      $day, $mon, $year;
    print OUT $out;
    $checksum += unpack "%16C*", $out;

    # print the checksum
    $checksum %= 65536;
    $out = pack "v", $checksum;
    print OUT $out;
    print $checksum;


#    print "PH checksum = ", $checksum, "\n";

    $cur_size += $NAME + $NOTES + $AUTHOR + $PATH * 6 + $SHORT * 10;

    #
    # each file start with file header
    #
    foreach $f (@allfiles) {

	$checksum = 0;

	$size = -s "$rootdir$f";
	print STDOUT "coping $rootdir$f ... $size\n";

	# write the file's full name and size
	$out = pack "a$PATH", &convertPaths($f);
	print OUT $out;
	$checksum += unpack "%16C*", $out;

	$out = pack "V", $size;
	print OUT $out;
	$checksum += unpack "%16C*", $out;

	$checksum %= 65536;
	$out = pack "v", $checksum;
	print OUT $out;

#	print "FH checksum = ", $checksum, "\n";

	$cur_size += $PATH + $LONG + $SHORT;

	$checksum = 0;

	# open the file to read and change to binary mode
	open IN, "<$rootdir$f" or die "Cannot open file: $rootdir$f!\n";
	binmode IN;
    
	while(read IN, $buf, 1024) {

	    $cur_size += 1024;
	    if($cur_dis < $disknum-1 && $cur_size > $disksize*1024) {
		# we need to finish this file
		# write the checksum we caculated
		$checksum %= 65536;
		$out = pack "v", $checksum;
		print OUT $out;
		close OUT;

#		print "file checksum = $checksum \n";

		# we need to create the next file
		$cur_dis ++;
		print "Generating output file: ", @outfiles[$cur_dis], "\n";

		open OUT, "+>".@outfiles[$cur_dis] 
		    or die "Cannot create ".@outfiles[$cur_dis]."\n";
		binmode OUT;

		# file signature
		print OUT $SIGNATURE_STR;
		$out = pack "v4", $H_V_MAJOR, $H_V_MINOR, $S_V_MAJOR, $S_V_MINOR;
		print OUT $out;

		# reset the checksum for the new file
		$checksum = 0;

		# disk header

		$out = pack "a$NAME", $name;
		print OUT $out;
		$checksum += unpack "%16C*", $out;

		$out = pack "v2", $disknum, $cur_dis;
		print OUT $out;
		$checksum += unpack "%16C*", $out;

		$out = pack "a$PATH", @outfiles[$cur_dis+1];
		print OUT $out;
		$checksum += unpack "%16C*", $out;

		# print out the checksum
		$checksum %= 65536;
		$out = pack "v", $checksum;
		print OUT $out;

		$cur_size = $NAME + $PATH + $SHORT * 3;

		$checksum = 0;
	    }
		
	    print OUT $buf;
	    $checksum += unpack "%16C*", $buf;
	}

	close IN;

	# write the checksum we caculated
	$checksum %= 65536;
	$out = pack "v", $checksum;
	print OUT $out;

#	print "file checksum = $checksum \n";
    }

    if ($zip) {
	close OUT;
	rename @outfiles[$cur_dis], "out.tmp";

	# Move the temporary file into a temporary zip.
	unlink "outtmp.zip";
	@args = ("pkzip", "-m", "outtmp.zip", "out.tmp", ">nul");
	system(@args) == 0 or die "Error running pkzip: $?\n";

	# Create the final package file.
	open IN, "<outtmp.zip" or die "Cannot open outtmp.zip\n";
	open OUT,  "+>".@outfiles[$cur_dis]
	    or die "Cannot create ".@outfiles[$cur_dis]."\n";
	binmode IN;
	binmode OUT;

	# file signature
	print OUT $SIGNATURE_STR;
	$out = pack "v4", $H_V_MAJOR, $H_V_MINOR, $S_V_MAJOR, $S_V_MINOR;
	print OUT $out;

	while(read IN, $buf, 1024) {
	    print OUT $buf;
	}
	close IN;
	unlink "outtmp.zip";
    }
    close OUT;

    print STDOUT "\n\nDone! \n";

}

sub convertPaths {
    my($path) = @_;
    my($newpath) = "";
    
    # Skip entirely if path has no directories.
    if ($path !~ /\//) {
    	return $path;
    }

    if ($LONGNAME) {
	# Iterate each subdir in the path.
	my($workpath) = "";
	my(@paths) = ($path =~ /.+?\//g);
	my($name) = $';
	foreach (@paths) {
	    $workpath .= $_;
	    
	    # Search our longname cache for the path.
	    my($np) = $PATHCACHE{$workpath};
	    
	    # If we don't get a cache hit, look for @dirname.000.
	    if (!$np) {
		if (open IN, "<$rootdir\/$workpath\@dirname.000") {
		    # Extract the longname from the expected place in the file.
		    binmode IN;
		    # Skip the signature
		    seek IN, 4, 0;
		    # Immediately following is the 32-byte longname
		    read IN, $np, 32;
		    $np =~ s/\0.*$//g;
		    $np .= "/";
		} else {
		    # There is no longname. Get the last dirname in the path.
		    $np = $_;
		}
		# Add the longname to the cache.
		$PATHCACHE{$workpath} = $np;
	    }
	    # Append the name to our newpath.
	    $newpath .= $np;
	}
	# Append the filename to the newpath.
	$newpath .= $name;
	$path = $newpath;
    }
    return $path;
}

sub find {
    my($curdir) = @_;

    opendir DIR, "$rootdir\/$curdir" 
	or die "Cannot open directory: $rootdir\/$curdir!\n";

    # find all the files matched (without "." and "..")
    my(@list) = grep !/^\.\.?$/, readdir DIR;
    closedir DIR;

    if(@list) {
	my($f);
	foreach $f (@list) {

	    next unless -e "$rootdir$curdir\/$f";

	    if(-d "$rootdir$curdir\/$f") {
		
		# this is a subdir
		if(defined $pathpattern) {
		    if($f =~ /$pathpattern/i) {
			&find("$curdir\/$f");
		    }
		}

	    } else {
		if ($f =~ /^$filepattern$/i) {
		    # get the size of the file
		    $totalsize += -s "$rootdir$curdir\/$f";

		    $_ = "$curdir\/$f";

		    # get rid of "./" from the beginning
		    s/^\.\/?//s;
		    s/\\/\//g;
		    s/\/+/\//g;
		    print "curdir $_";

		    # append to allfiles array
		    push @allfiles, $_;
		}
	    }
	}
    }
}

sub list {
    # get the package file
    local $diskname = shift;

    open IN, "<$diskname" or die "Cannot open file: $diskname!\n";
    binmode IN;

    # read the signature first
    read IN, $signature, length $SIGNATURE_STR;
    die "wrong file signature!" unless $signature eq $SIGNATURE_STR;
    read IN, $buf, $SHORT * 4;
    ($hvmajor, $hvminor, $svmajor, $svminor) = unpack "v4", $buf;

    $zip = ($svmajor == 1 && $svminor == 3);

    if ($zip) {
	close IN;

	# Unzip the package to a temporary file.
	@args = ("pkunzip", $diskname, "out.tmp", ">nul");
	system(@args) == 0 or die "Error running pkunzip: $?\n";
	
	# Open the temporary file for reading.
	open IN, "<out.tmp" or die "Cannot open file out.tmp\n";
	binmode IN;
    }

    print "Package hardware version: $hvmajor.$hvminor\n";
    print "Package software version: $svmajor.$svminor\n\n";

    # checksum reset
    $checksum = 0;

    # read the disk header
    read IN, $buf, $NAME;
    $checksum += unpack "%16C*", $buf;
    $name = unpack "A$NAME", $buf;

    read IN, $buf, $SHORT*2;
    $checksum += unpack "%16C*", $buf;
    ($disknum, $cur_disk) = unpack "v2", $buf;

    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $nextfile = unpack "A$PATH", $buf;

    # read checksum
    read IN, $buf, $SHORT;
    $org_checksum = unpack "v", $buf;

    die "Wrong disk order!\n" if $cur_disk != 0;
    die "Wrong disk number!\n" if $disknum == 0;

    # check checksum
    $checksum %= 65536;
    if($checksum != $org_checksum) {
	print "Wrong checksum for DH org = $org_checksum, new = $checksum \n";
    }

    # checksum reset
    $checksum = 0;

    # read package header

    read IN, $buf, $NAME;
    $checksum += unpack "%16C*", $buf;
    die "The names are not match!\n" if $name ne (unpack "A$NAME", $buf);

    read IN, $buf, $NOTES;
    $checksum += unpack "%16C*", $buf;
    $notes = unpack "A$NOTES", $buf;
    read IN, $buf, $AUTHOR;
    $checksum += unpack "%16C*", $buf;
    $author = unpack "A$AUTHOR", $buf;
    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $mainprog = unpack "A$PATH", $buf;
    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $readme = unpack "A$PATH", $buf;
    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $installpath = unpack "A$PATH", $buf;
    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $linkpath = unpack "A$PATH", $buf;
    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $inifile = unpack "A$PATH", $buf;
    read IN, $buf, $PATH;
    $checksum += unpack "%16C*", $buf;
    $setupgeos = unpack "A$PATH", $buf;
    read IN, $buf, $SHORT * 9;
    $checksum += unpack "%16C*", $buf;
    ($ver_major, $ver_minor, $sys_major, $sys_minor, $totalfiles, 
     $type, $day, $mon, $year) = unpack "v9", $buf;

    read IN, $buf, $SHORT;
    $org_checksum = unpack "v", $buf;

    # check checksum
    $checksum %= 65536;
    if($checksum != $org_checksum) {
	print "Wrong checksum for PH, org = $org_checksum, new = $checksum \n";
    }

    print "name = $name\n";
    print "type = $type\n";
    print "version = $ver_major\.$ver_minor\n";
    print "author = $author\n";
    print "system = $sys_major\.$sys_minor\n";
    print "mainprog = $mainprog\n";
    print "readme = $readme\n";
    print "installpath = $installpath\n";
    print "linkpath = $linkpath\n";
    print "inifile = $inifile\n";
    print "setupGeos = $setupgeos\n";
    print "note = $notes\n";
    $mon ++;
    print "date = $mon\/$day\/$year\n";
    print "\ntotal $totalfiles files and in $disknum disks(files).\n\n";

    print "disk $cur_disk ...\n";

    while(read IN, $buf, $PATH) {

	$checksum = unpack "%16C*", $buf;
	$file = unpack "A$PATH", $buf;
	print "file: $file ";

	read IN, $buf, $LONG;
	$checksum += unpack "%16C*", $buf;
	$len = unpack "V", $buf;

	print $len, "\n";

	read IN, $buf, $SHORT;
	$org_checksum = unpack "v", $buf;

	# check checksum
	$checksum %= 65536;
	if($checksum != $org_checksum) {
	    print "Wrong checksum for FH, org = $org_checksum, new = $checksum \n";
	}

READFILE:
	$checksum = 0;

	while($size = read IN, $buf, $len) {
	    $len -= $size;
	    if(eof IN != 1) {
		$checksum += unpack "%16C*", $buf;
	    } else {
		$len += $SHORT;
		$size -= $SHORT;
		$checksum += unpack "%16C$size", $buf;
		$org_checksum = unpack "v", substr($buf, $size);

		# check checksum
		$checksum %= 65536;
		if($checksum != $org_checksum) {
		    print "Wrong checksum for file, org = $org_checksum, new = $checksum \n";
		}
	    }
	}

	die "File size is wrong!\n" if $len > 0 && 1 != eof IN;

	if($len > 0) {

	    # this file not end yet!
	    die "Wrong disk number!\n" unless $cur_disk < $disknum;

	    close IN;

	    # go to next file
	    $diskname = $nextfile;

	    open IN, "<$diskname" or die "Cannot open file: $diskname!\n";
	    binmode IN;

	    read IN, $signature, length $SIGNATURE_STR;
	    die "wrong file signature!" unless $signature eq $SIGNATURE_STR;
	    read IN, $buf, $SHORT * 4;
	    ($hvmajor, $hvminor, $svmajor, $svminor) = unpack "v4", $buf;
	    die "wrong version of package format!" 
		unless ($hvmajor == $H_V_MAJOR && $hvminor == $H_V_MINOR &&
			$svmajor == $S_V_MAJOR && $svminor == $S_V_MINOR);

	    $checksum = 0;

	    # read the disk header
	    read IN, $buf, $NAME;
	    $checksum += unpack "%16C*", $buf;
	    $name = unpack "A$NAME", $buf;
	    die "Wrong package name: $buf\n" if $name ne (unpack "A$NAME", $buf);

	    read IN, $buf, $SHORT*2;
	    $checksum += unpack "%16C*", $buf;
	    ($dn, $cd) = unpack "v2", $buf;

	    die "Wrong disk order: $cd!\n" if $cd != $cur_disk + 1;
	    die "Wrong disk number: $dn!\n" if $dn != $disknum;

	    read IN, $buf, $PATH;
	    $checksum += unpack "%16C*", $buf;
	    $nextfile = unpack "A$PATH", $buf;

	    # read checksum
	    read IN, $buf, $SHORT;
	    $org_checksum = unpack "v", $buf;

	    $cur_disk ++;
	    print "disk $cur_disk ... $diskname\n";

	    goto READFILE;
	}

	read IN, $buf, $SHORT;
	$org_checksum = unpack "v", $buf;

	# check checksum
	$checksum %= 65536;
	if($checksum != $org_checksum) {
	    print "Wrong checksum for file, org = $org_checksum, new = $checksum \n";
	}

    }

    close IN;

    unlink "out.tmp" if $zip;
}
