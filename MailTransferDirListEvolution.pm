
package MailTransferDirListEvolution;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the evolution way
#
# we have to make the evolution adjustments here
$version = '1.0.0';

# we are a list after all ...
use parent 'MailTransferDirList';

sub new {

    my $class = shift;

    return $class->SUPER::new('evolution', @_);
}

sub add_directory {
    # we have a directory and this is how to add it ..

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

    # handle the dotpath thing for evolution
    if ($#path > -1) {
	my @ppath  = split(/\./, $path[0]);

	if ($#ppath > 0) {
	    shift @ppath;
	}
	
	shift @path;

	unshift @path, @ppath;
    }
  
    my ($basename,$normpath) = $self->get_normalized_path(@path);
    
    $self->SUPER::add_directory($directory, $basename, $normpath, $subdir);
}

sub get_normalized_path {
    my $self = shift;

    # evolution has a small mapping for the . problem ...
    my $path = '';

    my $basedir = '';

    foreach my $d (@_) {
	my $nd = $d;

	$nd =~ s:_5F:_:g;

	$nd =~ s:_2E:.:g;

	$basedir = $nd;
	
	$path .= '/' . $nd;
    }

    return ($basedir,$path);
}

sub gen {

    my $self = shift;

    my $ret = $self->gen_traget_structure(\&convert_folder_names_evolution, @_);

    return $ret;
}

sub convert_folder_names_evolution {
    # helper : we are a callback for dir ...
    my $retdata = '';

    my $normpath = shift;

    my $prefix = shift;

    my @parts = split (/\//, $normpath);

    shift @parts;

    if ($prefix ne '') {
	unshift @parts, $prefix;
	
    }

    # we have to adjust sone chars for evolution here
    # not needed a-z : ; , - @ euro ~ space * ' # +
    # ^ ! " paragraph $ % & ()=?`´}][{
    # it seems every char of the iso else works like in local .. ä ö ü ß for germany ok ...
    # care for \, its othen double in tools, but here only one
    # impossible for evolution is a /
    foreach $d (@parts) {
	$d =~ s:_:_5F:g; # a undrescore is a special char, need that
	$d =~ s:\.:_2E:g; # a dot is a special char , need that
    }

    $retdata = '.'  . join('.', @parts);

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

    return \&convert_folder_names_evolution;
}


sub filterit {
    # we need to ignore stuff we dont want to transfer ...
    my $self = shift ;

    my $c = shift;
    
    my $ret = 0;

    if ($c =~ m:^\.$:) {
	return 1;
    }
	
    if ($c =~ m:^cur$:) {
	return 1;
    }
	
    if ($c =~ m:^new$:) {
	return 1;
    }
	
    if ($c =~ m:^tmp$:) {
	return 1;
    }
	
    if ($c =~ m:^.Inbox$:) {
	return 1;
    }
	
    if ($c =~ m:^.Inbox/(cur|new|tmp)$:) {
	return 1;
    }
	
    if ($c =~ m:^.Trash$:) {
	return 1;
    }
	
    if ($c =~ m:^.Trash/(cur|new|tmp)$:) {
	return 1;
    }
	
    if ($c =~ m:^.Outbox$:) {
	return 1;
    }
	
    if ($c =~ m:^.Outbox/(cur|new|tmp)$:) {
	return 1;
    }
	
    # we get it
    return 0;
}

1;
# end of file

