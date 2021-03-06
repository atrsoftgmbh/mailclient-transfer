
package MailTransferRule;

use MailTransferMatch;

# import LOCK_* and SEEK_END constants

use Fcntl qw(:flock SEEK_END);


# atrsoftgmbh 2018
# part of the MailTransfer script system
#

$verbose = 1;

# we hold a rule
$version = '1.0.0';

# the global erg that is used in the and things between rules ... dirty..
$lasterg = 0;

# global number for shadowing in case i need it ...
$globnr = 0;

# the last id in case we define a rule ..
$lastid = 0;

sub initialize {
    # we initialize here our little thing.
    # depending on the mechanism on top we have three diffrent 
    # things in here...
    
    my $self = shift;

    my $lastand = shift;

    my $text = shift ;
    
    my $all_rules_r = shift;

    my $level = shift;

    my $fname = shift;

    my $lnr = shift ;
    
    if ($#_ == -1) {
	# we have only text now in. its from a scanner parser and contians the
	# rule from RULE to ENDRULE
	my @l = split(/[\n\r]+/, $text);

	$self->{id} = 0;

	$self->{level} = $level;

	$self->{filename} = $fname;
	
	$self->{line} = $lnr;
	
	$self->{stop} = 1;

	$self->{and} = $lastand;

	$self->{why} = 0;

	$self->{always} = 0;

	$self->{never} = 0;

	$self->{newrule} = 0;


	$self->{store} = 1;

	$self->{routecount} = 9999; #  magic number ... so many in ...

	$self->{match} = [];

	$self->{notheader} = [];

	$self->{notbody} = [];

	$self->{copy} = [];

	$self->{sent} = [];

	$self->{sentm} = [];

	$self->{proc} = [];

	$self->{code} = [];

	$lastmatch = '';

	my $lindex = 0;
	my $limit = $#l;
	
	for ($lindex = 0; $lindex <= $limit; ++$lindex) { 
	    my $line = $l[$lindex];
	
	    $line =~ s:^[\s]*#.*::; # kill comments ...

	    # we eat up empty lines .. ignore them totally ..
	    if ($line =~ m:^[\s]*$:) {
		next;
	    } 

	    if ($line =~ m:^[\s]*ENDRULE\b:i) {
		last;
	    }
	    
	    if ($line =~ m:^[\s]*RULE[\s]+([\d]+)[\s]+EXTENDS[\s]+([\d]+)[\s]*$:i) {
		my $id = 0 + $1;

		my $father = 0 + $2;
		
		$self->copyif($father, $all_rules_r);
		
		$self->{id} = $id;

		$lastid = $id;

		next;
	    }

	    if ($line =~ m:^[\s]*RULE[\s]+AUTO[\s]+EXTENDS[\s]+([\d]+)[\s]*$:i) {
		my $id = $lastid + 1;

		my $father = 0 + $1;
		
		$self->copyif($father, $all_rules_r);

		$self->{id} = $id;

		$lastid = $id;

		next;
	    }

	    if ($line =~ m:^[\s]*RULE[\s]+EXTENDS[\s]+([\d]+)[\s]*$:i) {
		my $id = $lastid + 1;

		my $father = 0 + $1;
		
		$self->copyif($father, $all_rules_r);

		$self->{id} = $id;

		$lastid = $id;

		next;
	    }

	    if ($line =~ m:^[\s]*RULE[\s]+([\d]+)[\s]*$:i) {
		my $id = 0 + $1;

		$self->{id} = $id;

		$lastid = $id;

		next;
	    }

	    if ($line =~ m:^[\s]*RULE[\s]+AUTO[\s]*$:i) {
		my $id = $lastid + 1;

		$self->{id} = $id;

		$lastid = $id;

		next;
	    }

	    # hidden nice thing - rule only is like auto
	    if ($line =~ m:^[\s]*RULE[\s]*$:i) {
		my $id = $lastid + 1;

		$self->{id} = $id;

		$lastid = $id;

		next;
	    }

	    if ($line =~ m:^[\s]*ALWAYS[\s]*$:i) {
		$self->{always} = 1;

		next;
	    }

	    if ($line =~ m:^[\s]*NOT[\s]+STORE[\s]*$:i) {
		$self->{store} = 0;

		next;
	    }

	    if ($line =~ m:^[\s]*NEVER[\s]*$:i) {
		$self->{never} = 1;

		next;
	    }

	    if ($line =~ m:^[\s]*NOT[\s]+NEVER[\s]*$:i) {
		$self->{never} = 0;

		next;
	    }

	    if ($line =~ m:^[\s]*STOP[\s]*$:i) {
		$self->{stop} = 1;
		next;
	    }
	    
	    if ($line =~ m:^[\s]*NOT[\s]+STOP[\s]*$:i) {
		$self->{stop} = 0;
		next;
	    }
	    
	    if ($line =~ m:^[\s]*WHY[\s]*$:i) {
		$self->{why} = 1;
		next;
	    }
	    
	    if ($line =~ m:^[\s]*NOT[\s]+WHY[\s]*$:i) {
		$self->{why} = 0;
		next;
	    }
	    
	    if ($line =~ m:^[\s]*NEW[\s]+RULE[\s]*$:i) {
		$self->{newrule} = 1;
		next;
	    }

	    if ($line =~ m:^[\s]*AND[\s]+NOT[\s]*$:i) {
		if ($lastmatch ne '') {
		    $lastmatch->{and} = 1;
		    $lastmatch->{not} = 1;
		}
		
		next;
	    }

	    if ($line =~ m:^[\s]*AND[\s]*$:i) {
		if ($lastmatch ne '') {
		    $lastmatch->{and} = 1;
		}

		next;
	    }
	    
	    if ($line =~ m:^[\s]*HEADER[\s]*$:i) {
		eval {
		    my ($r,$nr,$cm, $co, $lastline) = &getmatch($lindex, \@l);
		    my $ru = new MailTransferMatch('header', $r, $nr, $cm, $co);
		    push @{$self->{match}}, $ru;
		    $lastmatch = $ru;
		    $lindex = $lastline;
		};

		if ($@) {
		    &::dolog("ERROR701: in rule $id in rulefile $fname line $lnr \n$@\nthis is an error");
		    exit (1);
		}
		next;
	    }

 	    if ($line =~ m:^[\s]*BODY[\s]*$:i) {
		eval {
		    my ($r,$nr,$cm, $co, $lastline) = &getmatch($lindex, \@l);
		    my $ru = new MailTransferMatch('body', $r, $nr, $cm, $co);
		    push @{$self->{match}}, $ru;
		    $lastmatch = $ru;
		    $lindex = $lastline;
		};

		if ($@) {
		    &::dolog("ERROR702: in rule $id in rulefile $fname line $lnr \n$@\nthis is an error");
		    exit (1);
		}

		next;
	    }

	    if ($line =~ m:^[\s]*ALL[\s]*$:i) {
		eval {
		    my ($r,$nr,$cm, $co, $lastline) = &getmatch($lindex, \@l);
		    my $ru = new MailTransferMatch('all', $r, $nr, $cm, $co);
		    push @{$self->{match}}, $ru;
		    $lastmatch = $ru;
		    $lindex = $lastline;
		};

		if ($@) {
		    &::dolog("ERROR703: in rule $id in rulefile $fname line $lnr \n$@\nthis is an error");
		    exit (1);
		}


		next;
	    }

	    if ($line =~ m:^[\s]*ROUTE[\s]*$:i) {
		eval {
		    my ($r,$nr,$cm, $co, $lastline) = &getmatch($lindex, \@l);
		    my $ru = new MailTransferMatch('route', $r, $nr, $cm, $co);
		    push @{$self->{match}}, $ru;
		    $lastmatch = $ru;
		    $lindex = $lastline;
		};

		if ($@) {
		    &::dolog("ERROR704: in rule $id in rulefile $fname line $lnr \n$@\nthis is an error");
		    exit (1);
		}


		next;
	    }

	    if ($line =~ m:^[\s]*ROUTECOUNT[\s]+([\d]+)$:i) {
		$self->{routecount} = 0 + $1;
		next;
	    }

	    if ($line =~ m:^[\s]*NOT[\s]+HEADER[\s]*$:i) {

		++$lindex;
		
		my $re = $l[$lindex];
		$re =~ s:^[\s]::;

		eval {
		    my $qre = qr/$re/;

		    push @{$self->{notheader}}, $qre;
		
		};
		if ($@) {
		    &::dolog("ERROR705: cannot compile in rule " . $self->{id} . " in file $fname line $lnr \n$re ..\nthis is an error.");
		    exit(1);
		}
		
		next;
	    }

 	    if ($line =~ m:^[\s]*NOT[\s]+BODY[\s]*$:i) {

		++$lindex;
		
		my $re = $l[$lindex];
		$re =~ s:^[\s]::;

		eval {
		    my $qre = qr/$re/;

		    push @{$self->{notbody}}, $qre;
		
		};
		if ($@) {
		    &::dolog("ERROR706: cannot compile in rule " . $self->{id} . " in file $fname line $lnr \n$re ..\nthis is an error.");
		    exit(1);
		}
		
		next;
	    }

	    if ($line =~ m:^[\s]*NOT[\s]+ALL[\s]*$:i) {

		++$lindex;
		
		my $re = $l[$lindex];
		$re =~ s:^[\s]::;

		eval {
		    my $qre = qr/$re/;

		    push @{$self->{notheader}}, $qre;
		    push @{$self->{notbody}}, $qre;
		};
		if ($@) {
		    &::dolog("ERROR707: cannot compile in rule " . $self->{id} . " in file $fname line $lnr \n$re ..\nthis is an error.");
		    exit(1);
		}
		
		
		next;
	    }

 	    if ($line =~ m:^[\s]*WHITELIST[\s]*$:i) {

		++$lindex;
		
		my $re = $l[$lindex];
		$re =~ s:^[\s]::;

		eval {
		    &MailTransferMail::add_white($re);
		};
		if ($@) {
		    &::dolog("ERROR708: cannot whitelist in rule " . $self->{id} . " in file $fname line $lnr \n$re ..\nthis is an error.");
		    exit(1);
		} 
		else
		{
		    $self->{store} = 0;

		 }   
		
		next;
	    }

 	    if ($line =~ m:^[\s]*BLACKLIST[\s]*$:i) {

		++$lindex;
		
		my $re = $l[$lindex];
		$re =~ s:^[\s]::;

		eval {
		    &MailTransferMail::add_black($re);
		};
		if ($@) {
		    &::dolog("ERROR709: cannot blacklist in rule " . $self->{id} . " in file $fname line $lnr \n$re ..\nthis is an error.");
		    exit(1);
		}
		else
		{
		    $self->{store} = 0;

		 }   
		
		next;
	    }


	    if ($line =~ m:^[\s]*COPY[\s]+(.*):i) {

		my $p = $1;

		push @{$self->{copy}}, $p;
		
		next;
	    }

	    if ($line =~ m:^[\s]*SEND[\s]+(.*):i) {

		my $p = $1;

		push @{$self->{sent}}, $p;
		
		next;
	    }

	    if ($line =~ m:^[\s]*SENDMAIL[\s]+(.*):i) {

		my $p = $1;

		push @{$self->{sentm}}, $p;
		
		next;
	    }

	    if ($line =~ m:^[\s]*PROC[\s]+(.*):i) {

		my $p = $1;

		push @{$self->{proc}}, $p;
		
		next;
	    }

	    if ($line =~ m:^[\s]*CODE[\s]+(.*):i) {

		my $p = $1;

		push @{$self->{code}}, $p;
		
		next;
	    }

	    &::dolog("ERROR710: strange line in rule $self->{id} rulefile $fname line $lnr \n$line\nthis is an error.");
	    exit (1);
	}
    } else {
	&::dolog("ERROR711: wrong number of parameters rulefile $fname line $lnr \n.\nthis is an error.");
	exit (1);
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


sub copyif {

    my $self = shift ;

    my $fatherid = shift;

    my $a_r = shift;

    foreach my $f (@$a_r) {
	if ($f->{id} == $fatherid) {
	    $self->copy($f);
	    return;
	}
    }


    die "ERROR712:father $fatherid not found in extends rule ... \n"; 
}

sub copy {
    my $self = shift;

    my $f = shift;

    # no, not this one ...    $self->{id} = 0;

    # no, not this one ...    $self->{level} 

    # no, not this one ...    $self->{filename}

    $self->{stop} = $f->{stop};
    
    $self->{and} = $f->{and};

    $self->{why} = $f->{why};

    $self->{store} = $f->{store};

    $self->{always} = $f->{always};

    $self->{never} = $f->{never};

    $self->{newrule} = $f->{newrule};

    my @t = @{$f->{match}};
    
    $self->{match} = \@t;
    

    my @t4 = @{$f->{notheader}};
    
    $self->{notheader} = \@t4;

    my @t5 = @{$f->{notbody}};
    
    $self->{notbody} = \@t5;

    my @t6 = @{$f->{copy}};
    
    $self->{copy} = \@t6;

    my @t7 = @{$f->{sent}};
    
    $self->{sent} = \@t7;

    my @t8 = @{$f->{sentm}};
    
    $self->{sentm} = \@t8;

    my @t9 = @{$f->{proc}};
    
    $self->{proc} = \@t9;

    my @t10 = @{$f->{code}};
    
    $self->{code} = \@t10;
}

sub getmatch {
    # we are a helper, no method...
    my $akline = shift;

    my $t = shift;

    my $r = [];
    my $nr = [];
    my $cm = [];
    my $co = [];

    # we check the next line ...
    ++$akline;

    while ($akline <= $#{$t}) {
	my $line  = $t->[$akline];

	$line =~ s:^[\s]*#.*::; # kill comments - but only first char in line
	$line =~ s:[\s]*$::; # kill rest white space at end 

	if ($line =~ m:^[\s]*HEADER[\s]*$:i
	    || $line =~ m:^[\s]*BODY[\s]*$:i
	    || $line =~ m:^[\s]*ALL[\s]*$:i
	    || $line =~ m:^[\s]*ROUTE[\s]*$:i
	    || $line =~ m:^[\s]*ROUTECOUNT[\s]+:i
	    || $line =~ m:^[\s]*AND[\s]*$:i
	    || $line =~ m:^[\s]*AND[\s]+NOT[\s]*$:i
	    || $line =~ m:^[\s]*NOT[\s]+HEADER[\s]*$:i
 	    || $line =~ m:^[\s]*NOT[\s]+BODY[\s]*$:i
 	    || $line =~ m:^[\s]*NOT[\s]+ALL[\s]*$:i
 	    || $line =~ m:^[\s]*BLACKLIST[\s]*$:i
 	    || $line =~ m:^[\s]*WHITELIST[\s]*$:i
 	    || $line =~ m:^[\s]*ALWAYS[\s]*$:i
 	    || $line =~ m:^[\s]*NOT[\s]+STORE[\s]*$:i
 	    || $line =~ m:^[\s]*NEVER[\s]*$:i
 	    || $line =~ m:^[\s]*NOT[\s]+NEVER[\s]*$:i
 	    || $line =~ m:^[\s]*COPY[\s]+:i
 	    || $line =~ m:^[\s]*SENDMAIL[\s]+:i
 	    || $line =~ m:^[\s]*SEND[\s]+:i
 	    || $line =~ m:^[\s]*PROC[\s]+:i
 	    || $line =~ m:^[\s]*CODE[\s]+:i
 	    || $line =~ m:^[\s]*STOP[\s]*$:i
 	    || $line =~ m:^[\s]*NOT[\s]+STOP[\s]*$:i
 	    || $line =~ m:^[\s]*WHY[\s]*$:i
 	    || $line =~ m:^[\s]*NEW[\s]+RULE[\s]*$:i
 	    || $line =~ m:^[\s]*ENDRULE\b:i
	    ) {
	    # ok, we have it in. we have hit the next valid thing
	    -- $akline;
	    
	    return ($r, $nr, $cm, $co, $akline );
	}

	if ($line =~ m:^[\s]*$: ) {
	    # no empty lines count here
	} elsif (substr($line, 0, 1) eq '/') {
	    # we have a command in
	    push @{$cm} , $line;
	} elsif (substr($line, 0, 1) eq '!') {
	    # we have a notregex in
	    my $rt = substr($line,1);
	    my $rtest = qr/$rt/;
	    push @{$nr} , $rt;
	} elsif (substr($line, 0, 1) eq '&') {
	    # we have a code in
	    push @{$co} , $line;
	} elsif (substr($line, 0, 1) =~ m:^[\s]$:) {
	    # we have a regex in
	    my $rt = substr($line,1);
	    my $rtest = qr/$rt/;
	    push @{$r} , $rt;
	} else {
	    die "ERROR713: text not ok in match $line ";
	}
	    
	++ $akline;
    }

    return ($r, $nr, $cm, $co, $akline);
}

sub apply {
    my $rule = shift;

    if ($rule->{and} ) {
	# we are an and rue. so if the former lasterg is not 0 we have to skip.
	if ($lasterg != 0) {
	    # we have to skip. and no change of the lasterg ...
	    # return is 0, stop is 0
	    return (0,0);
	} else {
	    # we have to move on, the and is still in ...
	    # nothing to do here
	}
    } else {
	# we are no and rule, so we are the first in the chain.
	# we reset the lastreg so our reg is the thing we see...
	$lasterg = 0;
    }
    
    my $id = $rule->{'id'};

    # this returns a 0,0 on done, but no stop
    # if ok but stop we give a 0,1
    # else a 1,0 ... we ignore the rule then and try the next ... still
    my $mail_r = shift ;
    
    my $h_r = $mail_r->{text} ;

    my $hbegin = $mail_r->{hstart};

    my $hend  = $mail_r->{hend};

    my $b_r = $mail_r->{text};

    my $bbegin = $mail_r->{bstart} ;

    my $bend = $mail_r->{bend};

    my $a_r = $mail_r->{text};

    my $abegin = $mail_r->{hstart};

    my $aend = $mail_r->{bend};
    
    my $logfh = shift;

    my $dirlist = shift ;

    my $mailnumber = shift;

    my $mailboxkind = shift;

    my $mailboxdir = shift;

    my $sendmailproc = shift;

    my $prefix = shift;

    my $pools_r = shift;
    
    my $reason = 'never';
    
    if ($rule->{'never'}) {
	# no more test needed
	&::dolog("RULE $id never for $mailnumber ...") if $verbose;
	return (0,0); # never have an error, never have a stop
    }

    if ($rule->{'store'} == 0) {
	# no more test needed
	&::dolog("RULE $id not store for $mailnumber ...") if $verbose;
	return (0,0); # never have an error, never have a stop
    }

    # always  ...

    # normal execution of apply
    if ($rule->{'always'}) {
	# no more test needed
	$reason = 'always';

	$lasterg = 0;

	&::dolog("RULE $id always for $mailnumber ...");
    } elsif ($rule->{routecount} < 9999) {
	# we have the magic routecount check in
	$reason = 'routecount';

	if ($mail_r->valid_trace == 0) {

	    my $t  = $mail_r->{traceroute};
	    
	    my $count = $#{$t};

	    if ($count == -1) {
		# no trace at all .... ignore that .. break the rest
		$lasterg = 1;
		return (0,0);
	    }

	    my $hostlines = 0;
	    for (my $i = 1; $i <= $count; ++$i) {
		my $c = $t->[$i];

		$c =~ s:[\s]+ms[\s]+::g;
		
		$c =~ s:[\s]+ms$::g;
		
		if ($c =~ m:\.[a-zA-Z]:) {
		    # we have a valid domain in ...
		    ++$hostlines;
		}
	    }
	    
	    if ($hostlines <= $rule->{routecount}) {
		$lasterg = 0;
		# go on and do what you have to do ...
	    } else {
		$lasterg = 1;
		
		return (0,0);		
	    }
	    
	} else {
	    $lasterg = 1; # for all and rules that follow us
		
	    return (0,0);
	}
    } else {

	# if there is no test, we leave ... its an extend rule 
	if ($#{$rule->{match}} == -1
	    && $#{$rule->{notbody}} == -1
	    && $#{$rule->{notheader}} == -1
	    ) {
	    $lasterg = 0; # for all and rules that follow us
		
	    return (0,0);
	}
	
	# the simple tests. first all not
	my $hit = 0;

	foreach my $notheader (@{$rule->{notheader}}) {
	    my $i ;
	    for ($i = $hbegin; $i <= $hend; ++$i) {
		if ($h_r->[$i] =~ /$notheader/) {
		    $reason = $notheader;
		    $hit = 1;
		    last;
		}
	    }
	    last if $hit;
	}

	if ($hit) {
	    # rule impossible ...
	    # print $logfh "RULE $id hits a notheader $reason for $mailnumber ...\n";
	    $lasterg = 1; # for all and rules that follow us
	    
	    return (0,0);
	}

	$hit = 0;

	foreach my $notbody (@{$rule->{notbody}}) {
	    my $i ;
	    for ($i = $bbegin; $i <= $bend; ++$i) {
		if ($b_r->[$i] =~ /$notbody/) {
		    $reason = $notbody;
		    $hit = 1;
		    last;
		}
	    }
	    last if $hit;
	}

	if ($hit) {
	    # rule impossible now
	    # print $logfh "RULE $id hits a notbody $notbody for $mailnumber ...\n";
	    $lasterg = 1; # for all and rules that follow us
	    
	    return (0,0);
	}

	# now we do the real tests that are in . use the CALL if needed..
	# do the and thing ...

	
	# next : any header hit ?

	$reason = '';


	if ($#{$rule->{match}} > -1) {
	    my $lastmatchresult = 0;

	    my $lastmatcher = '';
	    
	    foreach my $matcher (@{$rule->{match}}) {
		$hit = 0;

		if ($lastmatchresult != 0) {
		    # we are in a and chain and its false ...
		    if ($matcher->{and} == 1) {
			# still in chain .. skip me
			$lastmatcher = $matcher;
			next;
		    } else {
			# we are a isolated, or a last in the chain .
			# we are definetely not the first ..
			if ($lastmatcher->{and} == 1) {
			    # ok, we are the last in the chain. cleanup
			    $lastmatcher = $matcher;
			    $lastmatchresult = 0;
			    # but still skip it ...
			    next;
			} else {
			    # we are isolated.
			    $lastmatchresult = 0;
			    # we go on...
			}
		    }
		}

		# we have in a new chain for and. or a isolated match
		
		my $i ;

		my $type = $matcher->{type};

		my $start;
		my $end;
		my $text ;
		
		if ($type  eq 'header') {
		    $start = $hbegin;
		    $end = $hend;
		    $text = $h_r;
		    
		    # ok. we have come so far. we check now this match
		    for ($i = $start; $i <= $end; ++$i) {
			if ($matcher->apply($text->[$i], $mail_r, $i) == 0) {
			    $hit = 1;
			    last;
			}
		    }

		} elsif ($type eq 'body') {
		    $start = $bbegin;
		    $end = $bend;
		    $text = $b_r;
		    
		    # ok. we have come so far. we check now this match
		    for ($i = $start; $i <= $end; ++$i) {
			if ($matcher->apply($text->[$i], $mail_r, $i) == 0) {
			    $hit = 1;
			    last;
			}
		    }

		} elsif ($type eq 'all') {
		    $start = $abegin;
		    $end = $aend;
		    $text = $a_r;
		    
		    # ok. we have come so far. we check now this match
		    for ($i = $start; $i <= $end; ++$i) {
			if ($matcher->apply($text->[$i], $mail_r, $i) == 0) {
			    $hit = 1;
			    last;
			}
		    }

		} elsif ($type eq 'route') {
		    $start = $#{$mail_r->{traceroute}};

		    if ($start > -1) {
			# ok, we have a trace to test here ...
			$text = $mail_r->{traceroute};
		    
			# ok. we have come so far. we check now this match
			for ($i = $start; $i >= 0; --$i) {
			    if ($matcher->apply($text->[$i], $mail_r, $i) == 0) {
				$hit = 1;
				last;
			    }
			}
		    } else {
			# no hit for this rule ...
		    }
		    

		} else {
		    print "ups. what is that matcher here ? " . $matcher->{type}  . "\n";
		    next;
		}


		# ok. we have now the following logic.
		# if we are in a and chain, we have to set lastmatcherresult
		# this depends on the real result.
		# in case it is a and its the result.
		# in case its a and not, its the reverse result.
		# if we are the first in the chain ist the result like in and  case

		if ($lastmatcher ne '' ) {
		    if ($lastmatcher->{and} == 1
			&& $lastmatcher->{not} == 1) {
			# we have to reverse the logic in case there is a former not and ...
			$hit = ($hit == 1) ? 0 : 1;
		    }
		}

		# ok we are in now with the real result regarding logic of the former if it exists...
		
		$lastmatchresult = $hit == 0 ? 1 : 0;

		if ($matcher->{and} == 1) {
		    # if we are in a chain the thing has to run till the end, so we leave it for now
		    # we are a start of a and chain. so DONT leave here if its a hit ...
		    if ($hit == 1) {
			# we still loop for the rest
			# the skip is done in the loop for the lastmatchresult ...
		    } else {
			# hit is 0, means we are out.
			# this is done by the lastmatchresult ..
		    }
		} else {
		    # we are at end of the chain or we are isolated.
		    # so now the hit is relevant for the result of the chain
		    if ($lastmatcher ne '' ) {
			if ($lastmatcher->{and} == 1) {
			    # the last hit determines if the chain is a hit...
			    if ($hit == 1) {
				last;
			    } else {
				# test the rest after the chain
			    }
			} else {
			    # we are not in a chain. isolated ...
			    if ($hit == 1) {
				# ok. one hit is enough...
				last;
			    } else {
				# test the next ...
			    }
			}
		    } else {
			# we are the first ... and not in chain
			if ($hit == 1) {
			    # we fullfillthe rule
			    last;
			} else {
			    # test the next ...
			}
		    }
		}

		$lastmatcher = $matcher;
	    }

	    if ($hit == 0) {
		# rule impossible
		# but this is normal , so no log here 
		# print $logfh "RULE $id not hits this header  for $mailnumber ...\n";
		$lasterg = 1; # for all and rules that follow us

		return (0,0);
	    }
	}
	
    }  # the big else for the always ...
    
    # ok. so far all hits are made or not made for the not thing..

    # now we can make it with the thing to a COPY or SENT ...

    foreach my $sent (@{$rule->{sent}}) {
	# we append the thing to the mailbox of the user on this box..
	&::dolog("RULE $id send to $sent  for $mailnumber ...");

	if ($rule->{why}) {
	    &why_info($mail_r, $logfh);
	}
	
	my $msg = '';

	my $i;
	
	for ($i = $hbegin; $i <= $hend ; ++$i) {
	    last if $h_r->[$i] =~ m/^content-type:/i; 
	    $msg .=  $h_r->[$i];
	}

	$msg .= $mail_r->traceoutput($id,  $h_r->[$i]);
	
	$msg .= $mail_r->resulttag($id, 1, $h_r->[$i]);
	
	for ( 1; $i <= $hend ; ++$i) {
	    $msg .=  $h_r->[$i];
	}
	
	for ($i = $bbegin; $i <= $bend ; ++$i) {
	    $msg .=  $b_r->[$i];
	}

	# print "sent : $sent $hbegin $bend " . ($bend - $hbegin) . "\n";
	
	eval {
	    &mailto ($sent, $msg, $mailboxkind, $mailboxdir);
	};

	if ($@) {
	    &::dolog("ERROR714: cannot send to $sent because $@ "); 
	}
    }

    foreach my $sentm (@{$rule->{sentm}}) {
	# use the mailer to sent it.
	print $logfh "RULE $id sendmail to $sentm  for $mailnumber ...\n";

	if ($rule->{why}) {
	    &why_info($mail_r, $logfh);
	}
	
	my $msg = '';

	my $i;
	
	for ($i = $hbegin; $i <= $hend ; ++$i) {
	    last if $h_r->[$i] =~ m/^content-type:/i; 
	    $msg .=  $h_r->[$i];
	}

	$msg .= $mail_r->traceoutput($id,  $h_r->[$i]);
	
	$msg .= $mail_r->resulttag($id, 1, $h_r->[$i]);
	
	for ( 1; $i <= $hend ; ++$i) {
	    $msg .=  $h_r->[$i];
	}
	
	for ($i = $bbegin; $i <= $bend ; ++$i) {
	    $msg .=  $b_r->[$i];
	}

	eval {
	    &sentmailto ($sentm, $msg, $sendmailproc);
	};

	if ($@) {
	    &::dolog("ERROR715: cannot sendmail to $sent because $@ "); 
	}
    }

    foreach my $proc (@{$rule->{proc}}) {
	# we append the thing to the mailbox of the user on this box..
	print $logfh "RULE $id proc to $proc  for $mailnumber ...\n";

	if ($rule->{why}) {
	    &why_info($mail_r, $logfh);
	}
	
	my $msg = '';

	my $i;
	
	for ($i = $hbegin; $i <= $hend ; ++$i) {
	    last if $h_r->[$i] =~ m/^content-type:/i; 
	    $msg .=  $h_r->[$i];
	}

	$msg .= $mail_r->traceoutput($id,  $h_r->[$i]);
	
	$msg .= $mail_r->resulttag($id, 1, $h_r->[$i]);
	
	for ( 1; $i <= $hend ; ++$i) {
	    $msg .=  $h_r->[$i];
	}
	
	for ($i = $bbegin; $i <= $bend ; ++$i) {
	    $msg .=  $b_r->[$i];
	}

	eval {
	    &procto ($proc, $msg);
	};

	if ($@) {
	    &::dolog("ERROR716: cannot proc to $proc because $@ "); 
	}
    }

    my $cnr = 0;
    foreach my $code (@{$rule->{code}}) {
	# we append the thing to the mailbox of the user on this box..
	print $logfh "RULE $id code for $mailnumber ...\n";

	if ($rule->{why}) {
	    &why_info($mail_r, $logfh);
	}
	
	my $codeline = 'sub { ' . $code . '};' ;

	eval {
	    my $co = eval $codeline;

	    &codeto ( $co , $mail_r, $id, $cnr);
	};

	if ($@) {
	    &::dolog("ERROR717: cannot code because $@ "); 
	}

	++$cnr;
    }
    # now we do the copy thing ...

    my $conv = $dirlist->get_convert;
    
    # if ($dirlist->{'sourcemailsystem'} eq 'thunderbird' && $prefix ne '') {
    # 	# thunderbird needs this .. or you dont see the rest ...
    # 	my $fh;
    # 	open($fh, ">>" . $dirlist->{sourcefile} . '/' . $prefix);
    # 	close $fh;
    # }
    
    # if ($dirlist->{'sourcemailsystem'} eq 'seamonkey' && $prefix ne '') {
    # 	# seamonkey needs this .. or you dont see the rest ...
    # 	my $fh;
    # 	open($fh, ">>" . $dirlist->{sourcefile} . '/' . $prefix);
    # 	close $fh;
    # }

    # if ($dirlist->{'sourcemailsystem'} eq 'kmail' && $prefix ne '') {
    # 	# kmail needs this .. or you dont see the rest ...
    # 	my $prefixfolder = $dirlist->{sourcefile} . '/'. $prefix;

    # 	if (! -d $prefixfolder) {
    # 	    mkdir $prefixfolder;
    # 	}
    # }
    
    foreach my $copy (@{$rule->{copy}}) {
	# we append the thing to the mailbox of the user on this box..
	print $logfh "RULE $id copy to $copy  for $mailnumber ...\n";

	if ($rule->{why}) {
	    &why_info($mail_r, $logfh);
	}
	

	# we use the lists thing her. build in that path from bottem to top, then create_directory it ...

	my @copyp = split(/\//, $prefix . '/' . $copy);
	my $p = '';
	my $lastcur = '';
	my $lastmeta = '';
	
	foreach my $copyppart (@copyp) {
	    $p .= '/' . $copyppart;
	    
	    my $directory = $p;
	   
	    my $e = &$conv($p, '');

	    my @f = ();
	    my @t = ();
	    my @fmbox = ();
	    
	    $lastcur = $e->{cur};
	    $lastmeta = $e->{meta};

	    my $subdir = '';
	    if ($dirlist->{'sourcemailsystem'} eq 'sylpheed' 
		|| $dirlist->{'sourcemailsystem'} eq 'claws-mail') {
		$subdir = $dirlist->{'sourcemailsystem'};
	    }
	    
	    $dirlist->add_new_node($directory,
				   $copyppart,
				   $p, 
				   $subdir,
				   $e->{meta},
				   $e->{base},
				   $e->{cur},
				   $e->{new},
				   $e->{tmp},
				   \@f, \@t,
				   \@fmbox);  
	}

	my $lastnode = '';
	foreach my $d (sort keys %{$dirlist->{'nodes'}}) {
	    $lastnode = $dirlist->{'nodes'}->{$d};
	    my $ret = $lastnode->create_folders($logfh, $dirlist->{'sourcefile'});
	    
	    if($ret != 0) {
		next;
	    }
	}

	# ok. we are now in for the target directory, so we can now do the job and pack the thing in ...
	# we need the last node now, its a thing we can get from the last tcur ..
	my $tcur = $dirlist->{'sourcefile'} . '/' . $lastcur;

	# hm.. or is it meta ??? # TODO 

	# later ... for now vanilla rules ..

	my $num = $lastnode->get_last_number($tcur);

	my $retwrite =  $lastnode->writefile_clean($tcur,
						   $num,
						   $mail_r,
						   $logfh,
						   $dirlist->{sourcemailsystem}, # as flag ...
	     [  $mail_r->traceoutput($id, '') , $mail_r->resulttag($id, 1, '') ] );

	if ($retwrite != 0) {
	    # ups ... what to do ? spell it out ..
	    &::dolog("ERROR718: error in writefile for $copy  for $mailnumber ... "); 
	}
    }

    if ($rule->{newrule}) {
	# we append the thing to the mailbox of the user on this box..
	&::dolog("RULE $id newrule for $mailnumber ...");

	eval {
	    &newrule ($mail_r, $pools_r);
	};

	if ($@) {
	    &::dolog("ERROR719: cannot newrule because : $@ "); 
	}
    }

    # so far. we set the lastreg for our followers and rules
    $lasterg = 0;

    if ($rule->{stop} != 0) {
	return (0,1);
    }
    
    return (0,0);
}




sub why_info {

    my $a_r = shift;

    my $log = shift;
    
    my $from = "From: empty\n";

    my $to = "To: empty\n";

    my $subject = "Subject: empty\n";

    my $i ;
    for ($i = $a_r->{hstart} ; $i < $a_r->{hend}; ++$i) {
	if ($a_r->{text}->[$i] =~ m/^From: /) {
	    $from = $a_r->{text}->[$i];
	}
	if ($a_r->{text}->[$i] =~ m/^To: /) {
	    $to = $a_r->{text}->[$i];
	}
	if ($a_r->{text}->[$i] =~ m/^Subject: /) {
	    $subject = $a_r->{text}->[$i];
	}
    }

    print $log "    " . $from
	.  "    " . $to
	.  "    " . $subject ;
}

# class methods are in here 

sub procto {
    # we do the proc thing : execute and pipe in the mail 
    my $proc = shift;

    my $msg = shift;

    my $fh ;

    if (! -x $proc ) {
	die "ERROR734: cannot execute the $proc ..\n";
    }
    
    open ($fh, "|" . $proc) or die "ERROR735: cannot open $proc for pipe\n";

    my $pret = print $fh $msg;

    # i do a separate io here to give the proc the chance to do its thing ...
    print $fh "\n";
    
    close $fh;
}

sub codeto {
    # we do the proc thing : execute and pipe in the mail 
    my $code = shift;

    my $mail_r = shift;

    my $rulenumber = shift ;

    my $codenumber = shift;

    eval {
	&$code($mail_r, $rulenumber, $codenumber);
    };

    if ($@) {
	die "ERROR720: cannot execute code : $@ \n";
    }
}

sub sentmailto {
    # we do the sendmail thing : execute and pipe in the thing and a . on a line 
    my $mailadr = shift;

    my $msg = shift;

    my $sendmailproc = shift;

    
    my $fh ;

    open ($fh, "|" . $sendmailproc . " " . $mailadr ) or die "ERROR736: cannot open $sendmailproc for pipe\n";

    my $pret = print $fh $msg;

    # i do a separate io here to give the proc the chance to do its thing ...
    print $fh "\n";
    
    close $fh;
}

sub mailto {
    # we do the thing : simulate a snedmail by simply copy append.
    # if you do this for other user it it likely you need here
    # a setuid or setgid thing.
    # be sure to read the howto for this ...
    my $user = shift;

    my $msg = shift;

    my $mailboxkind = shift;

    my $mailboxdir = shift;

    if ($mailboxkind eq 'mbox') {
	my $target = $mailboxdir . '/' . $user;

	if (! -f $target) {
	    die "ERROR737: mailbox not existing for $user at $mailboxdir ...\n";
	}
	
	if (! -w $target) {
	    die "ERROR738: mailbox not writeable for $user at $mailboxdir ...\n";
	}
	
	open(my $mbox, ">>" . $target ) or die "ERROR739: cannot open target for write.. \n";
	lock($mbox);
	print $mbox $msg,"\n\n";
	unlock($mbox);
	close $mbox;
    }
}

sub lock {
    # helper
    my ($fh) = @_;
    flock($fh, LOCK_EX) or die "ERROR739: Cannot lock mailbox - $!\n";

    # and, in case someone appended while we were waiting...
    seek($fh, 0, SEEK_END) or die "ERROR740: Cannot seek - $!\n";
}

sub unlock {
    # helper
    my ($fh) = @_;
    flock($fh, LOCK_UN) or die "ERROR741: Cannot unlock mailbox - $!\n";
}



sub newrule {
    my $mail_r = shift;

    my $pools_r = shift;
    
    my $text = $mail_r->{text};

    my $ruletext = '';

    my $rulepool = '';

    my $i;
    
    for ($i = $mail_r->{bstart} ; $i <= $mail_r->{bend} ; ++$i) {
	if ($text->[$i] =~ m:^RULE:i) {
	    my $line = $text->[$i];
	    $line =~ s:[\s]*$::;
	    
	    $ruletext = $line . "\n";
	    last;
	}
    }

    for (++$i ; $i <= $mail_r->{bend} ; ++$i) {
	if ($text->[$i] =~ m:^ENDRULE:i) {
	    last;
	}

	my $line = $text->[$i];
	$line =~ s:[\s]*$::;
	    
	$ruletext .= $line . "\n";
    }

    if ($text->[$i] =~ m:^ENDRULE\b:i) {
	$ruletext .= "ENDRULE\n";
    }

    for (++$i ; $i <= $mail_r->{bend} ; ++$i) {
	if ($text->[$i] =~ m:^POOL[\s]+([^\s]+):i) {
	    $rulepool = $1;
	    last;
	}
	
    }

    my $inpool = 1;
    
    foreach my $pool (@{$pools_r}) {
	if ($pool eq $rulepool) {
	    $inpool = 0;
	    last;
	}
    }

    if ($inpool == 1) {
	die "ERROR743: pool not in allowed list of pools.\n";
    }
    
    if ($rulepool ne ''
	&& $ruletext ne '') {

	if (-d $rulepool) {
	
	    my $lastnumber = &get_next_number($rulepool);

	    my $lnr = sprintf("%08d", $lastnumber);
	    my $rfile = $rulepool . '/' . 's' . $lnr  . '.rule';

	    my $fh ;
	    if (open($fh, ">" . $rfile)) {
		my $ret = print $fh $ruletext;

		close $fh;
		if ($ret != 1) {
		    die "ERROR744: cannot write rulefile $rfile .. \n";
		}
	    } else {
		die "ERROR745: cannot open rulefile for write $rfile .. \n";
	    }
	}
    }
}


sub get_next_number {
    my $t = shift;

    my $dh;
    
    if (!opendir($dh, $t)) {
	return 1;

    }

    my @files = readdir($dh);

    closedir($dh);

    my $n = 1;
    
    foreach my $f (@files) {
	if ($f =~ m:([\d]+)\.rule$:) {
	    my $v = $1;

	    if ($n <= $v + 0) {
		$n = $v + 1;
	    }
	}
    }

    if ($n < 1) {
	$n = 1;
    }
    
    return $n;
}

sub set_lasterg {
    $lasterg = shift;
}

sub factory {
    my $rfh = shift;

    my $rflnr = shift;

    my $r_r = shift;

    my $fname = shift;

    my $level = 0;
    
    &load_rules_file($rfh, $rflnr, $r_r, $level + 1, $fname);

}

sub load_rules_file {
    my $rfh = shift;

    my $rflnr = shift;

    my $r_r = shift;

    my $level = shift;

    my $fname = shift;
    
    
    # now we can scan the rules
    my $ruletext = '';

    my $inrule = 0;

    my $lastrule = '';

    my $lastand = 0;

    while (<$rfh>) {
	++$rflnr;

	next if m:^[\s]*$:;

	next if m:^[\s]*#:; # kill all comments only lines
	
	if ($inrule == 1 && m:^[\s]*ENDRULE:i) {
	    $ruletext .= $_;
	    my $r = new MailTransferRule($lastand, $ruletext, $r_r, $level, $fname, $rflnr);

	    if ($r->{store} == 1) {
		push @{$r_r}, $r;

		$lastrule = $r;
	    }
	    
	    $inrule = 0;

	    $lastand = 0;
	    next;
	}

	if ($inrule == 0 && m:^[\s]*INCLUDE[\s]+([^\s]+):i) {
	    my $pm = $1;

	    if (-f $pm) {
		# we have a single file in...

		my $fh;
		if (open($fh, $pm)) {
		    &load_rules_file($fh, 0, $r_r, $level + 1, $pm);

		    close $fh;
		} else {
		    &::dolog("ERROR721: include not readable in $fname line $rflnr\n$_\n" . $pm . "\nthis is an error.");
		    exit(1);
		}
	    } elsif (-f $::basedirs[0] . '/' . $pm) {
		# we have a single file in...

		my $fh;
		if (open($fh, $::basedirs[0] . '/' . $pm)) {
		    &load_rules_file($fh, 0, $r_r, $level + 1, $::basedirs[0] . '/' . $pm);

		    close $fh;
		} else {
		    &::dolog("ERROR722: include not readable in $fname line $rflnr\n$_\n" . $::basedirs[0] . '/' . $pm . "\nthis is an error.");
		    exit(1);
		}
	    } elsif (-f $::basedirs[1] . '/' . $pm) {
		# we have a single file in...

		my $fh;
		if (open($fh, $::basedirs[1] . '/' . $pm)) {
		    &load_rules_file($fh, 0, $r_r, $level + 1, $::basedirs[1] . '/' . $pm);

		    close $fh;
		} else {
		    &::dolog("ERROR723: include not readable in $fname line $rflnr\n$_\n" . $::basedirs[1] . '/' . $pm . "\nthis is an error.");
		    exit(1);
		}
	    } elsif (-d $pm) {
		# we have a dir of rules in...
		my $dh;

		if (opendir($dh, $pm)) {
		    my @f =  readdir($dh);

		    closedir($dh);

		    @f = sort @f;
		    
		    foreach my $rfile (@f) {
			next if $rfile !~ m:\.rule$:;
			
			my $f = $pm . '/' . $rfile;

			if (-f $f) {
			    my $fh;

			    if (open($fh, $f)) {
				&load_rules_file($fh, 0, $r_r, $level + 1, $f);
				close $fh;
			    } else {
				&::dolog("ERROR724: include not readable in $fname line $rflnr\n$_\n$f\nthis is an error.");
				exit(1);
			    }
			} else {
			    &::dolog("ERROR725: include not readable in $fname line $rflnr\n$_\n$f\nthis is an error.");
			    exit(1);
			}
		    }
		} else {
		    &::dolog("ERROR726: include directory not readable in $fname line $rflnr\n$_\n$pm\nthis is an error.");
		    exit(1);
		}
	    } elsif (-d $::basedirs[0] . '/' . $pm) {
		# we have a dir of rules in...
		my $dh;

		if (opendir($dh, $::basedirs[0] . '/' . $pm)) {
		    my @f =  readdir($dh);

		    closedir($dh);

		    @f = sort @f;
		    
		    foreach my $rfile (@f) {
			next if $rfile !~ m:\.rule$:;
			
			my $f = $::basedirs[0] . '/' .$pm . '/' . $rfile;

			if (-f $f) {
			    my $fh;

			    if (open($fh, $f)) {
				&load_rules_file($fh, 0, $r_r, $level + 1, $f);
				close $fh;
			    } else {
				&::dolog("ERROR727: include not readable in $fname line $rflnr\n$_\n$f\nthis is an error.");
				exit(1);
			    }
			} else {
			    &::dolog("ERROR728: include not readable in $fname line $rflnr\n$_\n$f\nthis is an error.");
			    exit(1);
			}
		    }
		} else {
		    &::dolog("ERROR729: include directory not readable in $fname line $rflnr\n$_\n" . $::basedirs[0] . '/' . $pm . "\nthis is an error.");
		    exit(1);
		}
	    } elsif (-d $::basedirs[1] . '/' . $pm) {
		# we have a dir of rules in...
		my $dh;

		if (opendir($dh, $::basedirs[1] . '/' . $pm)) {
		    my @f =  readdir($dh);

		    closedir($dh);

		    @f = sort @f;
		    
		    foreach my $rfile (@f) {
			next if $rfile !~ m:\.rule$:;
			
			my $f = $::basedirs[1] . '/' .$pm . '/' . $rfile;

			if (-f $f) {
			    my $fh;

			    if (open($fh, $f)) {
				&load_rules_file($fh, 0, $r_r, $level + 1, $f);
				close $fh;
			    } else {
				&::dolog("ERROR730: include not readable in $fname line $rflnr\n$_\n$f\nthis is an error.");
				exit(1);
			    }
			} else {
			    &::dolog("ERROR731: include not readable in $fname line $rflnr\n$_\n$f\nthis is an error.");
			    exit(1);
			}
		    }
		} else {
		    &::dolog("ERROR732: include directory not readable in $fname line $rflnr\n$_\n" . $::basedirs[1] . '/' . $pm . "\nthis is an error.");
		    exit(1);
		}
	    } else {
		# ups. we have an include that does not work here

		&::dolog("ERROR733: include is not possible for $fname line $rflnr\n$_\nthis is an error.");
		exit(1);
	    }
	    
	    next;
	}
	
	
	if ($inrule == 0 && m:^[\s]*RULE[\s]+:i) {
	    $ruletext = $_;
	    $inrule = 1;
	    next;
	}

	if ($inrule == 0 && m:^[\s]*AND[\s]*$:i) {
	    if ($lastrule ne '') {
		$lastrule->{stop} = 0;
		$lastand = 1;
	    }
	    next;
	}

	if ($inrule == 1) {
	    $ruletext .= $_;
	    next;
	}


	# ups. something but not known in this rulefile ...

	&::dolog("ERROR734: unknown found in rulefile $fname line $rflnr\n$_\nthis is an error.");
	exit(1);
    }

    return 0;
}


## end

1;

# end of file



