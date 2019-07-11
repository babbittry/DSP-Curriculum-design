delete(instrfindall);  % 删除所有可见或隐藏端口
s = serial('COM6','Parity','none','BaudRate',57600,'DataBits',8,'StopBits',1);  % 定义串口

ESP= tcpip('192.168.43.12', 8086, 'NetworkRole', 'server');
fopen(ESP);

s.BytesAvailableFcnCount = 64; % 512/8=64
s.BytesAvailableFcnMode = 'byte';
s.timeout = 1;
buffer_rawdata = [];
sumA=0;
sumB=0;
j=1;
  Fs=1024; %采样频率 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%陷波滤波器%%%%%%%%%%%%%%%%%%%%%%%%%%%
wp50=[48 52]/100;
ws50=[49 51]/100;%阻带位于50HZ
rp50=3;
rs50=20;
[n50,wn50]=buttord(wp50,ws50,rp50,rs50);
[h50]=butter(n50,wn50,'stop');
figure(50)
freqz(h50,Fs);title('巴特沃斯陷波滤波器幅频曲线'); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%低通滤波%%%%%%%%%%%%%%%%%%%%%%%%%%%
  Fs=1024; %采样频率 
fp=40;fs=45; %通带截止频率，阻带截止频率 
rp=1.4;rs=1.6; %通带、阻带衰减 
wp=2*pi*fp;ws=2*pi*fs; 
[n,wn]=buttord(wp,ws,rp,rs,'s'); %’s’是确定巴特沃斯模拟滤波器阶次和3dB 截止模拟频率 
[z,P,k]=buttap(n); %设计归一化巴特沃斯模拟低通滤波器，z为极点，p为零点和k为增益 
[bp,ap]=zp2tf(z,P,k); %转换为Ha(p),bp为分子系数，ap为分母系数 
[bs,as]=lp2lp(bp,ap,wp); %Ha(p)转换为低通Ha(s)并去归一化，bs为分子系数，as为分母系数 
[hs,ws]=freqs(bs,as); %模拟滤波器的幅频响应 
[bz,az]=bilinear(bs,as,Fs); %对模拟滤波器双线性变换 
[h1,w1]=freqz(bz,az); %数字滤波器的幅频响应 
figure(1)
freqz(bz,az);title('巴特沃斯低通滤波器幅频曲线'); 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%去除基线漂移%%%%%%%%%%%%%%%%%%%%%%%%%%%
Wp51=4*2/Fs; %通带截止频率 
Ws51=0.1*2/Fs; %阻带截止频率 
devel=0.005; %通带纹波 
Rp51=20*log10((1+devel)/(1-devel)); %通带纹波系数 
Rs51=20; %阻带衰减 
[N51,Wn51]=ellipord(Wp51,Ws51,Rp51,Rs51,'s'); %求椭圆滤波器的阶次 
[b51,a51]=ellip(N51,Rp51,Rs51,Wn51,'high'); %求椭圆滤波器的系数 
[hw51,w51]=freqz(b51,a51,512); 
figure(51) 
freqz(b51,a51)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%带通滤波得到B波%%%%%%%%%%%%%%%%%%%%%%%%%%%
wlp=2*pi*14/Fs;wls=2*pi*16/Fs;
wus=2*pi*30/Fs;wup=2*pi*32/Fs;
wc=[(wlp+wls)/2/pi,(wus+wup)/2/pi];
%tr_width(wup-wus);
B=wls-wlp;
M=ceil(12*pi/B)-1;
hn=fir1(M,wc,kaiser(M+1));
wf=0: pi/511 :pi;
HK=freqz(hn,wf);
wHz=wf*511/(2*pi);%转化为Hz
figure(6)
subplot (2, 1, 1);
plot(20*log10(abs(HK)));
xlabel('频率(Hz)');ylabel('幅度');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%带通滤波得到A波%%%%%%%%%%%%%%%%%%%%%%%%%%%
wlp1=2*pi*8/Fs;wls1=2*pi*10/Fs;
wus1=2*pi*13/Fs;wup1=2*pi*15/Fs;
wc1=[(wlp1+wls1)/2/pi,(wus1+wup1)/2/pi];
%tr_width(wup-wus);
B1=wls1-wlp1;
M1=ceil(12*pi/B1)-1;
hn1=fir1(M1,wc1,kaiser(M1+1));
wf1=0: pi/511 :pi;
HK1=freqz(hn1,wf1);
wHz1=wf1*511/(2*pi);%转化为Hz
subplot (2, 1, 2);
plot(20*log10(abs(HK1)));
xlabel('频率(Hz)');ylabel('幅度');


N=1024 ;
n=0:N-1; 
try
    fopen(s);  %打开串口
catch   % 若串口打开失败，提示“串口不可获得！”
    msgbox('串口不可获得！');
    return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%读取原始数据%%%%%%%%%%%%%%%%%%%%%%%%%%%
p = 1;
while(p == 1)
    value = fread(s,64,'uint8');
    for i =1:length(value)-7
        if value(i) == hex2dec('AA')
            if value(i+1) == hex2dec('AA')
                if value(i+2) == hex2dec('04')
                    if value(i+3) == hex2dec('80')
                        if value(i+4) == hex2dec('02')
                            rawdata = bitor(bitshift(value(i+5),8),value(i+6));
                            if rawdata > 32768
                                rawdata = rawdata-65536;
                            end
                            buffer_rawdata = [buffer_rawdata;rawdata];
                            
                            g=filter(h50,1,buffer_rawdata(:,1));%去除工频
                            result =filter(b51,a51,g); %去除基线漂移
                            m=filter(bz,az, result); %低通滤波

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%画时域图%%%%%%%%%%%%%%%%%%%%%%%%%%%
 figure(2)                         
 subplot(4,1,1); 
plot(buffer_rawdata(:,1)); 
xlabel('t(s)');ylabel('mv');title('原始脑电信号波形');grid; 
 subplot(4,1,2); 
plot(m(:,1));
xlabel('t(s)');ylabel('mv');title('低通滤波、去工频、去基线漂移后的时域图形');grid; 

z=fftfilt(hn,m);% 带通滤波B波
Y1 = fft (z, Fs); 
subplot (4, 1, 3);
plot(z(:,1));
title ('带通滤波后B波信号的时域图');

z1=fftfilt(hn1,m);% 带通滤波A波
Y2 = fft (z1, Fs); 
subplot (4, 1, 4);
plot(z1(:,1));
title ('带通滤波后A波信号的时域图');



 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%画频域图%%%%%%%%%%%%%%%%%%%%%%%%%%%

mf=fft(buffer_rawdata(:,1),N); %进行频谱变换（傅里叶变换） 
mag=abs(mf); 
f=(0:length(mf)-1)*Fs/length(mf); %进行频率变换 
figure(3) 
subplot(4,1,1) 
plot(f,mag);axis([0,1500,1,20000]);grid; %画出频谱图 
xlabel('频率(HZ)');ylabel('幅值');title('脑电信号频谱图'); 

mfa=fft(m,N); %进行频谱变换（傅里叶变换） 
maga=abs(mfa); 
fa=(0:length(mfa)-1)*Fs/length(mfa); %进行频率变换 
subplot(4,1,2) 
plot(fa,maga);axis([0,100,0,20000]);grid; %画出频谱图 
xlabel('频率(HZ)');ylabel('幅值');title('低通滤波、去工频、去基线漂移后脑电信号频谱图'); 

magab=abs(Y1); 
fab=(0:length(Y1)-1)*Fs/length(Y1); %进行频率变换 
subplot(4,1,3) 
plot(fab,magab);axis([0,100,0,5000]);grid; %画出频谱图 
xlabel('频率(HZ)');ylabel('幅值');title('带通滤波后B波信号的频谱'); 


magaa=abs(Y2); 
faa=(0:length(Y2)-1)*Fs/length(Y2); %进行频率变换 
subplot(4,1,4) 
plot(faa,magaa);axis([0,100,0,5000]);grid; %画出频谱图 
xlabel('频率(HZ)');ylabel('幅值');title('带通滤波后A波信号的频谱'); 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%求专注度%%%%%%%%%%%%%%%%%%%%%%%%%%%

[r,q]=size(m);
if (r-j)>50
for t=1:50
sumB=z(j,1).^2+sumB;
sumA=z1(j,1).^2+sumA;
j=j+1;
end
a=sumA/sumB;
a=ceil(a);
if a>100
    a=a-50
end
disp(a);

a=a*3+20;
fprintf(ESP,"%d\r\n",a);
sumA=0;
sumB=0;
end                                          
                            
                        end
                    end
                end
            end
        end
    end
    
end