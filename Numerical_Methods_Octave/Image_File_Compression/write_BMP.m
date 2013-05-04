function write_BMP(filename, red, green, blue)
    hdr = [ 66, 77, 54, 0, 12, 0, 0, 0, 0, 0, 54, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 117, 10, 0, 0, 117, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
                
    fout = fopen(filename, "wb");
    
    [height, width]  = size(red);
    hdr( 19) = mod(width, 256);
    hdr( 20) = floor(width/ 256);
    
    hdr( 23) = mod(height, 256);
    hdr( 24) = floor(height/ 256);
    
    count = fwrite(fout, hdr, "uchar", 0,"native");

    data = zeros(height , 3 * width);
    data(:, 1:3:3*width) = blue;
    data(:, 2:3:3*width) = green;
    data(:, 3:3:3*width) = red;
    count = fwrite(fout, data', "uchar",0,"native");    

    fclose(fout);    
endfunction
