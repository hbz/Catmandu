package Catmandu::Importer::Aleph;

use 5.010;

use Moose;
use Data::Dumper;
use File::Slurp qw(slurp);
use List::MoreUtils qw(natatime);

no strict "subs";

with 'Catmandu::Importer';

has map => (
    traits => ['Getopt'],
    is => 'ro',
    isa => IO,
    coerce => 1,
    documentation => "Path to the MARC mapping definition file to use.",
);

has inline_map => (
    is => 'ro',
    isa => 'ArrayRef',
    documentation => "Inline definition of MARC mapping definition.",
);

sub each {
   my ($self, $callback) = @_;
   my $num = 0;

   my $fh  = $self->file;

   my $rec     = {};

   my $prev_id = undef;

   binmode $fh, ':utf8';

   my $mapper  = $self->mapper( $self->inline_map || $self->file_map );

   while(<$fh>) {
     chomp;
     my ($sysid,@data)  = &parse_line($_);
 
     if (defined $prev_id && $prev_id != $sysid) {
        if (defined $callback) {
            $callback->( $mapper->($rec) ); 
        }

        $num++;

        $rec = {};
     }

     $rec->{id} = $sysid;
     push @{$rec->{data}}, [@data];

     $prev_id = $sysid;
   }

   if (defined $callback) {
      $callback->( $mapper->($rec) ); 
   }

   $num++;

   return $num;
}

# Load a mapping file to map MARC fields to stored fields
# E.g. the input can be
#
#  245       title
#  540+a     rights
#  852+j     relation
#  100+ac    author
#  260-x     publisher
#
sub file_map {
    my $self = shift;

    return undef unless $self->map;

    my $map = [];

    foreach my $line (split /\n/, slurp($self->map)) {
        next if ($line =~ /^\s*#/);
        next if ($line =~ /^\s*$/);

        my ($path, $key) = split /\s+/, $line;
        push (@$map , $path => $key );
    }

    $map;
}

# Compile a mapping array into a translator for MARC records
#
# Usage:
#      
#   my $mapper = $self->mapper([ '024' => 'info' , '245' => 'title']);
#   my $hash   = $mapper->($rec);
#
sub mapper {
    my ($self,$map) = @_;
    $map = [] unless $map;

    my $dc = {};
   
    my $eval =<<EOF;
sub {
   my \$rec = shift;

   my \$dc = {};

EOF

    while (@$map) {
        my ($key,$value) = splice(@$map, 0, 2);

        if ($key =~ /^([A-Z0-9*]{3})(\+([a-z0-9]+))?(\-([a-z0-9]+))?/) {
            my $field    = $1; $field =~ s/\*/./g;
            my $includes = $3 ? join '|' , split (// , $3) : undef;
            my $excludes = $5 ? join '|' , split (// , $5) : undef;

            my $inc_code = $includes ?  ", includes => '$includes'" : "";
            my $exc_code = $excludes ?  ", excludes => '$excludes'" : "";

            $eval .= "   push(\@{\$dc->{$value}} , \&field(\$rec, '$field' $inc_code $exc_code));\n";
        }
        else {
            warn "syntax error in map '$key' -> '$value'";
        }
    }

    $eval .=<<EOF;

    \&clean_empty(\$dc);
}
EOF

   my $sub = eval $eval;

   die "$@\n$eval" if ($@);

   $sub;
}

sub clean_empty {
    my $rec = shift;
    my $out = { _id => $rec->{_id}->[0] };

    foreach my $key (keys %$rec) {
        next if $key eq '_id';

        my $val = $rec->{$key};

        $out->{$key} = $val if defined $val && @$val > 0; 
    }

    $out;
}


sub field {
    my ($rec,$field, %opts) = @_;

    my @fields = grep { $_->[0] =~ /$field/ } @{$rec->{data}};

    my @out = ();

    foreach (@fields) {
        my $len    = @$_;
        my @data   = @$_[4 .. $len -1 ];
        my @values = ();

        my $it = natatime 2, @data;

        INNER: while (my @v = $it->() ) {
            next INNER if defined $opts{includes} && $v[0] !~ /$opts{includes}/;
            next INNER if defined $opts{excludes} && $v[0] =~ /$opts{excludes}/;

            push (@values, $v[1]);
        }

        my $str = join(" ",@values);
        $str =~ s/(^\s+|\s+$)//;

        push @out , $str;
    }

    @out; 
}

# Parse ALEPH sequential lines into Perl arrays
#
# [ '0123456789' , '001' , ' ' , ' ' , 'L' , '_' , '0123456789' ]
# [ '0123456789' , '100' , ' ' , ' ' , 'L' , 'a' , 'Mijn konijn' ]
sub parse_line {
    my ($line) = @_;
    my $sysid = substr($line,0,9);
    my $tag   = substr($line,10,3);
    my $ind1  = substr($line,13,1);
    my $ind2  = substr($line,14,1);
    my $char  = substr($line,16,1);
    my $data  = substr($line,18);

    my @parts = ('_' , split(/\$\$(.)/, $data) );

    ( $sysid , $tag , $ind1 , $ind2 , $char , @parts );
}

__PACKAGE__->meta->make_immutable;
no Moose;
__PACKAGE__;

=head1 SYNOPSIS

    use Catmandu::Importer::Aleph;

    my $importer = Catmandu::Importer::Aleph(file => 'import.marc' , map => 'aleph.map');

    or 

    my $importer = Catmandu::Importer::Aleph(file => 'import.marc' , inline_map => [
            '001'       => '_id' ,
            '245'       => 'title' ,
            '852+j'     => 'relation' ,
            '700-x'     => 'author' ,
            '5**'       => 'notes' ,
    ]);

    $importer->each(sub {
        my $obj = shift;

        ...
    });

    or via the command line

    catmandu convert -I Aleph -i map=data/aleph.map -o pretty=1 import.txt

    catmandu import  -I Aleph -i map=data/aleph.map -o path=data/aleph.db import.txt

=head1 METHODS

=head2 $c->new(file => $file , map => $map_file , inline_map => [])

Creates a new Catmandu::Importer for parsing MARC sequential data from $file into
Perl hashes. The contents of the Perl hash is defined by the $map_file which has
a contents like:

   245      title
   852+j    relation
   700-x    author

Which states that the '245' field should be extracted into a 'title' key. The
'852' only the 'j' subfield should be extracted into the 'relation' key. And the
'700' field without the 'x' subfield should be in the author field.

Mapping syntax:
    
    <map>      ::= { <line> }
    <line>     ::= <selector> ' '+ <field> '\n'
    <selector> ::= <f-sel> <f-sel> <f-sel> ['+' <s-sel>+] ['-' <s-sel>+]
    <field>    ::= <letter> { <letter> | <digit> }
    <f-sel>    ::= <digit> | <upper> | '*'
    <s-sel>    ::= <digit> | <lower>
    <letter>   ::= <upper> | <lower>
    <digit>    ::= '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9'
    <upper>    ::= 'A' | 'B' | 'C' | 'D' | 'E' | 'F' | 'G' | 'H' | 'I' | 'J' |
                   'K' | 'L' | 'M' | 'N' | 'O' | 'P' | 'Q' | 'R' | 'S' | 'T' |
                   'U' | 'V' | 'W' | 'X' | 'Y' | 'Z'
    <lower>    ::= 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'g' | 'h' | 'i' | 'j' |
                   'k' | 'l' | 'm' | 'n' | 'o' | 'p' | 'q' | 'r' | 's' | 't' |
                   'u' | 'v' | 'w' | 'x' | 'y' | 'z'

=head2 $c->each($callback)

Execute $callback for every record imported. The callback functions get as 
first argument the parsed object (a ref hash of key => [ values ]).

=head1 SEE ALSO

L<Catmandu::Importer>
