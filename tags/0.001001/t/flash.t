#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use lib 't/lib';
use Test::Formflow;

my $form = Test::Formflow->form;

my $arg = {
  input   => {},
  session => {},
  flash   => {},
};

$form->display($arg);

is(
  Test::Formflow->last_displayed,
  "basics",
  "displayed first page",
);

$form->page(1)->{action} = sub {
  my ($self, $arg) = @_;
  $arg->{flash}->{color} = $arg->{input}->{color};
};

$arg->{flash}->{error} = { foo => "A foo error" };
$arg->{input}->{form_page} = 1;
$arg->{input}->{color} = "purple";

$form->submit($arg);

is_deeply(
  $arg->{flash},
  { error => {}, color => "purple" },
  "flash was cleared and stored into",
);

$arg->{input} = {};

$form->page(2)->{display} = sub {
  my ($self, $arg) = @_;
  Test::Formflow->last_displayed($arg->{flash}->{color});
};
$form->display($arg);

is(
  Test::Formflow->last_displayed,
  $arg->{flash}->{color},
  "flash present in display and correct form_page chosen from session",
);
