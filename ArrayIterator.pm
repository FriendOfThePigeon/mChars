#!/usr/bin/perl
package ArrayIterator;
use strict;

use Object;

our @ISA = qw( Object );

sub new_array {
	my ($class, @array) = @_;
	my $self = $class->basic_new();
	$self->initialize(\@array);
	return $self;
}

sub new_ref {
	my ($class, $array_ref) = @_;
	my $self = $class->basic_new();
	$self->initialize($array_ref);
	return $self;
}

sub initialize {
	my ($self, $array_ref) = @_;
	$self->SUPER::initialize();
	$self->{_ref} = $array_ref;
	$self->{_index} = 0;
	$self->{_len} = $#$array_ref + 1;
}

sub peek {
	my ($self) = @_;
	if ($self->at_end()) {
		return undef;
	}
	return $self->{_ref}->[$self->{_index}];
}

sub next {
	my ($self) = @_;
	my $index = $self->{_index};
	my $result = $self->{_ref}->[$index];
	$self->{_index} = $index + 1;
	return $result;
}

sub at_end {
	my ($self) = @_;
	my $result = ($self->{_index} >= $self->{_len});
	return $result;
}

1;
