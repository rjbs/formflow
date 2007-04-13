#!perl

use strict;
use warnings;

package Test::Formflow;
use base qw(Class::Accessor::Class);

my $CLASS; BEGIN { $CLASS = 'Formflow' }
BEGIN { eval "use $CLASS; 1" or die $@; };

my @pages;

__PACKAGE__->mk_class_accessors(qw(
  last_displayed
  done
  last_redirect
));

my $last_actions;
sub last_actions {
  my $self = shift;

  return $last_actions unless @_;

  my $value = shift;
  
  return (undef $last_actions) if not defined $value;

  $last_actions ||= [];
  push @$last_actions, $value;
  return $last_actions;
}

__PACKAGE__->done(0);

sub display { my $d = shift; sub { __PACKAGE__->last_displayed($d) } }

push @pages, Formflow::Page->new({
  name        => 'basics',
  display     => display('basics'),
  dfv_profile => { }, # D::FV profile? (this should be customizable)
  action      => sub { __PACKAGE__->last_actions('basics') },
});

push @pages, Formflow::Page->new({
  name        => 'details',
  display     => display('details'),
  dfv_profile => { }, # D::FV profile? (this should be customizable)
  action      => sub { __PACKAGE__->last_actions('details') },
});

push @pages, Formflow::Page->new({
  name        => 'preview',
  display     => display('preview'),
  dfv_profile => { required => [ qw(baz) ] },
  action      => sub { __PACKAGE__->last_actions('preview') },
});

push @pages, Formflow::Page->new({
  name        => 'success',
  display     => display('success'),
  dfv_profile => {}, # D::FV profile? (this should be customizable)
  action      => sub { __PACKAGE__->done( __PACKAGE__->done + 1 ) },
});

sub form {
  my $class = shift;
  my $arg   = shift || {};
  return $CLASS->new({
    pages    => \@pages, # the pages we can display
    redirect => sub { __PACKAGE__->last_redirect([ @_ ]) },
    %$arg,
  });
}

1;
