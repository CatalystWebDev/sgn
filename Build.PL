use lib 'lib';
use SGN::Build;

my $build = SGN::Build->new(
    dist_name          => 'SGN',
    license            => 'perl',
    create_makefile_pl => 'passthrough',

    module_name        => 'SGN::Context',

    # current version of our core libraries distribution
    dist_version  => '0.1',
    dist_author   => 'Lukas Mueller',
    dist_abstract => 'The code and content behind the Sol Genomics Network main website, http://solgenomics.net',

    recursive_test_files => 1,

    build_requires => {
        'Class::MethodMaker'             => 0,
        'Data::UUID'                     => 0,
        'File::Temp'                     => 0,
        'HTML::Lint'                     => 0,
        'Parse::Deb::Control'            => 0,
        'Test::JSON'                     => 0,
        'List::Util'                     => 0,
        'Test::Most'                     => 0,
        'Test::WWW::Mechanize'           => 0,
        'Test::WWW::Mechanize::Catalyst' => '0.50',
        'Test::WWW::Selenium'            => 0,
        'Test::MockObject'               => 0,
	'Module::Build::Tiny'            => 0,
    },
    requires => {
        'perl'                                     => '5.10.0',
        'version'                                  => '0.77',
        'autodie'                                  => 0,
        'IPC::System::Simple'                      => 0,         #< required for autodie :all
        'Algorithm::Combinatorics'                 => 0,
        'Array::Utils'                             => 0,
	'Barcode::Code128'                         => '2.21',
	'Bio::BLAST::Database'                     => 0,
        'Bio::Chado::Schema'                       => '0.20000',
        'Bio::Root::Version'                       => '1.006001',
        'Bio::GMOD::Blast::Graph'                  => '0.01',
	'Bio::GMOD::GenericGenePage'                   => 0,
        'Bio::Graphics::FeatureFile'               => 0,
        'Cache::File'                              => 0,
	'Captcha::reCAPTCHA'                       => 0,
        'Catalyst::Runtime'                        => '5.80024',
        'Catalyst::Controller::CGIBin'             => '0.029',
        'Catalyst::Controller::REST'               => 0,
        'Catalyst::Action::RenderView'             => 0,
        'Catalyst::Plugin::Authentication'         => 0,
        'Catalyst::Plugin::Authorization::Roles'   => 0,
        'Catalyst::Plugin::ConfigLoader'           => 0,
        'Catalyst::Plugin::Static::Simple'         => 0,
        'Catalyst::View::Bio::SeqIO'               => 0,
        'Catalyst::View::Email'                    => 0,
        'Catalyst::View::Download::CSV'            => 0,
        'Catalyst::View::HTML::Mason'              => 0,
        'Catalyst::Controller::HTML::FormFu'       => 0,
        'Catalyst::View::JavaScript::Minifier::XS' => '2.100000',
        'CatalystX::GlobalContext'                 => 0,
	'Chart::Clicker'                           => 0,
	'Class::DBI'                               => 0,
	'Class::Singleton'                         => 0,
        'Config::JFDI'                             => 0,
        'CGI'                                      => 0,
	'Data::BitMask'                            => 0,
        'Data::Page'                               => 0,
        'Data::Visitor::Callback'                  => 0,
        'DateTime'                                 => 0,
        # Remove the following dep when XML::Atom is fixed to depend on it and released
        'DateTime::TimeZone'                       => '1.31',
        'DateTime::Format::Flexible'               => 0,
	'DateTime::Format::Pg'                     => 0,
	'Digest::Crc32'                            => 0,
        'DBIx::Class'                              => 0,
        'DBIx::Connector'                          => 0,
	'enum'                                     => 0,
        'File::Basename'                           => 0,
        'File::Copy'                               => 0,
        'File::Flock'                              => 0,
        'File::NFSLock'                            => 0,
        'File::Slurp'                              => '9999.19',      
        'File::Spec::Functions'                    => 0,
        'File::Temp'                               => 0, 
        'Number::Bytes::Human'                     => '0.07',
        'GD'                                       => 0,
	'GD::Graph::bars'                          => 0,
        'GD::Graph::Map'                           => 0,
        'GD::Graph::points'                        => 0,
        'GD::Text'                                 => 0,
        'Hash::Merge'                              => 0,
        'HTML::Entities'                           => 0,
        'HTML::FormFu'                             => 0,
        'HTML::Mason'                              => 0,
        'HTML::TreeBuilder::XPath'                 => 0,
        'IO::String'                               => 0,
	'IPC::Run3'                                => 0,
        'Image::Size'                              => 0,
        'JSAN::ServerSide'                         => '0.06',
        'JSON'                                     => 0,
        'JSON::XS'                                 => '2.24',
        'JSON::Any'                                => 0,
     #   'jQuery::File::Upload'                     => 0,
        'Lingua::EN::Inflect'                      => 0,
        'List::AllUtils'                           => 0,
	'List::Compare'                            => 0,
        'List::Util'                               => 0,
        'LWP::UserAgent'                           => 0,
        'Mail::Sendmail'                           => 0,
	'Math::Base36'                             => 0,
        'Math::Round::Var'                         => 0,
        'Memoize'                                  => 0,
        'Modern::Perl'                             => 0,
        'Module::Build'                            => '0.36',
	'Module::Runtime'                          => 0,
        'Module::Find'                             => 0,
        'Module::Pluggable::Object'                => 0,      
        'Moose'                                    => 0,
        'MooseX::Declare'                          => 0,
	'MooseX::FollowPBP'                        => 0,
        'MooseX::Method::Signatures'               => '0.30',
        'MooseX::Object::Pluggable'                => 0,
        'MooseX::Types::Path::Class'               => 0,
        'MooseX::Types::URI'                       => 0,
        'MooseX::Singleton'                        => 0,
        'Number::Format'                           => 0,
        'namespace::autoclean'                     => 0,
	'Params::Util'                             => 0,
	'PDF::Create'                              => 0,
        'Scalar::Util'                             => 0,
        'SOAP::Transport::HTTP'                    => 0,
	'Spreadsheet::WriteExcel'                  => 0,
        'Spreadsheet::ParseExcel'                  => 0,
        'Statistics::Descriptive'                  => 0,
        'Storable'                                 => 0,
	'String::Approx'                           => 0,
	'String::CRC'                              => 0,
	'SVG'                                      => 0,
        'Test::More'                               => 0,
        'Test::Class'                              => 0,
        'Test::WWW::Mechanize'                     => 1.3,
        'Test::WWW::Mechanize::Catalyst'           => 0,
        'Text::ParseWords'                         => 0,
        'Tie::Function'                            => 0,
        'Tie::UrlEncoder'                          => 0,
        'Time::HiRes'                              => 0,
        'Try::Tiny'                                => 0,
        'URI'                                      => 0,
        'URI::Escape'                              => 0,
        'URI::FromHash'                            => 0,
	'XML::Feed'                                => 0,
        'XML::Generator'                           => 0,
        'XML::Atom'                                => 0,
        'XML::Twig'                                => 0,
        'YAML::Any'                                => 0,
	'R::YapRI'                                 => 0,
        'WWW::Mechanize::TreeBuilder'              => 0,
    },
);

$build->create_build_script;
