function Iout = colorThres(I)
    R = I; G = I; B = I;
    G(G>=255) = 0;
    B(B>=255) = 0;
    B(R<=0) = 255;
    B(G>180) = 0;
    Iout(:,:,1,:) = R;
    Iout(:,:,2,:) = G;
    Iout(:,:,3,:) = B;
end
