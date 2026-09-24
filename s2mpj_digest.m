function digest = s2mpj_digest(bytes, use_jvm)
%S2MPJ_DIGEST Internal SHA-256 of bytes, with a public-API no-JVM fallback.
% The optional second argument is used by integrity tests, not loader options.
    if nargin < 2, use_jvm = usejava('jvm'); end
    bytes = uint8(bytes(:).');
    if use_jvm && usejava('jvm')
        engine = java.security.MessageDigest.getInstance('SHA-256');
        if ~isempty(bytes), engine.update(typecast(bytes(:),'int8')); end
        digest = lower(reshape(dec2hex(typecast(engine.digest(), 'uint8'), 2)', 1, []));
        return
    end
    % FIPS 180-4 SHA-256: all additions wrap modulo 2^32. MATLAB uint32
    % addition saturates, so add exactly representable doubles before mod.
    persistent K initial
    if isempty(K)
        K = uint32(hex2dec({ ...
            '428a2f98','71374491','b5c0fbcf','e9b5dba5','3956c25b','59f111f1','923f82a4','ab1c5ed5', ...
            'd807aa98','12835b01','243185be','550c7dc3','72be5d74','80deb1fe','9bdc06a7','c19bf174', ...
            'e49b69c1','efbe4786','0fc19dc6','240ca1cc','2de92c6f','4a7484aa','5cb0a9dc','76f988da', ...
            '983e5152','a831c66d','b00327c8','bf597fc7','c6e00bf3','d5a79147','06ca6351','14292967', ...
            '27b70a85','2e1b2138','4d2c6dfc','53380d13','650a7354','766a0abb','81c2c92e','92722c85', ...
            'a2bfe8a1','a81a664b','c24b8b70','c76c51a3','d192e819','d6990624','f40e3585','106aa070', ...
            '19a4c116','1e376c08','2748774c','34b0bcb5','391c0cb3','4ed8aa4a','5b9cca4f','682e6ff3', ...
            '748f82ee','78a5636f','84c87814','8cc70208','90befffa','a4506ceb','bef9a3f7','c67178f2'}));
        initial = uint32(hex2dec({'6a09e667','bb67ae85','3c6ef372','a54ff53a', ...
            '510e527f','9b05688c','1f83d9ab','5be0cd19'})).';
    end
    bit_length = uint64(numel(bytes))*8;
    bytes = [bytes, uint8(128), zeros(1, mod(55-numel(bytes),64), 'uint8'), ...
        uint8(bitand(bitshift(bit_length, -8*(7:-1:0)), uint64(255)))];
    state = initial;
    for start = 1:64:numel(bytes)
        block = reshape(uint32(bytes(start:start+63)),4,16);
        w = zeros(1,64,'uint32');
        w(1:16) = bitor(bitor(bitshift(block(1,:),24),bitshift(block(2,:),16)), ...
            bitor(bitshift(block(3,:),8),block(4,:)));
        for j = 17:64
            a = w(j-15); b = w(j-2);
            s0 = bitxor(bitxor(rotate(a,7),rotate(a,18)),bitshift(a,-3));
            s1 = bitxor(bitxor(rotate(b,17),rotate(b,19)),bitshift(b,-10));
            w(j) = add32([w(j-16),s0,w(j-7),s1]);
        end
        v = state;
        for j = 1:64
            s1 = bitxor(bitxor(rotate(v(5),6),rotate(v(5),11)),rotate(v(5),25));
            ch = bitxor(bitand(v(5),v(6)),bitand(bitcmp(v(5)),v(7)));
            t1 = add32([v(8),s1,ch,K(j),w(j)]);
            s0 = bitxor(bitxor(rotate(v(1),2),rotate(v(1),13)),rotate(v(1),22));
            maj = bitxor(bitxor(bitand(v(1),v(2)),bitand(v(1),v(3))),bitand(v(2),v(3)));
            t2 = add32([s0,maj]);
            v = [add32([t1,t2]),v(1:3),add32([v(4),t1]),v(5:7)];
        end
        state = uint32(mod(double(state)+double(v),4294967296));
    end
    digest = lower(reshape(dec2hex(state,8)',1,[]));
end

function value = rotate(value, count)
    value = bitor(bitshift(value,-count),bitshift(value,32-count));
end

function value = add32(values)
    value = uint32(mod(sum(double(values)),4294967296));
end
