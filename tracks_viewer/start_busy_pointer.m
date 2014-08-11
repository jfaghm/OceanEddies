function [ old_pointer ] = start_busy_pointer( hdls )
%START_BUSY_POINTER Change current pointer of current figure to busy pointer before computation begins

old_pointer = get(hdls.fig, 'pointer');
set(hdls.fig, 'pointer', 'watch');
drawnow;

end

