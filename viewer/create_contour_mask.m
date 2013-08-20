function [ contour_mask ] = create_contour_mask( cell_eddies, ssh )
    contour_mask = false(size(ssh,1), size(ssh,2), length(cell_eddies));
    parfor i = 1:length(cell_eddies)
        slice = false(size(ssh));
        for j = 1:length(cell_eddies{i})
            slice(cell_eddies{i}(j).Stats.PixelIdxList) = true;
        end
        contour_mask(:,:,i) = bwperim(slice);
    end
    
    if nargout < 1
        save('contours', 'contour_mask', '-v7.3');
    end
end