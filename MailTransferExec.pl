#!/usr/bin/perl

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# execute the plan version of the target tree

# we use the plan input folder names.
# we use the plan output folder names.

# we echo all info. then we ask for the final go / nogo

# our data structures ...

BEGIN {
    push @INC, ".";
}

use MailTransferDirListVanilla;

use MailTransferDirListClaws;

use MailTransferDirListEvolution;

use MailTransferDirListKmail;

use MailTransferDirListMutt;

use MailTransferDirListSylpheed;

use MailTransferDirListSeamonkey;

use MailTransferDirListThunderbird;

# end of datastructs


# check parameters

if ($#ARGV < 2 ) {
  &usage ;

  exit(1);
  
}

$themailsystem = shift;

if ($themailsystem eq 'vanilla'
    || $themailsystem eq 'claws-mail'
    || $themailsystem eq 'evolution'
    || $themailsystem eq 'kmail'
    || $themailsystem eq 'mutt'
    || $themailsystem eq 'sylpheed'
    || $themailsystem eq 'seamonkey'
    || $themailsystem eq 'thunderbird'

    ) {
    # we have a valid system in now ...
} else {
    print "sorry, but mailsystem $themailsystem is not supported.\n";
    exit (1);
}


# we read in from input file 
$infile = shift @ARGV;

$outfile = shift @ARGV;

if ($themailsystem eq 'vanilla') {
    $dirlist = new MailTransferDirListVanilla($infile, 'dummy');
}

if ($themailsystem eq 'claws-mail') {
    $dirlist = new MailTransferDirListClaws($infile, 'dummy');
}

if ($themailsystem eq 'evolution') {
    $dirlist = new MailTransferDirListEvolution($infile, 'dummy');
}

if ($themailsystem eq 'kmail') {
    $dirlist = new MailTransferDirListKmail($infile, 'dummy');
}

if ($themailsystem eq 'mutt') {
    $dirlist = new MailTransferDirListMutt($infile, 'dummy');
}

if ($themailsystem eq 'sylpheed') {
    $dirlist = new MailTransferDirListSylpheed($infile, 'dummy');
}

if ($themailsystem eq 'seamonkey') {
    $dirlist = new MailTransferDirListSeamonkey($infile, 'dummy');
}

if ($themailsystem eq 'thunderbird') {
    $dirlist = new MailTransferDirListThunderbird($infile, 'dummy');
}

my $ifh;

open($ifh, "$infile") or die "cannot open $infile for read...\n";

my $ret = $dirlist->load_plan($ifh);

if ($ret != 0) {
    print "ERROR004: something went wrong in load plan \n";
    exit(1);
}

close $ifh;

if ($ret == 0) {

    my $ofh;
    
    open($ofh, ">$outfile") or die "ERROR005: cannot open $outfile for write log. \n";
    
    print "plan loaded. if you want to execute, press any key. \n";
    print "if you want to abort, press ctrl-C or whatever you need to... \n";

    $inp = <>;

    if ($inp =~ m:^(N|NO|n|no):) {
	exit(1);
    }
    
    $ret = $dirlist->execute($ofh);

    if($ret != 0) {
	print "ERROR006: something went wrong in execution of plan...\n";
	exit(1);
    }
}

close $ofh;

exit ($ret);

# end of main

sub usage {
    print 'perl MailTransferExec.pl mailsystem planfile logfile

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
  
';
}