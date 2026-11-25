# Magical Drop — CSC258 Assembly Project

A simplified version of Magical Drop, written in MIPS assembly and run in Saturn. The goal is to clear as many bubbles as possible before they reach the bottom of the board.

## How to Run

1. Open `magicaldrop.asm` in Saturn.
2. Open the Bitmap display tab and use the settings below.
3. Click the green Run button.
4. Click the bitmap display to enable keyboard input.

| Bitmap setting | Value |
| --- | --- |
| Unit width / height | 4 × 4 pixels |
| Display width / height | 128 × 128 pixels |
| Base address | `0x10008000` (`$gp`) |

## Controls

| Key | Action |
| --- | --- |
| **A** | Move left |
| **D** | Move right |
| **S** | Grab up to three consecutive, same-coloured bubbles from the column above |
| **W** | Throw held bubbles into the selected column |
| **Q** | Quit |

## Gameplay

- The board has 7 columns × 14 rows and starts with five randomly generated rows.
- The player can carry up to three bubbles of the same colour at once.
- Throwing bubbles can form a vertical match of three or more, which is then removed.
- Every 10 valid gameplay keypresses, existing bubbles move down one row and a new random row appears at the top.
- The game ends when bubbles reach the bottom row, or when the player presses Q.

## Implementation

Milestones 1–3 cover rendering the board, player movement, grabbing/throwing bubbles, row advancement, and vertical match detection. The board is stored as 98 four-byte cells (392 bytes), using `0` for empty and `1`–`4` for bubble colours.
