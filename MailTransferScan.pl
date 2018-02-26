#!/usr/bin/perl

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# scan the dir structure and change it to the generic structure.

# check files for being mails ...

# the generic format is ...

# a spot to start ? see the howto ...

# our data structure

BEGIN {
    push @INC, ".";
}

use File::Find;

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

if ($#ARGV < 2 ) {
  &usage ;

  exit(1);
}

$themailsystem = shift;

if (
    $themailsystem eq 'vanilla'
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

@candidates = ();

my $ofh;

open($ofh, ">$outfile") or die "cannot open $outfile for output write. \n";

# we dont need a factory

if ($themailsystem eq 'vanilla') {
    $dirlist = new MailTransferDirListVanilla($infile, 'targetunknown');
}

if ($themailsystem eq 'claws-mail') {
    $dirlist = new MailTransferDirListClaws($infile, 'targetunknown');
}

if ($themailsystem eq 'evolution') {
    $dirlist = new MailTransferDirListEvolution($infile, 'targetunknown');
}

if ($themailsystem eq 'kmail') {
    $dirlist = new MailTransferDirListKmail($infile, 'targetunknown');
}

if ($themailsystem eq 'mutt') {
    $dirlist = new MailTransferDirListMutt($infile, 'targetunknown');
}

if ($themailsystem eq 'sylpheed') {
    $dirlist = new MailTransferDirListSylpheed($infile, 'targetunknown');
}

if ($themailsystem eq 'seamonkey') {
    $dirlist = new MailTransferDirListSeamonkey($infile, 'targetunknown');
}

if ($themailsystem eq 'thunderbird') {
    $dirlist = new MailTransferDirListThunderbird($infile, 'targetunknown');
}

if ($prefix  ne '') {
    $dirlist->prefix($prefix);
}

if ($prefix  eq 'EMPTY') {
    $dirlist->prefix('');
}

if ( -d $infile ) {

    chdir($infile);
    
    if ($themailsystem eq 'vanilla') {
	find (\&wanted, $infile);
    } elsif ($themailsystem eq 'claws-mail') {
	find (\&wanted, $infile);
    } elsif ($themailsystem eq 'evolution') {
	find (\&wanted, $infile);
    } elsif ($themailsystem eq 'kmail') {
	find (\&wanted, $infile);
    } elsif ($themailsystem eq 'sylpheed') {
	find (\&wanted, $infile);
    } elsif ($themailsystem eq 'mutt') {
	find (\&wantedmutt, $infile);
    } elsif ($themailsystem eq 'seamonkey') {
	find (\&wantedthunderbirdseamonkey, $infile);
    } elsif ($themailsystem eq 'thunderbird') {
	find (\&wantedthunderbirdseamonkey, $infile);
    } 
}
else {
    open(IN, "$infile") or die "cannot open the input file $infile \n";

     while (<IN>) {

      s:^[\s]*::;
      s:[\s]*$::;

	# special cases. we ignore them ...

	if ($self->filterit($_) ) {
	    &ignore;
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
    print "ERROR001: check that, something was wrong...\n";
}

exit ($ret);

# end of main

sub wanted {
    if (-d $_ ) {
	if (m:^\.$:) {
	    &ignore ;
	    return;
	}
	
	if (m:^\.\.$:) {
	    &ignore ;
	    return;
	}
	
	my $t = substr($File::Find::name , length $infile);

	$t =~ s:^\/::;
	
	if ($dirlist->filterit($t)) {
	    &ignore;
	    return;
	}

	push @candidates, $t;

	return;
    } 
}

sub wantedthunderbirdseamonkey {
    if (-f $_  && -r $_ ) {
	if (m:^Trash.msf$:) {
	    return;
	}
	
	if (m:^Inbox.msf$:) {
	    return;
	}
	
	if (m:^Unsent Messages.msf$:) {
	    return;
	}
	
	if (m:^Trash$:) {
	    return;
	}
	
	if (m:^Inbox$:) {
	    return;
	}
	
	if (m:^Unsent Messages$:) {
	    return;
	}
	
	if (m:\.msf$:) {
	    my $t = substr($File::Find::name , length $infile);

	    $t =~ s:^\/::;
	
	    $t =~ s:\.msf$::;

	    my $msfonly = $_;

	    $msfonly =~ s:\.msf$::;
	    
	    if ( index($msfonly, '.') > -1) {
		# thunderbird and seamonkey does not accept a . as a regular name part, 
		# so any file with that is not a thunderbird or seamonkey file
		print "WARNING: ignore msf file $t ... has a dot in ...\n";
		return;
	    }

	    my $data = $File::Find::name;
	    $data =~ s:\.msf$::;
	    if (-s $data) {
		# we have a non zero file ...
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		    $atime,$mtime,$ctime,$blksize,$blocks)
		    = stat($data);
		my $k = int($size / 1024) + 1;
		$dirlist->{'total'} += $k;
		$dirlist->{'anz'} ++;
		print "found $t ...\n";
		print "total is $k K ...\n";
	    }

	    push @candidates, $t;

	    return;
	}

	if ( index($_, '.') > -1) {
	    # thunderbird and seamonkey does not accept a . as a regular name part, 
	    # so any file with that is not a thunderbird or seamonkey file
	    print "WARNING: ignore file $_ ... has a dot in ...\n";
	    return;
	}
	
	if ($_ !~ m:\.msf$:) {
	    # normal file if no msf is there ... 

	    
	    my $msf = $File::Find::name . '.msf';
	    
	    if (-f $msf) {
		# that did we already above ...
		return;
	    }
	    
	    my $t = substr($File::Find::name , length $infile);

	    $t =~ s:^\/::;

	    if (-s $File::Find::name) {
		# we have a non zero file ...
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		    $atime,$mtime,$ctime,$blksize,$blocks)
		    = stat($File::Find::name);
		my $k = int($size / 1024) + 1;
		$dirlist->{'total'} += $k;
		$dirlist->{'anz'} ++;
		print "found $t ...\n";
		print "total is $k K ...\n";
	    }
	    
	    push @candidates, $t;

	    return;
	}	
    }
}

sub wantedmutt {
    if (-f $_  && -r $_ ) {
	if ($_ =~ m:.:) {
	    # normal file ... 

	    
	    my $t = substr($File::Find::name , length $infile);

	    $t =~ s:^\/::;

	    if (-s $File::Find::name) {
		# we have a non zero file ...
		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
		    $atime,$mtime,$ctime,$blksize,$blocks)
		    = stat($File::Find::name);
		my $k = int($size / 1024) + 1;
		$dirlist->{'total'} += $k;
		$dirlist->{'anz'} ++;
		print "found $t ...\n";
		print "total is $k K ...\n";
	    }
	    
	    push @candidates, $t;

	    return;
	}	
    }
}

sub ignore {
    print "Ignore directory " . $_ . "\n";
}
     
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

