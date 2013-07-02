
package CXGN::Stock::StockTemplate;


=head1 NAME

CXGN::Stock::StockTemplate - an object to handle SGN stock data uploaded from a spreadsheet template

=head1 USAGE

 my $sbt = CXGN::Stock::Stocktemplate->new({ schema => $schema} );


=head1 DESCRIPTION


=head1 AUTHORS

 Naama Menda (nm249@cornell.edu)

=cut


use strict;
use warnings;
use Moose;
use Bio::Chado::Schema;
use Try::Tiny;

use Spreadsheet::ParseExcel;


has 'schema' => (
    is  => 'rw',
    isa =>  'DBIx::Class::Schema',
    );

has 'parsed_data' => (
    is => 'rw'
    );

has 'parse_errors' => (
    is => 'rw'
    );

has 'verify_errors' => (
    is => 'rw'
    );
has 'warnings' => (
    is => 'rw'
    );
has 'store_error' => (
    is => 'rw'
    );
has 'store_message' => (
    is => 'rw'
    );

sub parse {
################################ 
    my $self = shift;
    my @errors;
    my ($file , $metadata, $identifier_prefix, $db_name ) = @_;
    my $hashref; #hashref of hashrefs for storing the uploaded data , to be used for checking the fields
 
#Expected format:
#A. Spreadsheet identifier: B. $spreadsheet_unique_id
#A. trial name B. $name 
#A. $trial_description
#A. plants per plot: B. $plants_per_plot 
#A. Operator: B. $operator (user input)
#A. Date: B. $date (user input) 
#G... $trait_name [units] 
#1.. A. $row_number B. $clone_name C. $block D. $plot_id E. $rep F. $number_of_surviving_plants G. $trait_ontology_id 

    my $parser   = Spreadsheet::ParseExcel->new();
    my $workbook = $parser->parse($file); # $file is an Excel file
    if ( !defined $workbook ) {
        push @errors,  $parser->error(), ".\n";
        $self->parse_errors(\@errors);
        #die;
	return;
    }
    my $worksheet = ( $workbook->worksheets() )[0]; #support only one worksheet
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    if ($col_max < 3 || $row_max < 9 ) {#must have header and at least one row of phenotypes
      push @errors, "Spreadsheet is missing header\n";
      $self->parse_errors(\@errors);
      return;
    }
    #hash for column headers
    my %headers;
    #metadata is stored in rows 1..6
    my $spreadsheet_id  = $worksheet->get_cell(1,2);
    my $trial_name      = $worksheet->get_cell(2,2);
    my $trial_desc      = $worksheet->get_cell(3,1);
    my $plants_per_plot = $worksheet->get_cell(4,2);
    my $operator        = $worksheet->get_cell(5,2);
    my $date            = $worksheet->get_cell(6,2);
    if (!$spreadsheet_id) {
      push @errors, "Spreadsheet ID is missing from the header\n";
    }
    if (!$trial_name) {
      push @errors, "Trial name is missing from the header\n";
    }
    if (!$operator) {
      push @errors, "The name of the operator is missing from the header\n";
    }
    if (!$date) {
      push @errors, "The date is missing from the header\n";
    }
    #add a check to make sure that the data is valid?
    if (@errors) {
      $self->parse_errors(\@errors);
      return;
    }

    # Row #7 can be skipped, as it contains trait names just for human readability
#    for my $row ( 8 .. $row_max ) {
    for my $col ( $col_min .. $col_max ) {
        my $cell = $worksheet->get_cell( 8, $col );
        my $value  =  $cell->value() ;
        my $unformatted_value = $cell->unformatted() ;
        next unless $cell;
        ## read the header row, make a hash of names to column numbers, then in the data rows, get_cell($row, $col_for_header{'SomeHeader'})
        $headers{$value} = $col;
    }
    for my $row ( 9 .. $row_max ) { # phenotypes should be from row 9 and on
        # got the row number, now look at the column headers
        my $plot_stock_id =  $worksheet->get_cell ($row , $headers{'PLOT'} );
        my $replicate = $worksheet->get_cell ($row , $headers{'REP'});
        my $clone_name = $worksheet->get_cell ($row , $headers{'DESIG'});
        my $block = $worksheet->get_cell ($row , $headers{'BLOCK'});
        my $planted_plants = $worksheet->get_cell ($row , $headers{'NOPLT'});
        my $surv_plants = $worksheet->get_cell ($row , $headers{'NOSV'});
        foreach my $header (keys %headers) {
            if ($header =~ m/^CO.+?:\d{7}.+?/ ) {
                my $value = $worksheet->get_cell( $row , $header );
                ## remove spaces
                $value =~ s/^\s+//;
                $value =~ s/\s+$//;
                ###
                my ($full_accession, $full_unit ) = split(/\|/, $header); # do we support units in a spreadsheet upload?
                my ($value_type, $unit_value) = split(/\:/, $full_unit);
                my ($db_name, $accession) = split (/\:/ , $full_accession);
                #print STDERR "db_name = '$db_name' sp_accession = '$sp_accession'\n";
                next() if (!$accession);
                ####################
                #skip non-numeric values
                if ($value !~ /^\d/) {
                    if ($value eq "\." ) { next; }
                    push @errors,  "** Found non-numeric value in column $header (value = '" . $value ."') Row = $row. \n";
                    next;
                }
                #####################
                $hashref->{join("\t", $spreadsheet_id, $operator, $date, $row) }->{$plot_stock_id}->{$full_accession}->{replicate} = $replicate;
                $hashref->{join("\t", $spreadsheet_id, $operator, $date, $row) }->{$plot_stock_id}->{$full_accession}->{block} = $block;
                $hashref->{join("\t", $spreadsheet_id, $operator, $date, $row) }->{$plot_stock_id}->{$full_accession}->{planted_plants} = $planted_plants;
                $hashref->{join("\t", $spreadsheet_id, $operator, $date, $row) }->{$plot_stock_id}->{$full_accession}->{surviving_plants} = $surv_plants;
                $hashref->{join("\t", $spreadsheet_id, $operator, $date, $row) }->{$plot_stock_id}->{$full_accession}->{value} = $value;
            }
        }
    }
    ##unique#  PLOT REP  DESIG  BLOCK NOPLT NOSV CO:0000010	CO:0000099|scale:cassavabase  CO:0000018|unit:cm   CO:0000039|date:1MAP
###########
#################################
    #my ($op_name, $project_id, $location_id, $stock_id, $cvterm_accession, $value, $date, $count);
    $self->parsed_data($hashref);
    $self->parse_errors(\@errors);
}

sub verify {
    my $self = shift;
    my $schema = $self->schema;
    #check is stock exists and if cvterm exists.
    #print error only if stocks do not exist and the cvterms
    my $hashref = $self->parsed_data;
    my @errors;
    my @verify;
    my @warnings;
    foreach my $key (keys %$hashref) {
        ##$hashref->{join("\t", $spreadsheet_id, $operator, $date, $row) }->{$plot_stock_id}->{$cvterm_accession}->{replicate} = $replicate;
        my ($spreadsheet_id, $operator, $date, $row) = split(/\t/, $key);
        print STDERR "***** verify found key $key !!!!!!!\n\n";
        print STDERR "verify :  ... . . . .spreadsheet = $spreadsheet_id, operator = $operator, date = $date, row = $row \n\n";
        ###
        foreach my $plot_stock_id (keys %{$hashref->{$key} } ) {
            #check if the stock exists
            print STDERR "verify .. Looking for stock_id $plot_stock_id\n";
            my $stock = $schema->resultset("Stock::Stock")->find( { stock_id => $plot_stock_id } );
            if (!$stock) { push @errors, "Stock $plot_stock_id does not exist in the database!\n"; }
            foreach my $cvterm_accession (keys %{$hashref->{$key}->{$plot_stock_id} } ) {
                print STDERR "verify ... Looking for accession $cvterm_accession..\n";
                my ($db_name, $accession) = split (/:/, $cvterm_accession);
                if (!$db_name) { push @errors, "could not find valid db_name in accession $cvterm_accession\n";}
                if (!$accession) { push @errors, "Could not find valid cvterm accession in $cvterm_accession\n";}
                #check if the cvterm exists
                my $db = $schema->resultset("General::Db")->search(
                    { 'me.name' => $db_name } );
		if ($db->count) {
                    my $dbxref = $db->search_related('dbxrefs', { accession => $accession } );

                    if ($dbxref->count) {
                        my $cvterm = $dbxref->search_related("cvterm", {} )->single;
                        if (!$cvterm) { push @errors, "NO cvterm found in the database for accession $cvterm_accession!\n db_name = '" .  $db_name  . "' , accession = '" .  $accession . "' \n";
			}
                    } else {
                        push @errors, "No dbxref found for cvterm accession $accession\n";
                    }
                } else {
                    push @errors , "db_name $db_name does not exist in the database! \n";
                }
            }
        }
    }
    $self->warnings(\@warnings);
    foreach my $err (@errors) {
        print STDERR " *!*!*!error = $err\n";
    }
    $self->verify_errors(\@errors);
}

sub store {
    my $self = shift;
    my $schema = $self->schema;
    my $hashref = $self->parsed_data;
    my $message;

    my $coderef = sub {
        # find the cvterm for a phenotyping experiment
        my $pheno_cvterm = $schema->resultset('Cv::Cvterm')->create_with(
            { name   => 'phenotyping experiment',
              cv     => 'experiment type',
              db     => 'null',
              dbxref => 'phenotyping experiment',
            });
        print STDERR " ***store: phenotyping experiment cvterm = " . $pheno_cvterm->cvterm_id . "\n";
        ##################
        #This has to be stored in the database when adding a new project for these plots
        my $field_layout_experiment = 'field layout'; #############################
        ################
        foreach my $key (keys %$hashref) {
            my ($spreadsheet_id, $operator, $date, $row) = split(/\t/, $key);
            foreach my $plot_stock_id (keys %{$hashref->{$key} } ) {
                print STDERR " *** store: loading information for stock $plot_stock_id \n";
                foreach my $cvterm_accession (keys %{$hashref->{$key}->{$plot_stock_id} } ) {
                    print STDERR " ** store: cvterm_accession = $cvterm_accession\n";
                    my $replicate = $hashref->{$key}->{$plot_stock_id}->{$cvterm_accession}->{replicate};
                    my $block = $hashref->{$key}->{$plot_stock_id}->{$cvterm_accession}->{block};
                    my $planted_plants = $hashref->{$key}->{$plot_stock_id}->{$cvterm_accession}->{planted_plants};
                    my $surviving_plants = $hashref->{$key}->{$plot_stock_id}->{$cvterm_accession}->{surviving_plants};
                    my $value = $hashref->{$key}->{$plot_stock_id}->{$cvterm_accession}->{value};

                    print STDERR " ** store: value = $value\n";
                    my ($db_name, $accession) = split (/:/, $cvterm_accession);
                    my $db = $schema->resultset("General::Db")->search(
                        {'me.name' => $db_name, } );
                    print STDERR " ** store: found db $db_name , accession = $accession \n";
                    if ($db) {
                        my $dbxref = $db->search_related("dbxrefs", { accession => $accession, });
                        if ($dbxref) {
                            my $cvterm = $dbxref->search_related("cvterm")->single;
                            #now get the value and store the whole thing in the database!
                            my $stock = $self->schema->resultset("Stock::Stock")->find( { stock_id => $plot_stock_id});
                            my $stock_name = $stock->name;
################
                            my $field_exp = $stock->nd_experiment_stocks->search_related(
                                'nd_experiments' ,
                                {
                                    'type.name' => $field_layout_experiment },
                                { join => 'type' }
                                )->single; # there should be one field experiment per plot stock
                            my $location_id = $field_exp->nd_geolocation_id;
                            my $project = $field_exp->nd_experiment_projects->single ; #there should be one project linked with the field experiment
                            my $project_id = $project->project_id;

                            ###store a new nd_experiment. One phenotyping experiment per upload
                            #find if a phenotyping experiment exists for this location
                            my $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->find(
                                {
                                    nd_geolocation_id => $location_id,
                                    type_id => $pheno_cvterm->cvterm_id(),
                                } );
                            my ($op_prop, $date_prop);
                            ## Find if the experiment has the date and person of this upload, if yes, use the existing one, if no, create a new nd_experiment
                            if ($experiment) {
                                $op_prop = $experiment->search_related(
                                    'nd_experimentprops' , {
                                        'type.name' => 'operator',
                                        value       => $operator,
                                    },
                                    { join => 'type' }
                                    )->single;
                                $date_prop = $experiment->search_related(
                                    'nd_experimentprops' , {
                                        'type.name' => 'date',
                                        value       => $date,
                                    },
                                    { join => 'type' }
                                    )->single;
                            }
                            # Create a new experiment, if one does not exist
                            # or ff operator and date are not linked with the existing experiment
                            if ( !($op_prop && $date_prop) || !$experiment ) {
                                $experiment = $schema->resultset('NaturalDiversity::NdExperiment')->find(
                                    {
                                        nd_geolocation_id => $location_id,
                                        type_id => $pheno_cvterm->cvterm_id(),
                                    } );
                                print STDERR " ** store: created new experiment " . $experiment->nd_experiment_id . "\n";
                                $experiment->create_nd_experimentprops(
                                    { date => $date } ,
                                    { autocreate => 1 , cv_name => 'local' }
                                    );
                                $experiment->create_nd_experimentprops(
                                    { operator => $operator } ,
                                    { autocreate => 1 , cv_name => 'local' }
                                    );
                            }
                            ##
                            #link the experiment to the project
                            $experiment->find_or_create_related('nd_experiment_projects', {
                                project_id => $project_id
                                                                } );
                            print STDERR " ** store: linking experiment " . $experiment->nd_experiment_id . " with project $project_id \n";
                            #link the experiment to the stock
                            $experiment->find_or_create_related('nd_experiment_stocks' , {
                                stock_id => $plot_stock_id,
                                type_id  =>  $pheno_cvterm->cvterm_id,
                                                                });
                            print STDERR " ** store: linking experiment " . $experiment->nd_experiment_id . " to stock $plot_stock_id \n";
                            my $uniquename = "Stock: " . $plot_stock_id . ", trait: " . $cvterm->name . " date: $date" . "  operator = $operator" ;
                            my $phenotype = $cvterm->find_or_create_related(
                                "phenotype_cvalues", {
                                    observable_id => $cvterm->cvterm_id,
                                    value => $value ,
                                    uniquename => $uniquename,
                                });
                            print STDERR " ** store: added phenotype value $value , observable = " . $cvterm->name ." uniquename = $uniquename \n";
                            #link the phenotpe to the experiment
                            $experiment->find_or_create_related('nd_experiment_phenotypes' , {
                                phenotype_id => $phenotype->phenotype_id });
                            $message .= "Added phenotype: trait= " . $cvterm->name . ", value = $value, to stock " . qq|<a href="/stock/$plot_stock_id/view">$stock_name</a><br />| ;
                        }
                    }
                }
            }
        }
    };
    my $error;
    try {
        $schema->txn_do($coderef);
        $error = "Store completed!";
    } catch {
        # Transaction failed
        $error =  "An error occured! Cannot store data! <br />" . $_ . "\n";
    };
    $self->store_error($error);
    $self->store_message($message);
}

###
1;#
###
