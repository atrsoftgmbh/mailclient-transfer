
package MailTransferMatch;

use MailTransferMail;

# atrsoftgmbh 2018
# part of the MailTransfer script system
#
# we hold a match
$version = '1.0.0';

$lastusednumber = 0;

sub initialize {
    # we initialize here our little thing.
    # depending on the mechanism on top we have three diffrent 
    # things in here...
    
    my $self = shift;

    my $type = shift ; # header, body, all

    my $matchreg = shift;

    my $nonmatchreg = shift;

    my $command = shift;

    $self->{type} = $type;
    
    $self->{and} = 0;

    $self->{not} = 0;
    
    $self->{matcher} = [];
    
    $self->{notmatcher} = [];
    
    $self->{command} = [];

    foreach my $reg (@{$matchreg}) {
	eval {
	    my $r = qr/$reg/;

	    push @{$self->{matcher}}, $r;
	};
	if ($@) {
	    print "cannot make regex of $reg ..\n"; 
	}
    }

    foreach my $reg (@{$nonmatchreg}) {
	eval {
	    my $r = qr/$reg/;

	    push @{$self->{nonmatcher}}, $r;
	};
	if ($@) {
	    print "cannot make regex of $reg ..\n"; 
	}
    }
    
    foreach my $comm (@{$command}) {
	push @{$self->{command}}, $comm;
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



sub apply {
    my $self = shift;

    my $c = shift;

    my $t = shift ;
    

    foreach my $m (@{$self->{matcher}}) {
	if ($c =~ /$m/) {
	    # nothing
	} else {
	    # bad. a matcher have NOT to NOT  match ... 
	    return 1;
	}
    }

    foreach my $m (@{$self->{nonmatcher}}) {
	if ($c =~ /$m/) {
	    # bad thing. nonmatcher have NOT to match
	    return 1;
	} else {
	    # nothing to do
	}
    }

    foreach my $m (@{$self->{command}}) {
	if (! -x $m) {
	    print "WARNING : $m not executable for me ... ignore it \n";
	} else {

	    my $mfile = '.mailfilter_command_mail_' . $$ . '.txt';

	    if (-r $mfile) {
		unlink ($mfile);
	    }
	    
	    my $ofh;

	    if (!open($ofh, ">" . $mfile)) {
		print "WARNING: cannot write mail for command ... $mfile ..ignore it\n";
	    } else {
		my $mail = '';

		foreach my $l (@{$a_r}) {
		    $mail .= $l ;
		}

		print $ofh $mail;
		
		close $ofh;
	
		my $sret = system $m . " " . $mfile . " " ;

		unlink ($mfile);

		if ($sret != 0) {
		    return 1;
		}
	    }
	}
    }
    
    return 0;
}


### end

1;

# end of file



