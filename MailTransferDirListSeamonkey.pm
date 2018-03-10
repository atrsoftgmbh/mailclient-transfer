
package MailTransferDirListSeamonkey;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the seamonkey way
$version = '1.0.0';

# we are a list after all ...
use parent 'MailTransferDirList';


sub new {

    my $class = shift;

    return $class->SUPER::new('seamonkey', @_);
}

sub add_directory {
    # we add a diretory the seamonkey way

    my $self = shift;

    my $directory = $_[0];

    my @path = split(/\//, $directory);

    if ($#path < 0) {
	# we ignore it
	print "ignored $directory ... \n";
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

    my $ret = $self->gen_traget_structure(\&convert_folder_names_seamonkey, @_);

    return $ret;
}

sub convert_folder_names_seamonkey {
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

    # seamonkey can use a / ... but we dont support that ...
    
    
    
    # we can use a-z  , _ - space  @ EURO
    # ! $ % & ( ) =  PARAGRAPH { [ ] }  ^ + ' ` ´
    # careful: the \ is only one, check the listings in tools for this ...
    # german char work like in locale ä ö ü ß 
    
    # the last dir is not changed in seamonkey now. only the part before...
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

    return \&convert_folder_names_seamonkey;
}

sub filterit {
    # we filter that directries out 
    my $self = shift ;

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

1;
# end of file

