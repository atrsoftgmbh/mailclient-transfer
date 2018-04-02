#!/usr/bin/perl

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# execute the plan version of the target tree

# we use the plan input folder names.
# we use the plan output folder names.

# we echo all info. then we ask for the final go / nogo
$verbose = 1;

# our data structures ...
$version = '1.0.0';

BEGIN {
    push @INC, ".";
}

use MailTransferDirList;


# end of datastructs


# check parameters

$verbose = 1;
if ($ARGV[0] eq '-y') {
    $verbose = 0;
    shift;
}

if ($#ARGV < 2 ) {
  &usage ;

  exit(1);
  
}

$themailsystem = shift @ARGV;

$infile = shift @ARGV;

$dirlist = MailTransferDirList::factory($themailsystem, $infile, 'dummy');

$outfile = shift @ARGV;


my $ifh;

open($ifh, "$infile") or die "ERROR002: cannot open $infile for read...\n";

my $ret = $dirlist->load_plan($ifh);

if ($ret != 0) {
    print "ERROR003: something went wrong in load plan \n";
    exit(1);
}

close $ifh;

my $ofh;
    
if ($ret == 0) {

    open($ofh, ">$outfile") or die "ERROR004: cannot open $outfile for write log. \n";
    
    if ($verbose) {
	print "plan loaded. if you want to execute, press any key. \n";
	print "if you want to abort, press ctrl-C or whatever you need to... \n";

	$inp = <>;

	if ($inp =~ m:^(N|NO|n|no):) {
	    exit(1);
	}
    }
    
    $ret = $dirlist->execute($ofh);

    if($ret != 0) {
	print "ERROR005: something went wrong in execution of plan...\n";
	exit(1);
    }
}

close $ofh;

exit ($ret);

# end of main

sub usage {
    print 'perl MailTransferExec.pl [-y] mailsystem planfile logfile

-y: do it without a question

mailsystem : the target system, one of 
    vanilla
    claws-mail
    evolution
    kmail
    mutt
    sylpheed
    seamonkey
    thunderbird
  this has to fit to the plan - sorry for this, but a second check 
  here is better than nothing 

planfile : the plan generated from MailTransferGen.pl 

logfile : the log

You can execute the plan from MailTransferGen.pl with this.
You have a limited check for the thing - if you edit the plan careful
you can change at this time the files that are copied.

You can this way transfer till an error happens and adjust the plan later on. 

The exec will first create the directory structure, then copy the files.
So if you have a bad plan for the structure its no copy at all.
If the copy fails you have the last in the logfile with the trouble ....

Check and remove this from the plan, then re-execute it...

You have to understand that this is too late to change the structure then - 
this will be better done in a full retry, first get rid of the crap you made,
then redo it with a changed scan or plan ...

------------------------------------
This is version ' . $version . '
------------------------------------  
';
}
