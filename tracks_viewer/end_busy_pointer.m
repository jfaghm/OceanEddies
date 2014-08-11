function end_busy_pointer( hdls, old_pointer )
%END_BUSY_POINTER Change the busy pointer back to the old pointer before the computation begins

set(hdls.fig, 'pointer', old_pointer);

end

