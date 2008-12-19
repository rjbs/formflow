#!perl

use strict;
use warnings;

my $CLASS = 'Formflow';
my $PAGECLASS = "$CLASS\::Page";
use lib 't/lib';
use Test::Formflow;

use Test::More 'no_plan';

my $form = Test::Formflow->form;

$form->submit({
  input   => { baz => 1 },
  session => {},
  flash   => {},
});

is(
  Test::Formflow->done,
  1,
  "form is done",
);

# TODO:
#   test individual steps' submissions when there's no form_page
#   test validation
#
# TODO: (docs)
#   linear => 0|1 to ->new to handle the simple case (step1..N)

my @DISPLAY;
my @ACTION;
sub display { my $d = shift; sub { push @DISPLAY, $d } }
sub action  { my $d = shift; sub { push @ACTION,  $d } }

sub _page {
  my $name = shift;
  $PAGECLASS->new({
    name => $name,
    display => display($name),
    action  => action($name),
    @_
  });
}

$form = $CLASS->new({
  pages => [
    _page(
      'step1',
      next_id => sub {
        my ($self, $arg) = @_;
        ($arg->{input}->{color} || "") eq "red"
          ? 'step2.1' : 'step2.2';
      },
    ),
    _page(
      'step2.1',
      next_id => 'step3',
    ),
    _page(
      'step2.2',
    ),
    _page(
      'step3',
    ),
  ],
  redirect => sub { push @ACTION, "redirect" },
});

sub is_action {
  my ($form, $arg, $expected, $comment) = @_;
  # fill in defaults for testing
  $arg->{$_} ||= {} for qw(input session flash);
  @ACTION = ();
  $form->submit($arg);
  is_deeply(
    \@ACTION,
    $expected,
    $comment,
  );
}

is_action(
  $form, {}, [qw(step1 step2.2 step3 redirect)],
  "no input -- default path",
);

is_action(
  $form, { input => { color => "blue" } },
  [qw(step1 step2.2 step3 redirect)],
  "boring input -- default path",
);

is_action(
  $form, { input => { color => "red" } },
  [qw(step1 step2.1 step3 redirect)],
  "special input -- alternate path",
);
  
