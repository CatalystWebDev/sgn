use lib "t/lib";
use Modern::Perl;
use SGN::Test::WWW::Selenium;


my $sel = SGN::Test::WWW::Selenium->new(
            port    => 4444,
            browser => "*firefox",
        );
my @ORGANISM_IDS = ("Nicotiana attenuata","Capsicum annuum", "Solanum lycopersicoides","Solanum neorickii","Solanum lycopersicum", "Datura metel","Solanum melongena");
my $TABLEID= "id=xtratbl";

#check innerHTML of div when mouseover
$sel->start;
$sel->open("http://sgn.localhost.localdomain/content/sgn_data.pl");
    foreach (@ORGANISM_IDS){
        print "\n \n Information for ".$_."\n";
        $sel->mouse_over("id=".$_);
        print $sel->get_text($TABLEID)."\n";
    }
#check if innerHTML is correct when mouseout
    foreach(@ORGANISM_IDS){
        print "\n\n onmouseout for ".$_."\n";
        $sel->mouse_out("id=".$_);
        print $sel->get_text($TABLEID)."\n";
    }
$sel->stop;
