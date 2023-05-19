#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::exists';
    use_ok $pkg;
}

my $cond = $pkg->new('foo');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $cond->fix({foo => undef}), {foo => undef, test => 'pass'};

is_deeply $cond->fix({}), {test => 'fail'};

my $nested = $pkg->new('foo.bar');
$nested->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$nested->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $nested->fix({foo => {bar => undef}}),
    {foo => {bar => undef}, test => 'pass'};

is_deeply $nested->fix({foo => undef}), {foo  => undef, test => 'fail'};
is_deeply $nested->fix({}),             {test => 'fail'};

is_deeply $nested->fix({foo => {}}), {foo => {}, test => 'fail'};
is_deeply $nested->fix({foo => [{bar => undef}]}),
    {foo => [{bar => undef}], test => 'fail'};
is_deeply $nested->fix({foo => {baz => undef}}),
    {foo => {baz => undef}, test => 'fail'};

my $asterisk = $pkg->new('foo.*.bar');
$asterisk->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$asterisk->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $asterisk->fix({foo => [{bar => undef}]}),
    {foo => [{bar => undef}], test => 'pass'};

is_deeply $asterisk->fix({foo => undef}), {foo  => undef, test => 'fail'};
is_deeply $asterisk->fix({}),             {test => 'fail'};

is_deeply $asterisk->fix({foo => {}}), {foo => {}, test => 'fail'};
is_deeply $asterisk->fix({foo => {bar => undef}}),
    {foo => {bar => undef}, test => 'fail'};
is_deeply $asterisk->fix({foo => [{baz => undef}]}),
    {foo => [{baz => undef}], test => 'fail'};

done_testing 15;
