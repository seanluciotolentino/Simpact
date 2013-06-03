classdef JComponent
    %JCOMPONENT Java Swing type class
    %   Used for GUI types that don't have clear structure counterparts,
    %   e.g., a check box can be a boolean field, but how to
    %   know when to render a combo box?
    
    % Copyright 2009-2010 by Hummeling Engineering (www.hummeling.com)
    
    properties
        Type = '';
        Items = {''};
        SelectedIndex = 0;
        Constructor = {};
        SelectedItem = '';
    end
    
    methods
        %% JComponent
        function obj = JComponent(type, items, selectedIndex)
            
            % ******* Constructor *******
            obj.Type = type;
            obj.Items = items;
            obj.SelectedIndex = selectedIndex;
            switch obj.Type
                case 'javax.swing.JComboBox'
                    obj.Constructor = {obj.Items};
            end
        end
        
        
        %% get.Constructor
        function value = get.Constructor(obj)
            
            value = obj.Constructor;
        end
        
        
        %% get.Items
        function value = get.Items(obj)
            
            value = obj.Items;
        end
                
        %% get.SelectedIndex
        function value = get.SelectedIndex(obj)
            
            value = obj.SelectedIndex;
        end
                
        %% get.Type
        function value = get.Type(obj)
            
            value = obj.Type;
        end
                
        %% get.SelectedItem
        function value = get.SelectedItem(obj)
            
            if obj.SelectedIndex == 0
                value = '';
                return
            end
            
            value = obj.Items{obj.SelectedIndex};
        end
        
        
        %% set.Items
        function obj = set.Items(obj, value)
            
            obj.Items = value;
            obj.Constructor = {obj.Items};
        end        
        
        %% set.SelectedIndex
        function obj = set.SelectedIndex(obj, value)
            
            obj.SelectedIndex = value;
        end
                
        %% set.Type
        function obj = set.Type(obj, value)
            
            obj.Type = value;
        end
        
        
        %% thisTest
        function thisTest(obj, a, b)
            
            debugMsg
            keyboard
        end
    end
end
