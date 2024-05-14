% Note:
% Explanation of Changes
% Increased numBits: Reflects the 16-bit adder.
% Updated nTestCases: Adjusted to match the total number of test cases considering additional tests added in Verilog.
% Path and File: Ensure your directory path and filename ('adder_simulation') correctly point to where your outputs are stored.
% Vectorized Operations: Optimized MATLAB operations to process data vector-wise where possible for efficiency.
% Validation Section: Enhanced the output details for better debugging and verification.
% Make sure to validate the paths, signal names, and details like Vdd settings and timing specifics to match your actual simulation environment and design specifics.

% Set up cds_srr function
addpath('/opt/cadence/INNOVUS201/tools.lnx86/spectre/matlab/64bit');

% Directory that contains the simulation outputs
directory = sprintf('%s/Cadence/%s.psf', getenv('HOME'), 'adder_simulation');

% Define basic parameters
Vdd = 1.2; % Voltage
numBits = 16; % Change to 16 for a 16-bit adder
nTestCases = 2 + 16 + 16 + 2 + 2 + 2 + 2 + 2 + 16; % Updated number of test cases for 16-bit
startDelay = 1000;
period_clk = 4000; % CLK

% Initialize arrays
cin = cds_srr(directory, 'tran-tran', '/OutC', 0);
cout = cds_srr(directory, 'tran-tran', '/Cout_2', 0);
cin = cin.V;
cout = cout.V;
t_ps = cin.time * 1e12; % Convert time into ps

% Preallocate for input and output vectors
s_vec = zeros(numBits, length(cin.time));
a_vec = zeros(numBits, length(cin.time));
b_vec = zeros(numBits, length(cin.time));

% Extract signal voltages for all bits
for i = 1:numBits
    signal_name = sprintf('/S_2<%d>', i-1);
    s = cds_srr(directory, 'tran-tran', signal_name, 0);
    s_vec(i, :) = s.V;

    signal_name_a = sprintf('/OutA<%d>', i-1);
    a = cds_srr(directory, 'tran-tran', signal_name_a, 0);
    a_vec(i, :) = a.V;

    signal_name_b = sprintf('/OutB<%d>', i-1);
    b = cds_srr(directory, 'tran-tran', signal_name_b, 0);
    b_vec(i, :) = b.V;
end

% Sampling points for inputs and outputs
t_ps_sample_in = startDelay + period_clk/2 + (0:nTestCases-1)*period_clk;
t_ps_sample_out = startDelay + period_clk*0.75 + (0:nTestCases-1)*period_clk;

% Convert the analog output into digital signals and then into decimal numbers
digital_a = a_vec > Vdd/2;
digital_b = b_vec > Vdd/2;
digital_s = s_vec > Vdd/2;
decimal_a = bi2de(digital_a', 'left-msb');
decimal_b = bi2de(digital_b', 'left-msb');
decimal_s = bi2de(digital_s', 'left-msb');
decimal_cin = cin > Vdd/2;
decimal_cout = cout > Vdd/2;
exp_decimal_s = decimal_a + decimal_b + decimal_cin;

% Calculate expected output, considering carry
exp_decimal_cout = bitget(exp_decimal_s, numBits+1);
exp_decimal_s = bitset(exp_decimal_s, numBits+1, 0);

% Validation
err_flag = 0;
for i = 1:nTestCases
    t_ps_idx_in = find(t_ps - t_ps_sample_in(i) >= 0, 1);
    t_ps_idx_out = find(t_ps - t_ps_sample_out(i) >= 0, 1);
    
    myadder_output = decimal_s(t_ps_idx_out);
    exp_adder_output = exp_decimal_s(t_ps_idx_out);
    myadder_cout = decimal_cout(t_ps_idx_out);
    exp_adder_cout = exp_decimal_cout(t_ps_idx_out);

    % Check for discrepancies
    if (exp_adder_cout ~= myadder_cout || exp_adder_output ~= myadder_output)
        fprintf('Test %d/%d WRONG - Expected: s=%d, cout=%d | Measured: s=%d, cout=%d\n',...
            i, nTestCases, exp_adder_output, exp_adder_cout, myadder_output, myadder_cout);
        err_flag = err_flag + 1;
    else
        fprintf('Test %d/%d CORRECT\n', i, nTestCases);
    end
end
fprintf('Correct cases: %d/%d\n', nTestCases - err_flag, nTestCases);
if err_flag == 0
    disp('The adder circuit has no errors :)');
end
