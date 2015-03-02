#!/usr/bin/perl
package CharsIterator;
use strict;

use Object;

our @ISA = qw( Object );

sub new_string {
	my ($class, $string) = @_;
	my $self = $class->basic_new();
	$self->initialize($string);
	return $self;
}

sub initialize {
	my ($self, $string) = @_;
	$self->SUPER::initialize();
	$self->{_string} = $string;
	$self->{_index} = 0;
	$self->{_len} = length $string;
}

sub peek {
	my ($self) = @_;
	return substr($self->{_string}, $self->{_index}, 1);
}

sub next {
	my ($self) = @_;
	my $index = $self->{_index};
	my $result = substr($self->{_string}, $self->{_index}, 1);
	$self->{_index} = $index + 1;
	return $result;
}

sub at_end {
	my ($self) = @_;
	my $result = ($self->{_index} >= $self->{_len});
	return $result;
}

1;
