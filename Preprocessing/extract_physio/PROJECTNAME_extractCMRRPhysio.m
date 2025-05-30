function extractCMRRPhysio(varargin)
% -------------------------------------------------------------------------
% extractCMRRPhysio.m
% -------------------------------------------------------------------------
% Extract physiological log files from encoded "_PHYSIO" DICOM file
% generated by CMRR MB sequences (>=R015, >=VD13A)
%   E. Auerbach, CMRR, 2016
%
% This function expects to find a single encoded "_PHYSIO" DICOM file
% generated by the CMRR C2P sequences >=R015. It will extract and write
% individual log files (*_ECG.log, *_RESP.log, *_PULS.log, *_EXT.log,
% *_Info.log) compatible with the CMRR C2P sequences >=R013. Only log
% files with nonzero traces will be written.

% Usage:
%    extractCMRRPhysio(DICOM_filename, [output_path]);
%
% Inputs:
%    DICOM_filename = 'XXX.dcm'
%    output_path    = '/path/to/output/' (optional; if not specified, will
%                                         use path of input file)


% say hello
fprintf('\nextractCMRRPhysio: E. Auerbach, CMRR, 2016\n\n');

if (nargin < 1) || (nargin > 2)
    error('Invalid number of inputs.');
end
fn = varargin{1};
if (nargin == 2)
    outpath = varargin{2};
else
    [outpath, ~, ~] = fileparts(fn);
end

% first, verify our input is a DICOM file
if (2 ~= exist(fn,'file'))
    error('%s not found!', fn);
end
if (~isdicom(fn))
    error('%s not a DICOM file!', fn);
end

% read in the DICOM
fprintf('Attempting to read CMRR Physio DICOM format file...\n');
warning('off','images:dicominfo:attrWithSameName');
dcmInfo = dicominfo(fn);
if (~isempty(dcmInfo) && isfield(dcmInfo,'ImageType') && strcmp(dcmInfo.ImageType,'ORIGINAL\PRIMARY\RAWDATA\PHYSIO') ...
        && isfield(dcmInfo,'Private_7fe1_10xx_Creator') && strcmp(deblank(char(dcmInfo.Private_7fe1_10xx_Creator)),'SIEMENS CSA NON-IMAGE'))
    np = size(dcmInfo.Private_7fe1_1010,1);
    rows = dcmInfo.AcquisitionNumber;
    columns = np/rows;
    numFiles = columns/1024;
    if (rem(np,rows) || rem(columns,1024)), error('Invalid image size (%dx%d)!', columns, rows); end
    dcmData = reshape(dcmInfo.Private_7fe1_1010,[],numFiles)';
    % encoded DICOM format: columns = 1024*numFiles
    %                       first row: uint32 datalen, uint32 filenamelen, char[filenamelen] filename
    %                       remaining rows: char[datalen] data
    [~,~,endian] = computer;
    needswap = ~strcmp(endian,'L');
    for idx=1:numFiles
        datalen = typecast(dcmData(idx,1:4),'uint32');
        if needswap, datalen = swapbytes(datalen); end
        filenamelen = typecast(dcmData(idx,5:8),'uint32');
        if needswap, filenamelen = swapbytes(filenamelen); end
        filename = char(dcmData(idx,9:9+filenamelen-1));
        logData = dcmData(idx,1025:1025+datalen-1);
        outfn = fullfile(outpath, filename);
        fprintf('  Writing: %s\n', outfn);
        fp = fopen(outfn,'w');
        fwrite(fp, char(logData));
        fclose(fp);
    end
    fprintf('\nDone!\n');
else
    error('%s is not a valid encoded physio DICOM format file!', fn);
end
