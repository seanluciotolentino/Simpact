function struct2script(S, file, varargin)
%STRUCT2SCRIPT Save structure as script M-file
%
%   See also struct2tree, class2string.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    struct2script_test
    return
    
elseif nargin == 1
    file = [tempname, '.m'];
end

silent = any(strcmp('-silent', varargin));
nameIdx = strcmp('-name', varargin);
if any(nameIdx)
    name = varargin{find(nameIdx) + 1};
else
    name = inputname(1);
end

script = {
    sprintf('%% Date: %s', datestr(now))
    sprintf('%% User: %s', jproject('username'))
    sprintf('%% Creator: %s.m', mfilename)
    sprintf('%% Invoked by: %s.m', regexp(caller(1),'\w+','match','once'))
    ''
    %[inputname(1), ' = [];']   % not good for append
    };

struct2script_parse(S, name);
[ok, msg] = struct2script_write(script, file);
if ~ok
    debugMsg(msg)
end


%% parse
    function struct2script_parse(subS, Sname)
        
        for ii = 1 : numel(subS)
            
            for thisField = fieldnames(subS)'
                value = subS(ii).(thisField{1});
                %thisLine = [Sname, '.', thisField{1}, ' = '];
                if ii == 1
                    subSname = sprintf('%s.%s', Sname, thisField{1});
                else
                    subSname = sprintf('%s(%u).%s', Sname, ii, thisField{1});
                end
                thisLine = [subSname, ' = '];
                
                switch class2string(value)
                    case {'logical', 'char', 'integer', 'real'}
                        script{end + 1} = [thisLine, struct2script_this2str(value), ';'];
                        
                    case 'cell'
                        script{end + 1} = [thisLine, '{'];
                        for jj = 1 : size(value, 1)
                            cellLine = '';
                            for kk = 1 : size(value, 2)
                                cellLine = [cellLine, sprintf('\t%s', struct2script_this2str(value{jj,kk}))];
                            end
                            script{end + 1} = cellLine;
                        end
                        script{end + 1} = sprintf('\t};');
                        
                    case 'struct'
                        % call recursively
                        struct2script_parse(value, subSname)
                        
                    case 'function_handle'
                        script{end + 1} = sprintf('%s@%s;', thisLine, func2str(value));
                        
                    case 'JComponent'
                        cellLine = '{';
                        for thisItem = reshape(value.Items, 1, [])
                            cellLine = [cellLine, sprintf('\t%s', struct2script_this2str(thisItem{1}))];
                        end
                        cellLine = [cellLine, '}'];
                        script{end + 1} = sprintf('%sJComponent(''%s'', %s, %d);', thisLine, value.Type, cellLine, value.SelectedIndex);
                        
                    otherwise
                        % numeric
                        if numel(value) > 1
                            error .
                        end
                        script{end + 1} = [thisLine, num2str(value), ';'];
                end
            end
        end
    end


%% write
    function [ok, msg] = struct2script_write(script, file)
        
        ok = false;
        msg = '';
        
        %file = which(file);
        
        if exist(file, 'file') == 2
            
            msg = sprintf('%s already exists.', file);
            question = {msg, 'Do you want to replace it?'};
            if ~silent && ~strcmp('yes', questdlg(question, mfilename, 'yes', 'no', 'yes'))
                ok = true;
                return
            end
            delete(file)
        end
        
        try
            fid = fopen(file, 'w');
            % for ii = 1 : length(script)
            %     fprintf(fid, '%s\n', script{ii});
            % end
            for scriptLine = script'
                fprintf(fid, '%s\n', scriptLine{1});
            end
            fclose(fid);
            ok = true;
            
        catch errorMsg
            msg = errorMsg.message;
        end
    end


%% this2str
    function out = struct2script_this2str(this)
        
        out = '';
        thisClass = class(this);
        
        switch thisClass
            case 'logical'
                % if this
                %     out = 'true';
                % else
                %     out = 'false';
                % end
                out = mat2str(this);
                
            case 'char'
                out = ['''', strrep(this, '''', ''''''), ''''];
                
            case 'double'
                out = mat2str(this);
                
            otherwise
                if isnumeric(this)
                    out = mat2str(this, 'class');
                end
        end
    end
end


%% test
function struct2script_test

debugMsg

A.a1 = 1;
A.a2 = 'a''s';
A.a3 = true;
A.B.b1 = 4;
A.B.b2 = 'b';
A.B.b3 = false;
A.c = {
    false, 0, 'a'
    true, 1, 'b'
    };
A(2).a1 = 2;
A(2).a2 = 'a''s2';
A(2).a3 = false;
A(2).B.b1 = 8;
A(2).B.b2 = 'd';
A(2).B.b3 = false;
A(2).c = {
    false, 10, 'a a'
    true, 11, 'b b'
    };

A(2).fcnHandle = @disp;
A(2).JComp = JComponent('javax.swing.JComboBox', {'A', 'B'}, 1);

struct2script(A,[mfilename, '_test.m'], '-silent')
end

