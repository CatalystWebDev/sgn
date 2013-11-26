
=head1 NAME

  /CXGN/Bulk.pm

=head1 DESCRIPTION

  The CXGN::Bulk package is a superclass of all the different Bulk packages
  used by the download.pl script. It is never instantiated itself, but contains
  many methods its subclasses share.

=cut

package CXGN::Bulk;

use strict;
use warnings;
use Carp;
use File::Temp;
use File::Spec::Functions;
use Cache::File;

use File::Slurp qw/slurp/;

=head2 new

  Desc: sub new
  Args: hash reference containing parameters from user
  Ret : $self

  All subclasses of Bulk share the same constructor. The constructor takes a reference to a hash
  which contains the parameters as an argument and creates a new variable and value for every
  key-value pair in the hash reference. It creates several other variables for linking to the
  database and printing a web page.

=cut

sub new {
    my $class  = shift;
    my $self   = {};
    my $params = shift;
    foreach ( keys %$params ) {
        $self->{$_} = $params->{$_};
    }
    $self->{tempdir} or confess "must provide a tempdir argument to bulk constructor";
    -d $self->{tempdir} or confess "no such directory $self->{tempdir}";
    $self->{content} = "";    # the content of the page
    $self->{db} = $self->{dbc}
        or confess "must provide a dbc argument (database handle) to bulk constructor";

    my @empty_array = ();
    $self->{data} = \@empty_array;
    bless $self, $class;
    return $self;
}

=head2 create_dumpfile

  Desc: sub create_dumpfile
  Args: none
  Ret : file handle for dumpfile and notfound file

  Creates a dumpfile and a notfound file and returns file handles for them.

=cut

sub create_dumpfile {
    my $self          = shift;
    my $db            = $self->{db};
    my @output_fields = @{ $self->{output_fields} };
    my @notfound      = ();

    if (   !exists( $self->{dump_fh} )
        || !exists( $self->{notfound_fh} ) )
    {

        # generate tmp file names and open files for writing
        $self->{dumpfile} = File::Temp->new( TEMPLATE => catfile( $self->{tempdir}, "bulk-XXXXXX" ), UNLINK => 0 )->filename;
	$self->{dumpfile} =~ s!$self->{tempdir}/!!;

        $self->debug( "FILENAME: " . $self->{dumpfile} );
        my $filepath = catfile($self->{tempdir}, $self->{dumpfile});
        open( $self->{dump_fh}, '>', $filepath )
          || die "Can't open $filepath";
        $self->{notfoundfile} = $self->{dumpfile} . ".notfound";
        open( $self->{notfound_fh}, '>', "$self->{tempdir}/$self->{notfoundfile}" )
	    || die "Can't open $self -> {notfoundfile}";

        # write file header
        @output_fields = @{ $self->{output_fields} };
        my $dump_fh = $self->{dump_fh};
        print $dump_fh join( "\t", @output_fields ) . "\n";
    }

    # warn "dumpfile: $filepath \n";
    return $self->{dump_fh}, $self->{notfound_fh};
}

sub result_summary { 
    my $self = shift;
    
    my $cache_root = catfile($self->{tempdir}, $self->{dumpfile} . ".summary");

    my $lines_read =
	( $self->get_file_lines( catfile($self->{tempdir}, $self->{dumpfile}) ) - 1);
    my $notfoundcount =
      $self->get_file_lines( catfile($self->{tempdir}, $self->{notfoundfile} ));
    my $total        = $lines_read;
    my $file         = $self->{dumpfile};
    my $notfoundfile = $self->{notfoundfile};
    my $idType       = $self->{idType};
    my $query_time   = $self->{query_time};
    my $seq_type     = $self->{seq_type};
    my $est_seq      = $self->{est_seq};
    my $unigene_seq  = $self->{unigene_seq};
    my $filesize =
	(stat( catfile($self->{tempdir}, $self->{dumpfile})))[7] / 1000;
    my $missing_ids     = @{ $self->{ids} } - $notfoundcount - $lines_read;
    my $missing_ids_msg = "";
    my $file_lines = 0; #fix
	#$self->getFileLines( $self->{tempdir} . "/" . $self->{dumpfile} );
    
    my $numlines = scalar( @{ $self->{ids} } );
    if ( $missing_ids > 0 ) {
        $missing_ids_msg = "$missing_ids ids were not retrieved from the database because they were not part of the corresponding unigene set or because there were duplicate entries in the submitted id list.";
    }

    my $fastalink     = " Fasta ";
    my $fastadownload = " Fasta ";
    my $fastamessage  = "Note: Fasta option is not available because you didn't
                        choose a sequence to download.<br />";
    if ( join( " ", @{ $self->{output_fields} } ) =~ /seq/i ) {
        $fastalink =
"<a href=\"/tools/bulk/display?outputType=Fasta&amp;dumpfile=$file&amp;unigene_seq=$unigene_seq&amp;est_seq=$est_seq\">Fasta</a>";
        $fastadownload =
"<a href=\"/tools/bulk/display?outputType=Fasta&amp;dumpfile=$file&amp;unigene_seq=$unigene_seq&amp;est_seq=$est_seq&amp;download=1\">Fasta</a>";
        $fastamessage = "";
    }

    my $cache = Cache::File->new( cache_root => $cache_root );
    
    my $summary_data = { 
	fastalink => $fastalink,
	fastadownload => $fastadownload,
	fastamessage => $fastamessage,
	missing_ids_msg => $missing_ids_msg,
	file => $file,
	total => $total,
	query_time => $query_time,
	filesize => $filesize,
	numlines => $numlines, # number of lines in query
	lines_read => $lines_read,  # number of lines in file
	idType => $idType,
	seq_type => $seq_type,
	est_seq => $est_seq,
	unigene_seq => $unigene_seq,
    };

    foreach my $k (keys(%$summary_data)) { 
	$cache->set($k, $summary_data->{$k});
    }
}


=head2 error_message

  Desc: sub error_message
  Args: none
  Ret : none

  This method is called by download.pl if the Bulk object has a problem with the
  input parameters. It prints a page that contains an error message.

=cut

sub error_message {
    my $self = shift;


    my $html = $self ->{content} . "\n";
    $html .= <<EOH;
<h3>Bulk download error</h3>
I could not process your input.  Possible reasons for this include:
<ul>
<li>You may not have entered any identifiers for download</li>
<li>You may not have entered any identifiers that exist</li>
<li>Your identifiers may not be one-per-line, with no quotation marks, etc (see input example)</li>
<li>The input set may be larger than the limit of 10,000 identifiers</li>
</ul>
Please check your input and use your browser\'s "back" button to go back and try again!
EOH

return $html;
}

=head2 get_file_lines

  Desc: sub get_file_lines
  Args: file; example. $self -> get_file_lines($self->{tempdir});
  Ret : $list[0];

  Counts file lines (used on temp directories).

=cut

sub get_file_lines {
    my $self   = shift;
    my $file   = shift;
    open my $f, $file or die "$! opening $file";
    my $cnt = 0;
    $cnt++ while <$f>;
    return $cnt;
}

=head2 clean_up

  Desc: sub clean_up
  Args: default; example. $bulk -> clean_up();
  Ret : n/a

  Drops unigene, blast, and submitted_ids temp tables (i.e. cleans up after
  queries are done).

=cut

sub clean_up {
    my $self = shift;
    $self->{db}->disconnect();
}

=head2 debug

  Desc: sub debug
  Args: string; example. $self -> debug("input_ok: Input is NOT OK!");
  Ret : n/a

  Function for printing adds break and new line to messages.

=cut

sub debug {
    my $self = shift;

    #print messages if debug flag is set
    my $message = shift;
    if ( $self->{debug} ) {
        print <<EOHTML;
   <h4>Bulk download summary</h4>
    $message <br />
EOHTML
    }
}

=head2 check_ids

  Desc: sub check_ids
  Args: default
  Ret : @ids, array of IDs from input

  A common method between all types of Bulk objects, it checks that there are
  less than 10,000 IDs from input and puts them all into an array, returning
  the array of ids if everything went well, otherwise 0.

=cut

sub check_ids {
    my $self = shift;
    my @ids  = ();

    #do some simple parameter checking

    print STDERR "PROCESSING IDS: $self->{ids}. ($self->{idType})\n";

    return @ids if ( $self->{idType} eq "" );
    return @ids if ( $self->{ids} !~ /\w/ );

    #make sure the input string isn't too big
    return @ids if length( $self->{ids} ) > 1_000_000;


    # clean up data retrieved
    my $ids = $self->{ids};
    $ids =~ s/^\s+//;
    $ids =~ s/\n+/ /g;
    $ids =~ s/\s+/ /g;    # compress multiple returns into one
    $ids =~ s/\r+/ /g;    # convert carriage returns to space
    @ids = split /\s+/, $ids;
    @ids = () if @ids > 10_000;    #limit to 10_000 ids to process
    return @ids;
}

=head2 process_parameters

  Desc: sub process_parameters
  Args: none
  Ret : 1 if the parameters were OK, 0 if not

  Modifies some of the parameters received set in get_parameters. Preparing
  data for the database query.

=cut

sub process_parameters {

}

=head2 process_ids

  Desc: sub process_ids
  Args: default;
  Ret : data from database printed to a file;

  Queries database using Persistent (see perldoc Persistent) and
  object oriented perl to obtain data on Bulk Objects using formatted
  IDs.

=cut

sub process_ids {

}

=head2 accessors get_dumpfile, set_dumpfile

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_dumpfile {
  my $self = shift;
  return $self->{dumpfile}; 
}

sub set_dumpfile {
  my $self = shift;
  $self->{dumpfile} = shift;
}

=head2 accessors get_notfoundfile, set_notfoundfile

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_notfoundfile {
  my $self = shift;
  return $self->{notfoundfile}; 
}

sub set_notfoundfile {
  my $self = shift;
  $self->{notfoundfile} = shift;
}

=head2 accessors get_tempdir, set_tempdir

 Usage:
 Desc:
 Property
 Side Effects:
 Example:

=cut

sub get_tempdir {
  my $self = shift;
  return $self->{tempdir}; 
}

sub set_tempdir {
  my $self = shift;
  $self->{tempdir} = shift;
}


1;
