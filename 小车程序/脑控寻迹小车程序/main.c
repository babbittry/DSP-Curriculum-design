#include "stm32f10x.h"
#include "interface.h"
#include "IRCtrol.h"
#include "motor.h"
#include "uart.h"

//全局变量定义
unsigned int speed_count=0;//占空比计数器 50次一周期
char front_left_speed_duty=SPEED_DUTY;
char front_right_speed_duty=SPEED_DUTY;
char behind_left_speed_duty=SPEED_DUTY;
char behind_right_speed_duty=SPEED_DUTY;


unsigned char tick_5ms = 0;//5ms计数器，作为主函数的基本周期
unsigned char tick_1ms = 0;//1ms计数器，作为电机的基本计数器
unsigned char tick_200ms = 0;//刷新显示

char ctrl_comm = COMM_STOP;//控制指令
char ctrl_comm_last = COMM_STOP;//上一次的指令
unsigned char continue_time=0;


//循迹，通过判断三个光电对管的状态来控制小车运动
void SearchRun(void)
{
	//三路都检测到
	if(SEARCH_M_IO == BLACK_AREA && SEARCH_L_IO == BLACK_AREA && SEARCH_R_IO == BLACK_AREA)
	{
		ctrl_comm = COMM_UP;
		return;
	}
	
	if(SEARCH_R_IO == BLACK_AREA)//右
	{
		ctrl_comm = COMM_RIGHT;
	}
	else if(SEARCH_L_IO == BLACK_AREA)//左
	{
		ctrl_comm = COMM_LEFT;
	}
	else if(SEARCH_M_IO == BLACK_AREA)//中
	{
		ctrl_comm = COMM_UP;
	}
}


int main(void)
{
	u16 t;  
	u16 len;
	delay_init();
	GPIOCLKInit();
	UserLEDInit();
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2); //设置NVIC中断分组2:2位抢占优先级，2位响应优先级
	uart_init(115200);	 //串口初始化为115200
	TIM2_Init();
	MotorInit();
	CarGo();
	Delayms(200);
	CarStop();

	

	CarGo();
	Delayms(200); 
	CarStop();
	Delayms(10000); 
	printf("\r\nI`m ready\r\n\r\n");
	USART_RX_STA = 0;	
	attention = 0;
  
while(1)
{	 
	
	if(USART_RX_STA&0x8000)
	{
		CarStop();
		//0011 1111 1111 1111
		len=USART_RX_STA&0x3fff;//得到此次接收到的数据长度
		//获取专注度
		for(t=0;t<len;t++)
			{
				//获取8位中的低四位
				int low;
				low = (USART_RX_BUF[t] & 0x0f);
				//如果是一位数，专注度就是数字本身
				if (len == 1) {
					attention =low;
				//如果是两位数，专注度就是高四位*10 + 低四位
				}else if (len == 2) {
					if (t == 0) {
						attention =low * 10;
					}else {
						attention +=low;
					}
				}
			}
		printf("%d\n\r\n",attention);
		printf("\r\nI did it\n\r\n");

		USART_RX_STA=0;
		CarGo();
		//Delayms(5000); 
	}else
	{
		SearchRun();
		if(ctrl_comm_last != ctrl_comm)//指令发生变化
		{
			ctrl_comm_last = ctrl_comm;
			switch(ctrl_comm)
			{
				case COMM_UP:    CarGo();break;
				case COMM_DOWN:  CarBack();break;
				case COMM_LEFT:  CarLeft();break;
				case COMM_RIGHT: CarRight();break;
				case COMM_STOP:  CarStop();break;
				default : break;
			}
			Delayms(10);//防抖
		}
	}
	


 }
}

