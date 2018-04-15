
sub printout {

    my $m = shift;

    for (my $i = $m->{hstart}; $i <= $m->{bend} ; ++$i) {
	print $m->{text} -> [$i];
    } 
}


sub checkfedoralist {
    my $ret = 0;

    my $c = shift; # the candidate line, speeds up

    my $mail_r = shift ; # the whole mail

    my $s = shift ; # the matcher itself

    my $cnr = shift ; # my code check number to identify the check

    my $lnr = shift;
    
    my $i = index($c, 'users@lists.fedoraproject.org');

    return 1 if $i == -1; # bad. no good 

    return $ret;
}

1;

