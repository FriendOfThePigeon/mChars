#!/usr/bin/perl
package MapIterator;
use strict;

use Object;

our @ISA = qw( Object );

sub new {
	my ($class, $it, $func) = @_;
	my $self = $class->basic_new();
	$self->initialize($it, $func);
	return $self;
}

sub initialize {
	my ($self, $it, $func) = @_;
	$self->SUPER::initialize();
	$self->{_it} = $it;
	$self->{_func} = $func;
}

sub peek {
	my ($self) = @_;
	return undef if $self->{_it}->at_end();
	my $peek = $self->{_peek};
	return $peek if defined $peek;
	$peek = $self->{_func}->($self->{_it}->peek());
	$self->{_peek} = $peek;
	return $peek;
}

sub next {
	my ($self) = @_;
	return $self->{_func}->($self->{_it}->next());
}

sub at_end {
	my ($self) = @_;
	return $self->{_it}->at_end();
}

1;
