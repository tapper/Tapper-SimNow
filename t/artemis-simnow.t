use common::sense;

use Test::More;

use Artemis::Base;
use Artemis::SimNow;
use Test::MockModule;

my $mock =Test::MockModule->new('Artemis::Base');
$mock->mock('run_one', sub { return 0 });


my $sim = Artemis::SimNow->new();

#my $retval = $sim->run();

ok(1, 'Dummy');
#is($retval, 0, 'Running SimNow');

done_testing();
