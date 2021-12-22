#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix;
use Catmandu::Importer::Mock;
use Catmandu::Util qw(:is);

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Bind::list';
    use_ok $pkg;
}
require_ok $pkg;

my $fixes = <<EOF;
do list()
  add_field(foo,bar)
end
EOF

my $fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok $fixer , 'create fixer';

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing add_field';

$fixes = <<EOF;
do list()
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'},
    'testing zero fix functions';

$fixes = <<EOF;
do list()
  unless exists(foo)
  	add_field(foo,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}), {foo => 'bar'}, 'testing unless';

$fixes = <<EOF;
do list()
  if exists(foo)
  	add_field(foo2,bar)
  end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar', foo2 => 'bar'},
    'testing if';

$fixes = <<EOF;
do list()
  reject exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

ok !defined $fixer->fix({foo => 'bar'}), 'testing reject';

$fixes = <<EOF;
do list()
  select exists(foo)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'testing select';

$fixes = <<EOF;
do list()
 do list()
  do list()
   add_field(foo,bar)
  end
 end
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}), {foo => 'bar'}, 'before/after testing';

$fixes = <<EOF;
add_field(before,ok)
do list()
   add_field(inside,ok)
end
add_field(after,ok)
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => 'bar'}),
    {foo => 'bar', before => 'ok', inside => 'ok', after => 'ok'},
    'before/after testing';

$fixes = <<EOF;
do list(path => foo)
  add_field(test,bar)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => [{bar => 1}, {bar => 2}]}),
    {foo => [{bar => 1, test => 'bar'}, {bar => 2, test => 'bar'}]},
    'specific testing';

$fixes = <<EOF;
add_field(foo.\$append,1)
add_field(foo.\$append,2)
add_field(foo.\$append,3)
add_field(foo.\$append,4)

do list(path:foo,var:loop) 
 copy_field(loop,test2.\$append)
end

do list(path:foo) 
 append(.,':')
end

EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({}),
    {foo => ["1:", "2:", "3:", "4:"], test2 => [1, 2, 3, 4]},
    'specific testing, loop variable';

$fixes = <<EOF;
do list(path:foo,var:loop)
  copy_field(test,loop.baz)
  copy_field(loop.bar,loop.qux)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => [{bar => 1}, {bar => 2}], test => 42}),
    {foo => [{bar => 1, baz => 42, qux => 1}, {bar => 2, baz => 42, qux => 2}], test => 42},
    'binding scope w/ var testing';

$fixes = <<EOF;
do list(path:foo)
  copy_field(test,baz)
  copy_field(bar,qux)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => [{bar => 1}, {bar => 2}], test => 42}),
    {foo => [{bar => 1, qux => 1}, {bar => 2, qux => 2}], test => 42},
    'binding scope w/o var testing';

$fixes = <<EOF;
do list(path:foo.*.bar)
  add_field(test,bar)
end
EOF

$fixer = Catmandu::Fix->new(fixes => [$fixes]);

is_deeply $fixer->fix({foo => [{bar => {baz => 1}}, {bar => {baz => 2}}]}),
    {foo => [{bar => {baz => 1}}, {bar => {baz => 2}}]},
    'array path testing';

done_testing 16;
