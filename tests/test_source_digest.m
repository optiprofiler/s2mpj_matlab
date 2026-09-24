function test_source_digest()
%TEST_SOURCE_DIGEST Known SHA-256 vectors and optional JVM parity.
    inputs = {uint8([]),uint8('abc'),uint8(['abcdbcdecdefdefgefghfghighijhijk', ...
        'ijkljklmklmnlmnomnopnopq'])};
    expected = {'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', ...
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', ...
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1'};
    for k = 1:numel(inputs)
        assert(strcmp(s2mpj_digest(inputs{k},false),expected{k}));
        assert(strcmp(s2mpj_digest(inputs{k}),expected{k}));
    end
    for bytes = {uint8(0),uint8(255),uint8(0:255)}
        assert(strcmp(s2mpj_digest(bytes{1},false),s2mpj_digest(bytes{1})));
    end
    root = fileparts(fileparts(mfilename('fullpath')));
    for file = {fullfile(root,'src','s2mpjlib.m'), ...
            fullfile(root,'src','matlab_problems','ROSENBR.m')}
        fid=fopen(file{1},'rb'); bytes=fread(fid,Inf,'*uint8'); fclose(fid);
        assert(strcmp(s2mpj_digest(bytes,false),s2mpj_digest(bytes)));
    end
    disp('S2MPJ source digest: PASS');
end
