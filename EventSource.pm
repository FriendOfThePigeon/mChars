#!/usr/bin/perl
package EventSource;
use strict;

use Object;

our @ISA = qw( Object );

sub initialize {
	my ($self) = @_;
	$self->SUPER::initialize();
	$self->{_listeners} = [];
}

sub add_listener {
	my ($self, $listener) = @_;
	push @{ $self->{_listeners} }, $listener;
	return $self;
}

sub remove_listener {
	my ($self, $listener) = @_;
	for (my $i = 0; $i <= $#{$self->{_listeners}}; $i++) {
		if ($self->{_listeners}->[$i] == $listener) {
			delete $self->{_listeners}->[$i];
			return $listener;
		}
	}
}

sub activate {
	my ($self, $aspect, @data) = @_;
	foreach my $listener (@{ $self->{_listeners} }) {
		$listener->event($self, $aspect, @data);
	}
}
