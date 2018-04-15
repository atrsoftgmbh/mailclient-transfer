
# we use the mail thing here

use MailTransferMail;

package MailTransferDirData;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#

$verbose = 1;


$version = '1.0.0';

# we have here the basic data structure for holding a
# folder and ist data in ...
# here is also the heart of doings ...
# we copy, we concat, we split...
# and we create te target structure ...


# the magic from line if we dont have a front in first line ...
# we add it fro all new systems then ...
$fromline = "From root\@localhost   Mon Feb 12 23:26:05 2018 \n";



sub initialize {
    # we initialize here our little thing.
    # depending on the mechanism on top we have three diffrent 
    # things in here...
    
    my $self = shift;

    my $directory = $_[0];

    my $basename = $_[1];
    
    my $normpath = $_[2];

    my $subdir = $_[3];
    
    $self->{'sourcepath'} = $directory;
    $self->{'basename'} = $basename;
    $self->{'normpath'} = $normpath;

    $self->{'subdir'} = $subdir;

    $self->{'total'} = 0;
    
    $self->{'verbose'} = $verbose;
    
    if ($#_ == 3) {

	# first thing. we are in the scanner ...
	# only the basic info is known, the rest comes from the directory
	
	# now we get info about the number of emails in ..

	my $dir;

	# thunderbird uses instead files , not folders ...
	# seamonkey uses instead files , not folders ...
	# mutt uses instead files , not folders ...
	if ( -f $directory ) {
	    my @myfiles = ();
	    
	    $self->{'myfiles'} = \@myfiles;

	    my     $filenumber = $#myfiles;

	    ++ $filenumber;
	    
	    $self->{'filenumber'} = $filenumber ;

	    my @myfilesmailbox = ();
	    
	    $self->{'myfilesmailbox'} = \@myfilesmailbox;

	    my     $filenumbermailbox = $#myfilesmailbox;

	    ++ $filenumbermailbox;
	    
	    $self->{'filenumbermailbox'} = $filenumbermailbox ;

	    return ; 
	}

	my @files = ();
	
	# the others .... real directories ... 
	if (!opendir($dir, $directory)) {
	    print "ERROR101: cannot open directory $directory ... \n"  if $self->{'verbose'};
	} else { 

	    @files = readdir($dir);

	    closedir ($dir);
	}
	
	my @myfiles = ();
    
	my @myfilesmailbox = ();
	
	foreach my $node (@files) {
	    my $fullpath = $directory . '/' . $node;
	
	    if ( -f $fullpath ) {
		if ( -r $fullpath ) {
		    if ( -s $fullpath ) {
			# we have a non zero file ...
			my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
			    $atime,$mtime,$ctime,$blksize,$blocks)
			    = stat($fullpath);
			
			$self->{'total'} += int($size / 1024);
			$self->{'total'} += 1; # we add 1 k per file ...

			# this is depending on the system in use..
			# and it is depending on the order of testing
			# so dont change it if you dont need to
			
			# if we have kmail in and old mbox files... 
			if (-r $directory . '/.' . $node . '.index') {
			    # we have found a mbox file with index ... need to split it later
			    push @myfilesmailbox , $node;
			} elsif($subdir eq 'sylpheed'
				&& $node =~ m:^[\d]+$:) {
			    # ok, we have a sylpheed mail file in
			    push @myfiles , $node;
			} elsif($subdir eq 'sylpheed') {
			    # nothing to do else .. 

			} elsif($subdir eq 'claws-mail'
				&& $node =~ m:^[\d]+$:) {
			    # ok, we have a claws mail file in
			    push @myfiles , $node;
			} elsif($subdir eq 'claws-mail') {
			    # nothing to do else ..

			} elsif($directory !~ m:/(cur|new|tmp)$:
				&& &is_a_mbox_file($directory . '/' . $node)) {
			    # only a mbox file, no index, and not in the regular files ...
			    push @myfilesmailbox , $node;
			} else {
			    # the regular files ... normal case kmail, evolution
			    push @myfiles , $node;
			}
		    }
		}
	    } 
	}
    
	$self->{'myfiles'} = \@myfiles;

	$self->{'myfilesmailbox'} = \@myfilesmailbox;

	my     $filenumber = $#myfiles;

	++ $filenumber;

	my  $filenumbermailbox = $#myfilesmailbox;

	++ $filenumbermailbox;
	
	print "found $filenumber regular files in $directory .... \n"  if $self->{'verbose'};

	print "found $filenumbermailbox mailbox files in $directory .... \n"  if $self->{'verbose'};

	$self->{'filenumber'} = $filenumber ;
	
	$self->{'filenumbermailbox'} = $filenumbermailbox ;
	
    } elsif ($#_ == 5) {

	# we are from the read in of a scan result ...
	
	# we have that info from the reader ... we are in load ...
	$self->{'myfiles'} = $_[4];

	my     $filenumber = $#{$_[4]};

	++ $filenumber;
    
	$self->{'myfilesmailbox'} = $_[5];

	my     $filenumbermailbox = $#{$_[5]};

	++ $filenumbermailbox;
    
	$self->{'filenumber'} = $filenumber ;

	$self->{'filenumbermailbox'} = $filenumbermailbox ;
	
    } elsif ($#_ == 11) {
	# we have that info from the reader ... we are in plan ...

	$self->{'targetmeta'} = $_[4];
	$self->{'targetbase'} = $_[5];
	$self->{'targetdatacur'} = $_[6];
	$self->{'targetdatanew'} = $_[7];
	$self->{'targetdatatmp'} = $_[8];

	$self->{'myfiles'} = $_[9];

	my     $filenumber = $#{$_[9]};

	++ $filenumber;
    
	$self->{'mytargetfiles'} = $_[10];

	$self->{'myfilesmailbox'} = $_[11];

	my     $filenumbermailbox = $#{$_[11]};

	++ $filenumbermailbox;
    
	$self->{'filenumber'} = $filenumber ;

	$self->{'filenumbermailbox'} = $filenumbermailbox ;
	
    } else {
	print "ERROR102: in intialize ... wrong number parameters $#_ ...\n" if $self->{'verbose'};
	return ;
    }

    return ;
}

sub new {

    my $class = shift;

    my $self = {};

    bless $self , $class;

    $self->initialize(@_);
    
    return $self;
}

sub echo {
    # debug helper only ...
    my $self = shift;

    print " " . $self->{'basename'} . "\n";
    print "  " . $self->{'normpath'} . "\n";
    print "  " . $self->{'sourcepath'} . "\n";
    if ($self->{'subdir'} ne '') {
	print "  " . $self->{'subdir'} . "\n";
    }
    print "  " . $self->{'filenumber'} . "\n";

    return 0;
}

sub save {
    # we save what the scan has given ...
    my $self = shift ;

    my $fh = shift ;

    my $ret = 0;

    # if normpath is empt, we dont do it ..

    if ($self->{'normpath'} eq '') {
	return 0;
    }
    
    $ret = print $fh "#\n";

    if (!$ret) {
	print "ERROR103: cannot print to scan output.\n" if $self->{'verbose'};
	return 1;
    }
    
    $ret = print $fh "BASENAME:" . $self->{'basename'} . "\n";
    if (!$ret) {
	print "ERROR104: cannot print to scan output.\n" if $self->{'verbose'};
	return 1;
    }
    
    $ret = print $fh "NORMPATH:" . $self->{'normpath'} . "\n";
    if (!$ret) {
	print "ERROR105: cannot print to scan output.\n" if $self->{'verbose'};
	return 1;
    }

    
    $ret = print $fh "SOURCEPATH:" . $self->{'sourcepath'} . "\n";
    if (!$ret) {
	print "ERROR106: cannot print to scan output.\n" if $self->{'verbose'};
	return 1;
    }
    
    
    if ($self->{'subdir'} ne '') {
	$ret = print $fh "SUBDIR:" . $self->{'subdir'} . "\n";
	if (!$ret) {
	    print "ERROR107: cannot print to scan output.\n" if $self->{'verbose'};
	    return 1;
	}
    
    }

    if ($self->{'subdir'} =~ m:(.*)\.msf$:) {
	# we have a thunderbird or seamonkey in here ...
	my $f = $1;
	$ret = print $fh "FILES:0:1\n";
	if (!$ret) {
	    print "ERROR108: cannot print to scan output.\n" if $self->{'verbose'};
	    return 1;
	}
    
	$ret = print $fh 'FILEMAILBOX:' . $f . "\n";
	if (!$ret) {
	    print "ERROR109: cannot print to scan output.\n" if $self->{'verbose'};
	    return 1;
	}
    
    } else {
	$ret = print $fh "FILES:" . $self->{'filenumber'} . ':' . $self->{'filenumbermailbox'} . "\n";
	if (!$ret) {
	    print "ERROR110: cannot print to scan output.\n" if $self->{'verbose'};
	    return 1;
	}
    
	if ($self->{'filenumber'} > 0) {
	    foreach my $f (@{$self->{'myfiles'}}) {
		$ret = print $fh 'FILE:' . $f . "\n";
		if (!$ret) {
		    print "ERROR111: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}

		if ($f =~ m:\.index:) {
		    $ret = print $fh "HINT:index file , no transfer done.\n";
		    if (!$ret) {
			print "ERROR112: cannot print to scan output.\n" if $self->{'verbose'};
			return 1;
		    }
		}
	    }
	}
    }
    
    $ret = print $fh "ENDBASENAME:" . $self->{'basename'} . "\n";
    if (!$ret) {
	print "ERROR113: cannot print to scan output.\n" if $self->{'verbose'};
	return 1;
    }

    if ($self->{'subdir'} =~ m:(.*)\.msf$:) {
	# we have a thunderbird or seamonkey in here ...
    } else {
	# for every mailboxfile we need the scan to add a synthetic ..
	if ($self->{'filenumbermailbox'} > 0) {
	    foreach my $f (@{$self->{'myfilesmailbox'}}) {
		$ret = print $fh "#\n";
		if (!$ret) {
		    print "ERROR114: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
		
		$ret = print $fh "BASENAME:" . $f . "\n";
		if (!$ret) {
		    print "ERROR115: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
		$ret = print $fh "NORMPATH:" . $self->{'normpath'} . '/'  . $f . "\n";
		if (!$ret) {
		    print "ERROR116: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
		$ret = print $fh "SOURCEPATH:" . $self->{'sourcepath'} . '/' . $f . "\n";
		if (!$ret) {
		    print "ERROR117: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
		$ret = print $fh "FILES:0:1\n";
		if (!$ret) {
		    print "ERROR118: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
		$ret = print $fh 'FILEMAILBOX:' . $f . "\n";
		if (!$ret) {
		    print "ERROR119: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
		$ret = print $fh "ENDBASENAME:" . $f . "\n";
		if (!$ret) {
		    print "ERROR120: cannot print to scan output.\n" if $self->{'verbose'};
		    return 1;
		}
	    }
	}
    }

    return 0;
}

sub gen_traget_structure {
    # we create from the scan info and parameters now the plan info...
    my $self = shift ;

    my $callback_function = shift;
    
    my $prefix  = shift ;
    
    my $fh = shift ;

    my $ret = 0;
    
    $ret = print $fh "#\n";
    if (!$ret) {
	print "ERROR121: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "BASENAME:" . $self->{'basename'} . "\n";
    if (!$ret) {
	print "ERROR122: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "NORMPATH:" . $self->{'normpath'} . "\n";
    if (!$ret) {
	print "ERROR123: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "SOURCEPATH:" . $self->{'sourcepath'} . "\n";
    if (!$ret) {
	print "ERROR124: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    if ($self->{'subdir'} ne '') {
	$ret = print $fh "SUBDIR:" . $self->{'subdir'} . "\n";
	if (!$ret) {
	    print "ERROR125: cannot print to plan output.\n" if $self->{'verbose'};
	    return 1;
	}
    }

    # dirty. we dont know about the list type...
    # so we use here the info for a callback, not for a
    # overloaded method ..
    my $cbdata = &$callback_function($self->{'normpath'}, $prefix);

    $ret = print $fh "TARGETMETA:" . $cbdata->{meta} . "\n";
    if (!$ret) {
	print "ERROR126: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "TARGETBASE:" . $cbdata->{base} . "\n";
    if (!$ret) {
	print "ERROR127: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "TARGETDATACUR:" . $cbdata->{cur} . "\n";
    if (!$ret) {
	print "ERROR128: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "TARGETDATANEW:" . $cbdata->{new} . "\n";
    if (!$ret) {
	print "ERROR129: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    $ret = print $fh "TARGETDATATMP:" . $cbdata->{tmp} . "\n";
    if (!$ret) {
	print "ERROR130: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }
    
    $ret = print $fh "FILES:" . $self->{'filenumber'} . ':' . $self->{'filenumbermailbox'} . "\n";
    if (!$ret) {
	print "ERROR131: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }

    if ($self->{'filenumber'} > 0) {
	foreach my $f (@{$self->{'myfiles'}}) {
	    $ret = print $fh 'READFILE:' . $f . "\n";
	    if (!$ret) {
		print "ERROR132: cannot print to plan output.\n" if $self->{'verbose'};
		return 1;
	    }

	    if ($f =~ m:\.index:) {
		$ret = print $fh "HINT:index file , no transfer done.\n";
		if (!$ret) {
		    print "ERROR133: cannot print to plan output.\n" if $self->{'verbose'};
		    return 1;
		}
	    } else {
		if ($cbdata->{meta} eq '') {
		    $ret = print $fh 'WRITEFILE:' . $f . "\n";
		    if (!$ret) {
			print "ERROR134: cannot print to plan output.\n" if $self->{'verbose'};
			return 1;
		    }
		} else {
		    # we have thunderbird or seamonkey in ...
		    $ret = print $fh 'APPENDFILE:' . $cbdata->{meta} . "\n";
		    if (!$ret) {
			print "ERROR135: cannot print to plan output.\n" if $self->{'verbose'};
			return 1;
		    }
		}
	    }
	}
    }

    # so far .. now we have the mbox files in source ...
    # this is the exception part for it.
    # if we are in thunderbird or seamonkey its done above with append ...
    if ($self->{'filenumbermailbox'} > 0) {
	foreach my $f (@{$self->{'myfilesmailbox'}}) {
	    if ($f =~ m:\.index:) {
		# nothing to do ...
	    } else {
		$ret = print $fh 'SPLITFILE:' . $f . "\n";
		if (!$ret) {
		    print "ERROR136: cannot print to plan output.\n" if $self->{'verbose'};
		    return 1;
		}
	    }
	}
    }
    
    $ret = print $fh "ENDBASENAME:" . $self->{'basename'} . "\n";
    if (!$ret) {
	print "ERROR137: cannot print to plan output.\n" if $self->{'verbose'};
	return 1;
    }

    return 0;
}

sub create_folders {
    # we create the needed folders and
    # for our friend thunderbird the zero files
    # for our friend seamonkey the zero files
    my $self = shift ;

    my $ofh = shift;

    my $t = shift;

    my $td  = $t . '/' . $self->{'targetbase'};

    if (! -d $t) {
	# first we do it for the base at all
	mkdir ($t);
    }

    my $ret = 0;
    
    if (! -d $td) {
	$ret = print $ofh "create folder " . $td . "\n" ;
	if (!$ret) {
	    print "ERROR138: cannot create folder output.\n" if $self->{'verbose'};
	    return 1;
	}

	my $p = $t;
	
	foreach my $f (split(/\//, $self->{'targetbase'})) {
	    $p .= '/' . $f; 
	    if (! -d $p) {
		my $retbase = mkdir ($p) ;

		if ($retbase == 0) {
		    print $ofh "ERROR139: create $p ...\n";
		    return 1;
		}

		# thunderbird and seamonkey needs an empty file at least to
		# accept the folder. so we give it here in the 
		# creation of the directory
		if ($self->{'targetmeta'} ne '') {
		    my $empty = $p;
		    $empty =~ s:.sbd$::;

		    if (! -r $empty) {
			my $fh;
			if (!open($fh, ">" . $empty)) {
			    print $ofh "ERROR140: cannot create $empty ..\n";
			    return 1;
			}
			# nothing to write, only create ... 
			close $fh;
		    }
		}
	    }
	}

    }

    my $tcur = $t . '/' . $self->{'targetdatacur'} ;
    
    if ($self->create_subdir($tcur,$ofh)) {
	return 1;
    }

    my $tnew = $t . '/' . $self->{'targetdatanew'} ;

    if ($self->create_subdir($tnew,$ofh)) {
	return 1;
    }
    
    my $ttmp = $t . '/' . $self->{'targetdatatmp'} ;
    
    if ($self->create_subdir($ttmp,$ofh)) {
	return 1;
    }

    return 0;
}

sub create_subdir {
    # helper
    my $self = shift ;
    
    my $tcur = shift ;

    my $ofh = shift ;
    
    if (! -d $tcur) {
	$ret = print $ofh "create folder " . $tcur . "\n" ;
	my $retcur = mkdir ($tcur) ;

	if ($retcur == 0) {
	    print $ofh "ERROR141: cannot create $tcur ...\n";
	    return 1;
	}
    }

    return 0;
}

sub copy_files {
    # we copy the files in case a maildir is in ...
    # if we have mbox files we split them into the target cur ..
    my $ret = 0;
    
    my $self = shift ;
    
    my $ofh = shift;

    my $t = shift;

    my $s = shift;

    my $flags = shift ;

    my $tcur = $t . '/' . $self->{'targetdatacur'} ;

    my $i;

    my $limit = $#{$self->{'myfiles'}};
   
    print "$self->{'sourcepath'}\n" if $self->{'verbose'};
    
    for ($i = 0; $i <= $limit; ++$i) {

	my $sf = $self->{'myfiles'}->[$i];
	my $tf = $self->{'mytargetfiles'}->[$i];
 
	my $source = $s . '/' . $self->{'sourcepath'} . '/' . $sf;

	if ($flags eq 'sylpheed') {
	    # we have the thing in.. now simulate...
	    if ( -r $source) {
		# ok. we have one in...
		my $newnumber = $self->get_last_number( $tcur );

		my $target = $tcur . '/' . $newnumber;
		
		$ret = print $ofh "copy " . $source . " to " . $target .  "\n" ;
		if (!$ret) {
		    print "ERROR176: cannot write copy files log.\n" if $self->{'verbose'};
		    return 1;
		}
		# print "$sf $tf\n";
		# file module
		#		$ret = copy ($source, $target);

		$ret = $self->catit($ofh, $source,$target);
		    
		if ($ret != 0) {
		    my $err = $!;
		    print $ofh "ERROR177: catit ... $err \n";
		    return 1;
		}
	    }	
	} elsif ($flags eq 'claws-mail') {
	    # we have the thing in.. now simulate...
	    if ( -r $source) {
		# ok. we have one in...
		my $newnumber = $self->get_last_number( $tcur );

		my $target = $tcur . '/' . $newnumber;
		
		$ret = print $ofh "copy " . $source . " to " . $target .  "\n" ;
		if (!$ret) {
		    print "ERROR178: cannot write copy files log.\n" if $self->{'verbose'};
		    return 1;
		}
		# print "$sf $tf\n";
		# file module
		#		$ret = copy ($source, $target);

		$ret = $self->catit($ofh, $source,$target);
		    
		if ($ret != 0) {
		    my $err = $!;
		    print $ofh "ERROR179: catit ... $err \n";
		    return 1;
		}
	    }	
	} else {
	    # for the rest ...
	    my $target = $tcur . '/' . $tf;

	    if (! -r $target) {
		if ( -r $source) {
		    $ret = print $ofh "copy " . $source . " to " . $target .  "\n" ;
		    if (!$ret) {
			print "ERROR142: cannot write copy files log.\n" if $self->{'verbose'};
			return 1;
		    }
		    # print "$sf $tf\n";
		    # file module
		    #		$ret = copy ($source, $target);

		    $ret = $self->catit($ofh, $source,$target);
		    
		    if ($ret != 0) {
			my $err = $!;
			print $ofh "ERROR143: catit ... $err \n";
			return 1;
		    }
		}
	    }       
	}
    }

    # now we have to split in the mbox file
    $limit = $#{$self->{'myfilesmailbox'}};

    if ($limit > -1) {
	my $source = $s . '/' . $self->{'sourcepath'} ;

	my $target = $tcur;

	if ( -r $source && -f $source ) {
	    $ret = print $ofh "split " . $source . " to " . $target .  "\n" ;
 	    if (!$ret) {
		print "ERROR144: cannot write copy files log.\n" if $self->{'verbose'};
		return 1;
	    }

	    if (-s $source) {
		$ret = $self->splitit($ofh, $source, $target, $flags);
	    }
	} else {
	    print $ofh "ERROR145: not found source for split $source ..\n" if $self->{'verbose'};
	    return 1;
	}
    }
    
    return 0;
}


sub catit {
    # helper : cat a file into a source
    # we add if needed the From line in front of it ...

    my $self = shift;
    
    my $logfh = shift ;

    my $source = shift;

    my $target = shift;

    my $fh ;

    if ( ! -r $source || ! -s $source) {
	# hm. we dont have to do anything now ..
	$ret = print $logfh "Empty file ...\n";
	if (!$ret) {
	    print "ERROR146: cannot write to catit log.\n" if $self->{'verbose'};
	    return 1;
	}
 
	return 0;
    }
    
    if (-r $target ) {
	if (!open ($fh , ">>" . $target)) {
	    print $logfh "ERROR147: append target ...\n";
	    return 1;
	}
    } else {
	if (!open ($fh , ">" . $target)) {
	    print $logfh "ERROR148: open write target ...\n";
	    return 1;
	}
    }
    
    my $sfh;

    if (!open($sfh, $source )) {
	print $logfh "ERROR149: open read source $source ...\n";
	close $fh;
	return 1;
    }

    my $firstline;

    my $lines = 0;
    
    while ($firstline = <$sfh>) {
	++$lines;
	last if $firstline !~ m:^[\s]*$:;
    }

    if ($firstline =~ m:^[\s]*$:) {
	$ret = print $logfh "EMPTY file ..\n";
	if (!$ret) {
	    print "ERROR150: cannot write to catit log.\n" if $self->{'verbose'};
	    return 1;
	}
	close $fh;
	close $sfh;
	return 0;
    }
    
    if ($firstline !~ m/^From /) {
	$ret = print $fh $fromline;
	if (!$ret) {
	    print $logfh "ERROR151: cannot write in catit line $lines .\n";
	    return 1;
	}
    }

    $ret = print $fh $firstline;
    if (!$ret) {
	print $logfh "ERROR171: cannot write in catit line $lines .\n";
	return 1;
    }

    my $lastl = '';
    while (<$sfh>) {
	++$lines;
	$lastl = $_;
	$ret = print $fh $_;
	if (!$ret) {
	    print $logfh "ERROR152: cannot write in catit line $lines.\n";
	    return 1;
	}
    }

    if ($lastl =~ m:.:) {
	$ret = print $fh "\n"; # need an empty line in at last ...
	if (!$ret) {
	    print $logfh "ERROR153: cannot write in catit.\n";
	    return 1;
	}
    }

    close $fh;
    close $sfh;

    print $logfh "catit writed $lines lines .\n" if $self->{'verbose'};
    
    return 0;
}

sub append_files {
    # we append files in case of the thunderbird and seamonkey. 
    # this time a whole maildir stuff into one file ...
    
    my $ret = 0;
    
    my $self = shift ;

    my $ofh = shift;

    my $t = shift;
    
    my $s = shift;

    my $flags = shift ;

    my $tcur = $t . '/' . $self->{'targetmeta'} ;

    my $i;

    my $limit = $#{$self->{'myfiles'}};
   
    print "$self->{'sourcepath'}\n" if $self->{'verbose'};
    
    for ($i = 0; $i <= $limit; ++$i) {

	my $sf = $self->{'myfiles'}->[$i];
	my $tf = $self->{'mytargetfiles'}->[$i];
	
	my $source = $s . '/' . $self->{'sourcepath'} . '/' . $sf;

	my $target = $tcur;

	if ( -r $source) {
	    $ret = print $ofh "append " . $source . " to " . $target .  "\n" ;
	    if (!$ret) {
		print "ERROR154: cannot write to append output.\n" if $self->{'verbose'};
		return 1;
	    }

	    $ret = $self->catit($ofh, $source, $target);
	    if ($ret != 0) {
		print $ofh "ERROR172: cannot write to append output.\n";
		return 1;
	    }
	}
    }

    # now we have to cat the mbox file directly ..  
    $limit = $#{$self->{'myfilesmailbox'}};

    if ($limit > -1) {
	my $sf = $self->{'sourcepath'};
 
	my $source = $s . '/' . $self->{'sourcepath'} ;
	
	my $target = $t .'/' . $self->{'targetmeta'};

	if ( -r $source) {
	    $ret = print $ofh "append " . $source . " to " . $target .  "\n" ;
	    if (!$ret) {
		print "ERROR155: cannot write to append output.\n" if $self->{'verbose'};
		return 1;
	    }

	    # in case we do spiltit to a file its in fact a cat ...
	    # its also ok for seamonkey here 
	    $ret = $self->splitit($ofh, $source, $target, 'thunderbird_seamonkey_mutt');

	    if ($ret != 0) {
		print $ofh "ERROR173: cannot splitit $source ... \n";
		return 1;
	    }
	} else {
	    print $ofh "ERROR156: cannot read $source ... \n";
	    return 1;
	}
    }
    
    return 0;
}

sub split_files {
    # we are a helper.
    my $ret = 0;
    
    my $self = shift ;

    my $ofh = shift;

    my $t = shift;

    my $s = shift;

    my $flags = shift ;

    my $target = $t . '/' . $self->{'targetdatacur'} ;

    print "split $self->{'sourcepath'}\n";
    
    my $source = $s . '/' . $self->{'sourcepath'} ;

    if ( -r $source && -f $source ) {
	$ret = print $ofh "split " . $source . " to " . $target .  "\n" ;
	if (!$ret) {
	    print "ERROR157: cannot write to split output.\n" if $self->{'verbose'};
	    return 1;
	}

	if (-s $source) {
	    $ret = $self->splitit($ofh, $source, $target, $flags);
	    if ($ret != 0) {
		print $ofh "ERROR174: cannot splitit $source.\n";
		return 1;
	    }
	    return $ret;
	} 
    }

    return 0;
}

sub thunder_to_thunder_files {
    # we are the helper for thunder to thunder copy...
    # thi is also ok for seamonkey - no diffrence on this level
    # a one file to one file only on base of metadata as target
    # and sourcepath ...
    my $self = shift ;
    my $ofh = shift;
    my $t = shift ;
    my $s = shift ;

    my $ret = 0;
    
    my $target = $t . '/' . $self->{'targetmeta'};

    my $source = $s . '/' . $self->{'sourcepath'} ;
    
    $ret = print $ofh "copycat " . $source . " to " . $target .  "\n" ;
    if (!$ret) {
	print "ERROR158: cannot write to copycat output.\n" if $self->{'verbose'};
	return 1;
    }

    $ret = $self->catit($ofh, $source, $target);
    
    return $ret;
}

sub splitit {
    # some times we need to split mailbox files.
    # this is for one file ...
    # if target is a dir we create new files.(kmail, evolution ,...)
    # if target is a file we append one by one to that file (thunderbird , seamonkey)

    my $self = shift ;
    
    my $logfh = shift ;

    my $source = shift;

    my $target = shift;

    my $flags = shift; # if we have a sylpheed or claws-mail in ...
    
    my $num = 1;

    my $fh ;

    my $ret = 0;
    
    if (!open($fh, $source) ) {
	return 1;
    }

    my @lines = <$fh>;
    
    close $fh;

    print $logfh "read in a total of " . ($#lines + 1) . " lines.\n";

    my $mail_r = &MailTransferDirData::get_all_mails (\@lines,  $logfh);

    for (my $k = 0; $k <= $#$mail_r; ++$k) {
	my $f_r = $mail_r->[$k];

	$ret = $self->writefile($target, $num, $f_r, $logfh, $flags);

	++ $num;

	if ($ret != 0) {
	    return 1;
	}
    }

    print $logfh "split made " . ($num - 1) . " new files...\n";
    
    return 0;
}



sub writefile {
    # helper. we have a synthetic file to create
    my $self = shift;
    
    # mail is in the array per ref, log is in fh ..
    my $targetdir = shift;

    my $num = shift;

    my $a_r = shift;

    my $log = shift ;

    my $flags = shift ; # if we have a slypheed in ...

    my $tags = shift; # can be undefined in most cases... 

    my $ret = 0;

    my $fh;

    my $p = '';
    
    if ( -d $targetdir ) {
	if ($flags eq 'sylpheed') {
	    my $targetfile = $targetdir . '/' . $num;

	    if (!open ($fh, '>' . $targetfile)) {
		print $log "ERROR174: writefile  mailfile $targetfile .. $num ...\n";
		return 1;
	    }
	} elsif ($flags eq 'claws-mail') {
	    my $targetfile = $targetdir . '/' . $num;

	    if (!open ($fh, '>' . $targetfile)) {
		print $log "ERROR180: writefile  mailfile $targetfile .. $num ...\n";
		return 1;
	    }
	} else {
	    my $numfilled = sprintf("%08d",$num);

	    my $targetfile = $targetdir . '/mail' . $numfilled . '.file';

	    if (!open ($fh, '>' . $targetfile)) {
		print $log "ERROR160: writefile  mailfile $targetfile .. $num ...\n";
		return 1;
	    }
	}
    } else {
	# append to target, its a file in fact ...
	my $targetfile = $targetdir;

	$ret = print $log "append to file $targetfile ...\n";
	if (!$ret) {
	    print "ERROR161: cannot write to splitit .. $num output.\n" if $self->{'verbose'};
	    return 1;
	}

	if (-s $targetfile) {
	    $p = "\n";
	}

	if (!open ($fh, '>>' . $targetfile)) {
	    print $log "ERROR162: writefile appendfile $targetfile .. $num ...\n";
	    return 1;
	}
    }

    my $lines = 0;

    if ($text->[$start] !~ m/From /) {
	# we have an old mail file in, add the magic from line ...
	$ret = print $fh $p . $fromline;
	++ $lines;
	if (!$ret) {
	    print $log "ERROR163: cannot write in writefile line $lines .. $num .\n";
	    return 1;
	}
    }

    $p = '';
    my $nlines = 0;

    eval {
	$nlines = $a_r->write($fh, $tags);
    };

    if ($@) {
	close $fh;
	print $log "ERROR164: cannot write in writefile line $lines .. $num \n";
	return 1;
    }

    $lines += $nlines;

    close $fh;

    print $log "writefile did $lines lines .. $num .\n";

    return 0;
}

sub writefile_clean {
    # helper. we have a synthetic file to create
    my $self = shift;
    
    # mail is in the array per ref, log is in fh ..
    my $targetdir = shift;

    my $num = shift;

    my $a_r = shift;

    my $log = shift ;

    my $flags = shift ; # if we have a slypheed in ...

    my $tags = shift; # can be undefined in most cases... 

    my $ret = 0;

    my $fh;

    my $p = '';
    
    if ( -d $targetdir ) {
	if ($flags eq 'sylpheed') {
	    my $targetfile = $targetdir . '/' . $num;

	    if (!open ($fh, '>' . $targetfile)) {
		print $log "ERROR174: writefile  mailfile $targetfile .. $num ...\n";
		return 1;
	    }
	} elsif ($flags eq 'claws-mail') {
	    my $targetfile = $targetdir . '/' . $num;

	    if (!open ($fh, '>' . $targetfile)) {
		print $log "ERROR180: writefile  mailfile $targetfile .. $num ...\n";
		return 1;
	    }
	} else {
	    my $numfilled = sprintf("%08d",$num);

	    my $targetfile = $targetdir . '/mail' . $numfilled . '.file';

	    if (!open ($fh, '>' . $targetfile)) {
		print $log "ERROR160: writefile  mailfile $targetfile .. $num ...\n";
		return 1;
	    }
	}
    } else {
	# append to target, its a file in fact ...
	my $targetfile = $targetdir;

	$ret = print $log "append to file $targetfile ...\n";
	if (!$ret) {
	    print "ERROR161: cannot write to splitit .. $num output.\n" if $self->{'verbose'};
	    return 1;
	}

	if (-s $targetfile) {
	    $p = "\n";
	}

	if (!open ($fh, '>>' . $targetfile)) {
	    print $log "ERROR162: writefile appendfile $targetfile .. $num ...\n";
	    return 1;
	}
    }

    my $lines = 0;

   # if ($text->[$start] !~ m/From /) {
#	# we have an old mail file in, add the magic from line ...
#	$ret = print $fh $p . $fromline;
#	++ $lines;
#	if (!$ret) {
#	    print $log "ERROR163: cannot write in writefile line $lines .. $num .\n";
#	    return 1;
#	}
 #   }

    $p = '';
    my $nlines = 0;

    eval {
	$nlines = $a_r->write($fh, $tags);
    };

    if ($@) {
	close $fh;
	print $log "ERROR164: cannot write in writefile line $lines .. $num \n";
	return 1;
    }

    $lines += $nlines;

    close $fh;

    print $log "writefile did $lines lines .. $num .\n";

    return 0;
}

sub get_total {
    # we need to access this sometimes ...
    my $self = shift;

    return $self->{'total'};
    
}

sub is_a_mbox_file {
    # helper : check if this is a mbox file ...

    my $f = shift ;
    
    if (! -r $f ){
	# not readable ... so no ...
	return 0;
    }

    my $fh;

    if (!open($fh, $f)) {
	# cannot open still ... so no
	return 0;
    }

    my $hitfrom = 0;

    my $hitreturnpath = 0;

    my $hitreceived = 0;

    my $hitdate = 0;

    while (<$fh>) {
	if (m/^From: /) {
	    $hitfrom = 1;

	    if ($hitfrom + $hitreturnpath + $hitreceived + $hitdate  == 4) {
		close $fh;
		return 1;
	    }
	    next;
	}
	
	if (m/^Date: /) {
	    $hitdate = 1;

	    if ($hitfrom + $hitreturnpath + $hitreceived + $hitdate  == 4) {
		close $fh;
		return 1;
	    }
	    next;
	}
	
	if (m/^Received: /) {
	    $hitreceived = 1;

	    if ($hitfrom + $hitreturnpath + $hitreceived + $hitdate  == 4) {
		close $fh;
		return 1;
	    }
	    next;
	}
	
	if (m/^Return-Path: /) {
	    $hitreturnpath = 1;

	    if ($hitfrom + $hitreturnpath + $hitreceived + $hitdate == 4) {
		close $fh;
		return 1;
	    }
	    next;
	}
	
    }

    close $fh;

    # no, we are not one so far ...
    return 0;
}

sub get_last_number {
    my $self = shift ;
    
    my $t = shift;

    my $dh;
    
    if (!opendir($dh, $t)) {
	return "1";

    }

    my @files = readdir($dh);

    closedir($dh);

    my $n = 1;
    if ($self->{'subdir'} eq 'sylpheed' || $self->{'subdir'} eq 'claws-mail' ) {
	foreach my $f (@files) {
	    if ($f =~ m:^([\d]+)$:) {
		my $v = $1;
		
		if ($n <= $v + 0) {
		    $n = $v + 1;
		}
	    }
	}
    } else  {
	foreach my $f (@files) {
	    if ($f =~ m:^mail([\d]+)\.file$:) {
		my $v = $1;
		
		if ($n <= $v + 0) {
		    $n = $v + 1;
		}
	    }
	}
    }

    if ($n < 1) {
	$n = 1;
    }
    
    return sprintf("%d", $n);
}

# end of object methods
# we have now only class methods in

sub get_all_mails {
    # we get a ref to the text array here in. thats all.
    my $m_r = shift;

    my $log = shift ;
    
    my $k = 0;
    my $klimit = $#$m_r;
    my $nlines = 0;
    my @mails = ();

    my $num = 0;
    if ($klimit < 3) {
	# ups. garbage ...
	return [];
    }
    
    for ($k = 0; $k <= $klimit; $k += $nlines) {
	my $f_r = &getamail($m_r, $k, $log);

	push @mails, $f_r;
	
	$nlines = $f_r->{nl};
	
	++ $num;
    }

    # ok, we have them in.
    # now we readjust for the body end , its hstart - 1

    if ($#mails > 0 ) {
	my $f_next_r;
	
	for ($k = 0 ; $k < $#mails; ++$k) {

	    my $f_r = $mails[$k];

	    $f_next_r = $mails[$k + 1];

	    if ($f_r->{bend} != $f_next_r->{hstart} - 1) {
		print $log "RE-ADJUST FOR $k $f_r->{bend} to " . ($f_next_r->{hstart} - 1) . "\n";
		$f_r->{bend} = $f_next_r->{hstart} - 1;
	    }
	}

	# for the last, its till the end of the thing
	$f_next_r->{bend} = $klimit;
    } elsif ($#mails == 0) {
	# only one, so ...
	$mails[0]->{bend} = $klimit;
    }

    return \@mails;
}

sub getamail {
    my $m_r = shift;
    my $start = shift;

    my $log = shift;
    

    my $firststart = $start;
    
    my $lasthit = 0;

    while ($lasthit == 0) {
	my $i ;

	
	for ($i = $start; $i <= $#{$m_r}; ++$i) {
	    my $line = $m_r->[$i];
	    
	    if ($line !~ m/^[\s]*$/) {
		last;
	    }
	}

	# we are on the first line of the thing

	$m = new MailTransferMail($m_r, $i);
	
	# $start = $i; # we readjust
	
	# so now we seek to the Content-type after it

	for ( ; $i <= $#{$m_r}; ++$i) {
	    my $line = $m_r->[$i];
	    
	    if ($line =~ m/^content-type:[\s]*[^\s]/i) {
		$m->{hend} = $i;
		last;
	    } 
	}

	if ($i >= $#{$m_r}) {
	    # we have done it.

	    $m->{nl} = $i - $firststart;

	    $m->{bstart} = $i;
	    $m->{bend} = $i;

	    return $m;
	}
	
	# ok. take that info now.
	my $cline = $m_r->[$i];

	if ($cline =~ m/^content-type:[\s]*text\/([^\s]+)/i) {
	    # einfach. alles bis zum nächsten header ...
	    $m->{kind} = 'simpletext';
	    
	    my $typ = $1;

	    my $content = $cline;

	    ++$i;
	    
	    while ($m_r->[$i] =~ m:^[\s]+[^\s]:) {
		my $c = $m_r->[$i];
		$c =~ s:[\s]*$::;
		$content .= $c;
		++$i;
	    }
	    
	    
	    $content =~ m:charset=([^\s]+):;

	    my $coding = $1;
	    
	    my %cont = (kind => 'text', typ => $typ, coding => $coding, line => $i, content => $content);

	    push @{$m->{content}}, \%cont;
	    
	    my $firstempty = 0;
	    
	    for (++$i; $i <= $#{$m_r}; ++$i) {

		my $line = $m_r->[$i];

		if ($firstempty == 0 && $line =~ m:^[\s]*$:) {
		    $m->{hend} = $i;
		    $m->{bstart} = $i + 1;
		    $firstempty = 1;
		}
		
		if ($line =~ m/^return-path:[\s]*[^\s]/i) {
		    last;
		}
	    }

	    if ($i >= $#{$m_r}) {
		# end hit ...
		$m->{nl} = $i - $firststart;

		$m->{bend} = $i;
		return $m;

	    }

	    # we use the failsafe against endless looping in case a malformed mail is in
	    while( $m_r->[$i] =~ m:[^\s]: 
		   && $i > $m->{bstart}) {
		--$i;
	    }

	    if ($i == $m->{bstart}) {
		print $log "FAILSAFE HIT IN $i \n";
		++$i;
	    }

	    if ($m_r->[$i] =~ m:[^\s]:) {
		++$i;
	    }
	    
	    $m->{nl} = $i - $firststart;

	    $m->{bend} = $i;
	    
	    return $m;

	}


	
	if ($cline =~ m/^content-type:[\s]*multipart\/([^\s]+);/i) {
	    # ok. wir haben eine multipart, den müssen wir nun part by part...

	    $m->{kind} = 'multipart';

	    my $typ = $1;
	    my $bound ;
	    
	    my $content = $cline;

	    ++$i;
	    
	    while ($m_r->[$i] =~ m:^[\s]+[^\s]:) {
		my $c = $m_r->[$i];
		$c =~ s:[\s]*$::;
		$content .= $c;
		++$i;
	    }
	    
	    # ok we have now the boundary in 

	    if ($content =~ m:boundary="([^"]+)":) {
		$bound = $1;
	    } elsif ($content =~ m:boundary=([^;]+);:) { 
		$bound = $1;
	    } else {
		$content =~ m:boundary=([^\s]+):;
		$bound = $1;
	    }
	    
	    # ok. we have a type - interesting, but for now not needed
	    # and we have the boundary. this is the thing we really need.

	    $m->{boundary} = $bound;
	    $m->{mimetyp} = $typ;

	    my %cont = (kind => 'multipart', typ => $typ, line => $i, content => $content);

	    push @{$m->{content}}, \%cont;
	    


	    ++$i;

	    my $c = $m_r->[$i];

	    $c =~ s:^[\s]*::;
	    $c =~ s:[\s]*$::;

	    my $firstbound = 0;

	    my $endbound  = $bound . '--';

	    while ($i <= $#{$m_r}) {

		if (index($c , $endbound) > -1) {
		    # we have the end of the thing
		    my $typ = 'last';
		    my $coding = 'nothing';
		    my %cont = (kind => 'last', typ => $typ, coding => $coding, line => $i, content => 'empty');
		    push @{$m->{content}}, \%cont;
		    $lasthit = 1;
		    last;
		}
		
		if (index($c, $bound) > -1) {
		    if ($firstbound == 0) {
			$firstbound = 1;
			$m->{hend} = $i;
			$m->{bstart} = $i + 1;
		    }
		    
		    ++$i;

		    my $content = $m_r->[$i];

		    $content =~ s:[\s]*$::;

		    ++$i;
		    
		    while ($m_r->[$i] =~ m:^[\s]+[^\s]:) {
			my $d = $m_r->[$i];
			$d =~ s:[\s]*$::;
			$content .= $d;
			++$i;
		    }

		    if ($content =~ m/^content-type:[\s]*text\/([^\s]+)/i) {
			my $typ = $1;

			$content =~ m:charset=([^\s]+):;

			my $coding = $1;
			
			my %cont = (kind => 'text', typ => $typ, coding => $coding, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-type:[\s]*image\/([^\s]+)/i) {
			my $typ = $1;

			my %cont = (kind => 'image', typ => $typ, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-type:[\s]*multipart\/([^\s]); (.*)/i) {
			my $typ = $1;
			my %cont = (kind => 'multipart', typ => $typ, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-transfer-encoding:/i) {
			my $typ = $1;
			my %cont = (kind => 'encoding', line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-type:[\s]*application\/([^\s]+);/i) {
			my $typ = $1;

			
			my %cont = (kind => 'application', typ => $typ, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-type:[\s]*message\/([^\s]+)/i) {
			my $typ = $1;

			
			my %cont = (kind => 'message', typ => $typ, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-language:[\s]*([^\s]+)/i) {
			my $typ = $1;

			
			my %cont = (kind => 'language', typ => $typ, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^content-disposition:[\s]*([^\s]+)/i) {
			my $typ = $1;

			
			my %cont = (kind => 'disposition', typ => $typ, line => $i, content => $content);
			push @{$m->{content}}, \%cont;

		    } elsif ($content =~ m/^[\s]*$/i) {
			# no need for that
		    } elsif ($content =~ m/boundary=/i) {
			# no need for that
		    } elsif ($content =~ m/^List-/i) {
			# no need for that
		    } elsif ($content =~ m/^To:/i) {
			# no need for that
		    } elsif ($content =~ m/^MIME-Version:/i) {
			# no need for that
		    } elsif ($content =~ m/^X-PGP-Key:/i) {
			# no need for that
		    } elsif ($content =~ m/^X-eBay-MailTracker:/i) {
			# 
		    } elsif ($content =~ m/^Envelope-To:/i) {
			# no need for that
		    } elsif ($content =~ m/^Date:/i) {
			# no need for that
		    } else {
			print $log "UNKOWN CONTENT TYPE in $i : $content \n";
			my $typ = 'unknown';
			my $coding = 'unknown';
			my %cont = (kind => 'unknown', typ => $typ, coding => $coding, line => $i, content => $content);
			push @{$m->{content}}, \%cont;
		    }
		    
		}
		
		++$i;

		if ($i <= $#{$m_r}) {	
		    $c = $m_r->[$i];

		    $c =~ s:^[\s]*::;
		    $c =~ s:[\s]*$::;
		}
	    }

	    if ($lasthit == 0) {
		# reset the world. we retarget start and skip this bastard...
		$i = $m->{hend};

		print $log "BOUND NOT CLOSED $i ... reset the world ...\n";

		++ $i;

		$c = $m_r->[$i];

		until ($c =~ m/^return-path:/i) {
		    ++$i;
		    $c = $m_r->[$i];
		}

		while ($m_r->[$i] =~ m:[^\s]:) {
		    --$i;
		}
		
		$start = $i;
		
	    } else {
		
		# bingo. we have the last boundary and the line after is empty.
		++$i;

		# we now skip till the first line having something in or end
		while ($i < $#{$m_r}
		       && $m_r->[$i] =~ m:^[\s]*$: ) {
		    ++$i;
		}
		# we have the first line in .. or end.

		if ($i >= $#{$m_r}) {
		    $m->{nl} = $i - $firststart;
		    $m->{bend} = $i;

		    return $m;
		}
		
		# we are on the line of the next header.
		--$i;
		
		$m->{nl} = $i - $firststart;

		$m->{bend} = $i;

		return $m;
	    }
	}

    }

    print $log "NO CONTENT TYPE FOUND in $i : $cline \n";
    # however we made it so far ...
    
    $m->{nl} = $i - $firststart;


    $m->{bstart} = $i;
    $m->{bend} = $i;
    return $m;
}

1;

# end of file



