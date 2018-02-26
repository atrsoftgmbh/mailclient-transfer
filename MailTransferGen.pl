#!/usr/bin/perl

# atrsoftgmbh 2018
# part of the MailTransfer script system
#

# generate the target plan

# we use the normalized input file folder names.

# for evolution there is a bit to change.
# names with _ or . get a escaped name ...
# escape is done by using _XX instead of the char in queston
# so its a _2E for . and _5F for _ itself ...
# we do it to the normalized namens, then build the target description
#
# for others there are similar changes, see the code in doubt...
#
# most complicated thing is thunderbird and seamonkey ...
#
# we still dont transfer, its a blueprint for the last step, the transfer.

# our data structure

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

$prefix = '';
if ($ARGV[0] eq '-p') {
    shift;
    $prefix = shift;
}


if ($#ARGV < 3 ) {
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

$outdir  = shift @ARGV;

$outfile = shift @ARGV;

my $ofh;

open($ofh, ">$outfile") or die "cannot open $outfile for output write. \n";

if ($themailsystem eq 'vanilla') {
    $dirlist = new MailTransferDirListVanilla($infile, $outdir);
}

if ($themailsystem eq 'claws-mail') {
    $dirlist = new MailTransferDirListClaws($infile, $outdir);
}

if ($themailsystem eq 'evolution') {
    $dirlist = new MailTransferDirListEvolution($infile, $outdir);
}

if ($themailsystem eq 'kmail') {
    $dirlist = new MailTransferDirListKmail($infile, $outdir);
}

if ($themailsystem eq 'mutt') {
    $dirlist = new MailTransferDirListMutt($infile, $outdir);
}

if ($themailsystem eq 'sylpheed') {
    $dirlist = new MailTransferDirListSylpheed($infile, $outdir);
}

if ($themailsystem eq 'thunderbird') {
    $dirlist = new MailTransferDirListThunderbird($infile, $outdir);
}

if ($themailsystem eq 'seamonkey') {
    $dirlist = new MailTransferDirListSeamonkey($infile, $outdir);
}

if ($prefix  ne '') {
    $dirlist->prefix($prefix);
}

my $ifh;

open($ifh, "$infile") or die "cannot open $infile for read...\n";

my $ret = $dirlist->load($ifh);

if ($ret != 0) {
    print "ERROR002: something went wrong loading scan .. \n";
    exit(1);
}

close $ifh;

if ($prefix  ne '') {
    $dirlist->prefix($prefix);
}

if ($prefix  eq 'EMPTY') {
    $dirlist->prefix('');
}

if ($ret == 0) {
    $ret = $dirlist->gen($ofh);
}

close $ofh;

if ($ret != 0) {
    print "ERROR003:something went wrong in generation of plan ... \n";
}

exit ($ret);

# end of main

sub usage {
    print 'perl MailTransferGen.pl [ -p prefix ] mailsystem infile maildir planfile

perfix : prefix directory in target overwrite or EMPTY

mailsystem: the target mail system - one of 
    vanilla,
    claws-mail,
    evolution, 
    kmail, 
    mutt,
    sylpheed,
    seamonkey,
    thunderbird

infile: structure analyse file from the source system
  this is normally generated by a scan

maildir: the base for the new  mails directory tree. you can make a transfer to a dummy, then copy to target...

planfile: the generated plan
   this is then used in the exec

This is the generator. you create a plan from the infile. the plan can then be revised and executet.

Be sure to know what you do if you change the plan - its ok and possible to do it,
but the thing is not as good checked as the infile is.
 
'; 

}