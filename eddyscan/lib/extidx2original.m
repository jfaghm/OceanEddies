function [idx, row, col] = extidx2original(idx)
    SIZ=[721 1440];
    SIZ_EXT=SIZ + [0 400];
    
    [row, col] = ind2sub(SIZ_EXT,idx);
    offright = col > 1640;
    offleft = col < 201;
    notoff = ~(offleft | offright);
    col(offright)=col(offright)-1640;
    col(offleft)=col(offleft)+1240;
    col(notoff)=col(notoff)-200;
    idx = sub2ind(SIZ,row,col);
end