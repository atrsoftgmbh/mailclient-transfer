
package MailTransferDirListSeamonkey;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# do it the seamonkey way

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

sub get_from_msf_foldername {
    # warning : this work not perfect. only a limited thing is working..
    my $msf = shift;
    my $filenode = shift;

    my $fh ;

    if (!open($fh, $msf)) {
	# fallback, not nice but works ..
	return $filenode;
    }

    my $reval = $filenode;

    $reval =~ s:\\:\\\\:g;
    $reval =~ s:\):\\):g;
    $reval =~ s:\(:\\(:g;
    $reval =~ s:\[:\\[:g;
    $reval =~ s:\]:\\]:g;
    $reval =~ s:\*:\\*:g;
    $reval =~ s:\+:\\+:g;
    $reval =~ s:\-:\\-:g;
    $reval =~ s:\<:\\<:g;
    $reval =~ s:\>:\\>:g;
    $reval =~ s:\{:\\{:g;
    $reval =~ s:\}:\\}:g;
    $reval =~ s:\?:\\?:g;

    my $i ;
    my $limit = length $reval;

    my $revalf = '';
    for ($i = 0; $i < $limit; ++$i) {
	my $c = substr($reval, $i, 1);

	# sorry. this does not work ... 
	#	if (ord($c) > 127) {
	#	    $revalf .= '$' . sprintf("02X", ord($c));
	# 	} elsif($c eq '$') {
	if($c eq '$') {
	    $revalf .= "\\\$" ;
	} else {
	    $revalf .= $c;
	}
    }
    
#    print "regexval:" . $filenode . ":" . $reval . "::\n";
    
    my $res = qr{\(83=$revalf\).*\(85=(.*)};
    
    while (<$fh>) {
	my $l = $_;
	#kill the last parent ... 
	$l =~ s:\)>[\w]*$::;
	
	if ($l =~ m:$res:) {
	    my $c = $1;

	    # kill optiona parents after ...
	    $c =~ s:\)\(.*::;

	    if ($c =~ m:^[\d]+$:) {
		# ups . no new name at all ...
		next;
	    }
	    
	    # we have it ... if its the dreadful / .. we have to replace it now 
	    $c =~ s:\/:_2F_:g;

	    # if we have a paret in and it is escaped, we have to get it clean
	    $c =~ s:\\\):):g;
	    $c =~ s:\\\(:(:g;
	    
	    close $fh;

	    return $c;
	}
    }
    
    close $fh;

    return $filenode;
}

sub get_normalized_path {
    my $self = shift ;
    
    my $ret = '';
    my $b = '';

    my $dirs = $self->{'sourcefile'};
    
    foreach my $d (@_) {
	my $nd = $d;

	$nd =~ s:\.sbd$::;

	my $msf = $dirs . '/' . $nd . '.msf';
	
	$dirs .= '/' . $d;

	if ( -r $msf ) {
	    $nd = &get_from_msf_foldername($msf, $nd);
	} else {
	    # no new name in here ...
	}
	
	$b = $nd;
	
	$ret .= '/' . $nd;
    }

    return ($b,$ret);
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

sub filterit {
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

