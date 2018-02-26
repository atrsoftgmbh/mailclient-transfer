
package MailTransferDirListSylpheed;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the sylpheed way

# we are a list after all
use parent 'MailTransferDirList';


sub new {

    my $class = shift;

    my $self = $class->SUPER::new('sylpheed', @_);

    $self->{'copyflags'} = 'sylpheed';
    
    return $self;
}

sub add_directory {
    # we do the sylpheed stuff for nameing..
    my $self = shift;

    my $directory = $_[0];

    # specific code for sylpheed ...
    my @path = split(/\//, $directory);

    if ($#path < 0) {
	# we ignore it
	print "ignored $directory ... \n";
	return;
    }

    my $subdir = 'sylpheed';
    
    my ($basename,$normpath) = &get_normalized_path(@path);
    
    $self->SUPER::add_directory($directory, $basename, $normpath, $subdir);
}

sub get_normalized_path {
    # we do the sylpheed to normal thing here
    my $ret = '';
    my $b = '';
    
    foreach my $d (@_) {
	my $nd = $d;

	$b = $nd;
	
	$ret .= '/' . $nd;
    }

    return ($b,$ret);
}

sub gen {

    my $self = shift;

    my $ret = $self->gen_traget_structure(\&convert_folder_names_sylpheed, @_);

    return $ret;
}

sub convert_folder_names_sylpheed {
    # we have to adjust only minimum for sylpheed here
    my $retdata = '';
    
    my $normpath = shift;

    my $prefix = shift;

    my @parts = split (/\//, $normpath);

    shift @parts;

    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }

    # we cant use a / in sylpheed
    # we can use a-z < > | , ; : _ - space . @ EURO
    # ! " $ % & ( ) = ? PARAGRAPH { [ ] } ~ ^ * + ' # ` ´
    # careful: the \ is only one, check the listings in tools for this ...
    # german char work like in locale ä ö ü ß 
    
    # the last dir is not changed in kmail now. only the part before...
    $retdata = join('/', @parts);

    my %e = ();

    $e{cur} = $retdata ;
    $e{new} = $retdata ;
    $e{tmp} = $retdata ;
    $e{base} = $retdata ;
    $e{meta} = '' ;

    return \%e;
}


sub filterit {
    # what we dont transfer from kmail
    my $self = shift ;

    my $c = shift;
    
    my $ret = 0;

    if ($c =~ m:^inbox$:) {
 	return 1;
    }
	
    if ($c =~ m:^junk$:) {
 	return 1;
    }
	
    if ($c =~ m:^queue$:) {
 	return 1;
    }
	
    if ($c =~ m:^trash$:) {
 	return 1;
    }
	

    # we let it live
    return 0;
}

1;
# end of file

