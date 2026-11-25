#!/usr/bin/perl
##############################################################################
#
# PROJECT:	PC GEOS
# MODULE:	86Box target support
# FILE: 	box86.pl
#
# DESCRIPTION:
#	Runs the composed PC/GEOS target in 86Box instead of DOSBox/basebox
#	and connects swat over the emulated serial port.
#
#	  box86.pl image  [-n] [--fresh] [--destdir DIR]
#		create or update the bootable disk image of the target
#	  box86.pl config [-n]
#		write the 86Box machine configuration
#	  box86.pl run    [-n]
#		update image and configuration, start 86Box, start swat
#	  box86.pl freedos
#		fetch and verify the FreeDOS files (if FREEDOS_IMG is unset)
#
#	-n selects the non-EC target, as for "target".
#
#	Environment:
#	  ROOT_DIR, LOCAL_ROOT  as for the rest of the SDK (required)
#	  TARGET                gbuild target (default nt)
#	  TARGET_PLATFORM       rm16, pm16 or pm32 (default pm32)
#	  USE_86BOX             86Box executable, absolute path (like BASEBOX);
#	                        a value like 1/yes/on uses 86Box from the PATH
#	  BOX86_ROMS            86Box ROM directory (passed with --rompath)
#	  BOX86_PORT            TCP port for swat on Linux (default 8079)
#	  BOX86_KEEP_CFG        keep an existing 86box.cfg (no regeneration)
#	  BOX86_NOSWAT          "run" starts 86Box only, without swat
#	  FREEDOS_IMG           bootable FreeDOS hard disk image to use
#	  FREEDOS_SYSDIR        directory with FreeDOS files that take
#	                        precedence (KERNEL.SYS, COMMAND.COM, ...)
#	  GEOS_IMG_SIZE         size of a new disk image in MB
#	  GEOS_CDROM_DRIVE      ISO image attached as CD-ROM (drive R:)
#
###############################################################################
use strict;
use warnings;
use File::Path qw(mkpath);
use File::Copy;
use File::Basename;
use Cwd qw(abs_path);
use Digest::SHA;

$| = 1;				# keep output in order with child processes
my $IS_WIN = ($^O eq "MSWin32" || $^O eq "cygwin" || $^O eq "msys");
my @PLATFORMS = qw(rm16 pm16 pm32);
my $HEADS = 16;
my $SECTORS = 63;

##############################################################################
#	Command line and environment
##############################################################################
my $cmd = shift(@ARGV) || "";
my $ec = 1;
my $fresh = 0;
my $destdirArg;
while (@ARGV) {
    my $a = shift(@ARGV);
    if ($a eq "-n") {
	$ec = 0;
    } elsif ($a eq "--fresh") {
	$fresh = 1;
    } elsif ($a eq "--destdir") {
	$destdirArg = shift(@ARGV);
    } elsif ($a eq "--ec") {
	$ec = (shift(@ARGV) =~ /^(y|yes|1|true|ec)$/i) ? 1 : 0;
    } elsif ($a eq "") {
	# empty argument from target.cmd
    } else {
	Usage("unknown option $a");
    }
}
Usage() if ($cmd !~ /^(image|config|run|freedos)$/);

my $ROOT = $ENV{ROOT_DIR} || die "box86: ROOT_DIR must be set\n";
my $LOCAL = $ENV{LOCAL_ROOT} || die "box86: LOCAL_ROOT must be set\n";
$ROOT =~ s|\\|/|g;
$LOCAL =~ s|\\|/|g;
my $TARGET = $ENV{TARGET} || "nt";
my $TYPE = $ec ? "ec" : "nec";
my $PLATFORM = $ENV{TARGET_PLATFORM} || "pm32";
if (!grep { $_ eq $PLATFORM } @PLATFORMS) {
    die "box86: TARGET_PLATFORM must be one of @PLATFORMS (is $PLATFORM)\n";
}
my $VMDIR = "$LOCAL/86box/$PLATFORM.$TYPE";
my $IMAGE = "$VMDIR/geos.img";
my $CFGDIR = "$ROOT/bin/86box";

sub Usage {
    my ($msg) = @_;
    print STDERR "box86: $msg\n" if ($msg);
    print STDERR "usage: box86.pl image|config|run|freedos [-n] [--fresh]\n";
    exit(1);
}

my $LOGFH;

sub Info {
    print "[86Box] @_\n";
    print $LOGFH "[86Box] @_\n" if ($LOGFH);
}

#
# swat clears the screen, so the output of "run" is also kept in
# <vm>/box86.log; errors are written there too.
#
sub OpenRunLog {
    mkpath($VMDIR);
    open($LOGFH, ">", "$VMDIR/box86.log") || return;
    my $old = select($LOGFH); $| = 1; select($old);
    $SIG{__DIE__} = sub { print $LOGFH $_[0] if ($LOGFH); };
    $SIG{__WARN__} = sub { print STDERR $_[0]; print $LOGFH $_[0] if ($LOGFH); };
}

##############################################################################
#	Target location
##############################################################################
sub DestDir {
    return $destdirArg if (defined($destdirArg));

    my $cache = "$LOCAL/.bbxxip/.bbxxip.$TARGET.$TYPE";
    open(my $fh, "<", $cache) ||
	die "box86: *** Target type $TYPE not built ($cache missing).\n";
    my $destdir;
    while (<$fh>) {
	s/[\r\n]+$//;
	$destdir = $1 if (/^destdir=(.*)$/);
    }
    close($fh);
    die "box86: no destdir in $cache\n" if (!$destdir);
    $destdir =~ s|\\|/|g;
    return $destdir;
}

sub TreeDir {
    my $destdir = DestDir();
    my $tree = "$destdir/localpc";
    if (! -f "$tree/ENSEMBLE/ENSEMBLE.BAT" && ! -f "$tree/ENSEMBLE/SETUP.BAT" &&
	! -f "$tree/ensemble/ensemble.bat" && ! -f "$tree/ensemble/setup.bat") {
	die "box86: *** Target at $destdir not usable.\n";
    }
    return $tree;
}

##############################################################################
#	Configuration layers
##############################################################################
# A configuration is a list of [section, [[key, value], ...]] in file order.

sub ReadIni {
    my ($file, $cfg) = @_;
    open(my $fh, "<", $file) || die "box86: cannot read $file\n";
    my $section;
    while (my $line = <$fh>) {
	$line =~ s/[\r\n]+$//;
	next if ($line =~ /^\s*([#;].*)?$/);
	if ($line =~ /^\s*\[(.+)\]\s*$/) {
	    $section = IniSection($cfg, $1);
	} elsif ($line =~ /^\s*([^=]+?)\s*=\s*(.*?)\s*$/) {
	    die "box86: $file: key outside section: $line\n" if (!$section);
	    IniSet($section, $1, $2);
	} else {
	    die "box86: $file: cannot parse: $line\n";
	}
    }
    close($fh);
}

sub IniSection {
    my ($cfg, $name) = @_;
    foreach my $s (@$cfg) {
	return $s if (lc($s->[0]) eq lc($name));
    }
    my $s = [$name, []];
    push(@$cfg, $s);
    return $s;
}

sub IniSet {
    my ($section, $key, $value) = @_;
    # "ini" entries of [img86box] accumulate, everything else is replaced
    if (!(lc($section->[0]) eq "img86box" && $key eq "ini")) {
	foreach my $kv (@{$section->[1]}) {
	    if (lc($kv->[0]) eq lc($key)) {
		$kv->[1] = $value;
		return;
	    }
	}
    }
    push(@{$section->[1]}, [$key, $value]);
}

sub IniGet {
    my ($cfg, $section, $key) = @_;
    my @values;
    foreach my $s (@$cfg) {
	next if (lc($s->[0]) ne lc($section));
	foreach my $kv (@{$s->[1]}) {
	    push(@values, $kv->[1]) if (lc($kv->[0]) eq lc($key));
	}
    }
    return wantarray ? @values : $values[$#values];
}

sub LoadLayers {
    my @layers = ("$CFGDIR/base.cfg", "$CFGDIR/platform/$PLATFORM.cfg",
		  $IS_WIN ? "$CFGDIR/serial-win32.cfg" :
			    "$CFGDIR/serial-linux.cfg");
    if (CdromImage()) {
	push(@layers, "$CFGDIR/cdrom.cfg");
    }
    foreach my $user ("$LOCAL/86box_user.cfg",
		      "$LOCAL/86box_user.$PLATFORM.cfg") {
	push(@layers, $user) if (-f $user);
    }
    my $cfg = [];
    foreach my $layer (@layers) {
	ReadIni($layer, $cfg);
    }
    return $cfg;
}

sub CdromImage {
    my $cd = $ENV{GEOS_CDROM_DRIVE};
    return undef if (!$cd);
    if (-f $cd) {
	my $abs = abs_path($cd);
	$abs =~ s|\\|/|g if ($abs);
	return $abs;
    }
    return undef;
}

sub Expand {
    my ($value, $vars) = @_;
    $value =~ s/\@([A-Z]+)\@/defined($vars->{$1}) ? $vars->{$1} : "\@$1\@"/ge;
    return $value;
}

sub PipeName {
    return "\\\\.\\pipe\\geosswat-$PLATFORM-$TYPE";
}

sub TcpPort {
    return $ENV{BOX86_PORT} || 8079;
}

sub ImageCylinders {
    my $size = -s $IMAGE;
    die "box86: no disk image $IMAGE (run \"box86.pl image\" first)\n"
	if (!$size);
    return int($size / ($HEADS * $SECTORS * 512));
}

sub WriteConfig {
    my ($cfg) = @_;
    my $out = "$VMDIR/86box.cfg";

    if ($ENV{BOX86_KEEP_CFG} && -f $out) {
	Info("keeping $out (BOX86_KEEP_CFG)");
	return;
    }
    my $image = $IMAGE;
    $image =~ s|/|\\|g if ($IS_WIN);
    my %vars = (IMAGE => $image,
		CYLS => ImageCylinders(),
		PIPE => PipeName(),
		PORT => TcpPort(),
		CDROM => CdromImage() || "",
		EC => $ec ? "ec" : "");
    mkpath($VMDIR);
    open(my $fh, ">", "$out.tmp") || die "box86: cannot write $out\n";
    print $fh "# Generated by bin/box86.pl from bin/86box/*.cfg and " .
	"\$LOCAL_ROOT/86box_user*.cfg.\n# Changes are overwritten on the " .
	"next start unless BOX86_KEEP_CFG is set.\n\n";
    foreach my $s (@$cfg) {
	next if (lc($s->[0]) eq "img86box");
	print $fh "[$s->[0]]\n";
	foreach my $kv (@{$s->[1]}) {
	    print $fh "$kv->[0] = " . Expand($kv->[1], \%vars) . "\n";
	}
	print $fh "\n";
    }
    close($fh);
    rename("$out.tmp", $out) || die "box86: cannot write $out\n";
    Info("machine configuration $out");
}

##############################################################################
#	FreeDOS
##############################################################################
sub ReadManifest {
    my %entries;
    foreach my $file ("$CFGDIR/freedos.manifest",
		      "$LOCAL/86box/freedos.manifest") {
	next if (! -f $file);
	open(my $fh, "<", $file) || die "box86: cannot read $file\n";
	while (<$fh>) {
	    s/[\r\n]+$//;
	    next if (/^\s*(#.*)?$/);
	    my ($name, $sha, $url, $member) = split(" ", $_);
	    die "box86: $file: bad line: $_\n" if (!defined($member));
	    $entries{$name} = { sha => lc($sha), url => $url,
				member => $member };
	}
	close($fh);
    }
    return \%entries;
}

sub Sha256File {
    my ($file) = @_;
    return Digest::SHA->new(256)->addfile($file, "b")->hexdigest;
}

sub Download {
    my ($url, $dest) = @_;

    die "box86: only https:// downloads are allowed ($url)\n"
	if ($url !~ m{^https://});
    my $tmp = "$dest.part";
    my $ok = 0;
    if (eval { require HTTP::Tiny; 1 } && HTTP::Tiny->can_ssl()) {
	Info("downloading $url");
	my $http = HTTP::Tiny->new(verify_SSL => 1, timeout => 120);
	my $res = $http->mirror($url, $tmp);
	if ($res->{success}) {
	    $ok = 1;
	} else {
	    unlink($tmp);
	    die "box86: download of $url failed: $res->{status} $res->{reason}\n";
	}
    } else {
	# fall back to curl, which verifies TLS by default
	Info("downloading $url (curl)");
	unlink($tmp);
	my $rc = system("curl", "-fsSL", "--proto", "=https", "--tlsv1.2",
			"-o", $tmp, $url);
	if ($rc != 0) {
	    unlink($tmp);
	    die "box86: cannot download $url\n" .
		($rc == -1 ? "  curl not found: install curl, or IO::Socket::SSL" .
			     " and Net::SSLeay for Perl\n"
			   : "  curl failed (exit code " . ($rc >> 8) . ")\n") .
		"  (or set FREEDOS_IMG to a bootable FreeDOS hard disk image)\n";
	}
	$ok = 1;
    }
    rename($tmp, $dest) || die "box86: cannot rename $tmp\n";
}

#
# Fetch one manifest entry; returns the path of the verified download.
#
sub FetchVerified {
    my ($entry, $dest) = @_;

    if (-f $dest && $entry->{sha} ne "-" &&
	Sha256File($dest) eq $entry->{sha}) {
	return $dest;
    }
    Download($entry->{url}, $dest);
    my $got = Sha256File($dest);
    if ($entry->{sha} eq "-") {
	die "box86: no checksum pinned for $entry->{url}\n" .
	    "  downloaded file: $dest\n" .
	    "  its SHA-256:     $got\n" .
	    "Verify this value against the publisher's checksum list and add\n" .
	    "it to $LOCAL/86box/freedos.manifest, e.g.\n" .
	    "  image $got $entry->{url} $entry->{member}\n";
    }
    if ($got ne $entry->{sha}) {
	unlink($dest);
	die "box86: checksum mismatch for $entry->{url}\n" .
	    "  expected $entry->{sha}\n  got      $got\n";
    }
    return $dest;
}

sub ExtractMember {
    my ($zip, $pattern, $dest) = @_;
    require IO::Uncompress::Unzip;

    my $re = quotemeta($pattern);
    $re =~ s/\\\*/.*/g;
    my $u = IO::Uncompress::Unzip->new($zip) ||
	die "box86: cannot open $zip\n";
    my $status = 1;
    while ($status > 0) {
	my $name = $u->getHeaderInfo()->{Name};
	if ($name =~ /^$re$/i || basename($name) =~ /^$re$/i) {
	    open(my $out, ">", "$dest.part") || die "box86: cannot write $dest\n";
	    binmode($out);
	    my $buf;
	    my $n;
	    while (($n = $u->read($buf)) > 0) {
		print $out $buf;
	    }
	    close($out);
	    die "box86: error extracting $name from $zip\n" if ($n < 0);
	    rename("$dest.part", $dest) || die "box86: cannot write $dest\n";
	    $u->close();
	    return $dest;
	}
	$status = $u->nextStream();
    }
    die "box86: $pattern not found in $zip\n";
}

#
# Returns (image, sysdir) for img86box -f / -S.
#
sub FreeDos {
    my $sysdirEnv = $ENV{FREEDOS_SYSDIR};
    my $dir = "$LOCAL/86box/freedos";
    my $sysdir = "$dir/sys";
    mkpath($sysdir);

    if ($ENV{FREEDOS_IMG}) {
	die "box86: FREEDOS_IMG=$ENV{FREEDOS_IMG} not found\n"
	    if (! -f $ENV{FREEDOS_IMG});
	CopySysDir($sysdirEnv, $sysdir);
	return ($ENV{FREEDOS_IMG}, $sysdir);
    }
    my $m = ReadManifest();
    foreach my $need (qw(kernel command image)) {
	die "box86: freedos.manifest has no \"$need\" entry\n"
	    if (!$m->{$need});
    }
    my $kzip = FetchVerified($m->{kernel}, "$dir/" . basename($m->{kernel}{url}));
    ExtractMember($kzip, $m->{kernel}{member}, "$sysdir/KERNEL.SYS")
	if (! -f "$sysdir/KERNEL.SYS" || -M "$sysdir/KERNEL.SYS" > -M $kzip);
    my $czip = FetchVerified($m->{command}, "$dir/" . basename($m->{command}{url}));
    ExtractMember($czip, $m->{command}{member}, "$sysdir/COMMAND.COM")
	if (! -f "$sysdir/COMMAND.COM" || -M "$sysdir/COMMAND.COM" > -M $czip);
    my $izip = FetchVerified($m->{image}, "$dir/" . basename($m->{image}{url}));
    my $img = "$dir/freedos.img";
    ExtractMember($izip, $m->{image}{member}, $img)
	if (! -f $img || -M $img > -M $izip);

    # files in FREEDOS_SYSDIR win over the downloaded ones
    CopySysDir($sysdirEnv, $sysdir);
    return ($img, $sysdir);
}

sub CopySysDir {
    my ($from, $to) = @_;
    return if (!$from || ! -d $from);
    opendir(my $dh, $from);
    foreach my $f (readdir($dh)) {
	copy("$from/$f", "$to/" . uc($f)) if (-f "$from/$f");
    }
    closedir($dh);
}

#
# FreeDOS images like LiteUSB carry most programs only as package
# archives (e.g. PACKAGES\BASE\CTMOUSE.ZIP). Unpack the drivers the image
# configuration needs into the FreeDOS file directory, unless they are
# there already. The packages come from the (checksum verified) image.
#
my %DRIVER_PACKAGES = (
    "CTMOUSE.EXE" => ["CTMOUSE.ZIP"],
    "HIMEMX.EXE"  => ["HIMEMX.ZIP", "JEMM.ZIP"],
    "UDVD2.SYS"   => ["UDVD2.ZIP"],
    "SHSUCDX.COM" => ["SHSUCDX.ZIP"],
);

sub ExtractDrivers {
    my ($img, $sysdir, @files) = @_;
    my $tmp = "$LOCAL/86box/freedos/pkg";
    mkpath($tmp);
    FILE: foreach my $file (@files) {
	next if (!$file || -f "$sysdir/" . uc($file));
	my $base = uc($file);
	$base =~ s/\.[^.]*$//;
	# unpacked somewhere in the image?
	if (system(Tool("img86box"), "-f", $img, "--get",
		   uc($file) . "=$sysdir/" . uc($file)) == 0) {
	    next FILE;
	}
	unlink("$sysdir/" . uc($file));
	my @pkgs = @{$DRIVER_PACKAGES{uc($file)} || []};
	push(@pkgs, "$base.ZIP") if (!grep { $_ eq "$base.ZIP" } @pkgs);
	foreach my $pkg (@pkgs) {
	    my $zip = "$tmp/" . lc($pkg);
	    if (! -f $zip) {
		my $rc = system(Tool("img86box"), "-f", $img, "--get",
				"$pkg=$zip");
		next if ($rc != 0 || ! -f $zip);
	    }
	    if (eval { ExtractMember($zip, uc($file), "$sysdir/" . uc($file));
		       1 }) {
		Info("$file unpacked from package $pkg");
		next FILE;
	    }
	}
	print STDERR "box86: warning: $file not found in the FreeDOS image" .
	    " or its packages (put it into FREEDOS_SYSDIR)\n";
    }
}

##############################################################################
#	Disk image
##############################################################################
sub Tool {
    my ($name) = @_;
    foreach my $cand ("$ROOT/bin/$name", "$ROOT/bin/$name.exe") {
	return $cand if (-f $cand);
    }
    return $name;	# from the PATH
}

sub UpdateImage {
    my ($cfg) = @_;
    my $tree = TreeDir();
    my $stub = "$ROOT/" . (IniGet($cfg, "img86box", "stub") ||
			   "Installed/Tools/swat/Stub/LowMem/swat.exe");
    die "box86: serial Swat stub $stub not found (build it with \"pmake\"" .
	" in \$ROOT_DIR/Installed)\n" if (! -f $stub);

    my %vars = (EC => $ec ? "ec" : "");
    my @args = (Tool("img86box"), "-o", $IMAGE, "-s", $tree, "-t", $stub);
    my $creating = $fresh || ! -f $IMAGE;
    my ($img, $sysdir);
    if ($creating || $ENV{FREEDOS_IMG} ||
	-f "$LOCAL/86box/freedos/freedos.img") {
	# FreeDOS is needed to create the image; on updates it supplies
	# drivers that may have been added to the configuration
	($img, $sysdir) = FreeDos();
    } elsif (-d "$LOCAL/86box/freedos/sys") {
	$sysdir = "$LOCAL/86box/freedos/sys";
    }
    if ($img) {
	my @drivers;
	push(@drivers, "CTMOUSE.EXE") if (IniGet($cfg, "img86box", "mouse"));
	push(@drivers, IniGet($cfg, "img86box", "xms"));
	push(@drivers, "UDVD2.SYS", "SHSUCDX.COM")
	    if (IniGet($cfg, "img86box", "cdrom"));
	ExtractDrivers($img, $sysdir, @drivers);
	push(@args, "-f", $img);
    }
    push(@args, "-S", $sysdir) if ($sysdir);
    push(@args, "--fresh") if ($fresh);
    my $size = $ENV{GEOS_IMG_SIZE} || IniGet($cfg, "img86box", "size_mb");
    push(@args, "-m", $size) if ($size);
    foreach my $opt (["ptty", "-p"], ["kernel", "-k"], ["workdir", "-w"],
		     ["run", "-r"]) {
	my $v = IniGet($cfg, "img86box", $opt->[0]);
	push(@args, $opt->[1], Expand($v, \%vars)) if (defined($v) && $v ne "");
    }
    my $xms = IniGet($cfg, "img86box", "xms");
    push(@args, "-x", $xms) if (defined($xms) && $xms ne "");
    my $mouse = IniGet($cfg, "img86box", "mouse");
    push(@args, "-M", $mouse) if (defined($mouse) && $mouse ne "");
    push(@args, "--cdrom") if (IniGet($cfg, "img86box", "cdrom"));
    foreach my $ini (IniGet($cfg, "img86box", "ini")) {
	push(@args, "-I", Expand($ini, \%vars));
    }
    foreach my $dir (IniGet($cfg, "img86box", "prune")) {
	push(@args, "-P", $_) foreach (split(" ", $dir));
    }

    mkpath($VMDIR);
    Info("disk image $IMAGE ($PLATFORM, $TYPE)");
    my $rc = system(@args);
    die "box86: img86box failed\n" if ($rc != 0);
    Info("image geometry: " . ImageCylinders() .
	 " cylinders, $HEADS heads, $SECTORS sectors");
}

##############################################################################
#	ROM check and start
##############################################################################
sub Box86Exe {
    my $exe = $ENV{USE_86BOX};
    if (defined($exe) && $exe ne "" && $exe !~ /^(1|y|yes|on|true)$/i) {
	$exe =~ s/^"(.*)"$/$1/;		# quoted path from a .cmd file
	return $exe;
    }
    return $IS_WIN ? "86Box.exe" : "86Box";
}

sub FindInPath {
    my ($exe) = @_;
    return $exe if ($exe =~ m{[/\\]} && -f $exe);
    foreach my $d (split($IS_WIN ? ";" : ":", $ENV{PATH} || "")) {
	return "$d/$exe" if (-f "$d/$exe");
    }
    return undef;
}

sub CheckRoms {
    my ($cfg) = @_;
    my @dirs;
    push(@dirs, $ENV{BOX86_ROMS}) if ($ENV{BOX86_ROMS});
    my $exe = FindInPath(Box86Exe());
    push(@dirs, dirname($exe) . "/roms") if ($exe);
    if ($IS_WIN) {
	push(@dirs, "$ENV{APPDATA}/86Box/roms") if ($ENV{APPDATA});
    } else {
	my $data = $ENV{XDG_DATA_HOME} || "$ENV{HOME}/.local/share";
	push(@dirs, "$data/86Box/roms");
	push(@dirs, "/usr/share/86Box/roms", "/usr/local/share/86Box/roms");
    }
    my ($romdir) = grep { -d $_ } @dirs;
    if (!$romdir) {
	print STDERR "box86: warning: no 86Box ROM directory found " .
	    "(set BOX86_ROMS); not checking ROMs\n";
	return;
    }
    my @missing;
    foreach my $rom (split(" ", IniGet($cfg, "img86box", "roms") || "")) {
	push(@missing, $rom) if (! -f "$romdir/$rom");
    }
    if (@missing) {
	die "box86: ROM files missing in $romdir:\n  " .
	    join("\n  ", @missing) . "\n" .
	    "86Box needs the ROM set (https://github.com/86Box/roms).\n";
    }
}

sub CheckBox86Exe {
    my $exe = Box86Exe();
    if (!FindInPath($exe)) {
	die "box86: 86Box executable \"$exe\" not found (set USE_86BOX to" .
	    " its absolute path)\n";
    }
}

sub WinPath {
    my ($p) = @_;
    $p =~ s|/|\\|g if ($IS_WIN);
    return $p;
}

sub LogTail {
    my ($log) = @_;
    return "" if (! -f $log);
    open(my $fh, "<", $log) || return "";
    my @lines = <$fh>;
    close($fh);
    splice(@lines, 0, @lines - 15) if (@lines > 15);
    return "--- last lines of $log:\n" . join("", @lines);
}

sub StartBox86 {
    my $exe = Box86Exe();
    my $log = "$VMDIR/86box.log";
    my @cmd = ($exe, "-P", WinPath($VMDIR), "-L", WinPath($log));
    push(@cmd, "-R", WinPath($ENV{BOX86_ROMS})) if ($ENV{BOX86_ROMS});
    unlink($log);
    Info("starting @cmd");
    if ($^O eq "MSWin32") {
	# like target.cmd does for basebox: "start" returns at once and
	# leaves 86Box independent of this console
	my $image = basename($exe);
	$image .= ".exe" if ($image !~ /\.exe$/i);
	my $line = join(" ", map { ($_ eq "" || /[\s"&()^]/) ? "\"$_\"" : $_ }
			@cmd);
	# run through cmd.exe, "start" is one of its built-in commands
	system("cmd /d /c start \"86Box\" $line");
	sleep(3);
	# still running? (tasklist is part of every Windows)
	my $tl = `tasklist /FI "IMAGENAME eq $image" /NH 2>NUL` || "";
	if ($tl !~ /\Q$image\E/i) {
	    die "box86: $exe is not running after the start\n" .
		"  command: start \"86Box\" $line\n" . LogTail($log);
	}
    } else {
	# Linux, macOS, and Cygwin/MSYS perl on Windows
	my $pid = fork();
	die "box86: fork failed\n" if (!defined($pid));
	if ($pid == 0) {
	    open(STDIN, "<", "/dev/null");
	    open(STDOUT, ">", "/dev/null");
	    open(STDERR, ">", "/dev/null");
	    setpgrp(0, 0) if (!$IS_WIN);
	    exec(@cmd) || exit(127);
	}
	# lets img86box refuse to touch the image while 86Box runs
	if (!$IS_WIN && open(my $lock, ">", "$IMAGE.lock")) {
	    print $lock "$pid\n";
	    close($lock);
	}
	sleep(3);
	if (waitpid($pid, 1) == $pid) {	# 1 = WNOHANG
	    unlink("$IMAGE.lock");
	    die "box86: $exe exited at once (exit code " . ($? >> 8) .
		", see USE_86BOX)\n" . LogTail($log);
	}
    }
    Info("86Box is running; log: $log");
}

sub StartSwat {
    my @swat = ("swat");
    if ($IS_WIN) {
	push(@swat, "-serialpipe", PipeName());
    } else {
	delete($ENV{SWAT_NET});
	$ENV{SWAT_SERIAL_TCP} = "127.0.0.1:" . TcpPort();
    }
    Info("starting @swat");
    if ($IS_WIN) {
	exit(system(@swat) >> 8);
    }
    exec(@swat) || die "box86: cannot start swat\n";
}

##############################################################################
#	Main
##############################################################################
my $cfg = LoadLayers();

if ($cmd eq "freedos") {
    my ($img, $sysdir) = FreeDos();
    Info("FreeDOS image: $img");
    Info("FreeDOS files: $sysdir") if ($sysdir);
} elsif ($cmd eq "image") {
    UpdateImage($cfg);
} elsif ($cmd eq "config") {
    WriteConfig($cfg);
} elsif ($cmd eq "run") {
    OpenRunLog();
    Info("platform $PLATFORM, " . ($ec ? "EC" : "NC") . ", 86Box: " . Box86Exe());
    if (!$IS_WIN && !FindInPath("socat")) {
	die "box86: socat is needed to connect swat to 86Box (install it)\n";
    }
    CheckBox86Exe();
    CheckRoms($cfg);
    UpdateImage($cfg);
    WriteConfig($cfg);
    StartBox86();
    if ($ENV{BOX86_NOSWAT}) {
	Info("BOX86_NOSWAT is set: not starting swat");
	exit(0);
    }
    StartSwat();
}
exit(0);
