
package MailTransferDirListMutt;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the mutt way
$version = '1.0.0';

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
    
    
    my ($basename,$normpath) = $self->get_normalized_path(@path);
    
    $self->SUPER::add_directory($directory, $basename, $normpath, $subdir);
}



sub get_normalized_path {
    my $self = shift ;
    
    my $path = '';
    my $basedir = '';

    my $dirs = $self->{'sourcefile'};
    
    foreach my $d (@_) {
	my $nd = $d;

	$basedir = $nd;
	
	$path .= '/' . $nd;
    }

    return ($basedir,$path);
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

sub get_convert {
    # helper : we need the converter in the others ...
    my $self = shift;

    return \&convert_folder_names_mutt;
}

sub filterit {
    # we filter that directries out 
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

