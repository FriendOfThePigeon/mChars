#!/usr/bin/perl
package Object;
use strict;

sub basic_new {
	my ($class, $params) = @_;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

sub initialize {
	my ($self) = @_;
	return $self;
}

sub new {
	my ($class, $params) = @_;
	my $self = $class->basic_new();
	$self->initialize();
	return $self;
}

1;
