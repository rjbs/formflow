package Formflow::PageBinding;

use strict;
use warnings;

use Sub::Install ();
use base qw(Class::Accessor::Chained);

=head1 NAME

Formflow::PageBinding

=head1 DESCRIPTION

This class exists to represent a single run through a Formflow object's display
or submit cycle.

It binds together a Formflow::Page, its containing Formflow object, and the
input/session/flash.

You should never have to make one of these objects directly.

=cut

sub __make_delegations {
  my $class = shift;
  for my $method (@_) {
    Sub::Install::install_sub({
      into => $class,
      as   => $method,
      code => sub {
        my $self = shift;
        $self->page->$method($self->arg)
      },
    });
  }
}

sub __make_simple_delegations {
  my $class = shift;
  for my $method (@_) {
    Sub::Install::install_sub({
      into => $class,
      as   => $method,
      code => sub { shift->page->$method(@_) },
    });
  }
}

BEGIN {
  __PACKAGE__->__make_delegations(
    qw(display action validate next_id prev_id)
  );
}

BEGIN {
  __PACKAGE__->__make_simple_delegations(
    qw(name),
  );
}

BEGIN {
  __PACKAGE__->mk_accessors(
    qw(form page arg)
  );
}

1;
