#!perl -T
use Test::More tests => 9;
use strict;
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

# new resources
my $page1 = WebPage->new(
    uri => 'http://example.org/1',
    outlinks => [ 'http://example.org/2' ],
);
$store->save($page1);

my $page2 = WebPage->new(
    uri => 'http://example.org/2',
    outlinks => [ 'http://example.org/1' ],
);
$store->save($page2);

note 'load';
{
    my $cursor = $store->load( $page1 => 'outlinks' );
    isa_ok( $cursor, 'MongoDB::Web::Cursor' );
    is $cursor->count, 1, '1 result';
    my ($loaded) = $cursor->all;
    isa_ok $loaded, 'WebPage';
    is $loaded->uri, $page2->uri, 'this is page2';
}

note 'load_referers';
{
    my $cursor = $store->load_referers( WebPage => outlinks => $page2 );
    isa_ok( $cursor, 'MongoDB::Web::Cursor' );
    is $cursor->count, 1, '1 result';
    my ($loaded) = $cursor->all;
    isa_ok $loaded, 'WebPage';
    is $loaded->uri, $page1->uri, 'this is page1';
}

$store->remove($page1);
$store->remove($page2);

