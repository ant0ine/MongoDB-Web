#!perl -T
use Test::More tests => 21;
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

my $page1 = WebPage->new(
    uri => 'http://example.org/1',
    title => 'title1',
);
$store->save($page1);

my $page2 = WebPage->new(
    uri => 'http://example.org/2',
    title => 'title2',
);
$store->save($page2);

my $page3 = WebPage->new(
    uri => 'http://example.org/3',
    title => 'title3',
);
$store->save($page3);

note "find it by title";
{
    my $cursor = $store->find( WebPage => { title => 'title1' });
    isa_ok($cursor, 'MongoDB::Web::Cursor');
    isa_ok($cursor->cursor, 'MongoDB::Cursor');
    cmp_ok($cursor->count, '==', 1, 'one result');

    my $found = $cursor->next;
    isa_ok($found, 'WebPage');
    is($found->uri, $page1->uri, 'same resource');
    ok(! $cursor->next, 'only one result');
}

note "index queries";
{
    my $cursor = $store->find( WebPage => { title => 'title1' });
    ok $cursor->explain->{cursor} =~ /BasicCursor/, 'no index used';
    
    # add an index on title
    $store->ensure_index(WebPage => { title => 1}, { name => 'test_index', safe => 1 });
    $cursor = $store->find( WebPage => { title => 'title1' });
    ok $cursor->explain->{cursor} =~ /BtreeCursor/, 'index used';

    # drop index
    $store->drop_index(WebPage => 'test_index');
}

note "skip, limit, or, reset, sort";
{
    # skip and limit
    my $cursor = $store->find( WebPage => {});
    isa_ok($cursor, 'MongoDB::Web::Cursor');

    is $cursor->count, 3, '3 results';
    $cursor->skip(1);
    is $cursor->count(1), 2, '2 results';
    $cursor->limit(1);
    is $cursor->count(1), 1, '1 result';

    is $cursor->count, 3, '3 results';
    my @subset = $cursor->all;
    is scalar(@subset), 1, '1 result';

    # reset
    $cursor->reset;
    @subset = $cursor->limit(2)->skip(1)->all;
    is scalar(@subset), 2, '2 results';

    # or
    my $query = { '$or' => [
        { title => 'title1' },
        { title => 'title2' },
    ] };
    @subset = $store->find(WebPage => $query)->all;
    is scalar(@subset), 2, '2 results';

    # sort
    $cursor = $store->find(WebPage => {})->sort({ title => -1 });
    isa_ok($cursor, 'MongoDB::Web::Cursor');
    is $cursor->count, 3, '3 results';
    my $first = $cursor->next;
    isa_ok $first, 'WebPage';
    is $first->title, 'title3', 'order by title desc';
}

$store->remove($page1);
$store->remove($page2);
$store->remove($page3);

# $store->remove($_) for $store->find( WebPage => {} )->all; # clean all line
