

%% ORIGINAL FACES DATA FILE
origspmfilename='cdbespm8_SPM_CTF_MEG_example_faces1_3D.mat';

%% OUTPUT SIMULATED DATA FILE
spmfilename='simdata_aud1020Hz';


%% FOR SIMULATED NOISE- recording BW of 80Hz, white noise level 10ft/rtHz
noiselevel=10*1e-15;
BW=80; 

%% FOR SIMULATED DATA
dipolepositions=[ 52, -29, 13; -52, -29, 13]; % in mni space
%% set frequency and amplitude of the two dipoles defined above 
%% for each condition (faces/scrambled) separately
    %cond1 cond2
dipfreq=[10 10;... %% dip 1
         20 20];     %%% dip 2
      %cond1 cond2
dipamp=[1 0;...         % dip 1
        1 0].*1e-1; % dip2 
%% define period over which dipoles are active
startf1=0.1; % (sec) start time
duration=0.3;% duration 

 
Ndips=size(dipolepositions,1);

%%% LOAD IN ORGINAL FACE DATA
D = spm_eeg_load(origspmfilename);
modality='MEG';
channel_labels = D.chanlabels(D.meegchannels(modality));

%%% GET LOCATION OF MESH Vertices in MNI and MEG/CTF space
allmeshvert_mni=D.inv{1}.mesh.tess_mni.vert;
allmeshvert_ctf=D.inv{1}.forward.mesh.vert;
allmeshfaces=D.inv{1}.forward.mesh.face;
allmeshnorms_ctf=spm_eeg_inv_normals(allmeshvert_ctf,allmeshfaces);
allmeshnorms_mni=spm_eeg_inv_normals(allmeshvert_mni,allmeshfaces);

%%% FORCE  A SINGE SPHERE HEAD MODEL- simpler to compare inversions
headmodels = {'Single Sphere', 'MEG Local Spheres', 'Single Shell'};
 D.inv{1}.forward(1).voltype=headmodels{1}; 
 D = spm_eeg_inv_forward(D); 
 grad = D.sensors('meg');
 vol = D.inv{1}.forward.vol;
 
 Ntrials=D.ntrials;

[condnames,ncond,trialtypes]=unique(D.conditions);
if length(condnames)~=size(dipamp,2),
    error('number trial types should equal number of columns in dipamp');
end; % if


allavsignal=zeros(Ndips,length(D.time));
    
for dipind=1:Ndips,
cfg      = [];
cfg.vol  = vol;             
cfg.grad = grad;            

%% SIMULATE DIPOLES ON THE CORTICAL SURFACE


%% find nearest dipole to location specified
 [d meshind] = min(sum([allmeshvert_mni(:,1) - dipolepositions(dipind,1), ...
                             allmeshvert_mni(:,2) - dipolepositions(dipind,2), ...
                             allmeshvert_mni(:,3) - dipolepositions(dipind,3)].^2,2));
 meshdippos(dipind,:)=allmeshvert_ctf(meshind,:);
  cfg.dip.pos = meshdippos(dipind,:);
  t1=allmeshnorms_ctf(meshind,:); %% get dip orientation from mesh
  meshsourceind(dipind)=meshind;  %





cfg.dip.mom =t1';     % note, it should be transposed
cfg.ntrials =Ntrials;

endf1=duration+startf1; 

f1ind=intersect(find(D.time>startf1),find(D.time<=endf1));


for i=1:cfg.ntrials
    f1=dipfreq(dipind,trialtypes(i)); %% frequency depends on stim condition
    amp1=dipamp(dipind,trialtypes(i));
    phase1=pi/2; 
    signal=zeros(1,length(D.time));
    signal(f1ind)=signal(f1ind)+amp1*sin((D.time(f1ind)-D.time(min(f1ind)))*f1*2*pi+phase1);
    cfg.dip.signal{i}=signal;
    allavsignal(dipind,:)=allavsignal(dipind,:)+signal;
end; % for i

cfg.triallength =max(D.time)-min(D.time);        % seconds
cfg.fsample = D.fsample;          % Hz
onesampletime=1/D.fsample;
cfg.absnoise=0;
cfg.relnoise=0;
cfg.channel=channel_labels;
raw1 = ft_dipolesimulation(cfg);
allraw(dipind)=raw1;
end; % for dipind

%% MERGE N DIPOLES INTO ONE DATASET
for dipind=1:Ndips,
    if dipind==1;
        dipsum=allraw(dipind).trial;
    else
        for i=1:Ntrials,
            newdata=cell2mat(allraw(dipind).trial(i));
            dataprev=cell2mat(dipsum(i));
            dataraw=newdata+dataprev;
            dipsum(i)=mat2cell(dataraw,size(newdata,1),size(newdata,2));
        end;
        
    end;
end;
allraw=raw1;
allraw.trial=dipsum;
clear dipsum;

    %% NOW ADD WHITE NOISE
    for i=1:Ntrials,
        dataraw=cell2mat(allraw.trial(i));
        channoise=randn(size(dataraw)).*noiselevel*sqrt(BW);
        dataraw=dataraw+channoise;
        allraw.trial(i)=mat2cell(dataraw, size(dataraw,1),size(dataraw,2));
        allraw.time(i)=mat2cell(D.time,1);
        epochdata=cell2mat(allraw.trial(i))';
    end;


avg1 = ft_timelockanalysis([], allraw);
plot(avg1.time, avg1.avg);  % plot the average timecourse

%%% now write out a new data set
D2=D;
D2=spm_eeg_ft2spm(allraw,spmfilename);
D2=sensors(D2,'MEG',raw1.grad);
D2=fiducials(D2,D.fiducials);
D2.inv=D.inv;
D2 = conditions(D2, [], D.conditions);
D2=coor2D(D2,'MEG',coor2d(D)); %% save projected 2d channel locations
D2.save;

figure;
h=plot(D2.time,allavsignal);
set(h(1),'Linestyle',':');
set(h,'LineWidth',4);
set(gca,'FontSize',18);
set(gcf,'color','w');

%% write an averaged data set also
S=[];
S.D=D2;
S.robust=0;
D2av = spm_eeg_average(S);

  
  
  
  
