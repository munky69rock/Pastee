package Pastee::Web;

use strict;
use warnings;
use utf8;
use Kossy;

use DBIx::Sunny;
use Digest::SHA;
use File::Spec;

our $config = +{
	database          => File::Spec->catfile('db', 'pastee.db'),
	max_items_on_list => 10,
};

sub dbh {
	my $self = shift;
	$self->{_dbh} ||= do {
		my $db = File::Spec->catfile($self->root_dir, $config->{database});
		return DBIx::Sunny->connect("dbi:SQLite:dbname=$db", "", "", +{
			Callbacks => +{
				connected => sub {
					my $conn = shift;
					$conn->do(<<EOF);
CREATE TABLE IF NOT EXISTS entry (
  id VARCHAR(255) NOT NULL PRIMARY KEY,
  nickname VARCHAR(255) NOT NULL,
  body TEXT,
  created_at DATETIME NOT NULL
)
EOF
					$conn->do(q{CREATE INDEX IF NOT EXISTS index_created_at ON entry ( created_at )});
					return;
				},
			},
		});
1	};
}

sub add_entry {
	my $self = shift;
	my ($body, $nickname) = @_;
	$body = '' if !defined $body;
	$nickname = 'anonymous' if !defined $nickname;
	#my $id = substr Digest::SHA::sha1_hex($$.join("\0", @_).rand(1000)), 0, 16;
	my $id = substr Digest::SHA::sha1_hex($$.time().rand(1000)), 0, 16;
	$self->dbh->query(
		q{INSERT INTO entry (id, nickname, body, created_at) VALUES (?,?,?,DATETIME('now', 'localtime') )},
		$id, $nickname, $body
	);
	return $id;
}

sub entry_list {
	my $self = shift;
	my %args = @_;
	my $offset = 0;
	my $ipp = $config->{max_items_on_list};
	if (exists $args{offset}) {
		$offset = $args{offset};
	}
	elsif (exists $args{page}) {
		$offset = ($args{page} - 1) * $ipp;
	}
	my $rows = $self->dbh->select_all(
		q{SELECT * FROM entry ORDER BY created_at DESC LIMIT ?,11},
		$offset
	);
	my $next;
	$next = pop @$rows if @$rows > $ipp;
	return $rows, $next;
}

sub get_entry {
	my $self = shift;
	my $id = shift;
	$self->dbh->select_row(qq{
		SELECT * FROM entry
		 WHERE id=?
	}, $id);
}

get '/' => sub {
    my ( $self, $c )  = @_;
    $c->render('index.tx', { });
};

post '/create' => sub {
	my ($self, $c) = @_;
	my $result = $c->req->validator([
     	'body' => {
            rule => [
                ['NOT_NULL','empty body'],
            ],
        },
        'nickname' => {
            default => 'anonymous',
            rule => [
                ['NOT_NULL','empty nickname'],
            ],
        }
	]);
	if ($result->has_error) {
		return $c->render_json(+{ error => 1, messages => $result->errors });
	}
	my $id = $self->add_entry(map { $result->valid($_) } qw/body nickname/);
	$c->render_json(+{ error => 0, location => $c->req->uri_for('/'.$id)->as_string });
};

get '/:id' => sub {
	my ($self, $c) = @_;
	my $id = $c->{args}{id};
	$c->render('item.tx', +{
		id => $id,
		entry => $self->get_entry($id),
	});
};

get '/history' => sub {
	my ($self, $c) = @_;
	my $result = $c->req->validator([
		page => +{
			default => 1,
			rule => [
				['UINT','invalid page value'],
			],
		},
	]);
	$c->halt(403) if $result->has_error;
	my ($entries, $has_next) = $self->entry_list( page => $result->valid('page') );
    $c->render('list.tx', {
		page     => $result->valid('page'),
		entries  => $entries,
		has_next => $has_next,
	});
};

1;
