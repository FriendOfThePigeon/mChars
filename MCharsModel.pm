#!/usr/bin/perl
package MCharsModel;
use strict;

use Object;
use EventSource;
use ArrayIterator;

our @ISA = qw( EventSource );

sub new {
	my ($class, $cfg) = @_;
	my $self = $class->basic_new();
	$self->{_history} = [];
	$self->{_results} = [];
	$self->initialize($cfg);
	return $self;
}

sub initialize {
	my ($self, $cfg) = @_;
	$self->{_cfg} = ($cfg or {});
	return $self;
}

sub get_results {
	my ($self) = @_;
	return $self->{_results};
}

sub get_history {
	my ($self) = @_;
	return $self->{_history};
}

sub parse_one_result {
	my ($self, $it) = @_;
	my $code_and_description = $it->next();
	my $other_bases = $it->next();
	my $rendering = $it->next();
	my $category = $it->next();
	my $bidi = $it->next();
	while (!$it->at_end()) {
		my $next = $it->next();
		last if $next =~ m/^\s*$/;
	}
	$code_and_description =~ m/U\+([0-9A-F]{4}) (.*)/;
	my ($code, $description) = ($1, $2);
	$category =~ s/Category: //;
	chomp $rendering;
	utf8::decode($rendering);
	chomp $category;
	return [ $rendering, $code, $description, $category ];
}

sub parse_results {
	my ($self, @array) = @_;
	my $it = ArrayIterator->new_array(@array);
	my $results = [];
	while (!$it->at_end()) {
		my $result = $self->parse_one_result($it);
		push @$results, $result;
		#printf STDERR "Got: [%s]\n", join(';', @$result);
	}
	printf STDERR "%d results.\n", $#$results + 1;
	return $results;
}

sub input {
	my ($self, $input) = @_;
	printf STDERR "Filtering on >%s<\n", $input;
	my $results = $self->parse_results(`unicode --max=99 '$input'`);
	$self->{_results} = $results;
	$self->activate('results', $results);
}

1;
