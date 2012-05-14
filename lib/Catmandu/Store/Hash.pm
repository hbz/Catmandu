package Catmandu::Store::Hash;

use Catmandu::Sane;
use Moo;

with 'Catmandu::Store';

package Catmandu::Store::Hash::Bag;

use Catmandu::Sane;
use Catmandu::Hits;
use Moo;
use Clone qw(clone);

with 'Catmandu::Bag';
with 'Catmandu::Searchable';

has _hash => (is => 'rw', init_arg => undef, default => sub { +{} });
has _head => (is => 'rw', init_arg => undef, clearer => '_clear_head');
has _tail => (is => 'rw', init_arg => undef, clearer => '_clear_tail');

sub generator {
    my $self = $_[0];
    sub {
        state $node = $self->_head;
        state $data;
        $node || return;
        $data = $node->[1];
        $node = $node->[2];
        $data;
    };
}

sub get {
    my ($self, $id) = @_;
    my $node = $self->_hash->{$id} || return;
    clone($node->[1]);
}

sub add {
    my ($self, $data) = @_;
    my $id = $data->{_id};
    my $node = $self->_hash->{$id};
    if ($node) {
        $node->[1] = clone($data);
    } elsif (my $tail = $self->_tail) {
        $tail->[2] = $node = [$tail, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_tail($node);
    } else {
        $node = [undef, clone($data), undef];
        $self->_hash->{$id} = $node;
        $self->_head($node);
        $self->_tail($node);
    }
    $data;
}

sub delete {
    my ($self, $id) = @_;
    my $node = $self->_hash->{$id} || return;
    if ($node->[0]) {
        $node->[0][2] = $node->[2];
    } else {
        $self->_head($node->[2]);
    }
    if ($node->[2]) {
        $node->[2][0] = $node->[0];
    } else {
        $self->_tail($node->[0]);
    }
    delete $self->_hash->{$id};
}

sub delete_all {
    $_[0]->_clear_head;
    $_[0]->_clear_tail;
    $_[0]->_hash({});
}

sub translate_sru_sortkeys {
    confess "TODO";
}

sub translate_cql_query {
    confess "TODO";
}

sub search {
    my ($self, %args) = @_;
    my $query = $args{query};

    my @candidates = ();

    use Data::Visitor::Callback;
    my $match = 0;
    my $visitor = Data::Visitor::Callback->new(
        value => sub { $match = 1 if $_[1] =~ /$query/},
    );

    $self->each(sub {
        my $item = shift;
        $visitor->visit($item);
        push(@candidates,$item) if $match;
        $match = 0;
    });

    Catmandu::Hits->new({
        limit => undef,
        start => 0,
        total => int(@candidates),
        hits  => \@candidates,
    });
}

sub searcher {
    return $_[0];
}

sub delete_by_query {
    my $self = shift;
    my $hits = $self->search(@_);

    $hits->each(sub {
        my $item = shift;
        $self->delete($item->{_id});
    });
}

1;

=head1 NAME

Catmandu::Store::Hash - A Catmandu::Store plugin for in memory HASH-es

=head1 SYNOPSIS

   use Catmandu::Store::Hash;

   my $store = Catmandu::Store::Hash->new();

   my $obj1 = $store->bag->add({ name => 'Patrick' });

   printf "obj1 stored as %s\n" , $obj1->{_id};

   # Force an id in the store
   my $obj2 = $store->bag->add({ _id => 'test123' , name => 'Nicolas' });

   my $obj3 = $store->bag->get('test123');

   $store->bag->delete('test123');

   $store->bag->delete_all;

   # All bags are iterators
   $store->bag->each(sub { ... });
   $store->bag->take(10)->each(sub { ... });

=head1 DESCRIPTION

A Catmandu::Store::Hash is a Perl package that can store data into memory hashes.

=head1 METHODS

=head2 new()

Create a new Catmandu::Store::Hash 

=head2 bag($name)

Create or retieve a bag with name $name. Returns a Catmandu::Bag.

=head1 SEE ALSO

L<Catmandu::Bag>, L<Catmandu::Searchable>

=cut
