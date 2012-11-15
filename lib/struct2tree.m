function tree = struct2tree(S, varargin)
%STRUCT2TREE
%
%   See also structGui, struct2script.

% Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)

if nargin == 0
    struct2tree_test
    return
end

import java.awt.Color
import java.awt.GradientPaint
import javax.swing.JTree
import javax.swing.tree.DefaultTreeCellRenderer
import org.jdesktop.swingx.JXTree
import org.jdesktop.swingx.painter.MattePainter


% ******* Fetch Options *******
expand = any(strcmp('-expand', varargin));
noLeafs = any(strcmp('-noLeafs', varargin));
noIcons = any(strcmp('-noIcons', varargin));
hiddenIdx = strcmp('-hidden', varargin);
labelIdx = strcmp('-label', varargin);
foregroundIdx = strcmp('-foreground', varargin);
backgroundIdx = strcmp('-background', varargin);


% ******* Default Options *******
hidden = '';
label = inputname(1);
foreground = Color(4/15, 5/15, 6/15);
%background = Color(1, 1, 4/15);
background = MattePainter(GradientPaint(...
    1, 1, Color(12/15, 13/15, 14/15), ...
    300, 300, Color(10/15, 11/15, 12/15)));
blue = Color(11/15, 12/15, 13/15);
yellow = Color(1, 1, 14/15);

if any(hiddenIdx)
    hidden = varargin{find(hiddenIdx) + 1};
end
if any(labelIdx)
    label = varargin{find(labelIdx) + 1};
end
if any(backgroundIdx)
    background = varargin{find(backgroundIdx) + 1};
end
if any(foregroundIdx)
    foreground = varargin{find(foregroundIdx) + 1};
end


% ******* Parse Structure *******
tree = JTree(struct2tree_parse(S, label));
% tree = JXTree(struct2tree_parse(S, label));


% ******* Apply Options *******
renderer = DefaultTreeCellRenderer();
if expand
    struct2tree_expand
end
if noLeafs
    renderer.setLeafIcon(renderer.getDefaultClosedIcon())
end
if noIcons
    renderer.setClosedIcon([])
    renderer.setLeafIcon([])
    renderer.setOpenIcon([])
end
% tree.setBackground(background)
% tree.setBackgroundPainter(background)
%tree.setBackground([])
tree.setOpaque(false)
%renderer.setBackground([])
renderer.setBackgroundNonSelectionColor(blue)
%renderer.setBackgroundNonSelectionColor([])
%renderer.setBackgroundSelectionColor([])
% renderer.setBackgroundSelectionColor(foreground)
% renderer.setBackgroundSelectionColor(blue)
renderer.setBackgroundSelectionColor(yellow)
renderer.setBorderSelectionColor([])
renderer.setTextNonSelectionColor(foreground)
renderer.setTextSelectionColor(foreground)
% renderer.setTextSelectionColor(yellow)
tree.setCellRenderer(renderer)


%% parse
    function node = struct2tree_parse(thisS, name)
        
        import javax.swing.JPanel
        import javax.swing.JLabel
        import javax.swing.JSpinner
        import javax.swing.SpinnerNumberModel
        import javax.swing.tree.DefaultMutableTreeNode
        
        node = DefaultMutableTreeNode(strrep(name, '_', ' '));
        
        if isstruct(thisS)
            for thisField = fieldnames(thisS)'
                thisSubS = thisS.(thisField{1});
                % 0.53
                if (~isstruct(thisSubS) && noLeafs) || any(strcmp(thisField, hidden))
                    %0.54 if (noLeafs && ~isstruct(thisSubS)) || any(strcmp(thisField, hidden))
                    %1.65 if any(strcmp(thisField, hidden)) || (~isstruct(thisSubS) && noLeafs)
                    continue
                end
                
                N = numel(thisSubS);
                for ii = 1 : N
                    if N == 1
                        thisName = thisField{1};
                        %thisNode = struct2tree_parse(thisSubS, thisName);
                    else
                        thisName = sprintf('%s(%u)', thisField{1}, ii);
                    end
                    
                    node.add(struct2tree_parse(thisSubS(ii), thisName))
                end
            end
        end
    end


%% expand
    function struct2tree_expand
        
        row = 0;
        
        while row < tree.getRowCount
            tree.expandRow(row)
            row = row + 1;
        end
    end
end


%% test
function struct2tree_test

debugMsg


% ******* Data Structure *******
A.a1 = 1;
A.a2 = 'a''s';
A.a3 = true;
A.B_0.b1 = 4;
A.B_0.b2 = 'b';
A.B_0.b3.D = false;
A.c = {
    false, 0, 'a'
    true, 1, 'b'
    };
A.E(1).F(1).label = 'first 1';
A.E(1).F(2).label = 'first 2';
A.E(2).F(1).label = 'second 1';
A.swing = struct('component','JComboBox', ...
    'items','asd|feetfsd', ...
    'editable',false, ...
    'selectedIndex',3, ...
    'callback', @(eventData)(eventData)); % @(hObject, eventData)(eventData)

base(A)

tree = struct2tree(A);
treeExpand = struct2tree(A, '-expand');
hiddenC = {'swing', 'with_underscore'};
hiddenC = {};
treeNoLeafs = struct2tree(A, '-expand', '-noLeafs', '-noIcons', '-hidden', hiddenC);


% ******* JFrame *******
import java.awt.BorderLayout
import java.awt.Color
import java.awt.Font
import java.awt.GradientPaint
import javax.swing.JFrame
import javax.swing.JScrollPane
import org.jdesktop.swingx.JXFrame
import org.jdesktop.swingx.JXMultiSplitPane
import org.jdesktop.swingx.JXPanel
import org.jdesktop.swingx.JXTitledPanel
import org.jdesktop.swingx.MultiSplitLayout
import org.jdesktop.swingx.painter.CompoundPainter
import org.jdesktop.swingx.painter.MattePainter
import org.jdesktop.swingx.painter.PinstripePainter

panel = JXPanel();
panel.setBackgroundPainter(MattePainter(GradientPaint(...
    1, 1, Color(1, 1, 14/15), ...
    1, 300, Color(11/15, 12/15, 13/15))))
panel.add(tree);

foreground = Color(4/15, 5/15, 6/15);
blue = Color(11/15, 12/15, 13/15);
yellow = Color(1, 1, 14/15);
compPainter = CompoundPainter([
    MattePainter(blue)
    PinstripePainter(GradientPaint(1, 1, Color(12/15, 13/15, 14/15), ...
    500, 500, Color(10/15, 11/15, 12/15)))
    ]);
titlePainter = CompoundPainter([
    MattePainter(GradientPaint(1, 1, yellow, 1, 20, blue))
    PinstripePainter(GradientPaint(1, 1, yellow, 24, 24, blue, true))
    ]);
titleFont = Font(Font.SANS_SERIF, Font.PLAIN, 20);
backgroundPainter = MattePainter(GradientPaint(1, 1, blue, 1, 100, yellow));

%layout = '(ROW (LEAF name=selector weight=0.3) (COLUMN weight=0.7 (LEAF name=demo weight=0.7) (LEAF name=source weight=0.3)))';
layout = '(COLUMN (ROW (LEAF name=tree) (LEAF name=contents)) (LEAF name=messages))';
multiSplitLayout = MultiSplitLayout(MultiSplitLayout.parseModel(layout));
%ERR multiSplitLayout = MultiSplitLayout.parseModel(layout);
splitPane = JXMultiSplitPane(multiSplitLayout);

% tree.setBorder([])
treeScrollPane = JScrollPane(tree);
% treeScrollPane.getViewport.setBorder([])
treeScrollPane.getViewport.setOpaque(false)
% treeScrollPane.setBorder([])            % outer
treeScrollPane.setViewportBorder([])    % inner

treePanel = JXTitledPanel('Data Structure', treeScrollPane);
% treePanel.setBorder([])
treePanel.setTitleForeground(foreground)
treePanel.setTitleFont(titleFont)
treePanel.setTitlePainter(titlePainter)
% treePanel.setBackgroundPainter(backgroundPainter)

treeExpand.setBorder([])
scrollPane = JScrollPane(treeExpand);
scrollPane.getViewport.setOpaque(false)
% scrollPane.setBorder([])
scrollPane.setViewportBorder([])    % inner

contentsPanel = JXTitledPanel('Contents', scrollPane);
% contentsPanel.setBorder([])
%WIP contentsPanel.getBorder
contentsPanel.setTitleForeground(foreground)
contentsPanel.setTitleFont(titleFont)
contentsPanel.setTitlePainter(CompoundPainter([
    MattePainter(GradientPaint(1, 1, blue, 1, 15, yellow))
    PinstripePainter(GradientPaint(1, 1, blue, 20, 20, yellow))
    ]))
contentsPanel.setBackgroundPainter(MattePainter(GradientPaint(1, 1, yellow, 1, 500, blue)))

treeNoLeafs.setBorder([])
msgScrollPane = JScrollPane(treeNoLeafs);
msgScrollPane.getViewport.setOpaque(false)
msgScrollPane.setBorder([])

msgPanel = JXTitledPanel('Messages', msgScrollPane);
msgPanel.setBorder([])
msgPanel.setTitleForeground(foreground)
msgPanel.setTitleFont(titleFont)
msgPanel.setTitlePainter(titlePainter)
msgPanel.setBackgroundPainter(backgroundPainter)

splitPane.add('tree', treePanel);
splitPane.add('contents', contentsPanel);
splitPane.add('messages', msgPanel);
%splitPane.setBackground(Color.BLACK)
%splitPane.setBackgroundPainter(painter2)
splitPane.setBackgroundPainter(compPainter)

handles = struct;
handles.frame = JFrame(mfilename);
% handles.frame.add(JScrollPane(tree), BorderLayout.LINE_START);
% handles.frame.add(JScrollPane(treeExpand), BorderLayout.CENTER);
% handles.frame.add(JScrollPane(treeNoLeafs), BorderLayout.LINE_END);
% handles.frame.add(tree, BorderLayout.LINE_START);
% handles.frame.add(panel, BorderLayout.CENTER);
% handles.frame.add(treeNoLeafs, BorderLayout.LINE_END);
handles.frame.add(splitPane, BorderLayout.CENTER);

handles.frame.pack()
handles.frame.setVisible(true)

% splitPane.setOpaque(false)    this also works
% handles.frame.getContentPane.setBackgroundPainter(compPainter)
end
