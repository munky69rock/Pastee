package Pastee::Test;

use strict;
use warnings;

use File::Temp;
use File::Spec;
use File::Basename qw/dirname/;
use Path::Tiny;
use Pastee::Web;

my $root_dir = path(File::Spec->catdir(dirname(__FILE__)))->parent(2)->absolute;

# テスト用DB
$Pastee::Web::config->{database} = File::Spec->catfile(tempdir_from_root(), "test-pastee.db");

sub root_dir { $root_dir }

sub tempdir {
	my %args = @_;
	$args{DIR} ||= File::Spec->catdir($root_dir, 'db');
	$args{CLEANUP} = 1;
	return path(File::Temp::tempdir(%args));
}

sub tempdir_from_root {
	my %args = @_;
	my $tmp_dir = tempdir(%args);
	$tmp_dir =~ s/$root_dir//;
	return $tmp_dir;
}

1;
