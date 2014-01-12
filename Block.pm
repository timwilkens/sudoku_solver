package Block;

use strict;
use warnings;
use Cell;
use Data::Dumper;

=head1 new

  Our constructor method.

  Creates a new block object populated with 9 cell objects numbered 1 through 9.

  my $block = Block->new;

=cut

sub new {
  my $class = shift;
  my $self;

  for my $num (1 .. 9) {
    my $cell = Cell->new();
    $self->{$num} = $cell;
  }

  return bless $self, $class;
}

=head1 get_block_values

  Method that returns all the values for a given block, specified by cell number.

  my $values = $board->get_block_values;
  my $value_for_cell_3 = $values->{3};

=cut

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

=head1 get_cell

  Simple getter to get the cell object stored inside the given block;

  my $cell = $block->get_cell(3);

=cut

sub get_cell {
  my ($self, $cell_num) = @_;

  return $self->{$cell_num};
}

=head1 remove_options_by_block

  Method that goes through our block, cell by cell, and if a cell has a value,
  removes that as an option for the other cells.

  $block->remove_options_by_block;

=cut

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

