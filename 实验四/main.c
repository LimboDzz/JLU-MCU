#include <reg52.h>

#define uchar unsigned char
#define uint unsigned int

#region identifer_dev
sbit DS_X=P0^0;
sbit SHCP_X=P0^1;
sbit STCP_X=P0^2;
sbit DS_Y=P0^3;
sbit EN_Y=P0^4;
sbit SHCP_Y=P0^5;
sbit STCP_Y=P0^6;
sbit EN_X=P0^7;
#endregion

#region identifer_prod
//sbit DS_X=P0^0;
//sbit SHCP_X=P0^1;
//sbit STCP_X=P0^2;
//sbit DS_Y=P0^3;
//sbit EN_Y=P0^4;
//sbit SHCP_Y=P0^5;
//sbit STCP_Y=P0^6;
//sbit EN_X=P0^7;
#endregion

// 16x16 itasura
uchar charCodes={0x08,0x14,0x78,0x24,0x08,0x24,0xFE,0x04,0x8A,0x74,0x3A,0x0F,0x4E,0x04,0x72,0x24,
0x02,0x24,0x52,0x14,0x56,0x15,0xDA,0x08,0x52,0x48,0xF1,0x54,0x1E,0x62,0x00,0x41};

void main(){


}