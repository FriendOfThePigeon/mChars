#!/usr/bin/perl
package MCharsView;
use strict;

use Glib qw(TRUE FALSE);
use Gtk2 -init;
use Gtk2::SimpleList;
use ArrayIterator;
use ReverseArrayIterator;
use MapIterator;

use Object;

our @ISA = qw( Object );

sub new {
	my ($class, $params) = @_;
	my $self  = $class->basic_new()->initialize();
	$self->make_window();
	return $self;
}

sub initialize {
	my ($self) = @_;
	$self->{_clipboard_refs} = [];
	return $self;
}

sub set_show_msg {
	my ($self, $proc) = @_;
	$self->{_msg} = $proc;
	return $self;
}

sub set_abort {
	my ($self, $proc) = @_;
	$self->{_abort} = $proc;
	return $self;
}

sub set_model {
	my ($self, $model) = @_;
	$self->{_model} = $model;
	$model->add_listener($self);
	$self->event($model, 'all');
	return $self;
}

sub set_clipboard_model {
	my ($self, $clipboard_model) = @_;
	$self->{_clipboard_model} = $clipboard_model;
	$clipboard_model->add_listener($self);
	return $self;
}

sub show {
	my ($self) = @_;
	$self->{_wnd}->show_all();
	return $self;
}

sub set_auto {
	my ($self, $on) = @_;
	if ($on) {
		$self->{_auto}++;
	} elsif ($self->{_auto} > 0) {
		$self->{_auto}--;
	}
}

sub on_auto {
	my ($self) = @_;
	return $self->{_auto} > 0;
}

sub list_entry_selected {
	my ($self, $sl, $selection, $column, $modify) = @_;
	my ($model, $iter) = $selection->get_selected();
	$column = 0 unless defined($column);
	if ($iter) {
		my $item = $model->get($iter, $column);
		if (defined($modify)) {
			$item = $modify->($item);
		}
		$self->{_clipboard_model}->add($item);
	}
}

sub update_clipboard_1 {
	my ($self, $chars) = @_;
	printf STDERR "Updating clipboard: >%s<\n", join('', @$chars);
	my $current = $self->{_clipboard_refs};
	my $cur = ArrayIterator->new_ref($current);
	my $new = ArrayIterator->new_ref($chars);
	my $c = $cur->peek();
	my $n = $new->peek();
	while (!($cur->at_end() || $new->at_end())) {
		last if ($c->[0] ne $n);
		printf STDERR "OK for %s...\n", $n;
		$c = $cur->next();
		$n = $new->next();
	}
	if (defined $c) {
		while (1) {
			$self->remove_clipboard_widget($c->[1]);
			last if $cur->at_end();
			$c = $cur->next();
		}
	}
	if (defined $n) {
		while (1) {
			$self->add_clipboard_widget($n);
			last if $new->at_end();
			$n = $new->next();
		}
	}
}

sub update_clipboard {
	my ($self, $chars) = @_;
	my $current = $self->{_clipboard_refs};
	my $cur = ReverseArrayIterator->new_ref($current);
	while (!$cur->at_end()) {
		my $c = $cur->next();
		$self->remove_clipboard_widget($c->[1], $c->[0]);
	}
	my $new = ArrayIterator->new_ref($chars);
	while (!$new->at_end()) {
		my $n = $new->next();
		$self->add_clipboard_widget($n);
	}
}

sub add_clipboard_widget {
	my ($self, $char) = @_;
	my $label;
	$label = Gtk2::Label->new();
	$label->set_markup("<span font=\"48\">$char</span>");
	$self->{_clipboard_box}->pack_start($label, FALSE, FALSE, 0);
	$label->set_visible(TRUE);
	push @{ $self->{_clipboard_refs} }, [$char, $label];
}

sub remove_clipboard_widget {
	my ($self, $widget, $char) = @_;
	if (!defined($widget)) {
		printf STDERR "Attempting to remove undef from clipboard\n";
		return;
	}
	$self->{_clipboard_box}->remove($widget);
	$widget->destroy();
	my $current = $self->{_clipboard_refs};
	for (my $i = $#$current; $i >= 0; $i--) {
		if ($$current[$i][1] == $widget) {
			splice @$current, $i, 1;
			last;
		}
	}
}

sub clear_entry {
	my ($self) = @_;
	$self->set_auto(1);
	$self->{_entry}->set_text('');
	$self->set_auto(0);
}

sub set_entry {
	my ($self, $text) = @_;
	$self->set_auto(1);
	$self->{_entry}->set_text($text);
	$self->set_auto(0);
}

sub send_to_model {
	my ($self, $input) = @_;
	return 0 if $self->on_auto();
	$self->{_model}->input($input);
}

sub copy_activated {
	my ($self, $btn) = @_;
	my $chars = join('', @{ $self->{_clipboard_model}->get_contents() });
	my $clipboard = Gtk2::Clipboard->get(Gtk2::Gdk->SELECTION_CLIPBOARD);
	$clipboard->set_text($chars);
	$clipboard->store();
}

sub filter_edited {
	my ($self, $entry) = @_;
	return 0 if $self->on_auto();
	my $text = $self->{_filter}->get_text();
	if ($text =~ m/\S/) {
		$self->send_to_model($text);
	}
}

sub clipboard_edited {
	my ($self, $entry) = @_;
	return;
}

sub make_window {
	my ($self) = @_;

	my $wnd = Gtk2::Window->new("toplevel");
	$wnd->set_title('mtimes');
	$wnd->set_default_size(500, 300);

	my $cancel_handler = sub {
		my $model = $self->{_model};
		$wnd->destroy();
		$self->{_abort}->();
	};
	$wnd->signal_connect("delete_event" => $cancel_handler);

	#my $a1 = Gtk2::Alignment->new(0.5, 0.5, 1.0, 1.0);
	#$a1->set_padding(1, 1, 1, 1);
	#$wnd->add($a1);

	my $vbox1;
	$vbox1 = Gtk2::VBox->new(FALSE, 9);
	#$a1->add($vbox1);
	$wnd->add($vbox1);

	# Filter entry
	my $entry1;
	$entry1 = Gtk2::Entry->new();
	my $filter_handler = sub {
		my ($source) = @_;
		$self->filter_edited($source);
	};
	for my $sig ('changed') {
		$entry1->signal_connect($sig => $filter_handler);
	}
	#$entry1->set_property('activates-default' => 1);
	$vbox1->pack_start($entry1, FALSE, TRUE, 0);
	$self->{_filter} = $entry1;

	# Results list
	my $scroll1 = Gtk2::ScrolledWindow->new();
	$vbox1->pack_start($scroll1, TRUE, TRUE, 0);

	my $list1;
	$list1 = Gtk2::SimpleList->new('Character' => 'markup', 'Code' => 'text', 'Description' => 'text', 'Category' => 'text');
	my $trim_result_entry = sub {
		my ($input) = @_;
		if ($input =~ m/^[^>]*>(.)/) {
			$input = $1;
		}
		return $input;
	};
	my $select_result_handler = sub {
		my ($source) = @_;
		$self->list_entry_selected($list1, $source, 0, $trim_result_entry);
	};
	$list1->get_selection->signal_connect (changed => $select_result_handler);
	my $a1 = Gtk2::Alignment->new(0, 0, 1, 0);
	$a1->add($list1);
	$scroll1->add_with_viewport($a1);
	$self->{_results} = $list1;
	$self->{_results_scroll} = $scroll1;

	# Clipboard
	my $hbox1;
	$hbox1 = Gtk2::HBox->new(FALSE, 9);
	$vbox1->pack_start($hbox1, FALSE, TRUE, 0);
	$self->{_clipboard_box} = $hbox1;

	my $a2 = Gtk2::Alignment->new(0.5, 0.5, 0.0, 0.0);
	#$a1->set_padding(1, 1, 1, 1);
	$hbox1->pack_end($a2, FALSE, FALSE, 0);

	my $copy_btn = Gtk2::Button->new_with_label("Copy");
	my $copy_handler = sub {
		my ($source) = @_;
		$self->copy_activated($source);
	};
	$copy_btn->signal_connect("clicked" => $copy_handler);
	$a2->add($copy_btn);
	$self->{_copy_button} = $copy_btn;
	$copy_btn->set_flags('GTK_CAN_DEFAULT');
	$copy_btn->grab_default();

	$self->{_wnd} = $wnd;
}

sub populate_list {
	my ($self, $list, $items, $scroll, $pango_first_column) = @_;
	my $list_data = $self->{$list}->{data};
    @$list_data = ( ); # Empty list
	for my $item (@$items) {
		if (ref($item) eq 'ARRAY') {
			if ($pango_first_column) {
				#$$item[0] =~ s,(.*),<span size="xx-large">\1</span>,;
				$$item[0] =~ s,(.*),<span font="48">\1</span>,;
			}
			push @$list_data, $item;
		} else {
			push @$list_data, [ $item ];
		}
	}
	if ($scroll) {
		my $sw = $self->{"${list}_scroll"};
		my $adj = $sw->get_vadjustment();
		$adj->set_value($adj->upper);
	}
}

sub append_list {
	my ($self, $list, $item, $scroll) = @_;
	my $list_data = $self->{$list}->{data};
	if (ref($item) eq 'ARRAY') {
		push @$list_data, $item;
	} else {
		push @$list_data, [ $item ];
	}
	if ($scroll) {
		my $sw = $self->{"${list}_scroll"};
		my $adj = $sw->get_vadjustment();
		$adj->set_value($adj->upper);
	}
}

sub update_results {
	my ($self, $results) = @_;
	$self->set_auto(1);
	$self->populate_list('_results', $results, 0, 1);
	#$self->clear_entry();
	$self->set_auto(0);
}

sub update_history {
	my ($self, $history) = @_;
	print "Updating history\n";
	$self->set_auto(1);
	$self->populate_list('_history', $self->{_model}->get_history(), 1);
	$self->set_auto(0);
}

sub event {
	my ($self, $source, $aspect, @data) = @_;
	if ($source == $self->{_model}) {
		if ($aspect eq 'results') {
			$self->update_results($data[0]);
		}
	} elsif ($source == $self->{_clipboard_model}) {
		if ($aspect eq 'contents') {
			$self->update_clipboard($data[0]);
		}
	}
}

1;
