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

$verbose = 1;

# our data structure
$version = '1.0.0';

BEGIN {
    push @INC, ".";
}

# our datastructures
use MailTransferDirList;


# end of datastructs


# check parameters

$verbose = 1;
if ($ARGV[0] eq '-q') {
    shift;
    $verbose = 0;
}

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

$outdir  = shift @ARGV;

$infile = shift @ARGV;

if (! -f $infile ) {
    print "ERROR002: scan file not a file $infile \n" if $verbose;
    exit(1);
}

if (! -r $infile ) {
    print "ERROR003: scan file not readable $infile \n" if $verbose;
    exit(1);
}

$dirlist = MailTransferDirList::factory($themailsystem, $infile, $outdir);

$dirlist->verbose($verbose);

# we have to check this

$outfile = shift @ARGV;

my $ofh;

open($ofh, ">$outfile") or die "ERROR004: cannot open $outfile for output write. \n";

if ($prefix  ne '') {
    $dirlist->prefix($prefix);
}

my $ifh;

open($ifh, "$infile") or die "ERROR005: cannot open $infile for read...\n";

my $ret = $dirlist->load($ifh);

if ($ret != 0) {
    print "ERROR006: something went wrong loading scan $infile .. \n" if $verbose;
    exit(1);
}

close $ifh;

# we correct now the prefix if we need to
if ($prefix  ne '') {
    $dirlist->prefix($prefix);
}

if ($prefix  eq 'EMPTY') {
    $dirlist->prefix('');
}

# write out the plan
if ($ret == 0) {
    $ret = $dirlist->gen($ofh);
}

close $ofh;

if ($ret != 0) {
    print "ERROR007: something went wrong in generation of plan ... \n" if $verbose;
}

exit ($ret);

# end of main

sub usage {
    print 'perl MailTransferGen.pl [ -p prefix ] mailsystem maildir scanfile planfile

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

maildir: the base for the new  mails directory tree. you can make a transfer to a dummy, then copy to target...

scanfile: structure analyse file from the source system
  this is normally generated by a scan

planfile: the generated plan
   this is then used in the exec

This is the generator. you create a plan from the infile. the plan can then be revised and executet.

Be sure to know what you do if you change the plan - its ok and possible to do it,
but the thing is not as good checked as the scanfile is.

------------------------------------
This is version ' . $version . '
------------------------------------ 
'; 

}
