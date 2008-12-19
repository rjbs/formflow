#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use Test::Formflow;

my $form = Test::Formflow->form;

$form->submit({
  session => { foo => '2' },
  flash   => { },
  input   => { form_page => 'details' },
});

is_deeply(
  Test::Formflow->last_actions,
  [ 'details' ],
  "action occurred after last page",
);

Test::Formflow->last_actions(undef);

# try to prove the "work way through all possible pages" submit logic
$form->submit({
  session => { foo => '2' },
  flash   => { },
  input   => { },
});

is_deeply(
  Test::Formflow->last_actions,
  [ qw(basics details) ],
  "all actions occurred on way to last page",
);

ok(! Test::Formflow->done,"and we're not done");

my $session = {};
my $result;
$form->page('success')->page->{action} = sub {
  my ($self, $arg) = @_;
  $result = { %{ $arg->{session} } };
};

$form->submit({
  session => $session,
  flash   => {},
  input   => my $input = { baz => 1 },
});

is_deeply(
  $result,
  { 
    valid => { baz => 1 },
  },
  "input stored to session",
);

is_deeply(
  $session,
  {},
  "session emptied",
);
