#!/usr/bin/perl

# atrsoftgmbh 2018
# part of the MailTransfer script system
#

# we filter mails from an infile according to some rules...
# see the howto-filter.txt for the details
# see the howto.txt for the details on mailsystems

# give info 
$verbose = 1;

# give out a copy on disk 
$cc = 0;

# our version 
$version = '1.0.0';

# we do a traceroute for the mail .. no default
$traceroute = 0; 

# the traceroute prg
$tracerouteproc = '/usr/bin/traceroute'; 

# and the count of parallel processes
$traceroutecount = 100;

# some defaults that work normally for me :)

# the prefix if any is given for the target for copy in the mailsystem
$prefix = 'mailfilter';

# the sendmail process that we use
$sendmailproc = '/usr/sbin/sendmail -bm -oi';

# my private mailsystem - its only a storage for now
$themailsystem = 'vanilla';

# the base for it
$infile =  $ENV{'HOME'} . '/vanilla';

# my box input maildir from sendmail
$mailboxdir = '/var/spool/mail';

# my format from sendmail
$mailboxkind = 'mbox';

# my hunger
$eatinput = 0;

# our logfile
$logfile = $ENV{'HOME'} . '/mailfilter.log';

# our rules file
$rulesfile = $ENV{'HOME'} . '/.mailfilter.rule';

# out split is not needed, its exact
$exact = 0;

# our pools for writing newrule
@pools = ();

# our rules are here ...
@rules = ();


# our directory to check for pools
# we need to have access to this directory for loading code modules
BEGIN {
    @basedirs = ( "." );

    # the dot to read in the things in currend working directory
    push @INC, ".";
    
    my $baseinstall = $0;

    $baseinstall =~ s:[^/]*$::;

    if($baseinstall ne '') {
	# the relative path to work with filter installed in a
	# diffrent directory than the working directory
	push @INC, $baseinstall;
	push @basedirs , $baseinstall;
    }
}


# begin datastructures

use MailTransferRule;

use MailTransferDirList;


# end of datastructs

# import LOCK_* and SEEK_END constants

use Fcntl qw(:flock SEEK_END);


# check parameters

$verbose = 1;
if ($ARGV[0] eq '-q') {
    shift;
    $verbose = 0;
}

$cc = 0;
if ($ARGV[0] eq '-c') {
    shift;
    $cc = 1;
}

if ($ARGV[0] eq '-i') {
    shift;
    my $inc = shift;
}

$exact = 0;
if ($ARGV[0] eq '-e') {
    shift;
    $exact = 1;
}

$traceroute = 0;
if ($ARGV[0] eq '-t') {
    shift;
    $traceroute = 1;
}

if ($ARGV[0] eq '-r') {
    shift @ARGV;
    # this is our rules file 
    $rulesfile = shift @ARGV;
}

if ($ARGV[0] eq '-l') {
    shift @ARGV;
    # this is our log file now 
    $logfile = shift @ARGV;
}

if ($#ARGV < 0 ) {
    &usage();

    exit (1);
}

# the log file 
my $log;

# we always append to it ...
if (!open ($log, ">>$logfile")) {
    print "ERROR001: cannot open $logfile for logging .. \n";
    exit (1);
}

# from now on we have the global log and the helper function
# dolog and dolog_exit

# global ret... 
$gret = 0;

# checks for input rules and settings

if (! -f $rulesfile ) {
    &dolog_exit(1, "ERROR003: rulefile $rulesfile not a file ...");
}

my $rfh ;

if (!open ($rfh, $rulesfile)) {
    &dolog_exit(1, "ERROR004: cannot open $rulesfile for rule read..");
}

# we start at line 0 and set the rulefile linenumber after successful parse ...
$rflnr = &parse_settings($rfh, 0);

# so far the read in was ok ...

if ($themailsystem eq '' ) {
    &dolog_exit(1, "ERROR005: the settings mailsystem is empty. this is an error.");
}

if ($infile eq '' ) {
    &dolog_exit(1, "ERROR006: the settings basedirectory is empty. this is an error.");
}

if ($mailboxdir eq '' ) {
    &dolog_exit(1, "ERROR007: the settings mailboxdir is empty. this is an error.");
}

if ($mailboxkind eq '' ) {
    &dolog_exit(1, "ERROR008: the settings mailboxkind is empty. this is an error.");
}


if (! -d $infile) {
    &dolog_exit(1, "ERROR009: the basedirectory does not exist. this in an error.");
}

# set up the mailsystem thing now
eval {
    $dirlist = MailTransferDirList::factory($themailsystem, $infile, 'targetunknown');

    $dirlist->verbose($verbose);
};

if ($@) {
    &dolog_exit(1, "ERROR010: cannot set up mailsystem : $@");
}

if (! -d $mailboxdir) {
    &dolog_exit(1, "ERROR011: the mailboxdir does not exist. this in an error.");
    exit(1);
}

# later i make also the maildir thing here ...
if ($mailboxkind eq 'mbox'
    ) {
    # ok. we have it
} else {
    &dolog_exit(1, "ERROR012: sorry, but the mailboxkind $mailboxkind is not supported. this is an error.");
}

eval {
    &MailTransferRule::factory ( $rfh, $rflnr, \@rules , $rulesfile);
};

if ($@) {
    &dolog_exit(1, "ERROR013: cannot read in rules : $@");
}

close $rfh;

# here we now do the include if any is in.
# so you have full access to dirlist and to rules and the rest is up to you

if ($inc ne '') {
    if (-r $inc ) {
	eval {
	    require $inc;
	};

	if ($@) {
	    &dolog_exit(1, "ERROR014: cannot compile $inc : $@");
	}
    } else {
	&dolog_exit(1, "ERROR015: cannot open $inc for including code via require ..");
    }
}

# do we have any rules ? 
if ($#rules < 0) {
    &dolog_exit(1, "ERROR016: rulesfile $rulesfile does not contain rules. this is an error. at least one rule must be in.");
}

# we start here ...
&dolog("" , 
       "new filtering start at " . localtime ,
       "mailsystem is $themailsystem",
       "mailsystem directory is $infile",
       "prefix for filtered mails $prefix",
       "mailbox dir $mailboxdir",
       "mailbox kind $mailboxkind",
       "sendmail command $sendmailproc",
       "eat the input if its ok $eatinput",
       "start rulefile is $rulesfile with " . ( $#rules + 1) . " rules");


@sortedrules = sort { $a->{id} <=> $b->{id} } @rules;

foreach my $sr (@sortedrules) {
    &dolog("have rule " . $sr->{id} . " in level " . $sr->{level} . " for file " . $sr->{filename} . " and line " . $sr->{line} );
}


#############################################################################################################
## the main loop

eval {
    # we can now do the filter for every parameter on the line ...
    while ($#ARGV > -1) {
	# is the input mails thing ok ? 
	my $mails = shift @ARGV;
	
	if (! ( -f $mails || -d $mails ) ) {
	    &dolog("ERROR017: mails file or dir $mails is not existing ...");
	    next;
	}


	if ( -f $mails ) {
	    &dolog("scan this file $mails");
	    
	    # we have one file, so its a mbox file ...
	    my $ret = &splitit_and_filter($mails, 
					  $dirlist,  
					  $themailsystem, 
					  \@sortedrules,
					  \@pools);

	    if ($ret == 0 && $eatinput) {
		open(O, ">" .$mails);
		close O;
	    }

	    $gret += $ret;
	    
	    next;

	}

	if ( -d $mails ) {
	    # we have a directory in. so we assume a maildir with cur and new.

	    &dolog("scan this maildir $mails in new and cur");

	    &do_dir($mails, 'new' , $log);

	    &do_dir($mails, 'cur' , $log);
	}
    }

};

if ($@) {
    &dolog("ERROR018: exception ends program $@ ...");
    if ($gret == 0) {
	$gret = 1;
    }
}

&dolog("" , 
       "filtering stop with $gret at " . localtime );

close $log;
  
exit ($gret ? 1 : 0);

# end of main

sub dolog {

    my $l = join("\n", @_);
    
    print $log $l . "\n";     
}

sub dolog_exit{
    my $ret = shift;

    &dolog;

    close $log;
    
    exit($ret);
}

sub parse_settings {

    my $rfh = shift;
    
    my $rflnr = shift;

    # we read in the rules. first the settings part
    my $insettings = 0;

    while (<$rfh>) {
	++$rflnr;
      s:[\s]*$::;
      s:^[\s]*::;
      s:^[\s]*#.*::; # kill comments ...

	next if m:^[\s]*$: ;
	
	if ($insettings == 0 && m:^SETTINGS$:i) {
	    $insettings = 1;
	    next;
	}

	if ($insettings == 1 && m:^MAILSYSTEM[\s]+DIRECTORY[\s]+(.*)$:i) {
	    $infile = $1;
	    next;
	}
	if ($insettings == 1 && m:^MAILSYSTEM[\s]+([\w][\w\-_\d]*)$:i) {
	    $themailsystem = $1;
	    next;
	}
	
	
	if ($insettings == 1 && m:^MAILBOX[\s]+DIRECTORY[\s]+(.*)$:i) {
	    $mailboxdir = $1;
	    next;
	}

	if ($insettings == 1 && m:^MAILBOX[\s]+KIND[\s]+([\w][\w\-_\d]*)$:i) {
	    $mailboxkind = $1;
	    next;
	}

	if ($insettings == 1 && m:^PREFIX[\s]+(.*)$:i) {
	    $prefix = $1;
	    next;
	}

	if ($insettings == 1 && m:^SENDMAIL[\s]+PROGRAM[\s]+(.*)$:i) {
	    $sendmailproc = $1;

	    next;
	}

	if ($insettings == 1 && m:^TRACEROUTE[\s]+COUNT[\s]+([\d]+)$:i) {
	    $traceroutecount = (0 + $1);
	    $traceroutecount = $traceroutecount < 2 ? 2 :  $traceroutecount;
	    next;
	}
	
	if ($insettings == 1 && m:^TRACEROUTE[\s]+PROGRAM[\s]+(.*)$:i) {
	    $tracerouteproc = $1;
	    next;
	}

	if ($insettings == 1 && m:^TRACEROUTE[\s]+([\d]+)$:i) {
	    $traceroute = 0 + $1;
	    next;
	}

	if ($insettings == 1 && m:^EAT[\s]+INPUT[\s]+([\d]+)$:i) {
	    $eatinput = 0 + $1;
	    next;
	}


	if ($insettings == 1 && m:^CC[\s]+([\d]+)$:i) {
	    $cc = 0 + $1;
	    next;
	}

	if ($insettings == 1 && m:^EXACT[\s]+([\d]+)$:i) {
	    $exact = 0 + $1;
	    next;
	}

	if ($insettings == 1 && m:^VERBOSE[\s]+([\d]+)$:i) {
	    $verbose = 0 + $1;
	    next;
	}

	if ($insettings == 1 && m:^POOL[\s]+(.*)$:i) {
	    my $pool = $1;

	    next;
	}

	if ($insettings == 1 && m:^CODE[\s]+(.*)$:i) {
	    my $p = $1;

	    $inc = $p;
	    
	    next;
	}

	if ($insettings == 1 && m:^ENDSETTINGS$:i) {
	    $insettings = 2;
	    last;
	}

	# if we get here something is wrong with settings ...

	&dolog_exit(1, "ERROR019: settings contains unknown things in line $rflnr :\n$_\nThis is an Error ...");
    }

    if ($insettings == 0) {
	&dolog_exit(1, "ERROR020: rulefile $rulesfile does not contain settings. this is an error. at least empty settings are necessary.");
    }

    if ($insettings == 1) {
	&dolog_exit(1, "ERROR021: rulefile $rulesfile does not contain complete settings. this is an error. need ENDSETTINGS...");
    }

    return  $rflnr;
}

sub do_dir {

    my $dir = shift;

    my $subdir = shift;

    my $log = shift;
    
    $t = $dir . '/' . $subdir;
    
    if (-d $t) {
		
	my $dh;
		
	if (!opendir($dh, $t)) {
	    &dolog("ERROR022: the maildir directory $dir cannot be read in $subdir ...");
	} else {
		    
	    my @f = readdir($dh);

	    closedir($dh);

	    foreach my $mfile (@f) {
		my $f = $t . '/' . $mfile;

		if ( -f $f) {
		    # we assume the thing is a mbox file with at least one mail in...
		    my $ret = &splitit_and_filter($f, 
						  $dirlist,  
						  $themailsystem, 
						  \@sortedrules,
						  \@pools);

		    if ($ret == 0 && $eatinput) {
			unlink $f;
		    }
			    
		    $gret += $ret;
			    
		    last if $ret != 0;
		}
	    }
	}
    } else {
	&dolog("ERROR023: the maildir directory $dir cannot be read in $subdir ...");
    }
}

sub splitit_and_filter {
    # some times we need to split mailbox files.
    # this is for one file ...

    my $source = shift;

    my $target = shift; # the dirlist 

    my $flags = shift; # if we have a sylpheed or claws-mail in ...

    my $rules_r = shift;

    my $pools_r = shift;
    
    my $num = 1;

    my $fh ;

    my $ret = 0;
    
    if ( !open($fh, $source) ) {
	&dolog("ERROR024: the file $source cannot be read in ...");
	return 1;
    }

    my @lines = <$fh>;
    
    close $fh;

    &dolog("read in a total of " . ($#lines + 1) . " lines.");

    if ( $#lines > 5 ) {
	my $mail_r = [];

	if ($exact == 1) {
	    my $m = &MailTransferDirData::getamail(\@lines, 0, $log);
	    $m->{bend} = $#lines; # readjust length to full ...
	    $mail_r = [ $m  ]; 
	} else {
	    $mail_r = &MailTransferDirData::get_all_mails (\@lines,  $log);
	}
	
	&dolog("File scanned for mails, found " . ($#$mail_r + 1 ) . " mails ..");

	if ( $#$mail_r > -1 ) {
	    if ($traceroute) {

		&clean_old_traces;
		
		my $tracescript = '#!/bin/bash ' . "\n";

		my $lnr = 1;
		for (my $k = 0; $k <= $#$mail_r; ++$k) {
		    my $f_r = $mail_r->[$k];

		    next if $f_r->{hend} == -1 ; # ups in last line of emptyness
		
		    next if $f_r->{hend} == undef ; # ups in last line of emptyness

		    my $trout = '.mailfilter_trc_' . ($k + 0) . '.trc';

		    $tracescript .= '# tr ' . ($k + 0) . "\n";
		    
		    my $t = $f_r->gen_or_reuse_traceroute($trout, $tracerouteproc, $traceroute);

		    $tracescript .= $t . "\n";
		    
		    if ($t =~ m:nohup[\s]:) {
			$lnr++;
			$tracescript .= "wait\n" if ($lnr % $traceroutecount) == 0;
		    }
		}

		$tracescript .= "\nwait\nexit 0\n\n";
		
		my $ts = ".mailfilter_traceroute_" . $$ . ".sh";
		my $fh ;

		unlink $ts;
		
		open($fh, "> " . $ts) ;
		
		my $pret = print $fh $tracescript;

		close $fh;

		if ($pret == 1) {
		    my $tcmd = '/bin/bash ' . $ts . ' ';
		
		    my $ret = system $tcmd;

		    if ($ret == 0) {
		    
			for (my $k = 0; $k <= $#$mail_r; ++$k) {
			    my $f_r = $mail_r->[$k];

			    next if $f_r->{hend} == -1 ; # ups in last line of emptyness
		
			    next if $f_r->{hend} == undef ; # ups in last line of emptyness
			
			    next if $f_r->skip_traceroute == 0;

			    eval {
				$f_r->load_traceroute;
			    };

			    if ($@) {
				&dolog_exit(1, "ERROR025: cannot read in trace output for $k : $@ ...");
			    }
			}
		    }
		} else {
		    &dolog_exit(1, "ERROR026: cannot write trace script ...");
		}

		# we now delete the script ..
		unlink $ts;
	    } else {
		# we have no traceroute to do, 
		# but if we have a traceroute in the mail 
		# from a filter before we use it
		for (my $k = 0; $k <= $#$mail_r; ++$k) {
		    my $f_r = $mail_r->[$k];

		    next if $f_r->{hend} == -1 ; # ups in last line of emptyness
		
		    next if $f_r->{hend} == undef ; # ups in last line of emptyness

		    $f_r->gen_or_reuse_traceroute( ' ', $tracerouteproc, $traceroute);
		}
	    }
	    
	    for (my $k = 0; $k <= $#$mail_r; ++$k) {
		my $f_r = $mail_r->[$k];

		next if $f_r->{hend} == -1 ; # ups in last line of emptyness
		
		next if $f_r->{hend} == undef ; # ups in last line of emptyness
		
		if ($cc) {
		    my $fh;

		    open ($fh, ">m" . $f_r->{id} . ".txt");
		    
		    eval {
			$f_r->write($fh);
		    };

		    if ($@) {
			&dolog_exit(1, "ERROR027: cannot write carbon copy of mail $k : $@ ...");
		    }
	    
		    close $fh;
		}
	
		my $ret = &filter_one_mail($target, 
					 $num, 
					 $f_r, 
					 $flags, 
					 $rules_r, 
					 $pools_r);

		if ($ret != 0) {
		    &dolog("ERROR028: split made error " . ($num - 1) . "  ...");
		    return 1;
		}

		++ $num;
	    }
	} else {
	    # no mails ... hm .. i thing about it ...
	    &dolog("ERROR029: the file $source has no amils in  ...");
	    return 1;
	}
    } else {
	# hm, only 5 lines .. really  ... i think about it ...
	&dolog("ERROR030: the file $source has only 4 lines or less in  ...");
	return 1;
    }
    
    &dolog("split made " . ($num - 1) . " new mails ...");
    
    return 0;
}

sub clean_old_traces {
    my $dh;
		
    opendir ($dh, ".");

    my @fs = readdir($dh);

    closedir($dh);

    foreach my $trc (@fs) {
	if ($trc =~ m:^\.mailfilter_trc_[\d]+\.trc$:) {
	    unlink $trc;
	}
    }
}

sub filter_one_mail {
    # helper. we have a synthetic file to create
    # mail is in the array per ref, log is in fh ..
    my $targetdir = shift;

    my $num = shift;

    my $a_r = shift;

    my $flags = shift ; # if we have a slypheed in ...

    my $r = shift ;

    my $pools_r = shift ;
    
    my $ret = 0;

    my $hend = $a_r->{hend};

    if ($hend < 1) {
	&dolog("ERROR031: header not found for mail $num ...");
	return 1;
    }

    ++$gcnt;

    # print "vorher " . $gcnt . "\n";
    
    # $a_r->do_traceroute();
    
    # print "nachher " . $gcnt . "\n";
    
    # we rest the global erg to 0
    &MailTransferRule::set_lasterg( 0 );
    
    # we give in : header, startline, endline, 
    # body, startline, endline,
    # all, startline, endline,
    # log
    # dirlist
    # actual number of the mail

    foreach my $rule (@{$r}) {
	my ($ret,$stopit) = $rule->apply($a_r,
					 $log, 
					 $targetdir, 
					 $num,
					 $mailboxkind,
					 $mailboxdir,
					 $sendmailproc,
					 $prefix,
					 $pools_r);
	
	if ($ret != 0) {
	    return 1;
	}

	if ($stopit != 0) {
	    return 0;
	}
    }
 
    return 0;
}

sub usage {

print 'usage: perl MailFilter.pl  [-q] [-c] [-i perlcodefile ] 
                [-e] [-t] [ -r rules ] [ -l log ] mailboxfile [ mailboxfile .... ] 

-q : do it as quiete as possible

-c : make a copy of each mail in filesystem with m<number>.txt as name

-i : we include after setup all things includeing rules  the perlcodefile
     you can don waht you want here, even kill the thing.
     its lodaed with require. so dont forget a 1 ; ...

-e : exact mode for maildir : dont spilt up the files any more, its one mail

-t : traceroute the candidates

-r rules: a rules file 
  see howto for the rules file 
  default is $HOME/.mailfilter.rule

-l log : the log file 
  default is $HOME/mailfilter.log

mailboxfile : the mail input in mbox format or a maildir directory with mails in new and cur


---------------------------------------------
This is version  ' . $version . '
---------------------------------------------

Where to target the copy ? 


In alphabetic order:

claws-mail

$HOME/Mail

----------------------------------------------

evolution

$HOME/.local/share/evolution/mail/local

----------------------------------------------

kmail 

$HOME/.local/share/akonadi_maildir_resource_0

----------------------------------------------

sylpheed

$HOME/Mail

----------------------------------------------


thunderbird 

$HOME/.thunderbird

see the profile for next, then local folders or others in there ...

----------------------------------------------


seamonkey 

$HOME/.mozilla/seamonkey

see the profile for next, then local folders or others in there ...

----------------------------------------------

vanilla

is a testing and export import helper, so dont try this
if you dont know why you need it...

any folder you choose for a start ... 

----------------------------------------------

At last ...

Of course - first things first. 

Make a copy and try first a 
transfer into a dummy, 
then into the real target.

';
}

# end of file

