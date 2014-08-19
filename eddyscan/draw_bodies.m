function [ canvas ] = draw_bodies( eddies )
%DRAW_BODIES Will create a matrix that has 1s where the eddy bodies are.
%Useful for debugging/interactive work.
    canvas = zeros(721, 1440, 'uint8');
    
    for i = 1:length(eddies)
        canvas(eddies(i).Stats.PixelIdxList) = 1;
    end
end

