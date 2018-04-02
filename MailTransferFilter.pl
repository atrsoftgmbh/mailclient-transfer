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

# we need to have access to this directory for loading code modules
BEGIN {
    push @INC, ".";
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

    if (! -r $inc ) {
	die "cannot find include file $inc ...\n";
    }
}

$exact = 0;
if ($ARGV[0] eq '-e') {
    shift;
    $exact = 1;
}

if ($ARGV[0] eq '-r') {
    shift @ARGV;
    # this is our rules file 
    $rulesfile = shift @ARGV;
}

if ($ARGV[0] eq '-l') {
    shift @ARGV;
    # this is our log file 
    $logfile = shift @ARGV;
}

if ($#ARGV < 0 ) {
    &usage();

    exit (1);
}

# global ret... 
$gret = 0;

# checks for input rules and settings

if (! -f $rulesfile ) {
    print "ERROR001: rulefile $rulesfile not a file ...\n" if $verbose;
    exit (1);
}

@rules = ();

my $rfh ;

if (!open ($rfh, $rulesfile)) {
    print "ERROR041: cannot open $rulesfile for rule read..\n" if $verbose;
    exit (1);
}

# we read in the rules. first the settings part
my $insettings = 0;

while (<$rfh>) {
  s:[\s]*$::;
  s:^[\s]*::;
  s:^[\s]*#.*::; # kill comments ...
    
    if ($insettings == 0 && m:^[\s]*SETTINGS$:i) {
	$insettings = 1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*MAILSYSTEM[\s]+([\w][\w\-_\d]*)$:i) {
	$themailsystem = $1;
	next;
    }
    
    if ($insettings == 1 && m:^[\s]*BASEDIRECTORY[\s]+(.*)$:i) {
	$infile = $1;
	next;
    }
    
    if ($insettings == 1 && m:^[\s]*MAILBOXDIR[\s]+(.*)$:i) {
	$mailboxdir = $1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*PREFIX[\s]+(.*)$:i) {
	$prefix = $1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*SENDMAIL[\s]+(.*)$:i) {
	$sendmailproc = $1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*EAT_INPUT[\s]+([\d]+)$:i) {
	$eatinput = 0 + $1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*EXACT[\s]+([\d]+)$:i) {
	$exact = 0 + $1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*POOL[\s]+(.*)$:i) {
	my $pool = $1;

	if (-d $pool) {
	    push @pools, $pool;
	} else {
	    die "ERROR033: pool not existing $pool ..\n";
	}
	
	next;
    }

    if ($insettings == 1 && m:^[\s]*CODE[\s]+(.*)$:i) {
	my $p = $1;

	if (-r $p) {
	    $inc = $p;
	} else {
	    die "ERROR034: include not existing $p ..\n";
	}
	
	next;
    }

    if ($insettings == 1 && m:^[\s]*MAILBOXKIND[\s]+([\w][\w\-_\d]*)$:i) {
	$mailboxkind = $1;
	next;
    }

    if ($insettings == 1 && m:^[\s]*ENDSETTINGS$:i) {
	$insettings = 2;
	last;
    }
}

if ($insettings == 0) {
    print "ERROR002: rulefile $rulesfile does not contain settings. this is an error. at least empty settings are necessary.\n" if $verbose;
    exit (1);
}

if ($insettings == 1) {
    print "ERROR003: rulefile $rulesfile does not contain complete settings. this is an error. need ENDSETTINGS...\n" if $verbose;
    exit (1);
}


if ($themailsystem eq '' ) {
    print "ERROR004: the settings mailsystem is empty. this is an error.\n" if $verbose;
    exit (1);
}

if ($infile eq '' ) {
    print "ERROR005: the settings basedirectory is empty. this is an error.\n" if $verbose;
    exit (1);
}

if ($mailboxdir eq '' ) {
    print "ERROR006: the settings mailboxdir is empty. this is an error.\n" if $verbose;
    exit (1);
}

if ($mailboxkind eq '' ) {
    print "ERROR007: the settings mailboxkind is empty. this is an error.\n" if $verbose;
    exit (1);
}


if (! -d $infile) {
    print "ERROR009: the basedirectory does not exist. this in an error.\n" if $verbose;
    exit(1);
}

# set up the mailsystem thing now

$dirlist = MailTransferDirList::factory($themailsystem, $infile, 'targetunknown');


$dirlist->verbose($verbose);

if (! -d $mailboxdir) {
    print "ERROR010: the mailboxdir does not exist. this in an error.\n" if $verbose;
    exit(1);
}

# later i make also the maildir thing here ...
if ($mailboxkind eq 'mbox'
    ) {
    # ok. we have it
} else {
    print "ERROR011: sorry, but the mailboxkind $mailboxkind is not supported. this is an error.\n" if $verbose;
    exit (1);
}

&MailTransferRule::factory ( $rfh , \@rules , $rulesfile);

close $rfh;

# the log file 
my $log;

# we always append to it ...
if (!open ($log, ">>$logfile")) {
    print "ERROR014: cannot open $logfile for logging .. \n" if $verbose;
    exit (1);
}


# here we now do the include if any is in.
# so you have full access to dirlist and to rules and the rest is up to you
if (-r $inc ) {
    require $inc;
}

# do we have any rules ? 
if ($#rules < 0) {
    print $log "ERROR012: rulesfile $rulesfile does not contain rules. this is an error. at least one rule must be in.\n" if $verbose;

    close$log;
    
    exit (1);
}

# we start here ...
print $log "\nnew filtering start at " . localtime . "\n";
print $log "Mailsystem is $themailsystem\n";
print $log "Basedirectory is $infile\n";
print $log "Prefix for filtered mails $prefix\n";
print $log "Mailboxdir $mailboxdir\n";
print $log "Mailboxkind $mailboxkind\n";
print $log "Sendmail command $sendmailproc\n";
print $log "Eat the input if its ok $eatinput \n";
print $log "Start Rulefile is $rulesfile with " . ( $#rules + 1) . " rules \n";


@sortedrules = sort { $a->{id} <=> $b->{id} } @rules;

foreach my $sr (@sortedrules) {
    print $log "have rule " . $sr->{id} . " " . $sr->{level} . " " . $sr->{filename} . "\n";
}

# we can now do the filter for every parameter on the line ...
while ($#ARGV > -1) {
    # is the input mails thing ok ? 
    my $mails = shift @ARGV;
    
    if (! ( -f $mails || -d $mails ) ) {
	print $log "ERROR013: mails file or dir $mails is not existing ...\n" if $verbose;
	next;
    }


    if ( -f $mails ) {
	print $log "Scan this file $mails \n";
    
	# we have one file, so its a mbox file ...
	my $ret = &splitit_and_filter($log, 
				      $mails, 
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

	print $log "Scan this maildir $mails in new and cur\n";

	my $t = $mails . '/new' ;

	if (-d $t ) {
	    
	    my $dh;

	    if ( !opendir($dh, $t) ) {
		print $log "ERROR015: the maildir directory $mails cannot be read in new ...\n" if $verbose;

	    } else {

		my @f = readdir($dh);

		closedir($dh);

		foreach my $mfile (@f) {
		    my $f = $t . '/' . $mfile;
		
		    if ( -f $f) {
			# we assume the thing is a mbox file with at least one mail in...
			my $ret = &splitit_and_filter($log,  
						      $f, 
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
	    print $log "ERROR015: the maildir directory $mails cannot be read in new ...\n" if $verbose;
	}

	$t = $mails . '/cur' ;
	
	if (-d $t) {
	
	    my $dh;
	
	    if (!opendir($dh, $t)) {
		print $log "ERROR016: the maildir directory $mails cannot be read in cur ...\n" if $verbose;
	    } else {
	    
		my @f = readdir($dh);

		closedir($dh);

		foreach my $mfile (@f) {
		    my $f = $t . '/' . $mfile;

		    if ( -f $f) {
			# we assume the thing is a mbox file with at least one mail in...
			my $ret = &splitit_and_filter($log, 
						      $f, 
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
		print $log "ERROR016: the maildir directory $mails cannot be read in cur ...\n" if $verbose;
	}
    }
}

print $log "\nfiltering stop with $gret at " . localtime . " \n";

close $log;
  
exit ($gret ? 1 : 0);

# end of main

sub splitit_and_filter {
    # some times we need to split mailbox files.
    # this is for one file ...

    my $logfh = shift ;

    my $source = shift;

    my $target = shift; # the dirlist 

    my $flags = shift; # if we have a sylpheed or claws-mail in ...

    my $rules_r = shift;

    my $pools_r = shift;
    
    my $num = 1;

    my $fh ;

    my $ret = 0;
    
    if ( !open($fh, $source) ) {
	return 1;
    }

    my @lines = <$fh>;
    
    close $fh;

    print $logfh "read in a total of " . ($#lines + 1) . " lines.\n";

    if ( $#lines > 5 ) {
	my $mail_r = [];

	if ($exact == 1) {
	    my $m = &MailTransferDirData::getamail(\@lines, 0, $logfh);
	    $m->{bend} = $#lines;
	    $mail_r = [ $m  ]; 
	} else {
	    $mail_r = &MailTransferDirData::get_all_mails (\@lines,  $logfh);
	}
	print $logfh "File scanned for mails, found " . ($#$mail_r + 1 ) . " mails ..\n";

	if ( $#$mail_r > -1 ) {
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
	    
		    close $fh;
		}
	
		my $ret = &filter_one_mail($target, 
					 $num, 
					 $f_r, 
					 $logfh, 
					 $flags, 
					 $rules_r, 
					 $pools_r);

		if ($ret != 0) {
		    print $logfh "split made error " . ($num - 1) . "  ...\n";
		    return 1;
		}

		++ $num;
	    }
	} else {
	    # no mails ... hm .. i thing about it ...
	}
    } else {
	# hm, only 5 lines .. really  ... i think about it ...
    }
    
    print $logfh "split made " . ($num - 1) . " new mails ...\n";
    
    return 0;
}


sub filter_one_mail {
    # helper. we have a synthetic file to create
    # mail is in the array per ref, log is in fh ..
    my $targetdir = shift;

    my $num = shift;

    my $a_r = shift;

    my $log = shift ;

    my $flags = shift ; # if we have a slypheed in ...

    my $r = shift ;

    my $pools_r = shift ;
    
    my $ret = 0;

    my $hend = $a_r->{hend};

    if ($hend < 1) {
	print $log "ERROR016: header not found for mail $num ...\n";
	return 1;
    }


    # we rest the global erg to 0
    &MailTransferRule::set_lasterg( 0 );
    
    # we give in : header, startline, endline, 
    # body, startline, endline,
    # all, startline, endline,
    # log
    # dirlist
    # actual number of the mail

    my $text = $a_r->{text};

    my $hstart = $a_r->{hstart};

    
    my $bstart = $a_r->{bstart};
    my $bend = $a_r->{bend};
    
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
                [-e] [ -r rules ] [ -l log ] mailboxfile [ mailboxfile .... ] 

-q : do it as quiete as possible

-c : make a copy of each mail in filesystem with m<number>.txt as name

-i : we include after setup all things includeing rules  the perlcodefile
     you can don waht you want here, even kill the thing.
     its lodaed with require. so dont forget a 1 ; ...

-e : exact mode for maildir : dont spilt up the files any more, its one mail

rules: a rules file 
  see howto for the rules file 
  default is $HOME/.mailfilter.rule

log : the log file 
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

