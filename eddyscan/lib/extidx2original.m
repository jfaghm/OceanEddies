function [idx, row, col] = extidx2original(idx, original_size, extended_size)
%EXTIDX2ORIGINAL Convert from extended indexes to original indexes
    [row, col] = ind2sub(extended_size,idx);
    
    offright = col > (extended_size(2) + original_size(2)) / 2;
    offleft = col < (extended_size(2) - original_size(2)) / 2 + 1;
    notoff = ~(offleft | offright);
    col(offright)=col(offright) - (extended_size(2) + original_size(2)) / 2;
    col(offleft) = col(offleft) + original_size(2) - (extended_size(2) - original_size(2)) / 2;
    col(notoff)=col(notoff) - (extended_size(2) - original_size(2)) / 2;
    
    idx = sub2ind(original_size,row,col);
end