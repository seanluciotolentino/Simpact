function [ok, msg] = exportCSV_print(csvFile, dataC)
        
        ok = false;
        msg = ''; %#ok<NASGU>
        
        try
            fid = fopen(csvFile, 'w', 'n', 'UTF-8');
            fprintf(fid, '%s', dataC{1, 1});
            fprintf(fid, ', %s', dataC{1, 2:end});
            fprintf(fid, '\n');
            for ii = 2 : size(dataC, 1)
                fprintf(fid, '%g', dataC{ii, 1});
                fprintf(fid, ', %g', dataC{ii, 2:end});
                fprintf(fid, '\n');
            end
            status = fclose(fid);
        catch ME
            msg = ME.message;
            return
        end
        
        ok = status == 0;
        msg = ['CSV file stored as ', csvFile];
    end