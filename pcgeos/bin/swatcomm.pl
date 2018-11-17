use Win32::Registry;

if ($#ARGV >= 0) {
    $HKEY_CURRENT_USER->Open("Software\\Geoworks", $Geoworks)
	|| die "Unable to open registry key HKEY_CURRENT_USER\\Software\\Geoworks";
    $Geoworks->GetValues(\%values)
	|| die "Unable to query values of HKEY_CURRENT_USER\\Software\\Geoworks!";
    $SDK = $values{'USE_ALTERNATE_SDK'}[2];
    $Geoworks->Open("$SDK\\Swat", $Swat);
    $Swat->SetValueEx("COMM_MODE", "", REG_SZ, $ARGV[0])
	|| die "Unable to set COMM_MODE!";
} else {
    print "Sets the communication medium for Swat.\n\n";
    print "Usage: swatcomm <type>\n\n";
    print "Acceptable values for <type> are: \"Named Pipe\", \"Serial\"\n";
}
