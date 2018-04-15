
package MailTransferMail;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#

# do output 
$verbose = 1;

# this is the verion of mine
$version = '1.0.0';

# our id counter
$idcount = 1;

# default from line
$fromline = "From root\@localhost   Mon Feb 12 23:26:05 2018 \n";

# global cache object for the tracing ...

%gtracehost = ();

%gtracehost_trace = ();


# global whitelist for not tracing
@gwhite = ();

# global black for not tracing
@gblack = ();

# object methods
sub initialize {
    # we initialize here our little thing.
    # depending on the mechanism on top we have diffrent forms
    # things in here...
    
    my $self = shift;

    $self->{id} = $idcount;

    ++$idcount;

    $self->{content} = []; 

    $self->{hstart} = -1; # unkown

    $self->{hend} = -1; # unkown

    $self->{bstart} = -1; # unkown

    $self->{bend} = -1; # unkown

    $self->{nl} = -1 ; # unknown
    
    $self->{kind} = 'unknown' ; # unknown

    $self->{traceroute} = [];
    
    $self->{tracefile} = '';

    $self->{receivedtag} = '';
    
    if ($#_ == 1 ) {
	# we have the text and the potential header start line number .
	
	$self->{text} = shift;
    
	$self->{hstart} = shift;
    } else {
	# we use the keyword thing

	while ($#_ > -1) {
	    my $k = shift;
	    my $v  = shift;

	    $self{$k} = $v;
	}
    }
    
    return ;
}

sub new {

    my $class = shift;

    my $self = {};

    bless $self , $class;

    $self->initialize(@_);
    
    return $self;
}

sub write {
    my $self = shift;

    my $fh = shift;


    my $tags = shift;
    
    my $text = $self->{text};

    my $lines = 0;
    
    my $msg = '';

    my $lastline = '';

    if (defined $tags) {
	my $k ;
	# regular mail has a content-type line. period ...
	for ($k = $self->{hstart} ; $k <= $self->{hend} ; ++ $k) {
	    last if $text->[$k] =~ m/^content-type:/i;
	    ++ $lines;
	    $lastline = $text->[$k];
	    $msg .= $text->[$k];
	}

	foreach my $l (@{$tags}) {
	    ++$lines;
	    $msg .= $l;
	}
	
	for (; $k <= $self->{hend} ; ++ $k) {
	    ++ $lines;
	    $lastline = $text->[$k];
	    $msg .= $text->[$k];
	}

	
    } else {
	
	for (my $k = $self->{hstart} ; $k <= $self->{hend} ; ++ $k) {
	    ++ $lines;
	    $lastline = $text->[$k];
	    $msg .= $text->[$k];
	}
    }

    # now for the body ...
    for (my $k = $self->{bstart} ; $k <= $self->{bend} ; ++ $k) {
	++ $lines;
	$lastline = $text->[$k];
	$msg .= $text->[$k];
    }

    # any thing left ... 
    while ($#_ > -1) {
	++ $lines;
	$lastline = $_[0];
	$msg .= shift;
    }

    # mails have to have an empty line as last one
    if ($lastline =~ m:^[\s]*$:) {
	# ok ...
    } else {
	++$lines;
	$msg .= "\n";
    }
    
    my $ret = print $fh $msg;

    if ($ret != 1) {
	die "ERROR901:print failed in write \n";
    }

    return $lines; 
}

sub add_content {
    my $self = shift;

    
}


sub do_traceroute {

    my $self = shift;

    my $host ;

    if ($self->{hend} == -1 || $self->{text} == undef) {
	return 1;
    }

    my $done = 0;
    my $i = $self->{hend};
    while (!$done) {
	for ( ; $i >= $self->{hstart}; --$i) {
	    last if $self->{text}->[$i] =~ m/^Received:/;
	}

	# we assemble the thing...
	my $c = $self->{text}->[$i];

	$c =~ s:[\s]*$: :;
	
	my $j = $i;
	for (++$j; $j < $self->{hend}; ++$j) {
	    last if $self->{text}->[$j] =~ m:^[^\s]:;
	    $c .= $self->{text}->[$j];
	    $c =~ s:[\s]*$: :;
	}

	if ($j == $self->{hend}) {
	    # someting is not right ...
	    return 1;
	}

	if ($c =~ m/([\d]+\.[\d]+\.[\d]+\.[\d]+)/) {
	    $done = 1;
	    $host = $1;
	}

	--$i;
    }

    if (!$done ) {
	return 1;
    }

    my $trout = '.mailfilter_traceroute_' . $$ . '.trc';

    unlink $trout;
    
    my $tcmd = 'traceroute "'. $host . '" > "' . $trout. '" 2>&1 < /dev/null ';

    my $ret = system $tcmd;

    if ($ret != 0) {

	unlink $trout;

	return 1;
    } 

    my $fh;
    
    open ($fh, $trout) or die "cannot traceroute... no output ...\n";

    my @t = <$fh>;

    close $fh;

    unlink $trout;

    $self->{traceroute} = \@t;
    
    return 0;
}

sub gen_or_reuse_traceroute {

    my $self = shift;

    my $trout = shift;

    my $proc = shift;

    my $level = shift;

    my $host ;

    my $tag ;
    
    if ($self->{hend} == -1 || $self->{text} == undef) {
	return '';
    }

    # check: do we have it already in ?

    for (my $i = $self->{hend}; $i >= $self->{hstart}; --$i) {
	if ($self->{text}->[$i] =~ m/^X-atrsoftgmbh-mailfilter-trace: notexist="([^\s]+)"/) {
	    if ($level > 1) {
		$self->{text}->[$i] ='X-atrsoftgmbh-mailfilter-trace-ignore: level=' . $level . "\n";
	    } else {
		my $tf = $1;
	    
		$self->{tracefile} = $tf;

		$self->{receivedtag} = ' already found in mail a trace with flag ' . $tf;

		return '# ' . $c . "\n"
		    . '#  ' . $tf;
	    }
	}

	if ($self->{text}->[$i] =~ m/^X-atrsoftgmbh-mailfilter-trace: exist=0/) {
	    if ($level > 1 ) {
		$self->{text}->[$i] =~ s:X-atrsoftgmbh-mailfilter-trace:X-atrsoftgmbh-mailfilter-trace-ignore:;
	    } else {
		my @trace = ();
	    
		for (my $j = $i + 1; $j < $self->{hend}; ++$j) {
		    my $line = $self->{text}->[$j];
		
		    last if ($line =~ m:^[^\s]:);

		    my $tline = substr($line, 4);
		    $tline =~ s:[\s]*$::;
		    push @trace, $tline;
		}

		$self->{traceroute} = \@trace;
	    
		$self->{tracefile} = 'alreadydone';

		$self->{receivedtag} = ' already found in mail a trace ' . $tf;

		return '# ' . $c . "\n"
		    . '# alreadydone ';
	    }
	}
    }

    # no resue, we have to generate real command now ...
    
    my $done = 0;
    my $i = $self->{hend};
    while (!$done) {
	for ( ; $i >= $self->{hstart}; --$i) {
	    last if $self->{text}->[$i] =~ m/^Received:/;
	}

	# we assemble the thing...
	my $c = $self->{text}->[$i];

	$c =~ s:[\s]*$: :;
	
	my $j = $i;
	for (++$j; $j < $self->{hend}; ++$j) {
	    last if $self->{text}->[$j] =~ m:^[^\s]:;
	    $c .= $self->{text}->[$j];
	    $c =~ s:[\s]*$: :;
	}

	if ($j == $self->{hend}) {
	    # someting is not right ...
	    return '';
	}

	if (&whitelist($c) == 0) {
	    $self->{tracefile} = 'whitelist';

	    $self->{receivedtag} = $c;
	    
	    return '# ' . $c . "\n"
		. '# whitelist ';
	}
 
	if (&blacklist($c) == 0) {
	    $self->{tracefile} = 'blacklist';

	    $self->{receivedtag} = $c;
	    
	    return '# ' . $c . "\n"
		. '# blacklist ';
	}
 
	if ($c =~ m/\[([\da-f]+):+([\da-f]+)/) {
	    # ip v6 aussen vor ...
	    $self->{tracefile} = 'ipv6';

	    $self->{receivedtag} = $c;
	
	    ## hard exit ...
	    return '# ' . $c . "\n"
		. '# ipv6 ... ';
	}
	
	if ($c =~ m/([\d]+)\.([\d]+)\.([\d]+)\.([\d]+)/) {

	    my $h1 = $1;
	    my $h2 = $2;
	    my $h3 = $3;
	    my $h4 = $4;
	    
	    $host = $h1 . '.' . $h2 . '.' . $h3 . '.' .$h4 ;
	    
	    # we have something in...
	    # now we skip the internal networkings

	    if ($h1 == 127) {
		# we skip
	    } elsif ($h1 == 192 && $h2 == 168) {
		# we skip local network
	    } elsif ($h1 == 169 && $h2 == 254) {
		# we skip local network
	    } elsif ($h1 == 10) {
		# we skip local network
	    } elsif ($h1 == 172 && ($h2 >= 16 && $h2 <= 31)) { 
		# we skip local network
	    } elsif ($h1 == 100 && ($h2 >= 64 && $h2 <= 127)) {
		# we skip local network
	    } else {
		# we have one ...
		$done = 1;
		$tag = $c;
	    }
	}

	--$i;
    }

    if (!$done ) {
	return '';
    }

    if (defined $gtracehost{$host}) {
	# we already have him in ...
	my $tf = $gtracehost{$host} ;

	$self->{tracefile} = $tf;

	$self->{receivedtag} = $tag;
	
	my $tcmd =  '# read in ' . $tf;

	return $tcmd;
    } else {
	# my $trout = '.mailfilter_traceroute_' . $$ . '.trc';

	unlink $trout;


	my $tf = $trout;

	$gtracehost{$host} = $tf;
	
	$self->{tracefile} = $tf;

	$self->{receivedtag} = $tag;
	
	my $tcmd = '# ' . $tag . "\n" 
             . 'nohup ' . $proc . ' "' . $host . '" > "' . $tf . '" 2>&1 < /dev/null & ';

	return $tcmd;
    }
}

sub valid_trace {
    my $self = shift;

    my $f = $self->{tracefile};

    if ($f eq 'whitelist'
	|| $f eq 'blacklist'
	|| $f eq 'ipv6'
	|| $f eq ''
	)
    {
	return 1;
    }

    return 0;
}

sub skip_traceroute {
    my $self = shift;

    my $f = $self->{tracefile};

    if ($f eq 'whitelist'
	|| $f eq 'blacklist'
	|| $f eq 'ipv6'
	|| $f eq 'alreadydone'
	|| $f eq ''
	)
    {
	return 0;
    }

    return 1;
}

sub load_traceroute {
    my $self = shift;
    
    return if $self->skip_traceroute == 0;

    my $tf = $self->{tracefile};

    if (defined $gtracehost_trace{$tf}) {
	$self->{traceroute} = $gtracehost_trace{$tf};
    } else {
	if (-r $tf) {
	    my $fh;
	    
	    if (open($fh, $tf)) {
				
		my @t = <$fh>;
		
		close $fh;
		
		my $l = $#t;

		my $i;

		for ($i = $l ; $i > 0 ; --$i) {
		    my $line = $t[$i];

		    if ($line =~ m:^[\s]*[\d]+[\s]+\*[\s]+\*[\s]+\*:) {
			# we remove those unneeded empty info
			pop @t;
		    } else {
			last;
		    }
		}

		for (--$i ; $i > 0 ; --$i) {
		    my $line = $t[$i];

		    if ($line =~ m:^[\s]*[\d]+[\s]+\*[\s]+\*[\s]+\*:) {
			# we remove those unneeded empty info
			splice @t, $i, 1;
		    } 
		}


		foreach my $l (@t) {
		    $l =~ s:[\s]*$::;
		}
		    
		$self->{traceroute} = \@t;

		$gtracehost_trace{$tf} = \@t;
		
		unlink $tf;
	    }
	}
    }
}

sub traceoutput {
	
    my $self = shift;
    
    my $id = shift;
    
    my $cline = shift;

    if ($cline =~ m/^content-type: multipart\/report/i) {
	return ''; # no manip of a report
    }

    if ($self->{tracefile} eq 'alreadydone') {
	return ''; # we have a trace already in, so dont duplicate
    }

    my $t = $self->{traceroute};

    if ($#{$t} > -1) {

	$id  = 0 + $id;
    
	$result = 'X-atrsoftgmbh-mailfilter-trace: exist=0 ; ruleid=' 
		 . $id  . "\n";
	foreach my $l (@{$t}) {
	    
	    $result .= '    ' . $l . "\n";
	}

    } else {
	$result = 'X-atrsoftgmbh-mailfilter-trace: notexist="' 
                . $self->{tracefile} . '"; ruleid=' . $id  . "\n";
    }
    
    return $result;
}

sub resulttag {

    my $self = shift;

    my $ruleid = shift;
    
    my $returncode = shift;

    my $cline = shift;

    if ($cline =~ m/^content-type: multipart\/report/i) {
	return ''; # no manip of a report
    }
    
    $returncode = 0 + $returncode;
    
    $ruleid  = 0 + $ruleid;
    
    my $result = 'X-atrsoftgmbh-mailfilter-result: result=' .  $returncode . '; ruleid=' . $ruleid  . '; mailid=' . $self->{id} ."\n";

    return $result;
}


############################################

# class methods

sub whitelist {
    foreach my $r (@gwhite) {
	return 0 if $_[0] =~ m/$r/;
    }

    return 1;
}

sub blacklist {
    foreach my $r (@gblack) {
	return 0 if $_[0] =~ m/$r/;
    }

    return 1;
}

sub add_white {
    my $t = shift;

    eval {
	my $r = qr/$t/;

	push @gwhite, $r;
    };
}

sub add_black {
    my $t = shift;

    eval {
	my $r = qr/$t/;

	push @gblack, $r;
    };
}

1;

# end of file



