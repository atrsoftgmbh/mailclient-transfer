
package MailTransferDirListMutt;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the mutt way

# we are a list after all ...
use parent 'MailTransferDirList';


sub new {

    my $class = shift;

    return $class->SUPER::new('mutt', @_);
}

sub add_directory {
    # we add a directory the mutt way

    my $self = shift;

    my $directory = $_[0];

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
    my $self = shift ;
    
    my $ret = '';
    my $b = '';

    my $dirs = $self->{'sourcefile'};
    
    foreach my $d (@_) {
	my $nd = $d;

	$b = $nd;
	
	$ret .= '/' . $nd;
    }

    return ($b,$ret);
}

sub gen {

    my $self = shift;

    my $ret = $self->gen_traget_structure(\&convert_folder_names_mutt, @_);

    return $ret;
}

sub convert_folder_names_mutt {
    my $retdata = '';
    
    my $normpath = shift;

    my $prefix = shift;

    my @parts = split (/\//, $normpath);

    shift @parts;

    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }

    my $lastdir = pop @parts;

    # thunderbird can use a / ... but we dont support that ...
    
    
    
    # we can use a-z  , _ - space  @ EURO
    # ! $ % & ( ) =  PARAGRAPH { [ ] }  ^ + ' ` ´
    # careful: the \ is only one, check the listings in tools for this ...
    # german char work like in locale ä ö ü ß 

    # mutt has no folder concept - so we have to do something 
    # to prevent it from collosion for name of a mbox file ...
    # we use a suffix for a folder : .folder
    
    foreach $d (@parts) {
	$d = $d . '.folder';
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

sub filterit {
    my $self = shift ;

    my $c = shift;
    
    my $ret = 0;
    
    if ($c =~ m:^\.$:) {
	return 1;
    }
	
    # we let it live
    return 0;
}

1;
# end of file

