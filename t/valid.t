#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use Formflow;

my @DISPLAY;

my $form = Formflow->new({
  pages => [
    Formflow::Page->new({
      name => 'step1',
      display => sub { push @DISPLAY, [ step1 => pop ] },
      dfv_profile => { required => [qw(foo bar)], optional => [qw(baz)] },
    }),
    Formflow::Page->new({
      name => 'step2',
      display => sub { push @DISPLAY, [ step2 => pop ] },
      dfv_profile => { required => [qw(quux)] },
    }),
  ],
  redirect => sub { shift->display(shift) },
});

$form->submit({
  input   => { foo => 1 },
  session => my $session = {},
  flash   => my $flash   = {},
});

is_deeply(
  [ keys %{ $flash->{error} } ],
  [ qw(bar) ],
  "complain about missing fields",
);

is $session->{form_page}, 'step1',
  "did not advance beyond step1 with failed validation";

is_deeply(
  $session->{valid},
  { foo => 1 },
  "stored valid values even with some missing",
);

$form->submit({
  input   => { %{ $session->{valid} }, bar => 2, baz => 3 },
  session => $session,
  flash   => $flash,
});

is $session->{form_page}, '2',
  "advanced (validation passed)";

is_deeply(
  $flash,
  { error => {} },
  "nothing in flash",
);

is_deeply(
  $session->{valid},
  { foo => 1, bar => 2, baz => 3 },
  "accumulated state",
);
