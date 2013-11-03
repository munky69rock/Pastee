use strict;
use warnings;
use Test::More;
use File::Basename qw/dirname/;
use File::Spec;
use Path::Tiny;

use Pastee::Web;
use Pastee::Test;

like $Pastee::Web::config->{database}, qr/test-pastee\.db$/, 'connect mock database after "use Pastee::Test"';

done_testing;
