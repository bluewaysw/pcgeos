open(INFILE, "<secode.old") ;
$b = "Unknown" ;
$c = 0 ;
while ($line=<INFILE>)  {
    if ($line =~ /case (\S+):/)  {
        $b = $line ;
        $b =~ s/.*case (\S+):/$1/ ;
        $b =~ s/\n//g ;
        $c = 1 ;
    } elsif (($c!=0) && ($line =~ /break/))  {
        print " /* --- */ ProfPoint( \"", $b, "\" ) ;\n" ;
    }
    print $line ;
}
close(INFILE) ;