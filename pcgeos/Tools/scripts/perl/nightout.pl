$printall = 1;
$printWarn = 1;

while ($arg = shift @ARGV) {

    # don't print successful targets
    if ($arg eq "-e") {
        $printall = 0;
        next;
    }

    # don't print warnings
    if ($arg eq "-w") {
	$printWarn = 0;
        next;
    }
}

$pat = '(\Werror\W)|(^File[s:])}(^Can\'t)|(\Werrors\W)';

if ($printWarn) {
    $pat .= '|(warning)';
}

$printed = 0;
$target = "";
while (<>) {
    if (/(---\s.+\s---)/) {
	$target = $1;
	if ($printall) {
	    print;
	    $printed = 1;
	} else {
	    $printed = 0;
	}
    } elsif (/($pat)/oi) {
        if (!$printed) {
	    print $target, "\n";
	    $printed = 1;
	}
	print;
    }
}

