#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::rename';
    use_ok $pkg;
}

is_deeply $pkg->new('dots', '\.', '-')
    ->fix({dots => {'a.b' => [{'c.d' => ""}]}}),
    {dots => {'a-b' => [{'c-d' => ""}]}};

is_deeply $pkg->new('others', 'ani', 'QR')
    ->fix({others => {animal => 'human', canister => 'metall', area => {ani => 'test'}}}),
    {others => {QRmal => 'human', cQRster => 'metall', area => {QR => 'test'}}};

is_deeply $pkg->new('animals', 'ani', 'XY')
    ->fix({animals => [{animal => 'dog'}, {animal => 'cat'}]}),
    {animals => [{XYmal => 'dog'}, {XYmal => 'cat'}]};

is_deeply $pkg->new('.', 'ani', 'XY')
    ->fix({animals => [{animal => 'dog'}, {animal => 'cat'}], others => {animal => 'human', canister => 'metall', area => {ani => 'test'}}, fictional => {animal => 'unicorn'}}),
    {XYmals => [{XYmal => 'dog'}, {XYmal => 'cat'}], others => {XYmal => 'human', cXYster => 'metall', area => {XY => 'test'}}, fictional => {XYmal => 'unicorn'}};

done_testing;
