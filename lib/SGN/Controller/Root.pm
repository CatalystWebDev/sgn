package SGN::Controller::Root;
use Moose;
use namespace::autoclean;

use Scalar::Util 'weaken';
use CatalystX::GlobalContext ();

use CXGN::Login;
use CXGN::People::Person;
use CXGN::DB::Stats;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

SGN::Controller::Root - Root Controller for SGN

=head1 DESCRIPTION

Web application to run the SGN web site.

=head1 PUBLIC ACTIONS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->stash->{template} = '/index.mas';
    $c->stash->{schema}   = $c->dbic_schema('SGN::Schema');
    
    $c->stash->{dbstats}->{features}=sprintf "%8D", $c->dbic_schema('Bio::Chado::Schema')->resultset('Sequence::Feature')->count();
    $c->stash->{dbstats}->{loci}    =sprintf "%8D",$c->dbic_schema('CXGN::Phenome::Schema')->resultset('Locus')->count();
    $c->stash->{dbstats}->{images}  =sprintf "%8D",$c->dbic_schema('CXGN::Metadata::Schema')->resultset('MdImage')->count();
    $c->stash->{dbstats}->{accessions} = sprintf "%8D",$c->dbic_schema('Bio::Chado::Schema')->resultset('Stock::Stock')->count();
    
    $c->stash->{dbstats}->{markers} = sprintf "%8D",$c->dbic_schema('SGN::Schema')->resultset('Marker')->count();
    

}

=head2 default

Attempt to find index.pl pages, and prints standard 404 error page if
nothing could be found.

=cut

sub default :Path {
    my ( $self, $c ) = @_;

    return 1 if $self->_do_redirects($c);

    $c->throw_404;
}

=head2 bare_mason

Render a bare mason component, with no autohandler wrapping.
Currently used for GBrowse integration (GBrowse makes a subrequest for
the mason header and footer).

=cut

sub bare_mason :Path('bare_mason') {
    my ( $self, $c, @args ) = @_;

    # figure out our template path
    my $t = File::Spec->catfile( @args );
    $t .= '.mas' unless $t =~ m|\.[^/\\\.]+$|;
    $c->stash->{template} = $t;

    # TODO: check that it exists

    $c->forward('View::BareMason');
}

=head1 PRIVATE ACTIONS

=head2 end

Attempt to render a view, if needed.

=cut

sub render : ActionClass('RenderView') { }
sub end : Private {
    my ( $self, $c ) = @_;

    return if @{$c->error};

    # don't try to render a default view if this was handled by a CGI
    $c->forward('render') unless $c->req->path =~ /\.pl$/;

    # enforce a default text/html content type regardless of whether
    # we tried to render a default view
    $c->res->content_type('text/html') unless $c->res->content_type;

    # insert our javascript packages into the rendered view
    if( $c->res->content_type eq 'text/html' ) {
        $c->forward('/js/insert_js_pack_html');
        $c->res->headers->push_header('Vary', 'Cookie');
    } else {
        $c->log->debug("skipping JS pack insertion for page with content type ".$c->res->content_type)
            if $c->debug;
    }

}

=head2 auto

Run for every request to the site.

=cut

sub auto : Private {
    my ($self, $c) = @_;
    CatalystX::GlobalContext->set_context( $c );
    $c->stash->{c} = $c;
    weaken $c->stash->{c};

    # gluecode for logins
    #
    unless( $c->config->{'disable_login'} ) {
        my $dbh = $c->dbc->dbh;
        if ( my $sp_person_id = CXGN::Login->new( $dbh )->has_session ) {

            my $sp_person = CXGN::People::Person->new( $dbh, $sp_person_id);

            $c->authenticate({
                username => $sp_person->get_username(),
                password => $sp_person->get_password(),
            });
        }
    }

    return 1;
}



########### helper methods ##########3

sub _do_redirects {
    my ($self, $c) = @_;
    my $path = $c->req->path;
    my $query = $c->req->uri->query || '';
    $query = "?$query" if $query;

    $c->log->debug("searching for redirects ($path) ($query)") if $c->debug;

    # if the path has multiple // in it, collapse them and redirect to
    # the result
    if(  $path =~ s!/{2,}!/!g ) {
        $c->log->debug("redirecting multi-/ request to /$path$query") if $c->debug;
        $c->res->redirect( "/$path$query", 301 );
        return 1;
    }

    # try an internal redirect for index.pl files if the url has not
    # already been found and does not have an extension
    if( $path !~ m|\.\w{2,4}$| ) {
        if( my $index_action = $self->_find_cgi_action( $c, "$path/index.pl" ) ) {
            $c->log->debug("redirecting to action $index_action") if $c->debug;
            my $uri = $c->uri_for_action($index_action, $c->req->query_parameters)
                        ->rel( $c->uri_for('/') );
            $c->res->redirect( "/$uri", 302 );
            return 1;
        }
    }

    # redirect away from cgi-bin URLs
    elsif( $path =~ s!cgi-bin/!! ) {
        $c->log->debug("redirecting cgi-bin url to /$path$query") if $c->debug;
        $c->res->redirect( "/$path$query", 301 );
        return 1;
    }

}


############# helper subs ##########

sub _find_cgi_action {
    my ($self,$c,$path) = @_;

    $path =~ s!/+!/!g;
     my $cgi = $c->controller('CGI')
         or return;

    my $index_action = $cgi->cgi_action_for( $path )
        or return;

    $c->log->debug("found CGI index action '$index_action'") if $c->debug;

    return $index_action;
}

=head1 AUTHOR

Robert Buels, Jonathan "Duke" Leto

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
