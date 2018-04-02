
package MailTransferMail;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#

# do output 
$verbose = 1;

# this is the verion of mine
$version = '1.0.0';

# our id counter
$idcount = 1;

# default from line
$fromline = "From root\@localhost   Mon Feb 12 23:26:05 2018 \n";


# object methods
sub initialize {
    # we initialize here our little thing.
    # depending on the mechanism on top we have diffrent forms
    # things in here...
    
    my $self = shift;

    $self->{id} = $idcount;

    ++$idcount;

    $self->{content} = []; 

    $self->{hstart} = -1; # unkown

    $self->{hend} = -1; # unkown

    $self->{bstart} = -1; # unkown

    $self->{bend} = -1; # unkown

    $self->{nl} = -1 ; # unknown
    
    $self->{kind} = 'unknown' ; # unknown

    if ($#_ == 1 ) {
	# we have the text and the potential header start line number .
	
	$self->{text} = shift;
    
	$self->{hstart} = shift;
    } else {
	# we use the keyword thing

	while ($#_ > -1) {
	    my $k = shift;
	    my $v  = shift;

	    $self{$k} = $v;
	}
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

sub write {
    my $self = shift;

    my $fh = shift;


    my $text = $self->{text};

    my $lines = 0;
    
    my $msg = '';

    my $lastline = '';
    
    for (my $k = $self->{hstart} ; $k <= $self->{hend} ; ++ $k) {
	++ $lines;
	$lastline = $text->[$k];
	$msg .= $text->[$k];
    }
    for (my $k = $self->{bstart} ; $k <= $self->{bend} ; ++ $k) {
	++ $lines;
	$lastline = $text->[$k];
	$msg .= $text->[$k];
    }

    while ($#_ > -1) {
	++ $lines;
	$lastline = $_[0];
	$msg .= shift;
    }

    # mails have to have an empty line as last one
    if ($lastline =~ m:^[\s]*$:) {
	# ok ...
    } else {
	++$lines;
	$msg .= "\n";
    }
    
    my $ret = print $fh $msg;

    if ($ret != 1) {
	die "ERROR901:print failed in write \n";
    }

    return $lines; 
}

sub add_content {
    my $self = shift;

    
}

1;

# end of file



