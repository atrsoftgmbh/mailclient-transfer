
package MailTransferDirListClaws;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the claws-mail way
$version = '1.0.0';

# we are a list after all
use parent 'MailTransferDirList';


sub new {

    my $class = shift;
    
    my $self = $class->SUPER::new('claws-mail', @_);
    
    $self->{'copyflags'} = 'claws-mail';
    
    return $self;
}

sub add_directory {
    # we do the claws-mail stuff for nameing..
    my $self = shift;
    
    my $directory = $_[0];
    
    # specific code for claws-mail ...
    my @path = split(/\//, $directory);
    
    if ($#path < 0) {
	# we ignore it
	print "ignored $directory ... \n";
	return;
    }

    my $subdir = $self->{'copyflags'};
    
    my ($basename,$normpath) = $self->get_normalized_path(@path);
    
    $self->SUPER::add_directory($directory, $basename, $normpath, $subdir);
}

sub get_normalized_path {
    my $self = shift;

    # we do the claws-mail to normal thing here
    my $path = '';
    my $basedir = '';
    
    foreach my $d (@_) {
	my $nd = $d;
	
	$basedir = $nd;
	
	$path .= '/' . $nd;
    }
    
    return ($basedir,$path);
}

sub gen {

    my $self = shift;
    
    my $ret = $self->gen_traget_structure(\&convert_folder_names_claws, @_);
    
    return $ret;
}

sub convert_folder_names_claws {
    # we have to adjust only minimum for claws here
    my $retdata = '';
    
    my $normpath = shift;
    
    my $prefix = shift;
    
    my @parts = split (/\//, $normpath);
    
    shift @parts;
    
    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }
    
    # we cant use a / in claws
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

sub get_convert {
    # helper : we need the converter in the others ...
    my $self = shift;

    return \&convert_folder_names_claws;
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

sub get_find_wanted {
    # the generator for the closure function to help find to find its way ...
    my $self = shift ;

    my $candidates_r = shift;

    my $len = length $self->{'sourcefile'};
    
    return sub {
	if (-d $_ ) {
	    if (m:^\.$:) {
		print "ERROR005: Ignore directory " . $_ . "\n" if $self->{'verbose'};
		return;
	    }
	
	    if (m:^\.\.$:) {
		print "ERROR005: Ignore directory " . $_ . "\n" if $self->{'verbose'};
		return;
	    }
	
	    my $t = substr($File::Find::name , $len);

	    $t =~ s:^\/::;
	
	    if ($self->filterit($t)) {
		print "ERROR005: Ignore directory " . $_ . "\n" if $self->{'verbose'};
		return;
	    }

	    push @{$candidates_r}, $t;

	    return;
	} 

    };
}

1;
# end of file

