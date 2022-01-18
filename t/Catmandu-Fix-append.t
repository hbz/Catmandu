#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::append';
    use_ok $pkg;
}

is_deeply $pkg->new('name', 'y')->fix({name => 'joe'}), {name => "joey"},
    "append to value";

is_deeply $pkg->new('names.*.name', 'y')
    ->fix({names => [{name => 'joe'}, {name => 'rick'}]}),
    {names => [{name => 'joey'}, {name => 'ricky'}]},
    "append to wildcard values";

is_deeply $pkg->new('animals.0', ' is cool')
    ->fix({animals => ['dog', 'cat', 'zebra']}),
    {animals => ['dog is cool', 'cat', 'zebra']}, "append to array index";

is_deeply $pkg->new('animals.*', ' is cool')
    ->fix({animals => ['dog', 'cat', 'zebra']}),
    {animals => ['dog is cool', 'cat is cool', 'zebra is cool']},
    "append to trailing wildcard values";

is_deeply $pkg->new('animals', ' is cool')
    ->fix({animals => ['dog', 'cat', 'zebra']}),
    {animals => ['dog', 'cat', 'zebra']}, "append only to string values";

done_testing 6;
