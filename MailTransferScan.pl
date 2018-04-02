#!/usr/bin/perl

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# scan the dir structure and change it to the generic structure.

# check files for being mails ...

# the generic format is ...

# a spot to start ? see the howto ...

# our data structure
$version = '1.0.0';

BEGIN {
    push @INC, ".";
}

# our data structures
use MailTransferDirList;

# end of datastructs

# we use the find to scan a tree of directories
use File::Find;


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

if ($#ARGV < 2 ) {
  &usage ;

  exit(1);
}

$themailsystem = shift;

# we read in from input file 
$infile = shift @ARGV;

$dirlist = MailTransferDirList::factory($themailsystem, $infile, 'targetunknown');

$dirlist->verbose($verbose);

$outfile = shift @ARGV;

@candidates = ();

my $ofh;

open($ofh, ">$outfile") or die "ERROR007: cannot open $outfile for output write. \n";


if ($prefix  ne '') {
    $dirlist->prefix($prefix);
}

if ($prefix  eq 'EMPTY') {
    $dirlist->prefix('');
}

if ( -d $infile ) {

    chdir($infile);

    my $wanted_r = $dirlist->get_find_wanted (\@candidates);
    
    find ($wanted_r, $infile);
}
else {
    open(IN, "$infile") or die "ERROR008: cannot open the input file $infile \n";

     while (<IN>) {

      s:^[\s]*::;
      s:[\s]*$::;

	# special cases. we ignore them ...

	if ($dirlist->filterit($_) ) {
	    print "ERROR005: Ignore directory " . $_ . "\n" if $verbose;
	    next;
	}


	# ok. 

	push @candidates, $_;
    }


    close IN;
}

foreach my $c (@candidates) {
    $dirlist->add_directory($c);
}

$ret = $dirlist->save($ofh);

close $ofh;

if ($ret == 0) {
    my $t = $dirlist->total();

    my $anz = $dirlist->anz();

    print "you have a total of " . $anz . " files with " . $t . " K ... check your free disk ..\n";
} else {
    print "ERROR002: check that, something was wrong...\n";
}

exit ($ret);

# end of main

sub usage {

print 'usage: perl MailTransferScan.pl  [ -p prefix ]  mailsystem findlistfile|sourcedirectory outfile

mailsystem : name of the mailsystem that is scanned in (at now): 
   vanilla 
   claws-mail 
   evolution 
   kmail
   slypheed,
   seamonkey,
   thunderbird 

prefix : a prefix directory/folder - OR EMPTY - for the output structure to integrate 
   on lowest level - this helps to keep old mails in a separate tree
  in the new system... 

findlistfile: list of directorys in find format. see find command for this
   find . -type d
   or find sourcedir -type d

sourcedirectory : path to the directory to scan with the buildin scanner

outfile : file that holds the generic structinfo for checker 
   and generator - the important file you make with this script..

The resulting outfile is input for a checker or for a generator for plan.

You can edit the outfile to make things fit to your needs, see the
howto file for this. 

---------------------------------------------
This is version ' . $version . '
---------------------------------------------
Where to start the scan ?


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

