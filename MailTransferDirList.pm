use MailTransferDirData;

package MailTransferDirList;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# we use here a central global for the new base
# we have to make a clean dir, so we use a stub directory for all imports.
# we set the default to zzzzz
# so if you want another you have after loading the module overwrite it.
# the folder has to exist .. or you cannot write to it ..
#
# there is an option to all scripts, -p for prefix, that reset the thing.
# you can also overwrite it in the scan result and the plan

$basefolder = 'zzzzz';


# we use the regular cp of the system, the /bin/cp to be exact.
# we use copy flags here.

$copyflags = '--preserve=all';

# we use the regular cat of the system, the /bin/cat to be exact.
# we use append flags here.

$appendflags = '';

sub initialize {

    my $self = shift;

    $self->{'sourcemailsystem'} = shift;

    $self->{'sourcefile'} =  shift;
    
    $self->{'targetfile'} =  shift;

    # this is set to basefolder, if we have a param left ... we set it then too    
    $self->{'prefix'} = $basefolder;

    if ($#_ > -1) {
	$self->{'prefix'} = shift;
    }

    $self->{'nodes'} = {} ;

    if ($#_ > -1) {
	$self->{'nodes'} = shift;
    }
    
    $self->{'copyflags'} = $copyflags;

    $self->{'total'} = 0;

    $self->{'anz'} = 0;
}

sub new {

    my $class = shift;

    my $self = {};

    bless $self , $class;

    $self->initialize(@_);
    
    return $self;
}

sub add_new_node {
    # helper : add the node now
    my $self = shift;

    my $directory = $_[0];
    
    $self->{'nodes'}->{$directory} = new MailTransferDirData(@_);

    my $ret = $self->{'nodes'}->{$directory}->get_total();

    my $anz = $#{$self->{'nodes'}->{$directory}->{'myfiles'}}; 

    if ($ret > 0) {
	print "total is $ret K...\n";
    
	$self->add_total($ret);

	$self->{'anz'} += $anz + 1; 
    }
}

sub add_directory {
    # overloded in siblings
    my $self = shift;

    my $directory = $_[0];

    if (defined $self->{'nodes'}->{$directory}) {
	print "already in : $directory \n";
    } else {
	# print @_;
	$self->add_new_node (@_);
    }
}

sub echo {
    # helper : debug output
    my $self = shift;

    print $self->{'sourcemailsystem'} . "\n";
    print $self->{'sourcefile'} . "\n";
    print $self->{'targetfile'} . "\n";
    print $self->{'prefix'} . "\n";

    foreach my $d (sort keys %{$self->{'nodes'}}) {
	$self->{'nodes'}->{$d}->echo();
    }
}

sub save {
    # save the scan now ...
    my $self = shift;

    my $fh = shift;
    
    my $lt = localtime;
    
    my $ret = 0;
    
    $ret = print $fh '# description of the source mail directory for mailtransfer
# ' . $lt . '
# we have a list of input directories in here,
# with the files candidates for a transfer to the target system
#
# if you want to tweak the transfer then this is the first spot to do it.
#
# you can add a targetdir
# you can change the prefix directory, or delete it ... 
# you can add a hint for ignoring a file 
# you can edit the list of files ..
# the # is a comment for the line, so you can add a # in front to comment but not loose a line ...
#
# if you delete a folder, do it for the complete BASENAME to ENDBASENAME thing...
#
# you have some checks in in the next phase, the generator ...
# and no file is moved/changed ... only scnanned
#
# so feel free to make some adjustments if you need to
#
# if you have trouble : email to atr at atrsoft dot de
# replace at with the mail at char and dot with the . char
# and dont forget to sent the scan and plan files if you have them.
# please, dont try to sent em a whole mail folder ... this will overload
# my mail system only. 
# and dont forget to zip the files first if they are more than a meg 
# 
# if you are done generate a plan by use of the generator
#
# perl MailTransferGen.pl targetsystem filename_of_this_scanfile dir planfile
#
';
    if (!$ret) {
	print "ERROR201: cannot write scan to scan output.\n";
	return 1;
    }
    

    $ret = print $fh 'MAILSYSTEM:' . $self->{'sourcemailsystem'} . "\n";
    if (!$ret) {
	print "ERROR202: cannot write to scan output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCE:' . $self->{'sourcefile'} . "\n";
    if (!$ret) {
	print "ERROR203: cannot write to scan output.\n";
	return 1;
    }
    
    $ret = print $fh 'TARGET:' . $self->{'targetfile'} . "\n";
    if (!$ret) {
	print "ERROR204: cannot write to scan output.\n";
	return 1;
    }
    
    $ret = print $fh 'PREFIX:' . $self->{'prefix'} . "\n";
    if (!$ret) {
	print "ERROR205: cannot write to scan output.\n";
	return 1;
    }
    
    $ret = print $fh 'TOTAL:' . $self->{'total'} . "K\n";

    foreach my $d (sort keys %{$self->{'nodes'}}) {
	$ret = $self->{'nodes'}->{$d}->save($fh);
	if($ret != 0) {
	    return 1;
	}
    }

    $ret = print $fh 'ENDMAILSYSTEM:' . $self->{'sourcemailsystem'} . "\n";
    if (!$ret) {
	print "ERROR206: cannot write to scan output.\n";
	return 1;
    }
    

    close $fh;

    return 0;
}


sub load {
    # load a scan in
    my $self = shift;

    my $fh = shift;

    my $basename = '';
    my $normpath = '';
    my $sourcepath = '';
    my $subdir = '';
    my @files = ();    
    my @filesmailbox = ();    

    my $ret = 0;
    
    # we assume its a description generatete correctly,
    # but the user has added some stuf ...

    while ( <$fh>) {
      if (m:^[\s]*#:) {
	  next;
      }
      
      s:^[\s]*::;

      s:[\s]*::;

      next if $_ eq '';
      
      # ok. we can now scan and parse it in

      if (m/^MAILSYSTEM:(.*)/) {
	    my $tsys = $1;

	    $self->{'targetmailsystem'} = $tsys;

	    print "MAILSYSTEM $tsys \n";
	    next;
      }
 
      if (m/^ENDMAILSYSTEM:(.*)/) {
	    my $tsys = $1;

	    if  ($self->{'targetmailsystem'} ne $tsys) {
		print "ERROR207: the scanner didnt match MAILSYSTEM and ENDMAILSYSTEM ... \n$self->{'targetmailsystem'}\n$tsys\n";
		return 1;
	    }

	    print "ENDMAILSYSTEM $tsys \n";
	    next;
      }
 
	if (m/^SOURCE:(.*)/) {
	    my $source = $1;

	    $self->{'targetmaildirectory'} = $source;

	    print "SOURCE $source  \n";
	    next;
      } 
 
	if (m/^PREFIX:(.*)/) {
	    my $prefix = $1;

	    $self->{'prefix'} = $prefix;

	    print "PREFIX $prefix  \n";
	    next;
      } 
 
	if (m/^BASENAME:(.*)/) {
	    $basename = $1;
	    $normpath = '';
	    $sourcepath = '';
	    $subdir = '';
	    @files = ();    
	    @filesmailbox = ();    

	    
	    print "BASENAME $basename \n";

	    next;
      } 

      if (m/^NORMPATH:(.*)/) {
	  $normpath = $1;

	    print "NORMPATH $normpath \n";
	  next;
      }
      
      if (m/^SOURCEPATH:(.*)/) {
	  $sourcepath = $1;
	    print "SOURCEPATH $sourcepath \n";
	  next;
      }

      if (m/^SUBDIR:(.*)/) {
	  $subdir = $1;
	    print "SUBDIR $subdir \n";
	  next;
      }
      if (m/^FILES:(.*):(.*)/) {
	  @files = ();
	  @filesmailbox = ();
	    print "FILES $1 $2\n";
	  next;
      }
      if (m/^FILE:(.*)/) {
	  my $f = $1;
	  push 	  @files, $f;
	    print "FILE $f \n";
	  next;
      }
      if (m/^FILEMAILBOX:(.*)/) {
	  my $f = $1;
	  push 	  @filesmailbox, $f;
	    print "FILEMAILBOX $f \n";
	  next;
      }

      if (m/^ENDBASENAME:(.*)/) {
	  my $endbasename = $1;

	  if ($basename ne $endbasename) {
	      print "ERROR208: non match for basname and endbasenam \n$basename\n$endbasename\n";
	      return 1;
	  }

	  my @f = @files;
	  my @fmbox = @filesmailbox;
	  
	  $self->add_new_node($sourcepath, $basename, $normpath, $subdir, \@f, \@fmbox);  
	  next;
      }
    }

    return 0;
}

sub gen_traget_structure {
    # generate 
    my $self = shift;

    my $converter_function = shift;
    
    my $fh = shift;
    
    my $lt = localtime;

    my $ret = 0;
    
    if ($self->{'targetfile'} eq $self->{'targetmaildirectory'}) {
	print "ERROR209: plan does not work. dont accept a sourcedir same as targetdir\nSOURCEMAILDIR $self->{'targetmaildirectory'}\nTARGET$self->{'targetfile'} \n";
	return 1;
    }
    
    $ret = print $fh '# description of the target source mail directory for mailtransfer
# ' . $lt . '
# we have a list of input directories in here,
# we have a list of output directories in here,
#
# with the files candidates for a transfer to the target system
#
# if you want to tweak the transfer then this is the second spot to do it.
# you can add a targetdir hint...
# you can edit the list of files ..
# the  # is a comment for the line, so you can add a #  in front to comment but not loose a line ...
';
    if (!$ret) {
	print "ERROR210: cannot write to gen structure output.\n";
	return 1;
    }
    
    $ret = print $fh 'MAILSYSTEM:' . $self->{'sourcemailsystem'} . "\n";
    if (!$ret) {
	print "ERROR211: cannot write to gen structure output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCE:' . $self->{'sourcefile'} . "\n";
    if (!$ret) {
	print "ERROR212: cannot write to gen structure output.\n";
	return 1;
    }
    
    $ret = print $fh 'TARGET:' . $self->{'targetfile'} . "\n";
    if (!$ret) {
	print "ERROR213: cannot write to gen structure output.\n";
	return 1;
    }
    
    $ret = print $fh 'PREFIX:' . $self->{'prefix'} . "\n";
    if (!$ret) {
	print "ERROR214: cannot write to gen structure output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCEMAILSYSTEM:' . $self->{'targetmailsystem'} . "\n";
    if (!$ret) {
	print "ERROR215: cannot write to gen structure output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCEMAILDIR:' . $self->{'targetmaildirectory'} . "\n";
    
    foreach my $d (sort keys %{$self->{'nodes'}}) {
	$ret = $self->{'nodes'}->{$d}->gen_traget_structure($converter_function, $self->{'prefix'}, $fh);
	if ($ret != 0) {
	    return 1;
	}
    }

    $ret = print $fh 'ENDMAILSYSTEM:' . $self->{'sourcemailsystem'} . "\n";
    if (!$ret) {
	print "ERROR216: cannot write to gen structure output.\n";
	return 1;
    }
    

    close $fh;

    return 0;
}

sub load_plan {
    # load a plan .. hm, very silly, isnt it ... 
    my $self = shift;

    my $fh = shift;

    my $basename = '';
    my $normpath = '';
    my $sourcepath = '';
    my $subdir = '';
    my $targetmeta = '';
    my $targetbase = '';
    my $targetdatacur = '';
    my $targetdatanew = '';
    my $targetdatatmp = '';
    my @files = ();    
    my @targetfiles = ();    
    my @filesmailbox = ();    
    
    
    # we assume its a description generatete correctly,
    # but the user has added some stuf ...

    while (<$fh>) {
      s:#.*::; # delete any comment

      s:^[\s]*::;

      s:[\s]*::;

      next if $_ eq '';
      
      # ok. we can now scan and parse it in

      if (m/^MAILSYSTEM:(.*)/) {
	    my $tsys = $1;

	    if ($self->{'sourcemailsystem'} ne  $tsys) {
		print "ERROR217: plan sourcemailsystem not the target\n$self->{'sourcemailsystem'}\n$tsys\n";
		return 1;
	    }

	    print "MAILSYSTEM $tsys \n";
	    next;
      }
 
      if (m/^ENDMAILSYSTEM:(.*)/) {
	    my $tsys = $1;

	    if  ($self->{'sourcemailsystem'} ne $tsys) {
		print "ERROR218: the scanner didnt match MAILSYSTEM and ENDMAILSYSTEM ... \n$self->{'tsourcemailsystem'}\n$tsys\n";
		return 1;
	    }

	    print "ENDMAILSYSTEM $tsys \n";
	    next;
      }
 
	if (m/^SOURCE:(.*)/) {
	    my $source = $1;

	    $self->{'ANALYSEFILE'} = $source;

	    print "SOURCE $source  \n";
	    next;
      } 
 

	if (m/^PREFIX:(.*)/) {
	    my $p = $1;

	    $self->{'prefix'} = $p;

	    print "PREFIX $p  \n";
	    next;
      }
      
	if (m/^TARGET:(.*)/) {
	    my $t = $1;

	    $self->{'targetfile'} = $t;

	    print "TARGET $t  \n";
	    next;
      } 
 
	if (m/^SOURCEMAILSYSTEM:(.*)/) {
	    my $t = $1;

	    $self->{'targetmailsystem'} = $t;

	    print "SOURCEMAILSYSTEM $t  \n";
	    next;
      } 
 
	if (m/^SOURCEMAILDIR:(.*)/) {
	    my $t = $1;

	    $self->{'targetmaildirectory'} = $t;

	    print "SOURCEMAILDIR $t  \n";

	    if ($self->{'targetmaildirectory'} eq $self->{'targetfile'}) {
		print "ERROR219: plan does not work. dont accept a sourcedir same as targetdir\nSOURCEMAILDIR $self->{'targetmaildirectory'}\nTARGET$self->{'targetfile'} \n";
		return 1;
	    }
	    
	    next;
      } 
 
	if (m/^BASENAME:(.*)/) {
	    $basename = $1;
	    $normpath = '';
	    $sourcepath = '';
	    $subdir = '';
	    $targetmeta = '';
	    $targetbase = '';
	    $targetdatacur = '';
	    $targetdatanew = '';
	    $targetdatatmp = '';
	    @files = ();    
	    @targetfiles = ();
	    @filesmailbox = ();    
	    
	    print "BASENAME $basename \n";

	    next;
      } 

      if (m/^NORMPATH:(.*)/) {
	  $normpath = $1;

	    print "NORMPATH $normpath \n";
	  next;
      }
      
      if (m/^SOURCEPATH:(.*)/) {
	  $sourcepath = $1;
	    print "SOURCEPATH $sourcepath \n";
	  next;
      }

      if (m/^SUBDIR:(.*)/) {
	  $subdir = $1;
	    print "SUBDIR $subdir \n";
	  next;
      }

      if (m/^TARGETMETA:(.*)/) {
	  $targetmeta = $1;
	    print "TARGETMETA $targetmeta \n";
	  next;
      }

      if (m/^TARGETBASE:(.*)/) {
	  $targetbase = $1;
	    print "TARGETBASE $targetbase \n";
	  next;
      }

      if (m/^TARGETDATACUR:(.*)/) {
	  $targetdatacur = $1;
	    print "TARGETDATACUR $targetdatacur \n";
	  next;
      }

      if (m/^TARGETDATANEW:(.*)/) {
	  $targetdatanew = $1;
	    print "TARGETDATANEW $targetdatanew \n";
	  next;
      }

      if (m/^TARGETDATATMP:(.*)/) {
	  $targetdatatmp = $1;
	    print "TARGETDATATMP $targetdatatmp \n";
	  next;
      }


      if (m/^FILES:(.*):(.*)/) {
	  @files = ();
	  @targetfiles = ();
	  @filesmailbox = ();
	    print "FILES $1 $2\n";
	  next;
      }
      if (m/^READFILE:(.*)/) {
	  my $f = $1;
	  push 	  @files, $f;
	  push     @targetfiles , $f;
	    print "READFILE $f \n";
	  next;
      }
      if (m/^SPLITFILE:(.*)/) {
	  my $f = $1;
	  push 	  @filesmailbox, $f;

	    print "SPLITFILE $f \n";
	  next;
      }
      if (m/^HINT:(.*)/) {
	  my $f = $1;
	  pop 	  @files;
	  pop     @targetfiles;
	    print "HINT $f \n";
	  next;
      }

      if (m/^WRITEFILE:(.*)/) {
	  my $f = $1;
	  pop @targetfiles;
	  push     @targetfiles , $f;
	    print "WRITEFILE $f \n";
	    print "READFILE " . $files[$#files] . "\n";
	  next;
      }

      if (m/^APPENDFILE:(.*)/) {
	  my $f = $1;
	  pop @targetfiles;
	  push     @targetfiles , $f;
	    print "WRITEFILE $f \n";
	    print "APPENDFILE " . $files[$#files] . "\n";
	  next;
      }

      if (m/^ENDBASENAME:(.*)/) {
	  my $endbasename = $1;

	  if ($basename ne $endbasename) {
	      print "ERROR220: non match for basname and endbasenam \n$basename\n$endbasename\n";
	      return 1;
	  }

	  my @f = @files;

	  my @t = @targetfiles;
	  
	  my @fmbox = @filesmailbox;
	  
	  $self->add_new_node($sourcepath, 
			      $basename, 
			      $normpath, 
			      $subdir,
			      $targetmeta,
			      $targetbase,
			      $targetdatacur,
			      $targetdatanew,
			      $targetdatatmp,
			      \@f, \@t,
			      \@fmbox);  
	  next;
      }
    }

    return 0;
}

sub execute {
    # execute the plan ...
    my $self = shift;

    my $fh = shift;
    

    my $lt = localtime;

    my $ret = 0;
    
    print "begin execution .... \n";
    print " $lt \n";
    $ret = print $fh '# execute of plan
#
# ' . $lt . '
# 
';
    if (!$ret) {
	print "ERROR221: cannot write to execute output.\n";
	return 1;
    }
    
    
    $ret = print $fh 'MAILSYSTEM:' . $self->{'sourcemailsystem'} . "\n";
    if (!$ret) {
	print "ERROR222: cannot write to execute output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCE:' . $self->{'sourcefile'} . "\n";
    if (!$ret) {
	print "ERROR223: cannot write to execute output.\n";
	return 1;
    }
    
    $ret = print $fh 'TARGET:' . $self->{'targetfile'} . "\n";
    if (!$ret) {
	print "ERROR224: cannot write to execute output.\n";
	return 1;
    }
    

    if (! -d $self->{'targetfile'} ) {
	print $fh "ERROR225: cannot find TARGET ...\n";
	return 1;
    }
    
    $ret = print $fh 'PREFIX:' . $self->{'prefix'} . "\n";
    if (!$ret) {
	print "ERROR226: cannot write to execute output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCEMAILSYSTEM:' . $self->{'targetmailsystem'} . "\n";
    if (!$ret) {
	print "ERROR227: cannot write to execute output.\n";
	return 1;
    }
    
    $ret = print $fh 'SOURCEMAILDIR:' . $self->{'targetmaildirectory'} . "\n";
    if (!$ret) {
	print "ERROR228: cannot write to execute output.\n";
	return 1;
    }
    

    if (! -d $self->{'targetmaildirectory'} ) {
	print $fh "ERROR229: cannot find SOURCEMAILDIR ...\n";
	return 1;
    }
    
    $ret = print $fh 'ANALYSEFILE:' . $self->{'ANALYSEFILE'} . "\n";
    if (!$ret) {
	print "ERROR230: cannot write to execute output.\n";
	return 1;
    }
    
    
    $ret = print $fh "begin folderoperations execution .... \n";
    if (!$ret) {
	print "ERROR231: cannot write to execute output.\n";
	return 1;
    }
    
    $ret = print "begin folderoperations execution .... \n";
    if (!$ret) {
	print "ERROR232: cannot write to execute output.\n";
	return 1;
    }
    

    if ($self->{'prefix'} ne '' 
	&& $self->{'sourcemailsystem'} eq 'thunderbird') {
	# thunderbird needs this .. or you dont see the rest ...
	my $fh;
	open($fh, ">" . $self->{'targetfile'} . '/' . $self->{'prefix'});
	close $fh;
    }
    
    if ($self->{'prefix'} ne '' 
	&& $self->{'sourcemailsystem'} eq 'seamonkey') {
	# seamonkey needs this .. or you dont see the rest ...
	my $fh;
	open($fh, ">" . $self->{'targetfile'} . '/' . $self->{'prefix'});
	close $fh;
    }

    if ($self->{'prefix'} ne '' 
	&& $self->{'sourcemailsystem'} eq 'kmail') {
	# kmail needs this .. or you dont see the rest ...
	my $prefixfolder = $self->{'targetfile'} . '/' . $self->{'prefix'};

	mkdir $prefixfolder;
    }
    
    foreach my $d (sort keys %{$self->{'nodes'}}) {
	$ret = $self->{'nodes'}->{$d}->create_folders($fh, $self->{'targetfile'});

	if($ret != 0) {
	    return 1;
	}
    }

    system "sync";
    
    if ($ret == 0) {
	print "begin copyoperations execution .... \n";
	$ret = print $fh "begin copyoperations execution .... \n";
	if (!$ret) {
	    print "ERROR233: cannot write to execute output.\n";
	    return 1;
	}
    
	# we first make some logic to see what we are in.
	# then we do the thing that fits ..

	# we have 1 for thunder_to_thunder
	# meaning thunderbird and seamonkey in here, and we transfer
	# the mails one to one by copy whole folderfiles ...
	# same for mutt - but mutt has no target directory structure ...
	# its done outside of it ... it navigates to dirs .. 
	# we have 2 for a transfer to a thunder or seamonky or mutt from the rest...
	# we have 3 for a transfer from the rest to thunder or seamonkey or mutt
	# we have 4 for the rest themselfs ..
	
	my $transfercase = 0;

	if ($self->{'sourcemailsystem'} eq 'thunderbird'
	    && $self->{'targetmailsystem'} eq 'thunderbird') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'seamonkey'
	    && $self->{'targetmailsystem'} eq 'thunderbird') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'thunderbird'
	    && $self->{'targetmailsystem'} eq 'seamonkey') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'seamonkey'
	    && $self->{'targetmailsystem'} eq 'seamonkey') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'mutt'
	    && $self->{'targetmailsystem'} eq 'mutt') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'mutt'
	    && $self->{'targetmailsystem'} eq 'thunderbird') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'mutt'
	    && $self->{'targetmailsystem'} eq 'seamonkey') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'seamonkey'
	    && $self->{'targetmailsystem'} eq 'mutt') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'thunderbird'
	    && $self->{'targetmailsystem'} eq 'mutt') {
	    $transfercase = 1;
	} elsif ($self->{'sourcemailsystem'} eq 'thunderbird') {
	    # others are in, no thunder or seamonkey
	    $transfercase = 2;
	} elsif ($self->{'sourcemailsystem'} eq 'seamonkey') {
	    # others are in, no thunder or seamonkey
	    $transfercase = 2;
	} elsif ($self->{'sourcemailsystem'} eq 'mutt') {
	    # others are in, no thunder or seamonkey or mutt
	    $transfercase = 2;
	} elsif ($self->{'targetmailsystem'} eq 'thunderbird') {
	    # others are in, no thunder or seamonkey
	    $transfercase = 3;
	} elsif ($self->{'targetmailsystem'} eq 'seamonkey') {
	    # others are in, no thunder or seamonkey
	    $transfercase = 3;
	} elsif ($self->{'targetmailsystem'} eq 'mutt') {
	    # others are in, no thunder or seamonkey or mutt
	    $transfercase = 3;
	} else {
	    # we have all the others, no thunder and no seamonkey, so it is
	    # case 4 ...
	    $transfercase = 4;
	}

	# we have now the cases...
	# so we simply do the proper thing ...

	if ($transfercase == 0) {
	    # bad thing. still not covered case ...
	    return 1;
	}

	# we have case 1 : thunder to thunder
	if ($transfercase == 1) {
	    # we simply copy the mailfiles ...
	    foreach my $d (sort keys %{$self->{'nodes'}}) {
		$ret = $self->{'nodes'}->{$d}->thunder_to_thunder_files($fh, $self->{'targetfile'}, $self->{'targetmaildirectory'});

		if ($ret != 0 ) {
		    return 1;
		}
	    }
	} elsif ($transfercase == 2) {
	    # we have to append them ... not to copy ..
	    foreach my $d (sort keys %{$self->{'nodes'}}) {
		$ret = $self->{'nodes'}->{$d}->append_files($fh, $self->{'targetfile'}, $self->{'targetmaildirectory'}, $self->{'copyflags'});

		if ($ret != 0) {
		    return 1;
		}
	    }
	} elsif ($transfercase == 3) {
	    # we want to copy from thunderbird/semonkey/mutt to another, so we have to
	    # split up the files in single files and name them ...
	    foreach my $d (sort keys %{$self->{'nodes'}}) {
		$ret = $self->{'nodes'}->{$d}->split_files($fh, $self->{'targetfile'}, $self->{'targetmaildirectory'}, $self->{'copyflags'});

		if ($ret != 0) {
		    return 1;
		}
	    }
	} elsif ($transfercase == 4) {
	    # for the rest we copy into cur ...
	    foreach my $d (sort keys %{$self->{'nodes'}}) {
		$ret = $self->{'nodes'}->{$d}->copy_files($fh, $self->{'targetfile'}, $self->{'targetmaildirectory'}, $self->{'copyflags'});

		if ($ret != 0) {
		    return 1;
		}
	    }
	}
    }
    
    print "end execution .... code $ret\n";
    $retout = print $fh "end execution .... code $ret\n";
    if (!$retout) {
	print "ERROR234: cannot write to execute output.\n";
	return 1;
    }
    
    
    close $fh;

    return 0;
}


sub prefix {
    # we set the prefix
    my $self = shift;

    if ($#_ == -1) {
	return $self->{'prefix'};
    }

    $self->{'prefix'} = shift;

    return $self->{'prefix'};
}

sub copyflags {
    # the flags for a copy
    my $self = shift;

    if ($#_ == -1) {
	return $self->{'copyflags'};
    }

    $self->{'copyflags'} = shift;

    return $self->{'copyflags'};
}

sub appendflags {
    # the flags fro the append
    my $self = shift;

    if ($#_ == -1) {
	return $self->{'appendflags'};
    }

    $self->{'appendflags'} = shift;

    return $self->{'appendflags'};
}


sub filterit {
    my $self = shift ;

    print "WARNING: dont have a filter in place, so we drop anything ...\n";
    return 1;
}

sub total {
    # we assume 32 bit arithmetik, so we have the size in K as one..
    my $self = shift;

    return $self->{'total'};
    
}

sub anz {
    my $self = shift;

    return $self->{'anz'};
}

sub add_total {
    # we assume 32 bit arithmetik, so we have the size in K as one..
    my $self = shift;

    my $size = shift;
    $self->{'total'} += $size;
    
    return $self->{'total'};
    
}

1;
