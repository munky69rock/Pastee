use strict;
use warnings;
use Test::More;

use Pastee::Web;
use Pastee::Test;

my $app = Pastee::Web->new( Pastee::Test->root_dir );
my $entry_table = 'entry';

sub init_db {
	$app->dbh->query(qq/DELETE FROM $entry_table/);
}

subtest 'dbh' => sub {
	is $app->dbh->select_one(qq/SELECT count(*) FROM $entry_table/), 0;
};

subtest 'add_entry & get_entry' => sub {
	init_db();
	my $id = $app->add_entry('body', 'nickname');
	my $res = $app->get_entry($id);
	is $res->{body}, 'body';
	is $res->{nickname}, 'nickname';

	# without nickname
	my $id2 = $app->add_entry('body');
	my $res2 = $app->get_entry($id2);
	is $res2->{nickname}, 'anonymous';
};

subtest 'entry_list' => sub {
	init_db();
	# sort
	for (1 .. 15) {
		$app->add_entry("body$_", "nickname$_");
	}
	my ($list, $next) = $app->entry_list;

	is $list->[0]->{body}, 'body15';
	is scalar @$list, 10;
	ok $next;
	
	# pagination
	($list, $next) = $app->entry_list( page => 2 );
	is $list->[0]->{body}, 'body5';
	is scalar @$list, 5;
	ok !$next;
};

done_testing;
