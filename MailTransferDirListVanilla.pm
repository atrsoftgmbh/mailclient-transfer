
package MailTransferDirListVanilla;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the maildir vanilla way
$version = '1.0.0';

# we are a list after all
use parent 'MailTransferDirList';


sub new {

    my $class = shift;

    return $class->SUPER::new('vanilla', @_);
}

sub add_directory {
    # we do the vanilla stuff for nameing..
    my $self = shift;

    my $directory = $_[0];

    # specific code for vanilla ...
    my @path = split(/\//, $directory);

    if ($#path < 0) {
	# we ignore it
	print "ignored $directory ... \n";
	return;
    }

    my $subdir = '';
    
    if ($path[$#path] eq 'new') {
	# we have a new subdirectory at last ...
	$subdir = pop @path;
    } elsif ($path[$#path] eq 'cur') {
	# we have a cur subdirectory at last ...
	$subdir = pop @path;
    } elsif ($path[$#path] eq 'tmp') {
	# we have a tmp subdirectory at last ...
	$subdir = pop @path;
    }
    
    my ($basename,$normpath) = $self->get_normalized_path(@path);
    
    $self->SUPER::add_directory($directory, $basename, $normpath, $subdir);
}

sub get_normalized_path {
    my $self = shift;
    
    # we do the vanilla to normal thing here
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

    my $ret = $self->gen_traget_structure(\&convert_folder_names_vanilla, @_);

    return $ret;
}

sub convert_folder_names_vanilla {
    # we have to adjust only minimum for vanilla here
    my $retdata = '';
    
    my $normpath = shift;

    my $prefix = shift;

    my @parts = split (/\//, $normpath);

    shift @parts;

    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }

    # we cant use a / in vanilla
    # we can use a-z < > | , ; : _ - space . @ EURO
    # ! " $ % & ( ) = ? PARAGRAPH { [ ] } ~ ^ * + ' # ` ´
    # careful: the \ is only one, check the listings in tools for this ...
    # german char work like in locale ä ö ü ß 
    foreach $d (@parts) {
	$d =~ s:\\:_BACKSLASH_:g;
	$d =~ s:\.:_DOT_:g;
	$d =~ s:\/:_SLASH_:g;
    }
    
    $retdata = join('/', @parts);

    my %e = ();

    $e{cur} = $retdata . '/cur';
    $e{new} = $retdata . '/new';
    $e{tmp} = $retdata . '/tmp';
    $e{base} = $retdata ;
    $e{meta} = '' ;

    return \%e;
}


sub get_convert {
    # helper : we need the converter in the others ...
    my $self = shift;

    return \&convert_folder_names_vanilla;
}

sub filterit {
    # what we dont transfer from vanilla
    my $self = shift ;

    my $c = shift;
    
    my $ret = 0;

    # we let it live
    return 0;
}

sub get_find_wanted {
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

