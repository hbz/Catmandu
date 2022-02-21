#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::set_array';
    use_ok $pkg;
}

is_deeply $pkg->new('job')->fix({}), {job => []}, "set array at root";

is_deeply $pkg->new('deeply.nested.$append.job')->fix({}), {},
    "set array doesn't create intermediate path";

is_deeply $pkg->new('deeply.nested.*.job')
    ->fix({deeply => {nested => [undef, {}]}}),
    {deeply => {nested => [undef, {job => []}]}}, "set deeply nested array";

is_deeply $pkg->new('deeply.nested.$append.job')
    ->fix({deeply => {nested => {}}}), {deeply => {nested => {}}},
    "only set array if the path matches";

is_deeply $pkg->new('job', 1, "foo", 2)->fix({}), {job => [1, "foo", 2]},
    "set array with initial contents";

is_deeply $pkg->new('job')->fix({job => "foo"}), {job => []},
    "set array with existing string";

is_deeply $pkg->new('job')->fix({job => {}}), {job => []},
    "set array with existing hash";

is_deeply $pkg->new('job')->fix({job => [1, "foo", 2]}), {job => []},
    "set array with existing array";

done_testing 9;
