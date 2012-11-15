function [ok, msg] = popGui(handles)
%POPGUI Population Inspector
% 
%   Requires: field2str, debugMsg, Java SwingX.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    [ok, msg] = popGui_test;
    return
end

ok = false;
msg = '';


% ******* Main *******
import java.awt.GridBagConstraints
import java.awt.GridBagLayout
import java.awt.Insets
import javax.swing.ImageIcon
import javax.swing.JLabel
import javax.swing.JPanel
import javax.swing.JScrollPane
import javax.swing.JSpinner
import javax.swing.SpinnerNumberModel
import org.jdesktop.swingx.JXFrame
import org.jdesktop.swingx.JXTable
import org.jdesktop.swingx.JXTitledPanel


Skin = handles.skin();
Prefs = handles.prefs('retrieve');
SDS = handles.data();
if isempty(SDS.males.born)
    msg = 'Warning: empty population';
    return
end


% ******* Labels & Spinners *******
maleLabel = JLabel('Male');
popGui_applySkin(maleLabel)

femaleLabel = JLabel('Female');
popGui_applySkin(femaleLabel)

maleSpinner = JSpinner(SpinnerNumberModel(1, 1, SDS.number_of_males, 1));
editor = maleSpinner.getEditor();
editor.getTextField().setBackground(Skin.yellow);
popGui_applySkin(editor.getTextField())
jset(maleSpinner, 'StateChangedCallback', @popGui_callback)

femaleSpinner = ...
    JSpinner(SpinnerNumberModel(1, 1, SDS.number_of_females, 1));
editor = femaleSpinner.getEditor();
editor.getTextField().setBackground(Skin.yellow);
popGui_applySkin(editor.getTextField())
jset(femaleSpinner, 'StateChangedCallback', @popGui_callback)


% ******* Table *******
%popTable = JXTable(popC, {'A', 'B', 'C', 'D'});
popTable = JXTable();
popGui_applySkin(popTable)
popTable.setBackground(Skin.yellow)
popTable.setShowHorizontalLines(false);

[ok, msg] = popGui_update(1, 1);
if ~ok
    return
end

prefSize = popTable.getPreferredSize();
prefSize.setSize(prefSize.getWidth() + 300, prefSize.getHeight())
popTable.setPreferredSize(prefSize)


% ******* Content Panel with Layout *******
panel = JPanel(GridBagLayout());   % doesn't scroll cells like JXPanel

constraints = GridBagConstraints();
constraints.anchor = GridBagConstraints.LINE_END;
constraints.gridx = 0;
constraints.gridy = 0;
constraints.insets = Insets(4, 2, 0, 2);
constraints.weightx = 1;
panel.add(maleLabel, constraints);

constraints.anchor = GridBagConstraints.LINE_START;
constraints.gridx = 1;
panel.add(maleSpinner, constraints);

constraints.anchor = GridBagConstraints.LINE_END;
constraints.gridx = 2;
panel.add(femaleLabel, constraints);

constraints.anchor = GridBagConstraints.LINE_START;
constraints.gridx = 3;
panel.add(femaleSpinner, constraints);

constraints.anchor = GridBagConstraints.CENTER;
constraints.fill = GridBagConstraints.BOTH;
constraints.gridx = 0;
constraints.gridy = 1;
constraints.gridwidth = 4;
constraints.insets = Insets(4, 4, 4, 4);
panel.add(popTable, constraints);
%{
panel = JPanel();
layout = GroupLayout(panel);
panel.setLayout(layout);
%}

panel.setOpaque(false)


% ******* Scroll Pane *******
scrollPane = JScrollPane(panel);
scrollPane.getViewport.setOpaque(false)
scrollPane.setOpaque(false)


% ******* Titled Panel *******
titledPanel = JXTitledPanel('Population Inspector', scrollPane);
titledPanel.setBorder(Skin.border)
titledPanel.setTitleForeground(Skin.foreground)
titledPanel.setTitleFont(Skin.titleFont)
titledPanel.setTitlePainter(Skin.titlePainter)


% ******* Frame *******
handles.frame = JXFrame([Prefs.appName, ' - Population']);
handles.frame.add(titledPanel);
handles.frame.getContentPane.setBackgroundPainter(Skin.compPainter)
handles.frame.setDefaultCloseOperation(JXFrame.DISPOSE_ON_CLOSE)
handles.frame.setIconImage(ImageIcon(which(Prefs.appIcon)).getImage)
handles.frame.setLocationByPlatform(true)
handles.frame.pack()
handles.frame.setVisible(true)

ok = true;


%% update
    function [ok, msg] = popGui_update(male, female)
        
        ok = false;
        msg = '';
        
        import javax.swing.table.DefaultTableModel
        
        %popC = popGui_get(male, female);
        startDateVec = datevec(SDS.start_date);
        
        [maleC, maleCount] = popGui_update_get(SDS.males, male);
        [femaleC, femaleCount] = popGui_update_get(SDS.females, female);
        
        popC = cell(max(maleCount, femaleCount), 4);
        popC(1:maleCount, 1:2) = maleC;
        popC(1:femaleCount, 3:4) = femaleC;
        
        
        % ******* Add Relations *******
        maleRelIdx = SDS.relations.ID(:,SDS.index.male) == male;
        maleRel = SDS.relations.ID(maleRelIdx,SDS.index.female);
        maleRelStr = sprintf('%g, ', unique(maleRel));
        femaleRelIdx = SDS.relations.ID(:,SDS.index.female) == female;
        femaleRel = SDS.relations.ID(femaleRelIdx,SDS.index.male);
        femaleRelStr = sprintf('%g, ', unique(femaleRel));
        popC(end + 1, :) = {
            'partner(s)', maleRelStr(1:end - 2), ...
            'partner(s)', femaleRelStr(1:end - 2)
            };
        
        
        % ******* Add Children *******
        maleSonsStr = sprintf('%g, ', find(SDS.males.father == male));
        femaleSonsStr = sprintf('%g, ', find(SDS.males.mother == female));
        popC(end + 1, :) = {
            'son(s)', maleSonsStr(1:end - 2), ...
            'son(s)', femaleSonsStr(1:end - 2)
            };
        
        maleDaughters = sprintf('%g, ', find(SDS.females.father == male));
        femaleDaughters = sprintf('%g, ', find(SDS.females.mother == female));
        popC(end + 1, :) = {
            'daughter(s)', maleDaughters(1:end - 2), ...
            'daughter(s)', femaleDaughters(1:end - 2)
            };
        
        
        popTable.setModel(DefaultTableModel(popC, {'A', 'B', 'C', 'D'}))
        popTable.doLayout();
        
        ok = true;
        
        
        %% update_get
        function [thisC, thisCount] = popGui_update_get(S, idx)
            
            thisC = fieldnames(S);
            thisCount = numel(thisC);
            
            for ii = 1 : thisCount
                values = S.(thisC{ii, 1});
                thisC{ii, 1} = field2str(thisC{ii, 1});
                if isempty(values)
                    continue
                end
                value = values(idx);
                if isnan(value)
                    value = 'unknown';
                end
                
                switch class(value)
                    case SDS.integer
                        % IDs
                        if value == 0
                            value = 'none';
                        end
                        
                    case SDS.float
                        % years w.r.t. start date
                        value = datestr(datenum(startDateVec + [
                            value 0 0 0 0 0
                            ]));
                        
                    case 'logical'
                        if value
                            value = 'yes';
                        else
                            value = 'no';
                        end
                end
                thisC{ii, 2} = value;
            end
        end
    end


%% callback
    function popGui_callback(~, ~)
        
        male = maleSpinner.getValue();
        female = femaleSpinner.getValue();
        
        [ok, msg] = popGui_update(male, female);
    end


%% applySkin
    function popGui_applySkin(obj)
        
        obj.setFont(Skin.font)
        obj.setForeground(Skin.foreground)
        obj.setFont(Skin.font)
        obj.setForeground(Skin.foreground)
    end


%%
    function popGui_
        
    end
end


%% test
function [ok, msg] = popGui_test

ok = false;
msg = '';

debugMsg

ok = true;
end
