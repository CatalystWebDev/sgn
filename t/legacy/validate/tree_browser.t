use strict;
use warnings;

use lib 't/lib';
use SGN::Test qw/validate_urls/;
use Test::More;

my %urls = (
        "Tree Browser input page"                  => "/tools/tree_browser/",
        "Tree Browser sample tree"                 => "/tools/tree_browser/?tree_string=%281%3A0%2E020058%2C%28%28%28%28%28%282%3A0%2E051985%2C6%3A0%2E002761%29%3A0%2E027131%2C11%3A0%2E405224%29%3A0%2E042208%2C15%3A0%2E067923%29%3A0%2E046508%2C%288%3A1%2E655e%2D08%2C10%3A0%2E155643%29%3A0%2E083277%29%3A0%2E096957%2C9%3A0%2E119609%29%3A0%2E124781%2C%28%283%3A0%2E066341%2C%28%28%284%3A0%2E013384%2C7%3A0%2E007637%29%3A0%2E019214%2C%2016%3A0%2E085744%29%3A0%2E020811%2C12%3A0%2E025839%29%3A0%2E168755%29%3A0%2E086288%2C13%3A0%2E170910%29%3A0%2E016660%29%3A0%2E027472%2C%285%3A0%2E005652%2C14%3A0%2E043026%29%3A0%2E014920%29%3B",
);

validate_urls(\%urls, $ENV{ITERATIONS} || 1 );

done_testing;