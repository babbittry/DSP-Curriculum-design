global neurosky_scom

try
fclose(neurosky_scom);
catch err
    msgbox('´®¿Ú¹Ø±ÕÊ§°Ü£¡');
    return
end
delete(neurosky_scom);