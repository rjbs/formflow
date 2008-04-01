package Formflow;
use strict;
use warnings;

use Carp ();
use Formflow::Page;
use Params::Util ();
use Formflow::Util ();

=head1 NAME

Formflow - skeleton for multipage web forms

=head1 VERSION

  Version 0.001001

=cut

our $VERSION = '0.001001';

=head1 DESCRIPTION

=head1 METHODS

define 'standard argument'

=cut

sub new {
  my ($class, $arg) = @_;

  # assert pages
  $arg->{form_page} ||= 'form_page';

  $arg->{linear} = 1 unless exists $arg->{linear};

  my $self = bless $arg => $class;

  for my $id (1..@{ $self->{pages} }) {
    my $page = $self->page($id);

    # XXX breaking encapsulation
    for my $id_field (qw(prev_id next_id)) {
      next if exists $page->{$id_field};
      Carp::croak "page $id has no $id_field" unless $arg->{linear};
    }
    $page->{next_id} ||= $id + 1 unless $id == @{ $self->{pages} };
    $page->{prev_id} ||= $id - 1 unless $id == 1;
  }

  return $self;
}

sub display {
  my $self = shift;
  my $arg  = Formflow::Util::_INPUT(shift);

  # Maybe later we should be more specific about what parts of $arg we pass.
  my $page;
  if (keys %{ $arg->{session} }) {
    $page = $self->__given_form_page($arg)
  }

  # default to page 1 if there was no session or it didn't specify a form_page
  $page ||= $self->page(1)->arg($arg);

  return $page->display;
}

sub __given_form_page {
  my ($self, $arg) = @_;

  my $id = $arg->{ input }{ $self->{form_page} }
        || $arg->{session}{ $self->{form_page} };

  return unless $id;
  return $self->page($id)->arg($arg);
}

sub submit {
  my $self = shift;
  my $arg  = Formflow::Util::_INPUT(shift);

  %{ $arg->{flash} } = ();

  my $page;

  # eventually stored in the session; means "what form page is next" -- hdp,
  # 2006-08-23
  my $form_page;

  if ($page = $self->__given_form_page($arg)) {
    # single page requested; run it
    if ($page->validate) {
      $page->action;
      $form_page = $page->next_id;
    } else {
      $form_page = $page->name;
    }
  } else {
    # no single page requested; run all that have data
    # XXX this may re-run pages that didn't get new input -- hdp, 2006-08-22
    %{ $arg->{session} } = ();

    $page = $self->page(1)->arg($arg);
    while (1) {
      unless ($page->validate) {
        $form_page = $page->name;
        last;
      }

      $page->action;
      # we don't need to set $form_page here because if there's no next_id,
      # form_page will be undef anyway
      last unless my $next_id = $page->next_id;
      $page = $self->page($next_id)->arg($arg);
    }
  }

  if ($form_page) {
    $arg->{session}{form_page} = $form_page;
  } else {
    # if there's no next_id, we assume we're done and clear the session
    %{ $arg->{session} } = ();
  }

  $self->redirect($arg);
}

sub redirect {
  my ($self, $arg) = @_;
  # assert ... ?
  # perform redirection
  $self->{redirect}->($self, $arg);
}

=head2 page

  my $page       = $form->page(1);
  my $bound_page = $form->page('hello');

Given a numerical page id, returns the given page object (unbound).

Given a page name, returns an object for the named page bound to the containing
form.

=cut

sub page {
  my ($self, $id) = @_;

  my $pages = $self->{pages};

  if ($id =~ /\A\d+\z/) {
    Carp::croak "invalid page number: $id" unless $id and $id <= @$pages;
    return $pages->[$id - 1];
  }

  my @found = grep { $_->name eq $id } @$pages;

  # Probably check for this at setup instead -- rjbs, 2006-08-21
  Carp::croak "multiple pages with same name: $id" if @found > 1;
  Carp::croak "no page with given name: $id" if @found < 1;

  return $found[0]->form($self);
}

=head2 dispatch_path

  my @pages = $form->dispatch_path($arg);

Given a standard argument, return the list of pages that would be displayed, in
order.

Returns pages bound to the form and argument.

=cut

sub dispatch_path {
  my $self = shift;
  my $arg  = Formflow::Util::_INPUT(shift);
  my @pages = $self->page(1)->form($self)->arg($arg);
  
  while (my $next_id = $pages[-1]->next_id) {
    push @pages, $self->page($next_id)->form($self)->arg($arg);
  }

  return @pages;
}

1;
