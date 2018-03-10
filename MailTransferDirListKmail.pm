
package MailTransferDirListKmail;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the kmail way
$version = '1.0.0';

# we are a list after all
use parent 'MailTransferDirList';


sub new {

    my $class = shift;

    return $class->SUPER::new('kmail', @_);
}

sub add_directory {
    # we do the kmail stuff for nameing..
    my $self = shift;

    my $directory = $_[0];

    # specific code for kmail ...
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

    # we do the kmail to normal thing here
    my $path = '';
    my $basedir = '';
    
    foreach my $d (@_) {
	my $nd = $d;

	$nd =~ s:\.directory$::;

	$nd =~ s:^\.::;

	$basedir = $nd;
	
	$path .= '/' . $nd;
    }

    return ($basedir,$path);
}

sub gen {

    my $self = shift;

    my $ret = $self->gen_traget_structure(\&convert_folder_names_kmail, @_);

    return $ret;
}

sub convert_folder_names_kmail {
    # we have to adjust only minimum for kmail here
    my $retdata = '';
    
    my $normpath = shift;

    my $prefix = shift;

    my @parts = split (/\//, $normpath);

    shift @parts;

    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }

    my $lastdir = pop @parts;
    
    # we cant use a / in kmail
    # we can use a-z < > | , ; : _ - space . @ EURO
    # ! " $ % & ( ) = ? PARAGRAPH { [ ] } ~ ^ * + ' # ` ´
    # careful: the \ is only one, check the listings in tools for this ...
    # german char work like in locale ä ö ü ß 
    
    # the last dir is not changed in kmail now. only the part before...
    foreach $d (@parts) {
	$d = '.' . $d . '.directory';
    }

    $retdata = join('/', @parts);

    if ($retdata ne '') {
	$retdata .= '/' . $lastdir; 
    } else {
	$retdata = $lastdir;
    }

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

    return \&convert_folder_names_kmail;
}


sub filterit {
    # what we dont transfer from kmail
    my $self = shift ;

    my $c = shift;
    
    my $ret = 0;

    if ($c =~ m:^inbox$:) {
 	return 1;
    }
	
    if ($c =~ m:^inbox/(cur|new|tmp)$:) {
 	return 1;
    }

    if ($c =~ m:^outbox$:) {
 	return 1;
    }
	
    if ($c =~ m:^outbox/(cur|new|tmp)$:) {
 	return 1;
    }
	
    if ($c =~ m:^trash$:) {
 	return 1;
    }
	
    if ($c =~ m:^trash/(cur|new|tmp)$:) {
 	return 1;
    }

    # we let it live
    return 0;
}

1;
# end of file

