/*  Igi Chorazewicz [ichor001@ucr.edu]
 *  
 *  Assignment: Lab 10
 *  Description: Final project - Snake II Electric Boogaloo
 *
 *  I acknowledge all content contained herein excluding template or example
 *  code, is my own original work.
*/

#include <avr/io.h>
#include <stdio.h>
//#include "io.c"
#include "timer.c"	// basic PES code
#include "task.c"	// basic PES code

// cpu frequency
#define F_CPU 8000000

// bit manip helpers
#define SET_BIT(p,i) ((p) |= (1 << (i)))
#define CLR_BIT(p,i) ((p) &= ~(1 << (i)))
#define GET_BIT(p,i) ((p) & (1 << (i)))

#define MAX(a,b) ((a) > (b) ? (a) : (b))
#define MIN(a,b) ((a) < (b) ? (a) : (b))

// helpful function to reverse bits in a byte
unsigned char reverse(unsigned char b) {

    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
    b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
    b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
    return b;
}

// signed char 2D vector
typedef struct {
	char x;
	char y;
} vec2c;

// unsigned char 2D vector
typedef struct {
	unsigned char x;
	unsigned char y;
} vec2uc;

// checks for vector equality
unsigned char vecmatch(vec2c a, vec2c b) { return (a.x == b.x) && (a.y == b.y); }

// unsigned short exponent recursive function (a^b)
unsigned short uspow(unsigned short a, unsigned short b) {
	if(b == 0) return 1;
	else if(b == 1) return a;
	else return a * uspow(a, b-1);
}

// -------------- CONTROL PINS --------------

// control port pin assignments
#define CONTROL_PORT PORTC
#define CONTROL_PIN_ROWS_LATCH	7
#define CONTROL_PIN_MAT_ENABLE	6
#define CONTROL_PIN_LCD_LATCH	5
#define CONTROL_PIN_SSEG_LATCH	4
#define CONTROL_PIN_LCD_E		3
#define CONTROL_PIN_LCD_RS		2
#define CONTROL_PIN_MAT_LATCH	1
#define CONTROL_PIN_INPUT_LATCH	0


// -------------- LED MATRIX [MAT] --------------

// predefined color bytes (3-bit color; 0000 0RGB)
#define COL_RED		0x01
#define COL_GREEN	0x02
#define COL_BLUE	0x04
#define COL_WHITE	0x07
#define COL_CYAN	0x06
#define COL_MAGENTA	0x05
#define COL_YELLOW	0x03
#define COL_BLACK	0x00

// -------------- SEVEN SEGMENT DISPLAY [SSEG] --------------

/*	SSEG REFERENCE
		6
	5		7
		4
	0		2
		1		3
*/

// preset characters and numerals
#define SSEG_ALL 0xFF
#define SSEG_0 0xE7
#define SSEG_1 0x84
#define SSEG_2 0xD3
#define SSEG_3 0xD6
#define SSEG_4 0xB4
#define SSEG_5 0x76
#define SSEG_6 0x77
#define SSEG_7 0xC4
#define SSEG_8 0xF7
#define SSEG_9 0xF6

#define SSEG_DEC 0x08

// sseg numeral lookup table
unsigned const char SSEG_NUMS[10] = {	SSEG_0, SSEG_1, SSEG_2, SSEG_3, SSEG_4, 
										SSEG_5, SSEG_6, SSEG_7, SSEG_8, SSEG_9 };

// value to be written to sseg
volatile unsigned char SSEG_value;

void SSEG_setValue(unsigned char num) { SSEG_value = num; }


// -------------- INPUT --------------

// input button positions (use sseg to verify)
#define INPUT_BUTTON_UP		4
#define INPUT_BUTTON_DOWN	2
#define INPUT_BUTTON_LEFT	3
#define INPUT_BUTTON_RIGHT	7
#define INPUT_BUTTON_ACT	5
#define INPUT_ANY_BUTTON	0xB6

unsigned char INPUT_status;
unsigned char INPUT_held;
unsigned char INPUT_pressed;
unsigned char INPUT_released;


// -------------- GAME INTERNALS [GAME] --------------

//Game controller task
task GAME_task;

enum {
    GAME_start_menu,
	GAME_choose_level,
    GAME_main,
    GAME_over,
	GAME_scores
};

// game data bits assignment
#define GAME_OBJ_PLAYER (1 << 0)
#define GAME_OBJ_TRAIL	(1 << 1)
#define GAME_OBJ_POINT	(1 << 2)
#define GAME_OBJ_COIN	(1 << 3)
#define GAME_OBJ_CLEAR	(1 << 4)
#define GAME_OBJ_SHOT	(1 << 6)
#define GAME_OBJ_WALL	(1 << 7)

// other global game constants
#define GAME_SHOT_SPEED 2

// predefined direction vectors
#define DIR_UP		(vec2c){ .x =  0, .y =  1 }
#define DIR_DOWN	(vec2c){ .x =  0, .y = -1 }
#define DIR_LEFT	(vec2c){ .x = -1, .y =  0 }
#define DIR_RIGHT	(vec2c){ .x =  1, .y =  0 }

struct {
    vec2uc pos;
	vec2c dir;
    unsigned char size;
    unsigned char color;
    unsigned char score;
	unsigned char speed;

	unsigned char shot_ready;
	unsigned char shot_active;
	vec2uc shot_pos;
	vec2c shot_dir;
} player;

unsigned char current_level = 0;
unsigned char start_level = 1;

// snake-trail is implemented as an extremely simple queue
char trail_list[64] = {-1};
unsigned char trail_start = 0;
unsigned char trail_end = 0;
unsigned char trail_size = 0;

// simple variable for a simple explosion animation
vec2uc flash_pos;
unsigned char flash_active;

// game data structure
unsigned char game_data[8][8] = {};

// time in ms since game start
volatile long int game_time;

// strings for display on LCD
char display_string_a[16];
char display_string_b[16];

// this value determines the position at which score number is written to on bottom line.
unsigned char score_offset;

// rows that will be directly output to LED matrix
unsigned char screen_data[24];

// buffer formatted for 1 byte (3 bits) of color per pixel (0000 0BGR)
unsigned char color_grid[64] = { COL_BLACK };

// flags
volatile unsigned char timer_flag = 0;
volatile unsigned char flag_update_display;
volatile unsigned char flag_clear_display;
volatile unsigned char flag_paused;
volatile unsigned char flag_ingame;
volatile unsigned char flag_collision;
volatile unsigned char flag_update_scores;
volatile unsigned char flag_random_fill;

// Input SM task
task ISM_task;

enum {
	ISM_update
};

//Output SM task
task OSM_task;

enum {
	OSM_update
};

//Game logic task (pause functionality)
task LOGIC_task;

enum {
	LOGIC_main,
	LOGIC_shift,
	LOGIC_wait_fall
};


// timer function to be called as the timer's ISR
void timerFunc() {
	
	timer_flag = 1;
}


// send/recieve data via SPI
unsigned char SPI_masterTransmit(char cData) {

	// Send byte to SPI register to be transmitted
	SPDR = cData; 

	// Wait for transmission to complete
	while(!(SPSR & (1<<SPIF)));

	// Return the data received
	return SPDR;
}


void trail_push(char val) {

	trail_list[trail_end] = val;
	trail_end = (trail_end + 1) % 64;
	trail_size++;
}

char trail_pop() {
	
	char val = trail_list[trail_start];
	trail_list[trail_start] = -1;
	trail_start = (trail_start + 1) % 64;
	trail_size--;
	return val;
}

void trail_cut(unsigned char val) {

	unsigned char i;
	unsigned char found = 0;

	// look for val inside the trail, return if not found
	for(i = 0; i < trail_size; i++)
		if(trail_list[(trail_start + i) % 64] == val) found = 1;

	if(!found) return;
	
	// remove the trail up to the requested point
	unsigned char val_at;
	do {
		val_at = trail_pop();
		game_data[val_at / 8][val_at % 8] &= ~GAME_OBJ_TRAIL;
	//	game_data[val_at / 8][val_at % 8] |= GAME_OBJ_POINT;
		player.size--;

	} while(val_at != val);
}

// -------------- RANDOM NUMBER GENERATOR [RNG] ------------------

// base value
volatile unsigned short RNG_DATA;

// amount of LFSR iterations to run each time a rand is fetched.
// This is a simple way of increasing randomization without directly changing
// the RNG's value - at a cost of slightly more computations
volatile unsigned char RNG_ITER;

void RNG_seed(unsigned short seed) { RNG_DATA = seed; }

void RNG_iter(unsigned char x) { RNG_ITER = x; }

unsigned short rand() {

	// LFSR iteration.  Running more than 4 times helps to prevent lingering patterns from occurring within a 4 bit sample.
	unsigned char i;
    for(i = 0; i < RNG_ITER; i++)
		RNG_DATA = (RNG_DATA >> 1) | (((RNG_DATA >> 0) ^ (RNG_DATA >> 2) ^ (RNG_DATA >> 3) ^ (RNG_DATA >> 5)) << 15);
	
	return RNG_DATA;
}


// -------------- LCD SCREEN [LCD] --------------
//	Hijacked from io.c, necessary due to differences 
//	in sending data and massacre of processor cycles

// worst function ever
void delay_ms(int miliSec) //for 8 Mhz crystal
{
    int i,j;
    for(i=0;i<miliSec;i++)
    for(j=0;j<775;j++)
    {
        asm("nop");
    }
}


void LCD_writeCommand (unsigned char command) {

    CLR_BIT(CONTROL_PORT, CONTROL_PIN_LCD_RS);
    
    //DATA_BUS = Command;
    CLR_BIT(CONTROL_PORT, CONTROL_PIN_LCD_LATCH);
    SPI_masterTransmit(reverse(command));
    SET_BIT(CONTROL_PORT, CONTROL_PIN_LCD_LATCH);

    SET_BIT(CONTROL_PORT, CONTROL_PIN_LCD_E);
    asm("nop");
    CLR_BIT(CONTROL_PORT, CONTROL_PIN_LCD_E);
	
	// ~40 microsecond delay
	int i;
	for(i=0;i<40;i++) asm("nop");
}


void LCD_writeData(unsigned char data) {

   SET_BIT(CONTROL_PORT, CONTROL_PIN_LCD_RS);
   
   //DATA_BUS = Data;
   CLR_BIT(CONTROL_PORT, CONTROL_PIN_LCD_LATCH);
   SPI_masterTransmit(reverse(data));
   SET_BIT(CONTROL_PORT, CONTROL_PIN_LCD_LATCH);

   asm("nop");
   
   SET_BIT(CONTROL_PORT, CONTROL_PIN_LCD_E);
   asm("nop");
   CLR_BIT(CONTROL_PORT, CONTROL_PIN_LCD_E);
   
	// ~40 microsecond delay
	int i;
	for(i=0;i<40;i++) asm("nop");
}


void LCD_cursor(unsigned char column) {

   if ( column < 17 ) { // 16x1 LCD: column < 9
						// 16x2 LCD: column < 17
      LCD_writeCommand(0x80 + column - 1);
   } else {
      LCD_writeCommand(0xB8 + column - 9);	// 16x1 LCD: column - 1
											// 16x2 LCD: column - 9
   }
}


void LCD_clearScreen(void) {
   LCD_writeCommand(0x01);
   delay_ms(2); // ClearScreen requires 1.52ms to execute
}


void LCD_init(void) {

    //wait for 100 ms.
	delay_ms(100);
	LCD_writeCommand(0x38);
	LCD_writeCommand(0x06);
	LCD_writeCommand(0x0f);
	LCD_clearScreen();
	delay_ms(10);						 
}


void LCD_displayString(unsigned char column, const unsigned char* string) {

   LCD_clearScreen();
   unsigned char c = column;
   while(*string) {
      LCD_cursor(c++);
      LCD_writeData(*string++);
   }
}


// function to write 2 character arrays to the LCD, one for each row
void LCD_writeString(char const text_a[16], char const text_b[16]) {
	
	LCD_cursor(1);
	
	unsigned char i;
	for(i = 0; i < 32; i++) {
		
		LCD_cursor(i + 1);
		LCD_writeData(i < 16 ? text_a[i] : text_b[i - 16]);
	}
	LCD_cursor(0);
}


// utility function that directly reads string literals into display char array
void LCD_setDisplayString(const char* row_a, const char* row_b) {
	
	unsigned char i;
	for(i = 0; i < 16; i++) {
		display_string_a[i] = row_a[i];
		display_string_b[i] = row_b[i];
	}
}

// decimal-to-char and write the inputted number (left-align to the LCD at the position
void LCD_writeNumber(unsigned char val, unsigned char start, unsigned char size) {

	unsigned char count;
	unsigned short mul = uspow(10, size-1);
	unsigned char leading = 1;
	char c;

	// convert value to chars
	for(count = 0; count < size; count++) {
		c = '0' + (char)((val / mul)%10);
		mul /= 10;

		// don't write leading zeroes
		if(leading && count < 2 && c == '0') continue;

		LCD_cursor(start);
		LCD_writeData(c);

		start++;
		leading = 0;
	}
}


// -------------- LED MATRIX [MAT] --------------

/* Directly overwrites the screen with all 8 colors. */
void MAT_testColors() {

	unsigned char i;
	for(i = 0; i < 8; i++) {
		screen_data[i*3 + 0] = 0x39; // R
		screen_data[i*3 + 1] = 0x5A; // G
		screen_data[i*3 + 2] = 0x6C; // B
	}
}

/* Overwrites color buffer with fill color. */
void MAT_clearScreen(unsigned char fill) {

	unsigned char i;
	for(i = 0; i < 64; i++)
		color_grid[i] = fill;
}

/* Writes random colors into buffer (settles on one half the time) */
void MAT_randomFill() {

	static unsigned char count = 0;
	static unsigned char col = 0;

	// random seeds
	unsigned short rand_x = rand();
	unsigned short rand_y = rand();

	// use bits [3:0] of each rand as a screen pos from 0-7
	color_grid[(rand_x & 0x0007) * 8 + (rand_y & 0x0007)] = col;

	count++;

	// for half the time, fill with random colors, then fill with only one during the other half
	if(count > 128) {
		col = (rand_x & 0x0070) >> 4;
	}
}


void MAT_snakeFill(unsigned char col, unsigned short ticks) {
	

}


void MAT_shiftData() {
	
	unsigned char i;
	for(i = 0; i < 8; i++) {
    	screen_data[i] = (screen_data[i] << 1) | (screen_data[i] >> 7);
	}
}

/* copy and format data from color buffer into screen data (one row only) */
void MAT_transferBufferRow(unsigned char row) {

	unsigned char col;

	screen_data[row*3 + 0] = 0;
	screen_data[row*3 + 1] = 0;
	screen_data[row*3 + 2] = 0;

	for(col = 0; col < 8; col++) {
		screen_data[row * 3 + 0] |= ((color_grid[col * 8 + (7-row)] >> 0) & 1) << col; // R bit
		screen_data[row * 3 + 1] |= ((color_grid[col * 8 + (7-row)] >> 1) & 1) << col; // G bit
		screen_data[row * 3 + 2] |= ((color_grid[col * 8 + (7-row)] >> 2) & 1) << col; // B bit
	}
}

/* same as above, for entire screen */
void MAT_transferBuffer() {
	
	unsigned char row;
	for(row = 0; row < 8; row++) {
		MAT_transferBufferRow(row);
	}
}

/* Assigns colors to game objects, output into screen data. */
void GAME_render(unsigned short ticks) {

	unsigned char x, y;
	unsigned char blink_32 = (ticks / 32) % 2;
	unsigned char blink_64 = (ticks / 64) % 2;
//	unsigned char blink_128 = (ticks / 128) % 2;
//	unsigned char blink_182 = (ticks / 182) % 2;
	static unsigned short flash_timer;

	unsigned char color, data_point;

	for(x = 0; x < 8; x++) {
		for(y = 0; y < 8; y++) {
			data_point = game_data[x][y];
			color = COL_BLACK;
			// trail coloring
			color = data_point & GAME_OBJ_TRAIL ? (flag_collision ? COL_RED : COL_BLUE) : color;

			// goodie coloring
			color = data_point & GAME_OBJ_POINT ? COL_GREEN : color;
			color = data_point & GAME_OBJ_COIN ? COL_YELLOW : color;
			color = data_point & GAME_OBJ_CLEAR ? COL_MAGENTA : color;
			color = data_point & GAME_OBJ_SHOT ? COL_RED : color;

			color_grid[x*8 + y] = color;
		}
	}

	// flash animation (controlled by flash_active flag)
	if(flash_active) {
		if(flash_timer < 100) {
			unsigned char i;
			unsigned char j;

			for(i = 0; i <= 2; i++)
				for(j = 0; j <= 2; j++)
					if((flash_pos.x+i-1)>=0 && (flash_pos.x+i-1) <= 7 && (flash_pos.y+j-1)>=0 && (flash_pos.y+j-1)<=7)
						color_grid[(flash_pos.x + (unsigned char)i -1) * 8 + (flash_pos.y + (unsigned char)j -1)] = blink_32 ? COL_WHITE : color;
		
			flash_timer++;
		} else {
			flash_active = 0;
			flash_timer = 0;
		}
	}

	// overwrite pixel that player's at with player col
	color_grid[player.pos.x *8 + player.pos.y] = flag_collision ? (blink_64 ? COL_RED : COL_BLACK) : player.color;


	// if direction is being changed, flash a helper pixel
//	if(INPUT_pressed & (INPUT_BUTTON_UP | INPUT_BUTTON_DOWN | INPUT_BUTTON_LEFT | INPUT_BUTTON_RIGHT)) {
//		color_grid[(unsigned char)(player.pos.x + player.dir.x)*8 + (unsigned char)(player.pos.y + player.dir.y)] = COL_GREEN;
//	}

}


void GAME_spawnPoint(unsigned char type) {

	unsigned char i = 0;
	vec2uc pos;

	// search for an empty spot in the game grid (max 64 times)
	do {
		pos = (vec2uc){ .x = rand() % 8, .y = rand() % 8 };
		i++;
	} while(game_data[pos.x][pos.y] && i < 64);

	game_data[pos.x][pos.y] |= type;

	if(rand() % 15 == 0) GAME_spawnPoint(GAME_OBJ_COIN);
	if(rand() % 20 == 0) GAME_spawnPoint(GAME_OBJ_CLEAR);
	if(rand() % 25 == 0) GAME_spawnPoint(GAME_OBJ_SHOT);
}

// Dumped from initial state because it was getting too big
void GAME_init() {

	// GAME INITIALIZATION
	player.pos.x = 3;
	player.pos.y = 0;
	player.dir = DIR_UP;
	player.color = COL_GREEN;
	player.size = 0;
	player.score = 0;
	player.shot_ready = 0;
	current_level = start_level;
	GAME_spawnPoint(GAME_OBJ_POINT);
	LCD_writeString(	"  - LEVEL  x -  ",
						"   score:  x    ");
	flag_update_scores = 1;
}

// Clears away all game data after a game (soft reset)
void GAME_clear() {
	
	unsigned char i;
	for(i=0;i<64;i++) game_data[i/8][i%8] = 0;
	for(i=0;i<8;i++) screen_data[i] = 0x00;
	for(i=0;i<64;i++) trail_list[i] = -1;
	trail_start = trail_end = 0;
	flag_random_fill = 0;
	flag_collision = 0;
	trail_size = 0;
}


int ISM_tick(int state) {
	
	//transitions
	switch(state) {
		case ISM_update:
			break;
		default:
			state = ISM_update;
			break;
	}
	
	//actions
	switch(state) {
		case ISM_update:
		
			// Shift in byte from 4014B game-pad register
			CLR_BIT(CONTROL_PORT, CONTROL_PIN_INPUT_LATCH);
			INPUT_status = SPI_masterTransmit(0x00);
			SET_BIT(CONTROL_PORT, CONTROL_PIN_INPUT_LATCH);
			
			// bit will be flagged here for 1 tick if button detected and not yet stored
			INPUT_pressed = INPUT_status & ~INPUT_held;
			
			// bit will be flagged here for 1 tick if button stored but not detected anymore
			INPUT_released = ~INPUT_status & INPUT_held;

			// Store state of inputs as array of held buttons
			INPUT_held = INPUT_status;
			
			break;
		default:
			break;
	}
	
	return state;
}


int OSM_tick(int state) {

	static unsigned short ticks = 0;
	static unsigned char count = 0;
	static unsigned char num = 0;

	unsigned char shift = (count % 8);
	
	// transitions
	switch(state) {
		case OSM_update:
			break;
		default:
			MAT_clearScreen(COL_WHITE);
			game_time = 0;
			state = OSM_update;
			break;
	}
	
	// actions
	switch(state) {
		case OSM_update:

			if(flag_random_fill) {
				if(count % 10 == 0)
					MAT_randomFill();
			} else {

			//	color_grid[0] = COL_WHITE;	// debug pixel, top-left
			
				MAT_clearScreen(COL_BLACK);
			
				if(flag_ingame)
					GAME_render(ticks);
			}

    		// write color data buffer to screen data array in byte-per-row format
			// only current row is updated
    		MAT_transferBufferRow(shift);

    	//	MAT_testColors();

			if(ticks % 1 == 0) {

				// disable display during shifting (prevents ghosting and glitches)
				SET_BIT(CONTROL_PORT, CONTROL_PIN_MAT_ENABLE);
				
				// shift row data into three-byte shift register
				CLR_BIT(CONTROL_PORT, CONTROL_PIN_MAT_LATCH);
				SPI_masterTransmit(~screen_data[shift * 3 + 2]); // B
				SPI_masterTransmit(~screen_data[shift * 3 + 1]); // G
				SPI_masterTransmit(~screen_data[shift * 3 + 0]); // R
				SET_BIT(CONTROL_PORT, CONTROL_PIN_MAT_LATCH);

				// shift to next row
				CLR_BIT(CONTROL_PORT, CONTROL_PIN_ROWS_LATCH);
				//SPI_MasterTransmit(1 << shift);	// bottom to top
				SPI_masterTransmit(0x80 >> shift);	// top to bottom
				SET_BIT(CONTROL_PORT, CONTROL_PIN_ROWS_LATCH);

				// shift in 7 segment display number
				CLR_BIT(CONTROL_PORT, CONTROL_PIN_SSEG_LATCH);
			//	SPI_masterTransmit(INPUT_pressed | INPUT_released);
				SPI_masterTransmit(SSEG_value);
				SET_BIT(CONTROL_PORT, CONTROL_PIN_SSEG_LATCH);
				
				// clear display if requested
				if(flag_clear_display) {
					LCD_clearScreen();
					flag_clear_display = 0;
				}
				
				// update display if requested
				if(flag_update_display) {
					LCD_writeString(display_string_a, display_string_b);
					flag_update_display = 0;
				}

				// update score amounts on level display ingame
				if(flag_update_scores) {

					// level display
				//	LCD_cursor(12);
					LCD_writeNumber(current_level, 12, 2);

					LCD_writeNumber(player.score, 28, 3);

					LCD_cursor(0);

					flag_update_scores = 0;
				}

				// re-enable display
				CLR_BIT(CONTROL_PORT, CONTROL_PIN_MAT_ENABLE);

				// row counter
				count++;
			}

			ticks++;
			game_time++;
			
			break;
		default:
			break;
	}
	
	return state;
}


int LOGIC_tick(int state) {
	
//	static unsigned short ticks = 0;
	
	// transition
	switch(state) {
		case LOGIC_main:
// 			if(button_2) {
// 				flag_paused = !flag_paused;
// 				state = LOGIC_wait_fall;
// 			}
			break;
		case LOGIC_wait_fall:
		//	if(!button_2) state = LOGIC_main;
			break;
		default:
			state = LOGIC_main;
			break;
	} //end transition
	
	//action
	switch(state) {
		case LOGIC_main:
			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_RIGHT) && !vecmatch(player.dir, DIR_LEFT))	
				player.dir = DIR_RIGHT;

			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_LEFT) && !vecmatch(player.dir , DIR_RIGHT))	
				player.dir = DIR_LEFT;

			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_UP) && !vecmatch(player.dir , DIR_DOWN))		
				player.dir = DIR_UP;

			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_DOWN) && !vecmatch(player.dir , DIR_UP))		
				player.dir = DIR_DOWN;


			current_level = (player.score+1) / 10 + start_level;
			unsigned char level_score = player.score % 10;

			SSEG_value = flag_ingame ? SSEG_NUMS[player.score % 10] : 0x00;

			// modify RNG based on player's position (increases entropy)
			RNG_iter(MAX(player.pos.x, player.pos.y)/2 + 1);

			// switching speeds of game through levels
			switch(current_level) {
				case 0:
					player.speed = 60;
					break;
				case 1:
					player.speed = 50;
					break;
				case 2:
					player.speed = 40;
					break;
				case 3:
					player.speed = 35;
					break;
				case 4:
					player.speed = 30;
					break;
				case 5:
					player.speed = 27;
					break;
				case 6:
					player.speed = 24;
					break;
				case 7:
					player.speed = 21;
					break;
				case 8:
					player.speed = 19;
					break;
				case 9:
					player.speed = 17;
					break;
				default:
					player.speed = 15;
					break;
			}

			break;
		default:
			break;
	} // end action
	
	return state;
}


int GAME_tick(int state) {
	
	// small counter to keep track of time
	static unsigned short ticks = 0;
	
	// transition
	switch(state) {
		case GAME_start_menu:
			if(INPUT_pressed & INPUT_ANY_BUTTON) {
				start_level = 1;
				ticks = 0;
				LCD_writeString(	"  LEVEL SELECT  ",
									"     < 1 >      ");
				state = GAME_choose_level;
			}
			break;
		case GAME_choose_level:
			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_ACT)) {
				ticks = 0;
				GAME_init();
				flag_ingame = 1;
				state = GAME_main;
			}
			break;
		case GAME_main:
			if(flag_collision) {
				ticks = 0;
				state = GAME_over;
			}
			break;
		case GAME_over:
			// after 3 sec
			if(ticks > 300) {
				// transition to final score screen
				LCD_writeString(	"  Final Score:  ",
									"||     x      ||");
				LCD_writeNumber(player.score, 24, 3);
				LCD_cursor(0);
				flag_ingame = 0;
				state = GAME_scores;
			}
			break;
		case GAME_scores:
			// advance to restart game from score screen
			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_ACT)) {
				state = -1;
			}
			break;
		default:
			// initial stuff
			ticks = 0;
			GAME_clear();
			flag_random_fill = 0;
			state = GAME_start_menu;
			break;
	} // end transition

	static vec2uc old_pos;
	static vec2uc new_pos;
	
	// action
	switch(state) {
		case GAME_start_menu:
			if(ticks == 0)
				LCD_writeString(	"    SNAKE       ",
									"                ");
			else if(ticks == 50)
				LCD_writeString(	" == SNAKE II == ",
									"                ");
			else if(ticks > 100) {
				if(ticks % 100 == 0)
					LCD_writeString(	" == SNAKE II == ",
										" press any key! ");
				if(ticks % 100 == 50)
					LCD_writeString(	" == SNAKE II == ",
										"                ");
			}

			ticks++;
			break;
		case GAME_choose_level:
			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_LEFT)) {
				start_level = MAX(start_level - 1, 1);
				LCD_writeNumber(start_level, 24, 1);
				LCD_cursor(0);
			}
			if(GET_BIT(INPUT_pressed, INPUT_BUTTON_RIGHT)) {
				start_level = MIN(start_level + 1, 10);
				LCD_writeNumber(start_level, 24, 1);
				LCD_cursor(0);
			}
			break;
		case GAME_main:

			// SHOT MOVEMENT

		//	if(!player.shot_active) player.shot_ready = 1;

			if(ticks % GAME_SHOT_SPEED == 0 && player.shot_active) {

				// remove shot from gamedata
				game_data[player.shot_pos.x][player.shot_pos.y] &= ~GAME_OBJ_SHOT;
				
				// prepare new coordinates
				vec2c new_shot_pos;
				new_shot_pos.x = player.shot_pos.x + player.shot_dir.x;
				new_shot_pos.y = player.shot_pos.y + player.shot_dir.y;
				char data_at = game_data[(unsigned char)new_shot_pos.x][(unsigned char)new_shot_pos.y];

				if(		(new_shot_pos.x < 0 || new_shot_pos.x > 7) || 
						(new_shot_pos.y < 0 || new_shot_pos.y > 7)	) {
					// if out of bounds

					// disable
					player.shot_active = 0;
							
					// set flash on boundary
					flash_pos.x = player.shot_pos.x;
					flash_pos.y = player.shot_pos.y;
					flash_active = 1;

				} else if(data_at) {
					// if colliding with any nonzero point

					player.shot_active = 0;

					if(data_at & GAME_OBJ_TRAIL) {
						// if shot hit a trail, cut the trail up to that position (:D)
						trail_cut(new_shot_pos.x * 8 + new_shot_pos.y);
					} else if(data_at & GAME_OBJ_POINT) {
						// if hit point, give big bonus and spawn another
						player.score += 10;
						GAME_spawnPoint(GAME_OBJ_POINT);
					} else if(data_at & (GAME_OBJ_COIN | GAME_OBJ_CLEAR)) {
						// if anything else was hit, just give a bonus
						player.score += 20;
					}

					// remove hit object
					game_data[(unsigned char)new_shot_pos.x][(unsigned char)new_shot_pos.y] = 0;

					// update score
					flag_update_scores = 1;
					
					// set flash
					flash_pos.x = new_shot_pos.x;
					flash_pos.y = new_shot_pos.y;
					flash_active = 1;

				} else {
					// normal movement

					// move shot to new pos
					player.shot_pos.x = new_shot_pos.x;
					player.shot_pos.y = new_shot_pos.y;
					game_data[player.shot_pos.x][player.shot_pos.y] |= GAME_OBJ_SHOT;
				}
			}
			
			// PLAYER MOVEMENT

			// prepare new coordinates
			new_pos = player.pos;
			new_pos.x += player.dir.x;
			new_pos.y += player.dir.y;

			// if pos has changed (reject if moving to old pos)
			if(	(ticks % player.speed == player.speed-1) &&
				(new_pos.x != player.pos.x || new_pos.y != player.pos.y) &&
				(new_pos.x != old_pos.x || new_pos.y != old_pos.y)) {
			
				// store old pos
				old_pos = player.pos;

				// check for trail or bounds collision
				if(	(game_data[new_pos.x][new_pos.y] & GAME_OBJ_TRAIL) ||
					(new_pos.x < 0 || new_pos.x > 7 || new_pos.y < 0 || new_pos.y > 7)) {
					// collision detected

					flag_collision = 1;

				} else {
				
					// pick up point
					if(game_data[new_pos.x][new_pos.y] & GAME_OBJ_POINT) {

						game_data[new_pos.x][new_pos.y] &= ~GAME_OBJ_POINT;
						player.score++;
						player.size++;
						GAME_spawnPoint(GAME_OBJ_POINT);
						flag_update_scores = 1;
					//	flag_clear_display = 1;
						ticks = 0;
					}

					// pick up coin
					if(game_data[new_pos.x][new_pos.y] & GAME_OBJ_COIN) {
						
						game_data[new_pos.x][new_pos.y] &= ~GAME_OBJ_COIN;
						player.score += 5;
						flag_update_scores = 1;
						ticks = 0;
					}

					// pick up clear
					if(game_data[new_pos.x][new_pos.y] & GAME_OBJ_CLEAR) {
						
						game_data[new_pos.x][new_pos.y] &= ~GAME_OBJ_CLEAR;

						player.score += 2;
						player.size = 3;
						
						flag_update_scores = 1;
						
						ticks = 0;
					}

					// pick up shot
					if(game_data[new_pos.x][new_pos.y] & GAME_OBJ_SHOT) {
						
						game_data[new_pos.x][new_pos.y] &= ~GAME_OBJ_SHOT;

						player.score += 3;
						player.shot_ready = 1;
						
						flag_update_scores = 1;
						
						ticks = 0;
					}

					// remove end of trail
					while(trail_size > player.size) {
						char trail_end_index = trail_pop();
						game_data[trail_end_index / 8][trail_end_index % 8] &= ~GAME_OBJ_TRAIL;
					}

					// adjust gamedata with player object
					game_data[player.pos.x][player.pos.y] &= ~GAME_OBJ_PLAYER;
					player.pos = new_pos;
					game_data[player.pos.x][player.pos.y] |= GAME_OBJ_PLAYER;

					// update trail
					flag_collision = 0;
					game_data[player.pos.x][player.pos.y] |= GAME_OBJ_TRAIL;
					trail_push(player.pos.x * 8 + player.pos.y);
				}
			}

			// Player action
			if(GET_BIT(INPUT_held, INPUT_BUTTON_ACT)) {

				player.color = COL_WHITE;

				// if shot was equipped, initialize and "fire"
				if(player.shot_ready) {
					player.shot_ready = 0;
					player.shot_active = 1;
					player.shot_pos = player.pos;
					player.shot_dir = player.dir;
				}
			} else
				// indicator that a shot is ready
				player.color = player.shot_ready ? COL_RED : COL_CYAN;

			ticks++;

			break;

		case GAME_over:
			
			// only update every 25 ticks
			if(ticks % 25 == 0) {

				// alternate to flash words
				if(ticks % 50 == 0)
					LCD_setDisplayString(	"||    GAME    ||",
											"||    OVER    ||");
				if(ticks % 50 == 25)
					LCD_setDisplayString(	"||            ||",
											"||            ||");
				flag_update_display = 1;
				flag_clear_display = 1;
			}

			ticks++;
			break;
		case GAME_scores:
			// activate random animation
			flag_random_fill = 1;
			break;
		default:
			break;
	} // end action
			
	return state;
}


int main(void) {
	
	DDRA = 0x00; PORTA = 0xFF; // button inputs
	DDRB = 0xFF; PORTB = 0x00; // LCD data out
	DDRC = 0xFF; PORTC = 0x00; // various control outputs
	DDRD = 0xFF; PORTD = 0x00; // various control outputs

	/* Enable SPI master mode */
	SPCR = (1 << SPE) | (1 << MSTR);

	// Set SPI clk speed
//	SPSR |= (1 << SPR1) | (1 << SPR0);
	SPSR |= (1 << SPI2X);

	CLR_BIT(CONTROL_PORT, CONTROL_PIN_MAT_ENABLE);
	
	// default period
	int timer_period = 1;

	// timer multiplier.  OCR will be set to (125 / mul)
	int timer_mul = 5;
	
	// init LCD
	LCD_init();
	LCD_clearScreen();
	LCD_writeString(	"    Testing     ",
						"      testing   ");
	LCD_cursor(0);
	
	// add tasks (in order of execution)
	addTask(&ISM_task, &ISM_tick, 10 * timer_mul);
	addTask(&LOGIC_task, &LOGIC_tick, 10 * timer_mul);
	addTask(&GAME_task, &GAME_tick, 10 * timer_mul);
	addTask(&OSM_task, &OSM_tick, 1 * timer_mul);

	// calculate GCD and init timer
	timer_period = periodGCD(tasks);
	TimerSet(timer_period);
	TimerMul(timer_mul);
	TimerOn();
	TimerISR = &timerFunc;

	// initialize RNG
	RNG_seed(0x36A9);
	RNG_iter(5);
	
	// basic task scheduler
	unsigned char i;	
    while(1) {
	    
	    // set state processing indicator
	    SET_BIT(PORTD, 0);
		
		for(i = 0; tasks[i] && i < num_tasks; i++) {
			
			// call task tick
			if(tasks[i]->elapsed_time >= tasks[i]->period) {
				tasks[i]->state = tasks[i]->tick(tasks[i]->state);
				tasks[i]->elapsed_time = 0;
			}
			
			tasks[i]->elapsed_time += timer_period;
		}
	
		CLR_BIT(PORTD, 0);
		
		//timer delay
		while(!timer_flag);
		timer_flag = 0;
    }
}
