#!perl -T
use Test::More tests => 36;
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

note "new";

my $page = WebPage->new(
    uri => 'http://example.orG',
    title => 'example',
    outlinks => [ 'http://example2.orG/index.html' ],
    is_fresh => 1,
);

isa_ok $page, 'WebPage';
isa_ok $page, 'MongoDB::Web::Resource';
is $page->uri, 'http://example.org/', 'uri is coerced';
is $page->title, 'example', 'title';
is_deeply $page->outlinks, [ 'http://example2.org/index.html' ], 'uris, coerced';
is $page->is_fresh, 1, 'is_fresh';
is $page->mongodb_id, undef, 'mongodb_id';

note "document";
my $document = $page->document;
is_deeply( $document, {
    uri => 'http://example.org/',
    title => 'example',
    outlinks => [ 'http://example2.org/index.html' ],
}, 'document');

note 'save';
is $store->class_to_collection_name('WebPage'), 'webpage', 'collection name';
my $collection = $store->class_to_collection('WebPage');
isa_ok $collection, 'MongoDB::Collection';
ok $store->save($page), 'save';

note 'load_by_uri';
my $same = $store->load_by_uri( WebPage => $page->uri );
isa_ok $same, 'MongoDB::Web::Resource';
isa_ok $same, 'WebPage';
is $same->uri, 'http://example.org/', 'uri';
is $same->title, 'example', 'title';
is_deeply $page->outlinks, [ 'http://example2.org/index.html' ], 'uris';
is $same->is_fresh, undef, 'is_fresh is not stored';
ok $same->mongodb_id, 'has mongodb_id';

note 'load_by_mongodb_id';
my $more = $store->load_by_mongodb_id( WebPage => $same->mongodb_id ); 
isa_ok $more, 'MongoDB::Web::Resource';
isa_ok $more, 'WebPage';
is $more->uri, 'http://example.org/', 'uri';
is $more->title, 'example', 'title';
ok $more->mongodb_id, 'has mongodb_id';

note 'find';
my $cursor = $store->find( WebPage => {} );
isa_ok $cursor, 'MongoDB::Web::Cursor';
isa_ok $cursor->cursor, 'MongoDB::Cursor';
is $cursor->class, 'WebPage';
is $cursor->count, 1, '1 page';

note 'find_uri';
my $list = $store->find_uri( WebPage => {} );
isa_ok $list, 'ARRAY';
is_deeply $list, [ $page->uri ], 'correct list';

note 'find_mongodb_id';
$list = $store->find_mongodb_id( WebPage => {} );
isa_ok $list, 'ARRAY';
is_deeply $list, [ $same->mongodb_id ], 'correct list';

note 'unique uri index';

my $dupe = WebPage->new( uri => 'http://example.orG', title => 'example' );
ok $store->save($page), 'save dupe';
is $store->find( WebPage => {} )->count, 1, 'still 1';

note 'remove';
ok $store->remove($page), 'remove';
is $store->find( WebPage => {} )->count, 0, 'removed';

