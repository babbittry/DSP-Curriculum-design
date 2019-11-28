function CallBackCom(obj,event)
%CallBackCom 串口回调函数
%
global neurosky_scom
global buffer_attention_data
global attention_data
% try
neurosky_data = fread(neurosky_scom,288,'uint8');  % uint8 8 位无符号整数 1字节

for i = 1:length(neurosky_data)-32
    if neurosky_data(i) == hex2dec('AA')
        if neurosky_data(i+1) == hex2dec('AA')
            if neurosky_data(i+2) == hex2dec('20')
                if neurosky_data(i+3) == hex2dec('02')
                    if neurosky_data(i+5) == hex2dec('83')
                        if neurosky_data(i+6) == hex2dec('18')
                            if neurosky_data(i+31) == hex2dec('04')
                                attention_data = neurosky_data(i+32);  %%专注度数值
                                buffer_attention_data = [buffer_attention_data(2:end); attention_data];
                                disp(attention_data);
                                break;
                            end
                        end
                    end
                end
            end
        end
    end
end
% catch
%     CloseNeuroskyCom;
% end

end

