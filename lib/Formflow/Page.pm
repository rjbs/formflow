package Formflow::Page;

use strict;
use warnings;

use Carp ();
use Data::FormValidator;
use Params::Util qw(_CODELIKE);
use Sub::Install ();

use Formflow::Util ();
use Formflow::PageBinding;

sub new {
  my ($class, $arg) = @_;

  # XXX defaulting to empty; is this right? -- hdp, 2006-08-22
  $arg->{dfv_profile} ||= {};
  
  bless $arg => $class;
}

sub _method_or_constant {
  my $self = shift;
  my $name = shift;

  if (_CODELIKE($self->{$name})) {
    return $self->{$name}->($self, @_);
  }
  return $self->{$name};
}

sub _method {
  my $self = shift;
  my $name = shift;

  return unless exists $self->{$name};
  Carp::croak "'$name' must be a coderef" unless _CODELIKE($self->{$name});
  return $self->_method_or_constant($name, @_);
}

sub name {
  return $_[0]->{name};
}

sub display { shift->_method(display => @_) }

sub validate {
  my $self = shift;
  my $arg  = Formflow::Util::_INPUT(shift);

  my $result = Data::FormValidator->check(
    $arg->{input},
    $self->dfv_profile($arg),
  );

  for my $valid ($result->valid) {
    $arg->{session}{valid}{$valid} = $result->valid($valid);
  }

  $arg->{flash}{error} = $result->msgs;

  return not $result->has_invalid || $result->has_missing;
}

sub action { shift->_method(action => @_) }

sub next_id { shift->_method_or_constant(next_id => @_) }

sub prev_id { shift->_method_or_constant(prev_id => @_) }

sub dfv_profile { shift->_method_or_constant(dfv_profile => @_) }

sub __make_bindings {
  my $class = shift;
  for my $method (@_) {
    Sub::Install::install_sub({
      into => $class,
      as   => $method,
      code => sub {
        my $self = shift;
        # assert $_[0]
        return Formflow::PageBinding->new({
          page    => $self,
          $method => shift,
        });
      },
    });
  }
}

BEGIN { __PACKAGE__->__make_bindings(qw(form arg)) }

1;
