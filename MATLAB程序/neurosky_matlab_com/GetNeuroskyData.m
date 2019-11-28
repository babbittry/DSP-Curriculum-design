
global neurosky_scom

neurosky_Port = 'COM4';
neurosky_scom = serial(char(neurosky_Port));
%% 配置串口属性，指定其回调函数
%BaudRate 波特率
%Parity 检验位
%BytesAvailableFcnCount 获取指定字节数触发中断函数
%BytesAvailableFcnMode 中断触发事件为‘bytes-aviliable Event’
%BytesAvailableFcn 设置回调函数，并把neurosky_scom写入回调函数
%Terminator 终止符为 CR(回车) LF（换行）    'Terminator','CR/LF',...
%timeout 设置一次读写操作最大完成时间
set(neurosky_scom, 'BaudRate', 57600,...
    'Parity', 'none',...
    'BytesAvailableFcnCount', 288,...
    'BytesAvailableFcnMode', 'byte',...
    'BytesAvailableFcn', @CallBackNeuroskyCom,...  
    'timeout',1); 

try
    fopen(neurosky_scom);  %打开串口
catch   % 若串口打开失败，提示“串口不可获得！”
    msgbox('串口不可获得！');
    return;
end




