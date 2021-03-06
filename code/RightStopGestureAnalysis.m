fs = 100; % 100Hz

% convert timetable to array and extract data
% convertedData = [seconds(Acceleration.Timestamp - Acceleration.Timestamp(1)) Acceleration.Variables]
acceleration_table = timetable2table(Acceleration);
accel_phone = table2array(acceleration_table(:,2:4));
orientation_table = timetable2table(Orientation);
orientation = table2array(orientation_table(:,2:4)); 
gyro_table = timetable2table(AngularVelocity);
gyro = table2array(gyro_table(:,2:4));
gyro_x = gyro(:,1);
gyro_y = gyro(:,2);
gyro_z = gyro(:,3);
yaw = orientation(:,1);
pitch = orientation(:,2);
roll = orientation(:,3);

% extract gravity component
gravity = [0;0;9.8];
N = length(orientation);
g_phone = [];

for i = 1:N
    PitchMat = pitchrot(pitch(i));
    RollMat = rollrot(roll(i));
    YawMat = yawrot(yaw(i));
    
    g =  RollMat'*PitchMat'*YawMat'*gravity; 
    g_phone = [g_phone; transpose(g)];
end

% filter out gravity offset
accel_phone_filtered = accel_phone - g_phone;
% Analyze Gravity filtered data
accel_x = accel_phone_filtered(:,1);
accel_y = accel_phone_filtered(:,2);
accel_z = accel_phone_filtered(:,3);

% plot gravity filtered
figure
subplot(3,2,1)
plot(accel_x)
title("Accel X Gravity Filtered")
subplot(3,2,3)
plot(accel_y)
title("Accel Y Gravity Filtered")
subplot(3,2,5)
plot(accel_z)
title("Accel Z Gravity Filtered")
subplot(3,2,2)
plot(accel_phone(:,1))
title("Accel X Raw Data")
subplot(3,2,4)
plot(accel_phone(:,2))
title("Accel Y Raw Data")
subplot(3,2,6)
plot(accel_phone(:,3))
title("Accel Z Raw Data")

% plot acceleration gyro data time domain
figure
subplot(3,2,1)
plot(gyro_x)
title("Gyro x")
subplot(3,2,3)
plot(gyro_y)
title("Gyro y")
subplot(3,2,5)
plot(gyro_z)
title("Gyro z")
subplot(3,2,2)
plot(accel_x)
title("Acceleration x")
subplot(3,2,4)
plot(accel_y)
title("Acceleration y")
subplot(3,2,6)
plot(accel_z)
title("Acceleration z")

% subtract mean
accel_x = accel_x - mean(accel_x);
accel_y = accel_y - mean(accel_y);
accel_z = accel_z - mean(accel_z);
gyro_x = gyro_x - mean(gyro_x);
gyro_y = gyro_y - mean(gyro_y);
gyro_z = gyro_z - mean(gyro_z);

% fft raw data
N_accel = length(accel_x);
N_gyro = length(gyro_x);
N_orien = length(yaw);
f_accel = linspace(-fs/2, fs/2 - fs/N_accel, N_accel) + fs/(2*N_accel)*mod(N_accel, 2);
f_gyro = linspace(-fs/2, fs/2 - fs/N_gyro, N_gyro) + fs/(2*N_gyro)*mod(N_gyro, 2);
f_orien = linspace(-fs/2, fs/2 - fs/N_orien, N_orien) + fs/(2*N_orien)*mod(N_orien, 2);
X_accel = fft(accel_x);
Y_accel = fft(accel_y);
Z_accel = fft(accel_z);
X_gyro = fft(gyro_x);
Y_gyro = fft(gyro_y);
Z_gyro = fft(gyro_z);

% plot accel frequency domain
figure
subplot(3,1,1);
plot(f_accel, fftshift(abs(X_accel)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Accel x")
subplot(3,1,2);
plot(f_accel, fftshift(abs(Y_accel)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Accel y")
subplot(3,1,3);
plot(f_accel, fftshift(abs(Z_accel)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Accel z")

% plot gyro frequency domain
figure
subplot(3,1,1);
plot(f_gyro, fftshift(abs(X_gyro)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Gyro x")
subplot(3,1,2);
plot(f_gyro, fftshift(abs(Y_gyro)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Gyro y")
subplot(3,1,3);
plot(f_gyro, fftshift(abs(Z_gyro)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Gyro z")

% Analyze Orientation Data (y axis only)
world_y = [0,1,0];
% change world axis to phone axis
N = length(orientation);
phone_y = rpy_world2local(N,world_y,orientation);
% subtract mean
phone_y = phone_y - mean(phone_y);
% fft on phone axis
phone_Y = fftn(phone_y);
N_orien = length(yaw);
f_orien = linspace(-fs/2, fs/2 - fs/N_orien, N_orien) + fs/(2*N_orien)*mod(N_orien, 2);
% plot orientation frequency domain y axis
figure
plot(f_orien, fftshift(abs(phone_Y(:,1)))); % only look at i component
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Phone Y axis i")

% identify peak frequency 
[X_gyro_sorted,X_gyro_I] = sort(fftshift(abs(X_gyro)),'descend');
majorfreq_X_gyro = abs(f_gyro(X_gyro_I(7))); % stop
majorfreq_X_gyro_mag = X_gyro_sorted(7); % stop
% majorfreq_X_gyro = abs(f_gyro(X_gyro_I(5))); % right
% majorfreq_X_gyro_mag = X_gyro_sorted(5); % right
X_gyro_phase = fftshift(angle(X_gyro));
majorfreq_X_gyro_phase = X_gyro_phase(X_gyro_I(1));
[phone_Y_sorted, phone_Y_I] = sort(fftshift(abs(phone_Y(:,1))),'descend');
maxfreq_phone_Y = abs(f_orien(phone_Y_I(1)));
maxfreq_phone_Y_mag = phone_Y_sorted(1);
phone_Y_phase = fftshift(angle(phone_Y(:,1)));
maxfreq_phone_Y_phase = phone_Y_phase(phone_Y_I(1));

% bandpass 
lower_offset = 0.01;
higher_offset = 0.12;
accel_x_bp = bandpass(accel_x,[majorfreq_X_gyro - lower_offset, majorfreq_X_gyro + higher_offset],fs);
accel_y_bp = bandpass(accel_y,[majorfreq_X_gyro - lower_offset, majorfreq_X_gyro + higher_offset],fs);
accel_z_bp = bandpass(accel_z,[majorfreq_X_gyro - lower_offset, majorfreq_X_gyro + higher_offset],fs);
gyro_x_bp = bandpass(gyro_x,[majorfreq_X_gyro - lower_offset, majorfreq_X_gyro + higher_offset],fs);
gyro_y_bp = bandpass(gyro_y,[majorfreq_X_gyro - lower_offset, majorfreq_X_gyro + higher_offset],fs);
gyro_z_bp = bandpass(gyro_z,[majorfreq_X_gyro - lower_offset, majorfreq_X_gyro + higher_offset],fs);

% fft filtered data
X_accel_bp = fft(accel_x_bp);
Y_accel_bp = fft(accel_y_bp);
Z_accel_bp = fft(accel_z_bp);
X_gyro_bp = fft(gyro_x_bp);
Y_gyro_bp = fft(gyro_y_bp);
Z_gyro_bp = fft(gyro_z_bp);

% plot accel band pass frequency domain
figure
subplot(3,1,1);
plot(f_accel, fftshift(abs(X_accel_bp)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Accel x filtered")
subplot(3,1,2);
plot(f_accel, fftshift(abs(Y_accel_bp)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Accel y filtered")
subplot(3,1,3);
plot(f_accel, fftshift(abs(Z_accel_bp)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Accel z filtered")

% plot gyro band pass frequency domain
figure
subplot(3,1,1);
plot(f_gyro, fftshift(abs(X_gyro_bp)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Gyro x filtered")
subplot(3,1,2);
plot(f_gyro, fftshift(abs(Y_gyro_bp)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Gyro y filtered")
subplot(3,1,3);
plot(f_gyro, fftshift(abs(Z_gyro_bp)));
xlabel("Frequency(Hz)");
ylabel("Amplitude");
title("Gyro z filtered")

% plot accel gyro orientation bandpass time domain
figure
subplot(3,2,1)
plot(gyro_x_bp)
title("Gyro x filtered")
subplot(3,2,3)
plot(gyro_y_bp)
title("Gyro y filtered")
subplot(3,2,5)
plot(gyro_z_bp)
title("Gyro z filtered")
subplot(3,2,2)
plot(accel_x_bp)
title("Acceleration x filtered")
subplot(3,2,4)
plot(accel_y_bp)
title("Acceleration y filtered")
subplot(3,2,6)
plot(accel_z_bp)
title("Acceleration z filtered")

% change accelerometer data to world coordinate frame
accel_phone_filtered = horzcat(accel_x_bp, accel_y_bp, accel_z_bp);
N = length(orientation);
accel_world = [];

for i = 1:N
    PitchMat = pitchrot(pitch(i));
    RollMat = rollrot(roll(i));
    YawMat = yawrot(yaw(i));
    
    a_world =  RollMat*PitchMat*YawMat*transpose(accel_phone_filtered(i,:)); 
    accel_world = [accel_world; transpose(a_world)];
end


% Take the integral of acceleration
velocity_world = [0,0,0];
for i = 2:length(accel_world)
    vf = accel_world(i,:)*0.01 + velocity_world(i-1,:);
    velocity_world = [velocity_world;vf];
end

% Take the integral of velocity
position_world = [0,0,0];
for i = 2:length(velocity_world)
    df = velocity_world(i,:)*0.01 + position_world(i-1,:);
    position_world = [position_world;df];
end

% plot position
figure
plot(position_world(:,1),position_world(:,2),'b')
title("Position of Biker Over Time")
xlabel("x(m)")
ylabel("y(m)")


function res = pitchrot(alpha) % pitch
    res = [1 0 0; 0 cosd(alpha) sind(alpha); 0 -sind(alpha) cosd(alpha)];
end 

function res = rollrot(beta) % roll
    res = [cosd(beta) 0 sind(beta); 0 1 0; -sind(beta) 0 cosd(beta)];
end

function res = yawrot(theta) % yaw
    res = [cosd(theta) -sind(theta) 0; sind(theta) cosd(theta) 0; 0 0 1];
end
function res = rpy_world2local(n, v,orientation)
    axis = [];
    for i = 1:n
        YawMat = yawrot(orientation(i,1));
        PitchMat = pitchrot(orientation(i,2));
        RollMat = rollrot(orientation(i,3));
        new_axis =  RollMat'*PitchMat'*YawMat'*transpose(v); 
        axis = [axis; transpose(new_axis)]; 
    end
    res = axis;
end