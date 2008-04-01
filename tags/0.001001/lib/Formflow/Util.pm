package Formflow::Util;

use strict;
use warnings;

use Sub::Exporter -setup => {
  exports => [qw(_INPUT)],
};

use Params::Util ();
use Carp ();

sub _INPUT {
  my $arg  = Params::Util::_HASH0(shift || {})
    or Carp::croak("argument to _INPUT must be hashref");

  my $result = {};

  $arg->{input} ||= {};

  # input from http request
  $result->{input} = Params::Util::_HASH0($arg->{input})
    or Carp::croak("optional 'input' argument must be hashref");

  # long-term state
  $result->{session} = Params::Util::_HASH0($arg->{session})
    or Carp::croak("mandatory 'session' argument must be hashref");

  # ephemeral state
  $result->{flash} = Params::Util::_HASH0($arg->{flash})
    or Carp::croak("mandatory 'flash' argument must be hashref");

  Carp::croak "unrecognized arguments: " . join(" ", keys %$arg)
    if (grep { !$result->{$_} } keys %$arg);

  return $result;
}

1;
