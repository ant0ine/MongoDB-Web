#!perl -T
use Test::More tests => 4;
use strict;

use MongoDB::Web;

my %canonicals = (
    'http://example.org/test index.html' => 'http://example.org/test%20index.html',
    ' http://example.org' => 'http://example.org/',
    'HTTP://example.org' => 'http://example.org/',
    'http://example.org//' => 'http://example.org//',
);

for (keys %canonicals) {
    my $expected = $canonicals{$_};
    cmp_ok( MongoDB::Web->canonical_uri($_), 'eq', $expected);
}

