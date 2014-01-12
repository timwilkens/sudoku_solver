#!/usr/bin/perl

use strict;
use warnings;
use Board;
use Cell;
use Block;
use Data::Dumper;

## EASY ##
#my $board = Board->new([0,1,0,0,0,0,4,6,0,
#                        3,6,8,0,1,0,0,7,0,
#                        4,0,0,6,0,9,0,5,3,
#                        0,4,6,1,0,0,0,2,5,
#                        1,5,0,0,2,0,0,8,3,
#                        9,3,0,0,0,8,7,1,0,
#                        2,8,0,7,0,3,0,0,1,
#                        0,9,0,0,4,0,7,3,2,
#                        0,7,1,0,0,0,0,4,0,]);

## MEDIUM ##
#my $board = Board->new([0,0,0,7,0,4,0,0,0,
#                        0,4,1,0,0,0,3,0,0,
#                        2,7,8,0,0,0,0,9,0,
#                        1,0,0,3,9,2,0,7,6,
#                        4,0,6,7,0,8,9,0,3,
#                        7,3,0,6,1,4,0,0,2,
#                        0,3,0,0,0,0,6,1,9,
#                        0,0,7,0,0,0,8,3,0,
#                        0,0,0,3,0,6,0,0,0,]);

## HARD ##
my $board = Board->new([0,0,0,3,0,0,0,0,1,
                        2,0,0,0,0,5,0,0,3,
                        0,6,3,4,0,1,9,8,0,
                        0,0,0,0,0,0,0,3,0,
                        0,0,0,5,3,8,0,0,0,
                        0,9,0,0,0,0,0,0,0,
                        0,2,6,5,0,3,4,7,0,
                        3,0,0,7,0,0,0,0,1,
                        5,0,0,0,0,8,0,0,0,]);

## EXPERT ##
#my $board = Board->new([0,0,6,0,0,0,0,4,0,
#                        0,0,0,8,6,0,3,5,0,
#                        0,0,4,7,3,0,0,0,2,
#                        1,7,0,0,9,0,0,0,8,
#                        4,0,0,0,0,0,0,0,6,
#                        6,0,0,0,8,0,0,1,7,
#                        2,0,0,0,6,7,8,0,0,
#                        0,8,1,0,4,3,0,0,0,
#                        0,4,0,0,0,0,3,0,0,]);

## EXTREME ##
#my $board = Board->new([6,0,0,0,0,5,7,2,9,
#                        0,0,0,0,0,2,0,0,0,
#                        0,4,0,0,0,7,0,0,3,
#                        0,9,0,0,0,0,4,0,0,
#                        0,4,0,0,6,0,0,8,0,
#                        0,0,1,0,0,0,0,7,0,
#                        3,0,0,2,0,0,0,5,0,
#                        0,0,0,4,0,0,0,0,0,
#                        1,6,5,8,0,0,0,0,4,]);

#my $board = Board->new([0,7,0,9,0,0,0,0,8,
#                        0,0,6,0,0,0,0,0,9,
#                        0,0,0,0,4,2,0,5,0,
#                        0,9,0,0,0,3,4,0,0,
#                        0,0,7,0,0,0,8,0,0,
#                        0,0,2,8,0,0,0,1,0,
#                        0,8,0,1,6,0,0,0,0,
#                        3,0,0,0,0,0,5,0,0,
#                        9,0,0,0,0,7,0,8,0,]);

## EXTREME ##
#my $board = Board->new([9,0,0,0,6,0,2,0,0,
#                        0,0,0,0,4,0,5,0,0,
#                        2,0,0,0,5,0,3,0,0,
#                        0,0,4,0,3,0,5,0,0,
 #                       0,0,0,0,1,0,0,0,0,
 #                       0,0,9,0,6,0,8,0,0,
#                        0,0,1,0,5,0,0,0,6,
#                        0,0,9,0,7,0,0,0,0,
#                        0,0,2,0,4,0,0,0,7,]);

## WORLD'S HARDEST ##
#my $board = Board->new([8,0,0,0,0,3,0,7,0,
#                        0,0,0,6,0,0,0,9,0,
#                        0,0,0,0,0,0,2,0,0,
#                        0,5,0,0,0,0,0,0,0,
#                        0,0,7,0,4,5,1,0,0,
#                        0,0,0,7,0,0,0,3,0,
#                        0,0,1,0,0,8,0,9,0,
#                        0,0,0,5,0,0,0,0,0,
#                        0,6,8,0,1,0,4,0,0,]);

$board->display();
$board->solve();
