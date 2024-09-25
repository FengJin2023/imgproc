%% Illustrate sensor aliasing using a monochrome sensor
%
% When the acuity of the lens exceeds the sampling rate of the sensor,x_0.2y_3.099999999999996z_2.7.png
% aliasing patterns emerge.  These are low frequency patterns in the sensor
% response that are caused by the high frequency patterns in the original
% image but under-sampled by the sensor.
%
% To protect against aliasing, you can use a lens that does not pass the
% high frequency terms.
%
% The aliasing artifacts illustrated here are for a monochrome sensor.
% When the same problem arises from a color CFA, the artifacts emerge as
% unwanted colors (chromatic aliasing).
%
% Copyright Imageval Consulting, LLC, 2016

%%
ieInit
delay = 0.2;

%% Load display calibration data

displayCalFile = 'LCD-Apple.mat';
load(displayCalFile,'d'); dsp = d;
wave = displayGet(dsp,'wave');
spd = displayGet(dsp,'spd');

%vcNewGraphWin; plot(wave,spd);
%xlabel('Wave (nm)'); ylabel('Energy'); grid on
%title('Spectral Power Distribution of Display Color Primaries');

%% Analyze the display properties: Chromaticity

d = displayCreate(displayCalFile);
whtSPD = displayGet(d,'white spd');
wave   = displayGet(d,'wave');
whiteXYZ = ieXYZFromEnergy(whtSPD',wave);

% Brings up the window
%fig = chromaticityPlot(chromaticity(whiteXYZ));

%% Read in an rgb file and create calibrated display values

rgbFile = fullfile(isetRootPath,'data','images','rgb','HDimage','RGB','beforesim','x_-2.5y_0.8999999999999999z_2.7.png');
scene = sceneFromFile(rgbFile,'rgb',[],displayCalFile);
% To see an example of the dependence, consider the effect of scene
% distance, which we can get, on scene sample spacing.

scene = sceneSet(scene,'distance',1)
%sceneWindow(scene)
%% Set up a high resolution lens

oi = oiCreate('diffraction limited');
oi = oiSet(oi,'optics fnumber', 2);
oi = oiCompute(oi,scene);
%oiWindow(oi);

%% We use a small pixel size and see the scene come through correctly
bayerSensor = sensorCreate;
%bayerSensor = sensorSet(bayerSensor,'pixel size constant fill factor',3e-6);
bayerSensor = sensorSet(bayerSensor,'size',[2500 2500]);
bayerSensor = sensorSet(bayerSensor,'name','Bayer');
sensor = sensorCompute(bayerSensor,oi);
%sensorWindow(sensor);



%sensor = sensorCreate('monochrome');


%sensor = sensorSetSizeToFOV(sensor,fov,oi);

% Set a two micron pixel

%sensor = sensorSet(sensor,'pixel size constant fill factor',3e-5);
%sensor = sensorCompute(sensor,oi);
%sensorWindow(sensor);

%sensorPlot(sensor,'electrons hline',[5 1]);

%% Make the sensor pixel under-sample by creating a large pixel.

% Create the image processor.
ip = ipCreate;
ip = ipSet(ip,'name','default');


% First, we compute using the default image processing pipeline.
% Reading the boxes on the right of the window, we see the default
% processing steps.  These are
%
%  * Bilinear demosaicking
%  * Converting the sensor data into a calibrated internal color space
%  * Correcting for the illumination
%
% The demosaicking algorithm is implemented in Demosaic.m
% The sensor conversion in the default uses this logic:
%   * We know the sensor spectral responsivities
%   * We find the 3x3 linear transformation that best maps (least-squares)
%     the sensor values into a calibrated
% color space (See notes below).

% Choose the internal color space
ip = ipSet(ip,'internal cs','XYZ');

% Choose the likely set of signals the sensor will encounter
ip = ipSet(ip,'conversion method sensor','MCC Optimized');

% Give the image processor a name
ip = ipSet(ip,'name','MCC-XYZ');

% Note that at this point we have left illuminant correction to 'None'.  So
% there will be no illuminant correction at this point.

% Compute from sensor to sRGB
ip = ipCompute(ip,sensor);
showImageFlag = false; trueSizeFlag = false;
fName = ipSaveImage(ip,fullfile(isetRootPath,'data','images','rgb','HDimage','RGB','aftersim','x_-2.5y_0.8999999999999999z_2.7.png'),showImageFlag, trueSizeFlag);
%ipWindow(ip)
%% END