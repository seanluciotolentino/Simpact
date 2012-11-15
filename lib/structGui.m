function structGui(Prefs)
%STRUCTGUI Java-based MATLAB structure interface/editor
%
%   Features:
% * Read, edit, store data file (M-file or MAT-file)
% * Dump data structure to MATLAB base workspace
% * Recent files list in File menu
% * Open with last data file
% * Store settings in user folder (MAT-file)
% * Tree context menus augmented by model function
% * Remove fields implemented by model function
% 
%   Development:
% * respond to table edit
%
%   Requires: JComponent, jproject, jset, struct2tree, treepath2struct,
%   caller, backup, field2str, SwingX, isme.

% Copyright 2009-2011 by Hummeling Engineering (www.hummeling.com)

% Swing Component Keystroke Assignments:
%http://java.sun.com/j2se/1.4.2/docs/api/javax/swing/doc-files/Key-Index.html

if nargin == 0
    switch jproject('username')
        case 'RHummeling'
            % Leiden
            ndsGui
        case 'ralph'
            % Lisse
            SIMPACT
    end
    return
end

import java.awt.BorderLayout
import java.awt.CardLayout
import java.awt.Color
import java.awt.Dimension
import java.awt.Font
import java.awt.GradientPaint
import java.awt.GridBagLayout
import javax.swing.ImageIcon
import javax.swing.JFileChooser
import javax.swing.JPanel
import javax.swing.JScrollPane
%import javax.swing.JSplitPane
import org.jdesktop.swingx.JXFrame
import org.jdesktop.swingx.JXMultiSplitPane
import org.jdesktop.swingx.JXPanel
import org.jdesktop.swingx.JXTitledPanel
import org.jdesktop.swingx.MultiSplitLayout
import org.jdesktop.swingx.painter.CompoundPainter
import org.jdesktop.swingx.painter.MattePainter
import org.jdesktop.swingx.painter.PinstripePainter


% ******* Handles *******
handles = struct('prefs', @structGui_preferences, ...
    'data', @structGui_data, 'update', @structGui_update, ...
    'msg', @structGui_msg, 'fail', @structGui_fail, ...
    'state', @structGui_state, 'progress', @structGui_progress, ...
    'units', @structGui_units, 'skin', @structGui_skin);


% ******* Preferences *******
S = [];
P.caller = caller(1);
Prefs = structGui_preferences('retrieve');
P.logFile = fullfile(jproject('folder'), '~archive', ...
    sprintf('%s.%s.log', Prefs.appName, datestr(now,30)));
P.state = 'ready';
P.tree = true;


% ******* File Chooser *******
fileChooser = JFileChooser(jproject('folder'));
fileChooser.setAcceptAllFileFilterUsed(false)


% ******* Drag n Drop *******
%transferHandler = javax.swing.TransferHandler('copy');

%handles.treeScrollPane.setDragEnabled(true)
%handles.treeScrollPane.setTransferHandler(transferHandler)
%panel = JPanel();
%panel = org.jdesktop.swingx.JXPanel();
%pane = org.jdesktop.swingx.JXCollapsiblePane();
%pane.setContentPane(panel);
%panel.setTitlePainter(RectanglePainter(Color.MAGENTA, Color.MAGENTA))
%panel = JPanel(GridBagLayout());
%xPanel = org.jdesktop.swingx.JXPanel();
%xPanel.add(JScrollPane(panel));
%panelTitle = org.jdesktop.swingx.JXTitledPanel('', JScrollPane(panel,
%JScrollPane.VERTICAL_SCROLLBAR_ALWAYS,
%JScrollPane.HORIZONTAL_SCROLLBAR_ALWAYS));
%contentScrollPane.setViewportBorder(border)
%panel.setBorder(border)
%panel.setTitle('asdfasfd')

%treePanel = JXPanel();
%treePanel.setBackgroundPainter(gradientPainter)
%treePanel.add(handles.treeScrollPane);


% ******* Skin *******
Skin.font = Font.decode(Prefs.font);
%Skin.font.setSize(Skin.font.getSize() + 2);
%Skin.inputFont = Font.decode('DialogInput');
Skin.inputFont = Font('DialogInput', Font.PLAIN, Skin.font.getSize + 2);
Skin.titleFont = Font(Prefs.font, Font.PLAIN, Skin.font.getSize + 8);
%Skin.gray = Color(14/15, 14/15, 14/15);
Skin.gray = Color(13/15, 13/15, 13/15);
Skin.blue = Color(11/15, 12/15, 13/15);
Skin.yellow = Color(1, 1, 14/15);
Skin.foreground = Color(4/15, 5/15, 6/15);
Skin.error = Color(12/15, 0, 0);
Skin.warning = Color(12/15, 6/15, 0);
Skin.note = Color(0, 6/15, 12/15);
Skin.ok = Color(0, 6/15, 0);
Skin.titlePainter = CompoundPainter([
    MattePainter(GradientPaint(1, 1, Skin.blue, 1, 15, Skin.yellow))
    PinstripePainter(GradientPaint(1, 1, Skin.blue, 20, 20, Skin.yellow))
    ]);
Skin.compPainter = CompoundPainter([
    MattePainter(Skin.blue)
    PinstripePainter(GradientPaint(1, 1, Color(12/15, 13/15, 14/15), ...
    300, 400, Color(10/15, 11/15, 12/15)))
    ]);
Skin.border = javax.swing.BorderFactory.createEtchedBorder(...
    javax.swing.border.EtchedBorder.LOWERED);
handles.skin = @structGui_skin;


% ******* Data Tree *******
handles.treeScrollPane = JScrollPane();
handles.treeScrollPane.getViewport.setOpaque(false)
handles.treeScrollPane.setBorder(Skin.border)
handles.treeScrollPane.setOpaque(false)
handles.treeScrollPane.setViewportBorder([])


% ******* Content Panel *******
% JXFrame> JXMultiSplitPane> JXTitledPanel> JScrollPane> JPanel> GridBagLayout
panel = JPanel(GridBagLayout());   % doesn't scroll cells like JXPanel
panel.setOpaque(false)

contentScrollPane = JScrollPane(panel);
contentScrollPane.getViewport.setOpaque(false)
contentScrollPane.setOpaque(false)
% jset(contentScrollPane, 'PropertyChangeCallback', @structGui_drawNow)
% jset(contentScrollPane, 'VetoableChangeCallback', @structGui_drawNow)
% jset(contentScrollPane, 'ComponentMovedCallback', @structGui_drawNow)
contentPanel = JXTitledPanel('', contentScrollPane);
contentPanel.setBorder(Skin.border)
contentPanel.setTitleForeground(Skin.foreground)
contentPanel.setTitleFont(Skin.titleFont)
contentPanel.setTitlePainter(Skin.titlePainter)


% ******* Message Logging *******
handles.frame = JXFrame(Prefs.appName);
handles.frame.add(structGui_makeToolBar, BorderLayout.PAGE_START);
structGui_makeStatusBar
structGui_makeEditorPane
messagePane = JScrollPane(handles.editorPane);
messagePane.setBorder(Skin.border)


layout = '(ROW(LEAF name=tree weight=0.0)(LEAF name=contents weight=0.1))';
%ERR multiSplitLayout = MultiSplitLayout.parseModel(layout);
multiSplitLayout = MultiSplitLayout(MultiSplitLayout.parseModel(layout));
multiSplitLayout.setFloatingDividers(false)
%multiSplitLayout.setLayoutByWeight(true)
splitPane = JXMultiSplitPane(multiSplitLayout);     % uses MultiSplitLayout
splitPane.add('tree', handles.treeScrollPane);
%splitPane.add('contents', contentScrollPane);
splitPane.add('contents', contentPanel);
%splitPane.add('messages', messagePane);
splitPane.setOpaque(false)


% ******* Card Layout *******
handles.cards = JPanel(CardLayout());
handles.cards.add(splitPane, 'Data');
handles.cards.add(messagePane, 'Messages');
handles.cards.setOpaque(false)


% ******* Frame *******
%handles.frame.add(splitPane, BorderLayout.CENTER);
handles.frame.add(handles.cards, BorderLayout.CENTER);
handles.frame.add(handles.statusBar, BorderLayout.PAGE_END);
handles.frame.getContentPane.setBackgroundPainter(Skin.compPainter)
handles.frame.setDefaultCloseOperation(JXFrame.DISPOSE_ON_CLOSE)
handles.frame.setIconImage(ImageIcon(which(Prefs.appIcon)).getImage)
handles.frame.setJMenuBar(structGui_makeMenuBar)
handles.frame.setLocationByPlatform(true)
handles.frame.setSize(Dimension(Prefs.lastDimension{:}))


% ******* User *******
if isdeployed
    structGui_msg('Deployed standalone %s.\n', Prefs.appName)
else
    structGui_msg(help(which(P.caller)))    % only works when not deployed
end

if ~Prefs.debug && ~isempty(Prefs.recentFiles) && ...
        exist(Prefs.recentFiles{1}, 'file') == 2
    structGui_file('openThis', Prefs.recentFiles{1});
else
    structGui_file('new')       % structGui_file_new
    %structGui_msg -clear
end


%handles.frame.pack()
if Prefs.expandTree
    %structGui_view expand
else
    structGui_view collapse
end

handles.frame.setVisible(true)
%awtinvoke(handles.frame, 'setVisible(Z)', true);    % memory leak issue?

% ******* Debugging *******
% if Prefs.debug
%     base(handles)
% end


%% makeMenuBar
    function menuBar = structGui_makeMenuBar
        
        menuBar = javax.swing.JMenuBar();
        
        
        % ******* File Menu *******
        menuBar.add(structGui_file('menu'));
        
        
        % ******* User Menus *******
        for thisMenu = {Prefs.menu{:}}
            menuBar.add(thisMenu{1}(@structGui_handles));
        end
        
        
        % ******* View Menu *******
        menuBar.add(structGui_view('menu'));
        
        
        % ******* Help Menu *******
        menuBar.add(structGui_help('menu'));
    end


%% makeToolBar
    function toolBar = structGui_makeToolBar
        
        import javax.swing.Box
        import javax.swing.BoxLayout
        import javax.swing.ImageIcon
        import javax.swing.JButton
        import javax.swing.JProgressBar
        import javax.swing.JToolBar
        
        toolBar = JToolBar('Controls', JToolBar.HORIZONTAL);
        %toolBar.add(Box.createHorizontalStrut(10));
        toolBar.setLayout(BoxLayout(toolBar, BoxLayout.LINE_AXIS))
        toolBar.setOpaque(false)
        jset(toolBar, ...
            'HierarchyChangedCallback', @structGui_makeToolBar_move)
        
        if ~isempty(Prefs.runFcn)
            button = JButton(ImageIcon(which('stop.png')));
            button.setActionCommand('stop')
            button.setAlignmentX(.5)
            button.setBorderPainted(false)
            button.setContentAreaFilled(false)
            button.setFocusable(false)
            button.setPressedIcon(ImageIcon(which('stopP.png')))
            button.setRolloverIcon(ImageIcon(which('stopR.png')))
            button.setToolTipText('Stop simulation')
            jset(button, 'ActionPerformedCallback', @structGui_callback)
            toolBar.add(button);
            
            button = JButton(ImageIcon(which('pause.png')));
            button.setActionCommand('pause')
            button.setAlignmentX(.5)
            button.setBorderPainted(false)
            button.setContentAreaFilled(false)
            button.setFocusable(false)
            button.setPressedIcon(ImageIcon(which('pauseP.png')))
            button.setRolloverIcon(ImageIcon(which('pauseR.png')))
            button.setToolTipText('Pause or continue simulation')
            jset(button, 'ActionPerformedCallback', @structGui_callback)
            toolBar.add(button);
            
            button = JButton(ImageIcon(which('start.png')));
            button.setActionCommand('start')
            button.setAlignmentX(.5)
            button.setBorderPainted(false)
            button.setContentAreaFilled(false)
            button.setFocusable(false)
            button.setPressedIcon(ImageIcon(which('startP.png')))
            button.setRolloverIcon(ImageIcon(which('startR.png')))
            button.setToolTipText('Start simulation')
            jset(button, 'ActionPerformedCallback', @structGui_callback)
            toolBar.add(button);
        end
        
        %toolBar.addSeparator()
        
        handles.progressBar = JProgressBar(0, 1e3);
        handles.progressBar.setAlignmentX(.5)
        handles.progressBar.setFont(Skin.font)
        toolBar.add(handles.progressBar);
        
        %toolBar.addSeparator()
        
        
        %% makeToolBar_move
        function structGui_makeToolBar_move(~, ~)
            
            if ~strcmp(get(toolBar.getTopLevelAncestor, 'Type'), ...
                    'javax.swing.JXFrame')
                % toolbar in its own window
                toolBar.setOrientation(toolBar.HORIZONTAL)
            end
            
            handles.progressBar.setOrientation(toolBar.getOrientation)
        end
    end


%% makeEditorPane
    function structGui_makeEditorPane
        
        import java.awt.Color
        import java.awt.Font
        import javax.swing.JEditorPane
        % import javax.swing.text.SimpleAttributeSet
        % import javax.swing.text.StyleConstants
        
        % att = SimpleAttributeSet();
        % StyleConstants.setBackground(att, Skin.blue)
        
        %editorPane = JEditorPane('text/html', '');
        %editorPane = JEditorPane('text/plain', '');
        handles.editorPane = JEditorPane('text/rtf', '');
        handles.editorPane.setEditable(false)
        handles.editorPane.setFont(Skin.font)
        jset(handles.editorPane, 'MouseClickedCallback', @structGui_callback)
        
        [~, logFile, logExt] = fileparts(P.logFile);
        structGui_log(sprintf(' ******* %s LOG FILE - %s%s *******\n\n', ...
            Prefs.appName, logFile, logExt))
    end


%% makeStatusBar
    function structGui_makeStatusBar
        
        import java.awt.event.KeyEvent
        import javax.swing.ButtonGroup
        import javax.swing.JLabel
        import javax.swing.JToggleButton
        import org.jdesktop.swingx.JXStatusBar
        %import org.jdesktop.swingx.JXStatusBar.Constraint
        
        handles.statusBar = JXStatusBar();
        handles.statusBar.setOpaque(false)
        
        buttonGroup = ButtonGroup();
        
        button = JToggleButton('Data', true);
        button.setFont(Skin.font)
        button.setForeground(Skin.foreground)
        button.setMnemonic(KeyEvent.VK_F1)
        button.setOpaque(false)
        jset(button, 'ActionPerformedCallback', @structGui_callback)
        buttonGroup.add(button);
        handles.statusBar.add(button);
        handles.dataButton = button;
        
        button = JToggleButton('Messages', false);
        button.setFont(Skin.font)
        button.setForeground(Skin.foreground)
        button.setMnemonic(KeyEvent.VK_F2)
        button.setOpaque(false)
        jset(button, 'ActionPerformedCallback', @structGui_callback)
        buttonGroup.add(button);
        handles.statusBar.add(button);
        %ERR statusBar.add(buttonGroup);
        handles.messagesButton = button;
        
        statusLabel = JLabel('Ready');
        statusLabel.setFont(Skin.font)
        % c1 = org.jdesktop.swingx.JXStatusBar.Constraint();
        % c1.setFixedWidth(100);
        % statusBar.add(statusLabel, c1);
        handles.statusBar.add(statusLabel);
        handles.statusBar.setOpaque(false)
    end


%% callback
% structGui_select_component_callback
    function structGui_callback(hObject, eventData, varargin)
        
        import java.io.File
        
        object = eventData.getSource;
        objectType = class(object);
        actionCommand = '';
        if ismethod(object, 'getActionCommand')
            actionCommand = char(object.getActionCommand());
        end
        name = '';
        if ismethod(object, 'getName')
            name = char(object.getName());
        end
        
        switch objectType
            case 'javax.swing.JButton'
                switch actionCommand
                    case 'stop'
                        Prefs.runFcn('stop', handles);
                        structGui_state ready
                        
                    case 'pause'
                        Prefs.runFcn('pause', handles);
                        %structGui_state ready
                        
                    case 'start'
                        structGui_state busy
                        %handles.msg('-clear')
                        Prefs.runFcn('start', handles);
                        structGui_state ready
                        
                    otherwise
                        % ******* Folder *******
                        %thisDir = File(eval(strrep(actionCommand,
                        %Prefs.dataName, 'S')));
                        thisDir = File(evalstruct(S, actionCommand));
                        while ~isnumeric(thisDir) && ~thisDir.exists()
                            thisDir = thisDir.getParentFile();
                        end
                        if isnumeric(thisDir)
                            % fall-back to project folder
                            thisDir = jproject('folder');
                        end
                        fileChooser.resetChoosableFileFilters()
                        fileChooser.setCurrentDirectory(thisDir)
                        fileChooser.setDialogTitle([
                            'Select directory for ', actionCommand
                            ])
                        fileChooser.setFileSelectionMode(...
                            fileChooser.DIRECTORIES_ONLY)
                        if fileChooser.showOpenDialog(handles.frame) ~= ...
                                fileChooser.APPROVE_OPTION
                            return
                        end
                        folder = char(fileChooser.getSelectedFile());
                        
                        structGui_edit(folder, actionCommand)
                        structGui_update(S)     % refresh
                end
                
            case 'javax.swing.JCheckBox'
                structGui_edit(get(hObject,'Selected'), name)
                
            case 'javax.swing.JComboBox'
                structGui_edit(object.getSelectedIndex(), name)
                
            case 'javax.swing.JEditorPane'
                structGui_popupMenu(hObject, eventData)
                
            case 'javax.swing.JList'
                %2BD structGui_edit(eventData.getKeyChar, ...
                % sprintf('%s(%d)', name, object.getSelectedIndex() + 1))
                
            case {'javax.swing.JTextArea', 'javax.swing.JTextField'}
                structGui_edit(get(hObject, 'Text'), name)
                
            case 'javax.swing.JToggleButton'
                handles.cards.getLayout.show(handles.cards, actionCommand)
                switch actionCommand
                    case 'Data'
                        handles.viewData.setSelected(true)
                    case 'Messages'
                        handles.viewMessages.setSelected(true)
                end
                
            case 'javax.swing.JTree'
                if eventData.getButton == eventData.BUTTON1
                    structGui_tree
                    
                elseif eventData.getButton == eventData.BUTTON3
                    structGui_popupMenu(hObject, eventData)
                end
                
            case 'javax.swing.table.DefaultTableModel'
                row = eventData.getFirstRow();
                column = eventData.getColumn();
                table = varargin{1};
                Schar = sprintf('%s{%d,%d}', ...
                    char(table.getName()), row + 2, column + 1);
                structGui_edit(object.getValueAt(row, column), Schar)
                
            case 'javax.swing.tree.DefaultTreeSelectionModel'
                %EXC structGui_state busy
                structGui_select(eventData.getPath)
                %EXC structGui_state ready
                
            case 'org.jdesktop.swingx.JXDatePicker'
                newDate = get(hObject, 'Date');
                newDateStr = datestr(datenum(newDate.getYear() + 1900, ...
                    newDate.getMonth() + 1, newDate.getDate()), 1);
                structGui_edit(newDateStr, name)
                
            otherwise
                debugMsg(objectType)
        end
    end


%% popupMenu
    function structGui_popupMenu(hObject, eventData)
        
        import javax.swing.JCheckBoxMenuItem
        import javax.swing.JMenuItem
        import javax.swing.JPopupMenu
        
        if eventData.getButton ~= eventData.BUTTON3
            % only respond to right-clicks (PC specific)
            return
        end
        
        x = eventData.getX();
        y = eventData.getY();
        component = eventData.getComponent();
        
        switch class(eventData.getSource())
            case 'javax.swing.JEditorPane'
                popupMenu = JPopupMenu();
                menuItem = JCheckBoxMenuItem('Log Messages');
                menuItem.setState(Prefs.logMessages)
                menuItem.setToolTipText('Save messages to log file')
                jset(menuItem, ...
                    'ActionPerformedCallback', @structGui_popupMenu_log)
                popupMenu.add(menuItem);
                
                menuItem = JMenuItem('Clear Log');
                menuItem.setToolTipText('Clear the message log')
                jset(menuItem, ...
                    'ActionPerformedCallback', @structGui_popupMenu_log)
                popupMenu.add(menuItem);
                popupMenu.show(component, x, y)
                
            case 'javax.swing.JTree'
                treePath = component.getPathForLocation(x, y);
                Schar = treepath2struct(treePath);
                
                popupMenu = JPopupMenu();
                Prefs.dataFcn('popupMenu', Schar, S, popupMenu, handles)
                
                if isempty(regexp(char(treePath), Prefs.final, 'once'))
                    if popupMenu.getComponentCount > 0
                        popupMenu.addSeparator()
                    end
                    structGui_popupMenu_move
                end
                
                if popupMenu.getComponentCount == 0
                    return
                end
                popupMenu.show(component, x, y)
        end
        
        
        %% popupMenu_log
        function structGui_popupMenu_log(hObject, eventData)
            
            switch char(eventData.getActionCommand())
                case 'Clear Log'
                    structGui_msg -clear
                    
                case 'Log Messages'
                    Prefs.logMessages = ~Prefs.logMessages;
                    structGui_preferences('store', Prefs)
                    if Prefs.logMessages
                        msg = 'These messages will be logged\n';
                    else
                        msg = 'These messages will not be logged\n';
                    end
                    structGui_msg(msg)
            end
        end
        
        
        %% popupMenu_move
        function structGui_popupMenu_move
            
            import javax.swing.JMenuItem
            
            enumC = regexp(Schar, '\.(\w+)\(?(\d*)\)?', 'tokens');
            if isempty(enumC) || isempty(enumC{end}{2})
                return
            end
            subC = regexp(Schar, '(.+)\(\d+\)', 'tokens', 'once');
            subS = eval(['S', regexp(subC{1}, '\..*', 'match', 'once')]);
            
            level = numel(enumC);
            eC = [enumC{:}];
            for ii = 2*(1 : level)
                if isempty(eC{ii})
                    eC{ii} = '1';
                end
                eC{ii} = {str2double(eC{ii})};
            end
            
            srcIdx = eC{end}{1};
            
            if srcIdx > 1
                menuItem = JMenuItem(capitalise([
                    'Move this ', eC{end - 1}, ' up'
                    ]));
                jset(menuItem, 'ActionPerformedCallback', ...
                    {@structGui_popupMenu_move_callback, srcIdx - 1})
                popupMenu.add(menuItem);
            end
            
            if srcIdx < numel(subS)
                menuItem = JMenuItem(capitalise([
                    'Move this ', eC{end - 1}, ' down'
                    ]));
                jset(menuItem, 'ActionPerformedCallback', ...
                    {@structGui_popupMenu_move_callback, srcIdx + 1});
                popupMenu.add(menuItem);
            end
            
            
            %% popupMenu_move_callback
            function structGui_popupMenu_move_callback(arg1, arg2, dstIdx)
                
                S0 = S;
                
                subType = {'.' '()'};
                srcSubC = [
                    subType(repmat([1 2], 1, level))
                    eC
                    ];
                dstSubC = srcSubC;
                dstSubC{end} = {dstIdx};
                
                srcS = subsref(S0, substruct(srcSubC{:}));
                subsasgn(S, substruct(dstSubC{:}), srcS)
                
                srcS = subsref(S0, substruct(dstSubC{:}));
                subsasgn(S, substruct(srcSubC{:}), srcS)
                
                clear S0
                structGui_update(S)
            end
        end
    end


%% edit
    function structGui_edit(value, Schar)
        
        Schar = ['S', regexp(Schar, '\..*', 'match', 'once')];
        % Schar = regexprep(Schar, '([^)])\.', '$1(1).');
        % [subS, msg] = evalstruct(S, Schar);
        % if ~isempty(msg)
        %     return
        % end
        try
            subS = eval(Schar);
            
            switch class2string(subS)
                case 'logical'
                    if value
                        eval(sprintf('%s = true;', Schar))
                    else
                        eval(sprintf('%s = false;', Schar))
                    end
                    
                case 'char'
                    if strcmp(subS, value)
                        return
                    end
                    eval(sprintf('%s = ''%s'';', Schar, value))
                    
                case {'integer', 'real'}
                    if isempty(value)
                        value = '[]';
                    elseif value(1) == '.'
                        value = ['0', value];
                    end
                    eval(sprintf('%s = %s;', Schar, value))
                    
                case 'cell'
                    % TBD: return on non-text content
                    eval(sprintf('%s = {''''};', Schar))
                    valueC = regexp(strrep(value, '''', ''''''), ...
                        '[^\n]*', 'match');
                    for ii = 1 : numel(valueC)
%structGui_edit(valueC{ii}, sprintf('%s{%d,1}', Schar, ii))
                        eval(sprintf('%s{%d,1} = ''%s'';', ...
                            Schar, ii, valueC{ii}))
                    end
                    
                case 'JComponent'
                    eval(sprintf('%s.SelectedIndex = %d;', ...
                        Schar, value + 1))
                    
                otherwise
                    debugMsg 'Not implemented yet'
            end
            
            structGui_changed
        catch
        end
    end


%% title
    function structGui_title(dataFile)
        
        titleString = Prefs.appName;
        if nargin
            titleString = sprintf('%s - %s', Prefs.appName, dataFile);
        end
        handles.frame.setTitle(titleString)
    end


%% file
    function varargout = structGui_file(action, varargin)
        
        switch action
            case 'menu'
                varargout{1} = structGui_file_menu;
                return
        end
        
        import java.io.File
        import javax.swing.ImageIcon
        import javax.swing.JOptionPane
        
        fileFilter = FileNameExtensionFilter(...
            [Prefs.appName, ' data files (*.m, *.mat)'], {'m', 'mat'});
        fileChooser.resetChoosableFileFilters()
        fileChooser.setFileFilter(fileFilter)
        fileChooser.setFileSelectionMode(fileChooser.FILES_ONLY)
        
        
        % ******* Check Data State *******
        frameTitle = char(handles.frame.getTitle());
        
        if exist('S', 'var') == 1 && isstruct(S)
            dataFile = Prefs.dataFcn('dataFile', S);
            
            if ~strcmp(action, 'save') && strcmp(frameTitle(end), '*')
                [folder, file, ext] = fileparts(dataFile);
                
                choice = JOptionPane.showConfirmDialog(handles.frame, ...
                    sprintf('Save changes to %s%s?', file, ext), ...
                    Prefs.appName, JOptionPane.YES_NO_CANCEL_OPTION, ...
                    JOptionPane.QUESTION_MESSAGE, ...
                    ImageIcon(which(Prefs.appIcon)));
                
                if choice == JOptionPane.YES_OPTION
                    structGui_file save
                    
                elseif choice == JOptionPane.NO_OPTION
                    
                else
                    % Cancel or close button
                    return
                end
                drawnow
            end
        end
        
        
        % ******* Perform Action *******
        switch action
            case 'new'
                structGui_file_new
                
            case 'open'
                fileChooser.setCurrentDirectory(File(jproject('folder')))
                fileChooser.setDialogTitle(...
                    sprintf('Open %s data file', Prefs.appName))
                if fileChooser.showOpenDialog(handles.frame) ~= ...
                        fileChooser.APPROVE_OPTION
                    return
                end
                dataFile = char(fileChooser.getSelectedFile());
                structGui_file_open(dataFile)
                
            case 'openThis'
                dataFile = varargin{1};
                structGui_file_open(dataFile)
                
            case 'save'
                structGui_file_save
                
            case 'exit'
                structGui_file_exit
                
            otherwise
                debugMsg(action)
        end
        
        
        %% file_menu
        function thisMenu = structGui_file_menu
            
            import java.awt.event.ActionEvent
            import java.awt.event.KeyEvent
            import javax.swing.JMenu
            import javax.swing.JMenuItem
            import javax.swing.KeyStroke
            
%menuPrp = struct('ActionPerformedCallback', @structGui_file_menu_callback);
            
            thisMenu = JMenu('File');
            thisMenu.setMnemonic(KeyEvent.VK_F)
            
            menuItem = JMenuItem('New', KeyEvent.VK_N);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_N, ActionEvent.CTRL_MASK))
            menuItem.setToolTipText('New data structure')
            jset(menuItem, 'ActionPerformedCallback', ...
                {@structGui_file_menu_callback, 'new'})
            thisMenu.add(menuItem);
            
            menuItem = JMenuItem('Open...', KeyEvent.VK_O);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_O, ActionEvent.CTRL_MASK))
            menuItem.setToolTipText('Open data file (M-file, MAT-file)')
            jset(menuItem, 'ActionPerformedCallback', ...
                {@structGui_file_menu_callback, 'open'})
            thisMenu.add(menuItem);
            thisMenu.addSeparator()
            
            menuItem = JMenuItem('Save', KeyEvent.VK_S);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_S, ActionEvent.CTRL_MASK))
            jset(menuItem, 'ActionPerformedCallback', ...
                {@structGui_file_menu_callback, 'save'})
            thisMenu.add(menuItem);
            
            menuItem = JMenuItem('Save As...', KeyEvent.VK_A);
            menuItem.setAccelerator(...
                KeyStroke.getKeyStroke(KeyEvent.VK_F12, 0))
            menuItem.setDisplayedMnemonicIndex(5)
            jset(menuItem, 'ActionPerformedCallback', ...
                {@structGui_file_menu_callback, 'save', '-showDialog'})
            thisMenu.add(menuItem);
            thisMenu.addSeparator()
            
            recentFileCount = numel(Prefs.recentFiles);
            for ii = 1 : min([recentFileCount, 9])
                recentFile = Prefs.recentFiles{ii};
                isAvailable = exist(recentFile, 'file') == 2;
                [file, file, ext] = fileparts(recentFile);
                menuItem = JMenuItem(sprintf('%d %s%s', ii, file, ext), ...
                    eval(sprintf('KeyEvent.VK_%d', ii)));
                if isAvailable
                    D = dir(recentFile);
                    toolTip = ['<html>File: ', recentFile, sprintf([
                        '<br>Size: %s<br>Date Modified: %s</html>'
                        ], bytestr(D.bytes), D.date)];
                else
                    %menuItem.setForeground(java.awt.Color.GRAY)
                    toolTip = [
                        '<html>Can''t find<br>', recentFile, '</html>'
                        ];
                end
                menuItem.setEnabled(isAvailable)
                menuItem.setToolTipText(toolTip)
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_file_menu_callback, 'openThis', recentFile
                    })
                thisMenu.add(menuItem);
                
                if ii == recentFileCount
                    thisMenu.addSeparator()
                end
            end
            
            menuItem = JMenuItem(['Exit ', Prefs.appName], KeyEvent.VK_X);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_Q, ActionEvent.CTRL_MASK))
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_file_menu_callback, 'exit'
                })
            thisMenu.add(menuItem);
            
            
            %% file_menu_callback
            function structGui_file_menu_callback(arg1, arg2, varargin)
                
                %userDataC = get(hObject, 'UserData');
                structGui_file(varargin{:})
            end
        end
        
        
        %% file_new
        function structGui_file_new
            
            %structGui_msg -clear
            %structGui_msg 'Creating new data structure'
            structGui_msg 'Creating new data structure... '
            S = Prefs.dataFcn('new');
            %S = Prefs.dataFcn('new', handles);
            dataFile = Prefs.dataFcn('dataFile', S);
            %structGui_msg(' %s... ', dataFile)
            structGui_update(S, '-saved')
            structGui_msg ok\n
        end
        
        
        %% file_open
        function structGui_file_open(dataFile)
            
            [folder, file, ext] = fileparts(dataFile);
            if exist(dataFile, 'file') ~= 2
                % invoke save?
                %structGui_file save
                structGui_msg('Warning: can''t find %s\n', dataFile)
                return
            end
            cd(folder)
            dataFile = which(dataFile);% solves run(<different case>) issue
            [folder, file, ext] = fileparts(dataFile);
            
            structGui_state busy
            structGui_msg('Opening data file %s%s... ', file, ext)
            
            switch lower(ext)
                case '.m'
                    clear S
                    try
                        %run(dataFile)
                        S = structGui_eval(dataFile, Prefs.dataName);
                    catch ME
                        handles.fail('Error: %s\n', ME.message)
                        %handles.fail('Error: %s\n', lasterr)
                        return
                    end
                    
                case '.mat'
                    MAT = load(dataFile);
                    if ~isfield(MAT, Prefs.dataName)
                        handles.fail([
                            'Warning: %s data structure not present in %s\n'
                            ], Prefs.dataName, dataFile)
                        return
                    end
                    S = MAT.(Prefs.dataName);
            end
            
            %jproject('setPath', folder)
            
            S.data_file = [file, ext];
            
            structGui_msg ok\n
            structGui_title(dataFile)
            structGui_update(S, '-saved')
            structGui_state ready
            
            
            % ******* Store Recent *******
            structGui_file_recent
            
            
            % ******* Messages *******
            D = dir(dataFile);
            structGui_msg(' %s file date %s\n %s file size %s\n', ...
                char(183), D.date, char(183), bytestr(D.bytes))
        end
        
        
        %% file_save
        function structGui_file_save
            
            import java.io.File
            
            showDialog = any(strcmp('-showDialog', varargin));
            
            [folder, file, ext] = fileparts(dataFile);
            W = whos('S');
            if strcmpi(ext, '.m') && W.bytes > 2^20
                % save data > 1 MB as MAT-file
                showDialog = true;
                dataFile = fullfile(folder, [file, '.mat']);
            end
            
            if exist(dataFile, 'file') == 2
                dataFile = which(dataFile);
            else
                showDialog = true;
            end
            
            if showDialog
                fileChooser.setDialogTitle(...
                    sprintf('Save %s data file', Prefs.appName))
                fileChooser.setSelectedFile(File(dataFile))
                if fileChooser.showSaveDialog(handles.frame) ~= ...
                        fileChooser.APPROVE_OPTION
                    return
                end
                dataFile = char(fileChooser.getSelectedFile());
            end
            
            
            % ******* Save Data File *******
            structGui_state busy
            [folder, file, ext] = fileparts(dataFile);
            S.data_file = [file, ext];
            S.user_name = jproject('username');
            S.file_date = datestr(now);
            
            structGui_msg('Storing data structure %s... ', S.data_file)
%             if ~structGui_file_backup
%                 return
%             end
            
            [ok, msg] = structGui_save(dataFile, S, Prefs.dataName);
            if ~ok
                handles.fail(msg)
            end
            cd(folder)
            
            
            % ******* Store Recent *******
            structGui_file_recent
            
            structGui_msg ok\n
            structGui_title(dataFile)
            structGui_update(S, '-restore', '-saved')
            structGui_state ready
            
            D = dir(dataFile);
            structGui_msg(' %s file date %s\n %s file size %s\n', ...
                char(183), D.date, char(183), bytestr(D.bytes))
        end
        
        
        %% file_recent
        function structGui_file_recent
            
            recentIdx = strcmpi(dataFile, Prefs.recentFiles);
            if any(recentIdx)
                Prefs.recentFiles(recentIdx) = [];
            end
            Prefs.recentFiles = [
                dataFile
                Prefs.recentFiles(1 : min([end, 8]))
                ];
            
            structGui_preferences('store', Prefs)
            
            handles.frame.getJMenuBar.removeAll()
            handles.frame.remove(handles.frame.getJMenuBar)
            handles.frame.setJMenuBar(structGui_makeMenuBar)
            handles.frame.show()
        end
        
        
        %% file_backup
        function ok = structGui_file_backup
            
            if exist(dataFile, 'file') ~= 2
                ok = true;
                return
            end
            
            [ok, msg] = backup(dataFile);
            if ~ok
                handles.fail('Error: %s\n', msg)
                return
            end
        end
        
        
        %% file_exit
        function structGui_file_exit
            
            structGui_preferences('store', Prefs)
            
            handles.frame.getJMenuBar.removeAll()
            handles.frame.getContentPane.removeAll()
            handles.frame.removeNotify()
            
            handles.frame.dispose()
            %awtinvoke(handles.frame, 'dispose()');  % memory leak issue
            %evalin('base', 'java.lang.System.gc()')
            handles = rmfield(handles, 'frame');
            %evalin('base', 'clear handles')
        end
    end


%% view
    function varargout = structGui_view(action, varargin)
        
        switch action
            case 'menu'
                varargout{1} = structGui_view_menu;
                return
                
            case 'data'
                %handles.dataButton.setSelected(true)
                handles.dataButton.doClick()
                
            case 'messages'
                %handles.messagesButton.setSelected(true)
                handles.messagesButton.doClick()
                
            case 'log'
                %edit(P.logFile)
                %winopen(P.logFile)
                open(P.logFile)
                
            case 'archive'
                go archive
                
            case 'pref'
                go pref
                
            case 'temp'
                go temp
                
            case 'user'
                go user
                
            case 'windows'
                go windows
                
            case 'lookAndFeel'
                Prefs.lookAndFeel = varargin{1};
                javax.swing.UIManager.setLookAndFeel(Prefs.lookAndFeel)
                javax.swing.SwingUtilities.updateComponentTreeUI(...
                    handles.frame)
                
            case 'expand'
                row = 0;
                
                while row < handles.tree.getRowCount
                    handles.tree.expandRow(row)
                    row = row + 1;
                end
                Prefs.expandTree = true;
                
            case 'collapse'
                row = handles.tree.getRowCount;
                
                while row > 0
                    row = row - 1;
                    handles.tree.collapseRow(row)
                end
                Prefs.expandTree = false;
                
            case 'root'
                % toggle root visible state
                handles.tree.setRootVisible(~handles.tree.isRootVisible)
                
            case 'scrollBars'
                Prefs.showScrollBars = ~Prefs.showScrollBars;
                structGui_select(handles.tree.getSelectionPath)
                
            case 'preferences'
                debugMsg(action)
                
            otherwise
                debugMsg(action)
        end
        
        structGui_preferences('store', Prefs)
        
        
        %% view_menu
        function viewMenu = structGui_view_menu
            
            import java.awt.event.ActionEvent
            import java.awt.event.KeyEvent
            import javax.swing.ButtonGroup
            import javax.swing.JCheckBoxMenuItem
            import javax.swing.JMenu
            import javax.swing.JMenuItem
            import javax.swing.JRadioButtonMenuItem
            import javax.swing.KeyStroke
            import javax.swing.UIManager
            
            viewMenu = JMenu('View');
            viewMenu.setMnemonic(KeyEvent.VK_V)
            
            buttonGroup = ButtonGroup();
            menuItem = ...
                JRadioButtonMenuItem('Data Structure', true);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_1, ActionEvent.ALT_MASK))
            menuItem.setMnemonic(KeyEvent.VK_D)
            menuItem.setToolTipText('Show data structure')
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'data'
                })
            buttonGroup.add(menuItem)
            viewMenu.add(menuItem);
            handles.viewData = menuItem;
            
            menuItem = JRadioButtonMenuItem('Message Panel', false);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_2, ActionEvent.ALT_MASK))
            menuItem.setMnemonic(KeyEvent.VK_M)
            menuItem.setToolTipText('Show message panel')
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'messages'
                })
            buttonGroup.add(menuItem)
            viewMenu.add(menuItem);
            handles.viewMessages = menuItem;
            
            viewMenu.addSeparator()
            
            menuItem = JMenuItem('Log File', KeyEvent.VK_L);
            menuItem.setToolTipText([
                '<html>View current log file<br>', P.logFile, '</html>'
                ])
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'log'
                })
            viewMenu.add(menuItem);
            
            if ispc
                viewMenu.addSeparator()
                
                menuItem = JMenuItem('Log Folder');
                menuItem.setToolTipText([
                    'Open log folder in Windows Explorer'
                    ])
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_view_menu_callback, 'archive'
                    })
                viewMenu.add(menuItem);
                
                menuItem = JMenuItem('Preferences Folder');
                menuItem.setToolTipText([
                    'Open MATLAB preferences folder in Windows Explorer'
                    ])
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_view_menu_callback, 'pref'
                    })
                viewMenu.add(menuItem);
                
                menuItem = JMenuItem('User Folder');
                menuItem.setToolTipText([
                    'Open MATLAB user folder in Windows Explorer'
                    ])
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_view_menu_callback, 'user'
                    })
                viewMenu.add(menuItem);
                
                menuItem = JMenuItem('Temp Folder');
                menuItem.setToolTipText([
                    'Open Windows temporary folder in Windows Explorer'
                    ])
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_view_menu_callback, 'temp'
                    })
                viewMenu.add(menuItem);
                
                menuItem = JMenuItem('Windows Folder');
                menuItem.setToolTipText([
                    'Open Windows installation folder in Windows Explorer'
                    ])
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_view_menu_callback, 'windows'
                    })
                viewMenu.add(menuItem);
            end
            
            viewMenu.addSeparator()
            
            if Prefs.debug
                lafMenu = JMenu('Look & Feel');
                buttonGroup = ButtonGroup();
                laf = UIManager.getInstalledLookAndFeels();
                for ii = 1 : numel(laf)
                    className = char(laf(ii).getClassName);
                    menuItem = JRadioButtonMenuItem(laf(ii).getName, ...
                        strcmp(className, Prefs.lookAndFeel));
                    jset(menuItem, 'ActionPerformedCallback', {
                        @structGui_view_menu_callback, ...
                        'lookAndFeel', className
                        })
                    lafMenu.add(menuItem);
                    buttonGroup.add(menuItem)
                end
                viewMenu.add(lafMenu);
                
                viewMenu.addSeparator()
            end
            
            buttonGroup = ButtonGroup();
            menuItem = ...
                JRadioButtonMenuItem('Expand Tree', Prefs.expandTree);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_MULTIPLY, ActionEvent.CTRL_MASK))
            menuItem.setMnemonic(KeyEvent.VK_E)
            menuItem.setToolTipText('Expand data structure tree')
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'expand'
                })
            buttonGroup.add(menuItem)
            viewMenu.add(menuItem);
            
            menuItem = JRadioButtonMenuItem(...
                'Collapse Tree', ~Prefs.expandTree);
            menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                KeyEvent.VK_DIVIDE, ActionEvent.CTRL_MASK))
            menuItem.setMnemonic(KeyEvent.VK_C)
            menuItem.setToolTipText('Collapse data structure tree')
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'collapse'
                })
            buttonGroup.add(menuItem)
            viewMenu.add(menuItem);
            
            viewMenu.addSeparator()
            
            menuItem = JCheckBoxMenuItem('Scroll Bars');
            menuItem.setMnemonic(KeyEvent.VK_B)
            menuItem.setState(Prefs.showScrollBars)
            menuItem.setToolTipText('Show or hide table scroll bars')
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'scrollBars'
                })
            viewMenu.add(menuItem);
            
            viewMenu.addSeparator()
            
            menuItem = JCheckBoxMenuItem('Preferences');
            menuItem.setMnemonic(KeyEvent.VK_P)
            menuItem.setState(false)
            menuItem.setToolTipText('Set personal preferences')
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_view_menu_callback, 'preferences'
                })
            viewMenu.add(menuItem);
            
            
            %% view_menu_callback
            function structGui_view_menu_callback(~, ~, varargin)
                
                structGui_state busy
                structGui_view(varargin{:})
                structGui_state ready
            end
        end
    end


%% help
    function varargout = structGui_help(action, varargin)
        
        switch action
            case 'menu'
                varargout{1} = structGui_help_menu;
                
            case 'debug'
                if he('-debug') ~= varargin{1}.getState()
                    he -debug
                end
                
            case 'help'
                if exist(Prefs.help, 'file') ~= 2
                    structGui_fail(...
                        'Warning: can''t find %s help file %s', ...
                        Prefs.appName, Prefs.help)
                    return
                end
                web(Prefs.help, '-helpbrowser')
                
            case 'matlab help'
                doc
                
            case 'about'
                import javax.swing.JOptionPane
                
                about = [
                    sprintf('<html><center><h1>%s</h1></center>', ...
                    Prefs.appName), ...
                    sprintf('%s<br>', Prefs.about{:}), ...
                    '<h3>Software development by</h3>' ...
                    'Hummeling Engineering<br>' ...
                    'www.hummeling.com<br>' ...
                    'engineering@hummeling.com<br>' ...
                    '<br>' ...
                    'This software uses Java SwingX<br>' ...
                    'released under Lesser General Public License.' ...
                    '</html>'
                    ];
                JOptionPane.showMessageDialog(handles.frame, ...
                    about, ...
                    ['About ', Prefs.appName], ...
                    JOptionPane.INFORMATION_MESSAGE, ...
                    javax.swing.ImageIcon(which(Prefs.appIcon)))
                
            otherwise
                debugMsg(action)
        end
        
        
        %% help_menu
        function thisMenu = structGui_help_menu
            
            import java.awt.event.ActionEvent
            import java.awt.event.KeyEvent
            import javax.swing.JCheckBoxMenuItem
            import javax.swing.JMenu
            import javax.swing.JMenuItem
            import javax.swing.KeyStroke
            
            thisMenu = JMenu('Help');
            thisMenu.setMnemonic(KeyEvent.VK_H)
            
            if exist('he.m', 'file') == 2
                menuItem = JCheckBoxMenuItem('Debug Mode');
                menuItem.setAccelerator(KeyStroke.getKeyStroke(...
                    KeyEvent.VK_B, ActionEvent.CTRL_MASK))
                menuItem.setMnemonic(KeyEvent.VK_B)
                menuItem.setState(he('-debug'))
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_help_menu_callback, 'debug', menuItem
                    })
                thisMenu.add(menuItem);
                
                thisMenu.addSeparator()
            end
            
            if exist(Prefs.help, 'file') == 2
                menuItem = JMenuItem([
                    Prefs.appName, ' Help'
                    ], KeyEvent.VK_H);
                menuItem.setAccelerator(...
                    KeyStroke.getKeyStroke(KeyEvent.VK_F1, 0))
                menuItem.setToolTipText([Prefs.appName, ' help manual'])
                jset(menuItem, 'ActionPerformedCallback', {
                    @structGui_help_menu_callback, 'help'
                    })
                thisMenu.add(menuItem);
            end
            
            menuItem = JMenuItem('MATLAB Help', KeyEvent.VK_M);
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_help_menu_callback, 'matlab help'
                })
            thisMenu.add(menuItem);
            
            thisMenu.addSeparator()
            
            menuItem = JMenuItem([
                'About ', Prefs.appName
                ], KeyEvent.VK_A);
            jset(menuItem, 'ActionPerformedCallback', {
                @structGui_help_menu_callback, 'about'
                })
            thisMenu.add(menuItem);
            
            
            %% help_menu_callback
            function structGui_help_menu_callback(hObj, evtData, varargin)
                
                structGui_help(varargin{:})
            end
        end
    end


%% msg
    function structGui_msg(msg, varargin)
        
        import javax.swing.text.SimpleAttributeSet
        import javax.swing.text.StyleConstants
        
        if isa(msg, 'MException')
            msg = msg.getReport;
            if ~strncmpi(msg, 'error', 5)
                msg = ['Error: ', msg];
            end
        end
        msg = regexprep(msg, '<a href="[^\n]+">|</a>', '');
        msg = strrep(msg, '\', '\\');
        msg = strrep(msg, '\\n', '\n');
        
        isOk = strncmp(strtrim(msg), 'ok', 2);
        isError = strncmpi(msg, 'error', 5);
        isWarning = strncmpi(msg, 'warning', 7);
        isNote = strncmpi(msg, 'note', 4);
        
        if exist('handles', 'var') ~= 1
            % fall-back to Command Window
            fid = double(isError & isWarning) + 1;
            fprintf(fid, msg, varargin{:});
            return
        end
        
        switch msg
            case '-clear'
                handles.editorPane.setText('')
                return
        end
        
        thisColor = Skin.foreground;
        
        att = SimpleAttributeSet();
        StyleConstants.setAlignment(att, StyleConstants.ALIGN_JUSTIFIED)
        StyleConstants.setFontFamily(att, Skin.font.getFamily())
        if isError
            thisColor = Skin.error;
        elseif isWarning
            thisColor = Skin.warning;
            StyleConstants.setItalic(att, true)
        elseif isNote
            thisColor = Skin.note;
        elseif isOk
            thisColor = Skin.ok;
        end
        StyleConstants.setForeground(att, thisColor)
        
        doc = handles.editorPane.getDocument();
        msgStr = sprintf(msg, varargin{:});
        doc.insertString(doc.getLength(), msgStr, att)
        handles.editorPane.setCaretPosition(doc.getLength())
        
        
        % ******* Append to Log File *******
        structGui_log(msgStr)
        
        
        % ******* Status Panel *******
        statusStrC = regexp(msgStr,'([^\n]+)', 'tokens', 'once');
        if isempty(statusStrC)
            return
        end
        statusStr = statusStrC{1};
        % handles.progressBar.setForeground(thisColor)
        % if isOk
        %     getStr = char(handles.progressBar.getString());
        %     handles.progressBar.setString([getStr, statusStr])
        % elseif ~strncmp(statusStr, ' ', 1)
        %     handles.progressBar.setString(statusStr)
        %     handles.progressBar.setStringPainted(true)
        % end
        
        idx = 2;
        handles.statusBar.getComponent(idx).setForeground(thisColor)
        if isOk
            getStr = char(handles.statusBar.getComponent(idx).getText());
            handles.statusBar.getComponent(idx).setText([
                getStr, statusStr
                ])
        elseif ~strncmp(statusStr, ' ', 1)
            handles.statusBar.getComponent(idx).setText(statusStr)
        end
    end


%% fail
    function structGui_fail(varargin)
        
        structGui_msg \n
        structGui_msg(varargin{:})
        structGui_msg \n
        structGui_state ready
    end


%% state
    function varargout = structGui_state(action, varargin)
        
        import java.awt.Color
        import java.awt.Cursor
        
        varargout = {};
        
        switch action
            case 'busy'
                P.state = action;
                % pause(.1)   % prevents Java Exception
                %EXC handles.progressBar.setIndeterminate(setIndeterminate)
                handles.frame.setCursor(...
                    Cursor.getPredefinedCursor(Cursor.WAIT_CURSOR))
                %handles.progressBar.setIndeterminate(setIndeterminate)
                
            case 'ready'
                P.state = action;
                handles.frame.setCursor(...
                    Cursor.getPredefinedCursor(Cursor.DEFAULT_CURSOR))
                %EXC handles.progressBar.setIndeterminate(false)
                handles.progressBar.setStringPainted(false)
                handles.progressBar.setValue(0)
                
            case 'status'
                varargout{1} = P.state;
        end
    end


%% update
    function structGui_update(updatedS, varargin)
        
        import java.awt.Font
        import javax.swing.tree.TreeSelectionModel
        
        if ~any(strcmp('-restore', varargin))
            % reset expanded/collapsed state
            P.tree = true;
        end
        if ~any(strcmp('-saved', varargin))
            structGui_changed
        end
        
        S = updatedS;
        
        hiddenC = Prefs.hidden;
        handles.tree = struct2tree(S, '-noLeafs', '-noIcons', ...
            '-hidden', hiddenC, '-label', Prefs.dataName);
        handles.tree.setFont(Skin.font)
        
        jset(handles.tree, 'MouseClickedCallback', @structGui_callback)
        
        selectionModel = handles.tree.getSelectionModel;
        selectionModel.setSelectionMode(...
            TreeSelectionModel.SINGLE_TREE_SELECTION)
        jset(selectionModel, 'ValueChangedCallback', @structGui_callback)
        
        handles.treeScrollPane.setViewportView(handles.tree)
        
        
        % ******* Restore Expanded/Collapsed State *******
        for row = 1 : numel(P.tree)
            if P.tree(row)
                handles.tree.expandRow(row - 1)
            end
        end
        
        structGui_select(Prefs.lastTreePath)
    end


%% select
    function structGui_select(treePath)
        
        import java.awt.Font
        import java.awt.GridBagConstraints
        import java.awt.Insets
        import javax.swing.JButton
        import javax.swing.JLabel
        import javax.swing.JScrollPane
        
        if isempty(treePath)
            return
        end
        
        %contentScrollPane.setViewportView(JLabel('loading contents...'))
        
        Schar = treePath;
        if isa(treePath, 'javax.swing.tree.TreePath')
            Schar = treepath2struct(treePath);
        end
        
        %thisS = evalstruct(S, Schar);
        try
            thisS = eval(regexprep(Schar, Prefs.dataName, 'S', 'once'));
        catch
            nodeCC = regexp(Schar, '(\.[^.]+)', 'tokens');
            nodeC = [nodeCC{1 : end - 1}];
            
            Schar = Prefs.dataName;% fall-back to root node   % selections
            
            if ~isempty(nodeC)
                % try parent tree node
                Schar = [Schar, sprintf('%s', nodeC{:})];
            end
            
            structGui_select(Schar)
            return
        end
        
        %handles.frame.setEnabled(false)
        %handles.tree.scrollRowToVisible(Prefs.lastTreeRow)
        
        Prefs.lastTreePath = Schar;
        lastTreePathC = regexp(Schar, '([^\.]+)', 'tokens');
        %tp1 = javax.swing.tree.TreePath([lastTreePathC{:}]);
        %tp2 = handles.tree.getSelectionPath();
%         for ii = 0 : Prefs.lastTreeRow
%             handles.tree.expandRow(ii)
%         end
        nodeCnt = numel(lastTreePathC);
        lastTreePath = ...
            javaArray('javax.swing.tree.DefaultMutableTreeNode', nodeCnt);
        for ii = 1 : nodeCnt
            lastTreePath(ii) = javax.swing.tree.DefaultMutableTreeNode(...
                lastTreePathC{ii}{1});
        end
        %ERR
        treePath = javax.swing.tree.TreePath(lastTreePath);
        
        structGui_preferences('store', Prefs)
        
        editable = isempty(regexp(char(treePath), Prefs.final, 'once'));
        
        
        % ******* Units *******
        unitPattern = '()';
        if isfield(S, 'units') && isstruct(S.units)
            quantities = fieldnames(S.units);
            unitPattern = ['(', sprintf('|%s', quantities{:}), ')'];
        end
        
        
        % ******* Border *******
        contentPanel.setTitle(field2str(Schar))
        
        %panelTitle.setTitleFont(headerFont)
        %handles.tree.getCellRenderer.setBackground(java.awt.Color.RED)
        
        panel.removeAll()
        %panel.setVisible(false)
        %ERR panel.setAlpha(1)
        %panel.setBackground(java.awt.Color(0,0,0,0))
        %structGui_drawNow
        
        constraints = GridBagConstraints();
        constraints.anchor = GridBagConstraints.LINE_START;
        %constraints.anchor = GridBagConstraints.FIRST_LINE_START;
        constraints.gridy = 0;
        constraints.insets = Insets(0, 5, 1, 5);
        
        field = fieldnames(thisS);
        for ii = 1 : numel(field)
            
            subS = thisS.(field{ii});
            isHidden = any(strcmp(field{ii}, Prefs.hidden));
            if isstruct(subS) || isHidden
                continue
            end
            
            %constraints.anchor = GridBagConstraints.LINE_END;
            constraints.fill = GridBagConstraints.NONE;
            constraints.gridx = 0;
            constraints.weightx = 0;
            label = strrep(field{ii}, '_', ' ');
            
            
            % ******* Add Unit *******
            unitToken = regexp(field{ii}, unitPattern, 'tokens', 'once');
            if ~isempty(unitToken)
                label = sprintf('%s [%s]', label, S.units.(unitToken{1}));
            end
            
            %if isempty(strfind(label, 'folder'))
            thisLabel = JLabel(label);
            thisLabel.setFont(Skin.font)
            thisLabel.setForeground(Skin.foreground)
            panel.add(thisLabel, constraints);
            % else
            %     % TEMP!!!
            %     button = JButton('folder...');
            %     button.setFont(Skin.font)
            %     button.setForeground(Skin.foreground)
            %     jset(button, ...
            %         'ActionPerformedCallback', @structGui_callback, ...
            %         'ActionCommand', [Schar, '.', field{ii}])
            %     panel.add(button, constraints);
            % end
            
            
            % ******* Add Component *******
            %constraints.anchor = GridBagConstraints.LINE_START;
            constraints.fill = GridBagConstraints.NONE;
            constraints.gridx = 1;
            constraints.weightx = 1;
            panel.add(structGui_select_component(subS), constraints);
            
            
            constraints.gridy = constraints.gridy + 1;
        end
        
        % ******* Float Components PAGE_START *******
        % constraints.weighty = 1;        % fill vertical space
        % panel.add(JLabel(''), constraints);
        
        structGui_drawNow
        %panel.setVisible(true)
        %ERR panel.setAlpha(0)
        %panel.setBackground(Skin.blue)
        
        % panel.setMinimumSize(panel.getPreferredSize)
        
        
        % ******* Store Tree State *******
        %P.treeModel = handles.tree.getModel();
        %P.treePath = char(treePath);
        
        
        %% select_component
        function comp = structGui_select_component(value)
            
            import java.awt.Color
            import java.awt.Dimension
            import java.awt.FlowLayout
            import java.awt.GridBagConstraints
            import javax.swing.JCheckBox
            import javax.swing.JComboBox
            import javax.swing.JLabel
            import javax.swing.JList
            import javax.swing.JPanel
            import javax.swing.JRadioButton
            import javax.swing.JScrollPane
            import javax.swing.JTable
            import javax.swing.JTextArea
            import javax.swing.JTextField
            import javax.swing.ListSelectionModel
            import javax.swing.table.DefaultTableModel
            import org.jdesktop.swingx.JXDatePicker
            
            % colNames = {};
            [rows, cols] = size(value);
            % for colName = char(double('A') + mod(0 : cols - 1, 26))
            %     colNames{end + 1} = colName;
            % end
%enable = editable && ~any(strcmp(field{ii}, Prefs.finalFields));
            editableField = editable && ...
                ~any(strcmp(field{ii}, Prefs.finalFields));
            %enable = true;
            enable = editableField;
            
            comp = JLabel();
            thisClass = class2string(value);
            
            switch thisClass
                case 'logical'
                    if numel(value) == 1
                        comp = JCheckBox();
                        comp.setEnabled(enable)
                        comp.setOpaque(false)
                        comp.setSelected(value)
                        structGui_select_component_callback(comp)
                        return
                    end
                    
                    
                    % comp = JPanel();
                    % comp.getLayout.setAlignment(FlowLayout.LEADING)
                    % group = ButtonGroup();
                    %
                    % for thisValue = value
                    %     thisComp = JRadioButton('', thisValue);
                    %     thisComp.setEnabled(enable)
                    %     comp.add(thisComp);
                    %     group.add(thisComp);
                    % end
                    comp = structGui_select_component(uint8(value));
                    
                case 'cell'
                    constraints.fill = GridBagConstraints.HORIZONTAL;
                    if cols == 1
                        % document
                        textArea = JTextArea(sprintf('%s\n', value{:}));
                        textArea.setEditable(editableField)
                        textArea.setFont(Skin.inputFont)
                        structGui_select_component_callback(textArea)
                        
                        if Prefs.showScrollBars
                            limitRows = min([rows + 1, Prefs.maxRows]);
                            textArea.setRows(limitRows)
                            comp = JScrollPane(textArea);
                            
                        else
                            textArea.setLineWrap(true)
                            textArea.setWrapStyleWord(true)
                            comp = textArea;
                        end
                        %textArea.setMinimumSize(Dimension(868,200))
                        return
                    end
                    
                    table = JTable(rows, cols);
                    
                    %if rows > 1
                        % assume first row is column headers
                        colNames = value(1,:);
                        value = value(2 : end,:);
                        rows = rows - 1;
                    %end
                    
                    %tic
                    for jj = 1 : numel(value)
                        if isempty(value{jj})
                            % TBD solve in TableModelP.java if possible
                            value{jj} = ' ';
                        end
                    end
                    %toc
                    
                    
                    % ******* Table Settings *******
                    table.setGridColor(Skin.blue)
                    table.setSelectionBackground(Skin.blue)
                    table.setSelectionForeground(Skin.foreground)
                    
                    %table.setEnabled(enable)
                    if rows == 1
                        table.setCellSelectionEnabled(true)
                    end
                    if ~editableField
                        table.setDefaultEditor(...
                            java.lang.Object().getClass, [])
                    end
                    table.setShowHorizontalLines(false)
                    
                    tableModel = DefaultTableModel(value, colNames);
                    table.setModel(tableModel)
                    
                    
                    % ******* Fix Column Widths *******
% % ERROR with Windows Vista painter
% columnModel = table.getColumnModel();
% headerRenderer = table.getTableHeader.getDefaultRenderer();
% for jj = 1 : cols
%   headerValue = columnModel.getColumn(jj-1).getHeaderValue();
%   cellRenderer = table.getDefaultRenderer(tableModel.getColumnClass(jj-1));
%   headerComp = headerRenderer.getTableCellRendererComponent([], ...
%     headerValue, false, false, 0, 0);
%   cellWidth = headerComp.getPreferredSize.width;
%   for kk = 1 : min(rows, Prefs.maxRows)
%     cellComp = cellRenderer.getTableCellRendererComponent(table, ...
%       value{kk,jj}, false, false, kk-1, jj-1);
%     cellWidth = max([cellWidth, cellComp.getPreferredSize.width]);
%   end
%   columnModel.getColumn(jj-1).setPreferredWidth(cellWidth)
% end
% table.setColumnModel(columnModel)
                    
                    if Prefs.showScrollBars
                        height = min(table.getRowHeight()*[
                            rows, Prefs.maxRows
                            ]);
                        table.setPreferredScrollableViewportSize(...
                            Dimension(1, height))
                        comp = JScrollPane(table);
                    else
                        comp = table;
                    end
                    structGui_select_component_callback(table)
                    
                case 'char'
                    if editableField && ~isempty(regexp(value, ...
                            '\d{1,2}-[A-S][a-y]{2}-\d{4}', 'once'))
                        try     % TEMP!!!
                            df = java.text.SimpleDateFormat('yyyy-MM-dd');
                            comp = JXDatePicker(df.parse(datestr(value, ...
                                29)), java.util.Locale.UK);
                            comp.getEditor.setBackground(Skin.yellow)
                            comp.setFont(Skin.inputFont)
                            comp.setFormats('dd-MMM-yyyy')
                            structGui_select_component_callback(comp)
                            return
                        catch
                        end
                    end
                    
                    columns = (floor(cols/Prefs.textFieldColumns) + ...
                        1)*Prefs.textFieldColumns;
                    comp = JTextField(value, columns);
                    comp.setEditable(editableField)
                    comp.setFont(Skin.inputFont)
                    comp.setHorizontalAlignment(JTextField.LEFT)
                    % SwingX issue
                    comp.setMinimumSize(comp.getPreferredSize)
                    %comp.setOpaque(false)
                    structGui_select_component_callback(comp)
                    
                case {'integer', 'real'}
                    numVals = numel(value);
                    
                    if numVals <= 1
                        % make text field
                        comp = JTextField(num2str(value), ...
                            Prefs.textFieldColumns);
                        comp.setEditable(editableField)
                        comp.setFont(Skin.inputFont)
                        comp.setHorizontalAlignment(JTextField.TRAILING)
                        % SwingX issue
                        comp.setMinimumSize(comp.getPreferredSize)
                        structGui_select_component_callback(comp)
                        return
                    end
                    
                % if rows > 1 && cols > 1
                %     comp = structGui_select_component(num2cell(value));
                %     return
                % end
                    % make list
                    comp = JList(num2cell(value(:)));
                    %comp = org.jdesktop.swingx.JXList(num2cell(value(:)));
                    %comp.setBackground(Skin.yellow)
                    comp.setFont(Skin.inputFont)
                    %comp.setForeground(Skin.foreground)
                    %comp.setEnabled(editable)
                    if rows == 1
                        % render as column TEMP
                        rows = cols;
                        cols = 1;
                    end
                    if cols == 1
                        comp.setLayoutOrientation(JList.VERTICAL)
                    else
                        comp.setLayoutOrientation(JList.VERTICAL_WRAP)
                    end
                    comp.setSelectionMode(...
                        ListSelectionModel.SINGLE_INTERVAL_SELECTION)
                    comp.setVisibleRowCount(rows)
                    structGui_select_component_callback(comp)
                    
                    if Prefs.showScrollBars && rows > Prefs.maxRows
                        height = comp.getCellBounds(0,0).getHeight()*...
                            min(rows, Prefs.maxRows);
                        comp = JScrollPane(comp);
                        width = comp.getPreferredSize.getWidth + 20;
                        comp.setPreferredSize(Dimension(width, height))
                        %comp.setPreferredSize(Dimension(width, height))
                    end
                    
                    
                case 'struct'
                    % ******* Java Component *******
                    switch value.component
                        case 'JComboBox'
                            if isempty(value.items)
                                comp = JComboBox();
                                return
                            end
                            comp = JComboBox(value.items);
                            comp.setSelectedIndex(value.selectedIndex)
                    end
                    
                case 'function_handle'
                    value = func2str(value);
                    cols = size(value, 2);
                    
                    columns = (floor(cols*.75/Prefs.textFieldColumns) + ...
                        1)*Prefs.textFieldColumns;
                    comp = JTextField(value, columns);
                    comp.setEditable(editableField)
                    comp.setHorizontalAlignment(JTextField.LEFT)
                    structGui_select_component_callback(comp)
                    
                case 'JComponent'
                    % Only combo box supported TEMP!!!
                    if isempty(value.Items)
                        comp = JComboBox();
                    else
                        comp = JComboBox(value.Items);
                    end
                    %comp.setBackground(Skin.yellow)
                    %TEST comp.setForeground(Color.GREEN)
                    comp.setFont(Skin.inputFont)
                    comp.setSelectedIndex(value.SelectedIndex - 1)
                    renderer = comp.getRenderer();
                    %renderer.setBackground(Color.RED)
                    renderer.setForeground(Skin.blue)
                    comp.setRenderer(renderer)
                    editableField = true;
                    enable = true;
                    structGui_select_component_callback(comp)
                    
                case 'Simulink.SimulationOutput'
                % comp = JTextField(sprintf('%s class object', thisClass));
                % comp.setBackground(Skin.gray)
                % comp.setEditable(false)
                % comp.setFont(Skin.inputFont)
                % comp.setForeground(Skin.foreground)
                    comp = structGui_select_component(value.who());
                    
                otherwise
                    comp = ...
                        JLabel(sprintf('Warning: unknown data type %s', ...
                        class(value)));
                    comp.setForeground(Color.RED)
                    comp.setBackground(Color.WHITE)
                    comp.setOpaque(true)
            end
            
            
            %% select_component_callback
            % structGui_callback
            function structGui_select_component_callback(comp, varargin)
                
                if ismethod(comp, 'setForeground')
                    comp.setForeground(Skin.foreground)
                end
                setBackground = ismethod(comp, 'setBackground');
                if ~editableField || ~enable
                    if setBackground
                        comp.setBackground(Skin.gray)
                    end
                    return
                end
                if setBackground
                    comp.setBackground(Skin.yellow)
                end
                
                dataPath = sprintf('%s.%s', Schar, field{ii});
                
                if ismethod(comp, 'setName')
                    comp.setName(dataPath)
                end
                
                switch class(comp)
                    case {'javax.swing.JCheckBox', 'javax.swing.JComboBox'}
                        jset(comp, ...
                            'ActionPerformedCallback', @structGui_callback)
                        
                    case 'javax.swing.JList'
                        jset(comp, 'KeyTypedCallback', @structGui_callback)
                        
                    case 'javax.swing.JTextArea'
                        jset(comp, 'KeyTypedCallback', @structGui_callback)
                        
                    case 'javax.swing.JTextField'
                        comp.setActionCommand(dataPath)
                        jset(comp, 'KeyTypedCallback', @structGui_callback)
                        
                    case 'javax.swing.table.DefaultTableModel'
                        %compPrp.TableChangedCallback = @structGui_callback;
                        jset(comp, 'TableChangedCallback', [
                            {@structGui_callback}, varargin
                            ])
                        
                    case 'javax.swing.JTable'
                        % recursion
                        structGui_select_component_callback(...
                            comp.getModel(), comp)
                        
                    case 'javax.swing.JScrollPane'
                        
                    case 'org.jdesktop.swingx.JXDatePicker'
                        jset(comp, ...
                            'PropertyChangeCallback', @structGui_callback)
                        
                    otherwise
                        debugMsg(class(comp))
                end
            end
        end
    end


%% tree
    function structGui_tree
        
        P.tree = true;
        row = 0;
        
        while row < handles.tree.getRowCount
            row = row + 1;
            P.tree(row) = handles.tree.isExpanded(row - 1);
        end
    end


%% data
    function data = structGui_data
        data = S;
    end


%% handles
    function handlesStruct = structGui_handles
        handlesStruct = handles;
    end


%% skin
    function skin = structGui_skin
        skin = Skin;
    end


%% preferences
    function varargout = structGui_preferences(action, varargin)
        
        prefFile = ...
            fullfile(strrep(userpath, pathsep, ''), [P.caller, '.mat']);
        
        switch action
            case 'defaults'
                Prefs = structGui_preferences_defaults;
                varargout{1} = Prefs;
                
            case 'retrieve'
                Defaults = structGui_preferences_defaults;
                
                % ******* Add MAT-File Preferences *******
                if exist(prefFile, 'file') == 2
                    try
                        loadPrefs = load(prefFile);
                        for thisField = fieldnames(loadPrefs.Prefs)'
                            Defaults.(thisField{1}) = ...
                                loadPrefs.Prefs.(thisField{1});
                        end
                    catch
                        %structGui_fail('Error: %s\n', lasterr)
                    end
                end
                
                % ******* Add User Preferences *******
                if isfield(Prefs, 'dataName') && ...
                        ~isfield(Prefs, 'lastTreePath')
                    Prefs.lastTreePath = Prefs.dataName;
                end
                for thisField = fieldnames(Prefs)'
                    Defaults.(thisField{1}) = Prefs.(thisField{1});
                end
                
                varargout{1} = Defaults;
                
            case 'store'
                % Prefs = structGui_preferences_defaults;
                % for thisField = fieldnames(varargin{1})'
                %     Prefs.(thisField{1}) = varargin{1}.(thisField{1});
                % end
                Prefs.lastDimension = {
                    handles.frame.getSize.getWidth()
                    handles.frame.getSize.getHeight()
                    }';
                try
                    save(prefFile, 'Prefs')
                catch
                    structGui_fail('Error: %s\n', lasterr)
                end
            otherwise
                debugMsg(action)
        end
        
        
        %% preferences_defaults
        function Prefs = structGui_preferences_defaults
            
            Prefs.debug = isme;
            Prefs.dividerSize = 12;
            Prefs.expandTree = true;
            Prefs.font = 'Verdana';
            Prefs.maxRows = 25;
            Prefs.showScrollBars = true;
            Prefs.textFieldColumns = 10;
            Prefs.appName = mfilename;
            Prefs.appIcon = '';
            Prefs.hidden = {'units'};
            Prefs.final = '( )';
            Prefs.finalFields = {''};
            Prefs.dataName = 'S';
            Prefs.lastTreePath = Prefs.dataName;
            Prefs.lastDimension = {600, 600};
            Prefs.dataFolder = jproject('folder');
            Prefs.logMessages = true;
            Prefs.lookAndFeel = char(...
                javax.swing.UIManager.getCrossPlatformLookAndFeelClassName());
            Prefs.recentFiles = {};
            Prefs.dataFcn = @structGui_dataFcn;
            %Prefs.runFcn = @structGui_runFcn;
            Prefs.runFcn = [];
            Prefs.menu = {};
            Prefs.help = '';
            Prefs.about = {
                '<h2>Data Structure Interface</h2>'
                };
        end
    end


%% progress
    function structGui_progress(fraction, handles)
        
        handles.progressBar.setIndeterminate(false)
        %handles.progressBar.setStringPainted(false)
        handles.progressBar.setValue(floor(1e3*fraction))
        handles.progressBar.setString(sprintf('%.f%%', 1e2*fraction))
        handles.progressBar.setStringPainted(true)
    end


%% dataFcn
    function out = structGui_dataFcn(action, varargin)
        
        out = [];
        
        % ******* Required Data Function Actions *******
        switch action
            case 'init'
                out = Prefs;
                
            case 'dataFile'
                out = fullfile(jproject('folder'), ...
                    sprintf('data%s.m', datestr(now, 30)));
                
            case 'popupMenu'    % structGui_popupMenu
                Schar = varargin{1};
                debugMsg(Schar)
                %S = varargin{2};
                %popupMenu = varargin{3};
        end
    end


%% changed
    function structGui_changed
        
        structGui_title([which(Prefs.dataFcn('dataFile', S)), '*'])
    end


%% units
    function structGui_units(updatedUnits)
        
        Prefs.units = updatedUnits;
    end


%% log
    function structGui_log(msg)
        
        if ~Prefs.logMessages
            return
        end
        if ~isfield(P, 'logFile')
            keyboard
        end
        try
            fid = fopen(P.logFile, 'a');
            fprintf(fid, strrep(msg, '\', '\\'));
            fclose(fid);
        catch ME
            % disable message logging
            Prefs.logMessages = false;
            structGui_fail('Warning: message logging disabled:\n%s\n', ...
                ME.message)
        end
    end


%% drawNow
    function structGui_drawNow(varargin)
        
        panel.repaint()
        panel.revalidate()
        contentScrollPane.repaint()
    end
end


%% eval
function S = structGui_eval(dataFile, dataName)

run(dataFile)
S = eval(dataName);
end


%% save
function [ok, msg] = structGui_save(file, S, name)

ok = false;
msg = '';

[~, ~, ext] = fileparts(file);

switch lower(ext)
    case '.m'
        struct2script(S, file, '-silent', '-name', name)
        
    case '.mat'
            delete(timerfindall('Name', mfilename))
            timerObject = timer('BusyMode', 'queue', ...
                'ExecutionMode', 'fixedSpacing', 'Name', mfilename, ...
                'ObjectVisibility', 'off', 'Period', 1e-3, ...
                'TasksToExecute', 2, 'TimerFcn', {@structGui_save_mat, file, S, name});
            start(timerObject)
        
    otherwise
        msg = sprintf(...
            'Warning: unknown extension %s, data NOT stored!\n', ext);
        return
end

ok = true;
end


%% save_mat
function structGui_save_mat(timerObject, ~, file, S, name)

if get(timerObject, 'TasksExecuted') == 1
    return
end

eval([name, ' = S;'])

try
    %tic
    %save(file, name, '-mat', '-v6')   % 46 sec
    save(file, name, '-mat', '-v7')     % 46 sec
    %save(file, name, '-mat', '-v7.3')   % 60 sec
    %toc
catch ME
    fprintf(2, 'Error storing %s:\n%s\n', file, ME.message);
end
end
