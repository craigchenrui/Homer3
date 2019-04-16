function varargout = Homer3(varargin)

% Start initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Homer3_OpeningFcn, ...
    'gui_OutputFcn',  @Homer3_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1}) && ~strcmp(varargin{end},'userargs')
    if varargin{1}(1)=='.'
        varargin{1}(1) = '';
    end
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT



% ---------------------------------------------------------------------
function Homer3_Init(handles, args)

% Set the figure renderer. Some renderers aren't compatible
% with certain OSs or graphics cards. Homer3 uses the figure renderer
% when displaying patches. Allow user to set the renderer that is best
% for the host system.
%
hFig = handles.Homer3;
if ~isempty(args)
    if strcmpi(args{1},'zbuffer') || ...
            strcmpi(args{1},'painters') || ...
            strcmpi(args{1},'opengl')
        
        set(hFig,'renderer',args{1});
        set(hFig,'renderermode','manual');
        
    elseif strcmpi(args{1},'rendererauto')
        
        if isunix()
            set(hObject,'renderer','zbuffer');
        elseif ispc()
            set(hFig,'renderer','painters');
        else
            set(hFig,'renderer','zbuffer');
        end
        set(hFig,'renderermode','manual');
        
    end
end
positionGUI(hFig, 0.20, 0.10, 0.70, 0.85)
setGuiFonts(hFig);

% Get rid of the useless "might be unsused" warnings for GUI callbacks
checkboxPlotHRF_Callback([]);
checkboxApplyProcStreamEditToAll_Callback([]);
pushbuttonCalcProcStream_Callback([]);
listboxFilesErr_Callback([]);
uipanelPlot_SelectionChangeFcn([]);
menuItemProcStreamEdit_Callback([]);
checkboxPlotProbe_Callback([]);
pushbuttonSave_Callback([]);
menuItemViewHRFStdErr_Callback([]);
menuItemLaunchStimGUI_Callback([]);
pushbuttonProcStreamOptionsEdit_Callback([]);
guiControls_ButtonDownFcn([]);
axesSDG_ButtonDownFcn([]);
popupmenuConditions_Callback([]);
listboxPlotWavelength_Callback([]);
listboxPlotConc_Callback([]);
menuChangeGroupFolder_Callback([]);
menuItemExit_Callback([]);
menuItemReset_Callback([]);
menuCopyCurrentPlot_Callback([]);
uipanelProcessingType_SelectionChangeFcn([]);


% ---------------------------------------------------------------------
function Homer3_EnableDisableGUI(handles, val)

set(handles.listboxFiles, 'enable', val);
set(handles.radiobuttonProcTypeGroup, 'enable', val);
set(handles.radiobuttonProcTypeSubj, 'enable', val);
set(handles.radiobuttonProcTypeRun, 'enable', val);
set(handles.radiobuttonPlotRaw, 'enable', val);
set(handles.radiobuttonPlotOD,  'enable', val);
set(handles.radiobuttonPlotConc, 'enable', val);
set(handles.checkboxPlotHRF, 'enable', val);
set(handles.textStatus, 'enable', val);


% --------------------------------------------------------------------
function eventdata = Homer3_OpeningFcn(hObject, eventdata, handles, varargin)
global hmr

hmr = [];

if isempty(varargin)    
    hmr.format = 'snirf';
else
    hmr.format = varargin{1};
end
hmr.gid = 1;
hmr.sid = 2;
hmr.rid = 3;

hmr.dataTree = [];

% Choose default command line output for Homer3
handles.output = hObject;
guidata(hObject, handles);

% Set the Homer3_version version number
[~, V] = Homer3_version(hObject);
hmr.version = V;
hmr.childguis = ChildGuiClass().empty();

% Disable and reset all window gui objects
Homer3_EnableDisableGUI(handles,'off');
Homer3_Init(handles, {'zbuffer'});

% Load date files into group tree object
hmr.dataTree  = LoadDataTree(hmr.format);
if hmr.dataTree.IsEmpty()
    return;
end
hmr.guiControls = InitGuiControls(handles);

% If data set has no errors enable window gui objects
Homer3_EnableDisableGUI(handles,'on');

% Display data from currently selected processing element
DisplayFiles(handles);
DisplayData(handles, hObject);

hmr.childguis(1) = ChildGuiClass('procStreamGUI');
hmr.childguis(2) = ChildGuiClass('stimGUI');
hmr.childguis(3) = ChildGuiClass('PlotProbeGUI');
hmr.childguis(4) = ChildGuiClass('ProcStreamOptionsGUI');

hmr.handles = handles;
hmr.Update = @Update;



% --------------------------------------------------------------------
function varargout = Homer3_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;



% --------------------------------------------------------------------
function [eventdata, handles] = Homer3_DeleteFcn(hObject, eventdata, handles)
global hmr;

if ishandles(hObject)
    delete(hObject)
end
if isempty(hmr)
    return;
end
if isempty(hmr.dataTree)
    return;
end
delete(hmr.dataTree);
for ii=1:length(hmr.childguis)
    hmr.childguis(ii).Close();
end
hmr = [];
clear hmr;



% --------------------------------------------------------------------------------------------
function DisplayFiles(handles)
global hmr;

files    = hmr.dataTree.files;
filesErr = hmr.dataTree.filesErr;

% Set listbox for valid .nirs files
listboxFiles = cell(length(files),1);
nFiles=0;
for ii=1:length(files)
    if files(ii).isdir
        listboxFiles{ii} = files(ii).name;
    elseif ~isempty(files(ii).subjdir)
        listboxFiles{ii} = ['    ', files(ii).filename];
        nFiles=nFiles+1;
    else
        listboxFiles{ii} = files(ii).name;
        nFiles=nFiles+1;
    end
end

% Set listbox for invalid .nirs files
listboxFiles2 = cell(length(filesErr),1);
nFilesErr=0;
for ii=1:length(filesErr)
    if filesErr(ii).isdir
        listboxFiles2{ii} = filesErr(ii).name;
    elseif ~isempty(filesErr(ii).subjdir)
        listboxFiles2{ii} = ['    ', filesErr(ii).filename];
        nFilesErr=nFilesErr+1;
    else
        listboxFiles2{ii} = filesErr(ii).name;
        nFilesErr=nFilesErr+1;
    end
end

% Set graphics objects: text and listboxes if handles exist
if ~isempty(handles)
    % Report status in the status text object
    set( handles.textStatus, 'string', { ...
        sprintf('%d files loaded successfully',nFiles), ...
        sprintf('%d files failed to load',nFilesErr) ...
        } );
    
    if ~isempty(files)
        set(handles.listboxFiles, 'value',1)
        set(handles.listboxFiles, 'string',listboxFiles)
    end
    
    if ~isempty(filesErr)
        set(handles.listboxFilesErr, 'visible','on');
        set(handles.listboxFilesErr, 'value',1);
        set(handles.listboxFilesErr, 'string',listboxFiles2)
    else
        set(handles.listboxFilesErr, 'visible','off');
        pos1 = get(handles.listboxFiles, 'position');
        pos2 = get(handles.listboxFilesErr, 'position');
        set(handles.listboxFiles, 'position', [pos1(1) pos2(2) pos1(3) .98-pos2(2)]);
    end
end
listboxFiles_Callback([], [1,1,1], handles)



% --------------------------------------------------------------------
function eventdata = uipanelProcessingType_SelectionChangeFcn(hObject, eventdata, handles)
global hmr

if isempty(hObject)
    return;
end
proclevel = getProclevel(handles);
iFile = get(handles.listboxFiles,'value');
[iGroup,iSubj,iRun] = hmr.dataTree.MapFile2Group(iFile);
switch(proclevel)
	case hmr.gid
        if iGroup==0
            iGroup=1;
        end
        hmr.dataTree.SetCurrElem(iGroup);
    case hmr.sid
        if iGroup==0
            iGroup=1;
        end
        if iSubj==0
            iSubj=1;
        end
        hmr.dataTree.SetCurrElem(iGroup, iSubj);
    case hmr.rid
        if iGroup==0
            iGroup=1;
        end
        if iSubj==0
            iSubj=1;
        end
        if iRun==0
            iRun=1;
        end
        hmr.dataTree.SetCurrElem(iGroup, iSubj, iRun);
end
listboxFiles_Callback([], [iGroup,iSubj,iRun], handles)
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function listboxFiles_Callback(hObject0, eventdata, handles)
global hmr

if isempty(hObject0)    
    hObject = handles.listboxFiles;
else
    hObject = hObject0;
end

iFile = get(hObject,'value');
if isempty(iFile==0)
    return;
end

% If evendata isn't empty then caller is trying to set currElem
if isa(eventdata, 'matlab.ui.eventdata.ActionData')
    
    % Get the [iGroup,iSubj,iRun] mapping of the clicked lisboxFiles entry
    [iGroup,iSubj,iRun] = hmr.dataTree.MapFile2Group(iFile);
    
    % Get the current processing level radio buttons setting
    proclevel = getProclevel(handles);
        
    % Set new gui state based on current gui selections of listboxFiles
    % (iGroup, iSubj, iRun) and proc level radio buttons (proclevel)
    SetGuiProcLevel(handles, iGroup, iSubj, iRun, proclevel);
    
elseif ~isempty(eventdata)
    
    iGroup = eventdata(1);
    iSubj = eventdata(2);
    iRun = eventdata(3);
    iFile = hmr.dataTree.MapGroup2File(iGroup, iSubj, iRun);
    if iFile==0
        return;
    end
    set(hObject,'value', iFile);
    
end
DisplayData(handles, hObject0);


% --------------------------------------------------------------------
function [eventdata, handles] = pushbuttonCalcProcStream_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end
% Set the display status to pending. In order to avoid redisplaying 
% in a single callback thread in functions called from here which 
% also call DisplayData
hmr.dataTree.CalcCurrElem();
hmr.dataTree.SaveCurrElem();
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function [eventdata, handles] = listboxFilesErr_Callback(hObject, eventdata, handles)
if ~ishandles(hObject)
    return;
end

% TBD: We may want to try fix files with errors



% --------------------------------------------------------------------
function [eventdata, handles] = uipanelPlot_SelectionChangeFcn(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

if strcmp(get(hObject, 'tag'), 'radiobuttonPlotRaw')
    set(handles.checkboxPlotHRF, 'value',0);
elseif strcmp(get(hObject, 'tag'), 'radiobuttonPlotOD') && isempty(hmr.dataTree.currElem.GetDodAvg())
    if isa(hmr.dataTree.currElem, 'RunClass')
        set(handles.checkboxPlotHRF, 'value',0);
    end
elseif strcmp(get(hObject, 'tag'), 'radiobuttonPlotConc') && isempty(hmr.dataTree.currElem.GetDcAvg())
    if isa(hmr.dataTree.currElem, 'RunClass')
        set(handles.checkboxPlotHRF, 'value',0);
    end
end
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function UpdateDatatypePanel(handles)
global hmr
datatype   = getDatatype(handles);
if datatype == hmr.buttonVals.RAW || datatype == hmr.buttonVals.RAW_HRF
    set(handles.listboxPlotWavelength, 'visible','on');
    set(handles.listboxPlotConc, 'visible','off');
elseif datatype == hmr.buttonVals.OD || datatype == hmr.buttonVals.OD_HRF
    set(handles.listboxPlotWavelength, 'visible','on');
    set(handles.listboxPlotConc, 'visible','off');
elseif datatype == hmr.buttonVals.CONC || datatype == hmr.buttonVals.CONC_HRF
    set(handles.listboxPlotWavelength, 'visible','off');
    set(handles.listboxPlotConc, 'visible','on');
end



% --------------------------------------------------------------------
function [eventdata, handles] = checkboxPlotHRF_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end
if get(hObject, 'value')==1
    if ~isempty(hmr.dataTree.currElem.GetDcAvg())
        set(handles.radiobuttonPlotConc, 'enable', 'on');
        set(handles.radiobuttonPlotConc, 'value', 1);
    elseif ~isempty(hmr.dataTree.currElem.GetDodAvg())
        set(handles.radiobuttonPlotOD, 'enable', 'on');
        set(handles.radiobuttonPlotOD, 'value', 1);
    end
end
DisplayData(handles, hObject);


% --------------------------------------------------------------------
function [eventdata, handles] = guiControls_ButtonDownFcn(hObject, eventdata, handles)

% Make sure the user clicked on the axes and not
% some other object on top of the axes
if ~strcmp(get(hObject,'type'),'axes')
    return;
end


% --------------------------------------------------------------------
function [eventdata, handles] = axesSDG_ButtonDownFcn(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end
dataTree = hmr.dataTree;
if dataTree.IsEmpty()
    return;
end

% Transfer the channels selection to guiControls
SetAxesDataCh();

% Update the displays of the guiControls and axesSDG axes
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function [eventdata, handles] = popupmenuConditions_Callback(hObject, eventdata, handles)
if ~ishandles(hObject)
    return;
end
GetAxesDataCondition();
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function [eventdata, handles] = listboxPlotWavelength_Callback(hObject, eventdata, handles)
if ~ishandles(hObject)
    return;
end
GetAxesDataWl();
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function [eventdata, handles] = listboxPlotConc_Callback(hObject, eventdata, handles)
if ~ishandles(hObject)
    return;
end
GetAxesDataHbType();
DisplayData(handles, hObject);



% --------------------------------------------------------------------
function [eventdata, handles] = menuChangeGroupFolder_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

fmt = hmr.format;

% Change directory
pathnm = uigetdir( cd, 'Pick the new directory' );
if pathnm==0
    return;
end
cd(pathnm);
hGui=get(get(hObject,'parent'),'parent');
Homer3_DeleteFcn(hGui,[],handles);

% restart
Homer3(fmt);



% --------------------------------------------------------------------
function menuItemExit_Callback(hObject, eventdata, handles)
if ~ishandles(hObject)
    return;
end
hGui=get(get(hObject,'parent'),'parent');
Homer3_DeleteFcn(hGui,eventdata,handles);



% --------------------------------------------------------------------
function [eventdata, handles] = menuItemReset_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end
dataTree = hmr.dataTree;
dataTree.currElem.Reset();
dataTree.currElem.Save();
DisplayData(handles, hObject);


% --------------------------------------------------------------------
function [eventdata, handles] = menuCopyCurrentPlot_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

currElem = hmr.dataTree.currElem;
hf = figure;
set(hf, 'color', [1 1 1]);
fields = fieldnames(hmr.buttonVals);
plotname = sprintf('%s_%s', currElem.name, fields{getDatatype(handles)});
set(hf,'name', plotname);


% DISPLAY DATA
guiControls.axesData.handles.axes = axes('position',[0.05 0.05 0.6 0.9]);

% DISPLAY SDG
guiControls.axesSDG.handles.axes = axes('position',[0.65 0.05 0.3 0.9]);
axis off

% TBD: Display current element without help from dataTree



% --------------------------------------------------------------------
function [eventdata, handles] = pushbuttonProcStreamOptionsEdit_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

idx = FindChildGuiIdx('ProcStreamOptionsGUI');
if get(hObject, 'value')
    hmr.childguis(idx).Launch(hmr.guiControls.applyEditCurrNodeOnly);
else
    hmr.childguis(idx).Close();
end



% -------------------------------------------------------------------
function [eventdata, handles] = menuItemLaunchStimGUI_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

idx = FindChildGuiIdx('stimGUI');
hmr.childguis(idx).Launch();



% --------------------------------------------------------------------
function [eventdata, handles] = pushbuttonSave_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end
hmr.dataTree.currElem.Save();



% --------------------------------------------------------------------
function [eventdata, handles] = menuItemViewHRFStdErr_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

if strcmp(get(hObject, 'checked'), 'on')
    set(hObject, 'checked', 'off')
elseif strcmp(get(hObject, 'checked'), 'off')
    set(hObject, 'checked', 'on')
end
if strcmp(get(hObject, 'checked'), 'on')
    hmr.guiControls.showStdErr = true;
elseif strcmp(get(hObject, 'checked'), 'off')
    hmr.guiControls.showStdErr = false;
end
DisplayData(handles, hObject);



% ---------------------------------------------------------------------------
function [eventdata, handles] = checkboxPlotProbe_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

idx = FindChildGuiIdx('PlotProbeGUI');
if get(hObject, 'value')
    hmr.childguis(idx).Launch(getDatatype(handles), hmr.guiControls.condition);
else
    hmr.childguis(idx).Close();
end



% --------------------------------------------------------------------
function [eventdata, handles] = menuItemProcStreamEdit_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

checked = get(hObject,'checked');
idx = FindChildGuiIdx('procStreamGUI');
if checked
    hmr.childguis(idx).Launch();
else
    hmr.childguis(idx).Close();
end


% --------------------------------------------------------------------
function [eventdata, handles] = checkboxApplyProcStreamEditToAll_Callback(hObject, eventdata, handles)
global hmr
if ~ishandles(hObject)
    return;
end

if get(hObject, 'value')
    hmr.guiControls.applyEditCurrNodeOnly = false;
else
    hmr.guiControls.applyEditCurrNodeOnly = true;
end
UpdateArgsChildGuis(handles);



% --------------------------------------------------------------------
function idx = FindChildGuiIdx(name)
global hmr

for ii=1:length(hmr.childguis)
    if strcmp(hmr.childguis(ii).GetName, name)
        break;
    end
end
idx = ii;


% --------------------------------------------------------------------
function UpdateArgsChildGuis(handles)
global hmr
if isempty(hmr.childguis)
    return;
end

hmr.childguis(FindChildGuiIdx('PlotProbeGUI')).UpdateArgs(getDatatype(handles), hmr.guiControls.condition);
hmr.childguis(FindChildGuiIdx('ProcStreamOptionsGUI')).UpdateArgs(hmr.guiControls.applyEditCurrNodeOnly);


% --------------------------------------------------------------------
function UpdateChildGuis(handles)
global hmr
if isempty(hmr.childguis)
    return;
end
UpdateArgsChildGuis(handles)
for ii=1:length(hmr.childguis)
    hmr.childguis(ii).Update();
end


% ----------------------------------------------------------------------------------
function hObject = DisplayData(handles, hObject)
global hmr


% Some callbacks which call DisplayData, serve double duty as called functions 
% from other callbacks which also call DisplayData. To avoid double or
% triple redisplaying in a single thread, exit DisplayData if hObject is
% not a handle. 
if ~exist('hObject','var')
    hObject=[];
end
if ~ishandles(hObject)
    return;
end

dataTree = hmr.dataTree;
procElem = dataTree.currElem;
EnableDisableGuiPlotBttns(handles);

hAxes = hmr.guiControls.axesData.handles.axes;
if ~ishandles(hAxes)
    return;
end

axes(hAxes)
cla;
legend off
set(hAxes,'ygrid','on');

linecolor  = hmr.guiControls.axesData.linecolor;
linestyle  = hmr.guiControls.axesData.linestyle;
datatype   = getDatatype(handles);
condition  = hmr.guiControls.condition;
iCh0       = hmr.guiControls.ch;
iWl        = hmr.guiControls.wl;
hbType     = hmr.guiControls.hbType;
sclConc    = hmr.guiControls.sclConc;        % convert Conc from Molar to uMolar
showStdErr = hmr.guiControls.showStdErr;

condition = find(procElem.CondName2Group == condition);

[iDataBlks, iCh] = procElem.GetDataBlocksIdxs(iCh0);
fprintf('Displaying channels [%s] in data blocks [%s]\n', num2str(iCh0(:)'), num2str(iDataBlks(:)'))
iColor = 1;
for iBlk = iDataBlks

    if isempty(iCh)
        iChBlk  = [];
    else
        iChBlk  = iCh{iBlk};
    end
    
    ch      = procElem.GetMeasList(iBlk);
    chVis   = find(ch.MeasListVis(iChBlk)==1);
    d       = [];
    dStd    = [];
    t       = [];
    nTrials = [];    
    
    % Get plot data from dataTree
    if datatype == hmr.buttonVals.RAW
        d = procElem.GetDataMatrix(iBlk);
        t = procElem.GetTime(iBlk);
    elseif datatype == hmr.buttonVals.OD
        d = procElem.GetDod(iBlk);
        t = procElem.GetTime(iBlk);
    elseif datatype == hmr.buttonVals.CONC
        d = procElem.GetDc(iBlk);
        t = procElem.GetTime(iBlk);
    elseif datatype == hmr.buttonVals.OD_HRF
        d = procElem.GetDodAvg([], iBlk);
        t = procElem.GetTHRF(iBlk);
        if showStdErr
            dStd = procElem.GetDodAvgStd(iBlk);
        end
        nTrials = procElem.GetNtrials();
        if isempty(condition)
            return;
        end
    elseif datatype == hmr.buttonVals.CONC_HRF
        d = procElem.GetDcAvg([], iBlk);
        t = procElem.GetTHRF(iBlk);
        if showStdErr
            dStd = procElem.GetDcAvgStd([], iBlk) * sclConc;
        end
        nTrials = procElem.GetNtrials();
        if isempty(condition)
            return;
        end
    end
    
    %%% Plot data
    if ~isempty(d)
        xx = xlim();
        yy = ylim();
        if strcmpi(get(hAxes,'ylimmode'),'manual')
            flagReset = 0;
        else
            flagReset = 1;
        end
        hold on
        
        % Set the axes ranges
        if flagReset==1
            set(hAxes,'xlim',[t(1), t(end)]);
            set(hAxes,'ylimmode','auto');
        else
            xlim(xx);
            ylim(yy);
        end
        
        linecolors = linecolor(iColor:iColor+length(iChBlk)-1,:);
        
        % Plot data
        if datatype == hmr.buttonVals.RAW || datatype == hmr.buttonVals.OD || datatype == hmr.buttonVals.OD_HRF
            if  datatype == hmr.buttonVals.OD_HRF
                d = d(:,:,condition);
            end
            d = procElem.reshape_y(d, ch.MeasList);
            DisplayDataRawOrOD(t, d, dStd, iWl, iChBlk, chVis, nTrials, condition, linecolors, linestyle);
        elseif datatype == hmr.buttonVals.CONC || datatype == hmr.buttonVals.CONC_HRF
            if  datatype == hmr.buttonVals.CONC_HRF
                d = d(:,:,:,condition);
            end
            d = d * sclConc;
            DisplayDataConc(t, d, dStd, hbType, iChBlk, chVis, nTrials, condition, linecolors, linestyle);
        end
    end
    iColor = iColor+length(iChBlk);
end

DisplayAxesSDG();
DisplayExcludedTime(handles, datatype);
DisplayStim(handles);
UpdateCondPopupmenu(handles);
UpdateDatatypePanel(handles);
UpdateChildGuis(handles);



% ----------------------------------------------------------------------------------
function DisplayStim(handles)
global hmr
dataTree = hmr.dataTree;
guiControls = hmr.guiControls;
procElem = dataTree.currElem;

if ~strcmp(procElem.type, 'run')
    return;
end

hAxes = guiControls.axesData.handles.axes;
if ~ishandles(hAxes)
    return;
end
axes(hAxes);
hold on;

datatype = getDatatype(handles);
if datatype == hmr.buttonVals.RAW_HRF
    return;
end
if datatype == hmr.buttonVals.OD_HRF
    return;
end
if datatype == hmr.buttonVals.CONC_HRF
    return;
end

%%% Plot stim marks. This has to be done before plotting exclude time
%%% patches because stim legend doesn't work otherwise.
t          = procElem.GetTime();
s          = procElem.GetStims();
stimVals   = procElem.GetStimValSettings();
CondColTbl = procElem.CondColTbl;

% Plot included and excluded stims
yrange = GetAxesYRangeForStimPlot(hAxes);
hLg=[];
idxLg=[];
kk=1;
for iCond = 1:size(s,2)
    iCondGroup = procElem.CondName2Group(iCond);
    iS = find(s(:,iCond) ~= stimVals.none);
    for ii=1:length(iS)
        linestyle = '';
        if     s(iS(ii),iCond) == stimVals.excl_auto
            linestyle = '-.';
        elseif s(iS(ii),iCond) == stimVals.excl_manual
            linestyle = '--';
        elseif s(iS(ii),iCond) == stimVals.incl
            linestyle = '-';
        end
        hl = plot(t(iS(ii))*[1 1], yrange, linestyle);
        set(hl, 'linewidth',1);
        set(hl, 'color',CondColTbl(iCondGroup,:));
    end
    
    % Get handles and indices of each stim condition
    % for legend display
    if ~isempty(iS)
        % We don't want dashed lines appearing in legend, so
        % we draw invisible solid stims over all stims to
        % trick the legend into only showing solid lines.
        hLg(kk) = plot(t(iS(1))*[1 1],yrange,'-', 'linewidth',4, 'visible','off');
        set(hLg(kk),'color',CondColTbl(iCondGroup,:));
        idxLg(kk) = iCondGroup;
        kk=kk+1;
    end
end
DisplayCondLegend(hLg, idxLg);
hold off
set(hAxes,'ygrid','on');
                
                
                
% ----------------------------------------------------------------------------------
function DisplayCondLegend(hLg, idxLg)
global hmr
dataTree = hmr.dataTree;
procElem = dataTree.currElem;

if isempty(hLg)
    return;    
end
if isempty(idxLg)
    return;    
end
[idxLg, k] = sort(idxLg);
CondNamesAll = procElem.CondNamesAll;
if ishandles(hLg)
    legend(hLg(k), CondNamesAll(idxLg));
end



% ----------------------------------------------------------------------------------
function Update()
global hmr

DisplayData(hmr.handles, hmr.handles.axesData);



% --------------------------------------------------------------------
function menuItemResetGroupFolder_Callback(hObject, eventdata, handles)

resetGroupFolder();


