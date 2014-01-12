package Block;

use strict;
use warnings;
use Cell;
use Data::Dumper;

sub new {
  my $class = shift;
  my $self;

  for my $num (1 .. 9) {
    my $cell = Cell->new();
    $self->{$num} = $cell;
  }

  return bless $self, $class;
}

sub get_block_values {
  my $self = shift;

  my $values;
  for my $num (1 .. 9) {
    my $value = $self->{$num}->get_value();
    if (defined $value) {
      $values->{$num} = $value;
    } else {
      $values->{$num} = ' ';
    }
  }
  return $values;
}

sub get_cell {
  my ($self, $cell_num) = @_;

  return $self->{$cell_num};
}

sub remove_options_by_block {
  my $self = shift;
  my $removals = 0;

  for my $cell_number (1 .. 9) {
    my $cell = $self->get_cell($cell_number);
    my $value = $cell->get_value;

    if (defined $value) {
      for my $other_cell_number (1 .. 9) {
        my $other_cell = $self->get_cell($other_cell_number);
        next if ($cell_number == $other_cell_number);
        next if (defined $other_cell->get_value);
        my $options = $other_cell->get_options;
        if (defined $options->{$value}) {
          $other_cell->remove_option($value);
          $removals++;
        }
      }
    }
  }
  return $removals;
}      

1;

