#include "reg52.h"
#include "codes.h"
#include "delay.h"

#region sbit
sbit RST_164=P1^1;
sbit CLK_164=P1^4;
sbit IN_164	=P1^5;
sbit btn		=P1^0;		// btn==0 pressed down
#endregion

#region !IMPORTENT
// hex_code&0x80 to get the HIGHEST bit CUZ abcdefg link to P^0123456
// would go wrong if you get the lowest bit as is done in the tutorial, cuz the codes sequence in reverse
#endregion

unsigned char flag=0;
unsigned int num=0x00;

void onkeyup(){
	if(flag==0&&btn==0){
		flag=1;	// pressed down
	}
	if(flag==1&&btn==1){
		flag=0;
	}
}

// display 2 digit hex_num
void display_2_digit_hex(unsigned int hex){
	unsigned int digit[2],i=0,j=0;
	digit[1]=hex/16;
	digit[0]=hex%16;
	for(i=0;i<2;i++){
		// send every digit(8bit to lit a 7seg) in 8 times
		unsigned int n=digit[i];
		unsigned int hex_code=SEG_CC_NUM[n];
		for(j=0;j<8;j++){
			CLK_164=0;
			IN_164=hex_code&0x80;			// &0x80 to get the highest bit abcdefg link to P^0123456
			hex_code=hex_code<<1;			// shl 8 times in this loop
			CLK_164=1;								// CLK_164 0->1 Enable
		}
	}
}

void main(){
	while(1){
		display_2_digit_hex(num);
		onkeyup();
		if(flag){
			num=++num%256;
			delay_ms(500);
		}
	}
}