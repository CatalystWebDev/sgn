package CXGN::Trial::ParseUpload;

use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;

with 'MooseX::Object::Pluggable';


has 'chado_schema' => (
		       is       => 'ro',
		       isa      => 'DBIx::Class::Schema',
		       required => 1,
		      );

has 'filename' => (
		   is => 'ro',
		   isa => 'Str',
		   required => 1,
		  );

has 'parse_errors' => (
		       is => 'ro',
		       isa => 'ArrayRef[Str]',
		       writer => '_set_parse_errors',
		       reader => 'get_parse_errors',
		       predicate => 'has_parse_errors',
		      );

has '_parsed_data' => (
		       is => 'ro',
		       isa => 'HashRef',
		       writer => '_set_parsed_data',
		       predicate => '_has_parsed_data',
		      );

sub parse {
  my $self = shift;

  if (!$self->_validate_with_plugin()) {
    print STDERR "\nCould not validate trial file: ".$self->get_filename()."\n";
    return;
  }

  if (!$self->_parse_with_plugin()) {
    print STDERR "\nCould not parse trial file: ".$self->get_filename()."\n";
    return;
  }

  if (!$self->_has_parsed_data()) {
    print STDERR "\nNo parsed data for trial file: ".$self->get_filename()."\n";
    return;
  } else {
    return $self->_parsed_data();
  }

  print STDERR "\nError parsing trial file: ".$self->get_filename()."\n";
  return;
}


1;
