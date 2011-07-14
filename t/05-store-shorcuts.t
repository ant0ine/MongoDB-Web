#!perl -T
use Test::More tests => 12;
use strict;
use warnings;
use lib 't';

use Data::Dumper;

use MongoDB;
use MongoDB::Web::Store;

use WebPage;

my $host = $ENV{MONGODB_HOST} || 'localhost';
my $store = MongoDB::Web::Store->new(
    database => MongoDB::Connection->new(host => $host, port => 27017)->test_mongodb_web
);
isa_ok($store, 'MongoDB::Web::Store');

WebPage->set_store($store);

note "new";

my $page = WebPage->new(
    uri => 'http://example.orG',
    title => 'example',
    outlinks => [ 'http://example2.orG/index.html' ],
    is_fresh => 1,
);

note 'save';
ok $page->save, 'save';

note 'load_by_uri';
my $same = WebPage->load_by_uri( $page->uri );
isa_ok $same, 'WebPage';
is $same->uri, $page->uri, 'uri';

note 'load_by_mongodb_id';
my $more = WebPage->load_by_mongodb_id( $same->mongodb_id ); 
isa_ok $more, 'WebPage';
is $more->uri, $page->uri, 'uri';

note 'find';
my $cursor = WebPage->find( {} );
isa_ok $cursor, 'MongoDB::Web::Cursor';
isa_ok $cursor->cursor, 'MongoDB::Cursor';
is $cursor->class, 'WebPage';
is $cursor->count, 1, '1 page';

note 'remove';
ok $same->remove, 'remove';
is( WebPage->find( {} )->count, 0, 'removed');

