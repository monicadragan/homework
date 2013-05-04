function [red, green, blue] = read_BMP(filename)
    fin = fopen(filename, "rb");
    [hdr, count] = fread(fin, 54, "uchar=>double", 0,"native");
    
    width = hdr(19) + hdr(20) * 256 + hdr(21) * 65536 + hdr(22) * 16777216;
    height = hdr(23) + hdr(24) * 256 + hdr(25) * 65536 + hdr(26) * 16777216;
    
    [data, count] = fread(fin, [3 * width, height ], "uchar=>double",0,"native");
    
    blue  = data'(:, 1:3:3*width);
    green = data'(:, 2:3:3*width);
    red   = data'(:, 3:3:3*width);
    fclose(fin);    
endfunction
