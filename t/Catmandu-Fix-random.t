#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::random';
    use_ok $pkg;
}

is_deeply $pkg->new('random', '1')->fix({}), {random => 0},
    "add random field at root";

is_deeply $pkg->new('deeply.nested.$append.random', '1')->fix({}),
    {deeply => {nested => [{random => 0}]}};

is_deeply $pkg->new('deeply.nested.1.random', '1')->fix({}),
    {deeply => {nested => [undef, {random => 0}]}};

is_deeply $pkg->new('deeply.nested.$append.random', '1')
    ->fix({deeply => {nested => {}}}), {deeply => {nested => {}}},
    "only add field if the path matches";

like $pkg->new('random', '10')->fix({})->{random}, qr/^[0-9]$/,
    "add a random number";

is_deeply $pkg->new('others', '1')->fix({others => 'human'}), {others => 0},
    "replace existing value";

is_deeply $pkg->new('animals[].$append', '1')
    ->fix({animals => ['dog', 'cat']}),
    {animals => ['dog', 'cat'], 'animals[]' => [0]}, "append to marked array";

is_deeply $pkg->new('bnimals[].$append.number', '1')->fix({}),
    {'bnimals[]' => [{number => 0}]}, "append object to marked array";

is_deeply $pkg->new('animals.$append', '1')->fix({animals => ['dog', 'cat']}),
    {animals => ['dog', 'cat', 0]}, "append to array";

done_testing;
