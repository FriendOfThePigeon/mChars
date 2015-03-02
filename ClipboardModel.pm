#!/usr/bin/perl
package ClipboardModel;
use strict;

use Object;
use EventSource;
use ArrayIterator;

our @ISA = qw( EventSource );

sub new {
	my ($class, $cfg) = @_;
	my $self = $class->basic_new();
	$self->{_entries} = [];
	$self->initialize($cfg);
	$self->{_cmp} = sub {
		my ($a, $b) = @_;
		return $a eq $b;
	};
	return $self;
}

sub initialize {
	my ($self, $cfg) = @_;
	return $self;
}

sub add {
	my ($self, $entry) = @_;
	my $new = [];
	for my $a (@{ $self->{_entries} }) {
		next if ($self->{_cmp}->($entry, $a));
		push @$new, $a;
	}
	push @$new, $entry;
	$self->{_entries} = $new;
	$self->activate('contents', $self->{_entries});
}

sub clear {
	my ($self) = @_;
	$self->{_entries} = [];
	$self->activate('contents', $self->{_entries});
}

sub get_contents {
	my ($self) = @_;
	return $self->{_entries};
}

1;

