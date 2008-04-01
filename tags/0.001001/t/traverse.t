#!perl

use strict;
use warnings;

use Test::More 'no_plan';

use Formflow;

sub _page {
  my $name = shift;
  return Formflow::Page->new({
    name => $name,
    display => sub { },
    @_,
  });
}

my $form = Formflow->new({
  pages => [
    _page('start'),
    _page('mid1'),
    _page('mid2',
      next_id => sub { 
        ('mid3', 'mid2-extra')[($_[1]->{session}->{type} || "") eq "extra"]
      },
    ),
    _page('mid2-extra'),
    _page('mid3',
      prev_id => sub {
        ('mid2', 'mid2-extra')[($_[1]->{session}->{type} || "") eq "extra"]
      },
    ),
    _page('mid4'),
    _page('stop'),
  ],
  redirect => sub { },
});

sub is_visited {
  my ($start, $method, $arg, $expect, $comment) = @_;
  my @VISIT;
  my $page = $form->page($start)->arg($arg);

  $arg->{$_} ||= {} for qw(input session flash);

  if ($method eq 'next_id') {
    is_deeply(
      [ map { $_->name } $form->dispatch_path($arg) ],
      [ $start, @$expect ],
      "dispatch_path: $comment",
    );
  }

  while (my $id = $page->$method) {
    my $next = $form->page($id)->arg($arg);
    push @VISIT, $next->name;
    $page = $next;
  }

  is_deeply(
    \@VISIT,
    $expect,
    "actual path: $comment",
  );
}

is_visited(
  'start',
  'next_id',
  {},
  [qw(mid1 mid2 mid3 mid4 stop)],
  "start to stop, default path"
);

is_visited(
  'start',
  'next_id',
  { session => { type => 'extra' } },
  [qw(mid1 mid2 mid2-extra mid3 mid4 stop)],
  "start to stop, extra path",
);

is_visited(
  'stop',
  'prev_id',
  {},
  [qw(mid4 mid3 mid2 mid1 start)],
  "stop to start, default path",
);

is_visited(
  'stop',
  'prev_id',
  { session => { type => 'extra' } },
  [qw(mid4 mid3 mid2-extra mid2 mid1 start)],
  "stop to start, default path",
);
