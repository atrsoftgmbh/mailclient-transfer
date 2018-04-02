
package MailTransferDirListThunderbird;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the thunderbird way
$version = '1.0.0';

# we are a list after all ...
use parent 'MailTransferDirList';


sub new {

    my $class = shift;

    return $class->SUPER::new('thunderbird', @_);
}

sub add_directory {
    # we add a diretory the thunderbird way

    my $self = shift;

    my $directory = $_[0];

    my @path = split(/\//, $directory);

    if ($#path < 0) {
	# we ignore it
	print "ignored $directory ... \n" if $self->{'verbose'};
	return;
    }

    my $subdir = '';
    
    
    my ($basename,$normpath) = $self->get_normalized_path(@path);
    
    $self->SUPER::add_directory($directory, $basename, $normpath, $subdir);
}

sub get_normalized_path {
    # we have a real path and make the normalized thing here
    my $self = shift ;
    
    my $path = '';
    my $basepart = '';

    my $dirs = $self->{'sourcefile'};
    
    foreach my $d (@_) {
	my $nd = $d;

	$nd =~ s:\.sbd$::;

	my $msf = $dirs . '/' . $nd . '.msf';
	
	$dirs .= '/' . $d;

	if ( -r $msf ) {
	    $nd = $self->get_from_msf_foldername($msf, $nd);
	} else {
	    # no new name in here ...
	}
	
	$basepart = $nd;
	
	$path .= '/' . $nd;
    }

    return ($basepart,$path);
}

sub gen {

    my $self = shift;

    my $ret = $self->gen_traget_structure(\&convert_folder_names_thunderbird, @_);

    return $ret;
}

sub convert_folder_names_thunderbird {
    my $retdata = '';
    
    my $normpath = shift;

    my $prefix = shift;

    my @parts = split (/\//, $normpath);

    shift @parts;

    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }

    # we will not allow a .
    # we will not allow a ;
    # we will not allow a :
    # we will not allow a <
    # we will not allow a >
    # we will not allow a |
    # we will not allow a "
    # we will not allow a ?
    # we will not allow a ~
    # we will not allow a *
    # we will not allow a #
    foreach $d (@parts) {
	$d =~ s/\./_2E_/g;
	$d =~ s/;/_3B_/g;
	$d =~ s/:/_3A_/g;
	$d =~ s/</_3C_/g;
	$d =~ s/>/_3E_/g;
	$d =~ s/\|/_7C_/g;
	$d =~ s/"/_22_/g;
	$d =~ s/\?/_3F_/g;
	$d =~ s/~/_7E_/g;
	$d =~ s/\*/_2A_/g;
	$d =~ s/#/_23_/g;
    }
    
    my $lastdir = pop @parts;

    # thunderbird can use a / ... but we dont support that ...
    
    
    
    # we can use a-z  , _ - space  @ EURO
    # ! $ % & ( ) =  PARAGRAPH { [ ] }  ^ + ' ` ´
    # careful: the \ is only one, check the listings in tools for this ...
    # german char work like in locale ä ö ü ß 
    
    # the last dir is not changed in thunderbird now. only the part before...
    foreach $d (@parts) {
	$d = $d . '.sbd';
    }

    $retdata = join('/', @parts);

    my %e = ();

    $e{cur} = $retdata ;
    $e{new} = $retdata ;
    $e{tmp} = $retdata ;
    $e{base} = $retdata ;
    $e{meta} = $retdata . '/' . $lastdir ;

    return \%e;
}

sub get_convert {
    # helper : we need the converter in the others ...
    my $self = shift;

    return \&convert_folder_names_thunderbird;
}

sub filterit {
    # we filter that directries out 
    my $self = shift ;

    # the candidate directory path
    my $c = shift;
    
    my $ret = 0;
    
    if ($c =~ m:^\.$:) {
	return 1;
    }
	
    if ($c =~ m:^Inbox$:) {
	return 1;
    }
	
    if ($c =~ m:^Trash$:) {
	return 1;
    }
	
    if ($c =~ m:^Unsent Messages$:) {
	return 1;
    }
	

    # we let it live
    return 0;
}

sub get_find_wanted {
    # the generator for the closure function to help find to find its way ...
    my $self = shift ;

    my $candidates_r = shift;

    my $len = length $self->{'sourcefile'};
    
    return sub {
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
		my $t = substr($File::Find::name , $len);

		$t =~ s:^\/::;
	
		$t =~ s:\.msf$::;

		my $msfonly = $_;

		$msfonly =~ s:\.msf$::;
	    
		if ( index($msfonly, '.') > -1) {
		    # thunderbird and seamonkey does not accept a . as a regular name part, 
		    # so any file with that is not a thunderbird or seamonkey file
		    print "ERROR003: ignore msf file $t ... has a dot in ...\n" if $self->{'verbose'};
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
		    $self->{'total'} += $k;
		    $self->{'anz'} ++;
		    print "found $t ...\n" if $self->{'verbose'};
		    print "total is $k K ...\n" if $self->{'verbose'};
		}

		push @{$candidates_r}, $t;

		return;
	    }

	    if ( index($_, '.') > -1) {
		# thunderbird and seamonkey does not accept a . as a regular name part, 
		# so any file with that is not a thunderbird or seamonkey file
		print "ERROR004: ignore file $_ ... has a dot in ...\n" if $self->{'verbose'};
		return;
	    }
	
	    if ($_ !~ m:\.msf$:) {
		# normal file if no msf is there ... 

	    
		my $msf = $File::Find::name . '.msf';
	    
		if (-f $msf) {
		    # that did we already above ...
		    return;
		}
	    
		my $t = substr($File::Find::name , $len);

		$t =~ s:^\/::;

		if (-s $File::Find::name) {
		    # we have a non zero file ...
		    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
			$atime,$mtime,$ctime,$blksize,$blocks)
			= stat($File::Find::name);
		    my $k = int($size / 1024) + 1;
		    $self->{'total'} += $k;
		    $self->{'anz'} ++;
		    print "found $t ...\n" if $self->{'verbose'};
		    print "total is $k K ...\n" if $self->{'verbose'};
		}
	    
		push @{$candidates_r}, $t;

		return;
	    }	
	}
    } ;
}

1;
# end of file

