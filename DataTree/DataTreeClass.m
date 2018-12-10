classdef DataTreeClass < handle
    
    properties
        group
        currElem
    end
    
    methods
        
        % ---------------------------------------------------------------
        function obj = DataTreeClass(files, handles, funcptr)
            if ~exist('files','var')
                return;
            end
            if ~exist('handles','var')
                handles = [];
            end
            if ~exist('funcptr','var')
                funcptr = [];
            end
            obj.LoadData(files);
            
            % Initialize the current processing element within the group
            obj.currElem = InitCurrElem(handles, funcptr);
            obj.LoadCurrElem(files, 1, 1);
        end
        
        
        % --------------------------------------------------------------
        function delete(obj)
            if isempty(obj.currElem)
                return;
            end
            if ishandle(obj.currElem.handles.ProcStreamOptionsGUI)
                delete(obj.currElem.handles.ProcStreamOptionsGUI);
            end
        end


        % ---------------------------------------------------------------
        function LoadData(obj, files)
            obj.AcqData2Group(files);
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Load derived or post-acquisition data from a file if it exists
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.group.Load();
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Find out if we need to ask user for prcessing options config file
            % to initialize procInput.procFunc at the run, subject or group level.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            subj = obj.group.subjs(1);
            run = obj.group.subjs(1).runs(1);
            
            for jj=1:length(obj.group.subjs)
                if ~procStreamIsEmpty(obj.group.subjs(jj).procInput)
                    subj = obj.group.subjs(jj);
                end
                for kk=1:length(obj.group.subjs(jj).runs)
                    if ~procStreamIsEmpty(obj.group.subjs(jj).runs(kk).procInput)
                        run = obj.group.subjs(jj).runs(kk);
                    end
                end
            end
            
            % Find the procInput defaults at each level with which to initialize
            % uninitialized procInput
            [procInputGroupDefault, procfilenm] = obj.group.GetProcInputDefault();
            [procInputSubjDefault, procfilenm]  = subj.GetProcInputDefault(procfilenm);
            [procInputRunDefault, ~]            = run.GetProcInputDefault(procfilenm);
            
            % Copy default procInput to all uninitialized nodes in the group
            obj.group.CopyProcInput('group', procInputGroupDefault);
            obj.group.CopyProcInput('subj', procInputSubjDefault);
            obj.group.CopyProcInput('run', procInputRunDefault);
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Copy input variables for group, subjects and runs
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            obj.group.SetConditions();
            obj.group.SetMeasList();
            
        end
        
        
        % ----------------------------------------------------------
        function AcqData2Group(obj, files)
           
            obj.group = GroupClass().empty();
            
            if ~exist('files','var') || isempty(files)
                return;
            end
            
            % Create new group based only on the .nirs files
            
            rnum = 1;
            obj.group = GroupClass(files(1).name);
            files(1).MapFile2Group(1, 1);
            hwait = waitbar(0, sprintf('Loading proc elements') );
            p = get(hwait,'position');
            set(hwait, 'Position',[p(1), p(2), p(3)*1.5, p(4)]);
            for ii=2:length(files)
                
                waitbar(ii/length(files), hwait, sprintf('Loading %s: %d of %d', ...
                    sprintf_s(files(ii).name), ii, length(files)) );
                fname = files(ii).name;
                if files(ii).isdir
                    
                    jj = length(obj.group.subjs)+1;
                    obj.group.subjs(jj) = SubjClass(fname, jj, 0, rnum);
                    files(ii).MapFile2Group(jj,rnum);
                    
                else
                    
                    [sname, rnum_tmp, iExt] = getSubjNameAndRun(fname, rnum);
                    if rnum_tmp ~= rnum
                        rnum = rnum_tmp;
                    end
                    
                    jj=1;
                    while jj<=length(obj.group.subjs)
                        if(strcmp(sname, obj.group.subjs(jj).name))
                            nRuns = length(obj.group.subjs(jj).runs);
                            
                            % If this run already exists under this subject, the user probably
                            % made a mistake in naming the file (e.g., having two files named
                            % <subjname>_run01.nirs and <subjname>_run01_<descriptor>.nirs)
                            % We handle it anyways by continuing through all existing subjects
                            % until we are forced to create a new subject with one run.
                            flag=0;
                            for kk=1:nRuns
                                if rnum == obj.group.subjs(jj).runs(kk).rnum
                                    sname = fname(1:iExt-1);
                                    jj=jj+1;
                                    
                                    flag = 1;
                                    break;
                                end
                            end
                            if flag==1
                                flag = 0;
                                continue
                            end
                            
                            % Create new run in existing subject
                            obj.group.subjs(jj).runs(nRuns+1) = RunClass(fname, jj, nRuns+1, rnum);
                            obj.group.nFiles = obj.group.nFiles+1;
                            files(ii).MapFile2Group(jj, nRuns+1);
                            
                            rnum=rnum+1;
                            break;
                        end
                        jj=jj+1;
                    end
                    
                    % Create new subject with one run
                    if(jj>length(obj.group.subjs))
                        
                        obj.group.subjs(jj) = SubjClass(fname, jj, 1, rnum);
                        obj.group.nFiles = obj.group.nFiles+1;
                        files(ii).MapFile2Group(jj, 1);
                        
                        rnum=rnum+1;
                        
                    end
                end
            end
            close(hwait);
        end



        % ----------------------------------------------------------
        function DisplayCurrElem(obj, varargin)            
            if nargin<2
                return;
            end
            canvas = varargin{1};
            if nargin>2
                datatype = varargin{2}.datatype;
                buttonVals = varargin{2}.buttonVals;
                condition = varargin{2}.condition;
            else
                datatype = canvas.datatype;
                buttonVals = canvas.buttonVals;
                condition = canvas.condition;
            end

            % Display current elem unless the data is undefined for current
            % elem, for instance raw data is undefined for group and
            % subject. In that case, display current run.
            procElem = obj.currElem.procElem;
            if obj.currElem.procType ~= 3
                if ~ismember(datatype, [buttonVals.OD_HRF, buttonVals.OD_HRF_PLOT_PROBE, buttonVals.CONC_HRF, buttonVals.CONC_HRF_PLOT_PROBE])
                    iSubj = obj.currElem.iSubj;
                    iRun = obj.currElem.iRun;
                    if iRun==0, iRun=1; end
                    procElem = obj.group.subjs(iSubj).runs(iRun);                    
                end
            end
            
            if strcmp(canvas.name, 'guiMain')
                procElem.DisplayGuiMain(canvas);
            elseif strcmp(canvas.name, 'plotprobe')
                procElem.DisplayPlotProbe(canvas, datatype, buttonVals, condition);
            end
        end

        
        % ----------------------------------------------------------
        function LoadCurrElem(obj, files, iSubj, iRun)
            
            if exist('iSubj','var') & exist('iRun','var')
                for ii=1:length(files)
                    if files(ii).map2group.iSubj==iSubj && files(ii).map2group.iRun==iRun
                        iFile = ii;
                        break;
                    end
                end
                if ishandle(obj.currElem.handles.listboxFiles)
                    set(obj.currElem.handles.listboxFiles,'value',iFile);
                end
            end

            if ishandle(obj.currElem.handles.listboxFiles)
                iFile = get(obj.currElem.handles.listboxFiles,'value');
                iSubj = files(iFile).map2group.iSubj;
                iRun = files(iFile).map2group.iRun;
                
                % iSubj==0 means the file chosen is a group directory - no
                % subject or run processing allowed for the corresponding
                % group tree element
                if iSubj==0
                    
                    set(obj.currElem.handles.radiobuttonProcTypeSubj,'enable','off');
                    set(obj.currElem.handles.radiobuttonProcTypeRun,'enable','off');
                    set(obj.currElem.handles.radiobuttonProcTypeGroup,'value',1);
                    
                    % iRun==0 means the file chosen is a subject directory - no single
                    % run processing allowed for the corresponding group tree element
                elseif iSubj>0 && iRun==0
                    
                    set(obj.currElem.handles.radiobuttonProcTypeSubj,'enable','on');
                    set(obj.currElem.handles.radiobuttonProcTypeRun,'enable','on');
                    
                    % Don't change the value of the button group unless it is
                    % currently set to an illegal value
                    if obj.currElem.procType==3
                        set(obj.currElem.handles.radiobuttonProcTypeSubj,'value',1);
                    end
                    
                    % iRun==0 means the file chosen is a subject directory - no single
                    % run processing allowed for the corresponding group tree element
                elseif iSubj>0 && iRun>0
                    
                    set(obj.currElem.handles.radiobuttonProcTypeSubj,'enable','on');
                    set(obj.currElem.handles.radiobuttonProcTypeRun,'enable','on');
                    
                end
            else
                iFile = 1;
                iSubj = 1;
                iRun = 1;
            end

            obj.currElem = getProcType(obj.currElem);
            if obj.currElem.procType==1
                obj.currElem.procElem = obj.group(1);
            elseif obj.currElem.procType==2
                obj.currElem.procElem = obj.group(1).subjs(iSubj);
            elseif obj.currElem.procType==3
                obj.currElem.procElem = obj.group(1).subjs(iSubj).runs(iRun);
            end
            
            obj.currElem.iFile = iFile;
            obj.currElem.iSubj = iSubj;
            obj.currElem.iRun = iRun;
            
        end


        % ----------------------------------------------------------
        function UpdateCurrElemProcStreamOptionsGUI(obj)
            
            % Update only if the gui is already active. Otherwise do nothing
            if ishandles(obj.currElem.handles.ProcStreamOptionsGUI)
                % Get position in character units
                set(obj.currElem.handles.ProcStreamOptionsGUI, 'units','characters');
                pos = get(obj.currElem.handles.ProcStreamOptionsGUI, 'position');
                
                % Race condition in matlab versions 2014b and higher: give some time
                % for set/get to finish before deleting GUI
                pause(0.1);
                delete(obj.currElem.handles.ProcStreamOptionsGUI);
                
                % Another race condition, which might make GUI disappear when going through files in the
                % listboxFiles and this time in any matlab version with the
                % ProcStreamOptionsGUI active
                pause(0.1);
                obj.currElem.handles.ProcStreamOptionsGUI = ProcStreamOptionsGUI(obj.currElem, pos, 'userargs');
            end
        end


        % ----------------------------------------------------------
        function SaveCurrElem(obj)
            obj.currElem.procElem.Save();
        end


        % ----------------------------------------------------------
        function CalcCurrElem(obj)
            obj.currElem.procElem.Calc(obj.currElem.handles.listboxFiles, obj.currElem.funcPtrListboxFiles);
        end

    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
                
    end
    
    
end