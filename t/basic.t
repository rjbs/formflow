#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use Test::Formflow;

sub is_last {
  my ($arg, $last, $comment) = @_;
  $arg->{$_} ||= {} for qw(input session flash);
  my $form = Test::Formflow->form;
  $form->display($arg);
  is(Test::Formflow->last_displayed, $last, "$comment => $last");
}

is_last({}, 'basics', 'no input/state/flash');

# Here we assert that you can't just demand to see page two if you haven't
# bothered building up a session.  Honestly, some people! -- rjbs, 2006-08-21
is_last(
  { input => { form_page => 2 } },
  'basics',
  "only form_page input",
);

for my $p (qw(2 details)) {
  is_last(
    {
      input   => { form_page => $p        },
      session => { bogus     => 'totally' },
    },
    'details',
    "form_page input and session",
  );
}

is_last(
  { session => { foo => 1 } },
  'basics',
  "session and nothing else",
);
